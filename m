From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 20:04:36 +0000
Subject: [PATCH 1/2] iommu/vsi: Don't leak a runtime PM reference in the
 TLB flush
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-vsi-iommu-pm-ref-v1-1-fd917eebdf18@gmail.com>
References: <20261113-vsi-iommu-pm-ref-v1-0-fd917eebdf18@gmail.com>
In-Reply-To: <20261113-vsi-iommu-pm-ref-v1-0-fd917eebdf18@gmail.com>
To: Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794600275; l=1868;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=i0Td+6MujQPe/DQQLSw3KocWhyfuPseeSSAgf/Ii2lY=;
 b=MS9jm5kQt427s30pjdB3RvqYejasoBAlixqn90BPdp56Se3+a3Gt3T+n3MbnDymK1sI+uqQ7l
 t8ZajGSwg0vBAcismXo4r9WwGpMnyZZHD2AspeX64HKwZDW4kgjBJBU
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pm_runtime_get() takes a usage reference even when it fails, e.g. with
-EINPROGRESS while a resume runs, and vsi_iommu_flush_tlb() then skips
the put. The IOMMU then never suspends again.

Flush only an active IOMMU and flush the TLB when the IOMMU is enabled,
which covers resume.

Fixes: 917ace84b770 ("iommu: Add verisilicon IOMMU driver")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/iommu/vsi-iommu.c | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/drivers/iommu/vsi-iommu.c b/drivers/iommu/vsi-iommu.c
index 5dac20b143a5..5d581be95333 100644
--- a/drivers/iommu/vsi-iommu.c
+++ b/drivers/iommu/vsi-iommu.c
@@ -369,7 +369,8 @@ static void vsi_iommu_flush_tlb(struct iommu_domain *domain)
 	struct vsi_iommu *iommu;
 
 	list_for_each_entry(iommu, &vsi_domain->iommus, node) {
-		if (pm_runtime_get(iommu->dev) < 0)
+		/* A suspended IOMMU is flushed when it resumes */
+		if (pm_runtime_get_if_active(iommu->dev) <= 0)
 			continue;
 
 		spin_lock(&iommu->lock);
@@ -545,6 +546,8 @@ static void vsi_iommu_enable(struct vsi_iommu *iommu, struct iommu_domain *domai
 	writel(VSI_MMU_OUT_OF_BOUND, iommu->regs + VSI_MMU_CONFIG1_BASE);
 	writel(VSI_MMU_BIT_ENABLE, iommu->regs + VSI_MMU_AHB_EXCEPTION_BASE);
 	writel(VSI_MMU_BIT_ENABLE, iommu->regs + VSI_MMU_AHB_CONTROL_BASE);
+	writel(VSI_MMU_BIT_FLUSH, iommu->regs + VSI_MMU_FLUSH_BASE);
+	writel(0, iommu->regs + VSI_MMU_FLUSH_BASE);
 	iommu->enable = true;
 }
 
@@ -564,8 +567,6 @@ static int vsi_iommu_attach_device(struct iommu_domain *domain,
 	spin_lock(&iommu->lock);
 
 	vsi_iommu_enable(iommu, domain);
-	writel(VSI_MMU_BIT_FLUSH, iommu->regs + VSI_MMU_FLUSH_BASE);
-	writel(0, iommu->regs + VSI_MMU_FLUSH_BASE);
 
 	list_del_init(&iommu->node);
 	list_add_tail(&iommu->node, &vsi_domain->iommus);

-- 
2.55.0

