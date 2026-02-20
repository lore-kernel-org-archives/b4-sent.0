From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 20 Feb 2026 16:46:09 +0000
Subject: [PATCH RFC 5/8] iio: frequency: ad9910: add digital ramp generator
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260220-ad9910-iio-driver-v1-5-3b264aa48a10@analog.com>
References: <20260220-ad9910-iio-driver-v1-0-3b264aa48a10@analog.com>
In-Reply-To: <20260220-ad9910-iio-driver-v1-0-3b264aa48a10@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771605986; l=17752;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=izJCqqe/mjPLHctBorpLyiMP1dZRqD1NyGEif4TXAjw=;
 b=2IVfzeWafZ9tnV0QCz+Ju0CiRp6gWOSDBaaJ6nWuDC33d72ygpNw8qEUfZvntliTvaroSZHLg
 hiOvY7N6QV3CXkJbrTeszMLhadA8sVEV5crFYdyhAWiXcXUzICTLTAA
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add DRG channel with destination selection (frequency, phase, or
amplitude), operating mode control, configurable upper/lower limits,
increment/decrement step sizes, and step rate settings for the digital
ramp generator.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/ad9910.c | 454 +++++++++++++++++++++++++++++++++++++++++
 1 file changed, 454 insertions(+)

diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index a72e3685f676..84698bf2dc4e 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -133,6 +133,18 @@
 #define AD9910_MC_SYNC_OUTPUT_DELAY_MSK		GENMASK(15, 11)
 #define AD9910_MC_SYNC_INPUT_DELAY_MSK		GENMASK(7, 3)
 
+/* Digital Ramp Limit Register */
+#define AD9910_DRG_LIMIT_UPPER_MSK		AD9910_REG_HIGH32_MSK
+#define AD9910_DRG_LIMIT_LOWER_MSK		AD9910_REG_LOW32_MSK
+
+/* Digital Ramp Step Register */
+#define AD9910_DRG_STEP_DEC_MSK			AD9910_REG_HIGH32_MSK
+#define AD9910_DRG_STEP_INC_MSK			AD9910_REG_LOW32_MSK
+
+/* Digital Ramp Rate Register */
+#define AD9910_DRG_RATE_DEC_MSK			GENMASK(31, 16)
+#define AD9910_DRG_RATE_INC_MSK			GENMASK(15, 0)
+
 /* Profile Register Format (Single Tone Mode) */
 #define AD9910_PROFILE_ST_ASF_MSK		GENMASK_ULL(61, 48)
 #define AD9910_PROFILE_ST_POW_MSK		GENMASK_ULL(47, 32)
@@ -148,8 +160,11 @@
 #define AD9910_ASF_PP_LSB_MAX		(BIT(6) - 1)
 #define AD9910_POW_MAX			(BIT(16) - 1)
 #define AD9910_POW_PP_LSB_MAX		(BIT(8) - 1)
+#define AD9910_STEP_RATE_MAX		(BIT(16) - 1)
 #define AD9910_NUM_PROFILES		8
 
+#define AD9910_DRG_DEST_NUM		3
+
 /* PLL constants */
 #define AD9910_PLL_MIN_N		12
 #define AD9910_PLL_MAX_N		127
