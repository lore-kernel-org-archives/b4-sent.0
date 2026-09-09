From: Jim Cromie <jim.cromie@gmail.com>
Date: Tue, 08 Sep 2026 18:55:32 -0600
Subject: [PATCH v9 36/39] dyndbg: Ignore additional arguments from pr_fmt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260908-dd-cmap-part2-clean-v9-36-3a3f621f4a10@gmail.com>
References: <20260908-dd-cmap-part2-clean-v9-0-3a3f621f4a10@gmail.com>
In-Reply-To: <20260908-dd-cmap-part2-clean-v9-0-3a3f621f4a10@gmail.com>
To: Jason Baron <jbaron@akamai.com>, Shuah Khan <shuah@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Arnd Bergmann <arnd@arndb.de>, Luis Chamberlain <mcgrof@kernel.org>, 
 Petr Pavlu <petr.pavlu@suse.com>, Daniel Gomez <da.gomez@kernel.org>, 
 Sami Tolvanen <samitolvanen@google.com>, Aaron Tomlin <atomlin@atomlin.com>, 
 Jonathan Corbet <corbet@net.net>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Len Brown <lenb@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-arch@vger.kernel.org, 
 linux-modules@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, linux-pm@vger.kernel.org, 
 Jim Cromie <jim.cromie@gmail.com>, Philipp Hahn <phahn-oss@avm.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788915300; l=8312;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=/A60lUIkH61bJfL+P8nVPAZClgD7ugNv+jDM6NGco90=;
 b=scWmCDUSh2gbt7E4Eju27StH0aAVspB2JMsaaMPu3Gy+RLRl2wv5WblUNfq06+ksFDnRKZxCP
 HzwQC1cQmk5ARV1CKeFdtqlNN3EU9IjT04xMSSkUGmr6BQQF90p6b8E
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Philipp Hahn <phahn-oss@avm.de>

pr_fmt can be used to add a common prefix to any output from a module:
	#define pr_fmt(fmt) KBUILD_MODNAME ".%s " fmt, __func__

But adding additional arguments breaks dynamic debug:
> error: macro "DEFINE_DYNAMIC_DEBUG_METADATA_CLS" passed 4 arguments, but takes just 3
> |         pr_debug_ratelimited("%s", "Hello world!");
> |                                                  ^
> note: macro "DEFINE_DYNAMIC_DEBUG_METADATA_CLS" defined here
> | #define DEFINE_DYNAMIC_DEBUG_METADATA_CLS(name, cls, fmt)       \
> |
> error: ‘DEFINE_DYNAMIC_DEBUG_METADATA_CLS’ undeclared (first use in this function)
> |         DEFINE_DYNAMIC_DEBUG_METADATA_CLS(name, _DPRINTK_CLASS_DFLT, fmt)
> |         ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
> note: in expansion of macro ‘DEFINE_DYNAMIC_DEBUG_METADATA’
> |         DEFINE_DYNAMIC_DEBUG_METADATA(descriptor, pr_fmt(fmt));         \
> |         ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
> note: in expansion of macro ‘pr_debug_ratelimited’
> |         pr_debug_ratelimited("%s", "Hello world!");
> |         ^~~~~~~~~~~~~~~~~~~~

Add an additional ', ...' to DEFINE_DYNAMIC_DEBUG_METADATA_CLS to slurp
any additional argument, which `pr_fmt` might add.

Signed-off-by: Philipp Hahn <phahn-oss@avm.de>
[pr_fmt change on test_dynamic_debug_submod instead of parent]
Reviewed-by: Jim Cromie <jim.cromie@gmail.com>
---
 include/linux/dynamic_debug.h                      |  2 +-
 lib/test_dynamic_debug.c                           |  4 +-
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 68 +++++++++++-----------
 3 files changed, 37 insertions(+), 37 deletions(-)

diff --git a/include/linux/dynamic_debug.h b/include/linux/dynamic_debug.h
index 32a34a80672b..39de59c8bac2 100644
--- a/include/linux/dynamic_debug.h
+++ b/include/linux/dynamic_debug.h
@@ -364,7 +364,7 @@ void __dynamic_ibdev_dbg(struct _ddebug *descriptor,
 		dump_stack();					\
 }
 
