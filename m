From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Thu, 02 Jul 2026 11:55:57 +0200
Subject: [PATCH v8 4/8] mfd: khadas-mcu: Add support for VIM4 MCU variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260702-add-mcu-fan-khadas-vim4-v8-4-244feee91a36@aliel.fr>
References: <20260702-add-mcu-fan-khadas-vim4-v8-0-244feee91a36@aliel.fr>
In-Reply-To: <20260702-add-mcu-fan-khadas-vim4-v8-0-244feee91a36@aliel.fr>
To: Neil Armstrong <neil.armstrong@linaro.org>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Beniamino Galvani <b.galvani@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>
Cc: linux-amlogic@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-pm@vger.kernel.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=5599;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=QvhTcJKgRDVJSqzub3GPP49FeuQA92Jq2f2X41Eli+Y=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ5ab6e/pl79Nq438NOng+6mq+6yjLrlFJB/YH3Rz+V83s
 fdhM+/adJSyMIhxMciKKbL0z7U88e7y0TNf96inwMxhZQIZwsDFKQATueHA8M+q+O07t+dO0d4L
 1q3oWSsT22IQ5zDPMWvW/W2rlDXj331jZGhT/fr8QSDDdNP1F/qDfp5jv9X+fH2Twi7vBQmlRrq
 3k1gB
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Refactor probe() to use per-variant values
instead of hardcoded globals.

Add dedicated regmap configuration for the VIM4 MCU,
with its own volatile/writeable registers.

Add the fan control register
(0–100 levels vs 0–3 for previous supported boards).

Add a new compatible string "khadas,vim4-mcu".

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 drivers/mfd/khadas-mcu.c | 118 ++++++++++++++++++++++++++++++++++++++++-------
 1 file changed, 102 insertions(+), 16 deletions(-)

diff --git a/drivers/mfd/khadas-mcu.c b/drivers/mfd/khadas-mcu.c
index ba981a7886921..d2ca7deda45c6 100644
--- a/drivers/mfd/khadas-mcu.c
+++ b/drivers/mfd/khadas-mcu.c
@@ -13,6 +13,9 @@
 #include <linux/module.h>
 #include <linux/regmap.h>
 
