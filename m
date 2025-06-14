From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Sat, 14 Jun 2025 15:36:09 +0100
Subject: [PATCH v5 18/20] mfd: adp5585: support getting vdd regulator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250614-dev-adp5589-fw-v5-18-7e9d84906268@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749911835; l=1292;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=YHxZoknRry0Hvk65sFGbz6N2xfvPc6b8ZJ/D4iQv1WE=;
 b=0hM2FsIW6Az+gChfSNnyXhFkFS73Ok6JojvajuTuwM37Q8I9Hj+36R8H3GefYF4TgUIp6Yjxf
 jx8qmSVylyKBtXZApkm/XEbl+j+QdqzudGDMj1ruFXNMtGYRAxnBZgZ
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make sure we get and enable the VDD supply (if available).

Reviewed-by: Lee Jones <lee@kernel.org>
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/mfd/adp5585.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/mfd/adp5585.c b/drivers/mfd/adp5585.c
index 3a53bc895e60e6a10f797aebcc29b722906ff087..e4a725b9e1475be03cd26898faa7a7bb8de4319b 100644
--- a/drivers/mfd/adp5585.c
+++ b/drivers/mfd/adp5585.c
@@ -17,6 +17,7 @@
 #include <linux/mod_devicetable.h>
 #include <linux/module.h>
 #include <linux/regmap.h>
+#include <linux/regulator/consumer.h>
 #include <linux/types.h>
 
 enum {
@@ -710,6 +711,10 @@ static int adp5585_i2c_probe(struct i2c_client *i2c)
 	if (IS_ERR(regmap_config))
 		return PTR_ERR(regmap_config);
 
+	ret = devm_regulator_get_enable(&i2c->dev, "vdd");
+	if (ret)
+		return ret;
+
 	adp5585->regmap = devm_regmap_init_i2c(i2c, regmap_config);
 	if (IS_ERR(adp5585->regmap))
 		return dev_err_probe(&i2c->dev, PTR_ERR(adp5585->regmap),
@@ -726,6 +731,7 @@ static int adp5585_i2c_probe(struct i2c_client *i2c)
 				     "Invalid device ID 0x%02x\n", id);
 
 	adp5585->pin_usage = devm_bitmap_zalloc(&i2c->dev, adp5585->n_pins, GFP_KERNEL);
+
 	if (!adp5585->pin_usage)
 		return -ENOMEM;
 

-- 
2.49.0

