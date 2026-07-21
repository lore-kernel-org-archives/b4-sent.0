From: Ackerley Tng <ackerleytng@google.com>
Subject: [PATCH v3 00/13] Fix bugs on HugeTLB folio allocation failure
 paths
Date: Mon, 20 Jul 2026 17:25:03 -0700
Message-Id: <20260720-hugetlb-alloc-failure-fixes-v3-0-7d2a169aa9ee@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAF+8XmoC/33OSw7CIBCA4asY1o6h9EF15T2MC6ADJcFioCWap
 neXNjHRTZf/TPLNzCRisBjJ5TCTgMlG64cc5fFAVC8Gg2C73IRR1lBOG+gng6OTIJzzCrSwbgo
 I2r4wguKa8xqVYGdNsvAMuC0ycLvn7m0cfXhvx1KxTr8u33VTARRqKbtSVLItm+5qvDcOT8o/y
 Aon9ou1+xjLWP6UcSVl1TD5hy3L8gH2imHdFAEAAA==
X-Change-ID: 20260706-hugetlb-alloc-failure-fixes-c7f775eca29f
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Nhat Pham <nphamcs@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Peter Xu <peterx@redhat.com>, 
 Wupeng Ma <mawupeng1@huawei.com>, fvdl@google.com, rientjes@google.com, 
 jthoughton@google.com, Mike Kravetz <mike.kravetz@oracle.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>
Cc: vannapurve@google.com, erdemaktas@google.com, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 Ackerley Tng <ackerleytng@google.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784602387; l=7782;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=/b9ba+DuL1XbYBDfD0yTQkd8n1jGFBevhBO73RcsrOw=;
 b=u+DAtxRvaQBp3wEDBRcruWX7yr+brSFQ3qMVQftTlM5gUEZdbUYZ6FNBsCubXBh8z34NyIOJe
 yDJ2EeTPmasDKEYWVrtqEz4Wg1LWCaDklIVDyLrG8h2NlcC3WGP4aQw
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes a few bugs on HugeTLB folio allocation failure paths.

Some of these issues were pointed out by Sashiko while I was working on
[1], and others were revealed while fixing the original issues.

1. subpool usage leak on allocation failure (Sashiko pointed this out
   in [2])

   When alloc_hugetlb_folio() fails early (e.g. buddy allocation failure or
   hugetlb cgroup charging failure) and gbl_chg == 1, the error path skips
   restoring the page to the subpool, leaking the subpool's used_hpages
   counter. Fix this by calling hugepage_subpool_put_pages()
   unconditionally if map_chg is true.

2. Folio refcount mismatch on memcg charge failure leading to
   VM_BUG_ON_FOLIO() (Sashiko pointed this out in [3])

   The error path in alloc_hugetlb_folio() calls free_huge_folio() directly
   on a folio with a refcount of 1 (set via folio_ref_unfreeze() earlier).
   This triggers VM_BUG_ON_FOLIO(folio_ref_count(folio), folio) if
   CONFIG_DEBUG_VM is enabled, and can corrupt allocator state otherwise.
   Fix this by using folio_put() instead of free_huge_folio() to correctly
   drop the refcount before freeing.

3. Returning -ENOMEM on memcg charge failure causes infinite loop

   alloc_hugetlb_folio() propagates -ENOMEM on charge failure, which maps
   to VM_FAULT_OOM. Because HugeTLB physical allocations are high-order and
   use __GFP_RETRY_MAYFAIL, the OOM killer is bypassed. Returning
   VM_FAULT_OOM leaks to the #PF handler, which cannot make progress and
   retries the faulting instruction indefinitely. Fix this by returning
   -ENOSPC instead of -ENOMEM on charge failure, which maps to
   VM_FAULT_SIGBUS, terminating the process cleanly.

4. vma reservation leak on mem_cgroup_charge_hugetlb() failure

   When mem_cgroup_charge_hugetlb() fails, the error path historically
   bypassed vma_end_reservation(). Since the reservation had already been
   committed via vma_commit_reservation(), this left the reservation map in
   an inconsistent state, leaking resv_huge_pages when the process
   exited. Fix this by moving mem_cgroup_charge_hugetlb() earlier in
   alloc_hugetlb_folio(), before vma_commit_reservation() is called.

Main changes in this patch series

1. subpool page tracking

The subpool now tracks every page allocated via
the subpool through used_hpages, regardless of whether min_hpages or
max_hpages is requested by the user.

When min_hpages is set, rsv_hpages is initialized to be equal to
min_hpages. As reserved pages are used, the count is transferred from
rsv_hpages to used_hpages. When reserved pages run out, as long as
max_hpages is not requested or not yet met, used_hpages continues to be
incremented. The following invariant holds true while used_hpages <=
min_hpages:

  used_hpages + rsv_hpages = min_hpages

when used_hpages exceeds min_hpages, rsv_hpages must always be 0.

