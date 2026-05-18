From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 18 May 2026 19:22:20 +0530
Subject: [PATCH v7 4/5] mmc: sdhci-msm: Remove NULL check from
 devm_of_qcom_ice_get()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260518-qcom-ice-fix-v7-4-2a595382185b@oss.qualcomm.com>
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
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Sumit Garg <sumit.garg@oss.qualcomm.com>, Ulf Hansson <ulfh@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1289;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=2TEgOkyvd4r+l0mpS0t2N7pBLvSeAP7e2d285TUvAGA=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqCxmbFl8JMCvWeUZA1bBL9JGP6YVKVE51lNsQa
 GrjY5i58+mJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagsZmwAKCRBVnxHm/pHO
 9bYBB/9xnakQ59nUEsBic128rGADmZ+LrKM3pZgMf6CzAY6cRrFIwHtekZF9BC2bLPqGq8bFQe7
 n9/ts8THbKKmZYuNlp/P+6+T47WnvgwvXAQyUw52jKAxb5VhdVSkQ7eUPhGMR7ZgrINp8xUe0OH
 m9FJwCWV8g2iSYKcRF9a3XCPiny/AMo2zBL1UKSMT34ikC6XsAxhyE6WY2nEErte+QoK8rtWDBc
 1ygGoRDiJonOv/td7yJ5h7H9PPJkrpUPMVS86r+idNJGRAfqzmgXH5nr8xzMUpsWvUIh7FxL00i
 X/ekjsKCSK2hzuu6lwgUn5xzhwlt6TNFW5ZzNxmOn76K6wYn
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now since the devm_of_qcom_ice_get() API never returns NULL, remove the
NULL check and also simplify the error handling.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Acked-by: Ulf Hansson <ulf.hansson@linaro.org>
Acked-by: Adrian Hunter <adrian.hunter@intel.com>
Tested-by: Sumit Garg <sumit.garg@oss.qualcomm.com> # OP-TEE as TZ
Acked-by: Sumit Garg <sumit.garg@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/mmc/host/sdhci-msm.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/mmc/host/sdhci-msm.c b/drivers/mmc/host/sdhci-msm.c
index 633462c0be5f..0882ce74e0c9 100644
--- a/drivers/mmc/host/sdhci-msm.c
+++ b/drivers/mmc/host/sdhci-msm.c
@@ -1918,14 +1918,14 @@ static int sdhci_msm_ice_init(struct sdhci_msm_host *msm_host,
 		return 0;
 
 	ice = devm_of_qcom_ice_get(dev);
-	if (ice == ERR_PTR(-EOPNOTSUPP)) {
+	if (IS_ERR(ice)) {
+		if (ice != ERR_PTR(-EOPNOTSUPP))
+			return PTR_ERR(ice);
+
 		dev_warn(dev, "Disabling inline encryption support\n");
-		ice = NULL;
+		return 0;
 	}
 
-	if (IS_ERR_OR_NULL(ice))
-		return PTR_ERR_OR_ZERO(ice);
-
 	msm_host->ice = ice;
 
 	/* Initialize the blk_crypto_profile */

-- 
2.48.1

