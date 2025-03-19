From: Nikita Shubin <n.shubin@yadro.com>
Date: Wed, 19 Mar 2025 10:57:53 +0300
Subject: [PATCH PoC 3/7] gpiodev: Add GPIO device frontend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-gpiodev-v1-3-76da4e5800a1@yadro.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742371072; l=22989;
 i=n.shubin@yadro.com; s=20230718; h=from:subject:message-id;
 bh=LTQ4DRZxUgYIxufc+VjL7CHLDfHRsY0h348VPbCO93Q=;
 b=RoqpcR3Zh9HwlMSu71p/Dmq3QlGR/Atk09T0ZsYOLuYHtZ2T47HTXNNp5Us70EO8BPkK4uLau
 0fx0jSYJSaYBJwQbP1w7FHc7CTSknCFdYaNyhYyHKqyiHbJelyKPtKC
X-Developer-Key: i=n.shubin@yadro.com; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for n.shubin@yadro.com/20230718 with auth_id=161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add GPIO device front end with helper functions to provide information
about GPIO Port to Backends and to allow Frontend to set data.

To use it GPIO device should register with qemu_gpio_fe_init()
and provide handlers with qemu_gpio_fe_set_handlers().

Notifications about config and changed value events should be done with
qemu_gpio_fe_line_event() and qemu_gpio_fe_config_event().

Signed-off-by: Nikita Shubin <n.shubin@yadro.com>
---
 gpiodev/gpio-fe.c         | 103 ++++++++++++++++++
 gpiodev/gpio.c            | 264 +++++++++++++++++++++++++++++++++++++++++++++-
 gpiodev/meson.build       |   1 +
 include/gpiodev/gpio-fe.h | 122 +++++++++++++++++++++
 include/gpiodev/gpio.h    | 200 ++++++++++++++++++++++++++++++++++-
 qom/object.c              |   1 +
 6 files changed, 684 insertions(+), 7 deletions(-)

diff --git a/gpiodev/gpio-fe.c b/gpiodev/gpio-fe.c
new file mode 100644
index 0000000000000000000000000000000000000000..3377548d8ed9961a74595686f83636945132f4c8
--- /dev/null
+++ b/gpiodev/gpio-fe.c
@@ -0,0 +1,103 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * QEMU GPIO device frontend.
+ *
+ * Author: 2025 Nikita Shubin <n.shubin@yadro.com>
+ *
+ */
+#include "qemu/osdep.h"
+#include "qemu/error-report.h"
+#include "qapi/error.h"
+#include "qapi/qmp/qerror.h"
+
+#include "gpiodev/gpio-fe.h"
+
+bool qemu_gpio_fe_init(GpioBackend *b, Gpiodev *s, uint32_t nlines,
+                       const char *name, const char *label,
+                       Error **errp)
+{
+    if (s->be) {
+        goto unavailable;
+    } else {
+        s->be = b;
+    }
+
+    qemu_gpiodev_set_info(s, nlines, name, label);
+    b->gpio = s;
+
+    return true;
+
+unavailable:
+    error_setg(errp, "chardev '%s' is already in use", s->label);
+    return false;
+}
+
+void qemu_gpio_fe_set_handlers(GpioBackend *b,
+                               LineInfoHandler *line_info,
+                               LineGetValueHandler *get_value,
+                               LineSetValueHandler *set_value,
+                               void *opaque)
+{
+    Gpiodev *s;
+
+    s = b->gpio;
+    if (!s) {
+        return;
+    }
+
+    b->line_info = line_info;
+    b->get_value = get_value;
+    b->set_value = set_value;
+    b->opaque = opaque;
+}
+
+bool qemu_gpio_fe_line_event(GpioBackend *b, uint32_t offset,
+                             QEMUGpioLineEvent event)
+{
+    Gpiodev *gpio = b->gpio;
+
+    if (!gpio) {
+        return false;
+    }
+
+    qemu_gpio_line_event(gpio, offset, event);
+
+    return true;
+}
+
+bool qemu_gpio_fe_config_event(GpioBackend *b, uint32_t offset,
+                               QEMUGpioConfigEvent event)
+{
+    Gpiodev *gpio = b->gpio;
+
+    if (!gpio) {
+        return false;
+    }
+
+    qemu_gpio_config_event(gpio, offset, event);
+
+    return true;
+}
+
+void qemu_gpio_fe_deinit(GpioBackend *b, bool del)
+{
+    assert(b);
+
+    if (b->gpio) {
+        qemu_gpio_fe_set_handlers(b, NULL, NULL, NULL, NULL);
+        if (b->gpio->be == b) {
+            b->gpio->be = NULL;
+        }
+
+        if (del) {
+            Object *obj = OBJECT(b->gpio);
+            if (obj->parent) {
+                object_unparent(obj);
+            } else {
+                object_unref(obj);
+            }
+        }
+
+        b->gpio = NULL;
+    }
+}
diff --git a/gpiodev/gpio.c b/gpiodev/gpio.c
index 0f84fb6c502bd6d0a5f808bc299fabd4144c2909..396de1f03d9af1910e104bd0381dd81025e994db 100644
--- a/gpiodev/gpio.c
+++ b/gpiodev/gpio.c
@@ -8,52 +8,227 @@
 #include "qemu/osdep.h"
 
 #include "qapi/error.h"
