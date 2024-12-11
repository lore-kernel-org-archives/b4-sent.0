From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 11 Dec 2024 23:10:18 +0530
Subject: [PATCH 3/3] scsi: ufs: qcom: Power down the controller/device
 during system suspend for SM8550/SM8650 SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241211-ufs-qcom-suspend-fix-v1-3-83ebbde76b1c@linaro.org>
References: <20241211-ufs-qcom-suspend-fix-v1-0-83ebbde76b1c@linaro.org>
In-Reply-To: <20241211-ufs-qcom-suspend-fix-v1-0-83ebbde76b1c@linaro.org>
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
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=3031;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=m5hbLz2BGZb5dhnCo0YRsTuGrLlxs9RKo35x8MdorCc=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnWc6Jug+g5MxE/VtEK2FjzQbk0JDLOIwfZX5Tl
 Vf22pIM+W+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ1nOiQAKCRBVnxHm/pHO
 9ZaeCACitOr4/p3gF5QRQdrXLl85xxdiyVtcay3Km0nrxGt/olEHn09g41akBMRRYCz7KRxHV+o
 8ZCk+K7D5TAoKrro2bSxB2+4HOnj+e+1fMcIk0g5kXGR2SEH3duAHwDFIG1lLnaZ+X8yZTG5IXq
 ClAFlu1QUyMWm5dS/HVj8U3+ozYaBH4j/dBkTfU2zKr2n3JSlFOKfYdFvU1o9IXaFIbQLYwMbv9
 nAvAAimgyWBXS3549KJVEn0GSekNDL+lWYbdv1ltewh8mRNpUTSHoRezXW/s8IvwOF2/PnXIGU5
 jsRrfks0BFX/Ol+usp5F+KPrcHrJYJsgO56/SyZqQC6hOsVF
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM8550 and SM8650 SoCs doesn't support UFS PHY retention. So once these
SoCs reaches the low power state (CX power collapse) during system suspend,
all the PHY hardware state gets lost. This leads to the UFS resume failure:

ufshcd-qcom 1d84000.ufs: ufshcd_uic_hibern8_exit: hibern8 exit failed. ret = 5
ufshcd-qcom 1d84000.ufs: __ufshcd_wl_resume: hibern8 exit failed 5
ufs_device_wlun 0:0:0:49488: ufshcd_wl_resume failed: 5
ufs_device_wlun 0:0:0:49488: PM: dpm_run_callback(): scsi_bus_resume+0x0/0x84 returns 5
ufs_device_wlun 0:0:0:49488: PM: failed to resume async: error 5

With the default system suspend level of UFS_PM_LVL_3, the power domain for
UFS PHY needs to be kept always ON to retain the state. But this would
prevent these SoCs from reaching the CX power collapse state, leading to
poor power saving during system suspend.

So to fix this issue without affecting the power saving, set
'ufs_qcom_drvdata::no_phy_retention' to true which sets 'hba->spm_lvl' to
UFS_PM_LVL_5 to allow both the controller and device (in turn the PHY) to
be powered down during system suspend for these SoCs by default.

Cc: stable@vger.kernel.org # 6.3
Fixes: 35cf1aaab169 ("arm64: dts: qcom: sm8550: Add UFS host controller and phy nodes")
Fixes: 10e024671295 ("arm64: dts: qcom: sm8650: add interconnect dependent device nodes")
Reported-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/ufs/host/ufs-qcom.c | 5 +++++
 drivers/ufs/host/ufs-qcom.h | 1 +
 2 files changed, 6 insertions(+)

diff --git a/drivers/ufs/host/ufs-qcom.c b/drivers/ufs/host/ufs-qcom.c
index 35ae8c8fc301..edf62430cabe 100644
--- a/drivers/ufs/host/ufs-qcom.c
+++ b/drivers/ufs/host/ufs-qcom.c
@@ -1069,6 +1069,7 @@ static int ufs_qcom_init(struct ufs_hba *hba)
 	struct device *dev = hba->dev;
 	struct ufs_qcom_host *host;
 	struct ufs_clk_info *clki;
+	const struct ufs_qcom_drvdata *drvdata = of_device_get_match_data(hba->dev);
 
 	host = devm_kzalloc(dev, sizeof(*host), GFP_KERNEL);
 	if (!host)
@@ -1148,6 +1149,9 @@ static int ufs_qcom_init(struct ufs_hba *hba)
 		dev_warn(dev, "%s: failed to configure the testbus %d\n",
 				__func__, err);
 
+	if (drvdata && drvdata->no_phy_retention)
+		hba->spm_lvl = UFS_PM_LVL_5;
+
 	return 0;
 
 out_variant_clear:
@@ -1866,6 +1870,7 @@ static void ufs_qcom_remove(struct platform_device *pdev)
 
 static const struct ufs_qcom_drvdata ufs_qcom_sm8550_drvdata = {
 	.quirks = UFSHCD_QUIRK_BROKEN_LSDBS_CAP,
+	.no_phy_retention = true,
 };
 
 static const struct of_device_id ufs_qcom_of_match[] __maybe_unused = {
diff --git a/drivers/ufs/host/ufs-qcom.h b/drivers/ufs/host/ufs-qcom.h
index e85cc6fc072e..5a7b2fe4a7c9 100644
--- a/drivers/ufs/host/ufs-qcom.h
+++ b/drivers/ufs/host/ufs-qcom.h
@@ -219,6 +219,7 @@ struct ufs_qcom_host {
 
 struct ufs_qcom_drvdata {
 	unsigned int quirks;
+	bool no_phy_retention;
 };
 
 static inline u32

-- 
2.25.1

