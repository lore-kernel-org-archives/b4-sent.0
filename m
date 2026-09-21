From: Long Zhao <longzhao@ambarella.com>
Date: Mon, 21 Sep 2026 20:13:33 +0800
Subject: [PATCH] gpiolib: regmap: document gpio_regmap_get_chip()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-gpio-doc-followup-v1-1-618738124f4c@ambarella.com>
X-B4-Tracking: v=1; b=H4sIAGwfsWoC/yXMQQqDQAxA0atI1gY0heL0KqWLMUZNETPMaFsQ7
 95Rl2/x/wZJokqCR7FBlI8mtTmjLgvg0c+DoHbZQBXdK0c1DkENO2PsbZrsuwZsqHHM3t1a8pC
 7EKXX3/l8vi6ntX0LL8cI9v0P19YZnnUAAAA=
X-Change-ID: 20260921-gpio-doc-followup-8289cca93b2a
To: Michael Walle <mwalle@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 linux-gpio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Long Zhao <longzhao@ambarella.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789992813; l=1526;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=Y+L15bNZYFOa//sDZ7xQisO9fFHkBPK80aO8x+9P700=;
 b=6o98tZCvmhWBfOc2PDA4G7UaGMEcvfBdQp4oM4O2udMZUvTLl09SMB69+0SbdViydUZhy39m7
 HcTo7EYJFRTA+oRFa0N2seY7pHF8+UZQv3947OJjMiHiVGforSgNWIr
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add kernel-doc for the new helper and state that it is only for GPIO
controller drivers, not for GPIO consumers.

This is a follow-up to v8 09/18.

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
Follow-up to v8 09/18:
https://lore.kernel.org/r/20260921-cv75-v5-v8-9-42de52d636a0@ambarella.com
Add kernel-doc for gpio_regmap_get_chip().
---
 drivers/gpio/gpio-regmap.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/gpio/gpio-regmap.c b/drivers/gpio/gpio-regmap.c
index 21e0993b89e2..8ba7263729a8 100644
--- a/drivers/gpio/gpio-regmap.c
+++ b/drivers/gpio/gpio-regmap.c
@@ -295,6 +295,19 @@ void *gpio_regmap_get_drvdata(struct gpio_regmap *gpio)
 }
 EXPORT_SYMBOL_GPL(gpio_regmap_get_drvdata);
 
+/**
+ * gpio_regmap_get_chip() - Return the gpio_chip of a gpio-regmap instance
+ * @gpio: Handle returned by gpio_regmap_register()
+ *
+ * GPIO controller drivers that register through gpio-regmap but still
+ * implement a custom irqchip can use this to obtain the associated
+ * gpio_chip after registration.
+ *
+ * This must not be used outside of GPIO controller driver context,
+ * for example not by GPIO consumers.
+ *
+ * Return: Pointer to the embedded struct gpio_chip.
+ */
 struct gpio_chip *gpio_regmap_get_chip(struct gpio_regmap *gpio)
 {
 	return &gpio->gpio_chip;

---
base-commit: 4b54e79ffe453959073b81638c3ac6c04177639e
change-id: 20260921-gpio-doc-followup-8289cca93b2a

Best regards,
--  
Long Zhao <longzhao@ambarella.com>

