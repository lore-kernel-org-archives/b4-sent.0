From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 13 Dec 2024 18:32:49 +0100
Subject: [PATCH 3/4] gpio: 74x164: Add On Semi MC74HC595A compat
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241213-gpio74-v1-3-fa2c089caf41@posteo.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734111175; l=813;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=p+SUfUYDkyNDyg/5TyAQUD1YpV5pIGrbCTPlXDqshWE=;
 b=VBcoDkEueYYIwD8l+8ddCJA3JnJCeZrIc+cMWRpeiVfxRjxuCb5X/lqRgvAxv7VHZvzgpl+Nf
 tdsgqVmlPeZCaHH/q9EANaHOs0feIIaB3Yw5AaveRt8r8hbabfPAG6S
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The On Semi MC74HC595A/MC74HCT595A is another part that is compatible
with the Fairchild MM74HC595. This patch adds it to the driver.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 drivers/gpio/gpio-74x164.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpio/gpio-74x164.c b/drivers/gpio/gpio-74x164.c
index fca6cd2eb1ddacb3c330111343ebecf9b7c9234d..187032efa5b5cd1aa7aea7b2d55f6c06df4ccac4 100644
--- a/drivers/gpio/gpio-74x164.c
+++ b/drivers/gpio/gpio-74x164.c
@@ -173,6 +173,7 @@ MODULE_DEVICE_TABLE(spi, gen_74x164_spi_ids);
 static const struct of_device_id gen_74x164_dt_ids[] = {
 	{ .compatible = "fairchild,74hc595" },
 	{ .compatible = "nxp,74lvc594" },
+	{ .compatible = "onnn,74hc595a" },
 	{},
 };
 MODULE_DEVICE_TABLE(of, gen_74x164_dt_ids);

-- 
2.45.2

