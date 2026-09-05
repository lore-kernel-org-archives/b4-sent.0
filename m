From: Jim Cromie <jim.cromie@gmail.com>
Date: Sat, 05 Sep 2026 12:13:53 -0600
Subject: [PATCH v8 39/43] dyndbg: Ignore additional arguments from pr_fmt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260905-dd-cmap-part2-clean-v8-39-a4cc0674f6fd@gmail.com>
References: <20260905-dd-cmap-part2-clean-v8-0-a4cc0674f6fd@gmail.com>
In-Reply-To: <20260905-dd-cmap-part2-clean-v8-0-a4cc0674f6fd@gmail.com>
To: Jason Baron <jbaron@akamai.com>, Shuah Khan <shuah@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Arnd Bergmann <arnd@arndb.de>, Luis Chamberlain <mcgrof@kernel.org>, 
 Petr Pavlu <petr.pavlu@suse.com>, Daniel Gomez <da.gomez@kernel.org>, 
 Sami Tolvanen <samitolvanen@google.com>, Aaron Tomlin <atomlin@atomlin.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-arch@vger.kernel.org, 
 linux-modules@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, Jim Cromie <jim.cromie@gmail.com>, 
 Philipp Hahn <phahn-oss@avm.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788632017; l=8312;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=emu4+qhrK1ZLKiDIRNHJ+kSxfMaMHPbDRgjl3ckBxAo=;
 b=Ko17QfDvWw1ewhixWjtTBkaRRaStrE3qk5ZLM4bmPS0RM7wsuTWE58jAPP+uWVL6DweryPTpy
 B3K9nBjHRbHAsVjZ4t7mFnfM0XjdKcfgI5t6N0zOoLaws2KGWZgM6Gv
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
index d00605ef651e..82cde8e6b46c 100644
--- a/include/linux/dynamic_debug.h
+++ b/include/linux/dynamic_debug.h
@@ -362,7 +362,7 @@ void __dynamic_ibdev_dbg(struct _ddebug *descriptor,
 		dump_stack();					\
 }
 
