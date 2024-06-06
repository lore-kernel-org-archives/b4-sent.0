From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Thu, 06 Jun 2024 19:07:46 +0300
Subject: [PATCH v6 7/9] iio: adc: ad7173: refactor device info structs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240606-ad4111-v6-7-573981fb3e2e@analog.com>
References: <20240606-ad4111-v6-0-573981fb3e2e@analog.com>
In-Reply-To: <20240606-ad4111-v6-0-573981fb3e2e@analog.com>
To: Ceclan Dumitru <dumitru.ceclan@analog.com>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dumitru Ceclan <mitrutzceclan@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717690059; l=9649;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=tbKPX7mm3uILpoFW41vG4pl0sCWKf8ZeV8ZWdWAi7yw=;
 b=U+5mUk0R2rkSI4l5fJGhxgZ6+Y3Dh5HHuC4MyrgmliFCJq5/YNfLkVsoKFM4vJpKf8HRz1Ue8
 OEovQvWQQ/qAUuHr3Z2gLr0ydeni5QBv3+Z771oCron/a+M5kfm3IfE
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drop array of device info structs and use individual structs for all;
drop models enum as no longer needed. This improves readability as the
structs are pointed directly.

Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 drivers/iio/adc/ad7173.c | 267 ++++++++++++++++++++++-------------------------
 1 file changed, 127 insertions(+), 140 deletions(-)

diff --git a/drivers/iio/adc/ad7173.c b/drivers/iio/adc/ad7173.c
index d16fa081a285..8d008186cd6e 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -132,16 +132,6 @@
 #define AD7173_FILTER_ODR0_MASK		GENMASK(5, 0)
 #define AD7173_MAX_CONFIGS		8
 
