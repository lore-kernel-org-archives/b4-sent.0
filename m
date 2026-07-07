From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 07 Jul 2026 15:04:32 +0100
Subject: [PATCH v7 11/17] iio: frequency: ad9910: add basic parallel port
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260707-ad9910-iio-driver-v7-11-a4ec30f63700@analog.com>
References: <20260707-ad9910-iio-driver-v7-0-a4ec30f63700@analog.com>
In-Reply-To: <20260707-ad9910-iio-driver-v7-0-a4ec30f63700@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783433065; l=9245;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=nD3/cIViXBmbznilUhfzzPn+Qg83sDJvXdscdNp4lNk=;
 b=fW0tB5CYLm7gGxehwZ0hV6kqBqB5KWsaJIOGZYhfZKa3ibjokGNG88LlgBIk8uTsby0cqGNDS
 OrC8Z8J3qI3ABuKIUQMiBXDDfQ1z8CoB24qCXizW9gEbJzhAyRM+M7D
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add parallel port support with amplitude, phase and frequency channels.
Those will be buffered capable channels, but only basic control of offset
and scale are implemented at this point. There are separate amplitude
and phase control for polar destination, which will provide different scan
types. Enabling and disabling of parallel mode will be implemented with
buffer setup ops or with update_scan_mode() once IIO backend integration
is in place.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/ad9910.c | 154 +++++++++++++++++++++++++++++++++++++++++
 1 file changed, 154 insertions(+)

diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index 900c0323a173..78a0de9dc4ce 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -112,9 +112,13 @@
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
@@ -138,7 +142,9 @@
 #define AD9910_MAX_PHASE_MICRORAD	(AD9910_PI_NANORAD / 500)
 
 #define AD9910_ASF_MAX			FIELD_MAX(AD9910_PROFILE_ST_ASF_MSK)
+#define AD9910_ASF_PP_LSB_MAX		FIELD_MAX(AD9910_ASF_SCALE_FACTOR_PP_LSB_MSK)
 #define AD9910_POW_MAX			FIELD_MAX(AD9910_PROFILE_ST_POW_MSK)
+#define AD9910_POW_PP_LSB_MAX		FIELD_MAX(AD9910_POW_PP_LSB_MSK)
 #define AD9910_NUM_PROFILES		8
 
 /* PLL constants */
@@ -193,6 +199,8 @@
  * @AD9910_CHANNEL_PROFILE_5: Profile 5 output channel
  * @AD9910_CHANNEL_PROFILE_6: Profile 6 output channel
  * @AD9910_CHANNEL_PROFILE_7: Profile 7 output channel
