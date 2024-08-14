From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 14 Aug 2024 22:45:34 +0530
Subject: [PATCH 1/3] ufs: core: Rename LSDB to SDBS to reflect the UFSHCI
 4.0 spec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240814-ufs-bug-fix-v1-1-5eb49d5f7571@linaro.org>
References: <20240814-ufs-bug-fix-v1-0-5eb49d5f7571@linaro.org>
In-Reply-To: <20240814-ufs-bug-fix-v1-0-5eb49d5f7571@linaro.org>
To: Alim Akhtar <alim.akhtar@samsung.com>, 
 Avri Altman <avri.altman@wdc.com>, Bart Van Assche <bvanassche@acm.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
Cc: linux-scsi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Kyoungrul Kim <k831.kim@samsung.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2622;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=YW06jWkKjEWiplubl7FzAc5Mu1aZMxORon0NWYdZPK8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmvOY3WdNs13h5ZEVwiZkwRSCloR1bfX4X7ZrHy
 AIyYgHK9emJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZrzmNwAKCRBVnxHm/pHO
 9c+bB/9CjuTsZyKd9CqBKToyshFHSvU4ZD/FxkvmwXU8WGRlMYrs+Bw40cB06Yut3OOUHUuFbY7
 6LkOTkKh7kClYmSekCKyXlbc8WXZ9yreqvNB3rO8oMaW1jKSAVjIkJ+ZCXSL3shTPYny1g8KNN6
 YzcwhW8nEOPSnZEPwy3tV6/QzdcGaNCX+4SO6p+DS99BE3NjdJNE1DTMPAvAhLxmE6FPNWWKe52
 LlMF/0N9PwqpG4Q6nW5BVqVtJp9u/iqY01hrjy8Kli+X3Qt3B8r+ga3e8inbHrMMPvrzckCZoa0
 AVBYklWNJfdqHTAkx57oG2SXwAhgzaXpbTlYmcmcD5uciV6m
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

UFSHCI 4.0 spec names the 'Legacy Queue & Single Doorbell Support' field in
Controller Capabilities register as 'SDBS'. So let's use the same
terminology in the driver to align with the spec.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/ufs/core/ufshcd.c | 6 +++---
 include/ufs/ufshcd.h      | 2 +-
 include/ufs/ufshci.h      | 2 +-
 3 files changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/ufs/core/ufshcd.c b/drivers/ufs/core/ufshcd.c
index 0b3d0c8e0dda..168b9dbc3ada 100644
--- a/drivers/ufs/core/ufshcd.c
+++ b/drivers/ufs/core/ufshcd.c
@@ -2418,7 +2418,7 @@ static inline int ufshcd_hba_capabilities(struct ufs_hba *hba)
 
 	/*
 	 * The UFSHCI 3.0 specification does not define MCQ_SUPPORT and
-	 * LSDB_SUPPORT, but [31:29] as reserved bits with reset value 0s, which
+	 * SDBS_SUPPORT, but [31:29] as reserved bits with reset value 0s, which
 	 * means we can simply read values regardless of version.
 	 */
 	hba->mcq_sup = FIELD_GET(MASK_MCQ_SUPPORT, hba->capabilities);
@@ -2426,7 +2426,7 @@ static inline int ufshcd_hba_capabilities(struct ufs_hba *hba)
 	 * 0h: legacy single doorbell support is available
 	 * 1h: indicate that legacy single doorbell support has been removed
 	 */
-	hba->lsdb_sup = !FIELD_GET(MASK_LSDB_SUPPORT, hba->capabilities);
+	hba->sdbs_sup = !FIELD_GET(MASK_SDBS_SUPPORT, hba->capabilities);
 	if (!hba->mcq_sup)
 		return 0;
 
@@ -10512,7 +10512,7 @@ int ufshcd_init(struct ufs_hba *hba, void __iomem *mmio_base, unsigned int irq)
 	}
 
 	if (!is_mcq_supported(hba)) {
-		if (!hba->lsdb_sup) {
+		if (!hba->sdbs_sup) {
 			dev_err(hba->dev, "%s: failed to initialize (legacy doorbell mode not supported)\n",
 				__func__);
 			err = -EINVAL;
diff --git a/include/ufs/ufshcd.h b/include/ufs/ufshcd.h
index cac0cdb9a916..d44b19cf9f82 100644
--- a/include/ufs/ufshcd.h
+++ b/include/ufs/ufshcd.h
@@ -1109,7 +1109,7 @@ struct ufs_hba {
 	bool ext_iid_sup;
 	bool scsi_host_added;
 	bool mcq_sup;
-	bool lsdb_sup;
+	bool sdbs_sup;
 	bool mcq_enabled;
 	struct ufshcd_res_info res[RES_MAX];
 	void __iomem *mcq_base;
diff --git a/include/ufs/ufshci.h b/include/ufs/ufshci.h
index 9917c7743d80..b60212865e90 100644
--- a/include/ufs/ufshci.h
+++ b/include/ufs/ufshci.h
@@ -77,7 +77,7 @@ enum {
 	MASK_OUT_OF_ORDER_DATA_DELIVERY_SUPPORT	= 0x02000000,
 	MASK_UIC_DME_TEST_MODE_SUPPORT		= 0x04000000,
 	MASK_CRYPTO_SUPPORT			= 0x10000000,
-	MASK_LSDB_SUPPORT			= 0x20000000,
+	MASK_SDBS_SUPPORT			= 0x20000000,
 	MASK_MCQ_SUPPORT			= 0x40000000,
 };
 

-- 
2.25.1

