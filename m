From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 18 May 2026 19:22:19 +0530
Subject: [PATCH v7 3/5] soc: qcom: ice: Return proper error codes from
 devm_of_qcom_ice_get() instead of NULL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260518-qcom-ice-fix-v7-3-2a595382185b@oss.qualcomm.com>
References: <20260518-qcom-ice-fix-v7-0-2a595382185b@oss.qualcomm.com>
In-Reply-To: <20260518-qcom-ice-fix-v7-0-2a595382185b@oss.qualcomm.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Adrian Hunter <adrian.hunter@intel.com>, Ulf Hansson <ulfh@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mmc@vger.kernel.org, linux-scsi@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Sumit Garg <sumit.garg@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2164;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=zyGMoxK7AI1IRPc+etIM4UZGk/SADTv+9T9KAHweBVw=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqCxmahrJ+jerq1LRrZ6VYZmvgG5UhnEKv/cXI2
 yZosNGSuiaJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagsZmgAKCRBVnxHm/pHO
 9Z0tB/9plQvFEspGFOSg6Irs68JKzkrKJarNsxOt7OfJEuJZdma3kKqbKgAJpoT0/tgiYGPmvfv
 R6SBenoiC7quwaWVHJtXl7RlPabgRSicuKjzNhX1xprtVU9bnE4u2+/tXfo/6r6KckfOYPbK3Qn
 F/Hf94gisRXwAOeuXUV4ZidhoXWKeIfxTd2PhrLdxGp3DXvRro3gvWgKht2nfvfbxrI8cYiM12y
 0eKvv+vEbsj6h0nzq0nHEFlqQ+Yhx3m+Xsglh99H8OYxuEzb6tKCqUu6Uo79n5OsuyabKQgouFb
 uLtUGyaMVWGb+ScY7q+RuAIbV/N1+Ls7oYUDQZrP9+L23oYm
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
Tested-by: Sumit Garg <sumit.garg@oss.qualcomm.com> # OP-TEE as TZ
Acked-by: Sumit Garg <sumit.garg@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/soc/qcom/ice.c | 9 ++++-----
 1 file changed, 4 insertions(+), 5 deletions(-)

diff --git a/drivers/soc/qcom/ice.c b/drivers/soc/qcom/ice.c
index 85deb9ea4a68..2b592aa42941 100644
--- a/drivers/soc/qcom/ice.c
+++ b/drivers/soc/qcom/ice.c
@@ -563,7 +563,7 @@ static struct qcom_ice *qcom_ice_create(struct device *dev,
 
 	if (!qcom_scm_ice_available()) {
 		dev_warn(dev, "ICE SCM interface not found\n");
-		return NULL;
+		return ERR_PTR(-EOPNOTSUPP);
 	}
 
 	engine = devm_kzalloc(dev, sizeof(*engine), GFP_KERNEL);
@@ -645,7 +645,7 @@ static struct qcom_ice *of_qcom_ice_get(struct device *dev)
 	struct device_node *node __free(device_node) = of_parse_phandle(dev->of_node,
 									"qcom,ice", 0);
 	if (!node)
-		return NULL;
+		return ERR_PTR(-ENODEV);
 
 	pdev = of_find_device_by_node(node);
 	if (!pdev) {
@@ -698,8 +698,7 @@ static void devm_of_qcom_ice_put(struct device *dev, void *res)
  * phandle via 'qcom,ice' property to an ICE DT, the ICE instance will already
  * be created and so this function will return that instead.
  *
- * Return: ICE pointer on success, NULL if there is no ICE data provided by the
- * consumer or ERR_PTR() on error.
+ * Return: ICE pointer on success, ERR_PTR() on error.
  */
 struct qcom_ice *devm_of_qcom_ice_get(struct device *dev)
 {
@@ -710,7 +709,7 @@ struct qcom_ice *devm_of_qcom_ice_get(struct device *dev)
 		return ERR_PTR(-ENOMEM);
 
 	ice = of_qcom_ice_get(dev);
-	if (!IS_ERR_OR_NULL(ice)) {
+	if (!IS_ERR(ice)) {
 		*dr = ice;
 		devres_add(dev, dr);
 	} else {

-- 
2.48.1

