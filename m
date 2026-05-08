From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 08 May 2026 18:00:21 +0100
Subject: [PATCH RFC v4 05/10] iio: frequency: ad9910: add digital ramp
 generator support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-ad9910-iio-driver-v4-5-d26bfd20ee3d@analog.com>
References: <20260508-ad9910-iio-driver-v4-0-d26bfd20ee3d@analog.com>
In-Reply-To: <20260508-ad9910-iio-driver-v4-0-d26bfd20ee3d@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-hardening@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778259632; l=22477;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=NfpSToH2PcS1f6WsdaG2n9FQwZc6Cr0ilMxcCH5zjak=;
 b=KWrAdVdFQinincrxcCgh7foc6fTVmoCw38F7OLEqHRdO6YM9SLjjXmNrrml129wUN1tmlpvR7
 K76sAvTGcZ8DvyJ1Z1sseANxA0Enq+9IhKxaZbXyGwwWAjhlB1jjhFu
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Digital Ramp Generator channels with destination selection (frequency,
phase, or amplitude) based on attribute writes, dwell mode control,
configurable upper/lower limits, step size controlled with rate of change
config, and step rate controlled as sampling frequency.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/ad9910.c | 511 ++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 509 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index b069b849e8d7..d6c88ec51145 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -130,6 +130,18 @@
 #define AD9910_MC_SYNC_OUTPUT_DELAY_MSK		GENMASK(15, 11)
 #define AD9910_MC_SYNC_INPUT_DELAY_MSK		GENMASK(7, 3)
 
+/* Digital Ramp Limit Register */
+#define AD9910_DRG_LIMIT_UPPER_MSK		GENMASK_ULL(63, 32)
+#define AD9910_DRG_LIMIT_LOWER_MSK		GENMASK_ULL(31, 0)
+
+/* Digital Ramp Step Register */
+#define AD9910_DRG_STEP_DEC_MSK			GENMASK_ULL(63, 32)
+#define AD9910_DRG_STEP_INC_MSK			GENMASK_ULL(31, 0)
+
+/* Digital Ramp Rate Register */
+#define AD9910_DRG_RATE_DEC_MSK			GENMASK(31, 16)
+#define AD9910_DRG_RATE_INC_MSK			GENMASK(15, 0)
+
 /* Profile Register Format (Single Tone Mode) */
 #define AD9910_PROFILE_ST_ASF_MSK		GENMASK_ULL(61, 48)
 #define AD9910_PROFILE_ST_POW_MSK		GENMASK_ULL(47, 32)
@@ -145,6 +157,7 @@
 #define AD9910_ASF_PP_LSB_MAX		GENMASK(5, 0)
 #define AD9910_POW_MAX			GENMASK(15, 0)
 #define AD9910_POW_PP_LSB_MAX		GENMASK(7, 0)
+#define AD9910_STEP_RATE_MAX		GENMASK(15, 0)
 #define AD9910_NUM_PROFILES		8
 
 /* PLL constants */
@@ -196,6 +209,9 @@
  * @AD9910_CHANNEL_PROFILE_6: Profile 6 output channel
  * @AD9910_CHANNEL_PROFILE_7: Profile 7 output channel
  * @AD9910_CHANNEL_PARALLEL_PORT: Parallel Port output channel
