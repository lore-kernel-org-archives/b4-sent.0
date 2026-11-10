From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 06:05:18 +0000
Subject: [PATCH 2/2] iommu/sun50i: Print the page table level and status of
 a fault
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-sun50i-iommu-prefetch-v1-2-43428e792ef6@gmail.com>
References: <20261110-sun50i-iommu-prefetch-v1-0-43428e792ef6@gmail.com>
In-Reply-To: <20261110-sun50i-iommu-prefetch-v1-0-43428e792ef6@gmail.com>
To: "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>
Cc: iommu@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794290717; l=3756;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=FOk5fAnA+iXFlIIjGN70elq+MDZGG6Z5UuNNT5KUp+4=;
 b=Ke401L8ggwrBzgJ1veTdvXAv5Z7iGVXZAsKveDTuHCUhkwNwL6vwmYSTaDdhto2pYI48JS9Zx
 oqKynhLPP7LBfZC3PeHv56uwETGl3It0XY7iTMOBrtxGTfivIU5eFbo
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A page table fault that the hardware does not attribute to a master is
currently printed with master ilog2(0) = -1 and nothing else, which says
neither which walk failed nor what the interrupt register held. Name the
level (L1 or L2 page table, or permission) and print the raw blame
register next to the master, and print -1 explicitly when no master bit
is set, so such a fault is still diagnosable.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/iommu/sun50i-iommu.c | 31 ++++++++++++++++++-------------
 1 file changed, 18 insertions(+), 13 deletions(-)

diff --git a/drivers/iommu/sun50i-iommu.c b/drivers/iommu/sun50i-iommu.c
index 1b7a7f0d9b62..47e398e25a51 100644
--- a/drivers/iommu/sun50i-iommu.c
+++ b/drivers/iommu/sun50i-iommu.c
@@ -874,11 +874,13 @@ static const struct iommu_ops sun50i_iommu_ops = {
 };
 
 static void sun50i_iommu_report_fault(struct sun50i_iommu *iommu,
-				      unsigned master, phys_addr_t iova,
-				      unsigned prot)
+				      int master, phys_addr_t iova,
+				      unsigned int prot, const char *type,
+				      u32 status)
 {
-	dev_err(iommu->dev, "Page fault for %pad (master %d, dir %s)\n",
-		&iova, master, (prot == IOMMU_FAULT_WRITE) ? "wr" : "rd");
+	dev_err(iommu->dev, "Page fault for %pad (master %d, dir %s, %s, status %#x)\n",
+		&iova, master, (prot == IOMMU_FAULT_WRITE) ? "wr" : "rd",
+		type, status);
 
 	if (iommu->domain)
 		report_iommu_fault(iommu->domain, iommu->dev, iova, prot);
@@ -890,10 +892,11 @@ static void sun50i_iommu_report_fault(struct sun50i_iommu *iommu,
 
 static phys_addr_t sun50i_iommu_handle_pt_irq(struct sun50i_iommu *iommu,
 					      unsigned addr_reg,
-					      unsigned blame_reg)
+					      unsigned int blame_reg,
+					      const char *level)
 {
 	phys_addr_t iova;
-	unsigned master;
+	int master = -1;
 	u32 blame;
 
 	assert_spin_locked(&iommu->iommu_lock);
@@ -909,19 +912,21 @@ static phys_addr_t sun50i_iommu_handle_pt_irq(struct sun50i_iommu *iommu,
 	 * stalled or cached, so there is nothing to report, reset or zap.
 	 */
 	if ((blame & IOMMU_PG_INT_PREFETCH) && !(blame & IOMMU_INT_MASTER_MASK)) {
-		dev_dbg_ratelimited(iommu->dev, "page table prefetch of unmapped %pad\n",
-				    &iova);
+		dev_dbg_ratelimited(iommu->dev, "%s prefetch of unmapped %pad\n",
+				    level, &iova);
 		return iova;
 	}
 
-	master = ilog2(blame & IOMMU_INT_MASTER_MASK);
+	if (blame & IOMMU_INT_MASTER_MASK)
+		master = ilog2(blame & IOMMU_INT_MASTER_MASK);
 
 	/*
 	 * If the address is not in the page table, we can't get what
 	 * operation triggered the fault. Assume it's a read
 	 * operation.
 	 */
-	sun50i_iommu_report_fault(iommu, master, iova, IOMMU_FAULT_READ);
+	sun50i_iommu_report_fault(iommu, master, iova, IOMMU_FAULT_READ, level,
+				  blame);
 
 	return iova;
 }
@@ -976,7 +981,7 @@ static phys_addr_t sun50i_iommu_handle_perm_irq(struct sun50i_iommu *iommu)
 	 * operation triggered the fault. Assume it's a read
 	 * operation.
 	 */
-	sun50i_iommu_report_fault(iommu, master, iova, dir);
+	sun50i_iommu_report_fault(iommu, master, iova, dir, "permission", blame);
 
 	return iova;
 }
@@ -1000,11 +1005,11 @@ static irqreturn_t sun50i_iommu_irq(int irq, void *dev_id)
 	if (status & IOMMU_INT_INVALID_L2PG)
 		sun50i_iommu_handle_pt_irq(iommu,
 					    IOMMU_INT_ERR_ADDR_L2_REG,
-					    IOMMU_L2PG_INT_REG);
+					    IOMMU_L2PG_INT_REG, "L2 page table");
 	else if (status & IOMMU_INT_INVALID_L1PG)
 		sun50i_iommu_handle_pt_irq(iommu,
 					   IOMMU_INT_ERR_ADDR_L1_REG,
-					   IOMMU_L1PG_INT_REG);
+					   IOMMU_L1PG_INT_REG, "L1 page table");
 	else
 		sun50i_iommu_handle_perm_irq(iommu);
 

-- 
2.55.0

