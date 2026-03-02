From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 02 Mar 2026 18:30:18 +0530
Subject: [PATCH v4 1/5] soc: qcom: ice: Fix race between qcom_ice_probe()
 and of_qcom_ice_get()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260302-qcom-ice-fix-v4-1-0e65740a5dcc@oss.qualcomm.com>
References: <20260302-qcom-ice-fix-v4-0-0e65740a5dcc@oss.qualcomm.com>
In-Reply-To: <20260302-qcom-ice-fix-v4-0-0e65740a5dcc@oss.qualcomm.com>
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
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3469;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=PxxI5HrtkjPrewqydVjynd/KfkIqbLW5DMY9IbWY+NA=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBppYnyYy1MQoGSXd/MDRFIrOfC/xxPjbIcsmm6f
 lyIwDa27+KJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaaWJ8gAKCRBVnxHm/pHO
 9fXMB/4kmYdO/8QSldFwnY9RlPzmF3wDrJqZfUBmCjSLXpzobrai5e3qPCC8OC5IfHmiKBSiJzK
 d34+Ra8ERcgshcviBGZXHljmwY5mGaTdhFzhkbt4sSoIq6IxQCNLp7oswrCjHJ07P504km+h46w
 vMO7T676t4oQTLOAinGa9weFEIcpy8va4XWuMuenNyA4SYtpVb6xabm64cIYHZ5666Nc0KKNDKF
 aDCJqSkzTgWM/g+aymzYHPtun8gLP91xJWvDEqLWFixvSVoqcI/+WrxL8sEWiYe+BY5JF65elxK
 iSmvaF/YbWxoBseeCvO+DBVHs1chMmaVHyQXwVegRb4JCn2X
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The current platform driver design causes probe ordering races with
consumers (UFS, eMMC) due to ICE's dependency on SCM firmware calls. If ICE
probe fails (missing ICE SCM or DT registers), devm_of_qcom_ice_get() loops
with -EPROBE_DEFER, leaving consumers non-functional even when ICE should
be gracefully disabled. devm_of_qcom_ice_get() doesn't know if the ICE
driver probe has failed due to above reasons or it is waiting for the SCM
driver.

Moreover, there is no devlink dependency between ICE and consumer drivers
as 'qcom,ice' is not considered as a DT 'supplier'. So the consumer drivers
have no idea of when the ICE driver is going to probe.

To address these issues, store the error pointer in the platform drvdata
during probe in addition to the valid ice pointer and synchronize both
qcom_ice_probe() and of_qcom_ice_get() using a mutex.

If the platform drvdata is NULL, then it implies that the driver is not
probed yet, so return -EPROBE_DEFER. If it has any error pointer, return
that error pointer directly.

Note that this change only fixes the standalone ICE DT node bindings and
not the ones with 'ice' range embedded in the consumer nodes, where there
is no issue.

Cc: <stable@vger.kernel.org> # 6.4
Fixes: 2afbf43a4aec ("soc: qcom: Make the Qualcomm UFS/SDCC ICE a dedicated driver")
Reported-by: Sumit Garg <sumit.garg@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/soc/qcom/ice.c | 22 +++++++++++++++++-----
 1 file changed, 17 insertions(+), 5 deletions(-)

diff --git a/drivers/soc/qcom/ice.c b/drivers/soc/qcom/ice.c
index b203bc685cad..a7e7e2251015 100644
--- a/drivers/soc/qcom/ice.c
+++ b/drivers/soc/qcom/ice.c
@@ -113,6 +113,8 @@ struct qcom_ice {
 	u8 hwkm_version;
 };
 
+static DEFINE_MUTEX(ice_mutex);
+
 static bool qcom_ice_check_supported(struct qcom_ice *ice)
 {
 	u32 regval = qcom_ice_readl(ice, QCOM_ICE_REG_VERSION);
@@ -631,6 +633,8 @@ static struct qcom_ice *of_qcom_ice_get(struct device *dev)
 		return qcom_ice_create(&pdev->dev, base);
 	}
 
+	guard(mutex)(&ice_mutex);
+
 	/*
 	 * If the consumer node does not provider an 'ice' reg range
 	 * (legacy DT binding), then it must at least provide a phandle
@@ -648,11 +652,12 @@ static struct qcom_ice *of_qcom_ice_get(struct device *dev)
 	}
 
 	ice = platform_get_drvdata(pdev);
-	if (!ice) {
-		dev_err(dev, "Cannot get ice instance from %s\n",
-			dev_name(&pdev->dev));
+	if (IS_ERR_OR_NULL(ice)) {
 		platform_device_put(pdev);
-		return ERR_PTR(-EPROBE_DEFER);
+		if (!ice)
+			return ERR_PTR(-EPROBE_DEFER);
+		else
+			return ice;
 	}
 
 	link = device_link_add(dev, &pdev->dev, DL_FLAG_AUTOREMOVE_SUPPLIER);
@@ -719,15 +724,22 @@ static int qcom_ice_probe(struct platform_device *pdev)
 	struct qcom_ice *engine;
 	void __iomem *base;
 
+	guard(mutex)(&ice_mutex);
+
 	base = devm_platform_ioremap_resource(pdev, 0);
 	if (IS_ERR(base)) {
 		dev_warn(&pdev->dev, "ICE registers not found\n");
+		/* Store the error pointer for devm_of_qcom_ice_get() */
+		platform_set_drvdata(pdev, base);
 		return PTR_ERR(base);
 	}
 
 	engine = qcom_ice_create(&pdev->dev, base);
-	if (IS_ERR(engine))
+	if (IS_ERR(engine)) {
+		/* Store the error pointer for devm_of_qcom_ice_get() */
+		platform_set_drvdata(pdev, engine);
 		return PTR_ERR(engine);
+	}
 
 	platform_set_drvdata(pdev, engine);
 

-- 
2.51.0

