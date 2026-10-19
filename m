From: Xiubo Li <xiubo.li@clyso.com>
Date: Mon, 19 Oct 2026 13:33:28 +0200
Subject: [PATCH v2 2/4] ceph: drop the unused subvolume metrics debug
 counters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-ceph-metrics-percpu-v2-2-1fa5229b00b8@clyso.com>
References: <20261019-ceph-metrics-percpu-v2-0-1fa5229b00b8@clyso.com>
In-Reply-To: <20261019-ceph-metrics-percpu-v2-0-1fa5229b00b8@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Xiubo Li <xiubo.li@clyso.com>, Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dan van der Ster <dan.vanderster@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792409634; l=5945;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=gaWMTABAxeJ++HgckwUw1lcVL3j/VBtD0PVyKfJakCQ=;
 b=iIpCd8pEENMzR8g3SHkRuHKGWS5Iji/5zVWosP5r5VCifYSuhssu1mwJgvYWWj68Zrp4EbxPE
 4zSOkDHUmL/ANWbeTkjxDL/aaqfjFpjTdheb2qAmhuLU5u7NIWNiNen
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ceph_subvolume_metrics_record_io() bumps tracker->record_calls on
every OSD read and write completion, plus record_disabled or
record_no_subvol when it bails out, and ceph_subvolume_metrics_record()
adds to the total_read/write_ops/bytes counters on top of its own
per-subvolume ones.  All of them are atomic64_t shared by every CPU
of the mount, so even with subvolume metrics disabled each I/O
completion dirties a cache line that every other completion on the
client also writes.

Nothing ever reads these counters, nor the snapshot_* ones: debugfs
prints the per-subvolume entries and the totals kept under
subvol_metrics_last_mutex.  Remove them.

Fixes: b1137e0b3d4b ("ceph: add subvolume metrics collection and reporting")
Reported-by: Dan van der Ster <dan.vanderster@clyso.com>
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/subvolume_metrics.c | 34 ++++------------------------------
 fs/ceph/subvolume_metrics.h | 21 ---------------------
 2 files changed, 4 insertions(+), 51 deletions(-)

diff --git a/fs/ceph/subvolume_metrics.c b/fs/ceph/subvolume_metrics.c
index 03fda1f9257b..895878a49ea7 100644
--- a/fs/ceph/subvolume_metrics.c
+++ b/fs/ceph/subvolume_metrics.c
@@ -39,16 +39,6 @@ void ceph_subvolume_metrics_init(struct ceph_subvolume_metrics_tracker *tracker)
 	tracker->tree = RB_ROOT_CACHED;
 	tracker->nr_entries = 0;
 	tracker->enabled = false;
-	atomic64_set(&tracker->snapshot_attempts, 0);
-	atomic64_set(&tracker->snapshot_empty, 0);
-	atomic64_set(&tracker->snapshot_failures, 0);
-	atomic64_set(&tracker->record_calls, 0);
-	atomic64_set(&tracker->record_disabled, 0);
-	atomic64_set(&tracker->record_no_subvol, 0);
-	atomic64_set(&tracker->total_read_ops, 0);
-	atomic64_set(&tracker->total_read_bytes, 0);
-	atomic64_set(&tracker->total_write_ops, 0);
-	atomic64_set(&tracker->total_write_bytes, 0);
 }
 
 static struct ceph_subvol_metric_rb_entry *
@@ -196,14 +186,10 @@ void ceph_subvolume_metrics_record(struct ceph_subvolume_metrics_tracker *tracke
 			entry->write_ops++;
 			entry->write_bytes += size;
 			entry->write_latency_us += latency_us;
-			atomic64_inc(&tracker->total_write_ops);
-			atomic64_add(size, &tracker->total_write_bytes);
 		} else {
 			entry->read_ops++;
 			entry->read_bytes += size;
 			entry->read_latency_us += latency_us;
-			atomic64_inc(&tracker->total_read_ops);
-			atomic64_add(size, &tracker->total_read_bytes);
 		}
 		spin_unlock(&tracker->lock);
 		if (new_entry)
