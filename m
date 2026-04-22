From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 22 Apr 2026 16:54:45 +0530
Subject: [PATCH 04/12] power: sequencing: pcie-m2: Fix inconsistent
 function prefixes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-pwrseq-m2-bt-v1-4-720d02545a64@oss.qualcomm.com>
References: <20260422-pwrseq-m2-bt-v1-0-720d02545a64@oss.qualcomm.com>
In-Reply-To: <20260422-pwrseq-m2-bt-v1-0-720d02545a64@oss.qualcomm.com>
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Shuai Zhang <quic_shuaz@quicinc.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-bluetooth@vger.kernel.org, Wei Deng <wei.deng@oss.qualcomm.com>, 
 Luiz Augusto von Dentz <luiz.von.dentz@intel.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2033;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=LWnLixKrQibhExb1i5PgPATDR3O5JAuvbsbZ6mK36Y0=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBp6LAV/F3/E3MFsCt+z73n6IYm6bHQcgOZG2VRM
 CxU6IxmeSCJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaeiwFQAKCRBVnxHm/pHO
 9c+EB/9BLUydP/0XPcughRS5adJ+af8FQiEMYmytsxappZ2jIRxbkBmaT82LwuU/Q320mvHGQrJ
 jiHgYOtNU/xdlRIsKQwgJRrb8DTDC167WE7lA6/x0JHQh+bBLTYTzqNMeoAD4SG9uptegH1DhUM
 /4DAZpj2bWt6kBgbe8XB2QAIx7c9ZjTbP1HS8oNRDM1nt9M2pFpGsAt49eLzdhbRjFtBvkI2TEu
 vNyOUx3jlrJ0ypPCqHNwGG6BBdsiLNpJrHwX6fUURFEDX340NTUF5oX73AfVsfNGiRpa1VUD6a9
 WwRHQtkyUe/kFnf7UtzGwgXzvy83NwpMZWmILCO+s4FK8gZU
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All functions in this driver follow 'pwrseq_pcie_m2' prefix except a few.
Fix them to avoid inconsistency.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/power/sequencing/pwrseq-pcie-m2.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/power/sequencing/pwrseq-pcie-m2.c b/drivers/power/sequencing/pwrseq-pcie-m2.c
index 2b79f2e34079..49c326a6e445 100644
--- a/drivers/power/sequencing/pwrseq-pcie-m2.c
+++ b/drivers/power/sequencing/pwrseq-pcie-m2.c
@@ -185,7 +185,7 @@ static int pwrseq_pcie_m2_match(struct pwrseq_device *pwrseq,
 	return PWRSEQ_NO_MATCH;
 }
 
-static int pwrseq_m2_pcie_create_bt_node(struct pwrseq_pcie_m2_ctx *ctx,
+static int pwrseq_pcie_m2_create_bt_node(struct pwrseq_pcie_m2_ctx *ctx,
 					struct device_node *parent)
 {
 	struct device *dev = ctx->dev;
@@ -262,7 +262,7 @@ static int pwrseq_pcie_m2_create_serdev(struct pwrseq_pcie_m2_ctx *ctx)
 		goto err_put_ctrl;
 	}
 
-	ret = pwrseq_m2_pcie_create_bt_node(ctx, serdev_parent);
+	ret = pwrseq_pcie_m2_create_bt_node(ctx, serdev_parent);
 	if (ret)
 		goto err_free_serdev;
 
@@ -307,7 +307,7 @@ static void pwrseq_pcie_m2_remove_serdev(struct pwrseq_pcie_m2_ctx *ctx)
 	}
 }
 
-static int pwrseq_m2_pcie_notify(struct notifier_block *nb, unsigned long action,
+static int pwrseq_pcie_m2_notify(struct notifier_block *nb, unsigned long action,
 			      void *data)
 {
 	struct pwrseq_pcie_m2_ctx *ctx = container_of(nb, struct pwrseq_pcie_m2_ctx, nb);
@@ -372,7 +372,7 @@ static int pwrseq_pcie_m2_register_notifier(struct pwrseq_pcie_m2_ctx *ctx, stru
 	if (pwrseq_pcie_m2_check_remote_node(dev, 3, 0, "serial")) {
 		if (pwrseq_pcie_m2_check_remote_node(dev, 0, 0, "pcie")) {
 			ctx->dev = dev;
-			ctx->nb.notifier_call = pwrseq_m2_pcie_notify;
+			ctx->nb.notifier_call = pwrseq_pcie_m2_notify;
 			ret = bus_register_notifier(&pci_bus_type, &ctx->nb);
 			if (ret)
 				return dev_err_probe(dev, ret,

-- 
2.51.0

