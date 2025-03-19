From: Nikita Shubin <n.shubin@yadro.com>
Date: Wed, 19 Mar 2025 10:57:52 +0300
Subject: [PATCH PoC 2/7] Add gpiodev dummy
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-gpiodev-v1-2-76da4e5800a1@yadro.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742371072; l=9267;
 i=n.shubin@yadro.com; s=20230718; h=from:subject:message-id;
 bh=Us2ZTcDmCXB4hKwaTjATMDmdCnIaWHQ1GrXvw/CeVjQ=;
 b=2ucNJK+XU0gUIvebTFEg5dVj3MC/m+ixeBQuSYyHQSlCEpqaEhBYw3AL9s/htU+n+V205kVRu
 3a/ng7seFe4D1lBsmOjGAWECawPAtfr7YF1xk7WORUNqxRe2N5XQiST
X-Developer-Key: i=n.shubin@yadro.com; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for n.shubin@yadro.com/20230718 with auth_id=161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add gpiodev stub with single help option.

Signed-off-by: Nikita Shubin <n.shubin@yadro.com>
---
 gpiodev/gpio.c         | 145 +++++++++++++++++++++++++++++++++++++++++++++++++
 gpiodev/meson.build    |   5 ++
 include/gpiodev/gpio.h |  34 ++++++++++++
 meson.build            |  11 +++-
 qemu-options.hx        |   9 +++
 system/vl.c            |  25 +++++++++
 6 files changed, 228 insertions(+), 1 deletion(-)

