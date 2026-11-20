From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:46 -0500
Subject: [PATCH 55/60] mm/memory_hotplug: online and offline private memory
 nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-55-74f5f9a115c2@gourry.net>
References: <20261120-private_nodes_v6-v1-0-74f5f9a115c2@gourry.net>
In-Reply-To: <20261120-private_nodes_v6-v1-0-74f5f9a115c2@gourry.net>
To: Yury Norov <yury.norov@gmail.com>, 
 Rasmus Villemoes <linux@rasmusvillemoes.dk>, 
 David Hildenbrand <david@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Michal Hocko <mhocko@suse.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Oscar Salvador <osalvador@suse.de>, Johannes Weiner <hannes@cmpxchg.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Brendan Jackman <brendan.jackman@linux.dev>, Zi Yan <ziy@nvidia.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Rakie Kim <rakie.kim@sk.com>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Matthew Brost <matthew.brost@intel.com>, Byungchul Park <byungchul@sk.com>, 
 Alistair Popple <apopple@nvidia.com>, SJ Park <sj@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 K Prateek Nayak <kprateek.nayak@amd.com>, Kees Cook <kees@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Barry Song <baohua@kernel.org>, 
 Qi Zheng <qi.zheng@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Baoquan He <baoquan.he@linux.dev>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Michal Hocko <mhocko@kernel.org>, David Rientjes <rientjes@google.com>, 
 Pavel Machek <pavel@kernel.org>, Len Brown <lenb@kernel.org>, 
 Nico Pache <nico.pache@linux.dev>, Ryan Roberts <ryan.roberts@arm.com>, 
 Dev Jain <dev.jain@arm.com>, Lance Yang <lance.yang@linux.dev>, 
 Usama Arif <usama.arif@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 Xu Xin <xu.xin@linux.dev>, Chengming Zhou <chengming.zhou@linux.dev>, 
 Lorenzo Stoakes <ljs@kernel.org>, Pedro Falcato <pfalcato@suse.de>, 
 Jann Horn <jannh@google.com>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Youngjun Park <youngjun.park@lge.com>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, Jan Kara <jack@suse.cz>, 
 Waiman Long <longman@redhat.com>, Ridong Chen <ridong.chen@linux.dev>, 
 Tejun Heo <tj@kernel.org>, 
 =?utf-8?q?Michal_Koutn=C3=BD?= <mkoutny@suse.com>, 
 Dan Williams <djbw@kernel.org>, Vishal Verma <vishal.l.verma@intel.com>, 
 Dave Jiang <dave.jiang@intel.com>, 
 Alison Schofield <alison.schofield@intel.com>, 
 Shuah Khan <shuah@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-mm@kvack.org, 
 linux-cxl@vger.kernel.org, linux-doc@vger.kernel.org, 
 driver-core@lists.linux.dev, damon@lists.linux.dev, 
 linux-pm@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 cgroups@vger.kernel.org, nvdimm@lists.linux.dev, 
 linux-kselftest@vger.kernel.org, "Gregory Price (Meta)" <gourry@gourry.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198154; l=9476;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=b3jGnnyWNDUyPQKsXIBVFwBX7ofSFROdnSCpZbbkWAM=;
 b=dURyeucqjPXkJcCpnAWMuH39xYYU9Sy7XUOxE2r8Wwzbf7ANdiCKotrRObSTQ40QuJ0Zf1HzK
 SNlKPBgabacDKodij1dmaphP8727fp4GMxD4DcXEnSyqnVu+FgJGUPW
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow a driver to hotplug memory onto a private node at runtime.

Pass a feature mask through driver-managed hotplug, and reject masks
that node_memory_features_valid() refuses.

Memory joins a node only with the same mask. The node's features hold
while any System RAM block remains (including offline blocks), and are
reset after the last one is removed, even when ZONE_DEVICE memory keeps
the node alive.

dax/kmem and the other hotplug callers pass NODE_MEMORY_FEAT_ALL, which
registers the node as N_MEMORY_COMMON.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 drivers/dax/kmem.c             |  2 +-
 include/linux/memory_hotplug.h |  2 +-
 mm/internal.h                  |  9 ++++
 mm/memory_hotplug.c            | 94 +++++++++++++++++++++++++++++++-----------
 4 files changed, 80 insertions(+), 27 deletions(-)

