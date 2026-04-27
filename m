From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Tue, 28 Apr 2026 01:54:17 +0530
Subject: [PATCH v12 2/5] mm/vmalloc: use physical page count for vrealloc()
 grow-in-place check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-vmalloc-shrink-v12-2-3c18c9172eb1@zohomail.in>
References: <20260428-vmalloc-shrink-v12-0-3c18c9172eb1@zohomail.in>
In-Reply-To: <20260428-vmalloc-shrink-v12-0-3c18c9172eb1@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777321463; l=1711;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=3zaMDF3eqVJSjOkW52oDkHrDPus2VHUR0DHtrB4u00o=;
 b=9xDmV4QtPHHxQIrLU6FWBWFk5O11upRJ6kVq6BdfEg+o3OqmT9PIwsBDRRVjoqRHmvya8jdBG
 SRE0nLYjyARBGXOwMeVysPpN0kqJGi+kck6apHCR7qUZjDCWkzTwGDv
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the grow-in-place check in vrealloc() to compare the requested size
against the actual physical page count (vm->nr_pages) rather than the
virtual area size (alloced_size, derived from get_vm_area_size()).

Currently both values are equivalent, but the upcoming vrealloc() shrink
functionality will free pages without reducing the virtual reservation
size. After such a shrink, the old alloced_size-based comparison would
incorrectly allow a grow-in-place operation to succeed and attempt to
access freed pages. Switch to vm->nr_pages now so the check remains
correct once shrink support is added.

Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 mm/vmalloc.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index 1073abb6094e..9cb3e287a1e8 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -4338,6 +4338,12 @@ void *vrealloc_node_align_noprof(const void *p, size_t size, unsigned long align
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
@@ -4356,7 +4362,7 @@ void *vrealloc_node_align_noprof(const void *p, size_t size, unsigned long align
 	/*
 	 * We already have the bytes available in the allocation; use them.
 	 */
-	if (size <= alloced_size) {
+	if (size <= vm->nr_pages << PAGE_SHIFT) {
 		/*
 		 * No need to zero memory here, as unused memory will have
 		 * already been zeroed at initial allocation time or during

-- 
2.43.0