+#include "qapi/qmp/qerror.h"
+#include "qemu/bitmap.h"
 #include "qemu/config-file.h"
 #include "qemu/option.h"
 #include "qemu/qemu-print.h"
 #include "qemu/help_option.h"
 
 #include "gpiodev/gpio.h"
+#include "gpiodev/gpio-fe.h"
 
 static Object *get_gpiodevs_root(void)
 {
     return object_get_container("gpiodevs");
 }
 
+void qemu_gpiodev_set_info(Gpiodev *g, uint32_t nlines,
+                           const char *name, const char *label)
+{
+    g->lines = nlines;
+    g_strlcpy(g->name, name, sizeof(g->name));
+    g_strlcpy(g->label, label, sizeof(g->label));
+
+    g->mask.risen = bitmap_new(nlines);
+    g->mask.fallen = bitmap_new(nlines);
+    g->mask.config = bitmap_new(nlines);
+}
+
+void qemu_gpio_chip_info(Gpiodev *g, uint32_t *nlines,
+                         char *name, char *label)
+{
+    if (!g->be) {
+        g_strlcpy(name, "NULL", GPIO_MAX_NAME_SIZE);
+        g_strlcpy(label, "NULL", GPIO_MAX_NAME_SIZE);
+        *nlines = 0;
+        return;
+    }
+
+    g_strlcpy(name, g->name, GPIO_MAX_NAME_SIZE);
+    g_strlcpy(label, g->label, GPIO_MAX_NAME_SIZE);
+    *nlines = g->lines;
+}
+
+void qemu_gpio_line_info(Gpiodev *g, gpio_line_info *info)
+{
+    GpioBackend *be = g->be;
+
+    if (!be || !be->line_info) {
+        return;
+    }
+
+    be->line_info(be->opaque, info);
+}
+
+void qemu_gpio_set_line_value(Gpiodev *g, uint32_t offset, uint8_t value)
+{
+    GpioBackend *be = g->be;
+
+    if (!be || !be->set_value) {
+        return;
+    }
+
+    be->set_value(be->opaque, offset, value);
+}
+
+uint8_t qemu_gpio_get_line_value(Gpiodev *g, uint32_t offset)
+{
+    GpioBackend *be = g->be;
+
+    if (!be || !be->get_value) {
+        return 0;
+    }
+
+    return be->get_value(be->opaque, offset);
+}
+
+void qemu_gpio_add_event_watch(Gpiodev *g, uint32_t offset, uint64_t flags)
+{
+    if (flags & GPIO_EVENT_RISING_EDGE) {
+        set_bit(offset, g->mask.risen);
+    }
+
+    if (flags & GPIO_EVENT_FALLING_EDGE) {
+        set_bit(offset, g->mask.fallen);
+    }
+}
+
+void qemu_gpio_clear_event_watch(Gpiodev *g, uint32_t offset, uint64_t flags)
+{
+    if (flags & GPIO_EVENT_RISING_EDGE) {
+        clear_bit(offset, g->mask.risen);
+    }
+
+    if (flags & GPIO_EVENT_FALLING_EDGE) {
+        clear_bit(offset, g->mask.fallen);
+    }
+}
+
+void qemu_gpio_add_config_watch(Gpiodev *g, uint32_t offset)
+{
+    set_bit(offset, g->mask.config);
+}
+
+void qemu_gpio_clear_config_watch(Gpiodev *g, uint32_t offset)
+{
+    clear_bit(offset, g->mask.config);
+}
+
+void qemu_gpio_clear_watches(Gpiodev *g)
+{
+    bitmap_zero(g->mask.risen, g->lines);
+    bitmap_zero(g->mask.fallen, g->lines);
+    bitmap_zero(g->mask.config, g->lines);
+}
+
+void qemu_gpio_line_event(Gpiodev *g, uint32_t offset,
+                          QEMUGpioLineEvent event)
+{
+    GpiodevClass *gc = GPIODEV_GET_CLASS(g);
+    bool notify = false;
+
+    if (!gc->line_event) {
+        return;
+    }
+
+    if (event & GPIO_EVENT_RISING_EDGE) {
+        if (test_bit(offset, g->mask.risen)) {
+            notify = true;
+        }
+    }
+
+    if (event & GPIO_EVENT_FALLING_EDGE) {
+        if (test_bit(offset, g->mask.fallen)) {
+            notify = true;
+        }
+    }
+
+    if (notify) {
+        gc->line_event(g, offset, event);
+    }
+}
+
+void qemu_gpio_config_event(Gpiodev *g, uint32_t offset,
+                            QEMUGpioConfigEvent event)
+{
+    GpiodevClass *gc = GPIODEV_GET_CLASS(g);
+
+    if (!gc->config_event) {
+        return;
+    }
+
+    if (test_bit(offset, g->mask.config)) {
+        gc->config_event(g, offset, event);
+    }
+}
+
+static void qemu_gpio_finalize(Object *obj)
+{
+    Gpiodev *d = GPIODEV(obj);
+
+    g_free(d->mask.risen);
+    g_free(d->mask.fallen);
+    g_free(d->mask.config);
+}
+
 static const TypeInfo gpiodev_types_info[] = {
     {
         .name = TYPE_GPIODEV,
         .parent = TYPE_OBJECT,
         .instance_size = sizeof(Gpiodev),
+        .instance_finalize = qemu_gpio_finalize,
         .abstract = true,
+        .class_size = sizeof(GpiodevClass),
     },
 };
 
 DEFINE_TYPES(gpiodev_types_info);
 
