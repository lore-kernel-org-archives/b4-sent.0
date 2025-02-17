From: =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
Date: Mon, 17 Feb 2025 14:07:51 +0100
Subject: [PATCH 1/2] drivers: gpio: Add support for PCF8574T.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250217-gpio-pcf8574t-v1-1-137e140df5fc@gmail.com>
References: <20250217-gpio-pcf8574t-v1-0-137e140df5fc@gmail.com>
In-Reply-To: <20250217-gpio-pcf8574t-v1-0-137e140df5fc@gmail.com>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Laurent Pinchart <laurent.pinchart+renesas@ideasonboard.com>
Cc: linux-gpio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739797690; l=1707;
 i=gomba007@gmail.com; s=20230706; h=from:subject:message-id;
 bh=NOilr3HjpQ2oJwKALY56/6mHBbZIdGAWuyLI56+xsUI=;
 b=sKvDFTQlBO+NeSz7z25NPSzCWoyS+E5DMNcVsDhEZ2ucbeo25xuwX7zPYjlCj2BtSTvp9VAlo
 wTn92AND2faCHsd5CjQONktugAJCSsLWoG7NodqPsx3MhLfrSobWM27
X-Developer-Key: i=gomba007@gmail.com; a=ed25519;
 pk=iY9MjPCbud82ULS2PQJIq3QwjKyP/Sg730I6T2M8Y5U=
X-Endpoint-Received: by B4 Relay for gomba007@gmail.com/20230706 with auth_id=60
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the PCF8574T 8-bit I2C I/O expander.

The driver is tested with:
	+ tools/lsgpio
	+ tools/gpio-hammer
	+ some LEDs

[1] https://www.nxp.com/docs/en/data-sheet/PCF8574_PCF8574A.pdf

Signed-off-by: Tóth János <gomba007@gmail.com>
---
 drivers/gpio/Kconfig        | 2 +-
 drivers/gpio/gpio-pcf857x.c | 2 ++
 2 files changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/gpio/Kconfig b/drivers/gpio/Kconfig
index 98b4d1633b25..d7cdc3cc1b00 100644
--- a/drivers/gpio/Kconfig
+++ b/drivers/gpio/Kconfig
@@ -1193,7 +1193,7 @@ config GPIO_PCF857X
 	  Most of these parts are from NXP, though TI is a second source for
 	  some of them.  Compatible models include:
 
-	  8 bits:   pcf8574, pcf8574a, pca8574, pca8574a,
+	  8 bits:   pcf8574, pcf8574a, pcf8574t, pca8574, pca8574a,
 	            pca9670, pca9672, pca9674, pca9674a,
 	            max7328, max7329
 
diff --git a/drivers/gpio/gpio-pcf857x.c b/drivers/gpio/gpio-pcf857x.c
index 7c57eaeb0afe..2464c527a4e8 100644
--- a/drivers/gpio/gpio-pcf857x.c
+++ b/drivers/gpio/gpio-pcf857x.c
@@ -20,6 +20,7 @@
 static const struct i2c_device_id pcf857x_id[] = {
 	{ "pcf8574", 8 },
 	{ "pcf8574a", 8 },
+	{ "pcf8574t", 8 },
 	{ "pca8574", 8 },
 	{ "pca9670", 8 },
 	{ "pca9672", 8 },
@@ -38,6 +39,7 @@ MODULE_DEVICE_TABLE(i2c, pcf857x_id);
 static const struct of_device_id pcf857x_of_table[] = {
 	{ .compatible = "nxp,pcf8574", (void *)8 },
 	{ .compatible = "nxp,pcf8574a", (void *)8 },
+	{ .compatible = "nxp,pcf8574t", (void *)8 },
 	{ .compatible = "nxp,pca8574", (void *)8 },
 	{ .compatible = "nxp,pca9670", (void *)8 },
 	{ .compatible = "nxp,pca9672", (void *)8 },

-- 
2.34.1

