From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 15 Apr 2025 15:49:32 +0100
Subject: [PATCH v2 16/17] mfd: adp5585: add support for a reset pin
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250415-dev-adp5589-fw-v2-16-3a799c3ed812@analog.com>
References: <20250415-dev-adp5589-fw-v2-0-3a799c3ed812@analog.com>
In-Reply-To: <20250415-dev-adp5589-fw-v2-0-3a799c3ed812@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744728560; l=1359;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=YXvB+ZSL0gZ4TQpg4/Gr7rz9RArZE2EGcmubpPAGy0c=;
 b=c7XdjNLWoVohdo+K7gcTPaJ5dYtAo7/Xwwh8fOzY6qtAOuLhu1jL12IQfKPYutOaaCRnsXoTA
 UoNtNj6O6TeBfW9lIip3xC+GP1YwGhi1nvj91grKr5LKet32SFr2rcd
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make sure to perform an Hardware reset during probe  if the pin is given
in FW.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/mfd/adp5585.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/mfd/adp5585.c b/drivers/mfd/adp5585.c
index 667cc5bd0745f64eec60837ec3c00057af0cddeb..2af110fb28054c8ad6709a9a42cb21919be433e7 100644
--- a/drivers/mfd/adp5585.c
+++ b/drivers/mfd/adp5585.c
@@ -12,6 +12,7 @@
 #include <linux/device.h>
 #include <linux/err.h>
 #include <linux/i2c.h>
+#include <linux/gpio/consumer.h>
 #include <linux/mfd/adp5585.h>
 #include <linux/mfd/core.h>
 #include <linux/minmax.h>
@@ -833,6 +834,7 @@ static int adp5585_i2c_probe(struct i2c_client *i2c)
 {
 	const struct adp5585_info *info;
 	struct adp5585_dev *adp5585;
+	struct gpio_desc *gpio;
 	unsigned int id;
 	int ret;
 
@@ -854,6 +856,16 @@ static int adp5585_i2c_probe(struct i2c_client *i2c)
 	if (ret)
 		return ret;
 
+	gpio = devm_gpiod_get_optional(&i2c->dev, "reset", GPIOD_OUT_HIGH);
+	if (IS_ERR(gpio))
+		return PTR_ERR(gpio);
+
+	if (gpio) {
+		fsleep(30);
+		gpiod_set_value_cansleep(gpio, 0);
+		fsleep(60);
+	}
+
 	adp5585->regmap = devm_regmap_init_i2c(i2c, info->regmap_config);
 	if (IS_ERR(adp5585->regmap))
 		return dev_err_probe(&i2c->dev, PTR_ERR(adp5585->regmap),

-- 
2.49.0

