From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 14 Nov 2026 00:14:27 +0000
Subject: [PATCH 3/3] iommu/vsi: Unprepare the clocks when getting the IRQ
 fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-iommu-vsi-fixes-v1-3-1fc7728dfd35@gmail.com>
References: <20261114-iommu-vsi-fixes-v1-0-1fc7728dfd35@gmail.com>
In-Reply-To: <20261114-iommu-vsi-fixes-v1-0-1fc7728dfd35@gmail.com>
To: Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794615264; l=877;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=JBjjSQ7lBXTycTG2n7hcuVyoF1r2DyekbYpAYIdEgaQ=;
 b=3kpB/dvSubGhVQl4Bfk+/9p5oeKTAng3VYIHXpcHP7telMScnNimJtDwee2sxd01BWgdGZ624
 8O+0aeHa86ICQFMB5b3v7pi0iFbK2N91Bsb3WV/XHIHfeXkAsZqaEPJ
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vsi_iommu_probe() returns without clk_bulk_unprepare() when
platform_get_irq() fails.

Fixes: 917ace84b770 ("iommu: Add verisilicon IOMMU driver")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/iommu/vsi-iommu.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/iommu/vsi-iommu.c b/drivers/iommu/vsi-iommu.c
index 8a0f253f2017..579eb1ab5683 100644
--- a/drivers/iommu/vsi-iommu.c
+++ b/drivers/iommu/vsi-iommu.c
@@ -707,8 +707,10 @@ static int vsi_iommu_probe(struct platform_device *pdev)
 		return err;
 
 	iommu->irq = platform_get_irq(pdev, 0);
-	if (iommu->irq < 0)
-		return iommu->irq;
+	if (iommu->irq < 0) {
+		err = iommu->irq;
+		goto err_unprepare_clocks;
+	}
 
 	err = devm_request_irq(iommu->dev, iommu->irq, vsi_iommu_irq,
 			       IRQF_SHARED, dev_name(dev), iommu);

-- 
2.55.0

