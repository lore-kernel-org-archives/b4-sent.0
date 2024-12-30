From: Junhui Liu <liujh2818@outlook.com>
Date: Mon, 30 Dec 2024 11:30:23 +0800
Subject: [PATCH v2 8/8] usb: dwc2: Replace uint<x>_t types with u<x>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241230-dwc2-dev-v2-8-12cd9b8a2358@outlook.com>
References: <20241230-dwc2-dev-v2-0-12cd9b8a2358@outlook.com>
In-Reply-To: <20241230-dwc2-dev-v2-0-12cd9b8a2358@outlook.com>
To: Tom Rini <trini@konsulko.com>, Marek Vasut <marex@denx.de>, 
 Lukasz Majewski <lukma@denx.de>, 
 Mattijs Korpershoek <mkorpershoek@baylibre.com>
Cc: u-boot@lists.denx.de, Kongyang Liu <seashell11234455@gmail.com>, 
 Junhui Liu <liujh2818@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735529447; l=10535;
 i=liujh2818@outlook.com; s=20241030; h=from:subject:message-id;
 bh=aVG6Z7CXNkN+UN1DRCjvWOI3HxU/+VBcivLKWtHPRmg=;
 b=F1pSTsmEada9FrQO+bZR+sQojs21ls14gpd7lfxB/mz5/7JjYGUqg8jMLIpqz7FraOyM8wx1A
 yzkdNSXhbYlAJ7Ve369Ggz5iMScpXGK92zKj7r4B/oSJeV9iHuMnVss
X-Developer-Key: i=liujh2818@outlook.com; a=ed25519;
 pk=ApYwI6KD3EjynMw61RqGa6c5BGbStQnKSrbNN+aQqT4=
X-Endpoint-Received: by B4 Relay for liujh2818@outlook.com/20241030 with auth_id=259
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Kongyang Liu <seashell11234455@gmail.com>

Updates all instances of uint8_t, uint16_t, and uint32_t to u8, u16, and
u32 respectively, ensuring consistent use of kernel-preferred types and
resolving checkpatch.pl warnings.

Signed-off-by: Kongyang Liu <seashell11234455@gmail.com>
Signed-off-by: Junhui Liu <liujh2818@outlook.com>
---
 drivers/usb/gadget/dwc2_udc_otg.c |   4 +-
 drivers/usb/host/dwc2.c           | 100 +++++++++++++++++++-------------------
 2 files changed, 52 insertions(+), 52 deletions(-)

diff --git a/drivers/usb/gadget/dwc2_udc_otg.c b/drivers/usb/gadget/dwc2_udc_otg.c
index 83d63d7f2162d49c387e0042bd33cc7a5856d407..85bf262c103d9b38c7fa655b56e75f6e1b9ce37b 100644
--- a/drivers/usb/gadget/dwc2_udc_otg.c
+++ b/drivers/usb/gadget/dwc2_udc_otg.c
@@ -466,8 +466,8 @@ static void reconfig_usbd(struct dwc2_udc *dev)
 	/* 2. Soft-reset OTG Core and then unreset again. */
 	int i;
 	unsigned int uTemp;
-	uint32_t dflt_gusbcfg;
-	uint32_t rx_fifo_sz, tx_fifo_sz, np_tx_fifo_sz;
+	u32 dflt_gusbcfg;
+	u32 rx_fifo_sz, tx_fifo_sz, np_tx_fifo_sz;
 	u32 max_hw_ep;
 	int pdata_hw_ep;
 