+#define KHADAS_MCU_FAN_LEVEL_MAX 3
+#define KHADAS_MCU_VIM4_FAN_LEVEL_MAX 0x64
+
 static bool khadas_mcu_reg_volatile(struct device *dev, unsigned int reg)
 {
 	if (reg >= KHADAS_MCU_USER_DATA_0_REG &&
@@ -75,47 +78,129 @@ static const struct regmap_config khadas_mcu_regmap_config = {
 	.cache_type	= REGCACHE_MAPLE,
 };
 
-static struct mfd_cell khadas_mcu_fan_cells[] = {
+static const struct khadas_mcu_fan_pdata khadas_mcu_fan_pdata = {
+	.fan_reg	= KHADAS_MCU_CMD_FAN_STATUS_CTRL_REG,
+	.max_level	= KHADAS_MCU_FAN_LEVEL_MAX,
+};
+
+static const struct mfd_cell khadas_mcu_fan_cells[] = {
 	/* VIM1/2 Rev13+ and VIM3 only */
-	{ .name = "khadas-mcu-fan-ctrl", },
+	{
+		.name = "khadas-mcu-fan-ctrl",
+		.platform_data = &khadas_mcu_fan_pdata,
+		.pdata_size = sizeof(khadas_mcu_fan_pdata),
+	},
 };
 
-static struct mfd_cell khadas_mcu_cells[] = {
+static const struct mfd_cell khadas_mcu_cells[] = {
 	{ .name = "khadas-mcu-user-mem", },
 };
 
+static bool khadas_mcu_vim4_reg_volatile(struct device *dev, unsigned int reg)
+{
+	switch (reg) {
+	case KHADAS_MCU_PWR_OFF_CMD_REG:
+	case KHADAS_MCU_VIM4_REST_CONF_REG:
+	case KHADAS_MCU_WOL_INIT_START_REG:
+	case KHADAS_MCU_VIM4_LED_ON_RAM_REG:
+	case KHADAS_MCU_VIM4_FAN_CTRL_REG:
+	case KHADAS_MCU_VIM4_WDT_EN_REG:
+	case KHADAS_MCU_VIM4_SYS_RST_REG:
+		return true;
+	default:
+		return false;
+	}
+}
+
+static bool khadas_mcu_vim4_reg_writeable(struct device *dev, unsigned int reg)
+{
+	switch (reg) {
+	case KHADAS_MCU_VERSION_0_REG:
+	case KHADAS_MCU_VERSION_1_REG:
+	case KHADAS_MCU_SHUTDOWN_NORMAL_STATUS_REG:
+		return false;
+	default:
+		return true;
+	}
+}
+
+static const struct regmap_config khadas_mcu_vim4_regmap_config = {
+	.reg_bits	= 8,
+	.reg_stride	= 1,
+	.val_bits	= 8,
+	.max_register	= KHADAS_MCU_VIM4_SYS_RST_REG,
+	.volatile_reg	= khadas_mcu_vim4_reg_volatile,
+	.writeable_reg	= khadas_mcu_vim4_reg_writeable,
+	.cache_type	= REGCACHE_MAPLE,
+};
+
+static const struct khadas_mcu_fan_pdata khadas_vim4_fan_pdata = {
+	.fan_reg	= KHADAS_MCU_VIM4_FAN_CTRL_REG,
+	.max_level	= KHADAS_MCU_VIM4_FAN_LEVEL_MAX,
+};
+
+static const struct mfd_cell khadas_mcu_vim4_cells[] = {
+	{
+		.name		= "khadas-mcu-fan-ctrl",
+		.platform_data	= &khadas_vim4_fan_pdata,
+		.pdata_size	= sizeof(khadas_vim4_fan_pdata),
+	},
+};
+
 static int khadas_mcu_probe(struct i2c_client *client)
 {
+	const struct mfd_cell *cells, *fan_cells;
+	const struct regmap_config *regmap_cfg;
 	struct device *dev = &client->dev;
+	int ncells, nfan_cells, ret;
 	struct khadas_mcu *ddata;
-	int ret;
 
 	ddata = devm_kzalloc(dev, sizeof(*ddata), GFP_KERNEL);
 	if (!ddata)
 		return -ENOMEM;
 
+	switch ((uintptr_t)i2c_get_match_data(client)) {
+	case KHADAS_MCU_GENERIC:
+		regmap_cfg	= &khadas_mcu_regmap_config;
+		cells		= khadas_mcu_cells;
+		ncells		= ARRAY_SIZE(khadas_mcu_cells);
+		fan_cells	= khadas_mcu_fan_cells;
+		nfan_cells	= ARRAY_SIZE(khadas_mcu_fan_cells);
+		break;
+	case KHADAS_MCU_VIM4:
+		regmap_cfg	= &khadas_mcu_vim4_regmap_config;
+		cells		= NULL;
+		ncells		= 0;
+		fan_cells	= khadas_mcu_vim4_cells;
+		nfan_cells	= ARRAY_SIZE(khadas_mcu_vim4_cells);
+		break;
+	default:
+		return -ENODEV;
+	}
+
 	i2c_set_clientdata(client, ddata);
 
 	ddata->dev = dev;
 
-	ddata->regmap = devm_regmap_init_i2c(client, &khadas_mcu_regmap_config);
+	ddata->regmap = devm_regmap_init_i2c(client, regmap_cfg);
 	if (IS_ERR(ddata->regmap)) {
 		ret = PTR_ERR(ddata->regmap);
-		dev_err(dev, "Failed to allocate register map: %d\n", ret);
-		return ret;
+		return dev_err_probe(dev, ret, "Failed to allocate register map\n");
 	}
 
-	ret = devm_mfd_add_devices(dev, PLATFORM_DEVID_NONE,
-				   khadas_mcu_cells,
-				   ARRAY_SIZE(khadas_mcu_cells),
-				   NULL, 0, NULL);
-	if (ret)
-		return ret;
+	if (cells && ncells) {
+		ret = devm_mfd_add_devices(dev, PLATFORM_DEVID_NONE,
+					   cells,
+					   ncells,
+					   NULL, 0, NULL);
+		if (ret)
+			return ret;
+	}
 
 	if (of_property_present(dev->of_node, "#cooling-cells"))
 		return devm_mfd_add_devices(dev, PLATFORM_DEVID_NONE,
-					    khadas_mcu_fan_cells,
-					    ARRAY_SIZE(khadas_mcu_fan_cells),
+					    fan_cells,
+					    nfan_cells,
 					    NULL, 0, NULL);
 
 	return 0;
@@ -123,7 +208,8 @@ static int khadas_mcu_probe(struct i2c_client *client)
 
 #ifdef CONFIG_OF
 static const struct of_device_id khadas_mcu_of_match[] = {
-	{ .compatible = "khadas,mcu", },
+	{ .compatible = "khadas,mcu", .data = (void *)KHADAS_MCU_GENERIC },
+	{ .compatible = "khadas,vim4-mcu", .data = (void *)KHADAS_MCU_VIM4 },
 	{},
 };
 MODULE_DEVICE_TABLE(of, khadas_mcu_of_match);

-- 
2.49.0

