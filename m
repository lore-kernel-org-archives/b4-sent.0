From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Tue, 24 Mar 2026 15:30:28 +0530
Subject: [PATCH v7 3/6] mm/vmalloc: zero newly exposed memory on vrealloc()
 grow
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260324-vmalloc-shrink-v7-3-c0e62b8e5d83@zohomail.in>
References: <20260324-vmalloc-shrink-v7-0-c0e62b8e5d83@zohomail.in>
In-Reply-To: <20260324-vmalloc-shrink-v7-0-c0e62b8e5d83@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774346430; l=1805;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=LSUYWjYOjJYKYliRO3bYLhKxcMuMIBGaVN2tymO6+ew=;
 b=rnj4cYZkzkJ86bsOX6qnSlWl5dROAsN7ly5d6iDcEQPVC7kXfPVNp2+aT/Y+JklM8mQ3ukx5Y
 aizhMbSd8BvDTD8JdpVEUyF3RLaOHctT575Mvr0Wj0aLjsC/fSjn72S
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When growing an existing vmalloc allocation in-place, zero the newly
exposed memory region [old_size, size) if the caller requested it via
__GFP_ZERO (checked via want_init_on_alloc(flags)).

Previously, the code assumed that the unused capacity in the vm_struct
was already zeroed either at initial allocation time or during a prior
shrink. However, if an intermediate shrink operation occurred without
__GFP_ZERO and without init_on_free enabled, the "freed" portion of the
allocation would retain its old data.

If a subsequent grow-in-place operation then explicitly requests
__GFP_ZERO, failing to zero the memory here would violate the allocation
flags and leak the previously discarded, potentially sensitive data.

Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 mm/vmalloc.c | 13 ++++++++-----
 1 file changed, 8 insertions(+), 5 deletions(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index 133c3b0418fe..ddb689bf9ba5 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -4368,13 +4368,16 @@ void *vrealloc_node_align_noprof(const void *p, size_t size, unsigned long align
 	 * We already have the bytes available in the allocation; use them.
 	 */
 	if (size <= (size_t)vm->nr_pages << PAGE_SHIFT) {
-		/*
-		 * No need to zero memory here, as unused memory will have
-		 * already been zeroed at initial allocation time or during
-		 * realloc shrink time.
-		 */
 		vm->requested_size = size;
 		kasan_vrealloc(p, old_size, size);
+
+		/*
+		 * Zero the newly exposed bytes if requested.
+		 * The region [old_size, size) may contain stale data from
+		 * a previous shrink that did not use __GFP_ZERO.
+		 */
+		if (want_init_on_alloc(flags))
+			memset((void *)p + old_size, 0, size - old_size);
 		return (void *)p;
 	}
 

-- 
2.43.0

