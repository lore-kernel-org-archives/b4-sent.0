From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Sat, 21 Mar 2026 23:35:47 +0530
Subject: [PATCH v6 2/6] mm/vmalloc: fix vrealloc() grow-in-place check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260321-vmalloc-shrink-v6-2-062ca7b7ceb2@zohomail.in>
References: <20260321-vmalloc-shrink-v6-0-062ca7b7ceb2@zohomail.in>
In-Reply-To: <20260321-vmalloc-shrink-v6-0-062ca7b7ceb2@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774116351; l=1250;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=w90h6aByrvZe7M9pbnNSecs/NY6vWML8p6XHr/QXZq4=;
 b=KexBhgjzhjxhyLbuUOfWatjeAXgA9SkFNWaZp4aArRYDJYWYq1g/pF7XSztMPVb/Ga6zsw3X0
 LKH+xk6OfJiAKNWXkgjApLUsIQtI71bg+osn31qBTzXt5AdUOUQtbVH
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
 mm/vmalloc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index 3977398e56e4..7bc7a6892c1a 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -4361,7 +4361,7 @@ void *vrealloc_node_align_noprof(const void *p, size_t size, unsigned long align
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

