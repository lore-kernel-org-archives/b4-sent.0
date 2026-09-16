From: Jim Cromie <jim.cromie@gmail.com>
Date: Wed, 16 Sep 2026 09:33:06 -0600
Subject: [PATCH v10 14/38] dyndbg: Bind callsites and classmaps to
 DDEBUG_MODNAME
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260916-dd-cmap-part2-clean-v10-14-af4cf4767707@gmail.com>
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
 Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789572777; l=5456;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=QBYHFOAGtPUZQ0XtQfqknu+wV/y2/uE7ShWvPiZO9qg=;
 b=UBn3jzJiK8zgbFC+xg1+b0mfu0MV0P6ogZrSO9KhMbgJN3fmX3t1Ckby9SBoVGQbUb2xySmUT
 wPCVCh19BSuABrXQCh6w3mrUrd0KkNkohzY3imdW5yTotY8VgOllM9c
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, dyndbg binds KBUILD_MODNAME directly into callsite and
classmap declarator macros.

For built-ins, KBUILD_MODNAME defaults to the basename of the source
file. For many subsystems, this fragments what should be a single
module into separate file basenames: kernel/power/ produces "main",
"suspend", "hibernate", "snapshot", and "swap" when all should be
"power". Conversely, multiple unrelated built-in files across the tree
(init/main.c, kernel/power/main.c) all collide under "main".

While consolidating these fragments into unified subsystem names is
desirable for query targeting and classmaps, attempting a bulk heuristic
renaming across Kbuild introduces broad churn and disrupts control file
output across the kernel. Module naming should remain under explicit
maintainer control instead.

Define DDEBUG_MODNAME in include/linux/dynamic_debug.h guarded with
#ifndef, defaulting cleanly to KBUILD_MODNAME. Bind DDEBUG_MODNAME into
callsite and classmap declarator macros instead of hardcoding
KBUILD_MODNAME.

This establishes an opt-in hook allowing subsystem maintainers to
consolidate their module fragments if desired (e.g. via
ccflags-y += -DDDEBUG_MODNAME='"power"' in a subsystem Makefile)
while preserving existing module-name invariants by default.

What's Unchanged:
- Default module names remain strictly identical to KBUILD_MODNAME.
- Zero callsite memory overhead or layout changes in struct _ddebug.
- dynamic_debug/control output remains unchanged across the tree.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 include/linux/dynamic_debug.h                      | 12 +++++++--
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 29 +++++++++++-----------
 2 files changed, 25 insertions(+), 16 deletions(-)

diff --git a/include/linux/dynamic_debug.h b/include/linux/dynamic_debug.h
index baf5c0853f45..85863e24ad13 100644
--- a/include/linux/dynamic_debug.h
+++ b/include/linux/dynamic_debug.h
@@ -10,6 +10,14 @@
 
 #define __DDEBUG_ARRAY_SIZE(arr) (sizeof(arr) / sizeof((arr)[0]))
 
+/*
+ * DDEBUG_MODNAME: Subsystem/module name hook for callsites and classmaps.
+ * Defaults to KBUILD_MODNAME.
+ */
+#ifndef DDEBUG_MODNAME
+#define DDEBUG_MODNAME KBUILD_MODNAME
+#endif
+
 /*
  * An instance of this structure is created in a special
  * ELF section at every dynamic debug callsite.  At runtime,
@@ -121,7 +129,7 @@ struct ddebug_class_param {
 	static struct ddebug_class_map __aligned(8) __used		\
 		__section("__dyndbg_classes") _var = {			\
 		.mod = THIS_MODULE,					\
-		.mod_name = KBUILD_MODNAME,				\
+		.mod_name = DDEBUG_MODNAME,				\
 		.base = _base,						\
 		.map_type = _maptype,					\
 		.class_names = _var##_classnames,			\
@@ -160,7 +168,7 @@ void __dynamic_ibdev_dbg(struct _ddebug *descriptor,
 #define DEFINE_DYNAMIC_DEBUG_METADATA_CLS(name, cls, fmt)	\
 	static struct _ddebug  __aligned(8)			\
 	__section("__dyndbg") name = {				\
-		.modname = KBUILD_MODNAME,			\
+		.modname = DDEBUG_MODNAME,			\
 		.function = __func__,				\
 		.filename = __FILE__,				\
 		.format = (fmt),				\
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index 972f12c70a8e..09a8dbf239dc 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -267,34 +267,35 @@ function FT_grammar_errs {
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
 
 # Built-in Feature Tests (Can run on any CONFIG_DYNAMIC_DEBUG kernel, modular or monolithic)

-- 
2.55.0

