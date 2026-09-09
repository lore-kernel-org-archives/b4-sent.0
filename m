From: Jim Cromie <jim.cromie@gmail.com>
Date: Tue, 08 Sep 2026 18:55:11 -0600
Subject: [PATCH v9 15/39] kbuild, dyndbg: Clean up builtin module-name
 ambiguities
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-dd-cmap-part2-clean-v9-15-3a3f621f4a10@gmail.com>
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
 Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788915300; l=22604;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=o5BhoVsyPCjFZAY5WF8Er8w5yvYQggmrzeLYncZznwY=;
 b=T03VQmX4nN9MMPVVixi1D9ThrCKOqhZvw22RNyTllBG037ZtBtE1+zp4W2fYNyufpXWHTlmUx
 RGXPAKSYW4PDFp/OpRZU29m/TmfqVBUQuo1Cx31kCcIZRjqT4E4Pmc8
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, dyndbg binds KBUILD_MODNAME into callsite & classmap
declarator-macros. While loadable modules have unique names enforced at
modprobe, for built-ins, its values suffer some collisions (e.g.
multiple distinct compilation units named "main", "core", or "init").

KBUILD_MODNAME defaults to the leaf of the pathname, so built-in
subsystems are fragmented into the names of their individual
implementation parts. The callsites remain adjacent in their subsystem
directories, but expose 278 separate module labels in
/proc/dynamic_debug/control instead of unified subsystem addresses.

Bind DDEBUG_MODNAME into all callsite and classmap declarator macros
instead. In include/linux/dynamic_debug.h, define DDEBUG_MODNAME to
cascade across KBUILD_DD_MODNAME, KBUILD_MODFILE, and KBUILD_MODNAME.

In scripts/Makefile.lib, compute KBUILD_DD_MODNAME with structured
precedence:
0. Check for per-target override: DD_MODNAME_<target-stem>.o
1. Check for directory-level override: DD_MODNAME in local Makefile
2. Fall back to automatic clean heuristic:
   - Strip leading "drivers/" and arch prefixes.
   - Map top-level built-in targets to directory names (e.g. power,
     init).
   - Unify multi-target shared helpers under containing subsystem paths
     (e.g. mmc/host, coco/sev, events/amd, kernel/cpu).
   - Sanitize commas, hyphens, and whitespace to prevent token
     splitting in column 2 of /proc/dynamic_debug/control.

In /proc/dynamic_debug/control on a default boot, unique built-in module
names drop from 278 to 211, consolidating 67 fragmented targets:

  Subsystem Group   Legacy Names (linux.git)      Consolidated Name (wk-A)
  ----------------  ----------------------------  ------------------------
  Power             snapshot, swap, suspend,      power
                    hibernate, main, em
  Kernel Init       main, init, init_64,          init
                    initramfs, do_mounts
  Sound / HDA       snd_hda_codec_*, snd_intel*   sound/hda/codecs,
                    snd_hda_core, snd_hda_intel   sound/hda/controllers
  TTY & Serial      8250, 8250_base, 8250_pci,    tty/serial,
                    8250_exar, serial_base        tty/serial/8250
  GPU / DRM         drm, drm_kms_helper,          gpu/drm, gpu/drm/display
                    bridge, display, clients      gpu/drm/clients, tiny
  ACPI & Platform   acpi, acpi_dma, acpi_x86,     acpi, acpi/numa,
                    numa, srat                    acpi/x86
  IOMMU & Perf      amd_node, dmar, iommu,        iommu/amd, iommu/intel,
                    ibs, events                   events/amd, events/intel
  Input             atkbd, psmouse, libps2        input/keyboard, mouse
  Filesystems       fuse, overlay, inotify_user   fs/fuse, fs/overlayfs,
                    sysfs, kernfs                 fs/notify/inotify
  Networking        tcp, tcp_input, tcp_cong,     net/core, net/ipv4,
                    tcp_cubic, arp, icmp          net/sched

This yields unambiguous, user-visible subsystem namespaces across both
built-in objects and loadable modules while maintaining compatibility
with wildcard queries (e.g. `module main` matching `[*/main]`).

