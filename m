From: Roman Vivchar <rva333@protonmail.com>
Date: Mon, 04 May 2026 21:24:56 +0300
Subject: [PATCH 04/13] iio: adc: mediatek: add mt6323 PMIC AUXADC driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-mt6323-v1-4-799b58b355ff@protonmail.com>
References: <20260504-mt6323-v1-0-799b58b355ff@protonmail.com>
In-Reply-To: <20260504-mt6323-v1-0-799b58b355ff@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Srinivas Kandagatla <srini@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Lee Jones <lee@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-pm@vger.kernel.org, 
 Ben Grisdale <bengris32@protonmail.ch>, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777919095; l=12347;
 i=rva333@protonmail.com; s=20260325; h=from:subject:message-id;
 bh=ntbXW4JgcRRKUQ/pbraWJLDHLEhabTwURPdUBQZOVzI=;
 b=xMJnNoS8/Lw4YMf50KV1e0r4lDkQSQ1sV5zI54Be7RLHVPZWuNA1bm+U0PAOi7XT89oUN0Oc9
 945wYVty4spBfzm2htQ8dzpQgTqMKyf/hnOkqMKTXAzPWHYMQdU2jzY
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=euuVBZGtA2Cqb8Dju84qpQPhvwxyUirJlXpqEPQWKBM=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260325 with auth_id=695
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The mt6323 AUXADC is a 15-bit ADC used for system monitoring. This driver
provides support for reading various channels including battery and
charger voltages, battery and chip temperature, current sensing and
accessory detection.

Add a driver for the AUXADC found in the MediaTek mt6323 PMIC.

Tested-by: Ben Grisdale <bengris32@protonmail.ch> # Amazon Echo Dot (2nd Generation)
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/iio/adc/Kconfig         |  11 ++
 drivers/iio/adc/Makefile        |   1 +
 drivers/iio/adc/mt6323-auxadc.c | 372 ++++++++++++++++++++++++++++++++++++++++
 3 files changed, 384 insertions(+)

diff --git a/drivers/iio/adc/Kconfig b/drivers/iio/adc/Kconfig
index 60038ae8dfc4..a03614b46041 100644
--- a/drivers/iio/adc/Kconfig
+++ b/drivers/iio/adc/Kconfig
@@ -1137,6 +1137,17 @@ config MCP3911
 	  This driver can also be built as a module. If so, the module will be
 	  called mcp3911.
 
+config MEDIATEK_MT6323_AUXADC
+	tristate "MediaTek MT6323 PMIC AUXADC driver"
+	depends on MFD_MT6397
+	help
+	  Say yes here to enable support for MediaTek MT6323 PMIC Auxiliary ADC.
+	  This driver provides multiple channels for system monitoring,
+	  such as battery voltage, PMIC temperature, and others.
+
+	  This driver can also be built as a module. If so, the module will be
+	  called mt6323-auxadc.
+
 config MEDIATEK_MT6359_AUXADC
 	tristate "MediaTek MT6359 PMIC AUXADC driver"
 	depends on MFD_MT6397
diff --git a/drivers/iio/adc/Makefile b/drivers/iio/adc/Makefile
index c76550415ff1..58161750d6e3 100644
--- a/drivers/iio/adc/Makefile
+++ b/drivers/iio/adc/Makefile
@@ -99,6 +99,7 @@ obj-$(CONFIG_MCP320X) += mcp320x.o
 obj-$(CONFIG_MCP3422) += mcp3422.o
 obj-$(CONFIG_MCP3564) += mcp3564.o
 obj-$(CONFIG_MCP3911) += mcp3911.o
+obj-$(CONFIG_MEDIATEK_MT6323_AUXADC) += mt6323-auxadc.o
 obj-$(CONFIG_MEDIATEK_MT6359_AUXADC) += mt6359-auxadc.o
 obj-$(CONFIG_MEDIATEK_MT6360_ADC) += mt6360-adc.o
 obj-$(CONFIG_MEDIATEK_MT6370_ADC) += mt6370-adc.o
