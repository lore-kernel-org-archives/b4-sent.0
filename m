From: Thomas Antoine <t.antoine@uclouvain.be>
Date: Mon, 02 Dec 2024 14:07:15 +0100
Subject: [PATCH 1/4] power: supply: add support for max77759 fuel gauge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241202-b4-gs101_max77759_fg-v1-1-98d2fa7bfe30@uclouvain.be>
References: <20241202-b4-gs101_max77759_fg-v1-0-98d2fa7bfe30@uclouvain.be>
In-Reply-To: <20241202-b4-gs101_max77759_fg-v1-0-98d2fa7bfe30@uclouvain.be>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, Thomas Antoine <t.antoine@uclouvain.be>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733144859; l=5861;
 i=t.antoine@uclouvain.be; s=20241202; h=from:subject:message-id;
 bh=8/hl8HCrAHHJ3VeFvt/t1hZ/LAyPgByR74YhR463vjQ=;
 b=H9K7tMUAoGnrOOR2rqtXyyTvA8qiFvlZ3DCQkaWfcS2uiHCV/MFpnBLMUiTYIHlnaQAMz1kUP
 nYlq+ZLHwpkChbCaaLqOoZw3CBZxxpq0xOXTiND8Diy6ypVR8Q9xGMS
X-Developer-Key: i=t.antoine@uclouvain.be; a=ed25519;
 pk=sw7UYl31W1LTpgWRiX4xIF5x6ok7YWZ6XZnHqy/d3dY=
X-Endpoint-Received: by B4 Relay for t.antoine@uclouvain.be/20241202 with auth_id=289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Maxim max77759 fuel gauge has the same interface as the Maxim max1720x
except for the non-volatile memory slave address which is not available.
No slave is available at address 0xb of the i2c bus, which is coherent
with the following driver from google: line 5836 disables non-volatile
memory for m5 gauge.

Link: https://android.googlesource.com/kernel/google-modules/bms/+/1a68c36bef474573cc8629cc1d121eb6a81ab68c/max1720x_battery.c

Add support for the max77759 by allowing to use the non-volatile
memory or not based on the chip. Value for RSense comes from the following
stock devicetree:

Link: https://android.googlesource.com/kernel/devices/google/gs101/+/33eca36d43da6c2b6a546806eb3e7411bbe6d60d/dts/gs101-raviole-battery.dtsi

Signed-off-by: Thomas Antoine <t.antoine@uclouvain.be>
---
 drivers/power/supply/max1720x_battery.c | 71 +++++++++++++++++++++++++++------
 1 file changed, 59 insertions(+), 12 deletions(-)

diff --git a/drivers/power/supply/max1720x_battery.c b/drivers/power/supply/max1720x_battery.c
index 33105419e2427bb37963bda9948b647c239f8faa..faf336938dd4306dd2ceeb0a84b90ca80ad41a9f 100644
--- a/drivers/power/supply/max1720x_battery.c
+++ b/drivers/power/supply/max1720x_battery.c
@@ -13,6 +13,7 @@
 #include <linux/nvmem-provider.h>
 #include <linux/power_supply.h>
 #include <linux/regmap.h>
+#include <linux/types.h>
 
 #include <linux/unaligned.h>
 
@@ -39,6 +40,7 @@
 #define MAX172XX_DEV_NAME_TYPE_MASK	GENMASK(3, 0)
 #define MAX172XX_DEV_NAME_TYPE_MAX17201	BIT(0)
 #define MAX172XX_DEV_NAME_TYPE_MAX17205	(BIT(0) | BIT(2))
+#define MAX172XX_DEV_NAME_TYPE_MAX77759	0
 #define MAX172XX_QR_TABLE10		0x22
 #define MAX172XX_BATT			0xDA	/* Battery voltage */
 #define MAX172XX_ATAVCAP		0xDF
@@ -46,6 +48,7 @@
 static const char *const max1720x_manufacturer = "Maxim Integrated";
 static const char *const max17201_model = "MAX17201";
 static const char *const max17205_model = "MAX17205";
