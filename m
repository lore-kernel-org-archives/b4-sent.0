From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 10 Feb 2026 12:26:51 +0530
Subject: [PATCH v2 2/4] soc: qcom: ice: Return proper error codes from
 devm_of_qcom_ice_get() instead of NULL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260210-qcom-ice-fix-v2-2-9c1ab5d6502c@oss.qualcomm.com>
References: <20260210-qcom-ice-fix-v2-0-9c1ab5d6502c@oss.qualcomm.com>
In-Reply-To: <20260210-qcom-ice-fix-v2-0-9c1ab5d6502c@oss.qualcomm.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abel.vesa@linaro.org>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 Ulf Hansson <ulf.hansson@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mmc@vger.kernel.org, linux-scsi@vger.kernel.org, 
 Sumit Garg <sumit.garg@oss.qualcomm.com>, mani@kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1991;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=R3ti+Do4o2blOWOwxCpVWH7G3OaIyEGRpXFXfGBMGwo=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpita4hjQe5fQN8fLFldr783St9cfJQ2pKAom0u
 BxfbrQuiKyJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaYrWuAAKCRBVnxHm/pHO
 9bSNB/9Ys1wwQndfMoM+YNJqTzJ0bBhbgtGkAXjt+CgID8ZLWfGL3duLhuG7Eif4zs1MN/B7fVP
 jxPKfkL/Z5gcKtKrgO3+gIpHMaAPavMGsUiLMlacyTvB7B1ZldnzAaZ6/4YlqaBRPt+zFcRk714
 t2ciDbjvCblFyxZBTIhhFHOTj2zUusCymuP9UVgdCN7oOM/+sd9dmgg/kHl29pONtAiKANf/FuF
 BQXl6JAo1xnhvl4L/eKjZM8kkByA2qGJ7NEoW8TMq9suF16s5GJ64mwEJVgKg8wld3QN9DrAk6+
 a5d34SRNXnxOHQiV6Kp92AUcILXELkiHWJaqqvq4HP18xsAX
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

devm_of_qcom_ice_get() currently returns NULL if ICE SCM is not available or
"qcom,ice" property is not found in DT. But this confuses the clients since
NULL doesn't convey the reason for failure. So return proper error codes
instead of NULL.

Reported-by: Sumit Garg <sumit.garg@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/soc/qcom/ice.c | 9 ++++-----
 1 file changed, 4 insertions(+), 5 deletions(-)

diff --git a/drivers/soc/qcom/ice.c b/drivers/soc/qcom/ice.c
index 8e25609c7e7b..498cb0e0d1e4 100644
--- a/drivers/soc/qcom/ice.c
+++ b/drivers/soc/qcom/ice.c
@@ -563,7 +563,7 @@ static struct qcom_ice *qcom_ice_create(struct device *dev,
 
 	if (!qcom_scm_ice_available()) {
 		dev_warn(dev, "ICE SCM interface not found\n");
-		return NULL;
+		return ERR_PTR(-EOPNOTSUPP);
 	}
 
 	engine = devm_kzalloc(dev, sizeof(*engine), GFP_KERNEL);
@@ -641,7 +641,7 @@ static struct qcom_ice *of_qcom_ice_get(struct device *dev)
 	struct device_node *node __free(device_node) = of_parse_phandle(dev->of_node,
 									"qcom,ice", 0);
 	if (!node)
-		return NULL;
+		return ERR_PTR(-ENODEV);
 
 	pdev = of_find_device_by_node(node);
 	if (!pdev) {
@@ -697,8 +697,7 @@ static void devm_of_qcom_ice_put(struct device *dev, void *res)
  * Devres automatically decrements the refcount when consumer device gets
  * destroyed and frees the ICE instance when the last consumer goes away.
  *
- * Return: ICE pointer on success, NULL if there is no ICE data provided by the
- * consumer or ERR_PTR() on error.
+ * Return: ICE pointer on success, ERR_PTR() on error.
  */
 struct qcom_ice *devm_of_qcom_ice_get(struct device *dev)
 {
@@ -709,7 +708,7 @@ struct qcom_ice *devm_of_qcom_ice_get(struct device *dev)
 		return ERR_PTR(-ENOMEM);
 
 	ice = of_qcom_ice_get(dev);
-	if (!IS_ERR_OR_NULL(ice)) {
+	if (!IS_ERR(ice)) {
 		*dr = ice;
 		devres_add(dev, dr);
 	} else {

-- 
2.51.0

