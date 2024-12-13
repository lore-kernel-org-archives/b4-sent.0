From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 13 Dec 2024 18:32:50 +0100
Subject: [PATCH 4/4] gpio: 74x164: Add latch GPIO support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241213-gpio74-v1-4-fa2c089caf41@posteo.net>
References: <20241213-gpio74-v1-0-fa2c089caf41@posteo.net>
In-Reply-To: <20241213-gpio74-v1-0-fa2c089caf41@posteo.net>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Maxime Ripard <mripard@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734111175; l=2116;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=NHTF1nhuNdR0eYjJx9o0IFR59AC3RI+5HuDVC8y4CZg=;
 b=UuX6oJtAJB0Vb331MtDfTa02d4W2XlOU+gzFGpyU8X4UfOI/j+NEDiNv4n7jPD5WalTaT4APJ
 1tu5bE8X/psDcivPrJl434Q8ssJRtCRRer2H3Yrtj5S63pqPIMGgjyb
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Fairchild MM74HC595 and other compatible parts have a latch clock
input (also known as storage register clock input), which must be
clocked once in order to apply any value that was serially shifted in.

This patch adds driver support for using a GPIO that connects to the
latch clock.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 drivers/gpio/gpio-74x164.c | 21 ++++++++++++++++++++-
 1 file changed, 20 insertions(+), 1 deletion(-)

diff --git a/drivers/gpio/gpio-74x164.c b/drivers/gpio/gpio-74x164.c
index 187032efa5b5cd1aa7aea7b2d55f6c06df4ccac4..8e87eeb7a1c7a8c71079c8d837dc5c426db8b65b 100644
--- a/drivers/gpio/gpio-74x164.c
+++ b/drivers/gpio/gpio-74x164.c
@@ -7,6 +7,7 @@
  */
 
 #include <linux/bitops.h>
+#include <linux/delay.h>
 #include <linux/gpio/consumer.h>
 #include <linux/gpio/driver.h>
 #include <linux/module.h>
@@ -21,6 +22,7 @@ struct gen_74x164_chip {
 	struct gpio_chip	gpio_chip;
 	struct mutex		lock;
 	struct gpio_desc	*gpiod_oe;
+	struct gpio_desc	*gpiod_latch;
 	u32			registers;
 	/*
 	 * Since the registers are chained, every byte sent will make
@@ -34,8 +36,20 @@ struct gen_74x164_chip {
 
 static int __gen_74x164_write_config(struct gen_74x164_chip *chip)
 {
-	return spi_write(to_spi_device(chip->gpio_chip.parent), chip->buffer,
+	int ret;
+
+	ret = spi_write(to_spi_device(chip->gpio_chip.parent), chip->buffer,
 			 chip->registers);
+	if (ret)
+		return ret;
+
+	if (chip->gpiod_latch) {
+		gpiod_set_value_cansleep(chip->gpiod_latch, 1);
+		udelay(1);
+		gpiod_set_value_cansleep(chip->gpiod_latch, 0);
+	}
+
+	return 0;
 }
 
 static int gen_74x164_get_value(struct gpio_chip *gc, unsigned offset)
@@ -127,6 +141,11 @@ static int gen_74x164_probe(struct spi_device *spi)
 	if (IS_ERR(chip->gpiod_oe))
 		return PTR_ERR(chip->gpiod_oe);
 
+	chip->gpiod_latch = devm_gpiod_get_optional(&spi->dev, "latch",
+						    GPIOD_OUT_LOW);
+	if (IS_ERR(chip->gpiod_latch))
+		return PTR_ERR(chip->gpiod_latch);
+
 	spi_set_drvdata(spi, chip);
 
 	chip->gpio_chip.label = spi->modalias;

-- 
2.45.2

