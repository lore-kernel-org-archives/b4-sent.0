From: Joel Granados <j.granados@samsung.com>
Date: Fri, 28 Jun 2024 14:27:39 +0200
Subject: [PATCH RFC 1/5] iommu/vt-d: introduce cache_tag_id to the struct
 cache_tag
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240628-jag-revisit_cache_tag_assign-v1-1-a0c19063c983@samsung.com>
References: <20240628-jag-revisit_cache_tag_assign-v1-0-a0c19063c983@samsung.com>
In-Reply-To: <20240628-jag-revisit_cache_tag_assign-v1-0-a0c19063c983@samsung.com>
To: David Woodhouse <dwmw2@infradead.org>, 
 Lu Baolu <baolu.lu@linux.intel.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=7371;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=CeIl/+AGdknk3OAv3towgvKASz6XQ7Rq3zYF0Ui/bu4=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGZ+rDznM+jfL/TdhJL5yghg71UR9YBVUiO6F
 6f1QRESv0e3HokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmfqw8AAoJELqXzVK3
 lkFPUFAMAIchaETns9jmFV4Hz8ihPEvob+O5EvOqoCRt3PXdavH5jyjxG+T448FeuZAaO8SHnnq
 kX+tHEv1wcs7cR9ZFA6WgZNErkmjEr4VCw3k9AgkUVlIsaBw6U/XPd9nV2IVmtjyPvYHTe2qSFI
 wiXz+00EAn/LAN3PjhNyZjxue5hrTneYYar6YXtf+N2VvDuQw8Xh8tEU3wBb3JFJapbDtUIS0vT
 QJdOf6qyh8HAgVTbAkLUJkbj4KqxkY4DvxKDowMPTfs5ybC8b7kmB+jQJ482p6N7hulCFUFzRq+
 h0nACrNGVv1ecncwyh9w8iFyur55X3QcmULAkbVPLmNMc0nwrRdHcc1QrEhuIP+jWmQCP0ezZkT
 kio8bUwEATyomhXGuD512iElU8YA1idswEdL6tX9Xf7EOl8KvT6FOug/sgAdX6pzZMz52ekUGWu
 glIxF7ZTO24XW4t8QQmwsO3Fq3JHoHjoD76oLyuwjWN1a7SZ3eF6b7OwQe9iaheSrkNobVqkEO4
 h4=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a cache_tag_id so it can be used separately from list and user
counters.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/iommu/intel/cache.c | 62 ++++++++++++++++++++++-----------------------
 drivers/iommu/intel/iommu.h | 24 ++++++++++--------
 2 files changed, 44 insertions(+), 42 deletions(-)

diff --git a/drivers/iommu/intel/cache.c b/drivers/iommu/intel/cache.c
index e8418cdd8331..aa8a463b1251 100644
--- a/drivers/iommu/intel/cache.c
+++ b/drivers/iommu/intel/cache.c
@@ -24,17 +24,17 @@ static bool cache_tage_match(struct cache_tag *tag, u16 domain_id,
 			     struct intel_iommu *iommu, struct device *dev,
 			     ioasid_t pasid, enum cache_tag_type type)
 {
-	if (tag->type != type)
+	if (tag->id.type != type)
 		return false;
 
-	if (tag->domain_id != domain_id || tag->pasid != pasid)
+	if (tag->id.domain_id != domain_id || tag->id.pasid != pasid)
 		return false;
 
 	if (type == CACHE_TAG_IOTLB || type == CACHE_TAG_NESTING_IOTLB)
-		return tag->iommu == iommu;
+		return tag->id.iommu == iommu;
 
 	if (type == CACHE_TAG_DEVTLB || type == CACHE_TAG_NESTING_DEVTLB)
-		return tag->dev == dev;
+		return tag->id.dev == dev;
 
 	return false;
 }
