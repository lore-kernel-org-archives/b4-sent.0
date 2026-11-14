From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 14 Nov 2026 00:14:26 +0000
Subject: [PATCH 2/3] iommu/vsi: Unlink the IOMMU from its old domain under
 that domain's lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-iommu-vsi-fixes-v1-2-1fc7728dfd35@gmail.com>
References: <20261114-iommu-vsi-fixes-v1-0-1fc7728dfd35@gmail.com>
In-Reply-To: <20261114-iommu-vsi-fixes-v1-0-1fc7728dfd35@gmail.com>
To: Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794615264; l=1234;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=kspvKLgpotcfNu/d6d7HQui+izuIuODftxK9VojqQOs=;
 b=CmLw+MPs+6LaMoyRA5j4mUiHfYHHT2bNWj/ceD2ckX33Nt/dSBE3K89W2t2yW4zHy7jVTscFc
 Y2i5pFmAXoTCdmX80mSiR2pwibESzDrwUv/DKCgWQED+De3WSdFo6Tc
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Attaching a paging domain moves iommu->node to the new domain's list
holding only the new domain's lock. A concurrent map or unmap on the old
domain walks the old list in vsi_iommu_flush_tlb() and can follow the
moved node into the new list.

Unlink the IOMMU under the old domain's lock first.

Fixes: 917ace84b770 ("iommu: Add verisilicon IOMMU driver")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-206639@kernel.org/
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/iommu/vsi-iommu.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/iommu/vsi-iommu.c b/drivers/iommu/vsi-iommu.c
index 5156e8a2e7fc..8a0f253f2017 100644
--- a/drivers/iommu/vsi-iommu.c
+++ b/drivers/iommu/vsi-iommu.c
@@ -575,12 +575,13 @@ static int vsi_iommu_attach_device(struct iommu_domain *domain,
 	if (ret < 0)
 		return ret;
 
+	vsi_iommu_list_del(iommu);
+
 	spin_lock_irqsave(&vsi_domain->lock, flags);
 	spin_lock(&iommu->lock);
 
 	vsi_iommu_enable(iommu, domain);
 
-	list_del_init(&iommu->node);
 	list_add_tail(&iommu->node, &vsi_domain->iommus);
 
 	iommu->domain = domain;

-- 
2.55.0

