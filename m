From: Jim Cromie <jim.cromie@gmail.com>
Date: Mon, 12 Oct 2026 20:37:04 -0600
Subject: [PATCH v12 33/40] dyndbg: Ignore additional arguments from pr_fmt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261012-dd-cmap-part2-clean-v12-33-3c8cc5725def@gmail.com>
References: <20261012-dd-cmap-part2-clean-v12-0-3c8cc5725def@gmail.com>
In-Reply-To: <20261012-dd-cmap-part2-clean-v12-0-3c8cc5725def@gmail.com>
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
 Len Brown <lenb@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Petr Mladek <pmladek@suse.com>, Steven Rostedt <rostedt@goodmis.org>, 
 John Ogness <john.ogness@linutronix.de>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, 
 =?utf-8?q?Thomas_Wei=C3=9Fschuh?= <linux@weissschuh.net>
Cc: linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-arch@vger.kernel.org, 
 linux-modules@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, linux-pm@vger.kernel.org, 
 Jim Cromie <jim.cromie@gmail.com>, Philipp Hahn <phahn-oss@avm.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791858995; l=7362;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=t5yf/9QOx73a3npl53CVzsExtvCuSk75hmzNKV++o98=;
 b=yydqcf2/2/sRPwW8mWOzuD/gEKpNh+7G2e0Qu9cBzIuhQ3W7/T+QvzYfC/p4M0CkFbJtoxGwP
 b/KTLdVGCt5DPIvFYb5j0ry5elEgi9V5IWAq47TIpekB0ej+clxPNbf
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
v11:
. update golden record hashes for FT_modprobe_w_param tests after
  comma-token and native classmap attachment fixes.

v10:
. pass raw fmt to DEFINE_DYNAMIC_DEBUG_METADATA in pr_debug_ratelimited().
---
 include/linux/dynamic_debug.h                      |  2 +-
 include/linux/printk.h                             |  2 +-
 lib/test_dynamic_debug.c                           |  4 ++--
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 26 +++++++++++-----------
 4 files changed, 17 insertions(+), 17 deletions(-)

diff --git a/include/linux/dynamic_debug.h b/include/linux/dynamic_debug.h
index 56ad8090d7b9..dc755a24f1d6 100644
--- a/include/linux/dynamic_debug.h
+++ b/include/linux/dynamic_debug.h
@@ -351,7 +351,7 @@ void __dynamic_ibdev_dbg(struct _ddebug *descriptor,
 		dump_stack();					\
 }
 
-#define DEFINE_DYNAMIC_DEBUG_METADATA_CLS(name, cls, fmt)	\
+#define DEFINE_DYNAMIC_DEBUG_METADATA_CLS(name, cls, fmt, ...)	\
 	static struct _ddebug  __aligned(8)			\
 	__section("__dyndbg_descs") name = {			\
 		.modname = KBUILD_MODNAME,			\
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
index ea81c5158b13..35bb411c48d8 100644
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
@@ -317,7 +317,7 @@ static int __init test_dynamic_debug_init(void)
 
 static void __exit test_dynamic_debug_exit(void)
 {
-	pr_debug("exited\n");
+	pr_debug_ratelimited("exited\n");
 }
 
 module_init(test_dynamic_debug_init);
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index 11142cc0aecb..e439f367386c 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -581,40 +581,40 @@ function GOLDEN_RECORDS {
 #K= c14c8aa758e24046b3237d20e2189bf7 FT_classmap_inheritance.2
 #K= 5d0f3701517aa3a461c8887c332bdb42 FT_classmap_inheritance.3
 #K= f444ae312fcce32444c54da757d87c41 FT_classmap_inheritance.4
-#K= 7e92245008439ee79fe2460aeaa16a9b FT_classmap_inheritance.5
+#K= 0266e8d60659058ec589283022bf078c FT_classmap_inheritance.5
 #K= d2e8b8c5a5b4e7b9bbe1a29460a3c07d FT_modprobe_w_param.1
 #K= d2e8b8c5a5b4e7b9bbe1a29460a3c07d FT_modprobe_w_param.2
-#K= 11032ef17569bd151c3806527a2428be FT_modprobe_w_param.3
+#K= 20d8a1fac0330f1b5cc582ce93792d58 FT_modprobe_w_param.3
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.4
-#K= 942e62ca24809cad666c5725aeb14376 FT_modprobe_w_param.5
+#K= 3c19dd83b330a9d59901281aaa3bacf8 FT_modprobe_w_param.5
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.6
-#K= fe1aadca4b2b4165d8d5c98e973f9e4b FT_modprobe_w_param.7
+#K= 86b7a18d7a692187aa0b7cc0b6886e77 FT_modprobe_w_param.7
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.8
 #K= 535ab526b24a7214de41d92e94bbd52c FT_modprobe_w_param.9
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.10
-#K= a71670fec42b1b0646f0317180bafcc7 FT_modprobe_w_param.11
+#K= 4f96e9cd2c92ab099cd35dad83c35e86 FT_modprobe_w_param.11
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.12
-#K= aacdbab171b374f221f0196e6e415d09 FT_modprobe_w_param.13
+#K= 80ca4d681dcd4c0046a4daa01e9b168a FT_modprobe_w_param.13
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.14
-#K= c7eb8e25c780f58c78ed73dc1c187a02 FT_modprobe_w_param.15
+#K= e0cdc3a8471acf34201539231b2b2110 FT_modprobe_w_param.15
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.16
 #K= d682c98ced7d31f1555ab474a9ebe253 FT_modprobe_w_param.17
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.18
 #K= c468e49e8ce1f1aa25a3c6684f221fe5 FT_modprobe_w_param.19
 #K= c468e49e8ce1f1aa25a3c6684f221fe5 FT_modprobe_w_param.20
-#K= ef2408a036206c895d95061521f67906 FT_modprobe_w_param.21
+#K= 2b31c44bc2eb5b5d666dc1887c38b8dd FT_modprobe_w_param.21
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.22
-#K= 92c0174d5de412de82e3d5837b0690d0 FT_modprobe_w_param.23
+#K= 3bba1f526e669807407d9be380117564 FT_modprobe_w_param.23
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.24
-#K= a563a79aeffbf3d8cf2e37ab93898ae9 FT_modprobe_w_param.25
+#K= 1dc9fbf8e7ce91929308a441e3707915 FT_modprobe_w_param.25
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.26
 #K= 8d2f4db3b7885064a56594e1d81deb26 FT_modprobe_w_param.27
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.28
-#K= 7185968287bbc0e5a72350ea4786e852 FT_modprobe_w_param.29
+#K= b76a644b8d3c99bfd8df9220f4509828 FT_modprobe_w_param.29
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.30
-#K= b2514a7fda24f196fa87c0ace35f0b37 FT_modprobe_w_param.31
+#K= dfc272b2a1f7a075e3a37dc491396adf FT_modprobe_w_param.31
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.32
-#K= 545c3efd767efbae33ee341df9008c52 FT_modprobe_w_param.33
+#K= 24629bcce166addffcaae1232ef6a5a9 FT_modprobe_w_param.33
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.34
 #K= 28ace93a95da7aaea5b9b54a8656a2cf FT_modprobe_w_param.35
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.36

-- 
2.56.0

