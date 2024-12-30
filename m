From: Junhui Liu <liujh2818@outlook.com>
Date: Mon, 30 Dec 2024 11:30:22 +0800
Subject: [PATCH v2 7/8] usb: dwc2: Unify flush and reset logic with v4.20a
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241230-dwc2-dev-v2-7-12cd9b8a2358@outlook.com>
References: <20241230-dwc2-dev-v2-0-12cd9b8a2358@outlook.com>
In-Reply-To: <20241230-dwc2-dev-v2-0-12cd9b8a2358@outlook.com>
To: Tom Rini <trini@konsulko.com>, Marek Vasut <marex@denx.de>, 
 Lukasz Majewski <lukma@denx.de>, 
 Mattijs Korpershoek <mkorpershoek@baylibre.com>
Cc: u-boot@lists.denx.de, Kongyang Liu <seashell11234455@gmail.com>, 
 Junhui Liu <liujh2818@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735529447; l=11327;
 i=liujh2818@outlook.com; s=20241030; h=from:subject:message-id;
 bh=Y9b9Q7CExfA/Qu9buVu1pwfMx7ZExfHA/FX1MhGfKIE=;
 b=PKBFxwihQ0SR0nxJ9gsw4YitCHEyL7uBO/etkn0lsQP+StrmbdxnYVSxi3p3TdyNz1wo+rBX3
 SnSAYxbBd8kA8QgHOCUo9SMpo2Y4YSS++hBLgfqGSgsP6ATSoLNoiTQ
X-Developer-Key: i=liujh2818@outlook.com; a=ed25519;
 pk=ApYwI6KD3EjynMw61RqGa6c5BGbStQnKSrbNN+aQqT4=
X-Endpoint-Received: by B4 Relay for liujh2818@outlook.com/20241030 with auth_id=259
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Kongyang Liu <seashell11234455@gmail.com>

This patch merges flush and reset logic for both host and gadget code
into a common set of functions, reducing duplication. It also adds support
for the updated reset logic to compatible with core version since v4.20a.

This patch mainly refers to the patch in the kernel.
link: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=65dc2e725286106f99c6f6b78e3d9c52c15f3a9c

Signed-off-by: Kongyang Liu <seashell11234455@gmail.com>
Signed-off-by: Junhui Liu <liujh2818@outlook.com>
---
 drivers/usb/common/Makefile                |   2 +
 drivers/usb/common/dwc2_core.c             | 103 +++++++++++++++++++++++++++++
 drivers/usb/common/dwc2_core.h             |   4 ++
 drivers/usb/gadget/dwc2_udc_otg.c          |  12 +---
 drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c |   6 +-
 drivers/usb/host/dwc2.c                    |  80 ++--------------------
 6 files changed, 117 insertions(+), 90 deletions(-)

diff --git a/drivers/usb/common/Makefile b/drivers/usb/common/Makefile
index 11cc4657a0f403b84b1b8336781e1893d9c7a8f1..73e5bc6d7fdca692276e119911b47db4bf03586a 100644
--- a/drivers/usb/common/Makefile
+++ b/drivers/usb/common/Makefile
@@ -4,6 +4,8 @@
 #
 
 obj-$(CONFIG_$(XPL_)DM_USB) += common.o
+obj-$(CONFIG_USB_DWC2) += dwc2_core.o
+obj-$(CONFIG_USB_GADGET_DWC2_OTG) += dwc2_core.o
 obj-$(CONFIG_USB_ISP1760) += usb_urb.o
 obj-$(CONFIG_USB_MUSB_HOST) += usb_urb.o
 obj-$(CONFIG_USB_MUSB_GADGET) += usb_urb.o
