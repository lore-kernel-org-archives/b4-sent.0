From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 19 Dec 2024 22:20:42 +0530
Subject: [PATCH v3 2/4] scsi: ufs: core: Honor runtime/system PM levels if
 set by host controller drivers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241219-ufs-qcom-suspend-fix-v3-2-63c4b95a70b9@linaro.org>
References: <20241219-ufs-qcom-suspend-fix-v3-0-63c4b95a70b9@linaro.org>
In-Reply-To: <20241219-ufs-qcom-suspend-fix-v3-0-63c4b95a70b9@linaro.org>
To: Alim Akhtar <alim.akhtar@samsung.com>, 
 Avri Altman <avri.altman@wdc.com>, Bart Van Assche <bvanassche@acm.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>, 
 Abel Vesa <abel.vesa@linaro.org>, Bjorn Andersson <andersson@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-scsi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Amit Pundir <amit.pundir@linaro.org>, 
 Nitin Rawat <quic_nitirawa@quicinc.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1298;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=CRWjLkvIxV4yD3thmr9VSmE0rgLr7gmhR3D9+FQt6n0=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnZE7uo9JDtBHj/whdrBNMHmrHxXGvhWDyD21nP
 Rk0uUflwliJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ2RO7gAKCRBVnxHm/pHO
 9UfnCACaTTbmqXfVWbdx0Z4CIy5jVMfx3twVFrnWMKfDpsF79GFuaoRc1ZPukPBANbMu4+QX+G8
 V0UaSwAHk1a2fPX81UCFktcISXhztKG7LRbVhMWNzhGjgg+s4guX5XPdIMblxqlY/OjRI+StU2G
 LZSGaiaqdgyhFMHgtqVfDMau9dQt4ejEjLJ8MvnVsTgVfKcmtMvAO8uySWWedsrsHHtq+f4yTWw
 P/AXrdrwNCI0538WdWdoBk7KwgQi+SUUBlWOfMBHElrgzOI9lQWKX34ZSDMnN2fQv0MDgX7ViMu
 rvbu7SVRawvsplswqleEFkA68GwMFcLSgWC9zIZvEidrc5DT
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Otherwise, the default levels will override the levels set by the host
controller drivers.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/ufs/core/ufshcd.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/ufs/core/ufshcd.c b/drivers/ufs/core/ufshcd.c
index 7bd0f5482db3..457add6edb31 100644
--- a/drivers/ufs/core/ufshcd.c
+++ b/drivers/ufs/core/ufshcd.c
@@ -10551,14 +10551,17 @@ int ufshcd_init(struct ufs_hba *hba, void __iomem *mmio_base, unsigned int irq)
 	}
 
 	/*
-	 * Set the default power management level for runtime and system PM.
+	 * Set the default power management level for runtime and system PM if
+	 * not set by the host controller drivers.
 	 * Default power saving mode is to keep UFS link in Hibern8 state
 	 * and UFS device in sleep state.
 	 */
-	hba->rpm_lvl = ufs_get_desired_pm_lvl_for_dev_link_state(
+	if (!hba->rpm_lvl)
+		hba->rpm_lvl = ufs_get_desired_pm_lvl_for_dev_link_state(
 						UFS_SLEEP_PWR_MODE,
 						UIC_LINK_HIBERN8_STATE);
-	hba->spm_lvl = ufs_get_desired_pm_lvl_for_dev_link_state(
+	if (!hba->spm_lvl)
+		hba->spm_lvl = ufs_get_desired_pm_lvl_for_dev_link_state(
 						UFS_SLEEP_PWR_MODE,
 						UIC_LINK_HIBERN8_STATE);
 

-- 
2.25.1

