From: Mani Tofigh <mt4022@columbia.edu>
Date: Sun, 22 Nov 2026 19:25:13 -0500
Subject: [PATCH bpf v2 2/4] rhashtable: Don't retry trylock_irqsoff lookups
 with IRQs disabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-bpf-rhtab-irqs-disabled-v2-2-207aedcc2215@columbia.edu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795393512; l=2660;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=kYjGbBhSshdQz8OUIPJYVvaaWEVOrBeao9CRlWi5/+Y=;
 b=K7vDg+c6ADcr1YLDf5uftT+mGwZRE6ClJ6kJzmqtbZGr8phM5RTNzqKJMhozRN9Bz+E+yMhZv
 WTl/Ficbw5CBH2yoVhIPFFfMBaZE6dtoxASM7EzA+uTaHwHAsrTddvN
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The rehash links the last entry of a chain into the future table and
then unlinks it from the old chain.  A lookup that walks the old chain in
between ends in the new chain and retries.  A caller with IRQs disabled
can run inside that window on its own CPU, e.g., in NMI or in a kprobe,
and then the rehash never moves on and the retry never ends.

Don't retry for trylock_irqsoff callers with IRQs disabled.  The lookup
moves on to the future table, which has the moved entry and all entries
moved before it.  The rehash now stores entry->next with
rcu_assign_pointer(), so a lookup that walks into the new chain also
sees those earlier moves.

Suggested-by: Mykyta Yatsenko <yatsenko@meta.com>
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
 include/linux/rhashtable.h | 11 ++++++++++-
 lib/rhashtable.c           |  6 +++++-
 2 files changed, 15 insertions(+), 2 deletions(-)

diff --git a/include/linux/rhashtable.h b/include/linux/rhashtable.h
index e5f5b9385cc3..746d62978215 100644
--- a/include/linux/rhashtable.h
+++ b/include/linux/rhashtable.h
@@ -638,6 +638,15 @@ static __always_inline int rhashtable_compare(struct rhashtable_compare_arg *arg
 		      params.key_len ? : ht->p.key_len);
 }
 
+/*
+ * A caller with irqs disabled may have interrupted the rehash on this cpu, so
+ * its retry would never end. It finds the moved entries in the future table.
+ */
+static __always_inline bool rht_lookup_retry(const struct rhashtable_params params)
+{
+	return !params.trylock_irqsoff || !irqs_disabled();
+}
+
 /* Internal function, do not use. */
 static __always_inline struct rhash_head *__rhashtable_lookup(
 	struct rhashtable *ht, const void *key,
@@ -670,7 +679,7 @@ static __always_inline struct rhash_head *__rhashtable_lookup(
 		/* An object might have been moved to a different hash chain,
 		 * while we walk along it - better check and retry.
 		 */
-	} while (he != RHT_NULLS_MARKER(bkt));
+	} while (he != RHT_NULLS_MARKER(bkt) && rht_lookup_retry(params));
 
 	/* Ensure we see any new tables. */
 	smp_rmb();
diff --git a/lib/rhashtable.c b/lib/rhashtable.c
index 2dc13f0e2549..619609037051 100644
--- a/lib/rhashtable.c
+++ b/lib/rhashtable.c
@@ -274,7 +274,11 @@ static int rhashtable_rehash_one(struct rhashtable *ht,
 
 	head = rht_ptr(new_tbl->buckets + new_hash, new_tbl, new_hash);
 
-	RCU_INIT_POINTER(entry->next, head);
+	/*
+	 * Pairs with smp_rmb() in __rhashtable_lookup() for lookups that
+	 * don't retry.
+	 */
+	rcu_assign_pointer(entry->next, head);
 
 	rht_assign_unlock(new_tbl, &new_tbl->buckets[new_hash], entry, flags);
 

-- 
2.53.0

