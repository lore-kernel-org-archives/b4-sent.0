From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 10 Jul 2026 12:20:46 +0100
Subject: [PATCH v7 2/7] iio: dac: ad5686: refactor command/data macros
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-ad5686-new-features-v7-2-1bcc8c280e4d@analog.com>
References: <20260710-ad5686-new-features-v7-0-1bcc8c280e4d@analog.com>
In-Reply-To: <20260710-ad5686-new-features-v7-0-1bcc8c280e4d@analog.com>
To: Michael Auchter <michael.auchter@ni.com>, linux@analog.com, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, sashiko-bot@kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783682457; l=7147;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=qRHhDvXGjsAHu+93uFBdiAIlGZwBaY4I1ZjDTZ6pcx8=;
 b=WUUdOw/nwbKkYyAOpe2Hstci3fxn9nohhUXtpvUDp3h4WZf5E91t+EEjdtAHHEVOpa/rzbIdn
 J6XiYns/tj4BethZB++H0uhoTo8ywpfDSt5wLb9Jo3XK9hXs9GKrXGt
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace usage of bit shifting macros for FIELD_PREP(), which would not
ignore bit masking when preparing SPI/I2C commands. This change is a code
hardening measure to be paired with the upcoming triggered buffer support.
For the AD5310 regmap case, 16-bit data coming from the buffer may overlap
with command bits if the data field is unmasked.

*_REF_BIT_MSK and *_PD_MSK bit position macros are renamed (with a DATA
prefix) so to indicate that they are relative to the DATA field.

Reported-by: sashiko-bot@kernel.org
Link: https://lore.kernel.org/all/20260628143026.EC6CA1F000E9@smtp.kernel.org/#t
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686-spi.c | 21 +++++++++++----------
 drivers/iio/dac/ad5686.c     | 10 +++++-----
 drivers/iio/dac/ad5686.h     | 22 ++++++++++++----------
 drivers/iio/dac/ad5696-i2c.c | 11 ++++++-----
 4 files changed, 34 insertions(+), 30 deletions(-)

diff --git a/drivers/iio/dac/ad5686-spi.c b/drivers/iio/dac/ad5686-spi.c
index 6b6ef1d7071f..d3b64b4361d5 100644
--- a/drivers/iio/dac/ad5686-spi.c
+++ b/drivers/iio/dac/ad5686-spi.c
@@ -9,6 +9,7 @@
  */
 
 #include <linux/array_size.h>
+#include <linux/bitfield.h>
 #include <linux/errno.h>
 #include <linux/mod_devicetable.h>
 #include <linux/module.h>
@@ -26,21 +27,21 @@ static int ad5686_spi_write(struct ad5686_state *st,
 
 	switch (st->chip_info->regmap_type) {
 	case AD5310_REGMAP:
-		st->data[0].d16 = cpu_to_be16(AD5310_CMD(cmd) |
-					      val);
+		st->data[0].d16 = cpu_to_be16(FIELD_PREP(AD5310_CMD_MSK, cmd) |
+					      FIELD_PREP(AD5310_DATA_MSK, val));
 		buf = &st->data[0].d8[0];
 		tx_len = 2;
 		break;
 	case AD5683_REGMAP:
-		st->data[0].d32 = cpu_to_be32(AD5686_CMD(cmd) |
-					      AD5683_DATA(val));
+		st->data[0].d32 = cpu_to_be32(FIELD_PREP(AD5686_CMD_MSK, cmd) |
+					      FIELD_PREP(AD5683_DATA_MSK, val));
 		buf = &st->data[0].d8[1];
 		tx_len = 3;
 		break;
 	case AD5686_REGMAP:
-		st->data[0].d32 = cpu_to_be32(AD5686_CMD(cmd) |
-					      AD5686_ADDR(addr) |
-					      val);
+		st->data[0].d32 = cpu_to_be32(FIELD_PREP(AD5686_CMD_MSK, cmd) |
+					      FIELD_PREP(AD5686_ADDR_MSK, addr) |
+					      FIELD_PREP(AD5686_DATA_MSK, val));
 		buf = &st->data[0].d8[1];
 		tx_len = 3;
 		break;
@@ -81,9 +82,9 @@ static int ad5686_spi_read(struct ad5686_state *st, u8 addr)
 		return -EINVAL;
 	}
 
-	st->data[0].d32 = cpu_to_be32(AD5686_CMD(cmd) |
-				      AD5686_ADDR(addr));
-	st->data[1].d32 = cpu_to_be32(AD5686_CMD(AD5686_CMD_NOOP));
+	st->data[0].d32 = cpu_to_be32(FIELD_PREP(AD5686_CMD_MSK, cmd) |
+				      FIELD_PREP(AD5686_ADDR_MSK, addr));
+	st->data[1].d32 = cpu_to_be32(FIELD_PREP(AD5686_CMD_MSK, AD5686_CMD_NOOP));
 
 	ret = spi_sync_transfer(spi, t, ARRAY_SIZE(t));
 	if (ret < 0)
diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index 713fe71ad1e7..120dd095dd2e 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -35,8 +35,8 @@ static int ad5310_control_sync(struct ad5686_state *st)
 	unsigned int pd_val = st->pwr_down_mask & st->pwr_down_mode;
 
 	return ad5686_write(st, AD5686_CMD_CONTROL_REG, 0,
-			    FIELD_PREP(AD5310_PD_MSK, pd_val & AD5686_PD_MSK) |
-			    FIELD_PREP(AD5310_REF_BIT_MSK, st->use_internal_vref ? 0 : 1));
+			    FIELD_PREP(AD5310_DATA_PD_MSK, pd_val & AD5686_PD_MSK) |
+			    FIELD_PREP(AD5310_DATA_REF_MSK, st->use_internal_vref ? 0 : 1));
 }
 
 static int ad5683_control_sync(struct ad5686_state *st)
