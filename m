From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Tue, 19 May 2026 17:42:18 +0530
Subject: [PATCH v14 5/5] lib/test_vmalloc: add vrealloc test case
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-vmalloc-shrink-v14-5-70b96ee3e9c9@zohomail.in>
References: <20260519-vmalloc-shrink-v14-0-70b96ee3e9c9@zohomail.in>
In-Reply-To: <20260519-vmalloc-shrink-v14-0-70b96ee3e9c9@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779192749; l=2905;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=yP1QXayDidKnNU2S8I7BqJprRzQI2mQyl0fytHsaqPM=;
 b=qRwd2vwgvAIzFKzG34KR4AENXRAoMWlQWk9KjRHrtik8HlO1YbhPgnKGodIcAnWABPsjDf3lE
 5O5VZg2CZVBA2SAi/4XKrKRLkb+1syhjHClgrYqcMSjJMvi8TJiBoQ9
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a new test case "vrealloc_test" that exercises the vrealloc()
shrink and in-place grow paths:

  - Grow beyond allocated pages (triggers full reallocation).
  - Shrink crossing a page boundary (frees tail pages).
  - Shrink within the same page (no page freeing).
  - Grow within the already allocated page count (in-place).

Data integrity is validated after each realloc step by checking that
the first byte of the original allocation is preserved.

The test is gated behind run_test_mask bit 12 (id 4096).

Reviewed-by: Uladzislau Rezki (Sony) <urezki@gmail.com>
Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 lib/test_vmalloc.c | 62 ++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 62 insertions(+)

diff --git a/lib/test_vmalloc.c b/lib/test_vmalloc.c
index 876c72c18a0c..b23f85e8f8ca 100644
--- a/lib/test_vmalloc.c
+++ b/lib/test_vmalloc.c
@@ -55,6 +55,7 @@ __param(int, run_test_mask, 7,
 		"\t\tid: 512,  name: kvfree_rcu_2_arg_vmalloc_test\n"
 		"\t\tid: 1024, name: vm_map_ram_test\n"
 		"\t\tid: 2048, name: no_block_alloc_test\n"
+		"\t\tid: 4096, name: vrealloc_test\n"
 		/* Add a new test case description here. */
 );
 
@@ -421,6 +422,66 @@ vm_map_ram_test(void)
 	return nr_allocated != map_nr_pages;
 }
 
+static int vrealloc_test(void)
+{
+	void *ptr, *tmp;
+	int i;
+
+	for (i = 0; i < test_loop_count; i++) {
+		int err = -1;
+
+		ptr = vrealloc(NULL, PAGE_SIZE, GFP_KERNEL);
+		if (!ptr)
+			return -1;
+
+		*((__u8 *)ptr) = 'a';
+
+		/* Grow: beyond allocated pages, triggers full realloc. */
+		tmp = vrealloc(ptr, 4 * PAGE_SIZE, GFP_KERNEL);
+		if (!tmp)
+			goto error;
+		ptr = tmp;
+
+		if (*((__u8 *)ptr) != 'a')
+			goto error;
+
+		/* Shrink: crosses page boundary, frees tail pages. */
+		tmp = vrealloc(ptr, PAGE_SIZE, GFP_KERNEL);
+		if (!tmp)
+			goto error;
+		ptr = tmp;
+
+		if (*((__u8 *)ptr) != 'a')
+			goto error;
+
+		/* Shrink: within same page, no page freeing. */
+		tmp = vrealloc(ptr, PAGE_SIZE / 2, GFP_KERNEL);
+		if (!tmp)
+			goto error;
+		ptr = tmp;
+
+		if (*((__u8 *)ptr) != 'a')
+			goto error;
+
+		/* Grow: within allocated page, in-place, no realloc. */
+		tmp = vrealloc(ptr, PAGE_SIZE, GFP_KERNEL);
+		if (!tmp)
+			goto error;
+		ptr = tmp;
+
+		if (*((__u8 *)ptr) != 'a')
+			goto error;
+
+		err = 0;
+error:
+		vfree(ptr);
+		if (err)
+			return err;
+	}
+
+	return 0;
+}
+
 struct test_case_desc {
 	const char *test_name;
 	int (*test_func)(void);
@@ -440,6 +501,7 @@ static struct test_case_desc test_case_array[] = {
 	{ "kvfree_rcu_2_arg_vmalloc_test", kvfree_rcu_2_arg_vmalloc_test, },
 	{ "vm_map_ram_test", vm_map_ram_test, },
 	{ "no_block_alloc_test", no_block_alloc_test, true },
+	{ "vrealloc_test", vrealloc_test, },
 	/* Add a new test case here. */
 };
 

-- 
2.43.0

