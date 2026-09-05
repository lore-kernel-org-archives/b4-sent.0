From: Jim Cromie <jim.cromie@gmail.com>
Date: Sat, 05 Sep 2026 12:13:32 -0600
Subject: [PATCH v8 18/43] kbuild, dyndbg: clean up builtin module-name
 ambiguities
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260905-dd-cmap-part2-clean-v8-18-a4cc0674f6fd@gmail.com>
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
 linux-kbuild@vger.kernel.org, Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788632017; l=9818;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=YwLSQSsgq3qWTFnsyfZwa87o/14kan2U5iUpRpezoLY=;
 b=H4n0ZvsooJEE4EPOuNoZaSpkfs4IE36NjIeocF6djxh510cWwSm28DC9nf69F6h70zd/2/9IU
 xouDjOTtQVmBEzu7s5s9W0azk8ugmi0NuPDQ15lgzCAdmPWa8Co6Zxn
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, dyndbg gets its module name from KBUILD_MODNAME. This works
well for loadable modules, because the loader requires that the names
are unique.  For builtins theres no such guarantee, KBUILD_MODNAME
gives us several unrelated builtin modules named "main".

So we adapt DEFINE_DYNAMIC_DEBUG_METADATA_CLS to get its .modname from
DDEBUG_MODNAME instead, and derive that from either KBUILD_MODNAME for
loadable modules, or KBUILD_DD_MODNAME.

KBUILD_DD_MODNAME derives from KBUILD_MODFILE, which worked (and was
unique), but it appends the module target to the directory path,
producing redundant tails for subsystem-dedicated directories (e.g.,
"arch/x86/kvm/kvm", "drivers/gpu/drm/i915/i915").

Finally, we land upon:
0. Check for per-target override: DD_MODNAME_<target>.o
1. Check for directory-level override: DD_MODNAME in local Makefile
2. Fall back to automatic clean heuristic: strip leading "drivers/" and
   deduplicate the tail if the directory name matches the module target.

This gives us nice clean subsystem namespaces ("arch/x86/kvm",
"gpu/drm/i915") without altering existing KBUILD_* symbols.

Adjust documentation and selftests for unique subsystem module names.

NB: maybe KBUILD_MODNAME is malleable for builtins ?

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 Documentation/admin-guide/dynamic-debug-howto.rst  | 42 ++++++++++++----------
 include/linux/dynamic_debug.h                      | 17 +++++++--
 lib/dynamic_debug.c                                |  3 +-
 scripts/Makefile.lib                               |  9 +++++
 .../selftests/dynamic_debug/dyndbg_selftest.sh     |  7 ++--
 5 files changed, 54 insertions(+), 24 deletions(-)

diff --git a/Documentation/admin-guide/dynamic-debug-howto.rst b/Documentation/admin-guide/dynamic-debug-howto.rst
index 9c2f096ed1d8..99bbae37d34e 100644
--- a/Documentation/admin-guide/dynamic-debug-howto.rst
+++ b/Documentation/admin-guide/dynamic-debug-howto.rst
@@ -38,12 +38,12 @@ You can view the currently configured behaviour in the *prdbg* catalog::
 
   :#> head -n7 /proc/dynamic_debug/control
   # filename:lineno [module]function flags format
-  init/main.c:1179 [main]initcall_blacklist =_ "blacklisting initcall %s\n"
-  init/main.c:1218 [main]initcall_blacklisted =_ "initcall %s blacklisted\n"
-  init/main.c:1424 [main]run_init_process =_ "  with arguments:\n"
-  init/main.c:1426 [main]run_init_process =_ "    %s\n"
-  init/main.c:1427 [main]run_init_process =_ "  with environment:\n"
-  init/main.c:1429 [main]run_init_process =_ "    %s\n"
+  init/main.c:1179 [init/main]initcall_blacklist =_ "blacklisting initcall %s\n"
+  init/main.c:1218 [init/main]initcall_blacklisted =_ "initcall %s blacklisted\n"
+  init/main.c:1424 [init/main]run_init_process =_ "  with arguments:\n"
+  init/main.c:1426 [init/main]run_init_process =_ "    %s\n"
+  init/main.c:1427 [init/main]run_init_process =_ "  with environment:\n"
+  init/main.c:1429 [init/main]run_init_process =_ "    %s\n"
 
 The 3rd space-delimited column shows the current flags, preceded by
 a ``=`` for easy use with grep/cut. ``=p`` shows enabled callsites.
