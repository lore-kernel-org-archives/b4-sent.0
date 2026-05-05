From: Pawel Laszczak <pawell@cadence.com>
Date: Tue, 05 May 2026 12:02:56 +0200
Subject: [PATCH v2] usb: cdnsp: Add support for device-only configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260505-device_only_branch_v2-v2-1-98cc19fbd02a@cadence.com>
X-B4-Tracking: v=1; b=H4sIAE/A+WkC/yXM4QpAMBSG4VvR+W21jkbcirSYgyONNkRy74afT
 33fe4Enx+ShiC5wtLPn2QZgHIEZatuT4DYYUGIqlVSiDSNDerbTqRtXWzPoHYVK0hy7BPNMIYT
 v4qjj4+uW1W+/NSOZ9Y3BfT98wnY2eQAAAA==
X-Change-ID: 20260505-device_only_branch_v2-53692f329752
To: Peter Chen <peter.chen@kernel.org>, Roger Quadros <rogerq@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, Pawel Laszczak <pawell@cadence.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777975404; l=9953;
 i=pawell@cadence.com; h=from:subject:message-id;
 bh=Gk+Ur3rb0vu4TmqjL1PKDsyq1isvGfq6AyCr3o+OfN8=;
 b=UsZ3qCQ8u7zjM9qNAKCl6Qsxkw8utxSmDi+TZhLQlnPixxlE5WlxsQGhTjJgozJW6fcyt6JSi
 0yFhrYzsdVWBjzS9EvmgezEtzy7zyZjr0TodzEXPfMT632LiBoDSiFa
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

Acked-by: Bjorn Helgaas <bhelgaas@google.com> # pci_ids.h
Signed-off-by: Pawel Laszczak <pawell@cadence.com>
---
This is a resubmission of the previous patch, now based on the restored
commit e4d7362dc9cd ("usb: cdns3: Add USBSSP platform driver support").

Since the "usb: cdns3: Add USBSSP platform driver support" patch  was
reverted and then re-added, this version (v2) ensures compatibility
with the latest tree state.
---
v2:
  - Changed otg_irq to be optionali.
  - Added cdns->no_drd check in cdns_power_is_lost.
  - Added cdns->no_drd check in cdns_get_id.
---
 drivers/usb/cdns3/cdns3-plat.c | 23 ++++++++++++-----------
 drivers/usb/cdns3/cdnsp-pci.c  | 33 ++++++++++++++++++++++++---------
 drivers/usb/cdns3/core.c       |  3 ++-
 drivers/usb/cdns3/core.h       |  3 +++
 drivers/usb/cdns3/drd.c        | 22 ++++++++++++++++++++--
 include/linux/pci_ids.h        |  1 +
 6 files changed, 62 insertions(+), 23 deletions(-)

