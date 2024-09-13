From: Joel Granados <j.granados@samsung.com>
Date: Fri, 13 Sep 2024 13:44:51 +0200
Subject: [PATCH v2 5/5] iommu/vt-d: drop pasid requirement for prq
 initialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240913-jag-iopfv8-v2-5-dea01c2343bc@samsung.com>
References: <20240913-jag-iopfv8-v2-0-dea01c2343bc@samsung.com>
In-Reply-To: <20240913-jag-iopfv8-v2-0-dea01c2343bc@samsung.com>
To: David Woodhouse <dwmw2@infradead.org>, 
 Lu Baolu <baolu.lu@linux.intel.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Kevin Tian <kevin.tian@intel.com>, 
 Klaus Jensen <its@irrelevant.dk>
Cc: linux-kernel@vger.kernel.org, iommu@lists.linux.dev, 
 Joel Granados <j.granados@samsung.com>, Klaus Jensen <k.jensen@samsung.com>
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=1454;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=GQ979ruQ4vAANRiiIGnsASOC26gBsL07Le0pjm1OYPs=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGbkJdSDbDHpYQc6xVbn9fVpO6eCYSpUK9GLI
 mT3uAH1eI7JaokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJm5CXUAAoJELqXzVK3
 lkFPSRoL/jDNsHyu6rk8NtWUxOEZDUDZI8W/LxsklCrAfGXhdevfW124gc/cIkMBbEYtCbEynMP
 +ZMotsHFO1hEgp+Oiha5ma8cRVjdK+sq2BSE4TLUP9Kz0/4Wt8fEJbZ803ur0tRYqYdEeNc1hp1
 io8W7KtZlCUuc19Y2UGZLJvqqa+Z9SMNebnwRqiBayNu/h3Hub62B942p2NCol7P0MkXqt5x8BI
 KvLdDJUYkSd82IfQ5SedIurTIICvxlfNMO07CH0fYxel+a/fS36M4i+xLAT/7CnRkks+PEg3umv
 qy0Lns+EXrol0jdJykO//wCbNcM0Olg2B0qiqwOrff/PUQfEbazxru4CJrIvv5VyidU5rBkeivG
 fNQuljbsElRdiM2mrtf+5yy7P4eBHDYhVuBV7AEsQ5Rv9lmJcmb4W4zMq6Gv4QOyYs7uF7z23U9
 0/Tx/tykCCFxQ1cSUEneLyk/NhlvALPL2s1UaZuK8FP6i8TYiPZ1H19CvLOYTSHAqb6rsxE1D17
 yw=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Klaus Jensen <k.jensen@samsung.com>

PASID support within the IOMMU is not required to enable the Page
Request Queue, only the PRS capability.

Signed-off-by: Klaus Jensen <k.jensen@samsung.com>
Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/iommu/intel/iommu.c | 10 ++++------
 1 file changed, 4 insertions(+), 6 deletions(-)

diff --git a/drivers/iommu/intel/iommu.c b/drivers/iommu/intel/iommu.c
index 3d1c971eb9e5..9f3bbdbd6372 100644
--- a/drivers/iommu/intel/iommu.c
+++ b/drivers/iommu/intel/iommu.c
@@ -1487,10 +1487,8 @@ static void free_dmar_iommu(struct intel_iommu *iommu)
 	/* free context mapping */
 	free_context_table(iommu);
 
-	if (pasid_supported(iommu)) {
-		if (ecap_prs(iommu->ecap))
-			intel_finish_prq(iommu);
-	}
+	if (ecap_prs(iommu->ecap))
+		intel_finish_prq(iommu);
 }
 
 /*
@@ -2480,7 +2478,7 @@ static int __init init_dmars(void)
 
 		iommu_flush_write_buffer(iommu);
 
-		if (pasid_supported(iommu) && ecap_prs(iommu->ecap)) {
+		if (ecap_prs(iommu->ecap)) {
 			/*
 			 * Call dmar_alloc_hwirq() with dmar_global_lock held,
 			 * could cause possible lock race condition.
@@ -2921,7 +2919,7 @@ static int intel_iommu_add(struct dmar_drhd_unit *dmaru)
 	intel_iommu_init_qi(iommu);
 	iommu_flush_write_buffer(iommu);
 
-	if (pasid_supported(iommu) && ecap_prs(iommu->ecap)) {
+	if (ecap_prs(iommu->ecap)) {
 		ret = intel_enable_prq(iommu);
 		if (ret)
 			goto disable_iommu;

-- 
2.43.0

