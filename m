From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Sat, 04 Apr 2026 14:06:57 +0530
Subject: [PATCH v10 1/4] mm/vmalloc: extract vm_area_free_pages() helper
 from vfree()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260404-vmalloc-shrink-v10-1-335759165dfa@zohomail.in>
References: <20260404-vmalloc-shrink-v10-0-335759165dfa@zohomail.in>
In-Reply-To: <20260404-vmalloc-shrink-v10-0-335759165dfa@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775291829; l=2828;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=pPxio16sTZmRdQnFJiC4z+Co3PLVcVoIySf6x2/MXmo=;
 b=h1QBFXl+j95owXc6zAb1hldqce0tKV3luXhiWMIzcDI39Tj65UEqoVIriqEqgi/XZx8nVxDbW
 qsiV7AnmE+jBQaHWluQjOueqWKM8ZPxO37k9opPAdhZ+l6MXyhGNf19
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extract the page-freeing loop and NR_VMALLOC stat accounting from
vfree() into a reusable vm_area_free_pages() helper. The helper operates
on a range [start_idx, end_idx) of pages from a vm_struct, making it
suitable for both full free (vfree) and partial free (upcoming vrealloc
shrink).

Freed page pointers in vm->pages[] are set to NULL to prevent stale
references when the vm_struct outlives the free (as in vrealloc shrink).

Reviewed-by: Alice Ryhl <aliceryhl@google.com>
Reviewed-by: Uladzislau Rezki (Sony) <urezki@gmail.com>
Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 mm/vmalloc.c | 47 +++++++++++++++++++++++++++++++++--------------
 1 file changed, 33 insertions(+), 14 deletions(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index b31b208f6ecb..8dd7df79c5c5 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -3416,6 +3416,38 @@ void vfree_atomic(const void *addr)
 		schedule_work(&p->wq);
 }
 
+/*
+ * vm_area_free_pages - free a range of pages from a vmalloc allocation
+ * @vm: the vm_struct containing the pages
+ * @start_idx: first page index to free (inclusive)
+ * @end_idx: last page index to free (exclusive)
+ *
+ * Free pages [start_idx, end_idx) updating NR_VMALLOC stat accounting.
+ * Freed vm->pages[] entries are set to NULL.
+ * Caller is responsible for unmapping (vunmap_range) and KASAN
+ * poisoning before calling this.
+ */
+static void vm_area_free_pages(struct vm_struct *vm, unsigned int start_idx,
+			       unsigned int end_idx)
+{
+	unsigned int i;
+
+	for (i = start_idx; i < end_idx; i++) {
+		struct page *page = vm->pages[i];
+
+		BUG_ON(!page);
+		/*
+		 * High-order allocs for huge vmallocs are split, so
+		 * can be freed as an array of order-0 allocations
+		 */
+		if (!(vm->flags & VM_MAP_PUT_PAGES))
+			mod_lruvec_page_state(page, NR_VMALLOC, -1);
+		__free_page(page);
+		vm->pages[i] = NULL;
+		cond_resched();
+	}
+}
+
 /**
  * vfree - Release memory allocated by vmalloc()
  * @addr:  Memory base address
@@ -3436,7 +3468,6 @@ void vfree_atomic(const void *addr)
 void vfree(const void *addr)
 {
 	struct vm_struct *vm;
-	int i;
 
 	if (unlikely(in_interrupt())) {
 		vfree_atomic(addr);
@@ -3459,19 +3490,7 @@ void vfree(const void *addr)
 
 	if (unlikely(vm->flags & VM_FLUSH_RESET_PERMS))
 		vm_reset_perms(vm);
-	for (i = 0; i < vm->nr_pages; i++) {
-		struct page *page = vm->pages[i];
-
-		BUG_ON(!page);
-		/*
-		 * High-order allocs for huge vmallocs are split, so
-		 * can be freed as an array of order-0 allocations
-		 */
-		if (!(vm->flags & VM_MAP_PUT_PAGES))
-			mod_lruvec_page_state(page, NR_VMALLOC, -1);
-		__free_page(page);
-		cond_resched();
-	}
+	vm_area_free_pages(vm, 0, vm->nr_pages);
 	kvfree(vm->pages);
 	kfree(vm);
 }

-- 
2.43.0

