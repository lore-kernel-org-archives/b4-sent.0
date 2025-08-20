From: John Cox <john.cox@raspberrypi.com>
Date: Wed, 20 Aug 2025 11:28:06 +0100
Subject: [PATCH] arm64/dma-mapping: Fix arch_sync_dma_for_device to respect
 dir parameter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250820-arm64-dma-direction-fix-v1-1-818a4ca8f879@raspberrypi.com>
X-B4-Tracking: v=1; b=H4sIADWjpWgC/x2MSwqAMAwFryJZG2hL/V5FXFQbNQs/pCKCeHeDy
 3nMmwcSCVOCNntA6OLE+6Zg8wzGJWwzIUdlcMYVprYNBllLj3ENGFloPNXHiW+sgq3i4AtnvAF
 9H0I6/+Wuf98P26gJo2kAAAA=
X-Change-ID: 20250819-arm64-dma-direction-fix-7a17db452040
To: Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, 
 John Cox <john.cox@raspberrypi.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755685692; l=2865;
 i=john.cox@raspberrypi.com; s=20250820; h=from:subject:message-id;
 bh=A0faGdB6jvGvpOhr4yqKULcyxzYLZmrHeTUjS8AAS2I=;
 b=nrUwVChnIiNiher7bRqc6ipbU0fkP4TfLtEF+RtEpxE5xLugC4vRWGZBL2szJSAGBc60CXbWJ
 RzsIhegwfJoAg7TfnGbPK6FJzz5Y5fJxcjBgBQc5bz+7LOZ3MLrO8oc
X-Developer-Key: i=john.cox@raspberrypi.com; a=ed25519;
 pk=a3LAIU66MAZzpHbiNZ4El5gKaDfA4ONOVlPUCzEGUDI=
X-Endpoint-Received: by B4 Relay for john.cox@raspberrypi.com/20250820 with auth_id=497
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All other architectures do different cache operations depending on the
dir parameter. Fix arm64 to do the same.

This fixes udmabuf operations when syncing for read e.g. when the CPU
reads back a V4L2 decoded frame buffer.

Signed-off-by: John Cox <john.cox@raspberrypi.com>
---
This patch makes the arch_sync_dma_for_device function on arm64
do different things depending on the value of the dir parameter. In
particular it does a cache invalidate operation if the dir flag is
set to DMA_FROM_DEVICE. The current code does a writeback without
invalidate under all circumstances. Nearly all other architectures do
an invalidate if the direction is FROM_DEVICE which seems like the
correct thing to do to me.

This patch fixes a problem I was having with udmabuf allocated
dmabufs. It also fixes a very similar problem I had with dma_heap
allocated dmabuf but that occured very much less frequently and I
haven't traced exactly what was going on there.

My problem (on a Raspberry Pi5):

[Userland]
Alloc memory with memfd_create + ftruncate
Derive dmabuf from memfd with udmabuf
Close memfd
Queue dmabuf into V4L2 with QBUF
<decode a video frame>
Extract dmabuf from V4L2 with DQBUF
Map dmabuf for read with mmap
Sync for read with DMA_BUF_IOCTL_SYNC with (DMA_BUF_SYNC_START |
DMA_BUF_SYNC_READ)
Read buffer
Sync end
Unmap

I get old (zero) data out of the "Read buffer" stage in some cache
lines sometimes.
It doesn't matter which way round the mmap & sync are.

I am aware that there is a patchset going through for udmabuf that may
well fix the udmabuf case above, but given that this patch fixes
something similar in dma_heap/system too I think it is still worth
having.
---
 arch/arm64/mm/dma-mapping.c | 16 +++++++++++++++-
 1 file changed, 15 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/mm/dma-mapping.c b/arch/arm64/mm/dma-mapping.c
index b2b5792b2caaf81ccfc3204c94395bb0faeabddd..51c43c1f563015139e365ed86f0f5f0d9483fa7f 100644
--- a/arch/arm64/mm/dma-mapping.c
+++ b/arch/arm64/mm/dma-mapping.c
@@ -16,8 +16,22 @@ void arch_sync_dma_for_device(phys_addr_t paddr, size_t size,
 			      enum dma_data_direction dir)
 {
 	unsigned long start = (unsigned long)phys_to_virt(paddr);
+	unsigned long end = start + size;
 
-	dcache_clean_poc(start, start + size);
+	switch (dir) {
+	case DMA_BIDIRECTIONAL:
+		dcache_clean_inval_poc(start, end);
+		break;
+	case DMA_TO_DEVICE:
+		dcache_clean_poc(start, end);
+		break;
+	case DMA_FROM_DEVICE:
+		dcache_inval_poc(start, end);
+		break;
+	case DMA_NONE:
+	default:
+		break;
+	}
 }
 
 void arch_sync_dma_for_cpu(phys_addr_t paddr, size_t size,

---
base-commit: 14131859b2615fd3076ffdad370fc5500a037432
change-id: 20250819-arm64-dma-direction-fix-7a17db452040

Best regards,
-- 
John Cox <john.cox@raspberrypi.com>

