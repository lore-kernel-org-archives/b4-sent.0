From: Jim Cromie <jim.cromie@gmail.com>
Date: Sat, 05 Sep 2026 12:13:51 -0600
Subject: [PATCH v8 37/43] dyndbg: harden classmap and descriptor validation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260905-dd-cmap-part2-clean-v8-37-a4cc0674f6fd@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788632017; l=11154;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=5+16N9fcYRrm+lpvFqi6n7Hg6iJio0EQSnKVmnC/o/A=;
 b=ddMJcUkB0SGUfyCijAWJQ7idXnyBAY6vDdSbE69tS/8MOg/hozWq3U06E1yCaY48dEAiml4DA
 JPi+gRHU9VvB9I7wyrG2Pz8D3Oo2NJypTg9WuiSJtx93ZB0bKJSNLzs
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Dynamic debug classmaps allow modules to _DEFINE and/or _USE multiple
classmaps, but this requires coordination amongst the classmaps.

Previously, class validation done by DYNAMIC_DEBUG_CLASSMAP_DEFINE at
compile-time, and ddebug_class_range_overlap() at modprobe-time, was
incomplete, and DYNAMIC_DEBUG_CLASSMAP_USE_ had no validation.  This
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

old-v12 - squash several enhancments together

drop run-time USE check, now done at compile-time

s/WARN_ONCE/pr_err/, dont need stack trace for this, and do want
multiple error reports, so dont quit on 1st err.

Now that DYNAMIC_DEBUG_CLASSMAP_USE_() has an offset parameter, it is
possible for a user to specify an illegal value - one that shifts the
bit-range past the 64 bit max.  The macro detects an offset > 63, but
this isn't enough; the legal max is:

  map.length - 1 + map.base + user.offset < 64

Testing class-map vs class-user overlap is nonsense if the class-user
range extends past the implemented limit.  So check that 1st, before
looking for map/user overlap.

To validate this, add ifdef DD_RUNTIME_CLASS_CHECK code to
test_dynamic_debug_submod.ko.  When its enabled, it creates a bad
class-user record via:

  DYNAMIC_DEBUG_CLASSMAP_USE_(map_level_num, 55);

bash-5.3# modprobe test_dynamic_debug_submod
[   19.359818] dyndbg:  23 debug prints in module test_dynamic_debug
[   19.366239] dyndbg: module test_dynamic_debug_submod: base:16 + classes.len:8 + cli.offset:55 must be < 63
[   19.366612] dyndbg: dyndbg multi-classmap conflict in test_dynamic_debug_submod
[   19.366945] dyndbg: dyndbg: failed to add module test_dynamic_debug_submod: -22

Finally, replace the misleading "Failed to allocate memory" WARN in
the module notifier with a pr_err that reports the specific failure
code without the stack-trace.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 lib/dynamic_debug.c                                | 68 ++++++++++++++++++++--
 lib/test_dynamic_debug.c                           | 16 +++--
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 22 +++----
 3 files changed, 84 insertions(+), 22 deletions(-)

