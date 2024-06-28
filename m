From: Joel Granados <j.granados@samsung.com>
Date: Fri, 28 Jun 2024 14:27:41 +0200
Subject: [PATCH RFC 3/5] iommu/vt-d: Pass cache_tag_id to {un}assignment
 functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240628-jag-revisit_cache_tag_assign-v1-3-a0c19063c983@samsung.com>
References: <20240628-jag-revisit_cache_tag_assign-v1-0-a0c19063c983@samsung.com>
In-Reply-To: <20240628-jag-revisit_cache_tag_assign-v1-0-a0c19063c983@samsung.com>
To: David Woodhouse <dwmw2@infradead.org>, 
 Lu Baolu <baolu.lu@linux.intel.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=8380;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=VJrhxLNxW8HI5m/DeBVEAQusP+0q9BVObAY0Jv2AWqs=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGZ+rD7VrAJE58mEa+stecuzCUGdKNn5YDEM8
 U7bytv6gOZOuokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmfqw+AAoJELqXzVK3
 lkFPYncL/RwMN0b47HICMaKw/hTVh2I0bncndNZYINCnvad/6U5ww2F1X+WeL7Fv20AQdxndBQt
 aBOhQE35GnlIkjkJr7dZ1Zx8S9OK2jzJC/pXSqZWR21g77tSGuiB1EAdzYd2oU3DwV2xf02fhgr
 3gBCtfNqKwfNIDoakQ90NuJ6LH60UB0cTn68h9viUT2ejVu1AnbHc/efr0QGCvULkwuaXdNfU7W
 ItvBPf24Icx35IclbWkls2zpipmfe+qZWYnszuLbXXtnNI9oWd3DF6a2ivcJ9A5I7YZ/d/nfKUb
 lg99C8vZrvI2IBwgkD6Sg2454VywPgzCFaRbGzsJ3qrdeSirBkdTd9nH3Ws0LO3EsKzUvcCyMpv
 +aOD1HTbHjQSVr3hvLZWoVcqMK3NhNt/St9Qvxizn137scia6k3csdkyTqf4OgEy8TYlk1MjzUv
 j0hQ753XhABhst+IYrtm6ozG9phm5lcSbJ98VRXHHWil2jWtXW7S60FcTgvVG4aZaCAF5gFv5k8
 Vs=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace passing 4 arguments (domain id, pasid, cache type and device)
with just one cache_tag_id.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/iommu/intel/cache.c | 120 ++++++++++++++++++++------------------------
 1 file changed, 54 insertions(+), 66 deletions(-)

diff --git a/drivers/iommu/intel/cache.c b/drivers/iommu/intel/cache.c
index b50ec5520871..eb409a296e43 100644
--- a/drivers/iommu/intel/cache.c
+++ b/drivers/iommu/intel/cache.c
@@ -38,40 +38,26 @@ static bool cache_tag_cmp(const struct cache_tag_id *left,
 }
 
 /* Assign a cache tag with specified type to domain. */
