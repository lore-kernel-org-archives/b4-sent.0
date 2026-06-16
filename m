From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 16 Jun 2026 16:40:52 +0100
Subject: [PATCH RFC 1/3] dmaengine: Support address bus widths of 32 bytes
 and above
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260616-dmaengine-support-wider-dma-masks-v1-1-da23a8dcb756@analog.com>
References: <20260616-dmaengine-support-wider-dma-masks-v1-0-da23a8dcb756@analog.com>
In-Reply-To: <20260616-dmaengine-support-wider-dma-masks-v1-0-da23a8dcb756@analog.com>
To: dmaengine@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781624455; l=6136;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=seK2wQ1gP5/CY+c6SdU0DSHpgs7+1OD32PnCpLFnNMU=;
 b=VaSoQ22ie0zIfavrrNdBnJAYVMaoPhET+P1sK1CJcaHwofsEfWskGzpE1WIYXko/2LjABb4Bg
 9RDlOcrGB3sC+T4i94u/b9UbtFuta4UtWqxEHLuYX8weyX0HFdrgZQA
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The src_addr_widths and dst_addr_widths capability masks encode each
supported width as a bit whose position equals the corresponding
enum dma_slave_buswidth value (e.g. DMA_SLAVE_BUSWIDTH_4_BYTES sets
bit 4). As these masks are plain u32, widths of 32 bytes and above
(DMA_SLAVE_BUSWIDTH_32/64/128_BYTES map to bits 32, 64 and 128) cannot
be represented at all.

Introduce bitmap-based masks that span the full enum range. To allow
controllers and consumers to be converted incrementally, the legacy
u32 fields are kept alongside the new bitmaps: producers populate the
bitmap (mirroring the low 32 bits back into the legacy field) and
dma_get_slave_caps() folds a legacy-only producer's u32 into the
returned bitmap.

Add dma_set_{src,dst}_addr_mask() for producers and
dma_slave_caps_get_{src,dst}_width_min() for consumers so that, once
every user is converted, the legacy u32 fields can be dropped and the
bitmaps renamed without further churn.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dmaengine.c   |  18 +++++++++
 include/linux/dmaengine.h | 100 ++++++++++++++++++++++++++++++++++++++++++++--
 2 files changed, 114 insertions(+), 4 deletions(-)

diff --git a/drivers/dma/dmaengine.c b/drivers/dma/dmaengine.c
index 9049171df857..a21bc9c140aa 100644
--- a/drivers/dma/dmaengine.c
+++ b/drivers/dma/dmaengine.c
@@ -593,7 +593,25 @@ int dma_get_slave_caps(struct dma_chan *chan, struct dma_slave_caps *caps)
 		return -ENXIO;
 
 	caps->src_addr_widths = device->src_addr_widths;
+	if (bitmap_empty(device->src_addr_widths_mask, DMA_SLAVE_BUSWIDTH_MAX)) {
+		bitmap_zero(caps->src_addr_widths_mask, DMA_SLAVE_BUSWIDTH_MAX);
+		bitmap_from_arr32(caps->src_addr_widths_mask,
+				  &device->src_addr_widths, 32);
+	} else {
+		bitmap_copy(caps->src_addr_widths_mask,
+			    device->src_addr_widths_mask, DMA_SLAVE_BUSWIDTH_MAX);
+	}
+
 	caps->dst_addr_widths = device->dst_addr_widths;
+	if (bitmap_empty(device->dst_addr_widths_mask, DMA_SLAVE_BUSWIDTH_MAX)) {
+		bitmap_zero(caps->dst_addr_widths_mask, DMA_SLAVE_BUSWIDTH_MAX);
+		bitmap_from_arr32(caps->dst_addr_widths_mask,
+				  &device->dst_addr_widths, 32);
+	} else {
+		bitmap_copy(caps->dst_addr_widths_mask,
+			    device->dst_addr_widths_mask, DMA_SLAVE_BUSWIDTH_MAX);
+	}
+
 	caps->directions = device->directions;
 	caps->min_burst = device->min_burst;
 	caps->max_burst = device->max_burst;
diff --git a/include/linux/dmaengine.h b/include/linux/dmaengine.h
index b3d251c9734e..e249158aa4a5 100644
--- a/include/linux/dmaengine.h
+++ b/include/linux/dmaengine.h
@@ -5,6 +5,7 @@
 #ifndef LINUX_DMAENGINE_H
 #define LINUX_DMAENGINE_H
 
+#include <linux/bitops.h>
 #include <linux/device.h>
 #include <linux/err.h>
 #include <linux/uio.h>