diff --git a/drivers/usb/common/dwc2_core.c b/drivers/usb/common/dwc2_core.c
new file mode 100644
index 0000000000000000000000000000000000000000..323326e05d7b0318d883d4a3b8186b812c42f9ca
--- /dev/null
+++ b/drivers/usb/common/dwc2_core.c
@@ -0,0 +1,103 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (c) 2024, Kongyang Liu <seashell11234455@gmail.com>
+ */
+
+#include <linux/bitfield.h>
+#include <linux/errno.h>
+#include <linux/io.h>
+#include <wait_bit.h>
+
+#include "dwc2_core.h"
+
+int dwc2_core_reset(struct dwc2_core_regs *regs)
+{
+	u32 snpsid;
+	int ret;
+	bool host_mode = false;
+
+	if (!(readl(&regs->global_regs.gotgctl) & GOTGCTL_CONID_B) ||
+	    (readl(&regs->global_regs.gusbcfg) & GUSBCFG_FORCEDEVMODE))
+		host_mode = true;
+
+	/* Core Soft Reset */
+	snpsid = readl(&regs->global_regs.gsnpsid);
+	writel(GRSTCTL_CSFTRST, &regs->global_regs.grstctl);
+	if (FIELD_GET(GSNPSID_VER_MASK, snpsid) < 0x420a) {
+		ret = wait_for_bit_le32(&regs->global_regs.grstctl, GRSTCTL_CSFTRST,
+					false, 1000, false);
+		if (ret) {
+			log_warning("%s: Waiting for GRSTCTL_CSFTRST timeout\n", __func__);
+			return -EBUSY;
+		}
+	} else {
+		ret = wait_for_bit_le32(&regs->global_regs.grstctl, GRSTCTL_CSFTRST_DONE,
+					true, 1000, false);
+		if (ret) {
+			log_warning("%s: Waiting for GRSTCTL_CSFTRST_DONE timeout\n", __func__);
+			return -EBUSY;
+		}
+		clrsetbits_le32(&regs->global_regs.grstctl, GRSTCTL_CSFTRST, GRSTCTL_CSFTRST_DONE);
+	}
+
+	/* Wait for AHB master IDLE state. */
+	ret = wait_for_bit_le32(&regs->global_regs.grstctl, GRSTCTL_AHBIDLE,
+				true, 1000, false);
+	if (ret) {
+		log_warning("%s: Waiting for GRSTCTL_AHBIDLE timeout\n", __func__);
+		return -EBUSY;
+	}
+
+	if (host_mode) {
+		ret = wait_for_bit_le32(&regs->global_regs.gintsts, GINTSTS_CURMODE_HOST,
+					host_mode, 1000, false);
+		if (ret) {
+			log_warning("%s: Waiting for GINTSTS_CURMODE_HOST timeout\n", __func__);
+			return -EBUSY;
+		}
+	}
+
+	return 0;
+}
+
+void dwc2_flush_tx_fifo(struct dwc2_core_regs *regs, const int num)
+{
+	int ret;
+
+	log_debug("Flush Tx FIFO %d\n", num);
+
+	/* Wait for AHB master IDLE state */
+	ret = wait_for_bit_le32(&regs->global_regs.grstctl, GRSTCTL_AHBIDLE, true, 1000, false);
+	if (ret)
+		log_warning("%s: Waiting for GRSTCTL_AHBIDLE timeout\n", __func__);
+
+	writel(GRSTCTL_TXFFLSH | FIELD_PREP(GRSTCTL_TXFNUM_MASK, num), &regs->global_regs.grstctl);
+
+	ret = wait_for_bit_le32(&regs->global_regs.grstctl, GRSTCTL_TXFFLSH, false, 1000, false);
+	if (ret)
+		log_warning("%s: Waiting for GRSTCTL_TXFFLSH timeout\n", __func__);
+
+	/* Wait for 3 PHY Clocks */
+	udelay(1);
+}
+
+void dwc2_flush_rx_fifo(struct dwc2_core_regs *regs)
+{
+	int ret;
+
+	log_debug("Flush Rx FIFO\n");
+
+	/* Wait for AHB master IDLE state */
+	ret = wait_for_bit_le32(&regs->global_regs.grstctl, GRSTCTL_AHBIDLE, true, 1000, false);
+	if (ret)
+		log_warning("%s: Waiting for GRSTCTL_AHBIDLE timeout\n", __func__);
+
+	writel(GRSTCTL_RXFFLSH, &regs->global_regs.grstctl);
+
+	ret = wait_for_bit_le32(&regs->global_regs.grstctl, GRSTCTL_RXFFLSH, false, 1000, false);
+	if (ret)
+		log_warning("%s: Waiting for GRSTCTL_RXFFLSH timeout\n", __func__);
+
+	/* Wait for 3 PHY Clocks */
+	udelay(1);
+}
diff --git a/drivers/usb/common/dwc2_core.h b/drivers/usb/common/dwc2_core.h
index 862d3b3691c9caf84590d34960df21117848df0a..b50748b9f6b5c7a43524bb1b48972f1394bb63d8 100644
--- a/drivers/usb/common/dwc2_core.h
+++ b/drivers/usb/common/dwc2_core.h
@@ -125,6 +125,10 @@ struct dwc2_core_regs {
 	u8  ep_fifo[16][0x1000];		/* 0x1000 */
 };
 
