From: Anh Nguyen Hoang <anhnh.4work@gmail.com>
Date: Fri, 27 Nov 2026 00:52:48 -0600
Subject: [PATCH] parisc: pci-dma: Handle allocation failures in
 arch_dma_alloc()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-kbug-l001-v1-1-db0b44ec71d5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAL8oCWsC/yXM0QpAMBSA4VfRubba2Qp5FbmwOeMgtCEl7264/
 OrvvyCQZwpQJhd4OjjwMkdgmoDtm7kjwW00KKkyRJWL0eydmKREYYwutEanXG4h9qsnx+f3qur
 fYTcD2e0dwH0/vn+DrW0AAAA=
X-Change-ID: 20261127-kbug-l001-bb38331f2f7c
To: "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 Helge Deller <deller@gmx.de>
Cc: linux-parisc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Anh Nguyen Hoang <anhnh.4work@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795762368; l=3623;
 i=anhnh.4work@gmail.com; s=20261127; h=from:subject:message-id;
 bh=LbWh1p0JWyiyRtWO0aSmkJ1gB8M+YbXem8D4tGZGGVc=;
 b=DJdh6gcbpAwHy70+KQkuktnNPas6c90im+HCxTO8qLwfHB4z5hX/Xy5hEyRxfG6wQMj8OIxBf
 3IsrWwsnSBeBw7oJQclHGzpPhL9uUtAV+O0Drfs3mZfRC/gaaQ/bRT9
X-Developer-Key: i=anhnh.4work@gmail.com; a=ed25519;
 pk=9NJ/0SKqaFZmt1/I5XY11TZSNY2ys6RWB3gvqzrLHmI=
X-Endpoint-Received: by B4 Relay for anhnh.4work@gmail.com/20261127 with auth_id=1662
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

arch_dma_alloc() does not check the return value of __get_free_pages().
If the allocation fails, the function carries on with paddr == 0: it
calls flush_kernel_dcache_range(0, size), maps __pa(0) uncached into
the range reserved by pcxl_alloc_range(), stores __pa(0) in *dma_handle
and returns the non-NULL virtual address of that range.

The return value of map_uncached_pages() is ignored as well. It returns
-ENOMEM when pte_alloc_kernel() fails, in which case the returned
virtual range is left unmapped.

In both cases dma_direct_alloc() passes the non-NULL address on, so the
driver is told that the coherent allocation succeeded and then uses a
buffer which is not backed by the pages it expects, or not mapped at
all.

Check both results. If the page allocation fails, release the reserved
PCXL range and return NULL. If the mapping fails, additionally free
the pages. Call unmap_uncached_pages() there too, so that the error
path does not depend on how far the walk got before it failed; it
skips empty page directory entries and clearing an empty PTE is
harmless.

This only affects machines with a PCX-L or PCX-L2 CPU, the only ones
for which arch_dma_alloc() does not return NULL right away.

Found by an automated code scan and confirmed by code inspection.
Reproduced in qemu (B160L, PCX-L2) with page allocation fault
injection: without this change a failed page allocation makes
dma_alloc_coherent() return a valid looking address with DMA handle
0xf0000000, and a failed page table allocation is reported as success
too. With this change both return NULL.

Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")
Assisted-by: Claude:claude-fable-5-2
Signed-off-by: Anh Nguyen Hoang <anhnh.4work@gmail.com>
---
Tested in qemu-system-hppa 11.1.3 (B160L, PA7300LC) with
generic-32bit_defconfig plus FAIL_PAGE_ALLOC. A test-only initcall calls
dma_alloc_coherent() and fails one chosen page allocation through
current->fail_nth.
Before: a failed __get_free_pages() returns vaddr 0x00048000 with DMA
handle 0xf0000000 (__pa(0)); a failed page table allocation also
returns success.
After: both return NULL (300 and 297 injected failures), with no leaked
PCXL ranges or pages.
No Cc: stable added; please add it if warranted.

Testing:
- Compile-tested on parisc (allmodconfig, W=1):
  arch/parisc/kernel/pci-dma.o; no new warnings.
- checkpatch.pl --strict: no errors or warnings.
---
 arch/parisc/kernel/pci-dma.c | 12 +++++++++++-
 1 file changed, 11 insertions(+), 1 deletion(-)

diff --git a/arch/parisc/kernel/pci-dma.c b/arch/parisc/kernel/pci-dma.c
index bf9f192c826e..6e2d340921fe 100644
--- a/arch/parisc/kernel/pci-dma.c
+++ b/arch/parisc/kernel/pci-dma.c
@@ -412,12 +412,22 @@ void *arch_dma_alloc(struct device *dev, size_t size,
 	size = 1 << (order + PAGE_SHIFT);
 	vaddr = pcxl_alloc_range(size);
 	paddr = __get_free_pages(gfp | __GFP_ZERO, order);
+	if (!paddr)
+		goto out_free_range;
 	flush_kernel_dcache_range(paddr, size);
 	paddr = __pa(paddr);
-	map_uncached_pages(vaddr, size, paddr);
+	if (map_uncached_pages(vaddr, size, paddr))
+		goto out_unmap;
 	*dma_handle = (dma_addr_t) paddr;
 
 	return (void *)vaddr;
+
+out_unmap:
+	unmap_uncached_pages(vaddr, size);
+	free_pages((unsigned long)__va(paddr), order);
+out_free_range:
+	pcxl_free_range(vaddr, size);
+	return NULL;
 }
 
 void arch_dma_free(struct device *dev, size_t size, void *vaddr,

---
base-commit: c03c1a14507dfaf8b856c2608f9ac216021fc222
change-id: 20261127-kbug-l001-bb38331f2f7c

Best regards,
--  
Anh Nguyen Hoang <anhnh.4work@gmail.com>

