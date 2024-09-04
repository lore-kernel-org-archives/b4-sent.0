From: Joel Granados <j.granados@samsung.com>
Date: Wed, 04 Sep 2024 15:17:17 +0200
Subject: [PATCH 6/6] iommu/vt-d: drop pasid requirement for prq
 initialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240904-jag-iopfv8-v1-6-e3549920adf3@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1454;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=GQ979ruQ4vAANRiiIGnsASOC26gBsL07Le0pjm1OYPs=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGbYXhKOqYL08HTDL5U1FS6YKVJeseJUwf3VA
 Vyg9JiqiavFWYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJm2F4SAAoJELqXzVK3
 lkFPhwEMAJc0ezgHDa2U5drkdjhqFE9iQKVk3KUkm+9m70jbOA8N+95R9S36RYtpryTYFwjSTxS
 K3HNBVSj5Dfm1iz/uLNGPW71ImEuyoD+f9JveefAD8sN93nSlSykCrlFxmzKhVoM7rl9ZNJQ6Bq
 6uIRRXA36olvwExRfh4pzkSA0IkNgj7ZRo690ffXGX7kY6BZkNHwTzWvrhswLPNUuL0UHCTi5LL
 D3O57Rq1BNiXC+/qUiYHKqmOdvHY9j7P1iYeXF1ZRqJG4G26BssP3kXmKkqP5bN0Isvk28PF16n
 F3QwHAW2KXPG+qOdm4JTI6/HZF+xBNjoJfq/sTkIKrJ5eo1NLMKacQA4SGqIR6YtEra0SlWb+w9
 IvzME5R8OQuzOvnYhsfW6Fzwm2COK9juCNiITfiDH11K2h60XZ+48dYiTrs0Lq2BQ9hxRyPzpUe
 vlwFzoPVwkBXhUnA9kmWOa8FcbpKyKJ/ZsOVlLhBz38EpWnBlm4779t0Ic0hvwiyUeckIp4wj94
 W8=
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

