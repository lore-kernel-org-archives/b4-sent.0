From: Jim Cromie <jim.cromie@gmail.com>
Subject: [PATCH v7 0/3] kallsyms: Accelerate symbol name lookups by ~7x
Date: Tue, 29 Sep 2026 12:07:29 -0600
Message-Id: <20260929-ksyms-tune-v7-0-be568ceef41e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XNwW7CMAzG8VdBOS9TYidps9PeY+LgJQaire3UQ
 DWE+u4znNpqHD9Lv79vqvJYuKq33U2NPJVahl5G87JT6UT9kXXJshUYCCbaqL/qtav6fOlZMwA
 5yC2hJSXgZ+RD+X3EPvayT6Weh/H6aE/2fv03M1ltdG59ik0mSwjvx47K92saOnXPTLCgACsKQ
 gkRmdEypWZL8TlFoaGVf47J+By31D2nTmgESkyt+4zWbqlfUr+iXqg9NJ6ySQg2bWlY0rCiQSh
 gCGBS8BzbJZ3n+Q+NlOQ0ywEAAA==
X-Change-ID: 20260919-ksyms-tune-e22a42d8a31a
To: Andrew Morton <akpm@linux-foundation.org>
Cc: Petr Mladek <pmladek@suse.com>, Zhen Lei <thunder.leizhen@huawei.com>, 
 Luis Chamberlain <mcgrof@kernel.org>, 
 Andrey Grodzovsky <andrey.grodzovsky@crowdstrike.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Kees Cook <kees@kernel.org>, David Laight <david.laight.linux@gmail.com>, 
 Masahiro Yamada <masahiroy@kernel.org>, Jiri Olsa <olsajiri@gmail.com>, 
 linux-kernel@vger.kernel.org, linux-kbuild@vger.kernel.org, 
 bpf@vger.kernel.org, Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790705250; l=10591;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=HedXA29bP2AYga35+FP735wrhCFsjEPZwKzF7UPRSqs=;
 b=Mv/rpPgdR/0VpIzwGFWoQbsQv8QxW98ufFmXosfOyf0Cpmy3i7E8xS9kk4S6Bs+9oQ/Fph7GE
 7I+JIKeR3XSDlquZrCiJVg/l7V26hSsYx/IPlkYVnzaMpUdRgwhEr6B
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In 2022, commit 60443c88f3a8 ("kallsyms: Improve the performance of
kallsyms_lookup_name()") introduced kallsyms_seqs_of_names[] (+550 KiB
.rodata), transforming an O(N) linear scan into an O(log N) binary
search (5.2 ms -> ~7.2 us).  While this was a major step forward,
the binary search inner loop was left decompressing full candidate
names and scanning across sparse 256:1 markers on every probe.

Modern fleet observability, security daemons (e.g. CrowdStrike Falcon,
Cilium, Datadog, Falco), and tracing tools resolve thousands of kernel
functions by name at boot or service start.

CrowdStrike recently hit this in production:

commit 93e8fd1a565e ("ftrace: Use kallsyms binary search for single-symbol lookup")

Attaching just 50 kprobe.session programs caused an 858 ms attach
stall with 25% CPU burned in kallsyms.  That commit routed single-symbol
libbpf attach directly to kallsyms_lookup_name().  In larger workloads
(such as the BPF selftest serial_test_kprobe_multi_bench_attach across
64,000 symbols), kallsyms_lookup_names() spends ~390 ms in raw CPU spin.

This series accelerates kallsyms_lookup_names() by 7.0x (from 6,102 ns
down to 866 ns per lookup), cutting 64k-symbol attach from ~390 ms to
~55 ms, by fixing two inner-loop bottlenecks:

0. Candidate symbols are fully decompressed into a 512-byte stack buffer
   before calling strcmp(), even though ~16 of the 17 search steps
   mismatch at the first differing character (0..N-1, heavily
   front-loaded toward 0-2).

1. Probes scan sequentially from 256:1 markers in kallsyms_names[],
   decoding an average of 127.5 symbols per probe (~2,170 hops across a
   17-step search).

The 3-patch progression:

0. Patch 1 introduces kallsyms_strcmp_symbol() to compare ASCII queries
   against compressed tokens on the fly, bailing out on first mismatch.
   Drops the 512-byte stack buffer and saves ~530 ns.

1. Patch 2 increases marker density from 256:1 to 16:1, cutting average
   scan distance from 127.5 to 7.5 hops and dropping lookup latency from
   6,102 ns to 866 ns for +42.2 KiB of .rodata.

2. Patch 3 inlines and unrolls get_symbol_seq() 24-bit reconstruction.

