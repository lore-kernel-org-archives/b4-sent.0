From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 19 May 2026 14:25:56 +0530
Subject: [PATCH v3 1/9] power: sequencing: pcie-m2: Fix inconsistent
 function prefixes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-pwrseq-m2-bt-v3-1-b39dc2ae3966@oss.qualcomm.com>
References: <20260519-pwrseq-m2-bt-v3-0-b39dc2ae3966@oss.qualcomm.com>
In-Reply-To: <20260519-pwrseq-m2-bt-v3-0-b39dc2ae3966@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-pci@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-bluetooth@vger.kernel.org, Wei Deng <wei.deng@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2082;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=OzSOLSJTM2+lHbh50xUinPK/5SSZvR5hJw0X+Sc++Us=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqDCWdWD0JU00zP67qaszIZN42Iep5F+fvGO6XT
 cdm4VJ7Ge2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagwlnQAKCRBVnxHm/pHO
 9cezCACnXoJ/9spLcDtcdWp966CMw/XJM1luSmhRbMKjaiiZiAjXTi9Go3i2gCmHzI0Hb70Wo5j
 tYbSLlXPN5HFozEDa50H/qmMqlcrK8QcKaFTSUmx7WtRIgjwH58ev+UqTk4LssB1vRlpSlHectu
 aEtRlBKRRjarGMymg0o039C5dsvc8UXEZPLYxfKLCIR/JdgZxXi/jv1p8lvjf4LQsolcZRmqtTd
 3BALu5S9xP7xppdeBIs3Us6pJTFJAwgK9vW3qYATBto+BOO+wXnCMOGRM+j/CgUBZFXa3qlfomN
 kykXs/xKsQssVwXadmbya9Tv08wBgp7xPa9OLA2ah+VhN/So
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All functions in this driver follow 'pwrseq_pcie_m2' prefix except a few.
Fix them to avoid inconsistency.

Tested-by: Wei Deng <wei.deng@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/power/sequencing/pwrseq-pcie-m2.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/power/sequencing/pwrseq-pcie-m2.c b/drivers/power/sequencing/pwrseq-pcie-m2.c
index ef69ae268059..b2ed336fd5ad 100644
--- a/drivers/power/sequencing/pwrseq-pcie-m2.c
+++ b/drivers/power/sequencing/pwrseq-pcie-m2.c
@@ -177,7 +177,7 @@ static int pwrseq_pcie_m2_match(struct pwrseq_device *pwrseq,
 	return PWRSEQ_NO_MATCH;
 }
 
-static int pwrseq_m2_pcie_create_bt_node(struct pwrseq_pcie_m2_ctx *ctx,
+static int pwrseq_pcie_m2_create_bt_node(struct pwrseq_pcie_m2_ctx *ctx,
 					struct device_node *parent)
 {
 	struct device *dev = ctx->dev;
@@ -254,7 +254,7 @@ static int pwrseq_pcie_m2_create_serdev(struct pwrseq_pcie_m2_ctx *ctx)
 		goto err_put_ctrl;
 	}
 
-	ret = pwrseq_m2_pcie_create_bt_node(ctx, serdev_parent);
+	ret = pwrseq_pcie_m2_create_bt_node(ctx, serdev_parent);
 	if (ret)
 		goto err_free_serdev;
 
@@ -299,7 +299,7 @@ static void pwrseq_pcie_m2_remove_serdev(struct pwrseq_pcie_m2_ctx *ctx)
 	}
 }
 
-static int pwrseq_m2_pcie_notify(struct notifier_block *nb, unsigned long action,
+static int pwrseq_pcie_m2_notify(struct notifier_block *nb, unsigned long action,
 			      void *data)
 {
 	struct pwrseq_pcie_m2_ctx *ctx = container_of(nb, struct pwrseq_pcie_m2_ctx, nb);
@@ -364,7 +364,7 @@ static int pwrseq_pcie_m2_register_notifier(struct pwrseq_pcie_m2_ctx *ctx, stru
 	if (pwrseq_pcie_m2_check_remote_node(dev, 3, 0, "serial")) {
 		if (pwrseq_pcie_m2_check_remote_node(dev, 0, 0, "pcie")) {
 			ctx->dev = dev;
-			ctx->nb.notifier_call = pwrseq_m2_pcie_notify;
+			ctx->nb.notifier_call = pwrseq_pcie_m2_notify;
 			ret = bus_register_notifier(&pci_bus_type, &ctx->nb);
 			if (ret)
 				return dev_err_probe(dev, ret,

-- 
2.48.1

