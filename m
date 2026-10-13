From: Jim Cromie <jim.cromie@gmail.com>
Date: Mon, 12 Oct 2026 20:37:09 -0600
Subject: [PATCH v12 38/40] dyndbg: harden classmap and descriptor
 validation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-dd-cmap-part2-clean-v12-38-3c8cc5725def@gmail.com>
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
 Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791858995; l=10577;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=8P3918AoJzA9ezMcojS8Z9LIIbJHCfkHJGfzkcsbGmo=;
 b=UkyKQEGyZ2eCDb/frp2W/MDXnNoJJpwoUL2BWlE5+XWZd2wdXq1nZIrusk4NdQaTgKWbYryXH
 NxkA9qMdnXDBVg/5oNgg5kwABQfcSsvG/rtuLEr7GX2wcikSYKRpiwl
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Dynamic debug classmaps allow modules to _DEFINE and/or _USE multiple
classmaps, but this requires coordination amongst the classmaps.

Previously, class validation done by DYNAMIC_DEBUG_CLASSMAP_DEFINE at
compile-time, and ddebug_class_range_overlap() at modprobe-time, was
incomplete, and DYNAMIC_DEBUG_CLASSMAP_USE_ had no validation. This
could allow broken classmaps, making them harder to use well.

This commit improves classmap and descriptor validation:

- Unify runtime overlap and bounds checking across _DEFINE'd and _USE'd
  classmaps in ddebug_validate_class_range(), enforcing symmetry and the
  <= 62 upper bound for both.

- Split runtime validation out of ddebug_add_module() into dedicated
  helpers: ddebug_validate_classmaps() (fatal, returns boolean pass/fail)
  and ddebug_validate_descs() (scans callsites and emits an advisory
  warning once per unknown class_id).

- Downgrade the global WARN_ONCE in ddebug_match_desc() to a
  pr_warn_ratelimited, since orphaned class IDs are now tracked and
  warned about early at module load.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
v11:
. factor runtime classmap validation out of ddebug_add_module() into
  ddebug_validate_classmaps() and ddebug_validate_descs().
. unify overlap and bounds checking across maps and users in
  ddebug_validate_class_range().

v10:
. fix pr_warn_ratelimited() line wrap in ddebug_match_desc().
---
 lib/dynamic_debug.c                                | 92 ++++++++++++++++++----
 lib/test_dynamic_debug.c                           | 16 ++--
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 22 +++---
 3 files changed, 99 insertions(+), 31 deletions(-)

diff --git a/lib/dynamic_debug.c b/lib/dynamic_debug.c
index 47a830dbd564..0b90ea198499 100644
--- a/lib/dynamic_debug.c
+++ b/lib/dynamic_debug.c
@@ -329,7 +329,8 @@ static bool ddebug_match_desc(const struct ddebug_query *query,
 	/* site is class'd */
 	site_map = ddebug_find_map_by_class_id(di, dp->class_id);
 	if (!site_map) {
-		WARN_ONCE(1, "unknown class_id %d, check %s's CLASSMAP definitions", dp->class_id, di->mod_name);
+		pr_warn_ratelimited("unknown class_id %d, check %s's CLASSMAP definitions\n",
+				    dp->class_id, di->mod_name);
 		return false;
 	}
 	/* module(-param) decides protection */
@@ -1580,18 +1581,80 @@ static void ddebug_apply_class_users(const struct _ddebug_info *di)
 		__di->_vec.start = __start;				\
 })
 
