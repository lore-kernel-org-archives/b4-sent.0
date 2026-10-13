From: Xiubo Li <xiubo.li@clyso.com>
Date: Wed, 14 Oct 2026 01:20:42 +0200
Subject: [PATCH 3/3] ceph: accumulate subvolume metrics per CPU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-ceph-metrics-percpu-v1-3-38c5a24fec6e@clyso.com>
References: <20261014-ceph-metrics-percpu-v1-0-38c5a24fec6e@clyso.com>
In-Reply-To: <20261014-ceph-metrics-percpu-v1-0-38c5a24fec6e@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>, 
 Milind Changire <mchangir@redhat.com>, Jeff Layton <jlayton@kernel.org>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dan van der Ster <dan.vanderster@clyso.com>, Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791933643; l=10988;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=ejyhU/j4h0EfNpY7w3/UC+A/gQ5WXha8Jsf0MYe73u0=;
 b=2iD/Eic2g6JGSJGqJbIkB5PSa16+k9k+MAWZDdwcrb++jfe92xU8G8rtqjgqGLLd7LPa0q5lJ
 5d3uUCxeiGaDQM+S8vXUc/vCGQmUchCrCujFnjbacHRbocdKkep52ik
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With subvolume metrics enabled, every OSD read and write completion
takes the mount-wide tracker->lock and walks the rbtree of subvolumes
to add one op to its entry.  On a client with many cores doing a
large bandwidth, the completions of all its CPUs serialize on that
spinlock and bounce its cache line.

Give each CPU a slot holding the counters of one subvolume.  A
completion only takes its own slot's lock and adds to it; it goes to
the tree only when the slot held another subvolume, whose counters it
then folds into the tree entry the old way.  The metrics sender and
the debugfs dump fold every slot into the tree before they read it,
so what they report is unchanged.  A client usually works in one
subvolume at a time, so the tree is touched once per CPU and snapshot
instead of once per I/O.

The slot is looked up with raw_cpu_ptr() and protected by its own
lock, so a task that migrates in between just updates another CPU's
slot.  ceph_subvolume_metrics_init() now allocates the per-CPU slots
and can fail.

Reported-by: Dan van der Ster <dan.vanderster@clyso.com>
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/mds_client.c        |   6 +-
 fs/ceph/subvolume_metrics.c | 140 +++++++++++++++++++++++++++++++++++++-------
 fs/ceph/subvolume_metrics.h |   5 +-
 3 files changed, 129 insertions(+), 22 deletions(-)

diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index d4ef8a355a48..649284a2e746 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -6501,7 +6501,9 @@ int ceph_mdsc_init(struct ceph_fs_client *fsc)
 	err = ceph_metric_init(&mdsc->metric);
 	if (err)
 		goto err_mdsmap;
-	ceph_subvolume_metrics_init(&mdsc->subvol_metrics);
+	err = ceph_subvolume_metrics_init(&mdsc->subvol_metrics);
+	if (err)
+		goto err_metric;
 	mutex_init(&mdsc->subvol_metrics_last_mutex);
 	mdsc->subvol_metrics_last = NULL;
 	mdsc->subvol_metrics_last_nr = 0;
@@ -6533,6 +6535,8 @@ int ceph_mdsc_init(struct ceph_fs_client *fsc)
 	fsc->mdsc = mdsc;
 	return 0;
 
+err_metric:
+	ceph_metric_destroy(&mdsc->metric);
 err_mdsmap:
 	kfree(mdsc->mdsmap);
 err_mdsc:
diff --git a/fs/ceph/subvolume_metrics.c b/fs/ceph/subvolume_metrics.c
index 895878a49ea7..def26152e5fc 100644
--- a/fs/ceph/subvolume_metrics.c
+++ b/fs/ceph/subvolume_metrics.c
@@ -31,14 +31,36 @@ struct ceph_subvol_metric_rb_entry {
 	u64 write_latency_us;
 };
 
+/**
+ * struct ceph_subvol_metric_pcpu - Per-CPU accumulator in front of the tree
+ * @lock: Protects @m; only contended when a task migrates mid-update
+ * @m: Counters of one subvolume (@m.subvolume_id) not yet folded into the tree
+ *
+ * I/O completions add to the slot of the CPU they run on and only take
+ * tracker->lock when the slot holds another subvolume, or when a snapshot
+ * or a dump folds every slot into the tree.
+ */
+struct ceph_subvol_metric_pcpu {
+	spinlock_t lock;
+	struct ceph_subvol_metric_snapshot m;
+};
+
 static struct kmem_cache *ceph_subvol_metric_entry_cachep;
 
-void ceph_subvolume_metrics_init(struct ceph_subvolume_metrics_tracker *tracker)
+int ceph_subvolume_metrics_init(struct ceph_subvolume_metrics_tracker *tracker)
 {
+	int cpu;
+
 	spin_lock_init(&tracker->lock);
 	tracker->tree = RB_ROOT_CACHED;
 	tracker->nr_entries = 0;
 	tracker->enabled = false;
+	tracker->pcpu = alloc_percpu(struct ceph_subvol_metric_pcpu);
+	if (!tracker->pcpu)
+		return -ENOMEM;
+	for_each_possible_cpu(cpu)
+		spin_lock_init(&per_cpu_ptr(tracker->pcpu, cpu)->lock);
+	return 0;
 }
 
 static struct ceph_subvol_metric_rb_entry *
