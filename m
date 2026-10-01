From: Miao Wang <shankerwangmiao@gmail.com>
Date: Fri, 02 Oct 2026 02:13:22 +0800
Subject: [PATCH RFC v2 4/4] gpio: loongson-64bit: remove gpio_to_irq()
 handler
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-loongsongpio-v2-4-6e3eb150a4ef@gmail.com>
References: <20261002-loongsongpio-v2-0-6e3eb150a4ef@gmail.com>
In-Reply-To: <20261002-loongsongpio-v2-0-6e3eb150a4ef@gmail.com>
To: Yinbo Zhu <zhuyinbo@loongson.cn>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: Jiaxun Yang <jiaxun.yang@flygoat.com>, linux-gpio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1990;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=sOxZDjuak2otTPg7s201cfEhwPgcvSVkWzQzISyXx+0=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqvqL051MJZjWbgpRLaG3qnkIH7q0Je6cF5Kcgi
 Dajz6BQqrSJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCar6i9AAKCRCwMePKe/7Z
 bjsKD/43DDfSficR85QAF3BrkHy6vjoQBnSVl2F+9Zi5Hctoktc0PcRJoy26zv+4wC4Ac3I451O
 +4HD/xVi3a4up/tNiOhPE8APQ5xRDyfVwswsQo4DU47iwaabOsvO0fd47utsEULnZn+CZDeOvTR
 HtZpLkZccrjbDZ/7By3hn4dTdcMpIhEga8q5DZ3kIu2aF4DeQArJZceV2BOnguA4FDU7st48PBT
 jvSf5EHG2wRc8Md8+Q4j+XOTSuArdeqpGG2Oo7hn40P+PdC25nqrlRizUKSszZ0yuJSB6NRINYo
 NGxrWAHfl+k9PgRWVYoDGbWbb+Knrtgh51MlI3BAVZz870qE3+ngn+6/plRZHGB/gX5dpm05e06
 W1N2e/+rokAdL4czd2MHJ8YnmnCKCndQk9uk1n6+Fh5WlMErkkKI6jzuZ12x4wkpE1pAgM8uJ95
 XrpZf82ji6CG7CCHeA0+hz6lvoEiOoXxhMeiMi9L7Smi9QHxpqpnOn5wb1wBLDNLhLcAq4Ft553
 +R/6GoKq1kjZFjk+ZLYIeTAj7AzJLm7blx0rg6AXS1wHdWmWAYQVKmx7HiZkk662H6uEYsQg7nN
 is6DUnFaX/Oy/+n1tEAVwQFImmAKWpRvv6K66FKJielAcWMO+ll5/aYXlum6pPG4rMeUziJ49g4
 GdnRp+24FJZKnig==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As pointed out in the previous commit, gpio_to_irq() should not be used
because it should not be used to manipulate the registers to enable
interrupts.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 drivers/gpio/gpio-loongson-64bit.c | 20 --------------------
 1 file changed, 20 deletions(-)

diff --git a/drivers/gpio/gpio-loongson-64bit.c b/drivers/gpio/gpio-loongson-64bit.c
index 40ff845e21db18fa513d2d3b328bcb7ad16baf6a..4e6a490d524ef107e51729abd26cc4d2cbb00c41 100644
--- a/drivers/gpio/gpio-loongson-64bit.c
+++ b/drivers/gpio/gpio-loongson-64bit.c
@@ -141,24 +141,6 @@ static int loongson_gpio_set(struct gpio_chip *chip, unsigned int pin, int value
 	return 0;
 }
 
-static int loongson_gpio_to_irq(struct gpio_chip *chip, unsigned int offset)
-{
-	unsigned int u;
-	struct platform_device *pdev = to_platform_device(chip->parent);
-	struct loongson_gpio_chip *lgpio = to_loongson_gpio_chip(chip);
-
-	if (lgpio->chip_data->mode == BIT_CTRL_MODE) {
-		/* Get the register index from offset then multiply by bytes per register */
-		u = readl(lgpio->reg_base + lgpio->chip_data->inten_offset + (offset / 32) * 4);
-		u |= BIT(offset % 32);
-		writel(u, lgpio->reg_base + lgpio->chip_data->inten_offset + (offset / 32) * 4);
-	} else {
-		writeb(1, lgpio->reg_base + lgpio->chip_data->inten_offset + offset);
-	}
-
-	return platform_get_irq(pdev, offset);
-}
-
 static void loongson_gpio_irq_ack(struct irq_data *data)
 {
 	struct gpio_chip *chip = irq_data_get_irq_chip_data(data);
@@ -943,8 +925,6 @@ static int loongson_gpio_init(struct platform_device *pdev, struct loongson_gpio
 			dev_warn(&pdev->dev, "no parent IRQs ha been found, GPIO IRQs will not be available\n");
 			gpio_irq_chip_set_chip(&lgpio->chip.gc.irq, NULL);
 		}
-	} else if (lgpio->chip_data->inten_offset) {
-		lgpio->chip.gc.to_irq = loongson_gpio_to_irq;
 	}
 
 	return devm_gpiochip_add_data(&pdev->dev, &lgpio->chip.gc, lgpio);

-- 
2.55.0

