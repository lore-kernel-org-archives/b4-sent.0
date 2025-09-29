From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Mon, 29 Sep 2025 14:35:32 +0100
Subject: [PATCH v2] iio: dac: ltc2688: use the auto lock API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250929-dev-ltc2688-minor-v2-1-47f9508ca4cc@analog.com>
X-B4-Tracking: v=1; b=H4sIACOL2mgC/x3MTQqAIBBA4avErBuQCUW7SrToZ6qBstCQQLp70
 vJbvJchchCO0FYZAieJcvoCqiuYtsGvjDIXAynSylGDMyfc74mMtXiIPwOqwVh22ozKWSjdFXi
 R5392/ft+t+3r9WMAAAA=
X-Change-ID: 20250923-dev-ltc2688-minor-0a68e956b098
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759152933; l=3254;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=+06WQn+0U+kCXC/irDjEh0uloonpQaNhwKn4KabVt4E=;
 b=j/eTxj2w7RDiFG9F6OjxD7eMgsunK6sn8eZ0oUNpEA4ujNUluTAJNnKSLe2xzRZ85nFKcZEr8
 Pfym8c0eSkPDTEtLqlA0Jqx/ZUkxedf0qbbQw6QRsdUgOPGU85u+WHT
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make use of the cleanup API so that we can simplify some code paths.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
Here it goes v2 with the remaining patch.

Link to v1:
 - https://lore.kernel.org/linux-iio/20250923-dev-ltc2688-minor-v1-0-ef92c441dc42@analog.com/T/#mccd0040948b14f05ad7411e170701129fd2bea90

Changes in v2:
 * Simplify to 'return 0' and 'return len' as suggested.
---
 drivers/iio/dac/ltc2688.c | 28 ++++++++++++----------------
 1 file changed, 12 insertions(+), 16 deletions(-)

diff --git a/drivers/iio/dac/ltc2688.c b/drivers/iio/dac/ltc2688.c
index 7a2ee26a7d68730fe90d9cc91ea764f05eb61791..ca0ec131abad0203823db2589bccd407fba3c83a 100644
--- a/drivers/iio/dac/ltc2688.c
+++ b/drivers/iio/dac/ltc2688.c
@@ -6,6 +6,7 @@
  */
 #include <linux/bitfield.h>
 #include <linux/bits.h>
+#include <linux/cleanup.h>
 #include <linux/clk.h>
 #include <linux/device.h>
 #include <linux/gpio/consumer.h>
@@ -208,12 +209,12 @@ static int ltc2688_dac_code_write(struct ltc2688_state *st, u32 chan, u32 input,
 		code = FIELD_PREP(LTC2688_DITHER_RAW_MASK, code);
 	}
 
-	mutex_lock(&st->lock);
+	guard(mutex)(&st->lock);
 	/* select the correct input register to read from */
 	ret = regmap_update_bits(st->regmap, LTC2688_CMD_A_B_SELECT, BIT(chan),
 				 input << chan);
 	if (ret)
-		goto out_unlock;
+		return ret;
 
 	/*
 	 * If in dither/toggle mode the dac should be updated by an
@@ -224,10 +225,7 @@ static int ltc2688_dac_code_write(struct ltc2688_state *st, u32 chan, u32 input,
 	else
 		reg = LTC2688_CMD_CH_CODE(chan);
 
-	ret = regmap_write(st->regmap, reg, code);
-out_unlock:
-	mutex_unlock(&st->lock);
-	return ret;
+	return regmap_write(st->regmap, reg, code);
 }
 
 static int ltc2688_dac_code_read(struct ltc2688_state *st, u32 chan, u32 input,
@@ -236,20 +234,20 @@ static int ltc2688_dac_code_read(struct ltc2688_state *st, u32 chan, u32 input,
 	struct ltc2688_chan *c = &st->channels[chan];
 	int ret;
 
-	mutex_lock(&st->lock);
+	guard(mutex)(&st->lock);
 	ret = regmap_update_bits(st->regmap, LTC2688_CMD_A_B_SELECT, BIT(chan),
 				 input << chan);
 	if (ret)
-		goto out_unlock;
+		return ret;
 
 	ret = regmap_read(st->regmap, LTC2688_CMD_CH_CODE(chan), code);
-out_unlock:
-	mutex_unlock(&st->lock);
+	if (ret)
+		return ret;
 
 	if (!c->toggle_chan && input == LTC2688_INPUT_B)
 		*code = FIELD_GET(LTC2688_DITHER_RAW_MASK, *code);
 
-	return ret;
+	return 0;
 }
 
 static const int ltc2688_raw_range[] = {0, 1, U16_MAX};
@@ -359,17 +357,15 @@ static ssize_t ltc2688_dither_toggle_set(struct iio_dev *indio_dev,
 	if (ret)
 		return ret;
 
-	mutex_lock(&st->lock);
+	guard(mutex)(&st->lock);
 	ret = regmap_update_bits(st->regmap, LTC2688_CMD_TOGGLE_DITHER_EN,
 				 BIT(chan->channel), en << chan->channel);
 	if (ret)
-		goto out_unlock;
+		return ret;
 
 	c->mode = en ? LTC2688_MODE_DITHER_TOGGLE : LTC2688_MODE_DEFAULT;
-out_unlock:
-	mutex_unlock(&st->lock);
 
-	return ret ?: len;
+	return len;
 }
 
 static ssize_t ltc2688_reg_bool_get(struct iio_dev *indio_dev,

---
base-commit: 411e8b72c181e4f49352c12ced0fd8426eb683aa
change-id: 20250923-dev-ltc2688-minor-0a68e956b098
--

Thanks!
- Nuno Sá