@@ -391,6 +392,7 @@ enum dma_slave_buswidth {
 	DMA_SLAVE_BUSWIDTH_32_BYTES = 32,
 	DMA_SLAVE_BUSWIDTH_64_BYTES = 64,
 	DMA_SLAVE_BUSWIDTH_128_BYTES = 128,
+	DMA_SLAVE_BUSWIDTH_MAX
 };
 
 /**
@@ -509,8 +511,14 @@ enum dma_residue_granularity {
  * resubmitted multiple times
  */
 struct dma_slave_caps {
-	u32 src_addr_widths;
-	u32 dst_addr_widths;
+	struct {
+		DECLARE_BITMAP(src_addr_widths_mask, DMA_SLAVE_BUSWIDTH_MAX);
+		u32 src_addr_widths;
+	};
+	struct {
+		DECLARE_BITMAP(dst_addr_widths_mask, DMA_SLAVE_BUSWIDTH_MAX);
+		u32 dst_addr_widths;
+	};
 	u32 directions;
 	u32 min_burst;
 	u32 max_burst;
@@ -887,8 +895,14 @@ struct dma_device {
 	struct module *owner;
 	struct ida chan_ida;
 
-	u32 src_addr_widths;
-	u32 dst_addr_widths;
+	struct {
+		DECLARE_BITMAP(src_addr_widths_mask, DMA_SLAVE_BUSWIDTH_MAX);
+		u32 src_addr_widths;
+	};
+	struct {
+		DECLARE_BITMAP(dst_addr_widths_mask, DMA_SLAVE_BUSWIDTH_MAX);
+		u32 dst_addr_widths;
+	};
 	u32 directions;
 	u32 min_burst;
 	u32 max_burst;
@@ -1678,4 +1692,82 @@ static inline struct device *dmaengine_get_dma_device(struct dma_chan *chan)
 	return chan->device->dev;
 }
 
+static inline enum dma_slave_buswidth
+__dma_slave_caps_get_width_min(const unsigned long *bitmask)
+{
+	enum dma_slave_buswidth width = find_first_bit(bitmask,
+						       DMA_SLAVE_BUSWIDTH_MAX);
+
+	if (width == DMA_SLAVE_BUSWIDTH_MAX)
+		return DMA_SLAVE_BUSWIDTH_UNDEFINED;
+
+	return width;
+}
+
+static inline enum dma_slave_buswidth
+dma_slave_caps_get_src_width_min(const struct dma_slave_caps *caps)
+{
+	return __dma_slave_caps_get_width_min(caps->src_addr_widths_mask);
+}
+
+static inline enum dma_slave_buswidth
+dma_slave_caps_get_dst_width_min(const struct dma_slave_caps *caps)
+{
+	return __dma_slave_caps_get_width_min(caps->dst_addr_widths_mask);
+}
+
+static inline int __dma_set_addr_mask(unsigned long *bitmask,
+				      enum dma_slave_buswidth *widths,
+				      unsigned int n_widths)
+{
+	for (unsigned int i = 0; i < n_widths; i++) {
+		switch (widths[i]) {
+		case DMA_SLAVE_BUSWIDTH_1_BYTE:
+		case DMA_SLAVE_BUSWIDTH_2_BYTES:
+		case DMA_SLAVE_BUSWIDTH_3_BYTES:
+		case DMA_SLAVE_BUSWIDTH_4_BYTES:
+		case DMA_SLAVE_BUSWIDTH_8_BYTES:
+		case DMA_SLAVE_BUSWIDTH_16_BYTES:
+		case DMA_SLAVE_BUSWIDTH_32_BYTES:
+		case DMA_SLAVE_BUSWIDTH_64_BYTES:
+		case DMA_SLAVE_BUSWIDTH_128_BYTES:
+			break;
+		default:
+			return -EINVAL;
+		}
+
+		__set_bit(widths[i], bitmask);
+	}
+
+	return 0;
+}
+
+static inline int dma_set_src_addr_mask(struct dma_device *device,
+					enum dma_slave_buswidth *widths,
+					unsigned int n_widths)
+{
+	int ret;
+
+	ret = __dma_set_addr_mask(device->src_addr_widths_mask, widths, n_widths);
+	if (ret)
+		return ret;
+
+	device->src_addr_widths = bitmap_read(device->src_addr_widths_mask, 0, 32);
+	return 0;
+}
+
+static inline int dma_set_dst_addr_mask(struct dma_device *device,
+					enum dma_slave_buswidth *widths,
+					unsigned int n_widths)
+{
+	int ret;
+
+	ret = __dma_set_addr_mask(device->dst_addr_widths_mask, widths, n_widths);
+	if (ret)
+		return ret;
+
+	device->dst_addr_widths = bitmap_read(device->dst_addr_widths_mask, 0, 32);
+	return 0;
+}
+
 #endif /* DMAENGINE_H */

-- 
2.54.0

