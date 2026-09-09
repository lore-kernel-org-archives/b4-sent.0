From: Jim Cromie <jim.cromie@gmail.com>
Date: Tue, 08 Sep 2026 18:55:22 -0600
Subject: [PATCH v9 26/39] dyndbg: detect class_id reservation conflicts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-dd-cmap-part2-clean-v9-26-3a3f621f4a10@gmail.com>
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
 Jim Cromie <jim.cromie@gmail.com>, 
 Louis Chauvet <louis.chauvet@bootlin.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788915300; l=6755;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=S1c2OmlM1oIoBp+FxVegF45OlJDDvILkxusGJ7a4C04=;
 b=aC5ePyUoiu+q6kwt0okh/YMl6IJ+6XIIu1Iz4qdFnMzhPheDMj5sj0bi7+FmdvmotCpLS73+G
 ngmV7ck4bnIB/LnxR1u0DozS3DTvLQNXp52E+e0bMdMIfSg1KnnYMy5
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If a module _DEFINEs 2 or more classmaps, it must devise them to share
the per-module 0..62 class-id space; ie their respective base,+length
reservations cannot overlap.

To detect conflicts at modprobe, add ddebug_class_range_overlap(),
call it from ddebug_add_module(), and WARN and return -EINVAL when
they're detected.

This insures that class_id -> classname lookup has just 1 answer, so
the 1st-found search in find-class-name works properly.

test_dynamic_debug.c:

If built with -DFORCE_CLASSID_CONFLICT, the test-modules invoke 2
conflicting DYNAMIC_DEBUG_CLASSMAP_DEFINE() declarations, into parent
and the _submod.  These conflict with one of the good ones in the
parent (D2_CORE..etc), causing the modprobe(s) to WARN and fail.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
Reviewed-by: Louis Chauvet <louis.chauvet@bootlin.com>
---
v9:
. make ddebug_add_module() failure non-fatal during dynamic_debug_init(),
  logging warning and continuing instead of tearing down all tables kernel-wide.
v2: RvB after SoB

old-v9 - fix WARN() by adding new 1st arg 1.
old-v12 - drop maybe_unused on range-overlap fn
---
 lib/dynamic_debug.c      | 60 +++++++++++++++++++++++++++---------------------
 lib/test_dynamic_debug.c |  8 +++++++
 2 files changed, 42 insertions(+), 26 deletions(-)

diff --git a/lib/dynamic_debug.c b/lib/dynamic_debug.c
index e55747d26515..11aca5d0c89e 100644
--- a/lib/dynamic_debug.c
+++ b/lib/dynamic_debug.c
@@ -1101,18 +1101,19 @@ static void *ddebug_proc_next(struct seq_file *m, void *p, loff_t *pos)
 	return dp;
 }
 
-static bool ddebug_class_in_range(const int class_id, const struct ddebug_class_map *map)
+static bool ddebug_class_map_in_range(const int class_id, const struct ddebug_class_map *map)
 {
+	if (!map)
+		return false;
 	return (class_id >= map->base &&
 		class_id < map->base + map->length);
 }
 
-static bool ddebug_user_class_in_range(const int class_id, const struct ddebug_class_user *cli)
+static bool ddebug_class_user_in_range(const int class_id, const struct ddebug_class_user *user)
 {
-	if (!cli || !cli->map)
+	if (!user)
 		return false;
-	int base = cli->map->base + cli->offset;
-	return (class_id >= base && class_id < base + cli->map->length);
+	return ddebug_class_map_in_range(class_id - user->offset, user->map);
 }
 
 static const char *ddebug_class_name(struct _ddebug_info *di, struct _ddebug *dp)
@@ -1122,11 +1123,11 @@ static const char *ddebug_class_name(struct _ddebug_info *di, struct _ddebug *dp
 	int i;
 
 	for_subvec(i, map, di, maps)
-		if (ddebug_class_in_range(dp->class_id, map))
+		if (ddebug_class_map_in_range(dp->class_id, map))
 			return map->class_names[dp->class_id - map->base];
 
 	for_subvec(i, cli, di, users)
-		if (ddebug_user_class_in_range(dp->class_id, cli))
+		if (ddebug_class_user_in_range(dp->class_id, cli))
 			return cli->map->class_names[dp->class_id - cli->map->base - cli->offset];
 
 	return NULL;
@@ -1369,6 +1370,20 @@ static void ddebug_apply_class_users(const struct _ddebug_info *di)
 		__di->_vec.start = __start;				\
 })
 
