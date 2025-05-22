From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 22 May 2025 10:52:32 -0500
Subject: [PATCH] gpio: palmas: Allow building as a module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250522-gpio-palmas-gpio-v1-1-d6b1a3776ef5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAD9IL2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDUyMD3fSCzHzdgsSc3MRiCDvR0jIt2cDELCXZPE0JqK2gKDUtswJsZHR
 sbS0AksojLWIAAAA=
X-Change-ID: 20250520-gpio-palmas-gpio-a99fc046dc7f
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-gpio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747929156; l=1831;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=pgQV1y1p+7TtH8m/CBCGl6uKbuXEGSGVeVp8ilM/kAI=;
 b=SmQgz7oXQiNMOJaWbRJp9qhuVxXfP0XyXez4YXtuQ1dzsIsah1i4l/ZDtEkcCe/3wMrofbDrG
 XZfq4v8sHE0DoajCNESNtRGT59oToTggj5mU7wRU+VIiEHeRUBSllHm
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver works fine as a module, so allowing building as such. This
drops the driver specific init in favor of the module macro which does
the same, plus handling exit.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/gpio/Kconfig       |  2 +-
 drivers/gpio/gpio-palmas.c | 10 +++++-----
 2 files changed, 6 insertions(+), 6 deletions(-)

diff --git a/drivers/gpio/Kconfig b/drivers/gpio/Kconfig
index f2c39bbff83a33dcb12b2d32aa3ebc358a0dd949..be5d823516d0e2bff4b4231dac6a82bf10887118 100644
--- a/drivers/gpio/Kconfig
+++ b/drivers/gpio/Kconfig
@@ -1464,7 +1464,7 @@ config GPIO_MAX77650
 	  These chips have a single pin that can be configured as GPIO.
 
 config GPIO_PALMAS
-	bool "TI PALMAS series PMICs GPIO"
+	tristate "TI PALMAS series PMICs GPIO"
 	depends on MFD_PALMAS
 	help
 	  Select this option to enable GPIO driver for the TI PALMAS
diff --git a/drivers/gpio/gpio-palmas.c b/drivers/gpio/gpio-palmas.c
index 28dba7048509a3ef9c7972c1be53ea30adddabb0..c70782be502b2719bb30cf3e40065c89ecec3cc2 100644
--- a/drivers/gpio/gpio-palmas.c
+++ b/drivers/gpio/gpio-palmas.c
@@ -191,9 +191,9 @@ static struct platform_driver palmas_gpio_driver = {
 	.driver.of_match_table = of_palmas_gpio_match,
 	.probe		= palmas_gpio_probe,
 };
+module_platform_driver(palmas_gpio_driver);
 
-static int __init palmas_gpio_init(void)
-{
-	return platform_driver_register(&palmas_gpio_driver);
-}
-subsys_initcall(palmas_gpio_init);
+MODULE_ALIAS("platform:palmas_gpio");
+MODULE_DESCRIPTION("TI PALMAS series GPIO driver");
+MODULE_AUTHOR("Laxman Dewangan <ldewangan@nvidia.com>");
+MODULE_LICENSE("GPL");

---
base-commit: b36ddb9210e6812eb1c86ad46b66cc46aa193487
change-id: 20250520-gpio-palmas-gpio-a99fc046dc7f

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

