From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Mon, 02 Mar 2026 19:27:11 +0530
Subject: [PATCH 1/2] mm/vmalloc: extract vmalloc_free_pages() helper from
 vfree()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260302-vmalloc-shrink-v1-1-46deff465b7e@zohomail.in>
References: <20260302-vmalloc-shrink-v1-0-46deff465b7e@zohomail.in>
In-Reply-To: <20260302-vmalloc-shrink-v1-0-46deff465b7e@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772459853; l=2751;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=0JaRY63WuGpryYiSzUoBhSyJJKl7JuNe9P31f6tdjtc=;
 b=hWTwNZvKyvuYQpyWQFxgnjJGMxbWDPnuQ7m7FkLTfXN+BeWu1g4CHLZFsNnvu45DMMwYVa3qT
 pWbsHO4Vr70APHUiO3ECVzEapWycFN5r8gTidioHz35BeGbPDDGK3E2
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extract the page-freeing loop, memcg accounting, and nr_vmalloc_pages
update from vfree() into a reusable vmalloc_free_pages() helper. The
helper operates on a range [start, end) of pages from a vm_struct,
making it suitable for both full free (vfree) and partial free (upcoming
vrealloc shrink).

No functional change.

Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 mm/vmalloc.c | 48 +++++++++++++++++++++++++++++++-----------------
 1 file changed, 31 insertions(+), 17 deletions(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index 628f96e83b118..54e76a47e9957 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -3409,6 +3409,35 @@ void vfree_atomic(const void *addr)
 		schedule_work(&p->wq);
 }
 
+/*
+ * vmalloc_free_pages - free a range of pages from a vmalloc allocation
+ * @vm: the vm_struct containing the pages
+ * @start: first page index to free (inclusive)
+ * @end: last page index to free (exclusive)
+ *
+ * Free pages [start, end) updating memcg accounting and the global
+ * nr_vmalloc_pages counter. Caller is responsible for unmapping
+ * (vunmap_range) and KASAN poisoning before calling this.
+ */
+static void vmalloc_free_pages(struct vm_struct *vm,
+			       unsigned int start, unsigned int end)
+{
+	unsigned int i;
+	unsigned int nr = end - start;
+
+	if (!(vm->flags & VM_MAP_PUT_PAGES))
+		mod_memcg_page_state(vm->pages[start], MEMCG_VMALLOC, -nr);
+
+	for (i = start; i < end; i++) {
+		BUG_ON(!vm->pages[i]);
+		__free_page(vm->pages[i]);
+		cond_resched();
+	}
+
+	if (!(vm->flags & VM_MAP_PUT_PAGES))
+		atomic_long_sub(nr, &nr_vmalloc_pages);
+}
+
 /**
  * vfree - Release memory allocated by vmalloc()
  * @addr:  Memory base address
@@ -3429,7 +3458,6 @@ void vfree_atomic(const void *addr)
 void vfree(const void *addr)
 {
 	struct vm_struct *vm;
-	int i;
 
 	if (unlikely(in_interrupt())) {
 		vfree_atomic(addr);
@@ -3452,22 +3480,8 @@ void vfree(const void *addr)
 
 	if (unlikely(vm->flags & VM_FLUSH_RESET_PERMS))
 		vm_reset_perms(vm);
-	/* All pages of vm should be charged to same memcg, so use first one. */
-	if (vm->nr_pages && !(vm->flags & VM_MAP_PUT_PAGES))
-		mod_memcg_page_state(vm->pages[0], MEMCG_VMALLOC, -vm->nr_pages);
-	for (i = 0; i < vm->nr_pages; i++) {
-		struct page *page = vm->pages[i];
-
-		BUG_ON(!page);
-		/*
-		 * High-order allocs for huge vmallocs are split, so
-		 * can be freed as an array of order-0 allocations
-		 */
-		__free_page(page);
-		cond_resched();
-	}
-	if (!(vm->flags & VM_MAP_PUT_PAGES))
-		atomic_long_sub(vm->nr_pages, &nr_vmalloc_pages);
+	if (vm->nr_pages)
+		vmalloc_free_pages(vm, 0, vm->nr_pages);
 	kvfree(vm->pages);
 	kfree(vm);
 }

-- 
2.43.0

