From: Nikita Ofitserov <himikof@gmail.com>
Date: Wed, 27 Aug 2025 01:49:08 +0300
Subject: [PATCH 02/12] bcachefs: Introduce btree node number accounting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250827-better-progress-v1-2-74c24de7988a@gmail.com>
References: <20250827-better-progress-v1-0-74c24de7988a@gmail.com>
In-Reply-To: <20250827-better-progress-v1-0-74c24de7988a@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3296; i=himikof@gmail.com;
 h=from:subject:message-id; bh=zwjI5tCeCHw8e+Z7T2bZ8UaDq7Mjfrnlgre8FzWRL8g=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWSss5KR/R35wG5y3YQbe55n+uy+fyX35Q9Z8U6daIYVs
 gt56yrCOkpZGMS4GGTFFFk+LPn6Z02m9R9Lob2GMHNYmUCGMHBxCsBELF8wMqxPfCoudjH9d31O
 3fEJirMaGr4Y3FomzrrwgJu7edgDiTyGv1J87y46Crdt9JAr2f1QaNc35rUSckcmXpWZ++LAUmv
 DnSwA
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add 2 new counters for BCH_DISK_ACCOUNTING_btree: total number of btree
nodes (ignoring replication) and the number of non-leaf btree nodes
(likewise). Those are to be used by recovery progress reporting instead
 of estimating them.

This commit is missing the required upgrade/downgrade entries and
should be included only together with other accounting updates!

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/buckets.c                | 16 +++++++++++-----
 fs/bcachefs/disk_accounting_format.h | 10 +++++++++-
 2 files changed, 20 insertions(+), 6 deletions(-)

diff --git a/fs/bcachefs/buckets.c b/fs/bcachefs/buckets.c
index 021f5cb7998de704be9d135064af2817cb2c52fe..99e928f7799971d052f24ba6043eb54765cf42b9 100644
--- a/fs/bcachefs/buckets.c
+++ b/fs/bcachefs/buckets.c
@@ -749,6 +749,7 @@ static int __trigger_extent(struct btree_trans *trans,
 			    enum btree_iter_update_trigger_flags flags)
 {
 	bool gc = flags & BTREE_TRIGGER_gc;
+	bool insert = !(flags & BTREE_TRIGGER_overwrite);
 	struct bkey_ptrs_c ptrs = bch2_bkey_ptrs_c(k);
 	const union bch_extent_entry *entry;
 	struct extent_ptr_decoded p;
@@ -802,7 +803,7 @@ static int __trigger_extent(struct btree_trans *trans,
 
 		if (cur_compression_type &&
 		    cur_compression_type != p.crc.compression_type) {
-			if (flags & BTREE_TRIGGER_overwrite)
+			if (!insert)
 				bch2_u64s_neg(compression_acct, ARRAY_SIZE(compression_acct));
 
 			ret = bch2_disk_accounting_mod2(trans, gc, compression_acct,
@@ -835,7 +836,7 @@ static int __trigger_extent(struct btree_trans *trans,
 	}
 
 	if (cur_compression_type) {
-		if (flags & BTREE_TRIGGER_overwrite)
+		if (!insert)
 			bch2_u64s_neg(compression_acct, ARRAY_SIZE(compression_acct));
 
 		ret = bch2_disk_accounting_mod2(trans, gc, compression_acct,
@@ -845,12 +846,17 @@ static int __trigger_extent(struct btree_trans *trans,
 	}
 
 	if (level) {
-		ret = bch2_disk_accounting_mod2_nr(trans, gc, &replicas_sectors, 1, btree, btree_id);
+		const bool leaf_node = level == 1;
+		s64 v[3] = {
+			replicas_sectors,
+			insert ? 1 : -1,
+			!leaf_node ? (insert ? 1 : -1) : 0,
+		};
+
+		ret = bch2_disk_accounting_mod2(trans, gc, v, btree, btree_id);
 		if (ret)
 			return ret;
 	} else {
-		bool insert = !(flags & BTREE_TRIGGER_overwrite);
-
 		s64 v[3] = {
 			insert ? 1 : -1,
 			insert ? k.k->size : -((s64) k.k->size),
diff --git a/fs/bcachefs/disk_accounting_format.h b/fs/bcachefs/disk_accounting_format.h
index 8269af1dbe2a094454f780194f4ece33c4a4e461..730a17ea42431012282cec9d7803b0ac0b1d339d 100644
--- a/fs/bcachefs/disk_accounting_format.h
+++ b/fs/bcachefs/disk_accounting_format.h
@@ -108,7 +108,7 @@ static inline bool data_type_is_hidden(enum bch_data_type type)
 	x(dev_data_type,	3,	3)	\
 	x(compression,		4,	3)	\
 	x(snapshot,		5,	1)	\
-	x(btree,		6,	1)	\
+	x(btree,		6,	3)	\
 	x(rebalance_work,	7,	1)	\
 	x(inum,			8,	3)
 
@@ -174,6 +174,14 @@ struct bch_acct_snapshot {
 	__u32			id;
 } __packed;
 
+/*
+ * Metadata accounting per btree id:
+ * [
+ *   total btree disk usage in sectors
+ *   total number of btree nodes
+ *   number of non-leaf btree nodes
+ * ]
+ */
 struct bch_acct_btree {
 	__u32			id;
 } __packed;

-- 
2.50.1

