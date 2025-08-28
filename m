From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 28 Aug 2025 17:16:10 +0300
Subject: [PATCH v2 08/15] bcachefs: Optimize/fix bch2_dev_usage_remove
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-better-progress-v2-8-c088a2003940@gmail.com>
References: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
In-Reply-To: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3834; i=himikof@gmail.com;
 h=from:subject:message-id; bh=VfHQqLCXNpXsQd4pptDlTCf05tDcBv3FbIoR4G8Q3e8=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWRsSDk0++Jq88/5XIpWE97VOAU/3G25egvPszfVu9WE9
 taWzxSt6ChlYRDjYpAVU2T5sOTrnzWZ1n8shfYawsxhZQIZwsDFKQATOd7JyLBw+muhCz73ZPbu
 WWt883GJwMxFmrH5C64KzUv61x9Y+ukWwz/jrf2zWmwWVTtfvKsp1mmn6PGXY7vImQfPdu+88H/
 /aj4OAA==
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make bch2_dev_usage_remove iterate only through relevant keys instead
of the whole accounting tree. Use the proper bch2_disk_accounting_mod
API to ensure in-memory counters will be zeroed and cleaned up later.

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/alloc_background.c |  2 +-
 fs/bcachefs/disk_accounting.c  | 47 +++++++++++++++++++++++++++++++-----------
 fs/bcachefs/disk_accounting.h  |  2 +-
 3 files changed, 37 insertions(+), 14 deletions(-)

diff --git a/fs/bcachefs/alloc_background.c b/fs/bcachefs/alloc_background.c
index 3fc728efbf5cc0425b966a0d83d97b33a666c531..0a2b630ab8420b404990eb5a4359c9295b926050 100644
--- a/fs/bcachefs/alloc_background.c
+++ b/fs/bcachefs/alloc_background.c
@@ -2397,7 +2397,7 @@ int bch2_dev_remove_alloc(struct bch_fs *c, struct bch_dev *ca)
 					BTREE_TRIGGER_norun, NULL) ?:
 		bch2_btree_delete_range(c, BTREE_ID_alloc, start, end,
 					BTREE_TRIGGER_norun, NULL) ?:
-		bch2_dev_usage_remove(c, ca->dev_idx);
+		bch2_dev_usage_remove(c, ca);
 	bch_err_msg(ca, ret, "removing dev alloc info");
 	return ret;
 }
diff --git a/fs/bcachefs/disk_accounting.c b/fs/bcachefs/disk_accounting.c
index d6c91abcdc4140ef98b407fa580b7cd0cf3b8f56..82ce610a7e40c86d84296a47ef7ea7b5eb82f816 100644
--- a/fs/bcachefs/disk_accounting.c
+++ b/fs/bcachefs/disk_accounting.c
@@ -974,21 +974,44 @@ int bch2_accounting_read(struct bch_fs *c)
 	return ret;
 }
 
-int bch2_dev_usage_remove(struct bch_fs *c, unsigned dev)
+int bch2_dev_usage_remove(struct bch_fs *c, struct bch_dev *ca)
 {
 	CLASS(btree_trans, trans)(c);
+
+	struct disk_accounting_pos start;
+	disk_accounting_key_init(start, dev_data_type, .dev = ca->dev_idx);
+
+	struct disk_accounting_pos end;
+	disk_accounting_key_init(end, dev_data_type, .dev = ca->dev_idx, .data_type = U8_MAX);
+
 	return bch2_btree_write_buffer_flush_sync(trans) ?:
-		for_each_btree_key_commit(trans, iter, BTREE_ID_accounting, POS_MIN,
-				BTREE_ITER_all_snapshots, k, NULL, NULL, 0, ({
-			struct disk_accounting_pos acc;
-			bpos_to_disk_accounting_pos(&acc, k.k->p);
-
-			acc.type == BCH_DISK_ACCOUNTING_dev_data_type &&
-			acc.dev_data_type.dev == dev
-				? bch2_btree_bit_mod_buffered(trans, BTREE_ID_accounting, k.k->p, 0)
-				: 0;
-		})) ?:
-		bch2_btree_write_buffer_flush_sync(trans);
+		commit_do(trans, NULL, NULL, 0, ({
+			struct bkey_s_c k;
+			int ret = 0;
+
+			for_each_btree_key_max_norestart(trans, iter, BTREE_ID_accounting,
+							 disk_accounting_pos_to_bpos(&start),
+							 disk_accounting_pos_to_bpos(&end),
+							 BTREE_ITER_all_snapshots, k, ret) {
+				if (k.k->type != KEY_TYPE_accounting)
+					continue;
+
+				struct disk_accounting_pos acc;
+				bpos_to_disk_accounting_pos(&acc, k.k->p);
+
+				const unsigned nr = bch2_accounting_counters(k.k);
+				u64 v[BCH_ACCOUNTING_MAX_COUNTERS];
+				memcpy_u64s_small(v, bkey_s_c_to_accounting(k).v->d, nr);
+
+				bch2_u64s_neg(v, nr);
+
+				ret = bch2_disk_accounting_mod(trans, &acc, v, nr, false);
+				if (ret)
+					break;
+			}
+
+			ret;
+	})) ?: bch2_btree_write_buffer_flush_sync(trans);
 }
 
 int bch2_dev_usage_init(struct bch_dev *ca, bool gc)
diff --git a/fs/bcachefs/disk_accounting.h b/fs/bcachefs/disk_accounting.h
index cc73cce98a447d96ad40683b88bfbc12689d8bf2..438628b63a8065e22ec76aebcd69e285f84f41ef 100644
--- a/fs/bcachefs/disk_accounting.h
+++ b/fs/bcachefs/disk_accounting.h
@@ -297,7 +297,7 @@ int bch2_gc_accounting_done(struct bch_fs *);
 
 int bch2_accounting_read(struct bch_fs *);
 
-int bch2_dev_usage_remove(struct bch_fs *, unsigned);
+int bch2_dev_usage_remove(struct bch_fs *, struct bch_dev *);
 int bch2_dev_usage_init(struct bch_dev *, bool);
 
 void bch2_verify_accounting_clean(struct bch_fs *c);

-- 
2.50.1

