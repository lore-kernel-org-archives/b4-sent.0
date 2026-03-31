From: Pawel Laszczak <pawell@cadence.com>
Date: Tue, 31 Mar 2026 10:19:11 +0200
Subject: [PATCH] usb: cdnsp: Add support for device-only configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260331-device_only-v1-1-00378b80365c@cadence.com>
X-B4-Tracking: v=1; b=H4sIAH6Dy2kC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDY2ND3RSgouTU+Py8nEpdQ0ujFFNjSxNjgyRTJaCOgqLUtMwKsGnRsbW
 1APSz3sJdAAAA
To: Peter Chen <peter.chen@kernel.org>, Roger Quadros <rogerq@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, pawell@cadence.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774945165; l=10845;
 i=pawell@cadence.com; h=from:subject:message-id;
 bh=6OIqgxMFmEPIY1lz/0pWr94nNNQg9qsP83S9iKkdml4=;
 b=8R1w9k86i+MQEe4egtg5LnSARTaFCOOp61gbJ9RI8d9XrRsdnLCiD5tODDOFppJOfxsFkr/OC
 hIy6gF7zdCQBM3Z9P1d1h1yhRoXys4k3MpQglaU8kiFRfJw6AsyS/wq
X-Developer-Key: i=pawell@cadence.com; a=ed25519;
 pk=EUPBvLO9CDg7j6defeDl2iqi+z5Ivqu4Z46aiqe7dYc=
X-Endpoint-Received: by B4 Relay for pawell@cadence.com/default with auth_id=707
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch introduces support for operating the Cadence USBSSP (cdnsp)
controller in a peripheral-only mode, bypassing the Dual-Role Device (DRD)
logic.

The change in BAR indexing (from BAR 2 to BAR 1) is a direct
consequence of switching from 64-bit to 32-bit addressing in the
Peripheral-only configuration.

Tested on PCI platform with Device-only configuration. Platform-side
changes are included to support the PCI glue layer's property injection.

Signed-off-by: Pawel Laszczak <pawell@cadence.com>
---
NOTE: This patch depends on Peter Chen's series "usb: cdns3: Add 
USBSSP platform driver support", which was recently accepted by 
Greg into the usb-testing branch (commit 6076388ca1ed).
---
 drivers/usb/cdns3/cdns3-plat.c | 24 ++++++++++++---------
 drivers/usb/cdns3/cdnsp-pci.c  | 47 ++++++++++++++++++++++++++++++++++--------
 drivers/usb/cdns3/core.c       |  3 ++-
 drivers/usb/cdns3/core.h       |  5 ++++-
 drivers/usb/cdns3/drd.c        | 16 ++++++++++++--
 include/linux/pci_ids.h        |  1 +
 6 files changed, 73 insertions(+), 23 deletions(-)

diff --git a/drivers/usb/cdns3/cdns3-plat.c b/drivers/usb/cdns3/cdns3-plat.c
index 71c612e27b73..33746e672cda 100644
--- a/drivers/usb/cdns3/cdns3-plat.c
+++ b/drivers/usb/cdns3/cdns3-plat.c
@@ -75,6 +75,7 @@ static int cdns3_plat_probe(struct platform_device *pdev)
 	if (cdns->pdata && cdns->pdata->override_apb_timeout)
 		cdns->override_apb_timeout = cdns->pdata->override_apb_timeout;
 
+	cdns->no_drd = device_property_read_bool(dev, "no_drd");
 	platform_set_drvdata(pdev, cdns);
 
 	ret = platform_get_irq_byname(pdev, "host");
@@ -107,21 +108,23 @@ static int cdns3_plat_probe(struct platform_device *pdev)
 
 	cdns->dev_regs	= regs;
 
-	cdns->otg_irq = platform_get_irq_byname(pdev, "otg");
-	if (cdns->otg_irq < 0)
-		return dev_err_probe(dev, cdns->otg_irq,
-				     "Failed to get otg IRQ\n");
+	if (!cdns->no_drd) {
+		cdns->otg_irq = platform_get_irq_byname(pdev, "otg");
+		if (cdns->otg_irq < 0)
+			return dev_err_probe(dev, cdns->otg_irq,
+					     "Failed to get otg IRQ\n");
 
-	res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "otg");
-	if (!res) {
-		dev_err(dev, "couldn't get otg resource\n");
-		return -ENXIO;
+		res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "otg");
+		if (!res) {
+			dev_err(dev, "couldn't get otg resource\n");
+			return -ENXIO;
+		}
+
+		cdns->otg_res = *res;
 	}
 
 	cdns->phyrst_a_enable = device_property_read_bool(dev, "cdns,phyrst-a-enable");
 
