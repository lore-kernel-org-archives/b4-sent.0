From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Thu, 30 May 2024 15:07:53 +0300
Subject: [PATCH v3 5/5] iio: adc: ad7173: Fix sampling frequency setting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240530-ad7173-fixes-v3-5-b85f33079e18@analog.com>
References: <20240530-ad7173-fixes-v3-0-b85f33079e18@analog.com>
In-Reply-To: <20240530-ad7173-fixes-v3-0-b85f33079e18@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Jonathan Cameron <jic23@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dumitru Ceclan <mitrutzceclan@gmail.com>, 
 Dumitru Ceclan <dumitru.ceclan@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717070881; l=2969;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=SBPCEDIHiCkBTrkchaltcj60L2/HmJ7NW2rt8H7uZxM=;
 b=1yI8EuMNC1kGPCv+tv4qpgt9g1y7ShB+N4rgprlmp+0NraSAwqk4cxA7tfpVxGYlbztHEub0w
 3gVkgAXonMJAdtMh4xcWYt0oz0VLNdOjvpi2DvO9z3NmxYa60LMCN+Z
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch fixes two issues regarding the sampling frequency setting:
-The attribute was set as per device, not per channel. As such, when
 setting the sampling frequency, the configuration was always done for
 the slot 0, and the correct configuration was applied on the next
 channel configuration call by the LRU mechanism.
-The LRU implementation does not take into account external settings of
 the slot registers. When setting the sampling frequency directly to a
 slot register in write_raw(), there is no guarantee that other channels
 were not also using that slot and now incorrectly retain their config
 as live.

Set the sampling frequency attribute as separate in the channel templates.
Do not set the sampling directly to the slot register in write_raw(),
just mark the config as not live and let the LRU mechanism handle it.
As the reg variable is no longer used, remove it.

Fixes: 8eb903272f75 ("iio: adc: ad7173: add AD7173 driver")
Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 drivers/iio/adc/ad7173.c | 20 +++++---------------
 1 file changed, 5 insertions(+), 15 deletions(-)

diff --git a/drivers/iio/adc/ad7173.c b/drivers/iio/adc/ad7173.c
index e66a137a76be..ebf248741b34 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -717,7 +717,7 @@ static int ad7173_write_raw(struct iio_dev *indio_dev,
 {
 	struct ad7173_state *st = iio_priv(indio_dev);
 	struct ad7173_channel_config *cfg;
-	unsigned int freq, i, reg;
+	unsigned int freq, i;
 	int ret;
 
 	ret = iio_device_claim_direct_mode(indio_dev);
@@ -733,16 +733,7 @@ static int ad7173_write_raw(struct iio_dev *indio_dev,
 
 		cfg = &st->channels[chan->address].cfg;
 		cfg->odr = i;
-
-		if (!cfg->live)
-			break;
-
-		ret = ad_sd_read_reg(&st->sd, AD7173_REG_FILTER(cfg->cfg_slot), 2, &reg);
-		if (ret)
-			break;
-		reg &= ~AD7173_FILTER_ODR0_MASK;
-		reg |= FIELD_PREP(AD7173_FILTER_ODR0_MASK, i);
-		ret = ad_sd_write_reg(&st->sd, AD7173_REG_FILTER(cfg->cfg_slot), 2, reg);
+		cfg->live = false;
 		break;
 
 	default:
@@ -804,8 +795,7 @@ static const struct iio_chan_spec ad7173_channel_template = {
 	.type = IIO_VOLTAGE,
 	.indexed = 1,
 	.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
-		BIT(IIO_CHAN_INFO_SCALE),
-	.info_mask_shared_by_all = BIT(IIO_CHAN_INFO_SAMP_FREQ),
+		BIT(IIO_CHAN_INFO_SCALE) | BIT(IIO_CHAN_INFO_SAMP_FREQ),
 	.scan_type = {
 		.sign = 'u',
 		.realbits = 24,
@@ -819,8 +809,8 @@ static const struct iio_chan_spec ad7173_temp_iio_channel_template = {
 	.channel = AD7173_AIN_TEMP_POS,
 	.channel2 = AD7173_AIN_TEMP_NEG,
 	.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
-		BIT(IIO_CHAN_INFO_SCALE) | BIT(IIO_CHAN_INFO_OFFSET),
-	.info_mask_shared_by_all = BIT(IIO_CHAN_INFO_SAMP_FREQ),
+		BIT(IIO_CHAN_INFO_SCALE) | BIT(IIO_CHAN_INFO_OFFSET) |
+		BIT(IIO_CHAN_INFO_SAMP_FREQ),
 	.scan_type = {
 		.sign = 'u',
 		.realbits = 24,

-- 
2.43.0

