From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Mon, 02 Mar 2026 19:27:12 +0530
Subject: [PATCH 2/2] mm/vmalloc: free unused pages on vrealloc() shrink
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260302-vmalloc-shrink-v1-2-46deff465b7e@zohomail.in>
References: <20260302-vmalloc-shrink-v1-0-46deff465b7e@zohomail.in>
In-Reply-To: <20260302-vmalloc-shrink-v1-0-46deff465b7e@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772459853; l=2712;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=1erzrKM7o2q1ZdLZf3ysmYhvkVLpMZRusvoIpirIWHk=;
 b=s8dCbDyuolYo1EwgvZlaLveGaiqIPpn8jL2D/pue+DAQCoZWL5qLQQu2bmpearqaj1v9tgV41
 Z9VRutTIjuiBZHd/CR4Mhuj2rKwBIB21N2vcFieESoQCCZb6iesAsmH
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When vrealloc() shrinks an allocation and the new size crosses a page
boundary, unmap and free the tail pages that are no longer needed. This
reclaims physical memory that was previously wasted for the lifetime
of the allocation.

The heuristic is simple: always free when at least one full page becomes
unused. Huge page allocations (page_order > 0) are skipped, as partial
freeing would require splitting.

The virtual address reservation (vm->size / vmap_area) is intentionally
kept unchanged, preserving the address for potential future grow-in-place
support.

Fix the grow-in-place check to compare against vm->nr_pages rather than
get_vm_area_size(), since the latter reflects the virtual reservation
which does not shrink. Without this fix, a grow after shrink would
access freed pages.

Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 mm/vmalloc.c | 25 ++++++++++++++++++++-----
 1 file changed, 20 insertions(+), 5 deletions(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index 54e76a47e995..7a4c59422638 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -4327,14 +4327,29 @@ void *vrealloc_node_align_noprof(const void *p, size_t size, unsigned long align
 			goto need_realloc;
 	}
 
-	/*
-	 * TODO: Shrink the vm_area, i.e. unmap and free unused pages. What
-	 * would be a good heuristic for when to shrink the vm_area?
-	 */
 	if (size <= old_size) {
+		unsigned int new_nr_pages = PAGE_ALIGN(size) >> PAGE_SHIFT;
+
 		/* Zero out "freed" memory, potentially for future realloc. */
 		if (want_init_on_free() || want_init_on_alloc(flags))
 			memset((void *)p + size, 0, old_size - size);
+
+		/* Free tail pages when shrink crosses a page boundary. */
+		if (new_nr_pages < vm->nr_pages &&
+		    !vm_area_page_order(vm)) {
+			unsigned long addr = (unsigned long)p;
+
+			vunmap_range(addr + (new_nr_pages << PAGE_SHIFT),
+				     addr + (vm->nr_pages << PAGE_SHIFT));
+
+			kasan_poison_vmalloc(
+				(void *)(addr + (new_nr_pages << PAGE_SHIFT)),
+				(vm->nr_pages - new_nr_pages) << PAGE_SHIFT);
+
+			vmalloc_free_pages(vm, new_nr_pages, vm->nr_pages);
+			vm->nr_pages = new_nr_pages;
+		}
+
 		vm->requested_size = size;
 		kasan_poison_vmalloc(p + size, old_size - size);
 		return (void *)p;
@@ -4343,7 +4358,7 @@ void *vrealloc_node_align_noprof(const void *p, size_t size, unsigned long align
 	/*
 	 * We already have the bytes available in the allocation; use them.
 	 */
-	if (size <= alloced_size) {
+	if (size <= (size_t)vm->nr_pages << PAGE_SHIFT) {
 		kasan_unpoison_vmalloc(p + old_size, size - old_size,
 				       KASAN_VMALLOC_PROT_NORMAL |
 				       KASAN_VMALLOC_VM_ALLOC |

-- 
2.43.0