+int dwc2_core_reset(struct dwc2_core_regs *regs);
+void dwc2_flush_tx_fifo(struct dwc2_core_regs *regs, const int num);
+void dwc2_flush_rx_fifo(struct dwc2_core_regs *regs);
+
 /* Core Global Register */
 #define GOTGCTL_CHIRPEN				BIT(27)
 #define GOTGCTL_MULT_VALID_BC_MASK		GENMASK(26, 22)
diff --git a/drivers/usb/gadget/dwc2_udc_otg.c b/drivers/usb/gadget/dwc2_udc_otg.c
index 0fc9ee1b90fa71135083a1a6dae2e74992e51181..83d63d7f2162d49c387e0042bd33cc7a5856d407 100644
--- a/drivers/usb/gadget/dwc2_udc_otg.c
+++ b/drivers/usb/gadget/dwc2_udc_otg.c
@@ -471,7 +471,7 @@ static void reconfig_usbd(struct dwc2_udc *dev)
 	u32 max_hw_ep;
 	int pdata_hw_ep;
 
-	writel(GRSTCTL_CSFTRST, &reg->global_regs.grstctl);
+	dwc2_core_reset(reg);
 
 	debug("Resetting OTG controller\n");
 
@@ -575,16 +575,10 @@ static void reconfig_usbd(struct dwc2_udc *dev)
 		       &reg->global_regs.dptxfsizn[i]);
 	}
 	/* Flush the RX FIFO */
-	writel(GRSTCTL_RXFFLSH, &reg->global_regs.grstctl);
-	while (readl(&reg->global_regs.grstctl) & GRSTCTL_RXFFLSH)
-		debug("%s: waiting for DWC2_UDC_OTG_GRSTCTL\n", __func__);
+	dwc2_flush_rx_fifo(reg);
 
 	/* Flush all the Tx FIFO's */
-	writel(FIELD_PREP(GRSTCTL_TXFNUM_MASK, GRSTCTL_TXFNUM_ALL), &reg->global_regs.grstctl);
-	writel(FIELD_PREP(GRSTCTL_TXFNUM_MASK, GRSTCTL_TXFNUM_ALL) | GRSTCTL_TXFFLSH,
-	       &reg->global_regs.grstctl);
-	while (readl(&reg->global_regs.grstctl) & GRSTCTL_TXFFLSH)
-		debug("%s: waiting for DWC2_UDC_OTG_GRSTCTL\n", __func__);
+	dwc2_flush_tx_fifo(reg, GRSTCTL_TXFNUM_ALL);
 
 	/* 13. Clear NAK bit of EP0, EP1, EP2*/
 	/* For Slave mode*/
diff --git a/drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c b/drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c
index 64d2fe7bbde4494b4cbcdf57032b720901fdd4eb..2be93592c423df7a9acea473b0e84e1f948999be 100644
--- a/drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c
+++ b/drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c
@@ -164,11 +164,7 @@ static int setdma_tx(struct dwc2_ep *ep, struct dwc2_request *req)
 		pktcnt = (length - 1)/(ep->ep.maxpacket) + 1;
 
 	/* Flush the endpoint's Tx FIFO */
-	writel(FIELD_PREP(GRSTCTL_TXFNUM_MASK, ep->fifo_num), &reg->global_regs.grstctl);
-	writel(FIELD_PREP(GRSTCTL_TXFNUM_MASK, ep->fifo_num) | GRSTCTL_TXFFLSH,
-	       &reg->global_regs.grstctl);
-	while (readl(&reg->global_regs.grstctl) & GRSTCTL_TXFFLSH)
-		;
+	dwc2_flush_tx_fifo(reg, ep->fifo_num);
 
 	writel(phys_to_bus((unsigned long)ep->dma_buf), &reg->device_regs.in_endp[ep_num].diepdma);
 	writel(FIELD_PREP(DXEPTSIZ_PKTCNT_MASK, pktcnt) |
diff --git a/drivers/usb/host/dwc2.c b/drivers/usb/host/dwc2.c
index ff7885f8195c0bc08669dd99ef6c94992c991945..b27429235798ce223bb8a11999e3d520c26ef377 100644
--- a/drivers/usb/host/dwc2.c
+++ b/drivers/usb/host/dwc2.c
@@ -108,78 +108,6 @@ static void init_fslspclksel(struct dwc2_core_regs *regs)
 			FIELD_PREP(HCFG_FSLSPCLKSEL_MASK, phyclk));
 }
 
