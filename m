From: Nikita Ofitserov <himikof@gmail.com>
Date: Wed, 27 Aug 2025 01:49:11 +0300
Subject: [PATCH 05/12] bcachefs: Better progress reporting for btree
 iteration without leaves
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250827-better-progress-v1-5-74c24de7988a@gmail.com>
References: <20250827-better-progress-v1-0-74c24de7988a@gmail.com>
In-Reply-To: <20250827-better-progress-v1-0-74c24de7988a@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2706; i=himikof@gmail.com;
 h=from:subject:message-id; bh=0ayVqa649VFler2gE0/RkQ/6h2fXF6zOAUkxMAASsjs=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWSss5LRVZ20csl3lVfXMiunNslf+bf8fFt5yNk9J/qlG
 ZM4HZqjOkpZGMS4GGTFFFk+LPn6Z02m9R9Lob2GMHNYmUCGMHBxCsBE+H0ZGbZ1Jeh1K/0uZvPQ
 V28W5lkveWOLd4ymam3Eeu+Z05Z+4mH4p3FzapnlTp5Hcw+pMkXmSucZFlmWtImc/2gsofNG8uo
 qfgA=
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
index 3ad4e1f6f653c8c75205efdd6d72560b8dda4c51..013eca7d6017a81390001519f20bfc4d0c6bc173 100644
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
 	for (unsigned i = 0; i < BTREE_ID_NR; i++) {
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