+ * @AD9910_CHANNEL_DRG: Digital Ramp Generator output channel
+ * @AD9910_CHANNEL_DRG_RAMP_UP: DRG ramp up channel
+ * @AD9910_CHANNEL_DRG_RAMP_DOWN: DRG ramp down channel
  */
 enum ad9910_channel {
 	AD9910_CHANNEL_PHY = 100,
@@ -208,6 +224,24 @@ enum ad9910_channel {
 	AD9910_CHANNEL_PROFILE_6 = 107,
 	AD9910_CHANNEL_PROFILE_7 = 108,
 	AD9910_CHANNEL_PARALLEL_PORT = 110,
+	AD9910_CHANNEL_DRG = 120,
+	AD9910_CHANNEL_DRG_RAMP_UP = 121,
+	AD9910_CHANNEL_DRG_RAMP_DOWN = 122,
+};
+
+/**
+ * enum ad9910_destination - AD9910 DDS core parameter destination
+ *
+ * @AD9910_DEST_FREQUENCY: Frequency destination
+ * @AD9910_DEST_PHASE: Phase destination
+ * @AD9910_DEST_AMPLITUDE: Amplitude destination
+ * @AD9910_DEST_POLAR: Polar destination
+ */
+enum ad9910_destination {
+	AD9910_DEST_FREQUENCY,
+	AD9910_DEST_PHASE,
+	AD9910_DEST_AMPLITUDE,
+	AD9910_DEST_POLAR,
 };
 
 enum {
@@ -221,6 +255,9 @@ enum {
 	AD9910_CHAN_IDX_PROFILE_6,
 	AD9910_CHAN_IDX_PROFILE_7,
 	AD9910_CHAN_IDX_PARALLEL_PORT,
+	AD9910_CHAN_IDX_DRG,
+	AD9910_CHAN_IDX_DRG_RAMP_UP,
+	AD9910_CHAN_IDX_DRG_RAMP_DOWN,
 };
 
 enum {
@@ -229,6 +266,10 @@ enum {
 	AD9910_PP_FREQ_OFFSET,
 	AD9910_PP_PHASE_OFFSET,
 	AD9910_PP_AMP_OFFSET,
+	AD9910_DRG_FREQ_ROC,
+	AD9910_DRG_PHASE_ROC,
+	AD9910_DRG_AMP_ROC,
+	AD9910_DRG_DWELL_EN,
 };
 
 struct ad9910_data {
@@ -482,6 +523,26 @@ static int ad9910_sw_powerdown_set(struct ad9910_state *st, bool enable)
 				   true);
 }
 
+static inline int ad9910_drg_destination_set(struct ad9910_state *st,
+					     enum ad9910_destination dest,
+					     bool update)
+{
+	return ad9910_reg32_update(st, AD9910_REG_CFR2,
+				   AD9910_CFR2_DRG_DEST_MSK,
+				   FIELD_PREP(AD9910_CFR2_DRG_DEST_MSK, dest),
+				   update);
+}
+
+static inline int ad9910_drg_destination_assert(struct ad9910_state *st,
+						enum ad9910_destination dest)
+{
+	enum ad9910_destination drg_dest;
+
+	drg_dest = (enum ad9910_destination)FIELD_GET(AD9910_CFR2_DRG_DEST_MSK,
+						      st->reg[AD9910_REG_CFR2].val32);
+	return drg_dest == dest ? 0 : -EBUSY;
+}
+
 static ssize_t ad9910_ext_info_read(struct iio_dev *indio_dev,
 				    uintptr_t private,
 				    const struct iio_chan_spec *chan,
@@ -500,6 +561,14 @@ static ssize_t ad9910_ext_info_read(struct iio_dev *indio_dev,
 		val = BIT(FIELD_GET(AD9910_CFR2_FM_GAIN_MSK,
 				    st->reg[AD9910_REG_CFR2].val32));
 		break;
+	case AD9910_DRG_DWELL_EN:
+		if (chan->channel == AD9910_CHANNEL_DRG_RAMP_UP)
+			val = FIELD_GET(AD9910_CFR2_DRG_NO_DWELL_HIGH_MSK,
+					st->reg[AD9910_REG_CFR2].val32) ? 0 : 1;
+		else
+			val = FIELD_GET(AD9910_CFR2_DRG_NO_DWELL_LOW_MSK,
+					st->reg[AD9910_REG_CFR2].val32) ? 0 : 1;
+		break;
 	default:
 		return -EINVAL;
 	}
@@ -539,6 +608,23 @@ static ssize_t ad9910_ext_info_write(struct iio_dev *indio_dev,
 		if (ret)
 			return ret;
 		break;
+	case AD9910_DRG_DWELL_EN:
+		if (chan->channel == AD9910_CHANNEL_DRG_RAMP_UP) {
+			val32 = val32 ? 0 : AD9910_CFR2_DRG_NO_DWELL_HIGH_MSK;
+			ret = ad9910_reg32_update(st, AD9910_REG_CFR2,
+						  AD9910_CFR2_DRG_NO_DWELL_HIGH_MSK,
+						  val32, true);
+			if (ret)
+				return ret;
+		} else {
+			val32 = val32 ? 0 : AD9910_CFR2_DRG_NO_DWELL_LOW_MSK;
+			ret = ad9910_reg32_update(st, AD9910_REG_CFR2,
+						  AD9910_CFR2_DRG_NO_DWELL_LOW_MSK,
+						  val32, true);
+			if (ret)
+				return ret;
+		}
+		break;
 	default:
 		return -EINVAL;
 	}
@@ -650,6 +736,179 @@ static ssize_t ad9910_pp_attrs_write(struct iio_dev *indio_dev,
 	return len;
 }
 
+static ssize_t ad9910_drg_attrs_read(struct iio_dev *indio_dev,
+				     uintptr_t private,
+				     const struct iio_chan_spec *chan,
+				     char *buf)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+	unsigned int type;
+	int ret, vals[2];
+	u64 roc64;
+	u32 rate;
+
+	guard(mutex)(&st->lock);
+
+	switch (chan->channel) {
+	case AD9910_CHANNEL_DRG_RAMP_UP:
+		roc64 = FIELD_GET(AD9910_DRG_STEP_INC_MSK,
+				  st->reg[AD9910_REG_DRG_STEP].val64);
+		rate = FIELD_GET(AD9910_DRG_RATE_INC_MSK,
+				 st->reg[AD9910_REG_DRG_RATE].val32);
+		break;
+	case AD9910_CHANNEL_DRG_RAMP_DOWN:
+		roc64 = FIELD_GET(AD9910_DRG_STEP_DEC_MSK,
+				  st->reg[AD9910_REG_DRG_STEP].val64);
+		rate = FIELD_GET(AD9910_DRG_RATE_DEC_MSK,
+				 st->reg[AD9910_REG_DRG_RATE].val32);
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	if (!rate)
+		return -ERANGE;
+
+	roc64 *= st->data.sysclk_freq_hz;
+	rate *= 4;
+
+	switch (private) {
+	case AD9910_DRG_FREQ_ROC:
+		ret = ad9910_drg_destination_assert(st, AD9910_DEST_FREQUENCY);
+		if (ret)
+			return ret;
+
+		type = IIO_VAL_INT_64;
+		roc64 = ad9910_rational_scale(roc64, st->data.sysclk_freq_hz,
+					      BIT_ULL(32) * rate);
+		vals[0] = (u32)roc64;
+		vals[1] = (u32)(roc64 >> 32);
+		break;
+	case AD9910_DRG_PHASE_ROC:
+		ret = ad9910_drg_destination_assert(st, AD9910_DEST_PHASE);
+		if (ret)
+			return ret;
+
+		type = IIO_VAL_INT_PLUS_NANO;
+		roc64 = ad9910_rational_scale(roc64, AD9910_PI_NANORAD,
+					      BIT_ULL(31) * rate);
+		vals[0] = div_s64_rem(roc64, NANO, &vals[1]);
+		break;
+	case AD9910_DRG_AMP_ROC:
+		ret = ad9910_drg_destination_assert(st, AD9910_DEST_AMPLITUDE);
+		if (ret)
+			return ret;
+
+		type = IIO_VAL_INT_PLUS_NANO;
+		roc64 = ad9910_rational_scale(roc64, NANO, BIT_ULL(32) * rate);
+		vals[0] = div_s64_rem(roc64, NANO, &vals[1]);
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
+	enum ad9910_destination dest;
+	int val, val2;
+	u64 tmp64;
+	u32 rate;
+	int ret;
+
+	guard(mutex)(&st->lock);
+
+	switch (chan->channel) {
+	case AD9910_CHANNEL_DRG_RAMP_UP:
+		rate = FIELD_GET(AD9910_DRG_RATE_INC_MSK,
+				 st->reg[AD9910_REG_DRG_RATE].val32);
+		break;
+	case AD9910_CHANNEL_DRG_RAMP_DOWN:
+		rate = FIELD_GET(AD9910_DRG_RATE_DEC_MSK,
+				 st->reg[AD9910_REG_DRG_RATE].val32);
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	if (!rate)
+		return -ERANGE;
+
+	rate *= 4;
+
+	switch (private) {
+	case AD9910_DRG_FREQ_ROC:
+		ret = kstrtou64(buf, 10, &tmp64);
+		if (ret)
+			return ret;
+
+		tmp64 = ad9910_rational_scale(tmp64, BIT_ULL(32) * rate,
+					      (u64)st->data.sysclk_freq_hz *
+					      st->data.sysclk_freq_hz);
+		dest = AD9910_DEST_FREQUENCY;
+		break;
+	case AD9910_DRG_PHASE_ROC:
+		ret = iio_str_to_fixpoint(buf, NANO / 10, &val, &val2);
+		if (ret)
+			return ret;
+
+		if (val < 0 || val2 < 0)
+			return -EINVAL;
+
+		tmp64 = (u64)val * NANO + val2;
+		tmp64 = ad9910_rational_scale(tmp64, BIT_ULL(31) * rate,
+					      (u64)AD9910_PI_NANORAD *
+					      st->data.sysclk_freq_hz);
+		dest = AD9910_DEST_PHASE;
+		break;
+	case AD9910_DRG_AMP_ROC:
+		ret = iio_str_to_fixpoint(buf, NANO / 10, &val, &val2);
+		if (ret)
+			return ret;
+
+		if (val < 0 || val2 < 0)
+			return -EINVAL;
+
+		tmp64 = (u64)val * NANO + val2;
+		tmp64 = ad9910_rational_scale(tmp64, BIT_ULL(32) * rate,
+					      (u64)NANO * st->data.sysclk_freq_hz);
+		dest = AD9910_DEST_AMPLITUDE;
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	ret = ad9910_drg_destination_set(st, dest, false);
+	if (ret)
+		return ret;
+
+	tmp64 = min(tmp64, U32_MAX);
+
+	if (chan->channel == AD9910_CHANNEL_DRG_RAMP_UP) {
+		ret = ad9910_reg64_update(st, AD9910_REG_DRG_STEP,
+					  AD9910_DRG_STEP_INC_MSK,
+					  FIELD_PREP(AD9910_DRG_STEP_INC_MSK, tmp64),
+					  true);
+		if (ret)
+			return ret;
+	} else {
+		ret = ad9910_reg64_update(st, AD9910_REG_DRG_STEP,
+					  AD9910_DRG_STEP_DEC_MSK,
+					  FIELD_PREP(AD9910_DRG_STEP_DEC_MSK, tmp64),
+					  true);
+		if (ret)
+			return ret;
+	}
+
+	return len;
+}
+
 #define AD9910_EXT_INFO_TMPL(_name, _ident, _shared, _fn_desc) { \
 	.name = _name, \
 	.read = ad9910_ ## _fn_desc ## _read, \
@@ -664,6 +923,9 @@ static ssize_t ad9910_pp_attrs_write(struct iio_dev *indio_dev,
 #define AD9910_PP_EXT_INFO(_name, _ident) \
 	AD9910_EXT_INFO_TMPL(_name, _ident, IIO_SEPARATE, pp_attrs)
 
+#define AD9910_DRG_EXT_INFO(_name, _ident) \
+	AD9910_EXT_INFO_TMPL(_name, _ident, IIO_SEPARATE, drg_attrs)
+
 static const struct iio_chan_spec_ext_info ad9910_phy_ext_info[] = {
 	AD9910_EXT_INFO("powerdown", AD9910_POWERDOWN, IIO_SEPARATE),
 	{ }
@@ -677,6 +939,14 @@ static const struct iio_chan_spec_ext_info ad9910_pp_ext_info[] = {
 	{ }
 };
 
+static const struct iio_chan_spec_ext_info ad9910_drg_ramp_ext_info[] = {
+	AD9910_EXT_INFO("dwell_en", AD9910_DRG_DWELL_EN, IIO_SEPARATE),
+	AD9910_DRG_EXT_INFO("frequency_roc", AD9910_DRG_FREQ_ROC),
+	AD9910_DRG_EXT_INFO("phase_roc", AD9910_DRG_PHASE_ROC),
+	AD9910_DRG_EXT_INFO("scale_roc", AD9910_DRG_AMP_ROC),
+	{ }
+};
+
 #define AD9910_PROFILE_CHAN(idx) {				\
 	.type = IIO_ALTVOLTAGE,					\
 	.indexed = 1,						\
@@ -716,6 +986,40 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE),
 		.ext_info = ad9910_pp_ext_info,
 	},
+	[AD9910_CHAN_IDX_DRG] = {
+		.type = IIO_ALTVOLTAGE,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_DRG,
+		.address = AD9910_CHAN_IDX_DRG,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE),
+	},
+	[AD9910_CHAN_IDX_DRG_RAMP_UP] = {
+		.type = IIO_ALTVOLTAGE,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_DRG_RAMP_UP,
+		.address = AD9910_CHAN_IDX_DRG_RAMP_UP,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE) |
+				      BIT(IIO_CHAN_INFO_FREQUENCY) |
+				      BIT(IIO_CHAN_INFO_PHASE) |
+				      BIT(IIO_CHAN_INFO_SCALE) |
+				      BIT(IIO_CHAN_INFO_SAMP_FREQ),
+		.ext_info = ad9910_drg_ramp_ext_info,
+	},
+	[AD9910_CHAN_IDX_DRG_RAMP_DOWN] = {
+		.type = IIO_ALTVOLTAGE,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_DRG_RAMP_DOWN,
+		.address = AD9910_CHAN_IDX_DRG_RAMP_DOWN,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE) |
+				      BIT(IIO_CHAN_INFO_FREQUENCY) |
+				      BIT(IIO_CHAN_INFO_PHASE) |
+				      BIT(IIO_CHAN_INFO_SCALE) |
+				      BIT(IIO_CHAN_INFO_SAMP_FREQ),
+		.ext_info = ad9910_drg_ramp_ext_info,
+	},
 };
 
 static int ad9910_read_raw(struct iio_dev *indio_dev,
@@ -725,6 +1029,7 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 	struct ad9910_state *st = iio_priv(indio_dev);
 	u64 tmp64;
 	u32 tmp32;
+	int ret;
 
 	guard(mutex)(&st->lock);
 
@@ -739,6 +1044,10 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 				*val = (tmp32 == st->profile);
 			}
 			break;
+		case AD9910_CHANNEL_DRG:
+			*val = FIELD_GET(AD9910_CFR2_DRG_ENABLE_MSK,
+					 st->reg[AD9910_REG_CFR2].val32);
+			break;
 		default:
 			return -EINVAL;
 		}
@@ -750,6 +1059,22 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 			tmp64 = FIELD_GET(AD9910_PROFILE_ST_FTW_MSK,
 					  st->reg[AD9910_REG_PROFILE(tmp32)].val64);
 			break;
+		case AD9910_CHANNEL_DRG_RAMP_UP:
+			ret = ad9910_drg_destination_assert(st, AD9910_DEST_FREQUENCY);
+			if (ret)
+				return ret;
+
+			tmp64 = FIELD_GET(AD9910_DRG_LIMIT_UPPER_MSK,
+					  st->reg[AD9910_REG_DRG_LIMIT].val64);
+			break;
+		case AD9910_CHANNEL_DRG_RAMP_DOWN:
+			ret = ad9910_drg_destination_assert(st, AD9910_DEST_FREQUENCY);
+			if (ret)
+				return ret;
+
+			tmp64 = FIELD_GET(AD9910_DRG_LIMIT_LOWER_MSK,
+					  st->reg[AD9910_REG_DRG_LIMIT].val64);
+			break;
 		default:
 			return -EINVAL;
 		}
