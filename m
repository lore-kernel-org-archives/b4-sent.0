From: Junhui Liu <liujh2818@outlook.com>
Date: Mon, 30 Dec 2024 11:30:16 +0800
Subject: [PATCH v2 1/8] usb: dwc2: Extract register definitions to common
 header file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241230-dwc2-dev-v2-1-12cd9b8a2358@outlook.com>
References: <20241230-dwc2-dev-v2-0-12cd9b8a2358@outlook.com>
In-Reply-To: <20241230-dwc2-dev-v2-0-12cd9b8a2358@outlook.com>
To: Tom Rini <trini@konsulko.com>, Marek Vasut <marex@denx.de>, 
 Lukasz Majewski <lukma@denx.de>, 
 Mattijs Korpershoek <mkorpershoek@baylibre.com>
Cc: u-boot@lists.denx.de, Kongyang Liu <seashell11234455@gmail.com>, 
 Junhui Liu <liujh2818@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735529447; l=52696;
 i=liujh2818@outlook.com; s=20241030; h=from:subject:message-id;
 bh=uWc0jPBeTrTtaCQRoTCw704WYS1XbsBOZinDLn+WbCI=;
 b=22p18m8hGiwzXePo0sCxh2kjCS2eujwjYF//RbOozPEMTes/jOJghtUVqTeGo66OAFQEyTDd6
 e+UtPOaZ2HNDFXccIzL47mnbwEUcGwGtYDfDowwIyXl/vwJ1Qt3oJah
X-Developer-Key: i=liujh2818@outlook.com; a=ed25519;
 pk=ApYwI6KD3EjynMw61RqGa6c5BGbStQnKSrbNN+aQqT4=
X-Endpoint-Received: by B4 Relay for liujh2818@outlook.com/20241030 with auth_id=259
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Kongyang Liu <seashell11234455@gmail.com>

The same registers are accessed in both the otg and gatet drivers of
dwc2, and these registers are repeatedly defined in these two parts.
Extract register definitions into a common header file to reduce
redundancy and make the code more maintainable.

Signed-off-by: Kongyang Liu <seashell11234455@gmail.com>
Signed-off-by: Junhui Liu <liujh2818@outlook.com>
---
 drivers/usb/common/dwc2_core.h             | 126 ++++++++++++++++++
 drivers/usb/gadget/dwc2_udc_otg.c          |  94 +++++++-------
 drivers/usb/gadget/dwc2_udc_otg_regs.h     |  68 +---------
 drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c | 201 +++++++++++++++--------------
 drivers/usb/host/dwc2.c                    | 102 ++++++++-------
 drivers/usb/host/dwc2.h                    |  58 ---------
 6 files changed, 332 insertions(+), 317 deletions(-)

diff --git a/drivers/usb/common/dwc2_core.h b/drivers/usb/common/dwc2_core.h
new file mode 100644
index 0000000000000000000000000000000000000000..26483a57e7df58e2b9fe820367e1680b9251af8d
--- /dev/null
+++ b/drivers/usb/common/dwc2_core.h
@@ -0,0 +1,126 @@
+/* SPDX-License-Identifier: GPL-2.0+ */
+/*
+ * Copyright (c) 2024, Kongyang Liu <seashell11234455@gmail.com>
+ *
+ */
+
+#ifndef __DWC2_CORE_H_
+#define __DWC2_CORE_H_
+
+struct dwc2_global_regs {
+	u32 gotgctl;	/* 0x000 */
+	u32 gotgint;
+	u32 gahbcfg;
+	u32 gusbcfg;
+	u32 grstctl;	/* 0x010 */
+	u32 gintsts;
+	u32 gintmsk;
+	u32 grxstsr;
+	u32 grxstsp;	/* 0x020 */
+	u32 grxfsiz;
+	u32 gnptxfsiz;
+	u32 gnptxsts;
+	u32 gi2cctl;	/* 0x030 */
+	u32 gpvndctl;
+	u32 ggpio;
+	u32 guid;
+	u32 gsnpsid;	/* 0x040 */
+	u32 ghwcfg1;
+	u32 ghwcfg2;
+	u32 ghwcfg3;
+	u32 ghwcfg4;	/* 0x050 */
+	u32 glpmcfg;
+	u32 gpwrdn;
+	u32 gdfifocfg;
+	u32 gadpctl;	/* 0x060 */
+	u32 grefclk;
+	u32 gintmsk2;
+	u32 gintsts2;
+	u8  _pad_from_0x70_to_0x100[0x100 - 0x70];
+	u32 hptxfsiz;	/* 0x100 */
+	u32 dptxfsizn[15];
+	u8  _pad_from_0x140_to_0x400[0x400 - 0x140];
+};
+
+struct dwc2_hc_regs {
+	u32 hcchar;	/* 0x500 + 0x20 * ch */
+	u32 hcsplt;
+	u32 hcint;
+	u32 hcintmsk;
+	u32 hctsiz;
+	u32 hcdma;
+	u32 reserved;
+	u32 hcdmab;
+};
+
+struct dwc2_host_regs {
+	u32 hcfg;	/* 0x400 */
+	u32 hfir;
+	u32 hfnum;
+	u32 _pad_0x40c;
+	u32 hptxsts;	/* 0x410 */
+	u32 haint;
+	u32 haintmsk;
+	u32 hflbaddr;
+	u8  _pad_from_0x420_to_0x440[0x440 - 0x420];
+	u32 hprt0;	/* 0x440 */
+	u8  _pad_from_0x444_to_0x500[0x500 - 0x444];
+	struct dwc2_hc_regs hc[16];	/* 0x500 */
+	u8  _pad_from_0x700_to_0x800[0x800 - 0x700];
+};
+
+/* Device Logical IN Endpoint-Specific Registers */
+struct dwc2_dev_in_endp {
+	u32 diepctl;	/* 0x900 + 0x20 * ep */
+	u32 reserved0;
+	u32 diepint;
+	u32 reserved1;
+	u32 dieptsiz;
+	u32 diepdma;
+	u32 reserved2;
+	u32 diepdmab;
+};
+
+/* Device Logical OUT Endpoint-Specific Registers */
+struct dwc2_dev_out_endp {
+	u32 doepctl;	/* 0xB00 + 0x20 * ep */
+	u32 reserved0;
+	u32 doepint;
+	u32 reserved1;
+	u32 doeptsiz;
+	u32 doepdma;
+	u32 reserved2;
+	u32 doepdmab;
+};
+
+struct dwc2_device_regs {
+	u32 dcfg;	/* 0x800 */
+	u32 dctl;
+	u32 dsts;
+	u32 _pad_0x80c;
+	u32 diepmsk;	/* 0x810 */
+	u32 doepmsk;
+	u32 daint;
+	u32 daintmsk;
+	u32 dtknqr1;	/* 0x820 */
+	u32 dtknqr2;
+	u32 dvbusdis;
+	u32 dvbuspulse;
+	u32 dtknqr3;	/* 0x830 */
+	u32 dtknqr4;
+	u8  _pad_from_0x838_to_0x900[0x900 - 0x838];
+	struct dwc2_dev_in_endp  in_endp[16];	/* 0x900 */
+	struct dwc2_dev_out_endp out_endp[16];	/* 0xB00 */
+};
+
+struct dwc2_core_regs {
+	struct dwc2_global_regs  global_regs;	/* 0x000 */
+	struct dwc2_host_regs    host_regs;	/* 0x400 */
+	struct dwc2_device_regs  device_regs;	/* 0x800 */
+	u8  _pad_from_0xd00_to_0xe00[0xe00 - 0xd00];
+	u32 pcgcctl;				/* 0xe00 */
+	u8  _pad_from_0xe04_to_0x1000[0x1000 - 0xe04];
+	u8  ep_fifo[16][0x1000];		/* 0x1000 */
+};
+
+#endif /* __DWC2_CORE_H_ */
diff --git a/drivers/usb/gadget/dwc2_udc_otg.c b/drivers/usb/gadget/dwc2_udc_otg.c
index 7e9dd6f4268d3d80bf0572d71e267fbd26ce1516..c3dee8771e6c98692dd2ed6b50ca3c6ea21782af 100644
--- a/drivers/usb/gadget/dwc2_udc_otg.c
+++ b/drivers/usb/gadget/dwc2_udc_otg.c
@@ -45,6 +45,7 @@
 
 #include <power/regulator.h>
 
+#include "../common/dwc2_core.h"
 #include "dwc2_udc_otg_regs.h"
 #include "dwc2_udc_otg_priv.h"
 
@@ -154,11 +155,11 @@ static struct usb_ep_ops dwc2_ep_ops = {
 
 /***********************************************************/
 
-struct dwc2_usbotg_reg *reg;
+struct dwc2_core_regs *reg;
 
 bool dfu_usb_get_reset(void)
 {
-	return !!(readl(&reg->gintsts) & INT_RESET);
+	return !!(readl(&reg->global_regs.gintsts) & INT_RESET);
 }
 
 __weak void otg_phy_init(struct dwc2_udc *dev) {}
@@ -229,7 +230,7 @@ static int udc_enable(struct dwc2_udc *dev)
 
 	debug_cond(DEBUG_SETUP != 0,
 		   "DWC2 USB 2.0 OTG Controller Core Initialized : 0x%x\n",
-		    readl(&reg->gintmsk));
+		    readl(&reg->global_regs.gintmsk));
 
 	dev->gadget.speed = USB_SPEED_UNKNOWN;
 
