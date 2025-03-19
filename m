From: Nikita Shubin <n.shubin@yadro.com>
Date: Wed, 19 Mar 2025 10:57:57 +0300
Subject: [PATCH PoC 7/7] gpiodev: Add gpiobackend over GUSE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-gpiodev-v1-7-76da4e5800a1@yadro.com>
References: <20250319-gpiodev-v1-0-76da4e5800a1@yadro.com>
In-Reply-To: <20250319-gpiodev-v1-0-76da4e5800a1@yadro.com>
To: qemu-devel@nongnu.org
Cc: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 "Enrico Weigelt, metux IT consult" <info@metux.net>, 
 Viresh Kumar <vireshk@kernel.org>, Eric Blake <eblake@redhat.com>, 
 Markus Armbruster <armbru@redhat.com>, Michael Roth <michael.roth@amd.com>, 
 Paolo Bonzini <pbonzini@redhat.com>, 
 =?utf-8?q?Marc-Andr=C3=A9_Lureau?= <marcandre.lureau@redhat.com>, 
 =?utf-8?q?Daniel_P=2E_Berrang=C3=A9?= <berrange@redhat.com>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@linaro.org>, 
 Eduardo Habkost <eduardo@habkost.net>, 
 =?utf-8?q?C=C3=A9dric_Le_Goater?= <clg@kaod.org>, 
 Peter Maydell <peter.maydell@linaro.org>, 
 Steven Lee <steven_lee@aspeedtech.com>, Troy Lee <leetroy@gmail.com>, 
 Jamin Lin <jamin_lin@aspeedtech.com>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>, Joel Stanley <joel@jms.id.au>, 
 qemu-arm@nongnu.org, Nikita Shubin <nikita.shubin@maquefel.me>, 
 Nikita Shubin <n.shubin@yadro.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742371072; l=25956;
 i=n.shubin@yadro.com; s=20230718; h=from:subject:message-id;
 bh=cNBgCGBMLxXgwvJD8kFv/hNFULw4AM2bNKWA3qo9Ik0=;
 b=da/v3MMHqbf3iyZmB9TJpfufqJeB1STsA8hGs9bqbbyHrwgvkALZVqcpMMVYp6kDLHyQHhCSG
 c/2q74IEYPjBQwh+RLjfAOQccPcADl9KIqXQlBPDccX4ULYyCqoqzg4
X-Developer-Key: i=n.shubin@yadro.com; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for n.shubin@yadro.com/20230718 with auth_id=161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add GUSE (FUSE based kernel module similiar to CUSE) based backend.

This allows transparent usage of Linux GPIO UAPI based tools like
in kernel tools/gpio or libgpiod.

libgpiod requires some modification to allow "/sys/class/guse" in
gpiod_check_gpiochip_device().

It requires guse module to be loaded and providing DEVICE()->id
for GPIO module, for example:

```
DEVICE(&s->gpio)->id = g_strdup("aspeed-gpio0");
```

The id should be provided to gpiodev with any `devname` that doesn't
exists in /dev:

```
-gpiodev guse,id=aspeed-gpio0,devname=gpiochip10
```

That /dev/gpiochip10 can be used in the same way we usually operate with
gpiochip's.

Link: http://git.maquefel.me/?p=qemu-gpiodev/libgpiod.git;a=shortlog;h=refs/heads/nshubin/guse-fix
Link: http://git.maquefel.me/?p=qemu-gpiodev/guse.git;a=summary
Link: http://git.maquefel.me/?p=qemu-gpiodev/libfuse.git;a=shortlog;h=refs/heads/nshubin/guse
Signed-off-by: Nikita Shubin <n.shubin@yadro.com>
---
 gpiodev/gpio-guse.c    | 747 +++++++++++++++++++++++++++++++++++++++++++++++++
 gpiodev/meson.build    |   1 +
 include/gpiodev/gpio.h |   1 +
 qapi/gpio.json         |  31 +-
 4 files changed, 777 insertions(+), 3 deletions(-)

