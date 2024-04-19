From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 19 Apr 2024 17:36:50 +0200
Subject: [PATCH 7/8] iio: adc: ad9467: cache the sample rate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240419-ad9467-new-features-v1-7-3e7628ff6d5e@analog.com>
References: <20240419-ad9467-new-features-v1-0-3e7628ff6d5e@analog.com>
In-Reply-To: <20240419-ad9467-new-features-v1-0-3e7628ff6d5e@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713541010; l=1935;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=AVSjsumjo5TvKypskYPgN6fw3oHyN2j1uJ4FVRsJVt0=;
 b=M4HAt4TIvHefbkd2brW+3zFwv2Kv4zsyeem0qB7NE9I8pHZpgGeL+OOsjoUSvjFppixAuGByn
 qO9kYTydOw3DcqbxGs+JYFXrNh44kRoNQYC16xDcrQbD6IiiAVOtKnr
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since we allow to change the sampling frequency and do it with
clk_round_rate(), we can cache it and use on the read_raw() interface.
This will also be useful in a following patch supporting interface
calibration.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ad9467.c | 13 +++++++++++--
 1 file changed, 11 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/adc/ad9467.c b/drivers/iio/adc/ad9467.c
index 7475ec2a56c72..7db87ccc1ea4b 100644
--- a/drivers/iio/adc/ad9467.c
+++ b/drivers/iio/adc/ad9467.c
@@ -117,6 +117,7 @@ struct ad9467_state {
 	struct iio_backend		*back;
 	struct spi_device		*spi;
 	struct clk			*clk;
+	unsigned long			sample_rate;
 	unsigned int			output_mode;
 	unsigned int                    (*scales)[2];
 
@@ -331,7 +332,7 @@ static int ad9467_read_raw(struct iio_dev *indio_dev,
 	case IIO_CHAN_INFO_SCALE:
 		return ad9467_get_scale(st, val, val2);
 	case IIO_CHAN_INFO_SAMP_FREQ:
-		*val = clk_get_rate(st->clk);
+		*val = st->sample_rate;
 
 		return IIO_VAL_INT;
 	default:
@@ -346,6 +347,7 @@ static int ad9467_write_raw(struct iio_dev *indio_dev,
 	struct ad9467_state *st = iio_priv(indio_dev);
 	const struct ad9467_chip_info *info = st->info;
 	long r_clk;
+	int ret;
 
 	switch (mask) {
 	case IIO_CHAN_INFO_SCALE:
@@ -358,7 +360,12 @@ static int ad9467_write_raw(struct iio_dev *indio_dev,
 			return -EINVAL;
 		}
 
-		return clk_set_rate(st->clk, r_clk);
+		ret = clk_set_rate(st->clk, r_clk);
+		if (ret)
+			return ret;
+
+		st->sample_rate = r_clk;
+		return 0;
 	default:
 		return -EINVAL;
 	}
@@ -543,6 +550,8 @@ static int ad9467_probe(struct spi_device *spi)
 	if (IS_ERR(st->clk))
 		return PTR_ERR(st->clk);
 
+	st->sample_rate = clk_get_rate(st->clk);
+
 	st->pwrdown_gpio = devm_gpiod_get_optional(&spi->dev, "powerdown",
 						   GPIOD_OUT_LOW);
 	if (IS_ERR(st->pwrdown_gpio))

-- 
2.44.0