diff --git a/drivers/usb/host/dwc2.c b/drivers/usb/host/dwc2.c
index b27429235798ce223bb8a11999e3d520c26ef377..16f21fa9083a71da1c8dd62d174712962d0227b1 100644
--- a/drivers/usb/host/dwc2.c
+++ b/drivers/usb/host/dwc2.c
@@ -39,16 +39,16 @@
 
 struct dwc2_priv {
 #if CONFIG_IS_ENABLED(DM_USB)
-	uint8_t aligned_buffer[DWC2_DATA_BUF_SIZE] __aligned(ARCH_DMA_MINALIGN);
-	uint8_t status_buffer[DWC2_STATUS_BUF_SIZE] __aligned(ARCH_DMA_MINALIGN);
+	u8 aligned_buffer[DWC2_DATA_BUF_SIZE] __aligned(ARCH_DMA_MINALIGN);
+	u8 status_buffer[DWC2_STATUS_BUF_SIZE] __aligned(ARCH_DMA_MINALIGN);
 #ifdef CONFIG_DM_REGULATOR
 	struct udevice *vbus_supply;
 #endif
 	struct phy phy;
 	struct clk_bulk clks;
 #else
-	uint8_t *aligned_buffer;
-	uint8_t *status_buffer;
+	u8 *aligned_buffer;
+	u8 *status_buffer;
 #endif
 	u8 in_data_toggle[MAX_DEVICE][MAX_ENDPOINT];
 	u8 out_data_toggle[MAX_DEVICE][MAX_ENDPOINT];
@@ -67,10 +67,10 @@ struct dwc2_priv {
 
 #if !CONFIG_IS_ENABLED(DM_USB)
 /* We need cacheline-aligned buffers for DMA transfers and dcache support */
-DEFINE_ALIGN_BUFFER(uint8_t, aligned_buffer_addr, DWC2_DATA_BUF_SIZE,
-		ARCH_DMA_MINALIGN);
-DEFINE_ALIGN_BUFFER(uint8_t, status_buffer_addr, DWC2_STATUS_BUF_SIZE,
-		ARCH_DMA_MINALIGN);
+DEFINE_ALIGN_BUFFER(u8, aligned_buffer_addr, DWC2_DATA_BUF_SIZE,
+		    ARCH_DMA_MINALIGN);
+DEFINE_ALIGN_BUFFER(u8, status_buffer_addr, DWC2_STATUS_BUF_SIZE,
+		    ARCH_DMA_MINALIGN);
 
 static struct dwc2_priv local;
 #endif
@@ -85,7 +85,7 @@ static struct dwc2_priv local;
  */
 static void init_fslspclksel(struct dwc2_core_regs *regs)
 {
-	uint32_t phyclk;
+	u32 phyclk;
 
 #if (DWC2_PHY_TYPE == DWC2_PHY_TYPE_FS)
 	phyclk = HCFG_FSLSPCLKSEL_48_MHZ;	/* Full speed PHY */
@@ -95,9 +95,9 @@ static void init_fslspclksel(struct dwc2_core_regs *regs)
 #endif
 
 #ifdef DWC2_ULPI_FS_LS
-	uint32_t hwcfg2 = readl(&regs->global_regs.ghwcfg2);
-	uint32_t hval = FIELD_GET(GHWCFG2_HS_PHY_TYPE_MASK, ghwcfg2);
-	uint32_t fval = FIELD_GET(GHWCFG2_FS_PHY_TYPE_MASK, ghwcfg2);
+	u32 hwcfg2 = readl(&regs->global_regs.ghwcfg2);
+	u32 hval = FIELD_GET(GHWCFG2_HS_PHY_TYPE_MASK, ghwcfg2);
+	u32 fval = FIELD_GET(GHWCFG2_FS_PHY_TYPE_MASK, ghwcfg2);
 
 	if (hval == GHWCFG2_FS_PHY_TYPE_SHARED_UTMI && fval == GHWCFG2_HS_PHY_TYPE_UTMI)
 		phyclk = HCFG_FSLSPCLKSEL_48_MHZ;	/* Full speed PHY */
@@ -172,9 +172,9 @@ static int dwc_vbus_supply_exit(struct udevice *dev)
 static void dwc_otg_core_host_init(struct udevice *dev,
 				   struct dwc2_core_regs *regs)
 {
-	uint32_t nptxfifosize = 0;
-	uint32_t ptxfifosize = 0;
-	uint32_t hprt0 = 0;
+	u32 nptxfifosize = 0;
+	u32 ptxfifosize = 0;
+	u32 hprt0 = 0;
 	int i, ret, num_channels;
 
 	/* Restart the Phy Clock */
@@ -253,9 +253,9 @@ static void dwc_otg_core_init(struct udevice *dev)
 {
 	struct dwc2_priv *priv = dev_get_priv(dev);
 	struct dwc2_core_regs *regs = priv->regs;
-	uint32_t ahbcfg = 0;
-	uint32_t usbcfg = 0;
-	uint8_t brst_sz = DWC2_DMA_BURST_SIZE;
+	u32 ahbcfg = 0;
+	u32 usbcfg = 0;
+	u8 brst_sz = DWC2_DMA_BURST_SIZE;
 
 	/* Common Initialization */
 	usbcfg = readl(&regs->global_regs.gusbcfg);
@@ -347,9 +347,9 @@ static void dwc_otg_core_init(struct udevice *dev)
 	usbcfg = readl(&regs->global_regs.gusbcfg);
 	usbcfg &= ~(GUSBCFG_ULPI_FS_LS | GUSBCFG_ULPI_CLK_SUSP_M);
 #ifdef DWC2_ULPI_FS_LS
-	uint32_t hwcfg2 = readl(&regs->global_regs.ghwcfg2);
-	uint32_t hval = FIELD_GET(GHWCFG2_HS_PHY_TYPE_MASK, ghwcfg2);
-	uint32_t fval = FIELD_GET(GHWCFG2_FS_PHY_TYPE_MASK, ghwcfg2);
+	u32 hwcfg2 = readl(&regs->global_regs.ghwcfg2);
+	u32 hval = FIELD_GET(GHWCFG2_HS_PHY_TYPE_MASK, ghwcfg2);
+	u32 fval = FIELD_GET(GHWCFG2_FS_PHY_TYPE_MASK, ghwcfg2);
 
 	if (hval == GHWCFG2_FS_PHY_TYPE_SHARED_UTMI && fval == GHWCFG2_HS_PHY_TYPE_UTMI) {
 		usbcfg |= GUSBCFG_ULPI_FS_LS;
@@ -402,9 +402,9 @@ static void dwc_otg_core_init(struct udevice *dev)
  * @param regs Programming view of DWC_otg controller
  * @param hc Information needed to initialize the host channel
  */
-static void dwc_otg_hc_init(struct dwc2_core_regs *regs, uint8_t hc_num,
-		struct usb_device *dev, uint8_t dev_addr, uint8_t ep_num,
-		uint8_t ep_is_in, uint8_t ep_type, uint16_t max_packet)
+static void dwc_otg_hc_init(struct dwc2_core_regs *regs, u8 hc_num,
+			    struct usb_device *dev, u8 dev_addr, u8 ep_num,
+			    u8 ep_is_in, u8 ep_type, u16 max_packet)
 {
 	struct dwc2_hc_regs *hc_regs = &regs->host_regs.hc[hc_num];
 	u32 hcchar = FIELD_PREP(HCCHAR_DEVADDR_MASK, dev_addr) |
@@ -427,9 +427,9 @@ static void dwc_otg_hc_init(struct dwc2_core_regs *regs, uint8_t hc_num,
 }
 
 static void dwc_otg_hc_init_split(struct dwc2_hc_regs *hc_regs,
-				  uint8_t hub_devnum, uint8_t hub_port)
+				  u8 hub_devnum, u8 hub_port)
 {
-	uint32_t hcsplt = 0;
+	u32 hcsplt = 0;
 
 	hcsplt = HCSPLT_SPLTENA;
 	hcsplt |= FIELD_PREP(HCSPLT_HUBADDR_MASK, hub_devnum);
@@ -447,24 +447,24 @@ static int dwc_otg_submit_rh_msg_in_status(struct dwc2_core_regs *regs,
 					   struct usb_device *dev, void *buffer,
 					   int txlen, struct devrequest *cmd)
 {
-	uint32_t hprt0 = 0;
-	uint32_t port_status = 0;
-	uint32_t port_change = 0;
+	u32 hprt0 = 0;
+	u32 port_status = 0;
+	u32 port_change = 0;
 	int len = 0;
 	int stat = 0;
 
 	switch (cmd->requesttype & ~USB_DIR_IN) {
 	case 0:
-		*(uint16_t *)buffer = cpu_to_le16(1);
+		*(u16 *)buffer = cpu_to_le16(1);
 		len = 2;
 		break;
 	case USB_RECIP_INTERFACE:
 	case USB_RECIP_ENDPOINT:
-		*(uint16_t *)buffer = cpu_to_le16(0);
+		*(u16 *)buffer = cpu_to_le16(0);
 		len = 2;
 		break;
 	case USB_TYPE_CLASS:
-		*(uint32_t *)buffer = cpu_to_le32(0);
+		*(u32 *)buffer = cpu_to_le32(0);
 		len = 4;
 		break;
 	case USB_RECIP_OTHER | USB_TYPE_CLASS:
@@ -498,7 +498,7 @@ static int dwc_otg_submit_rh_msg_in_status(struct dwc2_core_regs *regs,
 		if (hprt0 & HPRT0_OVRCURRCHG)
 			port_change |= USB_PORT_STAT_C_OVERCURRENT;
 
-		*(uint32_t *)buffer = cpu_to_le32(port_status |
+		*(u32 *)buffer = cpu_to_le32(port_status |
 					(port_change << 16));
 		len = 4;
 		break;
@@ -519,11 +519,11 @@ static int dwc_otg_submit_rh_msg_in_descriptor(struct usb_device *dev,
 					       struct devrequest *cmd)
 {
 	unsigned char data[32];
-	uint32_t dsc;
+	u32 dsc;
 	int len = 0;
 	int stat = 0;
-	uint16_t wValue = cpu_to_le16(cmd->value);
-	uint16_t wLength = cpu_to_le16(cmd->length);
+	u16 wValue = cpu_to_le16(cmd->value);
+	u16 wLength = cpu_to_le16(cmd->length);
 
 	switch (cmd->requesttype & ~USB_DIR_IN) {
 	case 0:
@@ -606,7 +606,7 @@ static int dwc_otg_submit_rh_msg_in_configuration(struct usb_device *dev,
 
 	switch (cmd->requesttype & ~USB_DIR_IN) {
 	case 0:
-		*(uint8_t *)buffer = 0x01;
+		*(u8 *)buffer = 0x01;
 		len = 1;
 		break;
 	default:
@@ -650,8 +650,8 @@ static int dwc_otg_submit_rh_msg_out(struct dwc2_priv *priv,
 	struct dwc2_core_regs *regs = priv->regs;
 	int len = 0;
 	int stat = 0;
-	uint16_t bmrtype_breq = cmd->requesttype | (cmd->request << 8);
-	uint16_t wValue = cpu_to_le16(cmd->value);
+	u16 bmrtype_breq = cmd->requesttype | (cmd->request << 8);
+	u16 wValue = cpu_to_le16(cmd->value);
 
 	switch (bmrtype_breq & ~USB_DIR_IN) {
 	case (USB_REQ_CLEAR_FEATURE << 8) | USB_RECIP_ENDPOINT:
@@ -724,10 +724,10 @@ static int dwc_otg_submit_rh_msg(struct dwc2_priv *priv, struct usb_device *dev,
 	return stat;
 }
 
-int wait_for_chhltd(struct dwc2_hc_regs *hc_regs, uint32_t *sub, u8 *toggle)
+int wait_for_chhltd(struct dwc2_hc_regs *hc_regs, u32 *sub, u8 *toggle)
 {
 	int ret;
-	uint32_t hcint, hctsiz;
+	u32 hcint, hctsiz;
 
 	ret = wait_for_bit_le32(&hc_regs->hcint, HCINTMSK_CHHLTD, true,
 				2000, false);
@@ -764,7 +764,7 @@ static int transfer_chunk(struct dwc2_hc_regs *hc_regs, void *aligned_buffer,
 			  int xfer_len, int *actual_len, int odd_frame)
 {
 	int ret = 0;
-	uint32_t sub;
+	u32 sub;
 
 	debug("%s: chunk: pid %d xfer_len %u pkts %u\n", __func__,
 	      *pid, xfer_len, num_packets);
@@ -834,10 +834,10 @@ int chunk_msg(struct dwc2_priv *priv, struct usb_device *dev,
 	int ret = 0;
 	int do_split = 0;
 	int complete_split = 0;
-	uint32_t xfer_len;
-	uint32_t num_packets;
+	u32 xfer_len;
+	u32 num_packets;
 	int stop_transfer = 0;
-	uint32_t max_xfer_len;
+	u32 max_xfer_len;
 	int ssplit_frame_num = 0;
 
 	debug("%s: msg: pipe %lx pid %d in %d len %d\n", __func__, pipe, *pid,
@@ -859,9 +859,9 @@ int chunk_msg(struct dwc2_priv *priv, struct usb_device *dev,
 
 	/* Check if the target is a FS/LS device behind a HS hub */
 	if (dev->speed != USB_SPEED_HIGH) {
-		uint8_t hub_addr;
-		uint8_t hub_port;
-		uint32_t hprt0 = readl(&regs->host_regs.hprt0);
+		u8 hub_addr;
+		u8 hub_port;
+		u32 hprt0 = readl(&regs->host_regs.hprt0);
 
 		if (FIELD_GET(HPRT0_SPD_MASK, hprt0) == HPRT0_SPD_HIGH_SPEED) {
 			usb_find_usb2_hub_address_port(dev, &hub_addr,
@@ -876,7 +876,7 @@ int chunk_msg(struct dwc2_priv *priv, struct usb_device *dev,
 
 	do {
 		int actual_len = 0;
-		uint32_t hcint;
+		u32 hcint;
 		int odd_frame = 0;
 		xfer_len = len - done;
 
@@ -1083,7 +1083,7 @@ static int dwc2_reset(struct udevice *dev)
 static int dwc2_init_common(struct udevice *dev, struct dwc2_priv *priv)
 {
 	struct dwc2_core_regs *regs = priv->regs;
-	uint32_t snpsid;
+	u32 snpsid;
 	int i, j;
 	int ret;
 

-- 
2.39.2

