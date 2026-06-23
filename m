From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 23 Jun 2026 11:55:47 +0100
Subject: [PATCH v4 07/12] iio: dac: ad5686: add ldac gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260623-ad5686-new-features-v4-7-28962a57db0f@analog.com>
References: <20260623-ad5686-new-features-v4-0-28962a57db0f@analog.com>
In-Reply-To: <20260623-ad5686-new-features-v4-0-28962a57db0f@analog.com>
To: Michael Auchter <michael.auchter@ni.com>, linux@analog.com, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782212158; l=2164;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=qIXIbMOm8r3LJQkfBJp1eZbsYSUAGUStilUJvzLUnp0=;
 b=whCIm+R7Ww3LF+rxDWOC4SeqbumoYAH3pEyYEVz4CldQOsdOP0R1owY250wmwkx+ZuiwuPK/A
 X/EXB6P9CJsAXrsCZQofGM9A7DjcNLLUqbGH4luam8CGtmrwB84baYB
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If wired LDAC, should be asserted when unused (pin is active-low), which
allows for synchronous DAC updates. This will be used to update all the
channels at the same time when adding buffer support.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686.c | 6 ++++++
 drivers/iio/dac/ad5686.h | 4 ++++
 2 files changed, 10 insertions(+)

diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index 8ad8931a3d7f..713fe71ad1e7 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -12,6 +12,7 @@
 #include <linux/dev_printk.h>
 #include <linux/errno.h>
 #include <linux/export.h>
+#include <linux/gpio/consumer.h>
 #include <linux/kstrtox.h>
 #include <linux/module.h>
 #include <linux/regulator/consumer.h>
@@ -521,6 +522,11 @@ int ad5686_probe(struct device *dev,
 	fsleep(1);
 	reset_control_deassert(rstc);
 
+	st->ldac_gpio = devm_gpiod_get_optional(dev, "ldac", GPIOD_OUT_HIGH);
+	if (IS_ERR(st->ldac_gpio))
+		return dev_err_probe(dev, PTR_ERR(st->ldac_gpio),
+				     "Failed to get LDAC GPIO\n");
+
 	/* Initialize masks to all ones */
 	st->pwr_down_mask = ~0;
 	st->pwr_down_mode = ~0;
diff --git a/drivers/iio/dac/ad5686.h b/drivers/iio/dac/ad5686.h
index a06fe7d89305..c424720f8f72 100644
--- a/drivers/iio/dac/ad5686.h
+++ b/drivers/iio/dac/ad5686.h
@@ -60,6 +60,8 @@ enum ad5686_regmap_type {
 	AD5686_REGMAP,
 };
 
+struct gpio_desc;
+
 struct ad5686_state;
 
 /**
@@ -119,6 +121,7 @@ extern const struct ad5686_chip_info ad5679r_chip_info;
  * @dev:		device instance
  * @chip_info:		chip model specific constants, available modes etc
  * @ops:		bus specific operations
+ * @ldac_gpio:		LDAC pin GPIO descriptor
  * @vref_mv:		actual reference voltage used
  * @pwr_down_mask:	power down mask
  * @pwr_down_mode:	current power down mode
@@ -131,6 +134,7 @@ struct ad5686_state {
 	struct device			*dev;
 	const struct ad5686_chip_info	*chip_info;
 	const struct ad5686_bus_ops	*ops;
+	struct gpio_desc		*ldac_gpio;
 	unsigned short			vref_mv;
 	unsigned int			pwr_down_mask;
 	unsigned int			pwr_down_mode;

-- 
2.43.0

