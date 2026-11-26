From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: jic23@kernel.org, dlechner@baylibre.com, nuno.sa@analog.com, 
 andy@kernel.org
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 linux-iio@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH 1/3] iio: adc: mt6359: divide scale by ADC resolution
Date: Thu, 26 Nov 2026 00:53:27 +0000
Message-Id: <20261126005326.71926-2-iasnezhkov@gmail.com>
In-Reply-To: <20261126005326.71926-1-iasnezhkov@gmail.com>
References: <20261126005326.71926-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795654406; l=1939;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=7vl4u01SgEwCwc9gl97LuugAuG8wvcClmhuIXz5B3VY=;
 b=M8ELTrNymnSSBWnP8gL6gLxOjdl2/HKVLecz/v7T5ncHp45P7pIx1mRuN2Oe8O5ic9rZfd5TL
 0UqwEjBwP4nCH1dmLbKyCuBz49O1aoUzCyYUkdxvixwGZbEItLupanh
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mt6359_auxadc_read_raw() returns raw ADC counts for IIO_CHAN_INFO_RAW
(12-bit or 15-bit depending on the channel), and returns only
(r_ratio.numerator * vref_mV) / r_ratio.denominator for
IIO_CHAN_INFO_SCALE without dividing by the ADC full-scale range
(1 << chan->scan_type.realbits).

As a result, iio_read_channel_processed() and userspace consumers
multiplying raw * scale obtain millivolt values that are 4096x (12-bit)
or 32768x (15-bit) too large.

Include the 1 << chan->scan_type.realbits divisor in
IIO_CHAN_INFO_SCALE: shift r_ratio.denominator left by realbits for
IIO_VAL_FRACTIONAL when denominator > 1 (r_ratio.denominator is u8 and
realbits is at most 15, so the result fits comfortably in int), and
return IIO_VAL_FRACTIONAL_LOG2 with realbits otherwise so channels with
denominator == 1 use an exact shift and unpopulated descriptors (such
as MT6357 VDCXO where denominator == 0) cannot trigger division by zero.

Found and drafted with an AI coding assistant.

Fixes: 3587914bf61d ("iio: adc: Add support for MediaTek MT6357/8/9 Auxiliary ADC")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 drivers/iio/adc/mt6359-auxadc.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/adc/mt6359-auxadc.c b/drivers/iio/adc/mt6359-auxadc.c
index 88b0e26..54c9048 100644
--- a/drivers/iio/adc/mt6359-auxadc.c
+++ b/drivers/iio/adc/mt6359-auxadc.c
@@ -772,11 +772,12 @@ static int mt6359_auxadc_read_raw(struct iio_dev *indio_dev,
 		*val = desc->r_ratio.numerator * cinfo->vref_mV;
 
 		if (desc->r_ratio.denominator > 1) {
-			*val2 = desc->r_ratio.denominator;
+			*val2 = (int)desc->r_ratio.denominator << chan->scan_type.realbits;
 			return IIO_VAL_FRACTIONAL;
 		}
 
-		return IIO_VAL_INT;
+		*val2 = chan->scan_type.realbits;
+		return IIO_VAL_FRACTIONAL_LOG2;
 	}
 
 	scoped_guard(mutex, &adc_dev->lock) {
-- 
2.54.0 (Apple Git-157)


