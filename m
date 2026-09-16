From: Jim Cromie <jim.cromie@gmail.com>
Date: Wed, 16 Sep 2026 09:33:20 -0600
Subject: [PATCH v10 28/38] dyndbg-API: promote DYNAMIC_DEBUG_CLASSMAP_PARAM
 to API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260916-dd-cmap-part2-clean-v10-28-af4cf4767707@gmail.com>
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
 Jim Cromie <jim.cromie@gmail.com>, 
 Louis Chauvet <louis.chauvet@bootlin.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789572777; l=15336;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=HeXIsZix2F/mOCg1sqddVl9Q55ZdM/0ngfkTnOZFN/0=;
 b=qCciUY2UpzGYTtl0f/nnyEqLb2pe7bcDXbs+ERk+VNZ83zaVuMI3jl9oyop5oVaeg2h02ydun
 1d08JQm3JFWBXHl/jTdz0OibS+B4w4RqEEMrIwPvrbOX/2HfoLfX/J5
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

move the DYNAMIC_DEBUG_CLASSMAP_PARAM macro from test-dynamic-debug.c into
the header, and refine it, by distinguishing the 2 use cases:

1.DYNAMIC_DEBUG_CLASSMAP_PARAM_REF
    for DRM, to pass in extern __drm_debug by name.
    dyndbg keeps bits in it, so drm can still use it as before

2.DYNAMIC_DEBUG_CLASSMAP_PARAM
    new user (test_dynamic_debug) doesn't need to share state,
    declares a u32 to store the bitvec.

__DYNAMIC_DEBUG_CLASSMAP_PARAM
   bottom layer - allocate,init a ddebug-class-param, module-param-cb.

Also add stub macros, clean up and improve comments in test-code, and
add MODULE_DESCRIPTIONs.

cc: linux-doc@vger.kernel.org
Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
Reviewed-by: Louis Chauvet <louis.chauvet@bootlin.com>
---
v10:
. define _DPRINTK_CLASSBITS_INIT and initialize static state bitvector.
. add module_param_named fallback for DYNAMIC_DEBUG_CLASSMAP_PARAM* in !CONFIG_DYNAMIC_DEBUG.

v9:
. fix 4-argument signature for DYNAMIC_DEBUG_CLASSMAP_PARAM_REF fallback macro stub.
. update format specifier from %d to %u for inrep in ddebug_class_param_clamp_input().
. drop duplicate v2pr_info() line in param_set_dyndbg_module_classes().
. drop unused CLASSMAP_BITMASK(width, base) define in test_dynamic_debug.c.
---
 include/linux/dynamic_debug.h                      | 51 ++++++++++++++
 lib/dynamic_debug.c                                | 77 +++++++++++-----------
 lib/test_dynamic_debug.c                           | 55 ++++++----------
 lib/test_dynamic_debug_submod.c                    |  9 ++-
 .../selftests/dynamic_debug/dyndbg_selftest.sh     |  2 +-
 5 files changed, 118 insertions(+), 76 deletions(-)

