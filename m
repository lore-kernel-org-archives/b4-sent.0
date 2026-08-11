From: Esteban Urrutia <esteuwu@proton.me>
Date: Mon, 10 Aug 2026 23:31:37 -0400
Subject: [PATCH v3 2/2] usb: typec: Add support for Parade PS5169 USB
 Type-C redriver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-ps5169-bup-v3-2-a2178b2834d7@proton.me>
References: <20260810-ps5169-bup-v3-0-a2178b2834d7@proton.me>
In-Reply-To: <20260810-ps5169-bup-v3-0-a2178b2834d7@proton.me>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786419136; l=19402;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=fqyfs4yhNtpKPrC0p6KgL7zzm2LBsFexqBXocLgUHI8=;
 b=qUEUUqOfpYnFjWeeFdvFtD+F7Fg0ryvFGpxOZEmQxe+rtZGiftpVtEDm9iLmsP1QtD/G3xRF0
 KIrgXaUj6YvBX7/8QvUQTM8ymyxsYkwPF5J6nMGPOCaxE9pzw4JwbhV
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add driver for the Parade PS5169, an USB Type-C redriver capable of
handling 10Gb/s USB signals and 8.1Gb/s DP signals.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 MAINTAINERS                    |   7 +
 drivers/usb/typec/mux/Kconfig  |  10 +
 drivers/usb/typec/mux/Makefile |   1 +
 drivers/usb/typec/mux/ps5169.c | 592 +++++++++++++++++++++++++++++++++++++++++
 4 files changed, 610 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index da14a58df9e8..1b751a8ce0a8 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -28369,6 +28369,13 @@ F:	drivers/usb/typec/tcpm/tcpm.c
 F:	include/linux/usb/tcpci.h
 F:	include/linux/usb/tcpm.h
 
+USB TYPEC PS5169 MUX DRIVER
+M:	Esteban Urrutia <esteuwu@proton.me>
+L:	linux-usb@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/usb/parade,ps5169.yaml
+F:	drivers/usb/typec/mux/ps5169.c
+
 USB TYPEC TUSB1046 MUX DRIVER
 M:	Romain Gantois <romain.gantois@bootlin.com>
 L:	linux-usb@vger.kernel.org
diff --git a/drivers/usb/typec/mux/Kconfig b/drivers/usb/typec/mux/Kconfig
index 6dd8f961b593..2838a53ce564 100644
--- a/drivers/usb/typec/mux/Kconfig
+++ b/drivers/usb/typec/mux/Kconfig
@@ -56,6 +56,16 @@ config TYPEC_MUX_NB7VPQ904M
 	  Say Y or M if your system has a On Semiconductor NB7VPQ904M Type-C
 	  redriver chip found on some devices with a Type-C port.
 
+config TYPEC_MUX_PS5169
+	tristate "Parade PS5169 Type-C redriver driver"
+	depends on I2C
+	depends on DRM || DRM=n
+	select DRM_AUX_BRIDGE if DRM_BRIDGE && OF
+	select REGMAP_I2C
+	help
+	  Say Y or M if your system has a Parade PS5169 Type-C redriver chip
+	  found on some devices with a Type-C port.
+
 config TYPEC_MUX_PS883X
 	tristate "Parade PS883x Type-C retimer driver"
 	depends on I2C
diff --git a/drivers/usb/typec/mux/Makefile b/drivers/usb/typec/mux/Makefile
index b4f599eb5053..c775bfa12068 100644
--- a/drivers/usb/typec/mux/Makefile
+++ b/drivers/usb/typec/mux/Makefile
@@ -6,6 +6,7 @@ obj-$(CONFIG_TYPEC_MUX_PI3USB30532)	+= pi3usb30532.o
 obj-$(CONFIG_TYPEC_MUX_INTEL_PMC)	+= intel_pmc_mux.o
 obj-$(CONFIG_TYPEC_MUX_IT5205)		+= it5205.o
 obj-$(CONFIG_TYPEC_MUX_NB7VPQ904M)	+= nb7vpq904m.o