diff --git a/gpiodev/gpio.c b/gpiodev/gpio.c
new file mode 100644
index 0000000000000000000000000000000000000000..0f84fb6c502bd6d0a5f808bc299fabd4144c2909
--- /dev/null
+++ b/gpiodev/gpio.c
@@ -0,0 +1,145 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * QEMU GPIO device.
+ *
+ * Author: 2025 Nikita Shubin <n.shubin@yadro.com>
+ *
+ */
+#include "qemu/osdep.h"
+
+#include "qapi/error.h"
+#include "qemu/config-file.h"
+#include "qemu/option.h"
+#include "qemu/qemu-print.h"
+#include "qemu/help_option.h"
+
+#include "gpiodev/gpio.h"
+
+static Object *get_gpiodevs_root(void)
+{
+    return object_get_container("gpiodevs");
+}
+
+static const TypeInfo gpiodev_types_info[] = {
+    {
+        .name = TYPE_GPIODEV,
+        .parent = TYPE_OBJECT,
+        .instance_size = sizeof(Gpiodev),
+        .abstract = true,
+    },
+};
+
+DEFINE_TYPES(gpiodev_types_info);
+
+static Gpiodev *gpiodev_new(const char *id,
+                            GMainContext *gcontext,
+                            Error **errp)
+{
+    Object *obj;
+    Gpiodev *gpio = NULL;
+
+    assert(id);
+
+    obj = object_new(TYPE_GPIODEV);
+    gpio = GPIODEV(obj);
+    gpio->gcontext = gcontext;
+
+    return gpio;
+}
+
+static Gpiodev *qemu_gpiodev_new(const char *id,
+                                 GMainContext *gcontext,
+                                 Error **errp)
+{
+    Gpiodev *gpio;
+
+    gpio = gpiodev_new(id, gcontext, errp);
+    if (!gpio) {
+        return NULL;
+    }
+
+    if (!object_property_try_add_child(get_gpiodevs_root(), id, OBJECT(gpio),
+                                       errp)) {
+        object_unref(OBJECT(gpio));
+        return NULL;
+    }
+
+    object_unref(OBJECT(gpio));
+
+    return gpio;
+}
+
+typedef struct GpiodevClassFE {
+    void (*fn)(const char *name, void *opaque);
+    void *opaque;
+} GpiodevClassFE;
+
+static void
+gpiodev_class_foreach(ObjectClass *klass, void *opaque)
+{
+    GpiodevClassFE *fe = opaque;
+
+    assert(g_str_has_prefix(object_class_get_name(klass), "gpiodev-"));
+    fe->fn(object_class_get_name(klass) + 8, fe->opaque);
+}
+
+static void
+gpiodev_name_foreach(void (*fn)(const char *name, void *opaque),
+                     void *opaque)
+{
+    GpiodevClassFE fe = { .fn = fn, .opaque = opaque };
+
+    object_class_foreach(gpiodev_class_foreach, TYPE_GPIODEV, false, &fe);
+}
+
+static void
+help_string_append(const char *name, void *opaque)
+{
+    GString *str = opaque;
+
+    g_string_append_printf(str, "\n  %s", name);
+}
+
+Gpiodev *qemu_gpiodev_add(QemuOpts *opts, GMainContext *context,
+                          Error **errp)
+{
+    const char *id = qemu_opts_id(opts);
+    const char *name = qemu_opt_get(opts, "backend");
+
+    if (name && is_help_option(name)) {
+        GString *str = g_string_new("");
+
+        gpiodev_name_foreach(help_string_append, str);
+
+        qemu_printf("Available chardev backend types: %s\n", str->str);
+        g_string_free(str, true);
+        return NULL;
+    }
+
+    if (id == NULL) {
+        error_setg(errp, "gpiodev: no id specified");
+        return NULL;
+    }
+
+    return qemu_gpiodev_new(id, context, errp);
+}
+
+static QemuOptsList qemu_gpiodev_opts = {
+    .name = "gpiodev",
+    .implied_opt_name = "backend",
+    .head = QTAILQ_HEAD_INITIALIZER(qemu_gpiodev_opts.head),
+    .desc = {
+        {
+            .name = "backend",
+            .type = QEMU_OPT_STRING,
+        },
+        { /* end of list */ }
+    },
+};
+
+static void gpiodev_register_config(void)
+{
+    qemu_add_opts(&qemu_gpiodev_opts);
+}
+
+opts_init(gpiodev_register_config);
diff --git a/gpiodev/meson.build b/gpiodev/meson.build
new file mode 100644
index 0000000000000000000000000000000000000000..05aeb266bce8d905753d90d917b5f8b2d265a0cf
--- /dev/null
+++ b/gpiodev/meson.build
@@ -0,0 +1,5 @@
+gpiodev_ss.add(files(
+  'gpio.c',
+))
+
+gpiodev_ss = gpiodev_ss.apply({})
diff --git a/include/gpiodev/gpio.h b/include/gpiodev/gpio.h
new file mode 100644
index 0000000000000000000000000000000000000000..aca0a6090bb5264e1646fa5facace2d8f7cc47fd
--- /dev/null
+++ b/include/gpiodev/gpio.h
@@ -0,0 +1,34 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * QEMU GPIO device.
+ *
+ * Author: 2025 Nikita Shubin <n.shubin@yadro.com>
+ *
+ */
+#ifndef QEMU_GPIO_H
+#define QEMU_GPIO_H
+
+#include "qom/object.h"
+
+/* gpio back-end device */
+typedef struct GpioBackend GpioBackend;
+
+struct Gpiodev {
+    Object parent_obj;
+
+    GpioBackend *be;
+
+    GMainContext *gcontext;
+};
+
+struct GpiodevClass {
+    ObjectClass parent_class;
+};
+
+#define TYPE_GPIODEV "gpiodev"
+OBJECT_DECLARE_TYPE(Gpiodev, GpiodevClass, GPIODEV)
+
+Gpiodev *qemu_gpiodev_add(QemuOpts *opts, GMainContext *context,
+                          Error **errp);
+
+#endif /* QEMU_GPIO_H */
diff --git a/meson.build b/meson.build
index 8b9fda4d95e634e6faa8db5604e5e0ddc4b1eb9e..9daac5783bcf459a3ee6ff1e999582bf4e9a47cc 100644
--- a/meson.build
+++ b/meson.build
@@ -3646,6 +3646,7 @@ block_ss = ss.source_set()
 chardev_ss = ss.source_set()
 common_ss = ss.source_set()
 crypto_ss = ss.source_set()
+gpiodev_ss = ss.source_set()
 hwcore_ss = ss.source_set()
 io_ss = ss.source_set()
 qmp_ss = ss.source_set()
