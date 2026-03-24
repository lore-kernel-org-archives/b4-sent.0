From: Shivam Kalra <shivamkalra98@zohomail.in>
Subject: [PATCH v7 0/6] mm/vmalloc: free unused pages on vrealloc() shrink
Date: Tue, 24 Mar 2026 15:30:25 +0530
Message-Id: <20260324-vmalloc-shrink-v7-0-c0e62b8e5d83@zohomail.in>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALlgwmkC/3XOy07DMBCF4VepvMZoPPEl6Yr3QCx8JRZpjGxkA
 VXeHbcrI8PyH+l8mispPkdfyPl0JdnXWGLaW6iHE7Gr3l89ja41QUAJEyCtF71tydKy5ri/UeA
 Gg5bzrBknbfSefYifd/D5pfUay0fKX3e/stv1X6oyCpRL50PgUhjln77Tmi46bo9xJzesYg/wA
 cAG4GxxYU4CAxiBqQeWAZgaIMQCwc3OozcjwDuAjR/wBljWpmCM4EKMgOgBNQCiAcYEEwS3AuU
 fgOwAZAMgGwASrVZGWW/wN3Acxw+w5wC78wEAAA==
X-Change-ID: 20260302-vmalloc-shrink-04b2fa688a14
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774346430; l=5260;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=e6dIGEo7f/+1NfLq6ugPJOKFJUxC8pwekRAu/N6BZPo=;
 b=X35WFyaifuy2TYWC/Ep7XyQSNK115tVYS3zE/2935HlypgBLoNCPhYZqxN2Jr9l/AB0ECCEK9
 sBFLCKJoztMCWbHm40vABWXlFaKlagOqY2kdhJDP6YOk7np9fuF33zk
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
- Patch 2: Fixes the grow-in-place path to check vm->nr_pages instead
  of get_vm_area_size(), which reflects the virtual reservation and does
  not change on shrink. This is a prerequisite for shrinking.
- Patch 3: Zeros newly exposed memory on vrealloc() grow if __GFP_ZERO
  is requested, preventing stale data leaks from previously shrunk regions.
- Patch 4: Protects /proc/vmallocinfo readers with READ_ONCE() to safely
  handle concurrent decreases to vm->nr_pages and NULL page pointers.
- Patch 5: Uses the helper to free tail pages when vrealloc() shrinks
  across a page boundary. Skips huge page allocations, VM_FLUSH_RESET_PERMS,
  and VM_USERMAP. Updates Kmemleak tracking of the allocation.
- Patch 6: Adds a vrealloc test case to lib/test_vmalloc that exercises
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

Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
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

---
Shivam Kalra (6):
      mm/vmalloc: extract vm_area_free_pages() helper from vfree()
      mm/vmalloc: fix vrealloc() grow-in-place check
      mm/vmalloc: zero newly exposed memory on vrealloc() grow
      mm/vmalloc: use READ_ONCE() for vmalloc nr_pages status readers
      mm/vmalloc: free unused pages on vrealloc() shrink
      lib/test_vmalloc: add vrealloc test case

 lib/test_vmalloc.c |  62 +++++++++++++++++++++++
 mm/vmalloc.c       | 143 ++++++++++++++++++++++++++++++++++++++++++-----------
 2 files changed, 175 insertions(+), 30 deletions(-)
---
base-commit: 02b045682c74be16c7d1501563f02b0e92d42cdb
change-id: 20260302-vmalloc-shrink-04b2fa688a14

Best regards,
-- 
Shivam Kalra <shivamkalra98@zohomail.in>

