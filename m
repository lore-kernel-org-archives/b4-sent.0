From: Joel Granados <j.granados@samsung.com>
Date: Wed, 04 Sep 2024 15:17:16 +0200
Subject: [PATCH 5/6] iommu: init pasid array while doing domain_replace and
 iopf is active
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240904-jag-iopfv8-v1-5-e3549920adf3@samsung.com>
References: <20240904-jag-iopfv8-v1-0-e3549920adf3@samsung.com>
In-Reply-To: <20240904-jag-iopfv8-v1-0-e3549920adf3@samsung.com>
To: David Woodhouse <dwmw2@infradead.org>, 
 Lu Baolu <baolu.lu@linux.intel.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Kevin Tian <kevin.tian@intel.com>, 
 Klaus Jensen <its@irrelevant.dk>
Cc: linux-kernel@vger.kernel.org, iommu@lists.linux.dev, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=3911;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=pU8Ysqx41tEvpDjmz62CzUVFAwe2mnVh/jqq0I7a6v8=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGbYXhL2ESnsvHmBgN6QUX2UvqogpeVAeLBju
 RlQvGICyARVfokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJm2F4SAAoJELqXzVK3
 lkFPKPEL/0W3YFk6CZ063mfvqtAhaSNefjunJndB/tIn3/8SYtcSFlkwcglU8f60FsycxaA7pQP
 wt5i8nC1bKuklEe+/HFO59YQP3qJrA6ksrA2GxSpimLj7zGZ+5A4T+Igv+1xPAio8xmLyDin6F8
 c7hHnssgc6MnWXBt21Z+SuJHSOGH2ZZt42uGRa2dfiedbJ/R+1EASlhK7/PpjUWVcwu6m1qWLAk
 sUVTtQ+3/ububVeuQluvvqEoRYIQckZs/TQckdGyQiloAB0oDAC658bLVAM9XO3Z7JyAcl2bo9W
 x8kShMtes53jIJMB9X+new/KNrut3AXrgijUe8V6kGQsRG0sj5gWo8pkUg/CJlUy6/cMsTq708h
 1QjmCnMk0UbHCJoFao7QR/UlOZhnmGzf0wwxz92yzVkTCc1DvvqqiNUSyeK9IdQoqu5Sq1jRTx6
 AKweNOKGOmdB3N+t/LPplSwKiq8ku4dUY1Yf5ys7tPN/KvQsuvpxrHqGYsYKc0WD596hKRiV8o6
 kw=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

iommu_report_device_fault expects a pasid array to have an
iommu_attach_handle when a fault is detected. Add this handle when the
replacing hwpt has a valid iommufd fault object. Remove it when we
release ownership of the group.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/iommu/iommu-priv.h    |  3 +++
 drivers/iommu/iommu.c         | 30 ++++++++++++++++++++++++++++++
 drivers/iommu/iommufd/fault.c | 22 ++++++++++++++++++++++
 3 files changed, 55 insertions(+)

diff --git a/drivers/iommu/iommu-priv.h b/drivers/iommu/iommu-priv.h
index de5b54eaa8bf..493e501badc7 100644
--- a/drivers/iommu/iommu-priv.h
+++ b/drivers/iommu/iommu-priv.h
@@ -38,6 +38,9 @@ void iommu_device_unregister_bus(struct iommu_device *iommu,
 struct iommu_attach_handle *iommu_attach_handle_get(struct iommu_group *group,
 						    ioasid_t pasid,
 						    unsigned int type);
+int iommu_init_pasid_array(struct iommu_domain *domain,
+			   struct iommu_group *group,
+			   struct iommu_attach_handle *handle);
 int iommu_attach_group_handle(struct iommu_domain *domain,
 			      struct iommu_group *group,
 			      struct iommu_attach_handle *handle);
diff --git a/drivers/iommu/iommu.c b/drivers/iommu/iommu.c
index ed6c5cb60c5a..64ae1cf571aa 100644
--- a/drivers/iommu/iommu.c
+++ b/drivers/iommu/iommu.c
@@ -3262,6 +3262,9 @@ EXPORT_SYMBOL_GPL(iommu_device_claim_dma_owner);
 
 static void __iommu_release_dma_ownership(struct iommu_group *group)
 {
+	if (!xa_empty(&group->pasid_array))
+		xa_erase(&group->pasid_array, IOMMU_NO_PASID);
+
 	if (WARN_ON(!group->owner_cnt || !group->owner ||
 		    !xa_empty(&group->pasid_array)))
 		return;
@@ -3495,6 +3498,33 @@ iommu_attach_handle_get(struct iommu_group *group, ioasid_t pasid, unsigned int
 }
 EXPORT_SYMBOL_NS_GPL(iommu_attach_handle_get, IOMMUFD_INTERNAL);
 
+/**
+ * iommu_init_pasid_array - Initialize pasid array in the domain group
+ *
+ * Returns 0 on success. Error code on failure
+ *
+ * An IOMMU_NO_PASID element is *NOT* replaced if there is one already there.
+ */
+int iommu_init_pasid_array(struct iommu_domain *domain,
+			   struct iommu_group *group,
+			   struct iommu_attach_handle *handle)
+{
+	int ret;
+
+	if (handle)
+		handle->domain = domain;
+
+	mutex_lock(&group->mutex);
+	ret = xa_insert(&group->pasid_array, IOMMU_NO_PASID, handle, GFP_KERNEL);
+	mutex_unlock(&group->mutex);
+
+	if (ret == -EBUSY)
+		ret = 0;
+
+	return ret;
+}
+EXPORT_SYMBOL_NS_GPL(iommu_init_pasid_array, IOMMUFD_INTERNAL);
+
 /**
  * iommu_attach_group_handle - Attach an IOMMU domain to an IOMMU group
  * @domain: IOMMU domain to attach
diff --git a/drivers/iommu/iommufd/fault.c b/drivers/iommu/iommufd/fault.c
index a643d5c7c535..ea7f1bf64892 100644
--- a/drivers/iommu/iommufd/fault.c
+++ b/drivers/iommu/iommufd/fault.c
@@ -178,6 +178,25 @@ static int __fault_domain_replace_dev(struct iommufd_device *idev,
 	return ret;
 }
 
+static int iommufd_init_pasid_array(struct iommu_domain *domain,
+				  struct iommufd_device *idev)
+{
+	int ret;
+	struct iommufd_attach_handle *handle;
+	struct iommu_group *group = idev->igroup->group;
+
+	handle = kzalloc(sizeof(*handle), GFP_KERNEL);
+	if (!handle)
+		return -ENOMEM;
+	handle->idev = idev;
+
+	ret = iommu_init_pasid_array(domain, group, &handle->handle);
+	if (ret)
+		kfree(handle);
+
+	return ret;
+}
+
 int iommufd_fault_domain_replace_dev(struct iommufd_device *idev,
 				     struct iommufd_hw_pagetable *hwpt,
 				     struct iommufd_hw_pagetable *old)
@@ -190,6 +209,9 @@ int iommufd_fault_domain_replace_dev(struct iommufd_device *idev,
 		ret = iommufd_fault_iopf_enable(idev);
 		if (ret)
 			return ret;
+
+		if (iommufd_init_pasid_array(hwpt->domain, idev))
+			return -EINVAL;
 	}
 
 	ret = __fault_domain_replace_dev(idev, hwpt, old);

-- 
2.43.0

