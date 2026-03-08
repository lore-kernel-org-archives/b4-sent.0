From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Sun, 08 Mar 2026 11:57:28 +0530
Subject: [PATCH v5 2/5] soc: qcom: ice: Return -ENODEV if the ICE platform
 device is not found
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260308-qcom-ice-fix-v5-2-e47e8a44b6c4@oss.qualcomm.com>
References: <20260308-qcom-ice-fix-v5-0-e47e8a44b6c4@oss.qualcomm.com>
In-Reply-To: <20260308-qcom-ice-fix-v5-0-e47e8a44b6c4@oss.qualcomm.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 Ulf Hansson <ulf.hansson@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>, 
 Abel Vesa <abelvesa@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mmc@vger.kernel.org, linux-scsi@vger.kernel.org, 
 Sumit Garg <sumit.garg@oss.qualcomm.com>, mani@kernel.org, 
 Neeraj Soni <neeraj.soni@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1019;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=qK8flUkY0AriLSe7KcyTU7F/qyhSLO0EesRORdT3ebw=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBprRbgpEihdBq/VekYMOVpYQpxR2dndsZ0jfLVc
 f/e3W4jLH6JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaa0W4AAKCRBVnxHm/pHO
 9TeLCACNEQZO5ZWO2YQTSc4uFt1AiK9S4awX4aq1UZie2nSbEgl8Ip/AleqS9vFyBx3RJhaiZxR
 EZtqRzRakfe2Xvzes7MZqM1HB4qTiDXAJrG6znGrX3EfaVIDQGciyqw9MWB6W9JjK/DNEgi1qzx
 TtfNaPUxRRtY2noVeZCLO3cf6spd1/kkDo4WUjJxR8o5h6vLEmxuiTpXfAzokdPtzifK3CyEQ1y
 ePIm1HjLIP7d77xbnL1+ypVQAgizz12mrRLNqRZPnrUyrpbh8SA+g71nCAeZQPhXpqP2i0bcanp
 vNjsqTYHh839x9inqvexMrbyZW66SzZ+sbcjLSxM71pZlufD
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

By the time the consumer driver calls devm_of_qcom_ice_get(), all the
platform devices for ICE nodes would've been created by
of_platform_default_populate().

So for the absence of any platform device, -ENODEV should not returned, not
-EPROBE_DEFER.

Fixes: 2afbf43a4aec ("soc: qcom: Make the Qualcomm UFS/SDCC ICE a dedicated driver")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/soc/qcom/ice.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/soc/qcom/ice.c b/drivers/soc/qcom/ice.c
index 50da5a3e8073..6fde282584d0 100644
--- a/drivers/soc/qcom/ice.c
+++ b/drivers/soc/qcom/ice.c
@@ -650,7 +650,7 @@ static struct qcom_ice *of_qcom_ice_get(struct device *dev)
 	pdev = of_find_device_by_node(node);
 	if (!pdev) {
 		dev_err(dev, "Cannot find device node %s\n", node->name);
-		return ERR_PTR(-EPROBE_DEFER);
+		return ERR_PTR(-ENODEV);
 	}
 
 	ice = xa_load(&ice_handles, pdev->dev.of_node->phandle);

-- 
2.51.0

