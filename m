From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Sun, 17 May 2026 19:37:54 +0100
Subject: [PATCH v5 10/13] iio: frequency: ad9910: add output shift keying
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260517-ad9910-iio-driver-v5-10-31599c88314a@analog.com>
References: <20260517-ad9910-iio-driver-v5-0-31599c88314a@analog.com>
In-Reply-To: <20260517-ad9910-iio-driver-v5-0-31599c88314a@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779043094; l=11061;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=pnDIOx00dJa84RQDwArtfVFkLSpBVu3NlwOnM1swaFE=;
 b=l4bqhC/wgW/pZvD8tkZvgVDYePOpLobntAUVBtPPUFjPcWYkCiyRmoGiPMe2pFwItBYyc9eBu
 NKP5G+6kEn+DNFc+Sh3A36M0VCN2UYnDwlQRInuRBCxhaYi9wHT/BLZ
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add OSK channel with amplitude envelope control capabilities:
- OSK enable/disable via IIO_CHAN_INFO_ENABLE;
- Amplitude ramp rate control via IIO_CHAN_INFO_SAMP_FREQ;
- Amplitude scale readback via IIO_CHAN_INFO_SCALE (ASF register);
- Automatic OSK step size configurable through the scale_roc extended
  attribute, which allows for selectable step sizes in nano-units:
	- 0: no step, means manual mode (NOT pin controlled)
	- 61035: 1/2^14 step, automatic mode (pin controlled)
	- 122070: 2/2^14 step, automatic mode (pin controlled)
	- 244141: 4/2^14 step, automatic mode (pin controlled)
	- 488281: 8/2^14 step, automatic mode (pin controlled)
	- 1000000000: 1.0 step (max), manual mode (pin controlled)

The ASF register is initialized with a default amplitude ramp rate during
device setup to ensure valid readback.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/ad9910.c | 203 +++++++++++++++++++++++++++++++++++++++++
 1 file changed, 203 insertions(+)

diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index 86ed350011cf..91f28c7de68b 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -235,6 +235,7 @@
  * @AD9910_CHANNEL_DRG_RAMP_UP: DRG ramp up channel
  * @AD9910_CHANNEL_DRG_RAMP_DOWN: DRG ramp down channel
  * @AD9910_CHANNEL_RAM: RAM control output channel
