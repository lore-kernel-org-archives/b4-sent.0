From: Nikita Shubin <n.shubin@yadro.com>
Date: Wed, 19 Mar 2025 10:57:54 +0300
Subject: [PATCH PoC 4/7] gpiodev: Add GPIO backend over chardev
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-gpiodev-v1-4-76da4e5800a1@yadro.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742371072; l=15807;
 i=n.shubin@yadro.com; s=20230718; h=from:subject:message-id;
 bh=5SgTiI0ydbYQARFNJTO+9VhaH4GQhgG0X6FDQsOgxCo=;
 b=9UpynEdIOObCM9wieZowdBFdaPH5tLSl2huhFW0MjhsIL4vTt/GqRF9PZSLNt+7QTe7rBaPXK
 gqh9X9ChwduD8EL+yS8gtXzsMSASjOhgpMTc1jo44g41GzGMqEEDMAN
X-Developer-Key: i=n.shubin@yadro.com; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for n.shubin@yadro.com/20230718 with auth_id=161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently based on passing linux GPIO UAPI structs over
UNIX socket.

This is more a PoC than a real application, still this is something to
start with.

Signed-off-by: Nikita Shubin <n.shubin@yadro.com>
---
 gpiodev/gpio-chardev.c | 479 +++++++++++++++++++++++++++++++++++++++++++++++++
 gpiodev/meson.build    |   1 +
 include/gpiodev/gpio.h |   2 +
 3 files changed, 482 insertions(+)

