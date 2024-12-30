From: Junhui Liu <liujh2818@outlook.com>
Date: Mon, 30 Dec 2024 11:30:19 +0800
Subject: [PATCH v2 4/8] usb: dwc2: Clean up with bitfield macros
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241230-dwc2-dev-v2-4-12cd9b8a2358@outlook.com>
References: <20241230-dwc2-dev-v2-0-12cd9b8a2358@outlook.com>
In-Reply-To: <20241230-dwc2-dev-v2-0-12cd9b8a2358@outlook.com>
To: Tom Rini <trini@konsulko.com>, Marek Vasut <marex@denx.de>, 
 Lukasz Majewski <lukma@denx.de>, 
 Mattijs Korpershoek <mkorpershoek@baylibre.com>
Cc: u-boot@lists.denx.de, Kongyang Liu <seashell11234455@gmail.com>, 
 Junhui Liu <liujh2818@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735529447; l=71884;
 i=liujh2818@outlook.com; s=20241030; h=from:subject:message-id;
 bh=Yy/UoE/c6555cTAblCmwQneO9K3cNkjUkjP/cJ1ggUA=;
 b=grqYFzSYDBvRiUYLZQEtnN7zctUTnLCGcn5NpiqEQ8+O+taezW8ADJvtFnQkdt7VXAxhoKYGX
 v5VA3PoW/Y2Bhmx9wvad7Ab5AmrrS9vKbYVtT7cLmBA9X7Gl3Z2pK68
X-Developer-Key: i=liujh2818@outlook.com; a=ed25519;
 pk=ApYwI6KD3EjynMw61RqGa6c5BGbStQnKSrbNN+aQqT4=
X-Endpoint-Received: by B4 Relay for liujh2818@outlook.com/20241030 with auth_id=259
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Kongyang Liu <seashell11234455@gmail.com>

Use FIELD_PREP, FIELD_GET, BIT, and GENMASK macros to standardize bit
manipulation across the DWC2 code, improving readability and
maintainability without altering functionality.

Signed-off-by: Kongyang Liu <seashell11234455@gmail.com>
Signed-off-by: Junhui Liu <liujh2818@outlook.com>
---
 drivers/usb/gadget/dwc2_udc_otg.c          |   5 +-
 drivers/usb/gadget/dwc2_udc_otg_regs.h     | 180 +++---
 drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c |  21 +-
 drivers/usb/host/dwc2.c                    | 101 ++-
 drivers/usb/host/dwc2.h                    | 993 ++++++++++-------------------
 5 files changed, 482 insertions(+), 818 deletions(-)

diff --git a/drivers/usb/gadget/dwc2_udc_otg.c b/drivers/usb/gadget/dwc2_udc_otg.c
index c3dee8771e6c98692dd2ed6b50ca3c6ea21782af..2289dcc9c325a793ff86940625794066463b4083 100644
--- a/drivers/usb/gadget/dwc2_udc_otg.c
+++ b/drivers/usb/gadget/dwc2_udc_otg.c
@@ -29,6 +29,7 @@
 #include <linux/delay.h>
 #include <linux/printk.h>
 
+#include <linux/bitfield.h>
 #include <linux/errno.h>
 #include <linux/list.h>
 
@@ -526,8 +527,8 @@ static void reconfig_usbd(struct dwc2_udc *dev)
 	}
 
 	/* 8. Unmask EPO interrupts*/
-	writel(((1 << EP0_CON) << DAINT_OUT_BIT)
-	       | (1 << EP0_CON), &reg->device_regs.daintmsk);
+	writel(FIELD_PREP(DAINT_OUTEP_MASK, BIT(EP0_CON)) |
+	       FIELD_PREP(DAINT_INEP_MASK, BIT(EP0_CON)), &reg->device_regs.daintmsk);
 
 	/* 9. Unmask device OUT EP common interrupts*/
 	writel(DOEPMSK_INIT, &reg->device_regs.doepmsk);
