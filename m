From: Mani Tofigh <mt4022@columbia.edu>
Date: Sun, 22 Nov 2026 19:25:12 -0500
Subject: [PATCH bpf v2 1/4] rhashtable: Add trylock_irqsoff for callers
 that can't spin
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-bpf-rhtab-irqs-disabled-v2-1-207aedcc2215@columbia.edu>
References: <20261122-bpf-rhtab-irqs-disabled-v2-0-207aedcc2215@columbia.edu>
In-Reply-To: <20261122-bpf-rhtab-irqs-disabled-v2-0-207aedcc2215@columbia.edu>
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Mykyta Yatsenko <yatsenko@meta.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 Andrew Morton <akpm@linux-foundation.org>, Shuah Khan <shuah@kernel.org>
Cc: Thomas Graf <tgraf@suug.ch>, Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, bpf@vger.kernel.org, 
 linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, tz2294@columbia.edu, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795393512; l=4887;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=kMDLAvvhIMzxoCfNVIqmmi7a21lA07GVnSlSeg5xc/s=;
 b=XbJdmDt4RfIquhuztc53mw8Gdr8sLchZyPLeJF4gP/DQRVXdajgcFSkoNWvTRwsP1Nl64trMb
 gnFLRFWbQD8BUVmLsR8A/YOB61DQIt0N0s6jBzf1k6AuwveZwgh2g11
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A caller with IRQs disabled can run inside a bucket lock's critical
section on its own CPU, e.g., in NMI or in a kprobe on the hash function
that the resize worker calls with the lock held.  If it then inserts or
removes a key of that bucket it spins on the bit lock forever.

Add rhashtable_params.trylock_irqsoff.  With it, inserts and removes
called with IRQs disabled only try the bucket lock and return -EBUSY if
it's held.  A caller with IRQs enabled can't run inside a locked section
of its own CPU, so it still spins, and so does the resize worker.  The
flag is a compile time constant in the fast paths like
insecure_elasticity, so other users don't pay for it.

On UP without DEBUG_SPINLOCK the lock bit isn't kept, so these callers
always get -EBUSY there.

Suggested-by: Alexei Starovoitov <ast@kernel.org>
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
 include/linux/rhashtable-types.h |  3 +++
 include/linux/rhashtable.h       | 34 ++++++++++++++++++++++++++++++++--
 lib/rhashtable.c                 |  3 ++-
 3 files changed, 37 insertions(+), 3 deletions(-)

diff --git a/include/linux/rhashtable-types.h b/include/linux/rhashtable-types.h
index 3576b8f08aff..a5c4e696c193 100644
--- a/include/linux/rhashtable-types.h
+++ b/include/linux/rhashtable-types.h
@@ -52,6 +52,8 @@ typedef int (*rht_obj_cmpfn_t)(struct rhashtable_compare_arg *arg,
  * @min_size: Minimum size while shrinking
  * @insecure_elasticity: Set to true to disable chain length checks
  * @automatic_shrinking: Enable automatic shrinking of tables
+ * @trylock_irqsoff: With irqs disabled insert and remove don't spin on
+ *		     the bucket lock and return -EBUSY
  * @hashfn: Hash function (default: jhash2 if !(key_len % 4), or jhash)
  * @obj_hashfn: Function to hash object
  * @obj_cmpfn: Function to compare key with object
@@ -65,6 +67,7 @@ struct rhashtable_params {
 	u16			min_size;
 	bool			insecure_elasticity;
 	bool			automatic_shrinking;
+	bool			trylock_irqsoff;
 	rht_hashfn_t		hashfn;
 	rht_obj_hashfn_t	obj_hashfn;
 	rht_obj_cmpfn_t		obj_cmpfn;
diff --git a/include/linux/rhashtable.h b/include/linux/rhashtable.h
index 70dac9214617..e5f5b9385cc3 100644
--- a/include/linux/rhashtable.h
+++ b/include/linux/rhashtable.h
@@ -339,6 +339,32 @@ static inline unsigned long rht_lock(struct bucket_table *tbl,
 	return rht_lock_nested(tbl, bkt, 0);
 }
 
+/*
+ * A caller with irqs disabled may be inside this cpu's locked section (NMI,
+ * kprobe, tracepoint), so it only tries the lock.
+ */
+static __always_inline bool rht_lock_or_busy(struct bucket_table *tbl,
+					     struct rhash_lock_head __rcu **bkt,
+					     const struct rhashtable_params params,
+					     unsigned long *flags)
+	__cond_acquires(true, __bitlock(0, bkt))
+{
+	if (!params.trylock_irqsoff || !irqs_disabled()) {
+		*flags = rht_lock(tbl, bkt);
+		return true;
+	}
+	/* bit_spin_trylock() always succeeds on UP without DEBUG_SPINLOCK */
+	if (!IS_ENABLED(CONFIG_SMP) && !IS_ENABLED(CONFIG_DEBUG_SPINLOCK))
+		return false;
+	local_irq_save(*flags);
+	if (!bit_spin_trylock(0, (unsigned long *)bkt)) {
+		local_irq_restore(*flags);
+		return false;
+	}
+	lock_acquire_exclusive(&tbl->dep_map, 0, 1, NULL, _THIS_IP_);
+	return true;
+}
+
 static inline void rht_unlock(struct bucket_table *tbl,
 			      struct rhash_lock_head __rcu **bkt,
 			      unsigned long flags)
@@ -785,7 +811,9 @@ static __always_inline void *__rhashtable_insert_fast(
 	if (!bkt)
 		goto out;
 	pprev = NULL;
-	flags = rht_lock(tbl, bkt);
+	data = ERR_PTR(-EBUSY);
+	if (!rht_lock_or_busy(tbl, bkt, params, &flags))
+		goto out;
 
 	if (unlikely(rcu_access_pointer(tbl->future_tbl))) {
 slow_path:
@@ -1066,7 +1094,8 @@ static __always_inline int __rhashtable_remove_fast_one(
 	if (!bkt)
 		return -ENOENT;
 	pprev = NULL;
-	flags = rht_lock(tbl, bkt);
+	if (!rht_lock_or_busy(tbl, bkt, params, &flags))
+		return -EBUSY;
 
 	rht_for_each_from(he, rht_ptr(bkt, tbl, hash), tbl, hash) {
 		struct rhlist_head *list;
@@ -1149,6 +1178,7 @@ static __always_inline int __rhashtable_remove_fast(
 	 */
 	while ((err = __rhashtable_remove_fast_one(ht, tbl, obj, params,
 						   rhlist)) &&
+	       err != -EBUSY &&
 	       (tbl = rht_dereference_rcu(tbl->future_tbl, ht)))
 		;
 
diff --git a/lib/rhashtable.c b/lib/rhashtable.c
index 500c45cd1304..2dc13f0e2549 100644
--- a/lib/rhashtable.c
+++ b/lib/rhashtable.c
@@ -650,7 +650,8 @@ static void *rhashtable_try_insert(struct rhashtable *ht, const void *key,
 		} else {
 			bool inserted;
 
-			flags = rht_lock(tbl, bkt);
+			if (!rht_lock_or_busy(tbl, bkt, ht->p, &flags))
+				return ERR_PTR(-EBUSY);
 			data = rhashtable_lookup_one(ht, bkt, tbl,
 						     hash, key, obj);
 			new_tbl = rhashtable_insert_one(ht, bkt, tbl,

-- 
2.53.0

