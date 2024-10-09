From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 09 Oct 2024 09:28:10 +0200
Subject: [PATCH v3 2/5] iommu/vt-d: Remove the pasid present check in
 prq_event_thread
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241009-jag-iopfv8-v3-2-bd4271df5b2b@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1353;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=q5e1SCBaucXTws0gPw/H0pg3Kli8XwXfA9xXLDyz09U=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGcGMIzbIc1yZ1EvGs1YwSMI+BQ/aeLKHKix/
 5v6ODvs4Y52FYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnBjCMAAoJELqXzVK3
 lkFP/KQMAImU6V71R4eQptS7fAg6RCpz/fWWlIKy1S+Wl02ZYABOR4CsvGh9bm8fAqu7AJexfCE
 Wl/oj2SV7OyRGY5aG1VUA1FejQwuu231gzR0bz3u16IEX0inAMf7PTEiOh9ekbmc0n/KH+1nN1X
 VDEXV+ErpixPH8ZTk0jwCy2sWKU6m3uGphXesHt7MGNTQuFmx4x41DONByHPu4AN21EHBDHCLeD
 7IhclN2f9mwMGstg0so+MgE3xz8JMmc1uwy3d1MuGildW4JQvELGs0oX2j2YBj3/V4Ph/cEdCja
 F/mnZZBYCCIDJi/TZEcTY6bZ4bYS3Q42W0tQIFgVsFuh8y5kiWVk2JpoGRuT0zXfUe2gaDriUCi
 Ik15d1Xh54M6y6LsFfJwyeQIFqTyPQBG47XiiYyUHjoZsL5cLvS8it2N8GvJl5ZNmzglLyQwsHc
 j9xNEe+710oVLB7hGiQh78NAdAtqZ/eLFMV0s0MxlE2v0+FbOazyCDG3XQdjgLOZ4ShZvfBCeJ3
 k8=
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

