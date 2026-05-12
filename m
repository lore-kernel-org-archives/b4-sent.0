From: Roman Vivchar <rva333@protonmail.com>
Date: Tue, 12 May 2026 08:18:21 +0300
Subject: [PATCH v2 07/16] thermal: mediatek: add PMIC thermal support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260512-mt6323-v2-7-3efcba579e88@protonmail.com>
References: <20260512-mt6323-v2-0-3efcba579e88@protonmail.com>
In-Reply-To: <20260512-mt6323-v2-0-3efcba579e88@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sen Chu <sen.chu@mediatek.com>, Sean Wang <sean.wang@mediatek.com>, 
 Macpaul Lin <macpaul.lin@mediatek.com>, Lee Jones <lee@kernel.org>, 
 Roman Vivchar <rva333@protonmail.com>, 
 Srinivas Kandagatla <srini@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-pm@vger.kernel.org, 
 Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778563297; l=10834;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=hFPKqOXKCcLpfpEXwQPfAbklB9z0WWe06BxV3k4lbl0=;
 b=W7+nLGUmil4AW4098hS8aWRWFoE4tvASPMNKwu1CRViNnKb8P1z9VbvdNfeWsCAxUKJg0ZSKi
 1FBejqdmVWwAiOV+pSHep8d/dhdN01QEVD+JqQjlRa6YieW2Jrt4W04
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new driver to support thermal monitoring on MediaTek PMICs.

The driver retrieves calibration data from EFUSE, calculates the
temperature using a linear interpolation, and registers the device with
the thermal framework.

Initial support is added for the mt6323 PMIC.

Tested-by: Ben Grisdale <bengris32@protonmail.ch> # Amazon Echo Dot (2nd Generation)
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/thermal/mediatek/Kconfig            |  12 ++
 drivers/thermal/mediatek/Makefile           |   1 +
 drivers/thermal/mediatek/mtk_pmic_thermal.c | 316 ++++++++++++++++++++++++++++
 3 files changed, 329 insertions(+)

diff --git a/drivers/thermal/mediatek/Kconfig b/drivers/thermal/mediatek/Kconfig
index d82c86d9be56..8320d109fde6 100644
--- a/drivers/thermal/mediatek/Kconfig
+++ b/drivers/thermal/mediatek/Kconfig
@@ -34,4 +34,16 @@ config MTK_LVTS_THERMAL_DEBUGFS
        help
          Enable this option to debug the internals of the device driver.
 
+config MTK_PMIC_THERMAL
+	tristate "AUXADC temperature sensor driver for MediaTek PMICs"
+	depends on MFD_MT6397
+	help
+	  Enable this option if you want to get PMIC temperature
+	  information for MediaTek platforms.
+	  This driver configures thermal controllers to collect
+	  temperature via AUXADC interface.
+
+	  This driver can also be built as a module. If so, the module will be
+	  called mtk_pmic_thermal.
+
 endif
diff --git a/drivers/thermal/mediatek/Makefile b/drivers/thermal/mediatek/Makefile
index 1c6daa1e644b..bfb3b6f02539 100644
--- a/drivers/thermal/mediatek/Makefile
+++ b/drivers/thermal/mediatek/Makefile
@@ -1,2 +1,3 @@
 obj-$(CONFIG_MTK_SOC_THERMAL)	+= auxadc_thermal.o
 obj-$(CONFIG_MTK_LVTS_THERMAL)	+= lvts_thermal.o