-/*
- * Flush a Tx FIFO.
- *
- * @param regs Programming view of DWC_otg controller.
- * @param num Tx FIFO to flush.
- */
-static void dwc_otg_flush_tx_fifo(struct udevice *dev,
-				  struct dwc2_core_regs *regs, const int num)
-{
-	int ret;
-
-	writel(GRSTCTL_TXFFLSH | FIELD_PREP(GRSTCTL_TXFNUM_MASK, num),
-	       &regs->global_regs.grstctl);
-	ret = wait_for_bit_le32(&regs->global_regs.grstctl, GRSTCTL_TXFFLSH,
-				false, 1000, false);
-	if (ret)
-		dev_info(dev, "%s: Timeout!\n", __func__);
-
-	/* Wait for 3 PHY Clocks */
-	udelay(1);
-}
-
-/*
- * Flush Rx FIFO.
- *
- * @param regs Programming view of DWC_otg controller.
- */
-static void dwc_otg_flush_rx_fifo(struct udevice *dev,
-				  struct dwc2_core_regs *regs)
-{
-	int ret;
-
-	writel(GRSTCTL_RXFFLSH, &regs->global_regs.grstctl);
-	ret = wait_for_bit_le32(&regs->global_regs.grstctl, GRSTCTL_RXFFLSH,
-				false, 1000, false);
-	if (ret)
-		dev_info(dev, "%s: Timeout!\n", __func__);
-
-	/* Wait for 3 PHY Clocks */
-	udelay(1);
-}
-
-/*
- * Do core a soft reset of the core.  Be careful with this because it
- * resets all the internal state machines of the core.
- */
-static void dwc_otg_core_reset(struct udevice *dev,
-			       struct dwc2_core_regs *regs)
-{
-	int ret;
-
-	/* Wait for AHB master IDLE state. */
-	ret = wait_for_bit_le32(&regs->global_regs.grstctl, GRSTCTL_AHBIDLE,
-				true, 1000, false);
-	if (ret)
-		dev_info(dev, "%s: Timeout!\n", __func__);
-
-	/* Core Soft Reset */
-	writel(GRSTCTL_CSFTRST, &regs->global_regs.grstctl);
-	ret = wait_for_bit_le32(&regs->global_regs.grstctl, GRSTCTL_CSFTRST,
-				false, 1000, false);
-	if (ret)
-		dev_info(dev, "%s: Timeout!\n", __func__);
-
-	/*
-	 * Wait for core to come out of reset.
-	 * NOTE: This long sleep is _very_ important, otherwise the core will
-	 *       not stay in host mode after a connector ID change!
-	 */
-	mdelay(100);
-}
-
 #if CONFIG_IS_ENABLED(DM_USB) && defined(CONFIG_DM_REGULATOR)
 static int dwc_vbus_supply_init(struct udevice *dev)
 {
@@ -281,8 +209,8 @@ static void dwc_otg_core_host_init(struct udevice *dev,
 	clrbits_le32(&regs->global_regs.gotgctl, GOTGCTL_HSTSETHNPEN);
 
 	/* Make sure the FIFOs are flushed. */
-	dwc_otg_flush_tx_fifo(dev, regs, GRSTCTL_TXFNUM_ALL);	/* All Tx FIFOs */
-	dwc_otg_flush_rx_fifo(dev, regs);
+	dwc2_flush_tx_fifo(regs, GRSTCTL_TXFNUM_ALL);	/* All Tx FIFOs */
+	dwc2_flush_rx_fifo(regs);
 
 	/* Flush out any leftover queued requests. */
 	num_channels = FIELD_GET(GHWCFG2_NUM_HOST_CHAN_MASK, readl(&regs->global_regs.ghwcfg2)) + 1;
@@ -352,7 +280,7 @@ static void dwc_otg_core_init(struct udevice *dev)
 	writel(usbcfg, &regs->global_regs.gusbcfg);
 
 	/* Reset the Controller */
-	dwc_otg_core_reset(dev, regs);
+	dwc2_core_reset(regs);
 
 	/*
 	 * This programming sequence needs to happen in FS mode before
@@ -413,7 +341,7 @@ static void dwc_otg_core_init(struct udevice *dev)
 	writel(usbcfg, &regs->global_regs.gusbcfg);
 
 	/* Reset after setting the PHY parameters */
-	dwc_otg_core_reset(dev, regs);
+	dwc2_core_reset(regs);
 #endif
 
 	usbcfg = readl(&regs->global_regs.gusbcfg);

-- 
2.39.2