diff --git a/gpiodev/gpio-chardev.c b/gpiodev/gpio-chardev.c
new file mode 100644
index 0000000000000000000000000000000000000000..5c2ae0373e6b447ea17ee08eacdcb12fbaa13a9c
--- /dev/null
+++ b/gpiodev/gpio-chardev.c
@@ -0,0 +1,479 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * QEMU GPIO Chardev based backend.
+ *
+ * Author: 2025 Nikita Shubin <n.shubin@yadro.com>
+ *
+ */
+#include "qemu/osdep.h"
+#include "qemu/module.h"
+#include "qemu/option.h"
+#include "qemu/log.h"
+#include "qapi/error.h"
+#include "gpiodev/gpio.h"
+#include "chardev/char.h"
+#include "chardev/char-fe.h"
+
+#include <linux/gpio.h>
+
+/* Taken from include/linux/circ_buf.h */
+
+/*
+ * Return count in buffer.
+ */
+#define CIRC_CNT(head, tail, size) (((head) - (tail)) & ((size) - 1))
+
+/*
+ * Return space available, 0..size-1.  We always leave one free char
+ * as a completely full buffer has head == tail, which is the same as
+ * empty.
+ */
+#define CIRC_SPACE(head, tail, size) CIRC_CNT((tail), ((head) + 1), (size))
+
+/*
+ * Return count up to the end of the buffer.  Carefully avoid
+ * accessing head and tail more than once, so they can change
+ * underneath us without returning inconsistent results.
+ */
+#define CIRC_CNT_TO_END(head, tail, size) \
+        ({int end = (size) - (tail); \
+          int n = ((head) + end) & ((size) - 1); \
+          n < end ? n : end; })
+
+/*
+ * Return space available up to the end of the buffer.
+ */
+#define CIRC_SPACE_TO_END(head, tail, size) \
+        ({int end = (size) - 1 - (head); \
+          int n = (end + (tail)) & ((size) - 1); \
+          n <= end ? n : end + 1; })
+
+
+typedef struct ChardevGpiodev {
+    Gpiodev parent;
+
+    CharBackend chardev;
+    size_t size;
+    size_t prod;
+    size_t cons;
+    uint8_t *cbuf;
+
+    struct gpio_v2_line_request last_request;
+    uint64_t mask;
+} ChardevGpiodev;
+
+DECLARE_INSTANCE_CHECKER(ChardevGpiodev, GPIODEV_CHARDEV,
+                         TYPE_GPIODEV_CHARDEV)
+
+static void gpio_chardev_line_event(Gpiodev *g, uint32_t offset,
+                                    QEMUGpioLineEvent event)
+{
+    ChardevGpiodev *d = GPIODEV_CHARDEV(g);
+    struct gpio_v2_line_event changed = { 0 };
+    int ret;
+
+    changed.timestamp_ns = qemu_clock_get_ns(QEMU_CLOCK_VIRTUAL);
+    changed.id = event;
+    changed.offset = offset;
+
+    ret = qemu_chr_fe_write(&d->chardev, (uint8_t *)&changed, sizeof(changed));
+    if (ret != sizeof(changed)) {
+        qemu_log_mask(LOG_GUEST_ERROR, "%s: failed writing %d bytes\n",
+                                       __func__, ret);
+    }
+}
+
+static void gpio_chardev_config_event(Gpiodev *g, uint32_t offset,
+                                      QEMUGpioConfigEvent event)
+{
+    ChardevGpiodev *d = GPIODEV_CHARDEV(g);
+    struct gpio_v2_line_info_changed changed = { 0 };
+    int ret;
+
+    changed.timestamp_ns = qemu_clock_get_ns(QEMU_CLOCK_VIRTUAL);
+    changed.event_type = event;
+    changed.info.offset = offset;
+
+    ret = qemu_chr_fe_write(&d->chardev, (uint8_t *)&changed, sizeof(changed));
+    if (ret != sizeof(changed)) {
+        qemu_log_mask(LOG_GUEST_ERROR, "%s: failed writing %d bytes\n",
+                                       __func__, ret);
+    }
+}
+
+static int gpio_chardev_can_read(void *opaque)
+{
+    ChardevGpiodev *s = GPIODEV_CHARDEV(opaque);
+
+    return CIRC_SPACE(s->prod, s->cons, s->size);
+}
+
+static int gpio_chardev_send_chip_info(ChardevGpiodev *d)
+{
+    struct gpiochip_info info = { 0 };
+    int ret;
+
+    qemu_gpio_chip_info(&d->parent, &info.lines, info.name, info.label);
+    ret = qemu_chr_fe_write(&d->chardev, (uint8_t *)&info, sizeof(info));
+    if (ret != sizeof(info)) {
+        qemu_log_mask(LOG_GUEST_ERROR,
+                      "%s: failed writing %d bytes\n",
+                      __func__, ret);
+    }
+
+    return 8;
+}
+
+static int gpio_chardev_unwatch_line(ChardevGpiodev *d, const uint8_t *buf,
+                                     size_t len)
+{
+    uint32_t offset;
+
+    memcpy(&offset, &buf[8], sizeof(offset));
+    qemu_gpio_clear_event_watch(&d->parent, offset, -1ULL);
+
+    return 8 + 4;
+}
+
+static int gpio_chardev_send_line_info(ChardevGpiodev *d, const uint8_t *buf,
+                                       size_t len)
+{
+    struct gpio_v2_line_info info = { 0 };
+    gpio_line_info req = { 0 };
+    int ret;
+
+    if (len < sizeof(info) + 8) {
+        return -EAGAIN;
+    }
+
+    memcpy(&info, &buf[8], sizeof(info));
+    req.offset = info.offset;
+    qemu_gpio_line_info(&d->parent, &req);
+
+    g_strlcpy(info.name, req.name, GPIO_MAX_NAME_SIZE);
+    info.flags = req.flags;
+
+    ret = qemu_chr_fe_write(&d->chardev, (uint8_t *)&info, sizeof(info));
+    if (ret != sizeof(info)) {
+        qemu_log_mask(LOG_GUEST_ERROR, "%s: failed writing %d bytes\n",
+                      __func__, ret);
+    }
+
+    return sizeof(info) + 8;
+}
+
+static int gpio_chardev_line_watch(ChardevGpiodev *d, const uint8_t *buf,
+                                   size_t len)
+{
+    struct gpio_v2_line_info info = { 0 };
+    int ret;
+
+    if (len < sizeof(info) + 8) {
+        return -EAGAIN;
+    }
+
+    memcpy(&info, &buf[8], sizeof(info));
+    qemu_gpio_add_config_watch(&d->parent, info.offset);
+
+    ret = qemu_chr_fe_write(&d->chardev, (uint8_t *)&info, sizeof(info));
+    if (ret != sizeof(info)) {
+        qemu_log_mask(LOG_GUEST_ERROR, "%s: failed writing %d bytes\n",
+                      __func__, ret);
+    }
+
+    return sizeof(info) + 8;
+}
+
+static uint64_t gpio_chardev_get_flags(const struct gpio_v2_line_request *request)
+{
+    uint64_t req_flags = request->config.flags;
+    uint64_t flags = 0;
+
+    if (req_flags & GPIO_V2_LINE_FLAG_EDGE_RISING) {
+        flags |= GPIO_EVENT_RISING_EDGE;
+    }
+
+    if (req_flags & GPIO_V2_LINE_FLAG_EDGE_FALLING) {
+        flags |= GPIO_EVENT_FALLING_EDGE;
+    }
+
+    return flags;
+}
+
+static int gpio_chardev_line_request(ChardevGpiodev *d, const uint8_t *buf,
+                                     size_t len)
+{
+    struct gpio_v2_line_request *req = &d->last_request;
+    uint64_t flags;
+    int ret, i;
+
+    if (len < sizeof(*req) + 8) {
+        return -EAGAIN;
+    }
+
+    /* unwatch lines before proccessing new request */
+    d->mask = 0;
+    for (i = 0; i < req->num_lines; i++) {
+        qemu_gpio_clear_event_watch(&d->parent, req->offsets[i], -1ULL);
+    }
+
+    memcpy(req, &buf[8], sizeof(*req));
+    flags = gpio_chardev_get_flags(req);
+    for (i = 0; i < req->num_lines; i++) {
+        qemu_gpio_add_event_watch(&d->parent, req->offsets[i], flags);
+        d->mask |= BIT_ULL(req->offsets[i]);
+    }
+
+    ret = qemu_chr_fe_write(&d->chardev, (uint8_t *)req, sizeof(*req));
+    if (ret != sizeof(*req)) {
+        qemu_log_mask(LOG_GUEST_ERROR, "%s: failed writing %d bytes\n",
+                      __func__, ret);
+    }
+
+    return sizeof(*req) + 8;
+}
+
+static int gpio_chardev_get_line_values(ChardevGpiodev *d, const uint8_t *buf,
+                                        size_t len)
+{
+    struct gpio_v2_line_request *req = &d->last_request;
+    struct gpio_v2_line_values values = { 0 };
+    int ret, idx;
+
+    if (len < (sizeof(values) + 8)) {
+        return -EAGAIN;
+    }
+
+    memcpy(&values, &buf[8], sizeof(values));
+    idx = find_first_bit((unsigned long *)&values.mask, req->num_lines);
+    while (idx < req->num_lines) {
+        values.bits |= qemu_gpio_get_line_value(&d->parent, req->offsets[idx]);
+        idx = find_next_bit((unsigned long *)&values.mask, req->num_lines, idx + 1);
+    }
+
+    ret = qemu_chr_fe_write(&d->chardev, (uint8_t *)&values, sizeof(values));
+    if (ret != sizeof(values)) {
+        qemu_log_mask(LOG_GUEST_ERROR, "%s: failed writing %d bytes\n",
+                      __func__, ret);
+    }
+
+    return sizeof(values) + 8;
+}
+
+static int gpio_chardev_set_line_values(ChardevGpiodev *d, const uint8_t *buf,
+                                        size_t len)
+{
+    struct gpio_v2_line_request *req = &d->last_request;
+    struct gpio_v2_line_values values = { 0 };
+    int ret, idx;
+
+    if (len < sizeof(values) + 8) {
+        return -EAGAIN;
+    }
+
+    memcpy(&values, &buf[8], sizeof(values));
+    idx = find_first_bit((unsigned long *)&values.mask, req->num_lines);
+    while (idx < req->num_lines) {
+        qemu_gpio_set_line_value(&d->parent, req->offsets[idx],
+                                 test_bit(idx, (unsigned long *)&values.bits));
+        idx = find_next_bit((unsigned long *)&values.mask, req->num_lines, idx + 1);
+    }
+
+    ret = qemu_chr_fe_write(&d->chardev, (uint8_t *)&values, sizeof(values));
+    if (ret != sizeof(values)) {
+        qemu_log_mask(LOG_GUEST_ERROR, "%s: failed writing %d bytes\n",
+                      __func__, ret);
+    }
+
+    return sizeof(values) + 8;
+}
+
+static int gpio_chardev_consume_one(ChardevGpiodev *d, const uint8_t *buf,
+                                    size_t len)
+{
+    unsigned long ctl;
+    int ret;
+
+    if (len < 8) {
+        return -EAGAIN;
+    }
+
+    memcpy(&ctl, buf, 8);
+    switch (ctl) {
+    case GPIO_GET_CHIPINFO_IOCTL:
+        ret = gpio_chardev_send_chip_info(d);
+        break;
+    case GPIO_GET_LINEINFO_UNWATCH_IOCTL:
+        ret = gpio_chardev_unwatch_line(d, buf, len);
+        break;
+    case GPIO_V2_GET_LINEINFO_IOCTL:
+        ret = gpio_chardev_send_line_info(d, buf, len);
+        break;
+    case GPIO_V2_GET_LINEINFO_WATCH_IOCTL:
+        ret = gpio_chardev_line_watch(d, buf, len);
+        break;
+    case GPIO_V2_GET_LINE_IOCTL:
+        ret = gpio_chardev_line_request(d, buf, len);
+        break;
+    case GPIO_V2_LINE_GET_VALUES_IOCTL:
+        ret = gpio_chardev_get_line_values(d, buf, len);
+        break;
+    case GPIO_V2_LINE_SET_VALUES_IOCTL:
+        ret = gpio_chardev_set_line_values(d, buf, len);
+        break;
+    case GPIO_V2_LINE_SET_CONFIG_IOCTL:
+    default:
+        qemu_log_mask(LOG_GUEST_ERROR, "%s: unknow ctl=%lx\n",
+                        __func__, ctl);
+        return -EINVAL;
+    };
+
+    return ret;
+}
+
+static void gpio_chardev_consume(ChardevGpiodev *d, size_t len)
+{
+    g_autofree guint8 *buf;
+    size_t t_cons = d->cons;
+    int i, ret, pos = 0;
+    size_t left = len;
+
+    buf = g_malloc(len);
+
+    for (i = 0; i < len && t_cons != d->prod; i++) {
+        buf[i] = d->cbuf[t_cons++ & (d->size - 1)];
+    }
+
+    do {
+        ret = gpio_chardev_consume_one(d, &buf[pos], left);
+        if (ret > 0) {
+            left -= ret;
+            pos += ret;
+        }
+    } while (ret > 0);
+
+    /* advance */
+    d->cons += pos;
+    qemu_chr_fe_accept_input(&d->chardev);
+}
+
+static void gpio_chardev_read(void *opaque, const uint8_t *buf, int len)
+{
+    ChardevGpiodev *d = GPIODEV_CHARDEV(opaque);
+    int i;
+
+    if (!buf || (len < 0)) {
+        return;
+    }
+
+    for (i = 0; i < len; i++) {
+        d->cbuf[d->prod++ & (d->size - 1)] = buf[i];
+        if (d->prod - d->cons > d->size) {
+            d->cons = d->prod - d->size;
+        }
+    }
+
+    gpio_chardev_consume(d, CIRC_CNT(d->prod, d->cons, d->size));
+}
+
+static void gpio_chardev_event(void *opaque, QEMUChrEvent event)
+{
+    ChardevGpiodev *d = GPIODEV_CHARDEV(opaque);
+
+    if (event == CHR_EVENT_OPENED) {
+        d->prod = 0;
+        d->cons = 0;
+
+        /* remove watches */
+        qemu_gpio_clear_watches(&d->parent);
+    }
+}
+
+static void gpio_chardev_open(Gpiodev *gpio, GpiodevBackend *backend,
+                              Error **errp)
+{
+    GpiodevChardev *opts = backend->u.chardev.data;
+    ChardevGpiodev *d = GPIODEV_CHARDEV(gpio);
+    Object *chr_backend;
+    Chardev *chr = NULL;
+
+    d->size = opts->has_size ? opts->size : 65536;
+
+    /* The size must be power of 2 */
+    if (d->size & (d->size - 1)) {
+        error_setg(errp, "size of ringbuf chardev must be power of two");
+        return;
+    }
+
+    chr_backend = object_resolve_path_type(opts->chardev, TYPE_CHARDEV, NULL);
+    if (chr_backend) {
+        qemu_log_mask(LOG_GUEST_ERROR, "%s: %s got backend\n",
+                      __func__, opts->chardev);
+        chr = qemu_chr_find(opts->chardev);
+    }
+
+    if (!chr) {
+        error_setg(errp, "gpiodev: chardev: no chardev %s not found", opts->chardev);
+        return;
+    }
+
+    d->cbuf = g_malloc0(d->size);
+
+    qemu_chr_fe_init(&d->chardev, chr, NULL);
+    qemu_chr_fe_set_handlers(&d->chardev,
+                             gpio_chardev_can_read,
+                             gpio_chardev_read,
+                             gpio_chardev_event, NULL, d, NULL, true);
+}
+
+static void gpio_chardev_parse(QemuOpts *opts, GpiodevBackend *backend,
+                               Error **errp)
+{
+    const char *chardev = qemu_opt_get(opts, "chardev");
+    GpiodevChardev *gchardev;
+    int val;
+
+    if (chardev == NULL) {
+        error_setg(errp, "gpiodev: chardev: no chardev id given");
+        return;
+    }
+
+    backend->type = GPIODEV_BACKEND_KIND_CHARDEV;
+    gchardev = backend->u.chardev.data = g_new0(GpiodevChardev, 1);
+    val = qemu_opt_get_size(opts, "size", 0);
+    if (val != 0) {
+        gchardev->has_size = true;
+        gchardev->size = val;
+    }
+    gchardev->chardev = g_strdup(chardev);
+}
+
+static void gpio_chardev_finalize(Object *obj)
+{
+    ChardevGpiodev *d = GPIODEV_CHARDEV(obj);
+
+    g_free(d->cbuf);
+}
+
+static void gpio_chardev_class_init(ObjectClass *oc, void *data)
+{
+    GpiodevClass *cc = GPIODEV_CLASS(oc);
+
+    cc->parse = &gpio_chardev_parse;
+    cc->open = &gpio_chardev_open;
+    cc->line_event = &gpio_chardev_line_event;
+    cc->config_event = &gpio_chardev_config_event;
+}
+
+static const TypeInfo gpio_chardev_type_info[] = {
+    {
+        .name = TYPE_GPIODEV_CHARDEV,
+        .parent = TYPE_GPIODEV,
+        .class_init = gpio_chardev_class_init,
+        .instance_size = sizeof(ChardevGpiodev),
+        .instance_finalize = gpio_chardev_finalize,
+    },
+};
+
+DEFINE_TYPES(gpio_chardev_type_info);
+
diff --git a/gpiodev/meson.build b/gpiodev/meson.build
index 0c7e457a11a6b01ec675006ae11ce0c50356407e..64d3abb4e3d72cba0c26b665515a0f97e82fb5d9 100644
--- a/gpiodev/meson.build
+++ b/gpiodev/meson.build
@@ -1,4 +1,5 @@
 gpiodev_ss.add(files(
+  'gpio-chardev.c',
   'gpio-fe.c',
   'gpio.c',
 ))
diff --git a/include/gpiodev/gpio.h b/include/gpiodev/gpio.h
index 2ea6c0e6af8125caacc944cdddca94b1bca8c4ff..a34d805ccc0bf5a25986b118dcc0b2cc0a55572c 100644
--- a/include/gpiodev/gpio.h
+++ b/include/gpiodev/gpio.h
@@ -55,6 +55,8 @@ struct Gpiodev {
 #define TYPE_GPIODEV "gpiodev"
 OBJECT_DECLARE_TYPE(Gpiodev, GpiodevClass, GPIODEV)
 
+#define TYPE_GPIODEV_CHARDEV "gpiodev-chardev"
+
 struct GpiodevClass {
     ObjectClass parent_class;
 

-- 
2.45.2

