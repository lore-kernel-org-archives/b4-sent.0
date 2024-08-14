From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 14 Aug 2024 22:45:36 +0530
Subject: [PATCH 3/3] ufs: qcom: Add UFSHCD_QUIRK_BROKEN_SDBS_CAP for SM8550
 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240814-ufs-bug-fix-v1-3-5eb49d5f7571@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1960;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=tifq6GOjcopPL6cLTuL63f6pon2nnqW5vXlh4Zf80OY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmvOY3a7gkLi2VXbeUSPBQzUF/mhbLHVjzPz/dL
 G5CfvIi/dmJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZrzmNwAKCRBVnxHm/pHO
 9TGXB/9FfmWLoUKrlGEkbnbfPTE0oIH5VWXQrjhKPLgfEbLIXFnoPnIlzWy7xRg5fmNWXw59vUG
 x6cJh/XE29qcDlD1nik03+T4BP3rvailoHF6KiZhz6RdLgjyM/Zvrm5v4lX6Hd1+fX/sXo9yF+p
 XOCUDZQQq91QzS85LvEFRwyih9uDlX1tb22HvbGQkZfM61388t5f/Zcbh3dgO4e2mzzT0dWBnL2
 idV8CjLdhIz36ukGFbuARXLdAGsecnNG4Db6gbaPcrqSZ0Vau4udPnAaOWg1vbfU72wrtsDodo4
 OooygvFfvdYywZTZrvygzxbKtTbXtHUfSPT7ZyNTSdnZTdZS
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM8550 SoC supports the UFSHCI 3.0 spec, but it reports a bogus value of
1 in the reserved 'Legacy Queue & Single Doorbell Support (SDBS)' field of
the Controller Capabilities register. This field is supposed to read 0 as
per the spec.

But starting with commit 0c60eb0cc320 ("scsi: ufs: core: Check LSDBS cap
when !mcq"), ufshcd driver is now relying on the SDBS field to decide when
to use the legacy doorbell mode if MCQ is not supported. And this ends up
breaking UFS on SM8550:

ufshcd-qcom 1d84000.ufs: ufshcd_init: failed to initialize (legacy doorbell mode not supported)
ufshcd-qcom 1d84000.ufs: error -EINVAL: Initialization failed with error -22

So use the UFSHCD_QUIRK_BROKEN_SDBS_CAP quirk for SM8550 SoC so that the
ufshcd driver could use legacy doorbell mode correctly.

Fixes: 674f8bfb1848 ("ufs: qcom: Add UFSHCD_QUIRK_BROKEN_SDBS_CAP for SM8550 SoC")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/ufs/host/ufs-qcom.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/ufs/host/ufs-qcom.c b/drivers/ufs/host/ufs-qcom.c
index 810e637047d0..391b814c318e 100644
--- a/drivers/ufs/host/ufs-qcom.c
+++ b/drivers/ufs/host/ufs-qcom.c
@@ -857,6 +857,9 @@ static void ufs_qcom_advertise_quirks(struct ufs_hba *hba)
 
 	if (host->hw_ver.major > 0x3)
 		hba->quirks |= UFSHCD_QUIRK_REINIT_AFTER_MAX_GEAR_SWITCH;
+
+	if (of_device_is_compatible(hba->dev->of_node, "qcom,sm8550-ufshc"))
+		hba->quirks |= UFSHCD_QUIRK_BROKEN_SDBS_CAP;
 }
 
 static void ufs_qcom_set_phy_gear(struct ufs_qcom_host *host)
@@ -1847,7 +1850,8 @@ static void ufs_qcom_remove(struct platform_device *pdev)
 }
 
 static const struct of_device_id ufs_qcom_of_match[] __maybe_unused = {
-	{ .compatible = "qcom,ufshc"},
+	{ .compatible = "qcom,ufshc" },
+	{ .compatible = "qcom,sm8550-ufshc" },
 	{},
 };
 MODULE_DEVICE_TABLE(of, ufs_qcom_of_match);

-- 
2.25.1

