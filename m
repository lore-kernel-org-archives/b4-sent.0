From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Wed, 23 Sep 2026 16:37:51 +0200
Subject: [PATCH v2 2/2] thermal/drivers/amlogic: switch to clk_bulk API to
 support multiple clocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-fix-t7-thermal-clock-v2-2-bff7a09eb487@aliel.fr>
References: <20260923-fix-t7-thermal-clock-v2-0-bff7a09eb487@aliel.fr>
In-Reply-To: <20260923-fix-t7-thermal-clock-v2-0-bff7a09eb487@aliel.fr>
To: Guillaume La Roque <glaroque@baylibre.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>
Cc: Conor Dooley <conor.dooley@microchip.com>, linux-pm@vger.kernel.org, 
 linux-amlogic@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2489;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=d3X7NjHQSZTVQAEva268K6UvycI2mQfSqEccqomqrNU=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9bmJ7HPb1p8btvjlPvoXNjC7e8YnrUx5W5pqDwfua7rS
 OnJDau/dpSyMIhxMciKKbL0z7U88e7y0TNf96inwMxhZQIZwsDFKQATOanDyDB/j4efWe4T5wlm
 Uq0RB2RXbg40Ndlz+ULDKWduZ8N2WVdGhjvr5rxQ4e46tPZrBceLTsGNj837jiTo/dUWZZ/9dtX
 ZdB4A
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The t7-thermal variant now exposes two clocks (bus and core) in its
devicetree binding, but the driver only knows how to get and manage
a single struct clk. Using devm_clk_get() would silently ignore the
second clock, so switch to devm_clk_bulk_get_all() and the matching
clk_bulk_prepare_enable()/clk_bulk_disable_unprepare() calls. This
lets the driver transparently handle however many clocks a given
compatible declares, without needing per-variant clock-handling code,
and keeps working for existing SoCs that only have one.

Fixes: 18d65de8157c ("thermal/drivers/amlogic: Add support for secure monitor calibration readout")
Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 drivers/thermal/amlogic_thermal.c | 14 ++++++++------
 1 file changed, 8 insertions(+), 6 deletions(-)

diff --git a/drivers/thermal/amlogic_thermal.c b/drivers/thermal/amlogic_thermal.c
index a0b530624b60c..60728de6968ac 100644
--- a/drivers/thermal/amlogic_thermal.c
+++ b/drivers/thermal/amlogic_thermal.c
@@ -100,7 +100,8 @@ struct amlogic_thermal {
 	const struct amlogic_thermal_data *data;
 	struct regmap *regmap;
 	struct regmap *sec_ao_map;
-	struct clk *clk;
+	struct clk_bulk_data *clks;
+	int num_clks;
 	struct thermal_zone_device *tzd;
 	u32 trim_info;
 	struct meson_sm_firmware *sm_fw;
@@ -142,7 +143,7 @@ static int amlogic_thermal_enable(struct amlogic_thermal *data)
 {
 	int ret;
 
-	ret = clk_prepare_enable(data->clk);
+	ret = clk_bulk_prepare_enable(data->num_clks, data->clks);
 	if (ret)
 		return ret;
 
@@ -156,7 +157,7 @@ static void amlogic_thermal_disable(struct amlogic_thermal *data)
 {
 	regmap_update_bits(data->regmap, TSENSOR_CFG_REG1,
 			   TSENSOR_CFG_REG1_ENABLE, 0);
-	clk_disable_unprepare(data->clk);
+	clk_bulk_disable_unprepare(data->num_clks, data->clks);
 }
 
 static int amlogic_thermal_get_temp(struct thermal_zone_device *tz, int *temp)
@@ -323,9 +324,10 @@ static int amlogic_thermal_probe(struct platform_device *pdev)
 	if (IS_ERR(pdata->regmap))
 		return PTR_ERR(pdata->regmap);
 
-	pdata->clk = devm_clk_get(dev, NULL);
-	if (IS_ERR(pdata->clk))
-		return dev_err_probe(dev, PTR_ERR(pdata->clk), "failed to get clock\n");
+	ret = devm_clk_bulk_get_all(dev, &pdata->clks);
+	if (ret <= 0)
+		return dev_err_probe(dev, ret ?: -ENOENT, "failed to get clocks\n");
+	pdata->num_clks = ret;
 
 	if (pdata->data->use_sm)
 		ret = amlogic_thermal_probe_sm(pdev, pdata);

-- 
2.49.0

