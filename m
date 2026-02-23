From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 23 Feb 2026 13:32:55 +0530
Subject: [PATCH v3 4/4] scsi: ufs: ufs-qcom: Remove NULL check from
 devm_of_qcom_ice_get()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260223-qcom-ice-fix-v3-4-6ca5846329f7@oss.qualcomm.com>
References: <20260223-qcom-ice-fix-v3-0-6ca5846329f7@oss.qualcomm.com>
In-Reply-To: <20260223-qcom-ice-fix-v3-0-6ca5846329f7@oss.qualcomm.com>
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
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1049;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=K/orRBPrLSqNof1kmCJZCxhyo4EZ9ZRQZsR0+L1qTcE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpnAmuHMzsxDUfHs8N8ALR6oEJYQWQDnXUzVb+x
 zHhvm8YvUmJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaZwJrgAKCRBVnxHm/pHO
 9Qm9B/42Y0R3B2B04OH3iyfnwU3rtYgU6nNwsu6w+5x6t+fNt/IKcWtD6iXPwODYDWjL2KnpDmO
 7skmS+bhB/7EM89m6PruPxJcfEz11yVUNEB0F9qrt2LPy7t5s1XwHtA93iW+oqec12FipeKc6w7
 K96F8U4xCjhe/m9yRXslRG1I0iMYEa3/lkrjAP3QDZ0qSOscgPsiaEz1MlJiGL5IQJQ+7EputCP
 KMmKUV9IieOB1YMuZGPYi56cyee/P6aBWsMhoVNa6TPO8nQtIUr5pn/0biOI5TPJ8fHBr6lz5io
 GOYdiKQvJoLx6CtfEoIG408HnRx4ig+QxRaTmLuoxo6OQZTH
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now since the devm_of_qcom_ice_get() API never returns NULL, remove the
NULL check and also simplify the error handling.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/ufs/host/ufs-qcom.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/ufs/host/ufs-qcom.c b/drivers/ufs/host/ufs-qcom.c
index 375fd24ba458..72c24ed65fe1 100644
--- a/drivers/ufs/host/ufs-qcom.c
+++ b/drivers/ufs/host/ufs-qcom.c
@@ -177,14 +177,14 @@ static int ufs_qcom_ice_init(struct ufs_qcom_host *host)
 	int i;
 
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
 	host->ice = ice;
 
 	/* Initialize the blk_crypto_profile */

-- 
2.51.0