-static int ddebug_class_range_overlap(struct ddebug_class_map *cm, u64 *reserved_ids)
+static bool ddebug_validate_class_range(const char *modname,
+					const char *name,
+					int base, int length,
+					u64 *reserved_ids)
 {
-	u64 range = (((1ULL << cm->length) - 1) << cm->base);
+	u64 range;
 
+	if (base < 0 || length <= 0 ||
+	    base + length > _DPRINTK_CLASS_DFLT) {
+		pr_err("module %s: base:%d len:%d (from %s) exceeds class_id limit %d\n",
+		       modname, base, length, name, _DPRINTK_CLASS_DFLT);
+		return false;
+	}
+	range = (((1ULL << length) - 1) << base);
 	if (range & *reserved_ids) {
-		pr_err("[%d..%d] on %s conflicts with %llx\n", cm->base,
-		       cm->base + cm->length - 1, cm->class_names[0],
-		       *reserved_ids);
-		return -EINVAL;
+		pr_err("module %s: [%d..%d] (from %s) conflicts with 0x%llx\n",
+		       modname, base, base + length - 1, name, *reserved_ids);
+		return false;
 	}
 	*reserved_ids |= range;
-	return 0;
+	return true;
+}
+
+static bool ddebug_validate_classmaps(struct _ddebug_info *di)
+{
+	struct ddebug_class_map *cm;
+	struct ddebug_class_user *cli;
+	u64 reserved_ids = 0;
+	bool valid = true;
+	int i;
+
+	for_subvec(i, cm, di, maps)
+		if (!ddebug_validate_class_range(di->mod_name,
+						 cm->class_names[0],
+						 cm->base, cm->length,
+						 &reserved_ids))
+			valid = false;
+
+	for_subvec(i, cli, di, users) {
+		if (!cli->map) {
+			pr_err("module %s: classmap not found for user\n",
+			       di->mod_name);
+			valid = false;
+			continue;
+		}
+		if (!ddebug_validate_class_range(di->mod_name,
+						 cli->map->class_names[0],
+						 cli->map->base + cli->offset,
+						 cli->map->length,
+						 &reserved_ids))
+			valid = false;
+	}
+	return valid;
+}
+
+static void ddebug_validate_descs(struct _ddebug_info *di)
+{
+	struct _ddebug *dp;
+	u64 bad_ids = 0;
+	int i;
+
+	for (i = 0; i < di->descs.len; i++) {
+		dp = &di->descs.start[i];
+
+		if (dp->class_id == _DPRINTK_CLASS_DFLT)
+			continue;
+		if (bad_ids & (1ULL << dp->class_id))
+			continue;
+		if (!ddebug_find_map_by_class_id(di, dp->class_id)) {
+			pr_warn("module %s uses unknown class_id %d\n",
+				di->mod_name, dp->class_id);
+			bad_ids |= (1ULL << dp->class_id);
+		}
+	}
 }
 
 /*
@@ -1603,7 +1666,6 @@ static int ddebug_add_module(struct _ddebug_info *di)
 	struct ddebug_table *dt;
 	struct ddebug_class_map *cm;
 	struct ddebug_class_user *cli;
-	u64 reserved_ids = 0;
 	int i;
 
 	if (!di->descs.len)
@@ -1635,10 +1697,10 @@ static int ddebug_add_module(struct _ddebug_info *di)
 	dd_set_module_subrange(i, cm, &dt->info, maps);
 	dd_set_module_subrange(i, cli, &dt->info, users);
 
-	/* insure 2+ classmaps share the per-module 0..62 class_id space */
-	for_subvec(i, cm, &dt->info, maps)
-		if (ddebug_class_range_overlap(cm, &reserved_ids))
-			goto cleanup;
+	if (!ddebug_validate_classmaps(&dt->info))
+		goto cleanup;
+
+	ddebug_validate_descs(&dt->info);
 
 	/*
 	 * Bind controlling_param before publishing dt to ddebug_tables so
@@ -1665,7 +1727,7 @@ static int ddebug_add_module(struct _ddebug_info *di)
 		 dt->info.descs.len, dt->info.mod_name);
 	return 0;
 cleanup:
-	WARN_ONCE(1, "dyndbg multi-classmap conflict in %s\n", di->mod_name);
+	pr_err("dyndbg multi-classmap conflict in %s\n", di->mod_name);
 	kfree(dt);
 	return -EINVAL;
 }
@@ -1753,7 +1815,7 @@ static int ddebug_module_notify(struct notifier_block *self, unsigned long val,
 		mod->dyndbg_info.mod_name = mod->name;
 		ret = ddebug_add_module(&mod->dyndbg_info);
 		if (ret)
-			WARN(1, "Failed to allocate memory: dyndbg may not work properly.\n");
+			pr_err("dyndbg: failed to add module %s: %d\n", mod->name, ret);
 		break;
 	case MODULE_STATE_GOING:
 		ddebug_remove_module(mod->name);
diff --git a/lib/test_dynamic_debug.c b/lib/test_dynamic_debug.c
index 35bb411c48d8..aaf8aad481a0 100644
--- a/lib/test_dynamic_debug.c
+++ b/lib/test_dynamic_debug.c
@@ -173,14 +173,20 @@ DYNAMIC_DEBUG_CLASSMAP_DEFINE(fail_base_len, 0, 60,
 #endif
 
 #else /* TEST_DYNAMIC_DEBUG_SUBMOD */
-
 /*
- * in submod/drm-drivers, use the classmaps defined in top/parent
- * module above.
+ * In submod (drm-drivers/helpers) use the classmaps defined in
+ * top/parent module above.  We _USE_() with offset, to test the
+ * non-zero case.
  */