@@ -192,6 +207,32 @@
 enum ad9910_channel {
 	AD9910_CHANNEL_SINGLE_TONE,
 	AD9910_CHANNEL_PARALLEL_PORT,
+	AD9910_CHANNEL_DRG,
+};
+
+/**
+ * enum ad9910_destination - AD9910 DDS core parameter destination
+ */
+enum ad9910_destination {
+	AD9910_DEST_FREQUENCY,
+	AD9910_DEST_PHASE,
+	AD9910_DEST_AMPLITUDE,
+	AD9910_DEST_POLAR,
+};
+
+/**
+ * enum ad9910_drg_oper_mode - Digital Ramp Generator Operating Mode
+ *
+ * @AD9910_DRG_OPER_MODE_BIDIR: Normal Ramp Generation
+ * @AD9910_DRG_OPER_MODE_RAMP_DOWN: No-dwell Low only operation
+ * @AD9910_DRG_OPER_MODE_RAMP_UP: No-dwell High only operation
+ * @AD9910_DRG_OPER_MODE_BIDIR_CONT: Both No-dwell High/Low operation
+ */
+enum ad9910_drg_oper_mode {
+	AD9910_DRG_OPER_MODE_BIDIR,
+	AD9910_DRG_OPER_MODE_RAMP_DOWN,
+	AD9910_DRG_OPER_MODE_RAMP_UP,
+	AD9910_DRG_OPER_MODE_BIDIR_CONT,
 };
 
 enum {
@@ -201,6 +242,20 @@ enum {
 	AD9910_PP_FREQ_OFFSET,
 	AD9910_PP_PHASE_OFFSET,
 	AD9910_PP_AMP_OFFSET,
+	AD9910_DRG_FREQ_UPPER_LIMIT,
+	AD9910_DRG_FREQ_LOWER_LIMIT,
+	AD9910_DRG_FREQ_INC_STEP,
+	AD9910_DRG_FREQ_DEC_STEP,
+	AD9910_DRG_PHASE_UPPER_LIMIT,
+	AD9910_DRG_PHASE_LOWER_LIMIT,
+	AD9910_DRG_PHASE_INC_STEP,
+	AD9910_DRG_PHASE_DEC_STEP,
+	AD9910_DRG_AMP_UPPER_LIMIT,
+	AD9910_DRG_AMP_LOWER_LIMIT,
+	AD9910_DRG_AMP_INC_STEP,
+	AD9910_DRG_AMP_DEC_STEP,
+	AD9910_DRG_INC_STEP_RATE,
+	AD9910_DRG_DEC_STEP_RATE,
 };
 
 struct ad9910_data {
@@ -262,6 +317,20 @@ static const char * const ad9910_refclk_out_drv0[] = {
 	"disabled", "low", "medium", "high",
 };
 
+static const char * const ad9910_destination_str[] = {
+	[AD9910_DEST_FREQUENCY] = "frequency",
+	[AD9910_DEST_PHASE] = "phase",
+	[AD9910_DEST_AMPLITUDE] = "amplitude",
+	[AD9910_DEST_POLAR] = "polar",
+};
+
+static const char * const ad9910_drg_oper_mode_str[] = {
+	[AD9910_DRG_OPER_MODE_BIDIR] = "bidirectional",
+	[AD9910_DRG_OPER_MODE_RAMP_DOWN] = "ramp_down",
+	[AD9910_DRG_OPER_MODE_RAMP_UP] = "ramp_up",
+	[AD9910_DRG_OPER_MODE_BIDIR_CONT] = "bidirectional_continuous",
+};
+
 /**
  * ad9910_rational_scale() - Perform scaling of input given a reference.
  * @input: The input value to be scaled.
@@ -381,6 +450,66 @@ static int ad9910_powerdown_set(struct ad9910_state *st, bool enable)
 	return gpiod_set_value_cansleep(st->gpio_pwdown, enable);
 }
 
+static int ad9910_chan_destination_set(struct iio_dev *indio_dev,
+				       const struct iio_chan_spec *chan,
+				       unsigned int val)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+
+	guard(mutex)(&st->lock);
+
+	switch (chan->channel) {
+	case AD9910_CHANNEL_DRG:
+		return ad9910_reg32_update(st, AD9910_REG_CFR2,
+					   AD9910_CFR2_DRG_DEST_MSK,
+					   FIELD_PREP(AD9910_CFR2_DRG_DEST_MSK, val),
+					   true);
+	default:
+		return -EINVAL;
+	}
+}
+
+static int ad9910_chan_destination_get(struct iio_dev *indio_dev,
+				       const struct iio_chan_spec *chan)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+
+	guard(mutex)(&st->lock);
+
+	switch (chan->channel) {
+	case AD9910_CHANNEL_DRG:
+		return FIELD_GET(AD9910_CFR2_DRG_DEST_MSK,
+				 st->reg[AD9910_REG_CFR2].val32);
+	default:
+		return -EINVAL;
+	}
+}
+
+static int ad9910_drg_oper_mode_set(struct iio_dev *indio_dev,
+				    const struct iio_chan_spec *chan,
+				    unsigned int val)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+
+	guard(mutex)(&st->lock);
+
+	return ad9910_reg32_update(st, AD9910_REG_CFR2,
+				   AD9910_CFR2_DRG_NO_DWELL_MSK,
+				   FIELD_PREP(AD9910_CFR2_DRG_NO_DWELL_MSK, val),
+				   true);
+}
+
+static int ad9910_drg_oper_mode_get(struct iio_dev *indio_dev,
+				    const struct iio_chan_spec *chan)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+
+	guard(mutex)(&st->lock);
+
+	return FIELD_GET(AD9910_CFR2_DRG_NO_DWELL_MSK,
+			 st->reg[AD9910_REG_CFR2].val32);
+}
+
 static ssize_t ad9910_ext_info_read(struct iio_dev *indio_dev,
 				    uintptr_t private,
 				    const struct iio_chan_spec *chan,
@@ -546,6 +675,264 @@ static ssize_t ad9910_pp_attrs_write(struct iio_dev *indio_dev,
 	return ret ?: len;
 }
 
+static ssize_t ad9910_step_rate_read(struct iio_dev *indio_dev,
+				     uintptr_t private,
+				     const struct iio_chan_spec *chan,
+				     char *buf)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+	int vals[2];
+	u32 tmp32;
+
+	guard(mutex)(&st->lock);
+
+	switch (private) {
+	case AD9910_DRG_INC_STEP_RATE:
+		tmp32 = FIELD_GET(AD9910_DRG_RATE_INC_MSK,
+				  st->reg[AD9910_REG_DRG_RATE].val32);
+		break;
+	case AD9910_DRG_DEC_STEP_RATE:
+		tmp32 = FIELD_GET(AD9910_DRG_RATE_DEC_MSK,
+				  st->reg[AD9910_REG_DRG_RATE].val32);
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	if (tmp32 == 0)
+		return -ERANGE;
+
+	tmp32 *= 4;
+	vals[0] = st->data.sysclk_freq_hz / tmp32;
+	vals[1] = div_u64((u64)(st->data.sysclk_freq_hz % tmp32) * MICRO, tmp32);
+
+	return iio_format_value(buf, IIO_VAL_INT_PLUS_MICRO, ARRAY_SIZE(vals), vals);
+}
+
+static ssize_t ad9910_step_rate_write(struct iio_dev *indio_dev,
+				      uintptr_t private,
+				      const struct iio_chan_spec *chan,
+				      const char *buf, size_t len)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+	int val, val2;
+	u64 rate_val;
+	u64 sysclk_uhz;
+	int ret;
+
+	ret = iio_str_to_fixpoint(buf, MICRO / 10, &val, &val2);
+	if (ret)
+		return ret;
+
+	sysclk_uhz = (u64)st->data.sysclk_freq_hz * MICROHZ_PER_HZ;
+	rate_val = ((u64)val * MICROHZ_PER_HZ + val2) * 4;
+	if (rate_val == 0 || rate_val > sysclk_uhz)
+		return -EINVAL;
+
+	rate_val = min(DIV64_U64_ROUND_CLOSEST(sysclk_uhz, rate_val),
+		       AD9910_STEP_RATE_MAX);
+
+	guard(mutex)(&st->lock);
+
+	switch (private) {
+	case AD9910_DRG_INC_STEP_RATE:
+		ret = ad9910_reg32_update(st, AD9910_REG_DRG_RATE,
+					  AD9910_DRG_RATE_INC_MSK,
+					  FIELD_PREP(AD9910_DRG_RATE_INC_MSK, rate_val),
+					  true);
+		break;
+	case AD9910_DRG_DEC_STEP_RATE:
+		ret = ad9910_reg32_update(st, AD9910_REG_DRG_RATE,
+					  AD9910_DRG_RATE_DEC_MSK,
+					  FIELD_PREP(AD9910_DRG_RATE_DEC_MSK, rate_val), true);
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	return ret ?: len;
+}
+
+static ssize_t ad9910_drg_attrs_read(struct iio_dev *indio_dev,
+				     uintptr_t private,
+				     const struct iio_chan_spec *chan,
+				     char *buf)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+	unsigned int type;
+	int vals[2];
+	u64 tmp64;
+
+	guard(mutex)(&st->lock);
+
+	switch (private) {
+	case AD9910_DRG_FREQ_UPPER_LIMIT:
+	case AD9910_DRG_PHASE_UPPER_LIMIT:
+	case AD9910_DRG_AMP_UPPER_LIMIT:
+		tmp64 = FIELD_GET(AD9910_DRG_LIMIT_UPPER_MSK,
+				  st->reg[AD9910_REG_DRG_LIMIT].val64);
+		break;
+	case AD9910_DRG_FREQ_LOWER_LIMIT:
+	case AD9910_DRG_PHASE_LOWER_LIMIT:
+	case AD9910_DRG_AMP_LOWER_LIMIT:
+		tmp64 = FIELD_GET(AD9910_DRG_LIMIT_LOWER_MSK,
+				  st->reg[AD9910_REG_DRG_LIMIT].val64);
+		break;
+	case AD9910_DRG_FREQ_INC_STEP:
+	case AD9910_DRG_PHASE_INC_STEP:
+	case AD9910_DRG_AMP_INC_STEP:
+		tmp64 = FIELD_GET(AD9910_DRG_STEP_INC_MSK,
+				  st->reg[AD9910_REG_DRG_STEP].val64);
+		break;
+	case AD9910_DRG_FREQ_DEC_STEP:
+	case AD9910_DRG_PHASE_DEC_STEP:
+	case AD9910_DRG_AMP_DEC_STEP:
+		tmp64 = FIELD_GET(AD9910_DRG_STEP_DEC_MSK,
+				  st->reg[AD9910_REG_DRG_STEP].val64);
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	switch (private) {
+	case AD9910_DRG_FREQ_UPPER_LIMIT:
+	case AD9910_DRG_FREQ_LOWER_LIMIT:
+	case AD9910_DRG_FREQ_INC_STEP:
+	case AD9910_DRG_FREQ_DEC_STEP:
+		type = IIO_VAL_INT_PLUS_MICRO;
+		tmp64 *= st->data.sysclk_freq_hz;
+		vals[0] = upper_32_bits(tmp64);
+		vals[1] = upper_32_bits((u64)lower_32_bits(tmp64) * MICRO);
+		break;
+	case AD9910_DRG_PHASE_UPPER_LIMIT:
+	case AD9910_DRG_PHASE_LOWER_LIMIT:
+	case AD9910_DRG_PHASE_INC_STEP:
+	case AD9910_DRG_PHASE_DEC_STEP:
+		type = IIO_VAL_INT_PLUS_NANO;
+		tmp64 *= AD9910_PI_NANORAD;
+		tmp64 >>= 31;
+		vals[0] = div_u64_rem(tmp64, NANO, &vals[1]);
+		break;
+	case AD9910_DRG_AMP_UPPER_LIMIT:
+	case AD9910_DRG_AMP_LOWER_LIMIT:
+	case AD9910_DRG_AMP_INC_STEP:
+	case AD9910_DRG_AMP_DEC_STEP:
+		type = IIO_VAL_INT_PLUS_NANO;
+		vals[0] = 0;
+		vals[1] = tmp64 * NANO >> 32;
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	return iio_format_value(buf, type, ARRAY_SIZE(vals), vals);
+}
+
+static ssize_t ad9910_drg_attrs_write(struct iio_dev *indio_dev,
+				      uintptr_t private,
+				      const struct iio_chan_spec *chan,
+				      const char *buf, size_t len)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+	int val, val2;
+	u64 tmp64;
+	int ret;
+
+	switch (private) {
+	case AD9910_DRG_FREQ_UPPER_LIMIT:
+	case AD9910_DRG_FREQ_LOWER_LIMIT:
+	case AD9910_DRG_FREQ_INC_STEP:
+	case AD9910_DRG_FREQ_DEC_STEP:
+		ret = iio_str_to_fixpoint(buf, MICRO / 10, &val, &val2);
+		if (ret)
+			return ret;
+
+		if (val >= st->data.sysclk_freq_hz / 2)
+			return -EINVAL;
+
+		tmp64 = (u64)val * MICRO + val2;
+		tmp64 = ad9910_rational_scale(tmp64, BIT_ULL(32),
+					      (u64)MICRO * st->data.sysclk_freq_hz);
+		break;
+	case AD9910_DRG_PHASE_UPPER_LIMIT:
+	case AD9910_DRG_PHASE_LOWER_LIMIT:
+	case AD9910_DRG_PHASE_INC_STEP:
+	case AD9910_DRG_PHASE_DEC_STEP:
+		ret = iio_str_to_fixpoint(buf, NANO / 10, &val, &val2);
+		if (ret)
+			return ret;
+
+		if (val < 0 || val2 < 0)
+			return -EINVAL;
+
+		tmp64 = (u64)val * NANO + val2;
+		if (tmp64 > 2ULL * AD9910_PI_NANORAD)
+			return -EINVAL;
+
+		tmp64 <<= 31;
+		tmp64 = DIV_U64_ROUND_CLOSEST(tmp64, AD9910_PI_NANORAD);
+		break;
+	case AD9910_DRG_AMP_UPPER_LIMIT:
+	case AD9910_DRG_AMP_LOWER_LIMIT:
+	case AD9910_DRG_AMP_INC_STEP:
+	case AD9910_DRG_AMP_DEC_STEP:
+		ret = iio_str_to_fixpoint(buf, NANO / 10, &val, &val2);
+		if (ret)
+			return ret;
+
+		if (val < 0 || val > 1 || (val == 1 && val2 > 0))
+			return -EINVAL;
+
+		tmp64 = ((u64)val * NANO + val2) << 32;
+		tmp64 = DIV_U64_ROUND_CLOSEST(tmp64, NANO);
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	tmp64 = min(tmp64, U32_MAX);
+	guard(mutex)(&st->lock);
+
+	switch (private) {
+	case AD9910_DRG_FREQ_UPPER_LIMIT:
+	case AD9910_DRG_PHASE_UPPER_LIMIT:
+	case AD9910_DRG_AMP_UPPER_LIMIT:
+		ret = ad9910_reg64_update(st, AD9910_REG_DRG_LIMIT,
+					  AD9910_DRG_LIMIT_UPPER_MSK,
+					  FIELD_PREP(AD9910_DRG_LIMIT_UPPER_MSK, tmp64),
+					  true);
+		break;
+	case AD9910_DRG_FREQ_LOWER_LIMIT:
+	case AD9910_DRG_PHASE_LOWER_LIMIT:
+	case AD9910_DRG_AMP_LOWER_LIMIT:
+		ret = ad9910_reg64_update(st, AD9910_REG_DRG_LIMIT,
+					  AD9910_DRG_LIMIT_LOWER_MSK,
+					  FIELD_PREP(AD9910_DRG_LIMIT_LOWER_MSK, tmp64),
+					  true);
+		break;
+	case AD9910_DRG_FREQ_INC_STEP:
+	case AD9910_DRG_PHASE_INC_STEP:
+	case AD9910_DRG_AMP_INC_STEP:
+		ret = ad9910_reg64_update(st, AD9910_REG_DRG_STEP,
+					  AD9910_DRG_STEP_INC_MSK,
+					  FIELD_PREP(AD9910_DRG_STEP_INC_MSK, tmp64),
+					  true);
+		break;
+	case AD9910_DRG_FREQ_DEC_STEP:
+	case AD9910_DRG_PHASE_DEC_STEP:
+	case AD9910_DRG_AMP_DEC_STEP:
+		ret = ad9910_reg64_update(st, AD9910_REG_DRG_STEP,
+					  AD9910_DRG_STEP_DEC_MSK,
+					  FIELD_PREP(AD9910_DRG_STEP_DEC_MSK, tmp64),
+					  true);
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	return ret ?: len;
+}
+
 #define AD9910_EXT_INFO_TMPL(_name, _ident, _shared, _fn_desc) { \
 	.name = _name, \
 	.read = ad9910_ ## _fn_desc ## _read, \
@@ -560,6 +947,26 @@ static ssize_t ad9910_pp_attrs_write(struct iio_dev *indio_dev,
 #define AD9910_PP_EXT_INFO(_name, _ident) \
 	AD9910_EXT_INFO_TMPL(_name, _ident, IIO_SEPARATE, pp_attrs)
 
+#define AD9910_STEP_RATE_EXT_INFO(_name, _ident) \
+	AD9910_EXT_INFO_TMPL(_name, _ident, IIO_SEPARATE, step_rate)
+
+#define AD9910_DRG_EXT_INFO(_name, _ident) \
+	AD9910_EXT_INFO_TMPL(_name, _ident, IIO_SEPARATE, drg_attrs)
+
+static const struct iio_enum ad9910_drg_destination_enum = {
+	.items = ad9910_destination_str,
+	.num_items = AD9910_DRG_DEST_NUM,
+	.set = ad9910_chan_destination_set,
+	.get = ad9910_chan_destination_get,
+};
+
+static const struct iio_enum ad9910_drg_oper_mode_enum = {
+	.items = ad9910_drg_oper_mode_str,
+	.num_items = ARRAY_SIZE(ad9910_drg_oper_mode_str),
+	.set = ad9910_drg_oper_mode_set,
+	.get = ad9910_drg_oper_mode_get,
+};
+
 static const struct iio_chan_spec_ext_info ad9910_shared_ext_info[] = {
 	AD9910_EXT_INFO("profile", AD9910_PROFILE, IIO_SHARED_BY_TYPE),
 	AD9910_EXT_INFO("powerdown", AD9910_POWERDOWN, IIO_SHARED_BY_TYPE),
@@ -574,6 +981,28 @@ static const struct iio_chan_spec_ext_info ad9910_pp_ext_info[] = {
 	{ },
 };
 
+static const struct iio_chan_spec_ext_info ad9910_drg_ext_info[] = {
+	IIO_ENUM("destination", IIO_SEPARATE, &ad9910_drg_destination_enum),
+	IIO_ENUM_AVAILABLE("destination", IIO_SEPARATE, &ad9910_drg_destination_enum),
+	IIO_ENUM("operating_mode", IIO_SEPARATE, &ad9910_drg_oper_mode_enum),
+	IIO_ENUM_AVAILABLE("operating_mode", IIO_SEPARATE, &ad9910_drg_oper_mode_enum),
+	AD9910_DRG_EXT_INFO("frequency_max", AD9910_DRG_FREQ_UPPER_LIMIT),
+	AD9910_DRG_EXT_INFO("frequency_min", AD9910_DRG_FREQ_LOWER_LIMIT),
+	AD9910_DRG_EXT_INFO("frequency_increment", AD9910_DRG_FREQ_INC_STEP),
+	AD9910_DRG_EXT_INFO("frequency_decrement", AD9910_DRG_FREQ_DEC_STEP),
+	AD9910_DRG_EXT_INFO("phase_max", AD9910_DRG_PHASE_UPPER_LIMIT),
+	AD9910_DRG_EXT_INFO("phase_min", AD9910_DRG_PHASE_LOWER_LIMIT),
+	AD9910_DRG_EXT_INFO("phase_increment", AD9910_DRG_PHASE_INC_STEP),
+	AD9910_DRG_EXT_INFO("phase_decrement", AD9910_DRG_PHASE_DEC_STEP),
+	AD9910_DRG_EXT_INFO("scale_max", AD9910_DRG_AMP_UPPER_LIMIT),
+	AD9910_DRG_EXT_INFO("scale_min", AD9910_DRG_AMP_LOWER_LIMIT),
+	AD9910_DRG_EXT_INFO("scale_increment", AD9910_DRG_AMP_INC_STEP),
+	AD9910_DRG_EXT_INFO("scale_decrement", AD9910_DRG_AMP_DEC_STEP),
+	AD9910_STEP_RATE_EXT_INFO("increment_sampling_frequency", AD9910_DRG_INC_STEP_RATE),
+	AD9910_STEP_RATE_EXT_INFO("decrement_sampling_frequency", AD9910_DRG_DEC_STEP_RATE),
+	{ },
+};
+
 static const struct iio_chan_spec ad9910_channels[] = {
 	[AD9910_CHANNEL_SINGLE_TONE] = {
 		.type = IIO_ALTVOLTAGE,
@@ -594,6 +1023,15 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE),
 		.ext_info = ad9910_pp_ext_info,
 	},
+	[AD9910_CHANNEL_DRG] = {
+		.type = IIO_ALTVOLTAGE,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_DRG,
+		.scan_index = -1,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE),
+		.ext_info = ad9910_drg_ext_info,
+	},
 };
 
 static int ad9910_read_raw(struct iio_dev *indio_dev,
@@ -613,6 +1051,10 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 			*val = FIELD_GET(AD9910_CFR2_PARALLEL_DATA_PORT_EN_MSK,
 					 st->reg[AD9910_REG_CFR2].val32);
 			break;
+		case AD9910_CHANNEL_DRG:
+			*val = FIELD_GET(AD9910_CFR2_DRG_ENABLE_MSK,
+					 st->reg[AD9910_REG_CFR2].val32);
+			break;
 		default:
 			return -EINVAL;
 		}
@@ -662,6 +1104,11 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			return ad9910_reg32_update(st, AD9910_REG_CFR2,
 						   AD9910_CFR2_PARALLEL_DATA_PORT_EN_MSK,
 						   tmp32, true);
+		case AD9910_CHANNEL_DRG:
+			tmp32 = FIELD_PREP(AD9910_CFR2_DRG_ENABLE_MSK, val);
+			return ad9910_reg32_update(st, AD9910_REG_CFR2,
+						   AD9910_CFR2_DRG_ENABLE_MSK,
+						   tmp32, true);
 		default:
 			return -EINVAL;
 		}
@@ -972,6 +1419,13 @@ static int ad9910_setup(struct ad9910_state *st, struct reset_control *dev_rst)
 	if (ret)
 		return ret;
 
+	/* configure step rate with default values */
+	reg32 = FIELD_PREP(AD9910_DRG_RATE_DEC_MSK, 1) |
+		FIELD_PREP(AD9910_DRG_RATE_INC_MSK, 1);
+	ret = ad9910_reg32_write(st, AD9910_REG_DRG_RATE, reg32, false);
+	if (ret)
+		return ret;
+
 	return ad9910_io_update(st);
 }
 

-- 
2.43.0

