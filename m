From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 18 Mar 2026 17:56:03 +0000
Subject: [PATCH RFC v2 3/9] iio: frequency: ad9910: add simple parallel
 port mode support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260318-ad9910-iio-driver-v2-3-e79f93becf11@analog.com>
References: <20260318-ad9910-iio-driver-v2-0-e79f93becf11@analog.com>
In-Reply-To: <20260318-ad9910-iio-driver-v2-0-e79f93becf11@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773856569; l=8543;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=PlCtBUP0RZJkGXyIdwIVJVBbtVxiO7gUEORlBP1VJcM=;
 b=WPq7P/A++Yx7bK3PCfCWYJWTK8QPPCG7P2gHc9v416Vk2IvG4sfvWLTkPpCa0uGHfGUpc5ck+
 si6K7wxOVyaDtv+w9J1p8wTf7T5a0HV7abVWnQfeQRlC19MGx1TzSto
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add parallel port channel with frequency scale, frequency offset, phase
offset, and amplitude offset extended attributes for configuring the
parallel data path.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/ad9910.c | 173 ++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 170 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index a362d96cf651..726fac0b9fc1 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -114,9 +114,13 @@
 /* Auxiliary DAC Control Register Bits */
 #define AD9910_AUX_DAC_FSC_MSK			GENMASK(7, 0)
 
+/* POW Register Bits */
+#define AD9910_POW_PP_LSB_MSK			GENMASK(7, 0)
+
 /* ASF Register Bits */
 #define AD9910_ASF_RAMP_RATE_MSK		GENMASK(31, 16)
 #define AD9910_ASF_SCALE_FACTOR_MSK		GENMASK(15, 2)
+#define AD9910_ASF_SCALE_FACTOR_PP_LSB_MSK	GENMASK(7, 2)
 #define AD9910_ASF_STEP_SIZE_MSK		GENMASK(1, 0)
 
 /* Multichip Sync Register Bits */
@@ -140,7 +144,9 @@
 #define AD9910_MAX_PHASE_MICRORAD	(AD9910_PI_NANORAD / 500)
 
 #define AD9910_ASF_MAX			(BIT(14) - 1)
+#define AD9910_ASF_PP_LSB_MAX		(BIT(6) - 1)
 #define AD9910_POW_MAX			(BIT(16) - 1)
+#define AD9910_POW_PP_LSB_MAX		(BIT(8) - 1)
 #define AD9910_NUM_PROFILES		8
 
 /* PLL constants */
@@ -184,10 +190,12 @@
  *
  * @AD9910_CHANNEL_PHY: Physical output channel
  * @AD9910_CHANNEL_SINGLE_TONE: Single tone output channel
