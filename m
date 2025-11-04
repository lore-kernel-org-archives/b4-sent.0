From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 04 Nov 2025 16:22:27 +0000
Subject: [PATCH RESEND 3/4] dma: dma-axi-dmac: support bigger than 32bits
 addresses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251104-axi-dmac-fixes-and-improvs-v1-3-3e6fd9328f72@analog.com>
References: <20251104-axi-dmac-fixes-and-improvs-v1-0-3e6fd9328f72@analog.com>
In-Reply-To: <20251104-axi-dmac-fixes-and-improvs-v1-0-3e6fd9328f72@analog.com>
To: Vinod Koul <vkoul@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Paul Cercueil <paul@crapouillou.net>
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762273346; l=3123;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=S2/3AgaSBErULI0RSHcw3qkG62aVC+nhl7faANC0TJ0=;
 b=06dYRFgw0iPirSgMG1TrMM7Q2sKpSJT4EHmLx9iw1eTa9bAwHfXwGsNOP8ftOU6Sxs/u1oJsj
 6F88nrc8IEJBmMI9vx6RA3iA50P5lzN1hr+7YncsD17WmPA+01P/1Hu
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In some supported platforms as ARCH_ZYNQMP, part of the memory is mapped
above 32bit addresses and since the DMA mask, by default, is set to 32bits,
we would need to rely on swiotlb (which incurs a performance penalty)
for the DMA mappings. Thus, we can write either the SRC or DEST high
addresses with 1's and read them back. The last bit set on the return
value will reflect the IP address bus width and so we can update the
device DMA mask accordingly.

While at it, support bigger that 32 bits transfers in IP without HW
scatter gather support.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dma-axi-dmac.c | 24 ++++++++++++++++++++++++
 1 file changed, 24 insertions(+)

diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index 0f25f6d8ae71..15c569449a28 100644
--- a/drivers/dma/dma-axi-dmac.c
+++ b/drivers/dma/dma-axi-dmac.c
@@ -69,7 +69,9 @@
 #define AXI_DMAC_REG_START_TRANSFER	0x408
 #define AXI_DMAC_REG_FLAGS		0x40c
 #define AXI_DMAC_REG_DEST_ADDRESS	0x410
+#define AXI_DMAC_REG_DEST_ADDRESS_HIGH	0x490
 #define AXI_DMAC_REG_SRC_ADDRESS	0x414
+#define AXI_DMAC_REG_SRC_ADDRESS_HIGH	0x494
 #define AXI_DMAC_REG_X_LENGTH		0x418
 #define AXI_DMAC_REG_Y_LENGTH		0x41c
 #define AXI_DMAC_REG_DEST_STRIDE	0x420
@@ -271,11 +273,14 @@ static void axi_dmac_start_transfer(struct axi_dmac_chan *chan)
 	if (!chan->hw_sg) {
 		if (axi_dmac_dest_is_mem(chan)) {
 			axi_dmac_write(dmac, AXI_DMAC_REG_DEST_ADDRESS, sg->hw->dest_addr);
+			axi_dmac_write(dmac, AXI_DMAC_REG_DEST_ADDRESS_HIGH,
+				       sg->hw->dest_addr >> 32);
 			axi_dmac_write(dmac, AXI_DMAC_REG_DEST_STRIDE, sg->hw->dst_stride);
 		}
 
 		if (axi_dmac_src_is_mem(chan)) {
 			axi_dmac_write(dmac, AXI_DMAC_REG_SRC_ADDRESS, sg->hw->src_addr);
+			axi_dmac_write(dmac, AXI_DMAC_REG_SRC_ADDRESS_HIGH, sg->hw->src_addr >> 32);
 			axi_dmac_write(dmac, AXI_DMAC_REG_SRC_STRIDE, sg->hw->src_stride);
 		}
 	}
@@ -990,6 +995,9 @@ static int axi_dmac_read_chan_config(struct device *dev, struct axi_dmac *dmac)
 static int axi_dmac_detect_caps(struct axi_dmac *dmac, unsigned int version)
 {
 	struct axi_dmac_chan *chan = &dmac->chan;
+	struct device *dev = dmac->dma_dev.dev;
+	u32 mask;
+	int ret;
 
 	axi_dmac_write(dmac, AXI_DMAC_REG_FLAGS, AXI_DMAC_FLAG_CYCLIC);
 	if (axi_dmac_read(dmac, AXI_DMAC_REG_FLAGS) == AXI_DMAC_FLAG_CYCLIC)
@@ -1024,6 +1032,22 @@ static int axi_dmac_detect_caps(struct axi_dmac *dmac, unsigned int version)
 		return -ENODEV;
 	}
 
+	if (axi_dmac_dest_is_mem(chan)) {
+		axi_dmac_write(dmac, AXI_DMAC_REG_DEST_ADDRESS_HIGH, 0xffffffff);
+		mask = axi_dmac_read(dmac, AXI_DMAC_REG_DEST_ADDRESS_HIGH);
+	} else {
+		axi_dmac_write(dmac, AXI_DMAC_REG_SRC_ADDRESS_HIGH, 0xffffffff);
+		mask = axi_dmac_read(dmac, AXI_DMAC_REG_SRC_ADDRESS_HIGH);
+	}
+
+	mask = 32 + fls(mask);
+
+	ret = dma_set_mask_and_coherent(dev, DMA_BIT_MASK(mask));
+	if (ret) {
+		dev_err(dev, "DMA mask set error %d\n", ret);
+		return ret;
+	}
+
 	if (version >= ADI_AXI_PCORE_VER(4, 2, 'a'))
 		chan->hw_partial_xfer = true;
 

-- 
2.51.0