@@ -44,8 +44,8 @@ static int ad5683_control_sync(struct ad5686_state *st)
 	unsigned int pd_val = st->pwr_down_mask & st->pwr_down_mode;
 
 	return ad5686_write(st, AD5686_CMD_CONTROL_REG, 0,
-			    FIELD_PREP(AD5683_PD_MSK, pd_val & AD5686_PD_MSK) |
-			    FIELD_PREP(AD5683_REF_BIT_MSK, st->use_internal_vref ? 0 : 1));
+			    FIELD_PREP(AD5683_DATA_PD_MSK, pd_val & AD5686_PD_MSK) |
+			    FIELD_PREP(AD5683_DATA_REF_MSK, st->use_internal_vref ? 0 : 1));
 }
 
 static inline unsigned int ad5686_pd_mask_shift(const struct iio_chan_spec *chan)
@@ -562,7 +562,7 @@ int ad5686_probe(struct device *dev,
 		break;
 	case AD5686_REGMAP:
 		ret = ad5686_write(st, AD5686_CMD_INTERNAL_REFER_SETUP, 0,
-				   st->use_internal_vref ? 0 : AD5686_REF_BIT_MSK);
+				   st->use_internal_vref ? 0 : AD5686_DATA_REF_MSK);
 		if (ret)
 			return ret;
 		break;
diff --git a/drivers/iio/dac/ad5686.h b/drivers/iio/dac/ad5686.h
index c424720f8f72..32cb3931413c 100644
--- a/drivers/iio/dac/ad5686.h
+++ b/drivers/iio/dac/ad5686.h
@@ -14,12 +14,14 @@
 
 #include <linux/iio/iio.h>
 
-#define AD5310_CMD(x)				((x) << 12)
+#define AD5310_CMD_MSK				GENMASK(15, 12)
+#define AD5310_DATA_MSK				GENMASK(11, 0)
 
-#define AD5683_DATA(x)				((x) << 4)
+#define AD5683_DATA_MSK				GENMASK(19, 4)
 
-#define AD5686_ADDR(x)				((x) << 16)
-#define AD5686_CMD(x)				((x) << 20)
+#define AD5686_CMD_MSK				GENMASK(23, 20)
+#define AD5686_ADDR_MSK				GENMASK(19, 16)
+#define AD5686_DATA_MSK				GENMASK(15, 0)
 
 #define AD5686_ADDR_DAC(chan)			(0x1 << (chan))
 #define AD5686_ADDR_ALL_DAC			0xF
@@ -38,15 +40,15 @@
 #define AD5686_CMD_CONTROL_REG			0x4
 #define AD5686_CMD_READBACK_ENABLE_V2		0x5
 
-#define AD5310_REF_BIT_MSK			BIT(8)
-#define AD5310_PD_MSK				GENMASK(10, 9)
+#define AD5310_DATA_REF_MSK			BIT(8)
+#define AD5310_DATA_PD_MSK			GENMASK(10, 9)
 
-#define AD5683_REF_BIT_MSK			BIT(12)
-#define AD5683_PD_MSK				GENMASK(14, 13)
+#define AD5683_DATA_REF_MSK			BIT(12) /* DB16 */
+#define AD5683_DATA_PD_MSK			GENMASK(14, 13) /* DB18:DB17 */
+
+#define AD5686_DATA_REF_MSK			BIT(0)
 
-#define AD5686_REF_BIT_MSK			BIT(0)
 #define AD5686_PD_MSK				GENMASK(1, 0)
-
 #define AD5686_PD_MODE_1K_TO_GND		0x1
 #define AD5686_PD_MODE_100K_TO_GND		0x2
 #define AD5686_PD_MODE_THREE_STATE		0x3
diff --git a/drivers/iio/dac/ad5696-i2c.c b/drivers/iio/dac/ad5696-i2c.c
index 6f726e6301a6..73dcd2e6f51b 100644
--- a/drivers/iio/dac/ad5696-i2c.c
+++ b/drivers/iio/dac/ad5696-i2c.c
@@ -7,6 +7,7 @@
  * Copyright 2018 Analog Devices Inc.
  */
 
+#include <linux/bitfield.h>
 #include <linux/errno.h>
 #include <linux/i2c.h>
 #include <linux/mod_devicetable.h>
@@ -35,9 +36,8 @@ static int ad5686_i2c_read(struct ad5686_state *st, u8 addr)
 	};
 	int ret;
 
-	st->data[0].d32 = cpu_to_be32(AD5686_CMD(AD5686_CMD_NOOP) |
-				      AD5686_ADDR(addr) |
-				      0x00);
+	st->data[0].d32 = cpu_to_be32(FIELD_PREP(AD5686_CMD_MSK, AD5686_CMD_NOOP) |
+				      FIELD_PREP(AD5686_ADDR_MSK, addr));
 
 	ret = i2c_transfer(i2c->adapter, msg, 2);
 	if (ret != 2)
@@ -52,8 +52,9 @@ static int ad5686_i2c_write(struct ad5686_state *st,
 	struct i2c_client *i2c = to_i2c_client(st->dev);
 	int ret;
 
-	st->data[0].d32 = cpu_to_be32(AD5686_CMD(cmd) | AD5686_ADDR(addr)
-				      | val);
+	st->data[0].d32 = cpu_to_be32(FIELD_PREP(AD5686_CMD_MSK, cmd) |
+				      FIELD_PREP(AD5686_ADDR_MSK, addr) |
+				      FIELD_PREP(AD5686_DATA_MSK, val));
 
 	ret = i2c_master_send(i2c, &st->data[0].d8[1], 3);
 	if (ret < 0)

-- 
2.43.0