+ * @AD9910_CHANNEL_PARALLEL: Parallel Data output channel
+ * @AD9910_CHANNEL_PARALLEL_POLAR: Parallel Polar Data output channel
  */
 enum ad9910_channel {
 	AD9910_CHANNEL_PHY = 100,
@@ -204,6 +212,8 @@ enum ad9910_channel {
 	AD9910_CHANNEL_PROFILE_5 = 115,
 	AD9910_CHANNEL_PROFILE_6 = 116,
 	AD9910_CHANNEL_PROFILE_7 = 117,
+	AD9910_CHANNEL_PARALLEL = 120,
+	AD9910_CHANNEL_PARALLEL_POLAR = 121,
 };
 
 enum {
@@ -216,6 +226,11 @@ enum {
 	AD9910_CHAN_IDX_PROFILE_5,
 	AD9910_CHAN_IDX_PROFILE_6,
 	AD9910_CHAN_IDX_PROFILE_7,
+	AD9910_CHAN_IDX_PARALLEL_AMP,
+	AD9910_CHAN_IDX_PARALLEL_PHASE,
+	AD9910_CHAN_IDX_PARALLEL_FREQ,
+	AD9910_CHAN_IDX_PARALLEL_POLAR_AMP,
+	AD9910_CHAN_IDX_PARALLEL_POLAR_PHASE,
 };
 
 enum {
@@ -575,6 +590,53 @@ static const struct iio_chan_spec ad9910_channels[] = {
 	[AD9910_CHAN_IDX_PROFILE_5] = AD9910_PROFILE_CHAN(5),
 	[AD9910_CHAN_IDX_PROFILE_6] = AD9910_PROFILE_CHAN(6),
 	[AD9910_CHAN_IDX_PROFILE_7] = AD9910_PROFILE_CHAN(7),
+	[AD9910_CHAN_IDX_PARALLEL_AMP] = {
+		.type = IIO_ALTCURRENT,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_PARALLEL,
+		.address = AD9910_CHAN_IDX_PARALLEL_AMP,
+		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
+	},
+	[AD9910_CHAN_IDX_PARALLEL_PHASE] = {
+		.type = IIO_PHASE,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_PARALLEL,
+		.address = AD9910_CHAN_IDX_PARALLEL_PHASE,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_SCALE),
+		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
+	},
+	[AD9910_CHAN_IDX_PARALLEL_FREQ] = {
+		.type = IIO_FREQUENCY,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_PARALLEL,
+		.address = AD9910_CHAN_IDX_PARALLEL_FREQ,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_OFFSET) |
+				      BIT(IIO_CHAN_INFO_SCALE),
+		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
+	},
+	[AD9910_CHAN_IDX_PARALLEL_POLAR_AMP] = {
+		.type = IIO_ALTCURRENT,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_PARALLEL_POLAR,
+		.address = AD9910_CHAN_IDX_PARALLEL_POLAR_AMP,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_OFFSET) |
+				      BIT(IIO_CHAN_INFO_SCALE),
+		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
+	},
+	[AD9910_CHAN_IDX_PARALLEL_POLAR_PHASE] = {
+		.type = IIO_PHASE,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_PARALLEL_POLAR,
+		.address = AD9910_CHAN_IDX_PARALLEL_POLAR_PHASE,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_OFFSET) |
+				      BIT(IIO_CHAN_INFO_SCALE),
+		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
+	},
 };
 
 static int ad9910_read_raw(struct iio_dev *indio_dev,
@@ -656,6 +718,48 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 			*val = 0;
 			*val2 = tmp64 >> 14;
 			return IIO_VAL_INT_PLUS_NANO;
+		case AD9910_CHAN_IDX_PARALLEL_PHASE:
+			*val = 0;
+			*val2 = AD9910_PI_NANORAD >> 15;
+			return IIO_VAL_INT_PLUS_NANO;
+		case AD9910_CHAN_IDX_PARALLEL_FREQ:
+			tmp32 = FIELD_GET(AD9910_CFR2_FM_GAIN_MSK,
+					  st->reg[AD9910_REG_CFR2].val32);
+			tmp64 = (u64)st->data.sysclk_freq_hz << tmp32;
+			tmp64 = ad9910_rational_scale(tmp64, NANO, BIT_ULL(32));
+			*val = div_s64_rem(tmp64, NANO, val2);
+			return IIO_VAL_INT_PLUS_NANO;
+		case AD9910_CHAN_IDX_PARALLEL_POLAR_AMP:
+			tmp64 = (u64)st->data.output_current_uA *
+				AD9910_NANO_MILLIAMP_PER_MICROAMP;
+			*val = 0;
+			*val2 = tmp64 >> 8;
+			return IIO_VAL_INT_PLUS_NANO;
+		case AD9910_CHAN_IDX_PARALLEL_POLAR_PHASE:
+			*val = 0;
+			*val2 = AD9910_PI_NANORAD >> 7;
+			return IIO_VAL_INT_PLUS_NANO;
+		default:
+			return -EINVAL;
+		}
+	case IIO_CHAN_INFO_OFFSET:
+		switch (chan->address) {
+		case AD9910_CHAN_IDX_PARALLEL_FREQ:
+			tmp64 = (u64)st->reg[AD9910_REG_FTW].val32 * MICRO;
+			tmp64 >>= FIELD_GET(AD9910_CFR2_FM_GAIN_MSK,
+					    st->reg[AD9910_REG_CFR2].val32);
+			iio_val_s64_decompose(tmp64, val, val2);
+			return IIO_VAL_DECIMAL64_MICRO;
+		case AD9910_CHAN_IDX_PARALLEL_POLAR_AMP:
+			tmp32 = FIELD_GET(AD9910_ASF_SCALE_FACTOR_PP_LSB_MSK,
+					  st->reg[AD9910_REG_ASF].val32);
+			iio_val_s64_decompose(MICRO * tmp32 >> 6, val, val2);
+			return IIO_VAL_DECIMAL64_MICRO;
+		case AD9910_CHAN_IDX_PARALLEL_POLAR_PHASE:
+			tmp32 = FIELD_GET(AD9910_POW_PP_LSB_MSK,
+					  st->reg[AD9910_REG_POW].val16);
+			iio_val_s64_decompose(MICRO * tmp32 >> 8, val, val2);
+			return IIO_VAL_DECIMAL64_MICRO;
 		default:
 			return -EINVAL;
 		}
