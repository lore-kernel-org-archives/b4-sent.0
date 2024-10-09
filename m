From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 09 Oct 2024 09:28:13 +0200
Subject: [PATCH v3 5/5] iommu/vt-d: drop pasid requirement for prq
 initialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241009-jag-iopfv8-v3-5-bd4271df5b2b@kernel.org>
References: <20241009-jag-iopfv8-v3-0-bd4271df5b2b@kernel.org>
In-Reply-To: <20241009-jag-iopfv8-v3-0-bd4271df5b2b@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1474;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=7oRVYwfeS7mQ4a0yNBlw9DIcabzyWBJwpPFV6ErALFY=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGcGMI5CsxzhuZdlUI1iS7KJbFuss47HsqL1Z
 Byn1cDzioYS1IkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnBjCOAAoJELqXzVK3
 lkFPhk4L/i5NrRHqOct+GsRdBFQ8KjLQF91pXZKhGGv/1kIzDS1oPA9ys2fvM42EAn4cMo8HJHj
 PH+E9OEciYf0ti63BrcsGkh5aKO828gj6f1tVPn5ZZCbAkR3YBzPyB/yeyMegWbi9pG8YahQZjJ
 g9Xwq4XVnQSUuqVQZ7Pj8f6Gvi8zwQ5pW7w4F4/v9UB85YxqOGYCN+BPD2oO4n/HfqfRSQqnYC5
 l9hIPymoUdlGp/3+Crajflght84wkFK7MUmKdZriI+3VAp5295M8AbV53EJgfowIV9aqM2Rrb54
 oocaxV7hSukZZxzlmRD+jt14Yp2D5uYkbv2Tuwn265mXnUZA9kIvBsAfnzFpU4YbtUzRepYqUE0
 8+YaK1/Dc9c1I3WYtiSVtzWuQNJZYivjL4GUvJeIFO8q0WuH4vpLwqAavKD+6hPwc1A1PwvQqfD
 KsyCdHPIXfH3J1jwsn6LugPBSiFVW6GKiBg5Yv6IwNDU/iu+4srwUgpq0ruovsDH+HnQbECXGY5
 u8=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Klaus Jensen <k.jensen@samsung.com>

PASID support within the IOMMU is not required to enable the Page
Request Queue, only the PRS capability.

Signed-off-by: Klaus Jensen <k.jensen@samsung.com>
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

