From: Roman Vivchar <rva333@protonmail.com>
Date: Thu, 09 Jul 2026 13:52:48 +0300
Subject: [PATCH v5 2/4] iio: adc: mt6323-auxadc: add mt6323 PMIC AUXADC
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260709-mt6323-adc-v5-2-d11b8332a735@protonmail.com>
References: <20260709-mt6323-adc-v5-0-d11b8332a735@protonmail.com>
In-Reply-To: <20260709-mt6323-adc-v5-0-d11b8332a735@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Lee Jones <lee@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, Ben Grisdale <bengris32@protonmail.ch>, 
 Roman Vivchar <rva333@protonmail.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783594368; l=12074;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=cdo2n4utcrxfxA30v7GaqTLAN07hVaOJ8J00i2r47v8=;
 b=K1Qexdec+rvZH+fj2iqi1fh0euQUtDdT1ke13Qr7DF0tLSZyhAiCCGJCIxf4Z3NpA4XyXSjy7
 hDduw6NNqk5C1cf8cQhSp2ll7DriipRYmo+K+78SMVMD3uMLrxYvhYi
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The mt6323 AUXADC is a 15-bit ADC used for system monitoring. This driver
provides support for reading various channels including battery and
charger voltages, battery and chip temperature, current sensing and
accessory detection.

Add a driver for the AUXADC found in the MediaTek mt6323 PMIC.

Tested-by: Ben Grisdale <bengris32@protonmail.ch> # Amazon Echo Dot (2nd Generation)
Reviewed-by: Andy Shevchenko <andriy.shevchenko@intel.com>
Reviewed-by: David Lechner <dlechner@baylibre.com>
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 MAINTAINERS                     |   1 +
 drivers/iio/adc/Kconfig         |  11 ++
 drivers/iio/adc/Makefile        |   1 +
 drivers/iio/adc/mt6323-auxadc.c | 314 ++++++++++++++++++++++++++++++++++++++++
 4 files changed, 327 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 86b9a35c3d20..69c157edb92f 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -16582,6 +16582,7 @@ MEDIATEK MT6323 PMIC AUXADC DRIVER
 M:	Roman Vivchar <rva333@protonmail.com>
 L:	linux-iio@vger.kernel.org
 S:	Maintained
+F:	drivers/iio/adc/mt6323-auxadc.c
 F:	include/dt-bindings/iio/adc/mediatek,mt6323-auxadc.h
 
 MEDIATEK MT6735 CLOCK & RESET DRIVERS
diff --git a/drivers/iio/adc/Kconfig b/drivers/iio/adc/Kconfig
index bc21034078b5..8035e5313153 100644
--- a/drivers/iio/adc/Kconfig
+++ b/drivers/iio/adc/Kconfig
@@ -1166,6 +1166,17 @@ config MCP3911
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
index 707dd708912f..dc24d0ae76a5 100644
--- a/drivers/iio/adc/Makefile
+++ b/drivers/iio/adc/Makefile
@@ -100,6 +100,7 @@ obj-$(CONFIG_MCP320X) += mcp320x.o
 obj-$(CONFIG_MCP3422) += mcp3422.o
 obj-$(CONFIG_MCP3564) += mcp3564.o
 obj-$(CONFIG_MCP3911) += mcp3911.o
+obj-$(CONFIG_MEDIATEK_MT6323_AUXADC) += mt6323-auxadc.o
 obj-$(CONFIG_MEDIATEK_MT6359_AUXADC) += mt6359-auxadc.o
 obj-$(CONFIG_MEDIATEK_MT6360_ADC) += mt6360-adc.o
 obj-$(CONFIG_MEDIATEK_MT6370_ADC) += mt6370-adc.o
