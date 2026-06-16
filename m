From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 16 Jun 2026 09:21:13 +0100
Subject: [PATCH v3 07/12] iio: dac: ad5686: add ldac gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260616-ad5686-new-features-v3-7-f829fb7e9262@analog.com>
References: <20260616-ad5686-new-features-v3-0-f829fb7e9262@analog.com>
In-Reply-To: <20260616-ad5686-new-features-v3-0-f829fb7e9262@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781598070; l=2240;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=E84ULT/Vw/G5qLeMh29ivnSFEoa859ccYBvweeQdKOc=;
 b=tMLyqKmy3xKUR2xPpSl6VqCtFlpxl3Lsf58PkMv31NG6gey8/gQ+iv2PufuDj/7Obsu4kYdNM
 G076RR4JXYsB7BBhTbxcBQjeGP+jb1kUutXb38mwCUra9e2AtfdfIMc
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If wired LDAC, should be held low when unused (pin is active-low), which
allows for synchronous DAC updates. This will be used to update all the
channels at the same time when adding buffer support.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686.c | 6 ++++++
 drivers/iio/dac/ad5686.h | 3 +++
 2 files changed, 9 insertions(+)

diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index a48acedff51c..73105c197964 100644
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
@@ -515,6 +516,11 @@ int ad5686_probe(struct device *dev,
 		return dev_err_probe(dev, PTR_ERR(rstc),
 				     "Failed to get reset control\n");
 
+	st->ldac_gpio = devm_gpiod_get_optional(dev, "ldac", GPIOD_OUT_HIGH);
+	if (IS_ERR(st->ldac_gpio))
+		return dev_err_probe(dev, PTR_ERR(st->ldac_gpio),
+				     "Failed to get LDAC GPIO\n");
+
 	reset_control_assert(rstc);
 	fsleep(1); /* reset pulse: comfortably bigger than the spec */
 	reset_control_deassert(rstc);
diff --git a/drivers/iio/dac/ad5686.h b/drivers/iio/dac/ad5686.h
index a06fe7d89305..f3110410d89b 100644
--- a/drivers/iio/dac/ad5686.h
+++ b/drivers/iio/dac/ad5686.h
@@ -60,6 +60,7 @@ enum ad5686_regmap_type {
 	AD5686_REGMAP,
 };
 
+struct gpio_desc;
 struct ad5686_state;
 
 /**
@@ -119,6 +120,7 @@ extern const struct ad5686_chip_info ad5679r_chip_info;
  * @dev:		device instance
  * @chip_info:		chip model specific constants, available modes etc
  * @ops:		bus specific operations
+ * @ldac_gpio:		LDAC pin GPIO descriptor
  * @vref_mv:		actual reference voltage used
  * @pwr_down_mask:	power down mask
  * @pwr_down_mode:	current power down mode
@@ -131,6 +133,7 @@ struct ad5686_state {
 	struct device			*dev;
 	const struct ad5686_chip_info	*chip_info;
 	const struct ad5686_bus_ops	*ops;
+	struct gpio_desc		*ldac_gpio;
 	unsigned short			vref_mv;
 	unsigned int			pwr_down_mask;
 	unsigned int			pwr_down_mode;

-- 
2.43.0

