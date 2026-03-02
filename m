From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 02 Mar 2026 18:30:20 +0530
Subject: [PATCH v4 3/5] soc: qcom: ice: Return proper error codes from
 devm_of_qcom_ice_get() instead of NULL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260302-qcom-ice-fix-v4-3-0e65740a5dcc@oss.qualcomm.com>
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
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2044;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=wcyxYq4Tgpup9Do39u+XA9vsCKJN7lfFY2ui7J75Wis=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBppYny/cFuqyJR2X+PHP0XenRX/H7FOEDHMKcei
 WKpc2z4bluJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaaWJ8gAKCRBVnxHm/pHO
 9bM4CACpLJaBbWBLKf0lPk54F/UMS42G1MXslRbhONAQBNIv5Lyi3chLoO05X+k4Vb1FQQ4leFi
 shEZ4cPIsg4C2t/3iMUgtOsDSvHXZ3X6Z/F26wp9n59naoctuDJbeJfEqeWuouwbRHCKev78KmT
 Gf8HC+wE2HkrWzUlObWxJf5orlfbtaOoQgaNGkRxeQ+JLz613896OsmGvALchCW1yKBR/8TiD1c
 Q3sP40A1O4jlf2LqEZKFmWlrSdHCw3PQ4RCM3uwH6f01JLE14GVEQlGr2MlW9QtBQC7DLlPTXdL
 WIbmXl+RpXtvsjOSgbXKkHB2P2sOiZNWgOPjORNBmjBC4fav
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

devm_of_qcom_ice_get() currently returns NULL if ICE SCM is not available
or "qcom,ice" property is not found in DT. But this confuses the clients
since NULL doesn't convey the reason for failure. So return proper error
codes instead of NULL.

Reported-by: Sumit Garg <sumit.garg@oss.qualcomm.com>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/soc/qcom/ice.c | 9 ++++-----
 1 file changed, 4 insertions(+), 5 deletions(-)

diff --git a/drivers/soc/qcom/ice.c b/drivers/soc/qcom/ice.c
index 833d23dc7b06..d1efc676b63c 100644
--- a/drivers/soc/qcom/ice.c
+++ b/drivers/soc/qcom/ice.c
@@ -561,7 +561,7 @@ static struct qcom_ice *qcom_ice_create(struct device *dev,
 
 	if (!qcom_scm_ice_available()) {
 		dev_warn(dev, "ICE SCM interface not found\n");
-		return NULL;
+		return ERR_PTR(-EOPNOTSUPP);
 	}
 
 	engine = devm_kzalloc(dev, sizeof(*engine), GFP_KERNEL);
@@ -643,7 +643,7 @@ static struct qcom_ice *of_qcom_ice_get(struct device *dev)
 	struct device_node *node __free(device_node) = of_parse_phandle(dev->of_node,
 									"qcom,ice", 0);
 	if (!node)
-		return NULL;
+		return ERR_PTR(-ENODEV);
 
 	pdev = of_find_device_by_node(node);
 	if (!pdev) {
@@ -696,8 +696,7 @@ static void devm_of_qcom_ice_put(struct device *dev, void *res)
  * phandle via 'qcom,ice' property to an ICE DT, the ICE instance will already
  * be created and so this function will return that instead.
  *
- * Return: ICE pointer on success, NULL if there is no ICE data provided by the
- * consumer or ERR_PTR() on error.
+ * Return: ICE pointer on success, ERR_PTR() on error.
  */
 struct qcom_ice *devm_of_qcom_ice_get(struct device *dev)
 {
@@ -708,7 +707,7 @@ struct qcom_ice *devm_of_qcom_ice_get(struct device *dev)
 		return ERR_PTR(-ENOMEM);
 
 	ice = of_qcom_ice_get(dev);
-	if (!IS_ERR_OR_NULL(ice)) {
+	if (!IS_ERR(ice)) {
 		*dr = ice;
 		devres_add(dev, dr);
 	} else {

-- 
2.51.0

