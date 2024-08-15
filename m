From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 15 Aug 2024 10:46:56 +0530
Subject: [PATCH v2 1/3] ufs: core: Rename LSDB to LSDBS to reflect the
 UFSHCI 4.0 spec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240815-ufs-bug-fix-v2-1-b373afae888f@linaro.org>
References: <20240815-ufs-bug-fix-v2-0-b373afae888f@linaro.org>
In-Reply-To: <20240815-ufs-bug-fix-v2-0-b373afae888f@linaro.org>
To: Alim Akhtar <alim.akhtar@samsung.com>, 
 Avri Altman <avri.altman@wdc.com>, Bart Van Assche <bvanassche@acm.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
Cc: linux-scsi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Kyoungrul Kim <k831.kim@samsung.com>, 
 Amit Pundir <amit.pundir@linaro.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2678;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=ug56jraL0N0ozijA5VnULZ3EejWihFXWmVlZhCYNgqI=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmvY9KI9x6yyxcGEydOeOFk3MoomjFsm2pATgiw
 W0b/mTYaSiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZr2PSgAKCRBVnxHm/pHO
 9QkiB/943z89vSe87RUYHlGS0PIUdlG0yVOGrc4l8lnbusRoLbyBLueKIX0gw5Yd7Wzedk8BoBn
 1GjjPsBFolEPp2ltgHzHaODC6ppoaIjI7ad1lxn0n4TvKpxtDh96PQRUmka1e9ziRwHCIObo6+p
 hJ8WtwDOUvuLS6eqdtD09rC440aHQDUQld7lafi/EIKI1fcjSupsnQ+0xy8JoSoXTawMnMfkn7S
 vvuMhhcPRzhSI0zQyS6AkD+oQQywQBLGMwiIYX9IaGdWJ8+VMe2iHh9Flo66nRbBq02F78MJXBM
 3kpQBDO2txAzC4xi8LVxHgeAMOW004UyiK4vANKuarhuA/vE
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

UFSHCI 4.0 spec names the 'Legacy Queue & Single Doorbell Support' field in
Controller Capabilities register as 'LSDBS'. So let's use the same
terminology in the driver to align with the spec.

Tested-by: Amit Pundir <amit.pundir@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/ufs/core/ufshcd.c | 6 +++---
 include/ufs/ufshcd.h      | 2 +-
 include/ufs/ufshci.h      | 2 +-
 3 files changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/ufs/core/ufshcd.c b/drivers/ufs/core/ufshcd.c
index 0b3d0c8e0dda..0b1787074215 100644
--- a/drivers/ufs/core/ufshcd.c
+++ b/drivers/ufs/core/ufshcd.c
@@ -2418,7 +2418,7 @@ static inline int ufshcd_hba_capabilities(struct ufs_hba *hba)
 
 	/*
 	 * The UFSHCI 3.0 specification does not define MCQ_SUPPORT and
-	 * LSDB_SUPPORT, but [31:29] as reserved bits with reset value 0s, which
+	 * LSDBS_SUPPORT, but [31:29] as reserved bits with reset value 0s, which
 	 * means we can simply read values regardless of version.
 	 */
 	hba->mcq_sup = FIELD_GET(MASK_MCQ_SUPPORT, hba->capabilities);
@@ -2426,7 +2426,7 @@ static inline int ufshcd_hba_capabilities(struct ufs_hba *hba)
 	 * 0h: legacy single doorbell support is available
 	 * 1h: indicate that legacy single doorbell support has been removed
 	 */
-	hba->lsdb_sup = !FIELD_GET(MASK_LSDB_SUPPORT, hba->capabilities);
+	hba->lsdbs_sup = !FIELD_GET(MASK_LSDBS_SUPPORT, hba->capabilities);
 	if (!hba->mcq_sup)
 		return 0;
 
@@ -10512,7 +10512,7 @@ int ufshcd_init(struct ufs_hba *hba, void __iomem *mmio_base, unsigned int irq)
 	}
 
 	if (!is_mcq_supported(hba)) {
-		if (!hba->lsdb_sup) {
+		if (!hba->lsdbs_sup) {
 			dev_err(hba->dev, "%s: failed to initialize (legacy doorbell mode not supported)\n",
 				__func__);
 			err = -EINVAL;
diff --git a/include/ufs/ufshcd.h b/include/ufs/ufshcd.h
index cac0cdb9a916..c6ab1c671ad7 100644
--- a/include/ufs/ufshcd.h
+++ b/include/ufs/ufshcd.h
@@ -1109,7 +1109,7 @@ struct ufs_hba {
 	bool ext_iid_sup;
 	bool scsi_host_added;
 	bool mcq_sup;
-	bool lsdb_sup;
+	bool lsdbs_sup;
 	bool mcq_enabled;
 	struct ufshcd_res_info res[RES_MAX];
 	void __iomem *mcq_base;
diff --git a/include/ufs/ufshci.h b/include/ufs/ufshci.h
index 9917c7743d80..35013ba71b75 100644
--- a/include/ufs/ufshci.h
+++ b/include/ufs/ufshci.h
@@ -77,7 +77,7 @@ enum {
 	MASK_OUT_OF_ORDER_DATA_DELIVERY_SUPPORT	= 0x02000000,
 	MASK_UIC_DME_TEST_MODE_SUPPORT		= 0x04000000,
 	MASK_CRYPTO_SUPPORT			= 0x10000000,
-	MASK_LSDB_SUPPORT			= 0x20000000,
+	MASK_LSDBS_SUPPORT			= 0x20000000,
 	MASK_MCQ_SUPPORT			= 0x40000000,
 };
 

-- 
2.25.1