@@ -59,10 +59,10 @@ query/commands to the control file.  Example::
 
   :#> ddcmd '-p; module main func run* +p'
   :#> grep =p /proc/dynamic_debug/control
-  init/main.c:1424 [main]run_init_process =p "  with arguments:\n"
-  init/main.c:1426 [main]run_init_process =p "    %s\n"
-  init/main.c:1427 [main]run_init_process =p "  with environment:\n"
-  init/main.c:1429 [main]run_init_process =p "    %s\n"
+  init/main.c:1424 [init/main]run_init_process =p "  with arguments:\n"
+  init/main.c:1426 [init/main]run_init_process =p "    %s\n"
+  init/main.c:1427 [init/main]run_init_process =p "  with environment:\n"
+  init/main.c:1429 [init/main]run_init_process =p "    %s\n"
 
 Error messages go to console/syslog::
 
@@ -161,17 +161,21 @@ file
 	file kernel/freezer.c	# ie column 1 of control file
 	file drivers/usb/*	# all callsites under it
 	file inode.c:start_*	# parse :tail as a func (above)
-	file inode.c:1-100	# parse :tail as a line-range (above)
+	file inode.c:1-100	# parse :tail as a line-range (below)
 
 module
-    The given string is compared against the module name
-    of each callsite.  The module name is the string as
-    seen in ``lsmod``, i.e. without the directory or the ``.ko``
-    suffix and with ``-`` changed to ``_``.  Examples::
-
-	module sunrpc
-	module nfsd
-	module drm*	# both drm, drm_kms_helper
+    The query string is compared against the subsystem module name of
+    each callsite, as shown in the control file, or its simple name.
+    The simple module name is the string as seen in ``lsmod``,
+    i.e. without the directory or the ``.ko`` suffix and with ``-``
+    changed to ``_``.
+    Examples::
+
+        module nfsd        # simple modname (as from lsmod)
+	module init/main   # subsystem modname (as in control file)
+	module */main	   # any subsystem ending in main
+        module main	   # simple modname, selects same as above
+	module drm*	   # both drm, drm_kms_helper
 
 format
     The given string is searched for in the dynamic debug format
diff --git a/include/linux/dynamic_debug.h b/include/linux/dynamic_debug.h
index baf5c0853f45..1a8848670fcf 100644
--- a/include/linux/dynamic_debug.h
+++ b/include/linux/dynamic_debug.h
@@ -10,6 +10,19 @@
 
 #define __DDEBUG_ARRAY_SIZE(arr) (sizeof(arr) / sizeof((arr)[0]))
 