@@ -238,7 +239,7 @@ static int udc_enable(struct dwc2_udc *dev)
 
 static int dwc2_gadget_pullup(struct usb_gadget *g, int is_on)
 {
-	clrsetbits_le32(&reg->dctl, SOFT_DISCONNECT,
+	clrsetbits_le32(&reg->device_regs.dctl, SOFT_DISCONNECT,
 			is_on ? 0 : SOFT_DISCONNECT);
 
 	return 0;
@@ -463,12 +464,14 @@ static void reconfig_usbd(struct dwc2_udc *dev)
 {
 	/* 2. Soft-reset OTG Core and then unreset again. */
 	int i;
-	unsigned int uTemp = writel(CORE_SOFT_RESET, &reg->grstctl);
+	unsigned int uTemp;
 	uint32_t dflt_gusbcfg;
 	uint32_t rx_fifo_sz, tx_fifo_sz, np_tx_fifo_sz;
 	u32 max_hw_ep;
 	int pdata_hw_ep;
 
+	writel(CORE_SOFT_RESET, &reg->global_regs.grstctl);
+
 	debug("Resetting OTG controller\n");
 
 	dflt_gusbcfg =
@@ -490,47 +493,47 @@ static void reconfig_usbd(struct dwc2_udc *dev)
 	if (dev->pdata->usb_gusbcfg)
 		dflt_gusbcfg = dev->pdata->usb_gusbcfg;
 
-	writel(dflt_gusbcfg, &reg->gusbcfg);
+	writel(dflt_gusbcfg, &reg->global_regs.gusbcfg);
 
 	/* 3. Put the OTG device core in the disconnected state.*/
-	uTemp = readl(&reg->dctl);
+	uTemp = readl(&reg->device_regs.dctl);
 	uTemp |= SOFT_DISCONNECT;
-	writel(uTemp, &reg->dctl);
+	writel(uTemp, &reg->device_regs.dctl);
 
 	udelay(20);
 
 	/* 4. Make the OTG device core exit from the disconnected state.*/
-	uTemp = readl(&reg->dctl);
+	uTemp = readl(&reg->device_regs.dctl);
 	uTemp = uTemp & ~SOFT_DISCONNECT;
-	writel(uTemp, &reg->dctl);
+	writel(uTemp, &reg->device_regs.dctl);
 
 	/* 5. Configure OTG Core to initial settings of device mode.*/
 	/* [][1: full speed(30Mhz) 0:high speed]*/
-	writel(EP_MISS_CNT(1) | DEV_SPEED_HIGH_SPEED_20, &reg->dcfg);
+	writel(EP_MISS_CNT(1) | DEV_SPEED_HIGH_SPEED_20, &reg->device_regs.dcfg);
 
 	mdelay(1);
 
 	/* 6. Unmask the core interrupts*/
-	writel(GINTMSK_INIT, &reg->gintmsk);
+	writel(GINTMSK_INIT, &reg->global_regs.gintmsk);
 
 	/* 7. Set NAK bit of EP0, EP1, EP2*/
-	writel(DEPCTL_EPDIS|DEPCTL_SNAK, &reg->out_endp[EP0_CON].doepctl);
-	writel(DEPCTL_EPDIS|DEPCTL_SNAK, &reg->in_endp[EP0_CON].diepctl);
+	writel(DEPCTL_EPDIS | DEPCTL_SNAK, &reg->device_regs.out_endp[EP0_CON].doepctl);
+	writel(DEPCTL_EPDIS | DEPCTL_SNAK, &reg->device_regs.in_endp[EP0_CON].diepctl);
 
 	for (i = 1; i < DWC2_MAX_ENDPOINTS; i++) {
-		writel(DEPCTL_EPDIS|DEPCTL_SNAK, &reg->out_endp[i].doepctl);
-		writel(DEPCTL_EPDIS|DEPCTL_SNAK, &reg->in_endp[i].diepctl);
+		writel(DEPCTL_EPDIS | DEPCTL_SNAK, &reg->device_regs.out_endp[i].doepctl);
+		writel(DEPCTL_EPDIS | DEPCTL_SNAK, &reg->device_regs.in_endp[i].diepctl);
 	}
 
 	/* 8. Unmask EPO interrupts*/
 	writel(((1 << EP0_CON) << DAINT_OUT_BIT)
-	       | (1 << EP0_CON), &reg->daintmsk);
+	       | (1 << EP0_CON), &reg->device_regs.daintmsk);
 
 	/* 9. Unmask device OUT EP common interrupts*/
-	writel(DOEPMSK_INIT, &reg->doepmsk);
+	writel(DOEPMSK_INIT, &reg->device_regs.doepmsk);
 
 	/* 10. Unmask device IN EP common interrupts*/
-	writel(DIEPMSK_INIT, &reg->diepmsk);
+	writel(DIEPMSK_INIT, &reg->device_regs.diepmsk);
 
 	rx_fifo_sz = RX_FIFO_SIZE;
 	np_tx_fifo_sz = NPTX_FIFO_SIZE;
@@ -544,14 +547,14 @@ static void reconfig_usbd(struct dwc2_udc *dev)
 		tx_fifo_sz = dev->pdata->tx_fifo_sz;
 
 	/* 11. Set Rx FIFO Size (in 32-bit words) */
-	writel(rx_fifo_sz, &reg->grxfsiz);
+	writel(rx_fifo_sz, &reg->global_regs.grxfsiz);
 
 	/* 12. Set Non Periodic Tx FIFO Size */
 	writel((np_tx_fifo_sz << 16) | rx_fifo_sz,
-	       &reg->gnptxfsiz);
+	       &reg->global_regs.gnptxfsiz);
 
 	/* retrieve the number of IN Endpoints (excluding ep0) */
-	max_hw_ep = (readl(&reg->ghwcfg4) & GHWCFG4_NUM_IN_EPS_MASK) >>
+	max_hw_ep = (readl(&reg->global_regs.ghwcfg4) & GHWCFG4_NUM_IN_EPS_MASK) >>
 		    GHWCFG4_NUM_IN_EPS_SHIFT;
 	pdata_hw_ep = dev->pdata->tx_fifo_sz_nb;
 
@@ -565,27 +568,27 @@ static void reconfig_usbd(struct dwc2_udc *dev)
 			tx_fifo_sz = dev->pdata->tx_fifo_sz_array[i];
 
 		writel((rx_fifo_sz + np_tx_fifo_sz + (tx_fifo_sz * i)) |
-			tx_fifo_sz << 16, &reg->dieptxf[i]);
+			tx_fifo_sz << 16, &reg->global_regs.dptxfsizn[i]);
 	}
 	/* Flush the RX FIFO */
-	writel(RX_FIFO_FLUSH, &reg->grstctl);
-	while (readl(&reg->grstctl) & RX_FIFO_FLUSH)
+	writel(RX_FIFO_FLUSH, &reg->global_regs.grstctl);
+	while (readl(&reg->global_regs.grstctl) & RX_FIFO_FLUSH)
 		debug("%s: waiting for DWC2_UDC_OTG_GRSTCTL\n", __func__);
 
 	/* Flush all the Tx FIFO's */
-	writel(TX_FIFO_FLUSH_ALL, &reg->grstctl);
-	writel(TX_FIFO_FLUSH_ALL | TX_FIFO_FLUSH, &reg->grstctl);
-	while (readl(&reg->grstctl) & TX_FIFO_FLUSH)
+	writel(TX_FIFO_FLUSH_ALL, &reg->global_regs.grstctl);
+	writel(TX_FIFO_FLUSH_ALL | TX_FIFO_FLUSH, &reg->global_regs.grstctl);
+	while (readl(&reg->global_regs.grstctl) & TX_FIFO_FLUSH)
 		debug("%s: waiting for DWC2_UDC_OTG_GRSTCTL\n", __func__);
 
 	/* 13. Clear NAK bit of EP0, EP1, EP2*/
 	/* For Slave mode*/
 	/* EP0: Control OUT */
 	writel(DEPCTL_EPDIS | DEPCTL_CNAK,
-	       &reg->out_endp[EP0_CON].doepctl);
+	       &reg->device_regs.out_endp[EP0_CON].doepctl);
 
 	/* 14. Initialize OTG Link Core.*/
-	writel(GAHBCFG_INIT, &reg->gahbcfg);
+	writel(GAHBCFG_INIT, &reg->global_regs.gahbcfg);
 }
 
 static void set_max_pktsize(struct dwc2_udc *dev, enum usb_device_speed speed)
@@ -610,12 +613,12 @@ static void set_max_pktsize(struct dwc2_udc *dev, enum usb_device_speed speed)
 		dev->ep[i].ep.maxpacket = ep_fifo_size;
 
 	/* EP0 - Control IN (64 bytes)*/
-	ep_ctrl = readl(&reg->in_endp[EP0_CON].diepctl);
-	writel(ep_ctrl|(0<<0), &reg->in_endp[EP0_CON].diepctl);
+	ep_ctrl = readl(&reg->device_regs.in_endp[EP0_CON].diepctl);
+	writel(ep_ctrl | (0 << 0), &reg->device_regs.in_endp[EP0_CON].diepctl);
 
 	/* EP0 - Control OUT (64 bytes)*/