+ * @AD9910_CHANNEL_OSK: Output Shift Keying output channel
  */
 enum ad9910_channel {
 	AD9910_CHANNEL_PHY = 100,
@@ -251,6 +252,7 @@ enum ad9910_channel {
 	AD9910_CHANNEL_DRG_RAMP_UP = 131,
 	AD9910_CHANNEL_DRG_RAMP_DOWN = 132,
 	AD9910_CHANNEL_RAM = 140,
+	AD9910_CHANNEL_OSK = 150,
 };
 
 /**
@@ -306,6 +308,7 @@ enum {
 	AD9910_CHAN_IDX_DRG_RAMP_UP,
 	AD9910_CHAN_IDX_DRG_RAMP_DOWN,
 	AD9910_CHAN_IDX_RAM,
+	AD9910_CHAN_IDX_OSK,
 };
 
 enum {
@@ -318,6 +321,8 @@ enum {
 	AD9910_DRG_PHASE_ROC,
 	AD9910_DRG_AMP_ROC,
 	AD9910_DRG_DWELL_EN,
+	AD9910_OSK_AUTO_ROC,
+	AD9910_OSK_AUTO_ROC_AVAIL,
 };
 
 struct ad9910_data {
@@ -977,6 +982,135 @@ static ssize_t ad9910_drg_attrs_write(struct iio_dev *indio_dev,
 	return len;
 }
 
+static const u32 ad9910_osk_nstep[] = {
+	0,	/* no step: manual mode (NOT pin controlled) */
+	61035,	/* 1/2^14 step: automatic mode (pin controlled) */
+	122070,	/* 2/2^14 step: automatic mode (pin controlled) */
+	244141,	/* 4/2^14 step: automatic mode (pin controlled) */
+	488281,	/* 8/2^14 step: automatic mode (pin controlled) */
+	NANO,	/* full scale step: manual mode (pin controlled) */
+};
+
+static ssize_t ad9910_osk_attrs_read(struct iio_dev *indio_dev,
+				     uintptr_t private,
+				     const struct iio_chan_spec *chan,
+				     char *buf)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+	bool auto_en, pinctrl_en;
+	u32 rate, step;
+	int vals[2];
+	u64 roc64;
+
+	guard(mutex)(&st->lock);
+
+	rate = 4 * FIELD_GET(AD9910_ASF_RAMP_RATE_MSK,
+			     st->reg[AD9910_REG_ASF].val32);
+	if (!rate)
+		return -ERANGE;
+
+	switch (private) {
+	case AD9910_OSK_AUTO_ROC:
+		auto_en = FIELD_GET(AD9910_CFR1_SELECT_AUTO_OSK_MSK,
+				    st->reg[AD9910_REG_CFR1].val32);
+		pinctrl_en = FIELD_GET(AD9910_CFR1_OSK_MANUAL_EXT_CTL_MSK,
+				       st->reg[AD9910_REG_CFR1].val32);
+		if (auto_en) {
+			step = FIELD_GET(AD9910_ASF_STEP_SIZE_MSK,
+					 st->reg[AD9910_REG_ASF].val32);
+			step = ad9910_osk_nstep[step + 1];
+		} else if (pinctrl_en) {
+			step = ad9910_osk_nstep[ARRAY_SIZE(ad9910_osk_nstep) - 1];
+		} else {
+			step = ad9910_osk_nstep[0];
+		}
+
+		roc64 = div_u64((u64)step * st->data.sysclk_freq_hz, rate);
+		vals[0] = div_s64_rem(roc64, NANO, &vals[1]);
+		return iio_format_value(buf, IIO_VAL_INT_PLUS_NANO,
+					ARRAY_SIZE(vals), vals);
+	case AD9910_OSK_AUTO_ROC_AVAIL: {
+		ssize_t len = 0;
+
+		for (unsigned int i = 0; i < ARRAY_SIZE(ad9910_osk_nstep); i++) {
+			roc64 = div_u64((u64)ad9910_osk_nstep[i] *
+					st->data.sysclk_freq_hz, rate);
+			vals[0] = div_s64_rem(roc64, NANO, &vals[1]);
+			if (!vals[1])
+				len += sysfs_emit_at(buf, len, "%d ", vals[0]);
+			else
+				len += sysfs_emit_at(buf, len, "%d.%09d ",
+						     vals[0], vals[1]);
+		}
+
+		buf[len - 1] = '\n'; /* replace last space with a newline */
+		return len;
+	}
+	default:
+		return -EINVAL;
+	}
+}
+
+static ssize_t ad9910_osk_attrs_write(struct iio_dev *indio_dev,
+				      uintptr_t private,
+				      const struct iio_chan_spec *chan,
+				      const char *buf, size_t len)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+	int val, val2, ret;
+	u32 idx, cfg, rate;
+	u64 nstep;
+
+	ret = iio_str_to_fixpoint(buf, NANO / 10, &val, &val2);
+	if (ret)
+		return ret;
+
+	if (val < 0 || val2 < 0)
+		return -EINVAL;
+
+	guard(mutex)(&st->lock);
+
+	rate = 4 * FIELD_GET(AD9910_ASF_RAMP_RATE_MSK,
+			     st->reg[AD9910_REG_ASF].val32);
+	if (!rate)
+		return -ERANGE;
+
+	switch (private) {
+	case AD9910_OSK_AUTO_ROC:
+		nstep = ad9910_rational_scale((u64)val * NANO + val2, rate,
+					      st->data.sysclk_freq_hz);
+		nstep = min(nstep, NANO);
+		idx = find_closest(nstep, ad9910_osk_nstep,
+				   ARRAY_SIZE(ad9910_osk_nstep));
+		if (idx == ARRAY_SIZE(ad9910_osk_nstep) - 1) {
+			cfg = AD9910_CFR1_OSK_MANUAL_EXT_CTL_MSK;
+		} else if (idx == 0) {
+			cfg = 0;
+		} else {
+			cfg = FIELD_PREP(AD9910_ASF_STEP_SIZE_MSK, idx - 1);
+			ret = ad9910_reg32_update(st, AD9910_REG_ASF,
+						  AD9910_ASF_STEP_SIZE_MSK,
+						  cfg, false);
+			if (ret)
+				return ret;
+
+			cfg = AD9910_CFR1_SELECT_AUTO_OSK_MSK;
+		}
+
+		ret = ad9910_reg32_update(st, AD9910_REG_CFR1,
+					  AD9910_CFR1_SELECT_AUTO_OSK_MSK |
+					  AD9910_CFR1_OSK_MANUAL_EXT_CTL_MSK,
+					  cfg, true);
+		if (ret)
+			return ret;
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	return len;
+}
+
 #define AD9910_EXT_INFO_TMPL(_name, _ident, _shared, _fn_desc) { \
 	.name = _name, \
 	.read = ad9910_ ## _fn_desc ## _read, \
