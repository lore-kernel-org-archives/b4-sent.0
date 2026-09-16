From: Jim Cromie <jim.cromie@gmail.com>
Date: Wed, 16 Sep 2026 09:33:27 -0600
Subject: [PATCH v10 35/38] dyndbg: Ignore additional arguments from pr_fmt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260916-dd-cmap-part2-clean-v10-35-af4cf4767707@gmail.com>
References: <20260916-dd-cmap-part2-clean-v10-0-af4cf4767707@gmail.com>
In-Reply-To: <20260916-dd-cmap-part2-clean-v10-0-af4cf4767707@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789572777; l=7234;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=fSTkq3e+fagqoGSvxLT4HO/f6Eg0KGNZD7VBMflSa78=;
 b=YHRlv0h8KOwHcw0A6fQsfKidK8rYUsNmqIr+JVedrugUbIhnqA85LdxgVj9cKZT5HlkJUTXRI
 mlD6p6YNfMCA0fowmCUdrJmoGFieL4uRKiNKSwrh5PT1OI5VsxKX0Fo
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
v10:
. pass raw fmt to DEFINE_DYNAMIC_DEBUG_METADATA in pr_debug_ratelimited().
---
 include/linux/dynamic_debug.h                      |  2 +-
 include/linux/printk.h                             |  2 +-
 lib/test_dynamic_debug.c                           |  4 ++--
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 26 +++++++++++-----------
 4 files changed, 17 insertions(+), 17 deletions(-)

diff --git a/include/linux/dynamic_debug.h b/include/linux/dynamic_debug.h
index 2542d7c41b3e..d94ad3a2018a 100644
--- a/include/linux/dynamic_debug.h
+++ b/include/linux/dynamic_debug.h
@@ -359,7 +359,7 @@ void __dynamic_ibdev_dbg(struct _ddebug *descriptor,
 		dump_stack();					\
 }
 
