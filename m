From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Fri, 16 Aug 2024 11:55:10 +0530
Subject: [PATCH v3 1/2] ufs: core: Add a quirk for handling broken LSDBS
 field in controller capabilities register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240816-ufs-bug-fix-v3-1-e6fe0e18e2a3@linaro.org>
References: <20240816-ufs-bug-fix-v3-0-e6fe0e18e2a3@linaro.org>
In-Reply-To: <20240816-ufs-bug-fix-v3-0-e6fe0e18e2a3@linaro.org>
To: Alim Akhtar <alim.akhtar@samsung.com>, 
 Avri Altman <avri.altman@wdc.com>, Bart Van Assche <bvanassche@acm.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
Cc: linux-scsi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Kyoungrul Kim <k831.kim@samsung.com>, 
 Amit Pundir <amit.pundir@linaro.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2110;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=SPYkfqfo4Q1r17yald0viJ0Kdv4k2BQ9xtG4Fmr+8+w=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmvvDHq0jzkKSUn4HFBas0ngL6QLNvB73pon7rx
 Uduh/cpjtWJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZr7wxwAKCRBVnxHm/pHO
 9WRQCACLKRBqWESX7mELXEcfRVYlDNQ46hVNTfetT3ZhALCtfZc/t5UeaxTxoXuVF98Hb7SLQvS
 eVRduCS+H7Q8jUML7CwjWPBl2TsaW/U+EOd6mKfXdHQekAo5owyBvFEUE+7Y5dqQwGNiQlyXreB
 /YV5LeFg5AsESejFe/5vu/sTcftEGSOaTjlL2toiY3YjRrcFN4q2QjWsHtCq109pCXx86PB3hVi
 xVdL7Cadq+IdOLwbsAqRC0SovO1ryf7EV0Jp7AksuTk7dxR20bftLxzkG8L2jSFMvkz/6/ppvq9
 +IqO/NeVCTCeM+M7zkhFHvHmdnIwGgqiqixtNw/lHQbbdGZO
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'Legacy Queue & Single Doorbell Support (LSDBS)' field in the controller
capabilities register is supposed to report whether the legacy single
doorbell mode is supported in the controller or not. But some controllers
report '1' in this field which corresponds to 'LSDB not supported', but
they indeed support LSDB. So let's add a quirk to handle those controllers.

If the quirk is enabled by the controller driver, then LSDBS register field
will be ignored and legacy single doorbell mode is assumed to be enabled
always.

Tested-by: Amit Pundir <amit.pundir@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/ufs/core/ufshcd.c | 6 +++++-
 include/ufs/ufshcd.h      | 8 ++++++++
 2 files changed, 13 insertions(+), 1 deletion(-)

diff --git a/drivers/ufs/core/ufshcd.c b/drivers/ufs/core/ufshcd.c
index 0b3d0c8e0dda..a6f818cdef0e 100644
--- a/drivers/ufs/core/ufshcd.c
+++ b/drivers/ufs/core/ufshcd.c
@@ -2426,7 +2426,11 @@ static inline int ufshcd_hba_capabilities(struct ufs_hba *hba)
 	 * 0h: legacy single doorbell support is available
 	 * 1h: indicate that legacy single doorbell support has been removed
 	 */
-	hba->lsdb_sup = !FIELD_GET(MASK_LSDB_SUPPORT, hba->capabilities);
+	if (!(hba->quirks & UFSHCD_QUIRK_BROKEN_LSDBS_CAP))
+		hba->lsdb_sup = !FIELD_GET(MASK_LSDB_SUPPORT, hba->capabilities);
+	else
+		hba->lsdb_sup = true;
+
 	if (!hba->mcq_sup)
 		return 0;
 
diff --git a/include/ufs/ufshcd.h b/include/ufs/ufshcd.h
index cac0cdb9a916..0fd2aebac728 100644
--- a/include/ufs/ufshcd.h
+++ b/include/ufs/ufshcd.h
@@ -676,6 +676,14 @@ enum ufshcd_quirks {
 	 * the standard best practice for managing keys).
 	 */
 	UFSHCD_QUIRK_KEYS_IN_PRDT			= 1 << 24,
+
+	/*
+	 * This quirk indicates that the controller reports the value 1 (not
+	 * supported) in the Legacy Single DoorBell Support (LSDBS) bit of the
+	 * Controller Capabilities register although it supports the legacy
+	 * single doorbell mode.
+	 */
+	UFSHCD_QUIRK_BROKEN_LSDBS_CAP			= 1 << 25,
 };
 
 enum ufshcd_caps {

-- 
2.25.1

