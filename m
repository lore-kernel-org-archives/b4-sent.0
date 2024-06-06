From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Thu, 06 Jun 2024 19:07:44 +0300
Subject: [PATCH v6 5/9] iio: adc: ad7173: refactor ain and vref selection
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240606-ad4111-v6-5-573981fb3e2e@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717690059; l=4459;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=osgOuDlGa6R7YDZKTd3Tx1xGd0RE2vp7BzpV9WWHDMo=;
 b=xOA/LON3BxpaO/2XrvRdSGxoKqFzULVNGjXINlU5lvXfSc2iP8TWNVpWll9UQC/sbFiRDER+B
 hXMik25YNQQCKWSooT8PMX66gfewbH2GzI+aJMPZHc8X0F8kv80+Qe1
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move validation of analog inputs and reference voltage selection to
separate functions to reduce the size of the channel config parsing
function and improve readability.
Add defines for the number of analog inputs in a channel.

Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 drivers/iio/adc/ad7173.c | 68 +++++++++++++++++++++++++++++++++---------------
 1 file changed, 47 insertions(+), 21 deletions(-)

diff --git a/drivers/iio/adc/ad7173.c b/drivers/iio/adc/ad7173.c
index 8631f218b69e..4040edbd1c32 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -60,6 +60,7 @@
 #define AD7173_CH_SETUP_AINPOS_MASK	GENMASK(9, 5)
 #define AD7173_CH_SETUP_AINNEG_MASK	GENMASK(4, 0)
 
+#define AD7173_NO_AINS_PER_CHANNEL	2
 #define AD7173_CH_ADDRESS(pos, neg) \
 	(FIELD_PREP(AD7173_CH_SETUP_AINPOS_MASK, pos) | \
 	 FIELD_PREP(AD7173_CH_SETUP_AINNEG_MASK, neg))
@@ -629,6 +630,7 @@ static int ad7173_setup(struct iio_dev *indio_dev)
 static unsigned int ad7173_get_ref_voltage_milli(struct ad7173_state *st,
 						 u8 reference_select)
 {
+	struct device *dev = &st->sd.spi->dev;
 	int vref;
 
 	switch (reference_select) {
@@ -652,9 +654,11 @@ static unsigned int ad7173_get_ref_voltage_milli(struct ad7173_state *st,
 		return -EINVAL;
 	}
 
-	if (vref < 0)
+	if (vref < 0) {
+		dev_err(dev, "Cannot use reference %u. Error:%d\n",
+			reference_select, vref);
 		return vref;
-
+	}
 	return vref / (MICRO / MILLI);
 }
 
@@ -906,13 +910,47 @@ static int ad7173_register_clk_provider(struct iio_dev *indio_dev)
 					   &st->int_clk_hw);
 }
 
+static int ad7173_validate_voltage_ain_inputs(struct ad7173_state *st,
+					      unsigned int ain0, unsigned int ain1)
+{
+	struct device *dev = &st->sd.spi->dev;
+
+	if (ain0 >= st->info->num_inputs ||
+	    ain1 >= st->info->num_inputs)
+		return dev_err_probe(dev, -EINVAL,
+				     "Input pin number out of range for pair (%d %d).\n",
+				     ain0, ain1);
+
+	return 0;
+}
+
+static int ad7173_validate_reference(struct ad7173_state *st, int ref_sel)
+{
+	struct device *dev = &st->sd.spi->dev;
+	int ret;
+
+	if (ref_sel == AD7173_SETUP_REF_SEL_INT_REF && !st->info->has_int_ref)
+		return dev_err_probe(dev, -EINVAL,
+			"Internal reference is not available on current model.\n");
+
+	if (ref_sel == AD7173_SETUP_REF_SEL_EXT_REF2 && !st->info->has_ref2)
+		return dev_err_probe(dev, -EINVAL,
+			"External reference 2 is not available on current model.\n");
+
+	ret = ad7173_get_ref_voltage_milli(st, ref_sel);
+	if (ret < 0)
+		return ret;
+
+	return 0;
+}
+
 static int ad7173_fw_parse_channel_config(struct iio_dev *indio_dev)
 {
 	struct ad7173_channel *chans_st_arr, *chan_st_priv;
 	struct ad7173_state *st = iio_priv(indio_dev);
 	struct device *dev = indio_dev->dev.parent;
 	struct iio_chan_spec *chan_arr, *chan;
-	unsigned int ain[2], chan_index = 0;
+	unsigned int ain[AD7173_NO_AINS_PER_CHANNEL], chan_index = 0;
 	int ref_sel, ret, num_channels;
 
 	num_channels = device_get_child_node_count(dev);
@@ -966,11 +1004,9 @@ static int ad7173_fw_parse_channel_config(struct iio_dev *indio_dev)
 		if (ret)
 			return ret;
 
-		if (ain[0] >= st->info->num_inputs ||
-		    ain[1] >= st->info->num_inputs)
-			return dev_err_probe(dev, -EINVAL,
-				"Input pin number out of range for pair (%d %d).\n",
-				ain[0], ain[1]);
+		ret = ad7173_validate_voltage_ain_inputs(st, ain[0], ain[1]);
+		if (ret)
+			return ret;
 
 		ret = fwnode_property_match_property_string(child,
 							    "adi,reference-select",
@@ -981,19 +1017,9 @@ static int ad7173_fw_parse_channel_config(struct iio_dev *indio_dev)
 		else
 			ref_sel = ret;
 
-		if (ref_sel == AD7173_SETUP_REF_SEL_INT_REF &&
-		    !st->info->has_int_ref)
-			return dev_err_probe(dev, -EINVAL,
-				"Internal reference is not available on current model.\n");
-
-		if (ref_sel == AD7173_SETUP_REF_SEL_EXT_REF2 && !st->info->has_ref2)
-			return dev_err_probe(dev, -EINVAL,
-				"External reference 2 is not available on current model.\n");
-
-		ret = ad7173_get_ref_voltage_milli(st, ref_sel);
-		if (ret < 0)
-			return dev_err_probe(dev, ret,
-					     "Cannot use reference %u\n", ref_sel);
+		ret = ad7173_validate_reference(st, ref_sel);
+		if (ret)
+			return ret;
 
 		if (ref_sel == AD7173_SETUP_REF_SEL_INT_REF)
 			st->adc_mode |= AD7173_ADC_MODE_REF_EN;

-- 
2.43.0