@@ -767,6 +1092,26 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 			*val = tmp32 / MICRO;
 			*val2 = tmp32 % MICRO;
 			return IIO_VAL_INT_PLUS_MICRO;
+		case AD9910_CHANNEL_DRG_RAMP_UP:
+			ret = ad9910_drg_destination_assert(st, AD9910_DEST_PHASE);
+			if (ret)
+				return ret;
+
+			tmp64 = FIELD_GET(AD9910_DRG_LIMIT_UPPER_MSK,
+					  st->reg[AD9910_REG_DRG_LIMIT].val64);
+			tmp64 = (tmp64 * AD9910_PI_NANORAD) >> 31;
+			*val = div_u64_rem(tmp64, NANO, val2);
+			return IIO_VAL_INT_PLUS_NANO;
+		case AD9910_CHANNEL_DRG_RAMP_DOWN:
+			ret = ad9910_drg_destination_assert(st, AD9910_DEST_PHASE);
+			if (ret)
+				return ret;
+
+			tmp64 = FIELD_GET(AD9910_DRG_LIMIT_LOWER_MSK,
+					  st->reg[AD9910_REG_DRG_LIMIT].val64);
+			tmp64 = (tmp64 * AD9910_PI_NANORAD) >> 31;
+			*val = div_u64_rem(tmp64, NANO, val2);
+			return IIO_VAL_INT_PLUS_NANO;
 		default:
 			return -EINVAL;
 		}
