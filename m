From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Sat, 14 Mar 2026 14:34:14 +0530
Subject: [PATCH v4 2/3] mm/vmalloc: free unused pages on vrealloc() shrink
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260314-vmalloc-shrink-v4-2-c1e2e0bb5455@zohomail.in>
References: <20260314-vmalloc-shrink-v4-0-c1e2e0bb5455@zohomail.in>
In-Reply-To: <20260314-vmalloc-shrink-v4-0-c1e2e0bb5455@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773479164; l=2543;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=qiLrg/KiMgMQgQ06tgY/qjWWfVqF7Moa3eb5azEQPMU=;
 b=JSgIl8t091y/VKSsQI5DHU6yX/zoZKbxLX6f33+kCAYEstK2d+ExBt3JJ42ubUxhPL/afLIXy
 9RqAAyIaL4iDI2wyTUIBa/shktn0Zf1G93hgQP/weRS+R2Zs2taVyZQ
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
 mm/vmalloc.c | 19 ++++++++++++++-----
 1 file changed, 14 insertions(+), 5 deletions(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index b29bf58c0e3f..2c455f2038f6 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -4345,14 +4345,23 @@ void *vrealloc_node_align_noprof(const void *p, size_t size, unsigned long align
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
+		if (new_nr_pages < vm->nr_pages && !vm_area_page_order(vm)) {
+			unsigned long addr = (unsigned long)p;
+
+			vunmap_range(addr + (new_nr_pages << PAGE_SHIFT),
+				     addr + (vm->nr_pages << PAGE_SHIFT));
+
+			vm_area_free_pages(vm, new_nr_pages, vm->nr_pages);
+			vm->nr_pages = new_nr_pages;
+		}
 		vm->requested_size = size;
 		kasan_vrealloc(p, old_size, size);
 		return (void *)p;
@@ -4361,7 +4370,7 @@ void *vrealloc_node_align_noprof(const void *p, size_t size, unsigned long align
 	/*
 	 * We already have the bytes available in the allocation; use them.
 	 */
-	if (size <= alloced_size) {
+	if (size <= (size_t)vm->nr_pages << PAGE_SHIFT) {
 		/*
 		 * No need to zero memory here, as unused memory will have
 		 * already been zeroed at initial allocation time or during

-- 
2.43.0

