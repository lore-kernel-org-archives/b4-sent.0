From: quanyeyang <quanyemostima@gmail.com>
Date: Sat, 01 Aug 2026 18:13:27 +0800
Subject: [PATCH] rhashtable: use per-init-site lockdep classes for bucket
 locks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260801-fix-rhashtable-bucket-lockdep-v1-1-15a0f8ae094c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBBG4auUWTuQBirqVcRFJv01Y0tbMqkIp
 Xc36vJbvLeRISuMLs1GGS81naeK9tBQTGF6gLWvJu/80Z1cy3d9c07BUgkygmWNAwqPcxx6LHz
 u4LsgECBQfSwZNfj9r7e/bZUnYvlOad8/HEMS6oEAAAA=
X-Change-ID: 20260801-fix-rhashtable-bucket-lockdep-95e25abebeea
To: Thomas Graf <tgraf@suug.ch>, Herbert Xu <herbert@gondor.apana.org.au>, 
 Andrew Morton <akpm@linux-foundation.org>, NeilBrown <neilb@suse.com>, 
 "David S. Miller" <davem@davemloft.net>
Cc: linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 syzbot+ef8d17bae14efb960935@syzkaller.appspotmail.com, 
 quanyeyang <quanyemostima@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785579217; l=5881;
 i=quanyemostima@gmail.com; s=20260801; h=from:subject:message-id;
 bh=0N4OOkfbxgTWIlbrzMgCyEmTGY5MHduBeX6XyueQ9Ow=;
 b=5FW6wSL57G2tayTV0jw3QcforpkXT48l0JX2ga8p+vaewOc3qrA+2IBZW11fClCH8IY/JcQE/
 suzz/d2hzz6CiYFrOm/a/tF8xHAUNW/m3LDm8Ku3pPK/TIGHWfY69Zd
X-Developer-Key: i=quanyemostima@gmail.com; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyemostima@gmail.com/20260801 with auth_id=905
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All bucket tables currently share a single lockdep class. This makes
lockdep conflate bucket locks from unrelated rhashtable instances.

A BPF program attached to lock_release can expose this when pidfs
inserts a pid. The tracepoint runs before lockdep removes the pidfs
bucket lock from the task's held-lock stack. Deleting an element from
a BPF RHASH map then acquires a bucket lock belonging to a different
rhashtable. Since both tables use the same class, lockdep reports
possible recursive locking.

Declare a separate bucket lock class key at each rhashtable_init() and
rhltable_init() call site, alongside the mutex class key. Store the
bucket key in struct rhashtable so tables created during resize keep
using the same class.

A targeted reproducer triggers the warning reliably before this change.
After the change, the nested BPF RHASH deletion still executes, but
lockdep no longer reports recursive locking.

Fixes: 149212f07856 ("rhashtable: add lockdep tracking to bucket bit-spin-locks.")
Reported-by: syzbot+ef8d17bae14efb960935@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=ef8d17bae14efb960935
Assisted-by: Cursor:GPT-5.6 Sol
Signed-off-by: quanyeyang <quanyemostima@gmail.com>
---
 include/linux/rhashtable-types.h | 20 ++++++++++++++------
 lib/rhashtable.c                 | 19 +++++++++++++------
 2 files changed, 27 insertions(+), 12 deletions(-)

