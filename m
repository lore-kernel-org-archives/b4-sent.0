From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 15 Oct 2024 23:08:12 +0200
Subject: [PATCH v4 2/5] iommu/vt-d: Remove the pasid present check in
 prq_event_thread
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241015-jag-iopfv8-v4-2-b696ca89ba29@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1401;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=+oNZzPhrzkopeFgZ30BXEZ9R6agu9ZZzREmxGT2WjQY=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGcO2cmajgnthS6pVr55LiI+nlD0yq1pvSdVa
 tuYyusu4OCd6okBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnDtnJAAoJELqXzVK3
 lkFPiwsL/A+ykb7ivI8vGLSWZhvUGhvzj3lwa8z9g4dLyB2MHh6gck/cxCQ/2nNC/fZhJjaMwyy
 hLB0bzaPDOILLS2Z7yiea+gNtGFn2Mu7QGEGQg/vBcLSaaf0GrVWIONP/gJv9LdKda8XKL/6+1N
 LI6TiUTrwv1M9jJ74AGBLcGgKcLaupzKa3o1xwJGZ0NRmmI5Vlk7ikQVqVA4DOUKB2if5YjYhBY
 +e9GTubmHVf87H8CtmYFYQ0014E+yR7Hju2Dn6NVowrQ150CFVUI7jad3l1urNp8UNowkF6MzqB
 ATD5Hz3/MDYgvY37gHiFGqEBanF+HE+ddI2kT4eTXkTrIODMkdQlTO3A5Gl21sIkAz2bVLHyLT5
 q1kvI5z0X1giJr5GFGKgpYeEIoTdwEwyJuxuhyiDPLOiu4JmlKULePBXyzwrERAriTyc5T5AxWb
 y3RMlQIcJqzs++i/LRbCzQZdnRy9DasbC7+Wspt9/NBhZTYjZEi9bzBqM15Nh78De8kc+JWaKX6
 7A=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Klaus Jensen <k.jensen@samsung.com>

PASID is not strictly needed when handling a PRQ event; remove the check
for the pasid present bit in the request. This change was not included
in the creation of prq.c to emphasize the change in capability checks
when handing PRQ events.

Signed-off-by: Klaus Jensen <k.jensen@samsung.com>
Reviewed-by: Kevin Tian <kevin.tian@intel.com>
Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/iommu/intel/prq.c | 12 +++---------
 1 file changed, 3 insertions(+), 9 deletions(-)

diff --git a/drivers/iommu/intel/prq.c b/drivers/iommu/intel/prq.c
index d4f18eb46475..3c50c848893f 100644
--- a/drivers/iommu/intel/prq.c
+++ b/drivers/iommu/intel/prq.c
@@ -223,18 +223,12 @@ static irqreturn_t prq_event_thread(int irq, void *d)
 		req = &iommu->prq[head / sizeof(*req)];
 		address = (u64)req->addr << VTD_PAGE_SHIFT;
 
-		if (unlikely(!req->pasid_present)) {
-			pr_err("IOMMU: %s: Page request without PASID\n",
-			       iommu->name);
-bad_req:
-			handle_bad_prq_event(iommu, req, QI_RESP_INVALID);
-			goto prq_advance;
-		}
-
 		if (unlikely(!is_canonical_address(address))) {
 			pr_err("IOMMU: %s: Address is not canonical\n",
 			       iommu->name);
-			goto bad_req;
+bad_req:
+			handle_bad_prq_event(iommu, req, QI_RESP_INVALID);
+			goto prq_advance;
 		}
 
 		if (unlikely(req->pm_req && (req->rd_req | req->wr_req))) {

-- 
2.43.0

