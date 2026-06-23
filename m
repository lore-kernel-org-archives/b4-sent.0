From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 23 Jun 2026 11:55:46 +0100
Subject: [PATCH v4 06/12] iio: dac: ad5686: consume optional reset signal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260623-ad5686-new-features-v4-6-28962a57db0f@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782212158; l=1786;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=L5icfA5WYm8ov/3pCusG7IPcFnWQG1nvPrm0z48/efM=;
 b=MVMCdyoQpw/jroXdTgtf58cOTj/B2vHiSakbCztsqc8uOdTuGHPMwhZQFvF/wK2u6raai4XJJ
 b7h1meBrJnjAyTmqsNB9Rshyz0BUDZ1od2EhIjJ3PAmYlofG7QR/nuj
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add RESET pin GPIO support through an optional reset control, which is
local to the probe function. A reset pulse is manually generated after
the device is powered up.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index e2ebabca6887..8ad8931a3d7f 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -15,6 +15,7 @@
 #include <linux/kstrtox.h>
 #include <linux/module.h>
 #include <linux/regulator/consumer.h>
+#include <linux/reset.h>
 #include <linux/sysfs.h>
 #include <linux/wordpart.h>
 
@@ -472,6 +473,7 @@ int ad5686_probe(struct device *dev,
 		 const struct ad5686_chip_info *chip_info,
 		 const char *name, const struct ad5686_bus_ops *ops)
 {
+	struct reset_control *rstc;
 	struct ad5686_state *st;
 	struct iio_dev *indio_dev;
 	int ret, i;
@@ -486,6 +488,11 @@ int ad5686_probe(struct device *dev,
 	st->ops = ops;
 	st->chip_info = chip_info;
 
+	rstc = devm_reset_control_get_optional_exclusive(dev, NULL);
+	if (IS_ERR(rstc))
+		return dev_err_probe(dev, PTR_ERR(rstc),
+				     "Failed to get reset control\n");
+
 	ret = devm_regulator_get_enable(dev, "vdd");
 	if (ret)
 		return dev_err_probe(dev, ret, "failed to enable vdd supply\n");
@@ -509,6 +516,11 @@ int ad5686_probe(struct device *dev,
 	/* 4.5us power-up time: Datasheet Table 4: Timing Characteristics */
 	fsleep(5);
 
+	/* 1us >> 30ns reset pulse activation time: Datasheet Table 4 */
+	reset_control_assert(rstc);
+	fsleep(1);
+	reset_control_deassert(rstc);
+
 	/* Initialize masks to all ones */
 	st->pwr_down_mask = ~0;
 	st->pwr_down_mode = ~0;

-- 
2.43.0

