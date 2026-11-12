From: Angel Gabriel Crispin Valdivia <angelcrispinvaldivia@gmail.com>
Date: Wed, 11 Nov 2026 22:34:09 -0500
Subject: [PATCH v2 2/4] drm/fl2000: Add ITE IT66121 HDMI transmitter
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-fl2000-upstream-v2-2-201f87708cb0@gmail.com>
References: <20261111-fl2000-upstream-v2-0-201f87708cb0@gmail.com>
In-Reply-To: <20261111-fl2000-upstream-v2-0-201f87708cb0@gmail.com>
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Angel Gabriel Crispin Valdivia <angelcrispinvaldivia@gmail.com>
Cc: linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794454449; l=40578;
 i=angelcrispinvaldivia@gmail.com; s=20261106; h=from:subject:message-id;
 bh=Be02BkO1Or3symGl9LTgoOh5FC4YQ3xu7REBRVANWMg=;
 b=LYp/QgVm7Ty5zKJWu68QeQn7eBOvUQh2GFHkpfjwtTIOg1Xjwibpyxm+X3dXIFr2rtYYEO8+g
 mn9B+OktwmBClIp6acChDeoGc3dbR3tAqfJoT5aJHMMpKaB9mgdc9+w
X-Developer-Key: i=angelcrispinvaldivia@gmail.com; a=ed25519;
 pk=80bQU/p2R0pLIfdfJaB5I/2obI+RxQHondq5DEM0tbg=
X-Endpoint-Received: by B4 Relay for angelcrispinvaldivia@gmail.com/20261106 with auth_id=1425
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Probe the IT66121 on the FL2000 I2C bus and expose it as a DRM bridge.
It attaches with DRM_BRIDGE_ATTACH_NO_CONNECTOR and reports the hot plug
line and the EDID (DRM_BRIDGE_OP_DETECT and DRM_BRIDGE_OP_EDID), so the
connector is the display driver's. The transmitter (input bus, AFE, AVI
infoframe, HDMI/DVI mode) is programmed in atomic_enable, where the
connector that tells HDMI from DVI is known. The EDID is kept while the
monitor stays, since reading it over USB takes about a second.

The EDID is read at address 0x50 with the FL2000 I2C engine. On the
tested adapter, as on the Fresco Logic reference design, the monitor's
DDC lines are wired to the FL2000 I2C bus, and the IT66121 DDC engine
never completes. It could not work behind this I2C engine anyway, which
transfers aligned dwords: every read of the DDC status register also
pops a byte from the DDC FIFO, which is in the same dword. The HDCP
engine holds that bus after a chip reset, so the driver releases it
once before reading.

The bridge is created and destroyed with the binding of the USB device.
It is guarded with drm_bridge_enter(), since a DRM device that userspace
keeps open after an unplug still has it in its encoder's chain.

Signed-off-by: Angel Gabriel Crispin Valdivia <angelcrispinvaldivia@gmail.com>
---
 drivers/gpu/drm/fl2000/Makefile              |   1 +
 drivers/gpu/drm/fl2000/fl2000_drv.c          |  19 +-
 drivers/gpu/drm/fl2000/fl2000_it66121.c      | 799 +++++++++++++++++++++++++++
 drivers/gpu/drm/fl2000/fl2000_it66121.h      |  18 +
 drivers/gpu/drm/fl2000/fl2000_it66121_regs.h | 284 ++++++++++
 5 files changed, 1120 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/fl2000/Makefile b/drivers/gpu/drm/fl2000/Makefile
index 2b3a2f151..f64057634 100644
--- a/drivers/gpu/drm/fl2000/Makefile
+++ b/drivers/gpu/drm/fl2000/Makefile
@@ -3,6 +3,7 @@
 fl2000-y := \
 	fl2000_drv.o \
 	fl2000_i2c.o \
+	fl2000_it66121.o \
 	fl2000_registers.o
 
 obj-$(CONFIG_DRM_FL2000) += fl2000.o
diff --git a/drivers/gpu/drm/fl2000/fl2000_drv.c b/drivers/gpu/drm/fl2000/fl2000_drv.c
index 8e41de8f5..31d153553 100644
--- a/drivers/gpu/drm/fl2000/fl2000_drv.c
+++ b/drivers/gpu/drm/fl2000/fl2000_drv.c
@@ -5,6 +5,7 @@
  */
 
 #include "fl2000.h"
+#include "fl2000_it66121.h"
 
 #define USB_VENDOR_FRESCO_LOGIC 0x1D5C
 #define USB_PRODUCT_FL2000	0x2000
@@ -33,6 +34,7 @@ MODULE_DEVICE_TABLE(usb, fl2000_id_table);
 struct fl2000_devs {
 	struct regmap *regmap;
 	struct i2c_adapter *adapter;
+	struct drm_bridge *bridge;
 };
 
 /* Interface 0 is what the driver is probing: claim the others */
@@ -102,13 +104,26 @@ static int fl2000_probe(struct usb_interface *interface, const struct usb_device
 		return PTR_ERR(devs->adapter);
 	}
 
+	/* The IT66121 is looked for with the I2C engine, ready as for reading the EDID */
+	fl2000_reset(devs->regmap);
+	fl2000_usb_magic(devs->regmap);
+
+	devs->bridge = it66121_create(devs->adapter);
+	if (IS_ERR(devs->bridge))
+		return PTR_ERR(devs->bridge);
+
 	ret = fl2000_claim_interfaces(usb_dev, devs);
 	if (ret)
-		return ret;
+		goto err_destroy_bridge;
 
 	usb_set_intfdata(interface, devs);
 
 	return 0;
+
+err_destroy_bridge:
+	it66121_destroy(devs->bridge);
+
+	return ret;
 }
 
 static void fl2000_disconnect(struct usb_interface *interface)
@@ -123,6 +138,8 @@ static void fl2000_disconnect(struct usb_interface *interface)
 	for (int i = 0; i < FL2000_USBIF_NUM; i++)
 		usb_set_intfdata(usb_ifnum_to_if(usb_dev, i), NULL);
 
+	it66121_destroy(devs->bridge);
+
 	/* Last, as devs goes with interface 0, which may be one of these */
 	fl2000_release_interfaces(usb_dev, interface);
 }