@@ -759,9 +863,52 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			tmp32 = DIV_U64_ROUND_CLOSEST((u64)val2 << 14,
 						      AD9910_NANO_MILLIAMP_PER_MICROAMP);
 			return ad9910_set_dac_current(st, tmp32, true);
+		case AD9910_CHAN_IDX_PARALLEL_FREQ:
+			if (val < 0 || val2 < 0)
+				return -EINVAL;
+
+			tmp64 = ad9910_rational_scale((u64)val * NANO + val2, BIT_ULL(32),
+						      (u64)st->data.sysclk_freq_hz * NANO);
+			tmp64 = roundup_pow_of_two(clamp(tmp64, 1ULL, BIT_ULL(15)));
+			tmp32 = FIELD_PREP(AD9910_CFR2_FM_GAIN_MSK, ilog2(tmp64));
+			return ad9910_reg32_update(st, AD9910_REG_CFR2,
+						   AD9910_CFR2_FM_GAIN_MSK,
+						   tmp32, true);
 		default:
 			return -EINVAL;
 		}
+	case IIO_CHAN_INFO_OFFSET: {
+		s64 val64 = iio_val_s64_compose(val, val2);
+
+		if (val64 < 0)
+			return -EINVAL;
+
+		tmp64 = val64;
+		switch (chan->address) {
+		case AD9910_CHAN_IDX_PARALLEL_FREQ:
+			tmp32 = BIT(FIELD_GET(AD9910_CFR2_FM_GAIN_MSK,
+					      st->reg[AD9910_REG_CFR2].val32));
+			tmp64 = ad9910_rational_scale(tmp64, tmp32, MICRO);
+			tmp64 = min_t(u64, tmp64, U32_MAX);
+			return ad9910_reg32_write(st, AD9910_REG_FTW, tmp64, true);
+		case AD9910_CHAN_IDX_PARALLEL_POLAR_AMP:
+			tmp64 = ad9910_rational_scale(tmp64, BIT(6), MICRO);
+			tmp64 = min_t(u64, tmp64, AD9910_ASF_PP_LSB_MAX);
+			tmp32 = FIELD_PREP(AD9910_ASF_SCALE_FACTOR_PP_LSB_MSK, tmp64);
+			return ad9910_reg32_update(st, AD9910_REG_ASF,
+						   AD9910_ASF_SCALE_FACTOR_PP_LSB_MSK,
+						   tmp32, true);
+		case AD9910_CHAN_IDX_PARALLEL_POLAR_PHASE:
+			tmp64 = ad9910_rational_scale(tmp64, BIT(8), MICRO);
+			tmp64 = min_t(u64, tmp64, AD9910_POW_PP_LSB_MAX);
+			tmp32 = FIELD_PREP(AD9910_POW_PP_LSB_MSK, tmp64);
+			return ad9910_reg16_update(st, AD9910_REG_POW,
+						   AD9910_POW_PP_LSB_MSK,
+						   tmp32, true);
+		default:
+			return -EINVAL;
+		}
+	}
 	default:
 		return -EINVAL;
 	}
@@ -788,6 +935,8 @@ static int ad9910_write_raw_get_fmt(struct iio_dev *indio_dev,
 		return IIO_VAL_INT;
 	case IIO_CHAN_INFO_SCALE:
 		return IIO_VAL_INT_PLUS_NANO;
+	case IIO_CHAN_INFO_OFFSET:
+		return IIO_VAL_DECIMAL64_MICRO;
 	default:
 		return -EINVAL;
 	}
@@ -849,6 +998,11 @@ static const char * const ad9910_channel_str[] = {
 	[AD9910_CHAN_IDX_PROFILE_5] = "profile5",
 	[AD9910_CHAN_IDX_PROFILE_6] = "profile6",
 	[AD9910_CHAN_IDX_PROFILE_7] = "profile7",
+	[AD9910_CHAN_IDX_PARALLEL_AMP] = "parallel_amplitude",
+	[AD9910_CHAN_IDX_PARALLEL_PHASE] = "parallel_phase",
+	[AD9910_CHAN_IDX_PARALLEL_FREQ] = "parallel_frequency",
+	[AD9910_CHAN_IDX_PARALLEL_POLAR_AMP] = "parallel_polar_amplitude",
+	[AD9910_CHAN_IDX_PARALLEL_POLAR_PHASE] = "parallel_polar_phase",
 };
 
 static int ad9910_read_label(struct iio_dev *indio_dev,

-- 
2.43.0