diff --git a/include/linux/rhashtable-types.h b/include/linux/rhashtable-types.h
index 57c11ec9dc64..4dea91a49ec8 100644
--- a/include/linux/rhashtable-types.h
+++ b/include/linux/rhashtable-types.h
@@ -82,6 +82,7 @@ struct rhashtable_params {
  * @mutex: Mutex to protect current/future table swapping
  * @lock: Spin lock to protect walker list
  * @nelems: Number of elements in table
+ * @bucket_lock_key: Per-init-site lockdep class for bucket bit-locks
  */
 struct rhashtable {
 	struct bucket_table __rcu	*tbl;
@@ -94,6 +95,7 @@ struct rhashtable {
 	struct mutex                    mutex;
 	spinlock_t			lock;
 	atomic_t			nelems;
+	struct lock_class_key		*bucket_lock_key;
 #ifdef CONFIG_MEM_ALLOC_PROFILING
 	struct alloc_tag		*alloc_tag;
 #endif
@@ -138,23 +140,29 @@ struct rhashtable_iter {
 
 int __rhashtable_init_noprof(struct rhashtable *ht,
 		    const struct rhashtable_params *params,
-		    struct lock_class_key *key);
+		    struct lock_class_key *mutex_key,
+		    struct lock_class_key *bucket_key);
 #define rhashtable_init_noprof(ht, params)				\
 ({									\
-	static struct lock_class_key __key;				\
+	static struct lock_class_key __mutex_key;			\
+	static struct lock_class_key __bucket_key;			\
 									\
-	__rhashtable_init_noprof(ht, params, &__key);			\
+	__rhashtable_init_noprof(ht, params, &__mutex_key,		\
+				 &__bucket_key);			\
 })
 #define rhashtable_init(...)	alloc_hooks(rhashtable_init_noprof(__VA_ARGS__))
 
 int __rhltable_init_noprof(struct rhltable *hlt,
 		  const struct rhashtable_params *params,
-		  struct lock_class_key *key);
+		  struct lock_class_key *mutex_key,
+		  struct lock_class_key *bucket_key);
 #define rhltable_init_noprof(hlt, params)				\
 ({									\
-	static struct lock_class_key __key;				\
+	static struct lock_class_key __mutex_key;			\
+	static struct lock_class_key __bucket_key;			\
 									\
-	__rhltable_init_noprof(hlt, params, &__key);			\
+	__rhltable_init_noprof(hlt, params, &__mutex_key,		\
+			       &__bucket_key);				\
 })
 #define rhltable_init(...)	alloc_hooks(rhltable_init_noprof(__VA_ARGS__))
 
diff --git a/lib/rhashtable.c b/lib/rhashtable.c
index d459bef245f4..e047ad912f0e 100644
--- a/lib/rhashtable.c
+++ b/lib/rhashtable.c
@@ -189,7 +189,6 @@ static struct bucket_table *bucket_table_alloc(struct rhashtable *ht,
 	struct bucket_table *tbl = NULL;
 	size_t size;
 	int i;
-	static struct lock_class_key __key;
 
 	tbl = alloc_hooks_tag(ht->alloc_tag,
 			kvmalloc_node_align_noprof(struct_size(tbl, buckets, nbuckets),
@@ -205,7 +204,12 @@ static struct bucket_table *bucket_table_alloc(struct rhashtable *ht,
 	if (tbl == NULL)
 		return NULL;
 
-	lockdep_init_map(&tbl->dep_map, "rhashtable_bucket", &__key, 0);
+	/*
+	 * Keep all bucket tables belonging to the same rhashtable in the
+	 * per-init-site lock class, including tables created during resize.
+	 */
+	lockdep_init_map(&tbl->dep_map, "rhashtable_bucket",
+			 ht->bucket_lock_key, 0);
 
 	tbl->size = size;
 
@@ -1162,7 +1166,8 @@ static u32 rhashtable_jhash2(const void *key, u32 length, u32 seed)
  */
 int __rhashtable_init_noprof(struct rhashtable *ht,
 		    const struct rhashtable_params *params,
-		    struct lock_class_key *key)
+		    struct lock_class_key *mutex_key,
+		    struct lock_class_key *bucket_key)
 {
 	struct bucket_table *tbl;
 	size_t size;
@@ -1172,7 +1177,8 @@ int __rhashtable_init_noprof(struct rhashtable *ht,
 		return -EINVAL;
 
 	memset(ht, 0, sizeof(*ht));
-	mutex_init_with_key(&ht->mutex, key);
+	mutex_init_with_key(&ht->mutex, mutex_key);
+	ht->bucket_lock_key = bucket_key;
 	spin_lock_init(&ht->lock);
 	memcpy(&ht->p, params, sizeof(*params));
 
@@ -1237,11 +1243,12 @@ EXPORT_SYMBOL_GPL(__rhashtable_init_noprof);
  */
 int __rhltable_init_noprof(struct rhltable *hlt,
 			   const struct rhashtable_params *params,
-			   struct lock_class_key *key)
+			   struct lock_class_key *mutex_key,
+			   struct lock_class_key *bucket_key)
 {
 	int err;
 
-	err = __rhashtable_init_noprof(&hlt->ht, params, key);
+	err = __rhashtable_init_noprof(&hlt->ht, params, mutex_key, bucket_key);
 	hlt->ht.rhlist = true;
 	return err;
 }

---
base-commit: 0131b508c0e2489eac6e121135988f6eeb716f19
change-id: 20260801-fix-rhashtable-bucket-lockdep-95e25abebeea

Best regards,
--  
quanyeyang <quanyemostima@gmail.com>

