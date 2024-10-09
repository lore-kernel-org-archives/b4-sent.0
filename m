From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 09 Oct 2024 09:28:12 +0200
Subject: [PATCH v3 4/5] iommufd: Enable PRI when doing the
 iommufd_hwpt_alloc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241009-jag-iopfv8-v3-4-bd4271df5b2b@kernel.org>
References: <20241009-jag-iopfv8-v3-0-bd4271df5b2b@kernel.org>
In-Reply-To: <20241009-jag-iopfv8-v3-0-bd4271df5b2b@kernel.org>
To: David Woodhouse <dwmw2@infradead.org>, 
 Lu Baolu <baolu.lu@linux.intel.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Kevin Tian <kevin.tian@intel.com>, 
 Klaus Jensen <its@irrelevant.dk>
Cc: linux-kernel@vger.kernel.org, iommu@lists.linux.dev, 
 Joel Granados <joel.granados@kernel.org>, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=1696;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=FR5FCGd1FwO7Qap+AjqEbgQxhdmlbTbxFEQOXxA4JJ4=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGcGMI2+C3OfJR9R+WuJfWWOXeTEK+5Y2PJM1
 GLfT/TBDDDfh4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnBjCNAAoJELqXzVK3
 lkFPscoMAJmgkncfznL9bSg3ENqSAiTdw+cAJCk6vLgQqqJVi9jjFbwJSuJcCDRMqXbIyGgUw6C
 Uqnba/k50fbBXmMm4/5fBSq7pEPpCmk1EngfYYbrvhbGb1aW+bl0zIAbqaQu08ls54MRVIK8/Eb
 trkq+5P1rP2oJBt6bWGZY56WqkkmGl08kNlPv5q/mAUX26Thrtew6F+nYEvipwcLt2k55tR+zR7
 E7qLYiV2GOVOi5JK+S2romHOzyWsOFN3vFTPnLYyZYAlRjZQvU4b2HF4dDgMnto0hJfJL5jEFZB
 izHPb6jOgI6iVfq76gHsvxZcyLAHRP52CiDyuFu9x0yiqTsZUf0F5S/MSfgRBa3TE2H9fIqimkM
 D7uAAq212bHudrxRvozSzSaCH9Xb0GxAqI7Sc2rR77Bia17NGE+mi8gPUhfQR4aadorl5M5gkfF
 mx5/7iWD7knCWiJ7P3jTgboQadSEav3sMw9kSs722W6tZxMTJ3j9PtSAl5WxZC4w4gGu/Iu8iJ8
 Y0=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add IOMMU_HWPT_FAULT_ID_VALID as part of the valid flags when doing an
iommufd_hwpt_alloc allowing the use of an iommu fault allocation
(iommu_fault_alloc) with the IOMMU_HWPT_ALLOC ioctl.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/iommu/intel/iommu.c          | 3 ++-
 drivers/iommu/iommufd/hw_pagetable.c | 3 ++-
 2 files changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/iommu/intel/iommu.c b/drivers/iommu/intel/iommu.c
index 5d9c3333c92d..dd399ca09859 100644
--- a/drivers/iommu/intel/iommu.c
+++ b/drivers/iommu/intel/iommu.c
@@ -3535,7 +3535,8 @@ intel_iommu_domain_alloc_user(struct device *dev, u32 flags,
 	}
 
 	if (flags &
-	    (~(IOMMU_HWPT_ALLOC_NEST_PARENT | IOMMU_HWPT_ALLOC_DIRTY_TRACKING)))
+	    (~(IOMMU_HWPT_ALLOC_NEST_PARENT | IOMMU_HWPT_ALLOC_DIRTY_TRACKING
+	       | IOMMU_HWPT_FAULT_ID_VALID)))
 		return ERR_PTR(-EOPNOTSUPP);
 	if (nested_parent && !nested_supported(iommu))
 		return ERR_PTR(-EOPNOTSUPP);
diff --git a/drivers/iommu/iommufd/hw_pagetable.c b/drivers/iommu/iommufd/hw_pagetable.c
index d06bf6e6c19f..8f020bc0815f 100644
--- a/drivers/iommu/iommufd/hw_pagetable.c
+++ b/drivers/iommu/iommufd/hw_pagetable.c
@@ -107,7 +107,8 @@ iommufd_hwpt_paging_alloc(struct iommufd_ctx *ictx, struct iommufd_ioas *ioas,
 			  const struct iommu_user_data *user_data)
 {
 	const u32 valid_flags = IOMMU_HWPT_ALLOC_NEST_PARENT |
-				IOMMU_HWPT_ALLOC_DIRTY_TRACKING;
+				IOMMU_HWPT_ALLOC_DIRTY_TRACKING |
+				IOMMU_HWPT_FAULT_ID_VALID;
 	const struct iommu_ops *ops = dev_iommu_ops(idev->dev);
 	struct iommufd_hwpt_paging *hwpt_paging;
 	struct iommufd_hw_pagetable *hwpt;

-- 
2.43.0

