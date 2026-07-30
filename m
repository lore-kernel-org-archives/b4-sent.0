From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Thu, 30 Jul 2026 15:23:16 +0100
Subject: [PATCH 9/9] dmaengine: Drop legacy bus width fields from
 dma_slave_caps
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260730-dmaengine-support-wider-dma-masks-v1-9-3732f1f9d9ca@analog.com>
References: <20260730-dmaengine-support-wider-dma-masks-v1-0-3732f1f9d9ca@analog.com>
In-Reply-To: <20260730-dmaengine-support-wider-dma-masks-v1-0-3732f1f9d9ca@analog.com>
To: dmaengine@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785421644; l=3388;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=dNBaxJgY30zDtQLh74fGVt0NiM2nzPtf9ReiXmX9nLI=;
 b=JZc0kPD4e2qc9boXKiL2wudoER9WtmeDl3dai+VTH2i0Nj7qJUFWBQzGTfxwEydOYYa3bYX6n
 Tv1ffEHipxzBL+FSgCCbcL8EdOISgiaFO2OuODnvF4xvBMqO8dUHgxG
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All users of dma_get_slave_caps() that inspect bus width capabilities
now use bitmap helpers.

Remove the legacy fields from struct dma_slave_caps and stop copying the
dma_device legacy masks into them.

Keep folding legacy dma_device masks into the returned bitmaps so
unconverted DMA controller producers continue to work during the
transition.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dmaengine.c   |  2 --
 include/linux/dmaengine.h | 16 ++--------------
 2 files changed, 2 insertions(+), 16 deletions(-)

diff --git a/drivers/dma/dmaengine.c b/drivers/dma/dmaengine.c
index 7be23ba769d0..ee0b8bfc7c97 100644
--- a/drivers/dma/dmaengine.c
+++ b/drivers/dma/dmaengine.c
@@ -592,7 +592,6 @@ int dma_get_slave_caps(struct dma_chan *chan, struct dma_slave_caps *caps)
 	if (!device->directions)
 		return -ENXIO;
 
-	caps->src_addr_widths = device->src_addr_widths;
 	if (bitmap_empty(device->src_bus_widths, DMA_SLAVE_BUSWIDTH_MAX)) {
 		bitmap_zero(caps->src_bus_widths, DMA_SLAVE_BUSWIDTH_MAX);
 		bitmap_from_arr32(caps->src_bus_widths,
@@ -602,7 +601,6 @@ int dma_get_slave_caps(struct dma_chan *chan, struct dma_slave_caps *caps)
 			    DMA_SLAVE_BUSWIDTH_MAX);
 	}
 
-	caps->dst_addr_widths = device->dst_addr_widths;
 	if (bitmap_empty(device->dst_bus_widths, DMA_SLAVE_BUSWIDTH_MAX)) {
 		bitmap_zero(caps->dst_bus_widths, DMA_SLAVE_BUSWIDTH_MAX);
 		bitmap_from_arr32(caps->dst_bus_widths,
diff --git a/include/linux/dmaengine.h b/include/linux/dmaengine.h
index cea57b166dcb..f37a0559ec5f 100644
--- a/include/linux/dmaengine.h
+++ b/include/linux/dmaengine.h
@@ -495,9 +495,7 @@ enum dma_residue_granularity {
  * @src_bus_widths: bitmap of source bus widths the channel supports.
  *	Width is specified in bytes, e.g. for a channel supporting
  *	a width of 4 the bitmap should have bit 4 set.
- * @src_addr_widths: legacy bit mask of source bus widths the channel supports.
  * @dst_bus_widths: bitmap of destination bus widths the channel supports.
- * @dst_addr_widths: legacy bit mask of destination bus widths the channel supports.
  * @directions: bit mask of slave directions the channel supports.
  *	Since the enum dma_transfer_direction is not defined as bit flag for
  *	each type, the dma controller should set BIT(<TYPE>) and same
@@ -516,14 +514,8 @@ enum dma_residue_granularity {
  * resubmitted multiple times
  */
 struct dma_slave_caps {
-	struct {
-		DECLARE_DMA_BUS_WIDTHS(src_bus_widths);
-		u32 src_addr_widths;
-	};
-	struct {
-		DECLARE_DMA_BUS_WIDTHS(dst_bus_widths);
-		u32 dst_addr_widths;
-	};
+	DECLARE_DMA_BUS_WIDTHS(src_bus_widths);
+	DECLARE_DMA_BUS_WIDTHS(dst_bus_widths);
 	u32 directions;
 	u32 min_burst;
 	u32 max_burst;
@@ -1789,8 +1781,6 @@ dma_slave_caps_clear_src_width(struct dma_slave_caps *caps,
 			       enum dma_slave_buswidth width)
 {
 	__clear_bit(width, caps->src_bus_widths);
-	if (width < DMA_SLAVE_BUSWIDTH_32_BYTES)
-		caps->src_addr_widths &= ~BIT(width);
 }
 
 /**
@@ -1803,8 +1793,6 @@ dma_slave_caps_clear_dst_width(struct dma_slave_caps *caps,
 			       enum dma_slave_buswidth width)
 {
 	__clear_bit(width, caps->dst_bus_widths);
-	if (width < DMA_SLAVE_BUSWIDTH_32_BYTES)
-		caps->dst_addr_widths &= ~BIT(width);
 }
 
 static inline int __dma_set_bus_widths(unsigned long *bus_widths,

-- 
2.55.0