With this, pages can and must always be returned to the subpool if there's
some reservation or allocation failure after getting a page from the
subpool. One thing I missed in v2 was in processing the returned page. In
v2, the number of pages returned was compared to min_hpages, ignoring
used_hpages if it exists. v3 limits the number of pages returned to
min_hpages - used_hpages, upholding the invariant above.

2. (Re-)introduction of the try-commit-cancel protocol for memcg charging.

In v2, I took the shortcut where I moved mem_cgroup_charge_hugetlb() up
above committing vma reservations, and jumped to subpool cleanup when the
charging failed. With that, Sashiko pointed out that there are still issues
with subpool tracking.

In [4] I thought the issue was that gbl_chg == 0 (I flipped the condition
in [4], omg) doesn't always mean a reservation was actually used, but after
digging more, that doesn't seem to be true, since if gbl_chg == 0,
restore_reserve is set on the folio, and free_huge_folio() would have done
a h->resv_huge_pages++.

In my opinion, calling free_huge_folio() in the middle of the cleanup does
too much, and I think the cleaner approach would be to do all the charging
symmetrically, so that the subpool cleanup will also be symmetric
and (hopefully) easier to understand.

v3 is posted with reproducers (not meant to be merged) and some refactoring
of subpool-related code, which helped me check that the subpool stuff is
working. I think the subpool-related refactoring and tests would be good to
merge, but perhaps in another patch series? The refactoring was heavily
AI-driven and should be considered RFC. Would like to have your feedback on
that refactoring too.

Testing:

+ libhugetlbfs tests pass
+ ./tools/testing/selftests/mm/ksft_hugetlb.sh passes
+ Reproducers all pass

v1: https://lore.kernel.org/r/20260707-hugetlb-alloc-failure-fixes-v1-0-5bbd3a4b836d@google.com
v2: https://lore.kernel.org/r/20260708-hugetlb-alloc-failure-fixes-v2-0-c7f27cbb462b@google.com

The series [1] has some changes that are dependent on these fixes, so I'll wait
for your reviews before continuing on [1].

Thank you!

[1] https://lore.kernel.org/all/20260702-hugetlb-open-up-v4-0-d53cefcccf34@google.com/T/
[2] https://sashiko.dev/#/patchset/20260518-hugetlb-open-up-v3-0-e14b302477f8%40google.com?part=5
[3] https://sashiko.dev/#/patchset/20260702-hugetlb-open-up-v4-0-d53cefcccf34%40google.com?part=6
[4] https://lore.kernel.org/all/CAEvNRgGN0HSJ2iLSDD2haSKOxifa-uhkO9Hwossh0+Q_d9fzOw@mail.gmail.com/

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
Ackerley Tng (13):
      mm: hugetlb: Track used_hpages when getting/putting pages from subpool
      mm: hugetlb: Return -ENOSPC on memcg charge failure
      mm: hugetlb: Use try-commit-cancel protocol for memcg charge of folios
      mm: hugetlb: Remove unused mem_cgroup_charge_hugetlb function
      mm: hugetlb: Fix subpool usage leak on allocation failure
      WIP: mm: hugetlb: Move subpool functions to hugetlb_subpool.c
      WIP: fs: hugetlbfs: Refactor subpool getters and integrate with hugetlb_subpool API
      WIP: mm: hugetlb: Make struct hugepage_subpool private to hugetlb_subpool.c
      WIP: tools: testing: Add userspace unit tests for HugeTLB subpools
      WIP: Reproducer for allocation failure due to cgroup v2 memory limits
      WIP: Reproducer for subpool usage leak
      WIP: Reproducer for false restoration on shared HugeTLB mappings
      WIP: Reproducer for out_put_pages subpool reserve leakage

 cgroup_v2_allocation_failure.c               | 160 +++++++++++
 fs/hugetlbfs/inode.c                         |  25 +-
 hugetlb_reserve_pages_out_put_pages.c        |  49 ++++
 hugetlb_reserve_pages_out_put_pages.sh       | 153 ++++++++++
 include/linux/hugetlb.h                      |  17 +-
 include/linux/memcontrol.h                   |  30 +-
 mm/Makefile                                  |   2 +-
 mm/hugetlb.c                                 | 244 ++++------------
 mm/hugetlb_subpool.c                         | 223 +++++++++++++++
 mm/hugetlb_subpool.h                         |  21 ++
 mm/memcontrol.c                              | 116 ++++++--
 subpool_leak_max_size.sh                     |  71 +++++
 subpool_shared_leak.c                        |  29 ++
 subpool_shared_leak.sh                       |  86 ++++++
 tools/testing/hugetlb_subpool/.gitignore     |   1 +
 tools/testing/hugetlb_subpool/Makefile       |  18 ++
 tools/testing/hugetlb_subpool/test_subpool.c | 400 +++++++++++++++++++++++++++
 17 files changed, 1399 insertions(+), 246 deletions(-)
---
base-commit: b95f03f04d475aa6719d15a636ddf32222d55657
change-id: 20260706-hugetlb-alloc-failure-fixes-c7f775eca29f

Best regards,
--
Ackerley Tng <ackerleytng@google.com>

