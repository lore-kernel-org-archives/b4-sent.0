From: Junhui Liu <liujh2818@outlook.com>
Date: Mon, 30 Dec 2024 11:30:20 +0800
Subject: [PATCH v2 5/8] usb: dwc2: Align macros with Linux kernel
 definitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241230-dwc2-dev-v2-5-12cd9b8a2358@outlook.com>
References: <20241230-dwc2-dev-v2-0-12cd9b8a2358@outlook.com>
In-Reply-To: <20241230-dwc2-dev-v2-0-12cd9b8a2358@outlook.com>
To: Tom Rini <trini@konsulko.com>, Marek Vasut <marex@denx.de>, 
 Lukasz Majewski <lukma@denx.de>, 
 Mattijs Korpershoek <mkorpershoek@baylibre.com>
Cc: u-boot@lists.denx.de, Kongyang Liu <seashell11234455@gmail.com>, 
 Junhui Liu <liujh2818@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735529447; l=83772;
 i=liujh2818@outlook.com; s=20241030; h=from:subject:message-id;
 bh=vwmYRojq4RbxJxJF977VqR3YUZmxhR8rJZuFqf3LcSw=;
 b=IUUrKjo9Picim9PY/jTY5OV++KB9x5V7ZZz5uj6zmnqLayTAaTwtMY9tiGGd1213hdLqowcng
 8ALWZ8WIv7wCrRH6AE1TJDGm7GUdl6IhTD6KzFJd0iBXvN4HgggkcRI
X-Developer-Key: i=liujh2818@outlook.com; a=ed25519;
 pk=ApYwI6KD3EjynMw61RqGa6c5BGbStQnKSrbNN+aQqT4=
X-Endpoint-Received: by B4 Relay for liujh2818@outlook.com/20241030 with auth_id=259
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Kongyang Liu <seashell11234455@gmail.com>

Update the DWC2 macros to match those used in the Linux kernel, making
it easier to synchronize updates with kernel. Also removed some unused
macros to cleanup the code.

Signed-off-by: Kongyang Liu <seashell11234455@gmail.com>
Signed-off-by: Junhui Liu <liujh2818@outlook.com>
---
 drivers/usb/gadget/dwc2_udc_otg.c          |  62 +--
 drivers/usb/gadget/dwc2_udc_otg_regs.h     | 245 ++++++-----
 drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c | 130 +++---
 drivers/usb/host/dwc2.c                    | 260 ++++++------
 drivers/usb/host/dwc2.h                    | 638 +++++++++++++----------------
 5 files changed, 633 insertions(+), 702 deletions(-)

diff --git a/drivers/usb/gadget/dwc2_udc_otg.c b/drivers/usb/gadget/dwc2_udc_otg.c
index 2289dcc9c325a793ff86940625794066463b4083..0fc9ee1b90fa71135083a1a6dae2e74992e51181 100644
--- a/drivers/usb/gadget/dwc2_udc_otg.c
+++ b/drivers/usb/gadget/dwc2_udc_otg.c
@@ -160,7 +160,7 @@ struct dwc2_core_regs *reg;
 
 bool dfu_usb_get_reset(void)
 {
-	return !!(readl(&reg->global_regs.gintsts) & INT_RESET);
+	return !!(readl(&reg->global_regs.gintsts) & GINTSTS_USBRST);
 }
 
 __weak void otg_phy_init(struct dwc2_udc *dev) {}
@@ -240,8 +240,8 @@ static int udc_enable(struct dwc2_udc *dev)
 
 static int dwc2_gadget_pullup(struct usb_gadget *g, int is_on)
 {
-	clrsetbits_le32(&reg->device_regs.dctl, SOFT_DISCONNECT,
-			is_on ? 0 : SOFT_DISCONNECT);
+	clrsetbits_le32(&reg->device_regs.dctl, DCTL_SFTDISCON,
+			is_on ? 0 : DCTL_SFTDISCON);
 
 	return 0;
 }
@@ -471,7 +471,7 @@ static void reconfig_usbd(struct dwc2_udc *dev)
 	u32 max_hw_ep;
 	int pdata_hw_ep;
 
-	writel(CORE_SOFT_RESET, &reg->global_regs.grstctl);
+	writel(GRSTCTL_CSFTRST, &reg->global_regs.grstctl);
 
 	debug("Resetting OTG controller\n");
 
@@ -498,19 +498,20 @@ static void reconfig_usbd(struct dwc2_udc *dev)
 
 	/* 3. Put the OTG device core in the disconnected state.*/
 	uTemp = readl(&reg->device_regs.dctl);
-	uTemp |= SOFT_DISCONNECT;
+	uTemp |= DCTL_SFTDISCON;
 	writel(uTemp, &reg->device_regs.dctl);
 
 	udelay(20);
 
 	/* 4. Make the OTG device core exit from the disconnected state.*/
 	uTemp = readl(&reg->device_regs.dctl);
-	uTemp = uTemp & ~SOFT_DISCONNECT;
+	uTemp = uTemp & ~DCTL_SFTDISCON;
 	writel(uTemp, &reg->device_regs.dctl);
 
 	/* 5. Configure OTG Core to initial settings of device mode.*/
 	/* [][1: full speed(30Mhz) 0:high speed]*/
-	writel(EP_MISS_CNT(1) | DEV_SPEED_HIGH_SPEED_20, &reg->device_regs.dcfg);
+	writel(FIELD_PREP(DCFG_EPMISCNT_MASK, 1) |
+	       FIELD_PREP(DCFG_DEVSPD_MASK, DCFG_DEVSPD_HS), &reg->device_regs.dcfg);
 
 	mdelay(1);
 
@@ -518,12 +519,12 @@ static void reconfig_usbd(struct dwc2_udc *dev)
 	writel(GINTMSK_INIT, &reg->global_regs.gintmsk);
 
 	/* 7. Set NAK bit of EP0, EP1, EP2*/
-	writel(DEPCTL_EPDIS | DEPCTL_SNAK, &reg->device_regs.out_endp[EP0_CON].doepctl);
-	writel(DEPCTL_EPDIS | DEPCTL_SNAK, &reg->device_regs.in_endp[EP0_CON].diepctl);
+	writel(DXEPCTL_EPDIS | DXEPCTL_SNAK, &reg->device_regs.out_endp[EP0_CON].doepctl);
+	writel(DXEPCTL_EPDIS | DXEPCTL_SNAK, &reg->device_regs.in_endp[EP0_CON].diepctl);
 
 	for (i = 1; i < DWC2_MAX_ENDPOINTS; i++) {
-		writel(DEPCTL_EPDIS | DEPCTL_SNAK, &reg->device_regs.out_endp[i].doepctl);
-		writel(DEPCTL_EPDIS | DEPCTL_SNAK, &reg->device_regs.in_endp[i].diepctl);
+		writel(DXEPCTL_EPDIS | DXEPCTL_SNAK, &reg->device_regs.out_endp[i].doepctl);
+		writel(DXEPCTL_EPDIS | DXEPCTL_SNAK, &reg->device_regs.in_endp[i].diepctl);
 	}
 
 	/* 8. Unmask EPO interrupts*/
@@ -551,12 +552,12 @@ static void reconfig_usbd(struct dwc2_udc *dev)
 	writel(rx_fifo_sz, &reg->global_regs.grxfsiz);
 
 	/* 12. Set Non Periodic Tx FIFO Size */
-	writel((np_tx_fifo_sz << 16) | rx_fifo_sz,
+	writel(FIELD_PREP(FIFOSIZE_DEPTH_MASK, np_tx_fifo_sz) |
+	       FIELD_PREP(FIFOSIZE_STARTADDR_MASK, rx_fifo_sz),
 	       &reg->global_regs.gnptxfsiz);
 
 	/* retrieve the number of IN Endpoints (excluding ep0) */
-	max_hw_ep = (readl(&reg->global_regs.ghwcfg4) & GHWCFG4_NUM_IN_EPS_MASK) >>
-		    GHWCFG4_NUM_IN_EPS_SHIFT;
+	max_hw_ep = FIELD_GET(GHWCFG4_NUM_IN_EPS_MASK, readl(&reg->global_regs.ghwcfg4));
 	pdata_hw_ep = dev->pdata->tx_fifo_sz_nb;
 
 	/* tx_fifo_sz_nb should equal to number of IN Endpoint */
@@ -568,24 +569,27 @@ static void reconfig_usbd(struct dwc2_udc *dev)
 		if (pdata_hw_ep)
 			tx_fifo_sz = dev->pdata->tx_fifo_sz_array[i];
 
-		writel((rx_fifo_sz + np_tx_fifo_sz + (tx_fifo_sz * i)) |
-			tx_fifo_sz << 16, &reg->global_regs.dptxfsizn[i]);
+		writel(FIELD_PREP(FIFOSIZE_DEPTH_MASK, tx_fifo_sz) |
+		       FIELD_PREP(FIFOSIZE_STARTADDR_MASK,
+				  rx_fifo_sz + np_tx_fifo_sz + tx_fifo_sz * i),
+		       &reg->global_regs.dptxfsizn[i]);
 	}
 	/* Flush the RX FIFO */
-	writel(RX_FIFO_FLUSH, &reg->global_regs.grstctl);
-	while (readl(&reg->global_regs.grstctl) & RX_FIFO_FLUSH)
+	writel(GRSTCTL_RXFFLSH, &reg->global_regs.grstctl);
+	while (readl(&reg->global_regs.grstctl) & GRSTCTL_RXFFLSH)
 		debug("%s: waiting for DWC2_UDC_OTG_GRSTCTL\n", __func__);
 
 	/* Flush all the Tx FIFO's */
-	writel(TX_FIFO_FLUSH_ALL, &reg->global_regs.grstctl);
-	writel(TX_FIFO_FLUSH_ALL | TX_FIFO_FLUSH, &reg->global_regs.grstctl);
-	while (readl(&reg->global_regs.grstctl) & TX_FIFO_FLUSH)
+	writel(FIELD_PREP(GRSTCTL_TXFNUM_MASK, GRSTCTL_TXFNUM_ALL), &reg->global_regs.grstctl);
+	writel(FIELD_PREP(GRSTCTL_TXFNUM_MASK, GRSTCTL_TXFNUM_ALL) | GRSTCTL_TXFFLSH,
+	       &reg->global_regs.grstctl);
+	while (readl(&reg->global_regs.grstctl) & GRSTCTL_TXFFLSH)
 		debug("%s: waiting for DWC2_UDC_OTG_GRSTCTL\n", __func__);
 
 	/* 13. Clear NAK bit of EP0, EP1, EP2*/
 	/* For Slave mode*/
 	/* EP0: Control OUT */
