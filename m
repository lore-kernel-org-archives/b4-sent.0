From: Mani Tofigh <mt4022@columbia.edu>
Date: Sun, 22 Nov 2026 19:25:14 -0500
Subject: [PATCH bpf v2 3/4] bpf: Don't spin on rhtab bucket locks with IRQs
 disabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-bpf-rhtab-irqs-disabled-v2-3-207aedcc2215@columbia.edu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795393512; l=4196;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=H73UDxYxp4OhP3+zFdd1A4c8OBOGQZtNrFaT0BtiC3E=;
 b=RXk+Of9llLWxtSZjxODvOgb4cxu8nS1YoBFvaKijLsrrO9fNhSoo+nZHBWKIwA1eeKChG0Z9Z
 hKrDCwzMJd3AHHJVbB3NhuLqijg7wZSNZbt7+ZgmTHu2v/C0Jt10bV4
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A BPF program can spin forever on a resizable hash map's bucket lock
that its own CPU already holds.  Inserts and deletes take the rhashtable
bucket lock, a bit spinlock that can't detect re-entry.
bpf_disable_instrumentation() keeps kprobe and perf_event programs out
of rhtab's own inserts and deletes, but the resize worker calls the hash
function with that lock held, so a kprobe program on the hash function
that deletes a key of the same bucket never gets the lock:

  rht_deferred_worker()
    rht_lock(old_tbl, bkt)
    rhashtable_jhash2()
      kprobe program
        bpf_map_delete_elem()
          rht_lock(old_tbl, bkt)
            /* spins with IRQs disabled */

  rcu: INFO: rcu_preempt detected stalls on CPUs/tasks:
  ...
  NMI backtrace for cpu 0
  Workqueue: events rht_deferred_worker
  RIP: 0010:rhtab_delete_elem+0x15f9/0x1c80
  ...
  Call Trace:
   <TASK>
   rhtab_map_delete_elem+0x61/0x120
   bpf_prog_12e9295082de5b34+0xa0/0xee
   trace_call_bpf+0x2ca/0x930
   kprobe_perf_func+0x106/0x700
   aggr_pre_handler+0x8f/0x110
   kprobe_int3_handler+0x335/0x750
   do_int3+0xd/0x50
   exc_int3+0x165/0x340
   asm_exc_int3+0x39/0x40
  RIP: 0010:rhashtable_jhash2+0x5/0x360
  ...

Set trylock_irqsoff in both rhtab params.  Only a program with IRQs
disabled can run inside a locked section of its own CPU, so its inserts
and deletes now fail with -EBUSY when the bucket is locked, by this CPU
or another one, and work as before otherwise.  This also covers programs
in NMI, so bpf_disable_instrumentation() isn't needed anymore.  With the
fix, the delete fails with -EBUSY and the resize finishes.

Fixes: 16b4d3e2fb24 ("bpf: Implement resizable hashmap basic functions")
Suggested-by: Alexei Starovoitov <ast@kernel.org>
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
 kernel/bpf/hashtab.c | 17 ++---------------
 1 file changed, 2 insertions(+), 15 deletions(-)

diff --git a/kernel/bpf/hashtab.c b/kernel/bpf/hashtab.c
index 6e2115477cb9..edc7572a641e 100644
--- a/kernel/bpf/hashtab.c
+++ b/kernel/bpf/hashtab.c
@@ -2983,6 +2983,7 @@ struct bpf_rhtab {
 static const struct rhashtable_params rhtab_params = {
 	.head_offset = offsetof(struct rhtab_elem, node),
 	.key_offset  = offsetof(struct rhtab_elem, data),
+	.trylock_irqsoff = true,
 };
 
 static inline void *rhtab_elem_value(struct rhtab_elem *l, u32 key_size)
@@ -3011,6 +3012,7 @@ static const struct rhashtable_params rhtab_params_long = {
 	.head_offset = offsetof(struct rhtab_elem, node),
 	.key_offset  = offsetof(struct rhtab_elem, data),
 	.key_len     = sizeof(long),
+	.trylock_irqsoff = true,
 	.hashfn      = rhtab_hashfn_long,
 	.obj_cmpfn   = rhtab_key_cmp_long,
 };
@@ -3143,21 +3145,11 @@ static int rhtab_delete_elem(struct bpf_rhtab *rhtab, struct rhtab_elem *elem, v
 {
 	int err;
 
-	/*
-	 * disable_instrumentation() mitigates the deadlock for programs running in NMI context.
-	 * rhashtable locks bucket with local_irq_save(). Only NMI programs may reenter
-	 * rhashtable code, bpf_disable_instrumentation() disables programs running in NMI, except
-	 * raw tracepoints, which we don't have in rhashtable.
-	 */
-	bpf_disable_instrumentation();
-
 	if (rhtab->map.key_size == sizeof(long))
 		err = rhashtable_remove_fast(&rhtab->ht, &elem->node, rhtab_params_long);
 	else
 		err = rhashtable_remove_fast(&rhtab->ht, &elem->node, rhtab_params);
 
-	bpf_enable_instrumentation();
-
 	if (err)
 		return err;
 
@@ -3268,16 +3260,11 @@ static long rhtab_map_update_elem(struct bpf_map *map, void *key, void *value, u
 	memcpy(elem->data, key, map->key_size);
 	copy_map_value(map, rhtab_elem_value(elem, map->key_size), value);
 
-	/* Prevent deadlock for NMI programs attempting to take bucket lock */
-	bpf_disable_instrumentation();
-
 	if (map->key_size == sizeof(long))
 		tmp = rhashtable_lookup_get_insert_fast(&rhtab->ht, &elem->node, rhtab_params_long);
 	else
 		tmp = rhashtable_lookup_get_insert_fast(&rhtab->ht, &elem->node, rhtab_params);
 
-	bpf_enable_instrumentation();
-
 	if (tmp) {
 		bpf_mem_cache_free(&rhtab->ma, elem);
 		if (IS_ERR(tmp))

-- 
2.53.0

