From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 09 Sep 2025 10:58:01 +0200
Subject: [PATCH] intel/vt-d: Send Page Request Drain only if supported
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250909-jag-pds-v1-1-ad8cba0e494e@kernel.org>
X-B4-Tracking: v=1; b=H4sIABjsv2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDSwNL3azEdN2ClGJd8xQL0yQzg8QUyxQjJaDqgqLUtMwKsEnRsbW1APN
 AWXlZAAAA
X-Change-ID: 20250909-jag-pds-7d85b60ad9d2
To: David Woodhouse <dwmw2@infradead.org>, 
 Lu Baolu <baolu.lu@linux.intel.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1333;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=R84Vk67aONLqs9yimOEnlLpQaSiDWiX/yLC0yfwDvQg=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGi/7DWIt1dxbKK1nES9puS/0fThmuhAYzX+C
 KcoH0a+wd/n7okBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJov+w1AAoJELqXzVK3
 lkFP5hML/RA+hoWbDh4Sjga0mdO0hQB0LiYXRME/LTlVph89SDbZ8jSCT0qO7IY+reePdmmoikV
 onj5AofS+EKfs1v/eEIR7RatVbIA1E4LIu08JYArFUDAu2T8Nwfvzy+qipRCxmwPSlWzx6ZMlf3
 l1KQW7hJS+5NMq8GrD7AXwmZhy+RjviHRoLwQ1ENenOxR6Q6xqFRF3pgi2/wdtXmOpTdjDk3tOq
 wsh69V2ayejpTCtawtNeBp13p3hdKCo30gmtKEeDc537JInEKXuj3iMT+fZm+5oYyfbN7YtAZh2
 3I4T1Wks2opapNkdksLunm0FOw8q0RM3arMO8AqToBf2YteaQ9QZe/YQS+Ye7As9Q3QGXM2RAZA
 5+KVd2GKM68juxuSUUh5f/Ym/d+W02ZUi36c3METWuF9n3rMXOgf5DzVGhnlrr4GyLwrp/ARQpS
 amSxE23nSVOgb5sVPkYrVJ/snxWte190HsgaqDXPfjAVdTFd20IjDboLAUx6781f5brfaelHGd7
 d0=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The intel_iommu_drain_pasid_prq function sends QI_OPT_WAIT_DRAIN to
hardware without verifying Page Request Drain Support (PDS). According
to VT-d specification section 6.5.2.8, PRQ drain functionality should
only be used when PDS (bit 42) is set in the extended capability
register. Add ecap_pds() check to conditionally use QI_OPT_WAIT_DRAIN
based on hardware capability.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/iommu/intel/prq.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iommu/intel/prq.c b/drivers/iommu/intel/prq.c
index 52570e42a14c05b7492957909568805dc9c7b6ef..f89916de31a3439866f059f5400e45fb362a6a7d 100644
--- a/drivers/iommu/intel/prq.c
+++ b/drivers/iommu/intel/prq.c
@@ -119,7 +119,7 @@ void intel_iommu_drain_pasid_prq(struct device *dev, u32 pasid)
 	}
 qi_retry:
 	reinit_completion(&iommu->prq_complete);
-	qi_submit_sync(iommu, desc, 3, QI_OPT_WAIT_DRAIN);
+	qi_submit_sync(iommu, desc, 3, ecap_pds(iommu->ecap) ? QI_OPT_WAIT_DRAIN : 0);
 	if (readl(iommu->reg + DMAR_PRS_REG) & DMA_PRS_PRO) {
 		wait_for_completion(&iommu->prq_complete);
 		goto qi_retry;

---
base-commit: f777d1112ee597d7f7dd3ca232220873a34ad0c8
change-id: 20250909-jag-pds-7d85b60ad9d2

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