diff --git a/drivers/usb/cdns3/cdns3-plat.c b/drivers/usb/cdns3/cdns3-plat.c
index 3fe3109a3688..1af19360410e 100644
--- a/drivers/usb/cdns3/cdns3-plat.c
+++ b/drivers/usb/cdns3/cdns3-plat.c
@@ -113,21 +113,22 @@ static int cdns3_plat_probe(struct platform_device *pdev)
 
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
+	cdns->otg_irq = platform_get_irq_byname_optional(pdev, "otg");
+
+	if (cdns->otg_irq < 0) {
+		dev_dbg(dev, "Device-only mode: DRD support disabled\n");
+		cdns->no_drd = 1;
+	} else {
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
diff --git a/drivers/usb/cdns3/cdnsp-pci.c b/drivers/usb/cdns3/cdnsp-pci.c
index 432007cfe695..28e16b094525 100644
--- a/drivers/usb/cdns3/cdnsp-pci.c
+++ b/drivers/usb/cdns3/cdnsp-pci.c
@@ -29,10 +29,15 @@ struct cdnsp_wrap {
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
@@ -65,6 +70,7 @@ static int cdnsp_pci_probe(struct pci_dev *pdev,
 	struct cdnsp_wrap *wrap;
 	struct resource *res;
 	struct pci_dev *func;
+	bool no_drd = false;
 	int ret = 0;
 
 	/*
@@ -75,11 +81,14 @@ static int cdnsp_pci_probe(struct pci_dev *pdev,
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
@@ -93,7 +102,7 @@ static int cdnsp_pci_probe(struct pci_dev *pdev,
 
 	pci_set_master(pdev);
 
-	if (pci_is_enabled(func)) {
+	if (func && pci_is_enabled(func)) {
 		wrap = pci_get_drvdata(func);
 	} else {
 		wrap = kzalloc_obj(*wrap);
@@ -106,10 +115,12 @@ static int cdnsp_pci_probe(struct pci_dev *pdev,
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
@@ -145,7 +156,7 @@ static int cdnsp_pci_probe(struct pci_dev *pdev,
 		wrap->dev_res[RES_IRQ_OTG_ID].flags = IORESOURCE_IRQ;
 	}
 
-	if (pci_is_enabled(func)) {
+	if (no_drd || pci_is_enabled(func)) {
 		/* set up platform device info */
 		pdata.override_apb_timeout = CHICKEN_APB_TIMEOUT_VALUE;
 		memset(&plat_info, 0, sizeof(plat_info));
@@ -185,13 +196,17 @@ static void cdnsp_pci_remove(struct pci_dev *pdev)
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
index bca973b999a4..ef3f50169246 100644
--- a/drivers/usb/cdns3/core.h
+++ b/drivers/usb/cdns3/core.h
@@ -84,6 +84,8 @@ struct cdns3_platform_data {
  *                        value in CHICKEN_BITS_3 will be preserved.
  * @gadget_init: pointer to gadget initialization function
  * @host_init: pointer to host initialization function
+ * @no_drd: DRD register block is inaccessible - driver handles only
+ *          device mode.
  */
 struct cdns {
 	struct device			*dev;
@@ -124,6 +126,7 @@ struct cdns {
 	u32                             override_apb_timeout;
 	int (*gadget_init)(struct cdns *cdns);
 	int (*host_init)(struct cdns *cdns);
+	bool				no_drd;
 };
 
 int cdns_hw_role_switch(struct cdns *cdns);
diff --git a/drivers/usb/cdns3/drd.c b/drivers/usb/cdns3/drd.c
index 84fb38a5723a..8e8414c2e994 100644
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
@@ -234,6 +237,9 @@ int cdns_drd_gadget_on(struct cdns *cdns)
 	u32 ready_bit;
 	int ret, val;
 
+	if (cdns->no_drd)
+		return 0;
+
 	/* switch OTG core */
 	writel(OTGCMD_DEV_BUS_REQ | reg, &cdns->otg_regs->cmd);
 
@@ -265,6 +271,9 @@ void cdns_drd_gadget_off(struct cdns *cdns)
 {
 	u32 val;
 
+	if (cdns->no_drd)
+		return;
+
 	/*
 	 * Driver should wait at least 10us after disabling Device
 	 * before turning-off Device (DEV_BUS_DROP).
@@ -392,6 +401,12 @@ int cdns_drd_init(struct cdns *cdns)
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
@@ -500,6 +515,9 @@ int cdns_drd_exit(struct cdns *cdns)
 /* Indicate the cdns3 core was power lost before */
 bool cdns_power_is_lost(struct cdns *cdns)
 {
+	if (cdns->no_drd)
+		return false;
+
 	if (cdns->version == CDNS3_CONTROLLER_V0) {
 		if (!(readl(&cdns->otg_v0_regs->simulate) & BIT(0)))
 			return true;
diff --git a/include/linux/pci_ids.h b/include/linux/pci_ids.h
index 24cb42f66e4b..a6b9b6f6d8cc 100644
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
base-commit: 9d0d467c3572e93c5faa2e5906a8bbcd70b24efd
change-id: 20260505-device_only_branch_v2-53692f329752

Best regards,
--  
Pawel Laszczak <pawell@cadence.com>

