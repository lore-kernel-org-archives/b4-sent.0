From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Thu, 06 Jun 2024 19:07:45 +0300
Subject: [PATCH v6 6/9] iio: adc: ad7173: add support for special inputs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240606-ad4111-v6-6-573981fb3e2e@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717690059; l=4388;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=hVN7Wx0S4d3TmvMG178sCl53E62M7EsA/DtotGwBQqo=;
 b=LAua7k1WT20Gd1RAfZJ+1SPPfBdUeQz0SPDLW4Y3AuIZQUHMBnp98XiaQFNBeK/hXc/bHv1vN
 RLSSia25SARD6QPVBzlY0aehybhuFvkeKvW7AhpRKC8tSPOS+JXK0Dp
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

 Add support for selecting REF+ and REF- inputs on all models.
 Add support for selecting ((AVDD1 − AVSS)/5) inputs
  on supported models.

Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 drivers/iio/adc/ad7173.c | 29 +++++++++++++++++++++++++++--
 1 file changed, 27 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/adc/ad7173.c b/drivers/iio/adc/ad7173.c
index 4040edbd1c32..d16fa081a285 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -66,6 +66,13 @@
 	 FIELD_PREP(AD7173_CH_SETUP_AINNEG_MASK, neg))
 #define AD7173_AIN_TEMP_POS	17
 #define AD7173_AIN_TEMP_NEG	18
+#define AD7173_AIN_POW_MON_POS	19
+#define AD7173_AIN_POW_MON_NEG	20
+#define AD7173_AIN_REF_POS	21
+#define AD7173_AIN_REF_NEG	22
+
+#define AD7173_IS_REF_INPUT(x)		((x) == AD7173_AIN_REF_POS || \
+					(x) == AD7173_AIN_REF_NEG)
 
 #define AD7172_2_ID			0x00d0
 #define AD7175_ID			0x0cd0
@@ -146,6 +153,8 @@ struct ad7173_device_info {
 	unsigned int id;
 	char *name;
 	bool has_temp;
+	/* ((AVDD1 − AVSS)/5) */
+	bool has_pow_supply_monitoring;
 	bool has_input_buf;
 	bool has_int_ref;
 	bool has_ref2;
@@ -216,6 +225,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_temp = true,
 		.has_input_buf = true,
 		.has_int_ref = true,
+		.has_pow_supply_monitoring = true,
 		.clock = 2 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7173_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7173_sinc5_data_rates),
@@ -230,6 +240,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_temp = false,
 		.has_input_buf = true,
 		.has_ref2 = true,
+		.has_pow_supply_monitoring = true,
 		.clock = 2 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7173_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7173_sinc5_data_rates),
@@ -245,6 +256,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_input_buf = true,
 		.has_int_ref = true,
 		.has_ref2 = true,
+		.has_pow_supply_monitoring = false,
 		.clock = 2 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7173_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7173_sinc5_data_rates),
@@ -259,6 +271,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_temp = true,
 		.has_input_buf = true,
 		.has_int_ref = true,
+		.has_pow_supply_monitoring = true,
 		.clock = 16 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7175_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
@@ -274,6 +287,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_input_buf = true,
 		.has_int_ref = true,
 		.has_ref2 = true,
+		.has_pow_supply_monitoring = true,
 		.clock = 16 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7175_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
@@ -288,6 +302,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_temp = false,
 		.has_input_buf = false,
 		.has_int_ref = true,
+		.has_pow_supply_monitoring = false,
 		.clock = 16 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7175_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
@@ -302,6 +317,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_temp = true,
 		.has_input_buf = true,
 		.has_int_ref = true,
+		.has_pow_supply_monitoring = true,
 		.clock = 16 * HZ_PER_MHZ,
 		.odr_start_value = AD7177_ODR_START_VALUE,
 		.sinc5_data_rates = ad7175_sinc5_data_rates,
@@ -914,9 +930,18 @@ static int ad7173_validate_voltage_ain_inputs(struct ad7173_state *st,
 					      unsigned int ain0, unsigned int ain1)
 {
 	struct device *dev = &st->sd.spi->dev;
+	bool special_input0, special_input1;
+
+	/* (AVDD1-AVSS)/5 power supply monitoring */
+	if (ain0 == AD7173_AIN_POW_MON_POS && ain1 == AD7173_AIN_POW_MON_NEG &&
+	    st->info->has_pow_supply_monitoring)
+		return 0;
+
+	special_input0 = AD7173_IS_REF_INPUT(ain0);
+	special_input1 = AD7173_IS_REF_INPUT(ain1);
 
-	if (ain0 >= st->info->num_inputs ||
-	    ain1 >= st->info->num_inputs)
+	if ((ain0 >= st->info->num_inputs && !special_input0) ||
+	    (ain1 >= st->info->num_inputs && !special_input1))
 		return dev_err_probe(dev, -EINVAL,
 				     "Input pin number out of range for pair (%d %d).\n",
 				     ain0, ain1);

-- 
2.43.0

