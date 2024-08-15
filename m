From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 15 Aug 2024 10:46:58 +0530
Subject: [PATCH v2 3/3] ufs: qcom: Add UFSHCD_QUIRK_BROKEN_LSDBS_CAP for
 SM8550 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240815-ufs-bug-fix-v2-3-b373afae888f@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1997;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=86LYSca/QxWt1ChuWxvzEFW+WUoUlJ8CGwZ6Mkg+m0I=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmvY9KezBjEvKBHyC6JRqOSOXSyAJE3HpZf7pEI
 or6TZ3a8LOJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZr2PSgAKCRBVnxHm/pHO
 9VvKCACBCdKo6gmM1PLI+AHofj7KYljAd050Y3VIV1/+QgIwkMGg5fG+pGI6fG8cb66sZPdA5tX
 /lD78a+ijyD33Om5oBfxwOT286+/DZZ4aKfTeusnHQzcRfKJ1FTC4ra/tyHwckiARE6evITcmeS
 +zkez/V9zEy8iZi8BZ6GB9SKMYW+RcEVL9T9TGJSlcf3qoTwFh+7tynG0XOtaYUCJSPeMKTPE0C
 uPdc3Yoh9jx214LyenbxJSK3Vt2YWa2bLvKCnv9K4ra8Gl2VN/A9SJ1IePShCN6NFCkRgG4i38d
 rjbVNRbxmJfIO4jf6SvyzCVDB7Cr2imZqitPFWCt5HaG2qJ5
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM8550 SoC supports the UFSHCI 3.0 spec, but it reports a bogus value of
1 in the reserved 'Legacy Queue & Single Doorbell Support (LSDBS)' field of
the Controller Capabilities register. This field is supposed to read 0 as
per the spec.

But starting with commit 0c60eb0cc320 ("scsi: ufs: core: Check LSDBS cap
when !mcq"), ufshcd driver is now relying on the LSDBS field to decide when
to use the legacy doorbell mode if MCQ is not supported. And this ends up
breaking UFS on SM8550:

ufshcd-qcom 1d84000.ufs: ufshcd_init: failed to initialize (legacy doorbell mode not supported)
ufshcd-qcom 1d84000.ufs: error -EINVAL: Initialization failed with error -22

So use the UFSHCD_QUIRK_BROKEN_LSDBS_CAP quirk for SM8550 SoC so that the
ufshcd driver could use legacy doorbell mode correctly.

Fixes: 0c60eb0cc320 ("scsi: ufs: core: Check LSDBS cap when !mcq")
Tested-by: Amit Pundir <amit.pundir@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/ufs/host/ufs-qcom.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/ufs/host/ufs-qcom.c b/drivers/ufs/host/ufs-qcom.c
index 810e637047d0..c87fdc849c62 100644
--- a/drivers/ufs/host/ufs-qcom.c
+++ b/drivers/ufs/host/ufs-qcom.c
@@ -857,6 +857,9 @@ static void ufs_qcom_advertise_quirks(struct ufs_hba *hba)
 
 	if (host->hw_ver.major > 0x3)
 		hba->quirks |= UFSHCD_QUIRK_REINIT_AFTER_MAX_GEAR_SWITCH;
+
+	if (of_device_is_compatible(hba->dev->of_node, "qcom,sm8550-ufshc"))
+		hba->quirks |= UFSHCD_QUIRK_BROKEN_LSDBS_CAP;
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

