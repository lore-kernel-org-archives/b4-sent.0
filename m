From: Pawel Laszczak <pawell@cadence.com>
Date: Fri, 15 May 2026 13:24:39 +0200
Subject: [PATCH v8 2/2] usb: cdnsp: Add support for device-only
 configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260515-b4-no_drd_config-v8-2-75cb05317679@cadence.com>
References: <20260515-b4-no_drd_config-v8-0-75cb05317679@cadence.com>
In-Reply-To: <20260515-b4-no_drd_config-v8-0-75cb05317679@cadence.com>
To: Peter Chen <peter.chen@kernel.org>, Roger Quadros <rogerq@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Pawel Laszczak <pawell@cadence.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, kernel test robot <lkp@intel.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778844286; l=13694;
 i=pawell@cadence.com; h=from:subject:message-id;
 bh=Gzu9SgEXlUMKHCY5Kq/x02JpU0OHGqAEWUR9QGLTu0k=;
 b=XJg2ntLTZ1Q78e6NAv7YNhp16tFa3wciFWDmfv4rTcn1oRAmP83B9MZV7TYjPDUI8aYWXrwdT
 Z9WQ+QK78neDQ6jc3XciIsCAPHJJPeWVFFhNGYjZk91yTHiQRheLxW5
X-Developer-Key: i=pawell@cadence.com; a=ed25519;
 pk=EUPBvLO9CDg7j6defeDl2iqi+z5Ivqu4Z46aiqe7dYc=
X-Endpoint-Received: by B4 Relay for pawell@cadence.com/default with auth_id=707
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch introduces support for the Cadence USBSSP (cdnsp)
controller in hardware configurations where the Dual-Role Device (DRD)
register block is not implemented or is inaccessible.

In such cases, the driver cannot rely on the DRD logic to manage roles
and must operate exclusively in a fixed peripheral/host mode.

The change in BAR indexing (from BAR 2 to BAR 1) is a direct
consequence of the 32-bit addressing used in this specific
DRD-disabled hardware layout, compared to the 64-bit addressing
used in DRD-enabled configurations.

Tested on a PCI platform with a hardware configuration that lacks
DRD support. Platform-side changes are included to support the PCI
glue layer's property injection to handle this specific layout.

Acked-by: Peter Chen <peter.chen@kernel.org>
Acked-by: Bjorn Helgaas <bhelgaas@google.com>
Signed-off-by: Pawel Laszczak <pawell@cadence.com>
Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202605141023.18vWXyw3-lkp@intel.com/
---
v8:
- Use 'cdns,cdnsp-no-drd' compatible string to trigger no-DRD logic.
- Update PCI glue layer to inject the new compatible string.

v7:
- Use 'cdns,no-drd' instead of 'no_drd' to match updated bindings.
- Fix "uninitialized variable" warning in cdns_drd_host_on() by
  initializing 'ret' to 0.
---
 drivers/usb/cdns3/cdns3-plat.c | 30 ++++++++++++++++----------
 drivers/usb/cdns3/cdnsp-pci.c  | 48 ++++++++++++++++++++++++++++++++++--------
 drivers/usb/cdns3/core.c       |  3 ++-
 drivers/usb/cdns3/core.h       |  4 ++++
 drivers/usb/cdns3/drd.c        | 45 ++++++++++++++++++++++++++++++++++++---
 5 files changed, 106 insertions(+), 24 deletions(-)

diff --git a/drivers/usb/cdns3/cdns3-plat.c b/drivers/usb/cdns3/cdns3-plat.c
index 3fe3109a3688..303f7c1431dc 100644
--- a/drivers/usb/cdns3/cdns3-plat.c
+++ b/drivers/usb/cdns3/cdns3-plat.c
@@ -81,6 +81,12 @@ static int cdns3_plat_probe(struct platform_device *pdev)
 	if (cdns->pdata && cdns->pdata->override_apb_timeout)
 		cdns->override_apb_timeout = cdns->pdata->override_apb_timeout;
 
+	if (device_is_compatible(dev, "cdns,cdnsp-no-drd")) {
+		cdns->no_drd = true;
+		cdns->version = CDNSP_CONTROLLER_V2;
+		dev_dbg(dev, "No DRD support\n");
+	}
+
 	platform_set_drvdata(pdev, cdns);
 
 	ret = platform_get_irq_byname(pdev, "host");
@@ -113,21 +119,22 @@ static int cdns3_plat_probe(struct platform_device *pdev)
 
 	cdns->dev_regs	= regs;
 
