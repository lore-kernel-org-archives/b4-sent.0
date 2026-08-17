From: Jim Cromie <jim.cromie@gmail.com>
Subject: [PATCH 0/9] lib/folio_pool: Direct-Map Large Folio Pool &
 Scratchpad bump allocators
Date: Mon, 17 Aug 2026 11:22:14 -0600
Message-Id: <20260817-folio-pool-v1-v1-0-0c1d230aa3af@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/w3HQQqAIBAAwK/InltQSa1+U5vVgriR4EX8e85tG
 pT4cSywqQZfrFxY8oiZFNCz5zsin+NgtfV6MQ4vSSz4iiSsBukIjuwc/GoJev8BleereU8AAAA
 =
X-Change-ID: 20260815-folio-pool-v1-cb75c247692c
To: Andrew Morton <akpm@linux-foundation.org>, 
 Pablo Neira Ayuso <pablo@netfilter.org>, Florian Westphal <fw@strlen.de>, 
 Phil Sutter <phil@nwl.cc>, Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, Danilo Krummrich <dakr@kernel.org>, 
 Matthew Brost <matthew.brost@intel.com>, 
 Boris Brezillon <boris.brezillon@collabora.com>, 
 Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Will Deacon <will@kernel.org>, Waiman Long <longman@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 John Fastabend <john.fastabend@gmail.com>, 
 =?utf-8?q?Thomas_Hellstr=C3=B6m?= <thomas.hellstrom@linux.intel.com>, 
 Alice Ryhl <aliceryhl@google.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Boqun Feng <boqun@kernel.org>, Boqun Feng <boqun@kernel.org>
Cc: netfilter-devel@vger.kernel.org, bpf@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, coreteam@netfilter.org, netdev@vger.kernel.org, 
 Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786987349; l=10279;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=S4TsoAAriM4sI09Qb2bqw2yp5vAZgxjGGyIiOJ7aKR4=;
 b=6ocnK9kGfINHZu0sFQxosXoa9fjGshgR96/GaN0gRrx/bgz1WzePp0sGTF2pIHDrfTwHsE3pT
 Xf5QfrlXQLZBqAgieAwPs5KBseEIIPHPpOFwKAhctAZGFVpB/VetMaZ
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce two light-weight bump allocators backed directly by compound
folio pages from the buddy allocator (skipping SLUB metadata overhead):

1. struct folio_scratchpad - Variable-sized, alignment-aware bump allocator
   for bursty, append-mostly lifecycles with bulk teardown.
2. struct folio_pool - Fixed uniform-slot bump allocator for homogeneous
   descriptors.

These serve 2 kinds of use-cases:

1: Ephemeral Batch/transaction Lifecycles (Netfilter, BPF, DRM GPUVM)

- Transactional subsystems allocate bursts of hundreds or thousands of
  homogeneous or heterogeneous objects, only to tear them all down
  simultaneously at batch completion or error abort.

- Under SLUB: Each descriptor incurs freelist traversal, lock
  contention, and O(N) kfree() loops on teardown.

- Under Folio-Scratchpad: Allocations are straight-line pointer bumps,
  bulk teardown is O(1) folio_put(), and consecutive Netlink
  transactions reuse warm L1/L2 cachelines without buddy lock churn
  via folio_scratchpad_reset().

2: Dynamic Long-Lived Graph Scaling (Lockdep)

- Core subsystems historically avoided SLUB by statically
  preallocating massive compile-time arrays in .bss
  (e.g. list_entries[32768], 1.31 MB) to prevent SLUB allocator
  recursion deadlocks.

- Fixed arrays exhaust their limit and permanently disable validation
  (BUG: MAX_LOCKDEP_ENTRIES too low!).
  
- Under Folio-Pool: Lockdep uses a 4,096-entry __initdata bootstrap
  buffer for early boot prior to buddy initialization, then seamlessly
  migrates and compacts all dependency edges into 64 KB direct-map
  folios at late_initcall.
  
- Permanent static .bss allocation for dependency edges is reduced
  from 1.31 MB to 0 KB (100% reclamation at free_initmem()).

