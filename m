From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Mon, 09 Mar 2026 17:25:45 +0530
Subject: [PATCH v3 1/2] mm/vmalloc: extract vmalloc_free_pages() helper
 from vfree()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260309-vmalloc-shrink-v3-1-5590fd8de2eb@zohomail.in>
References: <20260309-vmalloc-shrink-v3-0-5590fd8de2eb@zohomail.in>
In-Reply-To: <20260309-vmalloc-shrink-v3-0-5590fd8de2eb@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773057354; l=2510;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=K+fKY35rqal1HjSu0w8XUZyvTIb7GSRojmpzX5n0cKs=;
 b=tMvxDF4NmGBn266aUsP+BKfmmmHzs/OZbd58axuJ2Mp3ZLEdgFFSuV5XELVT1XA29RKBD299L
 /+X1aDNpFovBk90VI4PO/fFT8dyB3TnaE17p1U4Enf3NXpoaaJacXwE
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extract the page-freeing loop and NR_VMALLOC stat accounting from
vfree() into a reusable vmalloc_free_pages() helper. The helper operates
on a range [start, end) of pages from a vm_struct, making it suitable
for both full free (vfree) and partial free (upcoming vrealloc shrink).

No functional change.

Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 mm/vmalloc.c | 46 ++++++++++++++++++++++++++++++++--------------
 1 file changed, 32 insertions(+), 14 deletions(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index c607307c657a..42ae68450a90 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -3416,6 +3416,36 @@ void vfree_atomic(const void *addr)
 		schedule_work(&p->wq);
 }
 
+/*
+ * vmalloc_free_pages - free a range of pages from a vmalloc allocation
+ * @vm: the vm_struct containing the pages
+ * @start: first page index to free (inclusive)
+ * @end: last page index to free (exclusive)
+ *
+ * Free pages [start, end) updating NR_VMALLOC stat accounting.
+ * Caller is responsible for unmapping (vunmap_range) and KASAN
+ * poisoning before calling this.
+ */
+static void vmalloc_free_pages(struct vm_struct *vm, unsigned int start,
+			       unsigned int end)
+{
+	unsigned int i;
+
+	for (i = start; i < end; i++) {
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
+		cond_resched();
+	}
+}
+
 /**
  * vfree - Release memory allocated by vmalloc()
  * @addr:  Memory base address
@@ -3436,7 +3466,6 @@ void vfree_atomic(const void *addr)
 void vfree(const void *addr)
 {
 	struct vm_struct *vm;
-	int i;
 
 	if (unlikely(in_interrupt())) {
 		vfree_atomic(addr);
@@ -3459,19 +3488,8 @@ void vfree(const void *addr)
 
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
+	if (vm->nr_pages)
+		vmalloc_free_pages(vm, 0, vm->nr_pages);
 	kvfree(vm->pages);
 	kfree(vm);
 }

-- 
2.43.0