@@ -3735,6 +3736,7 @@ subdir('io')
 subdir('chardev')
 subdir('fsdev')
 subdir('dump')
+subdir('gpiodev')
 
 if have_block
   block_ss.add(files(
@@ -4023,11 +4025,18 @@ libhwcore = static_library('hwcore', sources: hwcore_ss.sources() + genh,
 hwcore = declare_dependency(objects: libhwcore.extract_all_objects(recursive: false))
 common_ss.add(hwcore)
 
+libgpiodev = static_library('gpiodev', gpiodev_ss.sources() + genh,
+                            dependencies: gpiodev_ss.dependencies(),
+                            build_by_default: false)
+
+gpiodev = declare_dependency(objects: libgpiodev.extract_all_objects(recursive: false),
+                             dependencies: gpiodev_ss.dependencies())
+
 ###########
 # Targets #
 ###########
 
-system_ss.add(authz, blockdev, chardev, crypto, io, qmp)
+system_ss.add(authz, blockdev, chardev, crypto, gpiodev, io, qmp)
 common_ss.add(qom, qemuutil)
 
 common_ss.add_all(when: 'CONFIG_SYSTEM_ONLY', if_true: [system_ss])
diff --git a/qemu-options.hx b/qemu-options.hx
index dc694a99a30a7d1ef1567005f59ece88d13f3455..97d293c7d3276a5835c40bb9b26e5f0c8c2a2d28 100644
--- a/qemu-options.hx
+++ b/qemu-options.hx
@@ -4081,6 +4081,15 @@ ERST
 
 DEFHEADING()
 
+DEFHEADING(GPIO device options:)
+
+DEF("gpiodev", HAS_ARG, QEMU_OPTION_gpiodev,
+    "-gpiodev help\n"
+    , QEMU_ARCH_ALL
+)
+
+DEFHEADING()
+
 #ifdef CONFIG_TPM
 DEFHEADING(TPM device options:)
 
diff --git a/system/vl.c b/system/vl.c
index 04f78466c412a2f9e38c0b187c45d09d8df873ce..67e266a93d0d53c2a7cbd49f8831ae85702c8b42 100644
--- a/system/vl.c
+++ b/system/vl.c
@@ -73,6 +73,7 @@
 #include "gdbstub/enums.h"
 #include "qemu/timer.h"
 #include "chardev/char.h"
+#include "gpiodev/gpio.h"
 #include "qemu/bitmap.h"
 #include "qemu/log.h"
 #include "system/blockdev.h"
@@ -1230,6 +1231,20 @@ static int chardev_init_func(void *opaque, QemuOpts *opts, Error **errp)
     return 0;
 }
 
+static int gpiodev_init_func(void *opaque, QemuOpts *opts, Error **errp)
+{
+    Error *local_err = NULL;
+
+    if (!qemu_gpiodev_add(opts, NULL, &local_err)) {
+        if (local_err) {
+            error_propagate(errp, local_err);
+            return -1;
+        }
+        exit(0);
+    }
+    return 0;
+}
+
 #ifdef CONFIG_VIRTFS
 static int fsdev_init_func(void *opaque, QemuOpts *opts, Error **errp)
 {
@@ -2053,6 +2068,9 @@ static void qemu_create_early_backends(void)
     qemu_opts_foreach(qemu_find_opts("chardev"),
                       chardev_init_func, NULL, &error_fatal);
 
+    qemu_opts_foreach(qemu_find_opts("gpiodev"),
+                      gpiodev_init_func, NULL, &error_fatal);
+
 #ifdef CONFIG_VIRTFS
     qemu_opts_foreach(qemu_find_opts("fsdev"),
                       fsdev_init_func, NULL, &error_fatal);
@@ -3241,6 +3259,13 @@ void qemu_init(int argc, char **argv)
                     exit(1);
                 }
                 break;
+            case QEMU_OPTION_gpiodev:
+                opts = qemu_opts_parse_noisily(qemu_find_opts("gpiodev"),
+                                               optarg, true);
+                if (!opts) {
+                    exit(1);
+                }
+                break;
             case QEMU_OPTION_fsdev:
                 olist = qemu_find_opts("fsdev");
                 if (!olist) {

-- 
2.45.2

