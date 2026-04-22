From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 22 Apr 2026 16:54:48 +0530
Subject: [PATCH 07/12] power: sequencing: pcie-m2: Create serdev for PCI
 devices present before probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-pwrseq-m2-bt-v1-7-720d02545a64@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=5701;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=KxccIL0wAbXZIjNEfSWb+27f0NvPCoI50tHq4aONrQs=;
 b=owEBbAGT/pANAwAKAVWfEeb+kc71AcsmYgBp6LAVbba+rmaoWNsPlB2IV19Sjs+xxhqc3+Nvv
 4wQMp8j32WJATIEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaeiwFQAKCRBVnxHm/pHO
 9ceQB/jmXhyv+IU0xoV41g0QAsVGsLDcguP0JPoHg+6zANCkUnyxVDC01ECWG1sT87CqbkQatNP
 A6tZzfebquQ7lY7QHu4bR0eHU1iIwjF8vlclN5B6HtumHDOlknbEE3lj/ATuJ/rWp0LQOMPSYgW
 nrBNYVDccO3t8vCM+LWe0mrnf2ae6qUa5jqS3nfOngknN7CWu3mL5+B/XaDT6iV9cMjedVZxGQo
 KVZvn4FzlJW0iEuxDRAiQjljVBl0jwctqdhsrvSINq+h68jOKbEz/n5R5gMc0wqNeUCeT97WW7J
 /PACoCeSEslXf+JX6FtULcPrP0SxSsWDW4gKdA4oXOO47QE=
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

So far, the driver is registering a notifier to create serdev for the PCI
devices that are going to be attached after probe. But it doesn't handle
the devices present before probe. Due to this, serdev is not getting
created for those existing devices.

Hence, create serdev for PCI devices available before probe as well.

Note that the serdev for available devices are created before
registering the notifier. There is a small window where a device could
appear after pwrseq_pcie_m2_create_serdev(), before notifier registration.
But since M.2 cards are fixed to a slot, they are mostly added either
before booting the host or after using hotplug. So this window is mostly
theoretical.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/power/sequencing/pwrseq-pcie-m2.c | 83 ++++++++++++++++++++++++++-----
 1 file changed, 70 insertions(+), 13 deletions(-)

diff --git a/drivers/power/sequencing/pwrseq-pcie-m2.c b/drivers/power/sequencing/pwrseq-pcie-m2.c
index bdc4391c87c9..b21fcc089580 100644
--- a/drivers/power/sequencing/pwrseq-pcie-m2.c
+++ b/drivers/power/sequencing/pwrseq-pcie-m2.c
@@ -244,7 +244,7 @@ static int pwrseq_pcie_m2_create_bt_node(struct pwrseq_pcie_m2_ctx *ctx,
 	return ret;
 }
 
