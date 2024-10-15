From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 15 Oct 2024 23:08:15 +0200
Subject: [PATCH v4 5/5] iommu/vt-d: drop pasid requirement for prq
 initialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241015-jag-iopfv8-v4-5-b696ca89ba29@kernel.org>
References: <20241015-jag-iopfv8-v4-0-b696ca89ba29@kernel.org>
In-Reply-To: <20241015-jag-iopfv8-v4-0-b696ca89ba29@kernel.org>
To: David Woodhouse <dwmw2@infradead.org>, 
 Lu Baolu <baolu.lu@linux.intel.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Kevin Tian <kevin.tian@intel.com>, 
 Klaus Jensen <its@irrelevant.dk>
Cc: linux-kernel@vger.kernel.org, iommu@lists.linux.dev, 
 Joel Granados <joel.granados@kernel.org>, 
 Klaus Jensen <k.jensen@samsung.com>, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=1522;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=fgqmIRYN7P+tkRbowRwUpgEZhxpNtDWX7Dh3D2PZWok=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGcO2cpK9A4GoP/ugAWkb54WUdkhij2MLv8Ml
 167rcmwP+yQYYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnDtnKAAoJELqXzVK3
 lkFPNVEL/Rs4Q+ZYe/3LWAlJ2XtiJgk9hXq4KqHz8Xt5ETs0ecAHIQw8R2PGg6allwYAUuZoduw
 LWdNRIhtSxqFpJOAXbT6+cOdtId/2rMVzI7yq/Mdu6ZEH0Tf3UK5oPD6ktA7jEOr07Zt70hhL9v
 E2Jsg1lR6m5/GdhRrCgLr3WJhxO/OSJbHQphxWr2NQIi1jv6XrJRgM55Ztbpt17XWVilZQYOL2Q
 9PMKPKyaBbNrpFbNrQ0EGRtkEuUgu70Rkgz1bZVqe1W/I5lqDn6Hum9rcucrM/H+VM6d6mrC/fr
 tqL9f0R4AWpe6TcgUjvPWOIoCj2jsumhb+zOVWfRL8Vb+mcgoYfsJXMjdXjfIrtJuSXvU9h/UCX
 xMk1tXoXjinNMeoH+voYTO2mzUBNEzGTkr2n0TrqAxVYk07NyOqP0yRx+xkKznHqRSgyZ9VPPBO
 90GdXWg+1w1804KPllZXmu1cHBpcRhTRzqu4euOhil09JDhoZEe8uvQn6g9zvtw80KDt+GZgAe8
 iA=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Klaus Jensen <k.jensen@samsung.com>

PASID support within the IOMMU is not required to enable the Page
Request Queue, only the PRS capability.

Signed-off-by: Klaus Jensen <k.jensen@samsung.com>
Reviewed-by: Kevin Tian <kevin.tian@intel.com>
Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/iommu/intel/iommu.c | 10 ++++------
 1 file changed, 4 insertions(+), 6 deletions(-)

diff --git a/drivers/iommu/intel/iommu.c b/drivers/iommu/intel/iommu.c
index dd399ca09859..53bbaba847d3 100644
--- a/drivers/iommu/intel/iommu.c
+++ b/drivers/iommu/intel/iommu.c
@@ -1428,10 +1428,8 @@ static void free_dmar_iommu(struct intel_iommu *iommu)
 	/* free context mapping */
 	free_context_table(iommu);
 
-	if (pasid_supported(iommu)) {
-		if (ecap_prs(iommu->ecap))
-			intel_iommu_finish_prq(iommu);
-	}
+	if (ecap_prs(iommu->ecap))
+		intel_iommu_finish_prq(iommu);
 }
 
 /*
@@ -2352,7 +2350,7 @@ static int __init init_dmars(void)
 
 		iommu_flush_write_buffer(iommu);
 
-		if (pasid_supported(iommu) && ecap_prs(iommu->ecap)) {
+		if (ecap_prs(iommu->ecap)) {
 			/*
 			 * Call dmar_alloc_hwirq() with dmar_global_lock held,
 			 * could cause possible lock race condition.
@@ -2783,7 +2781,7 @@ static int intel_iommu_add(struct dmar_drhd_unit *dmaru)
 	intel_iommu_init_qi(iommu);
 	iommu_flush_write_buffer(iommu);
 
-	if (pasid_supported(iommu) && ecap_prs(iommu->ecap)) {
+	if (ecap_prs(iommu->ecap)) {
 		ret = intel_iommu_enable_prq(iommu);
 		if (ret)
 			goto disable_iommu;

-- 
2.43.0

