From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Sat, 21 Mar 2026 23:35:50 +0530
Subject: [PATCH v6 5/6] mm/vmalloc: free unused pages on vrealloc() shrink
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260321-vmalloc-shrink-v6-5-062ca7b7ceb2@zohomail.in>
References: <20260321-vmalloc-shrink-v6-0-062ca7b7ceb2@zohomail.in>
In-Reply-To: <20260321-vmalloc-shrink-v6-0-062ca7b7ceb2@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774116351; l=3733;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=XcuDrqFqC2b82xJlkUNy90ghNCbi8jDDIdt9qyKsYoA=;
 b=n6RzlbrUuUJWWVesQJaNtsmVnVtThnwM2RLFCf6wjivYwpMyZX9PivawyFUS9wWW8zOyBDLmf
 OSHUB2TTzYPD6fRljbtUA0Hu0WnpVStA5qCI4m4kRMUKPt8fIhPk8xZ
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
freeing would require splitting. Allocations with VM_FLUSH_RESET_PERMS
are also skipped, as their direct-map permissions must be reset before
pages are returned to the page allocator, which is handled by
vm_reset_perms() during vfree().

Additionally, allocations with VM_USERMAP are skipped because
remap_vmalloc_range_partial() validates mapping requests against the
unchanged vm->size; freeing tail pages would cause vmalloc_to_page()
to return NULL for the unmapped range.

To protect concurrent /proc/vmallocinfo readers, the shrink path
updates vm->nr_pages with WRITE_ONCE() before freeing the pages.

Finally, we notify kmemleak of the reduced allocation size using
kmemleak_free_part() to prevent the kmemleak scanner from faulting on
the newly unmapped virtual addresses.

The virtual address reservation (vm->size / vmap_area) is intentionally
kept unchanged, preserving the address for potential future grow-in-place
support.

Suggested-by: Danilo Krummrich <dakr@kernel.org>
Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 mm/vmalloc.c | 42 ++++++++++++++++++++++++++++++++++++++----
 1 file changed, 38 insertions(+), 4 deletions(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index 7658fdc087d2..8b8752fc10e9 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -4345,14 +4345,48 @@ void *vrealloc_node_align_noprof(const void *p, size_t size, unsigned long align
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
+		/*
+		 * Free tail pages when shrink crosses a page boundary.
+		 *
+		 * Skip huge page allocations (page_order > 0) as partial
+		 * freeing would require splitting.
+		 *
+		 * Skip VM_FLUSH_RESET_PERMS, as direct-map permissions must
+		 * be reset before pages are returned to the allocator.
+		 *
+		 * Skip VM_USERMAP, as remap_vmalloc_range_partial() validates
+		 * mapping requests against the unchanged vm->size; freeing
+		 * tail pages would cause vmalloc_to_page() to return NULL for
+		 * the unmapped range.
+		 */
+		if (new_nr_pages < vm->nr_pages && !vm_area_page_order(vm) &&
+		    !(vm->flags & (VM_FLUSH_RESET_PERMS | VM_USERMAP))) {
+			unsigned long addr = (unsigned long)p;
+			unsigned int old_nr_pages = vm->nr_pages;
+
+			/* Notify kmemleak of the reduced allocation size before unmapping. */
+			kmemleak_free_part(
+				(void *)addr + (new_nr_pages << PAGE_SHIFT),
+				(old_nr_pages - new_nr_pages) << PAGE_SHIFT);
+
+			vunmap_range(addr + (new_nr_pages << PAGE_SHIFT),
+				     addr + (old_nr_pages << PAGE_SHIFT));
+
+			/*
+			 * Update nr_pages before freeing pages to prevent
+			 * a concurrent reader (e.g. show_numa_info via
+			 * /proc/vmallocinfo) from accessing NULL entries.
+			 */
+			WRITE_ONCE(vm->nr_pages, new_nr_pages);
+			vm_area_free_pages(vm, new_nr_pages, old_nr_pages);
+		}
 		vm->requested_size = size;
 		kasan_vrealloc(p, old_size, size);
 		return (void *)p;

-- 
2.43.0