diff --git a/drivers/dax/kmem.c b/drivers/dax/kmem.c
index a48d699cf344..5ec653bc88f0 100644
--- a/drivers/dax/kmem.c
+++ b/drivers/dax/kmem.c
@@ -126,7 +126,7 @@ static int dax_kmem_do_hotplug(struct dev_dax *dev_dax,
 		 */
 		rc = __add_memory_driver_managed(data->mgid, range.start,
 				range_len(&range), kmem_name, mhp_flags,
-				online_type);
+				online_type, NODE_MEMORY_FEAT_ALL);
 
 		if (rc) {
 			dev_warn(dev, "mapping%d: %#llx-%#llx memory add failed\n",
diff --git a/include/linux/memory_hotplug.h b/include/linux/memory_hotplug.h
index ec71debc0673..ae6046510958 100644
--- a/include/linux/memory_hotplug.h
+++ b/include/linux/memory_hotplug.h
@@ -304,7 +304,7 @@ extern int add_memory_resource(int nid, struct resource *resource,
 			       mhp_t mhp_flags);
 int __add_memory_driver_managed(int nid, u64 start, u64 size,
 				const char *resource_name, mhp_t mhp_flags,
-				enum mmop online_type);
+				enum mmop online_type, unsigned long features);
 extern int add_memory_driver_managed(int nid, u64 start, u64 size,
 				     const char *resource_name,
 				     mhp_t mhp_flags);
diff --git a/mm/internal.h b/mm/internal.h
index 646efc2eacd1..0eefa0df1350 100644
--- a/mm/internal.h
+++ b/mm/internal.h
@@ -65,6 +65,15 @@ void folio_mark_lazyfree(struct folio *folio);
 void node_set_memory_state(int nid, unsigned long features);
 void node_clear_memory_state(int nid);
 
+#ifdef CONFIG_MEMORY_HOTPLUG
+bool can_claim_node_memory(int nid, unsigned long features);
+#else
+static inline bool can_claim_node_memory(int nid, unsigned long features)
+{
+	return false;
+}
+#endif
+
 /*
  * Common memory is available to generic MM services. ZONE_DEVICE folios do
  * not qualify even when their NUMA node is common.
diff --git a/mm/memory_hotplug.c b/mm/memory_hotplug.c
index 8146f77919d5..37e64c146b46 100644
--- a/mm/memory_hotplug.c
+++ b/mm/memory_hotplug.c
@@ -1494,6 +1494,43 @@ static int create_altmaps_and_memory_blocks(int nid, struct memory_group *group,
 	return ret;
 }
 
+static int check_no_memblock_for_node_cb(struct memory_block *mem, void *arg)
+{
+	int nid = *(int *)arg;
+
+	/*
+	 * If a memory block belongs to multiple nodes, the stored nid is not
+	 * reliable. However, such blocks are always online (e.g., cannot get
+	 * offlined) and, therefore, are still spanned by the node.
+	 */
+	return mem->nid == nid ? -EEXIST : 0;
+}
+
+/* Caller must hold the memory hotplug lock for these checks. */
+static bool node_has_memory_blocks(int nid)
+{
+	return for_each_memory_block(&nid, check_no_memblock_for_node_cb);
+}
+
+static bool node_has_system_ram(int nid)
+{
+	/* Mixed-node memory blocks are always online and covered by N_MEMORY. */
+	return node_state(nid, N_MEMORY) || node_has_memory_blocks(nid);
+}
+
+/*
+ * Whether memory with @features may join @nid. Offline System RAM blocks keep
+ * the node's features until the last block is removed.
+ */
+bool can_claim_node_memory(int nid, unsigned long features)
+{
+	pg_data_t *pgdat = NODE_DATA(nid);
+
+	if (pgdat->memory_features == features)
+		return true;
+	return !node_has_system_ram(nid);
+}
+
 /*
  * NOTE: The caller must call lock_device_hotplug() to serialize hotplug
  * and online/offline operations (triggered e.g. by sysfs).
@@ -1501,11 +1538,12 @@ static int create_altmaps_and_memory_blocks(int nid, struct memory_group *group,
  * we are OK calling __meminit stuff here - we have CONFIG_MEMORY_HOTPLUG
  */
 static int __add_memory_resource(int nid, struct resource *res, mhp_t mhp_flags,
-				 enum mmop online_type)
+				 enum mmop online_type, unsigned long features)
 {
 	struct mhp_params params = { .pgprot = pgprot_mhp(PAGE_KERNEL) };
 	enum memblock_flags memblock_flags = MEMBLOCK_NONE;
 	struct memory_group *group = NULL;
+	unsigned long old_features;
 	u64 start, size;
 	bool new_node = false;
 	int ret;
@@ -1528,6 +1566,8 @@ static int __add_memory_resource(int nid, struct resource *res, mhp_t mhp_flags,
 		WARN(1, "node %d was absent from the node_possible_map\n", nid);
 		return -EINVAL;
 	}
+	if (!node_memory_features_valid(features))
+		return -EINVAL;
 
 	mem_hotplug_begin();
 
@@ -1552,6 +1592,14 @@ static int __add_memory_resource(int nid, struct resource *res, mhp_t mhp_flags,
 		new_node = true;
 	}
 
+	old_features = NODE_DATA(nid)->memory_features;
+	if (!can_claim_node_memory(nid, features)) {
+		ret = -EBUSY;
+		goto error;
+	}
+	/* Set the node's features before onlining its memory. */
+	WRITE_ONCE(NODE_DATA(nid)->memory_features, features);
+
 	/*
 	 * Self hosted memmap array
 	 */
@@ -1597,6 +1645,8 @@ static int __add_memory_resource(int nid, struct resource *res, mhp_t mhp_flags,
 
 	return ret;
 error:
+	/* Restore the previous features while holding the lock. */
+	WRITE_ONCE(NODE_DATA(nid)->memory_features, old_features);
 	if (new_node) {
 		node_set_offline(nid);
 		unregister_node(nid);
@@ -1612,7 +1662,8 @@ static int __add_memory_resource(int nid, struct resource *res, mhp_t mhp_flags,
 int add_memory_resource(int nid, struct resource *res, mhp_t mhp_flags)
 {
 	return __add_memory_resource(nid, res, mhp_flags,
-				     mhp_get_default_online_type());
+				     mhp_get_default_online_type(),
+				     NODE_MEMORY_FEAT_ALL);
 }
 
 /* requires device_hotplug_lock, see __add_memory_resource() */
@@ -1651,6 +1702,9 @@ EXPORT_SYMBOL_GPL(add_memory);
  * @resource_name: Resource name in format "System RAM ($DRIVER)"
  * @mhp_flags: Memory hotplug flags
  * @online_type: Auto-Online behavior (offline, online, kernel, movable)
+ * @features: NODE_MEMORY_FEAT_* services the memory opts into;
+ *            %NODE_MEMORY_FEAT_ALL adds it as ordinary common system RAM,
+ *            and a mask without %NODE_MEMORY_FEAT_COMMON as private memory.
  *
  * Add special, driver-managed memory to the system as system RAM. Such
  * memory is not exposed via the raw firmware-provided memmap as system
@@ -1677,7 +1731,7 @@ EXPORT_SYMBOL_GPL(add_memory);
  */
 int __add_memory_driver_managed(int nid, u64 start, u64 size,
 		const char *resource_name, mhp_t mhp_flags,
-		enum mmop online_type)
+		enum mmop online_type, unsigned long features)
 {
 	struct resource *res;
 	int rc;
@@ -1698,7 +1752,7 @@ int __add_memory_driver_managed(int nid, u64 start, u64 size,
 		goto out_unlock;
 	}
 
-	rc = __add_memory_resource(nid, res, mhp_flags, online_type);
+	rc = __add_memory_resource(nid, res, mhp_flags, online_type, features);
 	if (rc < 0)
 		release_memory_resource(res);
 
@@ -1727,8 +1781,8 @@ int add_memory_driver_managed(int nid, u64 start, u64 size,
 			      const char *resource_name, mhp_t mhp_flags)
 {
 	return __add_memory_driver_managed(nid, start, size, resource_name,
-			mhp_flags,
-			mhp_get_default_online_type());
+			mhp_flags, mhp_get_default_online_type(),
+			NODE_MEMORY_FEAT_ALL);
 }
 EXPORT_SYMBOL_GPL(add_memory_driver_managed);
 
@@ -1789,18 +1843,6 @@ bool mhp_range_allowed(u64 start, u64 size, bool need_mapping)
 
 #ifdef CONFIG_MEMORY_HOTREMOVE
 
-static int check_no_memblock_for_node_cb(struct memory_block *mem, void *arg)
-{
-	int nid = *(int *)arg;
-
-	/*
-	 * If a memory block belongs to multiple nodes, the stored nid is not
-	 * reliable. However, such blocks are always online (e.g., cannot get
-	 * offlined) and, therefore, are still spanned by the node.
-	 */
-	return mem->nid == nid ? -EEXIST : 0;
-}
-
 /* Caller must hold the memory hotplug lock for this check. */
 static bool node_is_memoryless(int nid)
 {
@@ -1811,12 +1853,9 @@ static bool node_is_memoryless(int nid)
 	 */
 	if (node_spanned_pages(nid))
 		return false;
-	/*
-	 * Offline memory blocks may not be spanned by the node yet, but they
-	 * link to it in sysfs and can be onlined later, so the node is not
-	 * memoryless while any remain.
-	 */
-	return !for_each_memory_block(&nid, check_no_memblock_for_node_cb);
+
+	/* Offline memory blocks keep the node alive so they can be onlined. */
+	return !node_has_memory_blocks(nid);
 }
 
 /*
@@ -2347,8 +2386,13 @@ static int try_remove_memory(u64 start, u64 size)
 
 	release_mem_region_adjustable(start, size);
 
-	if (nid != NUMA_NO_NODE)
+	if (nid != NUMA_NO_NODE) {
+		/* No System RAM left: reset the node's features. */
+		if (!node_has_system_ram(nid))
+			WRITE_ONCE(NODE_DATA(nid)->memory_features,
+				   NODE_MEMORY_FEAT_ALL);
 		try_offline_node(nid);
+	}
 
 	mem_hotplug_done();
 	return 0;

-- 
2.56.1