@@ -109,12 +131,28 @@ static void ceph_subvolume_metrics_clear_locked(
 	tracker->tree = RB_ROOT_CACHED;
 }
 
+static void ceph_subvolume_metrics_clear_pcpu(
+		struct ceph_subvolume_metrics_tracker *tracker)
+{
+	int cpu;
+
+	for_each_possible_cpu(cpu) {
+		struct ceph_subvol_metric_pcpu *pc = per_cpu_ptr(tracker->pcpu, cpu);
+
+		spin_lock(&pc->lock);
+		memset(&pc->m, 0, sizeof(pc->m));
+		spin_unlock(&pc->lock);
+	}
+}
+
 void ceph_subvolume_metrics_destroy(struct ceph_subvolume_metrics_tracker *tracker)
 {
 	spin_lock(&tracker->lock);
 	ceph_subvolume_metrics_clear_locked(tracker);
 	tracker->enabled = false;
 	spin_unlock(&tracker->lock);
+	free_percpu(tracker->pcpu);
+	tracker->pcpu = NULL;
 }
 
 void ceph_subvolume_metrics_enable(struct ceph_subvolume_metrics_tracker *tracker,
@@ -128,20 +166,20 @@ void ceph_subvolume_metrics_enable(struct ceph_subvolume_metrics_tracker *tracke
 		ceph_subvolume_metrics_clear_locked(tracker);
 	}
 	spin_unlock(&tracker->lock);
+	if (!enable)
+		ceph_subvolume_metrics_clear_pcpu(tracker);
 }
 