-	cdns->otg_irq = platform_get_irq_byname(pdev, "otg");
-	if (cdns->otg_irq < 0)
-		return dev_err_probe(dev, cdns->otg_irq,
-				     "Failed to get otg IRQ\n");
-
-	res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "otg");
-	if (!res) {
-		dev_err(dev, "couldn't get otg resource\n");
-		return -ENXIO;
+	if (!cdns->no_drd) {
+		cdns->otg_irq = platform_get_irq_byname(pdev, "otg");
+		if (cdns->otg_irq < 0)
+			return dev_err_probe(dev, cdns->otg_irq,
+					     "Failed to get otg IRQ\n");
+
+		res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "otg");
+		if (!res) {
+			dev_err(dev, "couldn't get otg resource\n");
+			return -ENXIO;
+		}
+		cdns->otg_res = *res;
 	}
 
 	cdns->phyrst_a_enable = device_property_read_bool(dev, "cdns,phyrst-a-enable");
 
-	cdns->otg_res = *res;
-
 	cdns->wakeup_irq = platform_get_irq_byname_optional(pdev, "wakeup");
 	if (cdns->wakeup_irq == -EPROBE_DEFER)
 		return cdns->wakeup_irq;
@@ -338,6 +345,7 @@ static const struct dev_pm_ops cdns3_pm_ops = {
 #ifdef CONFIG_OF
 static const struct of_device_id of_cdns3_match[] = {
 	{ .compatible = "cdns,usb3" },
+	{ .compatible = "cdns,cdnsp-no-drd" },
 	{ },
 };
 MODULE_DEVICE_TABLE(of, of_cdns3_match);
diff --git a/drivers/usb/cdns3/cdnsp-pci.c b/drivers/usb/cdns3/cdnsp-pci.c
index 432007cfe695..1a71dee5044c 100644
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
@@ -40,6 +46,7 @@ struct cdnsp_wrap {
 #define PCI_DRIVER_NAME		"cdns-pci-usbssp"
 #define PLAT_DRIVER_NAME	"cdns-usb3"
 
+#define PCI_DEVICE_ID_CDNS_UDC_USBSSP   0x0400
 #define CHICKEN_APB_TIMEOUT_VALUE	0x1C20
 
 static struct pci_dev *cdnsp_get_second_fun(struct pci_dev *pdev)
@@ -65,6 +72,7 @@ static int cdnsp_pci_probe(struct pci_dev *pdev,
 	struct cdnsp_wrap *wrap;
 	struct resource *res;
 	struct pci_dev *func;
+	bool no_drd = false;
 	int ret = 0;
 
 	/*
@@ -75,11 +83,14 @@ static int cdnsp_pci_probe(struct pci_dev *pdev,
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
@@ -93,7 +104,7 @@ static int cdnsp_pci_probe(struct pci_dev *pdev,
 
 	pci_set_master(pdev);
 
-	if (pci_is_enabled(func)) {
+	if (func && pci_is_enabled(func)) {
 		wrap = pci_get_drvdata(func);
 	} else {
 		wrap = kzalloc_obj(*wrap);
@@ -106,10 +117,12 @@ static int cdnsp_pci_probe(struct pci_dev *pdev,
 	res = wrap->dev_res;
 
 	if (pdev->devfn == PCI_DEV_FN_HOST_DEVICE) {
+		int bar_dev = no_drd ? PCI_BAR_ONLY_DEV : PCI_BAR_DEV;
+
 		/* Function 0: host(BAR_0) + device(BAR_2). */
 		dev_dbg(&pdev->dev, "Initialize Device resources\n");
-		res[RES_DEV_ID].start = pci_resource_start(pdev, PCI_BAR_DEV);
-		res[RES_DEV_ID].end = pci_resource_end(pdev, PCI_BAR_DEV);
+		res[RES_DEV_ID].start = pci_resource_start(pdev, bar_dev);
+		res[RES_DEV_ID].end = pci_resource_end(pdev, bar_dev);
 		res[RES_DEV_ID].name = "dev";
 		res[RES_DEV_ID].flags = IORESOURCE_MEM;
 		dev_dbg(&pdev->dev, "USBSSP-DEV physical base addr: %pa\n",
@@ -145,9 +158,21 @@ static int cdnsp_pci_probe(struct pci_dev *pdev,
 		wrap->dev_res[RES_IRQ_OTG_ID].flags = IORESOURCE_IRQ;
 	}
 
-	if (pci_is_enabled(func)) {
+	if (no_drd || pci_is_enabled(func)) {
+		u8 idx = 0;
+
 		/* set up platform device info */
 		pdata.override_apb_timeout = CHICKEN_APB_TIMEOUT_VALUE;
+
+		if (no_drd) {
+			wrap->prop[idx++] = PROPERTY_ENTRY_STRING("compatible",
+								  "cdns,cdnsp-no-drd");
+			wrap->prop[idx++] = PROPERTY_ENTRY_STRING("dr_mode", "peripheral");
+		} else {
+			wrap->prop[idx++] = PROPERTY_ENTRY_STRING("dr_mode", "otg");
+			wrap->prop[idx++] = PROPERTY_ENTRY_BOOL("usb-role-switch");
+		}
+
 		memset(&plat_info, 0, sizeof(plat_info));
 		plat_info.parent = &pdev->dev;
 		plat_info.fwnode = pdev->dev.fwnode;
@@ -158,6 +183,7 @@ static int cdnsp_pci_probe(struct pci_dev *pdev,
 		plat_info.dma_mask = pdev->dma_mask;
 		plat_info.data = &pdata;
 		plat_info.size_data = sizeof(pdata);
+		plat_info.properties = wrap->prop;
 		wrap->devfn = pdev->devfn;
 		/* register platform device */
 		wrap->plat_dev = platform_device_register_full(&plat_info);
@@ -185,13 +211,17 @@ static void cdnsp_pci_remove(struct pci_dev *pdev)
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
index 6a8d1fefbc0d..504bdf13ea80 100644
--- a/drivers/usb/cdns3/core.c
+++ b/drivers/usb/cdns3/core.c
@@ -70,7 +70,8 @@ static void cdns_role_stop(struct cdns *cdns)
 static void cdns_exit_roles(struct cdns *cdns)
 {
 	cdns_role_stop(cdns);
-	cdns_drd_exit(cdns);
+	if (!cdns->no_drd)
+		cdns_drd_exit(cdns);
 }
 
 /**
diff --git a/drivers/usb/cdns3/core.h b/drivers/usb/cdns3/core.h
index bca973b999a4..8c492fda924c 100644
--- a/drivers/usb/cdns3/core.h
+++ b/drivers/usb/cdns3/core.h
@@ -84,6 +84,9 @@ struct cdns3_platform_data {
  *                        value in CHICKEN_BITS_3 will be preserved.
  * @gadget_init: pointer to gadget initialization function
  * @host_init: pointer to host initialization function
+ * @no_drd: DRD register block is inaccessible. The controller is hardwired to
+ *          single role (host or device) or the logic for role switching is
+ *          missing.
  */
 struct cdns {
 	struct device			*dev;
@@ -124,6 +127,7 @@ struct cdns {
 	u32                             override_apb_timeout;
 	int (*gadget_init)(struct cdns *cdns);
 	int (*host_init)(struct cdns *cdns);
+	bool				no_drd;
 };
 
 int cdns_hw_role_switch(struct cdns *cdns);
diff --git a/drivers/usb/cdns3/drd.c b/drivers/usb/cdns3/drd.c
index 84fb38a5723a..d2bb682e4552 100644
--- a/drivers/usb/cdns3/drd.c
+++ b/drivers/usb/cdns3/drd.c
@@ -87,6 +87,9 @@ int cdns_get_id(struct cdns *cdns)
 {
 	int id;
 
+	if (cdns->no_drd)
+		return 0;
+
 	id = readl(&cdns->otg_regs->sts) & OTGSTS_ID_VALUE;
 	dev_dbg(cdns->dev, "OTG ID: %d", id);
 
@@ -107,7 +110,7 @@ void cdns_clear_vbus(struct cdns *cdns)
 {
 	u32 reg;
 
-	if (cdns->version != CDNSP_CONTROLLER_V2)
+	if (cdns->version != CDNSP_CONTROLLER_V2 || cdns->no_drd)
 		return;
 
 	reg = readl(&cdns->otg_cdnsp_regs->override);
@@ -120,7 +123,7 @@ void cdns_set_vbus(struct cdns *cdns)
 {
 	u32 reg;
 
-	if (cdns->version != CDNSP_CONTROLLER_V2)
+	if (cdns->version != CDNSP_CONTROLLER_V2 || cdns->no_drd)
 		return;
 
 	reg = readl(&cdns->otg_cdnsp_regs->override);
@@ -179,7 +182,10 @@ static void cdns_otg_enable_irq(struct cdns *cdns)
 int cdns_drd_host_on(struct cdns *cdns)
 {
 	u32 val, ready_bit;
-	int ret;
+	int ret = 0;
+
+	if (cdns->no_drd)
+		goto phy_set;
 
 	/* Enable host mode. */
 	writel(OTGCMD_HOST_BUS_REQ | OTGCMD_OTG_DIS,
@@ -197,6 +203,7 @@ int cdns_drd_host_on(struct cdns *cdns)
 	if (ret)
 		dev_err(cdns->dev, "timeout waiting for xhci_ready\n");
 
+phy_set:
 	phy_set_mode(cdns->usb2_phy, PHY_MODE_USB_HOST);
 	phy_set_mode(cdns->usb3_phy, PHY_MODE_USB_HOST);
 	return ret;
@@ -210,6 +217,9 @@ void cdns_drd_host_off(struct cdns *cdns)
 {
 	u32 val;
 
+	if (cdns->no_drd)
+		goto phy_set;
+
 	writel(OTGCMD_HOST_BUS_DROP | OTGCMD_DEV_BUS_DROP |
 	       OTGCMD_DEV_POWER_OFF | OTGCMD_HOST_POWER_OFF,
 	       &cdns->otg_regs->cmd);
@@ -218,6 +228,8 @@ void cdns_drd_host_off(struct cdns *cdns)
 	readl_poll_timeout_atomic(&cdns->otg_regs->state, val,
 				  !(val & OTGSTATE_HOST_STATE_MASK),
 				  1, 2000000);
+
+phy_set:
 	phy_set_mode(cdns->usb2_phy, PHY_MODE_INVALID);
 	phy_set_mode(cdns->usb3_phy, PHY_MODE_INVALID);
 }
@@ -234,6 +246,9 @@ int cdns_drd_gadget_on(struct cdns *cdns)
 	u32 ready_bit;
 	int ret, val;
 
+	if (cdns->no_drd)
+		goto phy_set;
+
 	/* switch OTG core */
 	writel(OTGCMD_DEV_BUS_REQ | reg, &cdns->otg_regs->cmd);
 
@@ -251,6 +266,7 @@ int cdns_drd_gadget_on(struct cdns *cdns)
 		return ret;
 	}
 
+phy_set:
 	phy_set_mode(cdns->usb2_phy, PHY_MODE_USB_DEVICE);
 	phy_set_mode(cdns->usb3_phy, PHY_MODE_USB_DEVICE);
 	return 0;
@@ -265,6 +281,9 @@ void cdns_drd_gadget_off(struct cdns *cdns)
 {
 	u32 val;
 
+	if (cdns->no_drd)
+		goto phy_set;
+
 	/*
 	 * Driver should wait at least 10us after disabling Device
 	 * before turning-off Device (DEV_BUS_DROP).
@@ -277,6 +296,8 @@ void cdns_drd_gadget_off(struct cdns *cdns)
 	readl_poll_timeout_atomic(&cdns->otg_regs->state, val,
 				  !(val & OTGSTATE_DEV_STATE_MASK),
 				  1, 2000000);
+
+phy_set:
 	phy_set_mode(cdns->usb2_phy, PHY_MODE_INVALID);
 	phy_set_mode(cdns->usb3_phy, PHY_MODE_INVALID);
 }
@@ -392,6 +413,18 @@ int cdns_drd_init(struct cdns *cdns)
 	u32 state, reg;
 	int ret;
 
+	if (cdns->no_drd) {
+		cdns->dr_mode = usb_get_dr_mode(cdns->dev);
+
+		if (cdns->dr_mode != USB_DR_MODE_HOST &&
+		    cdns->dr_mode != USB_DR_MODE_PERIPHERAL) {
+			dev_err(cdns->dev, "Incorrect dr_mode\n");
+			return -EINVAL;
+		}
+
+		return 0;
+	}
+
 	regs = devm_ioremap_resource(cdns->dev, &cdns->otg_res);
 	if (IS_ERR(regs))
 		return PTR_ERR(regs);
@@ -492,6 +525,9 @@ int cdns_drd_init(struct cdns *cdns)
 
 int cdns_drd_exit(struct cdns *cdns)
 {
+	if (cdns->no_drd)
+		return 0;
+
 	cdns_otg_disable_irq(cdns);
 
 	return 0;
@@ -500,6 +536,9 @@ int cdns_drd_exit(struct cdns *cdns)
 /* Indicate the cdns3 core was power lost before */
 bool cdns_power_is_lost(struct cdns *cdns)
 {
+	if (cdns->no_drd)
+		return false;
+
 	if (cdns->version == CDNS3_CONTROLLER_V0) {
 		if (!(readl(&cdns->otg_v0_regs->simulate) & BIT(0)))
 			return true;

-- 
2.43.0

