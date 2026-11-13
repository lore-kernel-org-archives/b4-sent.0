From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 20:04:37 +0000
Subject: [PATCH 2/2] iommu/vsi: Don't resume the IOMMU in its interrupt
 handler
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-vsi-iommu-pm-ref-v1-2-fd917eebdf18@gmail.com>
References: <20261113-vsi-iommu-pm-ref-v1-0-fd917eebdf18@gmail.com>
In-Reply-To: <20261113-vsi-iommu-pm-ref-v1-0-fd917eebdf18@gmail.com>
To: Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794600275; l=827;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=WTwZnHxIRE4pAuSff5z0uY+0kBdGQgUKwB9X8xak2LE=;
 b=louZVW1zyVrXM2EJ1hqLYg09BtlMHeNjToEEW5k+ngtDcqdnzYQfUUXZBGZX2gvZLjtOb862S
 IZSZOEpGGiJCkjwvxbqkWuhGoOx/5R4R+q8VaD2EL0HK/EDxlGxNYKP
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The interrupt handler calls pm_runtime_resume_and_get(), which can
sleep, in hard IRQ context. Handle the interrupt only if the IOMMU is
active.

Fixes: 917ace84b770 ("iommu: Add verisilicon IOMMU driver")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/iommu/vsi-iommu.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iommu/vsi-iommu.c b/drivers/iommu/vsi-iommu.c
index 5d581be95333..3dec58224953 100644
--- a/drivers/iommu/vsi-iommu.c
+++ b/drivers/iommu/vsi-iommu.c
@@ -196,7 +196,7 @@ static irqreturn_t vsi_iommu_irq(int irq, void *dev_id)
 	dma_addr_t iova;
 	u32 status;
 
-	if (pm_runtime_resume_and_get(iommu->dev) < 0)
+	if (pm_runtime_get_if_active(iommu->dev) <= 0)
 		return IRQ_NONE;
 
 	spin_lock_irqsave(&iommu->lock, flags);

-- 
2.55.0

