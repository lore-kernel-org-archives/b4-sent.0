From: Jim Cromie <jim.cromie@gmail.com>
Date: Wed, 16 Sep 2026 09:33:25 -0600
Subject: [PATCH v10 33/38] dyndbg: harden classmap and descriptor
 validation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260916-dd-cmap-part2-clean-v10-33-af4cf4767707@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789572777; l=9553;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=nVFWnFKk0QgFo8thqqeslt7rKlx+zalXosrMpbqoT/M=;
 b=HjX+eUvHojWORc3aN6sS1EcixM4R5BxkavlY5DAiN/HRS2V5h377CNjRsgFDeciopyiA/XGdn
 7YYA3T+SZWxCGh5hAVPTLpIegxifalHI9iGY11AjOpH9bXXs0ADMZzC
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

- Add run-time overlap checks for _USEd classmaps in ddebug_add_module()
  to prevent collisions between private maps and imported APIs.

- Scan module descriptors at load time to print a single warning per
  missing class_id, rather than waiting for a user query to trip over it.

- Downgrade the global WARN_ONCE in ddebug_match_desc() to a
  pr_warn_ratelimited, since orphaned class IDs are now tracked and
  warned about early at module load.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
v10:
. fix pr_warn_ratelimited() line wrap in ddebug_match_desc().
---
 lib/dynamic_debug.c                                | 68 ++++++++++++++++++++--
 lib/test_dynamic_debug.c                           | 16 +++--
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 22 +++----
 3 files changed, 84 insertions(+), 22 deletions(-)

diff --git a/lib/dynamic_debug.c b/lib/dynamic_debug.c
index ac54a0499369..eb28831a6cb2 100644
--- a/lib/dynamic_debug.c
+++ b/lib/dynamic_debug.c
@@ -317,7 +317,8 @@ static bool ddebug_match_desc(const struct ddebug_query *query,
 	/* site is class'd */
 	site_map = ddebug_find_map_by_class_id(di, dp->class_id);
 	if (!site_map) {
-		WARN_ONCE(1, "unknown class_id %d, check %s's CLASSMAP definitions", dp->class_id, di->mod_name);
+		pr_warn_ratelimited("unknown class_id %d, check %s's CLASSMAP definitions\n",
+				    dp->class_id, di->mod_name);
 		return false;
 	}
 	/* module(-param) decides protection */
@@ -1490,6 +1491,23 @@ static int ddebug_class_range_overlap(struct ddebug_class_map *cm, u64 *reserved
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
@@ -1500,7 +1518,8 @@ static int ddebug_add_module(struct _ddebug_info *di)
 	struct ddebug_class_map *cm;
 	struct ddebug_class_user *cli;
 	u64 reserved_ids = 0;
-	int i;
+	u64 bad_ids = 0;
+	int i, err = 0;
 
 	if (!di->descs.len)
 		return 0;
@@ -1531,10 +1550,47 @@ static int ddebug_add_module(struct _ddebug_info *di)
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
@@ -1546,7 +1602,7 @@ static int ddebug_add_module(struct _ddebug_info *di)
 		 dt->info.descs.len, dt->info.mod_name);
 	return 0;
 cleanup:
-	WARN_ONCE(1, "dyndbg multi-classmap conflict in %s\n", di->mod_name);
+	pr_err("dyndbg multi-classmap conflict in %s\n", di->mod_name);
 	kfree(dt);
 	return -EINVAL;
 }