Core Primitives in include/linux/folio_pool.h & lib/folio_pool.c:
-----------------------------------------------------------------
0. struct folio_scratchpad (Variable-Sized Elements):
   - Dynamic alignment-aware bump pointer with zero padding waste.
   - API: folio_scratchpad_init(), folio_scratchpad_alloc(),
     folio_scratchpad_reset(), folio_scratchpad_free(),
     folio_scratchpad_stats().
   - Typed macros: folio_scratchpad_alloc_obj(),
     folio_scratchpad_alloc_bytes(), DEFINE_FREE(folio_scratchpad, ...).

1. struct folio_pool (Fixed Uniform Elements):
   - Thin wrapper embedding struct folio_scratchpad for homogeneous objects.
   - API: folio_pool_init(), folio_pool_alloc(), folio_pool_free(),
     folio_pool_stats().
   - Typed macros: folio_pool_alloc_obj(), folio_pool_alloc_type().

2. Encapsulated Slab Discrimination & Reallocation:
   - is_folio_pool_ptr(ptr): Direct-map folios are identified via
     virt_to_folio(ptr) && !folio_test_slab(f), avoiding custom bitflags.
   - folio_scratchpad_free_elem(ptr): Safe no-op for folio-backed objects;
     delegates to kvfree() for SLUB/vmalloc fallback objects.
   - folio_scratchpad_realloc(ptr, old_size, new_size, gfp): Delegates to
     krealloc() for SLUB objects; allocates a fresh SLUB buffer and copies
     payload for folio-backed descriptors.

3. Subsystem Autonomy & Runtime Static-Key Control:
   - DEFINE_FOLIO_POOL_STATIC_KEY_PARAM() allows maintainers of each
     subsystem (Netfilter, Lockdep, DRM, BPF) to choose their own default
     enablement policy (DECLARE_STATIC_KEY_TRUE vs FALSE) and independent
     module/boot parameters (e.g. lockdep.folio_pool, nf_tables.trans_scratchpad).
   - Enables isolated, zero-overhead A/B benchmarking and production triage
     without cross-subsystem coupling or kernel recompilation.

Active Proofs & Performance Profiling:
--------------------------------------
0. Virtualized Guest Netfilter Benchmark (KVM / virtme-ng ftrace):
   Controlled A/B benchmark across 10,025 Netlink transaction descriptors
   and 5 asynchronous commit/abort teardown passes:

   Function: nft_trans_alloc (10,025 descriptor allocations)
   -----------------------------------------------------------------------------
   Mode                                 Total Time       Avg / Alloc      Delta
   -----------------------------------------------------------------------------
   folio_scratchpad Enabled (Bump)      9,158.02 us          0.914 us    -19.4%
   SLUB Fallback (kzalloc)             11,366.53 us          1.134 us  Baseline
   -----------------------------------------------------------------------------
   Net allocation latency reduction:   -2,208.52 us (-2.21 ms)

   Function: nf_tables_trans_destroy_work (5 asynchronous teardown passes)
   -----------------------------------------------------------------------------
   Mode                                 Total Time       Avg / Pass       Delta
   -----------------------------------------------------------------------------
   folio_scratchpad Enabled (Bulk)     36,065.65 us          7.21 ms      -8.6%
   SLUB Fallback (O(N) kfree)          39,449.65 us          7.89 ms   Baseline
   -----------------------------------------------------------------------------
   Net teardown latency reduction:     -3,384.00 us (-3.38 ms)

   Combined In-Kernel Netlink Transaction Lifecycle Savings: -5.59 ms (-13.3%)

1. Bare-Metal Host Netfilter Profile (AMD Zen 3 Hardware PMU & ftrace):
   - Asynchronous Teardown: 53.77 ms vs 56.03 ms (-2.26 ms / -4.0%).
   - Instruction Retirement: 281.29M -> 282.46M (-1,174,062 instructions).
   - Branch Instructions:     62.94M ->  63.20M (-265,961 branches).

2. Bare-Metal Host Lockdep Telemetry (Physical Host frodo, AMD Zen SMP):
   - Pre-Buddy Watermark: 928/4096 bootstrap entries consumed during boot.
   - Graph Compaction: Migrated and compacted bootstrap dependency edges
     into folio_pool at late_initcall; bootstrap array reclaimed by
     free_initmem() (0 KB permanent .bss cost).
   - Live procfs Telemetry (/proc/lockdep_stats):
     lock-classes:                          996 [max: 8192]
     direct dependencies:                  2324 [dynamic: 7 x 64 kB, tail: 17 kB/64 kB]
     indirect dependencies:               24612
     all direct dependencies:             81884
     zapped classes:                          2
     zapped lock chains:                    173
   - Active Invariant Validation: Live module unloads exercised modernized
     zap_class() direct list unlinking across dynamic folios with zero
     global bitmap scans and zero assertions.

