From: Haoning CHENG <Haoning.CHENG@cn.bosch.com>
Date: Wed, 22 Jul 2026 10:11:43 +0800
Subject: [PATCH v11 3/3] thermal/drivers/imx: Add calibration offset
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260722-b4-symana21-11221-imx-thermal-support-upstream-6-18-v11-3-90e4e46c0a13@cn.bosch.com>
References: <20260722-b4-symana21-11221-imx-thermal-support-upstream-6-18-v11-0-90e4e46c0a13@cn.bosch.com>
In-Reply-To: <20260722-b4-symana21-11221-imx-thermal-support-upstream-6-18-v11-0-90e4e46c0a13@cn.bosch.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Haoning CHENG <Haoning.CHENG@cn.bosch.com>, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784687940; l=4319;
 i=Haoning.CHENG@cn.bosch.com; s=20260709; h=from:subject:message-id;
 bh=iGtMCQeZJKH4z5VifCeuyUN93+QX4fy7skn49vUYhis=;
 b=SlhPV5ho3FNmNN6iMqbaR1vdUUAKNRWYpWNGh38K7fKyLTjQTT4qe81iPBIRFeHTKSQykqfz3
 0uqlVina7AgBZUnytKjIfmg5VPF6m2OLX+FDB/vcaE7njHeEu5iHkF7
X-Developer-Key: i=Haoning.CHENG@cn.bosch.com; a=ed25519;
 pk=glQGwad/fosRS5gZUJYbLDPPLGe7rFTrTV2VxY/ySdc=
X-Endpoint-Received: by B4 Relay for Haoning.CHENG@cn.bosch.com/20260709 with auth_id=860
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TEMPMON sensor reading may deviate from the theoretical SoC
junction temperature. Hardware characterization shows a measurable
offset between the sensor output and the calculated junction
temperature.

Read the optional fsl,temp-calibration-offset-millicelsius property
from DT and apply it uniformly to the i.MX6/6SX/7D formulas.

The offset is applied symmetrically at two points to keep trip point
semantics consistent:

1. In imx_set_alarm_temp() and imx_set_panic_temp(): the temperature
   threshold is *subtracted* by the offset before being converted to a
   hardware register value. This keeps the hardware IRQ trigger aligned
   with the physical sensor reading that corresponds to the intended
   temperature threshold.

2. In imx_get_temp(): after computing the temperature from the hardware
   register, the offset is *added* to produce the calibrated value.
   The thermal framework always sees the corrected temperature.

For example, if DT sets offset = +3000 m°C and the passive trip is 95°C:

  imx_set_alarm_temp(95000):
    alarm_temp = 95000 - 3000 = 92000
    → hardware register programmed for 92°C sensor reading

  Hardware IRQ fires when sensor reads 92°C

  imx_get_temp():
    reads hardware, computes 92°C
    *temp = 92000 + 3000 = 95000
    → thermal framework sees 95°C → correct trip

When the property is not present, the offset defaults to 0, preserving
the current behavior.

Reviewed-by: Frank Li <Frank.Li@nxp.com>
Reviewed-by: Lukasz Luba <lukasz.luba@arm.com>
Signed-off-by: Haoning Cheng <Haoning.CHENG@cn.bosch.com>
---
 drivers/thermal/imx_thermal.c | 27 +++++++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/drivers/thermal/imx_thermal.c b/drivers/thermal/imx_thermal.c
index 7f7d1116b9d6..d471acc16bce 100644
--- a/drivers/thermal/imx_thermal.c
+++ b/drivers/thermal/imx_thermal.c
@@ -85,6 +85,10 @@ enum imx_thermal_trip {
 #define TEMPMON_IMX6SX			2
 #define TEMPMON_IMX7D			3
 
+/* Calibration offset limits (±20 °C in millicelsius) */
+#define IMX_TEMP_CALIB_OFFSET_MIN	(-20000)
+#define IMX_TEMP_CALIB_OFFSET_MAX	20000
+
 struct thermal_soc_data {
 	u32 version;
 
@@ -207,6 +211,7 @@ struct imx_thermal_data {
 	struct regmap *tempmon;
 	u32 c1, c2; /* See formula in imx_init_calib() */
 	int temp_max;
+	s32 calibration_offset;
 	int alarm_temp;
 	int last_temp;
 	bool irq_enabled;
@@ -223,6 +228,7 @@ static void imx_set_panic_temp(struct imx_thermal_data *data,
 	struct regmap *map = data->tempmon;
 	int critical_value;
 
+	panic_temp -= data->calibration_offset;
 	critical_value = (data->c2 - panic_temp) / data->c1;
 
 	regmap_write(map, soc_data->panic_alarm_ctrl + REG_CLR,
@@ -239,6 +245,7 @@ static void imx_set_alarm_temp(struct imx_thermal_data *data,
 	int alarm_value;
 
 	data->alarm_temp = alarm_temp;
+	alarm_temp -= data->calibration_offset;
 
 	if (data->socdata->version == TEMPMON_IMX7D) {
 		if (alarm_temp >= 0)
@@ -283,6 +290,7 @@ static int imx_get_temp(struct thermal_zone_device *tz, int *temp)
 		*temp = (n_meas - data->c1 + 25) * 1000;
 	else
 		*temp = data->c2 - n_meas * data->c1;
+	*temp += data->calibration_offset;
 
 	/* Update alarm value to next higher trip point for TEMPMON_IMX6Q */
 	if (data->socdata->version == TEMPMON_IMX6Q) {
@@ -635,6 +643,25 @@ static int imx_thermal_probe(struct platform_device *pdev)
 
 	platform_set_drvdata(pdev, data);
 
+	if (of_property_present(dev->of_node,
+				"fsl,temp-calibration-offset-millicelsius")) {
+		ret = of_property_read_s32(dev->of_node,
+					   "fsl,temp-calibration-offset-millicelsius",
+					   &data->calibration_offset);
+		if (ret)
+			return dev_err_probe(dev, ret,
+					     "failed to read calibration offset\n");
+
+		if (data->calibration_offset < IMX_TEMP_CALIB_OFFSET_MIN ||
+		    data->calibration_offset > IMX_TEMP_CALIB_OFFSET_MAX)
+			return dev_err_probe(dev, -EINVAL,
+					     "calibration offset %d millicelsius out of range\n",
+					     data->calibration_offset);
+
+		dev_dbg(dev, "calibration offset: %d millicelsius\n",
+			data->calibration_offset);
+	}
+
 	if (of_property_present(dev->of_node, "nvmem-cells")) {
 		ret = imx_init_from_nvmem_cells(pdev);
 		if (ret)

-- 
2.43.0