@@ -1633,7 +1689,7 @@ static int ddebug_module_notify(struct notifier_block *self, unsigned long val,
 		mod->dyndbg_info.mod_name = mod->name;
 		ret = ddebug_add_module(&mod->dyndbg_info);
 		if (ret)
-			WARN(1, "Failed to allocate memory: dyndbg may not work properly.\n");
+			pr_err("dyndbg: failed to add module %s: %d\n", mod->name, ret);
 		break;
 	case MODULE_STATE_GOING:
 		ddebug_remove_module(mod->name);
diff --git a/lib/test_dynamic_debug.c b/lib/test_dynamic_debug.c
index 7c10a1ddc630..fe5b885398f3 100644
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
index a91a0ffa92d4..ef5f41ca7f7d 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -583,12 +583,12 @@ function GOLDEN_RECORDS {
 #K= c518a50ba30ba8099d0dc874a27ecf16 FT_multi_query.4
 #K= 8f18ea82c09460434b6e9e4cd12543e8 FT_test_classes.1
 #K= a15ec4843acd721fbdfddc0b512c8032 FT_test_classes.2
-#K= 20d4545f9753e677e72e3adf52527fd3 FT_test_classes.3
-#K= 934d8677872fe26bd636a6c3d6416aa2 FT_classmap_inheritance.1
-#K= cd1389958807063baa1ea4b06c61fa02 FT_classmap_inheritance.2
+#K= bc074e657d8d7f0bbc960e4dfa8de25d FT_test_classes.3
+#K= a60284143b51b5d13c4562f7f4a2e807 FT_classmap_inheritance.1
+#K= 1d43471dca765597d88a1be25d776c92 FT_classmap_inheritance.2
 #K= 0708a283f0f1959135c797e36119e4af FT_classmap_inheritance.3
-#K= 05f6efb80299d24cde65174f64d97308 FT_classmap_inheritance.4
-#K= 7e92245008439ee79fe2460aeaa16a9b FT_classmap_inheritance.5
+#K= a0b9a8a9530706b85c4f8bf911607db0 FT_classmap_inheritance.4
+#K= f43e0aff8a4b38435b73d90ed8100d1b FT_classmap_inheritance.5
 #K= 53d1b6875b65c79cfd759e209ae50b11 FT_modprobe_w_param.1
 #K= 53d1b6875b65c79cfd759e209ae50b11 FT_modprobe_w_param.2
 #K= 79d912e2aeb04dea70f9c7e701333f0a FT_modprobe_w_param.3
@@ -599,11 +599,11 @@ function GOLDEN_RECORDS {
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.8
 #K= f9cee4512e5604603e0262fba4bea223 FT_modprobe_w_param.9
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.10
-#K= b6a62433165f6423b81417f782551ab9 FT_modprobe_w_param.11
+#K= 7c645692e3e3796d4d3b8604c49583f7 FT_modprobe_w_param.11
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.12
-#K= de89753b843449d11da14240c4da4cad FT_modprobe_w_param.13
+#K= e995f70c0509334a33aec40ada9e6e6c FT_modprobe_w_param.13
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.14
-#K= 1d966d0cae735457791c93a86e9e1650 FT_modprobe_w_param.15
+#K= 72f97ca3e8f4c3e7f34fbe91de62e223 FT_modprobe_w_param.15
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.16
 #K= 1aacb7c196a8354c46c60c73d78c6bf2 FT_modprobe_w_param.17
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.18
@@ -617,11 +617,11 @@ function GOLDEN_RECORDS {
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.26
 #K= 7fa4c84490c42c750986614c3539d56a FT_modprobe_w_param.27
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.28
-#K= 1eb866a813551061cd73178ba7833543 FT_modprobe_w_param.29
+#K= fc098897aa3e1472a536e7ae8069c84f FT_modprobe_w_param.29
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.30
-#K= a9e7424ed7b02696b5e12108971792dd FT_modprobe_w_param.31
+#K= 38ea63fed62a0308241325e57020b28e FT_modprobe_w_param.31
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.32
-#K= 5323d7746d983cdcfda4866255cd5123 FT_modprobe_w_param.33
+#K= 4b896adb5e7cfcc79f9ffa879d791f37 FT_modprobe_w_param.33
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.34
 #K= 7f961a7d3facd89bdd4b9d8e7b5541e9 FT_modprobe_w_param.35
 #K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.36

-- 
2.55.0