Results (CONFIG_KALLSYMS_SELFTEST across ~184k symbols):
- Baseline (256:1):  6,102 ns
- Patch 1 (strcmp):  5,572 ns (-530 ns)
- Patch 2 (16:1):      866 ns (7.0x faster)

Trade-offs:
- .rodata footprint: +42.2 KiB (+10,782 u32 entries for ~184k symbols,
  ~0.1% of loaded kernel image).
- Runtime overhead: 0 bytes dynamic RAM (no kmalloc/kvmalloc), 0 RCU,
  0 new locks, and 0 new algorithms.
- Kernel stack: -512 bytes freed in kallsyms_lookup_names().
- Build tooling: scripts/kallsyms.c includes
  ../kernel/kallsyms_internal.h (guarded by #ifdef __KERNEL__) so host
  build and kernel runtime share KALLSYMS_MARKER_SHIFT 4 as a single
  source of truth.
- Build time: Unmeasurable delta (< 1 ms in scripts/kallsyms.c).

What's Unchanged:
- Symbol table layout in address order remains identical.
- Streaming decompression for /proc/kallsyms and sprint_symbol() is
  untouched.
- 0 new user-facing APIs, 0 new locking primitives, 0 Kconfig options.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
Changes in v7:
- Lead cover letter with concrete workloads and "who cares" (citing
  CrowdStrike commit 93e8fd1a565e and 64k BPF selftest attach times)
  (addresses Andrew Morton review).
- Document lineage from Zhen Lei's 2022 binary search work in commit
  60443c88f3a8 (+550 KiB .rodata) and frame this series as completing
  that optimization (+42 KiB .rodata for 7x faster lookups).
- Explicitly detail memory (+42.2 KiB .rodata, 0 B RAM, -512 B stack)
  and build-time (<1 ms) trade-offs in cover letter (addresses Andrew
  Morton review).
- Detail lack of runtime complexity (0 kmalloc, 0 RCU, 0 locks, 0 new
  algos).
- Note scripts/kallsyms.c reading KALLSYMS_MARKER_SHIFT from kernel/
  header as single source of truth.
- Add Petr Mladek, Zhen Lei, Luis Chamberlain, Andrey Grodzovsky, and
  Steven Rostedt to Cc list.
- Link to v6: https://lore.kernel.org/r/20260926-ksyms-tune-v6-0-236620c65e98@gmail.com

Changes in v6:
- In patch 1, clarify token matching mechanics and early exit on char
  0..N-1; cite CONFIG_KALLSYMS_SELFTEST across all ~184k symbols for the
  ~530 ns measurement (addresses BPF CI review).
- In patch 1, drop 0-2 list and fix repeated word typo ("the the").
- In patch 2, recast commit body around kallsyms storage trade-offs and
  drop hunk-by-hunk numbered list (addresses BPF CI review).
- In patch 2, drop 0.002% percentage claim and state absolute .rodata
  cost (+42 KiB for ~184k symbols).
- In patch 2, drop ephemeral benchmark comment from
  kernel/kallsyms_internal.h (addresses BPF CI review).
- Link to v5: https://lore.kernel.org/r/20260925-ksyms-tune-v5-0-1f75ad0c321c@gmail.com

Changes in v5:
- Dismiss dynamic 1:1 batch table as unnecessary:
  In v2-v4, a dynamic u32 lookup index allocated in transient RAM was
  explored.  While dynamic 1:1 breaks even against baseline 256:1 after
  ~1,200 queries, comparing dynamic 1:1 against static 16:1 markers
  dismisses the dynamic approach entirely:
  * Static 16:1 markers achieve 866 ns, capturing 97.4% of the maximum
    latency savings of a 1:1 table (an 85.8% reduction from baseline).
  * Dynamic 1:1 gains only an incremental 138 ns (the remaining 2.6%),
    while paying ~6,419 us in allocation setup and synchronize_rcu()
    teardown.
  * Amortizing 6,419 us at 138 ns saved requires 46,514 queries just to
    break even against 16:1 markers.  For any workload under 46k
    queries, dynamic allocation is slower overall.
  * Drop kallsyms_lookup_batch_start/end APIs, mutexes, refcounts,
    transient kvmalloc RAM allocations, and RCU synchronization.
- Drop lib/test_kallsyms_perf benchmark module and
  CONFIG_TEST_KALLSYMS_PERF; existing in-tree CONFIG_KALLSYMS_SELFTEST
  already benchmarks standard kallsyms_lookup_name() without adding
  unmaintained test files in lib/.
- In patch 2, increase marker density to 16:1 via
  KALLSYMS_MARKER_SHIFT 4 shared between scripts/kallsyms.c and
  kernel/kallsyms_internal.h, and drop all references to dynamic tables
  from the patch body.
- Link to v4: https://lore.kernel.org/r/20260922-ksyms-tune-v4-0-92acea84b911@gmail.com

Changes in v4:
- In patch 1, ignore early boot invocations in param_set_trigger() when
  system_state < SYSTEM_RUNNING to prevent NULL pointer dereference in
  ktime_get_ns() prior to timekeeping_init() (addresses Sashiko review).
- In patch 1, prevent sysfs TOCTOU divide-by-zero panic: reject
  num_iters == 0 in param setter, snapshot iters locally via READ_ONCE,
  and serialize runs with bench_lock mutex (addresses Sashiko review).
- In patch 1, eliminate multi-second boot stall: add run_on_boot
  parameter (default false) so late_initcall only runs benchmark when
  explicitly requested (addresses Sashiko review).
- In patch 1, chunk lookup loops in 4096-iter batches with
  cond_resched() outside the timing bracket to prevent preemption sleep
  time from inflating reported latency (addresses Sashiko review).
- In patch 3, annotate dyn_kallsyms_offsets declaration with __rcu to
  satisfy sparse type checking and prevent address-space warnings across
  rcu_assign_pointer() and rcu_dereference() (addresses Sashiko review).
- In patch 3, use rcu_replace_pointer() with lockdep_is_held() during
  batch teardown to atomically read and clear the pointer while
  satisfying sparse address-space constraints (addresses Sashiko
  review).
- Link to v3: https://lore.kernel.org/r/20260922-ksyms-tune-v3-0-681a34ea05d9@gmail.com

Changes in v3:
- Reorder series: place on-the-fly token matching ahead of marker
  density optimization, establishing an active proof of incremental
  performance deltas across all steps (addresses David Laight review).
- Add inlined and unrolled get_symbol_seq() 24-bit sequence index
  reconstruction into direct byte shifts (addresses David Laight
  review).
- In test_kallsyms_perf, configure as a built-in test (bool) rather
  than a module (tristate) and drop kallsyms iterator EXPORT_SYMBOL_GPL
  exports to avoid exposing internal kernel symbol data (addresses
  Sashiko review).
- In patch 1, optimize kallsyms_strcmp_symbol() by dropping
  skipped_first tracking and checking len at the bottom of the token
  loop (addresses David Laight review).
- Drop 'default m' from lib/Kconfig.debug.
- Fix soft lockup risks by adding cond_resched() every 16k iterations in
  test_kallsyms_perf loops.
- Replace direct 64-bit integer divisions with div_u64() to fix 32-bit
  builds.
- Guard against divide-by-zero when num_iters=0.
- Replace tcp_v4_rcv with panic in hit_symbols to prevent failures wo
  CONFIG_INET.
- Move David Laight to series-wide Cc on cover letter, dropping trailer
  from patch 3.
- Link to v2: https://lore.kernel.org/r/20260922-ksyms-tune-v2-0-a333ee31eac7@gmail.com

Changes in v2:
- Replaced static build-time 3-byte offset table with a dynamic u32
  index bracketed by kallsyms_lookup_batch_start() and
  kallsyms_lookup_batch_end().
- Dropped .rodata image footprint addition from +573 KiB to 0 KiB,
  addressing Kees Cook's memory footprint objection.
- Native u32 loads in transient RAM eliminate 24-bit big-endian shifts
  and unaligned loads, addressing David Laight's endianness critique.
- Direct O(1) table indexing provides 0 hops for all symbol lookups
  without remainder logic or odd/even branching.
- Restored scripts/kallsyms.c and kernel/kallsyms_internal.h to pristine
  state, leaving legacy kallsyms_markers[] as safety fallback.
- Rebased out Lorenzo Stoakes' kbuild series; this series is now
  completely decoupled and applies cleanly directly onto mainline.
- Link to v1: https://lore.kernel.org/r/20260919-ksyms-tune-v1-0-d85c97da1a32@gmail.com

---
Jim Cromie (3):
      kallsyms: Match compressed tokens on the fly during binary search
      kallsyms: Increase marker density to 16:1 to accelerate lookups
      kallsyms: Unroll 24-bit sequence reconstruction in get_symbol_seq()

 kernel/kallsyms.c          | 111 +++++++++++++++++++++++++++------------------
 kernel/kallsyms_internal.h |  11 +++++
 scripts/kallsyms.c         |  14 ++++--
 3 files changed, 86 insertions(+), 50 deletions(-)
---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260919-ksyms-tune-e22a42d8a31a

Best regards,
-- 
Jim Cromie <jim.cromie@gmail.com>

