From: Jim Cromie <jim.cromie@gmail.com>
Date: Tue, 08 Sep 2026 18:55:30 -0600
Subject: [PATCH v9 34/39] dyndbg: harden classmap and descriptor validation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-dd-cmap-part2-clean-v9-34-3a3f621f4a10@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788915300; l=9621;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=Ze3RSKS17krdNnPByKlYnYbOSbF5bNArIZQ1VzxmDzg=;
 b=baFYAtOr/VZR4IIryRn4v/M5iGX6+mxJJqTBZO/e/8sYCmC8jLK2HvS3P0F6XR1GTY6ZnDJJo
 x5ZhnOVinuSCa8rMMYUT4IlxEMttYm2yyHuVWHIug41MlOzgXDRbjjm
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

- Mirror the compile-time limits of _DEFINE by adding a static_assert
  to validate the _offset value passed to DYNAMIC_DEBUG_CLASSMAP_USE_.

- Add run-time overlap checks for _USEd classmaps in ddebug_add_module()
  to prevent collisions between private maps and imported APIs.

- Scan module descriptors at load time to print a single warning per
  missing class_id, rather than waiting for a user query to trip over it.

- Downgrade the global WARN_ONCE in ddebug_match_desc() to a
  pr_warn_ratelimited, since orphaned class IDs are now tracked and
  warned about early at module load.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 lib/dynamic_debug.c                                | 68 ++++++++++++++++++++--
 lib/test_dynamic_debug.c                           | 16 +++--
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 22 +++----
 3 files changed, 84 insertions(+), 22 deletions(-)

diff --git a/lib/dynamic_debug.c b/lib/dynamic_debug.c
index 8c90b1e4cd33..afde13a2121f 100644
--- a/lib/dynamic_debug.c
+++ b/lib/dynamic_debug.c
@@ -316,7 +316,8 @@ static bool ddebug_match_desc(const struct ddebug_query *query,
 	/* site is class'd */
 	site_map = ddebug_find_map_by_class_id(di, dp->class_id);
 	if (!site_map) {
-		WARN_ONCE(1, "unknown class_id %d, check %s's CLASSMAP definitions", dp->class_id, di->mod_name);
+		pr_warn_ratelimited("unknown class_id %d, check %s's CLASSMAP definitions\n",
+			  dp->class_id, di->mod_name);
 		return false;
 	}
 	/* module(-param) decides protection */
@@ -1483,6 +1484,23 @@ static int ddebug_class_range_overlap(struct ddebug_class_map *cm, u64 *reserved
 	return 0;
 }
 
+static int ddebug_class_user_overlap(struct ddebug_class_user *cli,
+				     u64 *reserved_ids)
+{
+	struct ddebug_class_map *cm = cli->map;
+	int base = cm->base + cli->offset;
+	u64 range = (((1ULL << cm->length) - 1) << base);
+
+	if (range & *reserved_ids) {
+		pr_err("module %s: [%d..%d] (from %s) conflicts with %llx\n",
+		       cli->mod_name, base, base + cm->length - 1,
+		       cm->class_names[0], *reserved_ids);
+		return -EINVAL;
+	}
+	*reserved_ids |= range;
+	return 0;
+}
+
 /*
  * Allocate a new ddebug_table for the given module
  * and add it to the global list.
@@ -1493,7 +1511,8 @@ static int ddebug_add_module(struct _ddebug_info *di)
 	struct ddebug_class_map *cm;
 	struct ddebug_class_user *cli;
 	u64 reserved_ids = 0;
-	int i;
+	u64 bad_ids = 0;
+	int i, err = 0;
 
 	if (!di->descs.len)
 		return 0;
@@ -1524,10 +1543,47 @@ static int ddebug_add_module(struct _ddebug_info *di)
 	dd_set_module_subrange(i, cm, &dt->info, maps);
 	dd_set_module_subrange(i, cli, &dt->info, users);
 
-	/* insure 2+ classmaps share the per-module 0..62 class_id space */
+	/* validate the per-module shared 0..62 class_id space */
 	for_subvec(i, cm, &dt->info, maps)
 		if (ddebug_class_range_overlap(cm, &reserved_ids))
-			goto cleanup;
+			err = -EINVAL;
+
+	for_subvec(i, cli, &dt->info, users) {
+		cm = cli->map;
+		if (!cm) {
+			pr_err("module %s: classmap not found for user\n", di->mod_name);
+			err = -EINVAL;
+			continue;
+		}
+
+		if (cm->base + cm->length + cli->offset > _DPRINTK_CLASS_DFLT) {
+			pr_err("module %s: base:%d + classes.len:%d + cli.offset:%d must be <= %d\n",
+			       di->mod_name, cm->base, cm->length,
+			       cli->offset, _DPRINTK_CLASS_DFLT);
+			err = -EINVAL;
+			continue;
+		}
+
+		if (ddebug_class_user_overlap(cli, &reserved_ids))
+			err = -EINVAL;
+	}
+	if (err)
+		goto cleanup;
+
+	/* validate all class_ids against module's classmaps/users */
+	for (i = 0; i < dt->info.descs.len; i++) {
+		struct _ddebug *dp = &dt->info.descs.start[i];
+
+		if (dp->class_id == _DPRINTK_CLASS_DFLT)
+			continue;
+		if (bad_ids & (1ULL << dp->class_id))
+			continue;
+		if (!ddebug_find_map_by_class_id(&dt->info, dp->class_id)) {
+			pr_warn("module %s uses unknown class_id %d\n",
+				dt->info.mod_name, dp->class_id);
+			bad_ids |= (1ULL << dp->class_id);
+		}
+	}
 
 	mutex_lock(&ddebug_lock);
 	list_add_tail(&dt->link, &ddebug_tables);
@@ -1539,7 +1595,7 @@ static int ddebug_add_module(struct _ddebug_info *di)
 		 dt->info.descs.len, dt->info.mod_name);
 	return 0;
 cleanup:
