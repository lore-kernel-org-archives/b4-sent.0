From: Joel Granados <j.granados@samsung.com>
Date: Fri, 28 Jun 2024 14:27:43 +0200
Subject: [PATCH RFC 5/5] iommu/vt-d: Remove dev_iommu_priv_get call from
 domain_get_id_for_dev
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240628-jag-revisit_cache_tag_assign-v1-5-a0c19063c983@samsung.com>
References: <20240628-jag-revisit_cache_tag_assign-v1-0-a0c19063c983@samsung.com>
In-Reply-To: <20240628-jag-revisit_cache_tag_assign-v1-0-a0c19063c983@samsung.com>
To: David Woodhouse <dwmw2@infradead.org>, 
 Lu Baolu <baolu.lu@linux.intel.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1737;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=bSKT5KATPjuI2PxohgEgtnVEXQsN8h24B4pOY9NhzjU=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGZ+rEF2V7Oo9xvBBkRnBcyi7uYIJn2E2BmRL
 zd6A97flRB21YkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmfqxBAAoJELqXzVK3
 lkFPc4sL/RP2u/N7pZpUkjwF9ibuOdDKPQq0mcziIN7z5zfCccwR8R5f28tiBqm36muQHDl3qVE
 b827WJyDMCL/DX2xxrJTBpjp5dK0mHykkG3RJ4RCV8FawkmJf7dZus7Knc80cToJNl+7baUGdFP
 0iOflA4jFxAIOQRS03F4+gj6NLIwkskCHNi/WQFz+pbkia1uBdd3swWzbqIAygVmswB0blfRN6U
 rkOc0E3WRWU6dGBigInYECE2YF1z14kJwzScXiptlXUP/5jSi2f65k0iwlK1CV4pBVVNN/USNO5
 vemGoTl1yPL8RCHMoLShNtc4Z1unj6CK7zCn6QsanxX49UT0Gp2/yOxZDb0ZrDHLNzB0K1G9TBO
 YhntrSay+2lqRYzp2s+QIAkhKLkLWGdvCrxpnvMN4cx+E05EKMo5oug1tfRQ4ISCwz9Yh0R+Kkr
 epg/Nod559pIr+Um5Yx6eWnjR6msc473VzqHPXAilzwSkwnxds3QegrN+CospmIlMhmle9VBof4
 8I=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We don't need to run dev_iommu_priv_get as we already have the struct
intel_iommu. Pass the intel_iommu instead of the device and rename the
function to domain_id_for_iommu to express what it is really doing.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/iommu/intel/cache.c | 10 ++++------
 1 file changed, 4 insertions(+), 6 deletions(-)

diff --git a/drivers/iommu/intel/cache.c b/drivers/iommu/intel/cache.c
index c630f4485a06..e55d700fcd29 100644
--- a/drivers/iommu/intel/cache.c
+++ b/drivers/iommu/intel/cache.c
@@ -147,11 +147,9 @@ static void __cache_tag_unassign_parent_domain(struct dmar_domain *domain,
 		cache_tag_unassign_type(domain, tag_id, CACHE_TAG_NESTING_DEVTLB);
 }
 
-static u16 domain_get_id_for_dev(struct dmar_domain *domain, struct device *dev)
+static u16 domain_id_for_iommu(struct dmar_domain *domain,
+			       struct intel_iommu *iommu)
 {
-	struct device_domain_info *info = dev_iommu_priv_get(dev);
-	struct intel_iommu *iommu = info->iommu;
-
 	/*
 	 * The driver assigns different domain IDs for all domains except
 	 * the SVA type.
@@ -178,7 +176,7 @@ int cache_tag_assign_domain(struct dmar_domain *domain,
 		.pasid = pasid,
 		.iommu = info->iommu,
 		.dev = dev,
-		.domain_id = domain_get_id_for_dev(domain, dev),
+		.domain_id = domain_id_for_iommu(domain, info->iommu),
 	};
 	int ret;
 
@@ -209,7 +207,7 @@ void cache_tag_unassign_domain(struct dmar_domain *domain,
 		.pasid = pasid,
 		.iommu = info->iommu,
 		.dev = dev,
-		.domain_id = domain_get_id_for_dev(domain, dev)
+		.domain_id = domain_id_for_iommu(domain, info->iommu)
 	};
 
 	__cache_tag_unassign_domain(domain, &tag_id, info->ats_enabled);

-- 
2.43.0