+ * @AD9910_CHANNEL_PARALLEL_PORT: Parallel port output channel
  */
 enum ad9910_channel {
 	AD9910_CHANNEL_PHY = 100,
 	AD9910_CHANNEL_SINGLE_TONE = 110,
+	AD9910_CHANNEL_PARALLEL_PORT = 120,
 };
 
 enum {
@@ -204,6 +212,10 @@ enum {
 enum {
 	AD9910_PROFILE,
 	AD9910_POWERDOWN,
+	AD9910_PP_FREQ_SCALE,
+	AD9910_PP_FREQ_OFFSET,
+	AD9910_PP_PHASE_OFFSET,
+	AD9910_PP_AMP_OFFSET,
 };
 
 struct ad9910_data {
@@ -468,6 +480,10 @@ static ssize_t ad9910_ext_info_read(struct iio_dev *indio_dev,
 		val = !!FIELD_GET(AD9910_CFR1_SOFT_POWER_DOWN_MSK,
 				  st->reg[AD9910_REG_CFR1].val32);
 		break;
+	case AD9910_PP_FREQ_SCALE:
+		val = BIT(FIELD_GET(AD9910_CFR2_FM_GAIN_MSK,
+				    st->reg[AD9910_REG_CFR2].val32));
+		break;
 	default:
 		return -EINVAL;
 	}
@@ -503,6 +519,15 @@ static ssize_t ad9910_ext_info_write(struct iio_dev *indio_dev,
 					  AD9910_CFR1_SOFT_POWER_DOWN_MSK,
 					  val32, true);
 		break;
+	case AD9910_PP_FREQ_SCALE:
+		if (val32 > BIT(15) || !is_power_of_2(val32))
+			return -EINVAL;
+
+		val32 = FIELD_PREP(AD9910_CFR2_FM_GAIN_MSK, ilog2(val32));
+		ret = ad9910_reg32_update(st, AD9910_REG_CFR2,
+					  AD9910_CFR2_FM_GAIN_MSK,
+					  val32, true);
+		break;
 	default:
 		return -EINVAL;
 	}
@@ -510,20 +535,132 @@ static ssize_t ad9910_ext_info_write(struct iio_dev *indio_dev,
 	return ret ?: len;
 }
 
-#define AD9910_EXT_INFO(_name, _ident, _shared) { \
+static ssize_t ad9910_pp_attrs_read(struct iio_dev *indio_dev,
+				    uintptr_t private,
+				    const struct iio_chan_spec *chan,
+				    char *buf)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+	int vals[2];
+	u32 tmp32;
+	u64 tmp64;
+
+	guard(mutex)(&st->lock);
+
+	switch (private) {
+	case AD9910_PP_FREQ_OFFSET:
+		tmp64 = (u64)st->reg[AD9910_REG_FTW].val32 * st->data.sysclk_freq_hz;
+		vals[0] = upper_32_bits(tmp64);
+		vals[1] = upper_32_bits((u64)lower_32_bits(tmp64) * MICRO);
+		break;
+	case AD9910_PP_PHASE_OFFSET:
+		tmp32 = FIELD_GET(AD9910_POW_PP_LSB_MSK,
+				  st->reg[AD9910_REG_POW].val16);
+		tmp32 = (tmp32 * AD9910_MAX_PHASE_MICRORAD) >> 16;
+		vals[0] = tmp32 / MICRO;
+		vals[1] = tmp32 % MICRO;
+		break;
+	case AD9910_PP_AMP_OFFSET:
+		tmp32 = FIELD_GET(AD9910_ASF_SCALE_FACTOR_PP_LSB_MSK,
+				  st->reg[AD9910_REG_ASF].val32);
+		vals[0] = 0;
+		vals[1] = (u64)tmp32 * MICRO >> 14;
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	return iio_format_value(buf, IIO_VAL_INT_PLUS_MICRO, ARRAY_SIZE(vals), vals);
+}
+
+static ssize_t ad9910_pp_attrs_write(struct iio_dev *indio_dev,
+				     uintptr_t private,
+				     const struct iio_chan_spec *chan,
+				     const char *buf, size_t len)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+	int val, val2;
+	u32 tmp32;
+	int ret;
+
+	ret = iio_str_to_fixpoint(buf, MICRO / 10, &val, &val2);
+	if (ret)
+		return ret;
+
+	guard(mutex)(&st->lock);
+
+	switch (private) {
+	case AD9910_PP_FREQ_OFFSET:
+		if (!in_range(val, 0, st->data.sysclk_freq_hz / 2))
+			return -EINVAL;
+
+		tmp32 = ad9910_rational_scale((u64)val * MICRO + val2, BIT_ULL(32),
+					      (u64)MICRO * st->data.sysclk_freq_hz);
+		ret = ad9910_reg32_write(st, AD9910_REG_FTW, tmp32, true);
+		break;
+	case AD9910_PP_PHASE_OFFSET:
+		if (val)
+			return -EINVAL;
+
+		if (!in_range(val2, 0, (AD9910_MAX_PHASE_MICRORAD >> 8)))
+			return -EINVAL;
+
+		tmp32 = DIV_ROUND_CLOSEST((u32)val2 << 16, AD9910_MAX_PHASE_MICRORAD);
+		tmp32 = min(tmp32, AD9910_POW_PP_LSB_MAX);
+		tmp32 = FIELD_PREP(AD9910_POW_PP_LSB_MSK, tmp32);
+		ret = ad9910_reg16_update(st, AD9910_REG_POW,
+					  AD9910_POW_PP_LSB_MSK,
+					  tmp32, true);
+		break;
+	case AD9910_PP_AMP_OFFSET:
+		if (val)
+			return -EINVAL;
+
+		if (!in_range(val2, 0, (MICRO >> 8)))
+			return -EINVAL;
+
+		tmp32 = DIV_ROUND_CLOSEST((u32)val2 << 14, MICRO);
+		tmp32 = min(tmp32, AD9910_ASF_PP_LSB_MAX);
+		tmp32 = FIELD_PREP(AD9910_ASF_SCALE_FACTOR_PP_LSB_MSK, tmp32);
+		ret = ad9910_reg32_update(st, AD9910_REG_ASF,
+					  AD9910_ASF_SCALE_FACTOR_PP_LSB_MSK,
+					  tmp32, true);
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	return ret ?: len;
+}
+
+#define AD9910_EXT_INFO_TMPL(_name, _ident, _shared, _fn_desc) { \
 	.name = _name, \
-	.read = ad9910_ext_info_read, \
-	.write = ad9910_ext_info_write, \
+	.read = ad9910_ ## _fn_desc ## _read, \
+	.write = ad9910_ ## _fn_desc ## _write, \
 	.private = _ident, \
 	.shared = _shared, \
 }
 
+#define AD9910_EXT_INFO(_name, _ident, _shared) \
+	AD9910_EXT_INFO_TMPL(_name, _ident, _shared, ext_info)
+
+#define AD9910_PP_EXT_INFO(_name, _ident) \
+	AD9910_EXT_INFO_TMPL(_name, _ident, IIO_SEPARATE, pp_attrs)
+
 static const struct iio_chan_spec_ext_info ad9910_phy_ext_info[] = {
 	AD9910_EXT_INFO("profile", AD9910_PROFILE, IIO_SEPARATE),
 	AD9910_EXT_INFO("powerdown", AD9910_POWERDOWN, IIO_SEPARATE),
 	{ }
 };
 
+static const struct iio_chan_spec_ext_info ad9910_pp_ext_info[] = {
+	AD9910_EXT_INFO("frequency_scale", AD9910_PP_FREQ_SCALE, IIO_SEPARATE),
+	AD9910_PP_EXT_INFO("frequency_offset", AD9910_PP_FREQ_OFFSET),
+	AD9910_PP_EXT_INFO("phase_offset", AD9910_PP_PHASE_OFFSET),
+	AD9910_PP_EXT_INFO("scale_offset", AD9910_PP_AMP_OFFSET),
+	{ }
+};
+
 static const struct iio_chan_spec ad9910_channels[] = {
 	[AD9910_CHAN_IDX_PHY] = {
 		.type = IIO_ALTVOLTAGE,
@@ -546,6 +683,15 @@ static const struct iio_chan_spec ad9910_channels[] = {
 				      BIT(IIO_CHAN_INFO_PHASE) |
 				      BIT(IIO_CHAN_INFO_SCALE),
 	},
+	[AD9910_CHAN_IDX_PARALLEL_PORT] = {
+		.type = IIO_ALTVOLTAGE,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_PARALLEL_PORT,
+		.address = AD9910_CHAN_IDX_PARALLEL_PORT,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE),
+		.ext_info = ad9910_pp_ext_info,
+	},
 };
 
 static int ad9910_read_raw(struct iio_dev *indio_dev,
@@ -559,6 +705,16 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 	guard(mutex)(&st->lock);
 
 	switch (info) {
+	case IIO_CHAN_INFO_ENABLE:
+		switch (chan->channel) {
+		case AD9910_CHANNEL_PARALLEL_PORT:
+			*val = FIELD_GET(AD9910_CFR2_PARALLEL_DATA_PORT_EN_MSK,
+					 st->reg[AD9910_REG_CFR2].val32);
+			break;
+		default:
+			return -EINVAL;
+		}
+		return IIO_VAL_INT;
 	case IIO_CHAN_INFO_FREQUENCY:
 		switch (chan->channel) {
 		case AD9910_CHANNEL_SINGLE_TONE:
@@ -619,6 +775,17 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 	guard(mutex)(&st->lock);
 
 	switch (info) {
+	case IIO_CHAN_INFO_ENABLE:
+		val = !!val;
+		switch (chan->channel) {
+		case AD9910_CHANNEL_PARALLEL_PORT:
+			tmp32 = FIELD_PREP(AD9910_CFR2_PARALLEL_DATA_PORT_EN_MSK, val);
+			return ad9910_reg32_update(st, AD9910_REG_CFR2,
+						   AD9910_CFR2_PARALLEL_DATA_PORT_EN_MSK,
+						   tmp32, true);
+		default:
+			return -EINVAL;
+		}
 	case IIO_CHAN_INFO_FREQUENCY:
 		if (!in_range(val, 0, st->data.sysclk_freq_hz / 2))
 			return -EINVAL;

-- 
2.43.0