@@ -779,6 +1124,26 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 			*val = 0;
 			*val2 = tmp64 * MICRO >> 14;
 			return IIO_VAL_INT_PLUS_MICRO;
+		case AD9910_CHANNEL_DRG_RAMP_UP:
+			ret = ad9910_drg_destination_assert(st, AD9910_DEST_AMPLITUDE);
+			if (ret)
+				return ret;
+
+			tmp64 = FIELD_GET(AD9910_DRG_LIMIT_UPPER_MSK,
+					  st->reg[AD9910_REG_DRG_LIMIT].val64);
+			*val = 0;
+			*val2 = tmp64 * NANO >> 32;
+			return IIO_VAL_INT_PLUS_NANO;
+		case AD9910_CHANNEL_DRG_RAMP_DOWN:
+			ret = ad9910_drg_destination_assert(st, AD9910_DEST_AMPLITUDE);
+			if (ret)
+				return ret;
+
+			tmp64 = FIELD_GET(AD9910_DRG_LIMIT_LOWER_MSK,
+					  st->reg[AD9910_REG_DRG_LIMIT].val64);
+			*val = 0;
+			*val2 = tmp64 * NANO >> 32;
+			return IIO_VAL_INT_PLUS_NANO;
 		default:
 			return -EINVAL;
 		}