-	WARN_ONCE(1, "dyndbg multi-classmap conflict in %s\n", di->mod_name);
+	pr_err("dyndbg multi-classmap conflict in %s\n", di->mod_name);
 	kfree(dt);
 	return -EINVAL;
 }
@@ -1626,7 +1682,7 @@ static int ddebug_module_notify(struct notifier_block *self, unsigned long val,
 		mod->dyndbg_info.mod_name = mod->name;
 		ret = ddebug_add_module(&mod->dyndbg_info);
 		if (ret)
-			WARN(1, "Failed to allocate memory: dyndbg may not work properly.\n");
+			pr_err("dyndbg: failed to add module %s: %d\n", mod->name, ret);
 		break;
 	case MODULE_STATE_GOING:
 		ddebug_remove_module(mod->name);
diff --git a/lib/test_dynamic_debug.c b/lib/test_dynamic_debug.c
index 368891075175..97f2c9e1b92b 100644
--- a/lib/test_dynamic_debug.c
+++ b/lib/test_dynamic_debug.c
@@ -161,14 +161,20 @@ DYNAMIC_DEBUG_CLASSMAP_DEFINE(fail_base_len, 0, 60,
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
index f10ef7522426..25137663d554 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -693,12 +693,12 @@ function GOLDEN_RECORDS {
 #K= 4542e1e5e7eadcbe8f90a9c934635618 FT_multi_query.4
 #K= 8146f6f983c3a76783c89b78b892ed48 FT_test_classes.1
 #K= a15ec4843acd721fbdfddc0b512c8032 FT_test_classes.2
-#K= 20d4545f9753e677e72e3adf52527fd3 FT_test_classes.3
-#K= 3a6afd41fadaaf70fad18f8a4632ffec FT_classmap_inheritance.1
-#K= 6f1e347f0a7930814d2e54d589439465 FT_classmap_inheritance.2
+#K= bc074e657d8d7f0bbc960e4dfa8de25d FT_test_classes.3
+#K= 878c5b9b20cbe8b93f2f3e92fc8b77bb FT_classmap_inheritance.1
+#K= 0eb7e891704074434646c2340ddac152 FT_classmap_inheritance.2
 #K= a6e6aab5a6cb9a792d4296b1200ba409 FT_classmap_inheritance.3
-#K= 315cc5dad3a775c54a0b60a0276300b7 FT_classmap_inheritance.4
-#K= 7e92245008439ee79fe2460aeaa16a9b FT_classmap_inheritance.5
+#K= 5b6d86bcaa2477699aab655447d780dd FT_classmap_inheritance.4
+#K= f43e0aff8a4b38435b73d90ed8100d1b FT_classmap_inheritance.5
 #K= 94610c57ac44bd7011002a654fd78f93 FT_modprobe_w_param.1
 #K= 94610c57ac44bd7011002a654fd78f93 FT_modprobe_w_param.2
 #K= c1309e18dc9bf2f57184fa13164d917d FT_modprobe_w_param.3
@@ -709,11 +709,11 @@ function GOLDEN_RECORDS {
 #K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.8
 #K= 591411c42cf52d7c4c46d76bcc345a5f FT_modprobe_w_param.9
 #K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.10
-#K= b0435304108118e64529469e59332111 FT_modprobe_w_param.11
+#K= 46d24fecc507a8f9be0bd120e27ff64f FT_modprobe_w_param.11
 #K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.12
-#K= 4d036833ce9f661057a4e13d97295c65 FT_modprobe_w_param.13
+#K= 79298a323d3dcca4f74fb9fc0de5a87e FT_modprobe_w_param.13
 #K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.14
-#K= 5c3c6ecf6a46f9ccebd60c5ca9ebdbb7 FT_modprobe_w_param.15
+#K= f649752dfb07a68087f04dafc00ed1e8 FT_modprobe_w_param.15
 #K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.16
 #K= 73a93377a823739e8aae44856a20fa7f FT_modprobe_w_param.17
 #K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.18
@@ -727,11 +727,11 @@ function GOLDEN_RECORDS {
 #K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.26
 #K= 7b91db8e9f160aebb1ee87fab2232404 FT_modprobe_w_param.27
 #K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.28
-#K= e393499e02677de414e478f4e710eeb9 FT_modprobe_w_param.29
+#K= d3d111da544dd5cee254e88178823b9d FT_modprobe_w_param.29
 #K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.30
-#K= 375e38613af3b49bb7c7689dfecf4177 FT_modprobe_w_param.31
+#K= b5a30ebac06aea6e77a44322667effc7 FT_modprobe_w_param.31
 #K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.32
-#K= 745a61d20e26a6a22db0b99420fea80a FT_modprobe_w_param.33
+#K= bbe7b47ed089428429f4264c8cc2a066 FT_modprobe_w_param.33
 #K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.34
 #K= 3d2538bf868e71bff17c768cf118c352 FT_modprobe_w_param.35
 #K= 13c54ef65e199294fd078ba72c0cd69a FT_modprobe_w_param.36

-- 
2.55.0

