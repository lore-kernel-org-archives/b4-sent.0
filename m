From: Dang Huynh <dang.huynh@mainlining.org>
Date: Wed, 17 Sep 2025 03:25:14 +0700
Subject: [PATCH 17/25] drivers: gpio: rda: Make direction register
 unreadable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250917-rda8810pl-drivers-v1-17-9ca9184ca977@mainlining.org>
References: <20250917-rda8810pl-drivers-v1-0-9ca9184ca977@mainlining.org>
In-Reply-To: <20250917-rda8810pl-drivers-v1-0-9ca9184ca977@mainlining.org>
To: Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Sebastian Reichel <sre@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Ulf Hansson <ulf.hansson@linaro.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-unisoc@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-rtc@vger.kernel.org, 
 linux-clk@vger.kernel.org, linux-pm@vger.kernel.org, 
 dmaengine@vger.kernel.org, linux-hardening@vger.kernel.org, 
 linux-mmc@vger.kernel.org, Dang Huynh <dang.huynh@mainlining.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758054322; l=890;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=Ej4sfxzJ/Gsg0f6d9t0Id5MGonhTVkngeFDG/IpOGqc=;
 b=7/dQ+zSEH7UofRPjo+bKlBs6ViTT+WuJvSx4Gecx+bo6BYwM3Re5lMQKArpXET7WxhoCPOvfe
 Rk52QJ6IW9cA55W805ijHTkhu0687ofj0g1SAA1xQxJl5AhXuzcWLTL
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The register doesn't like to be read, this causes the SD Card
Card Detect GPIO to misbehaves in the OS.

Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 drivers/gpio/gpio-rda.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpio/gpio-rda.c b/drivers/gpio/gpio-rda.c
index b4db8553a2371ae407fdb7e681d0f82c4d9f74b7..56aaa9f33d29469dfb1bf86ed7b63c54b413c89c 100644
--- a/drivers/gpio/gpio-rda.c
+++ b/drivers/gpio/gpio-rda.c
@@ -245,7 +245,7 @@ static int rda_gpio_probe(struct platform_device *pdev)
 		.clr = rda_gpio->base + RDA_GPIO_CLR,
 		.dirout = rda_gpio->base + RDA_GPIO_OEN_SET_OUT,
 		.dirin = rda_gpio->base + RDA_GPIO_OEN_SET_IN,
-		.flags = BGPIOF_READ_OUTPUT_REG_SET,
+		.flags = BGPIOF_READ_OUTPUT_REG_SET | BGPIOF_UNREADABLE_REG_DIR,
 	};
 
 	ret = gpio_generic_chip_init(&rda_gpio->chip, &config);

-- 
2.51.0

