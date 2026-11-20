From: yzddMr6 <yzddmr6@gmail.com>
Date: Fri, 20 Nov 2026 21:11:13 +0800
Subject: [PATCH] dma: swiotlb: Allocate the restricted DMA pool slot array
 with kvzalloc()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-upstream2-swiotlb-rmem-kvzalloc-v1-1-1c5f9b503223@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPBGAGsC/z2NwQ6CMBBEf4X07MZSkyb6K8bDtixSpYV0CxgJ/
 24Licc3M3mzCqboiMWtWkWk2bEbQob6VAnbYXgSuCazUFLpulYSppFTJPQKeHFD6g1ETx7e8xf
 7frDQamu0bUle8SKyZYzUus/+cH8czJN5kU1FWxYGmcBEDLYr0f/gvBeNRzgE2/YDw9xPX64AA
 AA=
X-Change-ID: 20261120-upstream2-swiotlb-rmem-kvzalloc-f6cb6cfe09a3
To: Marek Szyprowski <m.szyprowski@samsung.com>
Cc: Robin Murphy <robin.murphy@arm.com>, iommu@lists.linux.dev, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 yzddMr6 <yzddmr6@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795180275; l=3849;
 i=yzddmr6@gmail.com; s=20261028; h=from:subject:message-id;
 bh=CPGhP9PgqwLV82rbpKPFM4Th44lDe4QRFF5asZn42MY=;
 b=Ow366SDm/ZOCDPPCbunnu6HYWImiPaNgVhqeHKHadkj4UG2OwV+IbW2/7CKSoXvr/sm2/5n7/
 U3bfDna9DUaAt7hbd45wHa8yrBoGwuijQD5CrTrXNcyUlbohgoKgUfW
X-Developer-Key: i=yzddmr6@gmail.com; a=ed25519;
 pk=QLT2mwairk4R38oU379hkHynqjoLrlqd0Cl1ERUqIqY=
X-Endpoint-Received: by B4 Relay for yzddmr6@gmail.com/20261028 with auth_id=1489
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rmem_swiotlb_device_init() allocates one struct io_tlb_slot per 2 KiB
slot of a restricted DMA pool with kzalloc(). The struct is 24 bytes on
64-bit, so with 4 KiB pages and the default MAX_PAGE_ORDER of 10 the
array is larger than KMALLOC_MAX_SIZE (4 MiB) for any pool above about
341 MiB. For such a pool kzalloc() refuses the request with a
WARN_ON_ONCE() in ___kmalloc_large_node(), the pool is not set up, and
of_dma_set_restricted_buffer() warns that it failed to initialise the
pool. The devices assigned to it then lose the restriction without
their probe failing, and use the default DMA path.

The slot array is only accessed by the CPU and does not need to be
physically contiguous. Allocate it with kvzalloc_objs() and free it with
kvfree(). The other pools are not affected: the slot array of the
default pool comes from memblock, and the buffers of late and dynamic
pools are limited to MAX_PAGE_ORDER, which keeps their slot arrays
small.

Pools of this size are needed when large buffers go through the pool
for their whole lifetime: this was hit with an arm64 Gunyah protected
VM whose virtio-gpu resources stay mapped in the pool, and a desktop at
3392x2400 needed more than 341 MiB.

The problem was analysed and this change written with the help of an
AI coding assistant.

Fixes: 0b84e4f8b793 ("swiotlb: Add restricted DMA pool initialization")
Cc: stable@vger.kernel.org
Signed-off-by: yzddMr6 <yzddmr6@gmail.com>
---
Reproduced in QEMU on the base commit below (arm64 defconfig, 4 KiB
pages): virt machine with 2 GiB, a 512 MiB restricted-dma-pool added to
the DT and referenced by every virtio_mmio node, one virtio-rng device
with iommu_platform=on (modern virtio-mmio, so VIRTIO_F_ACCESS_PLATFORM
is negotiated), and swiotlb=track_hiwater. Without this patch the WARN in
___kmalloc_large_node() fires, every transport reports "failed to
initialise "restricted-dma-pool" memory node", no debugfs directory is
created for the pool, and reading /dev/hwrng works without any bounce
(io_tlb_used_hiwater of the default pool stays 0). With it there is no
warning, every transport is assigned the pool, and its debugfs
directory shows 262144 slots, with io_tlb_used_hiwater already at 17
once virtio-rng has probed. W=1 shows no new warnings in kernel/dma/.

The change is also used in the guest kernel of the Gunyah VMs
mentioned above.

I used an AI coding assistant for this work. It analysed the failure,
wrote this patch and changelog and set up the QEMU reproducer. I have
reviewed the change.
---
 kernel/dma/swiotlb.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/kernel/dma/swiotlb.c b/kernel/dma/swiotlb.c
index 786954bc5e6a..51c7c064b62f 100644
--- a/kernel/dma/swiotlb.c
+++ b/kernel/dma/swiotlb.c
@@ -2042,7 +2042,7 @@ static int rmem_swiotlb_device_init(struct reserved_mem *rmem,
 			return -ENOMEM;
 		pool = &mem->defpool;
 
-		pool->slots = kzalloc_objs(*pool->slots, nslabs);
+		pool->slots = kvzalloc_objs(*pool->slots, nslabs);
 		if (!pool->slots) {
 			kfree(mem);
 			return -ENOMEM;
@@ -2050,7 +2050,7 @@ static int rmem_swiotlb_device_init(struct reserved_mem *rmem,
 
 		pool->areas = kzalloc_objs(*pool->areas, nareas);
 		if (!pool->areas) {
-			kfree(pool->slots);
+			kvfree(pool->slots);
 			kfree(mem);
 			return -ENOMEM;
 		}
@@ -2067,7 +2067,7 @@ static int rmem_swiotlb_device_init(struct reserved_mem *rmem,
 			if (ret) {
 				dev_err(dev, "Failed to decrypt restricted DMA pool\n");
 				kfree(pool->areas);
-				kfree(pool->slots);
+				kvfree(pool->slots);
 				kfree(mem);
 				return ret;
 			}

---
base-commit: 14866e632fa48a0b4c385ab0121526575eb8f88c
change-id: 20261120-upstream2-swiotlb-rmem-kvzalloc-f6cb6cfe09a3

Best regards,
--  
yzddMr6 <yzddmr6@gmail.com>

