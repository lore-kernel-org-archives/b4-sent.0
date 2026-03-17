From: Shivam Kalra <shivamkalra98@zohomail.in>
Subject: [PATCH v5 0/3] mm/vmalloc: free unused pages on vrealloc() shrink
Date: Tue, 17 Mar 2026 13:47:32 +0530
Message-Id: <20260317-vmalloc-shrink-v5-0-bbfbf54c5265@zohomail.in>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABwOuWkC/3XOwU7EIBDG8VfZcBYzTAHbPfkexgOUwU7sFgOGq
 Ju+u+yeaojH/yTfL3MVhTJTEefTVWSqXDhtLczDScyL295IcmgtENDCACjrxa1rmmVZMm/vErT
 H6Ow4OqVFG31kivx1B19eWy9cPlP+vvtV3a7/UlVJkNoGilFb45/o+Sct6eJ4feRN3LCKR0B3A
 DYAxxknFSwogB4YjsDUAUMDjJkghjEQku8BfQBU/4FuwKzaFLw32pi/wL7vvydWuwxxAQAA
X-Change-ID: 20260302-vmalloc-shrink-04b2fa688a14
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773735454; l=3389;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=RisNgPVkJ2DmLymS1Pnu8hBXRm1dphIY+WY3EUkz0dk=;
 b=vq8rG2UAkpSPEXrOKqhYAZXPkT4gBEYlpeIhxkGE+9c/VjX8AxjbATOPskhzKea5U6KtWKBwo
 FXHzsHuk6hCAw/2Pa0y968p1hcZpT2I/DAXRTtmtwk4sJf340RJY6aY
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
- Patch 1: Extracts a vm_area_free_pages(vm, start, end) helper from
  vfree() that frees a range of pages with memcg and nr_vmalloc_pages
  accounting. Freed page pointers are set to NULL to prevent stale
  references.
- Patch 2: Uses the helper to free tail pages when vrealloc() shrinks
  across a page boundary. Skips huge page allocations (page_order > 0)
  since compound pages cannot be partially freed. Allocations with 
  VM_FLUSH_RESET_PERMS are also skipped. Also fixes the grow-in-place
  path to check vm->nr_pages instead of get_vm_area_size(), which 
  reflects the virtual reservation and does not change on shrink.
- Patch 3: Adds a vrealloc test case to lib/test_vmalloc that exercises
  grow-realloc, shrink-across-boundary, shrink-within-page, and
  grow-in-place paths with data integrity validation.

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
Shivam Kalra (3):
      mm/vmalloc: extract vm_area_free_pages() helper from vfree()
      mm/vmalloc: free unused pages on vrealloc() shrink
      lib/test_vmalloc: add vrealloc test case

 lib/test_vmalloc.c | 52 ++++++++++++++++++++++++++++++++++++++++++
 mm/vmalloc.c       | 67 ++++++++++++++++++++++++++++++++++++++----------------
 2 files changed, 100 insertions(+), 19 deletions(-)
---
base-commit: 7d47a508dfdc335c107fb00b4d9ef46488281a52
change-id: 20260302-vmalloc-shrink-04b2fa688a14

Best regards,
-- 
Shivam Kalra <shivamkalra98@zohomail.in>

