From: Mani Tofigh <mt4022@columbia.edu>
Date: Tue, 03 Nov 2026 13:46:20 -0500
Subject: [PATCH bpf] bpf: Fail rhtab inserts and deletes with IRQs disabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-bpf-rhtab-irqs-disabled-v1-1-9874d96a088c@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMywqDMBAAf0X23IUklYD9Fekhj42uFKu7thTEf
 29ajzMws4OSMCncmh2E3qz8nCvYSwNpDPNAyLkyOOO8teaKcSko4xYisqyKmTXEB2VMrW996sg
 UclDrRajw53/uoUZwP6W+4kRp+z3hOL5OQ3zIgAAAAA==
X-Change-ID: 20261103-bpf-rhtab-irqs-disabled-c4646c9e0fe2
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Mykyta Yatsenko <yatsenko@meta.com>
Cc: Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, bpf@vger.kernel.org, 
 linux-kernel@vger.kernel.org, tz2294@columbia.edu, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793731580; l=4598;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=k/fbalQH7E1usqP989+bFkfP43DzltNbY4941FlxG7Q=;
 b=L0FtAKcGFsRCo7qWQx89izPH5DV/0Lc1sSd0BeHxZN7aYi09wyNRr++7gm950zOYdQjmwMF9l
 yU1A1QSMTJvAQ2olkOHog2fGOluO/mvo7tspiwrIeTTMU6huyEiD0SF
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A BPF program can spin forever on a resizable hash map's bucket lock
that its own CPU already holds.  Inserts and deletes take the
rhashtable bucket lock, a bit spinlock that can't detect re-entry.  The
resize worker calls the hash function with that lock held, so a kprobe
program on the hash function that deletes a key of the same bucket
never gets the lock:

  rht_deferred_worker()
    rht_lock(old_tbl, bkt)
    rhashtable_jhash2()
      kprobe program
        bpf_map_delete_elem()
          rht_lock(old_tbl, bkt)
            /* spins with IRQs disabled */

  [   29.890449] rcu: INFO: rcu_preempt detected stalls on CPUs/tasks:
  ...
  [   29.906964] NMI backtrace for cpu 0
  [   29.906977] CPU: 0 UID: 0 PID: 9 Comm: kworker/0:0 Tainted: G        W            7.3.0-17087-gd865f2677c44 #1 PREEMPT
  [   29.907021] Workqueue: events rht_deferred_worker
  [   29.907041] RIP: 0010:rhtab_delete_elem+0x15f9/0x1c80
  ...
  [   29.907139] Call Trace:
  [   29.907145]  <TASK>
  [   29.907193]  rhtab_map_delete_elem+0x61/0x120
  [   29.907208]  bpf_prog_12e9295082de5b34+0xa0/0xee
  [   29.907231]  trace_call_bpf+0x2ca/0x930
  [   29.907334]  kprobe_perf_func+0x106/0x700
  [   29.907381]  aggr_pre_handler+0x8f/0x110
  [   29.907403]  kprobe_int3_handler+0x335/0x750
  [   29.907433]  do_int3+0xd/0x50
  [   29.907445]  exc_int3+0x165/0x340
  [   29.907467]  asm_exc_int3+0x39/0x40
  [   29.907477] RIP: 0010:rhashtable_jhash2+0x5/0x360
  ...

A program in NMI over any holder of a bucket lock can do the same.

A bucket lock is only ever held with IRQs disabled, so return -EBUSY
from deletes and from inserts of new keys when IRQs are already
disabled, like the other hash maps do on re-entry.  Lookups and updates
of existing keys don't take the lock and still work.  With the fix, the
delete fails with -EBUSY and the resize finishes.

This bug was identified and confirmed with the help of a deterministic
hypervisor currently under development.  The C reproducer below however
hits it within about 1s.

Fixes: 16b4d3e2fb24 ("bpf: Implement resizable hashmap basic functions")
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
This is the check Alexei suggested on the RFC of the series [1].  It also
stops perf_event and other programs that run with IRQs disabled from
inserting or deleting keys.  I can turn the reproducer into a selftest
if that helps.

[1] https://lore.kernel.org/all/CAADnVQKvp2tnQSWW4Kh3ofGLvaEYJ47kyZeNUscAH_DShw8XHw@mail.gmail.com/

Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/rhashlock.c
---
 kernel/bpf/hashtab.c | 16 +++++++++++-----
 1 file changed, 11 insertions(+), 5 deletions(-)

diff --git a/kernel/bpf/hashtab.c b/kernel/bpf/hashtab.c
index 6e2115477cb9..1a9f07b71bca 100644
--- a/kernel/bpf/hashtab.c
+++ b/kernel/bpf/hashtab.c
@@ -3144,11 +3144,14 @@ static int rhtab_delete_elem(struct bpf_rhtab *rhtab, struct rhtab_elem *elem, v
 	int err;
 
 	/*
-	 * disable_instrumentation() mitigates the deadlock for programs running in NMI context.
-	 * rhashtable locks bucket with local_irq_save(). Only NMI programs may reenter
-	 * rhashtable code, bpf_disable_instrumentation() disables programs running in NMI, except
-	 * raw tracepoints, which we don't have in rhashtable.
+	 * rhashtable takes its bucket bit locks with IRQs disabled and can't
+	 * detect re-entry. With IRQs already disabled this CPU may already
+	 * hold one, e.g., in NMI or in a program attached inside the resize
+	 * worker's locked section.
 	 */
+	if (irqs_disabled())
+		return -EBUSY;
+
 	bpf_disable_instrumentation();
 
 	if (rhtab->map.key_size == sizeof(long))
@@ -3261,6 +3264,10 @@ static long rhtab_map_update_elem(struct bpf_map *map, void *key, void *value, u
 	if (atomic_read(&rhtab->ht.nelems) >= map->max_entries)
 		return -E2BIG;
 
+	/* see rhtab_delete_elem() */
+	if (irqs_disabled())
+		return -EBUSY;
+
 	elem = bpf_mem_cache_alloc(&rhtab->ma);
 	if (!elem)
 		return -ENOMEM;
@@ -3268,7 +3275,6 @@ static long rhtab_map_update_elem(struct bpf_map *map, void *key, void *value, u
 	memcpy(elem->data, key, map->key_size);
 	copy_map_value(map, rhtab_elem_value(elem, map->key_size), value);
 
-	/* Prevent deadlock for NMI programs attempting to take bucket lock */
 	bpf_disable_instrumentation();
 
 	if (map->key_size == sizeof(long))

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261103-bpf-rhtab-irqs-disabled-c4646c9e0fe2

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

