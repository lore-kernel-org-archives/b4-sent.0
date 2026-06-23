From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 23 Jun 2026 11:55:45 +0100
Subject: [PATCH v4 05/12] iio: dac: ad5686: add support for missing power
 supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260623-ad5686-new-features-v4-5-28962a57db0f@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782212158; l=2460;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=Tr442c1u34XlsfiJuHQO8gjG3hY5veMoFtLrjc67lHs=;
 b=GXzwp+mOq/Ypfd7XZATgviGYnv/fuqLxK0d076CI1ac5w+xhPAjP5fiunyqJahB9rk79XSDBR
 6HhECGBqSDoCkTKOkb1OU9KAv1CLCrCI+8OGASDHdkpwp4UrVssKE6V
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Get and enable regulators for vdd, vlogic and vref input power pins. Vdd
is the input power supply, while vlogic powers the digital side. vref is
replacing vcc, which is being deprecated, but still supported. The value
of vref_mv is checked so that a device without internal voltage reference
cannot proceed without an explicit supply. For correct operation, vdd and
vlogic are required, then devm_regulator_get_enable() is used so the
driver can still work without them by using the stub/dummy regulators.
Error report uses dev_err_probe(), which helps debugging an init issue.
A small delay is added after the regulators are enabled to consider for
the power-up time (4.5 us).

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686.c | 22 ++++++++++++++++++++--
 1 file changed, 20 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index 5840fda4b011..e2ebabca6887 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -8,6 +8,8 @@
 #include <linux/array_size.h>
 #include <linux/bitfield.h>
 #include <linux/bitops.h>
+#include <linux/delay.h>
+#include <linux/dev_printk.h>
 #include <linux/errno.h>
 #include <linux/export.h>
 #include <linux/kstrtox.h>
@@ -484,12 +486,28 @@ int ad5686_probe(struct device *dev,
 	st->ops = ops;
 	st->chip_info = chip_info;
 
-	ret = devm_regulator_get_enable_read_voltage(dev, "vcc");
+	ret = devm_regulator_get_enable(dev, "vdd");
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to enable vdd supply\n");
+
+	ret = devm_regulator_get_enable(dev, "vlogic");
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to enable vlogic supply\n");
+
+	ret = devm_regulator_get_enable_read_voltage(dev, "vref");
+	if (ret == -ENODEV) /* vcc-supply is deprecated, but supported still */
+		ret = devm_regulator_get_enable_read_voltage(dev, "vcc");
 	if (ret < 0 && ret != -ENODEV)
-		return ret;
+		return dev_err_probe(dev, ret, "failed to read vref voltage\n");
 
 	st->use_internal_vref = ret == -ENODEV;
 	st->vref_mv = st->use_internal_vref ? st->chip_info->int_vref_mv : ret / 1000;
+	if (!st->vref_mv)
+		return dev_err_probe(dev, -EINVAL,
+				     "invalid or not provided vref voltage\n");
+
+	/* 4.5us power-up time: Datasheet Table 4: Timing Characteristics */
+	fsleep(5);
 
 	/* Initialize masks to all ones */
 	st->pwr_down_mask = ~0;

-- 
2.43.0