Adjust documentation and selftests to track refreshed module names.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
Revision history (v9):
. implement subsystem-centric KBUILD_DD_MODNAME naming heuristic.
. unify multi-target shared helpers under containing subsystem path.
. eliminate whitespace splitting in control file column 2.
---
 Documentation/admin-guide/dynamic-debug-howto.rst  |  42 ++++---
 include/linux/dynamic_debug.h                      |  19 ++-
 kernel/power/Makefile                              |   2 +
 lib/dynamic_debug.c                                |   3 +-
 scripts/Makefile.lib                               |  26 ++++
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 137 +++++++++++----------
 6 files changed, 143 insertions(+), 86 deletions(-)

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
index baf5c0853f45..54a80e7fdbaf 100644
--- a/include/linux/dynamic_debug.h
+++ b/include/linux/dynamic_debug.h
@@ -10,6 +10,21 @@
 
 #define __DDEBUG_ARRAY_SIZE(arr) (sizeof(arr) / sizeof((arr)[0]))
 
+/*
+ * DDEBUG_MODNAME resolves from:
+ * 1. KBUILD_DD_MODNAME: Subsystem-scoped, sanitized name from scripts/Makefile.lib
+ *    (supports directory-level DD_MODNAME and per-target DD_MODNAME_<target>.o).
+ * 2. KBUILD_MODFILE: Path-based fallback for specialized or out-of-tree builds.
+ * 3. KBUILD_MODNAME: Default kernel module target name.
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
@@ -121,7 +136,7 @@ struct ddebug_class_param {
 	static struct ddebug_class_map __aligned(8) __used		\
 		__section("__dyndbg_classes") _var = {			\
 		.mod = THIS_MODULE,					\
-		.mod_name = KBUILD_MODNAME,				\
+		.mod_name = DDEBUG_MODNAME,				\
 		.base = _base,						\
 		.map_type = _maptype,					\
 		.class_names = _var##_classnames,			\
@@ -160,7 +175,7 @@ void __dynamic_ibdev_dbg(struct _ddebug *descriptor,
 #define DEFINE_DYNAMIC_DEBUG_METADATA_CLS(name, cls, fmt)	\
 	static struct _ddebug  __aligned(8)			\
 	__section("__dyndbg") name = {				\
-		.modname = KBUILD_MODNAME,			\
+		.modname = DDEBUG_MODNAME,			\
 		.function = __func__,				\
 		.filename = __FILE__,				\
 		.format = (fmt),				\
diff --git a/kernel/power/Makefile b/kernel/power/Makefile
index 773e2789412b..ddceacfd76d7 100644
--- a/kernel/power/Makefile
+++ b/kernel/power/Makefile
@@ -1,5 +1,7 @@
 # SPDX-License-Identifier: GPL-2.0
 
+DD_MODNAME := power
+
 ifeq ($(CONFIG_DYNAMIC_DEBUG), y)
 CFLAGS_swap.o                   := -DDEBUG
 CFLAGS_snapshot.o               := -DDEBUG
diff --git a/lib/dynamic_debug.c b/lib/dynamic_debug.c
index 2a69f86f973e..d4dbbd1a91ef 100644
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
index 0a4fdd8bd975..e129c4d10ed8 100644
--- a/scripts/Makefile.lib
+++ b/scripts/Makefile.lib
@@ -23,6 +23,32 @@ modname_flags  = -DKBUILD_MODNAME=$(call name-fix,$(modname)) \
 		 -D__KBUILD_MODNAME=$(call name-fix-token,$(modname))
 modfile_flags  = -DKBUILD_MODFILE=$(call stringify,$(modfile))
 
+# Dynamic debug subsystem modname with clean heuristic and override support
+dd_modname_override = $(strip $(firstword $(DD_MODNAME_$(target-stem).o) \
+					  $(DD_MODNAME)))
+dd_obj := $(strip $(filter-out .,\
+		$(patsubst drivers/%,%,\
+		$(patsubst arch/$(SRCARCH)/%,%,\
+		$(patsubst arch/%/,%,$(obj))))))
+dd_modname_default = $(strip $(if $(filter $(notdir $(obj)),$(__modname)),\
+			 $(__modname),\
+			 $(if $(filter main core common util init snapshot \
+				       process,$(__modname)),\
+			     $(dd_obj),\
+			     $(if $(word 2,$(__modname)),\
+				 $(dd_obj),\
+				 $(if $(dd_obj),$(dd_obj),$(__modname))))))
+dd_modname = $(strip $(or $(dd_modname_override),\
+			  $(dd_modname_default),\
+			  $(__modname)))
+dd-name-subst = $(subst $(comma),_,$(subst -,_,$(strip $1)))
+dd-name-fix-token = $(subst $(space),_,$(call dd-name-subst,$1))
+dd_tok = $(call dd-name-fix-token,$(dd_modname))
+dd_modname_flags = $(if $(dd_modname),\
+	-DKBUILD_DD_MODNAME=$(call stringify,$(dd_tok)))
+
+modfile_flags += $(dd_modname_flags)
+
 _c_flags       = $(filter-out $(CFLAGS_REMOVE_$(target-stem).o), \
                      $(filter-out $(ccflags-remove-y), \
                          $(KBUILD_CPPFLAGS) $(KBUILD_CFLAGS) $(ccflags-y)) \
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index 69a1787a4302..5ef6e313fa4b 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -308,98 +308,114 @@ function FT_grammar_errs {
     ddcmd =_
 }
 
-# these queries run against the builtin module: params, and change
-# flags.  The control file state-of-interest is found by path,
-# kernel/params.c, to avoid module keyword entirely
+# these queries run against the builtin file: kernel/params.c, and change
+# flags.  The control file state-of-interest is found by path $f,
+# perfectly binding the stimulus scope to the observation slice.
 function FT_basic_queries {
     v_echo "${GREEN}# BASIC_TESTS ${NC}"
     if [ $LACK_DD_BUILTIN -eq 1 ]; then
-	echo "SKIP - test requires params, which is a builtin module"
+	echo "SKIP - test requires dynamic_debug built into kernel"
 	return
     fi
+    local f='kernel/params.c'
     ddcmd =_ # zero everything
 
-    ddcmd "module params +mf" 'kernel/params.c'
-    ddcmd "module params +l"  'kernel/params.c'
-    ddcmd "module params -m"  'kernel/params.c'
-    ddcmd "module params =_"  'kernel/params.c'
+    ddcmd "file $f +mf" "$f"
+    ddcmd "file $f +l"  "$f"
+    ddcmd "file $f -m"  "$f"
+    ddcmd "file $f =_"  "$f"
 
     # multi-query commands split on ; on a single line
-    ddcmd "module params +mf ; module params func parse_args +sl"  'kernel/params.c'
+    ddcmd "file $f +mf ; file $f func parse_args +sl" "$f"
 
     # verify multi-cmd input, newline separated, with embedded comments
     ddcmd =_ # reset before multiline query to capture full transition
-    ddcmd "module params =_		# clear params
-      module params +ml			# set flags
-      module params func parse_args +fs # set other flags" \
-	  'kernel/params.c'
+    ddcmd "file $f =_		# clear params
+      file $f +ml		# set flags
+      file $f func parse_args +fs # set other flags" \
+	  "$f"
 
     # clear flags and verify
-    ddcmd "module params =_"  'kernel/params.c'
+    ddcmd "file $f =_" "$f"
 }
 
 function FT_path_module_queries {
     v_echo "${GREEN}# TEST_PATH_MODULE_QUERIES ${NC}"
     ddcmd =_
 
-    # Find how many 'main' modules we have in total (by basename)
-    # Use a precise OR pattern to match exactly [main] or [*/main] and avoid irqdomain
-    local total_main=$(grep -c "\[main\]\|\[[^]]*/main\]" /proc/dynamic_debug/control)
-    v_echo "# found $total_main total 'main' modules"
+    # Find a module with a path/slash in its name from the control file
+    local slashed_mod
+    slashed_mod=$(awk -F'[][]' \
+        '/^[^#:]+:[0-9]+/ { if ($2 ~ /\//) { print $2; exit } }' \
+        /proc/dynamic_debug/control)
 