-static int pwrseq_pcie_m2_create_serdev(struct pwrseq_pcie_m2_ctx *ctx,
+static int __pwrseq_pcie_m2_create_serdev(struct pwrseq_pcie_m2_ctx *ctx,
 					struct pci_dev *pdev)
 {
 	struct serdev_controller *serdev_ctrl;
@@ -267,6 +267,16 @@ static int pwrseq_pcie_m2_create_serdev(struct pwrseq_pcie_m2_ctx *ctx,
 		return 0;
 	}
 
+	/* Bail out if the serdev device was already created for the PCI dev */
+	mutex_lock(&ctx->list_lock);
+	list_for_each_entry(pci_dev, &ctx->pci_devices, list) {
+		if (pci_dev->pdev == pdev) {
+			mutex_unlock(&ctx->list_lock);
+			return 0;
+		}
+	}
+	mutex_unlock(&ctx->list_lock);
+
 	pci_dev = kzalloc(sizeof(*pci_dev), GFP_KERNEL);
 	if (!pci_dev) {
 		ret = -ENOMEM;
@@ -376,7 +386,7 @@ static int pwrseq_pcie_m2_notify(struct notifier_block *nb, unsigned long action
 	switch (action) {
 	case BUS_NOTIFY_ADD_DEVICE:
 		if (pci_match_id(pwrseq_m2_pci_ids, pdev)) {
-			ret = pwrseq_pcie_m2_create_serdev(ctx, pdev);
+			ret = __pwrseq_pcie_m2_create_serdev(ctx, pdev);
 			if (ret)
 				return notifier_from_errno(ret);
 		}
@@ -408,7 +418,7 @@ static bool pwrseq_pcie_m2_check_remote_node(struct device *dev, u8 port, u8 end
  * protocol device needs to be created manually with the help of the notifier
  * of the discoverable bus like PCIe.
  */
-static int pwrseq_pcie_m2_register_notifier(struct pwrseq_pcie_m2_ctx *ctx, struct device *dev)
+static int pwrseq_pcie_m2_register_notifier(struct pwrseq_pcie_m2_ctx *ctx)
 {
 	int ret;
 
@@ -416,18 +426,56 @@ static int pwrseq_pcie_m2_register_notifier(struct pwrseq_pcie_m2_ctx *ctx, stru
 	 * Register a PCI notifier for Key E connector that has PCIe as Port
 	 * 0/Endpoint 0 interface and Serial as Port 3/Endpoint 0 interface.
 	 */
-	if (pwrseq_pcie_m2_check_remote_node(dev, 3, 0, "serial")) {
-		if (pwrseq_pcie_m2_check_remote_node(dev, 0, 0, "pcie")) {
-			ctx->dev = dev;
-			ctx->nb.notifier_call = pwrseq_pcie_m2_notify;
-			ret = bus_register_notifier(&pci_bus_type, &ctx->nb);
-			if (ret)
-				return dev_err_probe(dev, ret,
-						     "Failed to register notifier for serdev\n");
+	if (!pwrseq_pcie_m2_check_remote_node(ctx->dev, 3, 0, "serial") ||
+	    !pwrseq_pcie_m2_check_remote_node(ctx->dev, 0, 0, "pcie"))
+		return 0;
+
+	ctx->nb.notifier_call = pwrseq_pcie_m2_notify;
+	ret = bus_register_notifier(&pci_bus_type, &ctx->nb);
+	if (ret)
+		return dev_err_probe(ctx->dev, ret,
+				     "Failed to register notifier for serdev\n");
+	return 0;
+}
+
+static int pwrseq_pcie_m2_create_serdev(struct pwrseq_pcie_m2_ctx *ctx)
+{
+	struct pci_dev *pdev = NULL;
+	int ret;
+
+	if (!pwrseq_pcie_m2_check_remote_node(ctx->dev, 3, 0, "serial") ||
+	    !pwrseq_pcie_m2_check_remote_node(ctx->dev, 0, 0, "pcie"))
+		return 0;
+
+	struct device_node *pci_parent __free(device_node) =
+				of_graph_get_remote_node(dev_of_node(ctx->dev), 0, 0);
+	if (!pci_parent)
+		return 0;
+
+	/* Create serdev for existing PCI devices if required */
+	for_each_pci_dev(pdev) {
+		if (!pdev->dev.parent || pci_parent != pdev->dev.parent->of_node)
+			continue;
+
+		if (!pci_match_id(pwrseq_m2_pci_ids, pdev))
+			continue;
+
+		ret = __pwrseq_pcie_m2_create_serdev(ctx, pdev);
+		if (ret) {
+			dev_err_probe(ctx->dev, ret,
+				      "Failed to create serdev for PCI device (%s)\n",
+				      pci_name(pdev));
+			pci_dev_put(pdev);
+			goto err_remove_serdev;
 		}
 	}
 
 	return 0;
+
+err_remove_serdev:
+	pwrseq_pcie_m2_remove_serdev(ctx, NULL);
+
+	return ret;
 }
 
 static int pwrseq_pcie_m2_probe(struct platform_device *pdev)
@@ -489,16 +537,25 @@ static int pwrseq_pcie_m2_probe(struct platform_device *pdev)
 
 	mutex_init(&ctx->list_lock);
 	INIT_LIST_HEAD(&ctx->pci_devices);
+	ctx->dev = dev;
+
+	/* Create serdev for available PCI devices (if required) */
+	ret = pwrseq_pcie_m2_create_serdev(ctx);
+	if (ret)
+		goto err_destroy_mutex;
+
 	/*
 	 * Register a notifier for creating protocol devices for
 	 * non-discoverable busses like UART.
 	 */
-	ret = pwrseq_pcie_m2_register_notifier(ctx, dev);
+	ret = pwrseq_pcie_m2_register_notifier(ctx);
 	if (ret)
-		goto err_destroy_mutex;
+		goto err_remove_serdev;
 
 	return 0;
 
+err_remove_serdev:
+	pwrseq_pcie_m2_remove_serdev(ctx, NULL);
 err_destroy_mutex:
 	mutex_destroy(&ctx->list_lock);
 err_free_regulators:

-- 
2.51.0

