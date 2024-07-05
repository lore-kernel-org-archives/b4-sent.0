From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 05 Jul 2024 17:12:39 +0200
Subject: [PATCH v2 1/4] spi: xcomm: add gpiochip support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240705-dev-spi-xcomm-gpiochip-v2-1-b10842fc9636@analog.com>
References: <20240705-dev-spi-xcomm-gpiochip-v2-0-b10842fc9636@analog.com>
In-Reply-To: <20240705-dev-spi-xcomm-gpiochip-v2-0-b10842fc9636@analog.com>
To: linux-spi@vger.kernel.org
Cc: Mark Brown <broonie@kernel.org>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Michael Hennerich <michael.hennerich@analog.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720192365; l=2456;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=sm/LUmqNmbQc+0zUV9BX4JH9pxe+vkMJ6Q/b4sAIHW4=;
 b=yLlJuu0yEz4OPzzx702Hne37YH8dzQSY5dtmF9bSEbVvw5OGG1j9V91OeZqVZ4skEp+vGmCdE
 xKZBJ34ZlbQB0S1+sxHoRrDl2hlV+CGRZAc20vqz2ZKWaqG8oK/Kd0A
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Michael Hennerich <michael.hennerich@analog.com>

The hardware can expose one pin as a GPO. Hence, register a simple
gpiochip to support it.

Signed-off-by: Michael Hennerich <michael.hennerich@analog.com>
Co-developed-by: Nuno Sa <nuno.sa@analog.com>
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/spi/spi-xcomm.c | 42 +++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 41 insertions(+), 1 deletion(-)

diff --git a/drivers/spi/spi-xcomm.c b/drivers/spi/spi-xcomm.c
index 63354dd3110fc..063ce75af6504 100644
--- a/drivers/spi/spi-xcomm.c
+++ b/drivers/spi/spi-xcomm.c
@@ -10,6 +10,7 @@
 #include <linux/module.h>
 #include <linux/delay.h>
 #include <linux/i2c.h>
+#include <linux/gpio/driver.h>
 #include <linux/spi/spi.h>
 #include <asm/unaligned.h>
 
@@ -26,12 +27,15 @@
 
 #define SPI_XCOMM_CMD_UPDATE_CONFIG	0x03
 #define SPI_XCOMM_CMD_WRITE		0x04
+#define SPI_XCOMM_CMD_GPIO_SET		0x05
 
 #define SPI_XCOMM_CLOCK 48000000
 
 struct spi_xcomm {
 	struct i2c_client *i2c;
 
+	struct gpio_chip gc;
+
 	uint16_t settings;
 	uint16_t chipselect;
 
@@ -40,6 +44,42 @@ struct spi_xcomm {
 	uint8_t buf[63];
 };
 
+static void spi_xcomm_gpio_set_value(struct gpio_chip *chip,
+				     unsigned int offset, int val)
+{
+	struct spi_xcomm *spi_xcomm = gpiochip_get_data(chip);
+	unsigned char buf[2];
+
+	buf[0] = SPI_XCOMM_CMD_GPIO_SET;
+	buf[1] = !!val;
+
+	i2c_master_send(spi_xcomm->i2c, buf, 2);
+}
+
+static int spi_xcomm_gpio_get_direction(struct gpio_chip *chip,
+					unsigned int offset)
+{
+	return GPIO_LINE_DIRECTION_OUT;
+}
+
+static int spi_xcomm_gpio_add(struct spi_xcomm *spi_xcomm)
+{
+	struct device *dev = &spi_xcomm->i2c->dev;
+
+	if (!IS_ENABLED(CONFIG_GPIOLIB))
+		return 0;
+
+	spi_xcomm->gc.get_direction = spi_xcomm_gpio_get_direction;
+	spi_xcomm->gc.set = spi_xcomm_gpio_set_value;
+	spi_xcomm->gc.can_sleep = 1;
+	spi_xcomm->gc.base = -1;
+	spi_xcomm->gc.ngpio = 1;
+	spi_xcomm->gc.label = spi_xcomm->i2c->name;
+	spi_xcomm->gc.owner = THIS_MODULE;
+
+	return devm_gpiochip_add_data(dev, &spi_xcomm->gc, spi_xcomm);
+}
+
 static int spi_xcomm_sync_config(struct spi_xcomm *spi_xcomm, unsigned int len)
 {
 	uint16_t settings;
@@ -227,7 +267,7 @@ static int spi_xcomm_probe(struct i2c_client *i2c)
 	if (ret < 0)
 		spi_controller_put(host);
 
-	return ret;
+	return spi_xcomm_gpio_add(spi_xcomm);
 }
 
 static const struct i2c_device_id spi_xcomm_ids[] = {

-- 
2.45.2