@@ -787,9 +1152,23 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 		case AD9910_CHANNEL_PHY:
 			*val = st->data.sysclk_freq_hz;
 			return IIO_VAL_INT;
+		case AD9910_CHANNEL_DRG_RAMP_UP:
+			tmp32 = FIELD_GET(AD9910_DRG_RATE_INC_MSK,
+					  st->reg[AD9910_REG_DRG_RATE].val32);
+			break;
+		case AD9910_CHANNEL_DRG_RAMP_DOWN:
+			tmp32 = FIELD_GET(AD9910_DRG_RATE_DEC_MSK,
+					  st->reg[AD9910_REG_DRG_RATE].val32);
+			break;
 		default:
 			return -EINVAL;
 		}
+		if (!tmp32)
+			return -ERANGE;
+		tmp32 *= 4;
+		*val = st->data.sysclk_freq_hz / tmp32;
+		*val2 = div_u64((u64)(st->data.sysclk_freq_hz % tmp32) * MICRO, tmp32);
+		return IIO_VAL_INT_PLUS_MICRO;
 	default:
 		return -EINVAL;
 	}
@@ -823,6 +1202,11 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 				return ret;
 
 			return ad9910_profile_set(st, tmp32);
+		case AD9910_CHANNEL_DRG:
+			tmp32 = FIELD_PREP(AD9910_CFR2_DRG_ENABLE_MSK, val);
+			return ad9910_reg32_update(st, AD9910_REG_CFR2,
+						   AD9910_CFR2_DRG_ENABLE_MSK,
+						   tmp32, true);
 		default:
 			return -EINVAL;
 		}
