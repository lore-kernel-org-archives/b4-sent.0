From: Jim Cromie <jim.cromie@gmail.com>
Subject: [PATCH v5 0/3] kallsyms: Accelerate symbol name lookups by ~7x
Date: Fri, 25 Sep 2026 15:16:35 -0600
Message-Id: <20260925-ksyms-tune-v5-0-1f75ad0c321c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XNTQ6CMBCG4auQrq2h0/JTV97DuBjbERoFDEUiI
 dzdwgqJLL9JnndG5ql15NkpGllLvfOuqcNIDhEzJdYFcWfDZhBDGmuh+cMPlefduyZOAKjA5ig
 FsgBeLd3dZ4ldrmGXzndNOyztXszXv5le8JjbPDE6syhQwrmo0D2PpqnYnOlhRQF+KASKUkoiK
 QhNtqVyn8pA0zz8U4RxYvWWqn2qAtWAhjBXNy3Emk7T9AXGLBa3VQEAAA==
X-Change-ID: 20260919-ksyms-tune-e22a42d8a31a
To: Andrew Morton <akpm@linux-foundation.org>
Cc: Lorenzo Stoakes <ljs@kernel.org>, Kees Cook <kees@kernel.org>, 
 David Laight <david.laight.linux@gmail.com>, 
 Masahiro Yamada <masahiroy@kernel.org>, Jiri Olsa <olsajiri@gmail.com>, 
 linux-kernel@vger.kernel.org, linux-kbuild@vger.kernel.org, 
 bpf@vger.kernel.org, Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790370996; l=9194;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=gUiMkOcEBxUU9LS1teUE6jeukMIc+96YYXQX0CViWrc=;
 b=ro4e2ZD/NU/xYaI689YiwePmybVZSf0UlscHthOqUxK6v9lDvcH2jAz6jJw3cv/0UdYaZsC3J
 PbIxMv7t8BBDN5ezYraVTOCXnPaHPpiwOes6DytSXxLZJWR6u77lIcj
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

kallsyms_lookup_names() resolves symbol names to addresses using a
17-step binary search over kallsyms_names[] (~184k symbols on x86_64).
At each step of the search, two bottlenecks compound to create
substantial lookup latency:

0. Redundant string expansion: kallsyms_expand_symbol() decompresses
   the entire candidate symbol into a 512-byte stack buffer (namebuf)
   before calling strcmp(), even though ~94% of binary search probes
   mismatch on the first 1-2 characters (~580 ns per lookup).

1. Marker scanning: get_symbol_offset() scans sequentially from the
   nearest 256-symbol marker in kallsyms_names[], decoding an average
   of ~128 ULEB128 record headers per probe (~2,176 header decodes,
   consuming ~3,230 ns to ~5,200 ns per lookup).

Together, these bottlenecks impose a substantial latency penalty during
symbol lookup (~3.8 us to ~6.1 us per probe).  During bulk workloads
such as BPF multi-trampoline attach (e.g. tracing across 64,021 kernel
functions in serial_test_tracing_multi_bench_attach), this compounds
into multiple seconds of attach stall time.

David Laight suggested rounding binary search probes down to multiples
of 256, but kallsyms_names[] is ordered by symbol address while the
binary search operates alphabetically over kallsyms_seqs_of_names[].
Address sequence numbers jump pseudo-randomly across address space on
every probe, meaning address markers cannot be pre-rounded during
alphabetical binary search.

Instead, this 3-patch series addresses both bottlenecks directly in
a clean progression:

0. Patch 1 introduces kallsyms_strcmp_symbol() to compare ASCII queries
   against compressed tokens on the fly, bailing out on the first
   mismatched character without expanding subsequent tokens.  This drops
   the 512-byte namebuf buffer from the kernel stack and saves ~530 ns
   per lookup on unmodified marker infrastructure.

1. Patch 2 increases the static marker density from 256:1 down to 16:1
   (1 marker every 16 symbols) via KALLSYMS_MARKER_SHIFT 4 shared
   between scripts/kallsyms.c and kernel/kallsyms_internal.h.  This cuts
   average marker scan distance by 17x (from 127.5 down to 7.5 hops) and
   drops lookup latency from 6,102 ns to 866 ns (a 7.0x speedup) for
   only +42.2 KiB of write-protected .rodata (0.002% of vmlinux).

2. Patch 3 inlines and unrolls get_symbol_seq() 24-bit sequence index
   reconstruction into direct byte shifts, eliminating loop overhead
   on inner binary search probes.

In-Tree Selftest Progression (virtme-ng, kernel/kallsyms_selftest):
- Baseline (256:1 markers):   6,102 ns / lookup
- 16:1 markers (Patch 2):       866 ns / lookup (7.0x speedup, -85.8%)
- Dynamic 1:1 batch table:      728 ns / lookup (only 138 ns delta)
- Break-even vs 256:1 base:   1,194 queries (6,419 us / 5,374 ns)
- Break-even vs 16:1 markers: 46,514 queries (6,419 us / 138 ns)

What's Unchanged:
0. Address-ordered layout of kallsyms_names[] remains identical.
1. Address-to-name resolution (sprint_symbol, sprint_symbol_no_offset)
   and sequential table iteration (kallsyms_on_each_symbol,
   /proc/kallsyms) remain untouched, maintaining full L1/L2 prefetching.
2. Kernel symbol table encapsulation is preserved with 0 new exported
   symbols, 0 new batch APIs, and 0 Kconfig options.

Memory footprint: +42.2 KiB .rodata added to kernel image (0.002% of
vmlinux).  0 bytes dynamic RAM.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
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
 kernel/kallsyms_internal.h |   5 ++
 scripts/kallsyms.c         |  14 ++++--
 3 files changed, 80 insertions(+), 50 deletions(-)
---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260919-ksyms-tune-e22a42d8a31a

Best regards,
-- 
Jim Cromie <jim.cromie@gmail.com>

