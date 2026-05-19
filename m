From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Tue, 19 May 2026 17:42:16 +0530
Subject: [PATCH v14 3/5] mm/vmalloc: use physical page count in
 vread_iter() for VM_ALLOC areas
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-vmalloc-shrink-v14-3-70b96ee3e9c9@zohomail.in>
References: <20260519-vmalloc-shrink-v14-0-70b96ee3e9c9@zohomail.in>
In-Reply-To: <20260519-vmalloc-shrink-v14-0-70b96ee3e9c9@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779192749; l=1455;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=17YglxgG2ppUqTmOumv09d5uhEbrPDSaz3Teo6shawQ=;
 b=15zXYsWKqHJrAve7nV5Lj3j6NhR1QbpkCVzs/TxDWjJT14PEhptP1gVhj2ucTu11Cb1lwn2Qx
 5SiREPfwJ02C/Z3uoyWrH9NoY6YBtHeGjLyWDQJn182X/2d4P8Kfa3G
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For VM_ALLOC areas in vread_iter(), derive the vm area size from
vm->nr_pages rather than get_vm_area_size().

Only VM_ALLOC areas are subject to vrealloc() shrinking, which frees
pages without reducing the virtual reservation size. Switch to using
vm->nr_pages for VM_ALLOC areas so the reader remains correct once
shrink support is added. Other mapping types (vmap, ioremap) do not
initialize nr_pages and will continue using get_vm_area_size().

Reviewed-by: Uladzislau Rezki (Sony) <urezki@gmail.com>
Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 mm/vmalloc.c | 13 ++++++++++++-
 1 file changed, 12 insertions(+), 1 deletion(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index 3e159b74cfab..2f606cfade9b 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -4666,7 +4666,18 @@ long vread_iter(struct iov_iter *iter, const char *addr, size_t count)
 		smp_rmb();
 
 		vaddr = (char *) va->va_start;
-		size = vm ? get_vm_area_size(vm) : va_size(va);
+		if (vm)
+			/*
+			 * For VM_ALLOC areas, use nr_pages rather than
+			 * get_vm_area_size() because vrealloc() may shrink
+			 * the mapping without updating area->size. Other
+			 * mapping types (vmap, ioremap) don't set nr_pages.
+			 */
+			size = (vm->flags & VM_ALLOC) ?
+				       (vm->nr_pages << PAGE_SHIFT) :
+				       get_vm_area_size(vm);
+		else
+			size = va_size(va);
 
 		if (addr >= vaddr + size)
 			goto next_va;

-- 
2.43.0

