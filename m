From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Tue, 24 Dec 2024 09:02:11 +0100
Subject: [PATCH v2 2/3] gpio: 74x164: Add On Semi MC74HC595A compat
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241224-gpio74-v2-2-bbcf14183191@posteo.net>
References: <20241224-gpio74-v2-0-bbcf14183191@posteo.net>
In-Reply-To: <20241224-gpio74-v2-0-bbcf14183191@posteo.net>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Maxime Ripard <mripard@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735027364; l=1201;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=jNZ4WbNdUkUKrupx6QKar4ygLSbl4KDsxbO9QciWLhg=;
 b=6sCPX2fn+hTmdmKC0JmdHwlHcc48bkvOZEJS2VyR7/dK8l6n4WbEio67KcA7woh/7UOgghbHj
 BzCq6M1mctbC3+21CG6xAh2Ba8YWTyNIDFBZSNupdfnxls9BQvUD2Ar
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The On Semi MC74HC595A/MC74HCT595A is another part that is compatible
with the Fairchild MM74HC595. This patch adds it to the driver.

Reviewed-by: Linus Walleij <linus.walleij@linaro.org>
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

v2:
- Add Linus Walleij's R-b
- Add missing spi_device_id entry, required by the SPI core
---
 drivers/gpio/gpio-74x164.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpio/gpio-74x164.c b/drivers/gpio/gpio-74x164.c
index fca6cd2eb1ddacb3c330111343ebecf9b7c9234d..2ce00e90ea5650673420d7852999d13c298c2db6 100644
--- a/drivers/gpio/gpio-74x164.c
+++ b/drivers/gpio/gpio-74x164.c
@@ -165,6 +165,7 @@ static void gen_74x164_remove(struct spi_device *spi)
 
 static const struct spi_device_id gen_74x164_spi_ids[] = {
 	{ .name = "74hc595" },
+	{ .name = "74hc595a" },
 	{ .name = "74lvc594" },
 	{},
 };
@@ -173,6 +174,7 @@ MODULE_DEVICE_TABLE(spi, gen_74x164_spi_ids);
 static const struct of_device_id gen_74x164_dt_ids[] = {
 	{ .compatible = "fairchild,74hc595" },
 	{ .compatible = "nxp,74lvc594" },
+	{ .compatible = "onnn,74hc595a" },
 	{},
 };
 MODULE_DEVICE_TABLE(of, gen_74x164_dt_ids);

-- 
2.45.2