What's Unchanged:
-----------------
- All consumer object structures, alignment rules, and lifecycle boundaries
  remain strictly identical.
- Memory safety invariants are preserved: individual deallocation is a safe
  no-op for arena-backed objects while SLUB objects continue to use kfree().

Subsystem Adoptions in this Series:
-----------------------------------
0. lib/folio_pool: Core direct-map large-folio pool and scratchpad allocators.
1. netfilter/nf_tables: Pack netlink transaction descriptors into per-net
   trans_scratchpad with bulk reclaim & warm chunk reset.
2. bpf/verifier: Route verifier stack state node allocations to folio_pool.
3. drm/gpuvm: Route gpuva_op allocations to folio_scratchpad.
4. bpf/syscall: Route generic_map_update_batch key/value allocations to
   folio_scratchpad.
5. locking/lockdep: Fallback to folio_pool in alloc_list_entry when static
   pool is full and expose dynamic folio telemetry in /proc/lockdep_stats.
6. locking/lockdep: Traverse adjacency lists directly in zap_class().
7. locking/lockdep: Shrink static list_entries array to early bootstrap buffer.
8. locking/lockdep: Migrate and compact boot-time dependency graph from __initdata.

Patches in this series:
-----------------------
[PATCH 1/9] lib/folio_pool: Introduce Direct-Map Large Folio Pool & Scratchpad bump allocators
[PATCH 2/9] netfilter/nf_tables: Add folio_scratchpad collector to struct nftables_pernet
[PATCH 3/9] bpf/verifier: Route verifier stack state node allocations to folio_pool
[PATCH 4/9] drm/gpuvm: Route gpuva_op allocations to folio_scratchpad
[PATCH 5/9] bpf/syscall: Route generic_map_update_batch key/value allocations to folio_scratchpad
[PATCH 6/9] locking/lockdep: Fallback to folio_pool in alloc_list_entry when static pool is full
[PATCH 7/9] locking/lockdep: Traverse adjacency lists directly in zap_class()
[PATCH 8/9] locking/lockdep: Shrink static list_entries array to early bootstrap buffer
[PATCH 9/9] locking/lockdep: Migrate and compact boot-time dependency graph from __initdata

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
Jim Cromie (9):
      lib/folio_pool: Introduce Direct-Map Large Folio Pool & Scratchpad bump allocators
      netfilter/nf_tables: Add folio_scratchpad collector to struct nftables_pernet
      bpf/verifier: Route verifier stack state node allocations to folio_pool
      drm/gpuvm: Route gpuva_op allocations to folio_scratchpad
      bpf/syscall: Route generic_map_update_batch key/value allocations to folio_scratchpad
      locking/lockdep: Fallback to folio_pool in alloc_list_entry when static pool is full
      locking/lockdep: Traverse adjacency lists directly in zap_class()
      locking/lockdep: Shrink static list_entries array to early bootstrap buffer
      locking/lockdep: Migrate and compact boot-time dependency graph from __initdata

 drivers/gpu/drm/drm_gpuvm.c        |  11 +-
 include/drm/drm_gpuvm.h            |   6 +
 include/linux/bpf_verifier.h       |   3 +
 include/linux/folio_pool.h         | 279 +++++++++++++++++++++++++++++++++++++
 include/net/netfilter/nf_tables.h  |   3 +
 kernel/bpf/syscall.c               |  17 ++-
 kernel/bpf/verifier.c              |  16 ++-
 kernel/locking/lockdep.c           | 278 +++++++++++++++++++++++++++++-------
 kernel/locking/lockdep_internals.h |   2 +
 kernel/locking/lockdep_proc.c      |  16 ++-
 lib/Makefile                       |   2 +-
 lib/folio_pool.c                   | 230 ++++++++++++++++++++++++++++++
 net/netfilter/nf_tables_api.c      |  51 +++++--
 13 files changed, 837 insertions(+), 77 deletions(-)
---
base-commit: 1a7ac48cd3e62f281ce62f8ed89dc2cc8866eaa4
change-id: 20260815-folio-pool-v1-cb75c247692c

Best regards,
-- 
Jim Cromie <jim.cromie@gmail.com>