-	ep_ctrl = readl(&reg->out_endp[EP0_CON].doepctl);
-	writel(ep_ctrl|(0<<0), &reg->out_endp[EP0_CON].doepctl);
+	ep_ctrl = readl(&reg->device_regs.out_endp[EP0_CON].doepctl);
+	writel(ep_ctrl | (0 << 0), &reg->device_regs.out_endp[EP0_CON].doepctl);
 }
 
 static int dwc2_ep_enable(struct usb_ep *_ep,
@@ -904,7 +907,7 @@ int dwc2_udc_probe(struct dwc2_plat_otg_data *pdata)
 
 	dev->pdata = pdata;
 
-	reg = (struct dwc2_usbotg_reg *)pdata->regs_otg;
+	reg = (struct dwc2_core_regs *)pdata->regs_otg;
 
 	dev->gadget.is_dualspeed = 1;	/* Hack only*/
 	dev->gadget.is_otg = 0;
@@ -932,8 +935,8 @@ int dwc2_udc_probe(struct dwc2_plat_otg_data *pdata)
 
 int dwc2_udc_handle_interrupt(void)
 {
-	u32 intr_status = readl(&reg->gintsts);
-	u32 gintmsk = readl(&reg->gintmsk);
+	u32 intr_status = readl(&reg->global_regs.gintsts);
+	u32 gintmsk = readl(&reg->global_regs.gintmsk);
 
 	if (intr_status & gintmsk)
 		return dwc2_udc_irq(1, (void *)the_controller);
@@ -1087,8 +1090,8 @@ static int dwc2_udc_otg_probe(struct udevice *dev)
 {
 	struct dwc2_plat_otg_data *plat = dev_get_plat(dev);
 	struct dwc2_priv_data *priv = dev_get_priv(dev);
-	struct dwc2_usbotg_reg *usbotg_reg =
-		(struct dwc2_usbotg_reg *)plat->regs_otg;
+	struct dwc2_core_reg *usbotg_reg =
+		(struct dwc2_core_reg *)plat->regs_otg;
 	int ret;
 
 	ret = dwc2_udc_otg_clk_init(dev, &priv->clks);
@@ -1123,21 +1126,22 @@ static int dwc2_udc_otg_probe(struct udevice *dev)
 		if (plat->force_b_session_valid &&
 		    !plat->force_vbus_detection) {
 			/* Override VBUS detection: enable then value*/
-			setbits_le32(&usbotg_reg->gotgctl, VB_VALOEN);
-			setbits_le32(&usbotg_reg->gotgctl, VB_VALOVAL);
+			setbits_le32(&usbotg_reg->global_regs.gotgctl, VB_VALOEN);
+			setbits_le32(&usbotg_reg->global_regs.gotgctl, VB_VALOVAL);
 		} else {
 			/* Enable VBUS sensing */
-			setbits_le32(&usbotg_reg->ggpio,
+			setbits_le32(&usbotg_reg->global_regs.ggpio,
 				     GGPIO_STM32_OTG_GCCFG_VBDEN);
 		}
 		if (plat->force_b_session_valid) {
 			/* Override B session bits: enable then value */
-			setbits_le32(&usbotg_reg->gotgctl, A_VALOEN | B_VALOEN);
-			setbits_le32(&usbotg_reg->gotgctl,
+			setbits_le32(&usbotg_reg->global_regs.gotgctl,
+				     A_VALOEN | B_VALOEN);
+			setbits_le32(&usbotg_reg->global_regs.gotgctl,
 				     A_VALOVAL | B_VALOVAL);
 		} else {
 			/* Enable ID detection */
-			setbits_le32(&usbotg_reg->ggpio,
+			setbits_le32(&usbotg_reg->global_regs.ggpio,
 				     GGPIO_STM32_OTG_GCCFG_IDEN);
 		}
 	}
diff --git a/drivers/usb/gadget/dwc2_udc_otg_regs.h b/drivers/usb/gadget/dwc2_udc_otg_regs.h
index 01056fab1c21a136fcf75d9b89f397df1aa869f3..198ba7a7c37d05dca084ef017534265f5fb5fd70 100644
--- a/drivers/usb/gadget/dwc2_udc_otg_regs.h
+++ b/drivers/usb/gadget/dwc2_udc_otg_regs.h
@@ -10,80 +10,14 @@
 #ifndef __ASM_ARCH_REGS_USB_OTG_HS_H
 #define __ASM_ARCH_REGS_USB_OTG_HS_H
 
-/* USB2.0 OTG Controller register */
 #include <linux/bitops.h>
+
 struct dwc2_usbotg_phy {
 	u32 phypwr;
 	u32 phyclk;
 	u32 rstcon;
 };
 
-/* Device Logical IN Endpoint-Specific Registers */
-struct dwc2_dev_in_endp {
-	u32 diepctl;
-	u8  res1[4];
-	u32 diepint;
-	u8  res2[4];
-	u32 dieptsiz;
-	u32 diepdma;
-	u8  res3[4];
-	u32 diepdmab;
-};
-
-/* Device Logical OUT Endpoint-Specific Registers */
-struct dwc2_dev_out_endp {
-	u32 doepctl;
-	u8  res1[4];
-	u32 doepint;
-	u8  res2[4];
-	u32 doeptsiz;
-	u32 doepdma;
-	u8  res3[4];
-	u32 doepdmab;
-};
-
-struct ep_fifo {
-	u32 fifo;
-	u8  res[4092];
-};
-
-/* USB2.0 OTG Controller register */
-struct dwc2_usbotg_reg {
-	/* Core Global Registers */
-	u32 gotgctl; /* OTG Control & Status */
-	u32 gotgint; /* OTG Interrupt */
-	u32 gahbcfg; /* Core AHB Configuration */
-	u32 gusbcfg; /* Core USB Configuration */
-	u32 grstctl; /* Core Reset */
-	u32 gintsts; /* Core Interrupt */
-	u32 gintmsk; /* Core Interrupt Mask */
-	u32 grxstsr; /* Receive Status Debug Read/Status Read */
-	u32 grxstsp; /* Receive Status Debug Pop/Status Pop */
-	u32 grxfsiz; /* Receive FIFO Size */
-	u32 gnptxfsiz; /* Non-Periodic Transmit FIFO Size */
-	u8  res0[12];
-	u32 ggpio;     /* 0x038 */
-	u8  res1[20];
-	u32 ghwcfg4; /* User HW Config4 */
-	u8  res2[176];
-	u32 dieptxf[15]; /* Device Periodic Transmit FIFO size register */
-	u8  res3[1728];
-	/* Device Configuration */
-	u32 dcfg; /* Device Configuration Register */
-	u32 dctl; /* Device Control */
-	u32 dsts; /* Device Status */
-	u8  res4[4];
-	u32 diepmsk; /* Device IN Endpoint Common Interrupt Mask */
-	u32 doepmsk; /* Device OUT Endpoint Common Interrupt Mask */
-	u32 daint; /* Device All Endpoints Interrupt */
-	u32 daintmsk; /* Device All Endpoints Interrupt Mask */
-	u8  res5[224];
-	struct dwc2_dev_in_endp in_endp[16];
-	struct dwc2_dev_out_endp out_endp[16];
-	u8  res6[768];
-	struct ep_fifo ep[16];
-};
-
 /*===================================================================== */
 /*definitions related to CSR setting */
 
diff --git a/drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c b/drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c
index c0408bae0768cd81fa50de946dee4aa08c1059f8..e2a24c53b4c8d632163484d52b4338820dcb1731 100644
--- a/drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c
+++ b/drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c
@@ -32,15 +32,16 @@ static inline void dwc2_udc_ep0_zlp(struct dwc2_udc *dev)
 {
 	u32 ep_ctrl;
 
-	writel(phys_to_bus((unsigned long)usb_ctrl_dma_addr), &reg->in_endp[EP0_CON].diepdma);
-	writel(DIEPT_SIZ_PKT_CNT(1), &reg->in_endp[EP0_CON].dieptsiz);
+	writel(phys_to_bus((unsigned long)usb_ctrl_dma_addr),
+	       &reg->device_regs.in_endp[EP0_CON].diepdma);
+	writel(DIEPT_SIZ_PKT_CNT(1), &reg->device_regs.in_endp[EP0_CON].dieptsiz);
 
-	ep_ctrl = readl(&reg->in_endp[EP0_CON].diepctl);
-	writel(ep_ctrl|DEPCTL_EPENA|DEPCTL_CNAK,
-	       &reg->in_endp[EP0_CON].diepctl);
+	ep_ctrl = readl(&reg->device_regs.in_endp[EP0_CON].diepctl);
+	writel(ep_ctrl | DEPCTL_EPENA | DEPCTL_CNAK,
+	       &reg->device_regs.in_endp[EP0_CON].diepctl);
 
 	debug_cond(DEBUG_EP0 != 0, "%s:EP0 ZLP DIEPCTL0 = 0x%x\n",
-		__func__, readl(&reg->in_endp[EP0_CON].diepctl));
+		__func__, readl(&reg->device_regs.in_endp[EP0_CON].diepctl));
 	dev->ep0state = WAIT_FOR_IN_COMPLETE;
 }
 
@@ -52,16 +53,17 @@ static void dwc2_udc_pre_setup(void)
 		   "%s : Prepare Setup packets.\n", __func__);
 
 	writel(DOEPT_SIZ_PKT_CNT(1) | sizeof(struct usb_ctrlrequest),
-	       &reg->out_endp[EP0_CON].doeptsiz);
-	writel(phys_to_bus((unsigned long)usb_ctrl_dma_addr), &reg->out_endp[EP0_CON].doepdma);
+	       &reg->device_regs.out_endp[EP0_CON].doeptsiz);
+	writel(phys_to_bus((unsigned long)usb_ctrl_dma_addr),
+	       &reg->device_regs.out_endp[EP0_CON].doepdma);
 
-	ep_ctrl = readl(&reg->out_endp[EP0_CON].doepctl);
-	writel(ep_ctrl|DEPCTL_EPENA, &reg->out_endp[EP0_CON].doepctl);
+	ep_ctrl = readl(&reg->device_regs.out_endp[EP0_CON].doepctl);
+	writel(ep_ctrl | DEPCTL_EPENA, &reg->device_regs.out_endp[EP0_CON].doepctl);
 
 	debug_cond(DEBUG_EP0 != 0, "%s:EP0 ZLP DIEPCTL0 = 0x%x\n",
-		__func__, readl(&reg->in_endp[EP0_CON].diepctl));
+		__func__, readl(&reg->device_regs.in_endp[EP0_CON].diepctl));
 	debug_cond(DEBUG_EP0 != 0, "%s:EP0 ZLP DOEPCTL0 = 0x%x\n",
-		__func__, readl(&reg->out_endp[EP0_CON].doepctl));
+		__func__, readl(&reg->device_regs.out_endp[EP0_CON].doepctl));
 
 }
 
@@ -70,25 +72,26 @@ static inline void dwc2_ep0_complete_out(void)
 	u32 ep_ctrl;
 
 	debug_cond(DEBUG_EP0 != 0, "%s:EP0 ZLP DIEPCTL0 = 0x%x\n",
-		__func__, readl(&reg->in_endp[EP0_CON].diepctl));
+		__func__, readl(&reg->device_regs.in_endp[EP0_CON].diepctl));
 	debug_cond(DEBUG_EP0 != 0, "%s:EP0 ZLP DOEPCTL0 = 0x%x\n",
-		__func__, readl(&reg->out_endp[EP0_CON].doepctl));
+		__func__, readl(&reg->device_regs.out_endp[EP0_CON].doepctl));
 
 	debug_cond(DEBUG_IN_EP,
 		"%s : Prepare Complete Out packet.\n", __func__);
 
 	writel(DOEPT_SIZ_PKT_CNT(1) | sizeof(struct usb_ctrlrequest),
-	       &reg->out_endp[EP0_CON].doeptsiz);
-	writel(phys_to_bus((unsigned long)usb_ctrl_dma_addr), &reg->out_endp[EP0_CON].doepdma);
+	       &reg->device_regs.out_endp[EP0_CON].doeptsiz);
+	writel(phys_to_bus((unsigned long)usb_ctrl_dma_addr),
+	       &reg->device_regs.out_endp[EP0_CON].doepdma);
 
