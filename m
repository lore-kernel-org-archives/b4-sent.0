From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Mon, 12 May 2025 13:38:54 +0100
Subject: [PATCH v3 02/22] mfd: adp5585: only add devices given in FW
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250512-dev-adp5589-fw-v3-2-092b14b79a88@analog.com>
References: <20250512-dev-adp5589-fw-v3-0-092b14b79a88@analog.com>
In-Reply-To: <20250512-dev-adp5589-fw-v3-0-092b14b79a88@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747053537; l=2562;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=p1qFaXq/Tlp65PC7izdwLK8ARXRCtU7DhWNOoYI6ohQ=;
 b=2h4pLETaeUA42Tl62ZzpSKm/Xsp/92O/UM+yFjjc9lD+otCcXJrEkbpQnMcC8rw4YVs1aAvpY
 KFdi+0mTnCqB71QLbVuogrncPfYC+NpTwIn3DqVC6kWHffYmZWfDdBQ
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Not all devices (features) of the adp5585 device are mandatory to be
used in all platforms. Hence, check what's given in FW and dynamically
create the mfd_cell array to be given to devm_mfd_add_devices().

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/mfd/adp5585.c | 45 +++++++++++++++++++++++++++++++++++++++++----
 1 file changed, 41 insertions(+), 4 deletions(-)

diff --git a/drivers/mfd/adp5585.c b/drivers/mfd/adp5585.c
index 160e0b38106a6d78f7d4b7c866cb603d96ea673e..02f9e8c1c6a1d8b9516c060e0024d69886e9fb7a 100644
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
@@ -110,12 +116,40 @@ static const struct regmap_config adp5585_regmap_configs[] = {
 	},
 };
 
+static int adp5585_parse_fw(struct device *dev, struct adp5585_dev *adp5585,
+			    struct mfd_cell **devs)
+{
+	unsigned int has_pwm = 0, has_gpio = 0, rc = 0;
+
+	if (device_property_present(dev, "#pwm-cells"))
+		has_pwm = 1;
+
+	if (device_property_present(dev, "#gpio-cells"))
+		has_gpio = 1;
+
+	if (!has_pwm && !has_gpio)
+		return -ENODEV;
+
+	*devs = devm_kcalloc(dev, has_pwm + has_gpio, sizeof(struct mfd_cell),
+			     GFP_KERNEL);
+	if (!*devs)
+		return -ENOMEM;
+
+	if (has_pwm)
+		(*devs)[rc++] = adp5585_devs[ADP5585_DEV_PWM];
+	if (has_gpio)
+		(*devs)[rc++] = adp5585_devs[ADP5585_DEV_GPIO];
+
+	return rc;
+}
+
 static int adp5585_i2c_probe(struct i2c_client *i2c)
 {
 	const struct regmap_config *regmap_config;
 	struct adp5585_dev *adp5585;
+	struct mfd_cell *devs;
 	unsigned int id;
-	int ret;
+	int ret, n_devs;
 
 	adp5585 = devm_kzalloc(&i2c->dev, sizeof(*adp5585), GFP_KERNEL);
 	if (!adp5585)
@@ -138,9 +172,12 @@ static int adp5585_i2c_probe(struct i2c_client *i2c)
 		return dev_err_probe(&i2c->dev, -ENODEV,
 				     "Invalid device ID 0x%02x\n", id);
 
+	n_devs = adp5585_parse_fw(&i2c->dev, adp5585, &devs);
+	if (n_devs < 0)
+		return n_devs;
+
 	ret = devm_mfd_add_devices(&i2c->dev, PLATFORM_DEVID_AUTO,
-				   adp5585_devs, ARRAY_SIZE(adp5585_devs),
-				   NULL, 0, NULL);
+				   devs, n_devs, NULL, 0, NULL);
 	if (ret)
 		return dev_err_probe(&i2c->dev, ret,
 				     "Failed to add child devices\n");

-- 
2.49.0