diff --git a/gpiodev/gpio-guse.c b/gpiodev/gpio-guse.c
new file mode 100644
index 0000000000000000000000000000000000000000..7e94c825653d42aae6e273acb79d5e9f8eec293c
--- /dev/null
+++ b/gpiodev/gpio-guse.c
@@ -0,0 +1,747 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * QEMU GPIO GUSE based backend.
+ *
+ * Author: 2025 Nikita Shubin <n.shubin@yadro.com>
+ *
+ */
+#include "qemu/osdep.h"
+#include "qemu/module.h"
+#include "qemu/option.h"
+#include "qemu/log.h"
+#include "qemu/lockable.h"
+#include "qapi/error.h"
+#include "gpiodev/gpio.h"
+#include "chardev/char.h"
+#include "chardev/char-fe.h"
+
+#define FUSE_USE_VERSION            31
+#include <fuse.h>
+#include <fuse_lowlevel.h>
+#include <guse_lowlevel.h>
+#undef FUSE_USE_VERSION
+
+#include <poll.h>
+#include <linux/gpio.h>
+
+#define GUSE_DEVICE_INODE_FLAG      BIT_ULL(63)
+#define GUSE_MAX_WATCH              64
+#define GUSE_MAX_EVENTS             64
+
+typedef struct GusedevLineWatch {
+    uint64_t i_node;
+    struct fuse_pollhandle *ph;
+
+    /* since we can have multiply requests per device we need own masks */
+    struct {
+        unsigned long risen;
+        unsigned long fallen;
+
+        /* special for GPIO_V2_LINE_FLAG_OUTPUT */
+        unsigned long mask;
+    } mask;
+
+    /* required to match mask with actual offsets */
+    uint32_t num_lines;
+    uint32_t offsets[GPIO_V2_LINES_MAX];
+
+    QemuMutex event_lock;
+    uint32_t num_events;
+    struct gpio_v2_line_event events[GUSE_MAX_EVENTS];
+
+    QSIMPLEQ_ENTRY(GusedevLineWatch) next;
+} GusedevLineWatch;
+
+typedef struct GusedevConfigWatch {
+    uint64_t i_node;
+    struct fuse_pollhandle *ph;
+
+    unsigned long *mask;
+
+    uint32_t num_events;
+    struct gpio_v2_line_info_changed events[GUSE_MAX_EVENTS];
+    QSIMPLEQ_ENTRY(GusedevConfigWatch) next;
+} GusedevConfigWatch;
+
+typedef struct GusedevGpiodev {
+    Gpiodev parent;
+
+    char *devname;
+    struct fuse_session *fuse_session;
+    struct fuse_buf fuse_buf;
+
+    QemuMutex linereq_lock;
+    QSIMPLEQ_HEAD(, GusedevLineWatch) linereq;
+
+    QemuMutex configreq_lock;
+    QSIMPLEQ_HEAD(, GusedevConfigWatch) configreq;
+} GusedevGpiodev;
+
+DECLARE_INSTANCE_CHECKER(GusedevGpiodev, GPIODEV_GUSEDEV,
+                         TYPE_GPIODEV_GUSEDEV)
+
+static GusedevLineWatch *gpio_gusedev_find_linereq(GusedevGpiodev *d, uint64_t i_node)
+{
+    GusedevLineWatch *e;
+
+    QSIMPLEQ_FOREACH(e, &d->linereq, next) {
+        if (e->i_node == i_node) {
+            return e;
+        }
+    }
+
+    return NULL;
+}
+
+static GusedevLineWatch *gpio_gusedev_allocate_linereq(GusedevGpiodev *d, uint64_t i_node)
+{
+    GusedevLineWatch *e = g_new0(GusedevLineWatch, 1);
+
+    e->i_node = i_node;
+
+    QSIMPLEQ_INSERT_TAIL(&d->linereq, e, next);
+
+    return e;
+}
+
+static void gpio_gusedev_free_linereq(GusedevGpiodev *d, GusedevLineWatch *w)
+{
+    GusedevLineWatch *entry, *next;
+
+    QSIMPLEQ_FOREACH_SAFE(entry, &d->linereq, next, next) {
+        if (entry->i_node == w->i_node) {
+            QSIMPLEQ_REMOVE(&d->linereq, entry, GusedevLineWatch, next);
+            if (entry->ph) {
+                fuse_pollhandle_destroy(entry->ph);
+            }
+            g_free(entry);
+        }
+    }
+}
+
+static GusedevConfigWatch *gpio_gusedev_find_configreq(GusedevGpiodev *d, uint64_t i_node)
+{
+    GusedevConfigWatch *e;
+
+    QSIMPLEQ_FOREACH(e, &d->configreq, next) {
+        if (e->i_node == i_node) {
+            return e;
+        }
+    }
+
+    return NULL;
+}
+
+static GusedevConfigWatch *gpio_gusedev_allocate_configreq(GusedevGpiodev *d,
+                                                           uint64_t i_node)
+{
+    GusedevConfigWatch *e = g_new0(GusedevConfigWatch, 1);
+
+    e->i_node = i_node;
+    e->mask = bitmap_new(d->parent.lines);
+
+    QSIMPLEQ_INSERT_TAIL(&d->configreq, e, next);
+
+    return e;
+}
+
+static void gpio_gusedev_free_configreq(GusedevGpiodev *d,
+                                        GusedevConfigWatch *w)
+{
+    GusedevConfigWatch *entry, *next;
+
+    QSIMPLEQ_FOREACH_SAFE(entry, &d->configreq, next, next) {
+        if (entry->i_node == w->i_node) {
+            QSIMPLEQ_REMOVE(&d->configreq, entry, GusedevConfigWatch, next);
+            if (entry->ph) {
+                fuse_pollhandle_destroy(entry->ph);
+            }
+            g_free(entry->mask);
+            g_free(entry);
+        }
+    }
+}
+
+static inline uint64_t timespec_to_ns(struct timespec ts)
+{
+    return (uint64_t)ts.tv_nsec + 1000000000ULL * (uint64_t)ts.tv_sec;
+}
+
+static void gpio_gusedev_push_config(GusedevGpiodev *d, uint32_t offset,
+                                     enum gpio_v2_line_changed_type event)
+{
+    GusedevConfigWatch *e;
+    struct timespec ts;
+    uint64_t ts_ns;
+
+    timespec_get(&ts, TIME_UTC);
+    ts_ns = timespec_to_ns(ts);
+
+    QEMU_LOCK_GUARD(&d->configreq_lock);
+    QSIMPLEQ_FOREACH(e, &d->configreq, next) {
+        if (test_bit(offset, e->mask)) {
+            struct gpio_v2_line_info_changed *changed;
+            uint32_t num_events = e->num_events;
+            if (++num_events > GUSE_MAX_EVENTS) {
+                qemu_log_mask(LOG_GUEST_ERROR, "%s: max config events number exeeded\n",
+                          __func__);
+                continue;
+            }
+
+            changed = &e->events[e->num_events];
+            changed->timestamp_ns = ts_ns;
+            changed->event_type = event;
+            changed->info.offset = offset;
+
+            e->num_events = num_events;
+
+            if (e->ph) {
+                fuse_notify_poll(e->ph);
+                fuse_pollhandle_destroy(e->ph);
+                e->ph = NULL;
+            }
+        }
+    }
+}
+
+static void gpio_gusedev_push_event(GusedevGpiodev *d, uint32_t offset,
+                                    enum gpio_v2_line_event_id event)
+{
+    GusedevLineWatch *e;
+    struct timespec ts;
+    uint64_t ts_ns;
+
+    timespec_get(&ts, TIME_UTC);
+    ts_ns = timespec_to_ns(ts);
+
+    QEMU_LOCK_GUARD(&d->linereq_lock);
+    QSIMPLEQ_FOREACH(e, &d->linereq, next) {
+        bool notify = false;
+        if ((event & GPIO_V2_LINE_EVENT_RISING_EDGE)
+            && test_bit(offset, &e->mask.risen)) {
+            notify = true;
+        }
+
+        if ((event & GPIO_V2_LINE_EVENT_FALLING_EDGE)
+            && test_bit(offset, &e->mask.fallen)) {
+            notify = true;
+        }
+
+        if (notify) {
+            struct gpio_v2_line_event *info;
+            uint32_t num_events = e->num_events;
+            if (++num_events > GUSE_MAX_EVENTS) {
+                qemu_log_mask(LOG_GUEST_ERROR, "%s: max config events number exeeded\n",
+                          __func__);
+                continue;
+            }
+
+            info = &e->events[e->num_events];
+            info->timestamp_ns = ts_ns;
+            info->id = event;
+            info->offset = offset;
+
+            e->num_events = num_events;
+
+            if (e->ph) {
+                fuse_notify_poll(e->ph);
+                fuse_pollhandle_destroy(e->ph);
+                e->ph = NULL;
+            }
+        }
+    }
+}
+
+static void gpio_gusedev_line_event(Gpiodev *g, uint32_t offset,
+                                    QEMUGpioLineEvent event)
+{
+    GusedevGpiodev *d = GPIODEV_GUSEDEV(g);
+
+    gpio_gusedev_push_event(d, offset, (enum gpio_v2_line_event_id)event);
+}
+
+static void gpio_gusedev_config_event(Gpiodev *g, uint32_t offset,
+                                      QEMUGpioConfigEvent event)
+{
+    GusedevGpiodev *d = GPIODEV_GUSEDEV(g);
+
+    gpio_gusedev_push_config(d, offset, (enum gpio_v2_line_changed_type)event);
+}
+
+static void gusedev_init(void *userdata, struct fuse_conn_info *conn)
+{
+    (void)userdata;
+
+    /* Disable the receiving and processing of FUSE_INTERRUPT requests */
+    conn->no_interrupt = 1;
+}
+
+static void gusedev_destroy(void *private_data)
+{
+    (void)private_data;
+}
+
+static void gusedev_open(fuse_req_t req, fuse_ino_t ino,
+                         struct fuse_file_info *fi)
+{
+    fuse_reply_open(req, fi);
+}
+
+static void gusedev_release(fuse_req_t req, fuse_ino_t ino,
+                            struct fuse_file_info *fi)
+{
+    GusedevGpiodev *d = fuse_req_userdata(req);
+
+    if (ino & GUSE_DEVICE_INODE_FLAG) {
+        GusedevConfigWatch *e;
+
+        e = gpio_gusedev_find_configreq(d, ino);
+        if (e) {
+            gpio_gusedev_free_configreq(d, e);
+        }
+    } else {
+        GusedevLineWatch *e;
+
+        e = gpio_gusedev_find_linereq(d, ino);
+        if (e) {
+            gpio_gusedev_free_linereq(d, e);
+        }
+    }
+
+    fuse_reply_err(req, 0);
+}
+
+static void gusedev_read(fuse_req_t req, fuse_ino_t ino, size_t size, off_t off,
+                         struct fuse_file_info *fi)
+{
+    GusedevGpiodev *d = fuse_req_userdata(req);
+
+    if (ino & GUSE_DEVICE_INODE_FLAG) {
+        GusedevConfigWatch *e;
+
+        e = gpio_gusedev_find_configreq(d, ino);
+        if (e && e->num_events) {
+            fuse_reply_buf(req, (char *)&e->events, sizeof(e->events[0]) * e->num_events);
+            e->num_events = 0;
+            return;
+        }
+    } else {
+        GusedevLineWatch *e;
+
+        e = gpio_gusedev_find_linereq(d, ino);
+        if (e && e->num_events) {
+            fuse_reply_buf(req, (char *)&e->events, sizeof(e->events[0]) * e->num_events);
+            e->num_events = 0;
+            return;
+        }
+    }
+
+    fuse_reply_buf(req, NULL, 0);
+}
+
+static void gusedev_poll_config(fuse_req_t req, fuse_ino_t ino, struct fuse_file_info *fi,
+                                struct fuse_pollhandle *ph)
+{
+    GusedevGpiodev *d = fuse_req_userdata(req);
+    GusedevConfigWatch *e;
+
+    QEMU_LOCK_GUARD(&d->configreq_lock);
+    e = gpio_gusedev_find_configreq(d, ino);
+    if (!e) {
+        fuse_reply_poll(req, POLLERR);
+        return;
+    }
+
+    if (ph) {
+        if (e->ph) {
+            fuse_pollhandle_destroy(e->ph);
+        }
+
+        e->ph = ph;
+    }
+
+    if (e->num_events) {
+        fuse_reply_poll(req, POLLIN);
+    } else {
+        fuse_reply_poll(req, 0);
+    }
+}
+
+static void gusedev_poll_line(fuse_req_t req, fuse_ino_t ino, struct fuse_file_info *fi,
+                                struct fuse_pollhandle *ph)
+{
+    GusedevGpiodev *d = fuse_req_userdata(req);
+    GusedevLineWatch *e;
+
+    QEMU_LOCK_GUARD(&d->linereq_lock);
+    e = gpio_gusedev_find_linereq(d, ino);
+    if (!e) {
+        fuse_reply_poll(req, POLLERR);
+        return;
+    }
+
+    if (ph) {
+        if (e->ph) {
+            fuse_pollhandle_destroy(e->ph);
+        }
+
+        e->ph = ph;
+    }
+
+    if (e->num_events) {
+        fuse_reply_poll(req, POLLIN);
+    } else {
+        fuse_reply_poll(req, 0);
+    }
+}
+
+static void gusedev_poll(fuse_req_t req, fuse_ino_t ino, struct fuse_file_info *fi,
+                         struct fuse_pollhandle *ph)
+{
+    if (ino & GUSE_DEVICE_INODE_FLAG) {
+        gusedev_poll_config(req, ino, fi, ph);
+    } else {
+        gusedev_poll_line(req, ino, fi, ph);
+    }
+}
+
+static int gusedev_chipinfo(fuse_req_t req)
+{
+    GusedevGpiodev *d = fuse_req_userdata(req);
+    struct gpiochip_info info = { 0 };
+
+    qemu_gpio_chip_info(&d->parent, &info.lines, info.name, info.label);
+
+    return fuse_reply_ioctl(req, 0, &info, sizeof(info));
+}
+
+static int gusedev_lineinfo(fuse_req_t req, const void *in_buf)
+{
+    struct gpio_v2_line_info *in = (struct gpio_v2_line_info *)in_buf;
+    GusedevGpiodev *d = fuse_req_userdata(req);
+    struct gpio_v2_line_info reply = { 0 };
+    uint32_t offset = in->offset;
+    gpio_line_info info = { 0 };
+
+    if (offset > d->parent.lines) {
+        return fuse_reply_err(req, EINVAL);
+    }
+
+    info.offset = offset;
+    qemu_gpio_line_info(&d->parent, &info);
+    g_strlcpy(reply.name, info.name, GPIO_MAX_NAME_SIZE);
+    reply.flags = info.flags;
+
+    return fuse_reply_ioctl(req, 0, &reply, sizeof(reply));
+}
+
+static int gusedev_linerequest(fuse_req_t req, fuse_ino_t ino,
+                               const void *in_buf)
+{
+    struct gpio_v2_line_request *in = (struct gpio_v2_line_request *)in_buf;
+    GusedevGpiodev *d = fuse_req_userdata(req);
+    struct gpio_v2_line_request reply;
+    GusedevLineWatch *watch;
+    int i;
+
+    /* line request not available for device inode */
+    if (ino & GUSE_DEVICE_INODE_FLAG) {
+        return fuse_reply_err(req, EINVAL);
+    }
+
+    watch = gpio_gusedev_allocate_linereq(d, ino);
+    if (!watch) {
+        return fuse_reply_err(req, ENOMEM);
+    }
+
+    for (i = 0; i < in->num_lines; i++) {
+        bool notify = false;
+
+        if (in->config.flags & GPIO_V2_LINE_FLAG_INPUT) {
+            if (in->config.flags & GPIO_V2_LINE_FLAG_EDGE_RISING) {
+                watch->mask.risen |= BIT_ULL(in->offsets[i]);
+                qemu_gpio_add_event_watch(&d->parent, in->offsets[i],
+                                          GPIO_EVENT_RISING_EDGE);
+                notify = true;
+            }
+
+            if (in->config.flags & GPIO_V2_LINE_FLAG_EDGE_FALLING) {
+                watch->mask.fallen |= BIT_ULL(in->offsets[i]);
+                qemu_gpio_add_event_watch(&d->parent, in->offsets[i],
+                                          GPIO_EVENT_FALLING_EDGE);
+                notify = true;
+            }
+        /* TODO: check if lines are input and don't allow to change direction */
+        } else if (in->config.flags & GPIO_V2_LINE_FLAG_OUTPUT) {
+            watch->mask.mask |= BIT_ULL(in->offsets[i]);
+        }
+
+        /* dispatch config change event */
+        if (notify) {
+            gpio_gusedev_push_config(d, in->offsets[i],
+                                     GPIO_V2_LINE_CHANGED_REQUESTED);
+        }
+    }
+
+    memcpy(&reply, in_buf, sizeof(reply));
+
+    return fuse_reply_ioctl(req, 0, &reply, sizeof(reply));
+}
+
+static int gusedev_get_line_values(fuse_req_t req, fuse_ino_t ino,
+                                   const void *in_buf)
+{
+    struct gpio_v2_line_values *values = (struct gpio_v2_line_values *)in_buf;
+    GusedevGpiodev *d = fuse_req_userdata(req);
+    struct gpio_v2_line_values reply = { 0 };
+    GusedevLineWatch *e;
+    int idx;
+
+    e = gpio_gusedev_find_linereq(d, ino);
+    if (!e) {
+        return fuse_reply_err(req, EINVAL);
+    }
+
+    idx = find_first_bit((unsigned long *)values->mask, e->num_lines);
+    while (idx < e->num_lines) {
+        reply.bits |= qemu_gpio_get_line_value(&d->parent, e->offsets[idx]);
+        idx = find_next_bit((unsigned long *)values->mask, e->num_lines, idx + 1);
+    }
+
+    reply.mask = values->mask;
+
+    return fuse_reply_ioctl(req, 0, &reply, sizeof(reply));
+}
+
+/* TODO: merge with gusedev_set_line_values() */
+static int gusedev_set_line_values(fuse_req_t req, fuse_ino_t ino,
+                                   const void *in_buf)
+{
+    struct gpio_v2_line_values *values = (struct gpio_v2_line_values *)in_buf;
+    GusedevGpiodev *d = fuse_req_userdata(req);
+    struct gpio_v2_line_values reply = { 0 };
+    GusedevLineWatch *e;
+    int idx;
+
+    e = gpio_gusedev_find_linereq(d, ino);
+    if (!e) {
+        return fuse_reply_err(req, EINVAL);
+    }
+
+    idx = find_first_bit((unsigned long *)&values->mask, e->num_lines);
+    while (idx < e->num_lines) {
+        uint8_t bit = test_bit(idx, (unsigned long *)&values->bits);
+        qemu_gpio_set_line_value(&d->parent, e->offsets[idx], bit);
+        idx = find_next_bit((unsigned long *)&values->mask, e->num_lines, idx + 1);
+    }
+
+    reply.bits = values->bits;
+    reply.mask = values->mask;
+
+    return fuse_reply_ioctl(req, 0, &reply, sizeof(reply));
+}
+
+static int gusedev_set_line_watch(fuse_req_t req, fuse_ino_t ino,
+                                  const void *in_buf, bool watch)
+{
+    struct gpio_v2_line_info *info = (struct gpio_v2_line_info *)in_buf;
+    GusedevGpiodev *d = fuse_req_userdata(req);
+    struct gpio_v2_line_info reply = { 0 };
+    GusedevConfigWatch *e;
+
+    e = gpio_gusedev_find_configreq(d, ino);
+
+    /*
+     * If not found allocate it, because unlike linereq configreq is added separately
+     * per each line.
+     */
+    if (!e) {
+        e = gpio_gusedev_allocate_configreq(d, ino);
+    }
+
+    if (watch) {
+        qemu_gpio_add_config_watch(&d->parent, info->offset);
+        set_bit(info->offset, e->mask);
+    } else {
+        qemu_gpio_clear_config_watch(&d->parent, info->offset);
+        clear_bit(info->offset, e->mask);
+    }
+
+    memcpy(&reply, info, sizeof(reply));
+
+    return fuse_reply_ioctl(req, 0, &reply, sizeof(reply));
+}
+
+static void gusedev_ioctl(fuse_req_t req, fuse_ino_t ino, unsigned int cmd,
+                          void *arg, struct fuse_file_info *fi, unsigned flags,
+                          const void *in_buf, size_t in_bufsz, size_t out_bufsz)
+{
+    bool add_watch = false;
+    int ret;
+
+    if (flags & FUSE_IOCTL_COMPAT) {
+        fuse_reply_err(req, ENOSYS);
+        return;
+    }
+
+    switch (cmd) {
+    case GPIO_GET_CHIPINFO_IOCTL:
+        ret = gusedev_chipinfo(req);
+        break;
+    case GPIO_V2_GET_LINEINFO_IOCTL:
+        ret = gusedev_lineinfo(req, in_buf);
+        break;
+    /* GPIO_V2_GET_LINE_IOCTL is also processed by guse module. */
+    case GPIO_V2_GET_LINE_IOCTL:
+        ret = gusedev_linerequest(req, ino, in_buf);
+        break;
+    case GPIO_V2_LINE_GET_VALUES_IOCTL:
+        ret = gusedev_get_line_values(req, ino, in_buf);
+        break;
+    case GPIO_V2_LINE_SET_VALUES_IOCTL:
+        ret = gusedev_set_line_values(req, ino, in_buf);
+        break;
+    case GPIO_V2_GET_LINEINFO_WATCH_IOCTL:
+        add_watch = true;
+        /* fallthrough */
+    case GPIO_GET_LINEINFO_UNWATCH_IOCTL:
+        ret = gusedev_set_line_watch(req, ino, in_buf, add_watch);
+        break;
+    case GPIO_V2_LINE_SET_CONFIG_IOCTL:
+    default:
+        ret = fuse_reply_err(req, EINVAL);
+    }
+
+    if (ret) {
+        qemu_log_mask(LOG_GUEST_ERROR, "gusedev_ioctl() failed with %d\n",
+                      ret);
+    }
+}
+
+static const struct guse_cdev_lowlevel_ops gusedev_glop = {
+    .init       = gusedev_init,
+    .destroy    = gusedev_destroy,
+    .open       = gusedev_open,
+    .release    = gusedev_release,
+    .read       = gusedev_read,
+    .poll       = gusedev_poll,
+    .ioctl      = gusedev_ioctl,
+};
+
+static void read_from_fuse_export(void *opaque)
+{
+    GusedevGpiodev *guse = opaque;
+    int ret;
+
+    do {
+        ret = fuse_session_receive_buf(guse->fuse_session, &guse->fuse_buf);
+    } while (ret == -EINTR);
+
+    if (ret < 0) {
+        return;
+    }
+
+    fuse_session_process_buf(guse->fuse_session, &guse->fuse_buf);
+}
+
+static int setup_guse_export(GusedevGpiodev *guse, Error **errp)
+{
+    char dev_name[128] = "DEVNAME=";
+    const char *dev_info_argv[] = { dev_name };
+    char *curdir = get_current_dir_name();
+    struct fuse_session *session = NULL;
+    const char *argv[3];
+    struct guse_info ci;
+    int multithreaded;
+    AioContext *ctx;
+
+    strncat(dev_name, guse->devname, sizeof(dev_name) - sizeof("DEVNAME="));
+
+    argv[0] = ""; /* Dummy program name */
+    argv[1] = "-d";
+    argv[2] = NULL;
+
+    ci.dev_major = 0;
+    ci.dev_minor = 0;
+    ci.dev_info_argc = 1;
+    ci.dev_info_argv = dev_info_argv;
+
+    session = guse_lowlevel_setup(ARRAY_SIZE(argv) - 1, (char **)argv, &ci, &gusedev_glop,
+                                  &multithreaded, guse);
+    if (session == NULL) {
+        error_setg(errp, "guse_lowlevel_setup failed");
+        errno = EINVAL;
+        return -1;
+    }
+
+    /* FIXME: fuse_daemonize() calls chdir("/") */
+    chdir(curdir);
+    g_free(curdir);
+
+    ctx = iohandler_get_aio_context();
+
+    aio_set_fd_handler(ctx, fuse_session_fd(session),
+                       read_from_fuse_export, NULL,
+                       NULL, NULL, guse);
+
+    guse->fuse_session = session;
+
+    return 0;
+}
+
+static void gpio_gusedev_open(Gpiodev *gpio, GpiodevBackend *backend,
+                              Error **errp)
+{
+    GpiodevGusedev *opts = backend->u.gusedev.data;
+    GusedevGpiodev *d = GPIODEV_GUSEDEV(gpio);
+
+    d->devname = g_strdup(opts->devname);
+
+    QSIMPLEQ_INIT(&d->linereq);
+    QSIMPLEQ_INIT(&d->configreq);
+
+    qemu_mutex_init(&d->linereq_lock);
+    qemu_mutex_init(&d->configreq_lock);
+
+    setup_guse_export(d, errp);
+}
+
+static void gpio_gusedev_parse(QemuOpts *opts, GpiodevBackend *backend,
+                               Error **errp)
+{
+    const char *devname = qemu_opt_get(opts, "devname");
+    /* TODO: add bool debug for fuse debug */
+    GpiodevGusedev *ggusedev;
+
+    if (devname == NULL) {
+        error_setg(errp, "gpiodev: gusedev: no devname given");
+        return;
+    }
+
+    backend->type = GPIODEV_BACKEND_KIND_GUSEDEV;
+    ggusedev = backend->u.gusedev.data = g_new0(GpiodevGusedev, 1);
+    ggusedev->devname = g_strdup(devname);
+}
+
+static void gpio_gusedev_class_init(ObjectClass *oc, void *data)
+{
+    GpiodevClass *cc = GPIODEV_CLASS(oc);
+
+    cc->parse = &gpio_gusedev_parse;
+    cc->open = &gpio_gusedev_open;
+    cc->line_event = &gpio_gusedev_line_event;
+    cc->config_event = &gpio_gusedev_config_event;
+}
+
+static const TypeInfo gpio_gusedev_type_info[] = {
+    {
+        .name = TYPE_GPIODEV_GUSEDEV,
+        .parent = TYPE_GPIODEV,
+        .class_init = gpio_gusedev_class_init,
+        .instance_size = sizeof(GusedevGpiodev),
+        /* .instance_finalize = gpio_gusedev_finalize, */
+    },
+};
+
+DEFINE_TYPES(gpio_gusedev_type_info);
+
diff --git a/gpiodev/meson.build b/gpiodev/meson.build
index 64d3abb4e3d72cba0c26b665515a0f97e82fb5d9..32eae1c3f8bc856e8b7f4a4bb49d796147f59da7 100644
--- a/gpiodev/meson.build
+++ b/gpiodev/meson.build
@@ -4,4 +4,5 @@ gpiodev_ss.add(files(
   'gpio.c',
 ))
 