-#define DEFINE_DYNAMIC_DEBUG_METADATA_CLS(name, cls, fmt)	\
+#define DEFINE_DYNAMIC_DEBUG_METADATA_CLS(name, cls, fmt, ...)	\
 	static struct _ddebug  __aligned(8)			\
 	__section("__dyndbg_descs") name = {			\
 		.modname = DDEBUG_MODNAME,			\
diff --git a/lib/test_dynamic_debug.c b/lib/test_dynamic_debug.c
index 2d4be5442d46..2cf4092e7ec4 100644
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
@@ -269,7 +269,7 @@ static int __init test_dynamic_debug_init(void)
 
 static void __exit test_dynamic_debug_exit(void)
 {
-	pr_debug("exited\n");
+	pr_debug_ratelimited("exited\n");
 }
 
 module_init(test_dynamic_debug_init);
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index 5ef10cf8f6c3..eeb5018d6f82 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -683,50 +683,50 @@ function GOLDEN_RECORDS {
 #K= f49de2063a545721cf5e959efc160836 FT_multi_query.2
 #K= 2ff49f0c4d18ec99bcb1c30840fe8afc FT_multi_query.3
 #K= 9a1b13c32a15363dcf93913308edeea5 FT_multi_query.4
-#K= d4923595eea382923aee64aed15c7c35 FT_test_classes.1
+#K= 26586ed28518bdd7d718ff4172635c42 FT_test_classes.1
 #K= a15ec4843acd721fbdfddc0b512c8032 FT_test_classes.2
 #K= b4a593a1e1cab60da0156fcd5582d24c FT_test_classes.3
-#K= 2d5fccd52e747b803c0dc96186675f3f FT_classmap_inheritance.1
-#K= 3dcfea837b96c36bc61150414d810f9d FT_classmap_inheritance.2
-#K= d4937472530af6fdcb0a2440d4a366ea FT_classmap_inheritance.3
-#K= 5a78f2fdd6958ef6329aaff2f67c0e1e FT_classmap_inheritance.4
-#K= f43e0aff8a4b38435b73d90ed8100d1b FT_classmap_inheritance.5
+#K= 62501908ed46fb83205bebd80f850d56 FT_classmap_inheritance.1
+#K= 1d2ac19332c416e913d9fff8661db4b9 FT_classmap_inheritance.2
+#K= 8dd8f7c4b3b7777d5279b6635ec83f7b FT_classmap_inheritance.3
+#K= a8dfa89c4daf89f13a015e87a36077c1 FT_classmap_inheritance.4
+#K= 62b6803edf43519186d6185bebf34352 FT_classmap_inheritance.5
 #K= 94610c57ac44bd7011002a654fd78f93 FT_modprobe_w_param.1
 #K= 94610c57ac44bd7011002a654fd78f93 FT_modprobe_w_param.2
-#K= c1309e18dc9bf2f57184fa13164d917d FT_modprobe_w_param.3
-#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.4
-#K= a1232e658d95fbca8b23a69e9a0db965 FT_modprobe_w_param.5
-#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.6
-#K= af7b3d532325b1c5ab990e4b32fed577 FT_modprobe_w_param.7
-#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.8
+#K= 8ce6fcd5958d99524509f8ee8b337762 FT_modprobe_w_param.3
+#K= ef22493a8baadddc5dd0291577e413c8 FT_modprobe_w_param.4
+#K= e99561131cb0877e244ded16465d17be FT_modprobe_w_param.5
+#K= ef22493a8baadddc5dd0291577e413c8 FT_modprobe_w_param.6
+#K= a6c1e1585418e199de271b71a9746d93 FT_modprobe_w_param.7
+#K= ef22493a8baadddc5dd0291577e413c8 FT_modprobe_w_param.8
 #K= 591411c42cf52d7c4c46d76bcc345a5f FT_modprobe_w_param.9
-#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.10
-#K= 46d24fecc507a8f9be0bd120e27ff64f FT_modprobe_w_param.11
-#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.12
-#K= 79298a323d3dcca4f74fb9fc0de5a87e FT_modprobe_w_param.13
-#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.14
-#K= f649752dfb07a68087f04dafc00ed1e8 FT_modprobe_w_param.15
-#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.16
+#K= ef22493a8baadddc5dd0291577e413c8 FT_modprobe_w_param.10
+#K= b425428024ebf309fd38ac6c67d954ef FT_modprobe_w_param.11
+#K= ef22493a8baadddc5dd0291577e413c8 FT_modprobe_w_param.12
+#K= 35c26142670166a021b523097db2e418 FT_modprobe_w_param.13
+#K= ef22493a8baadddc5dd0291577e413c8 FT_modprobe_w_param.14
+#K= 090cde34d0a22f90f2bba1fed561aa9c FT_modprobe_w_param.15
+#K= ef22493a8baadddc5dd0291577e413c8 FT_modprobe_w_param.16
 #K= 73a93377a823739e8aae44856a20fa7f FT_modprobe_w_param.17
-#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.18
+#K= ef22493a8baadddc5dd0291577e413c8 FT_modprobe_w_param.18
 #K= 10464b2c3e3972f05e93c609700f8fb2 FT_modprobe_w_param.19
 #K= 10464b2c3e3972f05e93c609700f8fb2 FT_modprobe_w_param.20
-#K= 07c1f81d5a58675a291dc77acd6938c4 FT_modprobe_w_param.21
-#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.22
-#K= b070066b0eb13a033446bd05850b15e2 FT_modprobe_w_param.23
-#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.24
-#K= 32ca47823c27e629e03c21aebfc25095 FT_modprobe_w_param.25
-#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.26
+#K= 69502938a4be4936847568d8aad027f6 FT_modprobe_w_param.21
+#K= ef22493a8baadddc5dd0291577e413c8 FT_modprobe_w_param.22
+#K= 51fe322a7f368d936d2292c951247b33 FT_modprobe_w_param.23
+#K= ef22493a8baadddc5dd0291577e413c8 FT_modprobe_w_param.24
+#K= 91391932971be1d599d19ba04d6f6a34 FT_modprobe_w_param.25
+#K= ef22493a8baadddc5dd0291577e413c8 FT_modprobe_w_param.26
 #K= 7b91db8e9f160aebb1ee87fab2232404 FT_modprobe_w_param.27
-#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.28
-#K= d6b0165e279e8b9d06fa637d17bb8b07 FT_modprobe_w_param.29
-#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.30
-#K= a067091b2133dfe203a1c53f7e5f8b00 FT_modprobe_w_param.31
-#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.32
-#K= 677ccaca4125771d6c42d5612de0b0b3 FT_modprobe_w_param.33
-#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.34
+#K= ef22493a8baadddc5dd0291577e413c8 FT_modprobe_w_param.28
+#K= 82bddad95d7ac6ecae367c7b63f1778b FT_modprobe_w_param.29
+#K= ef22493a8baadddc5dd0291577e413c8 FT_modprobe_w_param.30
+#K= 6686e8b91736913b0047202ca8f0f20e FT_modprobe_w_param.31
+#K= ef22493a8baadddc5dd0291577e413c8 FT_modprobe_w_param.32
+#K= 8d71e5a7ec153e0be606ca80c6125342 FT_modprobe_w_param.33
+#K= ef22493a8baadddc5dd0291577e413c8 FT_modprobe_w_param.34
 #K= ff5bf6afec9642da83d3dcdb5e732ab9 FT_modprobe_w_param.35
-#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.36
+#K= ef22493a8baadddc5dd0291577e413c8 FT_modprobe_w_param.36
 EOF
         # Read the K-recs and skip those for tests that can't run
         while read -r line; do

-- 
2.55.0