-#define DEFINE_DYNAMIC_DEBUG_METADATA_CLS(name, cls, fmt)	\
+#define DEFINE_DYNAMIC_DEBUG_METADATA_CLS(name, cls, fmt, ...)	\
 	static struct _ddebug  __aligned(8)			\
 	__section("__dyndbg_descs") name = {			\
 		.modname = DDEBUG_MODNAME,			\
diff --git a/include/linux/printk.h b/include/linux/printk.h
index f594c1266bfd..5d701952e739 100644
--- a/include/linux/printk.h
+++ b/include/linux/printk.h
@@ -742,7 +742,7 @@ do {									\
 	static DEFINE_RATELIMIT_STATE(_rs,				\
 				      DEFAULT_RATELIMIT_INTERVAL,	\
 				      DEFAULT_RATELIMIT_BURST);		\
-	DEFINE_DYNAMIC_DEBUG_METADATA(descriptor, pr_fmt(fmt));		\
+	DEFINE_DYNAMIC_DEBUG_METADATA(descriptor, fmt);		\
 	if (DYNAMIC_DEBUG_BRANCH(descriptor) &&				\
 	    __ratelimit(&_rs))						\
 		__dynamic_pr_debug(&descriptor, pr_fmt(fmt), ##__VA_ARGS__);	\
diff --git a/lib/test_dynamic_debug.c b/lib/test_dynamic_debug.c
index fe5b885398f3..2710c4ea39a0 100644
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
@@ -272,7 +272,7 @@ static int __init test_dynamic_debug_init(void)
 
 static void __exit test_dynamic_debug_exit(void)
 {
-	pr_debug("exited\n");
+	pr_debug_ratelimited("exited\n");
 }
 
 module_init(test_dynamic_debug_init);
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index ef5f41ca7f7d..5eae762d6f78 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -588,40 +588,40 @@ function GOLDEN_RECORDS {
 #K= 1d43471dca765597d88a1be25d776c92 FT_classmap_inheritance.2
 #K= 0708a283f0f1959135c797e36119e4af FT_classmap_inheritance.3
 #K= a0b9a8a9530706b85c4f8bf911607db0 FT_classmap_inheritance.4
-#K= f43e0aff8a4b38435b73d90ed8100d1b FT_classmap_inheritance.5
+#K= 62b6803edf43519186d6185bebf34352 FT_classmap_inheritance.5
 #K= 53d1b6875b65c79cfd759e209ae50b11 FT_modprobe_w_param.1
 #K= 53d1b6875b65c79cfd759e209ae50b11 FT_modprobe_w_param.2
-#K= 79d912e2aeb04dea70f9c7e701333f0a FT_modprobe_w_param.3
+#K= 117ebf415c886c14b22e473d9b49886b FT_modprobe_w_param.3
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.4
-#K= 7cd75277388a6e7cf9c849442388f4af FT_modprobe_w_param.5
+#K= 23bf93d8d91b2e033f91caf2e5d2df2c FT_modprobe_w_param.5
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.6
-#K= 9196c43693f5e6059f3512e4d87e7347 FT_modprobe_w_param.7
+#K= 7090bc68365ad55564c54b1ba7355c73 FT_modprobe_w_param.7
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.8
 #K= f9cee4512e5604603e0262fba4bea223 FT_modprobe_w_param.9
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.10
-#K= 7c645692e3e3796d4d3b8604c49583f7 FT_modprobe_w_param.11
+#K= 076874eb43826e97586f034f4d2786e6 FT_modprobe_w_param.11
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.12
-#K= e995f70c0509334a33aec40ada9e6e6c FT_modprobe_w_param.13
+#K= 872dbd5d067953e34cd5a88db3a3b5e4 FT_modprobe_w_param.13
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.14
-#K= 72f97ca3e8f4c3e7f34fbe91de62e223 FT_modprobe_w_param.15
+#K= dce720419939a1baadaae27e98ceabea FT_modprobe_w_param.15
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.16
 #K= 1aacb7c196a8354c46c60c73d78c6bf2 FT_modprobe_w_param.17
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.18
 #K= e62014acf5ab6a76dfbfbcf67b2ca0e8 FT_modprobe_w_param.19
 #K= e62014acf5ab6a76dfbfbcf67b2ca0e8 FT_modprobe_w_param.20
-#K= 58c009cb287fa5df3f8c1c72c832cb42 FT_modprobe_w_param.21
+#K= 4bfcf87a67b1a5a5a56212deac36c20a FT_modprobe_w_param.21
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.22
-#K= e7831be2aac4a82daba43966b9d31e19 FT_modprobe_w_param.23
+#K= f0d3016e22d88ee9f810b81235c6acdc FT_modprobe_w_param.23
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.24
-#K= 4df2fbc0cae329debb14bedb5e7d86c0 FT_modprobe_w_param.25
+#K= da3e0531675fc96503a7077ef8fa5eeb FT_modprobe_w_param.25
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.26
 #K= 7fa4c84490c42c750986614c3539d56a FT_modprobe_w_param.27
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.28
-#K= fc098897aa3e1472a536e7ae8069c84f FT_modprobe_w_param.29
+#K= 923ca0e8a24d3e365b9dc89624062708 FT_modprobe_w_param.29
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.30
-#K= 38ea63fed62a0308241325e57020b28e FT_modprobe_w_param.31
+#K= 7eb76bdeb6e42f46e9c16b5932db79e1 FT_modprobe_w_param.31
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.32
-#K= 4b896adb5e7cfcc79f9ffa879d791f37 FT_modprobe_w_param.33
+#K= 5aaa5a8e367ec2871785f0c64853e243 FT_modprobe_w_param.33
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.34
 #K= 7f961a7d3facd89bdd4b9d8e7b5541e9 FT_modprobe_w_param.35
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.36

-- 
2.55.0

