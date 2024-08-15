From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 15 Aug 2024 10:46:57 +0530
Subject: [PATCH v2 2/3] ufs: core: Add a quirk for handling broken LSDBS
 field in controller capabilities register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240815-ufs-bug-fix-v2-2-b373afae888f@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1982;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=MCIRPdIw7ETAreNWkpU0sRIHAGg28eU3fllnElqMe2c=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmvY9K42XDU3zXkh8FTpsrZGIqprZAcOJUKh6e5
 LYBQbLGUpKJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZr2PSgAKCRBVnxHm/pHO
 9d5UCACQsRMTBjEYzY25J46wBA0oF+Efi6dHqYgYJnNyd9Ed3kgAuLh0S9/FvKP4vIpLQtOmBCm
 SolfhpoHqvGg4/lj313fwwOoY3BlGqJBAjRO2ruTMb8QJnTSn0WeMC9eXDZJ9sLIW1ZwB3Q/cbF
 ILstaNVW9sRcPITMglvKi3+GQu4TbDmsQmiVME6Nq/Sc7eCxjWYSq77umg6VOBRcuwIls4xzRnk
 w9ePwQVYmYjuKZDWkXuoI1JXyJ+bdH239tCOBqa4qN7do/Omk2WXaJFTRIwonXEIRFJpdlz3B/p
 1PcsYCGvY5R/EcUaGCbBiTD1cFdLR7wkVxyATHqkSUzUIQou
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'Legacy Queue & Single Doorbell Support (LSDBS)' field in the controller
capabilities register is supposed to be reserved for UFSHCI 3.0 based
controllers and should read as 0. But some controllers may report bogus
value of 1 due to the hardware bug. So let's add a quirk to handle those
controllers.

If the quirk is enabled by the controller driver, then LSDBS register field
will be ignored and legacy/single doorbell mode is assumed to be enabled
always.

Tested-by: Amit Pundir <amit.pundir@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/ufs/core/ufshcd.c | 6 +++++-
 include/ufs/ufshcd.h      | 7 +++++++
 2 files changed, 12 insertions(+), 1 deletion(-)

diff --git a/drivers/ufs/core/ufshcd.c b/drivers/ufs/core/ufshcd.c
index 0b1787074215..8c9ff8696bcd 100644
--- a/drivers/ufs/core/ufshcd.c
+++ b/drivers/ufs/core/ufshcd.c
@@ -2426,7 +2426,11 @@ static inline int ufshcd_hba_capabilities(struct ufs_hba *hba)
 	 * 0h: legacy single doorbell support is available
 	 * 1h: indicate that legacy single doorbell support has been removed
 	 */
-	hba->lsdbs_sup = !FIELD_GET(MASK_LSDBS_SUPPORT, hba->capabilities);
+	if (!(hba->quirks & UFSHCD_QUIRK_BROKEN_LSDBS_CAP))
+		hba->lsdbs_sup = !FIELD_GET(MASK_LSDBS_SUPPORT, hba->capabilities);
+	else
+		hba->lsdbs_sup = true;
+
 	if (!hba->mcq_sup)
 		return 0;
 
diff --git a/include/ufs/ufshcd.h b/include/ufs/ufshcd.h
index c6ab1c671ad7..250adb6eddb6 100644
--- a/include/ufs/ufshcd.h
+++ b/include/ufs/ufshcd.h
@@ -676,6 +676,13 @@ enum ufshcd_quirks {
 	 * the standard best practice for managing keys).
 	 */
 	UFSHCD_QUIRK_KEYS_IN_PRDT			= 1 << 24,
+
+	/*
+	 * This quirk needs to be enabled if the host controller has the broken
+	 * Legacy Queue & Single Doorbell Support (LSDBS) field in Controller
+	 * Capabilities register.
+	 */
+	UFSHCD_QUIRK_BROKEN_LSDBS_CAP			= 1 << 25,
 };
 
 enum ufshcd_caps {

-- 
2.25.1