diff --git a/lib/dynamic_debug.c b/lib/dynamic_debug.c
index a5d813ad323a..b7ccf471b5ef 100644
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
+		if (cm->base + cm->length + cli->offset >= _DPRINTK_CLASS_DFLT) {
+			pr_err("module %s: base:%d + classes.len:%d + cli.offset:%d must be < %d\n",
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
index def44524b762..2d4be5442d46 100644
--- a/lib/test_dynamic_debug.c
+++ b/lib/test_dynamic_debug.c
@@ -162,14 +162,20 @@ DYNAMIC_DEBUG_CLASSMAP_DEFINE(fail_base_len, 0, 60,
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
+  DYNAMIC_DEBUG_CLASSMAP_USE_(map_level_num, 8);
+#else
+  DYNAMIC_DEBUG_CLASSMAP_USE_(map_level_num, 55);
+#endif
 
 #if defined(DD_MACRO_ARGCHECK)
 DYNAMIC_DEBUG_CLASSMAP_USE_(fail_offset_big, 100);
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index 194e9c9d4544..5ef10cf8f6c3 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -685,12 +685,12 @@ function GOLDEN_RECORDS {
 #K= 9a1b13c32a15363dcf93913308edeea5 FT_multi_query.4
 #K= d4923595eea382923aee64aed15c7c35 FT_test_classes.1
 #K= a15ec4843acd721fbdfddc0b512c8032 FT_test_classes.2
-#K= 40a294034c886787960f4c751b196da9 FT_test_classes.3
-#K= 3af642df3771be04ab4428ce7f6d53a2 FT_classmap_inheritance.1
-#K= d6135911e9cff22d701ad0c3fdbb1c35 FT_classmap_inheritance.2
+#K= b4a593a1e1cab60da0156fcd5582d24c FT_test_classes.3
+#K= 2d5fccd52e747b803c0dc96186675f3f FT_classmap_inheritance.1
+#K= 3dcfea837b96c36bc61150414d810f9d FT_classmap_inheritance.2
 #K= d4937472530af6fdcb0a2440d4a366ea FT_classmap_inheritance.3
-#K= fea6f925b829f75a5b2d4e837738fa12 FT_classmap_inheritance.4
-#K= 7e92245008439ee79fe2460aeaa16a9b FT_classmap_inheritance.5
+#K= 5a78f2fdd6958ef6329aaff2f67c0e1e FT_classmap_inheritance.4
+#K= f43e0aff8a4b38435b73d90ed8100d1b FT_classmap_inheritance.5
 #K= 94610c57ac44bd7011002a654fd78f93 FT_modprobe_w_param.1
 #K= 94610c57ac44bd7011002a654fd78f93 FT_modprobe_w_param.2
 #K= c1309e18dc9bf2f57184fa13164d917d FT_modprobe_w_param.3
@@ -701,11 +701,11 @@ function GOLDEN_RECORDS {
 #K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.8
 #K= 591411c42cf52d7c4c46d76bcc345a5f FT_modprobe_w_param.9
 #K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.10
-#K= b0435304108118e64529469e59332111 FT_modprobe_w_param.11
+#K= 46d24fecc507a8f9be0bd120e27ff64f FT_modprobe_w_param.11
 #K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.12
-#K= 4d036833ce9f661057a4e13d97295c65 FT_modprobe_w_param.13
+#K= 79298a323d3dcca4f74fb9fc0de5a87e FT_modprobe_w_param.13
 #K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.14
-#K= 5c3c6ecf6a46f9ccebd60c5ca9ebdbb7 FT_modprobe_w_param.15
+#K= f649752dfb07a68087f04dafc00ed1e8 FT_modprobe_w_param.15
 #K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.16
 #K= 73a93377a823739e8aae44856a20fa7f FT_modprobe_w_param.17
 #K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.18
@@ -719,11 +719,11 @@ function GOLDEN_RECORDS {
 #K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.26
 #K= 7b91db8e9f160aebb1ee87fab2232404 FT_modprobe_w_param.27
 #K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.28
-#K= caa849a2817863d68a8d11ee415b049c FT_modprobe_w_param.29
+#K= d6b0165e279e8b9d06fa637d17bb8b07 FT_modprobe_w_param.29
 #K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.30
-#K= e94cc54f62faa428a03f2a7dbca06f97 FT_modprobe_w_param.31
+#K= a067091b2133dfe203a1c53f7e5f8b00 FT_modprobe_w_param.31
 #K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.32
-#K= 8919dde0fee0cf42f9388e541b33aa01 FT_modprobe_w_param.33
+#K= 677ccaca4125771d6c42d5612de0b0b3 FT_modprobe_w_param.33
 #K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.34
 #K= ff5bf6afec9642da83d3dcdb5e732ab9 FT_modprobe_w_param.35
 #K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.36

-- 
2.55.0

