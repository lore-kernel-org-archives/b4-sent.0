From: Suyuan Wang <shyckless@gmail.com>
Date: Mon, 23 Nov 2026 00:43:23 +0000
Subject: [PATCH] RDMA/mthca: Free the AV table index if kmalloc fails in
 create_ah
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-mthca-v1-1-506d3c3a7d4e@gmail.com>
X-B4-Tracking: v=1; b=H4sIACqMA2sC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyNj3dySjOREXTMDS0NToyTDZIvURCWg2oKi1LTMCrA50bEQfnFpUlZ
 qcglIs1JtLQB5iu6DaQAAAA==
X-Change-ID: 20261123-mthca-609152b1c8ea
To: jgg@ziepe.ca, leon@kernel.org
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795394602; l=1724;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=EGEqNSPKVCYN2FXlRYLvj7sqk9iwm3B+WQLsdldjfns=;
 b=ASVARoyNrqVBrE8R6tcfCPwQRJvOWtp5Zi1GUUtLlCmd50LmskhKkZ0IXzfCmqdomYPJkTMkD
 PaDonl9iNTBB6I8otZvtfJyEC5GOPinti6Lu8Na4b0//bL4F+FrQYP6
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

When an address handle can be stored in HCA memory, mthca_create_ah()
first takes an index from the AV table and then allocates a temporary
AV buffer:

	index = mthca_alloc(&dev->av_table.alloc);
	...
	av = kmalloc_obj(*av, GFP_ATOMIC);
	if (!av)
		goto on_hca_fail;

If the allocation fails, the code falls back to the PCI pool and
ah->type stays MTHCA_AH_PCI_POOL. mthca_destroy_ah() then frees the
pool entry but never the AV table index, so the index is lost for
good. The allocation is GFP_ATOMIC, so it can fail under memory
pressure, and repeated failures can exhaust the free on-HCA AV indices
until no new on-HCA address handle can be created.

Return the index to the allocator before falling back.

Found with a static analysis tool and checked by hand.

Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on x86_64 (W=1). I don't have the hardware.
---
 drivers/infiniband/hw/mthca/mthca_av.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/infiniband/hw/mthca/mthca_av.c b/drivers/infiniband/hw/mthca/mthca_av.c
index 83a7ba41fa04..a90b3e75cf00 100644
--- a/drivers/infiniband/hw/mthca/mthca_av.c
+++ b/drivers/infiniband/hw/mthca/mthca_av.c
@@ -176,8 +176,10 @@ int mthca_create_ah(struct mthca_dev *dev,
 			goto on_hca_fail;
 
 		av = kmalloc_obj(*av, GFP_ATOMIC);
-		if (!av)
+		if (!av) {
+			mthca_free(&dev->av_table.alloc, index);
 			goto on_hca_fail;
+		}
 
 		ah->type = MTHCA_AH_ON_HCA;
 		ah->avdma  = dev->av_table.ddr_av_base +



