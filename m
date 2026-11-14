From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 14 Nov 2026 00:14:25 +0000
Subject: [PATCH 1/3] iommu/vsi: Don't use the identity domain as a paging
 domain
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-iommu-vsi-fixes-v1-1-1fc7728dfd35@gmail.com>
References: <20261114-iommu-vsi-fixes-v1-0-1fc7728dfd35@gmail.com>
In-Reply-To: <20261114-iommu-vsi-fixes-v1-0-1fc7728dfd35@gmail.com>
To: Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794615264; l=3745;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=sUt1OgHP0kX/1e6KhlOzrX0uX6XICHM9fBwJZI98X+k=;
 b=uwaCK8K9u9ZhwRI7dzRczNhhRHpb3x40sz/aIThFPBAhP/hv/DTgCm1MNIOdBdTUcUnvkUANP
 si7JTA8ZdmTCN9E4fybO5+Ib64C9bgY0t7FkHdotG7PRbOxD9tdRooc
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vsi_identity_domain is a bare struct iommu_domain, but identity attach
and resume pass it to to_vsi_domain() and take the lock of that
vsi_iommu_domain, which is memory past the static domain. Identity
attach also unlinks the IOMMU from its old domain's list without that
domain's lock.

Take the old paging domain's lock to unlink the IOMMU, and only the
IOMMU lock otherwise. Resume touches neither the page tables nor the
domain's list, so it needs only the IOMMU lock.

Fixes: 917ace84b770 ("iommu: Add verisilicon IOMMU driver")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://sashiko.dev/#/patchset/20261113-vsi-iommu-pm-ref-v1-0-fd917eebdf18@gmail.com?part=1
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/iommu/vsi-iommu.c | 45 ++++++++++++++++++++++++++-------------------
 1 file changed, 26 insertions(+), 19 deletions(-)

diff --git a/drivers/iommu/vsi-iommu.c b/drivers/iommu/vsi-iommu.c
index 3dec58224953..5156e8a2e7fc 100644
--- a/drivers/iommu/vsi-iommu.c
+++ b/drivers/iommu/vsi-iommu.c
@@ -497,31 +497,42 @@ static void vsi_iommu_disable(struct vsi_iommu *iommu)
 	iommu->enable = false;
 }
 
+/* Take the IOMMU off the list of its paging domain, if it has one. */
+static void vsi_iommu_list_del(struct vsi_iommu *iommu)
+{
+	struct vsi_iommu_domain *vsi_domain;
+	unsigned long flags;
+
+	if (!iommu->domain || iommu->domain == &vsi_identity_domain)
+		return;
+
+	vsi_domain = to_vsi_domain(iommu->domain);
+	spin_lock_irqsave(&vsi_domain->lock, flags);
+	list_del_init(&iommu->node);
+	spin_unlock_irqrestore(&vsi_domain->lock, flags);
+}
+
 static int vsi_iommu_identity_attach(struct iommu_domain *domain,
 				     struct device *dev, struct iommu_domain *old)
 {
 	struct vsi_iommu *iommu = dev_iommu_priv_get(dev);
-	struct vsi_iommu_domain *vsi_domain = to_vsi_domain(domain);
 	unsigned long flags;
 	int ret;
 
+	if (iommu->domain == domain)
+		return 0;
+
 	ret = pm_runtime_resume_and_get(iommu->dev);
 	if (ret < 0)
 		return ret;
 
-	spin_lock_irqsave(&vsi_domain->lock, flags);
-	spin_lock(&iommu->lock);
-	if (iommu->domain == domain)
-		goto unlock;
+	vsi_iommu_list_del(iommu);
 
+	spin_lock_irqsave(&iommu->lock, flags);
 	vsi_iommu_disable(iommu);
-	list_del_init(&iommu->node);
-
 	iommu->domain = domain;
+	spin_unlock_irqrestore(&iommu->lock, flags);
 
-unlock:
-	spin_unlock(&iommu->lock);
-	spin_unlock_irqrestore(&vsi_domain->lock, flags);
 	pm_runtime_put_autosuspend(iommu->dev);
 	return 0;
 }
@@ -537,11 +548,12 @@ static struct iommu_domain vsi_identity_domain = {
 
 static void vsi_iommu_enable(struct vsi_iommu *iommu, struct iommu_domain *domain)
 {
-	struct vsi_iommu_domain *vsi_domain = to_vsi_domain(domain);
+	struct vsi_iommu_domain *vsi_domain;
 
 	if (domain == &vsi_identity_domain)
 		return;
 
+	vsi_domain = to_vsi_domain(domain);
 	writel(vsi_domain->pta_dma, iommu->regs + VSI_MMU_AHB_TLB_ARRAY_BASE_L_BASE);
 	writel(VSI_MMU_OUT_OF_BOUND, iommu->regs + VSI_MMU_CONFIG1_BASE);
 	writel(VSI_MMU_BIT_ENABLE, iommu->regs + VSI_MMU_AHB_EXCEPTION_BASE);
@@ -758,15 +770,10 @@ static int __maybe_unused vsi_iommu_resume(struct device *dev)
 	if (ret)
 		return ret;
 
-	if (iommu->domain) {
-		struct vsi_iommu_domain *vsi_domain = to_vsi_domain(iommu->domain);
-
-		spin_lock_irqsave(&vsi_domain->lock, flags);
-		spin_lock(&iommu->lock);
+	spin_lock_irqsave(&iommu->lock, flags);
+	if (iommu->domain)
 		vsi_iommu_enable(iommu, iommu->domain);
-		spin_unlock(&iommu->lock);
-		spin_unlock_irqrestore(&vsi_domain->lock, flags);
-	}
+	spin_unlock_irqrestore(&iommu->lock, flags);
 
 	return 0;
 }

-- 
2.55.0

