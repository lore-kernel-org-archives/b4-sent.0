From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Mon, 03 Jun 2024 19:23:04 +0300
Subject: [PATCH v5 6/9] iio: adc: ad7173: add support for special inputs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240603-ad4111-v5-6-9a9c54d9ac78@analog.com>
References: <20240603-ad4111-v5-0-9a9c54d9ac78@analog.com>
In-Reply-To: <20240603-ad4111-v5-0-9a9c54d9ac78@analog.com>
To: Ceclan Dumitru <dumitru.ceclan@analog.com>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dumitru Ceclan <mitrutzceclan@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717431792; l=4367;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=bRE3qYBUi2MhWS4l41aYscXn5nV81b7PK9EKPErwNCo=;
 b=c+Oy5u/dffBwokkQECvnCDqgXIdwP1MHbduxXCtjliOqj0561YUTnSD6iowUtUKEceBJda2ck
 uDl5VwygkIGB2IyEElMSH5pAa1BthqZiJ93mLcmhrQGDnmW5idb8W68
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

 Add support for selecting REF+ and REF- inputs on all models.
 Add support for selecting ((AVDD1 − AVSS)/5) inputs
  on supported models.

Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 drivers/iio/adc/ad7173.c | 28 ++++++++++++++++++++++++++--
 1 file changed, 26 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/adc/ad7173.c b/drivers/iio/adc/ad7173.c
index 4040edbd1c32..4cff3eda5a6b 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -66,6 +66,15 @@
 	 FIELD_PREP(AD7173_CH_SETUP_AINNEG_MASK, neg))
 #define AD7173_AIN_TEMP_POS	17
 #define AD7173_AIN_TEMP_NEG	18
+#define AD7173_AIN_COM_IN_POS	19
+#define AD7173_AIN_COM_IN_NEG	20
+#define AD7173_AIN_REF_POS	21
+#define AD7173_AIN_REF_NEG	22
+
+#define AD7173_IS_REF_INPUT(x)		((x) == AD7173_AIN_REF_POS || \
+					(x) == AD7173_AIN_REF_NEG)
+#define AD7173_IS_COM_INPUT(x)		((x) == AD7173_AIN_COM_IN_POS || \
+					(x) == AD7173_AIN_COM_IN_NEG)
 
 #define AD7172_2_ID			0x00d0
 #define AD7175_ID			0x0cd0
@@ -146,6 +155,8 @@ struct ad7173_device_info {
 	unsigned int id;
 	char *name;
 	bool has_temp;
+	/* ((AVDD1 − AVSS)/5) */
+	bool has_common_input;
 	bool has_input_buf;
 	bool has_int_ref;
 	bool has_ref2;
@@ -216,6 +227,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_temp = true,
 		.has_input_buf = true,
 		.has_int_ref = true,
+		.has_common_input = true,
 		.clock = 2 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7173_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7173_sinc5_data_rates),
@@ -230,6 +242,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_temp = false,
 		.has_input_buf = true,
 		.has_ref2 = true,
+		.has_common_input = true,
 		.clock = 2 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7173_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7173_sinc5_data_rates),
@@ -245,6 +258,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_input_buf = true,
 		.has_int_ref = true,
 		.has_ref2 = true,
+		.has_common_input = false,
 		.clock = 2 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7173_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7173_sinc5_data_rates),
@@ -259,6 +273,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_temp = true,
 		.has_input_buf = true,
 		.has_int_ref = true,
+		.has_common_input = true,
 		.clock = 16 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7175_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
@@ -274,6 +289,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_input_buf = true,
 		.has_int_ref = true,
 		.has_ref2 = true,
+		.has_common_input = true,
 		.clock = 16 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7175_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
@@ -288,6 +304,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_temp = false,
 		.has_input_buf = false,
 		.has_int_ref = true,
+		.has_common_input = false,
 		.clock = 16 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7175_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
@@ -302,6 +319,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_temp = true,
 		.has_input_buf = true,
 		.has_int_ref = true,
+		.has_common_input = true,
 		.clock = 16 * HZ_PER_MHZ,
 		.odr_start_value = AD7177_ODR_START_VALUE,
 		.sinc5_data_rates = ad7175_sinc5_data_rates,
@@ -914,9 +932,15 @@ static int ad7173_validate_voltage_ain_inputs(struct ad7173_state *st,
 					      unsigned int ain0, unsigned int ain1)
 {
 	struct device *dev = &st->sd.spi->dev;
+	bool special_input0, special_input1;
+
+	special_input0 = AD7173_IS_REF_INPUT(ain0) ||
+			(AD7173_IS_COM_INPUT(ain0) && st->info->has_common_input);
+	special_input1 = AD7173_IS_REF_INPUT(ain1) ||
+			(AD7173_IS_COM_INPUT(ain1) && st->info->has_common_input);
 
-	if (ain0 >= st->info->num_inputs ||
-	    ain1 >= st->info->num_inputs)
+	if ((ain0 >= st->info->num_inputs && !special_input0) ||
+	    (ain1 >= st->info->num_inputs && !special_input1))
 		return dev_err_probe(dev, -EINVAL,
 				     "Input pin number out of range for pair (%d %d).\n",
 				     ain0, ain1);

-- 
2.43.0