-	cdns->otg_res = *res;
-
 	cdns->wakeup_irq = platform_get_irq_byname_optional(pdev, "wakeup");
 	if (cdns->wakeup_irq == -EPROBE_DEFER)
 		return cdns->wakeup_irq;
@@ -158,6 +161,7 @@ static int cdns3_plat_probe(struct platform_device *pdev)
 		goto err_cdns_init;
 
 	cdns->gadget_init = cdns3_plat_gadget_init;
+
 	ret = cdns_core_init_role(cdns);
 	if (ret)
 		goto err_cdns_init;
diff --git a/drivers/usb/cdns3/cdnsp-pci.c b/drivers/usb/cdns3/cdnsp-pci.c
index 432007cfe695..e20c59ceb8a4 100644
--- a/drivers/usb/cdns3/cdnsp-pci.c
+++ b/drivers/usb/cdns3/cdnsp-pci.c
@@ -19,6 +19,7 @@
 
 struct cdnsp_wrap {
 	struct platform_device *plat_dev;
+	struct property_entry prop[3];
 	struct resource dev_res[6];
 	int devfn;
 };
@@ -29,10 +30,15 @@ struct cdnsp_wrap {
 #define RES_HOST_ID		3
 #define RES_DEV_ID		4
 #define RES_DRD_ID		5
-
+/* DRD PCI configuration - 64-bit addressing */
+/* First PCI function */
 #define PCI_BAR_HOST		0
-#define PCI_BAR_OTG		0
 #define PCI_BAR_DEV		2
+/* Second PCI function */
+#define PCI_BAR_OTG		0
+/* Device only PCI configuration - 32-bit addressing */
+/* First PCI function */
+#define PCI_BAR_ONLY_DEV	1
 
 #define PCI_DEV_FN_HOST_DEVICE	0
 #define PCI_DEV_FN_OTG		1
@@ -65,6 +71,7 @@ static int cdnsp_pci_probe(struct pci_dev *pdev,
 	struct cdnsp_wrap *wrap;
 	struct resource *res;
 	struct pci_dev *func;
+	bool no_drd = false;
 	int ret = 0;
 
 	/*
@@ -75,11 +82,14 @@ static int cdnsp_pci_probe(struct pci_dev *pdev,
 		    pdev->devfn != PCI_DEV_FN_OTG))
 		return -EINVAL;
 
+	if (pdev->device == PCI_DEVICE_ID_CDNS_UDC_USBSSP)
+		no_drd = true;
+
 	func = cdnsp_get_second_fun(pdev);
-	if (!func)
+	if (!func && !no_drd)
 		return -EINVAL;
 
-	if (func->class == PCI_CLASS_SERIAL_USB_XHCI ||
+	if ((func && func->class == PCI_CLASS_SERIAL_USB_XHCI) ||
 	    pdev->class == PCI_CLASS_SERIAL_USB_XHCI) {
 		ret = -EINVAL;
 		goto put_pci;
@@ -93,7 +103,7 @@ static int cdnsp_pci_probe(struct pci_dev *pdev,
 
 	pci_set_master(pdev);
 
-	if (pci_is_enabled(func)) {
+	if (func && pci_is_enabled(func)) {
 		wrap = pci_get_drvdata(func);
 	} else {
 		wrap = kzalloc_obj(*wrap);
@@ -106,10 +116,13 @@ static int cdnsp_pci_probe(struct pci_dev *pdev,
 	res = wrap->dev_res;
 
 	if (pdev->devfn == PCI_DEV_FN_HOST_DEVICE) {
+		int bar_dev = no_drd ? PCI_BAR_ONLY_DEV : PCI_BAR_DEV;
+
 		/* Function 0: host(BAR_0) + device(BAR_2). */
 		dev_dbg(&pdev->dev, "Initialize Device resources\n");
-		res[RES_DEV_ID].start = pci_resource_start(pdev, PCI_BAR_DEV);
-		res[RES_DEV_ID].end = pci_resource_end(pdev, PCI_BAR_DEV);
+
+		res[RES_DEV_ID].start = pci_resource_start(pdev, bar_dev);
+		res[RES_DEV_ID].end = pci_resource_end(pdev, bar_dev);
 		res[RES_DEV_ID].name = "dev";
 		res[RES_DEV_ID].flags = IORESOURCE_MEM;
 		dev_dbg(&pdev->dev, "USBSSP-DEV physical base addr: %pa\n",
@@ -145,9 +158,20 @@ static int cdnsp_pci_probe(struct pci_dev *pdev,
 		wrap->dev_res[RES_IRQ_OTG_ID].flags = IORESOURCE_IRQ;
 	}
 
-	if (pci_is_enabled(func)) {
+	if (no_drd || pci_is_enabled(func)) {
+		u8 idx = 0;
+
 		/* set up platform device info */
 		pdata.override_apb_timeout = CHICKEN_APB_TIMEOUT_VALUE;
+		if (no_drd) {
+			wrap->prop[idx++] = PROPERTY_ENTRY_STRING("dr_mode", "peripheral");
+			wrap->prop[idx++] = PROPERTY_ENTRY_BOOL("no_drd");
+		} else {
+			wrap->prop[idx++] = PROPERTY_ENTRY_STRING("dr_mode", "otg");
+			wrap->prop[idx++] = PROPERTY_ENTRY_BOOL("usb-role-switch");
+		}
+
+		wrap->prop[idx] = (struct property_entry){ };
 		memset(&plat_info, 0, sizeof(plat_info));
 		plat_info.parent = &pdev->dev;
 		plat_info.fwnode = pdev->dev.fwnode;
@@ -158,6 +182,7 @@ static int cdnsp_pci_probe(struct pci_dev *pdev,
 		plat_info.dma_mask = pdev->dma_mask;
 		plat_info.data = &pdata;
 		plat_info.size_data = sizeof(pdata);
+		plat_info.properties = wrap->prop;
 		wrap->devfn = pdev->devfn;
 		/* register platform device */
 		wrap->plat_dev = platform_device_register_full(&plat_info);
@@ -185,13 +210,17 @@ static void cdnsp_pci_remove(struct pci_dev *pdev)
 	if (wrap->devfn == pdev->devfn)
 		platform_device_unregister(wrap->plat_dev);
 
-	if (!pci_is_enabled(func))
+	if (!func || !pci_is_enabled(func))
 		kfree(wrap);
 
 	pci_dev_put(func);
 }
 
 static const struct pci_device_id cdnsp_pci_ids[] = {
+	{ PCI_DEVICE(PCI_VENDOR_ID_CDNS, PCI_DEVICE_ID_CDNS_UDC_USBSSP),
+	  .class = PCI_CLASS_SERIAL_USB_DEVICE },
+	{ PCI_DEVICE(PCI_VENDOR_ID_CDNS, PCI_DEVICE_ID_CDNS_UDC_USBSSP),
+	  .class = PCI_CLASS_SERIAL_USB_CDNS },
 	{ PCI_DEVICE(PCI_VENDOR_ID_CDNS, PCI_DEVICE_ID_CDNS_USBSSP),
 	  .class = PCI_CLASS_SERIAL_USB_DEVICE },
 	{ PCI_DEVICE(PCI_VENDOR_ID_CDNS, PCI_DEVICE_ID_CDNS_USBSSP),
diff --git a/drivers/usb/cdns3/core.c b/drivers/usb/cdns3/core.c
index 10f00b6c3c83..72f7acba6258 100644
--- a/drivers/usb/cdns3/core.c
+++ b/drivers/usb/cdns3/core.c
@@ -71,7 +71,8 @@ static void cdns_role_stop(struct cdns *cdns)
 static void cdns_exit_roles(struct cdns *cdns)
 {
 	cdns_role_stop(cdns);
-	cdns_drd_exit(cdns);
+	if (!cdns->no_drd)
+		cdns_drd_exit(cdns);
 }
 
 /**
diff --git a/drivers/usb/cdns3/core.h b/drivers/usb/cdns3/core.h
index dc8c4137de15..6abe231f4559 100644
--- a/drivers/usb/cdns3/core.h
+++ b/drivers/usb/cdns3/core.h
@@ -80,9 +80,11 @@ struct cdns3_platform_data {
  * @pdata: platform data from glue layer
  * @lock: spinlock structure
  * @xhci_plat_data: xhci private data structure pointer
+ * @gadget_init: pointer to gadget initialization function
  * @override_apb_timeout: hold value of APB timeout. For value 0 the default
  *                        value in CHICKEN_BITS_3 will be preserved.
- * @gadget_init: pointer to gadget initialization function
+ * @no_drd: DRD register block is inaccessible - driver handles only
+ *          device mode.
  */
 struct cdns {
 	struct device			*dev;
@@ -122,6 +124,7 @@ struct cdns {
 	struct xhci_plat_priv		*xhci_plat_data;
 	int (*gadget_init)(struct cdns *cdns);
 	u32                             override_apb_timeout;
+	bool				no_drd;
 };
 
 int cdns_hw_role_switch(struct cdns *cdns);
diff --git a/drivers/usb/cdns3/drd.c b/drivers/usb/cdns3/drd.c
index 84fb38a5723a..38f3051c2188 100644
--- a/drivers/usb/cdns3/drd.c
+++ b/drivers/usb/cdns3/drd.c
@@ -107,7 +107,7 @@ void cdns_clear_vbus(struct cdns *cdns)
 {
 	u32 reg;
 
-	if (cdns->version != CDNSP_CONTROLLER_V2)
+	if (cdns->version != CDNSP_CONTROLLER_V2 || cdns->no_drd)
 		return;
 
 	reg = readl(&cdns->otg_cdnsp_regs->override);
@@ -120,7 +120,7 @@ void cdns_set_vbus(struct cdns *cdns)
 {
 	u32 reg;
 
-	if (cdns->version != CDNSP_CONTROLLER_V2)
+	if (cdns->version != CDNSP_CONTROLLER_V2 || cdns->no_drd)
 		return;
 
 	reg = readl(&cdns->otg_cdnsp_regs->override);
@@ -234,6 +234,9 @@ int cdns_drd_gadget_on(struct cdns *cdns)
 	u32 ready_bit;
 	int ret, val;
 
+	if (cdns->no_drd)
+		return 0;
+
 	/* switch OTG core */
 	writel(OTGCMD_DEV_BUS_REQ | reg, &cdns->otg_regs->cmd);
 
@@ -265,6 +268,9 @@ void cdns_drd_gadget_off(struct cdns *cdns)
 {
 	u32 val;
 
+	if (cdns->no_drd)
+		return;
+
 	/*
 	 * Driver should wait at least 10us after disabling Device
 	 * before turning-off Device (DEV_BUS_DROP).
@@ -392,6 +398,12 @@ int cdns_drd_init(struct cdns *cdns)
 	u32 state, reg;
 	int ret;
 
+	if (cdns->no_drd) {
+		cdns->version  = CDNSP_CONTROLLER_V2;
+		cdns->dr_mode = USB_DR_MODE_PERIPHERAL;
+		return 0;
+	}
+
 	regs = devm_ioremap_resource(cdns->dev, &cdns->otg_res);
 	if (IS_ERR(regs))
 		return PTR_ERR(regs);
diff --git a/include/linux/pci_ids.h b/include/linux/pci_ids.h
index 406abf629be2..a931fb201402 100644
--- a/include/linux/pci_ids.h
+++ b/include/linux/pci_ids.h
@@ -2424,6 +2424,7 @@
 #define PCI_DEVICE_ID_CDNS_USBSS	0x0100
 #define PCI_DEVICE_ID_CDNS_USB		0x0120
 #define PCI_DEVICE_ID_CDNS_USBSSP	0x0200
+#define PCI_DEVICE_ID_CDNS_UDC_USBSSP	0x0400
 
 #define PCI_VENDOR_ID_ARECA		0x17d3
 #define PCI_DEVICE_ID_ARECA_1110	0x1110

---
base-commit: 5196f2c98340297e1fdd36555285e991ceddf776
change-id: 20260331-device_only-192d539430b5

Best regards,
-- 
Pawel Laszczak <pawell@cadence.com>