@@ -840,6 +1224,28 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			return ad9910_reg64_update(st, AD9910_REG_PROFILE(tmp32),
 						   AD9910_PROFILE_ST_FTW_MSK,
 						   tmp64, true);
+		case AD9910_CHANNEL_DRG_RAMP_UP:
+			ret = ad9910_drg_destination_set(st,
+							 AD9910_DEST_FREQUENCY,
+							 false);
+			if (ret)
+				return ret;
+
+			tmp64 = FIELD_PREP(AD9910_DRG_LIMIT_UPPER_MSK, tmp64);
+			return ad9910_reg64_update(st, AD9910_REG_DRG_LIMIT,
+						   AD9910_DRG_LIMIT_UPPER_MSK,
+						   tmp64, true);
+		case AD9910_CHANNEL_DRG_RAMP_DOWN:
+			ret = ad9910_drg_destination_set(st,
+							 AD9910_DEST_FREQUENCY,
+							 false);
+			if (ret)
+				return ret;
+
+			tmp64 = FIELD_PREP(AD9910_DRG_LIMIT_LOWER_MSK, tmp64);
+			return ad9910_reg64_update(st, AD9910_REG_DRG_LIMIT,
+						   AD9910_DRG_LIMIT_LOWER_MSK,
+						   tmp64, true);
 		default:
 			return -EINVAL;
 		}