diff --git a/drivers/iio/adc/mt6323-auxadc.c b/drivers/iio/adc/mt6323-auxadc.c
new file mode 100644
index 000000000000..c450fb6f09cb
--- /dev/null
+++ b/drivers/iio/adc/mt6323-auxadc.c
@@ -0,0 +1,314 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2026 Roman Vivchar <rva333@protonmail.com>
+ *
+ * Based on drivers/iio/adc/mt6359-auxadc.c
+ */
+
+#include <linux/array_size.h>
+#include <linux/bitfield.h>
+#include <linux/bits.h>
+#include <linux/cleanup.h>
+#include <linux/delay.h>
+#include <linux/iio/iio.h>
+#include <linux/mod_devicetable.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/platform_device.h>
+#include <linux/regmap.h>
+#include <linux/stringify.h>
+#include <linux/time.h>
+#include <linux/types.h>
+
+#include <linux/mfd/mt6323/registers.h>
+
+#include <dt-bindings/iio/adc/mediatek,mt6323-auxadc.h>
+
+#define AUXADC_STRUP_CON10_RSTB_SEL	BIT(7)
+#define AUXADC_STRUP_CON10_RSTB_SW	BIT(5)
+
+#define AUXADC_TOP_CKPDN2_CTL_CK	BIT(5)
+
+#define AUXADC_TRIM_CH2_MASK		GENMASK(11, 10)
+#define AUXADC_TRIM_CH4_MASK		GENMASK(9, 8)
+#define AUXADC_TRIM_CH5_MASK		GENMASK(5, 4)
+#define AUXADC_TRIM_CH6_MASK		GENMASK(3, 2)
+
+#define AUXADC_CON27_VREF18_ENB_MD	BIT(15)
+#define AUXADC_CON27_MD_STATUS		BIT(0)
+
+#define AUXADC_CON19_GPS_STATUS		BIT(1)
+
+#define AUXADC_CON26_VREF18_SELB	BIT(1)
+#define AUXADC_CON26_DECI_GDLY_SEL	BIT(0)
+
+#define AUXADC_CON11_VBUF_EN		BIT(4)
+
+#define AUXADC_CON19_DECI_GDLY_MASK	GENMASK(15, 14)
+#define AUXADC_ADC19_BUSY_MASK		GENMASK(15, 1)
+#define AUXADC_READY_MASK		BIT(15)
+#define AUXADC_DATA_MASK		GENMASK(14, 0)
+
+#define AUXADC_CON9_OSR_MASK		GENMASK(12, 10)
+#define AUXADC_DEFAULT_OSR		3
+
+#define MTK_PMIC_IIO_CHAN(_name, _chan, _addr)                  \
+{                                                               \
+	.type = IIO_VOLTAGE,                                    \
+	.indexed = 1,                                           \
+	.channel = _chan,                                       \
+	.address = _addr,                                       \
+	.datasheet_name = __stringify(_name),                   \
+	.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |          \
+			      BIT(IIO_CHAN_INFO_SCALE),         \
+}
+
+/*
+ * AUXADC reports everything in mV, including temperature and
+ * current channels. Channel macros are mapped such that their
+ * ID matches their respective hardware bit position in CON22.
+ */
+static const struct iio_chan_spec mt6323_auxadc_channels[] = {
+	MTK_PMIC_IIO_CHAN(baton2,    MT6323_AUXADC_BATON2,    MT6323_AUXADC_ADC6),
+	MTK_PMIC_IIO_CHAN(ch6,       MT6323_AUXADC_CH6,       MT6323_AUXADC_ADC11),
+	MTK_PMIC_IIO_CHAN(bat_temp,  MT6323_AUXADC_BAT_TEMP,  MT6323_AUXADC_ADC5),
+	MTK_PMIC_IIO_CHAN(chip_temp, MT6323_AUXADC_CHIP_TEMP, MT6323_AUXADC_ADC4),
+	MTK_PMIC_IIO_CHAN(vcdt,      MT6323_AUXADC_VCDT,      MT6323_AUXADC_ADC2),
+	MTK_PMIC_IIO_CHAN(baton1,    MT6323_AUXADC_BATON1,    MT6323_AUXADC_ADC3),
+	MTK_PMIC_IIO_CHAN(isense,    MT6323_AUXADC_ISENSE,    MT6323_AUXADC_ADC1),
+	MTK_PMIC_IIO_CHAN(batsns,    MT6323_AUXADC_BATSNS,    MT6323_AUXADC_ADC0),
+	MTK_PMIC_IIO_CHAN(accdet,    MT6323_AUXADC_ACCDET,    MT6323_AUXADC_ADC7),
+};
+
+/*
+ * The MediaTek MT6323 (as well as a lot of other PMICs) has the following hierarchy:
+ * PMIC AUXADC <- PMIC MFD <- SoC PWRAP (wrapper for PWRAP FSM)
+ *
+ * Therefore, PWRAP regmap should be obtained using dev->parent->parent.
+ */
+struct mt6323_auxadc {
+	struct regmap *regmap;
+	/* AUXADC doesn't support reading multiple channels simultaneously. */
+	struct mutex lock;
+};
+
+static int mt6323_auxadc_prepare_channel(struct mt6323_auxadc *auxadc)
+{
+	struct regmap *map = auxadc->regmap;
+	u32 val;
+	int ret;
+
+	ret = regmap_read(map, MT6323_AUXADC_CON19, &val);
+	if (ret)
+		return ret;
+
+	/* The ADC is idle. */
+	if (!(val & AUXADC_CON19_DECI_GDLY_MASK))
+		return 0;
+
+	ret = regmap_read_poll_timeout(map, MT6323_AUXADC_ADC19,
+				       val, !(val & AUXADC_ADC19_BUSY_MASK),
+				       10, 500);
+	if (ret)
+		return ret;
+
+	return regmap_clear_bits(map, MT6323_AUXADC_CON19,
+				 AUXADC_CON19_DECI_GDLY_MASK);
+}
+
+static int mt6323_auxadc_request(struct mt6323_auxadc *auxadc,
+				 unsigned long channel)
+{
+	struct regmap *map = auxadc->regmap;
+	int ret;
+
+	ret = regmap_set_bits(map, MT6323_AUXADC_CON11, AUXADC_CON11_VBUF_EN);
+	if (ret)
+		return ret;
+
+	return regmap_set_bits(map, MT6323_AUXADC_CON22, BIT(channel));
+}
+
+static int mt6323_auxadc_release(struct mt6323_auxadc *auxadc,
+				 unsigned long channel)
+{
+	struct regmap *map = auxadc->regmap;
+	int ret;
+
+	ret = regmap_clear_bits(map, MT6323_AUXADC_CON22, BIT(channel));
+	if (ret)
+		return ret;
+
+	return regmap_clear_bits(map, MT6323_AUXADC_CON11, AUXADC_CON11_VBUF_EN);
+}
+
+static int mt6323_auxadc_read(struct mt6323_auxadc *auxadc,
+			      const struct iio_chan_spec *chan, int *out)
+{
+	struct regmap *map = auxadc->regmap;
+	u32 val;
+	int ret;
+
+	ret = regmap_read_poll_timeout(map, chan->address,
+				       val, (val & AUXADC_READY_MASK),
+				       1 * USEC_PER_MSEC, 100 * USEC_PER_MSEC);
+	if (ret)
+		return ret;
+
+	*out = FIELD_GET(AUXADC_DATA_MASK, val);
+
+	return 0;
+}
+
+static int mt6323_auxadc_read_raw(struct iio_dev *indio_dev,
+				  const struct iio_chan_spec *chan,
+				  int *val, int *val2, long mask)
+{
+	struct mt6323_auxadc *auxadc = iio_priv(indio_dev);
+	int ret, mult;
+
+	switch (mask) {
+	case IIO_CHAN_INFO_SCALE:
+		if (chan->channel == MT6323_AUXADC_ISENSE ||
+		    chan->channel == MT6323_AUXADC_BATSNS)
+			mult = 4;
+		else
+			mult = 1;
+
+		/* 1800mV full range with 15-bit resolution. */
+		*val = mult * 1800;
+		*val2 = 15;
+
+		return IIO_VAL_FRACTIONAL_LOG2;
+	case IIO_CHAN_INFO_RAW: {
+		guard(mutex)(&auxadc->lock);
+
+		ret = mt6323_auxadc_prepare_channel(auxadc);
+		if (ret)
+			return ret;
+
+		ret = mt6323_auxadc_request(auxadc, chan->channel);
+		if (ret)
+			return ret;
+
+		/* Hardware limitation: the AUXADC needs a delay to become ready. */
+		fsleep(300);
+
+		ret = mt6323_auxadc_read(auxadc, chan, val);
+
+		if (mt6323_auxadc_release(auxadc, chan->channel))
+			dev_err(&indio_dev->dev,
+				"failed to release channel %d\n", chan->channel);
+
+		if (ret)
+			return ret;
+
+		return IIO_VAL_INT;
+	}
+	default:
+		return -EINVAL;
+	}
+}
+
+static int mt6323_auxadc_init(struct mt6323_auxadc *auxadc)
+{
+	struct regmap *map = auxadc->regmap;
+	int ret;
+
+	ret = regmap_set_bits(map, MT6323_STRUP_CON10,
+			      AUXADC_STRUP_CON10_RSTB_SW |
+			      AUXADC_STRUP_CON10_RSTB_SEL);
+	if (ret)
+		return ret;
+
+	ret = regmap_set_bits(map, MT6323_TOP_CKPDN2, AUXADC_TOP_CKPDN2_CTL_CK);
+	if (ret)
+		return ret;
+
+	ret = regmap_update_bits(map, MT6323_AUXADC_CON10,
+				 AUXADC_TRIM_CH2_MASK | AUXADC_TRIM_CH4_MASK |
+				 AUXADC_TRIM_CH5_MASK | AUXADC_TRIM_CH6_MASK,
+				 FIELD_PREP(AUXADC_TRIM_CH2_MASK, 1) |
+				 FIELD_PREP(AUXADC_TRIM_CH4_MASK, 1) |
+				 FIELD_PREP(AUXADC_TRIM_CH5_MASK, 1) |
+				 FIELD_PREP(AUXADC_TRIM_CH6_MASK, 1));
+	if (ret)
+		return ret;
+
+	ret = regmap_set_bits(map, MT6323_AUXADC_CON27,
+			      AUXADC_CON27_VREF18_ENB_MD |
+			      AUXADC_CON27_MD_STATUS);
+	if (ret)
+		return ret;
+
+	ret = regmap_set_bits(map, MT6323_AUXADC_CON19, AUXADC_CON19_GPS_STATUS);
+	if (ret)
+		return ret;
+
+	ret = regmap_set_bits(map, MT6323_AUXADC_CON26,
+			      AUXADC_CON26_VREF18_SELB |
+			      AUXADC_CON26_DECI_GDLY_SEL);
+	if (ret)
+		return ret;
+
+	return regmap_update_bits(map, MT6323_AUXADC_CON9, AUXADC_CON9_OSR_MASK,
+				  FIELD_PREP(AUXADC_CON9_OSR_MASK, AUXADC_DEFAULT_OSR));
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
+	struct regmap *regmap;
+	struct iio_dev *iio;
+	int ret;
+
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
+
+	ret = devm_mutex_init(dev, &auxadc->lock);
+	if (ret)
+		return ret;
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
+	return devm_iio_device_register(dev, iio);
+}
+
+static const struct of_device_id mt6323_auxadc_of_match[] = {
+	{ .compatible = "mediatek,mt6323-auxadc" },
+	{ }
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
2.54.0

