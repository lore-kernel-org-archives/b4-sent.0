From: Shivam Kalra <shivamkalra98@zohomail.in>
Subject: [PATCH v14 0/5] mm/vmalloc: free unused pages on vrealloc() shrink
Date: Tue, 19 May 2026 17:42:13 +0530
Message-Id: <20260519-vmalloc-shrink-v14-0-70b96ee3e9c9@zohomail.in>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJ1TDGoC/3XTy07kMBAF0F9BWRNUVXb5wYr/GLHwc9qi6aBkF
 DGD+t9x2GBUPUtb8rFv6fpj2srayjY93n1Ma9nb1pZLX6C+v5vSKVx+l7nlvjERkAEFNO+v4Xx
 e0ryd1nZ5mUFHqsE4F1BP/dDbWmp7/xJ/Pff1qW1/lvXv1wU7Hrv/pXacYdYml1q14WjL07/lt
 LyGdn5ol+nAdhoBLQDqALlEHrMBBJCAGgEvANUBZg81u1yoRAnoAUD5At2BhP0oxMiaWQI8AlY
 A3IEYa6ysE5O5AZgBIBSA6QAYSsFGm0okCdgRkBHsEQGKoegKZ6ck4EZARnAHkExkC+xLthLw3
 4AGGcEfM6jsco3e2+wkgDAKMgP2GcxKsWWPhnMNN4ihjJpAEkcbU8gOIoBjdYugkXCSOPqoErr
 k0fY24Q1iKCSjHAUejTRa9d+QyNrgfxLX6/UTgm1iDcMDAAA=
X-Change-ID: 20260302-vmalloc-shrink-04b2fa688a14
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779192749; l=7065;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=txJm4HOKhxmJ2vzYiuNeV73AcFhE33k97zNtzKsMCRE=;
 b=2nlUVHqf8OKtcJiFfsuyHHS+Csr0Tv8//UdGLcQNk574bX5j9U90+wEfRmSlTyHj0F87yaiat
 sZzdl7yYrulCzQOME+2leQpVS2tqFr9aQZ2GaV5oy5hg+Oh2Z9WeItO
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series implements the TODO in vrealloc() to unmap and free unused
pages when shrinking across a page boundary.

Problem:
When vrealloc() shrinks an allocation, it updates bookkeeping
(requested_size, KASAN shadow) but does not free the underlying physical
pages. This wastes memory for the lifetime of the allocation.

Solution:
- Patch 1: Extracts a vm_area_free_pages(vm, start_idx, end_idx) helper
  from vfree() that frees a range of pages with memcg and nr_vmalloc_pages
  accounting. Freed page pointers are set to NULL to prevent stale
  references.
- Patch 2: Update the grow-in-place check in vrealloc() to compare the
  requested size against the actual physical page count (vm->nr_pages) 
  rather than the virtual area sizes. This is a prerequisite for shrinking.
- Patch 3: For VM_ALLOC areas in vread_iter(), derive the vm area size 
  from vm->nr_pages rather than get_vm_area_size(), which would 
  overestimate the mapped range after a shrink. Other mapping types
  (vmap, ioremap) don't set nr_pages and keep using get_vm_area_size().
- Patch 4: Uses the helper to free tail pages when vrealloc() shrinks
  across a page boundary. 
- Patch 5: Adds a vrealloc test case to lib/test_vmalloc that exercises
  grow-realloc, shrink-across-boundary, shrink-within-page, and
  grow-in-place paths.

The virtual address reservation is kept intact to preserve the range
for potential future grow-in-place support.
A concrete user is the Rust binder driver's KVVec::shrink_to [1], which
performs explicit vrealloc() shrinks for memory reclamation.

Tested:
- KASAN KUnit (vmalloc_oob passes)
- lib/test_vmalloc stress tests (3/3, 1M iterations each)
- checkpatch, sparse, W=1, allmodconfig, coccicheck clean

[1] https://lore.kernel.org/all/20260216-binder-shrink-vec-v3-v6-0-ece8e8593e53@zohomail.in/

Suggested-by: Danilo Krummrich <dakr@kernel.org>
Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
Changes in v14:
- Scope nr_pages usage in vread_iter() to VM_ALLOC areas only;
  vmap() areas don't initialize nr_pages. (Sashiko, Uladzislau Rezki)
- Link to v13: https://patch.msgid.link/20260511-vmalloc-shrink-v13-0-643b7ec277a9@zohomail.in

Changes in v13:
- Collect all r-b tags
- Resubmit for Review. 
- Link to v12: https://lore.kernel.org/r/20260428-vmalloc-shrink-v12-0-3c18c9172eb1@zohomail.in

Changes in v12:
- Rewrite vm_area_free_pages() to use free_pages_bulk() 
  following the upstream vfree() refactoring.(Andrew)
- Drop Reviewed-by tags from Patch 1 due to the rewrite
- Rebase to latest mm-new
- Link to v11: https://lore.kernel.org/r/20260420-vmalloc-shrink-v11-0-cad80b00853a@zohomail.in

Changes in v11:
- Prepare vread_iter() to use vm->nr_pages instead of
  get_vm_area_size() (Uladzislau Rezki, Sashiko)