@@ -1015,6 +1149,23 @@ static const struct iio_chan_spec_ext_info ad9910_drg_ramp_ext_info[] = {
 	{ }
 };
 
+static const struct iio_chan_spec_ext_info ad9910_osk_ext_info[] = {
+	{
+		.name = "scale_roc",
+		.read = ad9910_osk_attrs_read,
+		.write = ad9910_osk_attrs_write,
+		.private = AD9910_OSK_AUTO_ROC,
+		.shared = IIO_SEPARATE,
+	},
+	{
+		.name = "scale_roc_available",
+		.read = ad9910_osk_attrs_read,
+		.private = AD9910_OSK_AUTO_ROC_AVAIL,
+		.shared = IIO_SEPARATE,
+	},
+	{ }
+};
+
 #define AD9910_PROFILE_CHAN(idx) {				\
 	.type = IIO_ALTVOLTAGE,					\
 	.indexed = 1,						\
@@ -1102,6 +1253,18 @@ static const struct iio_chan_spec ad9910_channels[] = {
 				      BIT(IIO_CHAN_INFO_SAMP_FREQ),
 		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
 	},
+	[AD9910_CHAN_IDX_OSK] = {
+		.type = IIO_ALTVOLTAGE,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_OSK,
+		.address = AD9910_CHAN_IDX_OSK,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE) |
+				      BIT(IIO_CHAN_INFO_SCALE) |
+				      BIT(IIO_CHAN_INFO_SAMP_FREQ),
+		.ext_info = ad9910_osk_ext_info,
+		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
+	},
 };
 
 static int ad9910_read_raw(struct iio_dev *indio_dev,
@@ -1134,6 +1297,10 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 			*val = FIELD_GET(AD9910_CFR1_RAM_ENABLE_MSK,
 					 st->reg[AD9910_REG_CFR1].val32);
 			break;
+		case AD9910_CHANNEL_OSK:
+			*val = FIELD_GET(AD9910_CFR1_OSK_ENABLE_MSK,
+					 st->reg[AD9910_REG_CFR1].val32);
+			break;
 		default:
 			return -EINVAL;
 		}
@@ -1239,6 +1406,12 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 			*val = 0;
 			*val2 = tmp64 * NANO >> 32;
 			return IIO_VAL_INT_PLUS_NANO;
+		case AD9910_CHANNEL_OSK:
+			tmp64 = FIELD_GET(AD9910_ASF_SCALE_FACTOR_MSK,
+					  st->reg[AD9910_REG_ASF].val32);
+			*val = 0;
+			*val2 = tmp64 * MICRO >> 14;
+			return IIO_VAL_INT_PLUS_MICRO;
 		default:
 			return -EINVAL;
 		}
@@ -1259,6 +1432,10 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 			tmp32 = FIELD_GET(AD9910_PROFILE_RAM_STEP_RATE_MSK,
 					  ad9910_ram_profile_val(st));
 			break;
