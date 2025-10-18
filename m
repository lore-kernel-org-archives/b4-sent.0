From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sat, 18 Oct 2025 11:59:47 +0200
Subject: [PATCH v2 1/2] gpio: i.MX: make _get_value() able to read output
 pin state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251018-imx_gpio-v2-1-22e4fc090de6@hotmail.com>
References: <20251018-imx_gpio-v2-0-22e4fc090de6@hotmail.com>
In-Reply-To: <20251018-imx_gpio-v2-0-22e4fc090de6@hotmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maud_spierings@hotmail.com>, 
 Ahmad Fatoum <a.fatoum@pengutronix.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760781589; l=1903;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=2RS2Lgt/bT52qDc9z9qZp64xftOMNQceTk9B57QI0ko=;
 b=lTKNqp7ogic62TIXw3+liKqD7kmvVJvuSXwpvyb1amR+zQG+1TjMVxDJRjO1TUjF/9/6HvPom
 1ES5EJjcDhLC2cjpcWgIFRps+X+RZ8ichty7kP1///nvQ1ie37hpxs8
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make _get_value() read back the dr register instead of the psr register
when the direction is set to output. Now _get_value() can actually read
the state of an output gpio instead of being always low.

This aproach is also used by u-boot and Linux.

Reviewed-by: Ahmad Fatoum <a.fatoum@pengutronix.de>
Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
 drivers/gpio/gpio-imx.c | 19 +++++++++++--------
 1 file changed, 11 insertions(+), 8 deletions(-)

diff --git a/drivers/gpio/gpio-imx.c b/drivers/gpio/gpio-imx.c
index d9499c66cd..bb14c56399 100644
--- a/drivers/gpio/gpio-imx.c
+++ b/drivers/gpio/gpio-imx.c
@@ -89,24 +89,27 @@ static int imx_gpio_direction_output(struct gpio_chip *chip, unsigned gpio, int
 	return 0;
 }
 
-static int imx_gpio_get_value(struct gpio_chip *chip, unsigned gpio)
+static int imx_get_direction(struct gpio_chip *chip, unsigned offset)
 {
 	struct imx_gpio_chip *imxgpio = container_of(chip, struct imx_gpio_chip, chip);
 	void __iomem *base = imxgpio->base;
-	u32 val;
-
-	val = readl(base + imxgpio->regs->psr);
+	u32 val = readl(base + imxgpio->regs->gdir);
 
-	return val & (1 << gpio) ? 1 : 0;
+	return (val & (1 << offset)) ? GPIOF_DIR_OUT : GPIOF_DIR_IN;
 }
 
-static int imx_get_direction(struct gpio_chip *chip, unsigned offset)
+static int imx_gpio_get_value(struct gpio_chip *chip, unsigned gpio)
 {
 	struct imx_gpio_chip *imxgpio = container_of(chip, struct imx_gpio_chip, chip);
 	void __iomem *base = imxgpio->base;
-	u32 val = readl(base + imxgpio->regs->gdir);
+	u32 val;
 
-	return (val & (1 << offset)) ? GPIOF_DIR_OUT : GPIOF_DIR_IN;
+	if (imx_get_direction(chip, gpio) == GPIOF_DIR_IN)
+		val = readl(base + imxgpio->regs->psr);
+	else
+		val = readl(base + imxgpio->regs->dr);
+
+	return val & (1 << gpio) ? 1 : 0;
 }
 
 static struct gpio_ops imx_gpio_ops = {

-- 
2.51.1.dirty