diff --git a/include/linux/dynamic_debug.h b/include/linux/dynamic_debug.h
index 26c858588eb1..3114f4f28be4 100644
--- a/include/linux/dynamic_debug.h
+++ b/include/linux/dynamic_debug.h
@@ -60,6 +60,8 @@ struct _ddebug {
 #else
 #define _DPRINTK_FLAGS_DEFAULT 0
 #endif
+#define _DPRINTK_CLASSBITS_INIT ((_DPRINTK_FLAGS_DEFAULT & _DPRINTK_FLAGS_PRINT) ? ~0U : 0U)
+
 	unsigned int flags:8;
 #ifdef CONFIG_JUMP_LABEL
 	union {
@@ -286,6 +288,44 @@ struct ddebug_class_param {
 		.offset = _offset					\
 	}
 
+/**
+ * DYNAMIC_DEBUG_CLASSMAP_PARAM - control a ddebug-classmap from a sys-param
+ * @_name:  sysfs node name
+ * @_var:   name of the classmap var defining the controlled classes/bits
+ * @_flags: flags to be toggled, typically just 'p'
+ *
+ * Creates a sysfs-param to control the classes defined by the
+ * exported classmap, with bits 0..N-1 mapped to the classes named.
+ * This version keeps class-state in a private long int.
+ */
+#define DYNAMIC_DEBUG_CLASSMAP_PARAM(_name, _var, _flags)		\
+	static u32 _name##_bvec = _DPRINTK_CLASSBITS_INIT;		\
+	__DYNAMIC_DEBUG_CLASSMAP_PARAM(_name, _name##_bvec, _var, _flags)
+
+/**
+ * DYNAMIC_DEBUG_CLASSMAP_PARAM_REF - wrap a classmap with a controlling sys-param
+ * @_name:  sysfs node name
+ * @_bits:  name of the module's u32 bit-vector, ex: __drm_debug
+ * @_var:   name of the (exported) classmap var defining the classes/bits
+ * @_flags: flags to be toggled, typically just 'p'
+ *
+ * Creates a sysfs-param to control the classes defined by the
+ * exported clasmap, with bits 0..N-1 mapped to the classes named.
+ * This version keeps class-state in user @_bits.  This lets drm check
+ * __drm_debug elsewhere too.
+ */
+#define DYNAMIC_DEBUG_CLASSMAP_PARAM_REF(_name, _bits, _var, _flags)	\
+	__DYNAMIC_DEBUG_CLASSMAP_PARAM(_name, _bits, _var, _flags)
+
+#define __DYNAMIC_DEBUG_CLASSMAP_PARAM(_name, _bits, _var, _flags)	\
+	static struct ddebug_class_param _name##_##_flags = {		\
+		.bits = &(_bits),					\
+		.flags = #_flags,					\
+		.map = &(_var),						\
+	};								\
+	module_param_cb(_name, &param_ops_dyndbg_classes,		\
+			&_name##_##_flags, 0600)
+
 extern __printf(2, 3)
 void __dynamic_pr_debug(struct _ddebug *descriptor, const char *fmt, ...);
 
@@ -466,9 +506,20 @@ void __dynamic_ibdev_dbg(struct _ddebug *descriptor,
 #include <linux/errno.h>
 #include <linux/printk.h>
 
+#if defined(DEBUG)
+#define _DPRINTK_CLASSBITS_INIT ~0U
+#else
+#define _DPRINTK_CLASSBITS_INIT 0U
+#endif
+
 #define DYNAMIC_DEBUG_CLASSMAP_DEFINE(_var, _mapty, _base, ...)
 #define DYNAMIC_DEBUG_CLASSMAP_USE(_var)
 #define DYNAMIC_DEBUG_CLASSMAP_USE_(_var, _offset)
+#define DYNAMIC_DEBUG_CLASSMAP_PARAM(_name, _var, _flags)		\
+	static u32 _name##_bvec = _DPRINTK_CLASSBITS_INIT;		\
+	module_param_named(_name, _name##_bvec, uint, 0600)
+#define DYNAMIC_DEBUG_CLASSMAP_PARAM_REF(_name, _bits, _var, _flags)	\
+	module_param_named(_name, _bits, uint, 0600)
 #define DEFINE_DYNAMIC_DEBUG_METADATA(name, fmt)
 #define DYNAMIC_DEBUG_BRANCH(descriptor) false
 #define DECLARE_DYNDBG_CLASSMAP(...)
diff --git a/lib/dynamic_debug.c b/lib/dynamic_debug.c
index 7736fb3d3b79..2347d13e1d30 100644
--- a/lib/dynamic_debug.c
+++ b/lib/dynamic_debug.c
@@ -697,9 +697,42 @@ static int ddebug_apply_class_bitmap(const struct ddebug_class_param *dcp,
 
 #define CLASSMAP_BITMASK(width) ((width) >= 32 ? ~0U : (1U << (width)) - 1)
 
-/*
- * param-setter helper to validate numeric input, clamp its value by
- * the classmap type and size, and apply the bits.
+static void __maybe_unused ddebug_class_param_clamp_input(u32 *inrep, const struct kernel_param *kp)
+{
+	const struct ddebug_class_param *dcp = kp->arg;
+	const struct ddebug_class_map *map = dcp->map;
+
+	switch (map->map_type) {
+	case DD_CLASS_TYPE_DISJOINT_BITS:
+		/* expect bits. mask and warn if too many */
+		if (*inrep & ~CLASSMAP_BITMASK(map->length)) {
+			pr_warn("%s: input: 0x%x exceeds mask: 0x%x, masking\n",
+				KP_NAME(kp), *inrep, CLASSMAP_BITMASK(map->length));
+			*inrep &= CLASSMAP_BITMASK(map->length);
+		}
+		break;
+	case DD_CLASS_TYPE_LEVEL_NUM:
+		/* input is bitpos, of highest verbosity to be enabled */
+		if (*inrep > map->length) {
+			pr_warn("%s: level:%u exceeds max:%d, clamping\n",
+				KP_NAME(kp), *inrep, map->length);
+			*inrep = map->length;
+		}
+		break;
+	}
+}
+
+/**
+ * param_set_dyndbg_classes - class FOO >control
+ * @instr: string echo>d to sysfs, input depends on map_type
+ * @kp:    kp->arg has state: bits/lvl, map, map_type
+ * @mod_name: module name or null for all modules with the classes
+ *
+ * Enable/disable prdbgs by their class, as given in the arguments to
+ * DECLARE_DYNDBG_CLASSMAP.  For LEVEL map-types, enforce relative
+ * levels by bitpos.
+ *
+ * Returns: 0 or <0 if error.
  */
 static int param_set_dyndbg_module_classes(const char *instr,
 					   const struct kernel_param *kp,
@@ -718,27 +751,16 @@ static int param_set_dyndbg_module_classes(const char *instr,
 		       len, instr, KP_NAME(kp));
 		return -EINVAL;
 	}
+	ddebug_class_param_clamp_input(&inrep, kp);
 
 	switch (map->map_type) {
 	case DD_CLASS_TYPE_DISJOINT_BITS:
-		/* expect bits. mask and warn if too many */
-		if (inrep & ~CLASSMAP_BITMASK(map->length)) {
-			pr_warn("%s: input: 0x%x exceeds mask: 0x%x, masking\n",
-				KP_NAME(kp), inrep, CLASSMAP_BITMASK(map->length));
-			inrep &= CLASSMAP_BITMASK(map->length);
-		}
 		old_val = READ_ONCE(*dcp->bits);
 		v2pr_info("bits:0x%x > %s.%s\n", inrep, mod_name ?: "*", KP_NAME(kp));
 		totct += ddebug_apply_class_bitmap(dcp, &inrep, old_val, mod_name);
 		WRITE_ONCE(*dcp->bits, inrep);
 		break;
 	case DD_CLASS_TYPE_LEVEL_NUM:
-		/* input is bitpos, of highest verbosity to be enabled */
-		if (inrep > map->length) {
-			pr_warn("%s: level:%u exceeds max:%d, clamping\n",
-				KP_NAME(kp), inrep, map->length);
-			inrep = map->length;
-		}
 		old_val = READ_ONCE(*dcp->lvl);
 		old_bits = CLASSMAP_BITMASK(old_val);
 		new_bits = CLASSMAP_BITMASK(inrep);
@@ -1236,30 +1258,7 @@ static inline u32 ddebug_class_param_to_bits(const struct ddebug_class_param *dc
 	}
 }
 
-static void __maybe_unused ddebug_class_param_clamp_input(u32 *inrep, const struct kernel_param *kp)
-{
-	const struct ddebug_class_param *dcp = kp->arg;
-	const struct ddebug_class_map *map = dcp->map;
 
-	switch (map->map_type) {
-	case DD_CLASS_TYPE_DISJOINT_BITS:
-		/* expect bits. mask and warn if too many */
-		if (*inrep & ~CLASSMAP_BITMASK(map->length)) {
-			pr_warn("%s: input: 0x%x exceeds mask: 0x%x, masking\n",
-				KP_NAME(kp), *inrep, CLASSMAP_BITMASK(map->length));
-			*inrep &= CLASSMAP_BITMASK(map->length);
-		}
-		break;
-	case DD_CLASS_TYPE_LEVEL_NUM:
-		/* input is bitpos, of highest verbosity to be enabled */
-		if (*inrep > map->length) {
-			pr_warn("%s: level:%d exceeds max:%d, clamping\n",
-				KP_NAME(kp), *inrep, map->length);
-			*inrep = map->length;
-		}
-		break;
-	}
-}
 
 /* called for class-users only, parse_one does this for definer modules */
 static void ddebug_sync_classbits(const struct kernel_param *kp, const char *modname)
@@ -1270,7 +1269,7 @@ static void ddebug_sync_classbits(const struct kernel_param *kp, const char *mod
 	if (!dcp || !dcp->map)
 		return;
 
-	init_bits = (_DPRINTK_FLAGS_DEFAULT & _DPRINTK_FLAGS_PRINT) ?
+	init_bits = _DPRINTK_CLASSBITS_INIT ?
 		CLASSMAP_BITMASK(dcp->map->length) : 0;
 
 	switch (dcp->map->map_type) {
diff --git a/lib/test_dynamic_debug.c b/lib/test_dynamic_debug.c
index 560e23f14ac8..7c10a1ddc630 100644
--- a/lib/test_dynamic_debug.c
+++ b/lib/test_dynamic_debug.c
@@ -1,6 +1,7 @@
 // SPDX-License-Identifier: GPL-2.0-only
 /*
- * Kernel module for testing dynamic_debug
+ * Kernel module to test/demonstrate dynamic_debug features,
+ * particularly classmaps and their support for subsystems like DRM.
  *
  * Authors:
  *      Jim Cromie	<jim.cromie@gmail.com>
@@ -68,33 +69,6 @@ static const struct kernel_param_ops param_ops_do_repeats = {
 module_param_cb(do_classes, &param_ops_do_repeats, do_classes, 0600);
 module_param_cb(do_bulk, &param_ops_do_repeats, do_bulk, 0600);
 
-/*
- * Using the CLASSMAP api:
- * - classmaps must have corresponding enum
- * - enum symbols must match/correlate with class-name strings in the map.
- * - base must equal enum's 1st value
- * - multiple maps must set their base to share the 0-30 class_id space !!
- *   (build-bug-on tips welcome)
- * Additionally, here:
- * - tie together sysname, mapname, bitsname, flagsname
- */
-#define DYNAMIC_DEBUG_CLASSMAP_PARAM_(_model, _flags, _init)		\
-	static u32 bits_##_model = _init;				\
-	static struct ddebug_class_param _flags##_##_model = {		\
-		.bits = &bits_##_model,					\
-		.flags = #_flags,					\
-		.map = &map_##_model,					\
-	};								\
-	module_param_cb(_flags##_##_model, &param_ops_dyndbg_classes,	\
-			&_flags##_##_model, 0600)
-#ifdef DEBUG
-#define DYNAMIC_DEBUG_CLASSMAP_PARAM(_model, _flags)		\
-	DYNAMIC_DEBUG_CLASSMAP_PARAM_(_model, _flags, ~0)
-#else
-#define DYNAMIC_DEBUG_CLASSMAP_PARAM(_model, _flags)		\
-	DYNAMIC_DEBUG_CLASSMAP_PARAM_(_model, _flags, 0)
-#endif
-
 /*
  * Demonstrate/test DISJOINT & LEVEL typed classmaps with a sys-param.
  *
@@ -128,12 +102,15 @@ enum cat_level_num { V1 = 16, V2, V3, V4, V5, V6, V7, V8 };
 /* test _USE_ w offset */
 enum cat_level_offset { Vu1 = V1 + 8, Vu2, Vu3, Vu4, Vu5, Vu6, Vu7, Vu8 };
 
-/* recapitulate DRM's multi-classmap setup */
+/*
+ * use/demonstrate multi-module-group classmaps, as for DRM
+ */
 #if !defined(TEST_DYNAMIC_DEBUG_SUBMOD)
 /*
- * In single user, or parent / coordinator (drm.ko) modules, define
- * classmaps on the client enums above, and then declares the PARAMS
- * ref'g the classmaps.  Each is exported.
+ * For module-groups of 1+, define classmaps with names (stringified
+ * enum-symbols) copied from above. 1-to-1 mapping is recommended.
+ * The classmap is exported, so that other modules in the group can
+ * link to it and control their prdbgs.
  */
 DYNAMIC_DEBUG_CLASSMAP_DEFINE(map_disjoint_bits, DD_CLASS_TYPE_DISJOINT_BITS,
 			      D2_CORE,
@@ -151,6 +128,15 @@ DYNAMIC_DEBUG_CLASSMAP_DEFINE(map_disjoint_bits, DD_CLASS_TYPE_DISJOINT_BITS,
 DYNAMIC_DEBUG_CLASSMAP_DEFINE(map_level_num, DD_CLASS_TYPE_LEVEL_NUM,
 			      V1, "V1", "V2", "V3", "V4", "V5", "V6", "V7", "V8");
 
+/*
+ * for use-cases that want it, provide a sysfs-param to set the
+ * classes in the classmap.  It is at this interface where the
+ * "v3>v2" property is applied to DD_CLASS_TYPE_LEVEL_NUM inputs.
+ */
+
+DYNAMIC_DEBUG_CLASSMAP_PARAM(p_disjoint_bits,	map_disjoint_bits, p);
+DYNAMIC_DEBUG_CLASSMAP_PARAM(p_level_num,	map_level_num, p);
+
 #ifdef FORCE_CLASSID_CONFLICT
 /*
  * Enable with -Dflag on compile to test overlapping class-id range
@@ -159,6 +145,7 @@ DYNAMIC_DEBUG_CLASSMAP_DEFINE(map_level_num, DD_CLASS_TYPE_LEVEL_NUM,
 DYNAMIC_DEBUG_CLASSMAP_DEFINE(classid_range_conflict, 0, D2_CORE + 1, "D3_CORE");
 #endif
 
+
 #if defined(DD_MACRO_ARGCHECK)
 /*
  * Exersize compile-time arg-checks in DYNAMIC_DEBUG_CLASSMAP_DEFINE.
@@ -192,8 +179,6 @@ DYNAMIC_DEBUG_CLASSMAP_USE_(fail_offset_big, 100);
 /*
  * now add the sysfs-params to both sub/super-mods
  */
-DYNAMIC_DEBUG_CLASSMAP_PARAM(disjoint_bits, p);
-DYNAMIC_DEBUG_CLASSMAP_PARAM(level_num, p);
 
 /* stand-in for all pr_debug etc */
 #define prdbg(SYM) __pr_debug_cls(SYM, #SYM " msg\n")
@@ -288,5 +273,5 @@ module_init(test_dynamic_debug_init);
 module_exit(test_dynamic_debug_exit);
 
 MODULE_AUTHOR("Jim Cromie <jim.cromie@gmail.com>");
-MODULE_DESCRIPTION("Kernel module for testing dynamic_debug");
+MODULE_DESCRIPTION("test/demonstrate dynamic-debug features");
 MODULE_LICENSE("GPL");
diff --git a/lib/test_dynamic_debug_submod.c b/lib/test_dynamic_debug_submod.c
index 672aabf40160..3adf3925fb86 100644
--- a/lib/test_dynamic_debug_submod.c
+++ b/lib/test_dynamic_debug_submod.c
@@ -1,6 +1,9 @@
 // SPDX-License-Identifier: GPL-2.0
 /*
- * Kernel module for testing dynamic_debug
+ * Kernel module to test/demonstrate dynamic_debug features,
+ * particularly classmaps and their support for subsystems, like DRM,
+ * which defines its drm_debug classmap in drm module, and uses it in
+ * helpers & drivers.
  *
  * Authors:
  *      Jim Cromie	<jim.cromie@gmail.com>
@@ -12,3 +15,7 @@
  */
 #define TEST_DYNAMIC_DEBUG_SUBMOD
 #include "test_dynamic_debug.c"
+
+MODULE_DESCRIPTION("test/demonstrate dynamic-debug subsystem support");
+MODULE_AUTHOR("Jim Cromie <jim.cromie@gmail.com>");
+MODULE_LICENSE("GPL");
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index 1bea45507352..8d3f1e49e9e1 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -546,7 +546,7 @@ function GOLDEN_RECORDS {
 #K= c518a50ba30ba8099d0dc874a27ecf16 FT_basic_queries.7
 #K= 69f1958beef98211d4181f9ded9787c4 FT_test_classes.1
 #K= 5516e3d13cba7ea4197a7fb6c033887a FT_test_classes.2
-#K= 22213a7bf431c3e0efd3edbfcba69677 FT_test_classes.3
+#K= 20d4545f9753e677e72e3adf52527fd3 FT_test_classes.3
 #K= 934d8677872fe26bd636a6c3d6416aa2 FT_classmap_inheritance.1
 #K= cd1389958807063baa1ea4b06c61fa02 FT_classmap_inheritance.2
 #K= 0708a283f0f1959135c797e36119e4af FT_classmap_inheritance.3

-- 
2.55.0