-    if [ $total_main -eq 0 ]; then
-        echo "SKIP - no 'main' modules found to test slashes"
+    if [ -z "$slashed_mod" ]; then
+        echo "SKIP - no slashed module found to test paths"
         return
     fi
 
-    # Verify a robust, cross-query state-interaction handshake between
-    # narrow path and wide wildcard/basename queries. This dynamically
-    # proves they interact with the exact same underlying callsites!
+    local base_mod=$(basename "$slashed_mod")
+    local slice_pattern="\[$slashed_mod\]"
+
+    v_echo "# testing path module queries for module: $slashed_mod (basename: $base_mod)"
+
+    # 1. Turn ON specific path
+    ddcmd "module '$slashed_mod' +p"
+    local hash_path=$(slice_and_hash_ddctrl "$slice_pattern")
 
-    # 1. Turn ON specific path, verified under '[init/main]' range
-    ddcmd "module 'init/main' +p" "init/main.c"
+    # 2. Turn OFF using wide wildcard query
+    ddcmd "module '*/$base_mod' =_"
+    local hash_off=$(slice_and_hash_ddctrl "$slice_pattern")
 
-    # 2. Turn OFF using wide wildcard query,
-    ddcmd "module '*/main' =_" "init/main.c"
+    # 3. Turn ON using wide unscoped basename
+    ddcmd "module '$base_mod' +p"
+    local hash_base=$(slice_and_hash_ddctrl "$slice_pattern")
 
