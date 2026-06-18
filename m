From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Thu, 18 Jun 2026 14:27:27 +0100
Subject: [PATCH v6 11/16] iio: frequency: ad9910: add digital ramp
 generator support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260618-ad9910-iio-driver-v6-11-79125ffbe430@analog.com>
References: <20260618-ad9910-iio-driver-v6-0-79125ffbe430@analog.com>
In-Reply-To: <20260618-ad9910-iio-driver-v6-0-79125ffbe430@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781789267; l=17060;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=CkD0qONRireLQC89JNLKHpd4PmYr3yBlKJa+/d4coLw=;
 b=YTljPZJHL5iuGp5NuJMe5hwz9g4pcX3wqVnPwM+TXKjGO8SZYIWKwlBa/A3wbrQLWVgcUgW8C
 nufPefGZzm7CHlm1NpLRP+3fKcuFuyQ7C8BXdPbn7lTiiME09yhIx+8
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
 drivers/iio/frequency/ad9910.c | 345 ++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 340 insertions(+), 5 deletions(-)

diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index 262702b62738..3fe97aa887c3 100644
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
@@ -137,6 +149,7 @@
 
 /* Device constants */
 #define AD9910_PI_NANORAD		3141592653UL
+#define AD9910_PI_PICORAD		3141592653590ULL
 
 #define AD9910_MAX_SYSCLK_HZ		(1000 * HZ_PER_MHZ)
 #define AD9910_MAX_PHASE_MICRORAD	(AD9910_PI_NANORAD / 500)
@@ -145,6 +158,7 @@
 #define AD9910_ASF_PP_LSB_MAX		FIELD_MAX(AD9910_ASF_SCALE_FACTOR_PP_LSB_MSK)
 #define AD9910_POW_MAX			FIELD_MAX(AD9910_PROFILE_ST_POW_MSK)
 #define AD9910_POW_PP_LSB_MAX		FIELD_MAX(AD9910_POW_PP_LSB_MSK)
+#define AD9910_STEP_RATE_MAX		FIELD_MAX(AD9910_DRG_RATE_DEC_MSK)
 #define AD9910_NUM_PROFILES		8
 
 /* PLL constants */
@@ -174,6 +188,7 @@
 
 /* altcurrent ABI is in mA */
 #define AD9910_NANO_MILLIAMP_PER_MICROAMP	1000000UL
+#define AD9910_PICO_MILLIAMP_PER_MICROAMP	1000000000UL
 
 #define AD9910_REFDIV2_MIN_FREQ_HZ	(120 * HZ_PER_MHZ)
 #define AD9910_REFDIV2_MAX_FREQ_HZ	(1900 * HZ_PER_MHZ)
@@ -201,6 +216,9 @@
  * @AD9910_CHANNEL_PROFILE_7: Profile 7 output channel
  * @AD9910_CHANNEL_PARALLEL: Parallel Data output channel
  * @AD9910_CHANNEL_PARALLEL_POLAR: Parallel Polar Data output channel