diff --git a/drivers/usb/gadget/dwc2_udc_otg_regs.h b/drivers/usb/gadget/dwc2_udc_otg_regs.h
index 198ba7a7c37d05dca084ef017534265f5fb5fd70..33359ba56f7864525fb435ab52f2b21538e4647f 100644
--- a/drivers/usb/gadget/dwc2_udc_otg_regs.h
+++ b/drivers/usb/gadget/dwc2_udc_otg_regs.h
@@ -50,27 +50,26 @@ struct dwc2_usbotg_phy {
 #define GBL_INT_MASK			(0<<0)
 
 /* DWC2_UDC_OTG_GRSTCTL */
-#define AHB_MASTER_IDLE		(1u<<31)
-#define CORE_SOFT_RESET		(0x1<<0)
+#define AHB_MASTER_IDLE			(1u<<31)
+#define CORE_SOFT_RESET			(0x1<<0)
 
 /* DWC2_UDC_OTG_GINTSTS/DWC2_UDC_OTG_GINTMSK core interrupt register */
-#define INT_RESUME			(1u<<31)
-#define INT_DISCONN			(0x1<<29)
-#define INT_CONN_ID_STS_CNG		(0x1<<28)
-#define INT_OUT_EP			(0x1<<19)
-#define INT_IN_EP			(0x1<<18)
-#define INT_ENUMDONE			(0x1<<13)
-#define INT_RESET			(0x1<<12)
-#define INT_SUSPEND			(0x1<<11)
-#define INT_EARLY_SUSPEND		(0x1<<10)
-#define INT_NP_TX_FIFO_EMPTY		(0x1<<5)
-#define INT_RX_FIFO_NOT_EMPTY		(0x1<<4)
-#define INT_SOF			(0x1<<3)
-#define INT_OTG			(0x1<<2)
-#define INT_DEV_MODE			(0x0<<0)
-#define INT_HOST_MODE			(0x1<<1)
-#define INT_GOUTNakEff			(0x01<<7)
-#define INT_GINNakEff			(0x01<<6)
+#define INT_RESUME			BIT(31)
+#define INT_DISCONN			BIT(29)
+#define INT_CONN_ID_STS_CNG		BIT(28)
+#define INT_OUT_EP			BIT(19)
+#define INT_IN_EP			BIT(18)
+#define INT_ENUMDONE			BIT(13)
+#define INT_RESET			BIT(12)
+#define INT_SUSPEND			BIT(11)
+#define INT_EARLY_SUSPEND		BIT(10)
+#define INT_GOUTNakEff			BIT(7)
+#define INT_GINNakEff			BIT(6)
+#define INT_NP_TX_FIFO_EMPTY		BIT(5)
+#define INT_RX_FIFO_NOT_EMPTY		BIT(4)
+#define INT_SOF				BIT(3)
+#define INT_OTG				BIT(2)
+#define INT_HOST_MODE			BIT(1)
 
 #define FULL_SPEED_CONTROL_PKT_SIZE	8
 #define FULL_SPEED_BULK_PKT_SIZE	64
@@ -78,15 +77,15 @@ struct dwc2_usbotg_phy {
 #define HIGH_SPEED_CONTROL_PKT_SIZE	64
 #define HIGH_SPEED_BULK_PKT_SIZE	512
 
-#define RX_FIFO_SIZE			(1024)
-#define NPTX_FIFO_SIZE			(1024)
-#define PTX_FIFO_SIZE			(384)
+#define RX_FIFO_SIZE			1024
+#define NPTX_FIFO_SIZE			1024
+#define PTX_FIFO_SIZE			384
 
-#define DEPCTL_TXFNUM_0		(0x0<<22)
-#define DEPCTL_TXFNUM_1		(0x1<<22)
-#define DEPCTL_TXFNUM_2		(0x2<<22)
-#define DEPCTL_TXFNUM_3		(0x3<<22)
-#define DEPCTL_TXFNUM_4		(0x4<<22)
+#define DEPCTL_TXFNUM_0			(0x0<<22)
+#define DEPCTL_TXFNUM_1			(0x1<<22)
+#define DEPCTL_TXFNUM_2			(0x2<<22)
+#define DEPCTL_TXFNUM_3			(0x3<<22)
+#define DEPCTL_TXFNUM_4			(0x4<<22)
 
 /* Enumeration speed */
 #define USB_HIGH_30_60MHZ		(0x0<<1)
@@ -96,38 +95,36 @@ struct dwc2_usbotg_phy {
 
 /* DWC2_UDC_OTG_GRXSTSP STATUS */
 #define OUT_PKT_RECEIVED		(0x2<<17)
-#define OUT_TRANSFER_COMPLELTED	(0x3<<17)
+#define OUT_TRANSFER_COMPLELTED		(0x3<<17)
 #define SETUP_TRANSACTION_COMPLETED	(0x4<<17)
 #define SETUP_PKT_RECEIVED		(0x6<<17)
 #define GLOBAL_OUT_NAK			(0x1<<17)
 
 /* DWC2_UDC_OTG_DCTL device control register */
 #define NORMAL_OPERATION		(0x1<<0)
-#define SOFT_DISCONNECT		(0x1<<1)
+#define SOFT_DISCONNECT			(0x1<<1)
 
 /* DWC2_UDC_OTG_DAINT device all endpoint interrupt register */
-#define DAINT_OUT_BIT			(16)
-#define DAINT_MASK			(0xFFFF)
+#define DAINT_OUTEP_MASK		GENMASK(31, 16)
+#define DAINT_INEP_MASK			GENMASK(15, 0)
 
 /* DWC2_UDC_OTG_DIEPCTL0/DOEPCTL0 device
    control IN/OUT endpoint 0 control register */
-#define DEPCTL_EPENA			(0x1<<31)
-#define DEPCTL_EPDIS			(0x1<<30)
-#define DEPCTL_SETD1PID		(0x1<<29)
-#define DEPCTL_SETD0PID		(0x1<<28)
-#define DEPCTL_SNAK			(0x1<<27)
-#define DEPCTL_CNAK			(0x1<<26)
-#define DEPCTL_STALL			(0x1<<21)
-#define DEPCTL_TYPE_BIT		(18)
-#define DEPCTL_TYPE_MASK		(0x3<<18)
+#define DEPCTL_EPENA			BIT(31)
+#define DEPCTL_EPDIS			BIT(30)
+#define DEPCTL_SETD1PID			BIT(29)
+#define DEPCTL_SETD0PID			BIT(28)
+#define DEPCTL_SNAK			BIT(27)
+#define DEPCTL_CNAK			BIT(26)
+#define DEPCTL_STALL			BIT(21)
+#define DEPCTL_TYPE_MASK		GENMASK(19, 18)
 #define DEPCTL_CTRL_TYPE		(0x0<<18)
-#define DEPCTL_ISO_TYPE		(0x1<<18)
+#define DEPCTL_ISO_TYPE			(0x1<<18)
 #define DEPCTL_BULK_TYPE		(0x2<<18)
 #define DEPCTL_INTR_TYPE		(0x3<<18)
-#define DEPCTL_USBACTEP		(0x1<<15)
-#define DEPCTL_NEXT_EP_BIT		(11)
-#define DEPCTL_MPS_BIT			(0)
-#define DEPCTL_MPS_MASK		(0x7FF)
+#define DEPCTL_USBACTEP			BIT(15)
+#define DEPCTL_NEXT_EP_MASK		GENMASK(14, 11)
+#define DEPCTL_MPS_MASK			GENMASK(10, 0)
 
 #define DEPCTL0_MPS_64			(0x0<<0)
 #define DEPCTL0_MPS_32			(0x1<<0)
@@ -141,56 +138,56 @@ struct dwc2_usbotg_phy {
 /* DWC2_UDC_OTG_DIEPMSK/DOEPMSK device IN/OUT endpoint
    common interrupt mask register */
 /* DWC2_UDC_OTG_DIEPINTn/DOEPINTn device IN/OUT endpoint interrupt register */
-#define BACK2BACK_SETUP_RECEIVED	(0x1<<6)
-#define INTKNEPMIS			(0x1<<5)
-#define INTKN_TXFEMP			(0x1<<4)
-#define NON_ISO_IN_EP_TIMEOUT		(0x1<<3)
-#define CTRL_OUT_EP_SETUP_PHASE_DONE	(0x1<<3)
-#define AHB_ERROR			(0x1<<2)
-#define EPDISBLD			(0x1<<1)
-#define TRANSFER_DONE			(0x1<<0)
+#define BACK2BACK_SETUP_RECEIVED	BIT(6)
+#define INTKNEPMIS			BIT(5)
+#define INTKN_TXFEMP			BIT(4)
+#define NON_ISO_IN_EP_TIMEOUT		BIT(3)
+#define CTRL_OUT_EP_SETUP_PHASE_DONE	BIT(3)
+#define AHB_ERROR			BIT(2)
+#define EPDISBLD			BIT(1)
+#define TRANSFER_DONE			BIT(0)
 
-#define USB_PHY_CTRL_EN0                (0x1 << 0)
+#define USB_PHY_CTRL_EN0		(0x1 << 0)
 
 /* OPHYPWR */
-#define PHY_0_SLEEP                     (0x1 << 5)
-#define OTG_DISABLE_0                   (0x1 << 4)
-#define ANALOG_PWRDOWN                  (0x1 << 3)
-#define FORCE_SUSPEND_0                 (0x1 << 0)
+#define PHY_0_SLEEP			(0x1 << 5)
+#define OTG_DISABLE_0			(0x1 << 4)
+#define ANALOG_PWRDOWN			(0x1 << 3)
+#define FORCE_SUSPEND_0			(0x1 << 0)
 
 /* URSTCON */
-#define HOST_SW_RST                     (0x1 << 4)
-#define PHY_SW_RST1                     (0x1 << 3)
-#define PHYLNK_SW_RST                   (0x1 << 2)
-#define LINK_SW_RST                     (0x1 << 1)
-#define PHY_SW_RST0                     (0x1 << 0)
+#define HOST_SW_RST			(0x1 << 4)
+#define PHY_SW_RST1			(0x1 << 3)
+#define PHYLNK_SW_RST			(0x1 << 2)
+#define LINK_SW_RST			(0x1 << 1)
+#define PHY_SW_RST0			(0x1 << 0)
 
 /* OPHYCLK */
-#define COMMON_ON_N1                    (0x1 << 7)
-#define COMMON_ON_N0                    (0x1 << 4)
-#define ID_PULLUP0                      (0x1 << 2)
-#define CLK_SEL_24MHZ                   (0x3 << 0)
-#define CLK_SEL_12MHZ                   (0x2 << 0)
-#define CLK_SEL_48MHZ                   (0x0 << 0)
+#define COMMON_ON_N1			(0x1 << 7)
+#define COMMON_ON_N0			(0x1 << 4)
+#define ID_PULLUP0			(0x1 << 2)
+#define CLK_SEL_24MHZ			(0x3 << 0)
+#define CLK_SEL_12MHZ			(0x2 << 0)
+#define CLK_SEL_48MHZ			(0x0 << 0)
 
 #define EXYNOS4X12_ID_PULLUP0		(0x01 << 3)
-#define EXYNOS4X12_COMMON_ON_N0	(0x01 << 4)
+#define EXYNOS4X12_COMMON_ON_N0		(0x01 << 4)
 #define EXYNOS4X12_CLK_SEL_12MHZ	(0x02 << 0)
 #define EXYNOS4X12_CLK_SEL_24MHZ	(0x05 << 0)
 
 /* Device Configuration Register DCFG */
-#define DEV_SPEED_HIGH_SPEED_20         (0x0 << 0)
-#define DEV_SPEED_FULL_SPEED_20         (0x1 << 0)
-#define DEV_SPEED_LOW_SPEED_11          (0x2 << 0)
-#define DEV_SPEED_FULL_SPEED_11         (0x3 << 0)
-#define EP_MISS_CNT(x)                  (x << 18)
-#define DEVICE_ADDRESS(x)               (x << 4)
+#define DEV_SPEED_HIGH_SPEED_20		(0x0 << 0)
+#define DEV_SPEED_FULL_SPEED_20		(0x1 << 0)
+#define DEV_SPEED_LOW_SPEED_11		(0x2 << 0)
+#define DEV_SPEED_FULL_SPEED_11		(0x3 << 0)
+#define EP_MISS_CNT(x)			(x << 18)
+#define DEVICE_ADDRESS(x)		(x << 4)
 
 /* Core Reset Register (GRSTCTL) */
-#define TX_FIFO_FLUSH                   (0x1 << 5)
-#define RX_FIFO_FLUSH                   (0x1 << 4)
-#define TX_FIFO_NUMBER(x)               (x << 6)
-#define TX_FIFO_FLUSH_ALL               TX_FIFO_NUMBER(0x10)
+#define TX_FIFO_FLUSH			(0x1 << 5)
+#define RX_FIFO_FLUSH			(0x1 << 4)
+#define TX_FIFO_NUMBER(x)		(x << 6)
+#define TX_FIFO_FLUSH_ALL		TX_FIFO_NUMBER(0x10)
 
 /* Masks definitions */
 #define GINTMSK_INIT	(INT_OUT_EP | INT_IN_EP | INT_RESUME | INT_ENUMDONE\
@@ -201,29 +198,28 @@ struct dwc2_usbotg_phy {
 			| GBL_INT_UNMASK)
 
 /* Device Endpoint X Transfer Size Register (DIEPTSIZX) */
-#define DIEPT_SIZ_PKT_CNT(x)                      (x << 19)
-#define DIEPT_SIZ_XFER_SIZE(x)                    (x << 0)
+#define DIEPT_SIZ_PKT_CNT(x)		(x << 19)
+#define DIEPT_SIZ_XFER_SIZE(x)		(x << 0)
 
 /* Device OUT Endpoint X Transfer Size Register (DOEPTSIZX) */
-#define DOEPT_SIZ_PKT_CNT(x)                      (x << 19)
-#define DOEPT_SIZ_XFER_SIZE(x)                    (x << 0)
-#define DOEPT_SIZ_XFER_SIZE_MAX_EP0               (0x7F << 0)
-#define DOEPT_SIZ_XFER_SIZE_MAX_EP                (0x7FFF << 0)
+#define DOEPT_SIZ_PKT_CNT(x)		(x << 19)
+#define DOEPT_SIZ_XFER_SIZE(x)		(x << 0)
+#define DOEPT_SIZ_XFER_SIZE_MAX_EP0	(0x7F << 0)
+#define DOEPT_SIZ_XFER_SIZE_MAX_EP	(0x7FFF << 0)
 
 /* Device Endpoint-N Control Register (DIEPCTLn/DOEPCTLn) */
-#define DIEPCTL_TX_FIFO_NUM(x)                    (x << 22)
-#define DIEPCTL_TX_FIFO_NUM_MASK                  (~DIEPCTL_TX_FIFO_NUM(0xF))
+#define DIEPCTL_TX_FIFO_NUM_MASK	GENMASK(25, 22)
 
 /* Device ALL Endpoints Interrupt Register (DAINT) */
-#define DAINT_IN_EP_INT(x)                        (x << 0)
-#define DAINT_OUT_EP_INT(x)                       (x << 16)
+#define DAINT_IN_EP_INT(x)		(x << 0)
+#define DAINT_OUT_EP_INT(x)		(x << 16)
 
 /* User HW Config4 */
 #define GHWCFG4_NUM_IN_EPS_MASK		(0xf << 26)
 #define GHWCFG4_NUM_IN_EPS_SHIFT	26
 
 /* OTG general core configuration register (OTG_GCCFG:0x38) for STM32MP1 */
-#define GGPIO_STM32_OTG_GCCFG_VBDEN               BIT(21)
-#define GGPIO_STM32_OTG_GCCFG_IDEN                BIT(22)
+#define GGPIO_STM32_OTG_GCCFG_VBDEN	BIT(21)
+#define GGPIO_STM32_OTG_GCCFG_IDEN	BIT(22)
 
 #endif
diff --git a/drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c b/drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c
index e2a24c53b4c8d632163484d52b4338820dcb1731..76c0b03c355b47e9523a071bd76ab8d6a17cd3ac 100644
--- a/drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c
+++ b/drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c
@@ -19,6 +19,7 @@
 
 #include <cpu_func.h>
 #include <log.h>
+#include <linux/bitfield.h>
 #include <linux/bug.h>
 
 static u8 clear_feature_num;
@@ -174,11 +175,11 @@ static int setdma_tx(struct dwc2_ep *ep, struct dwc2_request *req)
 	ctrl = readl(&reg->device_regs.in_endp[ep_num].diepctl);
 
 	/* Write the FIFO number to be used for this endpoint */
-	ctrl &= DIEPCTL_TX_FIFO_NUM_MASK;
-	ctrl |= DIEPCTL_TX_FIFO_NUM(ep->fifo_num);
+	ctrl &= ~DIEPCTL_TX_FIFO_NUM_MASK;
+	ctrl |= FIELD_PREP(DIEPCTL_TX_FIFO_NUM_MASK, ep->fifo_num);
 
 	/* Clear reserved (Next EP) bits */
-	ctrl = (ctrl&~(EP_MASK<<DEPCTL_NEXT_EP_BIT));
+	ctrl &= ~DEPCTL_NEXT_EP_MASK;
 
 	writel(DEPCTL_EPENA|DEPCTL_CNAK|ctrl, &reg->device_regs.in_endp[ep_num].diepctl);
 
@@ -380,7 +381,7 @@ static void process_ep_in_intr(struct dwc2_udc *dev)
 	debug_cond(DEBUG_IN_EP,
 		"*** %s: EP In interrupt : DAINT = 0x%x\n", __func__, ep_intr);
 
-	ep_intr &= DAINT_MASK;
+	ep_intr = FIELD_GET(DAINT_INEP_MASK, ep_intr);
 
 	while (ep_intr) {
 		if (ep_intr & DAINT_IN_EP_INT(1)) {
@@ -431,10 +432,10 @@ static void process_ep_out_intr(struct dwc2_udc *dev)
 		   "*** %s: EP OUT interrupt : DAINT = 0x%x\n",
 		   __func__, ep_intr);
 
-	ep_intr = (ep_intr >> DAINT_OUT_BIT) & DAINT_MASK;
+	ep_intr = FIELD_GET(DAINT_OUTEP_MASK, ep_intr);
 
 	while (ep_intr) {
-		if (ep_intr & 0x1) {
+		if (ep_intr & BIT(EP0_CON)) {
 			ep_intr_status = readl(&reg->device_regs.out_endp[ep_num].doepint);
 			debug_cond(DEBUG_OUT_EP != 0,
 				   "\tEP%d-OUT : DOEPINT = 0x%x\n",
@@ -1114,10 +1115,10 @@ static void dwc2_udc_ep_activate(struct dwc2_ep *ep)
 	/* Read DEPCTLn register */
 	if (ep_is_in(ep)) {
 		ep_ctrl = readl(&reg->device_regs.in_endp[ep_num].diepctl);
-		daintmsk = 1 << ep_num;
+		daintmsk = FIELD_PREP(DAINT_INEP_MASK, BIT(ep_num));
 	} else {
 		ep_ctrl = readl(&reg->device_regs.out_endp[ep_num].doepctl);
-		daintmsk = (1 << ep_num) << DAINT_OUT_BIT;
+		daintmsk = FIELD_PREP(DAINT_OUTEP_MASK, BIT(ep_num));
 	}
 
 	debug("%s: EPCTRL%d = 0x%x, ep_is_in = %d\n",
@@ -1127,9 +1128,9 @@ static void dwc2_udc_ep_activate(struct dwc2_ep *ep)
 	 * register. */
 	if (!(ep_ctrl & DEPCTL_USBACTEP)) {
 		ep_ctrl = (ep_ctrl & ~DEPCTL_TYPE_MASK) |
-			(ep->bmAttributes << DEPCTL_TYPE_BIT);
+			FIELD_PREP(DEPCTL_TYPE_MASK, ep->bmAttributes);
 		ep_ctrl = (ep_ctrl & ~DEPCTL_MPS_MASK) |
-			(ep->ep.maxpacket << DEPCTL_MPS_BIT);
+			FIELD_PREP(DEPCTL_MPS_MASK, ep->ep.maxpacket);
 		ep_ctrl |= (DEPCTL_SETD0PID | DEPCTL_USBACTEP | DEPCTL_SNAK);
 
 		if (ep_is_in(ep)) {
diff --git a/drivers/usb/host/dwc2.c b/drivers/usb/host/dwc2.c
index 954650d856a4f2e95d74e1b5716c0ebe83fa9ba8..d4245b9cb71c91adc658668dcf897bcb10366b73 100644
--- a/drivers/usb/host/dwc2.c
+++ b/drivers/usb/host/dwc2.c
@@ -19,6 +19,7 @@
 #include <asm/cache.h>
 #include <asm/io.h>
 #include <dm/device_compat.h>
+#include <linux/bitfield.h>
 #include <linux/delay.h>
 #include <linux/usb/otg.h>
 #include <power/regulator.h>
@@ -95,10 +96,8 @@ static void init_fslspclksel(struct dwc2_core_regs *regs)
 
 #ifdef DWC2_ULPI_FS_LS
 	uint32_t hwcfg2 = readl(&regs->global_regs.ghwcfg2);
-	uint32_t hval = (ghwcfg2 & DWC2_HWCFG2_HS_PHY_TYPE_MASK) >>
-			DWC2_HWCFG2_HS_PHY_TYPE_OFFSET;
-	uint32_t fval = (ghwcfg2 & DWC2_HWCFG2_FS_PHY_TYPE_MASK) >>
-			DWC2_HWCFG2_FS_PHY_TYPE_OFFSET;
+	uint32_t hval = FIELD_GET(GHWCFG2_HS_PHY_TYPE_MASK, ghwcfg2);
+	uint32_t fval = FIELD_GET(GHWCFG2_FS_PHY_TYPE_MASK, ghwcfg2);
 
 	if (hval == 2 && fval == 1)
 		phyclk = DWC2_HCFG_FSLSPCLKSEL_48_MHZ;	/* Full speed PHY */
@@ -106,7 +105,7 @@ static void init_fslspclksel(struct dwc2_core_regs *regs)
 
 	clrsetbits_le32(&regs->host_regs.hcfg,
 			DWC2_HCFG_FSLSPCLKSEL_MASK,
-			phyclk << DWC2_HCFG_FSLSPCLKSEL_OFFSET);
+			FIELD_PREP(DWC2_HCFG_FSLSPCLKSEL_MASK, phyclk));
 }
 
 /*
@@ -120,7 +119,7 @@ static void dwc_otg_flush_tx_fifo(struct udevice *dev,
 {
 	int ret;
 
-	writel(DWC2_GRSTCTL_TXFFLSH | (num << DWC2_GRSTCTL_TXFNUM_OFFSET),
+	writel(DWC2_GRSTCTL_TXFFLSH | FIELD_PREP(DWC2_GRSTCTL_TXFNUM_MASK, num),
 	       &regs->global_regs.grstctl);
 	ret = wait_for_bit_le32(&regs->global_regs.grstctl, DWC2_GRSTCTL_TXFFLSH,
 				false, 1000, false);
@@ -266,18 +265,14 @@ static void dwc_otg_core_host_init(struct udevice *dev,
 		writel(DWC2_HOST_RX_FIFO_SIZE, &regs->global_regs.grxfsiz);
 
 		/* Non-periodic Tx FIFO */
-		nptxfifosize |= DWC2_HOST_NPERIO_TX_FIFO_SIZE <<
-				DWC2_FIFOSIZE_DEPTH_OFFSET;
-		nptxfifosize |= DWC2_HOST_RX_FIFO_SIZE <<
-				DWC2_FIFOSIZE_STARTADDR_OFFSET;
+		nptxfifosize |= FIELD_PREP(DWC2_FIFOSIZE_DEPTH_MASK, DWC2_HOST_NPERIO_TX_FIFO_SIZE);
+		nptxfifosize |= FIELD_PREP(DWC2_FIFOSIZE_STARTADDR_MASK, DWC2_HOST_RX_FIFO_SIZE);
 		writel(nptxfifosize, &regs->global_regs.gnptxfsiz);
 
 		/* Periodic Tx FIFO */
-		ptxfifosize |= DWC2_HOST_PERIO_TX_FIFO_SIZE <<
-				DWC2_FIFOSIZE_DEPTH_OFFSET;
-		ptxfifosize |= (DWC2_HOST_RX_FIFO_SIZE +
-				DWC2_HOST_NPERIO_TX_FIFO_SIZE) <<
-				DWC2_FIFOSIZE_STARTADDR_OFFSET;
+		ptxfifosize |= FIELD_PREP(DWC2_FIFOSIZE_DEPTH_MASK, DWC2_HOST_PERIO_TX_FIFO_SIZE);
+		ptxfifosize |= FIELD_PREP(DWC2_FIFOSIZE_STARTADDR_MASK, DWC2_HOST_RX_FIFO_SIZE +
+					  DWC2_HOST_NPERIO_TX_FIFO_SIZE);
 		writel(ptxfifosize, &regs->global_regs.hptxfsiz);
 	}
 #endif
@@ -290,10 +285,8 @@ static void dwc_otg_core_host_init(struct udevice *dev,
 	dwc_otg_flush_rx_fifo(dev, regs);
 
 	/* Flush out any leftover queued requests. */
-	num_channels = readl(&regs->global_regs.ghwcfg2);
-	num_channels &= DWC2_HWCFG2_NUM_HOST_CHAN_MASK;
-	num_channels >>= DWC2_HWCFG2_NUM_HOST_CHAN_OFFSET;
-	num_channels += 1;
+	num_channels = FIELD_GET(DWC2_HWCFG2_NUM_HOST_CHAN_MASK,
+				 readl(&regs->global_regs.ghwcfg2)) + 1;
 
 	for (i = 0; i < num_channels; i++)
 		clrsetbits_le32(&regs->host_regs.hc[i].hcchar,
@@ -390,7 +383,7 @@ static void dwc_otg_core_init(struct udevice *dev)
 	/* Program GI2CCTL.I2CEn */
 	clrsetbits_le32(&regs->global_regs.gi2cctl, DWC2_GI2CCTL_I2CEN |
 			DWC2_GI2CCTL_I2CDEVADDR_MASK,
-			1 << DWC2_GI2CCTL_I2CDEVADDR_OFFSET);
+			FIELD_PREP(DWC2_GI2CCTL_I2CDEVADDR_MASK, 1));
 	setbits_le32(&regs->global_regs.gi2cctl, DWC2_GI2CCTL_I2CEN);
 #endif
 
@@ -429,10 +422,8 @@ static void dwc_otg_core_init(struct udevice *dev)
 	usbcfg &= ~(DWC2_GUSBCFG_ULPI_FSLS | DWC2_GUSBCFG_ULPI_CLK_SUS_M);
 #ifdef DWC2_ULPI_FS_LS
 	uint32_t hwcfg2 = readl(&regs->global_regs.ghwcfg2);
-	uint32_t hval = (ghwcfg2 & DWC2_HWCFG2_HS_PHY_TYPE_MASK) >>
-			DWC2_HWCFG2_HS_PHY_TYPE_OFFSET;
-	uint32_t fval = (ghwcfg2 & DWC2_HWCFG2_FS_PHY_TYPE_MASK) >>
-			DWC2_HWCFG2_FS_PHY_TYPE_OFFSET;
+	uint32_t hval = FIELD_GET(DWC2_HWCFG2_HS_PHY_TYPE_MASK, ghwcfg2);
+	uint32_t fval = FIELD_GET(DWC2_HWCFG2_FS_PHY_TYPE_MASK, ghwcfg2);
 	if (hval == 2 && fval == 1) {
 		usbcfg |= DWC2_GUSBCFG_ULPI_FSLS;
 		usbcfg |= DWC2_GUSBCFG_ULPI_CLK_SUS_M;
@@ -444,12 +435,11 @@ static void dwc_otg_core_init(struct udevice *dev)
 	writel(usbcfg, &regs->global_regs.gusbcfg);
 
 	/* Program the GAHBCFG Register. */
-	switch (readl(&regs->global_regs.ghwcfg2) & DWC2_HWCFG2_ARCHITECTURE_MASK) {
+	switch (FIELD_GET(DWC2_HWCFG2_ARCHITECTURE_MASK, readl(&regs->global_regs.ghwcfg2))) {
 	case DWC2_HWCFG2_ARCHITECTURE_SLAVE_ONLY:
 		break;
 	case DWC2_HWCFG2_ARCHITECTURE_EXT_DMA:
-		ahbcfg |= (LOG2(brst_sz >> 1) << DWC2_GAHBCFG_HBURSTLEN_OFFSET) &
-			  DWC2_GAHBCFG_HBURSTLEN_MASK;
+		ahbcfg |= FIELD_PREP(DWC2_GAHBCFG_HBURSTLEN_MASK, LOG2(brst_sz >> 1));
 
 #ifdef DWC2_DMA_ENABLE
 		ahbcfg |= DWC2_GAHBCFG_DMAENABLE;
@@ -492,11 +482,11 @@ static void dwc_otg_hc_init(struct dwc2_core_regs *regs, uint8_t hc_num,
 		uint8_t ep_is_in, uint8_t ep_type, uint16_t max_packet)
 {
 	struct dwc2_hc_regs *hc_regs = &regs->host_regs.hc[hc_num];
-	uint32_t hcchar = (dev_addr << DWC2_HCCHAR_DEVADDR_OFFSET) |
-			  (ep_num << DWC2_HCCHAR_EPNUM_OFFSET) |
-			  (ep_is_in << DWC2_HCCHAR_EPDIR_OFFSET) |
-			  (ep_type << DWC2_HCCHAR_EPTYPE_OFFSET) |
-			  (max_packet << DWC2_HCCHAR_MPS_OFFSET);
+	u32 hcchar = FIELD_PREP(DWC2_HCCHAR_DEVADDR_MASK, dev_addr) |
+			  FIELD_PREP(DWC2_HCCHAR_EPNUM_MASK, ep_num) |
+			  FIELD_PREP(DWC2_HCCHAR_EPDIR, ep_is_in) |
+			  FIELD_PREP(DWC2_HCCHAR_EPTYPE_MASK, ep_type) |
+			  FIELD_PREP(DWC2_HCCHAR_MPS_MASK, max_packet);
 
 	if (dev->speed == USB_SPEED_LOW)
 		hcchar |= DWC2_HCCHAR_LSPDDEV;
@@ -517,8 +507,8 @@ static void dwc_otg_hc_init_split(struct dwc2_hc_regs *hc_regs,
 	uint32_t hcsplt = 0;
 
 	hcsplt = DWC2_HCSPLT_SPLTENA;
-	hcsplt |= hub_devnum << DWC2_HCSPLT_HUBADDR_OFFSET;
-	hcsplt |= hub_port << DWC2_HCSPLT_PRTADDR_OFFSET;
+	hcsplt |= FIELD_PREP(DWC2_HCSPLT_HUBADDR_MASK, hub_devnum);
+	hcsplt |= FIELD_PREP(DWC2_HCSPLT_PRTADDR_MASK, hub_port);
 
 	/* Program the HCSPLIT register for SPLITs */
 	writel(hcsplt, &hc_regs->hcsplt);
@@ -567,11 +557,14 @@ static int dwc_otg_submit_rh_msg_in_status(struct dwc2_core_regs *regs,
 		if (hprt0 & DWC2_HPRT0_PRTPWR)
 			port_status |= USB_PORT_STAT_POWER;
 
-		if ((hprt0 & DWC2_HPRT0_PRTSPD_MASK) == DWC2_HPRT0_PRTSPD_LOW)
+		switch (FIELD_GET(DWC2_HPRT0_PRTSPD_MASK, hprt0)) {
+		case DWC2_HPRT0_PRTSPD_LOW:
 			port_status |= USB_PORT_STAT_LOW_SPEED;
-		else if ((hprt0 & DWC2_HPRT0_PRTSPD_MASK) ==
-			 DWC2_HPRT0_PRTSPD_HIGH)
+			break;
+		case DWC2_HPRT0_PRTSPD_HIGH:
 			port_status |= USB_PORT_STAT_HIGH_SPEED;
+			break;
+		}
 
 		if (hprt0 & DWC2_HPRT0_PRTENCHNG)
 			port_change |= USB_PORT_STAT_C_ENABLE;
@@ -822,9 +815,8 @@ int wait_for_chhltd(struct dwc2_hc_regs *hc_regs, uint32_t *sub, u8 *toggle)
 
 	hcint = readl(&hc_regs->hcint);
 	hctsiz = readl(&hc_regs->hctsiz);
-	*sub = (hctsiz & DWC2_HCTSIZ_XFERSIZE_MASK) >>
-		DWC2_HCTSIZ_XFERSIZE_OFFSET;
-	*toggle = (hctsiz & DWC2_HCTSIZ_PID_MASK) >> DWC2_HCTSIZ_PID_OFFSET;
+	*sub = FIELD_GET(DWC2_HCTSIZ_XFERSIZE_MASK, hctsiz);
+	*toggle = FIELD_GET(DWC2_HCTSIZ_PID_MASK, hctsiz);
 
 	debug("%s: HCINT=%08x sub=%u toggle=%d\n", __func__, hcint, *sub,
 	      *toggle);
@@ -856,9 +848,9 @@ static int transfer_chunk(struct dwc2_hc_regs *hc_regs, void *aligned_buffer,
 	debug("%s: chunk: pid %d xfer_len %u pkts %u\n", __func__,
 	      *pid, xfer_len, num_packets);
 
-	writel((xfer_len << DWC2_HCTSIZ_XFERSIZE_OFFSET) |
-	       (num_packets << DWC2_HCTSIZ_PKTCNT_OFFSET) |
-	       (*pid << DWC2_HCTSIZ_PID_OFFSET),
+	writel(FIELD_PREP(DWC2_HCTSIZ_XFERSIZE_MASK, xfer_len) |
+	       FIELD_PREP(DWC2_HCTSIZ_PKTCNT_MASK, num_packets) |
+	       FIELD_PREP(DWC2_HCTSIZ_PID_MASK, *pid),
 	       &hc_regs->hctsiz);
 
 	if (xfer_len) {
@@ -885,8 +877,8 @@ static int transfer_chunk(struct dwc2_hc_regs *hc_regs, void *aligned_buffer,
 	clrsetbits_le32(&hc_regs->hcchar, DWC2_HCCHAR_MULTICNT_MASK |
 			DWC2_HCCHAR_CHEN | DWC2_HCCHAR_CHDIS |
 			DWC2_HCCHAR_ODDFRM,
-			(1 << DWC2_HCCHAR_MULTICNT_OFFSET) |
-			(odd_frame << DWC2_HCCHAR_ODDFRM_OFFSET) |
+			FIELD_PREP(DWC2_HCCHAR_MULTICNT_MASK, 1) |
+			FIELD_PREP(DWC2_HCCHAR_ODDFRM, odd_frame) |
 			DWC2_HCCHAR_CHEN);
 
 	ret = wait_for_chhltd(hc_regs, &sub, pid);
@@ -950,8 +942,7 @@ int chunk_msg(struct dwc2_priv *priv, struct usb_device *dev,
 		uint8_t hub_port;
 		uint32_t hprt0 = readl(&regs->host_regs.hprt0);
 
-		if ((hprt0 & DWC2_HPRT0_PRTSPD_MASK) ==
-		     DWC2_HPRT0_PRTSPD_HIGH) {
+		if (FIELD_GET(DWC2_HPRT0_PRTSPD_MASK, hprt0) == DWC2_HPRT0_PRTSPD_HIGH) {
 			usb_find_usb2_hub_address_port(dev, &hub_addr,
 						       &hub_port);
 			dwc_otg_hc_init_split(hc_regs, hub_addr, hub_port);
@@ -995,17 +986,17 @@ int chunk_msg(struct dwc2_priv *priv, struct usb_device *dev,
 			stop_transfer = 0;
 			if (hcint & DWC2_HCINT_NYET) {
 				ret = 0;
-				int frame_num = DWC2_HFNUM_MAX_FRNUM &
-						readl(&host_regs->hfnum);
-				if (((frame_num - ssplit_frame_num) &
-				    DWC2_HFNUM_MAX_FRNUM) > 4)
+				int frame_num = FIELD_GET(DWC2_HFNUM_FRNUM_MASK,
+							  readl(&host_regs->hfnum));
+
+				if (((frame_num - ssplit_frame_num) & DWC2_HFNUM_FRNUM_MASK) > 4)
 					ret = -EAGAIN;
 			} else
 				complete_split = 0;
 		} else if (do_split) {
 			if (hcint & DWC2_HCINT_ACK) {
-				ssplit_frame_num = DWC2_HFNUM_MAX_FRNUM &
-						   readl(&host_regs->hfnum);
+				ssplit_frame_num = FIELD_GET(DWC2_HFNUM_FRNUM_MASK,
+							     readl(&host_regs->hfnum));
 				ret = 0;
 				complete_split = 1;
 			}
@@ -1183,8 +1174,8 @@ static int dwc2_init_common(struct udevice *dev, struct dwc2_priv *priv)
 	dev_info(dev, "Core Release: %x.%03x\n",
 		 snpsid >> 12 & 0xf, snpsid & 0xfff);
 
-	if ((snpsid & DWC2_SNPSID_DEVID_MASK) != DWC2_SNPSID_DEVID_VER_2xx &&
-	    (snpsid & DWC2_SNPSID_DEVID_MASK) != DWC2_SNPSID_DEVID_VER_3xx) {
+	if (FIELD_GET(DWC2_SNPSID_DEVID_MASK, snpsid) != DWC2_SNPSID_DEVID_VER_2xx &&
+	    FIELD_GET(DWC2_SNPSID_DEVID_MASK, snpsid) != DWC2_SNPSID_DEVID_VER_3xx) {
 		dev_info(dev, "SNPSID invalid (not DWC2 OTG device): %08x\n",
 			 snpsid);
 		return -ENODEV;
diff --git a/drivers/usb/host/dwc2.h b/drivers/usb/host/dwc2.h
index 61b544462edfd6778ddf2ddf2dcf6db3f02a3754..6bd98b481f2449e32f5ccf3dc5baca814a2f4a16 100644
--- a/drivers/usb/host/dwc2.h
+++ b/drivers/usb/host/dwc2.h
@@ -6,683 +6,358 @@
 #ifndef __DWC2_H__
 #define __DWC2_H__
 
-#define DWC2_GOTGCTL_SESREQSCS				(1 << 0)
-#define DWC2_GOTGCTL_SESREQSCS_OFFSET			0
-#define DWC2_GOTGCTL_SESREQ				(1 << 1)
-#define DWC2_GOTGCTL_SESREQ_OFFSET			1
-#define DWC2_GOTGCTL_HSTNEGSCS				(1 << 8)
-#define DWC2_GOTGCTL_HSTNEGSCS_OFFSET			8
-#define DWC2_GOTGCTL_HNPREQ				(1 << 9)
-#define DWC2_GOTGCTL_HNPREQ_OFFSET			9
-#define DWC2_GOTGCTL_HSTSETHNPEN			(1 << 10)
-#define DWC2_GOTGCTL_HSTSETHNPEN_OFFSET			10
-#define DWC2_GOTGCTL_DEVHNPEN				(1 << 11)
-#define DWC2_GOTGCTL_DEVHNPEN_OFFSET			11
-#define DWC2_GOTGCTL_CONIDSTS				(1 << 16)
-#define DWC2_GOTGCTL_CONIDSTS_OFFSET			16
-#define DWC2_GOTGCTL_DBNCTIME				(1 << 17)
-#define DWC2_GOTGCTL_DBNCTIME_OFFSET			17
-#define DWC2_GOTGCTL_ASESVLD				(1 << 18)
-#define DWC2_GOTGCTL_ASESVLD_OFFSET			18
-#define DWC2_GOTGCTL_BSESVLD				(1 << 19)
-#define DWC2_GOTGCTL_BSESVLD_OFFSET			19
-#define DWC2_GOTGCTL_OTGVER				(1 << 20)
-#define DWC2_GOTGCTL_OTGVER_OFFSET			20
-#define DWC2_GOTGINT_SESENDDET				(1 << 2)
-#define DWC2_GOTGINT_SESENDDET_OFFSET			2
-#define DWC2_GOTGINT_SESREQSUCSTSCHNG			(1 << 8)
-#define DWC2_GOTGINT_SESREQSUCSTSCHNG_OFFSET		8
-#define DWC2_GOTGINT_HSTNEGSUCSTSCHNG			(1 << 9)
-#define DWC2_GOTGINT_HSTNEGSUCSTSCHNG_OFFSET		9
-#define DWC2_GOTGINT_RESERVER10_16_MASK			(0x7F << 10)
-#define DWC2_GOTGINT_RESERVER10_16_OFFSET		10
-#define DWC2_GOTGINT_HSTNEGDET				(1 << 17)
-#define DWC2_GOTGINT_HSTNEGDET_OFFSET			17
-#define DWC2_GOTGINT_ADEVTOUTCHNG			(1 << 18)
-#define DWC2_GOTGINT_ADEVTOUTCHNG_OFFSET		18
-#define DWC2_GOTGINT_DEBDONE				(1 << 19)
-#define DWC2_GOTGINT_DEBDONE_OFFSET			19
-#define DWC2_GAHBCFG_GLBLINTRMSK			(1 << 0)
-#define DWC2_GAHBCFG_GLBLINTRMSK_OFFSET			0
+#include <linux/bitops.h>
+
+#define DWC2_GOTGCTL_SESREQSCS				BIT(0)
+#define DWC2_GOTGCTL_SESREQ				BIT(1)
+#define DWC2_GOTGCTL_HSTNEGSCS				BIT(8)
+#define DWC2_GOTGCTL_HNPREQ				BIT(9)
+#define DWC2_GOTGCTL_HSTSETHNPEN			BIT(10)
+#define DWC2_GOTGCTL_DEVHNPEN				BIT(11)
+#define DWC2_GOTGCTL_CONIDSTS				BIT(16)
+#define DWC2_GOTGCTL_DBNCTIME				BIT(17)
+#define DWC2_GOTGCTL_ASESVLD				BIT(18)
+#define DWC2_GOTGCTL_BSESVLD				BIT(19)
+#define DWC2_GOTGCTL_OTGVER				BIT(20)
+#define DWC2_GOTGINT_SESENDDET				BIT(2)
+#define DWC2_GOTGINT_SESREQSUCSTSCHNG			BIT(8)
+#define DWC2_GOTGINT_HSTNEGSUCSTSCHNG			BIT(9)
+#define DWC2_GOTGINT_RESERVER10_16_MASK			GENMASK(16, 10)
+#define DWC2_GOTGINT_HSTNEGDET				BIT(17)
+#define DWC2_GOTGINT_ADEVTOUTCHNG			BIT(18)
+#define DWC2_GOTGINT_DEBDONE				BIT(19)
+#define DWC2_GAHBCFG_GLBLINTRMSK			BIT(0)
 #define DWC2_GAHBCFG_HBURSTLEN_SINGLE			(0 << 1)
 #define DWC2_GAHBCFG_HBURSTLEN_INCR			(1 << 1)
 #define DWC2_GAHBCFG_HBURSTLEN_INCR4			(3 << 1)
 #define DWC2_GAHBCFG_HBURSTLEN_INCR8			(5 << 1)
 #define DWC2_GAHBCFG_HBURSTLEN_INCR16			(7 << 1)
-#define DWC2_GAHBCFG_HBURSTLEN_MASK			(0xF << 1)
-#define DWC2_GAHBCFG_HBURSTLEN_OFFSET			1
-#define DWC2_GAHBCFG_DMAENABLE				(1 << 5)
-#define DWC2_GAHBCFG_DMAENABLE_OFFSET			5
-#define DWC2_GAHBCFG_NPTXFEMPLVL_TXFEMPLVL		(1 << 7)
-#define DWC2_GAHBCFG_NPTXFEMPLVL_TXFEMPLVL_OFFSET	7
-#define DWC2_GAHBCFG_PTXFEMPLVL				(1 << 8)
-#define DWC2_GAHBCFG_PTXFEMPLVL_OFFSET			8
-#define DWC2_GUSBCFG_TOUTCAL_MASK			(0x7 << 0)
-#define DWC2_GUSBCFG_TOUTCAL_OFFSET			0
-#define DWC2_GUSBCFG_PHYIF				(1 << 3)
-#define DWC2_GUSBCFG_PHYIF_OFFSET			3
-#define DWC2_GUSBCFG_ULPI_UTMI_SEL			(1 << 4)
-#define DWC2_GUSBCFG_ULPI_UTMI_SEL_OFFSET		4
-#define DWC2_GUSBCFG_FSINTF				(1 << 5)
-#define DWC2_GUSBCFG_FSINTF_OFFSET			5
-#define DWC2_GUSBCFG_PHYSEL				(1 << 6)
-#define DWC2_GUSBCFG_PHYSEL_OFFSET			6
-#define DWC2_GUSBCFG_DDRSEL				(1 << 7)
-#define DWC2_GUSBCFG_DDRSEL_OFFSET			7
-#define DWC2_GUSBCFG_SRPCAP				(1 << 8)
-#define DWC2_GUSBCFG_SRPCAP_OFFSET			8
-#define DWC2_GUSBCFG_HNPCAP				(1 << 9)
-#define DWC2_GUSBCFG_HNPCAP_OFFSET			9
-#define DWC2_GUSBCFG_USBTRDTIM_MASK			(0xF << 10)
-#define DWC2_GUSBCFG_USBTRDTIM_OFFSET			10
-#define DWC2_GUSBCFG_NPTXFRWNDEN			(1 << 14)
-#define DWC2_GUSBCFG_NPTXFRWNDEN_OFFSET			14
-#define DWC2_GUSBCFG_PHYLPWRCLKSEL			(1 << 15)
-#define DWC2_GUSBCFG_PHYLPWRCLKSEL_OFFSET		15
-#define DWC2_GUSBCFG_OTGUTMIFSSEL			(1 << 16)
-#define DWC2_GUSBCFG_OTGUTMIFSSEL_OFFSET		16
-#define DWC2_GUSBCFG_ULPI_FSLS				(1 << 17)
-#define DWC2_GUSBCFG_ULPI_FSLS_OFFSET			17
-#define DWC2_GUSBCFG_ULPI_AUTO_RES			(1 << 18)
-#define DWC2_GUSBCFG_ULPI_AUTO_RES_OFFSET		18
-#define DWC2_GUSBCFG_ULPI_CLK_SUS_M			(1 << 19)
-#define DWC2_GUSBCFG_ULPI_CLK_SUS_M_OFFSET		19
-#define DWC2_GUSBCFG_ULPI_EXT_VBUS_DRV			(1 << 20)
-#define DWC2_GUSBCFG_ULPI_EXT_VBUS_DRV_OFFSET		20
-#define DWC2_GUSBCFG_ULPI_INT_VBUS_INDICATOR		(1 << 21)
-#define DWC2_GUSBCFG_ULPI_INT_VBUS_INDICATOR_OFFSET	21
-#define DWC2_GUSBCFG_TERM_SEL_DL_PULSE			(1 << 22)
-#define DWC2_GUSBCFG_TERM_SEL_DL_PULSE_OFFSET		22
-#define DWC2_GUSBCFG_INDICATOR_PASSTHROUGH		(1 << 24)
-#define DWC2_GUSBCFG_INDICATOR_PASSTHROUGH_OFFSET	24
-#define DWC2_GUSBCFG_IC_USB_CAP				(1 << 26)
-#define DWC2_GUSBCFG_IC_USB_CAP_OFFSET			26
-#define DWC2_GUSBCFG_IC_TRAFFIC_PULL_REMOVE		(1 << 27)
-#define DWC2_GUSBCFG_IC_TRAFFIC_PULL_REMOVE_OFFSET	27
-#define DWC2_GUSBCFG_TX_END_DELAY			(1 << 28)
-#define DWC2_GUSBCFG_TX_END_DELAY_OFFSET		28
-#define DWC2_GUSBCFG_FORCEHOSTMODE			(1 << 29)
-#define DWC2_GUSBCFG_FORCEHOSTMODE_OFFSET		29
-#define DWC2_GUSBCFG_FORCEDEVMODE			(1 << 30)
-#define DWC2_GUSBCFG_FORCEDEVMODE_OFFSET		30
-#define DWC2_GLPMCTL_LPM_CAP_EN				(1 << 0)
-#define DWC2_GLPMCTL_LPM_CAP_EN_OFFSET			0
-#define DWC2_GLPMCTL_APPL_RESP				(1 << 1)
-#define DWC2_GLPMCTL_APPL_RESP_OFFSET			1
-#define DWC2_GLPMCTL_HIRD_MASK				(0xF << 2)
-#define DWC2_GLPMCTL_HIRD_OFFSET			2
-#define DWC2_GLPMCTL_REM_WKUP_EN			(1 << 6)
-#define DWC2_GLPMCTL_REM_WKUP_EN_OFFSET			6
-#define DWC2_GLPMCTL_EN_UTMI_SLEEP			(1 << 7)
-#define DWC2_GLPMCTL_EN_UTMI_SLEEP_OFFSET		7
-#define DWC2_GLPMCTL_HIRD_THRES_MASK			(0x1F << 8)
-#define DWC2_GLPMCTL_HIRD_THRES_OFFSET			8
-#define DWC2_GLPMCTL_LPM_RESP_MASK			(0x3 << 13)
-#define DWC2_GLPMCTL_LPM_RESP_OFFSET			13
-#define DWC2_GLPMCTL_PRT_SLEEP_STS			(1 << 15)
-#define DWC2_GLPMCTL_PRT_SLEEP_STS_OFFSET		15
-#define DWC2_GLPMCTL_SLEEP_STATE_RESUMEOK		(1 << 16)
-#define DWC2_GLPMCTL_SLEEP_STATE_RESUMEOK_OFFSET	16
-#define DWC2_GLPMCTL_LPM_CHAN_INDEX_MASK		(0xF << 17)
-#define DWC2_GLPMCTL_LPM_CHAN_INDEX_OFFSET		17
-#define DWC2_GLPMCTL_RETRY_COUNT_MASK			(0x7 << 21)
-#define DWC2_GLPMCTL_RETRY_COUNT_OFFSET			21
-#define DWC2_GLPMCTL_SEND_LPM				(1 << 24)
-#define DWC2_GLPMCTL_SEND_LPM_OFFSET			24
-#define DWC2_GLPMCTL_RETRY_COUNT_STS_MASK		(0x7 << 25)
-#define DWC2_GLPMCTL_RETRY_COUNT_STS_OFFSET		25
-#define DWC2_GLPMCTL_HSIC_CONNECT			(1 << 30)
-#define DWC2_GLPMCTL_HSIC_CONNECT_OFFSET		30
-#define DWC2_GLPMCTL_INV_SEL_HSIC			(1 << 31)
-#define DWC2_GLPMCTL_INV_SEL_HSIC_OFFSET		31
-#define DWC2_GRSTCTL_CSFTRST				(1 << 0)
-#define DWC2_GRSTCTL_CSFTRST_OFFSET			0
-#define DWC2_GRSTCTL_HSFTRST				(1 << 1)
-#define DWC2_GRSTCTL_HSFTRST_OFFSET			1
-#define DWC2_GRSTCTL_HSTFRM				(1 << 2)
-#define DWC2_GRSTCTL_HSTFRM_OFFSET			2
-#define DWC2_GRSTCTL_INTKNQFLSH				(1 << 3)
-#define DWC2_GRSTCTL_INTKNQFLSH_OFFSET			3
-#define DWC2_GRSTCTL_RXFFLSH				(1 << 4)
-#define DWC2_GRSTCTL_RXFFLSH_OFFSET			4
-#define DWC2_GRSTCTL_TXFFLSH				(1 << 5)
-#define DWC2_GRSTCTL_TXFFLSH_OFFSET			5
-#define DWC2_GRSTCTL_TXFNUM_MASK			(0x1F << 6)
-#define DWC2_GRSTCTL_TXFNUM_OFFSET			6
-#define DWC2_GRSTCTL_DMAREQ				(1 << 30)
-#define DWC2_GRSTCTL_DMAREQ_OFFSET			30
-#define DWC2_GRSTCTL_AHBIDLE				(1 << 31)
-#define DWC2_GRSTCTL_AHBIDLE_OFFSET			31
-#define DWC2_GINTMSK_MODEMISMATCH			(1 << 1)
-#define DWC2_GINTMSK_MODEMISMATCH_OFFSET		1
-#define DWC2_GINTMSK_OTGINTR				(1 << 2)
-#define DWC2_GINTMSK_OTGINTR_OFFSET			2
-#define DWC2_GINTMSK_SOFINTR				(1 << 3)
-#define DWC2_GINTMSK_SOFINTR_OFFSET			3
-#define DWC2_GINTMSK_RXSTSQLVL				(1 << 4)
-#define DWC2_GINTMSK_RXSTSQLVL_OFFSET			4
-#define DWC2_GINTMSK_NPTXFEMPTY				(1 << 5)
-#define DWC2_GINTMSK_NPTXFEMPTY_OFFSET			5
-#define DWC2_GINTMSK_GINNAKEFF				(1 << 6)
-#define DWC2_GINTMSK_GINNAKEFF_OFFSET			6
-#define DWC2_GINTMSK_GOUTNAKEFF				(1 << 7)
-#define DWC2_GINTMSK_GOUTNAKEFF_OFFSET			7
-#define DWC2_GINTMSK_I2CINTR				(1 << 9)
-#define DWC2_GINTMSK_I2CINTR_OFFSET			9
-#define DWC2_GINTMSK_ERLYSUSPEND			(1 << 10)
-#define DWC2_GINTMSK_ERLYSUSPEND_OFFSET			10
-#define DWC2_GINTMSK_USBSUSPEND				(1 << 11)
-#define DWC2_GINTMSK_USBSUSPEND_OFFSET			11
-#define DWC2_GINTMSK_USBRESET				(1 << 12)
-#define DWC2_GINTMSK_USBRESET_OFFSET			12
-#define DWC2_GINTMSK_ENUMDONE				(1 << 13)
-#define DWC2_GINTMSK_ENUMDONE_OFFSET			13
-#define DWC2_GINTMSK_ISOOUTDROP				(1 << 14)
-#define DWC2_GINTMSK_ISOOUTDROP_OFFSET			14
-#define DWC2_GINTMSK_EOPFRAME				(1 << 15)
-#define DWC2_GINTMSK_EOPFRAME_OFFSET			15
-#define DWC2_GINTMSK_EPMISMATCH				(1 << 17)
-#define DWC2_GINTMSK_EPMISMATCH_OFFSET			17
-#define DWC2_GINTMSK_INEPINTR				(1 << 18)
-#define DWC2_GINTMSK_INEPINTR_OFFSET			18
-#define DWC2_GINTMSK_OUTEPINTR				(1 << 19)
-#define DWC2_GINTMSK_OUTEPINTR_OFFSET			19
-#define DWC2_GINTMSK_INCOMPLISOIN			(1 << 20)
-#define DWC2_GINTMSK_INCOMPLISOIN_OFFSET		20
-#define DWC2_GINTMSK_INCOMPLISOOUT			(1 << 21)
-#define DWC2_GINTMSK_INCOMPLISOOUT_OFFSET		21
-#define DWC2_GINTMSK_PORTINTR				(1 << 24)
-#define DWC2_GINTMSK_PORTINTR_OFFSET			24
-#define DWC2_GINTMSK_HCINTR				(1 << 25)
-#define DWC2_GINTMSK_HCINTR_OFFSET			25
-#define DWC2_GINTMSK_PTXFEMPTY				(1 << 26)
-#define DWC2_GINTMSK_PTXFEMPTY_OFFSET			26
-#define DWC2_GINTMSK_LPMTRANRCVD			(1 << 27)
-#define DWC2_GINTMSK_LPMTRANRCVD_OFFSET			27
-#define DWC2_GINTMSK_CONIDSTSCHNG			(1 << 28)
-#define DWC2_GINTMSK_CONIDSTSCHNG_OFFSET		28
-#define DWC2_GINTMSK_DISCONNECT				(1 << 29)
-#define DWC2_GINTMSK_DISCONNECT_OFFSET			29
-#define DWC2_GINTMSK_SESSREQINTR			(1 << 30)
-#define DWC2_GINTMSK_SESSREQINTR_OFFSET			30
-#define DWC2_GINTMSK_WKUPINTR				(1 << 31)
-#define DWC2_GINTMSK_WKUPINTR_OFFSET			31
-#define DWC2_GINTSTS_CURMODE_DEVICE			(0 << 0)
-#define DWC2_GINTSTS_CURMODE_HOST			(1 << 0)
-#define DWC2_GINTSTS_CURMODE				(1 << 0)
-#define DWC2_GINTSTS_CURMODE_OFFSET			0
-#define DWC2_GINTSTS_MODEMISMATCH			(1 << 1)
-#define DWC2_GINTSTS_MODEMISMATCH_OFFSET		1
-#define DWC2_GINTSTS_OTGINTR				(1 << 2)
-#define DWC2_GINTSTS_OTGINTR_OFFSET			2
-#define DWC2_GINTSTS_SOFINTR				(1 << 3)
-#define DWC2_GINTSTS_SOFINTR_OFFSET			3
-#define DWC2_GINTSTS_RXSTSQLVL				(1 << 4)
-#define DWC2_GINTSTS_RXSTSQLVL_OFFSET			4
-#define DWC2_GINTSTS_NPTXFEMPTY				(1 << 5)
-#define DWC2_GINTSTS_NPTXFEMPTY_OFFSET			5
-#define DWC2_GINTSTS_GINNAKEFF				(1 << 6)
-#define DWC2_GINTSTS_GINNAKEFF_OFFSET			6
-#define DWC2_GINTSTS_GOUTNAKEFF				(1 << 7)
-#define DWC2_GINTSTS_GOUTNAKEFF_OFFSET			7
-#define DWC2_GINTSTS_I2CINTR				(1 << 9)
-#define DWC2_GINTSTS_I2CINTR_OFFSET			9
-#define DWC2_GINTSTS_ERLYSUSPEND			(1 << 10)
-#define DWC2_GINTSTS_ERLYSUSPEND_OFFSET			10
-#define DWC2_GINTSTS_USBSUSPEND				(1 << 11)
-#define DWC2_GINTSTS_USBSUSPEND_OFFSET			11
-#define DWC2_GINTSTS_USBRESET				(1 << 12)
-#define DWC2_GINTSTS_USBRESET_OFFSET			12
-#define DWC2_GINTSTS_ENUMDONE				(1 << 13)
-#define DWC2_GINTSTS_ENUMDONE_OFFSET			13
-#define DWC2_GINTSTS_ISOOUTDROP				(1 << 14)
-#define DWC2_GINTSTS_ISOOUTDROP_OFFSET			14
-#define DWC2_GINTSTS_EOPFRAME				(1 << 15)
-#define DWC2_GINTSTS_EOPFRAME_OFFSET			15
-#define DWC2_GINTSTS_INTOKENRX				(1 << 16)
-#define DWC2_GINTSTS_INTOKENRX_OFFSET			16
-#define DWC2_GINTSTS_EPMISMATCH				(1 << 17)
-#define DWC2_GINTSTS_EPMISMATCH_OFFSET			17
-#define DWC2_GINTSTS_INEPINT				(1 << 18)
-#define DWC2_GINTSTS_INEPINT_OFFSET			18
-#define DWC2_GINTSTS_OUTEPINTR				(1 << 19)
-#define DWC2_GINTSTS_OUTEPINTR_OFFSET			19
-#define DWC2_GINTSTS_INCOMPLISOIN			(1 << 20)
-#define DWC2_GINTSTS_INCOMPLISOIN_OFFSET		20
-#define DWC2_GINTSTS_INCOMPLISOOUT			(1 << 21)
-#define DWC2_GINTSTS_INCOMPLISOOUT_OFFSET		21
-#define DWC2_GINTSTS_PORTINTR				(1 << 24)
-#define DWC2_GINTSTS_PORTINTR_OFFSET			24
-#define DWC2_GINTSTS_HCINTR				(1 << 25)
-#define DWC2_GINTSTS_HCINTR_OFFSET			25
-#define DWC2_GINTSTS_PTXFEMPTY				(1 << 26)
-#define DWC2_GINTSTS_PTXFEMPTY_OFFSET			26
-#define DWC2_GINTSTS_LPMTRANRCVD			(1 << 27)
-#define DWC2_GINTSTS_LPMTRANRCVD_OFFSET			27
-#define DWC2_GINTSTS_CONIDSTSCHNG			(1 << 28)
-#define DWC2_GINTSTS_CONIDSTSCHNG_OFFSET		28
-#define DWC2_GINTSTS_DISCONNECT				(1 << 29)
-#define DWC2_GINTSTS_DISCONNECT_OFFSET			29
-#define DWC2_GINTSTS_SESSREQINTR			(1 << 30)
-#define DWC2_GINTSTS_SESSREQINTR_OFFSET			30
-#define DWC2_GINTSTS_WKUPINTR				(1 << 31)
-#define DWC2_GINTSTS_WKUPINTR_OFFSET			31
-#define DWC2_GRXSTS_EPNUM_MASK				(0xF << 0)
-#define DWC2_GRXSTS_EPNUM_OFFSET			0
-#define DWC2_GRXSTS_BCNT_MASK				(0x7FF << 4)
-#define DWC2_GRXSTS_BCNT_OFFSET				4
-#define DWC2_GRXSTS_DPID_MASK				(0x3 << 15)
-#define DWC2_GRXSTS_DPID_OFFSET				15
-#define DWC2_GRXSTS_PKTSTS_MASK				(0xF << 17)
-#define DWC2_GRXSTS_PKTSTS_OFFSET			17
-#define DWC2_GRXSTS_FN_MASK				(0xF << 21)
-#define DWC2_GRXSTS_FN_OFFSET				21
-#define DWC2_FIFOSIZE_STARTADDR_MASK			(0xFFFF << 0)
-#define DWC2_FIFOSIZE_STARTADDR_OFFSET			0
-#define DWC2_FIFOSIZE_DEPTH_MASK			(0xFFFF << 16)
-#define DWC2_FIFOSIZE_DEPTH_OFFSET			16
-#define DWC2_GNPTXSTS_NPTXFSPCAVAIL_MASK		(0xFFFF << 0)
-#define DWC2_GNPTXSTS_NPTXFSPCAVAIL_OFFSET		0
-#define DWC2_GNPTXSTS_NPTXQSPCAVAIL_MASK		(0xFF << 16)
-#define DWC2_GNPTXSTS_NPTXQSPCAVAIL_OFFSET		16
-#define DWC2_GNPTXSTS_NPTXQTOP_TERMINATE		(1 << 24)
-#define DWC2_GNPTXSTS_NPTXQTOP_TERMINATE_OFFSET		24
-#define DWC2_GNPTXSTS_NPTXQTOP_TOKEN_MASK		(0x3 << 25)
-#define DWC2_GNPTXSTS_NPTXQTOP_TOKEN_OFFSET		25
-#define DWC2_GNPTXSTS_NPTXQTOP_CHNEP_MASK		(0xF << 27)
-#define DWC2_GNPTXSTS_NPTXQTOP_CHNEP_OFFSET		27
-#define DWC2_DTXFSTS_TXFSPCAVAIL_MASK			(0xFFFF << 0)
-#define DWC2_DTXFSTS_TXFSPCAVAIL_OFFSET			0
-#define DWC2_GI2CCTL_RWDATA_MASK			(0xFF << 0)
-#define DWC2_GI2CCTL_RWDATA_OFFSET			0
-#define DWC2_GI2CCTL_REGADDR_MASK			(0xFF << 8)
-#define DWC2_GI2CCTL_REGADDR_OFFSET			8
-#define DWC2_GI2CCTL_ADDR_MASK				(0x7F << 16)
-#define DWC2_GI2CCTL_ADDR_OFFSET			16
-#define DWC2_GI2CCTL_I2CEN				(1 << 23)
-#define DWC2_GI2CCTL_I2CEN_OFFSET			23
-#define DWC2_GI2CCTL_ACK				(1 << 24)
-#define DWC2_GI2CCTL_ACK_OFFSET				24
-#define DWC2_GI2CCTL_I2CSUSPCTL				(1 << 25)
-#define DWC2_GI2CCTL_I2CSUSPCTL_OFFSET			25
-#define DWC2_GI2CCTL_I2CDEVADDR_MASK			(0x3 << 26)
-#define DWC2_GI2CCTL_I2CDEVADDR_OFFSET			26
-#define DWC2_GI2CCTL_RW					(1 << 30)
-#define DWC2_GI2CCTL_RW_OFFSET				30
-#define DWC2_GI2CCTL_BSYDNE				(1 << 31)
-#define DWC2_GI2CCTL_BSYDNE_OFFSET			31
-#define DWC2_HWCFG1_EP_DIR0_MASK			(0x3 << 0)
-#define DWC2_HWCFG1_EP_DIR0_OFFSET			0
-#define DWC2_HWCFG1_EP_DIR1_MASK			(0x3 << 2)
-#define DWC2_HWCFG1_EP_DIR1_OFFSET			2
-#define DWC2_HWCFG1_EP_DIR2_MASK			(0x3 << 4)
-#define DWC2_HWCFG1_EP_DIR2_OFFSET			4
-#define DWC2_HWCFG1_EP_DIR3_MASK			(0x3 << 6)
-#define DWC2_HWCFG1_EP_DIR3_OFFSET			6
-#define DWC2_HWCFG1_EP_DIR4_MASK			(0x3 << 8)
-#define DWC2_HWCFG1_EP_DIR4_OFFSET			8
-#define DWC2_HWCFG1_EP_DIR5_MASK			(0x3 << 10)
-#define DWC2_HWCFG1_EP_DIR5_OFFSET			10
-#define DWC2_HWCFG1_EP_DIR6_MASK			(0x3 << 12)
-#define DWC2_HWCFG1_EP_DIR6_OFFSET			12
-#define DWC2_HWCFG1_EP_DIR7_MASK			(0x3 << 14)
-#define DWC2_HWCFG1_EP_DIR7_OFFSET			14
-#define DWC2_HWCFG1_EP_DIR8_MASK			(0x3 << 16)
-#define DWC2_HWCFG1_EP_DIR8_OFFSET			16
-#define DWC2_HWCFG1_EP_DIR9_MASK			(0x3 << 18)
-#define DWC2_HWCFG1_EP_DIR9_OFFSET			18
-#define DWC2_HWCFG1_EP_DIR10_MASK			(0x3 << 20)
-#define DWC2_HWCFG1_EP_DIR10_OFFSET			20
-#define DWC2_HWCFG1_EP_DIR11_MASK			(0x3 << 22)
-#define DWC2_HWCFG1_EP_DIR11_OFFSET			22
-#define DWC2_HWCFG1_EP_DIR12_MASK			(0x3 << 24)
-#define DWC2_HWCFG1_EP_DIR12_OFFSET			24
-#define DWC2_HWCFG1_EP_DIR13_MASK			(0x3 << 26)
-#define DWC2_HWCFG1_EP_DIR13_OFFSET			26
-#define DWC2_HWCFG1_EP_DIR14_MASK			(0x3 << 28)
-#define DWC2_HWCFG1_EP_DIR14_OFFSET			28
-#define DWC2_HWCFG1_EP_DIR15_MASK			(0x3 << 30)
-#define DWC2_HWCFG1_EP_DIR15_OFFSET			30
-#define DWC2_HWCFG2_OP_MODE_MASK			(0x7 << 0)
-#define DWC2_HWCFG2_OP_MODE_OFFSET			0
+#define DWC2_GAHBCFG_HBURSTLEN_MASK			GENMASK(4, 1)
+#define DWC2_GAHBCFG_DMAENABLE				BIT(5)
+#define DWC2_GAHBCFG_NPTXFEMPLVL_TXFEMPLVL		BIT(7)
+#define DWC2_GAHBCFG_PTXFEMPLVL				BIT(8)
+#define DWC2_GUSBCFG_TOUTCAL_MASK			GENMASK(2, 0)
+#define DWC2_GUSBCFG_PHYIF				BIT(3)
+#define DWC2_GUSBCFG_ULPI_UTMI_SEL			BIT(4)
+#define DWC2_GUSBCFG_FSINTF				BIT(5)
+#define DWC2_GUSBCFG_PHYSEL				BIT(6)
+#define DWC2_GUSBCFG_DDRSEL				BIT(7)
+#define DWC2_GUSBCFG_SRPCAP				BIT(8)
+#define DWC2_GUSBCFG_HNPCAP				BIT(9)
+#define DWC2_GUSBCFG_USBTRDTIM_MASK			GENMASK(13, 10)
+#define DWC2_GUSBCFG_NPTXFRWNDEN			BIT(14)
+#define DWC2_GUSBCFG_PHYLPWRCLKSEL			BIT(15)
+#define DWC2_GUSBCFG_OTGUTMIFSSEL			BIT(16)
+#define DWC2_GUSBCFG_ULPI_FSLS				BIT(17)
+#define DWC2_GUSBCFG_ULPI_AUTO_RES			BIT(18)
+#define DWC2_GUSBCFG_ULPI_CLK_SUS_M			BIT(19)
+#define DWC2_GUSBCFG_ULPI_EXT_VBUS_DRV			BIT(20)
+#define DWC2_GUSBCFG_ULPI_INT_VBUS_INDICATOR		BIT(21)
+#define DWC2_GUSBCFG_TERM_SEL_DL_PULSE			BIT(22)
+#define DWC2_GUSBCFG_INDICATOR_PASSTHROUGH		BIT(24)
+#define DWC2_GUSBCFG_IC_USB_CAP				BIT(26)
+#define DWC2_GUSBCFG_IC_TRAFFIC_PULL_REMOVE		BIT(27)
+#define DWC2_GUSBCFG_TX_END_DELAY			BIT(28)
+#define DWC2_GUSBCFG_FORCEHOSTMODE			BIT(29)
+#define DWC2_GUSBCFG_FORCEDEVMODE			BIT(30)
+#define DWC2_GLPMCTL_LPM_CAP_EN				BIT(0)
+#define DWC2_GLPMCTL_APPL_RESP				BIT(1)
+#define DWC2_GLPMCTL_HIRD_MASK				GENMASK(5, 2)
+#define DWC2_GLPMCTL_REM_WKUP_EN			BIT(6)
+#define DWC2_GLPMCTL_EN_UTMI_SLEEP			BIT(7)
+#define DWC2_GLPMCTL_HIRD_THRES_MASK			GENMASK(12, 8)
+#define DWC2_GLPMCTL_LPM_RESP_MASK			GENMASK(14, 13)
+#define DWC2_GLPMCTL_PRT_SLEEP_STS			BIT(15)
+#define DWC2_GLPMCTL_SLEEP_STATE_RESUMEOK		BIT(16)
+#define DWC2_GLPMCTL_LPM_CHAN_INDEX_MASK		GENMASK(20, 17)
+#define DWC2_GLPMCTL_RETRY_COUNT_MASK			GENMASK(23, 21)
+#define DWC2_GLPMCTL_SEND_LPM				BIT(24)
+#define DWC2_GLPMCTL_RETRY_COUNT_STS_MASK		GENMASK(27, 25)
+#define DWC2_GLPMCTL_HSIC_CONNECT			BIT(30)
+#define DWC2_GLPMCTL_INV_SEL_HSIC			BIT(31)
+#define DWC2_GRSTCTL_CSFTRST				BIT(0)
+#define DWC2_GRSTCTL_HSFTRST				BIT(1)
+#define DWC2_GRSTCTL_HSTFRM				BIT(2)
+#define DWC2_GRSTCTL_INTKNQFLSH				BIT(3)
+#define DWC2_GRSTCTL_RXFFLSH				BIT(4)
+#define DWC2_GRSTCTL_TXFFLSH				BIT(5)
+#define DWC2_GRSTCTL_TXFNUM_MASK			GENMASK(10, 6)
+#define DWC2_GRSTCTL_DMAREQ				BIT(30)
+#define DWC2_GRSTCTL_AHBIDLE				BIT(31)
+#define DWC2_GINTMSK_MODEMISMATCH			BIT(1)
+#define DWC2_GINTMSK_OTGINTR				BIT(2)
+#define DWC2_GINTMSK_SOFINTR				BIT(3)
+#define DWC2_GINTMSK_RXSTSQLVL				BIT(4)
+#define DWC2_GINTMSK_NPTXFEMPTY				BIT(5)
+#define DWC2_GINTMSK_GINNAKEFF				BIT(6)
+#define DWC2_GINTMSK_GOUTNAKEFF				BIT(7)
+#define DWC2_GINTMSK_I2CINTR				BIT(9)
+#define DWC2_GINTMSK_ERLYSUSPEND			BIT(10)
+#define DWC2_GINTMSK_USBSUSPEND				BIT(11)
+#define DWC2_GINTMSK_USBRESET				BIT(12)
+#define DWC2_GINTMSK_ENUMDONE				BIT(13)
+#define DWC2_GINTMSK_ISOOUTDROP				BIT(14)
+#define DWC2_GINTMSK_EOPFRAME				BIT(15)
+#define DWC2_GINTMSK_EPMISMATCH				BIT(17)
+#define DWC2_GINTMSK_INEPINTR				BIT(18)
+#define DWC2_GINTMSK_OUTEPINTR				BIT(19)
+#define DWC2_GINTMSK_INCOMPLISOIN			BIT(20)
+#define DWC2_GINTMSK_INCOMPLISOOUT			BIT(21)
+#define DWC2_GINTMSK_PORTINTR				BIT(24)
+#define DWC2_GINTMSK_HCINTR				BIT(25)
+#define DWC2_GINTMSK_PTXFEMPTY				BIT(26)
+#define DWC2_GINTMSK_LPMTRANRCVD			BIT(27)
+#define DWC2_GINTMSK_CONIDSTSCHNG			BIT(28)
+#define DWC2_GINTMSK_DISCONNECT				BIT(29)
+#define DWC2_GINTMSK_SESSREQINTR			BIT(30)
+#define DWC2_GINTMSK_WKUPINTR				BIT(31)
+#define DWC2_GINTSTS_CURMODE_HOST			BIT(0)
+#define DWC2_GINTSTS_MODEMISMATCH			BIT(1)
+#define DWC2_GINTSTS_OTGINTR				BIT(2)
+#define DWC2_GINTSTS_SOFINTR				BIT(3)
+#define DWC2_GINTSTS_RXSTSQLVL				BIT(4)
+#define DWC2_GINTSTS_NPTXFEMPTY				BIT(5)
+#define DWC2_GINTSTS_GINNAKEFF				BIT(6)
+#define DWC2_GINTSTS_GOUTNAKEFF				BIT(7)
+#define DWC2_GINTSTS_I2CINTR				BIT(9)
+#define DWC2_GINTSTS_ERLYSUSPEND			BIT(10)
+#define DWC2_GINTSTS_USBSUSPEND				BIT(11)
+#define DWC2_GINTSTS_USBRESET				BIT(12)
+#define DWC2_GINTSTS_ENUMDONE				BIT(13)
+#define DWC2_GINTSTS_ISOOUTDROP				BIT(14)
+#define DWC2_GINTSTS_EOPFRAME				BIT(15)
+#define DWC2_GINTSTS_INTOKENRX				BIT(16)
+#define DWC2_GINTSTS_EPMISMATCH				BIT(17)
+#define DWC2_GINTSTS_INEPINT				BIT(18)
+#define DWC2_GINTSTS_OUTEPINTR				BIT(19)
+#define DWC2_GINTSTS_INCOMPLISOIN			BIT(20)
+#define DWC2_GINTSTS_INCOMPLISOOUT			BIT(21)
+#define DWC2_GINTSTS_PORTINTR				BIT(24)
+#define DWC2_GINTSTS_HCINTR				BIT(25)
+#define DWC2_GINTSTS_PTXFEMPTY				BIT(26)
+#define DWC2_GINTSTS_LPMTRANRCVD			BIT(27)
+#define DWC2_GINTSTS_CONIDSTSCHNG			BIT(28)
+#define DWC2_GINTSTS_DISCONNECT				BIT(29)
+#define DWC2_GINTSTS_SESSREQINTR			BIT(30)
+#define DWC2_GINTSTS_WKUPINTR				BIT(31)
+#define DWC2_GRXSTS_EPNUM_MASK				GENMASK(3, 0)
+#define DWC2_GRXSTS_BCNT_MASK				GENMASK(14, 4)
+#define DWC2_GRXSTS_DPID_MASK				GENMASK(16, 15)
+#define DWC2_GRXSTS_PKTSTS_MASK				GENMASK(20, 17)
+#define DWC2_GRXSTS_FN_MASK				GENMASK(24, 21)
+#define DWC2_FIFOSIZE_STARTADDR_MASK			GENMASK(15, 0)
+#define DWC2_FIFOSIZE_DEPTH_MASK			GENMASK(31, 16)
+#define DWC2_GNPTXSTS_NPTXFSPCAVAIL_MASK		GENMASK(15, 0)
+#define DWC2_GNPTXSTS_NPTXQSPCAVAIL_MASK		GENMASK(23, 16)
+#define DWC2_GNPTXSTS_NPTXQTOP_TERMINATE		BIT(24)
+#define DWC2_GNPTXSTS_NPTXQTOP_TOKEN_MASK		GENMASK(26, 25)
+#define DWC2_GNPTXSTS_NPTXQTOP_CHNEP_MASK		GENMASK(30, 27)
+#define DWC2_DTXFSTS_TXFSPCAVAIL_MASK			GENMASK(15, 0)
+#define DWC2_GI2CCTL_RWDATA_MASK			GENMASK(7, 0)
+#define DWC2_GI2CCTL_REGADDR_MASK			GENMASK(15, 8)
+#define DWC2_GI2CCTL_ADDR_MASK				GENMASK(22, 16)
+#define DWC2_GI2CCTL_I2CEN				BIT(23)
+#define DWC2_GI2CCTL_ACK				BIT(24)
+#define DWC2_GI2CCTL_I2CSUSPCTL				BIT(25)
+#define DWC2_GI2CCTL_I2CDEVADDR_MASK			GENMASK(27, 26)
+#define DWC2_GI2CCTL_RW					BIT(30)
+#define DWC2_GI2CCTL_BSYDNE				BIT(31)
+#define DWC2_HWCFG1_EP_DIR0_MASK			GENMASK(1, 0)
+#define DWC2_HWCFG1_EP_DIR1_MASK			GENMASK(3, 2)
+#define DWC2_HWCFG1_EP_DIR2_MASK			GENMASK(5, 4)
+#define DWC2_HWCFG1_EP_DIR3_MASK			GENMASK(7, 6)
+#define DWC2_HWCFG1_EP_DIR4_MASK			GENMASK(9, 8)
+#define DWC2_HWCFG1_EP_DIR5_MASK			GENMASK(11, 10)
+#define DWC2_HWCFG1_EP_DIR6_MASK			GENMASK(13, 12)
+#define DWC2_HWCFG1_EP_DIR7_MASK			GENMASK(15, 14)
+#define DWC2_HWCFG1_EP_DIR8_MASK			GENMASK(17, 16)
+#define DWC2_HWCFG1_EP_DIR9_MASK			GENMASK(19, 18)
+#define DWC2_HWCFG1_EP_DIR10_MASK			GENMASK(21, 20)
+#define DWC2_HWCFG1_EP_DIR11_MASK			GENMASK(23, 22)
+#define DWC2_HWCFG1_EP_DIR12_MASK			GENMASK(25, 24)
+#define DWC2_HWCFG1_EP_DIR13_MASK			GENMASK(27, 26)
+#define DWC2_HWCFG1_EP_DIR14_MASK			GENMASK(29, 28)
+#define DWC2_HWCFG1_EP_DIR15_MASK			GENMASK(31, 30)
+#define DWC2_HWCFG2_OP_MODE_MASK			GENMASK(2, 0)
 #define DWC2_HWCFG2_ARCHITECTURE_SLAVE_ONLY		(0x0 << 3)
 #define DWC2_HWCFG2_ARCHITECTURE_EXT_DMA		(0x1 << 3)
 #define DWC2_HWCFG2_ARCHITECTURE_INT_DMA		(0x2 << 3)
-#define DWC2_HWCFG2_ARCHITECTURE_MASK			(0x3 << 3)
-#define DWC2_HWCFG2_ARCHITECTURE_OFFSET			3
-#define DWC2_HWCFG2_POINT2POINT				(1 << 5)
-#define DWC2_HWCFG2_POINT2POINT_OFFSET			5
-#define DWC2_HWCFG2_HS_PHY_TYPE_MASK			(0x3 << 6)
-#define DWC2_HWCFG2_HS_PHY_TYPE_OFFSET			6
-#define DWC2_HWCFG2_FS_PHY_TYPE_MASK			(0x3 << 8)
-#define DWC2_HWCFG2_FS_PHY_TYPE_OFFSET			8
-#define DWC2_HWCFG2_NUM_DEV_EP_MASK			(0xF << 10)
-#define DWC2_HWCFG2_NUM_DEV_EP_OFFSET			10
-#define DWC2_HWCFG2_NUM_HOST_CHAN_MASK			(0xF << 14)
-#define DWC2_HWCFG2_NUM_HOST_CHAN_OFFSET		14
-#define DWC2_HWCFG2_PERIO_EP_SUPPORTED			(1 << 18)
-#define DWC2_HWCFG2_PERIO_EP_SUPPORTED_OFFSET		18
-#define DWC2_HWCFG2_DYNAMIC_FIFO			(1 << 19)
-#define DWC2_HWCFG2_DYNAMIC_FIFO_OFFSET			19
-#define DWC2_HWCFG2_MULTI_PROC_INT			(1 << 20)
-#define DWC2_HWCFG2_MULTI_PROC_INT_OFFSET		20
-#define DWC2_HWCFG2_NONPERIO_TX_Q_DEPTH_MASK		(0x3 << 22)
-#define DWC2_HWCFG2_NONPERIO_TX_Q_DEPTH_OFFSET		22
-#define DWC2_HWCFG2_HOST_PERIO_TX_Q_DEPTH_MASK		(0x3 << 24)
-#define DWC2_HWCFG2_HOST_PERIO_TX_Q_DEPTH_OFFSET	24
-#define DWC2_HWCFG2_DEV_TOKEN_Q_DEPTH_MASK		(0x1F << 26)
-#define DWC2_HWCFG2_DEV_TOKEN_Q_DEPTH_OFFSET		26
-#define DWC2_HWCFG3_XFER_SIZE_CNTR_WIDTH_MASK		(0xF << 0)
-#define DWC2_HWCFG3_XFER_SIZE_CNTR_WIDTH_OFFSET		0
-#define DWC2_HWCFG3_PACKET_SIZE_CNTR_WIDTH_MASK		(0x7 << 4)
-#define DWC2_HWCFG3_PACKET_SIZE_CNTR_WIDTH_OFFSET	4
-#define DWC2_HWCFG3_OTG_FUNC				(1 << 7)
-#define DWC2_HWCFG3_OTG_FUNC_OFFSET			7
-#define DWC2_HWCFG3_I2C					(1 << 8)
-#define DWC2_HWCFG3_I2C_OFFSET				8
-#define DWC2_HWCFG3_VENDOR_CTRL_IF			(1 << 9)
-#define DWC2_HWCFG3_VENDOR_CTRL_IF_OFFSET		9
-#define DWC2_HWCFG3_OPTIONAL_FEATURES			(1 << 10)
-#define DWC2_HWCFG3_OPTIONAL_FEATURES_OFFSET		10
-#define DWC2_HWCFG3_SYNCH_RESET_TYPE			(1 << 11)
-#define DWC2_HWCFG3_SYNCH_RESET_TYPE_OFFSET		11
-#define DWC2_HWCFG3_OTG_ENABLE_IC_USB			(1 << 12)
-#define DWC2_HWCFG3_OTG_ENABLE_IC_USB_OFFSET		12
-#define DWC2_HWCFG3_OTG_ENABLE_HSIC			(1 << 13)
-#define DWC2_HWCFG3_OTG_ENABLE_HSIC_OFFSET		13
-#define DWC2_HWCFG3_OTG_LPM_EN				(1 << 15)
-#define DWC2_HWCFG3_OTG_LPM_EN_OFFSET			15
-#define DWC2_HWCFG3_DFIFO_DEPTH_MASK			(0xFFFF << 16)
-#define DWC2_HWCFG3_DFIFO_DEPTH_OFFSET			16
-#define DWC2_HWCFG4_NUM_DEV_PERIO_IN_EP_MASK		(0xF << 0)
-#define DWC2_HWCFG4_NUM_DEV_PERIO_IN_EP_OFFSET		0
-#define DWC2_HWCFG4_POWER_OPTIMIZ			(1 << 4)
-#define DWC2_HWCFG4_POWER_OPTIMIZ_OFFSET		4
-#define DWC2_HWCFG4_MIN_AHB_FREQ_MASK			(0x1FF << 5)
-#define DWC2_HWCFG4_MIN_AHB_FREQ_OFFSET			5
-#define DWC2_HWCFG4_UTMI_PHY_DATA_WIDTH_MASK		(0x3 << 14)
-#define DWC2_HWCFG4_UTMI_PHY_DATA_WIDTH_OFFSET		14
-#define DWC2_HWCFG4_NUM_DEV_MODE_CTRL_EP_MASK		(0xF << 16)
-#define DWC2_HWCFG4_NUM_DEV_MODE_CTRL_EP_OFFSET		16
-#define DWC2_HWCFG4_IDDIG_FILT_EN			(1 << 20)
-#define DWC2_HWCFG4_IDDIG_FILT_EN_OFFSET		20
-#define DWC2_HWCFG4_VBUS_VALID_FILT_EN			(1 << 21)
-#define DWC2_HWCFG4_VBUS_VALID_FILT_EN_OFFSET		21
-#define DWC2_HWCFG4_A_VALID_FILT_EN			(1 << 22)
-#define DWC2_HWCFG4_A_VALID_FILT_EN_OFFSET		22
-#define DWC2_HWCFG4_B_VALID_FILT_EN			(1 << 23)
-#define DWC2_HWCFG4_B_VALID_FILT_EN_OFFSET		23
-#define DWC2_HWCFG4_SESSION_END_FILT_EN			(1 << 24)
-#define DWC2_HWCFG4_SESSION_END_FILT_EN_OFFSET		24
-#define DWC2_HWCFG4_DED_FIFO_EN				(1 << 25)
-#define DWC2_HWCFG4_DED_FIFO_EN_OFFSET			25
-#define DWC2_HWCFG4_NUM_IN_EPS_MASK			(0xF << 26)
-#define DWC2_HWCFG4_NUM_IN_EPS_OFFSET			26
-#define DWC2_HWCFG4_DESC_DMA				(1 << 30)
-#define DWC2_HWCFG4_DESC_DMA_OFFSET			30
-#define DWC2_HWCFG4_DESC_DMA_DYN			(1 << 31)
-#define DWC2_HWCFG4_DESC_DMA_DYN_OFFSET			31
+#define DWC2_HWCFG2_ARCHITECTURE_MASK			GENMASK(4, 3)
+#define DWC2_HWCFG2_POINT2POINT				BIT(5)
+#define DWC2_HWCFG2_HS_PHY_TYPE_MASK			GENMASK(7, 6)
+#define DWC2_HWCFG2_FS_PHY_TYPE_MASK			GENMASK(9, 8)
+#define DWC2_HWCFG2_NUM_DEV_EP_MASK			GENMASK(13, 10)
+#define DWC2_HWCFG2_NUM_HOST_CHAN_MASK			GENMASK(17, 14)
+#define DWC2_HWCFG2_PERIO_EP_SUPPORTED			BIT(18)
+#define DWC2_HWCFG2_DYNAMIC_FIFO			BIT(19)
+#define DWC2_HWCFG2_MULTI_PROC_INT			BIT(20)
+#define DWC2_HWCFG2_NONPERIO_TX_Q_DEPTH_MASK		GENMASK(23, 22)
+#define DWC2_HWCFG2_HOST_PERIO_TX_Q_DEPTH_MASK		GENMASK(25, 24)
+#define DWC2_HWCFG2_DEV_TOKEN_Q_DEPTH_MASK		GENMASK(30, 26)
+#define DWC2_HWCFG3_XFER_SIZE_CNTR_WIDTH_MASK		GENMASK(3, 0)
+#define DWC2_HWCFG3_PACKET_SIZE_CNTR_WIDTH_MASK		GENMASK(6, 4)
+#define DWC2_HWCFG3_OTG_FUNC				BIT(7)
+#define DWC2_HWCFG3_I2C					BIT(8)
+#define DWC2_HWCFG3_VENDOR_CTRL_IF			BIT(9)
+#define DWC2_HWCFG3_OPTIONAL_FEATURES			BIT(10)
+#define DWC2_HWCFG3_SYNCH_RESET_TYPE			BIT(11)
+#define DWC2_HWCFG3_OTG_ENABLE_IC_USB			BIT(12)
+#define DWC2_HWCFG3_OTG_ENABLE_HSIC			BIT(13)
+#define DWC2_HWCFG3_OTG_LPM_EN				BIT(15)
+#define DWC2_HWCFG3_DFIFO_DEPTH_MASK			GENMASK(31, 16)
+#define DWC2_HWCFG4_NUM_DEV_PERIO_IN_EP_MASK		GENMASK(3, 0)
+#define DWC2_HWCFG4_POWER_OPTIMIZ			BIT(4)
+#define DWC2_HWCFG4_MIN_AHB_FREQ_MASK			GENMASK(13, 5)
+#define DWC2_HWCFG4_UTMI_PHY_DATA_WIDTH_MASK		GENMASK(15, 14)
+#define DWC2_HWCFG4_NUM_DEV_MODE_CTRL_EP_MASK		GENMASK(19, 16)
+#define DWC2_HWCFG4_IDDIG_FILT_EN			BIT(20)
+#define DWC2_HWCFG4_VBUS_VALID_FILT_EN			BIT(21)
+#define DWC2_HWCFG4_A_VALID_FILT_EN			BIT(22)
+#define DWC2_HWCFG4_B_VALID_FILT_EN			BIT(23)
+#define DWC2_HWCFG4_SESSION_END_FILT_EN			BIT(24)
+#define DWC2_HWCFG4_DED_FIFO_EN				BIT(25)
+#define DWC2_HWCFG4_NUM_IN_EPS_MASK			GENMASK(29, 26)
+#define DWC2_HWCFG4_DESC_DMA				BIT(30)
+#define DWC2_HWCFG4_DESC_DMA_DYN			BIT(31)
 #define DWC2_HCFG_FSLSPCLKSEL_30_60_MHZ			0
 #define DWC2_HCFG_FSLSPCLKSEL_48_MHZ			1
 #define DWC2_HCFG_FSLSPCLKSEL_6_MHZ			2
-#define DWC2_HCFG_FSLSPCLKSEL_MASK			(0x3 << 0)
-#define DWC2_HCFG_FSLSPCLKSEL_OFFSET			0
-#define DWC2_HCFG_FSLSSUPP				(1 << 2)
-#define DWC2_HCFG_FSLSSUPP_OFFSET			2
-#define DWC2_HCFG_DESCDMA				(1 << 23)
-#define DWC2_HCFG_DESCDMA_OFFSET			23
-#define DWC2_HCFG_FRLISTEN_MASK				(0x3 << 24)
-#define DWC2_HCFG_FRLISTEN_OFFSET			24
-#define DWC2_HCFG_PERSCHEDENA				(1 << 26)
-#define DWC2_HCFG_PERSCHEDENA_OFFSET			26
-#define DWC2_HCFG_PERSCHEDSTAT				(1 << 27)
-#define DWC2_HCFG_PERSCHEDSTAT_OFFSET			27
-#define DWC2_HFIR_FRINT_MASK				(0xFFFF << 0)
-#define DWC2_HFIR_FRINT_OFFSET				0
-#define DWC2_HFNUM_FRNUM_MASK				(0xFFFF << 0)
-#define DWC2_HFNUM_FRNUM_OFFSET				0
-#define DWC2_HFNUM_FRREM_MASK				(0xFFFF << 16)
-#define DWC2_HFNUM_FRREM_OFFSET				16
+#define DWC2_HCFG_FSLSPCLKSEL_MASK			GENMASK(1, 0)
+#define DWC2_HCFG_FSLSSUPP				BIT(2)
+#define DWC2_HCFG_DESCDMA				BIT(23)
+#define DWC2_HCFG_FRLISTEN_MASK				GENMASK(25, 24)
+#define DWC2_HCFG_PERSCHEDENA				BIT(26)
+#define DWC2_HCFG_PERSCHEDSTAT				BIT(27)
+#define DWC2_HFIR_FRINT_MASK				GENMASK(15, 0)
+#define DWC2_HFNUM_FRNUM_MASK				GENMASK(15, 0)
+#define DWC2_HFNUM_FRREM_MASK				GENMASK(31, 16)
 #define DWC2_HFNUM_MAX_FRNUM				0x3FFF
-#define DWC2_HPTXSTS_PTXFSPCAVAIL_MASK			(0xFFFF << 0)
-#define DWC2_HPTXSTS_PTXFSPCAVAIL_OFFSET		0
-#define DWC2_HPTXSTS_PTXQSPCAVAIL_MASK			(0xFF << 16)
-#define DWC2_HPTXSTS_PTXQSPCAVAIL_OFFSET		16
-#define DWC2_HPTXSTS_PTXQTOP_TERMINATE			(1 << 24)
-#define DWC2_HPTXSTS_PTXQTOP_TERMINATE_OFFSET		24
-#define DWC2_HPTXSTS_PTXQTOP_TOKEN_MASK			(0x3 << 25)
-#define DWC2_HPTXSTS_PTXQTOP_TOKEN_OFFSET		25
-#define DWC2_HPTXSTS_PTXQTOP_CHNUM_MASK			(0xF << 27)
-#define DWC2_HPTXSTS_PTXQTOP_CHNUM_OFFSET		27
-#define DWC2_HPTXSTS_PTXQTOP_ODD			(1 << 31)
-#define DWC2_HPTXSTS_PTXQTOP_ODD_OFFSET			31
-#define DWC2_HPRT0_PRTCONNSTS				(1 << 0)
-#define DWC2_HPRT0_PRTCONNSTS_OFFSET			0
-#define DWC2_HPRT0_PRTCONNDET				(1 << 1)
-#define DWC2_HPRT0_PRTCONNDET_OFFSET			1
-#define DWC2_HPRT0_PRTENA				(1 << 2)
-#define DWC2_HPRT0_PRTENA_OFFSET			2
-#define DWC2_HPRT0_PRTENCHNG				(1 << 3)
-#define DWC2_HPRT0_PRTENCHNG_OFFSET			3
-#define DWC2_HPRT0_PRTOVRCURRACT			(1 << 4)
-#define DWC2_HPRT0_PRTOVRCURRACT_OFFSET			4
-#define DWC2_HPRT0_PRTOVRCURRCHNG			(1 << 5)
-#define DWC2_HPRT0_PRTOVRCURRCHNG_OFFSET		5
-#define DWC2_HPRT0_PRTRES				(1 << 6)
-#define DWC2_HPRT0_PRTRES_OFFSET			6
-#define DWC2_HPRT0_PRTSUSP				(1 << 7)
-#define DWC2_HPRT0_PRTSUSP_OFFSET			7
-#define DWC2_HPRT0_PRTRST				(1 << 8)
-#define DWC2_HPRT0_PRTRST_OFFSET			8
-#define DWC2_HPRT0_PRTLNSTS_MASK			(0x3 << 10)
-#define DWC2_HPRT0_PRTLNSTS_OFFSET			10
-#define DWC2_HPRT0_PRTPWR				(1 << 12)
-#define DWC2_HPRT0_PRTPWR_OFFSET			12
-#define DWC2_HPRT0_PRTTSTCTL_MASK			(0xF << 13)
-#define DWC2_HPRT0_PRTTSTCTL_OFFSET			13
+#define DWC2_HPTXSTS_PTXFSPCAVAIL_MASK			GENMASK(15, 0)
+#define DWC2_HPTXSTS_PTXQSPCAVAIL_MASK			GENMASK(23, 16)
+#define DWC2_HPTXSTS_PTXQTOP_TERMINATE			BIT(24)
+#define DWC2_HPTXSTS_PTXQTOP_TOKEN_MASK			GENMASK(26, 25)
+#define DWC2_HPTXSTS_PTXQTOP_CHNUM_MASK			GENMASK(30, 27)
+#define DWC2_HPTXSTS_PTXQTOP_ODD			BIT(31)
+#define DWC2_HPRT0_PRTCONNSTS				BIT(0)
+#define DWC2_HPRT0_PRTCONNDET				BIT(1)
+#define DWC2_HPRT0_PRTENA				BIT(2)
+#define DWC2_HPRT0_PRTENCHNG				BIT(3)
+#define DWC2_HPRT0_PRTOVRCURRACT			BIT(4)
+#define DWC2_HPRT0_PRTOVRCURRCHNG			BIT(5)
+#define DWC2_HPRT0_PRTRES				BIT(6)
+#define DWC2_HPRT0_PRTSUSP				BIT(7)
+#define DWC2_HPRT0_PRTRST				BIT(8)
+#define DWC2_HPRT0_PRTLNSTS_MASK			GENMASK(11, 10)
+#define DWC2_HPRT0_PRTPWR				BIT(12)
+#define DWC2_HPRT0_PRTTSTCTL_MASK			GENMASK(16, 13)
 #define DWC2_HPRT0_PRTSPD_HIGH				(0 << 17)
 #define DWC2_HPRT0_PRTSPD_FULL				(1 << 17)
 #define DWC2_HPRT0_PRTSPD_LOW				(2 << 17)
-#define DWC2_HPRT0_PRTSPD_MASK				(0x3 << 17)
-#define DWC2_HPRT0_PRTSPD_OFFSET			17
+#define DWC2_HPRT0_PRTSPD_MASK				GENMASK(18, 17)
 #define DWC2_HPRT0_W1C_MASK				(DWC2_HPRT0_PRTCONNDET | \
 							DWC2_HPRT0_PRTENA | \
 							DWC2_HPRT0_PRTENCHNG | \
 							DWC2_HPRT0_PRTOVRCURRCHNG)
-#define DWC2_HAINT_CH0					(1 << 0)
-#define DWC2_HAINT_CH0_OFFSET				0
-#define DWC2_HAINT_CH1					(1 << 1)
-#define DWC2_HAINT_CH1_OFFSET				1
-#define DWC2_HAINT_CH2					(1 << 2)
-#define DWC2_HAINT_CH2_OFFSET				2
-#define DWC2_HAINT_CH3					(1 << 3)
-#define DWC2_HAINT_CH3_OFFSET				3
-#define DWC2_HAINT_CH4					(1 << 4)
-#define DWC2_HAINT_CH4_OFFSET				4
-#define DWC2_HAINT_CH5					(1 << 5)
-#define DWC2_HAINT_CH5_OFFSET				5
-#define DWC2_HAINT_CH6					(1 << 6)
-#define DWC2_HAINT_CH6_OFFSET				6
-#define DWC2_HAINT_CH7					(1 << 7)
-#define DWC2_HAINT_CH7_OFFSET				7
-#define DWC2_HAINT_CH8					(1 << 8)
-#define DWC2_HAINT_CH8_OFFSET				8
-#define DWC2_HAINT_CH9					(1 << 9)
-#define DWC2_HAINT_CH9_OFFSET				9
-#define DWC2_HAINT_CH10					(1 << 10)
-#define DWC2_HAINT_CH10_OFFSET				10
-#define DWC2_HAINT_CH11					(1 << 11)
-#define DWC2_HAINT_CH11_OFFSET				11
-#define DWC2_HAINT_CH12					(1 << 12)
-#define DWC2_HAINT_CH12_OFFSET				12
-#define DWC2_HAINT_CH13					(1 << 13)
-#define DWC2_HAINT_CH13_OFFSET				13
-#define DWC2_HAINT_CH14					(1 << 14)
-#define DWC2_HAINT_CH14_OFFSET				14
-#define DWC2_HAINT_CH15					(1 << 15)
-#define DWC2_HAINT_CH15_OFFSET				15
-#define DWC2_HAINT_CHINT_MASK				0xffff
-#define DWC2_HAINT_CHINT_OFFSET				0
-#define DWC2_HAINTMSK_CH0				(1 << 0)
-#define DWC2_HAINTMSK_CH0_OFFSET			0
-#define DWC2_HAINTMSK_CH1				(1 << 1)
-#define DWC2_HAINTMSK_CH1_OFFSET			1
-#define DWC2_HAINTMSK_CH2				(1 << 2)
-#define DWC2_HAINTMSK_CH2_OFFSET			2
-#define DWC2_HAINTMSK_CH3				(1 << 3)
-#define DWC2_HAINTMSK_CH3_OFFSET			3
-#define DWC2_HAINTMSK_CH4				(1 << 4)
-#define DWC2_HAINTMSK_CH4_OFFSET			4
-#define DWC2_HAINTMSK_CH5				(1 << 5)
-#define DWC2_HAINTMSK_CH5_OFFSET			5
-#define DWC2_HAINTMSK_CH6				(1 << 6)
-#define DWC2_HAINTMSK_CH6_OFFSET			6
-#define DWC2_HAINTMSK_CH7				(1 << 7)
-#define DWC2_HAINTMSK_CH7_OFFSET			7
-#define DWC2_HAINTMSK_CH8				(1 << 8)
-#define DWC2_HAINTMSK_CH8_OFFSET			8
-#define DWC2_HAINTMSK_CH9				(1 << 9)
-#define DWC2_HAINTMSK_CH9_OFFSET			9
-#define DWC2_HAINTMSK_CH10				(1 << 10)
-#define DWC2_HAINTMSK_CH10_OFFSET			10
-#define DWC2_HAINTMSK_CH11				(1 << 11)
-#define DWC2_HAINTMSK_CH11_OFFSET			11
-#define DWC2_HAINTMSK_CH12				(1 << 12)
-#define DWC2_HAINTMSK_CH12_OFFSET			12
-#define DWC2_HAINTMSK_CH13				(1 << 13)
-#define DWC2_HAINTMSK_CH13_OFFSET			13
-#define DWC2_HAINTMSK_CH14				(1 << 14)
-#define DWC2_HAINTMSK_CH14_OFFSET			14
-#define DWC2_HAINTMSK_CH15				(1 << 15)
-#define DWC2_HAINTMSK_CH15_OFFSET			15
-#define DWC2_HAINTMSK_CHINT_MASK			0xffff
-#define DWC2_HAINTMSK_CHINT_OFFSET			0
-#define DWC2_HCCHAR_MPS_MASK				(0x7FF << 0)
-#define DWC2_HCCHAR_MPS_OFFSET				0
-#define DWC2_HCCHAR_EPNUM_MASK				(0xF << 11)
-#define DWC2_HCCHAR_EPNUM_OFFSET			11
-#define DWC2_HCCHAR_EPDIR				(1 << 15)
-#define DWC2_HCCHAR_EPDIR_OFFSET			15
-#define DWC2_HCCHAR_LSPDDEV				(1 << 17)
-#define DWC2_HCCHAR_LSPDDEV_OFFSET			17
+#define DWC2_HAINT_CH0					BIT(0)
+#define DWC2_HAINT_CH1					BIT(1)
+#define DWC2_HAINT_CH2					BIT(2)
+#define DWC2_HAINT_CH3					BIT(3)
+#define DWC2_HAINT_CH4					BIT(4)
+#define DWC2_HAINT_CH5					BIT(5)
+#define DWC2_HAINT_CH6					BIT(6)
+#define DWC2_HAINT_CH7					BIT(7)
+#define DWC2_HAINT_CH8					BIT(8)
+#define DWC2_HAINT_CH9					BIT(9)
+#define DWC2_HAINT_CH10					BIT(10)
+#define DWC2_HAINT_CH11					BIT(11)
+#define DWC2_HAINT_CH12					BIT(12)
+#define DWC2_HAINT_CH13					BIT(13)
+#define DWC2_HAINT_CH14					BIT(14)
+#define DWC2_HAINT_CH15					BIT(15)
+#define DWC2_HAINT_CHINT_MASK				GENMASK(15, 0)
+#define DWC2_HAINTMSK_CH0				BIT(0)
+#define DWC2_HAINTMSK_CH1				BIT(1)
+#define DWC2_HAINTMSK_CH2				BIT(2)
+#define DWC2_HAINTMSK_CH3				BIT(3)
+#define DWC2_HAINTMSK_CH4				BIT(4)
+#define DWC2_HAINTMSK_CH5				BIT(5)
+#define DWC2_HAINTMSK_CH6				BIT(6)
+#define DWC2_HAINTMSK_CH7				BIT(7)
+#define DWC2_HAINTMSK_CH8				BIT(8)
+#define DWC2_HAINTMSK_CH9				BIT(9)
+#define DWC2_HAINTMSK_CH10				BIT(10)
+#define DWC2_HAINTMSK_CH11				BIT(11)
+#define DWC2_HAINTMSK_CH12				BIT(12)
+#define DWC2_HAINTMSK_CH13				BIT(13)
+#define DWC2_HAINTMSK_CH14				BIT(14)
+#define DWC2_HAINTMSK_CH15				BIT(15)
+#define DWC2_HAINTMSK_CHINT_MASK			GENMASK(15, 0)
+#define DWC2_HCCHAR_MPS_MASK				GENMASK(10, 0)
+#define DWC2_HCCHAR_EPNUM_MASK				GENMASK(14, 11)
+#define DWC2_HCCHAR_EPDIR				BIT(15)
+#define DWC2_HCCHAR_LSPDDEV				BIT(17)
 #define DWC2_HCCHAR_EPTYPE_CONTROL			0
 #define DWC2_HCCHAR_EPTYPE_ISOC				1
 #define DWC2_HCCHAR_EPTYPE_BULK				2
 #define DWC2_HCCHAR_EPTYPE_INTR				3
-#define DWC2_HCCHAR_EPTYPE_MASK				(0x3 << 18)
-#define DWC2_HCCHAR_EPTYPE_OFFSET			18
-#define DWC2_HCCHAR_MULTICNT_MASK			(0x3 << 20)
-#define DWC2_HCCHAR_MULTICNT_OFFSET			20
-#define DWC2_HCCHAR_DEVADDR_MASK			(0x7F << 22)
-#define DWC2_HCCHAR_DEVADDR_OFFSET			22
-#define DWC2_HCCHAR_ODDFRM				(1 << 29)
-#define DWC2_HCCHAR_ODDFRM_OFFSET			29
-#define DWC2_HCCHAR_CHDIS				(1 << 30)
-#define DWC2_HCCHAR_CHDIS_OFFSET			30
-#define DWC2_HCCHAR_CHEN				(1 << 31)
-#define DWC2_HCCHAR_CHEN_OFFSET				31
-#define DWC2_HCSPLT_PRTADDR_MASK			(0x7F << 0)
-#define DWC2_HCSPLT_PRTADDR_OFFSET			0
-#define DWC2_HCSPLT_HUBADDR_MASK			(0x7F << 7)
-#define DWC2_HCSPLT_HUBADDR_OFFSET			7
-#define DWC2_HCSPLT_XACTPOS_MASK			(0x3 << 14)
-#define DWC2_HCSPLT_XACTPOS_OFFSET			14
-#define DWC2_HCSPLT_COMPSPLT				(1 << 16)
-#define DWC2_HCSPLT_COMPSPLT_OFFSET			16
-#define DWC2_HCSPLT_SPLTENA				(1 << 31)
-#define DWC2_HCSPLT_SPLTENA_OFFSET			31
-#define DWC2_HCINT_XFERCOMP				(1 << 0)
-#define DWC2_HCINT_XFERCOMP_OFFSET			0
-#define DWC2_HCINT_CHHLTD				(1 << 1)
-#define DWC2_HCINT_CHHLTD_OFFSET			1
-#define DWC2_HCINT_AHBERR				(1 << 2)
-#define DWC2_HCINT_AHBERR_OFFSET			2
-#define DWC2_HCINT_STALL				(1 << 3)
-#define DWC2_HCINT_STALL_OFFSET				3
-#define DWC2_HCINT_NAK					(1 << 4)
-#define DWC2_HCINT_NAK_OFFSET				4
-#define DWC2_HCINT_ACK					(1 << 5)
-#define DWC2_HCINT_ACK_OFFSET				5
-#define DWC2_HCINT_NYET					(1 << 6)
-#define DWC2_HCINT_NYET_OFFSET				6
-#define DWC2_HCINT_XACTERR				(1 << 7)
-#define DWC2_HCINT_XACTERR_OFFSET			7
-#define DWC2_HCINT_BBLERR				(1 << 8)
-#define DWC2_HCINT_BBLERR_OFFSET			8
-#define DWC2_HCINT_FRMOVRUN				(1 << 9)
-#define DWC2_HCINT_FRMOVRUN_OFFSET			9
-#define DWC2_HCINT_DATATGLERR				(1 << 10)
-#define DWC2_HCINT_DATATGLERR_OFFSET			10
-#define DWC2_HCINT_BNA					(1 << 11)
-#define DWC2_HCINT_BNA_OFFSET				11
-#define DWC2_HCINT_XCS_XACT				(1 << 12)
-#define DWC2_HCINT_XCS_XACT_OFFSET			12
-#define DWC2_HCINT_FRM_LIST_ROLL			(1 << 13)
-#define DWC2_HCINT_FRM_LIST_ROLL_OFFSET			13
-#define DWC2_HCINTMSK_XFERCOMPL				(1 << 0)
-#define DWC2_HCINTMSK_XFERCOMPL_OFFSET			0
-#define DWC2_HCINTMSK_CHHLTD				(1 << 1)
-#define DWC2_HCINTMSK_CHHLTD_OFFSET			1
-#define DWC2_HCINTMSK_AHBERR				(1 << 2)
-#define DWC2_HCINTMSK_AHBERR_OFFSET			2
-#define DWC2_HCINTMSK_STALL				(1 << 3)
-#define DWC2_HCINTMSK_STALL_OFFSET			3
-#define DWC2_HCINTMSK_NAK				(1 << 4)
-#define DWC2_HCINTMSK_NAK_OFFSET			4
-#define DWC2_HCINTMSK_ACK				(1 << 5)
-#define DWC2_HCINTMSK_ACK_OFFSET			5
-#define DWC2_HCINTMSK_NYET				(1 << 6)
-#define DWC2_HCINTMSK_NYET_OFFSET			6
-#define DWC2_HCINTMSK_XACTERR				(1 << 7)
-#define DWC2_HCINTMSK_XACTERR_OFFSET			7
-#define DWC2_HCINTMSK_BBLERR				(1 << 8)
-#define DWC2_HCINTMSK_BBLERR_OFFSET			8
-#define DWC2_HCINTMSK_FRMOVRUN				(1 << 9)
-#define DWC2_HCINTMSK_FRMOVRUN_OFFSET			9
-#define DWC2_HCINTMSK_DATATGLERR			(1 << 10)
-#define DWC2_HCINTMSK_DATATGLERR_OFFSET			10
-#define DWC2_HCINTMSK_BNA				(1 << 11)
-#define DWC2_HCINTMSK_BNA_OFFSET			11
-#define DWC2_HCINTMSK_XCS_XACT				(1 << 12)
-#define DWC2_HCINTMSK_XCS_XACT_OFFSET			12
-#define DWC2_HCINTMSK_FRM_LIST_ROLL			(1 << 13)
-#define DWC2_HCINTMSK_FRM_LIST_ROLL_OFFSET		13
-#define DWC2_HCTSIZ_XFERSIZE_MASK			0x7ffff
-#define DWC2_HCTSIZ_XFERSIZE_OFFSET			0
-#define DWC2_HCTSIZ_SCHINFO_MASK			0xff
-#define DWC2_HCTSIZ_SCHINFO_OFFSET			0
-#define DWC2_HCTSIZ_NTD_MASK				(0xff << 8)
-#define DWC2_HCTSIZ_NTD_OFFSET				8
-#define DWC2_HCTSIZ_PKTCNT_MASK				(0x3ff << 19)
-#define DWC2_HCTSIZ_PKTCNT_OFFSET			19
-#define DWC2_HCTSIZ_PID_MASK				(0x3 << 29)
-#define DWC2_HCTSIZ_PID_OFFSET				29
-#define DWC2_HCTSIZ_DOPNG				(1 << 31)
-#define DWC2_HCTSIZ_DOPNG_OFFSET			31
-#define DWC2_HCDMA_CTD_MASK				(0xFF << 3)
-#define DWC2_HCDMA_CTD_OFFSET				3
-#define DWC2_HCDMA_DMA_ADDR_MASK			(0x1FFFFF << 11)
-#define DWC2_HCDMA_DMA_ADDR_OFFSET			11
-#define DWC2_PCGCCTL_STOPPCLK				(1 << 0)
-#define DWC2_PCGCCTL_STOPPCLK_OFFSET			0
-#define DWC2_PCGCCTL_GATEHCLK				(1 << 1)
-#define DWC2_PCGCCTL_GATEHCLK_OFFSET			1
-#define DWC2_PCGCCTL_PWRCLMP				(1 << 2)
-#define DWC2_PCGCCTL_PWRCLMP_OFFSET			2
-#define DWC2_PCGCCTL_RSTPDWNMODULE			(1 << 3)
-#define DWC2_PCGCCTL_RSTPDWNMODULE_OFFSET		3
-#define DWC2_PCGCCTL_PHYSUSPENDED			(1 << 4)
-#define DWC2_PCGCCTL_PHYSUSPENDED_OFFSET		4
-#define DWC2_PCGCCTL_ENBL_SLEEP_GATING			(1 << 5)
-#define DWC2_PCGCCTL_ENBL_SLEEP_GATING_OFFSET		5
-#define DWC2_PCGCCTL_PHY_IN_SLEEP			(1 << 6)
-#define DWC2_PCGCCTL_PHY_IN_SLEEP_OFFSET		6
-#define DWC2_PCGCCTL_DEEP_SLEEP				(1 << 7)
-#define DWC2_PCGCCTL_DEEP_SLEEP_OFFSET			7
+#define DWC2_HCCHAR_EPTYPE_MASK				GENMASK(19, 18)
+#define DWC2_HCCHAR_MULTICNT_MASK			GENMASK(21, 20)
+#define DWC2_HCCHAR_DEVADDR_MASK			GENMASK(28, 22)
+#define DWC2_HCCHAR_ODDFRM				BIT(29)
+#define DWC2_HCCHAR_CHDIS				BIT(30)
+#define DWC2_HCCHAR_CHEN				BIT(31)
+#define DWC2_HCSPLT_PRTADDR_MASK			GENMASK(6, 0)
+#define DWC2_HCSPLT_HUBADDR_MASK			GENMASK(13, 7)
+#define DWC2_HCSPLT_XACTPOS_MASK			GENMASK(15, 14)
+#define DWC2_HCSPLT_COMPSPLT				BIT(16)
+#define DWC2_HCSPLT_SPLTENA				BIT(31)
+#define DWC2_HCINT_XFERCOMP				BIT(0)
+#define DWC2_HCINT_CHHLTD				BIT(1)
+#define DWC2_HCINT_AHBERR				BIT(2)
+#define DWC2_HCINT_STALL				BIT(3)
+#define DWC2_HCINT_NAK					BIT(4)
+#define DWC2_HCINT_ACK					BIT(5)
+#define DWC2_HCINT_NYET					BIT(6)
+#define DWC2_HCINT_XACTERR				BIT(7)
+#define DWC2_HCINT_BBLERR				BIT(8)
+#define DWC2_HCINT_FRMOVRUN				BIT(9)
+#define DWC2_HCINT_DATATGLERR				BIT(10)
+#define DWC2_HCINT_BNA					BIT(11)
+#define DWC2_HCINT_XCS_XACT				BIT(12)
+#define DWC2_HCINT_FRM_LIST_ROLL			BIT(13)
+#define DWC2_HCINTMSK_XFERCOMPL				BIT(0)
+#define DWC2_HCINTMSK_CHHLTD				BIT(1)
+#define DWC2_HCINTMSK_AHBERR				BIT(2)
+#define DWC2_HCINTMSK_STALL				BIT(3)
+#define DWC2_HCINTMSK_NAK				BIT(4)
+#define DWC2_HCINTMSK_ACK				BIT(5)
+#define DWC2_HCINTMSK_NYET				BIT(6)
+#define DWC2_HCINTMSK_XACTERR				BIT(7)
+#define DWC2_HCINTMSK_BBLERR				BIT(8)
+#define DWC2_HCINTMSK_FRMOVRUN				BIT(9)
+#define DWC2_HCINTMSK_DATATGLERR			BIT(10)
+#define DWC2_HCINTMSK_BNA				BIT(11)
+#define DWC2_HCINTMSK_XCS_XACT				BIT(12)
+#define DWC2_HCINTMSK_FRM_LIST_ROLL			BIT(13)
+#define DWC2_HCTSIZ_XFERSIZE_MASK			GENMASK(18, 0)
+#define DWC2_HCTSIZ_SCHINFO_MASK			GENMASK(7, 0)
+#define DWC2_HCTSIZ_NTD_MASK				GENMASK(15, 8)
+#define DWC2_HCTSIZ_PKTCNT_MASK				GENMASK(28, 19)
+#define DWC2_HCTSIZ_PID_MASK				GENMASK(30, 29)
+#define DWC2_HCTSIZ_DOPNG				BIT(31)
+#define DWC2_HCDMA_CTD_MASK				GENMASK(10, 3)
+#define DWC2_HCDMA_DMA_ADDR_MASK			GENMASK(31, 11)
+#define DWC2_PCGCCTL_STOPPCLK				BIT(0)
+#define DWC2_PCGCCTL_GATEHCLK				BIT(1)
+#define DWC2_PCGCCTL_PWRCLMP				BIT(2)
+#define DWC2_PCGCCTL_RSTPDWNMODULE			BIT(3)
+#define DWC2_PCGCCTL_PHYSUSPENDED			BIT(4)
+#define DWC2_PCGCCTL_ENBL_SLEEP_GATING			BIT(5)
+#define DWC2_PCGCCTL_PHY_IN_SLEEP			BIT(6)
+#define DWC2_PCGCCTL_DEEP_SLEEP				BIT(7)
 #define DWC2_SNPSID_DEVID_VER_2xx			(0x4f542 << 12)
 #define DWC2_SNPSID_DEVID_VER_3xx			(0x4f543 << 12)
-#define DWC2_SNPSID_DEVID_MASK				(0xfffff << 12)
-#define DWC2_SNPSID_DEVID_OFFSET			12
+#define DWC2_SNPSID_DEVID_MASK				GENMASK(31, 12)
 
 /* Host controller specific */
 #define DWC2_HC_PID_DATA0		0
@@ -692,13 +367,13 @@
 #define DWC2_HC_PID_SETUP		3
 
 /* roothub.a masks */
-#define RH_A_NDP	(0xff << 0)	/* number of downstream ports */
-#define RH_A_PSM	(1 << 8)	/* power switching mode */
-#define RH_A_NPS	(1 << 9)	/* no power switching */
-#define RH_A_DT		(1 << 10)	/* device type (mbz) */
-#define RH_A_OCPM	(1 << 11)	/* over current protection mode */
-#define RH_A_NOCP	(1 << 12)	/* no over current protection */
-#define RH_A_POTPGT	(0xff << 24)	/* power on to power good time */
+#define RH_A_NDP	GENMASK(7, 0)	/* number of downstream ports */
+#define RH_A_PSM	BIT(8)		/* power switching mode */
+#define RH_A_NPS	BIT(9)		/* no power switching */
+#define RH_A_DT		BIT(10)		/* device type (mbz) */
+#define RH_A_OCPM	BIT(11)		/* over current protection mode */
+#define RH_A_NOCP	BIT(12)		/* no over current protection */
+#define RH_A_POTPGT	GENMASK(31, 24)	/* power on to power good time */
 
 /* roothub.b masks */
 #define RH_B_DR		0x0000ffff	/* device removable flags */

-- 
2.39.2