-enum ad7173_ids {
-	ID_AD7172_2,
-	ID_AD7172_4,
-	ID_AD7173_8,
-	ID_AD7175_2,
-	ID_AD7175_8,
-	ID_AD7176_2,
-	ID_AD7177_2,
-};
-
 struct ad7173_device_info {
 	const unsigned int *sinc5_data_rates;
 	unsigned int num_sinc5_data_rates;
@@ -214,115 +204,119 @@ static const unsigned int ad7175_sinc5_data_rates[] = {
 	5000,					/* 20    */
 };
 
-static const struct ad7173_device_info ad7173_device_info[] = {
-	[ID_AD7172_2] = {
-		.name = "ad7172-2",
-		.id = AD7172_2_ID,
-		.num_inputs = 5,
-		.num_channels = 4,
-		.num_configs = 4,
-		.num_gpios = 2,
-		.has_temp = true,
-		.has_input_buf = true,
-		.has_int_ref = true,
-		.has_pow_supply_monitoring = true,
-		.clock = 2 * HZ_PER_MHZ,
-		.sinc5_data_rates = ad7173_sinc5_data_rates,
-		.num_sinc5_data_rates = ARRAY_SIZE(ad7173_sinc5_data_rates),
-	},
-	[ID_AD7172_4] = {
-		.name = "ad7172-4",
-		.id = AD7172_4_ID,
-		.num_inputs = 9,
-		.num_channels = 8,
-		.num_configs = 8,
-		.num_gpios = 4,
-		.has_temp = false,
-		.has_input_buf = true,
-		.has_ref2 = true,
-		.has_pow_supply_monitoring = true,
-		.clock = 2 * HZ_PER_MHZ,
-		.sinc5_data_rates = ad7173_sinc5_data_rates,
-		.num_sinc5_data_rates = ARRAY_SIZE(ad7173_sinc5_data_rates),
-	},
-	[ID_AD7173_8] = {
-		.name = "ad7173-8",
-		.id = AD7173_ID,
-		.num_inputs = 17,
-		.num_channels = 16,
-		.num_configs = 8,
-		.num_gpios = 4,
-		.has_temp = true,
-		.has_input_buf = true,
-		.has_int_ref = true,
-		.has_ref2 = true,
-		.has_pow_supply_monitoring = false,
-		.clock = 2 * HZ_PER_MHZ,
-		.sinc5_data_rates = ad7173_sinc5_data_rates,
-		.num_sinc5_data_rates = ARRAY_SIZE(ad7173_sinc5_data_rates),
-	},
-	[ID_AD7175_2] = {
-		.name = "ad7175-2",
-		.id = AD7175_2_ID,
-		.num_inputs = 5,
-		.num_channels = 4,
-		.num_configs = 4,
-		.num_gpios = 2,
-		.has_temp = true,
-		.has_input_buf = true,
-		.has_int_ref = true,
-		.has_pow_supply_monitoring = true,
-		.clock = 16 * HZ_PER_MHZ,
-		.sinc5_data_rates = ad7175_sinc5_data_rates,
-		.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
-	},
-	[ID_AD7175_8] = {
-		.name = "ad7175-8",
-		.id = AD7175_8_ID,
-		.num_inputs = 17,
-		.num_channels = 16,
-		.num_configs = 8,
-		.num_gpios = 4,
-		.has_temp = true,
-		.has_input_buf = true,
-		.has_int_ref = true,
-		.has_ref2 = true,
-		.has_pow_supply_monitoring = true,
-		.clock = 16 * HZ_PER_MHZ,
-		.sinc5_data_rates = ad7175_sinc5_data_rates,
-		.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
-	},
-	[ID_AD7176_2] = {
-		.name = "ad7176-2",
-		.id = AD7176_ID,
-		.num_inputs = 5,
-		.num_channels = 4,
-		.num_configs = 4,
-		.num_gpios = 2,
-		.has_temp = false,
-		.has_input_buf = false,
-		.has_int_ref = true,
-		.has_pow_supply_monitoring = false,
-		.clock = 16 * HZ_PER_MHZ,
-		.sinc5_data_rates = ad7175_sinc5_data_rates,
-		.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
-	},
-	[ID_AD7177_2] = {
-		.name = "ad7177-2",
-		.id = AD7177_ID,
-		.num_inputs = 5,
-		.num_channels = 4,
-		.num_configs = 4,
-		.num_gpios = 2,
-		.has_temp = true,
-		.has_input_buf = true,
-		.has_int_ref = true,
-		.has_pow_supply_monitoring = true,
-		.clock = 16 * HZ_PER_MHZ,
-		.odr_start_value = AD7177_ODR_START_VALUE,
-		.sinc5_data_rates = ad7175_sinc5_data_rates,
-		.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
-	},
+static const struct ad7173_device_info ad7172_2_device_info = {
+	.name = "ad7172-2",
+	.id = AD7172_2_ID,
+	.num_inputs = 5,
+	.num_channels = 4,
+	.num_configs = 4,
+	.num_gpios = 2,
+	.has_temp = true,
+	.has_input_buf = true,
+	.has_int_ref = true,
+	.has_pow_supply_monitoring = true,
+	.clock = 2 * HZ_PER_MHZ,
+	.sinc5_data_rates = ad7173_sinc5_data_rates,
+	.num_sinc5_data_rates = ARRAY_SIZE(ad7173_sinc5_data_rates),
+};
+
+static const struct ad7173_device_info ad7172_4_device_info = {
+	.name = "ad7172-4",
+	.id = AD7172_4_ID,
+	.num_inputs = 9,
+	.num_channels = 8,
+	.num_configs = 8,
+	.num_gpios = 4,
+	.has_temp = false,
+	.has_input_buf = true,
+	.has_ref2 = true,
+	.has_pow_supply_monitoring = true,
+	.clock = 2 * HZ_PER_MHZ,
+	.sinc5_data_rates = ad7173_sinc5_data_rates,
+	.num_sinc5_data_rates = ARRAY_SIZE(ad7173_sinc5_data_rates),
+};
+
+static const struct ad7173_device_info ad7173_8_device_info = {
+	.name = "ad7173-8",
+	.id = AD7173_ID,
+	.num_inputs = 17,
+	.num_channels = 16,
+	.num_configs = 8,
+	.num_gpios = 4,
+	.has_temp = true,
+	.has_input_buf = true,
+	.has_int_ref = true,
+	.has_ref2 = true,
+	.has_pow_supply_monitoring = false,
+	.clock = 2 * HZ_PER_MHZ,
+	.sinc5_data_rates = ad7173_sinc5_data_rates,
+	.num_sinc5_data_rates = ARRAY_SIZE(ad7173_sinc5_data_rates),
+};
+
+static const struct ad7173_device_info ad7175_2_device_info = {
+	.name = "ad7175-2",
+	.id = AD7175_2_ID,
+	.num_inputs = 5,
+	.num_channels = 4,
+	.num_configs = 4,
+	.num_gpios = 2,
+	.has_temp = true,
+	.has_input_buf = true,
+	.has_int_ref = true,
+	.has_pow_supply_monitoring = true,
+	.clock = 16 * HZ_PER_MHZ,
+	.sinc5_data_rates = ad7175_sinc5_data_rates,
+	.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
+};
+
+static const struct ad7173_device_info ad7175_8_device_info = {
+	.name = "ad7175-8",
+	.id = AD7175_8_ID,
+	.num_inputs = 17,
+	.num_channels = 16,
+	.num_configs = 8,
+	.num_gpios = 4,
+	.has_temp = true,
+	.has_input_buf = true,
+	.has_int_ref = true,
+	.has_ref2 = true,
+	.has_pow_supply_monitoring = true,
+	.clock = 16 * HZ_PER_MHZ,
+	.sinc5_data_rates = ad7175_sinc5_data_rates,
+	.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
+};
+
+static const struct ad7173_device_info ad7176_2_device_info = {
+	.name = "ad7176-2",
+	.id = AD7176_ID,
+	.num_inputs = 5,
+	.num_channels = 4,
+	.num_configs = 4,
+	.num_gpios = 2,
+	.has_temp = false,
+	.has_input_buf = false,
+	.has_int_ref = true,
+	.has_pow_supply_monitoring = false,
+	.clock = 16 * HZ_PER_MHZ,
+	.sinc5_data_rates = ad7175_sinc5_data_rates,
+	.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
+};
+
+static const struct ad7173_device_info ad7177_2_device_info = {
+	.name = "ad7177-2",
+	.id = AD7177_ID,
+	.num_inputs = 5,
+	.num_channels = 4,
+	.num_configs = 4,
+	.num_gpios = 2,
+	.has_temp = true,
+	.has_input_buf = true,
+	.has_int_ref = true,
+	.has_pow_supply_monitoring = true,
+	.clock = 16 * HZ_PER_MHZ,
+	.odr_start_value = AD7177_ODR_START_VALUE,
+	.sinc5_data_rates = ad7175_sinc5_data_rates,
+	.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
 };
 
 static const char *const ad7173_ref_sel_str[] = {
@@ -1192,32 +1186,25 @@ static int ad7173_probe(struct spi_device *spi)
 }
 
 static const struct of_device_id ad7173_of_match[] = {
-	{ .compatible = "adi,ad7172-2",
-	  .data = &ad7173_device_info[ID_AD7172_2]},
-	{ .compatible = "adi,ad7172-4",
-	  .data = &ad7173_device_info[ID_AD7172_4]},
-	{ .compatible = "adi,ad7173-8",
-	  .data = &ad7173_device_info[ID_AD7173_8]},
-	{ .compatible = "adi,ad7175-2",
-	  .data = &ad7173_device_info[ID_AD7175_2]},
-	{ .compatible = "adi,ad7175-8",
-	  .data = &ad7173_device_info[ID_AD7175_8]},
-	{ .compatible = "adi,ad7176-2",
-	  .data = &ad7173_device_info[ID_AD7176_2]},
-	{ .compatible = "adi,ad7177-2",
-	  .data = &ad7173_device_info[ID_AD7177_2]},
+	{ .compatible = "adi,ad7172-2", .data = &ad7172_2_device_info },
+	{ .compatible = "adi,ad7172-4", .data = &ad7172_4_device_info },
+	{ .compatible = "adi,ad7173-8", .data = &ad7173_8_device_info },
+	{ .compatible = "adi,ad7175-2", .data = &ad7175_2_device_info },
+	{ .compatible = "adi,ad7175-8", .data = &ad7175_8_device_info },
+	{ .compatible = "adi,ad7176-2", .data = &ad7176_2_device_info },
+	{ .compatible = "adi,ad7177-2", .data = &ad7177_2_device_info },
 	{ }
 };
 MODULE_DEVICE_TABLE(of, ad7173_of_match);
 
 static const struct spi_device_id ad7173_id_table[] = {
-	{ "ad7172-2", (kernel_ulong_t)&ad7173_device_info[ID_AD7172_2]},
-	{ "ad7172-4", (kernel_ulong_t)&ad7173_device_info[ID_AD7172_4]},
-	{ "ad7173-8", (kernel_ulong_t)&ad7173_device_info[ID_AD7173_8]},
-	{ "ad7175-2", (kernel_ulong_t)&ad7173_device_info[ID_AD7175_2]},
-	{ "ad7175-8", (kernel_ulong_t)&ad7173_device_info[ID_AD7175_8]},
-	{ "ad7176-2", (kernel_ulong_t)&ad7173_device_info[ID_AD7176_2]},
-	{ "ad7177-2", (kernel_ulong_t)&ad7173_device_info[ID_AD7177_2]},
+	{ "ad7172-2", (kernel_ulong_t)&ad7172_2_device_info },
+	{ "ad7172-4", (kernel_ulong_t)&ad7172_4_device_info },
+	{ "ad7173-8", (kernel_ulong_t)&ad7173_8_device_info },
+	{ "ad7175-2", (kernel_ulong_t)&ad7175_2_device_info },
+	{ "ad7175-8", (kernel_ulong_t)&ad7175_8_device_info },
+	{ "ad7176-2", (kernel_ulong_t)&ad7176_2_device_info },
+	{ "ad7177-2", (kernel_ulong_t)&ad7177_2_device_info },
 	{ }
 };
 MODULE_DEVICE_TABLE(spi, ad7173_id_table);

-- 
2.43.0