+ * @AD9910_CHANNEL_DRG: Digital Ramp Generator output channel
+ * @AD9910_CHANNEL_DRG_RAMP_UP: DRG ramp up channel
+ * @AD9910_CHANNEL_DRG_RAMP_DOWN: DRG ramp down channel
  */
 enum ad9910_channel {
 	AD9910_CHANNEL_PHY = 100,
@@ -214,6 +232,9 @@ enum ad9910_channel {
 	AD9910_CHANNEL_PROFILE_7 = 117,
 	AD9910_CHANNEL_PARALLEL = 120,
 	AD9910_CHANNEL_PARALLEL_POLAR = 121,
+	AD9910_CHANNEL_DRG = 130,
+	AD9910_CHANNEL_DRG_RAMP_UP = 131,
+	AD9910_CHANNEL_DRG_RAMP_DOWN = 132,
 };
 
 enum {
@@ -231,10 +252,17 @@ enum {
 	AD9910_CHAN_IDX_PARALLEL_FREQ,
 	AD9910_CHAN_IDX_PARALLEL_POLAR_AMP,
 	AD9910_CHAN_IDX_PARALLEL_POLAR_PHASE,
+	AD9910_CHAN_IDX_DRG_FREQ,
+	AD9910_CHAN_IDX_DRG_PHASE,
+	AD9910_CHAN_IDX_DRG_AMP,
+	AD9910_CHAN_IDX_DRG_AMP_RAMP_UP,
+	AD9910_CHAN_IDX_DRG_AMP_RAMP_DOWN,
 };
 
 enum {
 	AD9910_POWERDOWN,
+	AD9910_DWELL_EN,
+	AD9910_ROC,
 };
 
 struct ad9910_data {
@@ -503,6 +531,14 @@ static ssize_t ad9910_ext_info_read(struct iio_dev *indio_dev,
 	case AD9910_POWERDOWN:
 		val = ad9910_sw_powerdown_get(st);
 		break;
+	case AD9910_DWELL_EN:
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
@@ -531,6 +567,113 @@ static ssize_t ad9910_ext_info_write(struct iio_dev *indio_dev,
 		if (ret)
 			return ret;
 		break;
+	case AD9910_DWELL_EN:
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
+	default:
+		return -EINVAL;
+	}
+
+	return len;
+}
+
+static ssize_t ad9910_drg_roc_read(struct iio_dev *indio_dev, uintptr_t private,
+				   const struct iio_chan_spec *chan,
+				   char *buf)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
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
+	return sysfs_emit(buf, "%llu\n", div_u64(roc64, 4 * rate));
+}
+
+static ssize_t ad9910_drg_roc_write(struct iio_dev *indio_dev,
+				    uintptr_t private,
+				    const struct iio_chan_spec *chan,
+				    const char *buf, size_t len)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+	u64 tmp64;
+	u32 rate;
+	int ret;
+
+	ret = kstrtou64(buf, 10, &tmp64);
+	if (ret)
+		return ret;
+
+	guard(mutex)(&st->lock);
+
+	switch (chan->channel) {
+	case AD9910_CHANNEL_DRG_RAMP_UP:
+		rate = FIELD_GET(AD9910_DRG_RATE_INC_MSK,
+				 st->reg[AD9910_REG_DRG_RATE].val32);
+		if (!rate)
+			return -ERANGE;
+
+		tmp64 = ad9910_rational_scale(tmp64, 4 * rate, st->data.sysclk_freq_hz);
+		tmp64 = min_t(u64, tmp64, U32_MAX);
+
+		ret = ad9910_reg64_update(st, AD9910_REG_DRG_STEP,
+					  AD9910_DRG_STEP_INC_MSK,
+					  FIELD_PREP(AD9910_DRG_STEP_INC_MSK, tmp64),
+					  true);
+		if (ret)
+			return ret;
+		break;
+	case AD9910_CHANNEL_DRG_RAMP_DOWN:
+		rate = FIELD_GET(AD9910_DRG_RATE_DEC_MSK,
+				 st->reg[AD9910_REG_DRG_RATE].val32);
+		if (!rate)
+			return -ERANGE;
+
+		tmp64 = ad9910_rational_scale(tmp64, 4 * rate, st->data.sysclk_freq_hz);
+		tmp64 = min_t(u64, tmp64, U32_MAX);
+
+		ret = ad9910_reg64_update(st, AD9910_REG_DRG_STEP,
+					  AD9910_DRG_STEP_DEC_MSK,
+					  FIELD_PREP(AD9910_DRG_STEP_DEC_MSK, tmp64),
+					  true);
+		if (ret)
+			return ret;
+		break;
 	default:
 		return -EINVAL;
 	}
@@ -549,6 +692,24 @@ static const struct iio_chan_spec_ext_info ad9910_phy_ext_info[] = {
 	{ }
 };
 
+static const struct iio_chan_spec_ext_info ad9910_drg_ramp_ext_info[] = {
+	{
+		.name = "dwell_en",
+		.read = ad9910_ext_info_read,
+		.write = ad9910_ext_info_write,
+		.private = AD9910_DWELL_EN,
+		.shared = IIO_SEPARATE,
+	},
+	{
+		.name = "raw_roc",
+		.read = ad9910_drg_roc_read,
+		.write = ad9910_drg_roc_write,
+		.private = AD9910_ROC,
+		.shared = IIO_SEPARATE,
+	},
+	{ }
+};
+
 #define AD9910_PROFILE_CHAN(idx) {				\
 	.type = IIO_ALTCURRENT,					\
 	.indexed = 1,						\
@@ -628,6 +789,58 @@ static const struct iio_chan_spec ad9910_channels[] = {
 				      BIT(IIO_CHAN_INFO_SCALE),
 		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
 	},
+	[AD9910_CHAN_IDX_DRG_FREQ] = {
+		.type = IIO_FREQUENCY,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_DRG,
+		.address = AD9910_CHAN_IDX_DRG_FREQ,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE) |
+				      BIT(IIO_CHAN_INFO_SCALE),
+		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
+	},
+	[AD9910_CHAN_IDX_DRG_PHASE] = {
+		.type = IIO_PHASE,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_DRG,
+		.address = AD9910_CHAN_IDX_DRG_PHASE,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE) |
+				      BIT(IIO_CHAN_INFO_SCALE),
+		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
+	},
+	[AD9910_CHAN_IDX_DRG_AMP] = {
+		.type = IIO_ALTCURRENT,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_DRG,
+		.address = AD9910_CHAN_IDX_DRG_AMP,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE) |
+				      BIT(IIO_CHAN_INFO_SCALE),
+		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
+	},
+	[AD9910_CHAN_IDX_DRG_AMP_RAMP_UP] = {
+		.type = IIO_ALTCURRENT,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_DRG_RAMP_UP,
+		.address = AD9910_CHAN_IDX_DRG_AMP_RAMP_UP,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
+				      BIT(IIO_CHAN_INFO_SAMP_FREQ),
+		.ext_info = ad9910_drg_ramp_ext_info,
+		.parent = &ad9910_channels[AD9910_CHAN_IDX_DRG_AMP],
+	},
+	[AD9910_CHAN_IDX_DRG_AMP_RAMP_DOWN] = {
+		.type = IIO_ALTCURRENT,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_DRG_RAMP_DOWN,
+		.address = AD9910_CHAN_IDX_DRG_AMP_RAMP_DOWN,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
+				      BIT(IIO_CHAN_INFO_SAMP_FREQ),
+		.ext_info = ad9910_drg_ramp_ext_info,
+		.parent = &ad9910_channels[AD9910_CHAN_IDX_DRG_AMP],
+	},
 };
 
 static int ad9910_read_raw(struct iio_dev *indio_dev,
@@ -651,6 +864,15 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 				*val = (tmp32 == st->profile);
 			}
 			break;
