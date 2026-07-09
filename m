From: HaoNing Cheng <Haoning.CHENG@cn.bosch.com>
Date: Thu, 09 Jul 2026 13:43:28 +0800
Subject: [PATCH 2/2] thermal/drivers/imx: Add calibration offset support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260709-b4-symana21-11221-imx-thermal-support-upstream-6-18-v1-2-00f88f42930b@cn.bosch.com>
References: <20260709-b4-symana21-11221-imx-thermal-support-upstream-6-18-v1-0-00f88f42930b@cn.bosch.com>
In-Reply-To: <20260709-b4-symana21-11221-imx-thermal-support-upstream-6-18-v1-0-00f88f42930b@cn.bosch.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783575916; l=2381;
 i=Haoning.CHENG@cn.bosch.com; s=20260709; h=from:subject:message-id;
 bh=qR9Z8v169awj6AlJQm9fFIYVqyTJvgxKRAwxDjCuvuM=;
 b=x0jK/SKaYc25IfFG+Jl46iyk32PvludzunbAtiX/CpT60YAd10Cngs5iIM3GFJcb8mGahWr9r
 0fdc8lZy9aVCi7ry5l/Rhx/AkpkMfVylPNZ6wobx4gdbQLP1m64ChV0
X-Developer-Key: i=Haoning.CHENG@cn.bosch.com; a=ed25519;
 pk=glQGwad/fosRS5gZUJYbLDPPLGe7rFTrTV2VxY/ySdc=
X-Endpoint-Received: by B4 Relay for Haoning.CHENG@cn.bosch.com/20260709 with auth_id=860
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some boards need a small per-design correction to align the reported CPU
temperature with board-level measurements.

Read the optional fsl,temp-calibration-offset-millicelsius property from
DT and apply it to the i.MX6/6SX/7D calibration formulas. When the
property is not present, the default offset remains 0, preserving the
current behaviour.

Signed-off-by: HaoNing Cheng <Haoning.CHENG@cn.bosch.com>
---
 drivers/thermal/imx_thermal.c | 11 ++++++++---
 1 file changed, 8 insertions(+), 3 deletions(-)

diff --git a/drivers/thermal/imx_thermal.c b/drivers/thermal/imx_thermal.c
index 38c993d1bcb3..c65400b51ed8 100644
--- a/drivers/thermal/imx_thermal.c
+++ b/drivers/thermal/imx_thermal.c
@@ -207,6 +207,7 @@ struct imx_thermal_data {
 	struct regmap *tempmon;
 	u32 c1, c2; /* See formula in imx_init_calib() */
 	int temp_max;
+	s32 calibration_offset;
 	int alarm_temp;
 	int last_temp;
 	bool irq_enabled;
@@ -241,7 +242,7 @@ static void imx_set_alarm_temp(struct imx_thermal_data *data,
 	data->alarm_temp = alarm_temp;
 
 	if (data->socdata->version == TEMPMON_IMX7D)
-		alarm_value = alarm_temp / 1000 + data->c1 - 25;
+		alarm_value = (alarm_temp - data->calibration_offset) / 1000 + data->c1 - 25;
 	else
 		alarm_value = (data->c2 - alarm_temp) / data->c1;
 
@@ -274,7 +275,7 @@ static int imx_get_temp(struct thermal_zone_device *tz, int *temp)
 
 	/* See imx_init_calib() for formula derivation */
 	if (data->socdata->version == TEMPMON_IMX7D)
-		*temp = (n_meas - data->c1 + 25) * 1000;
+		*temp = (n_meas - data->c1 + 25) * 1000 + data->calibration_offset;
 	else
 		*temp = data->c2 - n_meas * data->c1;
 
@@ -413,7 +414,7 @@ static int imx_init_calib(struct platform_device *pdev, u32 ocotp_ana1)
 	temp64 *= 1000; /* to get result in °mC */
 	do_div(temp64, 15423 * n1 - 4148468);
 	data->c1 = temp64;
-	data->c2 = n1 * data->c1 + 28581;
+	data->c2 = n1 * data->c1 + 28581 + data->calibration_offset;
 
 	return 0;
 }
@@ -629,6 +630,10 @@ static int imx_thermal_probe(struct platform_device *pdev)
 
 	platform_set_drvdata(pdev, data);
 
+	of_property_read_s32(dev->of_node,
+			     "fsl,temp-calibration-offset-millicelsius",
+			     &data->calibration_offset);
+
 	if (of_property_present(dev->of_node, "nvmem-cells")) {
 		ret = imx_init_from_nvmem_cells(pdev);
 		if (ret)

-- 
2.43.0