@@ -861,6 +1267,40 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			return ad9910_reg64_update(st, AD9910_REG_PROFILE(tmp32),
 						   AD9910_PROFILE_ST_POW_MSK,
 						   tmp64, true);
+		case AD9910_CHANNEL_DRG_RAMP_UP:
+			tmp64 = (u64)val * NANO + val2;
+			if (tmp64 > 2ULL * AD9910_PI_NANORAD)
+				return -EINVAL;
+
+			ret = ad9910_drg_destination_set(st, AD9910_DEST_PHASE,
+							 false);
+			if (ret)
+				return ret;
+
+			tmp64 <<= 31;
+			tmp64 = DIV_U64_ROUND_CLOSEST(tmp64, AD9910_PI_NANORAD);
+			tmp64 = min(tmp64, U32_MAX);
+			tmp64 = FIELD_PREP(AD9910_DRG_LIMIT_UPPER_MSK, tmp64);
+			return ad9910_reg64_update(st, AD9910_REG_DRG_LIMIT,
+						   AD9910_DRG_LIMIT_UPPER_MSK,
+						   tmp64, true);
+		case AD9910_CHANNEL_DRG_RAMP_DOWN:
+			tmp64 = (u64)val * NANO + val2;
+			if (tmp64 > 2ULL * AD9910_PI_NANORAD)
+				return -EINVAL;
+
+			ret = ad9910_drg_destination_set(st, AD9910_DEST_PHASE,
+							 false);
+			if (ret)
+				return ret;
+
+			tmp64 <<= 31;
+			tmp64 = DIV_U64_ROUND_CLOSEST(tmp64, AD9910_PI_NANORAD);
+			tmp64 = min(tmp64, U32_MAX);
+			tmp64 = FIELD_PREP(AD9910_DRG_LIMIT_LOWER_MSK, tmp64);
+			return ad9910_reg64_update(st, AD9910_REG_DRG_LIMIT,
+						   AD9910_DRG_LIMIT_LOWER_MSK,
+						   tmp64, true);
 		default:
 			return -EINVAL;
 		}
@@ -878,11 +1318,62 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			return ad9910_reg64_update(st, AD9910_REG_PROFILE(tmp32),
 						   AD9910_PROFILE_ST_ASF_MSK,
 						   tmp64, true);
+		case AD9910_CHANNEL_DRG_RAMP_UP:
+			ret = ad9910_drg_destination_set(st,
+							 AD9910_DEST_AMPLITUDE,
+							 false);
+			if (ret)
+				return ret;
+
+			tmp64 = ((u64)val * NANO + val2) << 32;
+			tmp64 = DIV_U64_ROUND_CLOSEST(tmp64, NANO);
+			tmp64 = min(tmp64, U32_MAX);
+			tmp64 = FIELD_PREP(AD9910_DRG_LIMIT_UPPER_MSK, tmp64);
+			return ad9910_reg64_update(st, AD9910_REG_DRG_LIMIT,
+						   AD9910_DRG_LIMIT_UPPER_MSK,
+						   tmp64, true);
+		case AD9910_CHANNEL_DRG_RAMP_DOWN:
+			ret = ad9910_drg_destination_set(st,
+							 AD9910_DEST_AMPLITUDE,
+							 false);
+			if (ret)
+				return ret;
+
+			tmp64 = ((u64)val * NANO + val2) << 32;
+			tmp64 = DIV_U64_ROUND_CLOSEST(tmp64, NANO);
+			tmp64 = min(tmp64, U32_MAX);
+			tmp64 = FIELD_PREP(AD9910_DRG_LIMIT_LOWER_MSK, tmp64);
+			return ad9910_reg64_update(st, AD9910_REG_DRG_LIMIT,
+						   AD9910_DRG_LIMIT_LOWER_MSK,
+						   tmp64, true);
 		default:
 			return -EINVAL;
 		}
 	case IIO_CHAN_INFO_SAMP_FREQ:
-		return ad9910_set_sysclk_freq(st, val, true);
+		if (chan->channel == AD9910_CHANNEL_PHY)
+			return ad9910_set_sysclk_freq(st, val, true);
+
+		tmp64 = ((u64)val * MICRO + val2) * 4;
+		if (!tmp64)
+			return -EINVAL;
+
+		tmp64 = DIV64_U64_ROUND_CLOSEST((u64)st->data.sysclk_freq_hz * MICRO, tmp64);
+		tmp32 = clamp(tmp64, 1U, AD9910_STEP_RATE_MAX);
+
+		switch (chan->channel) {
+		case AD9910_CHANNEL_DRG_RAMP_UP:
+			tmp32 = FIELD_PREP(AD9910_DRG_RATE_INC_MSK, tmp32);
+			return ad9910_reg32_update(st, AD9910_REG_DRG_RATE,
+						   AD9910_DRG_RATE_INC_MSK,
+						   tmp32, true);
+		case AD9910_CHANNEL_DRG_RAMP_DOWN:
+			tmp32 = FIELD_PREP(AD9910_DRG_RATE_DEC_MSK, tmp32);
+			return ad9910_reg32_update(st, AD9910_REG_DRG_RATE,
+						   AD9910_DRG_RATE_DEC_MSK,
+						   tmp32, true);
+		default:
+			return -EINVAL;
+		}
 	default:
 		return -EINVAL;
 	}
@@ -902,11 +1393,16 @@ static int ad9910_write_raw_get_fmt(struct iio_dev *indio_dev,
 		switch (chan->channel) {
 		case AD9910_CHANNEL_PROFILE_0 ... AD9910_CHANNEL_PROFILE_7:
 			return IIO_VAL_INT_PLUS_MICRO;
+		case AD9910_CHANNEL_DRG_RAMP_UP:
+		case AD9910_CHANNEL_DRG_RAMP_DOWN:
+			return IIO_VAL_INT_PLUS_NANO;
 		default:
 			return -EINVAL;
 		}
 	case IIO_CHAN_INFO_SAMP_FREQ:
-		return IIO_VAL_INT;
+		if (chan->channel == AD9910_CHANNEL_PHY)
+			return IIO_VAL_INT;
+		return IIO_VAL_INT_PLUS_MICRO;
 	default:
 		return -EINVAL;
 	}
@@ -969,6 +1465,9 @@ static const char * const ad9910_channel_str[] = {
 	[AD9910_CHAN_IDX_PROFILE_6] = "profile[6]",
 	[AD9910_CHAN_IDX_PROFILE_7] = "profile[7]",
 	[AD9910_CHAN_IDX_PARALLEL_PORT] = "parallel_port",
+	[AD9910_CHAN_IDX_DRG] = "digital_ramp_generator",
+	[AD9910_CHAN_IDX_DRG_RAMP_UP] = "digital_ramp_up",
+	[AD9910_CHAN_IDX_DRG_RAMP_DOWN] = "digital_ramp_down",
 };
 
 static int ad9910_read_label(struct iio_dev *indio_dev,
@@ -1094,6 +1593,14 @@ static int ad9910_setup(struct device *dev, struct ad9910_state *st,
 	if (ret)
 		return ret;
 
+	/* configure step rate with default values */
+	ret = ad9910_reg32_write(st, AD9910_REG_DRG_RATE,
+				 FIELD_PREP(AD9910_DRG_RATE_DEC_MSK, 1) |
+				 FIELD_PREP(AD9910_DRG_RATE_INC_MSK, 1),
+				 false);
+	if (ret)
+		return ret;
+
 	return ad9910_io_update(st);
 }
 

-- 
2.43.0

