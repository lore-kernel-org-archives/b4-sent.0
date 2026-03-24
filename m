From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Tue, 24 Mar 2026 15:30:29 +0530
Subject: [PATCH v7 4/6] mm/vmalloc: use READ_ONCE() for vmalloc nr_pages
 status readers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260324-vmalloc-shrink-v7-4-c0e62b8e5d83@zohomail.in>
References: <20260324-vmalloc-shrink-v7-0-c0e62b8e5d83@zohomail.in>
In-Reply-To: <20260324-vmalloc-shrink-v7-0-c0e62b8e5d83@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774346430; l=2959;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=q4Ito1vUmJmb3A3de47pGFK3WSX+j54Hs6oFM89TDPE=;
 b=3qyErl+BdMfksbupmMLQP9N6WcJ4/N+QyYsiJ6o6Do43NdkisYyO+pqnixaf4/KMJIZr53QVS
 n2yE/CxvHXWBew0wRQcmzqpR4d5njVMgs0tkA8bYJzMKeukfqW/6VBs
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The vmalloc status readers (vmalloc_info_show(), show_numa_info(), and
vmalloc_dump_obj()) currently read v->nr_pages and the v->pages array
without any concurrent protection.

In preparation for vrealloc() shrink support, where v->nr_pages can
be decreased and entries in the v->pages array can be nulled out
concurrently, these readers must be protected to prevent use-after-free
or NULL pointer dereferences.

Update these functions to use READ_ONCE() when accessing v->nr_pages
and v->pages[nr]. This ensures the compiler does not re-fetch these
values and provides a consistent view of the vmap area's state.
Additionally, in show_numa_info(), explicitly check for a NULL page
pointer before dereferencing it to avoid potential crashes if a page
was concurrently removed during a shrink operation.

Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 mm/vmalloc.c | 19 +++++++++++++------
 1 file changed, 13 insertions(+), 6 deletions(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index ddb689bf9ba5..c6bdddee6266 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -5189,7 +5189,7 @@ bool vmalloc_dump_obj(void *object)
 	vm = va->vm;
 	addr = (unsigned long) vm->addr;
 	caller = vm->caller;
-	nr_pages = vm->nr_pages;
+	nr_pages = READ_ONCE(vm->nr_pages);
 	spin_unlock(&vn->busy.lock);
 
 	pr_cont(" %u-page vmalloc region starting at %#lx allocated at %pS\n",
@@ -5210,7 +5210,7 @@ bool vmalloc_dump_obj(void *object)
 static void show_numa_info(struct seq_file *m, struct vm_struct *v,
 				 unsigned int *counters)
 {
-	unsigned int nr;
+	unsigned int nr, nr_pages;
 	unsigned int step = 1U << vm_area_page_order(v);
 
 	if (!counters)
@@ -5218,8 +5218,13 @@ static void show_numa_info(struct seq_file *m, struct vm_struct *v,
 
 	memset(counters, 0, nr_node_ids * sizeof(unsigned int));
 
-	for (nr = 0; nr < v->nr_pages; nr += step)
-		counters[page_to_nid(v->pages[nr])] += step;
+	nr_pages = READ_ONCE(v->nr_pages);
+	for (nr = 0; nr < nr_pages; nr += step) {
+		struct page *page = READ_ONCE(v->pages[nr]);
+
+		if (page)
+			counters[page_to_nid(page)] += step;
+	}
 	for_each_node_state(nr, N_HIGH_MEMORY)
 		if (counters[nr])
 			seq_printf(m, " N%u=%u", nr, counters[nr]);
@@ -5247,6 +5252,7 @@ static int vmalloc_info_show(struct seq_file *m, void *p)
 	struct vmap_area *va;
 	struct vm_struct *v;
 	unsigned int *counters;
+	unsigned int nr_pages;
 
 	if (IS_ENABLED(CONFIG_NUMA))
 		counters = kmalloc_array(nr_node_ids, sizeof(unsigned int), GFP_KERNEL);
@@ -5276,8 +5282,9 @@ static int vmalloc_info_show(struct seq_file *m, void *p)
 			if (v->caller)
 				seq_printf(m, " %pS", v->caller);
 
-			if (v->nr_pages)
-				seq_printf(m, " pages=%d", v->nr_pages);
+			nr_pages = READ_ONCE(v->nr_pages);
+			if (nr_pages)
+				seq_printf(m, " pages=%d", nr_pages);
 
 			if (v->phys_addr)
 				seq_printf(m, " phys=%pa", &v->phys_addr);

-- 
2.43.0

