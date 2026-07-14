From: Haoning CHENG <Haoning.CHENG@cn.bosch.com>
Date: Tue, 14 Jul 2026 18:28:42 +0800
Subject: [PATCH v8 2/3] thermal/drivers/imx: Fix rounding and clamp for
 i.MX7D alarm
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260714-b4-symana21-11221-imx-thermal-support-upstream-6-18-v8-2-d54d8690e16e@cn.bosch.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784024921; l=1614;
 i=Haoning.CHENG@cn.bosch.com; s=20260709; h=from:subject:message-id;
 bh=1JBV0u3QEY1X06yF+bBAxZo8ixtbx4eg4tQIOMJHWHs=;
 b=LslAkJd+wyxZebCbOnxK6QkqPn42J1gBAC0+EEqd81HxjetCdZIuFcuu9dcZflFdJgFrONEix
 D0jBwdItWe3AExsdqpDQrGB5K5kdWq6HGSMGBbC1D+V0wco9qbQ3O3z
X-Developer-Key: i=Haoning.CHENG@cn.bosch.com; a=ed25519;
 pk=glQGwad/fosRS5gZUJYbLDPPLGe7rFTrTV2VxY/ySdc=
X-Endpoint-Received: by B4 Relay for Haoning.CHENG@cn.bosch.com/20260709 with auth_id=860
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert the alarm temperature from millicelsius to degrees for i.MX7D
using ceiling division instead of integer division, ensuring rounding
errors do not cause the alarm to trigger below the intended threshold.
Use DIV_ROUND_UP() for non-negative values and plain integer division
for negative values, since C rounds toward zero which is equivalent to
ceiling when the divisor is positive.

Add clamp() to ensure the hardware register value stays within the 9-bit
range (0..0x1ff) of the i.MX7D alarm field, preventing silent truncation
if an out-of-range value is written.

Signed-off-by: Haoning CHENG <Haoning.CHENG@cn.bosch.com>
---
 drivers/thermal/imx_thermal.c | 12 +++++++++---
 1 file changed, 9 insertions(+), 3 deletions(-)

diff --git a/drivers/thermal/imx_thermal.c b/drivers/thermal/imx_thermal.c
index 38c993d1bcb3..7f7d1116b9d6 100644
--- a/drivers/thermal/imx_thermal.c
+++ b/drivers/thermal/imx_thermal.c
@@ -240,10 +240,16 @@ static void imx_set_alarm_temp(struct imx_thermal_data *data,
 
 	data->alarm_temp = alarm_temp;
 
-	if (data->socdata->version == TEMPMON_IMX7D)
-		alarm_value = alarm_temp / 1000 + data->c1 - 25;
-	else
+	if (data->socdata->version == TEMPMON_IMX7D) {
+		if (alarm_temp >= 0)
+			alarm_temp = DIV_ROUND_UP(alarm_temp, 1000);
+		else
+			alarm_temp /= 1000;
+		alarm_value = alarm_temp + data->c1 - 25;
+		alarm_value = clamp(alarm_value, 0, 0x1ff);
+	} else {
 		alarm_value = (data->c2 - alarm_temp) / data->c1;
+	}
 
 	regmap_write(map, soc_data->high_alarm_ctrl + REG_CLR,
 		     soc_data->high_alarm_mask);

-- 
2.43.0