-	ep_ctrl = readl(&reg->out_endp[EP0_CON].doepctl);
-	writel(ep_ctrl|DEPCTL_EPENA|DEPCTL_CNAK,
-	       &reg->out_endp[EP0_CON].doepctl);
+	ep_ctrl = readl(&reg->device_regs.out_endp[EP0_CON].doepctl);
+	writel(ep_ctrl | DEPCTL_EPENA | DEPCTL_CNAK,
+	       &reg->device_regs.out_endp[EP0_CON].doepctl);
 
 	debug_cond(DEBUG_EP0 != 0, "%s:EP0 ZLP DIEPCTL0 = 0x%x\n",
-		__func__, readl(&reg->in_endp[EP0_CON].diepctl));
+		__func__, readl(&reg->device_regs.in_endp[EP0_CON].diepctl));
 	debug_cond(DEBUG_EP0 != 0, "%s:EP0 ZLP DOEPCTL0 = 0x%x\n",
-		__func__, readl(&reg->out_endp[EP0_CON].doepctl));
+		__func__, readl(&reg->device_regs.out_endp[EP0_CON].doepctl));
 
 }
 
@@ -110,25 +113,25 @@ static int setdma_rx(struct dwc2_ep *ep, struct dwc2_request *req)
 	else
 		pktcnt = (length - 1)/(ep->ep.maxpacket) + 1;
 
-	ctrl =  readl(&reg->out_endp[ep_num].doepctl);
+	ctrl =  readl(&reg->device_regs.out_endp[ep_num].doepctl);
 
 	invalidate_dcache_range((unsigned long) ep->dma_buf,
 				(unsigned long) ep->dma_buf +
 				ROUND(ep->len, CONFIG_SYS_CACHELINE_SIZE));
 
-	writel(phys_to_bus((unsigned long)ep->dma_buf), &reg->out_endp[ep_num].doepdma);
+	writel(phys_to_bus((unsigned long)ep->dma_buf), &reg->device_regs.out_endp[ep_num].doepdma);
 	writel(DOEPT_SIZ_PKT_CNT(pktcnt) | DOEPT_SIZ_XFER_SIZE(length),
-	       &reg->out_endp[ep_num].doeptsiz);
-	writel(DEPCTL_EPENA|DEPCTL_CNAK|ctrl, &reg->out_endp[ep_num].doepctl);
+	       &reg->device_regs.out_endp[ep_num].doeptsiz);
+	writel(DEPCTL_EPENA | DEPCTL_CNAK | ctrl, &reg->device_regs.out_endp[ep_num].doepctl);
 
 	debug_cond(DEBUG_OUT_EP != 0,
 		   "%s: EP%d RX DMA start : DOEPDMA = 0x%x,"
 		   "DOEPTSIZ = 0x%x, DOEPCTL = 0x%x\n"
 		   "\tbuf = 0x%p, pktcnt = %d, xfersize = %d\n",
 		   __func__, ep_num,
-		   readl(&reg->out_endp[ep_num].doepdma),
-		   readl(&reg->out_endp[ep_num].doeptsiz),
-		   readl(&reg->out_endp[ep_num].doepctl),
+		   readl(&reg->device_regs.out_endp[ep_num].doepdma),
+		   readl(&reg->device_regs.out_endp[ep_num].doeptsiz),
+		   readl(&reg->device_regs.out_endp[ep_num].doepctl),
 		   buf, pktcnt, length);
 	return 0;
 
@@ -159,16 +162,16 @@ static int setdma_tx(struct dwc2_ep *ep, struct dwc2_request *req)
 		pktcnt = (length - 1)/(ep->ep.maxpacket) + 1;
 
 	/* Flush the endpoint's Tx FIFO */
-	writel(TX_FIFO_NUMBER(ep->fifo_num), &reg->grstctl);
-	writel(TX_FIFO_NUMBER(ep->fifo_num) | TX_FIFO_FLUSH, &reg->grstctl);
-	while (readl(&reg->grstctl) & TX_FIFO_FLUSH)
+	writel(TX_FIFO_NUMBER(ep->fifo_num), &reg->global_regs.grstctl);
+	writel(TX_FIFO_NUMBER(ep->fifo_num) | TX_FIFO_FLUSH, &reg->global_regs.grstctl);
+	while (readl(&reg->global_regs.grstctl) & TX_FIFO_FLUSH)
 		;
 
-	writel(phys_to_bus((unsigned long)ep->dma_buf), &reg->in_endp[ep_num].diepdma);
+	writel(phys_to_bus((unsigned long)ep->dma_buf), &reg->device_regs.in_endp[ep_num].diepdma);
 	writel(DIEPT_SIZ_PKT_CNT(pktcnt) | DIEPT_SIZ_XFER_SIZE(length),
-	       &reg->in_endp[ep_num].dieptsiz);
+	       &reg->device_regs.in_endp[ep_num].dieptsiz);
 
-	ctrl = readl(&reg->in_endp[ep_num].diepctl);
+	ctrl = readl(&reg->device_regs.in_endp[ep_num].diepctl);
 
 	/* Write the FIFO number to be used for this endpoint */
 	ctrl &= DIEPCTL_TX_FIFO_NUM_MASK;
@@ -177,16 +180,16 @@ static int setdma_tx(struct dwc2_ep *ep, struct dwc2_request *req)
 	/* Clear reserved (Next EP) bits */
 	ctrl = (ctrl&~(EP_MASK<<DEPCTL_NEXT_EP_BIT));
 
-	writel(DEPCTL_EPENA|DEPCTL_CNAK|ctrl, &reg->in_endp[ep_num].diepctl);
+	writel(DEPCTL_EPENA|DEPCTL_CNAK|ctrl, &reg->device_regs.in_endp[ep_num].diepctl);
 
 	debug_cond(DEBUG_IN_EP,
 		"%s:EP%d TX DMA start : DIEPDMA0 = 0x%x,"
 		"DIEPTSIZ0 = 0x%x, DIEPCTL0 = 0x%x\n"
 		"\tbuf = 0x%p, pktcnt = %d, xfersize = %d\n",
 		__func__, ep_num,
-		readl(&reg->in_endp[ep_num].diepdma),
-		readl(&reg->in_endp[ep_num].dieptsiz),
-		readl(&reg->in_endp[ep_num].diepctl),
+		readl(&reg->device_regs.in_endp[ep_num].diepdma),
+		readl(&reg->device_regs.in_endp[ep_num].dieptsiz),
+		readl(&reg->device_regs.in_endp[ep_num].diepctl),
 		buf, pktcnt, length);
 
 	return length;
@@ -207,7 +210,7 @@ static void complete_rx(struct dwc2_udc *dev, u8 ep_num)
 	}
 
 	req = list_entry(ep->queue.next, struct dwc2_request, queue);
-	ep_tsr = readl(&reg->out_endp[ep_num].doeptsiz);
+	ep_tsr = readl(&reg->device_regs.out_endp[ep_num].doeptsiz);
 
 	if (ep_num == EP0_CON)
 		xfer_size = (ep_tsr & DOEPT_SIZ_XFER_SIZE_MAX_EP0);
@@ -288,7 +291,7 @@ static void complete_tx(struct dwc2_udc *dev, u8 ep_num)
 
 	req = list_entry(ep->queue.next, struct dwc2_request, queue);
 
-	ep_tsr = readl(&reg->in_endp[ep_num].dieptsiz);
+	ep_tsr = readl(&reg->device_regs.in_endp[ep_num].dieptsiz);
 
 	xfer_size = ep->len;
 	is_short = (xfer_size < ep->ep.maxpacket);
@@ -373,7 +376,7 @@ static void process_ep_in_intr(struct dwc2_udc *dev)
 	u32 ep_intr, ep_intr_status;
 	u8 ep_num = 0;
 
-	ep_intr = readl(&reg->daint);
+	ep_intr = readl(&reg->device_regs.daint);
 	debug_cond(DEBUG_IN_EP,
 		"*** %s: EP In interrupt : DAINT = 0x%x\n", __func__, ep_intr);
 