-static Gpiodev *gpiodev_new(const char *id,
+static void qemu_gpio_open(Gpiodev *gpio, GpiodevBackend *backend,
+                           Error **errp)
+{
+    GpiodevClass *gc = GPIODEV_GET_CLASS(gpio);
+
+    if (gc->open) {
+        gc->open(gpio, backend, errp);
+    }
+}
+
+static Gpiodev *gpiodev_new(const char *id, const char *typename,
+                            GpiodevBackend *backend,
                             GMainContext *gcontext,
                             Error **errp)
 {
     Object *obj;
     Gpiodev *gpio = NULL;
+    Error *local_err = NULL;
 
+    assert(g_str_has_prefix(typename, "gpiodev-"));
     assert(id);
 
-    obj = object_new(TYPE_GPIODEV);
+    obj = object_new(typename);
     gpio = GPIODEV(obj);
     gpio->gcontext = gcontext;
 
+    qemu_gpio_open(gpio, backend, &local_err);
+    if (local_err) {
+        error_propagate(errp, local_err);
+        object_unref(obj);
+        return NULL;
+    }
+
     return gpio;
 }
 
-static Gpiodev *qemu_gpiodev_new(const char *id,
+static Gpiodev *qemu_gpiodev_new(const char *id, const char *typename,
+                                 GpiodevBackend *backend,
                                  GMainContext *gcontext,
                                  Error **errp)
 {
     Gpiodev *gpio;
 
-    gpio = gpiodev_new(id, gcontext, errp);
+    gpio = gpiodev_new(id, typename, backend, gcontext, errp);
     if (!gpio) {
         return NULL;
     }
@@ -100,11 +275,67 @@ help_string_append(const char *name, void *opaque)
     g_string_append_printf(str, "\n  %s", name);
 }
 
+static const GpiodevClass *gpio_get_class(const char *driver, Error **errp)
+{
+    ObjectClass *oc;
+    char *typename = g_strdup_printf("gpiodev-%s", driver);
+
+    oc = module_object_class_by_name(typename);
+    g_free(typename);
+
+    if (!object_class_dynamic_cast(oc, TYPE_GPIODEV)) {
+        error_setg(errp, "'%s' is not a valid gpio driver name", driver);
+        return NULL;
+    }
+
+    if (object_class_is_abstract(oc)) {
+        error_setg(errp, QERR_INVALID_PARAMETER_VALUE, "driver",
+                   "a non-abstract device type");
+        return NULL;
+    }
+
+    return GPIODEV_CLASS(oc);
+}
+
+static GpiodevBackend *qemu_gpio_parse_opts(QemuOpts *opts, Error **errp)
+{
+    Error *local_err = NULL;
+    const GpiodevClass *gc;
+    GpiodevBackend *backend = NULL;
+    const char *name = qemu_opt_get(opts, "backend");
+
+    if (name == NULL) {
+        error_setg(errp, "gpiodev: \"%s\" missing backend",
+                   qemu_opts_id(opts));
+        return NULL;
+    }
+
+    gc = gpio_get_class(name, errp);
+    if (gc == NULL) {
+        return NULL;
+    }
+
+    backend = g_new0(GpiodevBackend, 1);
+    if (gc->parse) {
+        gc->parse(opts, backend, &local_err);
+        if (local_err) {
+            error_propagate(errp, local_err);
+            qapi_free_GpiodevBackend(backend);
+            return NULL;
+        }
+    }
+
+    return backend;
+}
+
 Gpiodev *qemu_gpiodev_add(QemuOpts *opts, GMainContext *context,
                           Error **errp)
 {
     const char *id = qemu_opts_id(opts);
     const char *name = qemu_opt_get(opts, "backend");
+    const GpiodevClass *gc;
+    GpiodevBackend *backend = NULL;
+    Gpiodev *gpio = NULL;
 
     if (name && is_help_option(name)) {
         GString *str = g_string_new("");
@@ -121,7 +352,22 @@ Gpiodev *qemu_gpiodev_add(QemuOpts *opts, GMainContext *context,
         return NULL;
     }
 
-    return qemu_gpiodev_new(id, context, errp);
+    backend = qemu_gpio_parse_opts(opts, errp);
+    if (backend == NULL) {
+        return NULL;
+    }
+
+    gc = gpio_get_class(name, errp);
+    if (gc == NULL) {
+        goto out;
+    }
+
+    gpio = qemu_gpiodev_new(id, object_class_get_name(OBJECT_CLASS(gc)),
+                            backend, context, errp);
+
+out:
+    qapi_free_GpiodevBackend(backend);
+    return gpio;
 }
 
 static QemuOptsList qemu_gpiodev_opts = {
@@ -132,6 +378,14 @@ static QemuOptsList qemu_gpiodev_opts = {
         {
             .name = "backend",
             .type = QEMU_OPT_STRING,
+        }, {
+            .name = "chardev",
+            .type = QEMU_OPT_STRING,
+            .help = "Chardev id (for gpiodev-chardev)",
+        }, {
+            .name = "devname",
+            .type = QEMU_OPT_STRING,
+            .help = "Device name (for gpiodev-guse)",
         },
         { /* end of list */ }
     },
diff --git a/gpiodev/meson.build b/gpiodev/meson.build
index 05aeb266bce8d905753d90d917b5f8b2d265a0cf..0c7e457a11a6b01ec675006ae11ce0c50356407e 100644
--- a/gpiodev/meson.build
+++ b/gpiodev/meson.build
@@ -1,4 +1,5 @@
 gpiodev_ss.add(files(
+  'gpio-fe.c',
   'gpio.c',
 ))
 
diff --git a/include/gpiodev/gpio-fe.h b/include/gpiodev/gpio-fe.h
new file mode 100644
index 0000000000000000000000000000000000000000..ba775575c3b4a20219730189108a480fde7e60ca
--- /dev/null
+++ b/include/gpiodev/gpio-fe.h
@@ -0,0 +1,122 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * QEMU GPIO device frontend.
+ *
+ * Author: 2025 Nikita Shubin <n.shubin@yadro.com>
+ *
+ */
+#ifndef QEMU_GPIO_FE_H
+#define QEMU_GPIO_FE_H
+
+#include "qemu/main-loop.h"
+
+#include "gpiodev/gpio.h"
+
+/**
+ * LineInfoHandler: Return the gpio line info specified by offset
+ */
+typedef void LineInfoHandler(void *opaque, gpio_line_info *info);
+
+/**
+ * LineInfoHandler: Return the gpio line value specified by offset
+ */
+typedef int LineGetValueHandler(void *opaque, uint32_t offset);
+
+/**
+ * LineSetValueHandler: Set the gpio line value specified by offset
+ */
+typedef int LineSetValueHandler(void *opaque, uint32_t offset, uint8_t value);
+
+/**
+ * struct GpioBackend - back end as seen by front end
+ *
+ * The actual backend is Gpiodev
+ */
+struct GpioBackend {
+    Gpiodev *gpio;
+    LineInfoHandler *line_info;
+    LineGetValueHandler *get_value;
+    LineSetValueHandler *set_value;
+    void *opaque;
+};
+
+/**
+ * qemu_gpio_fe_deinit:
+ *
+ * @b: a GpioBackend
+ * @s: a Gpiodev
+ * @nlines: number of lines in the GPIO Port
+ * @name: name of the GPIO Port
+ * @label: label of the GPIO Port
+ * @errp: error if any
+ *
+ * Initializes a front end for the given GpioBackend and
+ * Gpiodev. Call qemu_gpio_fe_deinit() to remove the association and
+ * release the driver.
+ *
+ * nlines, name and label used for proving information
+ * via qemu_gpiodev_set_info().
+ *
+ * Returns: false on error.
+ */
+bool qemu_gpio_fe_init(GpioBackend *b, Gpiodev *s, uint32_t nlines,
+                       const char *name, const char *label,
+                       Error **errp);
+
+/**
+ * qemu_gpio_fe_set_handlers:
+ *
+ * @b: a GpioBackend
+ * @s: a Gpiodev
+ * @line_info: Line info handler to provide info about line
+ * @get_value: Get line value handler
+ * @set_value: Set line value handler
+ * @opaque: an opaque pointer for the callbacks
+ * @context: a main loop context or NULL for the default
+ *
+ * Set the front end gpio handlers.
+ *
+ */
+void qemu_gpio_fe_set_handlers(GpioBackend *b,
+                               LineInfoHandler *line_info,
+                               LineGetValueHandler *get_value,
+                               LineSetValueHandler *set_value,
+                               void *opaque);
+
+/**
+ * qemu_gpio_fe_deinit:
+ *
+ * @b: a GpioBackend
+ * @del: if true, delete the gpiodev backend
+ *
+ * Dissociate the GpioBackend from the Gpiodev.
+ *
+ * Safe to call without associated Gpiodev.
+ */
+void qemu_gpio_fe_deinit(GpioBackend *b, bool del);
+
+/**
+ * qemu_gpio_fe_line_event:
+ *
+ * @b: a GpioBackend
+ * @offset: line number offset
+ * @event: rising or falling edge event
+ *
+ * See enum QEMUGpioEvent.
+ */
+bool qemu_gpio_fe_line_event(GpioBackend *b, uint32_t offset,
+                             QEMUGpioLineEvent event);
+
+/**
+ * qemu_gpio_fe_config_event:
+ *
+ * @b: a GpioBackend
+ * @offset: line number offset
+ * @event: requested, released or input/output toggle
+ *
+ * See enum QEMUGpioConfigEvent.
+ */
+bool qemu_gpio_fe_config_event(GpioBackend *b, uint32_t offset,
+                               QEMUGpioConfigEvent event);
+
+#endif /* QEMU_GPIO_FE_H */
diff --git a/include/gpiodev/gpio.h b/include/gpiodev/gpio.h
index aca0a6090bb5264e1646fa5facace2d8f7cc47fd..2ea6c0e6af8125caacc944cdddca94b1bca8c4ff 100644
--- a/include/gpiodev/gpio.h
+++ b/include/gpiodev/gpio.h
@@ -8,25 +8,221 @@
 #ifndef QEMU_GPIO_H
 #define QEMU_GPIO_H
 
+#include "qapi/qapi-types-gpio.h"
 #include "qom/object.h"
+#include "qemu/bitops.h"
 
 /* gpio back-end device */
 typedef struct GpioBackend GpioBackend;
 
+#define GPIO_MAX_NAME_SIZE 32
+
+/* compatible with enum gpio_v2_line_flag */
+typedef enum QEMUGpioLineFlags {
+	GPIO_LINE_FLAG_INPUT            = BIT_ULL(2),
+	GPIO_LINE_FLAG_OUTPUT           = BIT_ULL(3),
+} QEMUGpioLineFlags;
+
+typedef enum QEMUGpioLineEvent {
+	GPIO_EVENT_RISING_EDGE	= 1,
+	GPIO_EVENT_FALLING_EDGE	= 2,
+} QEMUGpioLineEvent;
+
+typedef enum QEMUGpioConfigEvent {
+	GPIO_LINE_CHANGED_REQUESTED	= 1,
+	GPIO_LINE_CHANGED_RELEASED	= 2,
+	GPIO_LINE_CHANGED_CONFIG	= 3,
+} QEMUGpioConfigEvent;
+
 struct Gpiodev {
     Object parent_obj;
 
     GpioBackend *be;
 
+    uint32_t lines;
+    char name[GPIO_MAX_NAME_SIZE];
+	char label[GPIO_MAX_NAME_SIZE];
+
+    struct {
+        unsigned long *risen;
+        unsigned long *fallen;
+        unsigned long *config;
+    } mask;
+
     GMainContext *gcontext;
 };
 
+#define TYPE_GPIODEV "gpiodev"
+OBJECT_DECLARE_TYPE(Gpiodev, GpiodevClass, GPIODEV)
+
 struct GpiodevClass {
     ObjectClass parent_class;
+
+    /* parse command line options and populate QAPI @backend */
+    void (*parse)(QemuOpts *opts, GpiodevBackend *backend, Error **errp);
+
+    /* called after construction, open/starts the backend */
+    void (*open)(Gpiodev *gpio, GpiodevBackend *backend, Error **errp);
+
+    /* notify backend about line event */
+    void (*line_event)(Gpiodev *g, uint32_t offset,
+                       QEMUGpioLineEvent event);
+
+    /* notify backend about config event */
+    void (*config_event)(Gpiodev *g, uint32_t offset,
+                         QEMUGpioConfigEvent event);
 };
 
-#define TYPE_GPIODEV "gpiodev"
-OBJECT_DECLARE_TYPE(Gpiodev, GpiodevClass, GPIODEV)
+/**
+ * qemu_gpiodev_set_info:
+ *
+ * @g: a Gpiodev
+ * @nlines: number of lines in the GPIO Port
+ * @name: name of the GPIO Port
+ * @label: label of the GPIO Port
+ *
+ * Set basic info about GPIO Port, used by backends to provide data
+ * to client applications.
+ *
+ * nlines, name and label used for proving information
+ * via qemu_gpio_chip_info().
+ */
+void qemu_gpiodev_set_info(Gpiodev *g, uint32_t nlines,
+                           const char *name, const char *label);
+
+/**
+ * qemu_gpio_chip_info:
+ *
+ * @g: a Gpiodev
+ * @nlines: lines number of the GPIO Port will be set
+ * @name: name of the GPIO Port will be set
+ * @label: label of the GPIO Port will be set
+ *
+ * If GpioBackend is NULL, nlines will be set to zero and
+ * both name and label to NULL.
+ */
+void qemu_gpio_chip_info(Gpiodev *g, uint32_t *nlines,
+                         char *name, char *label);
+
+typedef struct gpio_line_info {
+	char name[GPIO_MAX_NAME_SIZE];
+	char consumer[GPIO_MAX_NAME_SIZE];
+	uint32_t offset;
+	uint64_t flags;
+} gpio_line_info;
+
+/**
+ * qemu_gpio_line_info:
+ *
+ * @g: a Gpiodev
+ * @info: info about requested line
+ *
+ * info->offset should be provided see gpio_line_info.
+ */
+void qemu_gpio_line_info(Gpiodev *g, gpio_line_info *info);
+
+/**
+ * qemu_gpio_set_line_value:
+ *
+ * @g: a Gpiodev
+ * @offset: line offset
+ * @value: line value
+ */
+void qemu_gpio_set_line_value(Gpiodev *g, uint32_t offset, uint8_t value);
+
+/**
+ * qemu_gpio_get_line_value:
+ *
+ * @g: a Gpiodev
+ * @offset: line offset
+ *
+ * returns 0 or 1 line status
+ */
+uint8_t qemu_gpio_get_line_value(Gpiodev *g, uint32_t offset);
+
+/**
+ * qemu_gpio_add_event_watch:
+ *
+ * @g: a Gpiodev
+ * @offset: line offset
+ * @flags: event flags
+ *
+ * See QEMUGpioLineEvent.
+ *
+ * Add lines specified by mask and flags to watch, called by GpiodevBackend to subscribe
+ * desired lines and events.
+ */
+void qemu_gpio_add_event_watch(Gpiodev *g, uint32_t offset, uint64_t flags);
+
+/**
+ * qemu_gpio_clear_event_watch:
+ *
+ * @g: a Gpiodev
+ * @offset: line offset
+ * @flags: event flags
+ *
+ * See QEMUGpioLineEvent.
+ *
+ * Remove lines specified by mask and flags from watch, called by GpiodevBackend.
+ */
+void qemu_gpio_clear_event_watch(Gpiodev *g, uint32_t offset, uint64_t flags);
+
+/**
+ * qemu_gpio_add_config_watch:
+ *
+ * @g: a Gpiodev
+ * @offset: line offset
+ *
+ * See QEMUGpioConfigEvent.
+ *
+ * Add lines specified by mask to watch, called by GpiodevBackend to subscribe
+ * about desired lines config change.
+ */
+void qemu_gpio_add_config_watch(Gpiodev *g, uint32_t offset);
+
+/**
+ * qemu_gpio_clear_config_watch:
+ *
+ * @g: a Gpiodev
+ * @mask: lines mask to clear
+ *
+ * See QEMUGpioConfigEvent.
+ *
+ * Remove lines specified by mask from watch, called by GpiodevBackend.
+ */
+void qemu_gpio_clear_config_watch(Gpiodev *g, uint32_t offset);
+
+void qemu_gpio_clear_watches(Gpiodev *g);
+
+
+/**
+ * qemu_gpio_line_event:
+ *
+ * @g: a Gpiodev
+ * @offset: line offset
+ * @event: event
+ *
+ * See QEMUGpioLineEvent.
+ *
+ * Called by GpioBackend to notify Gpiodev about line event, i.e. line set to 0/1.
+ */
+void qemu_gpio_line_event(Gpiodev *gpio, uint32_t offset,
+                          QEMUGpioLineEvent event);
+
+/**
+ * qemu_gpio_config_event:
+ *
+ * @g: a Gpiodev
+ * @offset: line offset
+ * @event: event
+ *
+ * See QEMUGpioConfigEvent.
+ *
+ * Called by GpioBackend to notify Gpiodev about line config event,
+ * i.e. input switched to output.
+ */
+void qemu_gpio_config_event(Gpiodev *g, uint32_t offset,
+                          QEMUGpioConfigEvent event);
 
 Gpiodev *qemu_gpiodev_add(QemuOpts *opts, GMainContext *context,
                           Error **errp);
diff --git a/qom/object.c b/qom/object.c
index 01618d06bd88b0b7049f4b6de9985d4b3c5c1dbc..e0b9095a1148be3c8de05408ef89578c10226c4e 100644
--- a/qom/object.c
+++ b/qom/object.c
@@ -1730,6 +1730,7 @@ const char *object_property_get_type(Object *obj, const char *name, Error **errp
 
 static const char *const root_containers[] = {
     "chardevs",
+    "gpiodevs",
     "objects",
     "backend"
 };

-- 
2.45.2