+obj-$(CONFIG_MTK_PMIC_THERMAL)	+= mtk_pmic_thermal.o
diff --git a/drivers/thermal/mediatek/mtk_pmic_thermal.c b/drivers/thermal/mediatek/mtk_pmic_thermal.c
new file mode 100644
index 000000000000..f644dad15fc2
--- /dev/null
+++ b/drivers/thermal/mediatek/mtk_pmic_thermal.c
@@ -0,0 +1,316 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2026 Roman Vivchar <rva333@protonmail.com>
+ *
+ * Based on drivers/thermal/mediatek/auxadc_thermal.c
+ */
+
+#include <linux/bitfield.h>
+#include <linux/bits.h>
+#include <linux/cleanup.h>
+#include <linux/err.h>
+#include <linux/iio/consumer.h>
+#include <linux/kernel.h>
+#include <linux/module.h>
+#include <linux/nvmem-consumer.h>
+#include <linux/platform_device.h>
+#include <linux/property.h>
+#include <linux/regmap.h>
+#include <linux/slab.h>
+#include <linux/thermal.h>
+#include <linux/units.h>
+
+#include <linux/mfd/mt6323/registers.h>
+
+#define MAX_SENSORS			1
+
+#define MT6323_TEMP_MIN			(-20 * MILLIDEGREE_PER_DEGREE)
+#define MT6323_TEMP_MAX			(50 * MILLIDEGREE_PER_DEGREE)
+
+/* Layout of the fuses providing the calibration data */
+#define CALIB_BUF0_VTS_MASK		GENMASK(15, 8)
+#define CALIB_BUF0_DEGC_CALI_MASK	GENMASK(7, 2)
+#define CALIB_BUF0_ADC_CALI_EN_MASK	BIT(1)
+
+#define CALIB_BUF1_ID_20_MASK		BIT(14)
+#define CALIB_BUF1_ID_10_MASK		BIT(12)
+#define CALIB_BUF1_O_SLOPE_20_HI	GENMASK(13, 11)
+#define CALIB_BUF1_O_SLOPE_20_LO	GENMASK(8, 6)
+#define CALIB_BUF1_O_SLOPE_10_MASK	GENMASK(11, 6)
+#define CALIB_BUF1_O_SLOPE_SIGN_MASK	BIT(5)
+#define CALIB_BUF1_VTS_MASK		GENMASK(4, 0)
+
+#define MT6323_CALIBRATION		171
+#define MT6323_ADC_VOLTAGE_RANGE	1800
+#define MT6323_ADC_RESOLUTION		32768
+#define MT6323_ADC_VBE_OFFSET		9102
+
+#define MT6323_DEFAULT_VTS		3698
+#define MT6323_DEFAULT_DEGC_CALI	50
+#define MT6323_DEFAULT_SLOPE		0
+#define MT6323_DEFAULT_SLOPE_SIGN	0
+
+struct mtk_pmic_thermal;
+
+struct mtk_thermal_data {
+	const char *const *sensors;
+	s32 num_sensors;
+
+	int (*extract_efuse)(struct mtk_pmic_thermal *mt, u16 *buf);
+	void (*precalc)(struct mtk_pmic_thermal *mt, s32 vts, s32 degc_cali,
+			s32 o_slope, s32 o_slope_sign);
+};
+
+struct mtk_pmic_sensor {
+	struct mtk_pmic_thermal *mt;
+	struct iio_channel *adc_channel;
+	struct thermal_zone_device *tzdev;
+
+	int id;
+};
+
+struct mtk_pmic_thermal {
+	struct device *dev;
+	struct regmap *regmap;
+	const struct mtk_thermal_data *data;
+
+	struct mtk_pmic_sensor sensors[MAX_SENSORS];
+
+	s32 t_slope1;
+	s32 t_slope2;
+	s32 t_intercept;
+};
+
+static bool mtk_pmic_thermal_temp_is_valid(int temp)
+{
+	return (temp >= MT6323_TEMP_MIN) && (temp <= MT6323_TEMP_MAX);
+}
+
+static int mtk_pmic_read_temp(struct thermal_zone_device *tz, int *temperature)
+{
+	struct mtk_pmic_sensor *sensor = thermal_zone_device_priv(tz);
+	int ret, raw, temp;
+
+	ret = iio_read_channel_processed(sensor->adc_channel, &raw);
+	if (ret < 0) {
+		dev_err(sensor->mt->dev, "failed to read iio channel: %d\n",
+			ret);
+		return ret;
+	}
+
+	/*
+	 *                 slope1 * V
+	 * t = Intercept + ----------
+	 *                   slope2
+	 */
+	temp = sensor->mt->t_intercept +
+	       (sensor->mt->t_slope1 * raw) / sensor->mt->t_slope2;
+
+	if (!mtk_pmic_thermal_temp_is_valid(temp))
+		return -EINVAL;
+
+	*temperature = temp;
+	return 0;
+}
+
+static const struct thermal_zone_device_ops mtk_pmic_thermal_ops = {
+	.get_temp = mtk_pmic_read_temp,
+};
+
+static void mtk_pmic_thermal_precalc_mt6323(struct mtk_pmic_thermal *mt,
+					    s32 vts, s32 degc_cali, s32 o_slope,
+					    s32 o_slope_sign)
+{
+	s32 vbe_t;
+
+	mt->t_slope1 = 100 * MILLIDEGREE_PER_DEGREE;
+
+	/*
+	 * Temperature coefficient. The o_slope is a trim value applied to
+	 * the base calibration
+	 */
+	if (o_slope_sign == 0)
+		mt->t_slope2 = -(MT6323_CALIBRATION + o_slope);
+	else
+		mt->t_slope2 = -(MT6323_CALIBRATION - o_slope);
+
+	/*
+	 *                 (Vraw + offset) * Vref
+	 * Vbe (mV) = -1 * ---------------------- * 1000
+	 *                      adc_resolution
+	 */
+	vbe_t = (vts + MT6323_ADC_VBE_OFFSET) * MT6323_ADC_VOLTAGE_RANGE;
+	vbe_t = -1 * (vbe_t / MT6323_ADC_RESOLUTION) * MILLIDEGREE_PER_DEGREE;
+
+	/* Intercept adjusts minimal temperature margin with degc_cali offset */
+	mt->t_intercept = vbe_t * 100 / mt->t_slope2;
+	mt->t_intercept += degc_cali * MILLIDEGREE_PER_DEGREE / 2;
+}
+
+static int mtk_pmic_thermal_extract_efuse_mt6323(struct mtk_pmic_thermal *mt,
+						 u16 *buf)
+{
+	u32 reg;
+	s32 vts, degc_cali, o_slope, o_slope_sign, id;
+	int ret;
+
+	if (!FIELD_GET(CALIB_BUF0_ADC_CALI_EN_MASK, buf[0]))
+		return -EINVAL;
+
+	/* Voltage offset */
+	vts = (FIELD_GET(CALIB_BUF1_VTS_MASK, buf[1]) << 8) |
+	      FIELD_GET(CALIB_BUF0_VTS_MASK, buf[0]);
+
+	/* Reference temperature for the vts */
+	degc_cali = FIELD_GET(CALIB_BUF0_DEGC_CALI_MASK, buf[0]);
+
+	o_slope_sign = FIELD_GET(CALIB_BUF1_O_SLOPE_SIGN_MASK, buf[1]);
+
+	ret = regmap_read(mt->regmap, MT6323_CID, &reg);
+	if (ret) {
+		dev_err(mt->dev, "failed to read chip id\n");
+		return ret;
+	}
+
+	if (reg == 0x1023) {
+		o_slope = FIELD_GET(CALIB_BUF1_O_SLOPE_10_MASK, buf[1]);
+		id = FIELD_GET(CALIB_BUF1_ID_10_MASK, buf[1]);
+	} else if (reg == 0x2023) {
+		o_slope = (FIELD_GET(CALIB_BUF1_O_SLOPE_20_HI, buf[1]) << 3) |
+			  FIELD_GET(CALIB_BUF1_O_SLOPE_20_LO, buf[1]);
+		id = FIELD_GET(CALIB_BUF1_ID_20_MASK, buf[1]);
+	} else {
+		dev_err(mt->dev, "invalid chip id: 0x%x\n", reg);
+		return -EINVAL;
+	}
+
+	if (id == 0)
+		o_slope = 0;
+
+	mt->data->precalc(mt, vts, degc_cali, o_slope, o_slope_sign);
+
+	return 0;
+}
+
+static int mtk_pmic_thermal_get_calib_data(struct device *dev,
+					   struct mtk_pmic_thermal *mt)
+{
+	void *buf __free(kfree) = NULL;
+	struct nvmem_cell *cell;
+	size_t len;
+	int ret;
+
+	cell = nvmem_cell_get(dev, NULL);
+	if (IS_ERR(cell))
+		return PTR_ERR(cell);
+
+	buf = nvmem_cell_read(cell, &len);
+	nvmem_cell_put(cell);
+
+	if (IS_ERR(buf)) {
+		ret = PTR_ERR(buf);
+		buf = NULL;
+		return ret;
+	}
+
+	if (len < 2 * sizeof(u16)) {
+		dev_err(dev, "invalid calibration data length\n");
+		return -EINVAL;
+	}
+
+	ret = mt->data->extract_efuse(mt, buf);
+	if (ret) {
+		dev_info(dev, "device not calibrated, using default values\n");
+		mt->data->precalc(mt, MT6323_DEFAULT_VTS,
+				  MT6323_DEFAULT_DEGC_CALI,
+				  MT6323_DEFAULT_SLOPE,
+				  MT6323_DEFAULT_SLOPE_SIGN);
+	}
+
+	return 0;
+}
+
+static int mtk_pmic_thermal_init_sensor(struct mtk_pmic_thermal *mt, int id)
+{
+	struct mtk_pmic_sensor *sensor = &mt->sensors[id];
+	struct device *dev = mt->dev;
+
+	sensor->id = id;
+	sensor->mt = mt;
+
+	if (mt->data->num_sensors > 1)
+		sensor->adc_channel = devm_iio_channel_get(dev, mt->data->sensors[id]);
+	else
+		sensor->adc_channel = devm_iio_channel_get(dev, NULL);
+
+	if (IS_ERR(sensor->adc_channel))
+		return dev_err_probe(dev, PTR_ERR(sensor->adc_channel),
+				     "failed to get channel %s\n",
+				     mt->data->sensors[id]);
+
+	sensor->tzdev = devm_thermal_of_zone_register(dev, id, sensor,
+						      &mtk_pmic_thermal_ops);
+	if (IS_ERR(sensor->tzdev))
+		return dev_err_probe(dev, PTR_ERR(sensor->tzdev),
+				     "failed to register thermal zone %d\n", id);
+
+	return 0;
+}
+
+static int mtk_pmic_thermal_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct mtk_pmic_thermal *mt;
+	int ret;
+
+	mt = devm_kzalloc(dev, sizeof(*mt), GFP_KERNEL);
+	if (!mt)
+		return -ENOMEM;
+
+	mt->regmap = dev_get_regmap(dev->parent->parent, NULL);
+	if (!mt->regmap)
+		return dev_err_probe(dev, -ENODEV, "failed to get regmap");
+
+	mt->dev = dev;
+	mt->data = device_get_match_data(dev);
+
+	ret = mtk_pmic_thermal_get_calib_data(dev, mt);
+	if (ret)
+		return ret;
+
+	for (int i = 0; i < mt->data->num_sensors; i++) {
+		ret = mtk_pmic_thermal_init_sensor(mt, i);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+static const char *const mt6323_adc_channels[] = { "vts" };
+
+static const struct mtk_thermal_data mt6323_thermal_data = {
+	.sensors = mt6323_adc_channels,
+	.num_sensors = ARRAY_SIZE(mt6323_adc_channels),
+	.extract_efuse = mtk_pmic_thermal_extract_efuse_mt6323,
+	.precalc = mtk_pmic_thermal_precalc_mt6323,
+};
+
+static const struct of_device_id mtk_pmic_thermal_of_match[] = {
+	{ .compatible = "mediatek,mt6323-thermal",
+	  .data = &mt6323_thermal_data },
+	{ /* sentinel */ },
+};
+MODULE_DEVICE_TABLE(of, mtk_pmic_thermal_of_match);
+
+static struct platform_driver mtk_pmic_thermal_driver = {
+	.probe = mtk_pmic_thermal_probe,
+	.driver = {
+		.name = "mtk-pmic-thermal",
+		.of_match_table = mtk_pmic_thermal_of_match,
+	},
+};
+module_platform_driver(mtk_pmic_thermal_driver);
+
+MODULE_DESCRIPTION("MediaTek PMIC thermal driver");
+MODULE_LICENSE("GPL");

-- 
2.54.0