-    # 3. Turn ON using wide unscoped basename,
-    ddcmd "module 'main' +p" "init/main.c"
+    # 4. Turn OFF using specific narrow path
+    ddcmd "module '$slashed_mod' =_"
 
-    # 4. Turn OFF using specific narrow path,
-    ddcmd "module 'init/main' =_" "init/main.c"
+    if [ "$hash_path" != "$hash_base" ]; then
+        echo -e "${RED}: Path vs Basename equivalence check failed! " \
+            "Fingerprints do not match.${NC}"
+        exit $ksft_fail
+    else
+        v_echo "${GREEN}: Proven: Slashed path and basename module queries match!${NC}"
+    fi
+
+    ddcmd =_
 }
 
 function FT_hyphen_underscore {
     v_echo "${GREEN}# TEST_HYPHEN_UNDERSCORE ${NC}"
     ddcmd =_
 
-    # Find a module with a hyphen in its name (e.g., from the control file)
-    local mod_with_hyphen
-    mod_with_hyphen=$(awk -F'[][]' \
-        '/^[^#:]+:[0-9]+/ { if ($2 ~ /-/) { print $2; exit } }' \
+    # Find a module with an underscore in its name (e.g., from the control file)
+    local mod_with_underscore
+    mod_with_underscore=$(awk -F'[][]' \
+        '/^[^#:]+:[0-9]+/ { if ($2 ~ /_/) { print $2; exit } }' \
         /proc/dynamic_debug/control)
 
-    if [ -z "$mod_with_hyphen" ]; then
-        echo "SKIP - no module with hyphen found in /proc/dynamic_debug/control"
+    if [ -z "$mod_with_underscore" ]; then
+        echo "SKIP - no module with underscore found in /proc/dynamic_debug/control"
         return
     fi
 
-    v_echo "# testing hyphen/underscore equivalence for module: $mod_with_hyphen"
-    local mod_with_underscore=$(echo "$mod_with_hyphen" | tr '-' '_')
+    local mod_with_hyphen=$(echo "$mod_with_underscore" | tr '_' '-')
+    local base_underscore=$(basename "$mod_with_underscore")
     local base_hyphen=$(basename "$mod_with_hyphen")
-    local slice_pattern="\[[^]]*$base_hyphen\]"
+    local slice_pattern="\[$mod_with_underscore\]"
+
+    v_echo "# testing hyphen/underscore equivalence for module: $mod_with_underscore (hyphen: $mod_with_hyphen)"
 
     # 1. Enable using literal hyphen name, and record the state fingerprint
     v_echo "#   trying hyphen name: $mod_with_hyphen"
-    ddcmd "module $mod_with_hyphen +p"
-    # verify_control_slice "$slice_pattern"
+    ddcmd "module '$mod_with_hyphen' +p"
     local hash_hyphen=$(slice_and_hash_ddctrl "$slice_pattern")
 
     # 2. Disable and enable using underscore name, record the state fingerprint
     ddcmd =_
     v_echo "#   trying underscore name: $mod_with_underscore"
-    ddcmd "module $mod_with_underscore +p"
-    # verify_control_slice "$slice_pattern"
+    ddcmd "module '$mod_with_underscore' +p"
     local hash_underscore=$(slice_and_hash_ddctrl "$slice_pattern")
 
     # Real-time mathematical proof of hyphen/underscore name equivalence!
@@ -413,19 +429,17 @@ function FT_hyphen_underscore {
         v_echo "${GREEN}: Proven: Hyphen/Underscore literal name equivalence matches!${NC}"
     fi
 
-        # Try kbasename with hyphen (if it has a path)
+    # 3. Try kbasename with hyphen (if it has a path)
     if [ "$base_hyphen" != "$mod_with_hyphen" ]; then
         ddcmd =_
         v_echo "#   trying hyphen kbasename: $base_hyphen"
-        ddcmd "module $base_hyphen +pmf"
-        # verify_control_slice "$slice_pattern" # omitted: slice contains dynamic
-        # module info which drifts across different targets
+        ddcmd "module '$base_hyphen' +pmf"
         local hash_base_hyphen=$(slice_and_hash_ddctrl "$slice_pattern")
 
         # Prove kbasename hyphen name matches literal path hyphen name (with different flags)!
         v_echo "#   trying full path hyphen with pmf flags"
         ddcmd =_
-        ddcmd "module $mod_with_hyphen +pmf"
+        ddcmd "module '$mod_with_hyphen' +pmf"
         local hash_path_pmf=$(slice_and_hash_ddctrl "$slice_pattern")
         if [ "$hash_path_pmf" != "$hash_base_hyphen" ]; then
             echo -e "${RED}: Hyphen kbasename check failed! " \
@@ -438,17 +452,13 @@ function FT_hyphen_underscore {
     fi
 
     # 4. Try kbasename with underscore
-    local base_underscore=$(echo "$base_hyphen" | tr '-' '_')
     ddcmd =_
     v_echo "#   trying underscore kbasename: $base_underscore"
-    ddcmd "module $base_underscore +pmf"
-    # verify_control_slice "$slice_pattern" # omitted: slice contains dynamic
-    # module info which drifts across different targets
+    ddcmd "module '$base_underscore' +pmf"
     local hash_base_underscore=$(slice_and_hash_ddctrl "$slice_pattern")
 
     # Real-time mathematical proof of hyphen/underscore kbasename equivalence!
-    if [ "$hash_base_hyphen" != "$hash_base_underscore" ] && \
-       [ -n "$hash_base_hyphen" ]; then
+    if [ -n "$hash_base_hyphen" ] && [ "$hash_base_hyphen" != "$hash_base_underscore" ]; then
         echo -e "${RED}: Hyphen/Underscore kbasename equivalence check " \
             "failed! Fingerprints do not match.${NC}"
         exit $ksft_fail
@@ -460,7 +470,6 @@ function FT_hyphen_underscore {
     ddcmd =_
 }
 
-
 # testing classmap-based query enablers and class configurations
 function FT_test_classes {
     v_echo "${GREEN}# TEST_CLASSES - classmap-based query enablers and class configs ${NC}"
@@ -590,7 +599,7 @@ builtin_tests=(
     FT_grammar_ok
     FT_grammar_errs
     FT_basic_queries
-    #FT_path_module_queries
+    FT_path_module_queries
     FT_hyphen_underscore
 )
 
@@ -657,13 +666,13 @@ function GOLDEN_RECORDS {
 #K= 781995971d28f732a792522f3c56cdd3 FT_grammar_errs.40
 #K= 6614a677d9f9ac09d9825b4e989d2c42 FT_grammar_errs.41
 #K= 70de9afed457a6be9f9c3c81cbd6d4d5 FT_grammar_errs.42
-#K= 6e8599556a312200fb6d484565b6c52f FT_basic_queries.1
-#K= db17180b59444e5e34a8fc20c40e4530 FT_basic_queries.2
-#K= f7bd56bd407ff255ef2e3b5fb093ae6a FT_basic_queries.3
-#K= 4ce44468b3b5f80ae42ade1f261b952f FT_basic_queries.4
-#K= 02e4fd94602e108cb89bfc70d47a5dad FT_basic_queries.5
-#K= f03a7ca7316e8db4c0e16523dc41e75d FT_basic_queries.6
-#K= c518a50ba30ba8099d0dc874a27ecf16 FT_basic_queries.7
+#K= 3c445fb23d701041e920a2a6d2b022c7 FT_basic_queries.1
+#K= d8eb8f226860aa558fb8a98097f05be9 FT_basic_queries.2
+#K= 6a86bb9209a3a0492bc6c2d29f4d5e52 FT_basic_queries.3
+#K= 90804574a5336971465f92d6cc3aa7fb FT_basic_queries.4
+#K= f2b4f24fece9c55f5a5d28323c2019f8 FT_basic_queries.5
+#K= 8c2dd1164fbcefb721345ce62a864a37 FT_basic_queries.6
+#K= 4542e1e5e7eadcbe8f90a9c934635618 FT_basic_queries.7
 EOF
         # Read the K-recs and skip those for tests that can't run
         while read -r line; do

-- 
2.55.0