-	writel(DEPCTL_EPDIS | DEPCTL_CNAK,
+	writel(DXEPCTL_EPDIS | DXEPCTL_CNAK,
 	       &reg->device_regs.out_endp[EP0_CON].doepctl);
 
 	/* 14. Initialize OTG Link Core.*/
@@ -1127,8 +1131,8 @@ static int dwc2_udc_otg_probe(struct udevice *dev)
 		if (plat->force_b_session_valid &&
 		    !plat->force_vbus_detection) {
 			/* Override VBUS detection: enable then value*/
-			setbits_le32(&usbotg_reg->global_regs.gotgctl, VB_VALOEN);
-			setbits_le32(&usbotg_reg->global_regs.gotgctl, VB_VALOVAL);
+			setbits_le32(&usbotg_reg->global_regs.gotgctl, GOTGCTL_VBVALOEN);
+			setbits_le32(&usbotg_reg->global_regs.gotgctl, GOTGCTL_VBVALOVAL);
 		} else {
 			/* Enable VBUS sensing */
 			setbits_le32(&usbotg_reg->global_regs.ggpio,
@@ -1137,9 +1141,9 @@ static int dwc2_udc_otg_probe(struct udevice *dev)
 		if (plat->force_b_session_valid) {
 			/* Override B session bits: enable then value */
 			setbits_le32(&usbotg_reg->global_regs.gotgctl,
-				     A_VALOEN | B_VALOEN);
+				     GOTGCTL_AVALOEN | GOTGCTL_BVALOEN);
 			setbits_le32(&usbotg_reg->global_regs.gotgctl,
-				     A_VALOVAL | B_VALOVAL);
+				     GOTGCTL_AVALOVAL | GOTGCTL_BVALOVAL);
 		} else {
 			/* Enable ID detection */
 			setbits_le32(&usbotg_reg->global_regs.ggpio,
@@ -1205,10 +1209,10 @@ U_BOOT_DRIVER(dwc2_udc_otg) = {
 int dwc2_udc_B_session_valid(struct udevice *dev)
 {
 	struct dwc2_plat_otg_data *plat = dev_get_plat(dev);
-	struct dwc2_usbotg_reg *usbotg_reg =
-		(struct dwc2_usbotg_reg *)plat->regs_otg;
+	struct dwc2_core_reg *usbotg_reg =
+		(struct dwc2_core_reg *)plat->regs_otg;
 
-	return readl(&usbotg_reg->gotgctl) & B_SESSION_VALID;
+	return readl(&usbotg_reg->global_regs.gotgctl) & GOTGCTL_BSESVLD;
 }
 #else
 int dm_usb_gadget_handle_interrupts(struct udevice *dev)
diff --git a/drivers/usb/gadget/dwc2_udc_otg_regs.h b/drivers/usb/gadget/dwc2_udc_otg_regs.h
index 33359ba56f7864525fb435ab52f2b21538e4647f..576fb2a999c39988bc6d47675c8fd720f234e088 100644
--- a/drivers/usb/gadget/dwc2_udc_otg_regs.h
+++ b/drivers/usb/gadget/dwc2_udc_otg_regs.h
@@ -22,54 +22,53 @@ struct dwc2_usbotg_phy {
 /*definitions related to CSR setting */
 
 /* DWC2_UDC_OTG_GOTGCTL */
-#define B_SESSION_VALID			BIT(19)
-#define A_SESSION_VALID			BIT(18)
-#define B_VALOVAL			BIT(7)
-#define B_VALOEN			BIT(6)
-#define A_VALOVAL			BIT(5)
-#define A_VALOEN			BIT(4)
-#define VB_VALOVAL			BIT(3)
-#define VB_VALOEN			BIT(2)
+#define GOTGCTL_BSESVLD			BIT(19)
+#define GOTGCTL_ASESVLD			BIT(18)
+#define GOTGCTL_BVALOVAL		BIT(7)
+#define GOTGCTL_BVALOEN			BIT(6)
+#define GOTGCTL_AVALOVAL		BIT(5)
+#define GOTGCTL_AVALOEN			BIT(4)
+#define GOTGCTL_VBVALOVAL		BIT(3)
+#define GOTGCTL_VBVALOEN		BIT(2)
 
 /* DWC2_UDC_OTG_GOTINT */
-#define GOTGINT_SES_END_DET		(1<<2)
+#define GOTGINT_SES_END_DET		BIT(2)
 
 /* DWC2_UDC_OTG_GAHBCFG */
-#define PTXFE_HALF			(0<<8)
-#define PTXFE_ZERO			(1<<8)
-#define NPTXFE_HALF			(0<<7)
-#define NPTXFE_ZERO			(1<<7)
-#define MODE_SLAVE			(0<<5)
-#define MODE_DMA			(1<<5)
-#define BURST_SINGLE			(0<<1)
-#define BURST_INCR			(1<<1)
-#define BURST_INCR4			(3<<1)
-#define BURST_INCR8			(5<<1)
-#define BURST_INCR16			(7<<1)
-#define GBL_INT_UNMASK			(1<<0)
-#define GBL_INT_MASK			(0<<0)
+#define GAHBCFG_AHB_SINGLE		BIT(23)
+#define GAHBCFG_NOTI_ALL_DMA_WRIT	BIT(22)
+#define GAHBCFG_REM_MEM_SUPP		BIT(21)
+#define GAHBCFG_P_TXF_EMP_LVL		BIT(8)
+#define GAHBCFG_NP_TXF_EMP_LVL		BIT(7)
+#define GAHBCFG_DMA_EN			BIT(5)
+#define GAHBCFG_HBSTLEN_MASK		GENMASK(4, 1)
+#define GAHBCFG_HBSTLEN_SINGLE		0
+#define GAHBCFG_HBSTLEN_INCR		1
+#define GAHBCFG_HBSTLEN_INCR4		3
+#define GAHBCFG_HBSTLEN_INCR8		5
+#define GAHBCFG_HBSTLEN_INCR16		7
+#define GAHBCFG_GLBL_INTR_EN		BIT(0)
 
 /* DWC2_UDC_OTG_GRSTCTL */
-#define AHB_MASTER_IDLE			(1u<<31)
-#define CORE_SOFT_RESET			(0x1<<0)
+#define GRSTCTL_AHBIDLE			BIT(31)
+#define GRSTCTL_CSFTRST			BIT(0)
 
 /* DWC2_UDC_OTG_GINTSTS/DWC2_UDC_OTG_GINTMSK core interrupt register */
-#define INT_RESUME			BIT(31)
-#define INT_DISCONN			BIT(29)
-#define INT_CONN_ID_STS_CNG		BIT(28)
-#define INT_OUT_EP			BIT(19)
-#define INT_IN_EP			BIT(18)
-#define INT_ENUMDONE			BIT(13)
-#define INT_RESET			BIT(12)
-#define INT_SUSPEND			BIT(11)
-#define INT_EARLY_SUSPEND		BIT(10)
-#define INT_GOUTNakEff			BIT(7)
-#define INT_GINNakEff			BIT(6)
-#define INT_NP_TX_FIFO_EMPTY		BIT(5)
-#define INT_RX_FIFO_NOT_EMPTY		BIT(4)
-#define INT_SOF				BIT(3)
-#define INT_OTG				BIT(2)
-#define INT_HOST_MODE			BIT(1)
+#define GINTSTS_WKUPINT			BIT(31)
+#define GINTSTS_DISCONNINT		BIT(29)
+#define GINTSTS_CONIDSTSCHNG		BIT(28)
+#define GINTSTS_OEPINT			BIT(19)
+#define GINTSTS_IEPINT			BIT(18)
+#define GINTSTS_ENUMDONE		BIT(13)
+#define GINTSTS_USBRST			BIT(12)
+#define GINTSTS_USBSUSP			BIT(11)
+#define GINTSTS_ERLYSUSP		BIT(10)
+#define GINTSTS_NPTXFEMP		BIT(5)
+#define GINTSTS_RXFLVL			BIT(4)
+#define GINTSTS_SOF			BIT(3)
+#define GINTSTS_OTGINT			BIT(2)
+#define GINTSTS_MODEMIS			BIT(1)
+#define GINTSTS_CURMODE_HOST		BIT(0)
 
 #define FULL_SPEED_CONTROL_PKT_SIZE	8
 #define FULL_SPEED_BULK_PKT_SIZE	64
@@ -81,28 +80,18 @@ struct dwc2_usbotg_phy {
 #define NPTX_FIFO_SIZE			1024
 #define PTX_FIFO_SIZE			384
 
-#define DEPCTL_TXFNUM_0			(0x0<<22)
-#define DEPCTL_TXFNUM_1			(0x1<<22)
-#define DEPCTL_TXFNUM_2			(0x2<<22)
-#define DEPCTL_TXFNUM_3			(0x3<<22)
-#define DEPCTL_TXFNUM_4			(0x4<<22)
+#define FIFOSIZE_DEPTH_MASK		GENMASK(31, 16)
+#define FIFOSIZE_STARTADDR_MASK		GENMASK(15, 0)
 
 /* Enumeration speed */
-#define USB_HIGH_30_60MHZ		(0x0<<1)
-#define USB_FULL_30_60MHZ		(0x1<<1)
-#define USB_LOW_6MHZ			(0x2<<1)
-#define USB_FULL_48MHZ			(0x3<<1)
-
-/* DWC2_UDC_OTG_GRXSTSP STATUS */
-#define OUT_PKT_RECEIVED		(0x2<<17)
-#define OUT_TRANSFER_COMPLELTED		(0x3<<17)
-#define SETUP_TRANSACTION_COMPLETED	(0x4<<17)
-#define SETUP_PKT_RECEIVED		(0x6<<17)
-#define GLOBAL_OUT_NAK			(0x1<<17)
+#define DSTS_ENUMSPD_MASK		GENMASK(2, 1)
+#define DSTS_ENUMSPD_HS			0
+#define DSTS_ENUMSPD_FS			1
+#define DSTS_ENUMSPD_LS			2
 
 /* DWC2_UDC_OTG_DCTL device control register */
-#define NORMAL_OPERATION		(0x1<<0)
-#define SOFT_DISCONNECT			(0x1<<1)
+#define DCTL_SFTDISCON			BIT(1)
+#define DCTL_RMTWKUPSIG			BIT(0)
 
 /* DWC2_UDC_OTG_DAINT device all endpoint interrupt register */
 #define DAINT_OUTEP_MASK		GENMASK(31, 16)
@@ -110,44 +99,51 @@ struct dwc2_usbotg_phy {
 
 /* DWC2_UDC_OTG_DIEPCTL0/DOEPCTL0 device
    control IN/OUT endpoint 0 control register */
-#define DEPCTL_EPENA			BIT(31)
-#define DEPCTL_EPDIS			BIT(30)
-#define DEPCTL_SETD1PID			BIT(29)
-#define DEPCTL_SETD0PID			BIT(28)
-#define DEPCTL_SNAK			BIT(27)
-#define DEPCTL_CNAK			BIT(26)
-#define DEPCTL_STALL			BIT(21)
-#define DEPCTL_TYPE_MASK		GENMASK(19, 18)
-#define DEPCTL_CTRL_TYPE		(0x0<<18)
-#define DEPCTL_ISO_TYPE			(0x1<<18)
-#define DEPCTL_BULK_TYPE		(0x2<<18)
-#define DEPCTL_INTR_TYPE		(0x3<<18)
-#define DEPCTL_USBACTEP			BIT(15)
-#define DEPCTL_NEXT_EP_MASK		GENMASK(14, 11)
-#define DEPCTL_MPS_MASK			GENMASK(10, 0)
-
-#define DEPCTL0_MPS_64			(0x0<<0)
-#define DEPCTL0_MPS_32			(0x1<<0)
-#define DEPCTL0_MPS_16			(0x2<<0)
-#define DEPCTL0_MPS_8			(0x3<<0)
-#define DEPCTL_MPS_BULK_512		(512<<0)
-#define DEPCTL_MPS_INT_MPS_16		(16<<0)
-
-#define DIEPCTL0_NEXT_EP_BIT		(11)
+#define DXEPCTL_EPENA			BIT(31)
+#define DXEPCTL_EPDIS			BIT(30)
+#define DXEPCTL_SETD1PID		BIT(29)
+#define DXEPCTL_SETODDFR		BIT(29)
+#define DXEPCTL_SETD0PID		BIT(28)
+#define DXEPCTL_SETEVENFR		BIT(28)
+#define DXEPCTL_SNAK			BIT(27)
+#define DXEPCTL_CNAK			BIT(26)
+#define DXEPCTL_STALL			BIT(21)
+#define DXEPCTL_EPTYPE_MASK		GENMASK(19, 18)
+#define DXEPCTL_EPTYPE_CONTROL		0
+#define DXEPCTL_EPTYPE_ISO		1
+#define DXEPCTL_EPTYPE_BULK		2
+#define DXEPCTL_EPTYPE_INTERRUPT	3
+#define DXEPCTL_EOFRNUM			BIT(16)
+#define DXEPCTL_USBACTEP		BIT(15)
+#define DXEPCTL_NEXTEP_MASK		GENMASK(14, 11)
+#define DXEPCTL_MPS_MASK		GENMASK(10, 0)
+
 
 /* DWC2_UDC_OTG_DIEPMSK/DOEPMSK device IN/OUT endpoint
    common interrupt mask register */
 /* DWC2_UDC_OTG_DIEPINTn/DOEPINTn device IN/OUT endpoint interrupt register */
-#define BACK2BACK_SETUP_RECEIVED	BIT(6)
-#define INTKNEPMIS			BIT(5)
-#define INTKN_TXFEMP			BIT(4)
-#define NON_ISO_IN_EP_TIMEOUT		BIT(3)
-#define CTRL_OUT_EP_SETUP_PHASE_DONE	BIT(3)
-#define AHB_ERROR			BIT(2)
-#define EPDISBLD			BIT(1)
-#define TRANSFER_DONE			BIT(0)
-
-#define USB_PHY_CTRL_EN0		(0x1 << 0)
+#define DIEPMSK_NAKMSK			BIT(13)
+#define DIEPMSK_BNAININTRMSK		BIT(9)
+#define DIEPMSK_TXFIFOUNDRNMSK		BIT(8)
+#define DIEPMSK_TXFIFOEMPTY		BIT(7)
+#define DIEPMSK_INEPNAKEFFMSK		BIT(6)
+#define DIEPMSK_INTKNEPMISMSK		BIT(5)
+#define DIEPMSK_INTKNTXFEMPMSK		BIT(4)
+#define DIEPMSK_TIMEOUTMSK		BIT(3)
+#define DIEPMSK_AHBERRMSK		BIT(2)
+#define DIEPMSK_EPDISBLDMSK		BIT(1)
+#define DIEPMSK_XFERCOMPLMSK		BIT(0)
+
+#define DOEPMSK_BNAMSK			BIT(9)
+#define DOEPMSK_BACK2BACKSETUP		BIT(6)
+#define DOEPMSK_STSPHSERCVDMSK		BIT(5)
+#define DOEPMSK_OUTTKNEPDISMSK		BIT(4)
+#define DOEPMSK_SETUPMSK		BIT(3)
+#define DOEPMSK_AHBERRMSK		BIT(2)
+#define DOEPMSK_EPDISBLDMSK		BIT(1)
+#define DOEPMSK_XFERCOMPLMSK		BIT(0)
+
+#define USB_PHY_CTRL_EN0                BIT(0)
 
 /* OPHYPWR */
 #define PHY_0_SLEEP			(0x1 << 5)
@@ -176,47 +172,46 @@ struct dwc2_usbotg_phy {
 #define EXYNOS4X12_CLK_SEL_24MHZ	(0x05 << 0)
 
 /* Device Configuration Register DCFG */
-#define DEV_SPEED_HIGH_SPEED_20		(0x0 << 0)
-#define DEV_SPEED_FULL_SPEED_20		(0x1 << 0)
-#define DEV_SPEED_LOW_SPEED_11		(0x2 << 0)
-#define DEV_SPEED_FULL_SPEED_11		(0x3 << 0)
-#define EP_MISS_CNT(x)			(x << 18)
-#define DEVICE_ADDRESS(x)		(x << 4)
+#define DCFG_EPMISCNT_MASK		GENMASK(22, 18)
+#define DCFG_DEVADDR_MASK		GENMASK(10, 4)
+#define DCFG_DEVSPD_MASK		GENMASK(1, 0)
+#define DCFG_DEVSPD_HS			0
+#define DCFG_DEVSPD_FS			1
+#define DCFG_DEVSPD_LS			2
+#define DCFG_DEVSPD_FS48		3
 
 /* Core Reset Register (GRSTCTL) */
-#define TX_FIFO_FLUSH			(0x1 << 5)
-#define RX_FIFO_FLUSH			(0x1 << 4)
-#define TX_FIFO_NUMBER(x)		(x << 6)
-#define TX_FIFO_FLUSH_ALL		TX_FIFO_NUMBER(0x10)
+#define GRSTCTL_TXFNUM_MASK		GENMASK(10, 6)
+#define GRSTCTL_TXFFLSH			BIT(5)
+#define GRSTCTL_RXFFLSH			BIT(4)
+#define GRSTCTL_TXFNUM_ALL		0x10
 
 /* Masks definitions */
-#define GINTMSK_INIT	(INT_OUT_EP | INT_IN_EP | INT_RESUME | INT_ENUMDONE\
-			| INT_RESET | INT_SUSPEND | INT_OTG)
-#define DOEPMSK_INIT	(CTRL_OUT_EP_SETUP_PHASE_DONE | AHB_ERROR|TRANSFER_DONE)
-#define DIEPMSK_INIT	(NON_ISO_IN_EP_TIMEOUT|AHB_ERROR|TRANSFER_DONE)
-#define GAHBCFG_INIT	(PTXFE_HALF | NPTXFE_HALF | MODE_DMA | BURST_INCR4\
-			| GBL_INT_UNMASK)
-
-/* Device Endpoint X Transfer Size Register (DIEPTSIZX) */
-#define DIEPT_SIZ_PKT_CNT(x)		(x << 19)
-#define DIEPT_SIZ_XFER_SIZE(x)		(x << 0)
-
-/* Device OUT Endpoint X Transfer Size Register (DOEPTSIZX) */
-#define DOEPT_SIZ_PKT_CNT(x)		(x << 19)
-#define DOEPT_SIZ_XFER_SIZE(x)		(x << 0)
-#define DOEPT_SIZ_XFER_SIZE_MAX_EP0	(0x7F << 0)
-#define DOEPT_SIZ_XFER_SIZE_MAX_EP	(0x7FFF << 0)
+#define GINTMSK_INIT	(GINTSTS_WKUPINT | GINTSTS_OEPINT | GINTSTS_IEPINT | GINTSTS_ENUMDONE | \
+			 GINTSTS_USBRST | GINTSTS_USBSUSP | GINTSTS_OTGINT)
+#define DOEPMSK_INIT	(DOEPMSK_SETUPMSK | DOEPMSK_AHBERRMSK | DOEPMSK_XFERCOMPLMSK)
+#define DIEPMSK_INIT	(DIEPMSK_TIMEOUTMSK | DIEPMSK_AHBERRMSK | DIEPMSK_XFERCOMPLMSK)
+#define GAHBCFG_INIT	(GAHBCFG_DMA_EN | \
+			 FIELD_PREP(GAHBCFG_HBSTLEN_MASK, GAHBCFG_HBSTLEN_INCR4) | \
+			 GAHBCFG_GLBL_INTR_EN)
+
+/* Device Endpoint X Transfer Size Register (DIEPTSIZX/DOEPTSIZX) */
+#define DIEPTSIZ0_PKTCNT_MASK		GENMASK(20, 19)
+#define DIEPTSIZ0_XFERSIZE_MASK		GENMASK(6, 0)
+
+#define DOEPTSIZ0_SUPCNT_MASK		GENMASK(30, 29)
+#define DOEPTSIZ0_PKTCNT		BIT(19)
+#define DOEPTSIZ0_XFERSIZE_MASK		GENMASK(6, 0)
+
+#define DXEPTSIZ_MC_MASK		GENMASK(30, 29)
+#define DXEPTSIZ_PKTCNT_MASK		GENMASK(28, 19)
+#define DXEPTSIZ_XFERSIZE_MASK		GENMASK(18, 0)
 
 /* Device Endpoint-N Control Register (DIEPCTLn/DOEPCTLn) */
-#define DIEPCTL_TX_FIFO_NUM_MASK	GENMASK(25, 22)
-
-/* Device ALL Endpoints Interrupt Register (DAINT) */
-#define DAINT_IN_EP_INT(x)		(x << 0)
-#define DAINT_OUT_EP_INT(x)		(x << 16)
+#define DXEPCTL_TXFNUM_MASK		GENMASK(25, 22)
 
 /* User HW Config4 */
-#define GHWCFG4_NUM_IN_EPS_MASK		(0xf << 26)
-#define GHWCFG4_NUM_IN_EPS_SHIFT	26
+#define GHWCFG4_NUM_IN_EPS_MASK		GENMASK(29, 26)
 
 /* OTG general core configuration register (OTG_GCCFG:0x38) for STM32MP1 */
 #define GGPIO_STM32_OTG_GCCFG_VBDEN	BIT(21)
diff --git a/drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c b/drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c
index 76c0b03c355b47e9523a071bd76ab8d6a17cd3ac..64d2fe7bbde4494b4cbcdf57032b720901fdd4eb 100644
--- a/drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c
+++ b/drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c
@@ -35,10 +35,10 @@ static inline void dwc2_udc_ep0_zlp(struct dwc2_udc *dev)
 
 	writel(phys_to_bus((unsigned long)usb_ctrl_dma_addr),
 	       &reg->device_regs.in_endp[EP0_CON].diepdma);
-	writel(DIEPT_SIZ_PKT_CNT(1), &reg->device_regs.in_endp[EP0_CON].dieptsiz);
+	writel(FIELD_PREP(DXEPTSIZ_PKTCNT_MASK, 1), &reg->device_regs.in_endp[EP0_CON].dieptsiz);
 
 	ep_ctrl = readl(&reg->device_regs.in_endp[EP0_CON].diepctl);
-	writel(ep_ctrl | DEPCTL_EPENA | DEPCTL_CNAK,
+	writel(ep_ctrl | DXEPCTL_EPENA | DXEPCTL_CNAK,
 	       &reg->device_regs.in_endp[EP0_CON].diepctl);
 
 	debug_cond(DEBUG_EP0 != 0, "%s:EP0 ZLP DIEPCTL0 = 0x%x\n",
@@ -53,13 +53,13 @@ static void dwc2_udc_pre_setup(void)
 	debug_cond(DEBUG_IN_EP,
 		   "%s : Prepare Setup packets.\n", __func__);
 
-	writel(DOEPT_SIZ_PKT_CNT(1) | sizeof(struct usb_ctrlrequest),
+	writel(FIELD_PREP(DXEPTSIZ_PKTCNT_MASK, 1) | sizeof(struct usb_ctrlrequest),
 	       &reg->device_regs.out_endp[EP0_CON].doeptsiz);
 	writel(phys_to_bus((unsigned long)usb_ctrl_dma_addr),
 	       &reg->device_regs.out_endp[EP0_CON].doepdma);
 
 	ep_ctrl = readl(&reg->device_regs.out_endp[EP0_CON].doepctl);
-	writel(ep_ctrl | DEPCTL_EPENA, &reg->device_regs.out_endp[EP0_CON].doepctl);
+	writel(ep_ctrl | DXEPCTL_EPENA, &reg->device_regs.out_endp[EP0_CON].doepctl);
 
 	debug_cond(DEBUG_EP0 != 0, "%s:EP0 ZLP DIEPCTL0 = 0x%x\n",
 		__func__, readl(&reg->device_regs.in_endp[EP0_CON].diepctl));
@@ -80,13 +80,13 @@ static inline void dwc2_ep0_complete_out(void)
 	debug_cond(DEBUG_IN_EP,
 		"%s : Prepare Complete Out packet.\n", __func__);
 
-	writel(DOEPT_SIZ_PKT_CNT(1) | sizeof(struct usb_ctrlrequest),
+	writel(FIELD_PREP(DXEPTSIZ_PKTCNT_MASK, 1) | sizeof(struct usb_ctrlrequest),
 	       &reg->device_regs.out_endp[EP0_CON].doeptsiz);
 	writel(phys_to_bus((unsigned long)usb_ctrl_dma_addr),
 	       &reg->device_regs.out_endp[EP0_CON].doepdma);
 
 	ep_ctrl = readl(&reg->device_regs.out_endp[EP0_CON].doepctl);
-	writel(ep_ctrl | DEPCTL_EPENA | DEPCTL_CNAK,
+	writel(ep_ctrl | DXEPCTL_EPENA | DXEPCTL_CNAK,
 	       &reg->device_regs.out_endp[EP0_CON].doepctl);
 
 	debug_cond(DEBUG_EP0 != 0, "%s:EP0 ZLP DIEPCTL0 = 0x%x\n",
@@ -121,9 +121,10 @@ static int setdma_rx(struct dwc2_ep *ep, struct dwc2_request *req)
 				ROUND(ep->len, CONFIG_SYS_CACHELINE_SIZE));
 
 	writel(phys_to_bus((unsigned long)ep->dma_buf), &reg->device_regs.out_endp[ep_num].doepdma);
-	writel(DOEPT_SIZ_PKT_CNT(pktcnt) | DOEPT_SIZ_XFER_SIZE(length),
+	writel(FIELD_PREP(DXEPTSIZ_PKTCNT_MASK, pktcnt) |
+	       FIELD_PREP(DXEPTSIZ_XFERSIZE_MASK, length),
 	       &reg->device_regs.out_endp[ep_num].doeptsiz);
-	writel(DEPCTL_EPENA | DEPCTL_CNAK | ctrl, &reg->device_regs.out_endp[ep_num].doepctl);
+	writel(DXEPCTL_EPENA | DXEPCTL_CNAK | ctrl, &reg->device_regs.out_endp[ep_num].doepctl);
 
 	debug_cond(DEBUG_OUT_EP != 0,
 		   "%s: EP%d RX DMA start : DOEPDMA = 0x%x,"
@@ -163,25 +164,27 @@ static int setdma_tx(struct dwc2_ep *ep, struct dwc2_request *req)
 		pktcnt = (length - 1)/(ep->ep.maxpacket) + 1;
 
 	/* Flush the endpoint's Tx FIFO */
-	writel(TX_FIFO_NUMBER(ep->fifo_num), &reg->global_regs.grstctl);
-	writel(TX_FIFO_NUMBER(ep->fifo_num) | TX_FIFO_FLUSH, &reg->global_regs.grstctl);
-	while (readl(&reg->global_regs.grstctl) & TX_FIFO_FLUSH)
+	writel(FIELD_PREP(GRSTCTL_TXFNUM_MASK, ep->fifo_num), &reg->global_regs.grstctl);
+	writel(FIELD_PREP(GRSTCTL_TXFNUM_MASK, ep->fifo_num) | GRSTCTL_TXFFLSH,
+	       &reg->global_regs.grstctl);
+	while (readl(&reg->global_regs.grstctl) & GRSTCTL_TXFFLSH)
 		;
 
 	writel(phys_to_bus((unsigned long)ep->dma_buf), &reg->device_regs.in_endp[ep_num].diepdma);
-	writel(DIEPT_SIZ_PKT_CNT(pktcnt) | DIEPT_SIZ_XFER_SIZE(length),
+	writel(FIELD_PREP(DXEPTSIZ_PKTCNT_MASK, pktcnt) |
+	       FIELD_PREP(DXEPTSIZ_XFERSIZE_MASK, length),
 	       &reg->device_regs.in_endp[ep_num].dieptsiz);
 
 	ctrl = readl(&reg->device_regs.in_endp[ep_num].diepctl);
 
 	/* Write the FIFO number to be used for this endpoint */
-	ctrl &= ~DIEPCTL_TX_FIFO_NUM_MASK;
-	ctrl |= FIELD_PREP(DIEPCTL_TX_FIFO_NUM_MASK, ep->fifo_num);
+	ctrl &= ~DXEPCTL_TXFNUM_MASK;
+	ctrl |= FIELD_PREP(DXEPCTL_TXFNUM_MASK, ep->fifo_num);
 
 	/* Clear reserved (Next EP) bits */
-	ctrl &= ~DEPCTL_NEXT_EP_MASK;
+	ctrl &= ~DXEPCTL_NEXTEP_MASK;
 
-	writel(DEPCTL_EPENA|DEPCTL_CNAK|ctrl, &reg->device_regs.in_endp[ep_num].diepctl);
+	writel(DXEPCTL_EPENA | DXEPCTL_CNAK | ctrl, &reg->device_regs.in_endp[ep_num].diepctl);
 
 	debug_cond(DEBUG_IN_EP,
 		"%s:EP%d TX DMA start : DIEPDMA0 = 0x%x,"
@@ -214,9 +217,9 @@ static void complete_rx(struct dwc2_udc *dev, u8 ep_num)
 	ep_tsr = readl(&reg->device_regs.out_endp[ep_num].doeptsiz);
 
 	if (ep_num == EP0_CON)
-		xfer_size = (ep_tsr & DOEPT_SIZ_XFER_SIZE_MAX_EP0);
+		xfer_size = FIELD_PREP(DIEPTSIZ0_XFERSIZE_MASK, ep_tsr);
 	else
-		xfer_size = (ep_tsr & DOEPT_SIZ_XFER_SIZE_MAX_EP);
+		xfer_size = FIELD_PREP(DXEPTSIZ_XFERSIZE_MASK, ep_tsr);
 
 	xfer_size = ep->len - xfer_size;
 
@@ -384,7 +387,7 @@ static void process_ep_in_intr(struct dwc2_udc *dev)
 	ep_intr = FIELD_GET(DAINT_INEP_MASK, ep_intr);
 
 	while (ep_intr) {
-		if (ep_intr & DAINT_IN_EP_INT(1)) {
+		if (ep_intr & BIT(EP0_CON)) {
 			ep_intr_status = readl(&reg->device_regs.in_endp[ep_num].diepint);
 			debug_cond(DEBUG_IN_EP,
 				   "\tEP%d-IN : DIEPINT = 0x%x\n",
@@ -393,7 +396,7 @@ static void process_ep_in_intr(struct dwc2_udc *dev)
 			/* Interrupt Clear */
 			writel(ep_intr_status, &reg->device_regs.in_endp[ep_num].diepint);
 
-			if (ep_intr_status & TRANSFER_DONE) {
+			if (ep_intr_status & DIEPMSK_XFERCOMPLMSK) {
 				complete_tx(dev, ep_num);
 
 				if (ep_num == 0) {
@@ -445,10 +448,9 @@ static void process_ep_out_intr(struct dwc2_udc *dev)
 			writel(ep_intr_status, &reg->device_regs.out_endp[ep_num].doepint);
 
 			if (ep_num == 0) {
-				if (ep_intr_status & TRANSFER_DONE) {
+				if (ep_intr_status & DOEPMSK_XFERCOMPLMSK) {
 					ep_tsr = readl(&epsiz_reg);
-					xfer_size = ep_tsr &
-						   DOEPT_SIZ_XFER_SIZE_MAX_EP0;
+					xfer_size = ep_tsr & DOEPTSIZ0_XFERSIZE_MASK;
 
 					if (xfer_size == req_size &&
 					    dev->ep0state == WAIT_FOR_SETUP) {
@@ -462,14 +464,13 @@ static void process_ep_out_intr(struct dwc2_udc *dev)
 					}
 				}
 
-				if (ep_intr_status &
-				    CTRL_OUT_EP_SETUP_PHASE_DONE) {
+				if (ep_intr_status & DOEPMSK_SETUPMSK) {
 					debug_cond(DEBUG_OUT_EP != 0,
 						   "SETUP packet arrived\n");
 					dwc2_handle_ep0(dev);
 				}
 			} else {
-				if (ep_intr_status & TRANSFER_DONE)
+				if (ep_intr_status & DOEPMSK_XFERCOMPLMSK)
 					complete_rx(dev, ep_num);
 			}
 		}
@@ -504,13 +505,13 @@ static int dwc2_udc_irq(int irq, void *_dev)
 		return IRQ_HANDLED;
 	}
 
-	if (intr_status & INT_ENUMDONE) {
+	if (intr_status & GINTSTS_ENUMDONE) {
 		debug_cond(DEBUG_ISR, "\tSpeed Detection interrupt\n");
 
-		writel(INT_ENUMDONE, &reg->global_regs.gintsts);
-		usb_status = (readl(&reg->device_regs.dsts) & 0x6);
+		writel(GINTSTS_ENUMDONE, &reg->global_regs.gintsts);
+		usb_status = FIELD_GET(DSTS_ENUMSPD_MASK, readl(&reg->device_regs.dsts));
 
-		if (usb_status & (USB_FULL_30_60MHZ | USB_FULL_48MHZ)) {
+		if (usb_status != DSTS_ENUMSPD_HS) {
 			debug_cond(DEBUG_ISR,
 				   "\t\tFull Speed Detection\n");
 			set_max_pktsize(dev, USB_SPEED_FULL);
@@ -523,16 +524,16 @@ static int dwc2_udc_irq(int irq, void *_dev)
 		}
 	}
 
-	if (intr_status & INT_EARLY_SUSPEND) {
+	if (intr_status & GINTSTS_ERLYSUSP) {
 		debug_cond(DEBUG_ISR, "\tEarly suspend interrupt\n");
-		writel(INT_EARLY_SUSPEND, &reg->global_regs.gintsts);
+		writel(GINTSTS_ERLYSUSP, &reg->global_regs.gintsts);
 	}
 
-	if (intr_status & INT_SUSPEND) {
+	if (intr_status & GINTSTS_USBSUSP) {
 		usb_status = readl(&reg->device_regs.dsts);
 		debug_cond(DEBUG_ISR,
 			"\tSuspend interrupt :(DSTS):0x%x\n", usb_status);
-		writel(INT_SUSPEND, &reg->global_regs.gintsts);
+		writel(GINTSTS_USBSUSP, &reg->global_regs.gintsts);
 
 		if (dev->gadget.speed != USB_SPEED_UNKNOWN
 		    && dev->driver) {
@@ -541,7 +542,7 @@ static int dwc2_udc_irq(int irq, void *_dev)
 		}
 	}
 
-	if (intr_status & INT_OTG) {
+	if (intr_status & GINTSTS_OTGINT) {
 		gotgint = readl(&reg->global_regs.gotgint);
 		debug_cond(DEBUG_ISR,
 			   "\tOTG interrupt: (GOTGINT):0x%x\n", gotgint);
@@ -558,9 +559,9 @@ static int dwc2_udc_irq(int irq, void *_dev)
 		writel(gotgint, &reg->global_regs.gotgint);
 	}
 
-	if (intr_status & INT_RESUME) {
+	if (intr_status & GINTSTS_WKUPINT) {
 		debug_cond(DEBUG_ISR, "\tResume interrupt\n");
-		writel(INT_RESUME, &reg->global_regs.gintsts);
+		writel(GINTSTS_WKUPINT, &reg->global_regs.gintsts);
 
 		if (dev->gadget.speed != USB_SPEED_UNKNOWN
 		    && dev->driver
@@ -570,13 +571,13 @@ static int dwc2_udc_irq(int irq, void *_dev)
 		}
 	}
 
-	if (intr_status & INT_RESET) {
+	if (intr_status & GINTSTS_USBRST) {
 		usb_status = readl(&reg->global_regs.gotgctl);
 		debug_cond(DEBUG_ISR,
 			"\tReset interrupt - (GOTGCTL):0x%x\n", usb_status);
-		writel(INT_RESET, &reg->global_regs.gintsts);
+		writel(GINTSTS_USBRST, &reg->global_regs.gintsts);
 
-		if ((usb_status & 0xc0000) == (0x3 << 18)) {
+		if (usb_status & (GOTGCTL_ASESVLD | GOTGCTL_BSESVLD)) {
 			if (reset_available) {
 				debug_cond(DEBUG_ISR,
 					"\t\tOTG core got reset (%d)!!\n",
@@ -595,10 +596,10 @@ static int dwc2_udc_irq(int irq, void *_dev)
 		}
 	}
 
-	if (intr_status & INT_IN_EP)
+	if (intr_status & GINTSTS_IEPINT)
 		process_ep_in_intr(dev);
 
-	if (intr_status & INT_OUT_EP)
+	if (intr_status & GINTSTS_OEPINT)
 		process_ep_out_intr(dev);
 
 	spin_unlock_irqrestore(&dev->lock, flags);
@@ -770,7 +771,8 @@ static int dwc2_fifo_read(struct dwc2_ep *ep, void *cp, int max)
 static void udc_set_address(struct dwc2_udc *dev, unsigned char address)
 {
 	u32 ctrl = readl(&reg->device_regs.dcfg);
-	writel(DEVICE_ADDRESS(address) | ctrl, &reg->device_regs.dcfg);
+
+	writel(FIELD_PREP(DCFG_DEVADDR_MASK, address) | ctrl, &reg->device_regs.dcfg);
 
 	dwc2_udc_ep0_zlp(dev);
 
@@ -790,10 +792,10 @@ static inline void dwc2_udc_ep0_set_stall(struct dwc2_ep *ep)
 	ep_ctrl = readl(&reg->device_regs.in_endp[EP0_CON].diepctl);
 
 	/* set the disable and stall bits */
-	if (ep_ctrl & DEPCTL_EPENA)
-		ep_ctrl |= DEPCTL_EPDIS;
+	if (ep_ctrl & DXEPCTL_EPENA)
+		ep_ctrl |= DXEPCTL_EPDIS;
 
-	ep_ctrl |= DEPCTL_STALL;
+	ep_ctrl |= DXEPCTL_STALL;
 
 	writel(ep_ctrl, &reg->device_regs.in_endp[EP0_CON].diepctl);
 
@@ -939,11 +941,11 @@ static int dwc2_udc_get_status(struct dwc2_udc *dev,
 			   ROUND(sizeof(g_status), CONFIG_SYS_CACHELINE_SIZE));
 
 	writel(phys_to_bus(usb_ctrl_dma_addr), &reg->device_regs.in_endp[EP0_CON].diepdma);
-	writel(DIEPT_SIZ_PKT_CNT(1) | DIEPT_SIZ_XFER_SIZE(2),
+	writel(FIELD_PREP(DXEPTSIZ_PKTCNT_MASK, 1) | FIELD_PREP(DXEPTSIZ_XFERSIZE_MASK, 2),
 	       &reg->device_regs.in_endp[EP0_CON].dieptsiz);
 
 	ep_ctrl = readl(&reg->device_regs.in_endp[EP0_CON].diepctl);
-	writel(ep_ctrl | DEPCTL_EPENA | DEPCTL_CNAK,
+	writel(ep_ctrl | DXEPCTL_EPENA | DXEPCTL_CNAK,
 	       &reg->device_regs.in_endp[EP0_CON].diepctl);
 	dev->ep0state = WAIT_FOR_NULL_COMPLETE;
 
@@ -960,13 +962,13 @@ static void dwc2_udc_set_nak(struct dwc2_ep *ep)
 
 	if (ep_is_in(ep)) {
 		ep_ctrl = readl(&reg->device_regs.in_endp[ep_num].diepctl);
-		ep_ctrl |= DEPCTL_SNAK;
+		ep_ctrl |= DXEPCTL_SNAK;
 		writel(ep_ctrl, &reg->device_regs.in_endp[ep_num].diepctl);
 		debug("%s: set NAK, DIEPCTL%d = 0x%x\n",
 			__func__, ep_num, readl(&reg->device_regs.in_endp[ep_num].diepctl));
 	} else {
 		ep_ctrl = readl(&reg->device_regs.out_endp[ep_num].doepctl);
-		ep_ctrl |= DEPCTL_SNAK;
+		ep_ctrl |= DXEPCTL_SNAK;
 		writel(ep_ctrl, &reg->device_regs.out_endp[ep_num].doepctl);
 		debug("%s: set NAK, DOEPCTL%d = 0x%x\n",
 		      __func__, ep_num, readl(&reg->device_regs.out_endp[ep_num].doepctl));
@@ -987,10 +989,10 @@ static void dwc2_udc_ep_set_stall(struct dwc2_ep *ep)
 		ep_ctrl = readl(&reg->device_regs.in_endp[ep_num].diepctl);
 
 		/* set the disable and stall bits */
-		if (ep_ctrl & DEPCTL_EPENA)
-			ep_ctrl |= DEPCTL_EPDIS;
+		if (ep_ctrl & DXEPCTL_EPENA)
+			ep_ctrl |= DXEPCTL_EPDIS;
 
-		ep_ctrl |= DEPCTL_STALL;
+		ep_ctrl |= DXEPCTL_STALL;
 
 		writel(ep_ctrl, &reg->device_regs.in_endp[ep_num].diepctl);
 		debug("%s: set stall, DIEPCTL%d = 0x%x\n",
@@ -1000,7 +1002,7 @@ static void dwc2_udc_ep_set_stall(struct dwc2_ep *ep)
 		ep_ctrl = readl(&reg->device_regs.out_endp[ep_num].doepctl);
 
 		/* set the stall bit */
-		ep_ctrl |= DEPCTL_STALL;
+		ep_ctrl |= DXEPCTL_STALL;
 
 		writel(ep_ctrl, &reg->device_regs.out_endp[ep_num].doepctl);
 		debug("%s: set stall, DOEPCTL%d = 0x%x\n",
@@ -1022,7 +1024,7 @@ static void dwc2_udc_ep_clear_stall(struct dwc2_ep *ep)
 		ep_ctrl = readl(&reg->device_regs.in_endp[ep_num].diepctl);
 
 		/* clear stall bit */
-		ep_ctrl &= ~DEPCTL_STALL;
+		ep_ctrl &= ~DXEPCTL_STALL;
 
 		/*
 		 * USB Spec 9.4.5: For endpoints using data toggle, regardless
@@ -1032,7 +1034,7 @@ static void dwc2_udc_ep_clear_stall(struct dwc2_ep *ep)
 		 */
 		if (ep->bmAttributes == USB_ENDPOINT_XFER_INT
 		    || ep->bmAttributes == USB_ENDPOINT_XFER_BULK) {
-			ep_ctrl |= DEPCTL_SETD0PID; /* DATA0 */
+			ep_ctrl |= DXEPCTL_SETD0PID; /* DATA0 */
 		}
 
 		writel(ep_ctrl, &reg->device_regs.in_endp[ep_num].diepctl);
@@ -1043,11 +1045,11 @@ static void dwc2_udc_ep_clear_stall(struct dwc2_ep *ep)
 		ep_ctrl = readl(&reg->device_regs.out_endp[ep_num].doepctl);
 
 		/* clear stall bit */
-		ep_ctrl &= ~DEPCTL_STALL;
+		ep_ctrl &= ~DXEPCTL_STALL;
 
 		if (ep->bmAttributes == USB_ENDPOINT_XFER_INT
 		    || ep->bmAttributes == USB_ENDPOINT_XFER_BULK) {
-			ep_ctrl |= DEPCTL_SETD0PID; /* DATA0 */
+			ep_ctrl |= DXEPCTL_SETD0PID; /* DATA0 */
 		}
 
 		writel(ep_ctrl, &reg->device_regs.out_endp[ep_num].doepctl);
@@ -1126,12 +1128,12 @@ static void dwc2_udc_ep_activate(struct dwc2_ep *ep)
 
 	/* If the EP is already active don't change the EP Control
 	 * register. */
-	if (!(ep_ctrl & DEPCTL_USBACTEP)) {
-		ep_ctrl = (ep_ctrl & ~DEPCTL_TYPE_MASK) |
-			FIELD_PREP(DEPCTL_TYPE_MASK, ep->bmAttributes);
-		ep_ctrl = (ep_ctrl & ~DEPCTL_MPS_MASK) |
-			FIELD_PREP(DEPCTL_MPS_MASK, ep->ep.maxpacket);
-		ep_ctrl |= (DEPCTL_SETD0PID | DEPCTL_USBACTEP | DEPCTL_SNAK);
+	if (!(ep_ctrl & DXEPCTL_USBACTEP)) {
+		ep_ctrl = (ep_ctrl & ~DXEPCTL_EPTYPE_MASK) |
+			FIELD_PREP(DXEPCTL_EPTYPE_MASK, ep->bmAttributes);
+		ep_ctrl = (ep_ctrl & ~DXEPCTL_MPS_MASK) |
+			FIELD_PREP(DXEPCTL_MPS_MASK, ep->ep.maxpacket);
+		ep_ctrl |= (DXEPCTL_SETD0PID | DXEPCTL_USBACTEP | DXEPCTL_SNAK);
 
 		if (ep_is_in(ep)) {
 			writel(ep_ctrl, &reg->device_regs.in_endp[ep_num].diepctl);
diff --git a/drivers/usb/host/dwc2.c b/drivers/usb/host/dwc2.c
index d4245b9cb71c91adc658668dcf897bcb10366b73..ff7885f8195c0bc08669dd99ef6c94992c991945 100644
--- a/drivers/usb/host/dwc2.c
+++ b/drivers/usb/host/dwc2.c
@@ -88,10 +88,10 @@ static void init_fslspclksel(struct dwc2_core_regs *regs)
 	uint32_t phyclk;
 
 #if (DWC2_PHY_TYPE == DWC2_PHY_TYPE_FS)
-	phyclk = DWC2_HCFG_FSLSPCLKSEL_48_MHZ;	/* Full speed PHY */
+	phyclk = HCFG_FSLSPCLKSEL_48_MHZ;	/* Full speed PHY */
 #else
 	/* High speed PHY running at full speed or high speed */
-	phyclk = DWC2_HCFG_FSLSPCLKSEL_30_60_MHZ;
+	phyclk = HCFG_FSLSPCLKSEL_30_60_MHZ;
 #endif
 
 #ifdef DWC2_ULPI_FS_LS
@@ -99,13 +99,13 @@ static void init_fslspclksel(struct dwc2_core_regs *regs)
 	uint32_t hval = FIELD_GET(GHWCFG2_HS_PHY_TYPE_MASK, ghwcfg2);
 	uint32_t fval = FIELD_GET(GHWCFG2_FS_PHY_TYPE_MASK, ghwcfg2);
 
-	if (hval == 2 && fval == 1)
-		phyclk = DWC2_HCFG_FSLSPCLKSEL_48_MHZ;	/* Full speed PHY */
+	if (hval == GHWCFG2_FS_PHY_TYPE_SHARED_UTMI && fval == GHWCFG2_HS_PHY_TYPE_UTMI)
+		phyclk = HCFG_FSLSPCLKSEL_48_MHZ;	/* Full speed PHY */
 #endif
 
 	clrsetbits_le32(&regs->host_regs.hcfg,
-			DWC2_HCFG_FSLSPCLKSEL_MASK,
-			FIELD_PREP(DWC2_HCFG_FSLSPCLKSEL_MASK, phyclk));
+			HCFG_FSLSPCLKSEL_MASK,
+			FIELD_PREP(HCFG_FSLSPCLKSEL_MASK, phyclk));
 }
 
 /*
@@ -119,9 +119,9 @@ static void dwc_otg_flush_tx_fifo(struct udevice *dev,
 {
 	int ret;
 
-	writel(DWC2_GRSTCTL_TXFFLSH | FIELD_PREP(DWC2_GRSTCTL_TXFNUM_MASK, num),
+	writel(GRSTCTL_TXFFLSH | FIELD_PREP(GRSTCTL_TXFNUM_MASK, num),
 	       &regs->global_regs.grstctl);
-	ret = wait_for_bit_le32(&regs->global_regs.grstctl, DWC2_GRSTCTL_TXFFLSH,
+	ret = wait_for_bit_le32(&regs->global_regs.grstctl, GRSTCTL_TXFFLSH,
 				false, 1000, false);
 	if (ret)
 		dev_info(dev, "%s: Timeout!\n", __func__);
@@ -140,8 +140,8 @@ static void dwc_otg_flush_rx_fifo(struct udevice *dev,
 {
 	int ret;
 
-	writel(DWC2_GRSTCTL_RXFFLSH, &regs->global_regs.grstctl);
-	ret = wait_for_bit_le32(&regs->global_regs.grstctl, DWC2_GRSTCTL_RXFFLSH,
+	writel(GRSTCTL_RXFFLSH, &regs->global_regs.grstctl);
+	ret = wait_for_bit_le32(&regs->global_regs.grstctl, GRSTCTL_RXFFLSH,
 				false, 1000, false);
 	if (ret)
 		dev_info(dev, "%s: Timeout!\n", __func__);
@@ -160,14 +160,14 @@ static void dwc_otg_core_reset(struct udevice *dev,
 	int ret;
 
 	/* Wait for AHB master IDLE state. */
-	ret = wait_for_bit_le32(&regs->global_regs.grstctl, DWC2_GRSTCTL_AHBIDLE,
+	ret = wait_for_bit_le32(&regs->global_regs.grstctl, GRSTCTL_AHBIDLE,
 				true, 1000, false);
 	if (ret)
 		dev_info(dev, "%s: Timeout!\n", __func__);
 
 	/* Core Soft Reset */
-	writel(DWC2_GRSTCTL_CSFTRST, &regs->global_regs.grstctl);
-	ret = wait_for_bit_le32(&regs->global_regs.grstctl, DWC2_GRSTCTL_CSFTRST,
+	writel(GRSTCTL_CSFTRST, &regs->global_regs.grstctl);
+	ret = wait_for_bit_le32(&regs->global_regs.grstctl, GRSTCTL_CSFTRST,
 				false, 1000, false);
 	if (ret)
 		dev_info(dev, "%s: Timeout!\n", __func__);
@@ -255,60 +255,58 @@ static void dwc_otg_core_host_init(struct udevice *dev,
 	/* Initialize Host Configuration Register */
 	init_fslspclksel(regs);
 #ifdef DWC2_DFLT_SPEED_FULL
-	setbits_le32(&regs->host_regs.hcfg, DWC2_HCFG_FSLSSUPP);
+	setbits_le32(&regs->host_regs.hcfg, HCFG_FSLSSUPP);
 #endif
 
 	/* Configure data FIFO sizes */
 #ifdef DWC2_ENABLE_DYNAMIC_FIFO
-	if (readl(&regs->global_regs.ghwcfg2) & DWC2_HWCFG2_DYNAMIC_FIFO) {
+	if (readl(&regs->global_regs.ghwcfg2) & GHWCFG2_DYNAMIC_FIFO) {
 		/* Rx FIFO */
 		writel(DWC2_HOST_RX_FIFO_SIZE, &regs->global_regs.grxfsiz);
 
 		/* Non-periodic Tx FIFO */
-		nptxfifosize |= FIELD_PREP(DWC2_FIFOSIZE_DEPTH_MASK, DWC2_HOST_NPERIO_TX_FIFO_SIZE);
-		nptxfifosize |= FIELD_PREP(DWC2_FIFOSIZE_STARTADDR_MASK, DWC2_HOST_RX_FIFO_SIZE);
+		nptxfifosize |= FIELD_PREP(FIFOSIZE_DEPTH_MASK, DWC2_HOST_NPERIO_TX_FIFO_SIZE);
+		nptxfifosize |= FIELD_PREP(FIFOSIZE_STARTADDR_MASK, DWC2_HOST_RX_FIFO_SIZE);
 		writel(nptxfifosize, &regs->global_regs.gnptxfsiz);
 
 		/* Periodic Tx FIFO */
-		ptxfifosize |= FIELD_PREP(DWC2_FIFOSIZE_DEPTH_MASK, DWC2_HOST_PERIO_TX_FIFO_SIZE);
-		ptxfifosize |= FIELD_PREP(DWC2_FIFOSIZE_STARTADDR_MASK, DWC2_HOST_RX_FIFO_SIZE +
+		ptxfifosize |= FIELD_PREP(FIFOSIZE_DEPTH_MASK, DWC2_HOST_PERIO_TX_FIFO_SIZE);
+		ptxfifosize |= FIELD_PREP(FIFOSIZE_STARTADDR_MASK, DWC2_HOST_RX_FIFO_SIZE +
 					  DWC2_HOST_NPERIO_TX_FIFO_SIZE);
 		writel(ptxfifosize, &regs->global_regs.hptxfsiz);
 	}
 #endif
 
 	/* Clear Host Set HNP Enable in the OTG Control Register */
-	clrbits_le32(&regs->global_regs.gotgctl, DWC2_GOTGCTL_HSTSETHNPEN);
+	clrbits_le32(&regs->global_regs.gotgctl, GOTGCTL_HSTSETHNPEN);
 
 	/* Make sure the FIFOs are flushed. */
-	dwc_otg_flush_tx_fifo(dev, regs, 0x10);	/* All Tx FIFOs */
+	dwc_otg_flush_tx_fifo(dev, regs, GRSTCTL_TXFNUM_ALL);	/* All Tx FIFOs */
 	dwc_otg_flush_rx_fifo(dev, regs);
 
 	/* Flush out any leftover queued requests. */
-	num_channels = FIELD_GET(DWC2_HWCFG2_NUM_HOST_CHAN_MASK,
-				 readl(&regs->global_regs.ghwcfg2)) + 1;
+	num_channels = FIELD_GET(GHWCFG2_NUM_HOST_CHAN_MASK, readl(&regs->global_regs.ghwcfg2)) + 1;
 
 	for (i = 0; i < num_channels; i++)
-		clrsetbits_le32(&regs->host_regs.hc[i].hcchar,
-				DWC2_HCCHAR_CHEN | DWC2_HCCHAR_EPDIR,
-				DWC2_HCCHAR_CHDIS);
+		clrsetbits_le32(&regs->host_regs.hc[i].hcchar, HCCHAR_CHENA | HCCHAR_EPDIR,
+				HCCHAR_CHDIS);
 
 	/* Halt all channels to put them into a known state. */
 	for (i = 0; i < num_channels; i++) {
 		clrsetbits_le32(&regs->host_regs.hc[i].hcchar,
-				DWC2_HCCHAR_EPDIR,
-				DWC2_HCCHAR_CHEN | DWC2_HCCHAR_CHDIS);
+				HCCHAR_EPDIR,
+				HCCHAR_CHENA | HCCHAR_CHDIS);
 		ret = wait_for_bit_le32(&regs->host_regs.hc[i].hcchar,
-					DWC2_HCCHAR_CHEN, false, 1000, false);
+					HCCHAR_CHENA, false, 1000, false);
 		if (ret)
 			dev_info(dev, "%s: Timeout!\n", __func__);
 	}
 
 	/* Turn on the vbus power. */
-	if (readl(&regs->global_regs.gintsts) & DWC2_GINTSTS_CURMODE_HOST) {
-		hprt0 = readl(&regs->host_regs.hprt0) & ~DWC2_HPRT0_W1C_MASK;
-		if (!(hprt0 & DWC2_HPRT0_PRTPWR)) {
-			hprt0 |= DWC2_HPRT0_PRTPWR;
+	if (readl(&regs->global_regs.gintsts) & GINTSTS_CURMODE_HOST) {
+		hprt0 = readl(&regs->host_regs.hprt0) & ~HPRT0_W1C_MASK;
+		if (!(hprt0 & HPRT0_PWR)) {
+			hprt0 |= HPRT0_PWR;
 			writel(hprt0, &regs->host_regs.hprt0);
 		}
 	}
@@ -336,20 +334,20 @@ static void dwc_otg_core_init(struct udevice *dev)
 
 	/* Program the ULPI External VBUS bit if needed */
 	if (priv->ext_vbus) {
-		usbcfg |= DWC2_GUSBCFG_ULPI_EXT_VBUS_DRV;
+		usbcfg |= GUSBCFG_ULPI_EXT_VBUS_DRV;
 		if (!priv->oc_disable) {
-			usbcfg |= DWC2_GUSBCFG_ULPI_INT_VBUS_INDICATOR |
-				  DWC2_GUSBCFG_INDICATOR_PASSTHROUGH;
+			usbcfg |= GUSBCFG_ULPI_INT_VBUS_IND |
+				  GUSBCFG_INDICATORPASSTHROUGH;
 		}
 	} else {
-		usbcfg &= ~DWC2_GUSBCFG_ULPI_EXT_VBUS_DRV;
+		usbcfg &= ~GUSBCFG_ULPI_EXT_VBUS_DRV;
 	}
 
 	/* Set external TS Dline pulsing */
 #ifdef DWC2_TS_DLINE
-	usbcfg |= DWC2_GUSBCFG_TERM_SEL_DL_PULSE;
+	usbcfg |= GUSBCFG_TERMSELDLPULSE;
 #else
-	usbcfg &= ~DWC2_GUSBCFG_TERM_SEL_DL_PULSE;
+	usbcfg &= ~GUSBCFG_TERMSELDLPULSE;
 #endif
 	writel(usbcfg, &regs->global_regs.gusbcfg);
 
@@ -363,7 +361,7 @@ static void dwc_otg_core_init(struct udevice *dev)
 #if defined(DWC2_DFLT_SPEED_FULL) && \
 	(DWC2_PHY_TYPE == DWC2_PHY_TYPE_FS)
 	/* If FS mode with FS PHY */
-	setbits_le32(&regs->global_regs.gusbcfg, DWC2_GUSBCFG_PHYSEL);
+	setbits_le32(&regs->global_regs.gusbcfg, GUSBCFG_PHYSEL);
 
 	/* Reset after a PHY select */
 	dwc2_core_reset(regs);
@@ -373,18 +371,18 @@ static void dwc_otg_core_init(struct udevice *dev)
 	 * Also do this on HNP Dev/Host mode switches (done in dev_init
 	 * and host_init).
 	 */
-	if (readl(&regs->global_regs.gintsts) & DWC2_GINTSTS_CURMODE_HOST)
+	if (readl(&regs->global_regs.gintsts) & GINTSTS_CURMODE_HOST)
 		init_fslspclksel(regs);
 
 #ifdef DWC2_I2C_ENABLE
 	/* Program GUSBCFG.OtgUtmifsSel to I2C */
-	setbits_le32(&regs->global_regs.gusbcfg, DWC2_GUSBCFG_OTGUTMIFSSEL);
+	setbits_le32(&regs->global_regs.gusbcfg, GUSBCFG_OTG_UTMI_FS_SEL);
 
 	/* Program GI2CCTL.I2CEn */
-	clrsetbits_le32(&regs->global_regs.gi2cctl, DWC2_GI2CCTL_I2CEN |
-			DWC2_GI2CCTL_I2CDEVADDR_MASK,
-			FIELD_PREP(DWC2_GI2CCTL_I2CDEVADDR_MASK, 1));
-	setbits_le32(&regs->global_regs.gi2cctl, DWC2_GI2CCTL_I2CEN);
+	clrsetbits_le32(&regs->global_regs.gi2cctl, GI2CCTL_I2CEN |
+			GI2CCTL_I2CDEVADDR_MASK,
+			FIELD_PREP(GI2CCTL_I2CDEVADDR_MASK, 1));
+	setbits_le32(&regs->global_regs.gi2cctl, GI2CCTL_I2CEN);
 #endif
 
 #else
@@ -396,19 +394,19 @@ static void dwc_otg_core_init(struct udevice *dev)
 	 * immediately after setting phyif.
 	 */
 #if (DWC2_PHY_TYPE == DWC2_PHY_TYPE_ULPI)
-	usbcfg |= DWC2_GUSBCFG_ULPI_UTMI_SEL;
-	usbcfg &= ~DWC2_GUSBCFG_PHYIF;
+	usbcfg |= GUSBCFG_ULPI_UTMI_SEL;
+	usbcfg &= ~GUSBCFG_PHYIF16;
 #ifdef DWC2_PHY_ULPI_DDR
-	usbcfg |= DWC2_GUSBCFG_DDRSEL;
+	usbcfg |= GUSBCFG_DDRSEL;
 #else
-	usbcfg &= ~DWC2_GUSBCFG_DDRSEL;
+	usbcfg &= ~GUSBCFG_DDRSEL;
 #endif /* DWC2_PHY_ULPI_DDR */
 #elif (DWC2_PHY_TYPE == DWC2_PHY_TYPE_UTMI)
-	usbcfg &= ~DWC2_GUSBCFG_ULPI_UTMI_SEL;
+	usbcfg &= ~GUSBCFG_ULPI_UTMI_SEL;
 #if (DWC2_UTMI_WIDTH == 16)
-	usbcfg |= DWC2_GUSBCFG_PHYIF;
+	usbcfg |= GUSBCFG_PHYIF16;
 #else
-	usbcfg &= ~DWC2_GUSBCFG_PHYIF;
+	usbcfg &= ~GUSBCFG_PHYIF16;
 #endif /* DWC2_UTMI_WIDTH */
 #endif /* DWC2_PHY_TYPE */
 
@@ -419,37 +417,36 @@ static void dwc_otg_core_init(struct udevice *dev)
 #endif
 
 	usbcfg = readl(&regs->global_regs.gusbcfg);
-	usbcfg &= ~(DWC2_GUSBCFG_ULPI_FSLS | DWC2_GUSBCFG_ULPI_CLK_SUS_M);
+	usbcfg &= ~(GUSBCFG_ULPI_FS_LS | GUSBCFG_ULPI_CLK_SUSP_M);
 #ifdef DWC2_ULPI_FS_LS
 	uint32_t hwcfg2 = readl(&regs->global_regs.ghwcfg2);
-	uint32_t hval = FIELD_GET(DWC2_HWCFG2_HS_PHY_TYPE_MASK, ghwcfg2);
-	uint32_t fval = FIELD_GET(DWC2_HWCFG2_FS_PHY_TYPE_MASK, ghwcfg2);
-	if (hval == 2 && fval == 1) {
-		usbcfg |= DWC2_GUSBCFG_ULPI_FSLS;
-		usbcfg |= DWC2_GUSBCFG_ULPI_CLK_SUS_M;
+	uint32_t hval = FIELD_GET(GHWCFG2_HS_PHY_TYPE_MASK, ghwcfg2);
+	uint32_t fval = FIELD_GET(GHWCFG2_FS_PHY_TYPE_MASK, ghwcfg2);
+
+	if (hval == GHWCFG2_FS_PHY_TYPE_SHARED_UTMI && fval == GHWCFG2_HS_PHY_TYPE_UTMI) {
+		usbcfg |= GUSBCFG_ULPI_FS_LS;
+		usbcfg |= GUSBCFG_ULPI_CLK_SUSP_M;
 	}
 #endif
 	if (priv->hnp_srp_disable)
-		usbcfg |= DWC2_GUSBCFG_FORCEHOSTMODE;
+		usbcfg |= GUSBCFG_FORCEHOSTMODE;
 
 	writel(usbcfg, &regs->global_regs.gusbcfg);
 
 	/* Program the GAHBCFG Register. */
-	switch (FIELD_GET(DWC2_HWCFG2_ARCHITECTURE_MASK, readl(&regs->global_regs.ghwcfg2))) {
-	case DWC2_HWCFG2_ARCHITECTURE_SLAVE_ONLY:
+	switch (FIELD_GET(GHWCFG2_ARCHITECTURE_MASK, readl(&regs->global_regs.ghwcfg2))) {
+	case GHWCFG2_SLAVE_ONLY_ARCH:
 		break;
-	case DWC2_HWCFG2_ARCHITECTURE_EXT_DMA:
-		ahbcfg |= FIELD_PREP(DWC2_GAHBCFG_HBURSTLEN_MASK, LOG2(brst_sz >> 1));
-
+	case GHWCFG2_EXT_DMA_ARCH:
+		ahbcfg |= FIELD_PREP(GAHBCFG_HBSTLEN_MASK, LOG2(brst_sz >> 1));
 #ifdef DWC2_DMA_ENABLE
-		ahbcfg |= DWC2_GAHBCFG_DMAENABLE;
+		ahbcfg |= GAHBCFG_DMA_EN;
 #endif
 		break;
-
-	case DWC2_HWCFG2_ARCHITECTURE_INT_DMA:
-		ahbcfg |= DWC2_GAHBCFG_HBURSTLEN_INCR4;
+	case GHWCFG2_INT_DMA_ARCH:
+		ahbcfg |= FIELD_PREP(GAHBCFG_HBSTLEN_MASK, GAHBCFG_HBSTLEN_INCR4);
 #ifdef DWC2_DMA_ENABLE
-		ahbcfg |= DWC2_GAHBCFG_DMAENABLE;
+		ahbcfg |= GAHBCFG_DMA_EN;
 #endif
 		break;
 	}
@@ -460,9 +457,9 @@ static void dwc_otg_core_init(struct udevice *dev)
 	usbcfg = 0;
 
 	if (!priv->hnp_srp_disable)
-		usbcfg |= DWC2_GUSBCFG_HNPCAP | DWC2_GUSBCFG_SRPCAP;
+		usbcfg |= GUSBCFG_HNPCAP | GUSBCFG_SRPCAP;
 #ifdef DWC2_IC_USB_CAP
-	usbcfg |= DWC2_GUSBCFG_IC_USB_CAP;
+	usbcfg |= GUSBCFG_ICUSBCAP;
 #endif
 
 	setbits_le32(&regs->global_regs.gusbcfg, usbcfg);
@@ -482,14 +479,14 @@ static void dwc_otg_hc_init(struct dwc2_core_regs *regs, uint8_t hc_num,
 		uint8_t ep_is_in, uint8_t ep_type, uint16_t max_packet)
 {
 	struct dwc2_hc_regs *hc_regs = &regs->host_regs.hc[hc_num];
-	u32 hcchar = FIELD_PREP(DWC2_HCCHAR_DEVADDR_MASK, dev_addr) |
-			  FIELD_PREP(DWC2_HCCHAR_EPNUM_MASK, ep_num) |
-			  FIELD_PREP(DWC2_HCCHAR_EPDIR, ep_is_in) |
-			  FIELD_PREP(DWC2_HCCHAR_EPTYPE_MASK, ep_type) |
-			  FIELD_PREP(DWC2_HCCHAR_MPS_MASK, max_packet);
+	u32 hcchar = FIELD_PREP(HCCHAR_DEVADDR_MASK, dev_addr) |
+			  FIELD_PREP(HCCHAR_EPNUM_MASK, ep_num) |
+			  FIELD_PREP(HCCHAR_EPDIR, ep_is_in) |
+			  FIELD_PREP(HCCHAR_EPTYPE_MASK, ep_type) |
+			  FIELD_PREP(HCCHAR_MPS_MASK, max_packet);
 
 	if (dev->speed == USB_SPEED_LOW)
-		hcchar |= DWC2_HCCHAR_LSPDDEV;
+		hcchar |= HCCHAR_LSPDDEV;
 
 	/*
 	 * Program the HCCHARn register with the endpoint characteristics
@@ -506,9 +503,9 @@ static void dwc_otg_hc_init_split(struct dwc2_hc_regs *hc_regs,
 {
 	uint32_t hcsplt = 0;
 
-	hcsplt = DWC2_HCSPLT_SPLTENA;
-	hcsplt |= FIELD_PREP(DWC2_HCSPLT_HUBADDR_MASK, hub_devnum);
-	hcsplt |= FIELD_PREP(DWC2_HCSPLT_PRTADDR_MASK, hub_port);
+	hcsplt = HCSPLT_SPLTENA;
+	hcsplt |= FIELD_PREP(HCSPLT_HUBADDR_MASK, hub_devnum);
+	hcsplt |= FIELD_PREP(HCSPLT_PRTADDR_MASK, hub_port);
 
 	/* Program the HCSPLIT register for SPLITs */
 	writel(hcsplt, &hc_regs->hcsplt);
@@ -544,33 +541,33 @@ static int dwc_otg_submit_rh_msg_in_status(struct dwc2_core_regs *regs,
 		break;
 	case USB_RECIP_OTHER | USB_TYPE_CLASS:
 		hprt0 = readl(&regs->host_regs.hprt0);
-		if (hprt0 & DWC2_HPRT0_PRTCONNSTS)
+		if (hprt0 & HPRT0_CONNSTS)
 			port_status |= USB_PORT_STAT_CONNECTION;
-		if (hprt0 & DWC2_HPRT0_PRTENA)
+		if (hprt0 & HPRT0_ENA)
 			port_status |= USB_PORT_STAT_ENABLE;
-		if (hprt0 & DWC2_HPRT0_PRTSUSP)
+		if (hprt0 & HPRT0_SUSP)
 			port_status |= USB_PORT_STAT_SUSPEND;
-		if (hprt0 & DWC2_HPRT0_PRTOVRCURRACT)
+		if (hprt0 & HPRT0_OVRCURRACT)
 			port_status |= USB_PORT_STAT_OVERCURRENT;
-		if (hprt0 & DWC2_HPRT0_PRTRST)
+		if (hprt0 & HPRT0_RST)
 			port_status |= USB_PORT_STAT_RESET;
-		if (hprt0 & DWC2_HPRT0_PRTPWR)
+		if (hprt0 & HPRT0_PWR)
 			port_status |= USB_PORT_STAT_POWER;
 
-		switch (FIELD_GET(DWC2_HPRT0_PRTSPD_MASK, hprt0)) {
-		case DWC2_HPRT0_PRTSPD_LOW:
+		switch (FIELD_GET(HPRT0_SPD_MASK, hprt0)) {
+		case HPRT0_SPD_LOW_SPEED:
 			port_status |= USB_PORT_STAT_LOW_SPEED;
 			break;
-		case DWC2_HPRT0_PRTSPD_HIGH:
+		case HPRT0_SPD_HIGH_SPEED:
 			port_status |= USB_PORT_STAT_HIGH_SPEED;
 			break;
 		}
 
-		if (hprt0 & DWC2_HPRT0_PRTENCHNG)
+		if (hprt0 & HPRT0_ENACHG)
 			port_change |= USB_PORT_STAT_C_ENABLE;
-		if (hprt0 & DWC2_HPRT0_PRTCONNDET)
+		if (hprt0 & HPRT0_CONNDET)
 			port_change |= USB_PORT_STAT_C_CONNECTION;
-		if (hprt0 & DWC2_HPRT0_PRTOVRCURRCHNG)
+		if (hprt0 & HPRT0_OVRCURRCHG)
 			port_change |= USB_PORT_STAT_C_OVERCURRENT;
 
 		*(uint32_t *)buffer = cpu_to_le32(port_status |
@@ -736,8 +733,7 @@ static int dwc_otg_submit_rh_msg_out(struct dwc2_priv *priv,
 	case (USB_REQ_CLEAR_FEATURE << 8) | USB_RECIP_OTHER | USB_TYPE_CLASS:
 		switch (wValue) {
 		case USB_PORT_FEAT_C_CONNECTION:
-			clrsetbits_le32(&regs->host_regs.hprt0, DWC2_HPRT0_W1C_MASK,
-					DWC2_HPRT0_PRTCONNDET);
+			clrsetbits_le32(&regs->host_regs.hprt0, HPRT0_W1C_MASK, HPRT0_CONNDET);
 			break;
 		}
 		break;
@@ -748,16 +744,13 @@ static int dwc_otg_submit_rh_msg_out(struct dwc2_priv *priv,
 			break;
 
 		case USB_PORT_FEAT_RESET:
-			clrsetbits_le32(&regs->host_regs.hprt0, DWC2_HPRT0_W1C_MASK,
-					DWC2_HPRT0_PRTRST);
+			clrsetbits_le32(&regs->host_regs.hprt0, HPRT0_W1C_MASK, HPRT0_RST);
 			mdelay(50);
-			clrbits_le32(&regs->host_regs.hprt0,
-				     DWC2_HPRT0_W1C_MASK | DWC2_HPRT0_PRTRST);
+			clrbits_le32(&regs->host_regs.hprt0, HPRT0_W1C_MASK | HPRT0_RST);
 			break;
 
 		case USB_PORT_FEAT_POWER:
-			clrsetbits_le32(&regs->host_regs.hprt0, DWC2_HPRT0_W1C_MASK,
-					DWC2_HPRT0_PRTRST);
+			clrsetbits_le32(&regs->host_regs.hprt0, HPRT0_W1C_MASK, HPRT0_RST);
 			break;
 
 		case USB_PORT_FEAT_ENABLE:
@@ -808,23 +801,23 @@ int wait_for_chhltd(struct dwc2_hc_regs *hc_regs, uint32_t *sub, u8 *toggle)
 	int ret;
 	uint32_t hcint, hctsiz;
 
-	ret = wait_for_bit_le32(&hc_regs->hcint, DWC2_HCINT_CHHLTD, true,
+	ret = wait_for_bit_le32(&hc_regs->hcint, HCINTMSK_CHHLTD, true,
 				2000, false);
 	if (ret)
 		return ret;
 
 	hcint = readl(&hc_regs->hcint);
 	hctsiz = readl(&hc_regs->hctsiz);
-	*sub = FIELD_GET(DWC2_HCTSIZ_XFERSIZE_MASK, hctsiz);
-	*toggle = FIELD_GET(DWC2_HCTSIZ_PID_MASK, hctsiz);
+	*sub = FIELD_GET(TSIZ_XFERSIZE_MASK, hctsiz);
+	*toggle = FIELD_GET(TSIZ_SC_MC_PID_MASK, hctsiz);
 
 	debug("%s: HCINT=%08x sub=%u toggle=%d\n", __func__, hcint, *sub,
 	      *toggle);
 
-	if (hcint & DWC2_HCINT_XFERCOMP)
+	if (hcint & HCINTMSK_XFERCOMPL)
 		return 0;
 
-	if (hcint & (DWC2_HCINT_NAK | DWC2_HCINT_FRMOVRUN))
+	if (hcint & (HCINTMSK_NAK | HCINTMSK_FRMOVRUN))
 		return -EAGAIN;
 
 	debug("%s: Error (HCINT=%08x)\n", __func__, hcint);
@@ -832,10 +825,10 @@ int wait_for_chhltd(struct dwc2_hc_regs *hc_regs, uint32_t *sub, u8 *toggle)
 }
 
 static int dwc2_eptype[] = {
-	DWC2_HCCHAR_EPTYPE_ISOC,
-	DWC2_HCCHAR_EPTYPE_INTR,
-	DWC2_HCCHAR_EPTYPE_CONTROL,
-	DWC2_HCCHAR_EPTYPE_BULK,
+	HCCHAR_EPTYPE_ISOC,
+	HCCHAR_EPTYPE_INTR,
+	HCCHAR_EPTYPE_CONTROL,
+	HCCHAR_EPTYPE_BULK,
 };
 
 static int transfer_chunk(struct dwc2_hc_regs *hc_regs, void *aligned_buffer,
@@ -848,9 +841,9 @@ static int transfer_chunk(struct dwc2_hc_regs *hc_regs, void *aligned_buffer,
 	debug("%s: chunk: pid %d xfer_len %u pkts %u\n", __func__,
 	      *pid, xfer_len, num_packets);
 
-	writel(FIELD_PREP(DWC2_HCTSIZ_XFERSIZE_MASK, xfer_len) |
-	       FIELD_PREP(DWC2_HCTSIZ_PKTCNT_MASK, num_packets) |
-	       FIELD_PREP(DWC2_HCTSIZ_PID_MASK, *pid),
+	writel(FIELD_PREP(TSIZ_XFERSIZE_MASK, xfer_len) |
+	       FIELD_PREP(TSIZ_PKTCNT_MASK, num_packets) |
+	       FIELD_PREP(TSIZ_SC_MC_PID_MASK, *pid),
 	       &hc_regs->hctsiz);
 
 	if (xfer_len) {
@@ -874,12 +867,12 @@ static int transfer_chunk(struct dwc2_hc_regs *hc_regs, void *aligned_buffer,
 	writel(0x3fff, &hc_regs->hcint);
 
 	/* Set host channel enable after all other setup is complete. */
-	clrsetbits_le32(&hc_regs->hcchar, DWC2_HCCHAR_MULTICNT_MASK |
-			DWC2_HCCHAR_CHEN | DWC2_HCCHAR_CHDIS |
-			DWC2_HCCHAR_ODDFRM,
-			FIELD_PREP(DWC2_HCCHAR_MULTICNT_MASK, 1) |
-			FIELD_PREP(DWC2_HCCHAR_ODDFRM, odd_frame) |
-			DWC2_HCCHAR_CHEN);
+	clrsetbits_le32(&hc_regs->hcchar, HCCHAR_MULTICNT_MASK |
+			HCCHAR_CHENA | HCCHAR_CHDIS |
+			HCCHAR_ODDFRM,
+			FIELD_PREP(HCCHAR_MULTICNT_MASK, 1) |
+			FIELD_PREP(HCCHAR_ODDFRM, odd_frame) |
+			HCCHAR_CHENA);
 
 	ret = wait_for_chhltd(hc_regs, &sub, pid);
 	if (ret < 0)
@@ -942,7 +935,7 @@ int chunk_msg(struct dwc2_priv *priv, struct usb_device *dev,
 		uint8_t hub_port;
 		uint32_t hprt0 = readl(&regs->host_regs.hprt0);
 
-		if (FIELD_GET(DWC2_HPRT0_PRTSPD_MASK, hprt0) == DWC2_HPRT0_PRTSPD_HIGH) {
+		if (FIELD_GET(HPRT0_SPD_MASK, hprt0) == HPRT0_SPD_HIGH_SPEED) {
 			usb_find_usb2_hub_address_port(dev, &hub_addr,
 						       &hub_port);
 			dwc_otg_hc_init_split(hc_regs, hub_addr, hub_port);
@@ -967,11 +960,11 @@ int chunk_msg(struct dwc2_priv *priv, struct usb_device *dev,
 			num_packets = 1;
 
 		if (complete_split)
-			setbits_le32(&hc_regs->hcsplt, DWC2_HCSPLT_COMPSPLT);
+			setbits_le32(&hc_regs->hcsplt, HCSPLT_COMPSPLT);
 		else if (do_split)
-			clrbits_le32(&hc_regs->hcsplt, DWC2_HCSPLT_COMPSPLT);
+			clrbits_le32(&hc_regs->hcsplt, HCSPLT_COMPSPLT);
 
-		if (eptype == DWC2_HCCHAR_EPTYPE_INTR) {
+		if (eptype == HCCHAR_EPTYPE_INTR) {
 			int uframe_num = readl(&host_regs->hfnum);
 			if (!(uframe_num & 0x1))
 				odd_frame = 1;
@@ -984,18 +977,18 @@ int chunk_msg(struct dwc2_priv *priv, struct usb_device *dev,
 		hcint = readl(&hc_regs->hcint);
 		if (complete_split) {
 			stop_transfer = 0;
-			if (hcint & DWC2_HCINT_NYET) {
+			if (hcint & HCINTMSK_NYET) {
 				ret = 0;
-				int frame_num = FIELD_GET(DWC2_HFNUM_FRNUM_MASK,
+				int frame_num = FIELD_GET(HFNUM_FRNUM_MASK,
 							  readl(&host_regs->hfnum));
 
-				if (((frame_num - ssplit_frame_num) & DWC2_HFNUM_FRNUM_MASK) > 4)
+				if (((frame_num - ssplit_frame_num) & HFNUM_FRNUM_MASK) > 4)
 					ret = -EAGAIN;
 			} else
 				complete_split = 0;
 		} else if (do_split) {
-			if (hcint & DWC2_HCINT_ACK) {
-				ssplit_frame_num = FIELD_GET(DWC2_HFNUM_FRNUM_MASK,
+			if (hcint & HCINTMSK_ACK) {
+				ssplit_frame_num = FIELD_GET(HFNUM_FRNUM_MASK,
 							     readl(&host_regs->hfnum));
 				ret = 0;
 				complete_split = 1;
@@ -1174,8 +1167,7 @@ static int dwc2_init_common(struct udevice *dev, struct dwc2_priv *priv)
 	dev_info(dev, "Core Release: %x.%03x\n",
 		 snpsid >> 12 & 0xf, snpsid & 0xfff);
 
-	if (FIELD_GET(DWC2_SNPSID_DEVID_MASK, snpsid) != DWC2_SNPSID_DEVID_VER_2xx &&
-	    FIELD_GET(DWC2_SNPSID_DEVID_MASK, snpsid) != DWC2_SNPSID_DEVID_VER_3xx) {
+	if (FIELD_GET(GSNPSID_ID_MASK, snpsid) != GSNPSID_OTG_ID) {
 		dev_info(dev, "SNPSID invalid (not DWC2 OTG device): %08x\n",
 			 snpsid);
 		return -ENODEV;
@@ -1196,9 +1188,9 @@ static int dwc2_init_common(struct udevice *dev, struct dwc2_priv *priv)
 		dwc_otg_core_host_init(dev, regs);
 	}
 
-	clrsetbits_le32(&regs->host_regs.hprt0, DWC2_HPRT0_W1C_MASK, DWC2_HPRT0_PRTRST);
+	clrsetbits_le32(&regs->host_regs.hprt0, HPRT0_W1C_MASK, HPRT0_RST);
 	mdelay(50);
-	clrbits_le32(&regs->host_regs.hprt0, DWC2_HPRT0_W1C_MASK | DWC2_HPRT0_PRTRST);
+	clrbits_le32(&regs->host_regs.hprt0, HPRT0_W1C_MASK | HPRT0_RST);
 
 	for (i = 0; i < MAX_DEVICE; i++) {
 		for (j = 0; j < MAX_ENDPOINT; j++) {
@@ -1213,7 +1205,7 @@ static int dwc2_init_common(struct udevice *dev, struct dwc2_priv *priv)
 	 * is started (the bus is scanned) and  fixes the USB detection
 	 * problems with some problematic USB keys.
 	 */
-	if (readl(&regs->global_regs.gintsts) & DWC2_GINTSTS_CURMODE_HOST)
+	if (readl(&regs->global_regs.gintsts) & GINTSTS_CURMODE_HOST)
 		mdelay(1000);
 
 	printf("USB DWC2\n");
@@ -1224,7 +1216,7 @@ static int dwc2_init_common(struct udevice *dev, struct dwc2_priv *priv)
 static void dwc2_uninit_common(struct dwc2_core_regs *regs)
 {
 	/* Put everything in reset. */
-	clrsetbits_le32(&regs->host_regs.hprt0, DWC2_HPRT0_W1C_MASK, DWC2_HPRT0_PRTRST);
+	clrsetbits_le32(&regs->host_regs.hprt0, HPRT0_W1C_MASK, HPRT0_RST);
 }
 
 #if !CONFIG_IS_ENABLED(DM_USB)
diff --git a/drivers/usb/host/dwc2.h b/drivers/usb/host/dwc2.h
index 6bd98b481f2449e32f5ccf3dc5baca814a2f4a16..a01edc5eff3ac8ef89addff29d2df26952288ccc 100644
--- a/drivers/usb/host/dwc2.h
+++ b/drivers/usb/host/dwc2.h
@@ -8,356 +8,294 @@
 
 #include <linux/bitops.h>
 
-#define DWC2_GOTGCTL_SESREQSCS				BIT(0)
-#define DWC2_GOTGCTL_SESREQ				BIT(1)
-#define DWC2_GOTGCTL_HSTNEGSCS				BIT(8)
-#define DWC2_GOTGCTL_HNPREQ				BIT(9)
-#define DWC2_GOTGCTL_HSTSETHNPEN			BIT(10)
-#define DWC2_GOTGCTL_DEVHNPEN				BIT(11)
-#define DWC2_GOTGCTL_CONIDSTS				BIT(16)
-#define DWC2_GOTGCTL_DBNCTIME				BIT(17)
-#define DWC2_GOTGCTL_ASESVLD				BIT(18)
-#define DWC2_GOTGCTL_BSESVLD				BIT(19)
-#define DWC2_GOTGCTL_OTGVER				BIT(20)
-#define DWC2_GOTGINT_SESENDDET				BIT(2)
-#define DWC2_GOTGINT_SESREQSUCSTSCHNG			BIT(8)
-#define DWC2_GOTGINT_HSTNEGSUCSTSCHNG			BIT(9)
-#define DWC2_GOTGINT_RESERVER10_16_MASK			GENMASK(16, 10)
-#define DWC2_GOTGINT_HSTNEGDET				BIT(17)
-#define DWC2_GOTGINT_ADEVTOUTCHNG			BIT(18)
-#define DWC2_GOTGINT_DEBDONE				BIT(19)
-#define DWC2_GAHBCFG_GLBLINTRMSK			BIT(0)
-#define DWC2_GAHBCFG_HBURSTLEN_SINGLE			(0 << 1)
-#define DWC2_GAHBCFG_HBURSTLEN_INCR			(1 << 1)
-#define DWC2_GAHBCFG_HBURSTLEN_INCR4			(3 << 1)
-#define DWC2_GAHBCFG_HBURSTLEN_INCR8			(5 << 1)
-#define DWC2_GAHBCFG_HBURSTLEN_INCR16			(7 << 1)
-#define DWC2_GAHBCFG_HBURSTLEN_MASK			GENMASK(4, 1)
-#define DWC2_GAHBCFG_DMAENABLE				BIT(5)
-#define DWC2_GAHBCFG_NPTXFEMPLVL_TXFEMPLVL		BIT(7)
-#define DWC2_GAHBCFG_PTXFEMPLVL				BIT(8)
-#define DWC2_GUSBCFG_TOUTCAL_MASK			GENMASK(2, 0)
-#define DWC2_GUSBCFG_PHYIF				BIT(3)
-#define DWC2_GUSBCFG_ULPI_UTMI_SEL			BIT(4)
-#define DWC2_GUSBCFG_FSINTF				BIT(5)
-#define DWC2_GUSBCFG_PHYSEL				BIT(6)
-#define DWC2_GUSBCFG_DDRSEL				BIT(7)
-#define DWC2_GUSBCFG_SRPCAP				BIT(8)
-#define DWC2_GUSBCFG_HNPCAP				BIT(9)
-#define DWC2_GUSBCFG_USBTRDTIM_MASK			GENMASK(13, 10)
-#define DWC2_GUSBCFG_NPTXFRWNDEN			BIT(14)
-#define DWC2_GUSBCFG_PHYLPWRCLKSEL			BIT(15)
-#define DWC2_GUSBCFG_OTGUTMIFSSEL			BIT(16)
-#define DWC2_GUSBCFG_ULPI_FSLS				BIT(17)
-#define DWC2_GUSBCFG_ULPI_AUTO_RES			BIT(18)
-#define DWC2_GUSBCFG_ULPI_CLK_SUS_M			BIT(19)
-#define DWC2_GUSBCFG_ULPI_EXT_VBUS_DRV			BIT(20)
-#define DWC2_GUSBCFG_ULPI_INT_VBUS_INDICATOR		BIT(21)
-#define DWC2_GUSBCFG_TERM_SEL_DL_PULSE			BIT(22)
-#define DWC2_GUSBCFG_INDICATOR_PASSTHROUGH		BIT(24)
-#define DWC2_GUSBCFG_IC_USB_CAP				BIT(26)
-#define DWC2_GUSBCFG_IC_TRAFFIC_PULL_REMOVE		BIT(27)
-#define DWC2_GUSBCFG_TX_END_DELAY			BIT(28)
-#define DWC2_GUSBCFG_FORCEHOSTMODE			BIT(29)
-#define DWC2_GUSBCFG_FORCEDEVMODE			BIT(30)
-#define DWC2_GLPMCTL_LPM_CAP_EN				BIT(0)
-#define DWC2_GLPMCTL_APPL_RESP				BIT(1)
-#define DWC2_GLPMCTL_HIRD_MASK				GENMASK(5, 2)
-#define DWC2_GLPMCTL_REM_WKUP_EN			BIT(6)
-#define DWC2_GLPMCTL_EN_UTMI_SLEEP			BIT(7)
-#define DWC2_GLPMCTL_HIRD_THRES_MASK			GENMASK(12, 8)
-#define DWC2_GLPMCTL_LPM_RESP_MASK			GENMASK(14, 13)
-#define DWC2_GLPMCTL_PRT_SLEEP_STS			BIT(15)
-#define DWC2_GLPMCTL_SLEEP_STATE_RESUMEOK		BIT(16)
-#define DWC2_GLPMCTL_LPM_CHAN_INDEX_MASK		GENMASK(20, 17)
-#define DWC2_GLPMCTL_RETRY_COUNT_MASK			GENMASK(23, 21)
-#define DWC2_GLPMCTL_SEND_LPM				BIT(24)
-#define DWC2_GLPMCTL_RETRY_COUNT_STS_MASK		GENMASK(27, 25)
-#define DWC2_GLPMCTL_HSIC_CONNECT			BIT(30)
-#define DWC2_GLPMCTL_INV_SEL_HSIC			BIT(31)
-#define DWC2_GRSTCTL_CSFTRST				BIT(0)
-#define DWC2_GRSTCTL_HSFTRST				BIT(1)
-#define DWC2_GRSTCTL_HSTFRM				BIT(2)
-#define DWC2_GRSTCTL_INTKNQFLSH				BIT(3)
-#define DWC2_GRSTCTL_RXFFLSH				BIT(4)
-#define DWC2_GRSTCTL_TXFFLSH				BIT(5)
-#define DWC2_GRSTCTL_TXFNUM_MASK			GENMASK(10, 6)
-#define DWC2_GRSTCTL_DMAREQ				BIT(30)
-#define DWC2_GRSTCTL_AHBIDLE				BIT(31)
-#define DWC2_GINTMSK_MODEMISMATCH			BIT(1)
-#define DWC2_GINTMSK_OTGINTR				BIT(2)
-#define DWC2_GINTMSK_SOFINTR				BIT(3)
-#define DWC2_GINTMSK_RXSTSQLVL				BIT(4)
-#define DWC2_GINTMSK_NPTXFEMPTY				BIT(5)
-#define DWC2_GINTMSK_GINNAKEFF				BIT(6)
-#define DWC2_GINTMSK_GOUTNAKEFF				BIT(7)
-#define DWC2_GINTMSK_I2CINTR				BIT(9)
-#define DWC2_GINTMSK_ERLYSUSPEND			BIT(10)
-#define DWC2_GINTMSK_USBSUSPEND				BIT(11)
-#define DWC2_GINTMSK_USBRESET				BIT(12)
-#define DWC2_GINTMSK_ENUMDONE				BIT(13)
-#define DWC2_GINTMSK_ISOOUTDROP				BIT(14)
-#define DWC2_GINTMSK_EOPFRAME				BIT(15)
-#define DWC2_GINTMSK_EPMISMATCH				BIT(17)
-#define DWC2_GINTMSK_INEPINTR				BIT(18)
-#define DWC2_GINTMSK_OUTEPINTR				BIT(19)
-#define DWC2_GINTMSK_INCOMPLISOIN			BIT(20)
-#define DWC2_GINTMSK_INCOMPLISOOUT			BIT(21)
-#define DWC2_GINTMSK_PORTINTR				BIT(24)
-#define DWC2_GINTMSK_HCINTR				BIT(25)
-#define DWC2_GINTMSK_PTXFEMPTY				BIT(26)
-#define DWC2_GINTMSK_LPMTRANRCVD			BIT(27)
-#define DWC2_GINTMSK_CONIDSTSCHNG			BIT(28)
-#define DWC2_GINTMSK_DISCONNECT				BIT(29)
-#define DWC2_GINTMSK_SESSREQINTR			BIT(30)
-#define DWC2_GINTMSK_WKUPINTR				BIT(31)
-#define DWC2_GINTSTS_CURMODE_HOST			BIT(0)
-#define DWC2_GINTSTS_MODEMISMATCH			BIT(1)
-#define DWC2_GINTSTS_OTGINTR				BIT(2)
-#define DWC2_GINTSTS_SOFINTR				BIT(3)
-#define DWC2_GINTSTS_RXSTSQLVL				BIT(4)
-#define DWC2_GINTSTS_NPTXFEMPTY				BIT(5)
-#define DWC2_GINTSTS_GINNAKEFF				BIT(6)
-#define DWC2_GINTSTS_GOUTNAKEFF				BIT(7)
-#define DWC2_GINTSTS_I2CINTR				BIT(9)
-#define DWC2_GINTSTS_ERLYSUSPEND			BIT(10)
-#define DWC2_GINTSTS_USBSUSPEND				BIT(11)
-#define DWC2_GINTSTS_USBRESET				BIT(12)
-#define DWC2_GINTSTS_ENUMDONE				BIT(13)
-#define DWC2_GINTSTS_ISOOUTDROP				BIT(14)
-#define DWC2_GINTSTS_EOPFRAME				BIT(15)
-#define DWC2_GINTSTS_INTOKENRX				BIT(16)
-#define DWC2_GINTSTS_EPMISMATCH				BIT(17)
-#define DWC2_GINTSTS_INEPINT				BIT(18)
-#define DWC2_GINTSTS_OUTEPINTR				BIT(19)
-#define DWC2_GINTSTS_INCOMPLISOIN			BIT(20)
-#define DWC2_GINTSTS_INCOMPLISOOUT			BIT(21)
-#define DWC2_GINTSTS_PORTINTR				BIT(24)
-#define DWC2_GINTSTS_HCINTR				BIT(25)
-#define DWC2_GINTSTS_PTXFEMPTY				BIT(26)
-#define DWC2_GINTSTS_LPMTRANRCVD			BIT(27)
-#define DWC2_GINTSTS_CONIDSTSCHNG			BIT(28)
-#define DWC2_GINTSTS_DISCONNECT				BIT(29)
-#define DWC2_GINTSTS_SESSREQINTR			BIT(30)
-#define DWC2_GINTSTS_WKUPINTR				BIT(31)
-#define DWC2_GRXSTS_EPNUM_MASK				GENMASK(3, 0)
-#define DWC2_GRXSTS_BCNT_MASK				GENMASK(14, 4)
-#define DWC2_GRXSTS_DPID_MASK				GENMASK(16, 15)
-#define DWC2_GRXSTS_PKTSTS_MASK				GENMASK(20, 17)
-#define DWC2_GRXSTS_FN_MASK				GENMASK(24, 21)
-#define DWC2_FIFOSIZE_STARTADDR_MASK			GENMASK(15, 0)
-#define DWC2_FIFOSIZE_DEPTH_MASK			GENMASK(31, 16)
-#define DWC2_GNPTXSTS_NPTXFSPCAVAIL_MASK		GENMASK(15, 0)
-#define DWC2_GNPTXSTS_NPTXQSPCAVAIL_MASK		GENMASK(23, 16)
-#define DWC2_GNPTXSTS_NPTXQTOP_TERMINATE		BIT(24)
-#define DWC2_GNPTXSTS_NPTXQTOP_TOKEN_MASK		GENMASK(26, 25)
-#define DWC2_GNPTXSTS_NPTXQTOP_CHNEP_MASK		GENMASK(30, 27)
-#define DWC2_DTXFSTS_TXFSPCAVAIL_MASK			GENMASK(15, 0)
-#define DWC2_GI2CCTL_RWDATA_MASK			GENMASK(7, 0)
-#define DWC2_GI2CCTL_REGADDR_MASK			GENMASK(15, 8)
-#define DWC2_GI2CCTL_ADDR_MASK				GENMASK(22, 16)
-#define DWC2_GI2CCTL_I2CEN				BIT(23)
-#define DWC2_GI2CCTL_ACK				BIT(24)
-#define DWC2_GI2CCTL_I2CSUSPCTL				BIT(25)
-#define DWC2_GI2CCTL_I2CDEVADDR_MASK			GENMASK(27, 26)
-#define DWC2_GI2CCTL_RW					BIT(30)
-#define DWC2_GI2CCTL_BSYDNE				BIT(31)
-#define DWC2_HWCFG1_EP_DIR0_MASK			GENMASK(1, 0)
-#define DWC2_HWCFG1_EP_DIR1_MASK			GENMASK(3, 2)
-#define DWC2_HWCFG1_EP_DIR2_MASK			GENMASK(5, 4)
-#define DWC2_HWCFG1_EP_DIR3_MASK			GENMASK(7, 6)
-#define DWC2_HWCFG1_EP_DIR4_MASK			GENMASK(9, 8)
-#define DWC2_HWCFG1_EP_DIR5_MASK			GENMASK(11, 10)
-#define DWC2_HWCFG1_EP_DIR6_MASK			GENMASK(13, 12)
-#define DWC2_HWCFG1_EP_DIR7_MASK			GENMASK(15, 14)
-#define DWC2_HWCFG1_EP_DIR8_MASK			GENMASK(17, 16)
-#define DWC2_HWCFG1_EP_DIR9_MASK			GENMASK(19, 18)
-#define DWC2_HWCFG1_EP_DIR10_MASK			GENMASK(21, 20)
-#define DWC2_HWCFG1_EP_DIR11_MASK			GENMASK(23, 22)
-#define DWC2_HWCFG1_EP_DIR12_MASK			GENMASK(25, 24)
-#define DWC2_HWCFG1_EP_DIR13_MASK			GENMASK(27, 26)
-#define DWC2_HWCFG1_EP_DIR14_MASK			GENMASK(29, 28)
-#define DWC2_HWCFG1_EP_DIR15_MASK			GENMASK(31, 30)
-#define DWC2_HWCFG2_OP_MODE_MASK			GENMASK(2, 0)
-#define DWC2_HWCFG2_ARCHITECTURE_SLAVE_ONLY		(0x0 << 3)
-#define DWC2_HWCFG2_ARCHITECTURE_EXT_DMA		(0x1 << 3)
-#define DWC2_HWCFG2_ARCHITECTURE_INT_DMA		(0x2 << 3)
-#define DWC2_HWCFG2_ARCHITECTURE_MASK			GENMASK(4, 3)
-#define DWC2_HWCFG2_POINT2POINT				BIT(5)
-#define DWC2_HWCFG2_HS_PHY_TYPE_MASK			GENMASK(7, 6)
-#define DWC2_HWCFG2_FS_PHY_TYPE_MASK			GENMASK(9, 8)
-#define DWC2_HWCFG2_NUM_DEV_EP_MASK			GENMASK(13, 10)
-#define DWC2_HWCFG2_NUM_HOST_CHAN_MASK			GENMASK(17, 14)
-#define DWC2_HWCFG2_PERIO_EP_SUPPORTED			BIT(18)
-#define DWC2_HWCFG2_DYNAMIC_FIFO			BIT(19)
-#define DWC2_HWCFG2_MULTI_PROC_INT			BIT(20)
-#define DWC2_HWCFG2_NONPERIO_TX_Q_DEPTH_MASK		GENMASK(23, 22)
-#define DWC2_HWCFG2_HOST_PERIO_TX_Q_DEPTH_MASK		GENMASK(25, 24)
-#define DWC2_HWCFG2_DEV_TOKEN_Q_DEPTH_MASK		GENMASK(30, 26)
-#define DWC2_HWCFG3_XFER_SIZE_CNTR_WIDTH_MASK		GENMASK(3, 0)
-#define DWC2_HWCFG3_PACKET_SIZE_CNTR_WIDTH_MASK		GENMASK(6, 4)
-#define DWC2_HWCFG3_OTG_FUNC				BIT(7)
-#define DWC2_HWCFG3_I2C					BIT(8)
-#define DWC2_HWCFG3_VENDOR_CTRL_IF			BIT(9)
-#define DWC2_HWCFG3_OPTIONAL_FEATURES			BIT(10)
-#define DWC2_HWCFG3_SYNCH_RESET_TYPE			BIT(11)
-#define DWC2_HWCFG3_OTG_ENABLE_IC_USB			BIT(12)
-#define DWC2_HWCFG3_OTG_ENABLE_HSIC			BIT(13)
-#define DWC2_HWCFG3_OTG_LPM_EN				BIT(15)
-#define DWC2_HWCFG3_DFIFO_DEPTH_MASK			GENMASK(31, 16)
-#define DWC2_HWCFG4_NUM_DEV_PERIO_IN_EP_MASK		GENMASK(3, 0)
-#define DWC2_HWCFG4_POWER_OPTIMIZ			BIT(4)
-#define DWC2_HWCFG4_MIN_AHB_FREQ_MASK			GENMASK(13, 5)
-#define DWC2_HWCFG4_UTMI_PHY_DATA_WIDTH_MASK		GENMASK(15, 14)
-#define DWC2_HWCFG4_NUM_DEV_MODE_CTRL_EP_MASK		GENMASK(19, 16)
-#define DWC2_HWCFG4_IDDIG_FILT_EN			BIT(20)
-#define DWC2_HWCFG4_VBUS_VALID_FILT_EN			BIT(21)
-#define DWC2_HWCFG4_A_VALID_FILT_EN			BIT(22)
-#define DWC2_HWCFG4_B_VALID_FILT_EN			BIT(23)
-#define DWC2_HWCFG4_SESSION_END_FILT_EN			BIT(24)
-#define DWC2_HWCFG4_DED_FIFO_EN				BIT(25)
-#define DWC2_HWCFG4_NUM_IN_EPS_MASK			GENMASK(29, 26)
-#define DWC2_HWCFG4_DESC_DMA				BIT(30)
-#define DWC2_HWCFG4_DESC_DMA_DYN			BIT(31)
-#define DWC2_HCFG_FSLSPCLKSEL_30_60_MHZ			0
-#define DWC2_HCFG_FSLSPCLKSEL_48_MHZ			1
-#define DWC2_HCFG_FSLSPCLKSEL_6_MHZ			2
-#define DWC2_HCFG_FSLSPCLKSEL_MASK			GENMASK(1, 0)
-#define DWC2_HCFG_FSLSSUPP				BIT(2)
-#define DWC2_HCFG_DESCDMA				BIT(23)
-#define DWC2_HCFG_FRLISTEN_MASK				GENMASK(25, 24)
-#define DWC2_HCFG_PERSCHEDENA				BIT(26)
-#define DWC2_HCFG_PERSCHEDSTAT				BIT(27)
-#define DWC2_HFIR_FRINT_MASK				GENMASK(15, 0)
-#define DWC2_HFNUM_FRNUM_MASK				GENMASK(15, 0)
-#define DWC2_HFNUM_FRREM_MASK				GENMASK(31, 16)
-#define DWC2_HFNUM_MAX_FRNUM				0x3FFF
-#define DWC2_HPTXSTS_PTXFSPCAVAIL_MASK			GENMASK(15, 0)
-#define DWC2_HPTXSTS_PTXQSPCAVAIL_MASK			GENMASK(23, 16)
-#define DWC2_HPTXSTS_PTXQTOP_TERMINATE			BIT(24)
-#define DWC2_HPTXSTS_PTXQTOP_TOKEN_MASK			GENMASK(26, 25)
-#define DWC2_HPTXSTS_PTXQTOP_CHNUM_MASK			GENMASK(30, 27)
-#define DWC2_HPTXSTS_PTXQTOP_ODD			BIT(31)
-#define DWC2_HPRT0_PRTCONNSTS				BIT(0)
-#define DWC2_HPRT0_PRTCONNDET				BIT(1)
-#define DWC2_HPRT0_PRTENA				BIT(2)
-#define DWC2_HPRT0_PRTENCHNG				BIT(3)
-#define DWC2_HPRT0_PRTOVRCURRACT			BIT(4)
-#define DWC2_HPRT0_PRTOVRCURRCHNG			BIT(5)
-#define DWC2_HPRT0_PRTRES				BIT(6)
-#define DWC2_HPRT0_PRTSUSP				BIT(7)
-#define DWC2_HPRT0_PRTRST				BIT(8)
-#define DWC2_HPRT0_PRTLNSTS_MASK			GENMASK(11, 10)
-#define DWC2_HPRT0_PRTPWR				BIT(12)
-#define DWC2_HPRT0_PRTTSTCTL_MASK			GENMASK(16, 13)
-#define DWC2_HPRT0_PRTSPD_HIGH				(0 << 17)
-#define DWC2_HPRT0_PRTSPD_FULL				(1 << 17)
-#define DWC2_HPRT0_PRTSPD_LOW				(2 << 17)
-#define DWC2_HPRT0_PRTSPD_MASK				GENMASK(18, 17)
-#define DWC2_HPRT0_W1C_MASK				(DWC2_HPRT0_PRTCONNDET | \
-							DWC2_HPRT0_PRTENA | \
-							DWC2_HPRT0_PRTENCHNG | \
-							DWC2_HPRT0_PRTOVRCURRCHNG)
-#define DWC2_HAINT_CH0					BIT(0)
-#define DWC2_HAINT_CH1					BIT(1)
-#define DWC2_HAINT_CH2					BIT(2)
-#define DWC2_HAINT_CH3					BIT(3)
-#define DWC2_HAINT_CH4					BIT(4)
-#define DWC2_HAINT_CH5					BIT(5)
-#define DWC2_HAINT_CH6					BIT(6)
-#define DWC2_HAINT_CH7					BIT(7)
-#define DWC2_HAINT_CH8					BIT(8)
-#define DWC2_HAINT_CH9					BIT(9)
-#define DWC2_HAINT_CH10					BIT(10)
-#define DWC2_HAINT_CH11					BIT(11)
-#define DWC2_HAINT_CH12					BIT(12)
-#define DWC2_HAINT_CH13					BIT(13)
-#define DWC2_HAINT_CH14					BIT(14)
-#define DWC2_HAINT_CH15					BIT(15)
-#define DWC2_HAINT_CHINT_MASK				GENMASK(15, 0)
-#define DWC2_HAINTMSK_CH0				BIT(0)
-#define DWC2_HAINTMSK_CH1				BIT(1)
-#define DWC2_HAINTMSK_CH2				BIT(2)
-#define DWC2_HAINTMSK_CH3				BIT(3)
-#define DWC2_HAINTMSK_CH4				BIT(4)
-#define DWC2_HAINTMSK_CH5				BIT(5)
-#define DWC2_HAINTMSK_CH6				BIT(6)
-#define DWC2_HAINTMSK_CH7				BIT(7)
-#define DWC2_HAINTMSK_CH8				BIT(8)
-#define DWC2_HAINTMSK_CH9				BIT(9)
-#define DWC2_HAINTMSK_CH10				BIT(10)
-#define DWC2_HAINTMSK_CH11				BIT(11)
-#define DWC2_HAINTMSK_CH12				BIT(12)
-#define DWC2_HAINTMSK_CH13				BIT(13)
-#define DWC2_HAINTMSK_CH14				BIT(14)
-#define DWC2_HAINTMSK_CH15				BIT(15)
-#define DWC2_HAINTMSK_CHINT_MASK			GENMASK(15, 0)
-#define DWC2_HCCHAR_MPS_MASK				GENMASK(10, 0)
-#define DWC2_HCCHAR_EPNUM_MASK				GENMASK(14, 11)
-#define DWC2_HCCHAR_EPDIR				BIT(15)
-#define DWC2_HCCHAR_LSPDDEV				BIT(17)
-#define DWC2_HCCHAR_EPTYPE_CONTROL			0
-#define DWC2_HCCHAR_EPTYPE_ISOC				1
-#define DWC2_HCCHAR_EPTYPE_BULK				2
-#define DWC2_HCCHAR_EPTYPE_INTR				3
-#define DWC2_HCCHAR_EPTYPE_MASK				GENMASK(19, 18)
-#define DWC2_HCCHAR_MULTICNT_MASK			GENMASK(21, 20)
-#define DWC2_HCCHAR_DEVADDR_MASK			GENMASK(28, 22)
-#define DWC2_HCCHAR_ODDFRM				BIT(29)
-#define DWC2_HCCHAR_CHDIS				BIT(30)
-#define DWC2_HCCHAR_CHEN				BIT(31)
-#define DWC2_HCSPLT_PRTADDR_MASK			GENMASK(6, 0)
-#define DWC2_HCSPLT_HUBADDR_MASK			GENMASK(13, 7)
-#define DWC2_HCSPLT_XACTPOS_MASK			GENMASK(15, 14)
-#define DWC2_HCSPLT_COMPSPLT				BIT(16)
-#define DWC2_HCSPLT_SPLTENA				BIT(31)
-#define DWC2_HCINT_XFERCOMP				BIT(0)
-#define DWC2_HCINT_CHHLTD				BIT(1)
-#define DWC2_HCINT_AHBERR				BIT(2)
-#define DWC2_HCINT_STALL				BIT(3)
-#define DWC2_HCINT_NAK					BIT(4)
-#define DWC2_HCINT_ACK					BIT(5)
-#define DWC2_HCINT_NYET					BIT(6)
-#define DWC2_HCINT_XACTERR				BIT(7)
-#define DWC2_HCINT_BBLERR				BIT(8)
-#define DWC2_HCINT_FRMOVRUN				BIT(9)
-#define DWC2_HCINT_DATATGLERR				BIT(10)
-#define DWC2_HCINT_BNA					BIT(11)
-#define DWC2_HCINT_XCS_XACT				BIT(12)
-#define DWC2_HCINT_FRM_LIST_ROLL			BIT(13)
-#define DWC2_HCINTMSK_XFERCOMPL				BIT(0)
-#define DWC2_HCINTMSK_CHHLTD				BIT(1)
-#define DWC2_HCINTMSK_AHBERR				BIT(2)
-#define DWC2_HCINTMSK_STALL				BIT(3)
-#define DWC2_HCINTMSK_NAK				BIT(4)
-#define DWC2_HCINTMSK_ACK				BIT(5)
-#define DWC2_HCINTMSK_NYET				BIT(6)
-#define DWC2_HCINTMSK_XACTERR				BIT(7)
-#define DWC2_HCINTMSK_BBLERR				BIT(8)
-#define DWC2_HCINTMSK_FRMOVRUN				BIT(9)
-#define DWC2_HCINTMSK_DATATGLERR			BIT(10)
-#define DWC2_HCINTMSK_BNA				BIT(11)
-#define DWC2_HCINTMSK_XCS_XACT				BIT(12)
-#define DWC2_HCINTMSK_FRM_LIST_ROLL			BIT(13)
-#define DWC2_HCTSIZ_XFERSIZE_MASK			GENMASK(18, 0)
-#define DWC2_HCTSIZ_SCHINFO_MASK			GENMASK(7, 0)
-#define DWC2_HCTSIZ_NTD_MASK				GENMASK(15, 8)
-#define DWC2_HCTSIZ_PKTCNT_MASK				GENMASK(28, 19)
-#define DWC2_HCTSIZ_PID_MASK				GENMASK(30, 29)
-#define DWC2_HCTSIZ_DOPNG				BIT(31)
-#define DWC2_HCDMA_CTD_MASK				GENMASK(10, 3)
-#define DWC2_HCDMA_DMA_ADDR_MASK			GENMASK(31, 11)
-#define DWC2_PCGCCTL_STOPPCLK				BIT(0)
-#define DWC2_PCGCCTL_GATEHCLK				BIT(1)
-#define DWC2_PCGCCTL_PWRCLMP				BIT(2)
-#define DWC2_PCGCCTL_RSTPDWNMODULE			BIT(3)
-#define DWC2_PCGCCTL_PHYSUSPENDED			BIT(4)
-#define DWC2_PCGCCTL_ENBL_SLEEP_GATING			BIT(5)
-#define DWC2_PCGCCTL_PHY_IN_SLEEP			BIT(6)
-#define DWC2_PCGCCTL_DEEP_SLEEP				BIT(7)
-#define DWC2_SNPSID_DEVID_VER_2xx			(0x4f542 << 12)
-#define DWC2_SNPSID_DEVID_VER_3xx			(0x4f543 << 12)
-#define DWC2_SNPSID_DEVID_MASK				GENMASK(31, 12)
+#define GOTGCTL_CHIRPEN				BIT(27)
+#define GOTGCTL_MULT_VALID_BC_MASK		GENMASK(26, 22)
+#define GOTGCTL_CURMODE_HOST			BIT(21)
+#define GOTGCTL_OTGVER				BIT(20)
+#define GOTGCTL_BSESVLD				BIT(19)
+#define GOTGCTL_ASESVLD				BIT(18)
+#define GOTGCTL_DBNC_SHORT			BIT(17)
+#define GOTGCTL_CONID_B				BIT(16)
+#define GOTGCTL_DBNCE_FLTR_BYPASS		BIT(15)
+#define GOTGCTL_DEVHNPEN			BIT(11)
+#define GOTGCTL_HSTSETHNPEN			BIT(10)
+#define GOTGCTL_HNPREQ				BIT(9)
+#define GOTGCTL_HSTNEGSCS			BIT(8)
+#define GOTGCTL_BVALOVAL			BIT(7)
+#define GOTGCTL_BVALOEN				BIT(6)
+#define GOTGCTL_AVALOVAL			BIT(5)
+#define GOTGCTL_AVALOEN				BIT(4)
+#define GOTGCTL_VBVALOVAL			BIT(3)
+#define GOTGCTL_VBVALOEN			BIT(2)
+#define GOTGCTL_SESREQ				BIT(1)
+#define GOTGCTL_SESREQSCS			BIT(0)
+
+#define GOTGINT_DBNCE_DONE			BIT(19)
+#define GOTGINT_A_DEV_TOUT_CHG			BIT(18)
+#define GOTGINT_HST_NEG_DET			BIT(17)
+#define GOTGINT_HST_NEG_SUC_STS_CHNG		BIT(9)
+#define GOTGINT_SES_REQ_SUC_STS_CHNG		BIT(8)
+#define GOTGINT_SES_END_DET			BIT(2)
+
+#define GAHBCFG_AHB_SINGLE			BIT(23)
+#define GAHBCFG_NOTI_ALL_DMA_WRIT		BIT(22)
+#define GAHBCFG_REM_MEM_SUPP			BIT(21)
+#define GAHBCFG_P_TXF_EMP_LVL			BIT(8)
+#define GAHBCFG_NP_TXF_EMP_LVL			BIT(7)
+#define GAHBCFG_DMA_EN				BIT(5)
+#define GAHBCFG_HBSTLEN_MASK			GENMASK(4, 1)
+#define GAHBCFG_HBSTLEN_SINGLE			0
+#define GAHBCFG_HBSTLEN_INCR			1
+#define GAHBCFG_HBSTLEN_INCR4			3
+#define GAHBCFG_HBSTLEN_INCR8			5
+#define GAHBCFG_HBSTLEN_INCR16			7
+#define GAHBCFG_GLBL_INTR_EN			BIT(0)
+#define GAHBCFG_CTRL_MASK			(GAHBCFG_P_TXF_EMP_LVL | \
+						 GAHBCFG_NP_TXF_EMP_LVL | \
+						 GAHBCFG_DMA_EN | \
+						 GAHBCFG_GLBL_INTR_EN)
+
+#define GUSBCFG_FORCEDEVMODE			BIT(30)
+#define GUSBCFG_FORCEHOSTMODE			BIT(29)
+#define GUSBCFG_TXENDDELAY			BIT(28)
+#define GUSBCFG_ICTRAFFICPULLREMOVE		BIT(27)
+#define GUSBCFG_ICUSBCAP			BIT(26)
+#define GUSBCFG_ULPI_INT_PROT_DIS		BIT(25)
+#define GUSBCFG_INDICATORPASSTHROUGH		BIT(24)
+#define GUSBCFG_INDICATORCOMPLEMENT		BIT(23)
+#define GUSBCFG_TERMSELDLPULSE			BIT(22)
+#define GUSBCFG_ULPI_INT_VBUS_IND		BIT(21)
+#define GUSBCFG_ULPI_EXT_VBUS_DRV		BIT(20)
+#define GUSBCFG_ULPI_CLK_SUSP_M			BIT(19)
+#define GUSBCFG_ULPI_AUTO_RES			BIT(18)
+#define GUSBCFG_ULPI_FS_LS			BIT(17)
+#define GUSBCFG_OTG_UTMI_FS_SEL			BIT(16)
+#define GUSBCFG_PHY_LP_CLK_SEL			BIT(15)
+#define GUSBCFG_USBTRDTIM_MASK			GENMASK(14, 10)
+#define GUSBCFG_HNPCAP				BIT(9)
+#define GUSBCFG_SRPCAP				BIT(8)
+#define GUSBCFG_DDRSEL				BIT(7)
+#define GUSBCFG_PHYSEL				BIT(6)
+#define GUSBCFG_FSINTF				BIT(5)
+#define GUSBCFG_ULPI_UTMI_SEL			BIT(4)
+#define GUSBCFG_PHYIF16				BIT(3)
+#define GUSBCFG_TOUTCAL_MASK			GENMASK(2, 0)
+
+#define GRSTCTL_AHBIDLE				BIT(31)
+#define GRSTCTL_DMAREQ				BIT(30)
+#define GRSTCTL_CSFTRST_DONE			BIT(29)
+#define GRSTCTL_TXFNUM_MASK			GENMASK(10, 6)
+#define GRSTCTL_TXFFLSH				BIT(5)
+#define GRSTCTL_RXFFLSH				BIT(4)
+#define GRSTCTL_IN_TKNQ_FLSH			BIT(3)
+#define GRSTCTL_FRMCNTRRST			BIT(2)
+#define GRSTCTL_HSFTRST				BIT(1)
+#define GRSTCTL_CSFTRST				BIT(0)
+#define GRSTCTL_TXFNUM_ALL			0x10
+
+#define GINTSTS_WKUPINT				BIT(31)
+#define GINTSTS_SESSREQINT			BIT(30)
+#define GINTSTS_DISCONNINT			BIT(29)
+#define GINTSTS_CONIDSTSCHNG			BIT(28)
+#define GINTSTS_LPMTRANRCVD			BIT(27)
+#define GINTSTS_PTXFEMP				BIT(26)
+#define GINTSTS_HCHINT				BIT(25)
+#define GINTSTS_PRTINT				BIT(24)
+#define GINTSTS_RESETDET			BIT(23)
+#define GINTSTS_FET_SUSP			BIT(22)
+#define GINTSTS_INCOMPL_IP			BIT(21)
+#define GINTSTS_INCOMPL_SOOUT			BIT(21)
+#define GINTSTS_INCOMPL_SOIN			BIT(20)
+#define GINTSTS_OEPINT				BIT(19)
+#define GINTSTS_IEPINT				BIT(18)
+#define GINTSTS_EPMIS				BIT(17)
+#define GINTSTS_RESTOREDONE			BIT(16)
+#define GINTSTS_EOPF				BIT(15)
+#define GINTSTS_ISOUTDROP			BIT(14)
+#define GINTSTS_ENUMDONE			BIT(13)
+#define GINTSTS_USBRST				BIT(12)
+#define GINTSTS_USBSUSP				BIT(11)
+#define GINTSTS_ERLYSUSP			BIT(10)
+#define GINTSTS_I2CINT				BIT(9)
+#define GINTSTS_ULPI_CK_INT			BIT(8)
+#define GINTSTS_GOUTNAKEFF			BIT(7)
+#define GINTSTS_GINNAKEFF			BIT(6)
+#define GINTSTS_NPTXFEMP			BIT(5)
+#define GINTSTS_RXFLVL				BIT(4)
+#define GINTSTS_SOF				BIT(3)
+#define GINTSTS_OTGINT				BIT(2)
+#define GINTSTS_MODEMIS				BIT(1)
+#define GINTSTS_CURMODE_HOST			BIT(0)
+
+#define FIFOSIZE_DEPTH_MASK			GENMASK(31, 16)
+#define FIFOSIZE_STARTADDR_MASK			GENMASK(15, 0)
+
+#define GI2CCTL_BSYDNE				BIT(31)
+#define GI2CCTL_RW				BIT(30)
+#define GI2CCTL_I2CDATSE0			BIT(28)
+#define GI2CCTL_I2CDEVADDR_MASK			GENMASK(27, 26)
+#define GI2CCTL_I2CSUSPCTL			BIT(25)
+#define GI2CCTL_ACK				BIT(24)
+#define GI2CCTL_I2CEN				BIT(23)
+#define GI2CCTL_ADDR_MASK			GENMASK(22, 16)
+#define GI2CCTL_REGADDR_MASK			GENMASK(15, 8)
+#define GI2CCTL_RWDATA_MASK			GENMASK(7, 0)
+
+#define GHWCFG2_OTG_ENABLE_IC_USB		BIT(31)
+#define GHWCFG2_DEV_TOKEN_Q_DEPTH_MASK		GENMASK(30, 26)
+#define GHWCFG2_HOST_PERIO_TX_Q_DEPTH_MASK	GENMASK(25, 24)
+#define GHWCFG2_NONPERIO_TX_Q_DEPTH_MASK	GENMASK(23, 22)
+#define GHWCFG2_MULTI_PROC_INT			BIT(20)
+#define GHWCFG2_DYNAMIC_FIFO			BIT(19)
+#define GHWCFG2_PERIO_EP_SUPPORTED		BIT(18)
+#define GHWCFG2_NUM_HOST_CHAN_MASK		GENMASK(17, 14)
+#define GHWCFG2_NUM_DEV_EP_MASK			GENMASK(13, 10)
+#define GHWCFG2_FS_PHY_TYPE_MASK		GENMASK(9, 8)
+#define GHWCFG2_FS_PHY_TYPE_NOT_SUPPORTED	0
+#define GHWCFG2_FS_PHY_TYPE_DEDICATED		1
+#define GHWCFG2_FS_PHY_TYPE_SHARED_UTMI		2
+#define GHWCFG2_FS_PHY_TYPE_SHARED_ULPI		3
+#define GHWCFG2_HS_PHY_TYPE_MASK		GENMASK(7, 6)
+#define GHWCFG2_HS_PHY_TYPE_NOT_SUPPORTED	0
+#define GHWCFG2_HS_PHY_TYPE_UTMI		1
+#define GHWCFG2_HS_PHY_TYPE_ULPI		2
+#define GHWCFG2_HS_PHY_TYPE_UTMI_ULPI		3
+#define GHWCFG2_POINT2POINT			BIT(5)
+#define GHWCFG2_ARCHITECTURE_MASK		GENMASK(4, 3)
+#define GHWCFG2_SLAVE_ONLY_ARCH			0
+#define GHWCFG2_EXT_DMA_ARCH			1
+#define GHWCFG2_INT_DMA_ARCH			2
+#define GHWCFG2_OP_MODE_MASK			GENMASK(2, 0)
+#define GHWCFG2_OP_MODE_HNP_SRP_CAPABLE		0
+#define GHWCFG2_OP_MODE_SRP_ONLY_CAPABLE	1
+#define GHWCFG2_OP_MODE_NO_HNP_SRP_CAPABLE	2
+#define GHWCFG2_OP_MODE_SRP_CAPABLE_DEVICE	3
+#define GHWCFG2_OP_MODE_NO_SRP_CAPABLE_DEVICE	4
+#define GHWCFG2_OP_MODE_SRP_CAPABLE_HOST	5
+#define GHWCFG2_OP_MODE_NO_SRP_CAPABLE_HOST	6
+#define GHWCFG2_OP_MODE_UNDEFINED		7
+
+#define GHWCFG4_DESC_DMA_DYN			BIT(31)
+#define GHWCFG4_DESC_DMA			BIT(30)
+#define GHWCFG4_NUM_IN_EPS_MASK			GENMASK(29, 26)
+#define GHWCFG4_DED_FIFO_EN			BIT(25)
+#define GHWCFG4_SESSION_END_FILT_EN		BIT(24)
+#define GHWCFG4_B_VALID_FILT_EN			BIT(23)
+#define GHWCFG4_A_VALID_FILT_EN			BIT(22)
+#define GHWCFG4_VBUS_VALID_FILT_EN		BIT(21)
+#define GHWCFG4_IDDIG_FILT_EN			BIT(20)
+#define GHWCFG4_NUM_DEV_MODE_CTRL_EP_MASK	GENMASK(19, 16)
+#define GHWCFG4_UTMI_PHY_DATA_WIDTH_MASK	GENMASK(15, 14)
+#define GHWCFG4_UTMI_PHY_DATA_WIDTH_8		0
+#define GHWCFG4_UTMI_PHY_DATA_WIDTH_16		1
+#define GHWCFG4_UTMI_PHY_DATA_WIDTH_8_OR_16	2
+#define GHWCFG4_ACG_SUPPORTED			BIT(12)
+#define GHWCFG4_IPG_ISOC_SUPPORTED		BIT(11)
+#define GHWCFG4_SERVICE_INTERVAL_SUPPORTED      BIT(10)
+#define GHWCFG4_XHIBER				BIT(7)
+#define GHWCFG4_HIBER				BIT(6)
+#define GHWCFG4_MIN_AHB_FREQ			BIT(5)
+#define GHWCFG4_POWER_OPTIMIZ			BIT(4)
+#define GHWCFG4_NUM_DEV_PERIO_IN_EP_MASK	GENMASK(3, 0)
+
+#define HCFG_MODECHTIMEN			BIT(31)
+#define HCFG_PERSCHEDENA			BIT(26)
+#define HCFG_FRLISTEN_MASK			GENMASK(25, 24)
+#define HCFG_FRLISTEN_8				0
+#define HCFG_FRLISTEN_16			1
+#define HCFG_FRLISTEN_32			2
+#define HCFG_FRLISTEN_64			3
+#define HCFG_DESCDMA				BIT(23)
+#define HCFG_RESVALID_MASK			GENMASK(15, 8)
+#define HCFG_ENA32KHZ				BIT(7)
+#define HCFG_FSLSSUPP				BIT(2)
+#define HCFG_FSLSPCLKSEL_MASK			GENMASK(2, 0)
+#define HCFG_FSLSPCLKSEL_30_60_MHZ		0
+#define HCFG_FSLSPCLKSEL_48_MHZ			1
+#define HCFG_FSLSPCLKSEL_6_MHZ			2
+
+#define HFIR_FRINT_MASK				GENMASK(15, 0)
+#define HFIR_RLDCTRL				BIT(16)
+
+#define HFNUM_FRREM_MASK			GENMASK(31, 16)
+#define HFNUM_FRNUM_MASK			GENMASK(15, 0)
+
+#define HPRT0_SPD_MASK				GENMASK(18, 17)
+#define HPRT0_SPD_HIGH_SPEED			0
+#define HPRT0_SPD_FULL_SPEED			1
+#define HPRT0_SPD_LOW_SPEED			2
+#define HPRT0_TSTCTL_MASK			GENMASK(16, 13)
+#define HPRT0_PWR				BIT(12)
+#define HPRT0_LNSTS_MASK			GENMASK(11, 10)
+#define HPRT0_RST				BIT(8)
+#define HPRT0_SUSP				BIT(7)
+#define HPRT0_RES				BIT(6)
+#define HPRT0_OVRCURRCHG			BIT(5)
+#define HPRT0_OVRCURRACT			BIT(4)
+#define HPRT0_ENACHG				BIT(3)
+#define HPRT0_ENA				BIT(2)
+#define HPRT0_CONNDET				BIT(1)
+#define HPRT0_CONNSTS				BIT(0)
+#define HPRT0_W1C_MASK				(HPRT0_CONNDET | \
+						 HPRT0_ENA | \
+						 HPRT0_ENACHG | \
+						 HPRT0_OVRCURRCHG)
+
+#define HCCHAR_CHENA				BIT(31)
+#define HCCHAR_CHDIS				BIT(30)
+#define HCCHAR_ODDFRM				BIT(29)
+#define HCCHAR_DEVADDR_MASK			GENMASK(28, 22)
+#define HCCHAR_MULTICNT_MASK			GENMASK(21, 20)
+#define HCCHAR_EPTYPE_MASK			GENMASK(19, 18)
+#define HCCHAR_EPTYPE_CONTROL			0
+#define HCCHAR_EPTYPE_ISOC			1
+#define HCCHAR_EPTYPE_BULK			2
+#define HCCHAR_EPTYPE_INTR			3
+#define HCCHAR_LSPDDEV				BIT(17)
+#define HCCHAR_EPDIR				BIT(15)
+#define HCCHAR_EPNUM_MASK			GENMASK(14, 11)
+#define HCCHAR_MPS_MASK				GENMASK(10, 0)
+
+#define HCSPLT_SPLTENA				BIT(31)
+#define HCSPLT_COMPSPLT				BIT(16)
+#define HCSPLT_XACTPOS_MASK			GENMASK(15, 14)
+#define HCSPLT_XACTPOS_MID			0
+#define HCSPLT_XACTPOS_END			1
+#define HCSPLT_XACTPOS_BEGIN			2
+#define HCSPLT_XACTPOS_ALL			3
+#define HCSPLT_HUBADDR_MASK			GENMASK(13, 7)
+#define HCSPLT_PRTADDR_MASK			GENMASK(6, 0)
+
+#define HCINTMSK_FRM_LIST_ROLL			BIT(13)
+#define HCINTMSK_XCS_XACT			BIT(12)
+#define HCINTMSK_BNA				BIT(11)
+#define HCINTMSK_DATATGLERR			BIT(10)
+#define HCINTMSK_FRMOVRUN			BIT(9)
+#define HCINTMSK_BBLERR				BIT(8)
+#define HCINTMSK_XACTERR			BIT(7)
+#define HCINTMSK_NYET				BIT(6)
+#define HCINTMSK_ACK				BIT(5)
+#define HCINTMSK_NAK				BIT(4)
+#define HCINTMSK_STALL				BIT(3)
+#define HCINTMSK_AHBERR				BIT(2)
+#define HCINTMSK_CHHLTD				BIT(1)
+#define HCINTMSK_XFERCOMPL			BIT(0)
+
+#define TSIZ_DOPNG				BIT(31)
+#define TSIZ_SC_MC_PID_MASK			GENMASK(30, 29)
+#define TSIZ_SC_MC_PID_DATA0			0
+#define TSIZ_SC_MC_PID_DATA2			1
+#define TSIZ_SC_MC_PID_DATA1			2
+#define TSIZ_SC_MC_PID_MDATA			3
+#define TSIZ_SC_MC_PID_SETUP			3
+#define TSIZ_PKTCNT_MASK			GENMASK(28, 19)
+#define TSIZ_NTD_MASK				GENMASK(15, 8)
+#define TSIZ_SCHINFO_MASK			GENMASK(7, 0)
+#define TSIZ_XFERSIZE_MASK			GENMASK(18, 0)
+
+#define GSNPSID_ID_MASK				GENMASK(31, 16)
+#define GSNPSID_OTG_ID				0x4f54
+#define GSNPSID_VER_MASK			GENMASK(15, 0)
 
 /* Host controller specific */
 #define DWC2_HC_PID_DATA0		0

-- 
2.39.2