@@ -227,8 +213,6 @@ int ceph_subvolume_metrics_snapshot(struct ceph_subvolume_metrics_tracker *track
 	if (!READ_ONCE(tracker->enabled))
 		return 0;
 
-	atomic64_inc(&tracker->snapshot_attempts);
-
 	spin_lock(&tracker->lock);
 	for (node = rb_first_cached(&tracker->tree); node; node = rb_next(node)) {
 		struct ceph_subvol_metric_rb_entry *entry =
@@ -240,16 +224,12 @@ int ceph_subvolume_metrics_snapshot(struct ceph_subvolume_metrics_tracker *track
 	}
 	spin_unlock(&tracker->lock);
 
-	if (!count) {
-		atomic64_inc(&tracker->snapshot_empty);
+	if (!count)
 		return 0;
-	}
 
 	snap = kcalloc(count, sizeof(*snap), GFP_NOFS);
-	if (!snap) {
-		atomic64_inc(&tracker->snapshot_failures);
+	if (!snap)
 		return -ENOMEM;
-	}
 
 	spin_lock(&tracker->lock);
 	node = rb_first_cached(&tracker->tree);
@@ -380,18 +360,12 @@ void ceph_subvolume_metrics_record_io(struct ceph_mds_client *mdsc,
 		return;
 
 	tracker = &mdsc->subvol_metrics;
-	atomic64_inc(&tracker->record_calls);
-
-	if (!ceph_subvolume_metrics_enabled(tracker)) {
-		atomic64_inc(&tracker->record_disabled);
+	if (!ceph_subvolume_metrics_enabled(tracker))
 		return;
-	}
 
 	subvol_id = READ_ONCE(ci->i_subvolume_id);
-	if (subvol_id == CEPH_SUBVOLUME_ID_NONE) {
-		atomic64_inc(&tracker->record_no_subvol);
+	if (subvol_id == CEPH_SUBVOLUME_ID_NONE)
 		return;
-	}
 
 	delta_us = ktime_to_us(ktime_sub(end, start));
 	if (delta_us <= 0)
diff --git a/fs/ceph/subvolume_metrics.h b/fs/ceph/subvolume_metrics.h
index 6f53ff726c75..8b901ae05e00 100644
--- a/fs/ceph/subvolume_metrics.h
+++ b/fs/ceph/subvolume_metrics.h
@@ -6,7 +6,6 @@
 #include <linux/rbtree.h>
 #include <linux/spinlock.h>
 #include <linux/ktime.h>
-#include <linux/atomic.h>
 
 struct seq_file;
 struct ceph_mds_client;
@@ -38,32 +37,12 @@ struct ceph_subvol_metric_snapshot {
  * @tree: Red-black tree of per-subvolume entries, keyed by subvolume_id
  * @nr_entries: Number of entries currently in @tree
  * @enabled: Whether collection is enabled (requires MDS feature support)
- * @snapshot_attempts: Debug counter: total ceph_subvolume_metrics_snapshot() calls
- * @snapshot_empty: Debug counter: snapshots that found no data to report
- * @snapshot_failures: Debug counter: snapshots that failed to allocate memory
- * @record_calls: Debug counter: total ceph_subvolume_metrics_record() calls
- * @record_disabled: Debug counter: record calls skipped because disabled
- * @record_no_subvol: Debug counter: record calls skipped (no subvolume_id)
- * @total_read_ops: Cumulative read ops across all snapshots (never reset)
- * @total_read_bytes: Cumulative bytes read across all snapshots (never reset)
- * @total_write_ops: Cumulative write ops across all snapshots (never reset)
- * @total_write_bytes: Cumulative bytes written across all snapshots (never reset)
  */
 struct ceph_subvolume_metrics_tracker {
 	spinlock_t lock;
 	struct rb_root_cached tree;
 	u32 nr_entries;
 	bool enabled;
-	atomic64_t snapshot_attempts;
-	atomic64_t snapshot_empty;
-	atomic64_t snapshot_failures;
-	atomic64_t record_calls;
-	atomic64_t record_disabled;
-	atomic64_t record_no_subvol;
-	atomic64_t total_read_ops;
-	atomic64_t total_read_bytes;
-	atomic64_t total_write_ops;
-	atomic64_t total_write_bytes;
 };
 
 void ceph_subvolume_metrics_init(struct ceph_subvolume_metrics_tracker *tracker);

-- 
2.53.0

