From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Mon, 11 May 2026 13:47:29 +0530
Subject: [PATCH v13 1/5] mm/vmalloc: extract vm_area_free_pages() helper
 from vfree()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-vmalloc-shrink-v13-1-643b7ec277a9@zohomail.in>
References: <20260511-vmalloc-shrink-v13-0-643b7ec277a9@zohomail.in>
In-Reply-To: <20260511-vmalloc-shrink-v13-0-643b7ec277a9@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778487457; l=2470;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=g8lqMk/sZRbF3gcdhaoXiAZumYYOTY4cCcb8pTUlYtU=;
 b=yTI5v4v022BkUsxgF/ATbU7cWVQWSCdz6ULdUZZYrurBnocjrT3VhfJT8S1YJIAB1TaEvo+7W
 fiO4ZjiJPrSAs65M19Bw+nn3MbIyt5cV3QPt9SRaL3oj2/fIv/QgxZ2
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extract page freeing and NR_VMALLOC stat accounting from
vfree() into a reusable vm_area_free_pages() helper.
The helper operates on a range [start_idx, end_idx) of pages
from a vm_struct, making it suitable for both full free (vfree)
and partial free (upcoming vrealloc shrink).

Freed page pointers in vm->pages[] are set to NULL
to prevent stale references when the vm_struct outlives the
free (as in vrealloc shrink).

Reviewed-by: Uladzislau Rezki (Sony) <urezki@gmail.com>
Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 mm/vmalloc.c | 34 +++++++++++++++++++++++++++-------
 1 file changed, 27 insertions(+), 7 deletions(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index 3e9e5156f43e..19a16e6f4014 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -3416,6 +3416,32 @@ void vfree_atomic(const void *addr)
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
+	if (!(vm->flags & VM_MAP_PUT_PAGES)) {
+		for (i = start_idx; i < end_idx; i++)
+			mod_lruvec_page_state(vm->pages[i], NR_VMALLOC, -1);
+	}
+	free_pages_bulk(vm->pages + start_idx, end_idx - start_idx);
+
+	for (i = start_idx; i < end_idx; i++)
+		vm->pages[i] = NULL;
+}
+
 /**
  * vfree - Release memory allocated by vmalloc()
  * @addr:  Memory base address
@@ -3436,7 +3462,6 @@ void vfree_atomic(const void *addr)
 void vfree(const void *addr)
 {
 	struct vm_struct *vm;
-	int i;
 
 	if (unlikely(in_interrupt())) {
 		vfree_atomic(addr);
@@ -3460,12 +3485,7 @@ void vfree(const void *addr)
 	if (unlikely(vm->flags & VM_FLUSH_RESET_PERMS))
 		vm_reset_perms(vm);
 
-	if (!(vm->flags & VM_MAP_PUT_PAGES)) {
-		for (i = 0; i < vm->nr_pages; i++)
-			mod_lruvec_page_state(vm->pages[i], NR_VMALLOC, -1);
-	}
-	free_pages_bulk(vm->pages, vm->nr_pages);
-
+	vm_area_free_pages(vm, 0, vm->nr_pages);
 	kvfree(vm->pages);
 	kfree(vm);
 }

-- 
2.43.0

