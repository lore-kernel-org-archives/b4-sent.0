From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Fri, 24 Apr 2026 17:45:12 +0200
Subject: [PATCH v5 4/8] thermal: amlogic: Add support for secure monitor
 calibration readout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260424-add-thermal-t7-vim4-v5-4-9040ca36afe2@aliel.fr>
References: <20260424-add-thermal-t7-vim4-v5-0-9040ca36afe2@aliel.fr>
In-Reply-To: <20260424-add-thermal-t7-vim4-v5-0-9040ca36afe2@aliel.fr>
To: Guillaume La Roque <glaroque@baylibre.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pm@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=6342;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=hpmbQYKzAOANOL4Nopof62ezzv9RGoucfmyDUhg4E+s=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ+brCX2zAov63O4XFDX/K982+6x8kaH/VF62rZ6ZnlbuJ
 s8eH/nYUcrCIMbFICumyNI/1/LEu8tHz3zdo54CM4eVCWQIAxenAEykKJ+RYeqTC7Ucf1+1Xp43
 tW5Hqllj0KyMdqM5PE8b1ny7rcYXw8PI0LjXNv/D/+JUUf3E9b/qVzOGFFlJnyx5LJnyrKHymPR
 /RgA=
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some SoCs (e.g. T7) expose thermal calibration data through the secure
monitor rather than a directly accessible eFuse register. Add a use_sm
flag to amlogic_thermal_data to select this path, and retrieve the
firmware handle and tsensor_id from the "amlogic,secure-monitor" DT
phandle with one fixed argument.

Also introduce the amlogic,t7-thermal compatible using this new path.

While refactoring, fix a pre-existing bug where
amlogic_thermal_initialize() was called after
devm_thermal_of_zone_register(), causing the thermal framework to
read an uninitialized trim_info on zone registration.

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 drivers/thermal/amlogic_thermal.c | 112 ++++++++++++++++++++++++++++----------
 1 file changed, 82 insertions(+), 30 deletions(-)

diff --git a/drivers/thermal/amlogic_thermal.c b/drivers/thermal/amlogic_thermal.c
index 5448d772db12a..a0b530624b60c 100644
--- a/drivers/thermal/amlogic_thermal.c
+++ b/drivers/thermal/amlogic_thermal.c
@@ -25,6 +25,7 @@
 #include <linux/platform_device.h>
 #include <linux/regmap.h>
 #include <linux/thermal.h>
+#include <linux/firmware/meson/meson_sm.h>
 
 #include "thermal_hwmon.h"
 
