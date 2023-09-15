From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Fri, 15 Sep 2023 11:11:15 +0300
Subject: [PATCH v4 33/42] gpio: ep93xx: add DT support for gpio-ep93xx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230915-ep93xx-v4-33-a1d779dcec10@maquefel.me>
References: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
In-Reply-To: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Andy Shevchenko <andy@kernel.org>
Cc: linux-gpio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>, 
 Andy Shevchenko <andy.shevchenko@gmail.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1694765525; l=993;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=7aghjn0T8vOwVoAvLNTsUFeOUJ29//nTopj4QzfsLDY=;
 b=AGYuLmPootuNhLbbH2svn6HFna04C+gkHGzYfYza0zy7TRRPpO8KQq2+wKKIvIFlk9J6DHB/UP/o
 07r5mctyA2ydriJwLu52ZlLPUgMWYiKQKtCAZT825+XpCHJqxfJC
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add OF ID match table.

Reviewed-by: Andy Shevchenko <andy.shevchenko@gmail.com>
Reviewed-by: Linus Walleij <linus.walleij@linaro.org>
Acked-by: Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 drivers/gpio/gpio-ep93xx.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/gpio/gpio-ep93xx.c b/drivers/gpio/gpio-ep93xx.c
index a55f635585f4..70997232257a 100644
--- a/drivers/gpio/gpio-ep93xx.c
+++ b/drivers/gpio/gpio-ep93xx.c
@@ -359,9 +359,15 @@ static int ep93xx_gpio_probe(struct platform_device *pdev)
 	return devm_gpiochip_add_data(&pdev->dev, gc, egc);
 }
 
+static const struct of_device_id ep93xx_gpio_match[] = {
+	{ .compatible = "cirrus,ep9301-gpio" },
+	{ /* sentinel */ }
+};
+
 static struct platform_driver ep93xx_gpio_driver = {
 	.driver		= {
 		.name	= "gpio-ep93xx",
+		.of_match_table = ep93xx_gpio_match,
 	},
 	.probe		= ep93xx_gpio_probe,
 };

-- 
2.39.2

