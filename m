From: Joel Granados <j.granados@samsung.com>
Date: Fri, 28 Jun 2024 14:27:42 +0200
Subject: [PATCH RFC 4/5] iommu/vt-d: Use ats_enable as an argument
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240628-jag-revisit_cache_tag_assign-v1-4-a0c19063c983@samsung.com>
References: <20240628-jag-revisit_cache_tag_assign-v1-0-a0c19063c983@samsung.com>
In-Reply-To: <20240628-jag-revisit_cache_tag_assign-v1-0-a0c19063c983@samsung.com>
To: David Woodhouse <dwmw2@infradead.org>, 
 Lu Baolu <baolu.lu@linux.intel.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3905;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=hio8w1SDQJuW7Ys9C3jM+VXzxzsPd2lcrv4x7GWHRTI=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGZ+rEDkqOIvynV0g/qnndBqQ0i8IEKRJ5coo
 KT42/eia1n+CokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmfqxAAAoJELqXzVK3
 lkFPcw0MAIFM16hWhkf04N2YmO5Lgfv9g8UJNnXRrhgj7dDkbQPxjpkNIPE++iu0cfVrcaLQ0Xu
 IuiSoZD7FUO1o5qLL/3u5K5MgzGIhhwce4bvvl+UzQ4z/2pABYCG0PvmCVb0/0JKFUUrMkQcVWf
 mVsWt+Mhgs3C+z3f0MuvvlIAhNrz7ujjo/QSKOMQA46V3IdRrfiwvdRGARJKCnmSBF5sh9XeUWy
 Qaz4ngg7u6TEPA4E96YyIVp0i0EKlVEHzDKTjeMwyK+or0ZdKaLlzUR1ttLoyg/E/6CW6CdqyYi
 IaG/L6RuF091B6JfJZFiuITB6qRwScCiB9q7LzGH6iEmKhgrYeSNXkt5dNdST8PoqTFgXCtwP+Q
 RYYeJMyHuoIQzOtDqbG6P/Z954YP+l+7+hUMazyUFwPKFVnDOpmJ4GolYCkRsNr9XIsAsIwuHAk
 1Q7rW+QNm+V6FmaSt47SG95dd73v5Tp6YiTYPMguMabQ10DuJW9AeDTvPDTbsOnVVyxGg+5i1Z6
 U4=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pass the ats_enabled flag as a function argument instead of calling
dev_iommu_priv_get.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/iommu/intel/cache.c | 38 +++++++++++++++++++-------------------
 1 file changed, 19 insertions(+), 19 deletions(-)

diff --git a/drivers/iommu/intel/cache.c b/drivers/iommu/intel/cache.c
index eb409a296e43..c630f4485a06 100644
--- a/drivers/iommu/intel/cache.c
+++ b/drivers/iommu/intel/cache.c
@@ -96,13 +96,13 @@ static void cache_tag_unassign_type(struct dmar_domain *domain,
 }
 
 static int __cache_tag_assign_domain(struct dmar_domain *domain,
-				     struct cache_tag_id *new_tag_id)
+				     struct cache_tag_id *new_tag_id,
+				     const bool ats_enabled)
 {
-	struct device_domain_info *info = dev_iommu_priv_get(new_tag_id->dev);
 	int ret;
 
 	ret = cache_tag_assign_type(domain, new_tag_id, CACHE_TAG_IOTLB);
-	if (ret || !info->ats_enabled)
+	if (ret || !ats_enabled)
 		return ret;
 
 	ret = cache_tag_assign_type(domain, new_tag_id, CACHE_TAG_DEVTLB);
@@ -113,23 +113,22 @@ static int __cache_tag_assign_domain(struct dmar_domain *domain,
 }
 
 static void __cache_tag_unassign_domain(struct dmar_domain *domain,
-					struct cache_tag_id *tag_id)
+					struct cache_tag_id *tag_id,
+					const bool ats_enabled)
 {
-	struct device_domain_info *info = dev_iommu_priv_get(tag_id->dev);
-
 	cache_tag_unassign_type(domain, tag_id, CACHE_TAG_IOTLB);
-	if (info->ats_enabled)
+	if (ats_enabled)
 		cache_tag_unassign_type(domain, tag_id, CACHE_TAG_DEVTLB);
 }
 
 static int __cache_tag_assign_parent_domain(struct dmar_domain *domain,
-					    struct cache_tag_id *new_tag_id)
+					    struct cache_tag_id *new_tag_id,
+					    const bool ats_enabled)
 {
-	struct device_domain_info *info = dev_iommu_priv_get(new_tag_id->dev);
 	int ret;
 
 	ret = cache_tag_assign_type(domain, new_tag_id, CACHE_TAG_NESTING_IOTLB);
-	if (ret || !info->ats_enabled)
+	if (ret || !ats_enabled)
 		return ret;
 
 	ret = cache_tag_assign_type(domain, new_tag_id, CACHE_TAG_NESTING_DEVTLB);
@@ -140,12 +139,11 @@ static int __cache_tag_assign_parent_domain(struct dmar_domain *domain,
 }
 
 static void __cache_tag_unassign_parent_domain(struct dmar_domain *domain,
-					       struct cache_tag_id *tag_id)
+					       struct cache_tag_id *tag_id,
+					       const bool ats_enabled)
 {
-	struct device_domain_info *info = dev_iommu_priv_get(tag_id->dev);
-
 	cache_tag_unassign_type(domain, tag_id, CACHE_TAG_NESTING_IOTLB);
-	if (info->ats_enabled)
+	if (ats_enabled)
 		cache_tag_unassign_type(domain, tag_id, CACHE_TAG_NESTING_DEVTLB);
 }
 
@@ -184,13 +182,14 @@ int cache_tag_assign_domain(struct dmar_domain *domain,
 	};
 	int ret;
 
-	ret = __cache_tag_assign_domain(domain, &new_tag_id);
+	ret = __cache_tag_assign_domain(domain, &new_tag_id, info->ats_enabled);
 	if (ret || domain->domain.type != IOMMU_DOMAIN_NESTED)
 		return ret;
 
-	ret = __cache_tag_assign_parent_domain(domain->s2_domain, &new_tag_id);
+	ret = __cache_tag_assign_parent_domain(domain->s2_domain, &new_tag_id,
+					       info->ats_enabled);
 	if (ret)
-		__cache_tag_unassign_domain(domain, &new_tag_id);
+		__cache_tag_unassign_domain(domain, &new_tag_id, info->ats_enabled);
 
 	return ret;
 }
@@ -213,9 +212,10 @@ void cache_tag_unassign_domain(struct dmar_domain *domain,
 		.domain_id = domain_get_id_for_dev(domain, dev)
 	};
 
-	__cache_tag_unassign_domain(domain, &tag_id);
+	__cache_tag_unassign_domain(domain, &tag_id, info->ats_enabled);
 	if (domain->domain.type == IOMMU_DOMAIN_NESTED)
-		__cache_tag_unassign_parent_domain(domain->s2_domain, &tag_id);
+		__cache_tag_unassign_parent_domain(domain->s2_domain, &tag_id,
+						   info->ats_enabled);
 }
 
 static unsigned long calculate_psi_aligned_address(unsigned long start,

-- 
2.43.0

