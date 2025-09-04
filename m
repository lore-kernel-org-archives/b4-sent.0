From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 04 Sep 2025 08:20:37 +0300
Subject: [PATCH v3 6/7] bcachefs: Better progress reporting for btree
 iteration without leaves
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250904-better-progress-v3-6-6cc4edf543f4@gmail.com>
References: <20250904-better-progress-v3-0-6cc4edf543f4@gmail.com>
In-Reply-To: <20250904-better-progress-v3-0-6cc4edf543f4@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2715; i=himikof@gmail.com;
 h=from:subject:message-id; bh=wRKn0+FpY3mQVliUpbvtIlpx5Xz4Yan6xBO1SABanUM=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWTsVPz5RpfDb6v8hG5TrsJbH9sP+UpqLdFfVO9yM4hhw
 ezj2xQ3dJSyMIhxMciKKbJ8WPL1z5pM6z+WQnsNYeawMoEMYeDiFICJBLxiZHgiu/1Q8SkPTwWz
 0gdKlZo1Ca982GoL1Fr5uESieLO2+DP8U6qoUHR/fFXxiniK2vQHF66X5SS17OLt2NLskivvfkO
 PEQA=
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/progress.c | 17 +++++++++++++----
 fs/bcachefs/progress.h | 12 +++++++++++-
 2 files changed, 24 insertions(+), 5 deletions(-)

diff --git a/fs/bcachefs/progress.c b/fs/bcachefs/progress.c
index 8181f6d2ca3808f57bef179383bd969d9a375d5f..7cc16490ffa98fec34ff228cb56bd1af0f42da3d 100644
--- a/fs/bcachefs/progress.c
+++ b/fs/bcachefs/progress.c
@@ -4,9 +4,10 @@
 #include "disk_accounting.h"
 #include "progress.h"
 
-void bch2_progress_init(struct progress_indicator_state *s,
-			struct bch_fs *c,
-			u64 btree_id_mask)
+void bch2_progress_init_inner(struct progress_indicator_state *s,
+			      struct bch_fs *c,
+			      u64 leaf_btree_id_mask,
+			      u64 inner_btree_id_mask)
 {
 	memset(s, 0, sizeof(*s));
 
@@ -16,6 +17,8 @@ void bch2_progress_init(struct progress_indicator_state *s,
 	const u32 expected_node_disk_sectors =
 		READ_ONCE(c->opts.metadata_replicas) * btree_sectors(c);
 
+	const u64 btree_id_mask = leaf_btree_id_mask | inner_btree_id_mask;
+
 	for (unsigned i = 0; i < btree_id_nr_alive(c); i++) {
 		if (!(btree_id_mask & BIT_ULL(i)))
 			continue;
@@ -31,11 +34,17 @@ void bch2_progress_init(struct progress_indicator_state *s,
 		bch2_accounting_mem_read(c, disk_accounting_pos_to_bpos(&acc),
 			(u64 *)&v, sizeof(v) / sizeof(u64));
 
+		/* Better to estimate as 0 than the total node count */
+		if (inner_btree_id_mask & BIT_ULL(i))
+			s->nodes_total += v.inner_nodes;
+
+		if (!(leaf_btree_id_mask & BIT_ULL(i)))
+			continue;
+
 		/*
 		 * We check for zeros to degrade gracefully when run
 		 * with un-upgraded accounting info (missing some counters).
 		 */
-
 		if (v.total_nodes != 0)
 			s->nodes_total += v.total_nodes - v.inner_nodes;
 		else
diff --git a/fs/bcachefs/progress.h b/fs/bcachefs/progress.h
index 972a73087ffe06632abef015e4556d8ee196eb24..91f3453377093e2713aa4198b68e13601223688e 100644
--- a/fs/bcachefs/progress.h
+++ b/fs/bcachefs/progress.h
@@ -20,7 +20,17 @@ struct progress_indicator_state {
 	struct btree		*last_node;
 };
 
-void bch2_progress_init(struct progress_indicator_state *, struct bch_fs *, u64);
+void bch2_progress_init_inner(struct progress_indicator_state *s,
+			      struct bch_fs *c,
+			      u64 leaf_btree_id_mask,
+			      u64 inner_btree_id_mask);
+
+static inline void bch2_progress_init(struct progress_indicator_state *s,
+				      struct bch_fs *c, u64 btree_id_mask)
+{
+	bch2_progress_init_inner(s, c, btree_id_mask, 0);
+}
+
 void bch2_progress_update_iter(struct btree_trans *,
 			       struct progress_indicator_state *,
 			       struct btree_iter *,

-- 
2.50.1

