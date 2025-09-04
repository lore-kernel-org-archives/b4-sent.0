From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 04 Sep 2025 08:20:35 +0300
Subject: [PATCH v3 4/7] bcachefs:
 bcachefs_metadata_version_btree_node_accounting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250904-better-progress-v3-4-6cc4edf543f4@gmail.com>
References: <20250904-better-progress-v3-0-6cc4edf543f4@gmail.com>
In-Reply-To: <20250904-better-progress-v3-0-6cc4edf543f4@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5300; i=himikof@gmail.com;
 h=from:subject:message-id; bh=PxB+FYC1S8dbPQm2xSJgEIf63fK880kNJs2yuTB+uG0=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWTsVPxxcdqjaf4Ty068vzhfLltx5bR2X5UwF6melT9XF
 VlfaZx8tqOUhUGMi0FWTJHlw5Kvf9ZkWv+xFNprCDOHlQlkCAMXpwBMhD2Y4X9x6ZKnkQY9Fick
 76m/F9nOF53/IvivxcpNhyTzZmc8j6ti+Kdiw9bUduuC5eY4hvs6LVe3db+/PHtlDm+9PJfYlyt
 aL/kA
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce btree node number accounting for better progress reporting.
This change includes a mandatory upgrade/downgrade.

Add 2 new counters for BCH_DISK_ACCOUNTING_btree: total number of btree
nodes (ignoring replication) and the number of non-leaf btree nodes
(likewise). Those are to be used by recovery progress reporting instead
of estimating them.

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/bcachefs_format.h        |  3 ++-
 fs/bcachefs/buckets.c                | 16 +++++++++++-----
 fs/bcachefs/disk_accounting_format.h | 10 +++++++++-
 fs/bcachefs/sb-downgrade.c           | 11 +++++++++--
 4 files changed, 31 insertions(+), 9 deletions(-)

diff --git a/fs/bcachefs/bcachefs_format.h b/fs/bcachefs/bcachefs_format.h
index 0839397105a9d20bcdb99090b508dcff2e0f1886..76a2ae7f8d2dca44dfdd31c0d1078c45778d8447 100644
--- a/fs/bcachefs/bcachefs_format.h
+++ b/fs/bcachefs/bcachefs_format.h
@@ -706,7 +706,8 @@ struct bch_sb_field_ext {
 	x(fast_device_removal,		BCH_VERSION(1, 27))		\
 	x(inode_has_case_insensitive,	BCH_VERSION(1, 28))		\
 	x(extent_snapshot_whiteouts,	BCH_VERSION(1, 29))		\
-	x(31bit_dirent_offset,		BCH_VERSION(1, 30))
+	x(31bit_dirent_offset,		BCH_VERSION(1, 30))		\
+	x(btree_node_accounting,	BCH_VERSION(1, 31))
 
 enum bcachefs_metadata_version {
 	bcachefs_metadata_version_min = 9,
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
diff --git a/fs/bcachefs/sb-downgrade.c b/fs/bcachefs/sb-downgrade.c
index de56a1ee79db202da7ca021fb1f67f4b4820a2a8..bfd06fd5d506169031a2f7cadb5b1697ac40c811 100644
--- a/fs/bcachefs/sb-downgrade.c
+++ b/fs/bcachefs/sb-downgrade.c
@@ -104,7 +104,10 @@
 	x(inode_has_case_insensitive,				\
 	  BIT_ULL(BCH_RECOVERY_PASS_check_inodes),		\
 	  BCH_FSCK_ERR_inode_has_case_insensitive_not_set,	\
-	  BCH_FSCK_ERR_inode_parent_has_case_insensitive_not_set)
+	  BCH_FSCK_ERR_inode_parent_has_case_insensitive_not_set)\
+	x(btree_node_accounting,				\
+	  BIT_ULL(BCH_RECOVERY_PASS_check_allocations),		\
+	  BCH_FSCK_ERR_accounting_mismatch)
 
 #define DOWNGRADE_TABLE()					\
 	x(bucket_stripe_sectors,				\
@@ -152,7 +155,11 @@
 	  BIT_ULL(BCH_RECOVERY_PASS_check_allocations),		\
 	  BCH_FSCK_ERR_accounting_mismatch,			\
 	  BCH_FSCK_ERR_accounting_key_replicas_nr_devs_0,	\
-	  BCH_FSCK_ERR_accounting_key_junk_at_end)
+	  BCH_FSCK_ERR_accounting_key_junk_at_end)		\
+	x(btree_node_accounting,				\
+	  BIT_ULL(BCH_RECOVERY_PASS_check_allocations),		\
+	  BCH_FSCK_ERR_accounting_mismatch,			\
+	  BCH_FSCK_ERR_accounting_key_nr_counters_wrong)
 
 struct upgrade_downgrade_entry {
 	u64		recovery_passes;

-- 
2.50.1

