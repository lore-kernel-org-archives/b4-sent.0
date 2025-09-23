From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 23 Sep 2025 09:41:48 +0100
Subject: [PATCH 2/2] iio: dac: ltc2688: use the auto lock API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250923-dev-ltc2688-minor-v1-2-ef92c441dc42@analog.com>
References: <20250923-dev-ltc2688-minor-v1-0-ef92c441dc42@analog.com>
In-Reply-To: <20250923-dev-ltc2688-minor-v1-0-ef92c441dc42@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758616915; l=2667;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=6yZ3xMxARLZBD4UHPpqf5e19eNf49oSofH3MuyGQxbU=;
 b=SScT76jCCJfUextKNuxpmW3OwlMcUylhHKjDk0DTIqmXlfZsdhec91xEB32ETQHOjt5oxxaf3
 CyKhVEdy0BUBpY7bV/A4hA1Qq3JKavzzHJqJ6lFixyWXm8g8N5JmYwz
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make use of the cleanup API so that we can simplify some code paths.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/dac/ltc2688.c | 24 ++++++++++--------------
 1 file changed, 10 insertions(+), 14 deletions(-)

diff --git a/drivers/iio/dac/ltc2688.c b/drivers/iio/dac/ltc2688.c
index 57028d422868ec48e6900ef1cc4be6dee9cd4547..628e96e20375c06bffe16878fc90cfdde99ae565 100644
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
@@ -236,15 +234,15 @@ static int ltc2688_dac_code_read(struct ltc2688_state *st, u32 chan, u32 input,
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
@@ -359,15 +357,13 @@ static ssize_t ltc2688_dither_toggle_set(struct iio_dev *indio_dev,
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
 
 	return ret ?: len;
 }

-- 
2.51.0

