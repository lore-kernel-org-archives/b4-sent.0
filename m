From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 04 Sep 2025 08:20:33 +0300
Subject: [PATCH v3 2/7] bcachefs: Fix online hidden (sb+journal) data
 accounting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250904-better-progress-v3-2-6cc4edf543f4@gmail.com>
References: <20250904-better-progress-v3-0-6cc4edf543f4@gmail.com>
In-Reply-To: <20250904-better-progress-v3-0-6cc4edf543f4@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3023; i=himikof@gmail.com;
 h=from:subject:message-id; bh=wd9BYmDrNSwQaAk+E9Fbl96RQ0Zy/3q0CxOTVWJm0wg=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWTsVPyxP+jxn+3xbKoZNnuML+2Xdo8T710pYHn/wmHzo
 yECMseMOkpZGMS4GGTFFFk+LPn6Z02m9R9Lob2GMHNYmUCGMHBxCsBE7m5n+Kft59Lx+u7Jnp8O
 BbesDJh87Y7+PLeaw+fMc/MaruI2+XeMDFfsvzY4ZrBHvdFIrO22lnn86WeZDIe+iPKVx1zfFN+
 v4gYA
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now the c->usage->hidden counters are kept up to date by the same
trigger-based mechanism as the other ones.

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/disk_accounting.c | 12 ++++++++----
 fs/bcachefs/disk_accounting.h | 10 +++++++---
 2 files changed, 15 insertions(+), 7 deletions(-)

diff --git a/fs/bcachefs/disk_accounting.c b/fs/bcachefs/disk_accounting.c
index 17408c03604547fcdff8f1cc4c8c40cf818eabfd..f09e43f78f13fc424d9bf22d94566d4961c8ca8e 100644
--- a/fs/bcachefs/disk_accounting.c
+++ b/fs/bcachefs/disk_accounting.c
@@ -1097,13 +1097,17 @@ void bch2_verify_accounting_clean(struct bch_fs *c)
 		case BCH_DISK_ACCOUNTING_dev_data_type: {
 			{
 				guard(rcu)(); /* scoped guard is a loop, and doesn't play nicely with continue */
+				const enum bch_data_type data_type = acc_k.dev_data_type.data_type;
 				struct bch_dev *ca = bch2_dev_rcu_noerror(c, acc_k.dev_data_type.dev);
 				if (!ca)
 					continue;
 
-				v[0] = percpu_u64_get(&ca->usage->d[acc_k.dev_data_type.data_type].buckets);
-				v[1] = percpu_u64_get(&ca->usage->d[acc_k.dev_data_type.data_type].sectors);
-				v[2] = percpu_u64_get(&ca->usage->d[acc_k.dev_data_type.data_type].fragmented);
+				v[0] = percpu_u64_get(&ca->usage->d[data_type].buckets);
+				v[1] = percpu_u64_get(&ca->usage->d[data_type].sectors);
+				v[2] = percpu_u64_get(&ca->usage->d[data_type].fragmented);
+
+				if (data_type == BCH_DATA_sb || data_type == BCH_DATA_journal)
+					base.hidden += a.v->d[0] * ca->mi.bucket_size;
 			}
 
 			if (memcmp(a.v->d, v, 3 * sizeof(u64))) {
@@ -1131,7 +1135,7 @@ void bch2_verify_accounting_clean(struct bch_fs *c)
 		mismatch = true;								\
 	}
 
-	//check(hidden);
+	check(hidden);
 	check(btree);
 	check(data);
 	check(cached);
diff --git a/fs/bcachefs/disk_accounting.h b/fs/bcachefs/disk_accounting.h
index 438628b63a8065e22ec76aebcd69e285f84f41ef..c3f2dc5d0c14241f3c0ae2d367d6da504df2e1ab 100644
--- a/fs/bcachefs/disk_accounting.h
+++ b/fs/bcachefs/disk_accounting.h
@@ -186,11 +186,15 @@ static inline int bch2_accounting_mem_mod_locked(struct btree_trans *trans,
 			break;
 		case BCH_DISK_ACCOUNTING_dev_data_type: {
 			guard(rcu)();
+			const enum bch_data_type data_type = acc_k.dev_data_type.data_type;
 			struct bch_dev *ca = bch2_dev_rcu_noerror(c, acc_k.dev_data_type.dev);
 			if (ca) {
-				this_cpu_add(ca->usage->d[acc_k.dev_data_type.data_type].buckets, a.v->d[0]);
-				this_cpu_add(ca->usage->d[acc_k.dev_data_type.data_type].sectors, a.v->d[1]);
-				this_cpu_add(ca->usage->d[acc_k.dev_data_type.data_type].fragmented, a.v->d[2]);
+				this_cpu_add(ca->usage->d[data_type].buckets, a.v->d[0]);
+				this_cpu_add(ca->usage->d[data_type].sectors, a.v->d[1]);
+				this_cpu_add(ca->usage->d[data_type].fragmented, a.v->d[2]);
+
+				if (data_type == BCH_DATA_sb || data_type == BCH_DATA_journal)
+					trans->fs_usage_delta.hidden += a.v->d[0] * ca->mi.bucket_size;
 			}
 			break;
 		}

-- 
2.50.1

