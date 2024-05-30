From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Thu, 30 May 2024 15:07:49 +0300
Subject: [PATCH v3 1/5] iio: adc: ad7173: fix buffers enablement for
 ad7176-2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240530-ad7173-fixes-v3-1-b85f33079e18@analog.com>
References: <20240530-ad7173-fixes-v3-0-b85f33079e18@analog.com>
In-Reply-To: <20240530-ad7173-fixes-v3-0-b85f33079e18@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Jonathan Cameron <jic23@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dumitru Ceclan <mitrutzceclan@gmail.com>, 
 Dumitru Ceclan <dumitru.ceclan@analog.com>, 
 David Lechner <dlechner@baylibre.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717070881; l=3513;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=YO3jbx93xkkdS8bNTk3Nk05937RhLKSs/ejH6uQRBSk=;
 b=FzPa9r6lTyIFZ21C+bTDhgDWHb91iNZNgNcsGvI+KkD5AASV7LNSSsGHniKZ7gp8YoW52L+8f
 b+yPnN1Ll5DCmHliqqMXKYH9t4yh0xBEDtYfU4BlqRk6KRxFRqdZNuy
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

AD7176-2 does not feature input buffers and marks corespondent register
bits as read only. Enable buffers only on supported models.

Fixes: 8eb903272f75 ("iio: adc: ad7173: add AD7173 driver")
Reviewed-by: David Lechner <dlechner@baylibre.com>
Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 drivers/iio/adc/ad7173.c | 12 ++++++++++--
 1 file changed, 10 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/adc/ad7173.c b/drivers/iio/adc/ad7173.c
index f6d29abe1d04..850574437bda 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -145,6 +145,7 @@ struct ad7173_device_info {
 	unsigned int id;
 	char *name;
 	bool has_temp;
+	bool has_input_buf;
 	bool has_int_ref;
 	bool has_ref2;
 	u8 num_gpios;
@@ -212,6 +213,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.num_configs = 4,
 		.num_gpios = 2,
 		.has_temp = true,
+		.has_input_buf = true,
 		.has_int_ref = true,
 		.clock = 2 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7173_sinc5_data_rates,
@@ -224,6 +226,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.num_configs = 8,
 		.num_gpios = 4,
 		.has_temp = false,
+		.has_input_buf = true,
 		.has_ref2 = true,
 		.clock = 2 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7173_sinc5_data_rates,
@@ -237,6 +240,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.num_configs = 8,
 		.num_gpios = 4,
 		.has_temp = true,
+		.has_input_buf = true,
 		.has_int_ref = true,
 		.has_ref2 = true,
 		.clock = 2 * HZ_PER_MHZ,
@@ -251,6 +255,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.num_configs = 4,
 		.num_gpios = 2,
 		.has_temp = true,
+		.has_input_buf = true,
 		.has_int_ref = true,
 		.clock = 16 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7175_sinc5_data_rates,
@@ -263,6 +268,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.num_configs = 8,
 		.num_gpios = 4,
 		.has_temp = true,
+		.has_input_buf = true,
 		.has_int_ref = true,
 		.has_ref2 = true,
 		.clock = 16 * HZ_PER_MHZ,
@@ -277,6 +283,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.num_configs = 4,
 		.num_gpios = 2,
 		.has_temp = false,
+		.has_input_buf = false,
 		.has_int_ref = true,
 		.clock = 16 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7175_sinc5_data_rates,
@@ -289,6 +296,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.num_configs = 4,
 		.num_gpios = 2,
 		.has_temp = true,
+		.has_input_buf = true,
 		.has_int_ref = true,
 		.clock = 16 * HZ_PER_MHZ,
 		.odr_start_value = AD7177_ODR_START_VALUE,
@@ -932,7 +940,7 @@ static int ad7173_fw_parse_channel_config(struct iio_dev *indio_dev)
 			AD7173_CH_ADDRESS(chan_arr[chan_index].channel,
 					  chan_arr[chan_index].channel2);
 		chan_st_priv->cfg.bipolar = false;
-		chan_st_priv->cfg.input_buf = true;
+		chan_st_priv->cfg.input_buf = st->info->has_input_buf;
 		chan_st_priv->cfg.ref_sel = AD7173_SETUP_REF_SEL_INT_REF;
 		st->adc_mode |= AD7173_ADC_MODE_REF_EN;
 
@@ -989,7 +997,7 @@ static int ad7173_fw_parse_channel_config(struct iio_dev *indio_dev)
 
 		chan_st_priv->ain = AD7173_CH_ADDRESS(ain[0], ain[1]);
 		chan_st_priv->chan_reg = chan_index;
-		chan_st_priv->cfg.input_buf = true;
+		chan_st_priv->cfg.input_buf = st->info->has_input_buf;
 		chan_st_priv->cfg.odr = 0;
 
 		chan_st_priv->cfg.bipolar = fwnode_property_read_bool(child, "bipolar");

-- 
2.43.0