diff --git a/drivers/gpu/drm/fl2000/fl2000_it66121.c b/drivers/gpu/drm/fl2000/fl2000_it66121.c
new file mode 100644
index 000000000..7235317b0
--- /dev/null
+++ b/drivers/gpu/drm/fl2000/fl2000_it66121.c
@@ -0,0 +1,799 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * (C) Copyright 2017, Fresco Logic, Incorporated.
+ * (C) Copyright 2018-2019, Artem Mygaiev
+ */
+
+#include <linux/delay.h>
+#include <linux/hdmi.h>
+#include <linux/unaligned.h>
+
+#include <drm/drm_atomic_state_helper.h>
+#include <drm/drm_edid.h>
+
+#include "fl2000.h"
+#include "fl2000_it66121.h"
+#include "fl2000_it66121_regs.h"
+
+#define VENDOR_ID      0x4954
+#define DEVICE_ID      0x0612
+#define REVISION_MASK  0xF000
+#define REVISION_SHIFT 12
+
+/* How often, and how far apart, to look for the chip on the bus */
+#define IT66121_DETECT_TRIES	5
+#define IT66121_DETECT_DELAY_MS	50
+
+struct it66121_priv {
+	struct i2c_adapter *adapter;
+	struct i2c_client *client;
+	struct regmap *regmap;
+	struct drm_bridge bridge;
+
+	/* The chip was reset and its HDCP engine may be holding the DDC bus */
+	bool ddc_held;
+
+	struct regmap_field *irq_pending;
+	struct regmap_field *hpd;
+	struct regmap_field *clr_irq;
+};
+
+static const struct regmap_range_cfg it66121_regmap_banks[] = {
+	/*
+	 * Do not put common registers to any range, this will lead to skipping "bank" configuration
+	 * when accessing those at addresses 0x00-0x2F.
+	 */
+	{
+		.name = "Banks",
+		.range_min = IT66121_BANK_START,
+		.range_max = IT66121_BANK_END,
+		.selector_reg = IT66121_SYS_CONTROL,
+		.selector_mask = IT66121_SYS_BANK_MASK,
+		.selector_shift = 0,
+		.window_start = IT66121_BANK_START,
+		.window_len = IT66121_BANK_SIZE,
+	},
+};
+
+static bool it66121_reg_volatile(struct device *dev, unsigned int reg)
+{
+	return IT66121_REG_VOLATILE(reg);
+}
+
+static const struct regmap_config it66121_regmap_config = {
+	.val_bits = 8, /* 8-bit register size */
+	.reg_bits = 8, /* 8-bit register address space */
+	.reg_stride = 1,
+	.max_register = 2 * IT66121_BANK_SIZE - 1, /* 2 banks of registers */
+
+	.cache_type = REGCACHE_MAPLE,
+
+	.volatile_reg = it66121_reg_volatile,
+
+	.ranges = it66121_regmap_banks,
+	.num_ranges = ARRAY_SIZE(it66121_regmap_banks),
+
+	.reg_format_endian = REGMAP_ENDIAN_BIG,
+	.val_format_endian = REGMAP_ENDIAN_BIG,
+
+	.use_single_read = true,
+	.use_single_write = true,
+};
+
+/*
+ * Poll sparsely: every status read is a transaction on the shared bus that
+ * competes with the DDC engine's own transfer.
+ */
+#define DDC_POLL_SLEEP_US   5000
+#define DDC_POLL_TIMEOUT_US 500000
+
+#define DDC_CMD_ABORT 0xF
+
+static int it66121_configure_input(struct it66121_priv *priv)
+{
+	int ret;
+
+	/*
+	 * This configures the bridge IC connection to the encoder IC, i.e. the
+	 * interface between IT66121 and FL2000. It is fixed by the board design,
+	 * so it is hardcoded:
+	 *   - input mode RGB
+	 *   - IO latch clock = TXCLK
+	 *   - CCIR656 disabled
+	 *   - embedded sync disabled
+	 *   - DDR mode disabled
+	 *   - 1 cycle input PCLK delay
+	 */
+	ret = regmap_write(priv->regmap, IT66121_INPUT_MODE,
+			   IT66121_INPUT_MODE_RGB | IT66121_INPUT_PCLKDELAY1);
+	if (ret)
+		return ret;
+
+	/*
+	 * No color space conversion: the input is RGB and so is the output, so the
+	 * conversion matrix and blank levels are left untouched.
+	 */
+	ret = regmap_write(priv->regmap, IT66121_INPUT_COLOR_CONV, IT66121_INPUT_NO_CONV);
+	if (ret)
+		return ret;
+
+	return 0;
+}
+
+static int it66121_configure_afe(struct it66121_priv *priv, int clock_khz)
+{
+	int ret;
+
+	ret = regmap_write(priv->regmap, IT66121_AFE_DRV_CONTROL, IT66121_AFE_RST);
+	if (ret)
+		return ret;
+
+	/* Values from the vendor reference driver, the bits are undocumented */
+	if (clock_khz > 80000) {
+		ret = regmap_write_bits(priv->regmap, IT66121_AFE_XP_CONTROL, 0x90, 0x80);
+		if (ret)
+			return ret;
+		ret = regmap_write_bits(priv->regmap, IT66121_AFE_IP_CONTROL_1, 0x89, 0x80);
+		if (ret)
+			return ret;
+		ret = regmap_write_bits(priv->regmap, IT66121_AFE_IP_CONTROL_3, 0x10, 0);
+		if (ret)
+			return ret;
+	} else {
+		ret = regmap_write_bits(priv->regmap, IT66121_AFE_XP_CONTROL, 0x90, 0x10);
+		if (ret)
+			return ret;
+		ret = regmap_write_bits(priv->regmap, IT66121_AFE_IP_CONTROL_1, 0x89, 0x09);
+		if (ret)
+			return ret;
+		ret = regmap_write_bits(priv->regmap, IT66121_AFE_IP_CONTROL_3, 0x10, 0x10);
+		if (ret)
+			return ret;
+	}
+
+	/* Fire AFE */
+	ret = regmap_write(priv->regmap, IT66121_AFE_DRV_CONTROL, 0);
+	if (ret)
+		return ret;
+
+	return 0;
+}
+
+/* DDC status bits: done (7), active (6), noack/wait bus/arbitration lose (5:3) */
+#define DDC_STATUS_TX_DONE BIT(7)
+
+static int it66121_wait_ddc_ready(struct it66121_priv *priv)
+{
+	unsigned int val = 0;
+	int ret;
+
+	/*
+	 * Wait for completion only. On this hardware the FL2000 I2C master and
+	 * the IT66121 DDC master share the physical bus, so 'wait bus' and
+	 * 'arbitration lose' flags are live/latched transients of the engine
+	 * retrying on a contended bus, not terminal errors - the only reliable
+	 * terminal signal is TX_DONE (or the timeout).
+	 */
+	ret = regmap_read_poll_timeout(priv->regmap, IT66121_DDC_STATUS, val,
+				       val & DDC_STATUS_TX_DONE, DDC_POLL_SLEEP_US,
+				       DDC_POLL_TIMEOUT_US);
+	if (ret)
+		dev_dbg(&priv->client->dev, "DDC not done (%d), status 0x%02X\n", ret, val);
+
+	return ret;
+}
+
+/*
+ * The HDCP engine shares the DDC master and holds the bus after chip reset (DDC status reports
+ * 'wait bus' + 'arbitration lose', 0x1A), and that bus is the one the monitor's DDC is on. Follow
+ * the ITE reference sequence, as the ite-it66121 driver does: clear HDCP CP_DESIRE, reset the HDCP
+ * engine and re-select the host as DDC master before issuing the abort command.
+ */
+static int it66121_release_ddc(struct it66121_priv *priv)
+{
+	int ret;
+
+	ret = regmap_write_bits(priv->regmap, IT66121_HDCP_CONTROL, IT66121_HDCP_CP_DESIRE, 0);
+	if (ret)
+		return ret;
+
+	ret = regmap_write_bits(priv->regmap, IT66121_SW_RST, IT66121_SW_HDCP_RST,
+				IT66121_SW_HDCP_RST);
+	if (ret)
+		return ret;
+
+	ret = regmap_write(priv->regmap, IT66121_DDC_CONTROL,
+			   IT66121_DDC_MASTER_DDC | IT66121_DDC_MASTER_HOST);
+	if (ret)
+		return ret;
+
+	/* The ITE reference driver issues the abort command twice */
+	for (int i = 0; i < 2; i++) {
+		ret = regmap_write(priv->regmap, IT66121_DDC_COMMAND, DDC_CMD_ABORT);
+		if (ret)
+			return ret;
+
+		ret = it66121_wait_ddc_ready(priv);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+/**
+ * it66121_hpd_connected() - live state of the HDMI hot plug detect line
+ * @bridge: the IT66121 bridge
+ *
+ * Return: 1 if an HDMI monitor is connected, 0 if not, a negative error code if the line cannot
+ * be read
+ */
+int it66121_hpd_connected(struct drm_bridge *bridge)
+{
+	struct it66121_priv *priv = container_of(bridge, struct it66121_priv, bridge);
+	unsigned int val;
+	int idx, ret;
+
+	if (!drm_bridge_enter(bridge, &idx))
+		return -ENODEV;
+
+	ret = regmap_field_read(priv->hpd, &val);
+	drm_bridge_exit(idx);
+	if (ret)
+		return ret;
+
+	return !!val;
+}
+
+/**
+ * it66121_ack_interrupts() - acknowledge what is pending in the IT66121
+ * @bridge: the IT66121 bridge
+ *
+ * Its interrupt line is routed to the FL2000, which reports it on its own interrupt endpoint (see
+ * fl2000_interrupt.c): called from there, and hotplug is handled by probing the connector. The
+ * interrupt sources themselves are not decoded here. An interrupt left pending would keep the line
+ * from changing again.
+ *
+ * Return: 0 on success, a negative error code otherwise
+ */
+int it66121_ack_interrupts(struct drm_bridge *bridge)
+{
+	struct it66121_priv *priv = container_of(bridge, struct it66121_priv, bridge);
+	unsigned int val;
+	int ret;
+
+	ret = regmap_field_read(priv->irq_pending, &val);
+	if (ret || !val)
+		return ret;
+
+	ret = regmap_read(priv->regmap, IT66121_INT_STATUS_1, &val);
+	if (ret)
+		return ret;
+
+	/* The only two sources with the same bit in both registers, and the only ones unmasked */
+	val &= IT66121_INT_STATUS_1_HPD | IT66121_INT_STATUS_1_RX_SENSE;
+	if (val) {
+		ret = regmap_write(priv->regmap, IT66121_INT_CLEAR_1, val);
+		if (ret)
+			return ret;
+	}
+
+	/* Forced: when the bit happens to read as set, a plain update would not write it */
+	return regmap_field_force_write(priv->clr_irq, 1);
+}
+
+/*
+ * The EDID is read with the FL2000's own I2C engine. On the Fresco reference designs the monitor's
+ * DDC lines hang off the FL2000 I2C bus and the vendor driver reads the EDID at address 0x50 this
+ * way. The IT66121's own EDID command cannot be used: it never completes on these boards, and
+ * could not work behind this I2C engine anyway, which transfers aligned dwords: every read of the
+ * DDC status register (0x16) also reads, and so pops, the DDC FIFO (0x17).
+ */
+static int it66121_get_edid_block(void *context, u8 *buf, unsigned int block, size_t len)
+{
+	struct it66121_priv *priv = context;
+	int ret;
+
+	ret = fl2000_ddc_read_block(priv->adapter, buf, block, len);
+	if (ret)
+		dev_dbg(&priv->client->dev, "EDID block %u read failed (%d)\n", block, ret);
+
+	return ret;
+}
+
+static enum drm_connector_status it66121_bridge_detect(struct drm_bridge *bridge,
+						       struct drm_connector *connector)
+{
+	struct it66121_priv *priv = container_of(bridge, struct it66121_priv, bridge);
+	int ret = it66121_hpd_connected(bridge);
+
+	if (ret > 0)
+		return connector_status_connected;
+
+	/* Gone with the USB device */
+	if (ret == -ENODEV)
+		return connector_status_disconnected;
+
+	if (ret < 0) {
+		/* Not bridge->dev: the chip, not the DRM device, failed to answer */
+		dev_err_ratelimited(&priv->client->dev, "Cannot get monitor status (%d)\n", ret);
+		return connector_status_unknown;
+	}
+
+	return connector_status_disconnected;
+}
+
+static const struct drm_edid *it66121_bridge_edid_read(struct drm_bridge *bridge,
+						       struct drm_connector *connector)
+{
+	struct it66121_priv *priv = container_of(bridge, struct it66121_priv, bridge);
+	const struct drm_edid *drm_edid;
+	int idx, ret;
+
+	if (!drm_bridge_enter(bridge, &idx))
+		return NULL;
+
+	if (priv->ddc_held) {
+		/* Not fatal: the read tells whether the bus is free */
+		ret = it66121_release_ddc(priv);
+		if (ret)
+			dev_dbg(&priv->client->dev, "Cannot release the DDC bus (%d)\n", ret);
+		priv->ddc_held = false;
+	}
+
+	drm_edid = drm_edid_read_custom(connector, it66121_get_edid_block, priv);
+	if (!drm_edid)
+		dev_warn(&priv->client->dev, "EDID read failed, using fallback modes\n");
+
+	drm_bridge_exit(idx);
+
+	return drm_edid;
+}
+
+/*
+ * Bring the transmitter out of reset into a known state, as the IT66121 manual and the vendor
+ * driver do: at attach, and again after system sleep, which may have cut the power.
+ */
+static void it66121_init_chip(struct it66121_priv *priv)
+{
+	/* Reset according to IT66121 manual */
+	regmap_write_bits(priv->regmap, IT66121_SW_RST, IT66121_SW_REF_RST_HDMITX,
+			  IT66121_SW_REF_RST_HDMITX);
+	msleep(50);
+
+	/* Power up GRCLK & power down IACLK, TxCLK, CRCLK */
+	regmap_write_bits(priv->regmap, IT66121_SYS_CONTROL, (0xf << 3), (7 << 3));
+
+	/* Continue according to IT66121 manual */
+	regmap_write_bits(priv->regmap, IT66121_INT_CONTROL, (1 << 0), (0 << 0));
+	regmap_write_bits(priv->regmap, IT66121_AFE_DRV_CONTROL, (1 << 5), (0 << 5));
+	regmap_write_bits(priv->regmap, IT66121_AFE_XP_CONTROL, (1 << 2) | (1 << 6),
+			  (0 << 2) | (0 << 6));
+	regmap_write_bits(priv->regmap, IT66121_AFE_IP_CONTROL_1, (1 << 6), (0 << 6));
+	regmap_write_bits(priv->regmap, IT66121_AFE_DRV_CONTROL, (1 << 4), (0 << 4));
+	regmap_write_bits(priv->regmap, IT66121_AFE_XP_CONTROL, (1 << 3), (1 << 3));
+	regmap_write_bits(priv->regmap, IT66121_AFE_IP_CONTROL_1, (1 << 2), (1 << 2));
+
+	/* Extra AFE steps from the vendor driver */
+	/* Whole register is defined as XP_TEST, values are undisclosed */
+	regmap_write_bits(priv->regmap, IT66121_AFE_XP_TEST, 0xFF, 0x70);
+	/* Lower 5 bits are undisclosed in manual */
+	regmap_write_bits(priv->regmap, IT66121_AFE_DRV_HS, 0xFF, 0x1F);
+	/*
+	 * DRV_ISW[5:3] value '011' is a default output current level swing, with change to '111' we
+	 * set output current level swing to maximum.
+	 */
+	regmap_write_bits(priv->regmap, IT66121_AFE_IP_CONTROL_2, 0xFF, 0x38);
+
+	/* Power up IACLK, TxCLK */
+	regmap_write_bits(priv->regmap, IT66121_SYS_CONTROL, (3 << 4), (0 << 4));
+
+	/* Reset according to IT66121 manual */
+	regmap_write_bits(priv->regmap, IT66121_SW_RST, IT66121_SW_REF_RST_HDMITX,
+			  IT66121_SW_REF_RST_HDMITX);
+	msleep(50);
+
+	/* We do not support HDCP so its ok to statically set host controls */
+	regmap_write(priv->regmap, IT66121_DDC_CONTROL,
+		     IT66121_DDC_MASTER_DDC | IT66121_DDC_MASTER_HOST);
+
+	priv->ddc_held = true;
+}
+
+/*
+ * Unmask the hot plug interrupt, the one that means something here. DDC errors have nobody to read
+ * them: the DDC engine is not used.
+ */
+static void it66121_start_interrupts(struct it66121_priv *priv)
+{
+	regmap_write_bits(priv->regmap, IT66121_INT_MASK_1, IT66121_MASK_DDC | IT66121_MASK_HPD,
+			  IT66121_MASK_DDC);
+	it66121_ack_interrupts(&priv->bridge);
+}
+
+static int it66121_bridge_attach(struct drm_bridge *bridge, struct drm_encoder *encoder,
+				 enum drm_bridge_attach_flags flags)
+{
+	struct it66121_priv *priv = container_of(bridge, struct it66121_priv, bridge);
+
+	/* The connector is the display driver's (drm_bridge_connector_init()) */
+	if (!(flags & DRM_BRIDGE_ATTACH_NO_CONNECTOR)) {
+		drm_err(bridge->dev, "The IT66121 bridge does not create a connector\n");
+		return -EINVAL;
+	}
+
+	if (!bridge->encoder) {
+		drm_err(bridge->dev, "Parent encoder object not found\n");
+		return -ENODEV;
+	}
+
+	it66121_init_chip(priv);
+
+	it66121_start_interrupts(priv);
+
+	drm_dbg(bridge->dev, "Bridge attached\n");
+
+	return 0;
+}
+
+/**
+ * it66121_resume() - set the IT66121 up again after system sleep
+ * @bridge: the IT66121 bridge
+ *
+ * The dongle is bus powered, and the test laptop resets its USB devices when it wakes from
+ * suspend to RAM: the chip may have lost every register. The register cache would then be wrong,
+ * and the read-modify-write updates of the initialisation would skip writes the chip still needs:
+ * drop it, so that values are read from the chip again. The mode is set again by the DRM core.
+ */
+void it66121_resume(struct drm_bridge *bridge)
+{
+	struct it66121_priv *priv = container_of(bridge, struct it66121_priv, bridge);
+
+	regcache_drop_region(priv->regmap, 0, it66121_regmap_config.max_register);
+	it66121_init_chip(priv);
+	it66121_start_interrupts(priv);
+}
+
+/*
+ * Program the transmitter for @mode, as the monitor behind @connector wants it (HDMI, or DVI when
+ * its EDID says so or there is none). The FL2000 already clocks the input at this point.
+ */
+static void it66121_set_mode(struct it66121_priv *priv, struct drm_connector *connector,
+			     const struct drm_display_mode *mode)
+{
+	struct drm_bridge *bridge = &priv->bridge;
+	bool dvi = !connector->display_info.is_hdmi;
+	struct hdmi_avi_infoframe frame;
+	ssize_t frame_size;
+	u8 buf[HDMI_INFOFRAME_SIZE(AVI)];
+	int ret;
+	const u16 aviinfo_reg[HDMI_AVI_INFOFRAME_SIZE] = {
+		IT66121_HDMI_AVIINFO_DB1,  IT66121_HDMI_AVIINFO_DB2,  IT66121_HDMI_AVIINFO_DB3,
+		IT66121_HDMI_AVIINFO_DB4,  IT66121_HDMI_AVIINFO_DB5,  IT66121_HDMI_AVIINFO_DB6,
+		IT66121_HDMI_AVIINFO_DB7,  IT66121_HDMI_AVIINFO_DB8,  IT66121_HDMI_AVIINFO_DB9,
+		IT66121_HDMI_AVIINFO_DB10, IT66121_HDMI_AVIINFO_DB11, IT66121_HDMI_AVIINFO_DB12,
+		IT66121_HDMI_AVIINFO_DB13
+	};
+
+	drm_dbg(bridge->dev, "Setting %s mode " DRM_MODE_FMT "\n", dvi ? "DVI" : "HDMI",
+		DRM_MODE_ARG(mode));
+
+	ret = drm_hdmi_avi_infoframe_from_display_mode(&frame, connector, mode);
+	if (ret) {
+		drm_err(bridge->dev, "Cannot create AVI infoframe (%d)\n", ret);
+		return;
+	}
+
+	frame_size = hdmi_avi_infoframe_pack(&frame, buf, sizeof(buf));
+	if (frame_size < 0) {
+		drm_err(bridge->dev, "Cannot pack AVI infoframe (%zd)\n", frame_size);
+		return;
+	}
+
+	/* Set TX mode */
+	ret = regmap_write(priv->regmap, IT66121_HDMI_MODE,
+			   dvi ? IT66121_HDMI_MODE_DVI : IT66121_HDMI_MODE_HDMI);
+	if (ret) {
+		drm_err(bridge->dev, "Cannot set TX mode (%d)\n", ret);
+		return;
+	}
+
+	/* Enable HDMI packets, repeat for every data frame as recommended */
+	ret = regmap_write(priv->regmap, IT66121_HDMI_GEN_CTRL_PKT,
+			   IT66121_HDMI_GEN_CTRL_PKT_ON | IT66121_HDMI_GEN_CTRL_PKT_RPT);
+	if (ret) {
+		drm_err(bridge->dev, "Cannot enable HDMI packets\n");
+		return;
+	}
+
+	/* Mute AV */
+	ret = regmap_write(priv->regmap, IT66121_HDMI_AV_MUTE,
+			   IT66121_HDMI_AV_MUTE_ON | IT66121_HDMI_AV_MUTE_BLUE);
+	if (ret) {
+		drm_err(bridge->dev, "Cannot mute AV\n");
+		return;
+	}
+
+	/* Write new AVI infoframe packet */
+	for (int i = 0; i < HDMI_AVI_INFOFRAME_SIZE; i++) {
+		ret = regmap_write(priv->regmap, aviinfo_reg[i],
+				   buf[i + HDMI_INFOFRAME_HEADER_SIZE]);
+		if (ret) {
+			drm_err(bridge->dev, "Cannot write AVI infoframe byte %d (%d)\n", i, ret);
+			return;
+		}
+	}
+	ret = regmap_write(priv->regmap, IT66121_HDMI_AVIINFO_CSUM, buf[3]);
+	if (ret) {
+		drm_err(bridge->dev, "Cannot write AVI infoframe checksum (%d)\n", ret);
+		return;
+	}
+
+	/* Enable AVI infoframe */
+	ret = regmap_write(priv->regmap, IT66121_HDMI_AVI_INFO_PKT,
+			   IT66121_HDMI_AVI_INFO_PKT_ON | IT66121_HDMI_AVI_INFO_RPT);
+	if (ret) {
+		drm_err(bridge->dev, "Cannot enable AVI infoframe (%d)\n", ret);
+		return;
+	}
+
+	/* Set reset flags */
+	ret = regmap_write_bits(priv->regmap, IT66121_SW_RST,
+				IT66121_SW_REF_RST_HDMITX | IT66121_SW_HDMI_VID_RST,
+				IT66121_SW_REF_RST_HDMITX | IT66121_SW_HDMI_VID_RST);
+	if (ret)
+		return;
+
+	/* Disable TXCLK prior to configuration */
+	ret = regmap_write_bits(priv->regmap, IT66121_SYS_CONTROL, IT66121_SYS_TXCLK_OFF,
+				IT66121_SYS_TXCLK_OFF);
+	if (ret)
+		return;
+
+	/* Configure connection, conversions, etc. */
+	ret = it66121_configure_input(priv);
+	if (ret) {
+		drm_err(bridge->dev, "Cannot configure input bus (%d)\n", ret);
+		return;
+	}
+
+	/* Configure AFE */
+	ret = it66121_configure_afe(priv, mode->clock);
+	if (ret) {
+		drm_err(bridge->dev, "Cannot configure AFE (%d)\n", ret);
+		return;
+	}
+
+	/* Clear reset flags */
+	ret = regmap_write_bits(priv->regmap, IT66121_SW_RST,
+				IT66121_SW_REF_RST_HDMITX | IT66121_SW_HDMI_VID_RST, 0);
+	if (ret)
+		return;
+
+	/* Enable TXCLK */
+	ret = regmap_write_bits(priv->regmap, IT66121_SYS_CONTROL, IT66121_SYS_TXCLK_OFF, 0);
+	if (ret)
+		return;
+}
+
+/*
+ * The mode is programmed here rather than in .mode_set, which has no atomic state: the connector,
+ * which tells HDMI from DVI and goes into the AVI infoframe, is only known from the state.
+ */
+static void it66121_bridge_atomic_enable(struct drm_bridge *bridge,
+					 struct drm_atomic_commit *state)
+{
+	struct it66121_priv *priv = container_of(bridge, struct it66121_priv, bridge);
+	const struct drm_connector_state *conn_state;
+	const struct drm_crtc_state *crtc_state;
+	struct drm_connector *connector;
+	int idx;
+
+	connector = drm_atomic_get_new_connector_for_encoder(state, bridge->encoder);
+	if (WARN_ON(!connector))
+		return;
+
+	conn_state = drm_atomic_get_new_connector_state(state, connector);
+	if (WARN_ON(!conn_state || !conn_state->crtc))
+		return;
+
+	crtc_state = drm_atomic_get_new_crtc_state(state, conn_state->crtc);
+	if (WARN_ON(!crtc_state))
+		return;
+
+	if (!drm_bridge_enter(bridge, &idx))
+		return;
+
+	it66121_set_mode(priv, connector, &crtc_state->mode);
+
+	/* Unmute AV */
+	regmap_write(priv->regmap, IT66121_HDMI_AV_MUTE, 0);
+
+	drm_bridge_exit(idx);
+}
+
+static void it66121_bridge_atomic_disable(struct drm_bridge *bridge,
+					  struct drm_atomic_commit *state)
+{
+	struct it66121_priv *priv = container_of(bridge, struct it66121_priv, bridge);
+	int idx;
+
+	if (!drm_bridge_enter(bridge, &idx))
+		return;
+
+	/* Mute AV */
+	regmap_write_bits(priv->regmap, IT66121_HDMI_AV_MUTE, IT66121_HDMI_AV_MUTE_ON,
+			  IT66121_HDMI_AV_MUTE_ON);
+
+	drm_bridge_exit(idx);
+}
+
+static const struct drm_bridge_funcs it66121_bridge_funcs = {
+	.attach = it66121_bridge_attach,
+	.atomic_create_state = drm_atomic_helper_bridge_create_state,
+	.atomic_duplicate_state = drm_atomic_helper_bridge_duplicate_state,
+	.atomic_destroy_state = drm_atomic_helper_bridge_destroy_state,
+	.atomic_enable = it66121_bridge_atomic_enable,
+	.atomic_disable = it66121_bridge_atomic_disable,
+	.detect = it66121_bridge_detect,
+	.edid_read = it66121_bridge_edid_read,
+};
+
+static int it66121_regs_init(struct it66121_priv *priv, struct i2c_client *client)
+{
+	priv->regmap = devm_regmap_init_i2c(client, &it66121_regmap_config);
+	if (IS_ERR(priv->regmap))
+		return PTR_ERR(priv->regmap);
+
+	priv->irq_pending =
+		devm_regmap_field_alloc(&client->dev, priv->regmap, IT66121_SYS_STATUS_irq_pending);
+	priv->hpd = devm_regmap_field_alloc(&client->dev, priv->regmap, IT66121_SYS_STATUS_hpd);
+	priv->clr_irq =
+		devm_regmap_field_alloc(&client->dev, priv->regmap, IT66121_SYS_STATUS_clr_irq);
+	if (IS_ERR(priv->irq_pending) || IS_ERR(priv->hpd) || IS_ERR(priv->clr_irq))
+		return -ENOMEM;
+
+	return 0;
+}
+
+/*
+ * The callback of i2c_new_scanned_device(): nonzero if the device is there. It reads the IDs with
+ * the same transfers as the regmap, which is all this adapter can do (see its quirks).
+ */
+static int it66121_i2c_probe(struct i2c_adapter *adapter, unsigned short address)
+{
+	int ret;
+	u8 id_regs[] = { IT66121_VENDOR_ID_1, IT66121_VENDOR_ID_2, IT66121_DEVICE_ID_1,
+			 IT66121_DEVICE_ID_2 };
+	u8 id[ARRAY_SIZE(id_regs)];
+	u16 vendor, device;
+
+	dev_dbg(&adapter->dev, "Detecting IT66121 at address 0x%X on %s\n", address,
+		adapter->name);
+
+	for (int i = 0; i < ARRAY_SIZE(id_regs); i++) {
+		struct i2c_msg msgs[] = {
+			{ .addr = address, .flags = 0, .len = 1, .buf = &id_regs[i] },
+			{ .addr = address, .flags = I2C_M_RD, .len = 1, .buf = &id[i] }
+		};
+
+		ret = i2c_transfer(adapter, msgs, ARRAY_SIZE(msgs));
+		if (ret != ARRAY_SIZE(msgs)) {
+			dev_dbg(&adapter->dev, "No answer at address 0x%X (%d)\n", address, ret);
+			return 0;
+		}
+	}
+
+	vendor = get_unaligned_le16(&id[0]);
+	device = get_unaligned_le16(&id[2]);
+	if (vendor != VENDOR_ID || (device & ~REVISION_MASK) != DEVICE_ID) {
+		dev_warn(&adapter->dev, "Not an IT66121 at address 0x%X (0x%04X-0x%04X)\n", address,
+			 vendor, device);
+		return 0;
+	}
+
+	dev_dbg(&adapter->dev, "IT66121 found, revision %d\n",
+		(device & REVISION_MASK) >> REVISION_SHIFT);
+
+	return 1;
+}
+
+static struct i2c_client *it66121_i2c_init(struct i2c_adapter *adapter)
+{
+	/*
+	 * Not "it66121": that name would make the ite-it66121 driver, if built,
+	 * try to bind this client and release our devres when its probe fails.
+	 */
+	struct i2c_board_info board_info = { I2C_BOARD_INFO("fl2000-it66121", 0) };
+
+	/* According to datasheet IT66121 addresses are 0x98 or 0x9A including cmd */
+	const unsigned short it66121_addr[] = { (0x98 >> 1), (0x9A >> 1), I2C_CLIENT_END };
+	struct i2c_client *client;
+
+	/* The chip may still be waking up when the USB device has just enumerated */
+	for (int i = 0; i < IT66121_DETECT_TRIES; i++) {
+		if (i)
+			msleep(IT66121_DETECT_DELAY_MS);
+
+		client = i2c_new_scanned_device(adapter, &board_info, it66121_addr,
+						it66121_i2c_probe);
+		if (!IS_ERR(client))
+			break;
+	}
+
+	return client;
+}
+
+/**
+ * it66121_destroy() - remove the bridge
+ * @bridge: the IT66121 bridge
+ *
+ * A DRM device that userspace keeps open still has the bridge in its encoder's chain, and frees it
+ * with the last reference, but nothing gets past drm_bridge_enter() any more.
+ */
+void it66121_destroy(struct drm_bridge *bridge)
+{
+	struct it66121_priv *priv = container_of(bridge, struct it66121_priv, bridge);
+
+	drm_bridge_unplug(bridge);
+
+	/*
+	 * Releases what is managed on the client, its regmap included, and drops the devm reference
+	 * to the bridge.
+	 */
+	i2c_unregister_device(priv->client);
+}
+
+/**
+ * it66121_create() - find the IT66121 on the FL2000 I2C bus and make a bridge of it
+ * @adapter: the FL2000 I2C adapter
+ *
+ * Return: the bridge, to attach to the encoder, or an ERR_PTR() on failure
+ */
+struct drm_bridge *it66121_create(struct i2c_adapter *adapter)
+{
+	int ret;
+	struct it66121_priv *priv;
+	struct i2c_client *client;
+
+	client = it66121_i2c_init(adapter);
+	if (IS_ERR(client)) {
+		dev_err(&adapter->dev, "No IT66121 found (%pe): adapters without one are not supported\n",
+			client);
+		return ERR_CAST(client);
+	}
+
+	/*
+	 * DRM core takes references on the bridge, so it must be allocated with
+	 * devm_drm_bridge_alloc(). Freeing happens automatically when the last
+	 * reference is dropped after i2c_unregister_device().
+	 */
+	priv = devm_drm_bridge_alloc(&client->dev, struct it66121_priv, bridge,
+				     &it66121_bridge_funcs);
+	if (IS_ERR(priv)) {
+		i2c_unregister_device(client);
+		return ERR_CAST(priv);
+	}
+
+	priv->client = client;
+	priv->adapter = adapter;
+
+	ret = it66121_regs_init(priv, priv->client);
+	if (ret) {
+		dev_err(&client->dev, "Cannot initialize registers (%d)\n", ret);
+		i2c_unregister_device(client);
+		return ERR_PTR(ret);
+	}
+
+	/*
+	 * The chip's interrupt reaches the host only through the FL2000's, which sends a hotplug
+	 * event for the whole device (fl2000_drm_hotplug()). The bridge therefore reports no hot
+	 * plug of its own (DRM_BRIDGE_OP_HPD), and the connector also polls the line.
+	 */
+	priv->bridge.type = DRM_MODE_CONNECTOR_HDMIA;
+	priv->bridge.ops = DRM_BRIDGE_OP_DETECT | DRM_BRIDGE_OP_EDID;
+
+	drm_bridge_add(&priv->bridge);
+
+	return &priv->bridge;
+}
diff --git a/drivers/gpu/drm/fl2000/fl2000_it66121.h b/drivers/gpu/drm/fl2000/fl2000_it66121.h
new file mode 100644
index 000000000..568d3cd60
--- /dev/null
+++ b/drivers/gpu/drm/fl2000/fl2000_it66121.h
@@ -0,0 +1,18 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * (C) Copyright 2019, Artem Mygaiev
+ */
+
+#ifndef FL2000_IT66121_H
+#define FL2000_IT66121_H
+
+struct drm_bridge;
+struct i2c_adapter;
+
+struct drm_bridge *it66121_create(struct i2c_adapter *adapter);
+void it66121_destroy(struct drm_bridge *bridge);
+int it66121_hpd_connected(struct drm_bridge *bridge);
+int it66121_ack_interrupts(struct drm_bridge *bridge);
+void it66121_resume(struct drm_bridge *bridge);
+
+#endif /* FL2000_IT66121_H */
diff --git a/drivers/gpu/drm/fl2000/fl2000_it66121_regs.h b/drivers/gpu/drm/fl2000/fl2000_it66121_regs.h
new file mode 100644
index 000000000..de784cd71
--- /dev/null
+++ b/drivers/gpu/drm/fl2000/fl2000_it66121_regs.h
@@ -0,0 +1,284 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Based on the un-official documentation found on the net and registers
+ * description from source code:
+ *  - FL2000DX Linux driver on GitHub
+ *  - RK3188 Android driver on GitHub
+ *
+ * (C) Copyright 2019, Artem Mygaiev
+ */
+
+#ifndef FL2000_IT66121_REGS_H
+#define FL2000_IT66121_REGS_H
+
+#define IT66121_BANK_SIZE 0x100
+
+/* 000 - 02F Common registers, same as 100 - 12F */
+#define IT66121_VENDOR_ID_1	  0x00
+#define IT66121_VENDOR_ID_2	  0x01
+#define IT66121_DEVICE_ID_1	  0x02
+#define IT66121_DEVICE_ID_2	  0x03
+#define IT66121_SW_RST		  0x04
+#define IT66121_SW_ENTEST	  BIT(7)
+#define IT66121_SW_REF_RST_HDMITX BIT(5)
+#define IT66121_SW_AREF_RST	  BIT(4)
+#define IT66121_SW_HDMI_VID_RST	  BIT(3)
+#define IT66121_SW_HDMI_AUD_RST	  BIT(2)
+#define IT66121_SW_HDMI_RST	  BIT(1)
+#define IT66121_SW_HDCP_RST	  BIT(0)
+
+#define IT66121_INT_CONTROL  0x05
+#define IT66121_INT_STATUS_1 0x06
+#define IT66121_INT_STATUS_1_HPD		BIT(0)
+#define IT66121_INT_STATUS_1_RX_SENSE		BIT(1)
+#define IT66121_INT_STATUS_1_DDC_BUS_HANG	BIT(2)
+#define IT66121_INT_STATUS_1_ROMACQ_BUS_HANG	BIT(3)
+#define IT66121_INT_STATUS_1_DDC_FIFO_ERR	BIT(4)
+#define IT66121_INT_STATUS_1_DDC_NOACK		BIT(5)
+#define IT66121_INT_STATUS_1_ROMACQ_NOACK	BIT(6)
+#define IT66121_INT_STATUS_1_AUD_OVERFLOW	BIT(7)
+
+#define IT66121_INT_STATUS_2	 0x07
+#define IT66121_INT_STATUS_3	 0x08
+#define IT66121_INT_MASK_1	 0x09
+#define IT66121_MASK_DDC_NOACK	 BIT(5)
+#define IT66121_MASK_DDC_FIFOERR BIT(4)
+#define IT66121_MASK_DDC_BUSHANG BIT(2)
+#define IT66121_MASK_DDC	 GENMASK(5, 2)
+#define IT66121_MASK_HPD	 BIT(0)
+
+#define IT66121_INT_MASK_2  0x0A
+#define IT66121_INT_MASK_3  0x0B
+#define IT66121_INT_CLEAR_1 0x0C
+#define IT66121_INT_CLEAR_2 0x0D
+#define IT66121_SYS_STATUS  0x0E
+static const struct reg_field IT66121_SYS_STATUS_irq_pending = REG_FIELD(IT66121_SYS_STATUS, 7, 7);
+static const struct reg_field IT66121_SYS_STATUS_hpd = REG_FIELD(IT66121_SYS_STATUS, 6, 6);
+static const struct reg_field IT66121_SYS_STATUS_clr_irq = REG_FIELD(IT66121_SYS_STATUS, 0, 0);
+
+#define IT66121_SYS_CONTROL   0x0F
+#define IT66121_SYS_RCLK_OFF  BIT(6)
+#define IT66121_SYS_IACLK_OFF BIT(5)
+#define IT66121_SYS_TXCLK_OFF BIT(4)
+#define IT66121_SYS_CRCLK_OFF BIT(3)
+#define IT66121_SYS_BANK_MASK 0x03
+
+#define IT66121_DDC_CONTROL	0x10
+#define IT66121_DDC_MASTER_ROM	BIT(1)
+#define IT66121_DDC_MASTER_DDC	0
+#define IT66121_DDC_MASTER_HOST BIT(0)
+#define IT66121_DDC_MASTER_HDCP 0
+
+#define IT66121_DDC_ADDRESS 0x11
+#define IT66121_DDC_OFFSET  0x12
+#define IT66121_DDC_SIZE    0x13
+#define IT66121_DDC_SEGMENT 0x14
+#define IT66121_DDC_COMMAND 0x15
+#define IT66121_DDC_STATUS  0x16
+
+#define IT66121_DDC_RD_FIFO 0x17
+/* reserved */
+#define IT66121_HDCP_ADDRESS 0x19
+
+#define IT66121_HDCP_CONTROL   0x20
+#define IT66121_HDCP_CP_DESIRE BIT(0)
+/* reserved */
+#define IT66121_DDC_BUS_HOLD_TIME 0x1B
+#define IT66121_ROM_STATUS	  0x1C
+/* reserved */
+/* reserved */
+/* 01F - 2F HDCP registers, ignored */
+
+#define IT66121_BANK_START 0x30
+
+/* 030 - 0FF Bank 0 */
+/* 030 - 057 HDCP registers, ignored */
+#define IT66121_MCLK_CONTROL	  0x058
+#define IT66121_PLL_CONTROL	  0x059
+#define IT66121_CLK_POWER_CONTROL 0x05A
+#define IT66121_OS_FREQ_NUM_2	  0x05B
+#define IT66121_OS_FREQ_NUM_1	  0x05C
+/* reserved */
+#define IT66121_TX_CLK_COUNT	 0x05E
+#define IT66121_PLL_LOCK_STATUS	 0x05F
+#define IT66121_AUDIO_FREQ_COUNT 0x060
+#define IT66121_AFE_DRV_CONTROL	 0x061
+#define IT66121_AFE_DRV_PWD	 BIT(5)
+#define IT66121_AFE_RST		 BIT(4)
+
+#define IT66121_AFE_XP_CONTROL	 0x062
+#define IT66121_AFE_IP_CONTROL_2 0x063
+#define IT66121_AFE_IP_CONTROL_1 0x064
+#define IT66121_AFE_RING_CONTROL 0x065
+#define IT66121_AFE_DRV_HS	 0x066
+/* reserved */
+#define IT66121_AFE_IP_CONTROL_3 0x068
+#define IT66121_AFE_PAT_RSTB	 0x069
+#define IT66121_AFE_XP_TEST	 0x06A
+/* reserved */
+/* reserved */
+/* reserved */
+/* reserved */
+/* reserved */
+#define IT66121_INPUT_MODE	     0x070
+#define IT66121_INPUT_MODE_RGB	     0
+#define IT66121_INPUT_MODE_YUV444    BIT(7)
+#define IT66121_INPUT_MODE_YUV422    BIT(6)
+#define IT66121_INPUT_MODE_TXCLKDIV2 BIT(5)
+#define IT66121_INPUT_MODE_CCIR656   BIT(4)
+#define IT66121_INPUT_MODE_SYNCEMB   BIT(3)
+#define IT66121_INPUT_MODE_DDR	     BIT(2)
+#define IT66121_INPUT_PCLKDELAY1     1
+#define IT66121_INPUT_PCLKDELAY2     2
+#define IT66121_INPUT_PCLKDELAY3     3
+
+#define IT66121_INPUT_IO_CONTROL 0x071
+#define IT66121_INPUT_COLOR_CONV 0x072
+#define IT66121_INPUT_DITHER	 BIT(7)
+#define IT66121_INPUT_UDFILTER	 BIT(6)
+#define IT66121_INPUT_DNFREE_GO	 BIT(5)
+#define IT66121_INPUT_BTAT1004	 BIT(2)
+#define IT66121_INPUT_RGB_TO_YUV 0x2
+#define IT66121_INPUT_YUV_TO_RGB 0x3
+#define IT66121_INPUT_NO_CONV	 0x0
+
+#define IT66121_Y_BLANK_LEVEL	0x073
+#define IT66121_C_BLANK_LEVEL	0x074
+#define IT66121_RGB_BLANK_LEVEL 0x075
+#define IT66121_MATRIX_11V_1	0x076
+#define IT66121_MATRIX_11V_2	0x077
+#define IT66121_MATRIX_12V_1	0x078
+#define IT66121_MATRIX_12V_2	0x079
+#define IT66121_MATRIX_13V_1	0x07A
+#define IT66121_MATRIX_13V_2	0x07B
+#define IT66121_MATRIX_21V_1	0x07C
+#define IT66121_MATRIX_21V_2	0x07D
+#define IT66121_MATRIX_22V_1	0x07E
+#define IT66121_MATRIX_22V_2	0x07F
+#define IT66121_MATRIX_23V_1	0x080
+#define IT66121_MATRIX_23V_2	0x081
+#define IT66121_MATRIX_31V_1	0x082
+#define IT66121_MATRIX_31V_2	0x083
+#define IT66121_MATRIX_32V_1	0x084
+#define IT66121_MATRIX_32V_2	0x085
+#define IT66121_MATRIX_33V_1	0x086
+#define IT66121_MATRIX_33V_2	0x087
+/* reserved */
+/* reserved */
+/* reserved */
+/* reserved */
+/* reserved */
+#define IT66121_PCI2C_CEC_ADDRESS 0x08D
+/* reserved */
+/* reserved */
+/* 090 - 0B2 Pattern generation registers, ignored */
+/* reserved */
+#define IT66121_HDMI_DATA_SWAP 0x0BF
+
+#define IT66121_HDMI_MODE      0x0C0
+#define IT66121_HDMI_MODE_HDMI BIT(0)
+#define IT66121_HDMI_MODE_DVI  0
+
+#define IT66121_HDMI_AV_MUTE	  0x0C1
+#define IT66121_HDMI_AV_MUTE_ON	  BIT(0)
+#define IT66121_HDMI_AV_MUTE_BLUE BIT(1)
+
+#define IT66121_HDMI_BLACK_SRC	 0x0C2
+#define IT66121_HDMI_OESS_PREIOD 0x0C3
+/* reserved */
+#define IT66121_HDMI_AUDIO_CTS	      0x0C5
+#define IT66121_HDMI_GEN_CTRL_PKT     0x0C6
+#define IT66121_HDMI_GEN_CTRL_PKT_ON  BIT(0)
+#define IT66121_HDMI_GEN_CTRL_PKT_RPT BIT(1)
+
+/* reserved */
+/* reserved */
+#define IT66121_HDMI_NULL_PKT 0x0C9
+#define IT66121_HDMI_ACP_PKT  0x0CA
+/* reserved */
+/* reserved */
+#define IT66121_HDMI_AVI_INFO_PKT    0x0CD
+#define IT66121_HDMI_AVI_INFO_PKT_ON BIT(0)
+#define IT66121_HDMI_AVI_INFO_RPT    BIT(1)
+
+#define IT66121_HDMI_AUD_INFO_PKT 0x0CE
+/* reserved */
+#define IT66121_HDMI_MPEG_INFO_PKT	0x0D0
+#define IT66121_HDMI_VIDEO_PARAM_STATUS 0x0D1
+#define IT66121_HDMI_3D_INFO_PKT	0x0D2
+/* reserved */
+/* reserved */
+/* reserved */
+/* reserved */
+#define IT66121_HDMI_PCLK_CONTROL 0x0D7
+#define IT66121_HDMI_PCLK_COUNT	  0x0D8
+/* reserved */
+/* reserved */
+/* reserved */
+/* reserved */
+/* reserved */
+/* reserved */
+/* reserved */
+/* E0 - E7 Audio channel registers, ignored */
+#define IT66121_EXT_INT_CONTROL 0x0E8
+/* reserved */
+/* reserved */
+/* reserved */
+#define IT66121_EXT_INT_MASK 0x0EC
+/* reserved */
+#define IT66121_EXT_INT_STATUS_1 0x0EE
+/* reserved */
+#define IT66121_EXT_INT_STATUS_2 0x0F0
+/* reserved */
+/* reserved */
+/* 0F3 - 0F8 Test registers, ignored */
+/* 0F9 - 0FF undefined*/
+
+/* 130 - 1BF Bank 1 */
+/* 130 - 18F HDMI packet content registers, ignored except AVI InfoFrame */
+#define IT66121_HDMI_AVIINFO_DB1  0x158
+#define IT66121_HDMI_AVIINFO_DB2  0x159
+#define IT66121_HDMI_AVIINFO_DB3  0x15A
+#define IT66121_HDMI_AVIINFO_DB4  0x15B
+#define IT66121_HDMI_AVIINFO_DB5  0x15C
+#define IT66121_HDMI_AVIINFO_CSUM 0x15D
+#define IT66121_HDMI_AVIINFO_DB6  0x15E
+#define IT66121_HDMI_AVIINFO_DB7  0x15F
+#define IT66121_HDMI_AVIINFO_DB8  0x160
+#define IT66121_HDMI_AVIINFO_DB9  0x161
+#define IT66121_HDMI_AVIINFO_DB10 0x162
+#define IT66121_HDMI_AVIINFO_DB11 0x163
+#define IT66121_HDMI_AVIINFO_DB12 0x164
+#define IT66121_HDMI_AVIINFO_DB13 0x165
+
+/* 190 - 1BF Audio channel status registers, ignored */
+
+#define IT66121_BANK_END 0x1FF
+
+/* CEC registers ignored (must be configured as a separate regmap / device) */
+
+/* List of volatile registers that shall not be cached */
+static inline bool IT66121_REG_VOLATILE(u32 reg)
+{
+	switch (reg) {
+	case IT66121_INT_STATUS_1:
+	case IT66121_INT_STATUS_2:
+	case IT66121_INT_STATUS_3:
+	case IT66121_SYS_STATUS:
+	case IT66121_DDC_STATUS:
+	case IT66121_DDC_RD_FIFO:
+	case IT66121_ROM_STATUS:
+	case IT66121_OS_FREQ_NUM_2:
+	case IT66121_OS_FREQ_NUM_1:
+	case IT66121_TX_CLK_COUNT:
+	case IT66121_PLL_LOCK_STATUS:
+	case IT66121_AUDIO_FREQ_COUNT:
+	case IT66121_HDMI_PCLK_CONTROL:
+	case IT66121_HDMI_PCLK_COUNT:
+		return true;
+	default:
+		return false;
+	}
+}
+
+#endif /* FL2000_IT66121_REGS_H */

-- 
2.56.0