-
 DYNAMIC_DEBUG_CLASSMAP_USE(map_disjoint_bits);
-DYNAMIC_DEBUG_CLASSMAP_USE_(map_level_num, 7);
+/*
+ * maybe force failure of runtime sanity test of classmap.length + offset < 63
+ */
+#if !defined(DD_RUNTIME_CLASS_CHECK)
+DYNAMIC_DEBUG_CLASSMAP_USE_(map_level_num, 8);
+#else
+DYNAMIC_DEBUG_CLASSMAP_USE_(map_level_num, 55);
+#endif
 
 #if defined(DD_MACRO_ARGCHECK)
 DYNAMIC_DEBUG_CLASSMAP_USE_(fail_offset_big, 100);
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index e439f367386c..109f11b2649e 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -576,12 +576,12 @@ function GOLDEN_RECORDS {
 #K= c518a50ba30ba8099d0dc874a27ecf16 FT_multi_query.4
 #K= 91838b4012c50a1dc1d9e210ba8d68f8 FT_test_classes.1
 #K= a15ec4843acd721fbdfddc0b512c8032 FT_test_classes.2
-#K= 2cee6842c9cdee5cb3bf50b2e3914813 FT_test_classes.3
-#K= 81b16613f8d444485e2bc5aa4d38d024 FT_classmap_inheritance.1
-#K= c14c8aa758e24046b3237d20e2189bf7 FT_classmap_inheritance.2
+#K= c03cd07445ca93358176130f04320ee7 FT_test_classes.3
+#K= 1489b3b72dbdfdb553cc0c6594c4face FT_classmap_inheritance.1
+#K= e11c22649735cedb6c30321378100e11 FT_classmap_inheritance.2
 #K= 5d0f3701517aa3a461c8887c332bdb42 FT_classmap_inheritance.3
-#K= f444ae312fcce32444c54da757d87c41 FT_classmap_inheritance.4
-#K= 0266e8d60659058ec589283022bf078c FT_classmap_inheritance.5
+#K= d39188ded831453d90d77390546b314d FT_classmap_inheritance.4
+#K= 62b6803edf43519186d6185bebf34352 FT_classmap_inheritance.5
 #K= d2e8b8c5a5b4e7b9bbe1a29460a3c07d FT_modprobe_w_param.1
 #K= d2e8b8c5a5b4e7b9bbe1a29460a3c07d FT_modprobe_w_param.2
 #K= 20d8a1fac0330f1b5cc582ce93792d58 FT_modprobe_w_param.3
@@ -592,11 +592,11 @@ function GOLDEN_RECORDS {
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.8
 #K= 535ab526b24a7214de41d92e94bbd52c FT_modprobe_w_param.9
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.10
-#K= 4f96e9cd2c92ab099cd35dad83c35e86 FT_modprobe_w_param.11
+#K= 64f91218760ca86d28a4b9b2d23849fb FT_modprobe_w_param.11
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.12
-#K= 80ca4d681dcd4c0046a4daa01e9b168a FT_modprobe_w_param.13
+#K= 03bad8f76b3587c2e8bdb9df43110a5e FT_modprobe_w_param.13
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.14
-#K= e0cdc3a8471acf34201539231b2b2110 FT_modprobe_w_param.15
+#K= 04b59fe2db45bc6bb314e9102b92dd64 FT_modprobe_w_param.15
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.16
 #K= d682c98ced7d31f1555ab474a9ebe253 FT_modprobe_w_param.17
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.18
@@ -610,11 +610,11 @@ function GOLDEN_RECORDS {
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.26
 #K= 8d2f4db3b7885064a56594e1d81deb26 FT_modprobe_w_param.27
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.28
-#K= b76a644b8d3c99bfd8df9220f4509828 FT_modprobe_w_param.29
+#K= 0658c273db527fb4fcaadbb142bf0565 FT_modprobe_w_param.29
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.30
-#K= dfc272b2a1f7a075e3a37dc491396adf FT_modprobe_w_param.31
+#K= 20cac1fd02b4615b337e84aa87892afc FT_modprobe_w_param.31
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.32
-#K= 24629bcce166addffcaae1232ef6a5a9 FT_modprobe_w_param.33
+#K= 8eb7924c66978d844e97bee9f91b981e FT_modprobe_w_param.33
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.34
 #K= 28ace93a95da7aaea5b9b54a8656a2cf FT_modprobe_w_param.35
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.36

-- 
2.56.0