+/*
+ * Pick the best name for the module:
+ * KBUILD_MODFILE includes the path (e.g., drivers/usb/core/usbcore) for built-ins.
+ * Fall back to KBUILD_MODNAME for modules (loader requires unique names).
+ */
+#ifdef KBUILD_DD_MODNAME
+# define DDEBUG_MODNAME KBUILD_DD_MODNAME
+#elif defined(KBUILD_MODFILE)
+# define DDEBUG_MODNAME KBUILD_MODFILE
+#else
+# define DDEBUG_MODNAME KBUILD_MODNAME
+#endif
+
 /*
  * An instance of this structure is created in a special
  * ELF section at every dynamic debug callsite.  At runtime,
@@ -121,7 +134,7 @@ struct ddebug_class_param {
 	static struct ddebug_class_map __aligned(8) __used		\
 		__section("__dyndbg_classes") _var = {			\
 		.mod = THIS_MODULE,					\
-		.mod_name = KBUILD_MODNAME,				\
+		.mod_name = DDEBUG_MODNAME,				\
 		.base = _base,						\
 		.map_type = _maptype,					\
 		.class_names = _var##_classnames,			\
@@ -160,7 +173,7 @@ void __dynamic_ibdev_dbg(struct _ddebug *descriptor,
 #define DEFINE_DYNAMIC_DEBUG_METADATA_CLS(name, cls, fmt)	\
 	static struct _ddebug  __aligned(8)			\
 	__section("__dyndbg") name = {				\
-		.modname = KBUILD_MODNAME,			\
+		.modname = DDEBUG_MODNAME,			\
 		.function = __func__,				\
 		.filename = __FILE__,				\
 		.format = (fmt),				\
diff --git a/lib/dynamic_debug.c b/lib/dynamic_debug.c
index b2892be2de36..2f18d2970aa6 100644
--- a/lib/dynamic_debug.c
+++ b/lib/dynamic_debug.c
@@ -242,7 +242,8 @@ static int ddebug_change(const struct ddebug_query *query,
 
 		/* match against the module name */
 		if (query->module &&
-		    !match_wildcard(query->module, dt->mod_name))
+		    !match_wildcard_hyphen(query->module, dt->mod_name) &&
+		    !match_wildcard_hyphen(query->module, kbasename(dt->mod_name)))
 			continue;
 
 		if (query->class_string) {
diff --git a/scripts/Makefile.lib b/scripts/Makefile.lib
index 0a4fdd8bd975..2d1544b30185 100644
--- a/scripts/Makefile.lib
+++ b/scripts/Makefile.lib
@@ -23,6 +23,15 @@ modname_flags  = -DKBUILD_MODNAME=$(call name-fix,$(modname)) \
 		 -D__KBUILD_MODNAME=$(call name-fix-token,$(modname))
 modfile_flags  = -DKBUILD_MODFILE=$(call stringify,$(modfile))
 
+# Dynamic debug subsystem modname with clean heuristic and Makefile override support
+dd_modname_override = $(firstword $(DD_MODNAME_$(target-stem).o) $(DD_MODNAME))
+dd_obj := $(patsubst drivers/%,%,$(obj))
+dd_modname_default = $(if $(filter $(notdir $(dd_obj)),$(__modname)),$(dd_obj),$(addprefix $(dd_obj)/,$(__modname)))
+dd_modname = $(if $(dd_modname_override),$(dd_modname_override),$(dd_modname_default))
+dd_modname_flags = -DKBUILD_DD_MODNAME=$(call stringify,$(dd_modname))
+
+modfile_flags += $(dd_modname_flags)
+
 _c_flags       = $(filter-out $(CFLAGS_REMOVE_$(target-stem).o), \
                      $(filter-out $(ccflags-remove-y), \
                          $(KBUILD_CPPFLAGS) $(KBUILD_CFLAGS) $(ccflags-y)) \
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index 8e881b5c860c..fac5a0eab32d 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -462,7 +462,6 @@ function FT_hyphen_underscore {
     ddcmd =_
 }
 
-
 # testing classmap-based query enablers and class configurations
 function FT_test_classes {
     v_echo "${GREEN}# TEST_CLASSES - classmap-based query enablers and class configs ${NC}"
@@ -592,7 +591,7 @@ builtin_tests=(
     FT_grammar_ok
     FT_grammar_errs
     FT_basic_queries
-    #FT_path_module_queries
+    FT_path_module_queries
     FT_hyphen_underscore
 )
 
@@ -666,6 +665,10 @@ function GOLDEN_RECORDS {
 #K= de950a3e60669fdd58d0a8c2867a056d FT_basic_queries.5
 #K= 2ff49f0c4d18ec99bcb1c30840fe8afc FT_basic_queries.6
 #K= 9a1b13c32a15363dcf93913308edeea5 FT_basic_queries.7
+#K= 4b902c159d7f08f91377bf0a353e0051 FT_path_module_queries.1
+#K= bede904b02278e5648bb7a8243be8d98 FT_path_module_queries.2
+#K= 4b902c159d7f08f91377bf0a353e0051 FT_path_module_queries.3
+#K= bede904b02278e5648bb7a8243be8d98 FT_path_module_queries.4
 EOF
         # Read the K-recs and skip those for tests that can't run
         while read -r line; do

-- 
2.55.0