+		case AD9910_CHANNEL_DRG:
+			tmp32 = FIELD_GET(AD9910_CFR2_DRG_DEST_MSK,
+					  st->reg[AD9910_REG_CFR2].val32);
+			if (tmp32 == (chan->address - AD9910_CHAN_IDX_DRG_FREQ))
+				*val = FIELD_GET(AD9910_CFR2_DRG_ENABLE_MSK,
+						 st->reg[AD9910_REG_CFR2].val32);
+			else
+				*val = 0;
+			break;
 		default:
 			return -EINVAL;
 		}
@@ -690,6 +912,16 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 			*val = FIELD_GET(AD9910_PROFILE_ST_ASF_MSK,
 					 st->reg[AD9910_REG_PROFILE(tmp32)].val64);
 			return IIO_VAL_INT;
+		case AD9910_CHANNEL_DRG_RAMP_UP:
+			tmp64 = FIELD_GET(AD9910_DRG_LIMIT_UPPER_MSK,
+					  st->reg[AD9910_REG_DRG_LIMIT].val64);
+			iio_val_s64_decompose(tmp64, val, val2);
+			return IIO_VAL_INT_64;
+		case AD9910_CHANNEL_DRG_RAMP_DOWN:
+			tmp64 = FIELD_GET(AD9910_DRG_LIMIT_LOWER_MSK,
+					  st->reg[AD9910_REG_DRG_LIMIT].val64);
+			iio_val_s64_decompose(tmp64, val, val2);
+			return IIO_VAL_INT_64;
 		default:
 			return -EINVAL;
 		}
@@ -698,9 +930,23 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
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
 	case IIO_CHAN_INFO_SCALE:
 		switch (chan->address) {
 		case AD9910_CHAN_IDX_PHY:
@@ -730,6 +976,21 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 			*val = 0;
 			*val2 = AD9910_PI_NANORAD >> 7;
 			return IIO_VAL_INT_PLUS_NANO;
+		case AD9910_CHAN_IDX_DRG_FREQ:
+			tmp64 = ad9910_rational_scale(st->data.sysclk_freq_hz,
+						      PICO, BIT_ULL(32));
+			iio_val_s64_decompose(tmp64, val, val2);
+			return IIO_VAL_DECIMAL64_PICO;
+		case AD9910_CHAN_IDX_DRG_PHASE:
+			tmp64 = DIV_U64_ROUND_CLOSEST(AD9910_PI_PICORAD, BIT(31));
+			iio_val_s64_decompose(tmp64, val, val2);
+			return IIO_VAL_DECIMAL64_PICO;
+		case AD9910_CHAN_IDX_DRG_AMP:
+			tmp64 = (u64)st->data.output_current_uA *
+				AD9910_PICO_MILLIAMP_PER_MICROAMP;
+			tmp64 = DIV_U64_ROUND_CLOSEST(tmp64 >> 1, BIT(31));
+			iio_val_s64_decompose(tmp64, val, val2);
+			return IIO_VAL_DECIMAL64_PICO;
 		default:
 			return -EINVAL;
 		}
@@ -789,6 +1050,22 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 				return ret;
 
 			return ad9910_profile_set(st, tmp32);
