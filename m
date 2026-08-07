From: Kairui Song <kasong@tencent.com>
Subject: [PATCH RFC 00/13] mm/huge_memory: clean up folio split and lift
 swapcache split limits
Date: Sat, 08 Aug 2026 05:17:01 +0800
Message-Id: <20260808-swap-thp-cleanup-v1-0-689939a7ccc3@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDCwMT3eLyxALdkowC3eSc1MS80gJds+RUo6RUs+Q04yQLJaC2gqLUtMw
 KsJHRSkFuzkqxEMHi0qSs1OQSkGFKtbUAQ+JxZnkAAAA=
X-Change-ID: 20260804-swap-thp-cleanup-6ce2be6cf3b8
To: linux-mm@kvack.org
Cc: linux-kernel@vger.kernel.org, Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Zi Yan <ziy@nvidia.com>, Baolin Wang <baolin.wang@linux.alibaba.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Nico Pache <nico.pache@linux.dev>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Chris Li <chrisl@kernel.org>, Kemeng Shi <shikemeng@huaweicloud.com>, 
 Nhat Pham <nphamcs@gmail.com>, Baoquan He <baoquan.he@linux.dev>, 
 Barry Song <baohua@kernel.org>, Youngjun Park <youngjun.park@lge.com>, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786137467; l=3669;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=F8O7FJxU7En109k29YAv2EDzjAiMtmbEJ18LeIdn92w=;
 b=btCVYHLU/t5mhFNxoCekjdi/BqIz2CIrr6pQDR9wm79cOi62ee2UlltZjtwgXVusUkiQDZqdh
 3cYT3kwGYadDLh7yr1Ooo4RfWM5qIvGLKH/Pd/luc7RTMJvLMke/q7/
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series clean up the split code, add better swap cache split support
for mappingless, large order, uniform and non-uniform split.  Generic
performance is on par or slightly better, and stack usage is reduced.

The swap cache infrastructure can handle non-uniform or high order folio
replace, so there is no reason for either restriction from the THP side.
What stands in the way is the mixed anon/file folio split routine,
which makes lifting the restrictions hard to follow, and it already
carries some buggy or redundant checks.

So this series cleans up the split path and separates anon and file
splitting into two helpers.  The file split path never sees a swap
cache folio, and that is now enforced up front: a folio that is both
in the page cache and the swap cache can only be a shmem folio, which
remains unsupported and is rejected early.  That helps to rule out swap
cache handling in that part completely.  Only the anon split path
handles swap cache folios, with an anon mapping or mappingless:
either way the splitting is similar, and non-uniform split is
supported as well.

Order-1 is still forbidden for swap cache splitting.  In theory it is
doable for shmem swap cache folios, but a mappingless swap cache
folio cannot currently be told apart from a shmem one, so forbid it
for all swap cache folios for now.

Testing:

The in-tree split_huge_page_test selftest (uniform, non-uniform and
in-folio-offset splits of anon and pagecache folios) passes 62/62 on
the patched kernel.

ftrace function_graph tracing filtered on __folio_split() was used to
compare per-call durations between the base and the patched kernel on
the same x86-64 box (interleaved runs across alternating reboots;
mean +- stddev of the per-run averages, 135 split calls per run):

  base:    24 runs, 69.6 +- 0.7 us per __folio_split()
  patched: 26 runs, 68.8 +- 1.3 us per __folio_split()

The patched kernel is consistently ~1% faster; with this sample
count the difference is outside run-to-run noise.

On x86-64 with gcc 12 (-fstack-usage), the stack frame of
__folio_split() shrinks from 240 to 96 bytes, and the worst-case
split call chain from ~544 to ~384 (anon) or ~464 (file) bytes.

Bloat-o-meter shows a tiny growth of huge_memory.o:
before=58419 after=58446, chg +0.05% (+27 bytes).

Signed-off-by: Kairui Song <kasong@tencent.com>
---
Kairui Song (13):
      mm/swap: fix off-by-one in swap cache replace sanity check
      mm/huge_memory: fix rejection of swap cache folios with a mapping
      mm/huge_memory: invert folio_ref_freeze() check to reduce indentation
      mm/huge_memory: split the routine for splitting anon and file folio
      mm/huge_memory: consolidate irq and locking for folio split
      mm/huge_memory: move EOF trimming into the file split helper
      mm/huge_memory: move unmap and remap into the split helpers
      mm/huge_memory: move anon_vma and filemap management into split helpers
      mm/huge_memory: move memcg switch into the file split helper
      mm/huge_memory: allow splitting mappingless swap cache folios
      mm/huge_memory: clean up after-split folio freeing in __folio_split
      mm/huge_memory: lift order-0 restriction for swapcache split
      mm/huge_memory: count only swap cache refs in anon folio split

 mm/huge_memory.c | 583 ++++++++++++++++++++++++++++---------------------------
 mm/swap_state.c  |   3 +-
 2 files changed, 298 insertions(+), 288 deletions(-)
---
base-commit: 7e4ead2558f28da16d82a8f5845eee44555ff6ba
change-id: 20260804-swap-thp-cleanup-6ce2be6cf3b8

Best regards,
--  
Kairui Song <kasong@tencent.com>

