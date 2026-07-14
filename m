From: Haoning CHENG <Haoning.CHENG@cn.bosch.com>
Date: Tue, 14 Jul 2026 18:28:43 +0800
Subject: [PATCH v8 3/3] thermal/drivers/imx: Add calibration offset support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260714-b4-symana21-11221-imx-thermal-support-upstream-6-18-v8-3-d54d8690e16e@cn.bosch.com>
References: <20260714-b4-symana21-11221-imx-thermal-support-upstream-6-18-v8-0-d54d8690e16e@cn.bosch.com>
In-Reply-To: <20260714-b4-symana21-11221-imx-thermal-support-upstream-6-18-v8-0-d54d8690e16e@cn.bosch.com>
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
 linux-kernel@vger.kernel.org, Haoning CHENG <Haoning.CHENG@cn.bosch.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784024921; l=4200;
 i=Haoning.CHENG@cn.bosch.com; s=20260709; h=from:subject:message-id;
 bh=fVZ8/nh0Wo4y9uiBm2vp04dsfqXgZZNI2dShzcEryTw=;
 b=/WnMq2zuNxvlbasuk2ft8ic81S5ZQT/nP29GZ+kVVgzJyYNVKsh42yxesFUiCuu0l94a4R6EH
 jNpzUSgxAk+AinG6HBgTnVpMp+wV9sQvEhQDlQAGyMwUq6U5P8ZiuYB
X-Developer-Key: i=Haoning.CHENG@cn.bosch.com; a=ed25519;
 pk=glQGwad/fosRS5gZUJYbLDPPLGe7rFTrTV2VxY/ySdc=
X-Endpoint-Received: by B4 Relay for Haoning.CHENG@cn.bosch.com/20260709 with auth_id=860
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some boards need a small per-design correction to align the reported CPU
temperature with board-level measurements. Read the optional
fsl,temp-calibration-offset-millicelsius property from DT and apply it
uniformly to the i.MX6/6SX/7D calibration formulas.

The offset is applied symmetrically at two points to ensure the thermal
framework sees calibrated temperatures while hardware thresholds remain
correctly positioned:

1. In imx_set_alarm_temp() and imx_set_panic_temp(): the temperature
   threshold is *subtracted* by the offset before being converted to a
   hardware register value. This shifts the hardware IRQ trigger to the
   physical temperature that corresponds to the intended threshold.

2. In imx_get_temp(): after computing physical temperature from the
   hardware register, the offset is *added* back. The thermal framework
   always sees the calibrated temperature.

For example, if DT sets offset = +3000 m°C (board reads 3°C too low)
and the passive trip is 95°C:

  imx_set_alarm_temp(95000):
    alarm_temp = 95000 - 3000 = 92000
    → hardware register programmed for 92°C physical

  Hardware IRQ fires at 92°C physical

  imx_get_temp():
    reads hardware, computes 92°C physical
    *temp = 92000 + 3000 = 95000
    → thermal framework sees 95°C → correct trip

When the property is not present, the offset defaults to 0, preserving
the current behavior.

Signed-off-by: Haoning CHENG <Haoning.CHENG@cn.bosch.com>
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