-void ceph_subvolume_metrics_record(struct ceph_subvolume_metrics_tracker *tracker,
-				   u64 subvol_id, bool is_write,
-				   size_t size, u64 latency_us)
+/*
+ * Add the counters of one subvolume taken out of a per-CPU slot to its
+ * entry in the tree.
+ */
+static void ceph_subvolume_metrics_fold(struct ceph_subvolume_metrics_tracker *tracker,
+					const struct ceph_subvol_metric_snapshot *d)
 {
 	struct ceph_subvol_metric_rb_entry *entry, *new_entry = NULL;
 	bool retry = false;
 
-	/* CEPH_SUBVOLUME_ID_NONE (0) means unknown/unset subvolume */
-	if (!READ_ONCE(tracker->enabled) ||
-	    subvol_id == CEPH_SUBVOLUME_ID_NONE || !size || !latency_us)
-		return;
-
 	/*
 	 * Retry loop for lock-free allocation pattern:
 	 * 1. First iteration: lookup under lock, if miss -> drop lock, alloc, retry
@@ -158,7 +196,7 @@ void ceph_subvolume_metrics_record(struct ceph_subvolume_metrics_tracker *tracke
 			return;
 		}
 
-		entry = __lookup_entry(tracker, subvol_id);
+		entry = __lookup_entry(tracker, d->subvolume_id);
 		if (!entry) {
 			if (!new_entry) {
 				spin_unlock(&tracker->lock);
@@ -166,7 +204,7 @@ void ceph_subvolume_metrics_record(struct ceph_subvolume_metrics_tracker *tracke
 						      GFP_NOFS);
 				if (!new_entry)
 					return;
-				new_entry->subvolume_id = subvol_id;
+				new_entry->subvolume_id = d->subvolume_id;
 				retry = true;
 				continue;
 			}
@@ -182,15 +220,12 @@ void ceph_subvolume_metrics_record(struct ceph_subvolume_metrics_tracker *tracke
 			new_entry = NULL;
 		}
 
-		if (is_write) {
-			entry->write_ops++;
-			entry->write_bytes += size;
-			entry->write_latency_us += latency_us;
-		} else {
-			entry->read_ops++;
-			entry->read_bytes += size;
-			entry->read_latency_us += latency_us;
-		}
+		entry->read_ops += d->read_ops;
+		entry->read_bytes += d->read_bytes;
+		entry->read_latency_us += d->read_latency_us;
+		entry->write_ops += d->write_ops;
+		entry->write_bytes += d->write_bytes;
+		entry->write_latency_us += d->write_latency_us;
 		spin_unlock(&tracker->lock);
 		if (new_entry)
 			kmem_cache_free(ceph_subvol_metric_entry_cachep, new_entry);
@@ -198,6 +233,66 @@ void ceph_subvolume_metrics_record(struct ceph_subvolume_metrics_tracker *tracke
 	} while (retry);
 }
 
+/* Move what every per-CPU slot holds into the tree. */
+static void ceph_subvolume_metrics_fold_pcpu(
+		struct ceph_subvolume_metrics_tracker *tracker)
+{
+	int cpu;
+
+	for_each_possible_cpu(cpu) {
+		struct ceph_subvol_metric_pcpu *pc = per_cpu_ptr(tracker->pcpu, cpu);
+		struct ceph_subvol_metric_snapshot d;
+
+		spin_lock(&pc->lock);
+		d = pc->m;
+		memset(&pc->m, 0, sizeof(pc->m));
+		pc->m.subvolume_id = d.subvolume_id;
+		spin_unlock(&pc->lock);
+
+		if (d.read_ops || d.write_ops)
+			ceph_subvolume_metrics_fold(tracker, &d);
+	}
+}
+
+void ceph_subvolume_metrics_record(struct ceph_subvolume_metrics_tracker *tracker,
+				   u64 subvol_id, bool is_write,
+				   size_t size, u64 latency_us)
+{
+	struct ceph_subvol_metric_snapshot old = {};
+	struct ceph_subvol_metric_pcpu *pc;
+
+	/* CEPH_SUBVOLUME_ID_NONE (0) means unknown/unset subvolume */
+	if (!READ_ONCE(tracker->enabled) ||
+	    subvol_id == CEPH_SUBVOLUME_ID_NONE || !size || !latency_us)
+		return;
+
+	/*
+	 * The slot of the CPU we start on; if we migrate, the lock still
+	 * keeps the update consistent and it just lands in another slot.
+	 */
+	pc = raw_cpu_ptr(tracker->pcpu);
+	spin_lock(&pc->lock);
+	if (unlikely(pc->m.subvolume_id != subvol_id)) {
+		old = pc->m;
+		memset(&pc->m, 0, sizeof(pc->m));
+		pc->m.subvolume_id = subvol_id;
+	}
+	if (is_write) {
+		pc->m.write_ops++;
+		pc->m.write_bytes += size;
+		pc->m.write_latency_us += latency_us;
+	} else {
+		pc->m.read_ops++;
+		pc->m.read_bytes += size;
+		pc->m.read_latency_us += latency_us;
+	}
+	spin_unlock(&pc->lock);
+
+	/* the slot held another subvolume: hand its counters to the tree */
+	if (old.read_ops || old.write_ops)
+		ceph_subvolume_metrics_fold(tracker, &old);
+}
+
 int ceph_subvolume_metrics_snapshot(struct ceph_subvolume_metrics_tracker *tracker,
 				    struct ceph_subvol_metric_snapshot **out,
 				    u32 *nr, bool consume)
@@ -213,6 +308,8 @@ int ceph_subvolume_metrics_snapshot(struct ceph_subvolume_metrics_tracker *track
 	if (!READ_ONCE(tracker->enabled))
 		return 0;
 
+	ceph_subvolume_metrics_fold_pcpu(tracker);
+
 	spin_lock(&tracker->lock);
 	for (node = rb_first_cached(&tracker->tree); node; node = rb_next(node)) {
 		struct ceph_subvol_metric_rb_entry *entry =
@@ -306,6 +403,9 @@ void ceph_subvolume_metrics_dump(struct ceph_subvolume_metrics_tracker *tracker,
 	struct rb_node *node;
 	bool found = false;
 
+	if (READ_ONCE(tracker->enabled))
+		ceph_subvolume_metrics_fold_pcpu(tracker);
+
 	spin_lock(&tracker->lock);
 	if (!tracker->enabled) {
 		spin_unlock(&tracker->lock);
diff --git a/fs/ceph/subvolume_metrics.h b/fs/ceph/subvolume_metrics.h
index 8b901ae05e00..b29d48e9a4f1 100644
--- a/fs/ceph/subvolume_metrics.h
+++ b/fs/ceph/subvolume_metrics.h
@@ -10,6 +10,7 @@
 struct seq_file;
 struct ceph_mds_client;
 struct ceph_inode_info;
+struct ceph_subvol_metric_pcpu;
 
 /**
  * struct ceph_subvol_metric_snapshot - Point-in-time snapshot of subvolume metrics
@@ -37,15 +38,17 @@ struct ceph_subvol_metric_snapshot {
  * @tree: Red-black tree of per-subvolume entries, keyed by subvolume_id
  * @nr_entries: Number of entries currently in @tree
  * @enabled: Whether collection is enabled (requires MDS feature support)
+ * @pcpu: Per-CPU accumulators that I/O completions update without @lock
  */
 struct ceph_subvolume_metrics_tracker {
 	spinlock_t lock;
 	struct rb_root_cached tree;
 	u32 nr_entries;
 	bool enabled;
+	struct ceph_subvol_metric_pcpu __percpu *pcpu;
 };
 
-void ceph_subvolume_metrics_init(struct ceph_subvolume_metrics_tracker *tracker);
+int ceph_subvolume_metrics_init(struct ceph_subvolume_metrics_tracker *tracker);
 void ceph_subvolume_metrics_destroy(struct ceph_subvolume_metrics_tracker *tracker);
 void ceph_subvolume_metrics_enable(struct ceph_subvolume_metrics_tracker *tracker,
 				   bool enable);

-- 
2.53.0

