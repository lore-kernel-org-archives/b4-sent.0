From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Thu, 30 Jul 2026 15:23:08 +0100
Subject: [PATCH 1/9] dmaengine: Support bus widths of 32 bytes and above
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260730-dmaengine-support-wider-dma-masks-v1-1-3732f1f9d9ca@analog.com>
References: <20260730-dmaengine-support-wider-dma-masks-v1-0-3732f1f9d9ca@analog.com>
In-Reply-To: <20260730-dmaengine-support-wider-dma-masks-v1-0-3732f1f9d9ca@analog.com>
To: dmaengine@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785421644; l=12568;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Z5O1BX+XZRBfceKyP5Rlj4DH1uZNddhZBgGcHqoSr1g=;
 b=X4wwR+ZPt1LLbgzH1BF3ywMF9sWQtnjOkGYiLKKFu9QGbQ8sobaOX2kQ7/WWjsRzFPgYRPu6T
 l4vziFFZV3TA0xdTVip6kk6kH1AaFDKwG8y8MlX4cm3c4iIPMojhv35
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The src_addr_widths and dst_addr_widths capability masks encode each
supported width as a bit whose position equals the corresponding
enum dma_slave_buswidth value (e.g. DMA_SLAVE_BUSWIDTH_4_BYTES sets bit
4). As these masks are plain u32, widths of 32 bytes and above
(DMA_SLAVE_BUSWIDTH_32/64/128_BYTES map to bits 32, 64 and 128) cannot
be represented at all.

Introduce bitmap-based bus width capabilities that span the full enum
range. To allow DMA controller producers to be converted incrementally,
keep the legacy dma_device u32 fields alongside the new bitmaps:
producers using the new helpers populate the bitmap and mirror the low
32 bits back into the legacy field, while dma_get_slave_caps() folds a
legacy-only producer's u32 into the returned bitmap.

Add helpers for producers and consumers so users do not need to depend
on the bitmap layout directly. Once the remaining producers are
converted, the legacy dma_device u32 fields can be dropped.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dmaengine.c   |  18 ++++
 include/linux/dmaengine.h | 246 ++++++++++++++++++++++++++++++++++++++++++++--
 2 files changed, 254 insertions(+), 10 deletions(-)

diff --git a/drivers/dma/dmaengine.c b/drivers/dma/dmaengine.c
index 9049171df857..7be23ba769d0 100644
--- a/drivers/dma/dmaengine.c
+++ b/drivers/dma/dmaengine.c
@@ -593,7 +593,25 @@ int dma_get_slave_caps(struct dma_chan *chan, struct dma_slave_caps *caps)
 		return -ENXIO;
 
 	caps->src_addr_widths = device->src_addr_widths;
+	if (bitmap_empty(device->src_bus_widths, DMA_SLAVE_BUSWIDTH_MAX)) {
+		bitmap_zero(caps->src_bus_widths, DMA_SLAVE_BUSWIDTH_MAX);
+		bitmap_from_arr32(caps->src_bus_widths,
+				  &device->src_addr_widths, 32);
+	} else {
+		bitmap_copy(caps->src_bus_widths, device->src_bus_widths,
+			    DMA_SLAVE_BUSWIDTH_MAX);
+	}
+
 	caps->dst_addr_widths = device->dst_addr_widths;
+	if (bitmap_empty(device->dst_bus_widths, DMA_SLAVE_BUSWIDTH_MAX)) {
+		bitmap_zero(caps->dst_bus_widths, DMA_SLAVE_BUSWIDTH_MAX);
+		bitmap_from_arr32(caps->dst_bus_widths,
+				  &device->dst_addr_widths, 32);
+	} else {
+		bitmap_copy(caps->dst_bus_widths, device->dst_bus_widths,
+			    DMA_SLAVE_BUSWIDTH_MAX);
+	}
+
 	caps->directions = device->directions;
 	caps->min_burst = device->min_burst;
 	caps->max_burst = device->max_burst;
