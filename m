From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 02 Jul 2025 00:56:26 -0500
Subject: [PATCH v3] gpio: palmas: Allow building as a module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250702-gpio-palmas-gpio-v3-1-e04633e0bc54@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAnKZGgC/4XNSwrCMBCA4avIrI0k6cu48h7iYsyjHWibkkhQS
 u9uWhEEF+7mH5hvZog2kI1w2s0QbKJIfsxR7HegOxxby8jkBsllxSvJWTuRZxP2A8b3jEo5zcv
 a6MZBPpuCdfTYyMs1d0fx7sNz+5DEuv1g8hdLgglm6pvAomlq66pzOyD1B+0HWLEk/wEyA0flJ
 FemRFWqb2BZlhe1sK618QAAAA==
X-Change-ID: 20250520-gpio-palmas-gpio-a99fc046dc7f
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-gpio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751435790; l=2298;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=wuPE+Xa58DGHAJ94TOlU6rlu8eroAUhZO7AO/CSPQEY=;
 b=iYX8TbCNm5Bdn/chuijhB+twCaPd6mcIeWGhUpxAQnndjZBy+dh3QaEZLvHY1b7jGyAXRm/fl
 sNHA7INVOLECzegyyW6+4F5xWqVes+IwNKrXFlwiv66T0AsvcrXLQ6N
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver works fine as a module, so allowing building as such. This
adds an exit handler to support module unload.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v3:
- Drop use of module init macro and add exit handler
- Link to v2: https://lore.kernel.org/r/20250522-gpio-palmas-gpio-v2-1-89f209d4a949@gmail.com

Changes in v2:
- Drop module alias and add module device table
- Link to v1: https://lore.kernel.org/r/20250522-gpio-palmas-gpio-v1-1-d6b1a3776ef5@gmail.com
---
 drivers/gpio/Kconfig       |  2 +-
 drivers/gpio/gpio-palmas.c | 11 +++++++++++
 2 files changed, 12 insertions(+), 1 deletion(-)

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
index 28dba7048509a3ef9c7972c1be53ea30adddabb0..232b3ac52b3362c33ea8b068d5932f682816a5e4 100644
--- a/drivers/gpio/gpio-palmas.c
+++ b/drivers/gpio/gpio-palmas.c
@@ -140,6 +140,7 @@ static const struct of_device_id of_palmas_gpio_match[] = {
 	{ .compatible = "ti,tps80036-gpio", .data = &tps80036_dev_data,},
 	{ },
 };
+MODULE_DEVICE_TABLE(of, of_palmas_gpio_match);
 
 static int palmas_gpio_probe(struct platform_device *pdev)
 {
@@ -197,3 +198,13 @@ static int __init palmas_gpio_init(void)
 	return platform_driver_register(&palmas_gpio_driver);
 }
 subsys_initcall(palmas_gpio_init);
+
+static void __exit palmas_gpio_exit(void)
+{
+	platform_driver_unregister(&palmas_gpio_driver);
+}
+module_exit(palmas_gpio_exit);
+
+MODULE_DESCRIPTION("TI PALMAS series GPIO driver");
+MODULE_AUTHOR("Laxman Dewangan <ldewangan@nvidia.com>");
+MODULE_LICENSE("GPL");

---
base-commit: b36ddb9210e6812eb1c86ad46b66cc46aa193487
change-id: 20250520-gpio-palmas-gpio-a99fc046dc7f

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