-static int cache_tag_assign(struct dmar_domain *domain, u16 did,
-			    struct device *dev, ioasid_t pasid,
-			    enum cache_tag_type type)
+static int cache_tag_assign_type(struct dmar_domain *domain,
+				 struct cache_tag_id const *tag_id,
+				 enum cache_tag_type tag_type)
 {
-	struct device_domain_info *info = dev_iommu_priv_get(dev);
-	struct intel_iommu *iommu = info->iommu;
 	struct cache_tag *tag, *temp;
 	unsigned long flags;
-	struct cache_tag_id cmp_tag = {
-		.type = type,
-		.pasid = pasid,
-		.iommu = info->iommu,
-		.dev = dev,
-		.domain_id = did
-	};
 
 	tag = kzalloc(sizeof(*tag), GFP_KERNEL);
 	if (!tag)
 		return -ENOMEM;
 
-	tag->id.type = type;
-	tag->id.iommu = iommu;
-	tag->id.domain_id = did;
-	tag->id.pasid = pasid;
+	tag->id = *tag_id;
+	tag->id.type = tag_type;
+	if (tag_id->type != CACHE_TAG_DEVTLB && tag_id->type != CACHE_TAG_NESTING_DEVTLB)
+		tag->id.dev = tag_id->iommu->iommu.dev;
 	tag->users = 1;
 
-	if (type == CACHE_TAG_DEVTLB || type == CACHE_TAG_NESTING_DEVTLB)
-		tag->id.dev = dev;
-	else
-		tag->id.dev = iommu->iommu.dev;
-
 	spin_lock_irqsave(&domain->cache_lock, flags);
 	list_for_each_entry(temp, &domain->cache_tags, node) {
-		if (cache_tag_cmp(&temp->id, &cmp_tag)) {
+		if (cache_tag_cmp(&temp->id, tag_id)) {
 			temp->users++;
 			spin_unlock_irqrestore(&domain->cache_lock, flags);
 			kfree(tag);
@@ -87,25 +73,17 @@ static int cache_tag_assign(struct dmar_domain *domain, u16 did,
 }
 
 /* Unassign a cache tag with specified type from domain. */
-static void cache_tag_unassign(struct dmar_domain *domain, u16 did,
-			       struct device *dev, ioasid_t pasid,
-			       enum cache_tag_type type)
+static void cache_tag_unassign_type(struct dmar_domain *domain,
+				    struct cache_tag_id *tag_id,
+				    enum cache_tag_type tag_type)
 {
 	struct cache_tag *tag;
 	unsigned long flags;
-	struct device_domain_info *info = dev_iommu_priv_get(dev);
-	struct cache_tag_id cmp_tag = {
-		.type = type,
-		.pasid = pasid,
-		.iommu = info->iommu,
-		.dev = dev,
-		.domain_id = did
-	};
-
 
+	tag_id->type = tag_type;
 	spin_lock_irqsave(&domain->cache_lock, flags);
 	list_for_each_entry(tag, &domain->cache_tags, node) {
-		if (cache_tag_cmp(&tag->id, &cmp_tag)) {
+		if (cache_tag_cmp(&tag->id, tag_id)) {
 			trace_cache_tag_unassign(tag);
 			if (--tag->users == 0) {
 				list_del(&tag->node);
@@ -117,60 +95,58 @@ static void cache_tag_unassign(struct dmar_domain *domain, u16 did,
 	spin_unlock_irqrestore(&domain->cache_lock, flags);
 }
 
-static int __cache_tag_assign_domain(struct dmar_domain *domain, u16 did,
-				     struct device *dev, ioasid_t pasid)
+static int __cache_tag_assign_domain(struct dmar_domain *domain,
+				     struct cache_tag_id *new_tag_id)
 {
-	struct device_domain_info *info = dev_iommu_priv_get(dev);
+	struct device_domain_info *info = dev_iommu_priv_get(new_tag_id->dev);
 	int ret;
 
-	ret = cache_tag_assign(domain, did, dev, pasid, CACHE_TAG_IOTLB);
+	ret = cache_tag_assign_type(domain, new_tag_id, CACHE_TAG_IOTLB);
 	if (ret || !info->ats_enabled)
 		return ret;
 
-	ret = cache_tag_assign(domain, did, dev, pasid, CACHE_TAG_DEVTLB);
+	ret = cache_tag_assign_type(domain, new_tag_id, CACHE_TAG_DEVTLB);
 	if (ret)
-		cache_tag_unassign(domain, did, dev, pasid, CACHE_TAG_IOTLB);
+		cache_tag_unassign_type(domain, new_tag_id, CACHE_TAG_IOTLB);
 
 	return ret;
 }
 
-static void __cache_tag_unassign_domain(struct dmar_domain *domain, u16 did,
-					struct device *dev, ioasid_t pasid)
+static void __cache_tag_unassign_domain(struct dmar_domain *domain,
+					struct cache_tag_id *tag_id)
 {
-	struct device_domain_info *info = dev_iommu_priv_get(dev);
-
-	cache_tag_unassign(domain, did, dev, pasid, CACHE_TAG_IOTLB);
+	struct device_domain_info *info = dev_iommu_priv_get(tag_id->dev);
 
+	cache_tag_unassign_type(domain, tag_id, CACHE_TAG_IOTLB);
 	if (info->ats_enabled)
-		cache_tag_unassign(domain, did, dev, pasid, CACHE_TAG_DEVTLB);
+		cache_tag_unassign_type(domain, tag_id, CACHE_TAG_DEVTLB);
 }
 
-static int __cache_tag_assign_parent_domain(struct dmar_domain *domain, u16 did,
-					    struct device *dev, ioasid_t pasid)
+static int __cache_tag_assign_parent_domain(struct dmar_domain *domain,
+					    struct cache_tag_id *new_tag_id)
 {
-	struct device_domain_info *info = dev_iommu_priv_get(dev);
+	struct device_domain_info *info = dev_iommu_priv_get(new_tag_id->dev);
 	int ret;
 
-	ret = cache_tag_assign(domain, did, dev, pasid, CACHE_TAG_NESTING_IOTLB);
+	ret = cache_tag_assign_type(domain, new_tag_id, CACHE_TAG_NESTING_IOTLB);
 	if (ret || !info->ats_enabled)
 		return ret;
 
-	ret = cache_tag_assign(domain, did, dev, pasid, CACHE_TAG_NESTING_DEVTLB);
+	ret = cache_tag_assign_type(domain, new_tag_id, CACHE_TAG_NESTING_DEVTLB);
 	if (ret)
-		cache_tag_unassign(domain, did, dev, pasid, CACHE_TAG_NESTING_IOTLB);
+		cache_tag_unassign_type(domain, new_tag_id, CACHE_TAG_NESTING_IOTLB);
 
 	return ret;
 }
 
-static void __cache_tag_unassign_parent_domain(struct dmar_domain *domain, u16 did,
-					       struct device *dev, ioasid_t pasid)
+static void __cache_tag_unassign_parent_domain(struct dmar_domain *domain,
+					       struct cache_tag_id *tag_id)
 {
-	struct device_domain_info *info = dev_iommu_priv_get(dev);
-
-	cache_tag_unassign(domain, did, dev, pasid, CACHE_TAG_NESTING_IOTLB);
+	struct device_domain_info *info = dev_iommu_priv_get(tag_id->dev);
 
+	cache_tag_unassign_type(domain, tag_id, CACHE_TAG_NESTING_IOTLB);
 	if (info->ats_enabled)
-		cache_tag_unassign(domain, did, dev, pasid, CACHE_TAG_NESTING_DEVTLB);
+		cache_tag_unassign_type(domain, tag_id, CACHE_TAG_NESTING_DEVTLB);
 }
 
 static u16 domain_get_id_for_dev(struct dmar_domain *domain, struct device *dev)
@@ -199,16 +175,22 @@ static u16 domain_get_id_for_dev(struct dmar_domain *domain, struct device *dev)
 int cache_tag_assign_domain(struct dmar_domain *domain,
 			    struct device *dev, ioasid_t pasid)
 {
-	u16 did = domain_get_id_for_dev(domain, dev);
+	struct device_domain_info *info = dev_iommu_priv_get(dev);
+	struct cache_tag_id new_tag_id = {
+		.pasid = pasid,
+		.iommu = info->iommu,
+		.dev = dev,
+		.domain_id = domain_get_id_for_dev(domain, dev),
+	};
 	int ret;
 
-	ret = __cache_tag_assign_domain(domain, did, dev, pasid);
+	ret = __cache_tag_assign_domain(domain, &new_tag_id);
 	if (ret || domain->domain.type != IOMMU_DOMAIN_NESTED)
 		return ret;
 
-	ret = __cache_tag_assign_parent_domain(domain->s2_domain, did, dev, pasid);
+	ret = __cache_tag_assign_parent_domain(domain->s2_domain, &new_tag_id);
 	if (ret)
-		__cache_tag_unassign_domain(domain, did, dev, pasid);
+		__cache_tag_unassign_domain(domain, &new_tag_id);
 
 	return ret;
 }
@@ -223,11 +205,17 @@ int cache_tag_assign_domain(struct dmar_domain *domain,
 void cache_tag_unassign_domain(struct dmar_domain *domain,
 			       struct device *dev, ioasid_t pasid)
 {
-	u16 did = domain_get_id_for_dev(domain, dev);
+	struct device_domain_info *info = dev_iommu_priv_get(dev);
+	struct cache_tag_id tag_id = {
+		.pasid = pasid,
+		.iommu = info->iommu,
+		.dev = dev,
+		.domain_id = domain_get_id_for_dev(domain, dev)
+	};
 
-	__cache_tag_unassign_domain(domain, did, dev, pasid);
+	__cache_tag_unassign_domain(domain, &tag_id);
 	if (domain->domain.type == IOMMU_DOMAIN_NESTED)
-		__cache_tag_unassign_parent_domain(domain->s2_domain, did, dev, pasid);
+		__cache_tag_unassign_parent_domain(domain->s2_domain, &tag_id);
 }
 
 static unsigned long calculate_psi_aligned_address(unsigned long start,

-- 
2.43.0