diff --git a/include/linux/dmaengine.h b/include/linux/dmaengine.h
index b3d251c9734e..cea57b166dcb 100644
--- a/include/linux/dmaengine.h
+++ b/include/linux/dmaengine.h
@@ -5,6 +5,7 @@
 #ifndef LINUX_DMAENGINE_H
 #define LINUX_DMAENGINE_H
 
+#include <linux/bitops.h>
 #include <linux/device.h>
 #include <linux/err.h>
 #include <linux/uio.h>
@@ -391,8 +392,12 @@ enum dma_slave_buswidth {
 	DMA_SLAVE_BUSWIDTH_32_BYTES = 32,
 	DMA_SLAVE_BUSWIDTH_64_BYTES = 64,
 	DMA_SLAVE_BUSWIDTH_128_BYTES = 128,
+	DMA_SLAVE_BUSWIDTH_MAX
 };
 
+#define DECLARE_DMA_BUS_WIDTHS(name) \
+	DECLARE_BITMAP(name, DMA_SLAVE_BUSWIDTH_MAX)
+
 /**
  * struct dma_slave_config - dma slave channel runtime config
  * @direction: whether the data shall go in or out on this slave
@@ -487,10 +492,12 @@ enum dma_residue_granularity {
 
 /**
  * struct dma_slave_caps - expose capabilities of a slave channel only
- * @src_addr_widths: bit mask of src addr widths the channel supports.
+ * @src_bus_widths: bitmap of source bus widths the channel supports.
  *	Width is specified in bytes, e.g. for a channel supporting
- *	a width of 4 the mask should have BIT(4) set.
- * @dst_addr_widths: bit mask of dst addr widths the channel supports
+ *	a width of 4 the bitmap should have bit 4 set.
+ * @src_addr_widths: legacy bit mask of source bus widths the channel supports.
+ * @dst_bus_widths: bitmap of destination bus widths the channel supports.
+ * @dst_addr_widths: legacy bit mask of destination bus widths the channel supports.
  * @directions: bit mask of slave directions the channel supports.
  *	Since the enum dma_transfer_direction is not defined as bit flag for
  *	each type, the dma controller should set BIT(<TYPE>) and same
@@ -509,8 +516,14 @@ enum dma_residue_granularity {
  * resubmitted multiple times
  */
 struct dma_slave_caps {
-	u32 src_addr_widths;
-	u32 dst_addr_widths;
+	struct {
+		DECLARE_DMA_BUS_WIDTHS(src_bus_widths);
+		u32 src_addr_widths;
+	};
+	struct {
+		DECLARE_DMA_BUS_WIDTHS(dst_bus_widths);
+		u32 dst_addr_widths;
+	};
 	u32 directions;
 	u32 min_burst;
 	u32 max_burst;
@@ -803,10 +816,12 @@ struct dma_filter {
  * @dev: struct device reference for dma mapping api
  * @owner: owner module (automatically set based on the provided dev)
  * @chan_ida: unique channel ID
- * @src_addr_widths: bit mask of src addr widths the device supports
+ * @src_bus_widths: bitmap of source bus widths the device supports.
  *	Width is specified in bytes, e.g. for a device supporting
- *	a width of 4 the mask should have BIT(4) set.
- * @dst_addr_widths: bit mask of dst addr widths the device supports
+ *	a width of 4 the bitmap should have bit 4 set.
+ * @src_addr_widths: legacy bit mask of source bus widths the device supports.
+ * @dst_bus_widths: bitmap of destination bus widths the device supports.
+ * @dst_addr_widths: legacy bit mask of destination bus widths the device supports.
  * @directions: bit mask of slave directions the device supports.
  *	Since the enum dma_transfer_direction is not defined as bit flag for
  *	each type, the dma controller should set BIT(<TYPE>) and same
@@ -887,8 +902,14 @@ struct dma_device {
 	struct module *owner;
 	struct ida chan_ida;
 
-	u32 src_addr_widths;
-	u32 dst_addr_widths;
+	struct {
+		DECLARE_DMA_BUS_WIDTHS(src_bus_widths);
+		u32 src_addr_widths;
+	};
+	struct {
+		DECLARE_DMA_BUS_WIDTHS(dst_bus_widths);
+		u32 dst_addr_widths;
+	};
 	u32 directions;
 	u32 min_burst;
 	u32 max_burst;
@@ -1678,4 +1699,209 @@ static inline struct device *dmaengine_get_dma_device(struct dma_chan *chan)
 	return chan->device->dev;
 }
 
+static inline enum dma_slave_buswidth
+__dma_slave_caps_get_width_min(const unsigned long *bus_widths)
+{
+	enum dma_slave_buswidth width = find_first_bit(bus_widths,
+						       DMA_SLAVE_BUSWIDTH_MAX);
+
+	if (width == DMA_SLAVE_BUSWIDTH_MAX)
+		return DMA_SLAVE_BUSWIDTH_UNDEFINED;
+
+	return width;
+}
+
+/**
+ * dma_slave_caps_get_src_width_min - get the minimum source bus width
+ * @caps: DMA slave capabilities
+ *
+ * Return: the minimum supported source bus width, or
+ * %DMA_SLAVE_BUSWIDTH_UNDEFINED if no source bus width is advertised.
+ */
+static inline enum dma_slave_buswidth
+dma_slave_caps_get_src_width_min(const struct dma_slave_caps *caps)
+{
+	return __dma_slave_caps_get_width_min(caps->src_bus_widths);
+}
+
+/**
+ * dma_slave_caps_get_dst_width_min - get the minimum destination bus width
+ * @caps: DMA slave capabilities
+ *
+ * Return: the minimum supported destination bus width, or
+ * %DMA_SLAVE_BUSWIDTH_UNDEFINED if no destination bus width is advertised.
+ */
+static inline enum dma_slave_buswidth
+dma_slave_caps_get_dst_width_min(const struct dma_slave_caps *caps)
+{
+	return __dma_slave_caps_get_width_min(caps->dst_bus_widths);
+}
+
+/**
+ * dma_slave_caps_copy_src_widths - copy source bus width capabilities
+ * @caps: DMA slave capabilities
+ * @bus_widths: destination bitmap declared with DECLARE_DMA_BUS_WIDTHS()
+ */
+static inline void
+dma_slave_caps_copy_src_widths(const struct dma_slave_caps *caps,
+			       unsigned long *bus_widths)
+{
+	bitmap_copy(bus_widths, caps->src_bus_widths, DMA_SLAVE_BUSWIDTH_MAX);
+}
+
+/**
+ * dma_slave_caps_copy_dst_widths - copy destination bus width capabilities
+ * @caps: DMA slave capabilities
+ * @bus_widths: destination bitmap declared with DECLARE_DMA_BUS_WIDTHS()
+ */
+static inline void
+dma_slave_caps_copy_dst_widths(const struct dma_slave_caps *caps,
+			       unsigned long *bus_widths)
+{
+	bitmap_copy(bus_widths, caps->dst_bus_widths, DMA_SLAVE_BUSWIDTH_MAX);
+}
+
+/**
+ * dma_slave_caps_intersect_widths - intersect destination and source widths
+ * @dst_caps: DMA slave capabilities providing destination bus widths
+ * @src_caps: DMA slave capabilities providing source bus widths
+ * @bus_widths: destination bitmap declared with DECLARE_DMA_BUS_WIDTHS()
+ *
+ * Return: true if the resulting bitmap contains at least one common bus width,
+ * false otherwise.
+ */
+static inline bool
+dma_slave_caps_intersect_widths(const struct dma_slave_caps *dst_caps,
+				const struct dma_slave_caps *src_caps,
+				unsigned long *bus_widths)
+{
+	return bitmap_and(bus_widths, dst_caps->dst_bus_widths,
+			  src_caps->src_bus_widths, DMA_SLAVE_BUSWIDTH_MAX);
+}
+
+/**
+ * dma_slave_caps_clear_src_width - clear a source bus width capability
+ * @caps: DMA slave capabilities
+ * @width: source bus width to clear
+ */
+static inline void
+dma_slave_caps_clear_src_width(struct dma_slave_caps *caps,
+			       enum dma_slave_buswidth width)
+{
+	__clear_bit(width, caps->src_bus_widths);
+	if (width < DMA_SLAVE_BUSWIDTH_32_BYTES)
+		caps->src_addr_widths &= ~BIT(width);
+}
+
+/**
+ * dma_slave_caps_clear_dst_width - clear a destination bus width capability
+ * @caps: DMA slave capabilities
+ * @width: destination bus width to clear
+ */
+static inline void
+dma_slave_caps_clear_dst_width(struct dma_slave_caps *caps,
+			       enum dma_slave_buswidth width)
+{
+	__clear_bit(width, caps->dst_bus_widths);
+	if (width < DMA_SLAVE_BUSWIDTH_32_BYTES)
+		caps->dst_addr_widths &= ~BIT(width);
+}
+
+static inline int __dma_set_bus_widths(unsigned long *bus_widths,
+				       const enum dma_slave_buswidth *widths,
+				       unsigned int n_widths)
+{
+	for (unsigned int i = 0; i < n_widths; i++) {
+		switch (widths[i]) {
+		case DMA_SLAVE_BUSWIDTH_UNDEFINED:
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
+		__set_bit(widths[i], bus_widths);
+	}
+
+	return 0;
+}
+
+/**
+ * dma_set_src_bus_widths - set supported source bus widths for a DMA device
+ * @device: DMA device
+ * @widths: array of supported source bus widths
+ * @n_widths: number of entries in @widths
+ *
+ * Return: 0 on success, -EINVAL if @widths contains an invalid bus width.
+ */
+static inline int dma_set_src_bus_widths(struct dma_device *device,
+					 const enum dma_slave_buswidth *widths,
+					 unsigned int n_widths)
+{
+	int ret;
+
+	ret = __dma_set_bus_widths(device->src_bus_widths, widths, n_widths);
+	if (ret)
+		return ret;
+
+	device->src_addr_widths = bitmap_read(device->src_bus_widths, 0, 32);
+	return 0;
+}
+
+/**
+ * dma_set_dst_bus_widths - set supported destination bus widths for a DMA device
+ * @device: DMA device
+ * @widths: array of supported destination bus widths
+ * @n_widths: number of entries in @widths
+ *
+ * Return: 0 on success, -EINVAL if @widths contains an invalid bus width.
+ */
+static inline int dma_set_dst_bus_widths(struct dma_device *device,
+					 const enum dma_slave_buswidth *widths,
+					 unsigned int n_widths)
+{
+	int ret;
+
+	ret = __dma_set_bus_widths(device->dst_bus_widths, widths, n_widths);
+	if (ret)
+		return ret;
+
+	device->dst_addr_widths = bitmap_read(device->dst_bus_widths, 0, 32);
+	return 0;
+}
+
+/**
+ * dma_set_src_bus_width - set a single supported source bus width
+ * @device: DMA device
+ * @width: supported source bus width
+ *
+ * Return: 0 on success, -EINVAL if @width is invalid.
+ */
+static inline int dma_set_src_bus_width(struct dma_device *device,
+					enum dma_slave_buswidth width)
+{
+	return dma_set_src_bus_widths(device, &width, 1);
+}
+
+/**
+ * dma_set_dst_bus_width - set a single supported destination bus width
+ * @device: DMA device
+ * @width: supported destination bus width
+ *
+ * Return: 0 on success, -EINVAL if @width is invalid.
+ */
+static inline int dma_set_dst_bus_width(struct dma_device *device,
+					enum dma_slave_buswidth width)
+{
+	return dma_set_dst_bus_widths(device, &width, 1);
+}
+
 #endif /* DMAENGINE_H */

-- 
2.55.0