+		case AD9910_CHANNEL_DRG:
+			tmp32 = chan->address - AD9910_CHAN_IDX_DRG_FREQ;
+			if (val) {
+				tmp32 = AD9910_CFR2_DRG_ENABLE_MSK |
+					FIELD_PREP(AD9910_CFR2_DRG_DEST_MSK, tmp32);
+			} else {
+				if (tmp32 != FIELD_GET(AD9910_CFR2_DRG_DEST_MSK,
+						       st->reg[AD9910_REG_CFR2].val32))
+					return 0; /* nothing to do */
+				tmp32 = 0;
+			}
+
+			return ad9910_reg32_update(st, AD9910_REG_CFR2,
+						   AD9910_CFR2_DRG_DEST_MSK |
+						   AD9910_CFR2_DRG_ENABLE_MSK,
+						   tmp32, true);
 		default:
 			return -EINVAL;
 		}
@@ -831,22 +1108,62 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			return -EINVAL;
 		}
 	case IIO_CHAN_INFO_RAW:
-		if (val < 0)
-			return -EINVAL;
-
 		switch (chan->channel) {
 		case AD9910_CHANNEL_PROFILE_0 ... AD9910_CHANNEL_PROFILE_7:
+			if (val < 0)
+				return -EINVAL;
+
 			tmp32 = chan->channel - AD9910_CHANNEL_PROFILE_0;
 			tmp64 = FIELD_PREP(AD9910_PROFILE_ST_ASF_MSK,
 					   min_t(u64, val, AD9910_ASF_MAX));
 			return ad9910_reg64_update(st, AD9910_REG_PROFILE(tmp32),
 						   AD9910_PROFILE_ST_ASF_MSK,
 						   tmp64, true);
+		case AD9910_CHANNEL_DRG_RAMP_UP:
+			tmp64 = iio_val_s64_compose(val, val2);
+			tmp64 = min_t(u64, tmp64, U32_MAX);
+			tmp64 = FIELD_PREP(AD9910_DRG_LIMIT_UPPER_MSK, tmp64);
+			return ad9910_reg64_update(st, AD9910_REG_DRG_LIMIT,
+						   AD9910_DRG_LIMIT_UPPER_MSK,
+						   tmp64, true);
+		case AD9910_CHANNEL_DRG_RAMP_DOWN:
+			tmp64 = iio_val_s64_compose(val, val2);
+			tmp64 = min_t(u64, tmp64, U32_MAX);
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
+		if (val < 0 || val2 < 0 || val > st->data.sysclk_freq_hz / 4)
+			return -EINVAL;
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
 	case IIO_CHAN_INFO_SCALE:
 		switch (chan->address) {
 		case AD9910_CHAN_IDX_PHY:
@@ -924,11 +1241,16 @@ static int ad9910_write_raw_get_fmt(struct iio_dev *indio_dev,
 		switch (chan->channel) {
 		case AD9910_CHANNEL_PROFILE_0 ... AD9910_CHANNEL_PROFILE_7:
 			return IIO_VAL_INT;
+		case AD9910_CHANNEL_DRG_RAMP_UP:
+		case AD9910_CHANNEL_DRG_RAMP_DOWN:
+			return IIO_VAL_INT_64;
 		default:
 			return -EINVAL;
 		}
 	case IIO_CHAN_INFO_SAMP_FREQ:
-		return IIO_VAL_INT;
+		if (chan->channel == AD9910_CHANNEL_PHY)
+			return IIO_VAL_INT;
+		return IIO_VAL_INT_PLUS_MICRO;
 	case IIO_CHAN_INFO_SCALE:
 		return IIO_VAL_INT_PLUS_NANO;
 	case IIO_CHAN_INFO_OFFSET:
@@ -999,6 +1321,11 @@ static const char * const ad9910_channel_str[] = {
 	[AD9910_CHAN_IDX_PARALLEL_FREQ] = "parallel_frequency",
 	[AD9910_CHAN_IDX_PARALLEL_POLAR_AMP] = "parallel_polar_amplitude",
 	[AD9910_CHAN_IDX_PARALLEL_POLAR_PHASE] = "parallel_polar_phase",
+	[AD9910_CHAN_IDX_DRG_FREQ] = "drg_frequency",
+	[AD9910_CHAN_IDX_DRG_PHASE] = "drg_phase",
+	[AD9910_CHAN_IDX_DRG_AMP] = "drg_amplitude",
+	[AD9910_CHAN_IDX_DRG_AMP_RAMP_UP] = "drg_rising",
+	[AD9910_CHAN_IDX_DRG_AMP_RAMP_DOWN] = "drg_falling",
 };
 
 static int ad9910_read_label(struct iio_dev *indio_dev,
@@ -1133,6 +1460,14 @@ static int ad9910_setup(struct device *dev, struct ad9910_state *st,
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