+static int ddebug_class_range_overlap(struct ddebug_class_map *cm, u64 *reserved_ids)
+{
+	u64 range = (((1ULL << cm->length) - 1) << cm->base);
+
+	if (range & *reserved_ids) {
+		pr_err("[%d..%d] on %s conflicts with %llx\n", cm->base,
+		       cm->base + cm->length - 1, cm->class_names[0],
+		       *reserved_ids);
+		return -EINVAL;
+	}
+	*reserved_ids |= range;
+	return 0;
+}
+
 /*
  * Allocate a new ddebug_table for the given module
  * and add it to the global list.
@@ -1378,6 +1393,7 @@ static int ddebug_add_module(struct _ddebug_info *di)
 	struct ddebug_table *dt;
 	struct ddebug_class_map *cm;
 	struct ddebug_class_user *cli;
+	u64 reserved_ids = 0;
 	int i;
 
 	if (!di->descs.len)
@@ -1409,16 +1425,24 @@ static int ddebug_add_module(struct _ddebug_info *di)
 	dd_set_module_subrange(i, cm, &dt->info, maps);
 	dd_set_module_subrange(i, cli, &dt->info, users);
 
+	/* insure 2+ classmaps share the per-module 0..62 class_id space */
+	for_subvec(i, cm, &dt->info, maps)
+		if (ddebug_class_range_overlap(cm, &reserved_ids))
+			goto cleanup;
+
 	mutex_lock(&ddebug_lock);
 	list_add_tail(&dt->link, &ddebug_tables);
 	mutex_unlock(&ddebug_lock);
-
 	if (dt->info.users.len)
 		ddebug_apply_class_users(&dt->info);
 
 	vpr_info("%3u debug prints in module %s\n",
 		 dt->info.descs.len, dt->info.mod_name);
 	return 0;
+cleanup:
+	WARN_ONCE(1, "dyndbg multi-classmap conflict in %s\n", di->mod_name);
+	kfree(dt);
+	return -EINVAL;
 }
 
 /* helper for ddebug_dyndbg_(boot|module)_param_cb */
@@ -1520,18 +1544,6 @@ static struct notifier_block ddebug_module_nb = {
 
 #endif /* CONFIG_MODULES */
 
-static void ddebug_remove_all_tables(void)
-{
-	mutex_lock(&ddebug_lock);
-	while (!list_empty(&ddebug_tables)) {
-		struct ddebug_table *dt = list_entry(ddebug_tables.next,
-						     struct ddebug_table,
-						     link);
-		ddebug_table_free(dt);
-	}
-	mutex_unlock(&ddebug_lock);
-}
-
 static __initdata int ddebug_init_success;
 
 static int __init dynamic_debug_init_control(void)
@@ -1602,7 +1614,7 @@ static int __init dynamic_debug_init(void)
 			di.mod_name = modname;
 			ret = ddebug_add_module(&di);
 			if (ret)
-				goto out_err;
+				pr_warn("failed to add built-in module %s: %d\n", modname, ret);
 
 			mod_ct++;
 
@@ -1617,7 +1629,7 @@ static int __init dynamic_debug_init(void)
 	di.mod_name = modname;
 	ret = ddebug_add_module(&di);
 	if (ret)
-		goto out_err;
+		pr_warn("failed to add built-in module %s: %d\n", modname, ret);
 
 	mod_ct++;
 
@@ -1642,10 +1654,6 @@ static int __init dynamic_debug_init(void)
 		   0, 0, 0, NULL, &ddebug_dyndbg_boot_param_cb);
 	kfree(cmdline);
 	return 0;
-
-out_err:
-	ddebug_remove_all_tables();
-	return 0;
 }
 /* Allow early initialization for boot messages via boot param */
 early_initcall(dynamic_debug_init);
diff --git a/lib/test_dynamic_debug.c b/lib/test_dynamic_debug.c
index 34e51996aa20..3a69cc3cae6d 100644
--- a/lib/test_dynamic_debug.c
+++ b/lib/test_dynamic_debug.c
@@ -128,6 +128,14 @@ DYNAMIC_DEBUG_CLASSMAP_DEFINE(map_disjoint_bits, DD_CLASS_TYPE_DISJOINT_BITS,
 DYNAMIC_DEBUG_CLASSMAP_DEFINE(map_level_num, DD_CLASS_TYPE_LEVEL_NUM,
 			      V1, "V1", "V2", "V3", "V4", "V5", "V6", "V7");
 
+#ifdef FORCE_CLASSID_CONFLICT
+/*
+ * Enable with -Dflag on compile to test overlapping class-id range
+ * detection.  This should warn on modprobes.
+ */
+DYNAMIC_DEBUG_CLASSMAP_DEFINE(classid_range_conflict, 0, D2_CORE + 1, "D3_CORE");
+#endif
+
 #else /* TEST_DYNAMIC_DEBUG_SUBMOD */
 
 /*

-- 
2.55.0

