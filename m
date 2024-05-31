From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Fri, 31 May 2024 22:42:30 +0300
Subject: [PATCH v4 4/6] iio: adc: ad7173: add support for special inputs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240531-ad4111-v4-4-64607301c057@analog.com>
References: <20240531-ad4111-v4-0-64607301c057@analog.com>
In-Reply-To: <20240531-ad4111-v4-0-64607301c057@analog.com>
To: Ceclan Dumitru <dumitru.ceclan@analog.com>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dumitru Ceclan <mitrutzceclan@gmail.com>, 
 Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717184569; l=3895;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=cB8o2kcrbEPNFNzCdWPShKZlvMUHAlRTNWGqJZsx23M=;
 b=1C5Nu3lQyjq+AULdmA9qCer108QWZ/p2cc+WRco1kxVyDtZc2kOVPqz1LELkzbu7DhXNB92Nv
 XFphNlajH7yAKq7ih96vrRdnywbKcNJhdoglIOpkoe6gjGmVO1rPSOl
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

 Add support for selecting REF+ and REF- inputs on all models.
 Add support for selecting ((AVDD1 − AVSS)/5) inputs
  on supported models.

Reviewed-by: Nuno Sa <nuno.sa@analog.com>
Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 drivers/iio/adc/ad7173.c | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/drivers/iio/adc/ad7173.c b/drivers/iio/adc/ad7173.c
index a20831d99aa5..ebfd2d5f9632 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -66,6 +66,10 @@
 	 FIELD_PREP(AD7173_CH_SETUP_AINNEG_MASK, neg))
 #define AD7173_AIN_TEMP_POS	17
 #define AD7173_AIN_TEMP_NEG	18
+#define AD7173_AIN_COM_IN_POS	19
+#define AD7173_AIN_COM_IN_NEG	20
+#define AD7173_AIN_REF_POS	21
+#define AD7173_AIN_REF_NEG	22
 
 #define AD7172_2_ID			0x00d0
 #define AD7175_ID			0x0cd0
@@ -146,6 +150,8 @@ struct ad7173_device_info {
 	unsigned int id;
 	char *name;
 	bool has_temp;
+	/* ((AVDD1 − AVSS)/5) */
+	bool has_common_input;
 	bool has_input_buf;
 	bool has_int_ref;
 	bool has_ref2;
@@ -216,6 +222,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_temp = true,
 		.has_input_buf = true,
 		.has_int_ref = true,
+		.has_common_input = true,
 		.clock = 2 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7173_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7173_sinc5_data_rates),
@@ -230,6 +237,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_temp = false,
 		.has_input_buf = true,
 		.has_ref2 = true,
+		.has_common_input = true,
 		.clock = 2 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7173_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7173_sinc5_data_rates),
@@ -245,6 +253,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_input_buf = true,
 		.has_int_ref = true,
 		.has_ref2 = true,
+		.has_common_input = false,
 		.clock = 2 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7173_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7173_sinc5_data_rates),
@@ -259,6 +268,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_temp = true,
 		.has_input_buf = true,
 		.has_int_ref = true,
+		.has_common_input = true,
 		.clock = 16 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7175_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
@@ -274,6 +284,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_input_buf = true,
 		.has_int_ref = true,
 		.has_ref2 = true,
+		.has_common_input = true,
 		.clock = 16 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7175_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
@@ -288,6 +299,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_temp = false,
 		.has_input_buf = false,
 		.has_int_ref = true,
+		.has_common_input = false,
 		.clock = 16 * HZ_PER_MHZ,
 		.sinc5_data_rates = ad7175_sinc5_data_rates,
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
@@ -302,6 +314,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.has_temp = true,
 		.has_input_buf = true,
 		.has_int_ref = true,
+		.has_common_input = true,
 		.clock = 16 * HZ_PER_MHZ,
 		.odr_start_value = AD7177_ODR_START_VALUE,
 		.sinc5_data_rates = ad7175_sinc5_data_rates,
@@ -918,6 +931,14 @@ static int ad7173_validate_voltage_ain_inputs(struct ad7173_state *st,
 		if (ain[i] < st->info->num_inputs)
 			continue;
 
+		if (ain[i] == AD7173_AIN_REF_POS || ain[i] == AD7173_AIN_REF_NEG)
+			continue;
+
+		if ((ain[i] == AD7173_AIN_COM_IN_POS ||
+		     ain[i] == AD7173_AIN_COM_IN_NEG) &&
+		    st->info->has_common_input)
+			continue;
+
 		return dev_err_probe(dev, -EINVAL,
 			"Input pin number out of range for pair (%d %d).\n",
 			ain[0], ain[1]);

-- 
2.43.0