- Drop (size_t) cast from nr_pages << PAGE_SHIFT (Uladzislau Rezki)
- Link to v10: https://lore.kernel.org/r/20260404-vmalloc-shrink-v10-0-335759165dfa@zohomail.in

Changes in v10:
- Reorder vm->nr_pages to the beginning (Alice Ryhl)
- Link to v9: https://lore.kernel.org/r/20260401-vmalloc-shrink-v9-0-bf58dfb997d8@zohomail.in

Changes in v9:
- Remove READ_ONCE, WRITE_ONCE and drop commit
  about show_numa_info. (Uladzislau Rezki)
- Update the commit message in Patch 2. (Alice Ryhl)
- Remove zero newly exposed memory commit.
- Link to v8: https://lore.kernel.org/r/20260327-vmalloc-shrink-v8-0-cc6b57059ed7@zohomail.in

Changes in v8:
- Strip the KASAN tag from the pointer before addr_to_node()
  to avoid acquiring the wrong node lock (Sashiko).
- Rebase to latest mm-new.
- Link to v7: https://lore.kernel.org/r/20260324-vmalloc-shrink-v7-0-c0e62b8e5d83@zohomail.in

Changes in v7:
- Fix NULL pointer dereference in shrink path (Sashiko)
- Acquire vn->busy.lock when updating vm->nr_pages to synchronize 
  with concurrent readers (Uladzislau Rezki)
- Use READ_ONCE in vmalloc_dump_obj (Sashiko)
- Skip shrink path on GFP_NIO or GFP_NOFS. (Sashiko)
- Fix Overflow issue for large allocations. (Sashiko)
- Use vrealloc instead of vmalloc in vrealloc test.  
- Link to v6: https://lore.kernel.org/r/20260321-vmalloc-shrink-v6-0-062ca7b7ceb2@zohomail.in

Changes in v6:
- Fix VM_USERMAP crash by explicitly bypassing early in the shrink path if the flag is set.(Sashiko)
- Fix Kmemleak scanner panic by calling kmemleak_free_part() to update tracking on shrink.(Sashiko)
- Fix /proc/vmallocinfo race condition by protecting vm->nr_pages access with 
  READ_ONCE()/WRITE_ONCE() for concurrent readers.(Sashiko)
- Fix stale data leak on grow-after-shrink by enforcing mandatory zeroing of the newly exposed memory.(Sashiko)
- Fix memory leaks in vrealloc_test() by using a temporary pointer to preserve and 
  free the original allocation upon failure.(Sashiko)
- Rename vmalloc_free_pages parameters from start/end to start_idx/end_idx for better clarity.(Uladzislau Rezki)
- Link to v5: https://lore.kernel.org/r/20260317-vmalloc-shrink-v5-0-bbfbf54c5265@zohomail.in
- Link to Sashiko: https://sashiko.dev/#/patchset/20260317-vmalloc-shrink-v5-0-bbfbf54c5265%40zohomail.in

Changes in v5:
- Skip vrealloc shrink for VM_FLUSH_RESET_PERMS (Uladzislau Rezki)
- Link to v4: https://lore.kernel.org/r/20260314-vmalloc-shrink-v4-0-c1e2e0bb5455@zohomail.in

Changes in v4:
- Rename vmalloc_free_pages() to vm_area_free_pages() to align with
  vm_area_alloc_pages() (Uladzislau Rezki)
- NULL out freed vm->pages[] entries to prevent stale pointers (Alice Ryhl)
- Remove redundant if (vm->nr_pages) guard in vfree() (Uladzislau Rezki)
- Add vrealloc test case to lib/test_vmalloc (new patch 3/3)
- Link to v3: https://lore.kernel.org/r/20260309-vmalloc-shrink-v3-0-5590fd8de2eb@zohomail.in

Changes in v3:
- Restore the comment.
- Rebase to the latest mm-new 
- Link to v2: https://lore.kernel.org/r/20260304-vmalloc-shrink-v2-0-28c291d60100@zohomail.in

Changes in v2:
- Updated the base-commit to mm-new
- Fix conflicts after rebase
- Ran `clang-format` on the changes made
- Use a single `kasan_vrealloc` (Alice Ryhl)
- Link to v1: https://lore.kernel.org/r/20260302-vmalloc-shrink-v1-0-46deff465b7e@zohomail.in

To: Andrew Morton <akpm@linux-foundation.org>
To: Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org
Cc: linux-kernel@vger.kernel.org

---
Shivam Kalra (5):
      mm/vmalloc: extract vm_area_free_pages() helper from vfree()
      mm/vmalloc: use physical page count for vrealloc() grow-in-place check
      mm/vmalloc: use physical page count in vread_iter() for VM_ALLOC areas
      mm/vmalloc: free unused pages on vrealloc() shrink
      lib/test_vmalloc: add vrealloc test case

 lib/test_vmalloc.c |  62 ++++++++++++++++++++++++++++++
 mm/vmalloc.c       | 111 ++++++++++++++++++++++++++++++++++++++++++++++-------
 2 files changed, 160 insertions(+), 13 deletions(-)
---
base-commit: a277a07d19bffcad38dea57bc234d0810a328657
change-id: 20260302-vmalloc-shrink-04b2fa688a14

Best regards,
--  
Shivam Kalra <shivamkalra98@zohomail.in>