+		case AD9910_CHANNEL_OSK:
+			tmp32 = FIELD_GET(AD9910_ASF_RAMP_RATE_MSK,
+					  st->reg[AD9910_REG_ASF].val32);
+			break;
 		default:
 			return -EINVAL;
 		}
@@ -1341,6 +1518,11 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			return ad9910_reg32_update(st, AD9910_REG_CFR1,
 						   AD9910_CFR1_RAM_ENABLE_MSK,
 						   tmp32, true);
+		case AD9910_CHANNEL_OSK:
+			tmp32 = FIELD_PREP(AD9910_CFR1_OSK_ENABLE_MSK, !!val);
+			return ad9910_reg32_update(st, AD9910_REG_CFR1,
+						   AD9910_CFR1_OSK_ENABLE_MSK,
+						   tmp32, true);
 		default:
 			return -EINVAL;
 		}
@@ -1510,6 +1692,14 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			return ad9910_reg64_update(st, AD9910_REG_DRG_LIMIT,
 						   AD9910_DRG_LIMIT_LOWER_MSK,
 						   tmp64, true);
+		case AD9910_CHANNEL_OSK:
+			tmp64 = ((u64)val * MICRO + val2) << 14;
+			tmp64 = DIV_U64_ROUND_CLOSEST(tmp64, MICRO);
+			tmp32 = min(tmp64, AD9910_ASF_MAX);
+			tmp32 = FIELD_PREP(AD9910_ASF_SCALE_FACTOR_MSK, tmp32);
+			return ad9910_reg32_update(st, AD9910_REG_ASF,
+						   AD9910_ASF_SCALE_FACTOR_MSK,
+						   tmp32, true);
 		default:
 			return -EINVAL;
 		}
@@ -1549,6 +1739,11 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			return ad9910_reg64_update(st, AD9910_REG_PROFILE(st->profile),
 						   AD9910_PROFILE_RAM_STEP_RATE_MSK,
 						   tmp64, true);
+		case AD9910_CHANNEL_OSK:
+			return ad9910_reg32_update(st, AD9910_REG_ASF,
+						   AD9910_ASF_RAMP_RATE_MSK,
+						   FIELD_PREP(AD9910_ASF_RAMP_RATE_MSK, tmp32),
+						   true);
 		default:
 			return -EINVAL;
 		}
@@ -1571,6 +1766,7 @@ static int ad9910_write_raw_get_fmt(struct iio_dev *indio_dev,
 		switch (chan->channel) {
 		case AD9910_CHANNEL_PROFILE_0 ... AD9910_CHANNEL_PROFILE_7:
 		case AD9910_CHANNEL_RAM:
+		case AD9910_CHANNEL_OSK:
 			return IIO_VAL_INT_PLUS_MICRO;
 		case AD9910_CHANNEL_DRG_RAMP_UP:
 		case AD9910_CHANNEL_DRG_RAMP_DOWN:
@@ -1648,6 +1844,7 @@ static const char * const ad9910_channel_str[] = {
 	[AD9910_CHAN_IDX_DRG_RAMP_UP] = "digital_ramp_up",
 	[AD9910_CHAN_IDX_DRG_RAMP_DOWN] = "digital_ramp_down",
 	[AD9910_CHAN_IDX_RAM] = "ram_control",
+	[AD9910_CHAN_IDX_OSK] = "output_shift_keying",
 };
 
 static int ad9910_read_label(struct iio_dev *indio_dev,
@@ -1896,6 +2093,12 @@ static int ad9910_setup(struct device *dev, struct ad9910_state *st,
 		return ret;
 
 	/* configure step rate with default values */
+	ret = ad9910_reg32_write(st, AD9910_REG_ASF,
+				 FIELD_PREP(AD9910_ASF_RAMP_RATE_MSK, 1),
+				 false);
+	if (ret)
+		return ret;
+
 	ret = ad9910_reg32_write(st, AD9910_REG_DRG_RATE,
 				 FIELD_PREP(AD9910_DRG_RATE_DEC_MSK, 1) |
 				 FIELD_PREP(AD9910_DRG_RATE_INC_MSK, 1),

-- 
2.43.0

