From: Ackerley Tng <ackerleytng@google.com>
Subject: [PATCH 0/4] Fix bugs on HugeTLB folio allocation failure paths
Date: Tue, 07 Jul 2026 13:46:07 -0700
Message-Id: <20260707-hugetlb-alloc-failure-fixes-v1-0-5bbd3a4b836d@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJBlTWoC/x3M0QpAMBSH8VfRuXZqVixeRS5m/uPUQhtS8u6Wy
 19ffQ8lREGirngo4pIk25pRlQW5xa4zWKZs0ko3yqiGl3PGEUa2IWyOvZVwRrCXG4md8cbUcFa
 3nvJhj/hDHvTD+35EVLoYbQAAAA==
X-Change-ID: 20260706-hugetlb-alloc-failure-fixes-c7f775eca29f
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Nhat Pham <nphamcs@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Peter Xu <peterx@redhat.com>, 
 Wupeng Ma <mawupeng1@huawei.com>, fvdl@google.com, rientjes@google.com
Cc: vannapurve@google.com, erdemaktas@google.com, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783457176; l=3948;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=3IWJjK6s97lq4LpNV8m481N4JvphBBCt49nzyXyP0oM=;
 b=lch27w8B/JNod6WTxLtbttJlGGBNwOHfR39Xka7cI9ItveylihcL8ihpENvPZdjg53+GflQqu
 5GAIHNHwj6cCs8lJZHLGxqOZsb39+g9S7bQNeh5o/Wo1lI9OpaRRu38
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When mem_cgroup_charge_hugetlb() fails (e.g. when hitting memcg limits),
the HugeTLB allocation path currently handles the errors incorrectly.

This series fixes 4 issues related to HugeTLB allocation failure paths.

Some of these issues were pointed out by Sashiko while I was working on
[1].

1. Fix subpool usage leak on allocation failure: (Sashiko pointed this out
   in [2])

   When alloc_hugetlb_folio() fails early (e.g. buddy allocation failure or
   hugetlb cgroup charging failure) and gbl_chg == 1, the error path skips
   restoring the page to the subpool, leaking the subpool's used_hpages
   counter. Fix this by calling hugepage_subpool_put_pages()
   unconditionally if map_chg is true.

(1.) above could technically be a separate patch series, but I'm relying on that
for fix (4.) below.

2. Fix folio refcount mismatch on memcg charge failure: (Sashiko pointed this
   out in [3])

   The error path in alloc_hugetlb_folio() calls free_huge_folio() directly
   on a folio with a refcount of 1 (set via folio_ref_unfreeze() earlier).
   This triggers VM_BUG_ON_FOLIO(folio_ref_count(folio), folio) if
   CONFIG_DEBUG_VM is enabled, and can corrupt allocator state otherwise.
   Fix this by using folio_put() instead of free_huge_folio() to correctly
   drop the refcount before freeing.

While fixing the above, the reproducer (I'll send these separately) was causing
an infinite loop during allocation, unveiling issue (3.).

3. Return -ENOSPC on memcg charge failure to prevent infinite loop:

   alloc_hugetlb_folio() propagates -ENOMEM on charge failure, which maps
   to VM_FAULT_OOM. Because HugeTLB physical allocations are high-order and
   use __GFP_RETRY_MAYFAIL, the OOM killer is bypassed. Returning
   VM_FAULT_OOM leaks to the #PF handler, which cannot make progress and
   retries the faulting instruction indefinitely. Fix this by returning
   -ENOSPC instead of -ENOMEM on charge failure, which maps to
   VM_FAULT_SIGBUS, terminating the process cleanly.

And while running the reproducer, I checked this routinely

    head /sys/kernel/mm/hugepages/hugepages-2048kB/*

and found that there was a resv_hugepages leakm, 1 per execution of the
reproducer, unveiling (4.) below.

4. Move memcg charge earlier to prevent reservation leak:

   When mem_cgroup_charge_hugetlb() fails, the error path historically
   bypassed vma_end_reservation(). Since the reservation had already been
   committed via vma_commit_reservation(), this left the reservation map in
   an inconsistent state, leaking resv_huge_pages when the process
   exited. Fix this by moving mem_cgroup_charge_hugetlb() earlier in
   alloc_hugetlb_folio(), before vma_commit_reservation() is called.

Testing:

+ libhugetlbfs tests pass
+ ./tools/testing/selftests/mm/ksft_hugetlb.sh passes

The series [1] has some changes that are dependent on these fixes, so I'll wait
for your reviews before continuing on [1].

Thank you!

[1] https://lore.kernel.org/all/20260702-hugetlb-open-up-v4-0-d53cefcccf34@google.com/T/
[2] https://sashiko.dev/#/patchset/20260518-hugetlb-open-up-v3-0-e14b302477f8%40google.com?part=5
[3] https://sashiko.dev/#/patchset/20260702-hugetlb-open-up-v4-0-d53cefcccf34%40google.com?part=6

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
Ackerley Tng (4):
      mm: hugetlb: Fix subpool usage leak on allocation failure
      mm: hugetlb: Fix folio refcount mismatch on memcg charge failure
      mm: hugetlb: Return -ENOSPC on memcg charge failure
      mm: hugetlb: Move memcg charge earlier to prevent reservation leak

 mm/hugetlb.c | 57 ++++++++++++++++++++++++++++++++++++---------------------
 1 file changed, 36 insertions(+), 21 deletions(-)
---
base-commit: 0e35b9b6ec0ffcc5e23cbdec09f5c622ad532b53
change-id: 20260706-hugetlb-alloc-failure-fixes-c7f775eca29f

Best regards,
--
Ackerley Tng <ackerleytng@google.com>