+obj-$(CONFIG_TYPEC_MUX_PS5169)		+= ps5169.o
 obj-$(CONFIG_TYPEC_MUX_PS883X)		+= ps883x.o
 obj-$(CONFIG_TYPEC_MUX_PTN36502)	+= ptn36502.o
 obj-$(CONFIG_TYPEC_MUX_TUSB1046)	+= tusb1046.o
diff --git a/drivers/usb/typec/mux/ps5169.c b/drivers/usb/typec/mux/ps5169.c
new file mode 100644
index 000000000000..5fbc452249d0
--- /dev/null
+++ b/drivers/usb/typec/mux/ps5169.c
@@ -0,0 +1,592 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Driver for Parade PS5169 USB Type-C linear redriver
+ * Registers and bits decoded from downstream drivers
+ *
+ * Copyright (c) 2026 Esteban Urrutia <esteuwu@proton.me>
+ */
+
+#include <drm/bridge/aux-bridge.h>
+
+#include <linux/i2c.h>
+#include <linux/regmap.h>
+
+#include <linux/usb/typec_altmode.h>
+#include <linux/usb/typec_dp.h>
+#include <linux/usb/typec_mux.h>
+#include <linux/usb/typec_retimer.h>
+
+/* Useful constants */
+#define PS5169_DP_EQ_REG_COUNT		2
+#define PS5169_USB_RX_EQ_REG_COUNT	4
+#define PS5169_USB_TX_EQ_REG_COUNT	3
+
+#define PS5169_DP_EQ_LEVEL_COUNT	8
+#define PS5169_USB_RX_EQ_LEVEL_COUNT	8
+#define PS5169_USB_TX_EQ_LEVEL_COUNT	8
+
+/* PS5169 registers */
+#define PS5169_CONFIG_REG		0x40
+#define PS5169_GAIN_REG			0x5c
+#define PS5169_USB_RX1_LFPS_REG		0x8d
+#define PS5169_USB_RX2_LFPS_REG		0x90
+#define PS5169_AUX_RX_DATA_REG		0x9f
+#define PS5169_AUX_MONITORING_REG	0xa0
+#define PS5169_HPD_LEVEL_REG		0xa1
+#define PS5169_CHIP_ID_REG		0xac
+#define PS5169_CHIP_REVISION_REG	0xae
+/* Chip revision is split in two registers */
+#define PS5169_MAX_REG			(PS5169_CHIP_REVISION_REG + 1)
+
+/* PS5169 register bits */
+#define PS5169_CONFIG_REVERSE_BIT	BIT(4)
+#define PS5169_CONFIG_DP_EN_BIT		BIT(5)
+#define PS5169_CONFIG_USB3_EN_BIT	BIT(6)
+#define PS5169_CONFIG_BASE_BIT		BIT(7)
+
+#define PS5169_GAIN_DP_BIT		BIT(4)
+#define PS5169_GAIN_USB_RX_BIT		BIT(2)
+#define PS5169_GAIN_USB_TX_BIT		BIT(0)
+
+#define PS5169_USB_RX_LFPS_50_OHM_BIT	BIT(0)
+
+#define PS5169_AUX_RX_DATA_REVERSE_BIT	BIT(1)
+
+#define PS5169_AUX_MONITORING_BIT	BIT(1)
+#define PS5169_HPD_LEVEL_BIT		BIT(2)
+
+/* PS5169 register values */
+#define PS5169_CHIP_ID_VAL		0x6987
+
+struct ps5169_eq_db {
+	const int major;
+	const int minor;
+};
+
+struct ps5169_eq_data {
+	const char *propname;
+	const struct ps5169_eq_db *db;
+	const int nlevels;
+};
+
+/* PS5169 EQ registers */
+static const int ps5169_dp_eq_reg[PS5169_DP_EQ_REG_COUNT]		= {0x52, 0x5e};
+static const int ps5169_usb_rx_eq_reg[PS5169_USB_RX_EQ_REG_COUNT]	= {0x51, 0x77, 0x54, 0x78};
+static const int ps5169_usb_tx_eq_reg[PS5169_USB_TX_EQ_REG_COUNT]	= {0x50, 0x5d, 0x54};
+
+/* PS5169 EQ register masks */
+static const int ps5169_dp_eq_mask[PS5169_DP_EQ_REG_COUNT]		= {0x70, 0x07};
+static const int ps5169_usb_rx_eq_mask[PS5169_USB_RX_EQ_REG_COUNT]	= {0xf6, 0xf0, 0x0f, 0xe1};
+static const int ps5169_usb_tx_eq_mask[PS5169_USB_TX_EQ_REG_COUNT]	= {0x70, 0x70, 0xf0};
+
+/* PS5169 EQ register values */
+static const int ps5169_dp_eq_val[PS5169_DP_EQ_LEVEL_COUNT][PS5169_DP_EQ_REG_COUNT] = {
+	{0x00, 0x04},
+	{0x10, 0x05},
+	{0x20, 0x06},
+	{0x30, 0x06},
+	{0x40, 0x06},
+	{0x50, 0x07},
+	{0x60, 0x07},
+	{0x70, 0x07},
+};
+
+static const int ps5169_usb_rx_eq_val[PS5169_USB_RX_EQ_LEVEL_COUNT][PS5169_USB_RX_EQ_REG_COUNT] = {
+	{0x86, 0x00, 0x00, 0x20},
+	{0x96, 0x00, 0x01, 0x20},
+	{0xa6, 0x50, 0x01, 0x40},
+	{0xb6, 0x50, 0x05, 0x40},
+	{0xc6, 0xb0, 0x0c, 0x80},
+	{0xd6, 0xf0, 0x05, 0x80},
+	{0xe6, 0xf0, 0x0f, 0x80},
+	{0xf6, 0x30, 0x0f, 0xa1},
+};
+
+static const int ps5169_usb_tx_eq_val[PS5169_USB_TX_EQ_LEVEL_COUNT][PS5169_USB_TX_EQ_REG_COUNT] = {
+	{0x00, 0x40, 0x00},
+	{0x10, 0x50, 0x10},
+	{0x20, 0x60, 0x10},
+	{0x30, 0x60, 0x50},
+	{0x40, 0x60, 0xc0},
+	{0x50, 0x70, 0x50},
+	{0x60, 0x70, 0xf0},
+	{0x70, 0x70, 0xf0},
+};
+
+/* PS5169 EQ decibels */
+static const struct ps5169_eq_db ps5169_dp_eq_db[PS5169_DP_EQ_LEVEL_COUNT] = {
+	{2,  0},
+	{5,  5},
+	{6,  5},
+	{7,  5},
+	{8,  0},
+	{8,  5},
+	{9,  5},
+	{10, 0}, /* Supposedly */
+};
+
+static const struct ps5169_eq_db ps5169_usb_rx_eq_db[PS5169_USB_RX_EQ_LEVEL_COUNT] = {
+	{5,  2},
+	{6,  0},
+	{7,  0},
+	{8,  0},
+	{8,  8},
+	{9,  6},
+	{10, 4},
+	{11, 2},
+};
+
+static const struct ps5169_eq_db ps5169_usb_tx_eq_db[PS5169_USB_TX_EQ_LEVEL_COUNT] = {
+	{2,  0},
+	{5,  5},
+	{6,  5},
+	{7,  5},
+	{8,  0},
+	{8,  5},
+	{9,  5},
+	{10, 0}, /* Supposedly */
+};
+
+/* PS5169 EQ data */
+static const struct ps5169_eq_data ps5169_dp_eq_data = {
+	.propname = "parade,dp-eq-db",
+	.db = ps5169_dp_eq_db,
+	.nlevels = PS5169_DP_EQ_LEVEL_COUNT,
+};
+
+static const struct ps5169_eq_data ps5169_usb_rx_eq_data = {
+	.propname = "parade,usb-rx-eq-db",
+	.db = ps5169_usb_rx_eq_db,
+	.nlevels = PS5169_USB_RX_EQ_LEVEL_COUNT,
+};
+
+static const struct ps5169_eq_data ps5169_usb_tx_eq_data = {
+	.propname = "parade,usb-tx-eq-db",
+	.db = ps5169_usb_tx_eq_db,
+	.nlevels = PS5169_USB_TX_EQ_LEVEL_COUNT,
+};
+
+struct redriver {
+	struct regulator *vcc;
+	struct gpio_desc *reset_gpio;
+
+	struct regmap *regmap;
+
+	struct typec_switch *typec_switch;
+	struct typec_mux *typec_mux;
+
+	struct typec_switch_dev *sw;
+	struct typec_retimer *retimer;
+
+	unsigned long mode;
+	enum typec_orientation orientation;
+
+	unsigned int dp_eq_level;
+	unsigned int usb_rx_eq_level;
+	unsigned int usb_tx_eq_level;
+
+	bool tune_lfps;
+
+	bool dp_set_gain;
+	bool usb_rx_set_gain;
+	bool usb_tx_set_gain;
+
+	struct mutex lock; /* protect non-concurrent retimer & switch */
+
+	unsigned int svid;
+};
+
+static const struct regmap_config ps5169_regmap = {
+	.max_register = PS5169_MAX_REG,
+	.reg_bits = 8,
+	.val_bits = 8,
+	/* Accesses only done under ps5169->lock */
+	.disable_locking = true,
+};
+
+static void ps5169_write(struct redriver *ps5169, unsigned int reg, unsigned int val)
+{
+	regmap_write(ps5169->regmap, reg, val);
+
+	if (val & PS5169_CONFIG_DP_EN_BIT) {
+		/* Clearing this bit will enable the AUX channel */
+		regmap_clear_bits(ps5169->regmap, PS5169_AUX_MONITORING_REG,
+				  PS5169_AUX_MONITORING_BIT);
+		/* Setting this bit will set a high HPD level */
+		regmap_set_bits(ps5169->regmap, PS5169_HPD_LEVEL_REG, PS5169_HPD_LEVEL_BIT);
+	} else {
+		/* Setting this bit will disable the AUX channel */
+		regmap_set_bits(ps5169->regmap, PS5169_AUX_MONITORING_REG,
+				PS5169_AUX_MONITORING_BIT);
+		/* Clearing this bit will set a low HPD level */
+		regmap_clear_bits(ps5169->regmap, PS5169_HPD_LEVEL_REG, PS5169_HPD_LEVEL_BIT);
+	}
+
+	if (ps5169->tune_lfps) {
+		if (val & PS5169_CONFIG_USB3_EN_BIT) {
+			/* Setting these bits will enable a 50 ohm termination on USB RX */
+			regmap_set_bits(ps5169->regmap, PS5169_USB_RX1_LFPS_REG,
+					PS5169_USB_RX_LFPS_50_OHM_BIT);
+			regmap_set_bits(ps5169->regmap, PS5169_USB_RX2_LFPS_REG,
+					PS5169_USB_RX_LFPS_50_OHM_BIT);
+		} else {
+			/* Clearing these bits will disable a 50 ohm termination on USB RX */
+			regmap_clear_bits(ps5169->regmap, PS5169_USB_RX1_LFPS_REG,
+					  PS5169_USB_RX_LFPS_50_OHM_BIT);
+			regmap_clear_bits(ps5169->regmap, PS5169_USB_RX2_LFPS_REG,
+					  PS5169_USB_RX_LFPS_50_OHM_BIT);
+		}
+	}
+}
+
+static int ps5169_set(struct redriver *ps5169)
+{
+	bool reverse = (ps5169->orientation == TYPEC_ORIENTATION_REVERSE);
+	unsigned int val = PS5169_CONFIG_BASE_BIT;
+
+	switch (ps5169->mode) {
+	case TYPEC_STATE_SAFE:
+		ps5169_write(ps5169, PS5169_CONFIG_REG, val);
+
+		return 0;
+
+	case TYPEC_STATE_USB:
+		val |= PS5169_CONFIG_USB3_EN_BIT;
+		if (reverse)
+			val |= PS5169_CONFIG_REVERSE_BIT;
+		ps5169_write(ps5169, PS5169_CONFIG_REG, val);
+
+		return 0;
+
+	default:
+		if (ps5169->svid != USB_TYPEC_DP_SID)
+			return -EINVAL;
+
+		break;
+	}
+
+	switch (ps5169->mode) {
+	case TYPEC_DP_STATE_C:
+	case TYPEC_DP_STATE_E:
+		val |= PS5169_CONFIG_DP_EN_BIT;
+		if (reverse)
+			val |= PS5169_CONFIG_REVERSE_BIT;
+		ps5169_write(ps5169, PS5169_CONFIG_REG, val);
+
+		break;
+
+	case TYPEC_DP_STATE_D:
+		val |= PS5169_CONFIG_DP_EN_BIT | PS5169_CONFIG_USB3_EN_BIT;
+		if (reverse)
+			val |= PS5169_CONFIG_REVERSE_BIT;
+		ps5169_write(ps5169, PS5169_CONFIG_REG, val);
+
+		break;
+
+	default:
+		return -EOPNOTSUPP;
+	}
+
+	return 0;
+}
+
+static int ps5169_switch_set(struct typec_switch_dev *sw, enum typec_orientation orientation)
+{
+	struct redriver *ps5169 = typec_switch_get_drvdata(sw);
+	int ret;
+
+	ret = typec_switch_set(ps5169->typec_switch, orientation);
+	if (ret)
+		return ret;
+
+	mutex_lock(&ps5169->lock);
+
+	if (ps5169->orientation != orientation) {
+		ps5169->orientation = orientation;
+
+		ret = ps5169_set(ps5169);
+	}
+
+	mutex_unlock(&ps5169->lock);
+
+	return ret;
+}
+
+static int ps5169_retimer_set(struct typec_retimer *retimer, struct typec_retimer_state *state)
+{
+	struct redriver *ps5169 = typec_retimer_get_drvdata(retimer);
+	struct typec_mux_state mux_state;
+	int ret = 0;
+
+	mutex_lock(&ps5169->lock);
+
+	if (ps5169->mode != state->mode) {
+		ps5169->mode = state->mode;
+
+		if (state->alt)
+			ps5169->svid = state->alt->svid;
+		else
+			ps5169->svid = 0; // No SVID
+
+		ret = ps5169_set(ps5169);
+	}
+
+	mutex_unlock(&ps5169->lock);
+
+	if (ret)
+		return ret;
+
+	mux_state.alt = state->alt;
+	mux_state.data = state->data;
+	mux_state.mode = state->mode;
+
+	return typec_mux_set(ps5169->typec_mux, &mux_state);
+}
+
+static int ps5169_eq_from_dt(const struct device *dev, const struct ps5169_eq_data *data,
+			     unsigned int *val)
+{
+	int ret;
+	u32 db[2];
+	unsigned int i;
+
+	if (device_property_present(dev, data->propname)) {
+		/* Read property */
+		ret = device_property_read_u32_array(dev, data->propname, db, ARRAY_SIZE(db));
+		if (ret) {
+			dev_err(dev, "Failed to read %s\n", data->propname);
+			return ret;
+		}
+
+		/* Map to level */
+		for (i = 0; i < data->nlevels; i++) {
+			if (db[0] == data->db[i].major && db[1] == data->db[i].minor) {
+				*val = i;
+				return 0;
+			}
+		}
+
+		/* Invalid dB in property */
+		dev_err(dev, "%s out of range\n", data->propname);
+		return -EINVAL;
+	}
+
+	/* A redriver is present for a reason, so raise a warning if property is not present */
+	dev_warn(dev, "Missing %s property\n", data->propname);
+	*val = U32_MAX;
+	return 0;
+}
+
+static void ps5169_init(struct redriver *ps5169)
+{
+	int i;
+
+	/* DP equalization */
+	if (ps5169->dp_eq_level != U32_MAX)
+		for (i = 0; i < PS5169_DP_EQ_REG_COUNT; i++)
+			regmap_update_bits(ps5169->regmap, ps5169_dp_eq_reg[i],
+					   ps5169_dp_eq_mask[i],
+					   ps5169_dp_eq_val[ps5169->dp_eq_level][i]);
+
+	/* USB RX equalization */
+	if (ps5169->usb_rx_eq_level != U32_MAX)
+		for (i = 0; i < PS5169_USB_RX_EQ_REG_COUNT; i++)
+			regmap_update_bits(ps5169->regmap, ps5169_usb_rx_eq_reg[i],
+					   ps5169_usb_rx_eq_mask[i],
+					   ps5169_usb_rx_eq_val[ps5169->usb_rx_eq_level][i]);
+
+	/* USB TX equalization */
+	if (ps5169->usb_tx_eq_level != U32_MAX)
+		for (i = 0; i < PS5169_USB_TX_EQ_REG_COUNT; i++)
+			regmap_update_bits(ps5169->regmap, ps5169_usb_tx_eq_reg[i],
+					   ps5169_usb_tx_eq_mask[i],
+					   ps5169_usb_tx_eq_val[ps5169->usb_tx_eq_level][i]);
+
+	/* If these bits are assigned a -0.9 dB gain will be set on the corresponding channels */
+	regmap_assign_bits(ps5169->regmap, PS5169_GAIN_REG, PS5169_GAIN_DP_BIT,
+			   ps5169->dp_set_gain);
+	regmap_assign_bits(ps5169->regmap, PS5169_GAIN_REG, PS5169_GAIN_USB_RX_BIT,
+			   ps5169->usb_rx_set_gain);
+	regmap_assign_bits(ps5169->regmap, PS5169_GAIN_REG, PS5169_GAIN_USB_TX_BIT,
+			   ps5169->usb_tx_set_gain);
+}
+
+static int ps5169_probe(struct i2c_client *client)
+{
+	struct redriver *ps5169;
+	struct device *dev = &client->dev;
+	int ret;
+	__le16 chip_id, chip_revision;
+	struct typec_switch_desc switch_desc = { };
+	struct typec_retimer_desc retimer_desc = { };
+
+	ps5169 = devm_kzalloc(dev, sizeof(*ps5169), GFP_KERNEL);
+	if (!ps5169)
+		return -ENOMEM;
+
+	mutex_init(&ps5169->lock);
+
+	ps5169->vcc = devm_regulator_get(dev, "vcc");
+	if (IS_ERR(ps5169->vcc))
+		return dev_err_probe(dev, PTR_ERR(ps5169->vcc), "Failed to get vcc-supply\n");
+
+	ps5169->reset_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_LOW);
+	if (IS_ERR(ps5169->reset_gpio))
+		return dev_err_probe(dev, PTR_ERR(ps5169->reset_gpio),
+				     "Failed to get reset-gpios\n");
+
+	ps5169->regmap = devm_regmap_init_i2c(client, &ps5169_regmap);
+	if (IS_ERR(ps5169->regmap))
+		return dev_err_probe(dev, PTR_ERR(ps5169->regmap), "Failed to initialize regmap\n");
+
+	ps5169->typec_switch = typec_switch_get(dev);
+	if (IS_ERR(ps5169->typec_switch))
+		return dev_err_probe(dev, PTR_ERR(ps5169->typec_switch),
+				     "Failed to get orientation-switch\n");
+
+	ps5169->typec_mux = typec_mux_get(dev);
+	if (IS_ERR(ps5169->typec_mux)) {
+		ret = dev_err_probe(dev, PTR_ERR(ps5169->typec_mux), "Failed to get mode-switch\n");
+		goto switch_put;
+	}
+
+	ret = regulator_enable(ps5169->vcc);
+	if (ret) {
+		dev_err(dev, "Failed to enable vcc-supply\n");
+		goto mux_put;
+	}
+
+	/* Reset the retimer */
+	gpiod_set_value(ps5169->reset_gpio, 1);
+	usleep_range(1000, 1500);
+	gpiod_set_value(ps5169->reset_gpio, 0);
+	usleep_range(10000, 11000);
+
+	ret = regmap_raw_read(ps5169->regmap, PS5169_CHIP_ID_REG, &chip_id, sizeof(chip_id));
+	if (ret) {
+		dev_err(dev, "Failed to read chip ID\n");
+		goto vcc_disable;
+	}
+
+	/* Compare chip IDs */
+	if (chip_id != PS5169_CHIP_ID_VAL) {
+		dev_err(dev, "Unexpected chip ID 0x%04x\n", chip_id);
+		ret = -EINVAL;
+		goto vcc_disable;
+	}
+
+	/* Read chip revision */
+	ret = regmap_raw_read(ps5169->regmap, PS5169_CHIP_REVISION_REG, &chip_revision,
+			      sizeof(chip_revision));
+	if (ret) {
+		dev_err(dev, "Failed to read chip revision\n");
+		goto vcc_disable;
+	}
+	dev_dbg(dev, "Found PS5169 with chip revision 0x%04x\n", chip_revision);
+
+	/* DP equalization */
+	ret = ps5169_eq_from_dt(dev, &ps5169_dp_eq_data, &(ps5169->dp_eq_level));
+	if (ret)
+		goto vcc_disable;
+
+	/* USB RX equalization */
+	ret = ps5169_eq_from_dt(dev, &ps5169_usb_rx_eq_data, &(ps5169->usb_rx_eq_level));
+	if (ret)
+		goto vcc_disable;
+
+	/* USB TX equalization */
+	ret = ps5169_eq_from_dt(dev, &ps5169_usb_tx_eq_data, &(ps5169->usb_tx_eq_level));
+	if (ret)
+		goto vcc_disable;
+
+	/* Read properties from DT */
+	ps5169->tune_lfps = device_property_read_bool(dev, "parade,fine-tune-lfps-swing");
+
+	ps5169->dp_set_gain = device_property_read_bool(dev, "parade,dp-set-gain");
+	ps5169->usb_rx_set_gain = device_property_read_bool(dev, "parade,usb-rx-set-gain");
+	ps5169->usb_tx_set_gain = device_property_read_bool(dev, "parade,usb-tx-set-gain");
+
+	ret = drm_aux_bridge_register(dev);
+	if (ret) {
+		dev_err(dev, "Failed to register aux_bridge\n");
+		goto vcc_disable;
+	}
+
+	ps5169->mode = TYPEC_STATE_SAFE;
+	ps5169->orientation = TYPEC_ORIENTATION_NONE;
+
+	/* orientation-switch */
+	switch_desc.drvdata = ps5169;
+	switch_desc.fwnode = dev_fwnode(dev);
+	switch_desc.set = ps5169_switch_set;
+
+	ps5169->sw = typec_switch_register(dev, &switch_desc);
+	if (IS_ERR(ps5169->sw)) {
+		ret = dev_err_probe(dev, PTR_ERR(ps5169->sw), "Failed to register switch\n");
+		goto vcc_disable;
+	}
+
+	/* retimer-switch */
+	retimer_desc.drvdata = ps5169;
+	retimer_desc.fwnode = dev_fwnode(dev);
+	retimer_desc.set = ps5169_retimer_set;
+
+	ps5169->retimer = typec_retimer_register(dev, &retimer_desc);
+	if (IS_ERR(ps5169->retimer)) {
+		ret = dev_err_probe(dev, PTR_ERR(ps5169->retimer), "Failed to register retimer\n");
+		goto switch_unregister;
+	}
+
+	ps5169_init(ps5169);
+
+	i2c_set_clientdata(client, ps5169);
+
+	return 0;
+
+switch_unregister:
+	typec_switch_unregister(ps5169->sw);
+
+vcc_disable:
+	regulator_disable(ps5169->vcc);
+
+mux_put:
+	typec_mux_put(ps5169->typec_mux);
+switch_put:
+	typec_switch_put(ps5169->typec_switch);
+
+	return ret;
+}
+
+static void ps5169_remove(struct i2c_client *client)
+{
+	struct redriver *ps5169 = i2c_get_clientdata(client);
+
+	typec_retimer_unregister(ps5169->retimer);
+	typec_switch_unregister(ps5169->sw);
+
+	regulator_disable(ps5169->vcc);
+
+	typec_mux_put(ps5169->typec_mux);
+	typec_switch_put(ps5169->typec_switch);
+}
+
+static const struct of_device_id ps5169_of_match_table[] = {
+	{ .compatible = "parade,ps5169" },
+	{ },
+};
+MODULE_DEVICE_TABLE(of, ps5169_of_match_table);
+
+static struct i2c_driver ps5169_driver = {
+	.driver = {
+		.name = "ps5169",
+		.of_match_table = ps5169_of_match_table,
+	},
+	.probe = ps5169_probe,
+	.remove = ps5169_remove,
+};
+
+module_i2c_driver(ps5169_driver);
+
+MODULE_AUTHOR("Esteban Urrutia <esteuwu@proton.me>");
+MODULE_DESCRIPTION("Driver for Parade PS5169 USB Type-C linear redriver");
+MODULE_LICENSE("GPL");

-- 
2.55.0

