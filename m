From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Fri, 27 Mar 2026 15:18:38 +0530
Subject: [PATCH v8 2/6] mm/vmalloc: fix vrealloc() grow-in-place check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260327-vmalloc-shrink-v8-2-cc6b57059ed7@zohomail.in>
References: <20260327-vmalloc-shrink-v8-0-cc6b57059ed7@zohomail.in>
In-Reply-To: <20260327-vmalloc-shrink-v8-0-cc6b57059ed7@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774604917; l=1675;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=JBxDN0g82pC84smB7v9qq2A4Kq3XUFnm46m5uC3JQmo=;
 b=HSIEpP+gWS/CI0lJnxlmSaw0gfljH77Mtt5owCSfUm1SMlxuTzAAVF4GvU7JLLlRDvUW0TnLR
 4/ZSGhlJUfKDNiY1tyUWDUeY34dA/y/qK0fs599OWmzNHGaO5xsmhJS
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the grow-in-place check in vrealloc() to compare the requested size
against the actual physical page count (vm->nr_pages) rather than the
virtual area size (alloced_size, derived from get_vm_area_size()).

The virtual reservation size (get_vm_area_size()) does not decrease when
pages are freed during a shrink operation. Consequently, without this fix,
a subsequent grow-in-place operation after a shrink would incorrectly
succeed and attempt to access freed pages. Correcting this check is a
prerequisite for the upcoming vrealloc() shrink functionality.

Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 mm/vmalloc.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index 79a57955345d..133c3b0418fe 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -4343,6 +4343,12 @@ void *vrealloc_node_align_noprof(const void *p, size_t size, unsigned long align
 		if (unlikely(flags & __GFP_THISNODE) && nid != NUMA_NO_NODE &&
 			     nid != page_to_nid(vmalloc_to_page(p)))
 			goto need_realloc;
+	} else {
+		/*
+		 * If p is NULL, vrealloc behaves exactly like vmalloc.
+		 * Skip the shrink and in-place grow paths.
+		 */
+		goto need_realloc;
 	}
 
 	/*
@@ -4361,7 +4367,7 @@ void *vrealloc_node_align_noprof(const void *p, size_t size, unsigned long align
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

