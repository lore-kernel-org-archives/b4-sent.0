From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 28 Aug 2025 17:16:11 +0300
Subject: [PATCH v2 09/15] bcachefs: Fix online hidden (sb+journal) data
 accounting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-better-progress-v2-9-c088a2003940@gmail.com>
References: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
In-Reply-To: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3023; i=himikof@gmail.com;
 h=from:subject:message-id; bh=rFTYXp6v1Q3agKmCyI5ewzfL4Uu2u6sOP5jVtX7VKug=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWRsSDnUmLVycfD/hesObDwnJTs1O2m7zf+erw6Fl/NVZ
 +4+Iv6tuKOUhUGMi0FWTJHlw5Kvf9ZkWv+xFNprCDOHlQlkCAMXpwBMxG0jI8Ot/fJitzy4mX2F
 jLZvmLTkbkjn74Cfbyv+NJzTmOevUfCTkWHz/nReFz2XXwGnjCv3PSlyWKnQ5seXJ28qZrsk5Ni
 rC+wA
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
index 82ce610a7e40c86d84296a47ef7ea7b5eb82f816..1649c0e1a89e8f4f04d122e40553b36f11491df5 100644
--- a/fs/bcachefs/disk_accounting.c
+++ b/fs/bcachefs/disk_accounting.c
@@ -1082,13 +1082,17 @@ void bch2_verify_accounting_clean(struct bch_fs *c)
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
@@ -1116,7 +1120,7 @@ void bch2_verify_accounting_clean(struct bch_fs *c)
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

