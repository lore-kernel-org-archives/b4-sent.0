From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 19 May 2026 14:26:00 +0530
Subject: [PATCH v3 5/9] power: sequencing: pcie-m2: Create BT node based on
 the pci_device_id[] table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-pwrseq-m2-bt-v3-5-b39dc2ae3966@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3201;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=rTMeZkV9x+HZuDVq+MMnQQueGW/iEF0ofpOAzeBSnvQ=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqDCWfn7HtNXJrb9ARsUTEL+69+rwmsb1554kQY
 ggoLyUZ90OJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagwlnwAKCRBVnxHm/pHO
 9XquB/wNvNaup7XxZTrnkoUfyGihGKPtpQ4X7gpjzt5jC0ATBqePcpqxbt+8nSAbcTtXJSwdLph
 s5Alt8uZewQ6lsoIcQ0BFTqrKAUxFnWqMBLk03DxgSxx2qLjeF4XaTCAXyfppNxHHrU1BVvpYt/
 gwkk4m7rExaI/BQg49Z8hJrJrS/0QjtT8GQDxVOHG6OfS/vt8rE05cJh7tmeVYwNfqz06v4YHuZ
 r2PaLvc4I/sLTp6sXjhA+di1lQunHDLI9ToMJuaE83S5wxzurx1l6jS3eeusjdq+CN4MBKO7zz2
 LTM06x3R+jZ/ULX4iFpMd/Fphw2K3xPMGniQch1DwBNdrpQL
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, pwrseq_pcie_m2_create_bt_node() hardcodes the BT compatible for
creating the devicetree node. But to allow adding support for more devices
in the future, create the BT node based on the pci_device_id[] table. The
BT compatible is passed using 'driver_data'.

Co-developed-by: Wei Deng <wei.deng@oss.qualcomm.com>
Signed-off-by: Wei Deng <wei.deng@oss.qualcomm.com>
Tested-by: Wei Deng <wei.deng@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/power/sequencing/pwrseq-pcie-m2.c | 29 ++++++++++++++++++++---------
 1 file changed, 20 insertions(+), 9 deletions(-)

diff --git a/drivers/power/sequencing/pwrseq-pcie-m2.c b/drivers/power/sequencing/pwrseq-pcie-m2.c
index 8164c4428977..e82821655fc4 100644
--- a/drivers/power/sequencing/pwrseq-pcie-m2.c
+++ b/drivers/power/sequencing/pwrseq-pcie-m2.c
@@ -185,14 +185,29 @@ static int pwrseq_pcie_m2_match(struct pwrseq_device *pwrseq,
 	return PWRSEQ_NO_MATCH;
 }
 
+static const struct pci_device_id pwrseq_m2_pci_ids[] = {
+	{ PCI_DEVICE(PCI_VENDOR_ID_QCOM, 0x1107),
+	  .driver_data = (kernel_ulong_t)"qcom,wcn7850-bt" },
+	{ } /* Sentinel */
+};
+
 static int pwrseq_pcie_m2_create_bt_node(struct pwrseq_pcie_m2_ctx *ctx,
 					struct pwrseq_pci_dev *pci_dev,
-					struct device_node *parent)
+					struct device_node *parent,
+					struct pci_dev *pdev)
 {
+	const struct pci_device_id *id;
 	struct device *dev = ctx->dev;
+	const char *compatible;
 	struct device_node *np;
 	int ret;
 
+	id = pci_match_id(pwrseq_m2_pci_ids, pdev);
+	if (WARN_ON_ONCE(!id)) /* Shouldn't happen */
+		return -ENODEV;
+
+	compatible = (const char *)id->driver_data;
+
 	pci_dev->ocs = kzalloc_obj(*pci_dev->ocs);
 	if (!pci_dev->ocs)
 		return -ENOMEM;
@@ -206,7 +221,7 @@ static int pwrseq_pcie_m2_create_bt_node(struct pwrseq_pcie_m2_ctx *ctx,
 		goto err_destroy_changeset;
 	}
 
-	ret = of_changeset_add_prop_string(pci_dev->ocs, np, "compatible", "qcom,wcn7850-bt");
+	ret = of_changeset_add_prop_string(pci_dev->ocs, np, "compatible", compatible);
 	if (ret) {
 		dev_err(dev, "Failed to add bluetooth compatible: %d\n", ret);
 		goto err_destroy_changeset;
@@ -279,13 +294,14 @@ static int pwrseq_pcie_m2_create_serdev_one(struct pwrseq_pcie_m2_ctx *ctx,
 		goto err_free_pci_dev;
 	}
 
-	ret = pwrseq_pcie_m2_create_bt_node(ctx, pci_dev, serdev_parent);
+	ret = pwrseq_pcie_m2_create_bt_node(ctx, pci_dev, serdev_parent, pdev);
 	if (ret)
 		goto err_free_serdev;
 
 	ret = serdev_device_add(pci_dev->serdev);
 	if (ret) {
-		dev_err(dev, "Failed to add serdev for WCN7850: %d\n", ret);
+		dev_err(dev, "Failed to add serdev for PCI device (%s): %d\n",
+			pci_name(pdev), ret);
 		goto err_free_dt_node;
 	}
 
@@ -351,11 +367,6 @@ static void pwrseq_pcie_m2_remove_serdev(struct pwrseq_pcie_m2_ctx *ctx,
 	mutex_unlock(&ctx->list_lock);
 }
 
-static const struct pci_device_id pwrseq_m2_pci_ids[] = {
-	{ PCI_DEVICE(PCI_VENDOR_ID_QCOM, 0x1107) },
-	{ } /* Sentinel */
-};
-
 static int pwrseq_pcie_m2_notify(struct notifier_block *nb, unsigned long action,
 			      void *data)
 {

-- 
2.48.1