+gpiodev_ss.add(when: fuse, if_true: files('gpio-guse.c'))
 gpiodev_ss = gpiodev_ss.apply({})
diff --git a/include/gpiodev/gpio.h b/include/gpiodev/gpio.h
index a34d805ccc0bf5a25986b118dcc0b2cc0a55572c..d3b95410d3a570480d187354ad384f9a23b102e6 100644
--- a/include/gpiodev/gpio.h
+++ b/include/gpiodev/gpio.h
@@ -56,6 +56,7 @@ struct Gpiodev {
 OBJECT_DECLARE_TYPE(Gpiodev, GpiodevClass, GPIODEV)
 
 #define TYPE_GPIODEV_CHARDEV "gpiodev-chardev"
+#define TYPE_GPIODEV_GUSEDEV "gpiodev-guse"
 
 struct GpiodevClass {
     ObjectClass parent_class;
diff --git a/qapi/gpio.json b/qapi/gpio.json
index 1c2b7af36813ff52cbb3a44e64a2e5a5d8658d62..e3cdca793260212622a30947eaea61bd523e98fb 100644
--- a/qapi/gpio.json
+++ b/qapi/gpio.json
@@ -21,12 +21,36 @@
 ##
 # @GpiodevBackendKind:
 #
-# @chardev: chardevs
+# @chardev: Gpio dev over chardev backend
+# @gusedev: Gpio dev over GUSE FUSE module
 #
 # Since: 9.2
 ##
 { 'enum': 'GpiodevBackendKind',
-  'data': [ 'chardev' ] }
+  'data': [ 'chardev',
+            { 'name': 'gusedev', 'if': 'CONFIG_LINUX' } ] }
+
+##
+# @GpiodevGusedev:
+#
+# Configuration info for guse gpiodevs.
+#
+# @devname: Name of device created in /dev
+#
+# Since: 9.2
+##
+  { 'struct': 'GpiodevGusedev',
+    'data': { 'devname': 'str' } }
+
+##
+# @GpiodevGusedevWrapper:
+#
+# @data: Configuration info for chardev gpiodevs
+#
+# Since: 9.2
+##
+{ 'struct': 'GpiodevGusedevWrapper',
+  'data': { 'data': 'GpiodevGusedev' } }
 
 ##
 # @GpiodevChardev:
@@ -65,4 +89,5 @@
 { 'union': 'GpiodevBackend',
   'base': { 'type': 'GpiodevBackendKind' },
   'discriminator': 'type',
-  'data': { 'chardev': 'GpiodevChardevWrapper' } }
\ No newline at end of file
+  'data': { 'chardev': 'GpiodevChardevWrapper',
+            'gusedev': { 'type': 'GpiodevGusedevWrapper', 'if': 'CONFIG_LINUX' } } }
\ No newline at end of file

-- 
2.45.2

