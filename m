From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Sat, 21 Mar 2026 23:35:49 +0530
Subject: [PATCH v6 4/6] mm/vmalloc: protect /proc/vmallocinfo readers with
 READ_ONCE()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260321-vmalloc-shrink-v6-4-062ca7b7ceb2@zohomail.in>
References: <20260321-vmalloc-shrink-v6-0-062ca7b7ceb2@zohomail.in>
In-Reply-To: <20260321-vmalloc-shrink-v6-0-062ca7b7ceb2@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774116351; l=2501;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=zRiycWT30EskDdJb187oavYNW2pvSidAAoWxjYptHoI=;
 b=Iy7HQsfLM2cG5f52zW/32wxoytcChbH5qmqXDljNno6hiSOpCsM0jsfPSkf4jREnsMI2UYKAj
 oIaHkILF7FEDFDs3hMJoP9lBl/FLGd09YT28gU2s7//g4yA0mPqxrng
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The /proc/vmallocinfo readers, specifically show_numa_info() and
vmalloc_info_show(), currently read v->nr_pages and the v->pages
array without any concurrent protection.

In preparation for vrealloc() shrink support, where v->nr_pages can
be decreased and entries in the v->pages array can be nulled out
concurrently, these readers must be protected to prevent use-after-free
or NULL pointer dereferences.

Update show_numa_info() to use READ_ONCE(v->nr_pages) and
READ_ONCE(v->pages[nr]), explicitly checking for NULL before
dereferencing the page. Similarly, update vmalloc_info_show() to
read nr_pages safely to avoid parsing a torn or inconsistent value.

Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 mm/vmalloc.c | 17 ++++++++++++-----
 1 file changed, 12 insertions(+), 5 deletions(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index 64f5d1088281..7658fdc087d2 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -5204,7 +5204,7 @@ bool vmalloc_dump_obj(void *object)
 static void show_numa_info(struct seq_file *m, struct vm_struct *v,
 				 unsigned int *counters)
 {
-	unsigned int nr;
+	unsigned int nr, nr_pages;
 	unsigned int step = 1U << vm_area_page_order(v);
 
 	if (!counters)
@@ -5212,8 +5212,13 @@ static void show_numa_info(struct seq_file *m, struct vm_struct *v,
 
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
@@ -5241,6 +5246,7 @@ static int vmalloc_info_show(struct seq_file *m, void *p)
 	struct vmap_area *va;
 	struct vm_struct *v;
 	unsigned int *counters;
+	unsigned int nr_pages;
 
 	if (IS_ENABLED(CONFIG_NUMA))
 		counters = kmalloc_array(nr_node_ids, sizeof(unsigned int), GFP_KERNEL);
@@ -5270,8 +5276,9 @@ static int vmalloc_info_show(struct seq_file *m, void *p)
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