@@ -53,16 +53,16 @@ static int cache_tag_assign(struct dmar_domain *domain, u16 did,
 	if (!tag)
 		return -ENOMEM;
 
-	tag->type = type;
-	tag->iommu = iommu;
-	tag->domain_id = did;
-	tag->pasid = pasid;
+	tag->id.type = type;
+	tag->id.iommu = iommu;
+	tag->id.domain_id = did;
+	tag->id.pasid = pasid;
 	tag->users = 1;
 
 	if (type == CACHE_TAG_DEVTLB || type == CACHE_TAG_NESTING_DEVTLB)
-		tag->dev = dev;
+		tag->id.dev = dev;
 	else
-		tag->dev = iommu->iommu.dev;
+		tag->id.dev = iommu->iommu.dev;
 
 	spin_lock_irqsave(&domain->cache_lock, flags);
 	list_for_each_entry(temp, &domain->cache_tags, node) {
@@ -269,16 +269,16 @@ void cache_tag_flush_range(struct dmar_domain *domain, unsigned long start,
 
 	spin_lock_irqsave(&domain->cache_lock, flags);
 	list_for_each_entry(tag, &domain->cache_tags, node) {
-		struct intel_iommu *iommu = tag->iommu;
+		struct intel_iommu *iommu = tag->id.iommu;
 		struct device_domain_info *info;
 		u16 sid;
 
-		switch (tag->type) {
+		switch (tag->id.type) {
 		case CACHE_TAG_IOTLB:
 		case CACHE_TAG_NESTING_IOTLB:
 			if (domain->use_first_level) {
-				qi_flush_piotlb(iommu, tag->domain_id,
-						tag->pasid, addr, pages, ih);
+				qi_flush_piotlb(iommu, tag->id.domain_id,
+						tag->id.pasid, addr, pages, ih);
 			} else {
 				/*
 				 * Fallback to domain selective flush if no
@@ -286,10 +286,10 @@ void cache_tag_flush_range(struct dmar_domain *domain, unsigned long start,
 				 */
 				if (!cap_pgsel_inv(iommu->cap) ||
 				    mask > cap_max_amask_val(iommu->cap))
-					iommu->flush.flush_iotlb(iommu, tag->domain_id,
+					iommu->flush.flush_iotlb(iommu, tag->id.domain_id,
 								 0, 0, DMA_TLB_DSI_FLUSH);
 				else
-					iommu->flush.flush_iotlb(iommu, tag->domain_id,
+					iommu->flush.flush_iotlb(iommu, tag->id.domain_id,
 								 addr | ih, mask,
 								 DMA_TLB_PSI_FLUSH);
 			}
@@ -306,18 +306,18 @@ void cache_tag_flush_range(struct dmar_domain *domain, unsigned long start,
 			mask = MAX_AGAW_PFN_WIDTH;
 			fallthrough;
 		case CACHE_TAG_DEVTLB:
-			info = dev_iommu_priv_get(tag->dev);
+			info = dev_iommu_priv_get(tag->id.dev);
 			sid = PCI_DEVID(info->bus, info->devfn);
 
-			if (tag->pasid == IOMMU_NO_PASID)
+			if (tag->id.pasid == IOMMU_NO_PASID)
 				qi_flush_dev_iotlb(iommu, sid, info->pfsid,
 						   info->ats_qdep, addr, mask);
 			else
 				qi_flush_dev_iotlb_pasid(iommu, sid, info->pfsid,
-							 tag->pasid, info->ats_qdep,
+							 tag->id.pasid, info->ats_qdep,
 							 addr, mask);
 
-			quirk_extra_dev_tlb_flush(info, addr, mask, tag->pasid, info->ats_qdep);
+			quirk_extra_dev_tlb_flush(info, addr, mask, tag->id.pasid, info->ats_qdep);
 			break;
 		}
 
@@ -337,23 +337,23 @@ void cache_tag_flush_all(struct dmar_domain *domain)
 
 	spin_lock_irqsave(&domain->cache_lock, flags);
 	list_for_each_entry(tag, &domain->cache_tags, node) {
-		struct intel_iommu *iommu = tag->iommu;
+		struct intel_iommu *iommu = tag->id.iommu;
 		struct device_domain_info *info;
 		u16 sid;
 
-		switch (tag->type) {
+		switch (tag->id.type) {
 		case CACHE_TAG_IOTLB:
 		case CACHE_TAG_NESTING_IOTLB:
 			if (domain->use_first_level)
-				qi_flush_piotlb(iommu, tag->domain_id,
-						tag->pasid, 0, -1, 0);
+				qi_flush_piotlb(iommu, tag->id.domain_id,
+						tag->id.pasid, 0, -1, 0);
 			else
-				iommu->flush.flush_iotlb(iommu, tag->domain_id,
+				iommu->flush.flush_iotlb(iommu, tag->id.domain_id,
 							 0, 0, DMA_TLB_DSI_FLUSH);
 			break;
 		case CACHE_TAG_DEVTLB:
 		case CACHE_TAG_NESTING_DEVTLB:
-			info = dev_iommu_priv_get(tag->dev);
+			info = dev_iommu_priv_get(tag->id.dev);
 			sid = PCI_DEVID(info->bus, info->devfn);
 
 			qi_flush_dev_iotlb(iommu, sid, info->pfsid, info->ats_qdep,
@@ -390,25 +390,25 @@ void cache_tag_flush_range_np(struct dmar_domain *domain, unsigned long start,
 
 	spin_lock_irqsave(&domain->cache_lock, flags);
 	list_for_each_entry(tag, &domain->cache_tags, node) {
-		struct intel_iommu *iommu = tag->iommu;
+		struct intel_iommu *iommu = tag->id.iommu;
 
 		if (!cap_caching_mode(iommu->cap) || domain->use_first_level) {
 			iommu_flush_write_buffer(iommu);
 			continue;
 		}
 
-		if (tag->type == CACHE_TAG_IOTLB ||
-		    tag->type == CACHE_TAG_NESTING_IOTLB) {
+		if (tag->id.type == CACHE_TAG_IOTLB ||
+		    tag->id.type == CACHE_TAG_NESTING_IOTLB) {
 			/*
 			 * Fallback to domain selective flush if no
 			 * PSI support or the size is too big.
 			 */
 			if (!cap_pgsel_inv(iommu->cap) ||
 			    mask > cap_max_amask_val(iommu->cap))
-				iommu->flush.flush_iotlb(iommu, tag->domain_id,
+				iommu->flush.flush_iotlb(iommu, tag->id.domain_id,
 							 0, 0, DMA_TLB_DSI_FLUSH);
 			else
-				iommu->flush.flush_iotlb(iommu, tag->domain_id,
+				iommu->flush.flush_iotlb(iommu, tag->id.domain_id,
 							 addr, mask,
 							 DMA_TLB_PSI_FLUSH);
 		}
diff --git a/drivers/iommu/intel/iommu.h b/drivers/iommu/intel/iommu.h
index eaf015b4353b..cc8c9130e177 100644
--- a/drivers/iommu/intel/iommu.h
+++ b/drivers/iommu/intel/iommu.h
@@ -1121,17 +1121,19 @@ enum cache_tag_type {
 
 struct cache_tag {
 	struct list_head node;
-	enum cache_tag_type type;
-	struct intel_iommu *iommu;
-	/*
-	 * The @dev field represents the location of the cache. For IOTLB, it
-	 * resides on the IOMMU hardware. @dev stores the device pointer to
-	 * the IOMMU hardware. For DevTLB, it locates in the PCIe endpoint.
-	 * @dev stores the device pointer to that endpoint.
-	 */
-	struct device *dev;
-	u16 domain_id;
-	ioasid_t pasid;
+	struct cache_tag_id {
+		enum cache_tag_type type;
+		ioasid_t pasid;
+		struct intel_iommu *iommu;
+		/*
+		 * The @dev field represents the location of the cache. For IOTLB, it
+		 * resides on the IOMMU hardware. @dev stores the device pointer to
+		 * the IOMMU hardware. For DevTLB, it locates in the PCIe endpoint.
+		 * @dev stores the device pointer to that endpoint.
+		 */
+		struct device *dev;
+		u16 domain_id;
+	} id;
 	unsigned int users;
 };
 

-- 
2.43.0

