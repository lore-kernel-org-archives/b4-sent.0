From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 14 Aug 2024 22:45:35 +0530
Subject: [PATCH 2/3] ufs: core: Add a quirk for handling broken SDBS field
 in controller capabilities register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240814-ufs-bug-fix-v1-2-5eb49d5f7571@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1955;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=b/cuuxILW/Nn5o+nE4aellu+itmsZwg73HSlbrIKfVs=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmvOY3lBK7tzrEC7WXwsQVgnENFIxae751N7f5D
 TgEOJSS2GmJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZrzmNwAKCRBVnxHm/pHO
 9cO4B/9PMf0FjxvFCxyoHFRSPjyHN18MiXSQ+tF0M1WFQxJu4PpPJXaHonmx1YLq7X3naUyB1IP
 s9mWrfcQt0saHVbW2B8dQ2J85iIYgIQp1+LSatEUvZKVd0/9csAQAl5r698pHEJZL9lmzBr8jJ8
 Sx8nW+GxxNfPca166Tlabp5p9lI2yUXZwo3Vl2Vrlad7ocnsez9yY2E528vD747w/BwRRfcGYPE
 57eRq80wMINMtBViFvvAMdfzuBE9Ci9m0BNvvKKFCWOL6JAcRAh0eo7WrZPudw28j6Me+MBBmSS
 UHmC3OubIS+a4r71H2ZoYpmJOB0uYEN1m2CjgeisuCUZSu7R
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'Legacy Queue & Single Doorbell Support (SDBS)' field in the controller
capabilities register is supposed to be reserved for UFSHCI 3.0 based
controllers and should read as 0. But some controllers may report bogus
value of 1 due to the hardware bug. So let's add a quirk to handle those
controllers.

If the quirk is enabled by the controller driver and MCQ is not supported,
then 'hba->sdbs_sup' field will be ignored and the SCSI device will be
added in legacy/single doorbell mode.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/ufs/core/ufshcd.c | 5 +++--
 include/ufs/ufshcd.h      | 7 +++++++
 2 files changed, 10 insertions(+), 2 deletions(-)

diff --git a/drivers/ufs/core/ufshcd.c b/drivers/ufs/core/ufshcd.c
index 168b9dbc3ada..acb6f261ecc2 100644
--- a/drivers/ufs/core/ufshcd.c
+++ b/drivers/ufs/core/ufshcd.c
@@ -10512,8 +10512,9 @@ int ufshcd_init(struct ufs_hba *hba, void __iomem *mmio_base, unsigned int irq)
 	}
 
 	if (!is_mcq_supported(hba)) {
-		if (!hba->sdbs_sup) {
-			dev_err(hba->dev, "%s: failed to initialize (legacy doorbell mode not supported)\n",
+		if (!(hba->quirks & UFSHCD_QUIRK_BROKEN_SDBS_CAP) && !hba->sdbs_sup) {
+			dev_err(hba->dev,
+				"%s: failed to initialize (legacy doorbell mode not supported)\n",
 				__func__);
 			err = -EINVAL;
 			goto out_disable;
diff --git a/include/ufs/ufshcd.h b/include/ufs/ufshcd.h
index d44b19cf9f82..85c6ea28d45d 100644
--- a/include/ufs/ufshcd.h
+++ b/include/ufs/ufshcd.h
@@ -676,6 +676,13 @@ enum ufshcd_quirks {
 	 * the standard best practice for managing keys).
 	 */
 	UFSHCD_QUIRK_KEYS_IN_PRDT			= 1 << 24,
+
+	/*
+	 * This quirk needs to be enabled if the host controller has the broken
+	 * Legacy Queue & Single Doorbell Support (SDBS) field in Controller
+	 * Capabilities register.
+	 */
+	UFSHCD_QUIRK_BROKEN_SDBS_CAP			= 1 << 25,
 };
 
 enum ufshcd_caps {

-- 
2.25.1

