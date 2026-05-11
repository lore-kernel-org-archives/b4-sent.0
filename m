From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Mon, 11 May 2026 13:47:31 +0530
Subject: [PATCH v13 3/5] mm/vmalloc: use physical page count in
 vread_iter()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-vmalloc-shrink-v13-3-643b7ec277a9@zohomail.in>
References: <20260511-vmalloc-shrink-v13-0-643b7ec277a9@zohomail.in>
In-Reply-To: <20260511-vmalloc-shrink-v13-0-643b7ec277a9@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778487457; l=1325;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=0/E2gQvGxEo3eGw/8wt9W0DQApE+QcKjBLa75ti9yYs=;
 b=KDZ8dim5ESybiJyOGbwcOhc1DmY5tSwZqA0TstiryUq+cc1v4bqjKAmKi/l3UjbFw+8qZij1e
 rmWpniLO2UoBwyy/+uajlyh+a2vwajeXbgiu6q3QKpj22mSFi8QVYFi
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update vread_iter() to derive the vm area size from vm->nr_pages rather
than get_vm_area_size().

Currently both values are equivalent, but the upcoming vrealloc() shrink
functionality will free pages without reducing the virtual reservation
size. After such a shrink, the old get_vm_area_size() based calculation
would overestimate the mapped range, causing vread_iter() to attempt
reading from unmapped addresses. Switch to vm->nr_pages now so the
reader remains correct once shrink support is added.

Reviewed-by: Uladzislau Rezki (Sony) <urezki@gmail.com>
Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 mm/vmalloc.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index 87278cf2046e..d69174afb171 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -4666,7 +4666,14 @@ long vread_iter(struct iov_iter *iter, const char *addr, size_t count)
 		smp_rmb();
 
 		vaddr = (char *) va->va_start;
-		size = vm ? get_vm_area_size(vm) : va_size(va);
+		if (vm)
+			/*
+			 * Cannot use get_vm_area_size() because realloc()
+			 * may shrink the mapping and area->size may be outdated.
+			 */
+			size = vm->nr_pages << PAGE_SHIFT;
+		else
+			size = va_size(va);
 
 		if (addr >= vaddr + size)
 			goto next_va;

-- 
2.43.0