+static const char *const max77759_model = "MAX77759";
 
 struct max1720x_device_info {
 	struct regmap *regmap;
@@ -54,6 +57,21 @@ struct max1720x_device_info {
 	int rsense;
 };
 
+struct chip_data {
+	u16 default_nrsense; /* in regs in 10^-5 */
+	u8 has_nvmem;
+};
+
+static const struct chip_data max1720x_data  = {
+	.default_nrsense = 1000,
+	.has_nvmem = 1,
+};
+
+static const struct chip_data max77759_data = {
+	.default_nrsense = 500,
+	.has_nvmem = 0,
+};
+
 /*
  * Model Gauge M5 Algorithm output register
  * Volatile data (must not be cached)
@@ -369,6 +387,8 @@ static int max1720x_battery_get_property(struct power_supply *psy,
 			val->strval = max17201_model;
 		else if (reg_val == MAX172XX_DEV_NAME_TYPE_MAX17205)
 			val->strval = max17205_model;
+		else if (reg_val == MAX172XX_DEV_NAME_TYPE_MAX77759)
+			val->strval = max77759_model;
 		else
 			return -ENODEV;
 		break;
@@ -416,7 +436,6 @@ static int max1720x_probe_nvmem(struct i2c_client *client,
 		.priv = info,
 	};
 	struct nvmem_device *nvmem;
-	unsigned int val;
 	int ret;
 
 	info->ancillary = i2c_new_ancillary_device(client, "nvmem", 0xb);
@@ -438,6 +457,27 @@ static int max1720x_probe_nvmem(struct i2c_client *client,
 		return PTR_ERR(info->regmap_nv);
 	}
 
+	nvmem = devm_nvmem_register(dev, &nvmem_config);
+	if (IS_ERR(nvmem)) {
+		dev_err(dev, "Could not register nvmem!");
+		return PTR_ERR(nvmem);
+	}
+
+	return 0;
+}
+
+static int max1720x_get_rsense(struct device *dev,
+					 struct max1720x_device_info *info,
+					 const struct chip_data *data)
+{
+	unsigned int val;
+	int ret;
+
+	if (!data->has_nvmem) {
+		info->rsense = data->default_nrsense;
+		return 0;
+	}
+
 	ret = regmap_read(info->regmap_nv, MAX1720X_NRSENSE, &val);
 	if (ret < 0) {
 		dev_err(dev, "Failed to read sense resistor value\n");
@@ -446,14 +486,9 @@ static int max1720x_probe_nvmem(struct i2c_client *client,
 
 	info->rsense = val;
 	if (!info->rsense) {
-		dev_warn(dev, "RSense not calibrated, set 10 mOhms!\n");
-		info->rsense = 1000; /* in regs in 10^-5 */
-	}
-
-	nvmem = devm_nvmem_register(dev, &nvmem_config);
-	if (IS_ERR(nvmem)) {
-		dev_err(dev, "Could not register nvmem!");
-		return PTR_ERR(nvmem);
+		dev_warn(dev, "RSense not calibrated, set %d mOhms!\n",
+						data->default_nrsense/100);
+		info->rsense = data->default_nrsense;
 	}
 
 	return 0;
@@ -474,6 +509,7 @@ static int max1720x_probe(struct i2c_client *client)
 	struct device *dev = &client->dev;
 	struct max1720x_device_info *info;
 	struct power_supply *bat;
+	const struct chip_data *data;
 	int ret;
 
 	info = devm_kzalloc(dev, sizeof(*info), GFP_KERNEL);
@@ -488,9 +524,19 @@ static int max1720x_probe(struct i2c_client *client)
 		return dev_err_probe(dev, PTR_ERR(info->regmap),
 				     "regmap initialization failed\n");
 
-	ret = max1720x_probe_nvmem(client, info);
+	data = device_get_match_data(dev);
+	if (!data)
+		return dev_err_probe(dev, ret, "Failed to get chip data\n");
+
+	if (data->has_nvmem) {
+		ret = max1720x_probe_nvmem(client, info);
+		if (ret)
+			return dev_err_probe(dev, ret, "Failed to probe nvmem\n");
+	}
+
+	ret = max1720x_get_rsense(dev, info, data);
 	if (ret)
-		return dev_err_probe(dev, ret, "Failed to probe nvmem\n");
+		return dev_err_probe(dev, ret, "Failed to get RSense");
 
 	bat = devm_power_supply_register(dev, &max1720x_bat_desc, &psy_cfg);
 	if (IS_ERR(bat))
@@ -501,7 +547,8 @@ static int max1720x_probe(struct i2c_client *client)
 }
 
 static const struct of_device_id max1720x_of_match[] = {
-	{ .compatible = "maxim,max17201" },
+	{ .compatible = "maxim,max17201", .data = (void *) &max1720x_data },
+	{ .compatible = "maxim,max77759-fg", .data = (void *) &max77759_data},
 	{}
 };
 MODULE_DEVICE_TABLE(of, max1720x_of_match);

-- 
2.47.1