@@ -84,12 +85,14 @@ struct amlogic_thermal_soc_calib_data {
  * @u_efuse_off: register offset to read fused calibration value
  * @calibration_parameters: calibration parameters structure pointer
  * @regmap_config: regmap config for the device
+ * @use_sm: read data from secure monitor instead of efuse
  * This structure is required for configuration of amlogic thermal driver.
  */
 struct amlogic_thermal_data {
 	int u_efuse_off;
 	const struct amlogic_thermal_soc_calib_data *calibration_parameters;
 	const struct regmap_config *regmap_config;
+	bool use_sm;
 };
 
 struct amlogic_thermal {
@@ -100,6 +103,8 @@ struct amlogic_thermal {
 	struct clk *clk;
 	struct thermal_zone_device *tzd;
 	u32 trim_info;
+	struct meson_sm_firmware *sm_fw;
+	u32 tsensor_id;
 };
 
 /*
@@ -133,26 +138,6 @@ static int amlogic_thermal_code_to_millicelsius(struct amlogic_thermal *pdata,
 	return temp;
 }
 
-static int amlogic_thermal_initialize(struct amlogic_thermal *pdata)
-{
-	int ret = 0;
-	int ver;
-
-	regmap_read(pdata->sec_ao_map, pdata->data->u_efuse_off,
-		    &pdata->trim_info);
-
-	ver = TSENSOR_TRIM_VERSION(pdata->trim_info);
-
-	if ((ver & TSENSOR_TRIM_CALIB_VALID_MASK) == 0) {
-		ret = -EINVAL;
-		dev_err(&pdata->pdev->dev,
-			"tsensor thermal calibration not supported: 0x%x!\n",
-			ver);
-	}
-
-	return ret;
-}
-
 static int amlogic_thermal_enable(struct amlogic_thermal *data)
 {
 	int ret;
@@ -190,6 +175,67 @@ static int amlogic_thermal_get_temp(struct thermal_zone_device *tz, int *temp)
 	return 0;
 }
 
+static int amlogic_thermal_probe_sm(struct platform_device *pdev,
+				    struct amlogic_thermal *pdata)
+{
+	struct device *dev = &pdev->dev;
+	struct of_phandle_args ph_args;
+	int ret;
+
+	ret = of_parse_phandle_with_fixed_args(pdev->dev.of_node,
+					       "amlogic,secure-monitor",
+					       1, 0, &ph_args);
+	if (ret)
+		return ret;
+
+	if (!ph_args.np) {
+		dev_err(dev, "Failed to parse secure monitor phandle\n");
+		return -ENODEV;
+	}
+
+	pdata->sm_fw = meson_sm_get(ph_args.np);
+	of_node_put(ph_args.np);
+	if (!pdata->sm_fw) {
+		dev_err(dev, "Failed to get secure monitor firmware\n");
+		return -EPROBE_DEFER;
+	}
+
+	pdata->tsensor_id = ph_args.args[0];
+
+	return meson_sm_get_thermal_calib(pdata->sm_fw,
+					  &pdata->trim_info,
+					  pdata->tsensor_id);
+}
+
+static int amlogic_thermal_probe_syscon(struct platform_device *pdev,
+					struct amlogic_thermal *pdata)
+{
+	struct device *dev = &pdev->dev;
+	int ver;
+
+	pdata->sec_ao_map =
+		syscon_regmap_lookup_by_phandle(pdev->dev.of_node,
+						"amlogic,ao-secure");
+	if (IS_ERR(pdata->sec_ao_map)) {
+		dev_err(dev, "syscon regmap lookup failed.\n");
+		return PTR_ERR(pdata->sec_ao_map);
+	}
+
+	regmap_read(pdata->sec_ao_map, pdata->data->u_efuse_off,
+		    &pdata->trim_info);
+
+	ver = TSENSOR_TRIM_VERSION(pdata->trim_info);
+
+	if ((ver & TSENSOR_TRIM_CALIB_VALID_MASK) == 0) {
+		dev_err(&pdata->pdev->dev,
+			"tsensor thermal calibration not supported: 0x%x!\n",
+			ver);
+		return -EINVAL;
+	}
+
+	return 0;
+}
+
 static const struct thermal_zone_device_ops amlogic_thermal_ops = {
 	.get_temp	= amlogic_thermal_get_temp,
 };
@@ -226,6 +272,12 @@ static const struct amlogic_thermal_data amlogic_thermal_a1_cpu_param = {
 	.regmap_config = &amlogic_thermal_regmap_config_g12a,
 };
 
+static const struct amlogic_thermal_data amlogic_thermal_t7_param = {
+	.use_sm			= true,
+	.calibration_parameters	= &amlogic_thermal_g12a,
+	.regmap_config		= &amlogic_thermal_regmap_config_g12a,
+};
+
 static const struct of_device_id of_amlogic_thermal_match[] = {
 	{
 		.compatible = "amlogic,g12a-ddr-thermal",
@@ -239,6 +291,10 @@ static const struct of_device_id of_amlogic_thermal_match[] = {
 		.compatible = "amlogic,a1-cpu-thermal",
 		.data = &amlogic_thermal_a1_cpu_param,
 	},
+	{
+		.compatible = "amlogic,t7-thermal",
+		.data = &amlogic_thermal_t7_param,
+	},
 	{ /* sentinel */ }
 };
 MODULE_DEVICE_TABLE(of, of_amlogic_thermal_match);
@@ -271,12 +327,12 @@ static int amlogic_thermal_probe(struct platform_device *pdev)
 	if (IS_ERR(pdata->clk))
 		return dev_err_probe(dev, PTR_ERR(pdata->clk), "failed to get clock\n");
 
-	pdata->sec_ao_map = syscon_regmap_lookup_by_phandle
-		(pdev->dev.of_node, "amlogic,ao-secure");
-	if (IS_ERR(pdata->sec_ao_map)) {
-		dev_err(dev, "syscon regmap lookup failed.\n");
-		return PTR_ERR(pdata->sec_ao_map);
-	}
+	if (pdata->data->use_sm)
+		ret = amlogic_thermal_probe_sm(pdev, pdata);
+	else
+		ret = amlogic_thermal_probe_syscon(pdev, pdata);
+	if (ret)
+		return ret;
 
 	pdata->tzd = devm_thermal_of_zone_register(&pdev->dev,
 						   0,
@@ -290,10 +346,6 @@ static int amlogic_thermal_probe(struct platform_device *pdev)
 
 	devm_thermal_add_hwmon_sysfs(&pdev->dev, pdata->tzd);
 
-	ret = amlogic_thermal_initialize(pdata);
-	if (ret)
-		return ret;
-
 	ret = amlogic_thermal_enable(pdata);
 
 	return ret;

-- 
2.49.0

