From: Joel Granados <j.granados@samsung.com>
Date: Wed, 04 Sep 2024 15:17:13 +0200
Subject: [PATCH 2/6] iommu/vt-d: Remove the pasid present check in
 prq_event_thread
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240904-jag-iopfv8-v1-2-e3549920adf3@samsung.com>
References: <20240904-jag-iopfv8-v1-0-e3549920adf3@samsung.com>
In-Reply-To: <20240904-jag-iopfv8-v1-0-e3549920adf3@samsung.com>
To: David Woodhouse <dwmw2@infradead.org>, 
 Lu Baolu <baolu.lu@linux.intel.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Kevin Tian <kevin.tian@intel.com>, 
 Klaus Jensen <its@irrelevant.dk>
Cc: linux-kernel@vger.kernel.org, iommu@lists.linux.dev, 
 Joel Granados <j.granados@samsung.com>, Klaus Jensen <k.jensen@samsung.com>
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=1351;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=FD3UiP6NJxmTUYvjmWxZFWuSigYaHG1wzRA5qCg/pTc=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGbYXhC3rVks+YQxMld3lqz3PtEbzx3YP/0tv
 SlyGftf39WU5YkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJm2F4QAAoJELqXzVK3
 lkFPT/AL/Rh3zXdT5UQaqGGi3xhl12hEX+DL8xYzus7bNkXGZIArVREL9Ww4N4fULNqSIcCJ46y
 EJUdiCBblIo79ZpC+jI45GUI8KDkChndRmfyHuwEzJC7mCuoHuShJff4c2xVFsjE4858NTA5pnV
 hA+wxIXDBRYNOt0e+Br+BAmbiyVRQ5bN259pkoqZ0nG6fQ4f+iKXen1Dsc10gr8BV+3xgxDf/eX
 YmEIKUO/135r3JdqWkCp6ixA1eAwcEFqMcdYbLVhT/o6Fe1d0slIhx/1KILIMPXcSAQ2WtuFwSz
 zkpx+VHDG7IH2RMAn+Hsq/mbTgBWDUmGJ64K8GWGmbnx0IF/IKpTkvQdDYLC342KrfZFByeUmEG
 6mBeA8HC/9L3n6/5E7iPlvItL/aWmYzHJKyjQokz2Ipxwqy5a0uGbqrQBVze9Q8axKTvclOZL1Q
 R+/islwVuLf4Wycl7PJQ0tDt1nZDninu9SQOJnLzF5qVDxbwZbqlmAZv5s4qoC9LBr0pJZYzC96
 Hs=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Klaus Jensen <k.jensen@samsung.com>

PASID is not strictly needed when handling a PRQ event; remove the check
for the pasid present bit in the request. This change was not included
in the creation of prq.c to emphasize the change in capability checks
when handing PRQ events.

Signed-off-by: Klaus Jensen <k.jensen@samsung.com>
Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/iommu/intel/prq.c | 12 +++---------
 1 file changed, 3 insertions(+), 9 deletions(-)

diff --git a/drivers/iommu/intel/prq.c b/drivers/iommu/intel/prq.c
index 3376f60082b5..5f2d01a9aa11 100644
--- a/drivers/iommu/intel/prq.c
+++ b/drivers/iommu/intel/prq.c
@@ -221,18 +221,12 @@ static irqreturn_t prq_event_thread(int irq, void *d)
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

