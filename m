From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Sat, 14 Jun 2025 15:35:53 +0100
Subject: [PATCH v5 02/20] mfd: adp5585: only add devices given in FW
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250614-dev-adp5589-fw-v5-2-7e9d84906268@analog.com>
References: <20250614-dev-adp5589-fw-v5-0-7e9d84906268@analog.com>
In-Reply-To: <20250614-dev-adp5589-fw-v5-0-7e9d84906268@analog.com>
To: linux-gpio@vger.kernel.org, linux-pwm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-input@vger.kernel.org
Cc: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Liu Ying <victor.liu@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749911835; l=2284;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=vmniaSLpbgWkvwxYbHERkkcnOZlR873SC8mAfAx5A0s=;
 b=LxaH66/QxjUlRnWX+/Xgfj3sJUTmP7VP/JbSclQw4zgE3KsUBl8eMhgsnQ4WIflI1WK0NDymG
 hM4zHomuPyNA+QlB64ves30J2QiGWFiE1ebukVzdHglWlQSDsP2TUlr
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Not all devices (features) of the adp5585 device are mandatory to be
used in all platforms. Hence, check what's given in FW and dynamically
create the mfd_cell array to be given to devm_mfd_add_devices().

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/mfd/adp5585.c | 38 +++++++++++++++++++++++++++++---------
 1 file changed, 29 insertions(+), 9 deletions(-)

diff --git a/drivers/mfd/adp5585.c b/drivers/mfd/adp5585.c
index 160e0b38106a6d78f7d4b7c866cb603d96ea673e..53a46734f2d022ec54b3efc2ebbf389357f8d85a 100644
--- a/drivers/mfd/adp5585.c
+++ b/drivers/mfd/adp5585.c
@@ -17,7 +17,13 @@
 #include <linux/regmap.h>
 #include <linux/types.h>
 
-static const struct mfd_cell adp5585_devs[] = {
+enum {
+	ADP5585_DEV_GPIO,
+	ADP5585_DEV_PWM,
+	ADP5585_DEV_MAX
+};
+
+static const struct mfd_cell adp5585_devs[ADP5585_DEV_MAX] = {
 	{ .name = "adp5585-gpio", },
 	{ .name = "adp5585-pwm", },
 };
@@ -110,6 +116,27 @@ static const struct regmap_config adp5585_regmap_configs[] = {
 	},
 };
 
+static int adp5585_add_devices(struct device *dev)
+{
+	int ret;
+
+	if (device_property_present(dev, "#pwm-cells")) {
+		ret = devm_mfd_add_devices(dev, PLATFORM_DEVID_AUTO,
+					   &adp5585_devs[ADP5585_DEV_PWM], 1, NULL, 0, NULL);
+		if (ret)
+			return dev_err_probe(dev, ret, "Failed to add PWM device\n");
+	}
+
+	if (device_property_present(dev, "#gpio-cells")) {
+		ret = devm_mfd_add_devices(dev, PLATFORM_DEVID_AUTO,
+					   &adp5585_devs[ADP5585_DEV_GPIO], 1, NULL, 0, NULL);
+		if (ret)
+			return dev_err_probe(dev, ret, "Failed to add GPIO device\n");
+	}
+
+	return 0;
+}
+
 static int adp5585_i2c_probe(struct i2c_client *i2c)
 {
 	const struct regmap_config *regmap_config;
@@ -138,14 +165,7 @@ static int adp5585_i2c_probe(struct i2c_client *i2c)
 		return dev_err_probe(&i2c->dev, -ENODEV,
 				     "Invalid device ID 0x%02x\n", id);
 
-	ret = devm_mfd_add_devices(&i2c->dev, PLATFORM_DEVID_AUTO,
-				   adp5585_devs, ARRAY_SIZE(adp5585_devs),
-				   NULL, 0, NULL);
-	if (ret)
-		return dev_err_probe(&i2c->dev, ret,
-				     "Failed to add child devices\n");
-
-	return 0;
+	return adp5585_add_devices(&i2c->dev);
 }
 
 static int adp5585_suspend(struct device *dev)

-- 
2.49.0

