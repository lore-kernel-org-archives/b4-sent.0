From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Fri, 13 Dec 2024 19:23:30 +0530
Subject: [PATCH v2 2/3] scsi: ufs: qcom: Allow passing platform specific OF
 data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241213-ufs-qcom-suspend-fix-v2-2-1de6cd2d6146@linaro.org>
References: <20241213-ufs-qcom-suspend-fix-v2-0-1de6cd2d6146@linaro.org>
In-Reply-To: <20241213-ufs-qcom-suspend-fix-v2-0-1de6cd2d6146@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2709;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=qqrxdC5u7a2vZfs8QFNpeAZBHqn1+eO7J3Xdho8U5SY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnXDxc+9/I1Jb3eWtP2983AMBHpbG+joy36Ntck
 aqYAwgqzuGJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ1w8XAAKCRBVnxHm/pHO
 9aJeB/4jtWCKxXc9qwEo64zElXLbEEQqNkPs8ZnFmOG3ENGVzDQ2g+83YJ8nG/1g8wSuEOBu62N
 qUDUwnTp4Ts14JmWMiJXz3Wa+lewGZqnxCBupsDRuUZ81AL/z+2e3Z8xj5qiiAbYGGaiuyu+zKJ
 BrJny0V8yHUkbCsqF3Tg2X8oFBS5TM1IRvPSyZp9yzRK/1ODd/lolElkJ8QBDWS2fzzGyqrMtbU
 tsmMKYCDb1i8f4dXhs2FmxvxIbzGKARMqpCNTRLWmjecOsIGUYrbNsc+JzGzlvfvmsBIDGaUt2O
 E81DEi3LOH/iNxMpxb+pXg/MTiRrUiHW8RmuphVT4X46R0km
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In order to allow platform specific flags and configurations, introduce
the platform specific OF data and move the existing quirk
UFSHCD_QUIRK_BROKEN_LSDBS_CAP for SM8550 and SM8650 SoCs.

Reviewed-by: Avri Altman <avri.altman@wdc.com>
Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Tested-by: Amit Pundir <amit.pundir@linaro.org> # on SM8550-HDK
Reviewed-by: Bart Van Assche <bvanassche@acm.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/ufs/host/ufs-qcom.c | 13 +++++++++----
 drivers/ufs/host/ufs-qcom.h |  4 ++++
 2 files changed, 13 insertions(+), 4 deletions(-)

diff --git a/drivers/ufs/host/ufs-qcom.c b/drivers/ufs/host/ufs-qcom.c
index 32b0c74437de..35ae8c8fc301 100644
--- a/drivers/ufs/host/ufs-qcom.c
+++ b/drivers/ufs/host/ufs-qcom.c
@@ -871,6 +871,7 @@ static u32 ufs_qcom_get_ufs_hci_version(struct ufs_hba *hba)
  */
 static void ufs_qcom_advertise_quirks(struct ufs_hba *hba)
 {
+	const struct ufs_qcom_drvdata *drvdata = of_device_get_match_data(hba->dev);
 	struct ufs_qcom_host *host = ufshcd_get_variant(hba);
 
 	if (host->hw_ver.major == 0x2)
@@ -879,9 +880,8 @@ static void ufs_qcom_advertise_quirks(struct ufs_hba *hba)
 	if (host->hw_ver.major > 0x3)
 		hba->quirks |= UFSHCD_QUIRK_REINIT_AFTER_MAX_GEAR_SWITCH;
 
-	if (of_device_is_compatible(hba->dev->of_node, "qcom,sm8550-ufshc") ||
-	    of_device_is_compatible(hba->dev->of_node, "qcom,sm8650-ufshc"))
-		hba->quirks |= UFSHCD_QUIRK_BROKEN_LSDBS_CAP;
+	if (drvdata && drvdata->quirks)
+		hba->quirks |= drvdata->quirks;
 }
 
 static void ufs_qcom_set_phy_gear(struct ufs_qcom_host *host)
@@ -1864,9 +1864,14 @@ static void ufs_qcom_remove(struct platform_device *pdev)
 	platform_device_msi_free_irqs_all(hba->dev);
 }
 
+static const struct ufs_qcom_drvdata ufs_qcom_sm8550_drvdata = {
+	.quirks = UFSHCD_QUIRK_BROKEN_LSDBS_CAP,
+};
+
 static const struct of_device_id ufs_qcom_of_match[] __maybe_unused = {
 	{ .compatible = "qcom,ufshc" },
-	{ .compatible = "qcom,sm8550-ufshc" },
+	{ .compatible = "qcom,sm8550-ufshc", .data = &ufs_qcom_sm8550_drvdata },
+	{ .compatible = "qcom,sm8650-ufshc", .data = &ufs_qcom_sm8550_drvdata },
 	{},
 };
 MODULE_DEVICE_TABLE(of, ufs_qcom_of_match);
diff --git a/drivers/ufs/host/ufs-qcom.h b/drivers/ufs/host/ufs-qcom.h
index b9de170983c9..15f6dad8b27f 100644
--- a/drivers/ufs/host/ufs-qcom.h
+++ b/drivers/ufs/host/ufs-qcom.h
@@ -217,6 +217,10 @@ struct ufs_qcom_host {
 	bool esi_enabled;
 };
 
+struct ufs_qcom_drvdata {
+	enum ufshcd_quirks quirks;
+};
+
 static inline u32
 ufs_qcom_get_debug_reg_offset(struct ufs_qcom_host *host, u32 reg)
 {

-- 
2.25.1

