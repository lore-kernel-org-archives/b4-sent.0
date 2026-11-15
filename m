From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 16 Nov 2026 01:49:43 +0530
Subject: [PATCH] iommu/arm-smmu-qcom: Add Kaanapali MDSS to the client
 match table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-molokai-smmu-v1-1-54b682313b66@yahoo.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0Mz3dz8nPzsxEzd4tzcUl3T5ERDy9TElCSTtBQloJaCotS0zAqwcdG
 xEH5xaVJWanIJyAyl2loASejl2HAAAAA=
X-Change-ID: 20261116-molokai-smmu-5ca19eadb4fd
To: Rob Clark <robin.clark@oss.qualcomm.com>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, "Joerg Roedel (AMD)" <joro@8bytes.org>
Cc: iommu@lists.linux.dev, linux-arm-msm@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794773982; l=1779;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=tu+NFiw+fOcsWLYvR0WEdnLT33HysKPDUYnretNByDs=;
 b=usbyYu8k6ChN1bte4HvsGANsBt1ix37tDWesx4q+KT/zXgFn31cltG79xKwaZgpNHvZ8W++10
 DmrUBdISdqdDjCahETGzpqd0el2vERJN6CcIqrwg1/QQPkxdppHSk2G
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The display subsystem on Kaanapali scans out the bootloader's splash
screen through the application SMMU. Use an identity domain for it like
on the other Qualcomm platforms, so the handover to the display driver
does not cause faults.

An LLM was used to help write this commit message.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
The display subsystem of Kaanapali, and of Molokai (SM8845) which reuses
it, scans out the bootloader's splash screen through the application
SMMU. Without the identity domain the handover to the display driver
faults, like on the other Qualcomm platforms already in the table.

Tested on the Motorola Signature (Molokai), where the display subsystem
comes up through the application SMMU with it.

I used an LLM (Claude) to help write this patch and its commit message.
I reviewed it and tested the result on the device.
---
 drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c b/drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c
index 795e8ec7e8fa..0ee9a9cfdf8e 100644
--- a/drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c
+++ b/drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c
@@ -407,6 +407,7 @@ static const struct of_device_id qcom_smmu_client_of_match[] __maybe_unused = {
 	{ .compatible = "qcom,adreno" },
 	{ .compatible = "qcom,adreno-gmu" },
 	{ .compatible = "qcom,glymur-mdss" },
+	{ .compatible = "qcom,kaanapali-mdss" },
 	{ .compatible = "qcom,mdp4" },
 	{ .compatible = "qcom,mdss" },
 	{ .compatible = "qcom,qcm2290-mdss" },

---
base-commit: 2cf4be57b301ed2d7af82e70cff5dfd96894d8de
change-id: 20261116-molokai-smmu-5ca19eadb4fd

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