diff --git a/drivers/iio/adc/mt6323-auxadc.c b/drivers/iio/adc/mt6323-auxadc.c
new file mode 100644
index 000000000000..97b4ad4e7b47
--- /dev/null
+++ b/drivers/iio/adc/mt6323-auxadc.c
@@ -0,0 +1,372 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2026 Roman Vivchar <rva333@protonmail.com>
+ *
+ * Based on drivers/iio/adc/mt6359-auxadc.c
+ */
+
+#include <linux/bitfield.h>
+#include <linux/bits.h>
+#include <linux/cleanup.h>
+#include <linux/delay.h>
+#include <linux/iio/iio.h>
+#include <linux/mod_devicetable.h>
+#include <linux/module.h>
+#include <linux/platform_device.h>
+#include <linux/property.h>
+#include <linux/regmap.h>
+#include <linux/types.h>
+
+#include <linux/mfd/mt6397/core.h>
+#include <linux/mfd/mt6323/registers.h>
+
+#include <dt-bindings/iio/adc/mediatek,mt6323-auxadc.h>
+
+#define AUXADC_RSTB_SEL		BIT(7)
+#define AUXADC_RSTB_SW		BIT(5)
+
+#define AUXADC_CTL_CK		BIT(5)
+
+#define AUXADC_TRIM_CH2		(3 << 10)
+#define AUXADC_TRIM_CH4		(3 << 8)
+#define AUXADC_TRIM_CH5		(3 << 4)
+#define AUXADC_TRIM_CH6		(3 << 2)
+
+#define AUXADC_VREF18_ENB_MD	BIT(15)
+#define AUXADC_MD_STATUS	BIT(0)
+
+#define AUXADC_GPS_STATUS	BIT(1)
+
+#define AUXADC_VREF18_SELB	BIT(1)
+#define AUXADC_DECI_GDLY_SEL	BIT(0)
+
+#define AUXADC_VBUF_EN		BIT(4)
+
+#define AUXADC_DECI_GDLY_MASK		GENMASK(15, 14)
+#define AUXADC_ADC19_BUSY_MASK		GENMASK(15, 0)
+#define AUXADC_RDY_MASK			BIT(15)
+#define AUXADC_DATA_MASK		GENMASK(14, 0)
+#define AUXADC_OSR_MASK			GENMASK(12, 10)
+#define AUXADC_LOW_CHANNEL_MASK		GENMASK(9, 0)
+#define AUXADC_AUDIO_CHANNEL_MASK	GENMASK(8, 0)
+
+#define MTK_PMIC_IIO_CHAN(_name, _idx, _ch_type) \
+	{ .type = _ch_type,                              \
+	  .indexed = 1,                                  \
+	  .channel = _idx,                               \
+	  .address = _idx,                               \
+	  .datasheet_name = __stringify(_name),          \
+	  .info_mask_separate = BIT(IIO_CHAN_INFO_RAW) | \
+				BIT(IIO_CHAN_INFO_SCALE) }
+
+static const struct iio_chan_spec mt6323_auxadc_channels[] = {
+	MTK_PMIC_IIO_CHAN(baton2, MT6323_AUXADC_BATON2, IIO_VOLTAGE),
+	MTK_PMIC_IIO_CHAN(ch6, MT6323_AUXADC_CH6, IIO_VOLTAGE),
+	MTK_PMIC_IIO_CHAN(bat_temp, MT6323_AUXADC_BAT_TEMP, IIO_TEMP),
+	MTK_PMIC_IIO_CHAN(chip_temp, MT6323_AUXADC_CHIP_TEMP, IIO_TEMP),
+	MTK_PMIC_IIO_CHAN(vcdt, MT6323_AUXADC_VCDT, IIO_VOLTAGE),
+	MTK_PMIC_IIO_CHAN(baton1, MT6323_AUXADC_BATON1, IIO_VOLTAGE),
+	MTK_PMIC_IIO_CHAN(isense, MT6323_AUXADC_ISENSE, IIO_VOLTAGE),
+	MTK_PMIC_IIO_CHAN(batsns, MT6323_AUXADC_BATSNS, IIO_VOLTAGE),
+	MTK_PMIC_IIO_CHAN(accdet, MT6323_AUXADC_ACCDET, IIO_VOLTAGE),
+};
+
+/**
+ * struct mt6323_auxadc - Main driver structure
+ * @dev:           Device pointer
+ * @regmap:        Regmap from PWRAP
+ * @lock:          Mutex to serialize AUXADC reading vs configuration
+ */
+struct mt6323_auxadc {
+	struct device *dev;
+	struct regmap *regmap;
+	struct mutex lock;
+};
+
+static u32 mt6323_auxadc_channel_to_reg(unsigned long channel)
+{
+	switch (channel) {
+	case 0:
+		return MT6323_AUXADC_ADC6;
+	case 1:
+		return MT6323_AUXADC_ADC11;
+	case 2:
+		return MT6323_AUXADC_ADC5;
+	case 3:
+		return MT6323_AUXADC_ADC4;
+	case 4:
+		return MT6323_AUXADC_ADC2;
+	case 5:
+		return MT6323_AUXADC_ADC3;
+	case 6:
+		return MT6323_AUXADC_ADC1;
+	case 7:
+		return MT6323_AUXADC_ADC0;
+	case 8:
+		return MT6323_AUXADC_ADC7;
+	default:
+		return MT6323_AUXADC_ADC17;
+	}
+}
+
+static int mt6323_auxadc_check_if_stuck(struct mt6323_auxadc *auxadc)
+{
+	int i, ret;
+	u32 val;
+
+	for (i = 0; i < 50; i++) {
+		ret = regmap_read(auxadc->regmap, MT6323_AUXADC_CON19, &val);
+		if (ret)
+			return ret;
+
+		if (FIELD_GET(AUXADC_DECI_GDLY_MASK, val)) {
+			ret = regmap_read(auxadc->regmap, MT6323_AUXADC_ADC19,
+					  &val);
+			if (ret)
+				return ret;
+
+			if (!FIELD_GET(AUXADC_ADC19_BUSY_MASK, val)) {
+				ret = regmap_update_bits(
+					auxadc->regmap, MT6323_AUXADC_CON19,
+					FIELD_PREP(AUXADC_DECI_GDLY_MASK, 3),
+					0x0);
+				if (ret)
+					return ret;
+			}
+		} else {
+			return 0;
+		}
+
+		fsleep(10);
+	}
+
+	return -ETIMEDOUT;
+}
+
+static int mt6323_auxadc_request(struct mt6323_auxadc *auxadc,
+				 unsigned long channel)
+{
+	int ret;
+	u32 pmic_val, adc_val;
+
+	if (channel < 9) {
+		ret = regmap_update_bits(auxadc->regmap, MT6323_AUXADC_CON11,
+					 AUXADC_VBUF_EN, AUXADC_VBUF_EN);
+		if (ret)
+			return ret;
+
+		ret = regmap_read(auxadc->regmap, MT6323_AUXADC_CON22,
+				  &pmic_val);
+		if (ret)
+			return ret;
+
+		adc_val = FIELD_GET(AUXADC_LOW_CHANNEL_MASK, pmic_val);
+		adc_val &= ~BIT(channel);
+
+		ret = regmap_update_bits(auxadc->regmap, MT6323_AUXADC_CON22,
+					 AUXADC_LOW_CHANNEL_MASK, adc_val);
+		if (ret)
+			return ret;
+
+		ret = regmap_read(auxadc->regmap, MT6323_AUXADC_CON22,
+				  &pmic_val);
+		if (ret)
+			return ret;
+
+		adc_val = FIELD_GET(AUXADC_LOW_CHANNEL_MASK, pmic_val);
+		adc_val |= BIT(channel);
+
+		ret = regmap_update_bits(auxadc->regmap, MT6323_AUXADC_CON22,
+					 AUXADC_LOW_CHANNEL_MASK, adc_val);
+
+	} else {
+		ret = regmap_read(auxadc->regmap, MT6323_AUXADC_CON23,
+				  &pmic_val);
+		if (ret)
+			return ret;
+
+		adc_val = FIELD_GET(AUXADC_AUDIO_CHANNEL_MASK, pmic_val);
+		adc_val &= ~BIT(channel - 9);
+
+		ret = regmap_update_bits(auxadc->regmap, MT6323_AUXADC_CON23,
+					 AUXADC_AUDIO_CHANNEL_MASK, adc_val);
+		if (ret)
+			return ret;
+
+		ret = regmap_read(auxadc->regmap, MT6323_AUXADC_CON23,
+				  &pmic_val);
+		if (ret)
+			return ret;
+
+		adc_val = FIELD_GET(AUXADC_AUDIO_CHANNEL_MASK, pmic_val);
+		adc_val |= BIT(channel - 9);
+
+		ret = regmap_update_bits(auxadc->regmap, MT6323_AUXADC_CON23,
+					 AUXADC_AUDIO_CHANNEL_MASK, adc_val);
+	}
+
+	return ret;
+}
+
+static int mt6323_auxadc_read(struct mt6323_auxadc *auxadc,
+			      const struct iio_chan_spec *chan, int *out)
+{
+	int ret;
+	u32 reg = mt6323_auxadc_channel_to_reg(chan->address);
+	u32 val;
+
+	ret = regmap_read_poll_timeout(auxadc->regmap, reg, val,
+				       (val & AUXADC_RDY_MASK), 1000, 100000);
+	if (ret)
+		return ret;
+
+	*out = FIELD_GET(AUXADC_DATA_MASK, val);
+
+	return 0;
+}
+
+static int mt6323_auxadc_read_raw(struct iio_dev *indio_dev,
+				  const struct iio_chan_spec *chan, int *val,
+				  int *val2, long mask)
+{
+	struct mt6323_auxadc *auxadc = iio_priv(indio_dev);
+	int ret, mult = 1;
+
+	if (mask == IIO_CHAN_INFO_RAW) {
+		scoped_guard(mutex, &auxadc->lock)
+		{
+			ret = mt6323_auxadc_check_if_stuck(auxadc);
+			if (ret)
+				return ret;
+
+			ret = mt6323_auxadc_request(auxadc, chan->address);
+			if (ret)
+				return ret;
+
+			usleep_range(300, 500);
+
+			ret = mt6323_auxadc_read(auxadc, chan, val);
+			if (ret)
+				return ret;
+			return IIO_VAL_INT;
+		}
+	} else if (mask == IIO_CHAN_INFO_SCALE) {
+		if (chan->channel == MT6323_AUXADC_ISENSE ||
+		    chan->address == MT6323_AUXADC_BATSNS)
+			mult = 4;
+
+		*val = mult * 1800;
+		*val2 = 32768;
+
+		return IIO_VAL_FRACTIONAL;
+	} else
+		return -EINVAL;
+}
+
+static int mt6323_auxadc_init(struct mt6323_auxadc *auxadc)
+{
+	int ret;
+
+	ret = regmap_update_bits(auxadc->regmap, MT6323_STRUP_CON10,
+				 AUXADC_RSTB_SW | AUXADC_RSTB_SEL,
+				 AUXADC_RSTB_SW | AUXADC_RSTB_SEL);
+	if (ret)
+		return ret;
+
+	ret = regmap_update_bits(auxadc->regmap, MT6323_TOP_CKPDN2,
+				 AUXADC_CTL_CK, AUXADC_CTL_CK);
+	if (ret)
+		return ret;
+
+	ret = regmap_update_bits(auxadc->regmap, MT6323_AUXADC_CON10,
+				 AUXADC_TRIM_CH2 | AUXADC_TRIM_CH4 |
+					 AUXADC_TRIM_CH5 | AUXADC_TRIM_CH6,
+				 AUXADC_TRIM_CH2 | AUXADC_TRIM_CH4 |
+					 AUXADC_TRIM_CH5 | AUXADC_TRIM_CH6);
+	if (ret)
+		return ret;
+
+	ret = regmap_update_bits(auxadc->regmap, MT6323_AUXADC_CON27,
+				 AUXADC_VREF18_ENB_MD | AUXADC_MD_STATUS,
+				 AUXADC_VREF18_ENB_MD | AUXADC_MD_STATUS);
+	if (ret)
+		return ret;
+
+	ret = regmap_update_bits(auxadc->regmap, MT6323_AUXADC_CON19,
+				 AUXADC_GPS_STATUS, AUXADC_GPS_STATUS);
+	if (ret)
+		return ret;
+
+	ret = regmap_update_bits(auxadc->regmap, MT6323_AUXADC_CON26,
+				 AUXADC_VREF18_SELB | AUXADC_DECI_GDLY_SEL,
+				 AUXADC_VREF18_SELB | AUXADC_DECI_GDLY_SEL);
+	if (ret)
+		return ret;
+
+	ret = regmap_update_bits(auxadc->regmap, MT6323_AUXADC_CON9,
+				 AUXADC_OSR_MASK,
+				 FIELD_PREP(AUXADC_OSR_MASK, 3));
+	return ret;
+}
+
+static const struct iio_info mt6323_auxadc_iio_info = {
+	.read_raw = mt6323_auxadc_read_raw,
+};
+
+static int mt6323_auxadc_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct mt6323_auxadc *auxadc;
+	struct iio_dev *iio;
+	struct regmap *regmap;
+	int ret;
+
+	/* mfd->pwrap regmap */
+	regmap = dev_get_regmap(dev->parent->parent, NULL);
+	if (!regmap)
+		return dev_err_probe(dev, -ENODEV, "failed to get regmap\n");
+
+	iio = devm_iio_device_alloc(dev, sizeof(*auxadc));
+	if (!iio)
+		return -ENOMEM;
+
+	auxadc = iio_priv(iio);
+	auxadc->regmap = regmap;
+	auxadc->dev = dev;
+	mutex_init(&auxadc->lock);
+
+	ret = mt6323_auxadc_init(auxadc);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to initialize auxadc\n");
+
+	iio->name = "mt6323-auxadc";
+	iio->info = &mt6323_auxadc_iio_info;
+	iio->modes = INDIO_DIRECT_MODE;
+	iio->channels = mt6323_auxadc_channels;
+	iio->num_channels = ARRAY_SIZE(mt6323_auxadc_channels);
+
+	ret = devm_iio_device_register(dev, iio);
+	if (ret)
+		return dev_err_probe(dev, ret,
+				     "failed to register iio device\n");
+
+	return 0;
+}
+
+static const struct of_device_id mt6323_auxadc_of_match[] = {
+	{ .compatible = "mediatek,mt6323-auxadc" },
+	{}
+};
+MODULE_DEVICE_TABLE(of, mt6323_auxadc_of_match);
+
+static struct platform_driver mt6323_auxadc_driver = {
+	.driver = {
+		.name = "mt6323-auxadc",
+		.of_match_table = mt6323_auxadc_of_match,
+	},
+	.probe	= mt6323_auxadc_probe,
+};
+module_platform_driver(mt6323_auxadc_driver);
+
+MODULE_LICENSE("GPL");
+MODULE_DESCRIPTION("MediaTek MT6323 PMIC AUXADC Driver");

-- 
2.53.0