-#define DEFINE_DYNAMIC_DEBUG_METADATA_CLS(name, cls, fmt)	\
+#define DEFINE_DYNAMIC_DEBUG_METADATA_CLS(name, cls, fmt, ...)	\
 	static struct _ddebug  __aligned(8)			\
 	__section("__dyndbg_descs") name = {			\
 		.modname = DDEBUG_MODNAME,			\
diff --git a/lib/test_dynamic_debug.c b/lib/test_dynamic_debug.c
index 97f2c9e1b92b..bce0993443b4 100644
--- a/lib/test_dynamic_debug.c
+++ b/lib/test_dynamic_debug.c
@@ -23,7 +23,7 @@
  * the usage clearer.
  */
 #if defined(TEST_DYNAMIC_DEBUG_SUBMOD)
-  #define pr_fmt(fmt) "test_dd_submod: " fmt
+  #define pr_fmt(fmt) "test_dd_submod: %s " fmt, __func__
 #else
   #define pr_fmt(fmt) "test_dd: " fmt
 #endif
@@ -270,7 +270,7 @@ static int __init test_dynamic_debug_init(void)
 
 static void __exit test_dynamic_debug_exit(void)
 {
-	pr_debug("exited\n");
+	pr_debug_ratelimited("exited\n");
 }
 
 module_init(test_dynamic_debug_init);
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index 25137663d554..9713b13be4e2 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -691,50 +691,50 @@ function GOLDEN_RECORDS {
 #K= cce9c41c3ac297e910c3ee3b10852cb3 FT_multi_query.2
 #K= 8c2dd1164fbcefb721345ce62a864a37 FT_multi_query.3
 #K= 4542e1e5e7eadcbe8f90a9c934635618 FT_multi_query.4
-#K= 8146f6f983c3a76783c89b78b892ed48 FT_test_classes.1
+#K= fd730021392c7d0044408f304d683c69 FT_test_classes.1
 #K= a15ec4843acd721fbdfddc0b512c8032 FT_test_classes.2
 #K= bc074e657d8d7f0bbc960e4dfa8de25d FT_test_classes.3
-#K= 878c5b9b20cbe8b93f2f3e92fc8b77bb FT_classmap_inheritance.1
-#K= 0eb7e891704074434646c2340ddac152 FT_classmap_inheritance.2
-#K= a6e6aab5a6cb9a792d4296b1200ba409 FT_classmap_inheritance.3
-#K= 5b6d86bcaa2477699aab655447d780dd FT_classmap_inheritance.4
-#K= f43e0aff8a4b38435b73d90ed8100d1b FT_classmap_inheritance.5
+#K= 824adca66a686b530ae8393351b16ecf FT_classmap_inheritance.1
+#K= c26dcd19a11f51322965a08e1fa5c98e FT_classmap_inheritance.2
+#K= cd150aea538ee12e9c18cafd2c95a39a FT_classmap_inheritance.3
+#K= 3aa6360c73a9509c30fff0c4f95f1607 FT_classmap_inheritance.4
+#K= 62b6803edf43519186d6185bebf34352 FT_classmap_inheritance.5
 #K= 94610c57ac44bd7011002a654fd78f93 FT_modprobe_w_param.1
 #K= 94610c57ac44bd7011002a654fd78f93 FT_modprobe_w_param.2
-#K= c1309e18dc9bf2f57184fa13164d917d FT_modprobe_w_param.3
-#K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.4
-#K= a1232e658d95fbca8b23a69e9a0db965 FT_modprobe_w_param.5
-#K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.6
-#K= af7b3d532325b1c5ab990e4b32fed577 FT_modprobe_w_param.7
-#K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.8
+#K= 8ce6fcd5958d99524509f8ee8b337762 FT_modprobe_w_param.3
+#K= a6dd47315e45f54d89fd2561f83b9bf0 FT_modprobe_w_param.4
+#K= e99561131cb0877e244ded16465d17be FT_modprobe_w_param.5
+#K= a6dd47315e45f54d89fd2561f83b9bf0 FT_modprobe_w_param.6
+#K= a6c1e1585418e199de271b71a9746d93 FT_modprobe_w_param.7
+#K= a6dd47315e45f54d89fd2561f83b9bf0 FT_modprobe_w_param.8
 #K= 591411c42cf52d7c4c46d76bcc345a5f FT_modprobe_w_param.9
-#K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.10
-#K= 46d24fecc507a8f9be0bd120e27ff64f FT_modprobe_w_param.11
-#K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.12
-#K= 79298a323d3dcca4f74fb9fc0de5a87e FT_modprobe_w_param.13
-#K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.14
-#K= f649752dfb07a68087f04dafc00ed1e8 FT_modprobe_w_param.15
-#K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.16
+#K= a6dd47315e45f54d89fd2561f83b9bf0 FT_modprobe_w_param.10
+#K= b425428024ebf309fd38ac6c67d954ef FT_modprobe_w_param.11
+#K= a6dd47315e45f54d89fd2561f83b9bf0 FT_modprobe_w_param.12
+#K= 35c26142670166a021b523097db2e418 FT_modprobe_w_param.13
+#K= a6dd47315e45f54d89fd2561f83b9bf0 FT_modprobe_w_param.14
+#K= 090cde34d0a22f90f2bba1fed561aa9c FT_modprobe_w_param.15
+#K= a6dd47315e45f54d89fd2561f83b9bf0 FT_modprobe_w_param.16
 #K= 73a93377a823739e8aae44856a20fa7f FT_modprobe_w_param.17
-#K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.18
+#K= a6dd47315e45f54d89fd2561f83b9bf0 FT_modprobe_w_param.18
 #K= 10464b2c3e3972f05e93c609700f8fb2 FT_modprobe_w_param.19
 #K= 10464b2c3e3972f05e93c609700f8fb2 FT_modprobe_w_param.20
-#K= 07c1f81d5a58675a291dc77acd6938c4 FT_modprobe_w_param.21
-#K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.22
-#K= b070066b0eb13a033446bd05850b15e2 FT_modprobe_w_param.23
-#K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.24
-#K= 32ca47823c27e629e03c21aebfc25095 FT_modprobe_w_param.25
-#K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.26
+#K= 69502938a4be4936847568d8aad027f6 FT_modprobe_w_param.21
+#K= a6dd47315e45f54d89fd2561f83b9bf0 FT_modprobe_w_param.22
+#K= 51fe322a7f368d936d2292c951247b33 FT_modprobe_w_param.23
+#K= a6dd47315e45f54d89fd2561f83b9bf0 FT_modprobe_w_param.24
+#K= 91391932971be1d599d19ba04d6f6a34 FT_modprobe_w_param.25
+#K= a6dd47315e45f54d89fd2561f83b9bf0 FT_modprobe_w_param.26
 #K= 7b91db8e9f160aebb1ee87fab2232404 FT_modprobe_w_param.27
-#K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.28
-#K= d3d111da544dd5cee254e88178823b9d FT_modprobe_w_param.29
-#K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.30
-#K= b5a30ebac06aea6e77a44322667effc7 FT_modprobe_w_param.31
-#K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.32
-#K= bbe7b47ed089428429f4264c8cc2a066 FT_modprobe_w_param.33
-#K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.34
+#K= a6dd47315e45f54d89fd2561f83b9bf0 FT_modprobe_w_param.28
+#K= 9d29af8b8039ca84138b6b030a3b2eb7 FT_modprobe_w_param.29
+#K= a6dd47315e45f54d89fd2561f83b9bf0 FT_modprobe_w_param.30
+#K= 2a90475b035790006963c6245334edab FT_modprobe_w_param.31
+#K= a6dd47315e45f54d89fd2561f83b9bf0 FT_modprobe_w_param.32
+#K= b4f6d119e4d5fea58ac3a78f6bd64540 FT_modprobe_w_param.33
+#K= a6dd47315e45f54d89fd2561f83b9bf0 FT_modprobe_w_param.34
 #K= 3d2538bf868e71bff17c768cf118c352 FT_modprobe_w_param.35
-#K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.36
+#K= a6dd47315e45f54d89fd2561f83b9bf0 FT_modprobe_w_param.36
 EOF
         # Read the K-recs and skip those for tests that can't run
         while read -r line; do

-- 
2.55.0

