From: Ackerley Tng <ackerleytng@google.com>
Subject: [PATCH 0/3] Fix HugeTLB subpool used_hpages tracking
Date: Wed, 02 Sep 2026 16:30:46 -0700
Message-Id: <20260902-hugetlb-subpool-always-track-used-v1-0-de1cd14bd713@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKaxmGoC/x3NwQqDMAyA4VeRnBfIQhG3Vxk71Bo1rFhprNsQ3
 31lx+/y/weYZBWDe3NAll1N01JxvTQQZr9MgjpUAxO3dCPGuUyyxR6t9GtKEX18+6/hln14YTE
 ZkFt2naPRBeqgdtYso37+j8fzPH8U1cpGcwAAAA==
X-Change-ID: 20260902-hugetlb-subpool-always-track-used-2624840f4c08
To: Alex Shi <alexs@kernel.org>, Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Dongliang Mu <dzm91@hust.edu.cn>, 
 Hongxiang Lou <louhongxiang@huawei.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Jonathan Corbet <corbet@lwn.net>, 
 Joshua Hahn <joshua.hahnjy@gmail.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Miaohe Lin <linmiaohe@huawei.com>, Michal Hocko <mhocko@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Muchun Song <muchun.song@linux.dev>, 
 Nhat Pham <nphamcs@gmail.com>, Oscar Salvador <osalvador@suse.de>, 
 Peter Xu <peterx@redhat.com>, Randy Dunlap <rdunlap@infradead.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Suren Baghdasaryan <surenb@google.com>, Usama Arif <usama.arif@linux.dev>, 
 Vlastimil Babka <vbabka@kernel.org>, Wupeng Ma <mawupeng1@huawei.com>, 
 Yanteng Si <si.yanteng@linux.dev>, fvdl@google.com, jthoughton@google.com, 
 rientjes@google.com, vannapurve@google.com
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, Ackerley Tng <ackerleytng@google.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788391851; l=6558;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=Xxc4EGpnsL1t3+z+6iTUEEoO2c75bqIsit8HhK+9hck=;
 b=j8AYp1AzMewolXJvwnkVhiePaFUKvLV9DIlmbjKhNscsoE4JyIiebqQvBOKGFL0qMPH9bWM35
 k/0zNqPL3VnDvGmIapusqP/hdH0fDfjw9sS3bLTTv4+aEYmCGwFkFXK
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

HugeTLB subpools currently only track used_hpages when the user configures
a size limit.

This is buggy since when there are existing allocations from the subpool
that would have satisfied the minimum reservations,
hugepage_subpool_put_pages() will still restore a reservation to the
subpool. See below for an example of a false reservation.

In addition, the subpool is considered free prematurely, is freed, and this
ends up causing a use-after-free.

The fix is to always track used_hpages within subpools, which is also
beneficial in general because with that information, reservation tracking
is also fully managed within hugepage_subpool_put_pages().

The invariant is that now (if min_hpages is requested),

  used_hpages + rsv_hpages >= min_hpages

This allows hugepage_subpool_put_pages() to always be able to report how
many reservations it can absorb and hence return an accurate number of
reservations to be returned to the global pool.

Hugepage reservations and restorations can always happen in parallel, so
relying on local variables to compute whether to restore to the global pool
(on allocation failure) is not safe.

There is complexity and some bugs in hugetlb_reserve_pages() and
alloc_hugetlb_folio() failure handling paths.

+ In hugetlb_reserve_pages(): On hugetlb_acct_memory() failure,
  out_put_pages manually calculates how many pages to return using local
  variables, which is race-prone and can leak reservations or underflow
  global counters.
+ In alloc_hugetlb_folio(): When allocation fails and gbl_chg == 1,
  out_subpool_put skips hugepage_subpool_put_pages(), permanently leaking
  used_hpages.

By tracking used_hpages in the subpool, these allocation/reservation paths
can handle failures by consistently returning pages to the subpool, and
relying on the return value to restore reservations to the global pool.

This series changes subpools to always track used_hpages, which itself
fixes the false reservation bug, and then uses used_hpages tracking in
subpools to fix other bugs.

This series is a subset of patches from [1] and replaces [1].

[1] https://lore.kernel.org/all/20260722-hugetlb-alloc-failure-fixes-v4-0-88e8b81970dc@google.com/

I have reproducers, get them from

https://github.com/googleprodkernel/linux-cc/commits/hugetlb-subpool-always-track-used-with-reproducers

Here's an example of a false restoration:

1. Mount time
    + spool->min_hpages = 1 (user requested min_size=2M)
    + spool->max_hpages = -1 (no maximum size specified)
    + spool->rsv_hpages = 1 (reserve min_hpages)
    + spool->used_hpages = 0 (not tracked when max_hpages == -1)
    + h->resv_huge_pages = 1 (reserved by hugetlb_acct_memory(h, 1))
2. Shared mapping of 4MB (2 pages) created (mmap with MAP_SHARED)
    + In hugetlb_reserve_pages(), region_chg() finds chg = 2 (pages 0 and 1
      need reservations)
    + hugepage_subpool_get_pages(spool, 2)
        + spool->rsv_hpages = 0 (consumed the 1 subpool reservation)
        + Return 1, since this subpool only had 1 reservation
    + hugetlb_acct_memory(h, 1)
        + h->resv_huge_pages = 2 (incremented from 1 to 2 for the global
          reservation)
        + region_add() records reservations for pages 0 and 1 in the inode
          resv_map
3. Process touches and populates Page 0:
    + hugetlb_no_page() calls alloc_hugetlb_folio()
    + Page 0 reuses the existing reservation (vma_needs_reservation()
      returns 0 => map_chg = MAP_CHG_REUSE = 0)
    + hugepage_subpool_get_pages() is not called (map_chg == 0)
    + dequeue_hugetlb_folio_nodemask() consumes 1 reservation:
      h->resv_huge_pages--;
    + h->resv_huge_pages = 1 (decremented from 2 to 1)
4. Process closes the file and exits:
    + For MAP_SHARED mappings, reservations persist in the inode resv_map
    + Page 1 reservation remains active
    + h->resv_huge_pages = 1 (retained for Page 1)
5. File is truncated to 2MB (truncate -s 2M):
    + Truncation invokes remove_inode_hugepages() for page range [1,
      LONG_MAX)
    + Page 1 was never faulted into page cache => freed = 0
    + Calls hugetlb_unreserve_pages(inode, 1, LONG_MAX, freed = 0)
    + region_del() removes Page 1 from resv_map => chg = 1
6. Inside hugetlb_unreserve_pages(): hugepage_subpool_put_pages(1)
    + delta = chg - freed = 1 - 0 = 1
    + Because spool->max_hpages == -1, spool->used_hpages always = 0
    + spool->used_hpages < spool->min_hpages => 0 < 1 => true
        <<== subpool assumes 0 pages are in use, ignoring allocated Page 0
    + spool->rsv_hpages + delta <= spool->min_hpages => 0 + 1 <= 1 => true
    + spool->rsv_hpages += 1 => spool->rsv_hpages = 1
        <<== false reservation restored to subpool!
    + Return 0 (subpool absorbed the reservation)
7. Back in hugetlb_unreserve_pages(): hugetlb_acct_memory()
    + hugetlb_acct_memory(h, -0) => does nothing
    + h->resv_huge_pages = 1 (remains 1, not decremented)
    + Both reservations have ended (Page 0 allocated, Page 1 truncated),
      but h->resv_huge_pages remains stuck at 1
8. Later during unmounting:
    + subpool_is_free() checks spool->rsv_hpages == spool->min_hpages => 1
      == 1 => true
    + Because spool->rsv_hpages was falsely restored to 1, the subpool is
      erroneously considered completely free
    + hugetlb_acct_memory(spool->hstate, -spool->min_hpages) decrements
      h->resv_huge_pages by 1 (1 - 1 = 0), masking the leak on unmount
9. If the folio outlives the inode, when the folio is freed (Page 0),
   free_huge_folio() will read subpool from the folio and act on it =>
   use-after-free and then double free

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
Ackerley Tng (3):
      mm: hugetlb: Track used_hpages when getting/putting pages from subpool
      mm: hugetlb: Fix out_put_pages subpool reserve calculation
      mm: hugetlb: Fix subpool usage leak on allocation failure

 Documentation/mm/hugetlbfs_reserv.rst              |  17 +--
 .../translations/zh_CN/mm/hugetlbfs_reserv.rst     |  11 +-
 fs/hugetlbfs/inode.c                               |   8 +-
 include/linux/hugetlb.h                            |   4 +-
 mm/hugetlb.c                                       | 145 +++++++++++----------
 5 files changed, 88 insertions(+), 97 deletions(-)
---
base-commit: cee9395acd8043be0644b25c34bfa86623f2b935
change-id: 20260902-hugetlb-subpool-always-track-used-2624840f4c08

Best regards,
--
Ackerley Tng <ackerleytng@google.com>