@@ -381,13 +384,13 @@ static void process_ep_in_intr(struct dwc2_udc *dev)
 
 	while (ep_intr) {
 		if (ep_intr & DAINT_IN_EP_INT(1)) {
-			ep_intr_status = readl(&reg->in_endp[ep_num].diepint);
+			ep_intr_status = readl(&reg->device_regs.in_endp[ep_num].diepint);
 			debug_cond(DEBUG_IN_EP,
 				   "\tEP%d-IN : DIEPINT = 0x%x\n",
 				   ep_num, ep_intr_status);
 
 			/* Interrupt Clear */
-			writel(ep_intr_status, &reg->in_endp[ep_num].diepint);
+			writel(ep_intr_status, &reg->device_regs.in_endp[ep_num].diepint);
 
 			if (ep_intr_status & TRANSFER_DONE) {
 				complete_tx(dev, ep_num);
@@ -420,10 +423,10 @@ static void process_ep_out_intr(struct dwc2_udc *dev)
 	u32 ep_intr, ep_intr_status;
 	u8 ep_num = 0;
 	u32 ep_tsr = 0, xfer_size = 0;
-	u32 epsiz_reg = reg->out_endp[ep_num].doeptsiz;
+	u32 epsiz_reg = reg->device_regs.out_endp[ep_num].doeptsiz;
 	u32 req_size = sizeof(struct usb_ctrlrequest);
 
-	ep_intr = readl(&reg->daint);
+	ep_intr = readl(&reg->device_regs.daint);
 	debug_cond(DEBUG_OUT_EP != 0,
 		   "*** %s: EP OUT interrupt : DAINT = 0x%x\n",
 		   __func__, ep_intr);
@@ -432,13 +435,13 @@ static void process_ep_out_intr(struct dwc2_udc *dev)
 
 	while (ep_intr) {
 		if (ep_intr & 0x1) {
-			ep_intr_status = readl(&reg->out_endp[ep_num].doepint);
+			ep_intr_status = readl(&reg->device_regs.out_endp[ep_num].doepint);
 			debug_cond(DEBUG_OUT_EP != 0,
 				   "\tEP%d-OUT : DOEPINT = 0x%x\n",
 				   ep_num, ep_intr_status);
 
 			/* Interrupt Clear */
-			writel(ep_intr_status, &reg->out_endp[ep_num].doepint);
+			writel(ep_intr_status, &reg->device_regs.out_endp[ep_num].doepint);
 
 			if (ep_num == 0) {
 				if (ep_intr_status & TRANSFER_DONE) {
@@ -486,14 +489,14 @@ static int dwc2_udc_irq(int irq, void *_dev)
 
 	spin_lock_irqsave(&dev->lock, flags);
 
-	intr_status = readl(&reg->gintsts);
-	gintmsk = readl(&reg->gintmsk);
+	intr_status = readl(&reg->global_regs.gintsts);
+	gintmsk = readl(&reg->global_regs.gintmsk);
 
 	debug_cond(DEBUG_ISR,
 		  "\n*** %s : GINTSTS=0x%x(on state %s), GINTMSK : 0x%x,"
 		  "DAINT : 0x%x, DAINTMSK : 0x%x\n",
 		  __func__, intr_status, state_names[dev->ep0state], gintmsk,
-		  readl(&reg->daint), readl(&reg->daintmsk));
+		  readl(&reg->device_regs.daint), readl(&reg->device_regs.daintmsk));
 
 	if (!intr_status) {
 		spin_unlock_irqrestore(&dev->lock, flags);
@@ -503,8 +506,8 @@ static int dwc2_udc_irq(int irq, void *_dev)
 	if (intr_status & INT_ENUMDONE) {
 		debug_cond(DEBUG_ISR, "\tSpeed Detection interrupt\n");
 
-		writel(INT_ENUMDONE, &reg->gintsts);
-		usb_status = (readl(&reg->dsts) & 0x6);
+		writel(INT_ENUMDONE, &reg->global_regs.gintsts);
+		usb_status = (readl(&reg->device_regs.dsts) & 0x6);
 
 		if (usb_status & (USB_FULL_30_60MHZ | USB_FULL_48MHZ)) {
 			debug_cond(DEBUG_ISR,
@@ -521,14 +524,14 @@ static int dwc2_udc_irq(int irq, void *_dev)
 
 	if (intr_status & INT_EARLY_SUSPEND) {
 		debug_cond(DEBUG_ISR, "\tEarly suspend interrupt\n");
-		writel(INT_EARLY_SUSPEND, &reg->gintsts);
+		writel(INT_EARLY_SUSPEND, &reg->global_regs.gintsts);
 	}
 
 	if (intr_status & INT_SUSPEND) {
-		usb_status = readl(&reg->dsts);
+		usb_status = readl(&reg->device_regs.dsts);
 		debug_cond(DEBUG_ISR,
 			"\tSuspend interrupt :(DSTS):0x%x\n", usb_status);
-		writel(INT_SUSPEND, &reg->gintsts);
+		writel(INT_SUSPEND, &reg->global_regs.gintsts);
 
 		if (dev->gadget.speed != USB_SPEED_UNKNOWN
 		    && dev->driver) {
@@ -538,7 +541,7 @@ static int dwc2_udc_irq(int irq, void *_dev)
 	}
 
 	if (intr_status & INT_OTG) {
-		gotgint = readl(&reg->gotgint);
+		gotgint = readl(&reg->global_regs.gotgint);
 		debug_cond(DEBUG_ISR,
 			   "\tOTG interrupt: (GOTGINT):0x%x\n", gotgint);
 
@@ -551,12 +554,12 @@ static int dwc2_udc_irq(int irq, void *_dev)
 				spin_lock_irqsave(&dev->lock, flags);
 			}
 		}
-		writel(gotgint, &reg->gotgint);
+		writel(gotgint, &reg->global_regs.gotgint);
 	}
 
 	if (intr_status & INT_RESUME) {
 		debug_cond(DEBUG_ISR, "\tResume interrupt\n");
-		writel(INT_RESUME, &reg->gintsts);
+		writel(INT_RESUME, &reg->global_regs.gintsts);
 
 		if (dev->gadget.speed != USB_SPEED_UNKNOWN
 		    && dev->driver
@@ -567,10 +570,10 @@ static int dwc2_udc_irq(int irq, void *_dev)
 	}
 
 	if (intr_status & INT_RESET) {
-		usb_status = readl(&reg->gotgctl);
+		usb_status = readl(&reg->global_regs.gotgctl);
 		debug_cond(DEBUG_ISR,
 			"\tReset interrupt - (GOTGCTL):0x%x\n", usb_status);
-		writel(INT_RESET, &reg->gintsts);
+		writel(INT_RESET, &reg->global_regs.gintsts);
 
 		if ((usb_status & 0xc0000) == (0x3 << 18)) {
 			if (reset_available) {
@@ -676,14 +679,14 @@ static int dwc2_queue(struct usb_ep *_ep, struct usb_request *_req,
 			req = 0;
 
 		} else if (ep_is_in(ep)) {
-			gintsts = readl(&reg->gintsts);
+			gintsts = readl(&reg->global_regs.gintsts);
 			debug_cond(DEBUG_IN_EP,
 				   "%s: ep_is_in, DWC2_UDC_OTG_GINTSTS=0x%x\n",
 				   __func__, gintsts);
 
 			setdma_tx(ep, req);
 		} else {
-			gintsts = readl(&reg->gintsts);
+			gintsts = readl(&reg->global_regs.gintsts);
 			debug_cond(DEBUG_OUT_EP != 0,
 				   "%s:ep_is_out, DWC2_UDC_OTG_GINTSTS=0x%x\n",
 				   __func__, gintsts);
@@ -765,14 +768,14 @@ static int dwc2_fifo_read(struct dwc2_ep *ep, void *cp, int max)
  */
 static void udc_set_address(struct dwc2_udc *dev, unsigned char address)
 {
-	u32 ctrl = readl(&reg->dcfg);
-	writel(DEVICE_ADDRESS(address) | ctrl, &reg->dcfg);
+	u32 ctrl = readl(&reg->device_regs.dcfg);
+	writel(DEVICE_ADDRESS(address) | ctrl, &reg->device_regs.dcfg);
 
 	dwc2_udc_ep0_zlp(dev);
 
 	debug_cond(DEBUG_EP0 != 0,
 		   "%s: USB OTG 2.0 Device address=%d, DCFG=0x%x\n",
-		   __func__, address, readl(&reg->dcfg));
+		   __func__, address, readl(&reg->device_regs.dcfg));
 
 	dev->usb_address = address;
 }
@@ -783,7 +786,7 @@ static inline void dwc2_udc_ep0_set_stall(struct dwc2_ep *ep)
 	u32		ep_ctrl = 0;
 
 	dev = ep->dev;
-	ep_ctrl = readl(&reg->in_endp[EP0_CON].diepctl);
+	ep_ctrl = readl(&reg->device_regs.in_endp[EP0_CON].diepctl);
 
 	/* set the disable and stall bits */
 	if (ep_ctrl & DEPCTL_EPENA)
@@ -791,11 +794,11 @@ static inline void dwc2_udc_ep0_set_stall(struct dwc2_ep *ep)
 
 	ep_ctrl |= DEPCTL_STALL;
 
-	writel(ep_ctrl, &reg->in_endp[EP0_CON].diepctl);
+	writel(ep_ctrl, &reg->device_regs.in_endp[EP0_CON].diepctl);
 
 	debug_cond(DEBUG_EP0 != 0,
 		   "%s: set ep%d stall, DIEPCTL0 = 0x%p\n",
-		   __func__, ep_index(ep), &reg->in_endp[EP0_CON].diepctl);
+		   __func__, ep_index(ep), &reg->device_regs.in_endp[EP0_CON].diepctl);
 	/*
 	 * The application can only set this bit, and the core clears it,
 	 * when a SETUP token is received for this endpoint
@@ -934,13 +937,13 @@ static int dwc2_udc_get_status(struct dwc2_udc *dev,
 			   (unsigned long) usb_ctrl +
 			   ROUND(sizeof(g_status), CONFIG_SYS_CACHELINE_SIZE));
 
-	writel(phys_to_bus(usb_ctrl_dma_addr), &reg->in_endp[EP0_CON].diepdma);
+	writel(phys_to_bus(usb_ctrl_dma_addr), &reg->device_regs.in_endp[EP0_CON].diepdma);
 	writel(DIEPT_SIZ_PKT_CNT(1) | DIEPT_SIZ_XFER_SIZE(2),
-	       &reg->in_endp[EP0_CON].dieptsiz);
+	       &reg->device_regs.in_endp[EP0_CON].dieptsiz);
 
-	ep_ctrl = readl(&reg->in_endp[EP0_CON].diepctl);
-	writel(ep_ctrl|DEPCTL_EPENA|DEPCTL_CNAK,
-	       &reg->in_endp[EP0_CON].diepctl);
+	ep_ctrl = readl(&reg->device_regs.in_endp[EP0_CON].diepctl);
+	writel(ep_ctrl | DEPCTL_EPENA | DEPCTL_CNAK,
+	       &reg->device_regs.in_endp[EP0_CON].diepctl);
 	dev->ep0state = WAIT_FOR_NULL_COMPLETE;
 
 	return 0;
@@ -955,17 +958,17 @@ static void dwc2_udc_set_nak(struct dwc2_ep *ep)
 	debug("%s: ep_num = %d, ep_type = %d\n", __func__, ep_num, ep->ep_type);
 
 	if (ep_is_in(ep)) {
-		ep_ctrl = readl(&reg->in_endp[ep_num].diepctl);
+		ep_ctrl = readl(&reg->device_regs.in_endp[ep_num].diepctl);
 		ep_ctrl |= DEPCTL_SNAK;
-		writel(ep_ctrl, &reg->in_endp[ep_num].diepctl);
+		writel(ep_ctrl, &reg->device_regs.in_endp[ep_num].diepctl);
 		debug("%s: set NAK, DIEPCTL%d = 0x%x\n",
-			__func__, ep_num, readl(&reg->in_endp[ep_num].diepctl));
+			__func__, ep_num, readl(&reg->device_regs.in_endp[ep_num].diepctl));
 	} else {
-		ep_ctrl = readl(&reg->out_endp[ep_num].doepctl);
+		ep_ctrl = readl(&reg->device_regs.out_endp[ep_num].doepctl);
 		ep_ctrl |= DEPCTL_SNAK;
-		writel(ep_ctrl, &reg->out_endp[ep_num].doepctl);
+		writel(ep_ctrl, &reg->device_regs.out_endp[ep_num].doepctl);
 		debug("%s: set NAK, DOEPCTL%d = 0x%x\n",
-		      __func__, ep_num, readl(&reg->out_endp[ep_num].doepctl));
+		      __func__, ep_num, readl(&reg->device_regs.out_endp[ep_num].doepctl));
 	}
 
 	return;
@@ -980,7 +983,7 @@ static void dwc2_udc_ep_set_stall(struct dwc2_ep *ep)
 	debug("%s: ep_num = %d, ep_type = %d\n", __func__, ep_num, ep->ep_type);
 
 	if (ep_is_in(ep)) {
-		ep_ctrl = readl(&reg->in_endp[ep_num].diepctl);
+		ep_ctrl = readl(&reg->device_regs.in_endp[ep_num].diepctl);
 
 		/* set the disable and stall bits */
 		if (ep_ctrl & DEPCTL_EPENA)
@@ -988,19 +991,19 @@ static void dwc2_udc_ep_set_stall(struct dwc2_ep *ep)
 
 		ep_ctrl |= DEPCTL_STALL;
 
-		writel(ep_ctrl, &reg->in_endp[ep_num].diepctl);
+		writel(ep_ctrl, &reg->device_regs.in_endp[ep_num].diepctl);
 		debug("%s: set stall, DIEPCTL%d = 0x%x\n",
-		      __func__, ep_num, readl(&reg->in_endp[ep_num].diepctl));
+		      __func__, ep_num, readl(&reg->device_regs.in_endp[ep_num].diepctl));
 
 	} else {
-		ep_ctrl = readl(&reg->out_endp[ep_num].doepctl);
+		ep_ctrl = readl(&reg->device_regs.out_endp[ep_num].doepctl);
 
 		/* set the stall bit */
 		ep_ctrl |= DEPCTL_STALL;
 
-		writel(ep_ctrl, &reg->out_endp[ep_num].doepctl);
+		writel(ep_ctrl, &reg->device_regs.out_endp[ep_num].doepctl);
 		debug("%s: set stall, DOEPCTL%d = 0x%x\n",
-		      __func__, ep_num, readl(&reg->out_endp[ep_num].doepctl));
+		      __func__, ep_num, readl(&reg->device_regs.out_endp[ep_num].doepctl));
 	}
 
 	return;
@@ -1015,7 +1018,7 @@ static void dwc2_udc_ep_clear_stall(struct dwc2_ep *ep)
 	debug("%s: ep_num = %d, ep_type = %d\n", __func__, ep_num, ep->ep_type);
 
 	if (ep_is_in(ep)) {
-		ep_ctrl = readl(&reg->in_endp[ep_num].diepctl);
+		ep_ctrl = readl(&reg->device_regs.in_endp[ep_num].diepctl);
 
 		/* clear stall bit */
 		ep_ctrl &= ~DEPCTL_STALL;
@@ -1031,12 +1034,12 @@ static void dwc2_udc_ep_clear_stall(struct dwc2_ep *ep)
 			ep_ctrl |= DEPCTL_SETD0PID; /* DATA0 */
 		}
 
-		writel(ep_ctrl, &reg->in_endp[ep_num].diepctl);
+		writel(ep_ctrl, &reg->device_regs.in_endp[ep_num].diepctl);
 		debug("%s: cleared stall, DIEPCTL%d = 0x%x\n",
-			__func__, ep_num, readl(&reg->in_endp[ep_num].diepctl));
+			__func__, ep_num, readl(&reg->device_regs.in_endp[ep_num].diepctl));
 
 	} else {
-		ep_ctrl = readl(&reg->out_endp[ep_num].doepctl);
+		ep_ctrl = readl(&reg->device_regs.out_endp[ep_num].doepctl);
 
 		/* clear stall bit */
 		ep_ctrl &= ~DEPCTL_STALL;
@@ -1046,9 +1049,9 @@ static void dwc2_udc_ep_clear_stall(struct dwc2_ep *ep)
 			ep_ctrl |= DEPCTL_SETD0PID; /* DATA0 */
 		}
 
-		writel(ep_ctrl, &reg->out_endp[ep_num].doepctl);
+		writel(ep_ctrl, &reg->device_regs.out_endp[ep_num].doepctl);
 		debug("%s: cleared stall, DOEPCTL%d = 0x%x\n",
-		      __func__, ep_num, readl(&reg->out_endp[ep_num].doepctl));
+		      __func__, ep_num, readl(&reg->device_regs.out_endp[ep_num].doepctl));
 	}
 
 	return;
@@ -1110,10 +1113,10 @@ static void dwc2_udc_ep_activate(struct dwc2_ep *ep)
 
 	/* Read DEPCTLn register */
 	if (ep_is_in(ep)) {
-		ep_ctrl = readl(&reg->in_endp[ep_num].diepctl);
+		ep_ctrl = readl(&reg->device_regs.in_endp[ep_num].diepctl);
 		daintmsk = 1 << ep_num;
 	} else {
-		ep_ctrl = readl(&reg->out_endp[ep_num].doepctl);
+		ep_ctrl = readl(&reg->device_regs.out_endp[ep_num].doepctl);
 		daintmsk = (1 << ep_num) << DAINT_OUT_BIT;
 	}
 
@@ -1130,21 +1133,21 @@ static void dwc2_udc_ep_activate(struct dwc2_ep *ep)
 		ep_ctrl |= (DEPCTL_SETD0PID | DEPCTL_USBACTEP | DEPCTL_SNAK);
 
 		if (ep_is_in(ep)) {
-			writel(ep_ctrl, &reg->in_endp[ep_num].diepctl);
+			writel(ep_ctrl, &reg->device_regs.in_endp[ep_num].diepctl);
 			debug("%s: USB Ative EP%d, DIEPCTRL%d = 0x%x\n",
 			      __func__, ep_num, ep_num,
-			      readl(&reg->in_endp[ep_num].diepctl));
+			      readl(&reg->device_regs.in_endp[ep_num].diepctl));
 		} else {
-			writel(ep_ctrl, &reg->out_endp[ep_num].doepctl);
+			writel(ep_ctrl, &reg->device_regs.out_endp[ep_num].doepctl);
 			debug("%s: USB Ative EP%d, DOEPCTRL%d = 0x%x\n",
 			      __func__, ep_num, ep_num,
-			      readl(&reg->out_endp[ep_num].doepctl));
+			      readl(&reg->device_regs.out_endp[ep_num].doepctl));
 		}
 	}
 
 	/* Unmask EP Interrtupt */
-	writel(readl(&reg->daintmsk)|daintmsk, &reg->daintmsk);
-	debug("%s: DAINTMSK = 0x%x\n", __func__, readl(&reg->daintmsk));
+	writel(readl(&reg->device_regs.daintmsk) | daintmsk, &reg->device_regs.daintmsk);
+	debug("%s: DAINTMSK = 0x%x\n", __func__, readl(&reg->device_regs.daintmsk));
 
 }
 
diff --git a/drivers/usb/host/dwc2.c b/drivers/usb/host/dwc2.c
index a9dbb85f4e6c5a9122108eb64f77e99758b840e8..b6c8b3d5a6bdf375f1adeb106d4832d92307f0db 100644
--- a/drivers/usb/host/dwc2.c
+++ b/drivers/usb/host/dwc2.c
@@ -24,6 +24,7 @@
 #include <power/regulator.h>
 #include <reset.h>
 
+#include "../common/dwc2_core.h"
 #include "dwc2.h"
 
 /* Use only HC channel 0. */
@@ -93,7 +94,7 @@ static void init_fslspclksel(struct dwc2_core_regs *regs)
 #endif
 
 #ifdef DWC2_ULPI_FS_LS
-	uint32_t hwcfg2 = readl(&regs->ghwcfg2);
+	uint32_t hwcfg2 = readl(&regs->global_regs.ghwcfg2);
 	uint32_t hval = (ghwcfg2 & DWC2_HWCFG2_HS_PHY_TYPE_MASK) >>
 			DWC2_HWCFG2_HS_PHY_TYPE_OFFSET;
 	uint32_t fval = (ghwcfg2 & DWC2_HWCFG2_FS_PHY_TYPE_MASK) >>
@@ -120,8 +121,8 @@ static void dwc_otg_flush_tx_fifo(struct udevice *dev,
 	int ret;
 
 	writel(DWC2_GRSTCTL_TXFFLSH | (num << DWC2_GRSTCTL_TXFNUM_OFFSET),
-	       &regs->grstctl);
-	ret = wait_for_bit_le32(&regs->grstctl, DWC2_GRSTCTL_TXFFLSH,
+	       &regs->global_regs.grstctl);
+	ret = wait_for_bit_le32(&regs->global_regs.grstctl, DWC2_GRSTCTL_TXFFLSH,
 				false, 1000, false);
 	if (ret)
 		dev_info(dev, "%s: Timeout!\n", __func__);
@@ -140,8 +141,8 @@ static void dwc_otg_flush_rx_fifo(struct udevice *dev,
 {
 	int ret;
 
-	writel(DWC2_GRSTCTL_RXFFLSH, &regs->grstctl);
-	ret = wait_for_bit_le32(&regs->grstctl, DWC2_GRSTCTL_RXFFLSH,
+	writel(DWC2_GRSTCTL_RXFFLSH, &regs->global_regs.grstctl);
+	ret = wait_for_bit_le32(&regs->global_regs.grstctl, DWC2_GRSTCTL_RXFFLSH,
 				false, 1000, false);
 	if (ret)
 		dev_info(dev, "%s: Timeout!\n", __func__);
@@ -160,14 +161,14 @@ static void dwc_otg_core_reset(struct udevice *dev,
 	int ret;
 
 	/* Wait for AHB master IDLE state. */
-	ret = wait_for_bit_le32(&regs->grstctl, DWC2_GRSTCTL_AHBIDLE,
+	ret = wait_for_bit_le32(&regs->global_regs.grstctl, DWC2_GRSTCTL_AHBIDLE,
 				true, 1000, false);
 	if (ret)
 		dev_info(dev, "%s: Timeout!\n", __func__);
 
 	/* Core Soft Reset */
-	writel(DWC2_GRSTCTL_CSFTRST, &regs->grstctl);
-	ret = wait_for_bit_le32(&regs->grstctl, DWC2_GRSTCTL_CSFTRST,
+	writel(DWC2_GRSTCTL_CSFTRST, &regs->global_regs.grstctl);
+	ret = wait_for_bit_le32(&regs->global_regs.grstctl, DWC2_GRSTCTL_CSFTRST,
 				false, 1000, false);
 	if (ret)
 		dev_info(dev, "%s: Timeout!\n", __func__);
@@ -260,16 +261,16 @@ static void dwc_otg_core_host_init(struct udevice *dev,
 
 	/* Configure data FIFO sizes */
 #ifdef DWC2_ENABLE_DYNAMIC_FIFO
-	if (readl(&regs->ghwcfg2) & DWC2_HWCFG2_DYNAMIC_FIFO) {
+	if (readl(&regs->global_regs.ghwcfg2) & DWC2_HWCFG2_DYNAMIC_FIFO) {
 		/* Rx FIFO */
-		writel(DWC2_HOST_RX_FIFO_SIZE, &regs->grxfsiz);
+		writel(DWC2_HOST_RX_FIFO_SIZE, &regs->global_regs.grxfsiz);
 
 		/* Non-periodic Tx FIFO */
 		nptxfifosize |= DWC2_HOST_NPERIO_TX_FIFO_SIZE <<
 				DWC2_FIFOSIZE_DEPTH_OFFSET;
 		nptxfifosize |= DWC2_HOST_RX_FIFO_SIZE <<
 				DWC2_FIFOSIZE_STARTADDR_OFFSET;
-		writel(nptxfifosize, &regs->gnptxfsiz);
+		writel(nptxfifosize, &regs->global_regs.gnptxfsiz);
 
 		/* Periodic Tx FIFO */
 		ptxfifosize |= DWC2_HOST_PERIO_TX_FIFO_SIZE <<
@@ -277,45 +278,45 @@ static void dwc_otg_core_host_init(struct udevice *dev,
 		ptxfifosize |= (DWC2_HOST_RX_FIFO_SIZE +
 				DWC2_HOST_NPERIO_TX_FIFO_SIZE) <<
 				DWC2_FIFOSIZE_STARTADDR_OFFSET;
-		writel(ptxfifosize, &regs->hptxfsiz);
+		writel(ptxfifosize, &regs->global_regs.hptxfsiz);
 	}
 #endif
 
 	/* Clear Host Set HNP Enable in the OTG Control Register */
-	clrbits_le32(&regs->gotgctl, DWC2_GOTGCTL_HSTSETHNPEN);
+	clrbits_le32(&regs->global_regs.gotgctl, DWC2_GOTGCTL_HSTSETHNPEN);
 
 	/* Make sure the FIFOs are flushed. */
 	dwc_otg_flush_tx_fifo(dev, regs, 0x10);	/* All Tx FIFOs */
 	dwc_otg_flush_rx_fifo(dev, regs);
 
 	/* Flush out any leftover queued requests. */
-	num_channels = readl(&regs->ghwcfg2);
+	num_channels = readl(&regs->global_regs.ghwcfg2);
 	num_channels &= DWC2_HWCFG2_NUM_HOST_CHAN_MASK;
 	num_channels >>= DWC2_HWCFG2_NUM_HOST_CHAN_OFFSET;
 	num_channels += 1;
 
 	for (i = 0; i < num_channels; i++)
-		clrsetbits_le32(&regs->hc_regs[i].hcchar,
+		clrsetbits_le32(&regs->host_regs.hc[i].hcchar,
 				DWC2_HCCHAR_CHEN | DWC2_HCCHAR_EPDIR,
 				DWC2_HCCHAR_CHDIS);
 
 	/* Halt all channels to put them into a known state. */
 	for (i = 0; i < num_channels; i++) {
-		clrsetbits_le32(&regs->hc_regs[i].hcchar,
+		clrsetbits_le32(&regs->host_regs.hc[i].hcchar,
 				DWC2_HCCHAR_EPDIR,
 				DWC2_HCCHAR_CHEN | DWC2_HCCHAR_CHDIS);
-		ret = wait_for_bit_le32(&regs->hc_regs[i].hcchar,
+		ret = wait_for_bit_le32(&regs->host_regs.hc[i].hcchar,
 					DWC2_HCCHAR_CHEN, false, 1000, false);
 		if (ret)
 			dev_info(dev, "%s: Timeout!\n", __func__);
 	}
 
 	/* Turn on the vbus power. */
-	if (readl(&regs->gintsts) & DWC2_GINTSTS_CURMODE_HOST) {
-		hprt0 = readl(&regs->hprt0) & ~DWC2_HPRT0_W1C_MASK;
+	if (readl(&regs->global_regs.gintsts) & DWC2_GINTSTS_CURMODE_HOST) {
+		hprt0 = readl(&regs->host_regs.hprt0) & ~DWC2_HPRT0_W1C_MASK;
 		if (!(hprt0 & DWC2_HPRT0_PRTPWR)) {
 			hprt0 |= DWC2_HPRT0_PRTPWR;
-			writel(hprt0, &regs->hprt0);
+			writel(hprt0, &regs->host_regs.hprt0);
 		}
 	}
 
@@ -338,7 +339,7 @@ static void dwc_otg_core_init(struct udevice *dev)
 	uint8_t brst_sz = DWC2_DMA_BURST_SIZE;
 
 	/* Common Initialization */
-	usbcfg = readl(&regs->gusbcfg);
+	usbcfg = readl(&regs->global_regs.gusbcfg);
 
 	/* Program the ULPI External VBUS bit if needed */
 	if (priv->ext_vbus) {
@@ -357,7 +358,7 @@ static void dwc_otg_core_init(struct udevice *dev)
 #else
 	usbcfg &= ~DWC2_GUSBCFG_TERM_SEL_DL_PULSE;
 #endif
-	writel(usbcfg, &regs->gusbcfg);
+	writel(usbcfg, &regs->global_regs.gusbcfg);
 
 	/* Reset the Controller */
 	dwc_otg_core_reset(dev, regs);
@@ -369,28 +370,28 @@ static void dwc_otg_core_init(struct udevice *dev)
 #if defined(DWC2_DFLT_SPEED_FULL) && \
 	(DWC2_PHY_TYPE == DWC2_PHY_TYPE_FS)
 	/* If FS mode with FS PHY */
-	setbits_le32(&regs->gusbcfg, DWC2_GUSBCFG_PHYSEL);
+	setbits_le32(&regs->global_regs.gusbcfg, DWC2_GUSBCFG_PHYSEL);
 
 	/* Reset after a PHY select */
-	dwc_otg_core_reset(dev, regs);
+	dwc2_core_reset(regs);
 
 	/*
 	 * Program DCFG.DevSpd or HCFG.FSLSPclkSel to 48Mhz in FS.
 	 * Also do this on HNP Dev/Host mode switches (done in dev_init
 	 * and host_init).
 	 */
-	if (readl(&regs->gintsts) & DWC2_GINTSTS_CURMODE_HOST)
+	if (readl(&regs->global_regs.gintsts) & DWC2_GINTSTS_CURMODE_HOST)
 		init_fslspclksel(regs);
 
 #ifdef DWC2_I2C_ENABLE
 	/* Program GUSBCFG.OtgUtmifsSel to I2C */
-	setbits_le32(&regs->gusbcfg, DWC2_GUSBCFG_OTGUTMIFSSEL);
+	setbits_le32(&regs->global_regs.gusbcfg, DWC2_GUSBCFG_OTGUTMIFSSEL);
 
 	/* Program GI2CCTL.I2CEn */
-	clrsetbits_le32(&regs->gi2cctl, DWC2_GI2CCTL_I2CEN |
+	clrsetbits_le32(&regs->global_regs.gi2cctl, DWC2_GI2CCTL_I2CEN |
 			DWC2_GI2CCTL_I2CDEVADDR_MASK,
 			1 << DWC2_GI2CCTL_I2CDEVADDR_OFFSET);
-	setbits_le32(&regs->gi2cctl, DWC2_GI2CCTL_I2CEN);
+	setbits_le32(&regs->global_regs.gi2cctl, DWC2_GI2CCTL_I2CEN);
 #endif
 
 #else
@@ -416,16 +417,16 @@ static void dwc_otg_core_init(struct udevice *dev)
 #endif
 	}
 
-	writel(usbcfg, &regs->gusbcfg);
+	writel(usbcfg, &regs->global_regs.gusbcfg);
 
 	/* Reset after setting the PHY parameters */
 	dwc_otg_core_reset(dev, regs);
 #endif
 
-	usbcfg = readl(&regs->gusbcfg);
+	usbcfg = readl(&regs->global_regs.gusbcfg);
 	usbcfg &= ~(DWC2_GUSBCFG_ULPI_FSLS | DWC2_GUSBCFG_ULPI_CLK_SUS_M);
 #ifdef DWC2_ULPI_FS_LS
-	uint32_t hwcfg2 = readl(&regs->ghwcfg2);
+	uint32_t hwcfg2 = readl(&regs->global_regs.ghwcfg2);
 	uint32_t hval = (ghwcfg2 & DWC2_HWCFG2_HS_PHY_TYPE_MASK) >>
 			DWC2_HWCFG2_HS_PHY_TYPE_OFFSET;
 	uint32_t fval = (ghwcfg2 & DWC2_HWCFG2_FS_PHY_TYPE_MASK) >>
@@ -438,10 +439,10 @@ static void dwc_otg_core_init(struct udevice *dev)
 	if (priv->hnp_srp_disable)
 		usbcfg |= DWC2_GUSBCFG_FORCEHOSTMODE;
 
-	writel(usbcfg, &regs->gusbcfg);
+	writel(usbcfg, &regs->global_regs.gusbcfg);
 
 	/* Program the GAHBCFG Register. */
-	switch (readl(&regs->ghwcfg2) & DWC2_HWCFG2_ARCHITECTURE_MASK) {
+	switch (readl(&regs->global_regs.ghwcfg2) & DWC2_HWCFG2_ARCHITECTURE_MASK) {
 	case DWC2_HWCFG2_ARCHITECTURE_SLAVE_ONLY:
 		break;
 	case DWC2_HWCFG2_ARCHITECTURE_EXT_DMA:
@@ -464,7 +465,7 @@ static void dwc_otg_core_init(struct udevice *dev)
 		break;
 	}
 
-	writel(ahbcfg, &regs->gahbcfg);
+	writel(ahbcfg, &regs->global_regs.gahbcfg);
 
 	/* Program the capabilities in GUSBCFG Register */
 	usbcfg = 0;
@@ -475,7 +476,7 @@ static void dwc_otg_core_init(struct udevice *dev)
 	usbcfg |= DWC2_GUSBCFG_IC_USB_CAP;
 #endif
 
-	setbits_le32(&regs->gusbcfg, usbcfg);
+	setbits_le32(&regs->global_regs.gusbcfg, usbcfg);
 }
 
 /*
@@ -491,7 +492,7 @@ static void dwc_otg_hc_init(struct dwc2_core_regs *regs, uint8_t hc_num,
 		struct usb_device *dev, uint8_t dev_addr, uint8_t ep_num,
 		uint8_t ep_is_in, uint8_t ep_type, uint16_t max_packet)
 {
-	struct dwc2_hc_regs *hc_regs = &regs->hc_regs[hc_num];
+	struct dwc2_hc_regs *hc_regs = &regs->host_regs.hc[hc_num];
 	uint32_t hcchar = (dev_addr << DWC2_HCCHAR_DEVADDR_OFFSET) |
 			  (ep_num << DWC2_HCCHAR_EPNUM_OFFSET) |
 			  (ep_is_in << DWC2_HCCHAR_EPDIR_OFFSET) |
@@ -553,7 +554,7 @@ static int dwc_otg_submit_rh_msg_in_status(struct dwc2_core_regs *regs,
 		len = 4;
 		break;
 	case USB_RECIP_OTHER | USB_TYPE_CLASS:
-		hprt0 = readl(&regs->hprt0);
+		hprt0 = readl(&regs->host_regs.hprt0);
 		if (hprt0 & DWC2_HPRT0_PRTCONNSTS)
 			port_status |= USB_PORT_STAT_CONNECTION;
 		if (hprt0 & DWC2_HPRT0_PRTENA)
@@ -743,7 +744,8 @@ static int dwc_otg_submit_rh_msg_out(struct dwc2_priv *priv,
 	case (USB_REQ_CLEAR_FEATURE << 8) | USB_RECIP_OTHER | USB_TYPE_CLASS:
 		switch (wValue) {
 		case USB_PORT_FEAT_C_CONNECTION:
-			clrsetbits_le32(&regs->hprt0, DWC2_HPRT0_W1C_MASK, DWC2_HPRT0_PRTCONNDET);
+			clrsetbits_le32(&regs->host_regs.hprt0, DWC2_HPRT0_W1C_MASK,
+					DWC2_HPRT0_PRTCONNDET);
 			break;
 		}
 		break;
@@ -754,13 +756,16 @@ static int dwc_otg_submit_rh_msg_out(struct dwc2_priv *priv,
 			break;
 
 		case USB_PORT_FEAT_RESET:
-			clrsetbits_le32(&regs->hprt0, DWC2_HPRT0_W1C_MASK, DWC2_HPRT0_PRTRST);
+			clrsetbits_le32(&regs->host_regs.hprt0, DWC2_HPRT0_W1C_MASK,
+					DWC2_HPRT0_PRTRST);
 			mdelay(50);
-			clrbits_le32(&regs->hprt0, DWC2_HPRT0_W1C_MASK | DWC2_HPRT0_PRTRST);
+			clrbits_le32(&regs->host_regs.hprt0,
+				     DWC2_HPRT0_W1C_MASK | DWC2_HPRT0_PRTRST);
 			break;
 
 		case USB_PORT_FEAT_POWER:
-			clrsetbits_le32(&regs->hprt0, DWC2_HPRT0_W1C_MASK, DWC2_HPRT0_PRTRST);
+			clrsetbits_le32(&regs->host_regs.hprt0, DWC2_HPRT0_W1C_MASK,
+					DWC2_HPRT0_PRTRST);
 			break;
 
 		case USB_PORT_FEAT_ENABLE:
@@ -907,7 +912,7 @@ int chunk_msg(struct dwc2_priv *priv, struct usb_device *dev,
 	      unsigned long pipe, u8 *pid, int in, void *buffer, int len)
 {
 	struct dwc2_core_regs *regs = priv->regs;
-	struct dwc2_hc_regs *hc_regs = &regs->hc_regs[DWC2_HC_CHANNEL];
+	struct dwc2_hc_regs *hc_regs = &regs->host_regs.hc[DWC2_HC_CHANNEL];
 	struct dwc2_host_regs *host_regs = &regs->host_regs;
 	int devnum = usb_pipedevice(pipe);
 	int ep = usb_pipeendpoint(pipe);
@@ -944,7 +949,8 @@ int chunk_msg(struct dwc2_priv *priv, struct usb_device *dev,
 	if (dev->speed != USB_SPEED_HIGH) {
 		uint8_t hub_addr;
 		uint8_t hub_port;
-		uint32_t hprt0 = readl(&regs->hprt0);
+		uint32_t hprt0 = readl(&regs->host_regs.hprt0);
+
 		if ((hprt0 & DWC2_HPRT0_PRTSPD_MASK) ==
 		     DWC2_HPRT0_PRTSPD_HIGH) {
 			usb_find_usb2_hub_address_port(dev, &hub_addr,
@@ -1174,7 +1180,7 @@ static int dwc2_init_common(struct udevice *dev, struct dwc2_priv *priv)
 	if (ret)
 		return ret;
 
-	snpsid = readl(&regs->gsnpsid);
+	snpsid = readl(&regs->global_regs.gsnpsid);
 	dev_info(dev, "Core Release: %x.%03x\n",
 		 snpsid >> 12 & 0xf, snpsid & 0xfff);
 
@@ -1200,9 +1206,9 @@ static int dwc2_init_common(struct udevice *dev, struct dwc2_priv *priv)
 		dwc_otg_core_host_init(dev, regs);
 	}
 
-	clrsetbits_le32(&regs->hprt0, DWC2_HPRT0_W1C_MASK, DWC2_HPRT0_PRTRST);
+	clrsetbits_le32(&regs->host_regs.hprt0, DWC2_HPRT0_W1C_MASK, DWC2_HPRT0_PRTRST);
 	mdelay(50);
-	clrbits_le32(&regs->hprt0, DWC2_HPRT0_W1C_MASK | DWC2_HPRT0_PRTRST);
+	clrbits_le32(&regs->host_regs.hprt0, DWC2_HPRT0_W1C_MASK | DWC2_HPRT0_PRTRST);
 
 	for (i = 0; i < MAX_DEVICE; i++) {
 		for (j = 0; j < MAX_ENDPOINT; j++) {
@@ -1217,7 +1223,7 @@ static int dwc2_init_common(struct udevice *dev, struct dwc2_priv *priv)
 	 * is started (the bus is scanned) and  fixes the USB detection
 	 * problems with some problematic USB keys.
 	 */
-	if (readl(&regs->gintsts) & DWC2_GINTSTS_CURMODE_HOST)
+	if (readl(&regs->global_regs.gintsts) & DWC2_GINTSTS_CURMODE_HOST)
 		mdelay(1000);
 
 	printf("USB DWC2\n");
@@ -1228,7 +1234,7 @@ static int dwc2_init_common(struct udevice *dev, struct dwc2_priv *priv)
 static void dwc2_uninit_common(struct dwc2_core_regs *regs)
 {
 	/* Put everything in reset. */
-	clrsetbits_le32(&regs->hprt0, DWC2_HPRT0_W1C_MASK, DWC2_HPRT0_PRTRST);
+	clrsetbits_le32(&regs->host_regs.hprt0, DWC2_HPRT0_W1C_MASK, DWC2_HPRT0_PRTRST);
 }
 
 #if !CONFIG_IS_ENABLED(DM_USB)
diff --git a/drivers/usb/host/dwc2.h b/drivers/usb/host/dwc2.h
index 6f022e33a19244d65a6b82e210948506c7bc1096..61b544462edfd6778ddf2ddf2dcf6db3f02a3754 100644
--- a/drivers/usb/host/dwc2.h
+++ b/drivers/usb/host/dwc2.h
@@ -6,64 +6,6 @@
 #ifndef __DWC2_H__
 #define __DWC2_H__
 
-struct dwc2_hc_regs {
-	u32			hcchar;		/* 0x00 */
-	u32			hcsplt;
-	u32			hcint;
-	u32			hcintmsk;
-	u32			hctsiz;		/* 0x10 */
-	u32			hcdma;
-	u32			reserved;
-	u32			hcdmab;
-};
-
-struct dwc2_host_regs {
-	u32			hcfg;		/* 0x00 */
-	u32			hfir;
-	u32			hfnum;
-	u32			_pad_0x40c;
-	u32			hptxsts;	/* 0x10 */
-	u32			haint;
-	u32			haintmsk;
-	u32			hflbaddr;
-};
-
-struct dwc2_core_regs {
-	u32			gotgctl;	/* 0x000 */
-	u32			gotgint;
-	u32			gahbcfg;
-	u32			gusbcfg;
-	u32			grstctl;	/* 0x010 */
-	u32			gintsts;
-	u32			gintmsk;
-	u32			grxstsr;
-	u32			grxstsp;	/* 0x020 */
-	u32			grxfsiz;
-	u32			gnptxfsiz;
-	u32			gnptxsts;
-	u32			gi2cctl;	/* 0x030 */
-	u32			gpvndctl;
-	u32			ggpio;
-	u32			guid;
-	u32			gsnpsid;	/* 0x040 */
-	u32			ghwcfg1;
-	u32			ghwcfg2;
-	u32			ghwcfg3;
-	u32			ghwcfg4;	/* 0x050 */
-	u32			glpmcfg;
-	u32			_pad_0x58_0x9c[42];
-	u32			hptxfsiz;	/* 0x100 */
-	u32			dptxfsiz_dieptxf[15];
-	u32			_pad_0x140_0x3fc[176];
-	struct dwc2_host_regs	host_regs;	/* 0x400 */
-	u32			_pad_0x420_0x43c[8];
-	u32			hprt0;		/* 0x440 */
-	u32			_pad_0x444_0x4fc[47];
-	struct dwc2_hc_regs	hc_regs[16];	/* 0x500 */
-	u32			_pad_0x700_0xe00[448];
-	u32			pcgcctl;	/* 0xe00 */
-};
-
 #define DWC2_GOTGCTL_SESREQSCS				(1 << 0)
 #define DWC2_GOTGCTL_SESREQSCS_OFFSET			0
 #define DWC2_GOTGCTL_SESREQ				(1 << 1)

-- 
2.39.2

