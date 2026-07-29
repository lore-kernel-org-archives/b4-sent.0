From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 29 Jul 2026 09:25:41 +0100
Subject: [PATCH v10 14/17] iio: frequency: ad9910: add output shift keying
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-ad9910-iio-driver-v10-14-aa1f6167729e@analog.com>
References: <20260729-ad9910-iio-driver-v10-0-aa1f6167729e@analog.com>
In-Reply-To: <20260729-ad9910-iio-driver-v10-0-aa1f6167729e@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785313627; l=10549;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=s4Oe+gYQYeYV5p2WoRGVToDuRzT8SWRaSOa/L2DMflc=;
 b=pE2A4pT+8zEOrKQ8K4KSjnMjLq17PE0CtHkHrzc9hV8PoYIgIltF6iGoEeYi/AbwmpVq9ZKlf
 AANcCSwI1vQAPWgj4s50E+L4NEs0lCu5PGvWWwIeMg79gzJPyusrQr6
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add OSK channel with amplitude envelope control capabilities:
- OSK enable/disable via IIO_CHAN_INFO_ENABLE;
- Amplitude ramp rate control via IIO_CHAN_INFO_SAMP_FREQ;
- Amplitude scale factor readback via IIO_CHAN_INFO_RAW (ASF register);
- Automatic OSK step size configurable through the raw_roc extended
  attribute, which allows for selectable step sizes in raw units:
	- 0: no step, means manual mode (NOT pin controlled)
	- 1: I_FS / 2^14 step, automatic mode (pin controlled)
	- 2: 2 I_FS / 2^14 step, automatic mode (pin controlled)
	- 4: 4 I_FS / 2^14 step, automatic mode (pin controlled)
	- 8: 8 I_FS / 2^14 step, automatic mode (pin controlled)
	- 16383: I_FS step (max), manual mode (pin controlled)

The ASF register is initialized with a default amplitude ramp rate during
device setup to ensure valid readback.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/ad9910.c | 191 +++++++++++++++++++++++++++++++++++++++++
 1 file changed, 191 insertions(+)

diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index d4f89fd44933..e1aacb191730 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -252,6 +252,7 @@
  * @AD9910_CHANNEL_DRG_RAMP_UP: DRG ramp up channel
  * @AD9910_CHANNEL_DRG_RAMP_DOWN: DRG ramp down channel
  * @AD9910_CHANNEL_RAM: RAM control output channel
+ * @AD9910_CHANNEL_OSK: Output Shift Keying output channel
  */
 enum ad9910_channel {
 	AD9910_CHANNEL_PHY = 100,
@@ -269,6 +270,7 @@ enum ad9910_channel {
 	AD9910_CHANNEL_DRG_RAMP_UP = 131,
 	AD9910_CHANNEL_DRG_RAMP_DOWN = 132,
 	AD9910_CHANNEL_RAM = 140,
+	AD9910_CHANNEL_OSK = 150,
 };
 
 /**
@@ -319,12 +321,14 @@ enum {
 	AD9910_CHAN_IDX_DRG_AMP_RAMP_UP,
 	AD9910_CHAN_IDX_DRG_AMP_RAMP_DOWN,
 	AD9910_CHAN_IDX_RAM,
+	AD9910_CHAN_IDX_OSK,
 };
 
 enum {
 	AD9910_POWERDOWN,
 	AD9910_DWELL_EN,
 	AD9910_ROC,
+	AD9910_ROC_AVAIL,
 };
 
 struct ad9910_data {
@@ -804,6 +808,125 @@ static ssize_t ad9910_drg_roc_write(struct iio_dev *indio_dev,
 	return len;
 }
 
+static const u32 ad9910_osk_raw_step[] = {
+	0,		/* no step: manual mode (NOT pin controlled) */
+	1,		/* step size 1: automatic mode (pin controlled) */
+	2,		/* step size 2: automatic mode (pin controlled) */
+	4,		/* step size 4: automatic mode (pin controlled) */
+	8,		/* step size 8: automatic mode (pin controlled) */
+	GENMASK(13, 0),	/* max step: manual mode (pin controlled) */
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
+	u64 roc64;
+
+	guard(mutex)(&st->lock);
+
+	rate = FIELD_GET(AD9910_ASF_RAMP_RATE_MSK, st->reg[AD9910_REG_ASF].val32);
+	if (!rate)
+		return -ERANGE;
+
+	switch (private) {
+	case AD9910_ROC:
+		auto_en = FIELD_GET(AD9910_CFR1_SELECT_AUTO_OSK_MSK,
+				    st->reg[AD9910_REG_CFR1].val32);
+		pinctrl_en = FIELD_GET(AD9910_CFR1_OSK_MANUAL_EXT_CTL_MSK,
+				       st->reg[AD9910_REG_CFR1].val32);
+		if (auto_en) {
+			step = FIELD_GET(AD9910_ASF_STEP_SIZE_MSK,
+					 st->reg[AD9910_REG_ASF].val32);
+			step = ad9910_osk_raw_step[step + 1];
+		} else if (pinctrl_en) {
+			step = ad9910_osk_raw_step[ARRAY_SIZE(ad9910_osk_raw_step) - 1];
+		} else {
+			step = ad9910_osk_raw_step[0];
+		}
+
+		roc64 = div_u64((u64)step * st->data.sysclk_freq_hz, 4 * rate);
+		return sysfs_emit(buf, "%llu\n", roc64);
+	case AD9910_ROC_AVAIL: {
+		ssize_t len = 0;
+
+		for (unsigned int i = 0; i < ARRAY_SIZE(ad9910_osk_raw_step); i++) {
+			roc64 = div_u64((u64)ad9910_osk_raw_step[i] * st->data.sysclk_freq_hz,
+					4 * rate);
+			len += sysfs_emit_at(buf, len, "%llu ", roc64);
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
+	u32 idx, reg_val, rate;
+	u64 step;
+	int ret;
+
+	ret = kstrtou64(buf, 10, &step);
+	if (ret)
+		return ret;
+
+	guard(mutex)(&st->lock);
+
+	rate = FIELD_GET(AD9910_ASF_RAMP_RATE_MSK, st->reg[AD9910_REG_ASF].val32);
+	if (!rate)
+		return -ERANGE;
+
+	switch (private) {
+	case AD9910_ROC:
+		step = ad9910_rational_scale(step, 4 * rate,
+					     st->data.sysclk_freq_hz);
+		step = min(step, AD9910_ASF_MAX);
+		idx = find_closest(step, ad9910_osk_raw_step,
+				   ARRAY_SIZE(ad9910_osk_raw_step));
+		if (idx == ARRAY_SIZE(ad9910_osk_raw_step) - 1) {
+			/* manual mode: pin-controlled */
+			reg_val = AD9910_CFR1_OSK_MANUAL_EXT_CTL_MSK;
+		} else if (idx == 0) {
+			/* manual mode, NOT pin-controlled */
+			reg_val = 0;
+		} else {
+			/* auto mode: pin-controlled */
+			reg_val = FIELD_PREP(AD9910_ASF_STEP_SIZE_MSK, idx - 1);
+			ret = ad9910_reg32_update(st, AD9910_REG_ASF,
+						  AD9910_ASF_STEP_SIZE_MSK,
+						  reg_val, false);
+			if (ret)
+				return ret;
+
+			reg_val = AD9910_CFR1_SELECT_AUTO_OSK_MSK;
+		}
+
+		ret = ad9910_reg32_update(st, AD9910_REG_CFR1,
+					  AD9910_CFR1_SELECT_AUTO_OSK_MSK |
+					  AD9910_CFR1_OSK_MANUAL_EXT_CTL_MSK,
+					  reg_val, true);
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
 static const struct iio_chan_spec_ext_info ad9910_phy_ext_info[] = {
 	{
 		.name = "powerdown",
@@ -833,6 +956,23 @@ static const struct iio_chan_spec_ext_info ad9910_drg_ramp_ext_info[] = {
 	{ }
 };
 
+static const struct iio_chan_spec_ext_info ad9910_osk_ext_info[] = {
+	{
+		.name = "raw_roc",
+		.read = ad9910_osk_attrs_read,
+		.write = ad9910_osk_attrs_write,
+		.private = AD9910_ROC,
+		.shared = IIO_SEPARATE,
+	},
+	{
+		.name = "raw_roc_available",
+		.read = ad9910_osk_attrs_read,
+		.private = AD9910_ROC_AVAIL,
+		.shared = IIO_SEPARATE,
+	},
+	{ }
+};
+
 #define AD9910_PROFILE_CHAN(idx) {				\
 	.type = IIO_ALTCURRENT,					\
 	.indexed = 1,						\
@@ -1020,6 +1160,18 @@ static const struct iio_chan_spec ad9910_channels[] = {
 				      BIT(IIO_CHAN_INFO_SAMP_FREQ),
 		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
 	},
+	[AD9910_CHAN_IDX_OSK] = {
+		.type = IIO_ALTCURRENT,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_OSK,
+		.address = AD9910_CHAN_IDX_OSK,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE) |
+				      BIT(IIO_CHAN_INFO_RAW) |
+				      BIT(IIO_CHAN_INFO_SAMP_FREQ),
+		.ext_info = ad9910_osk_ext_info,
+		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
+	},
 };
 
 static int ad9910_read_raw(struct iio_dev *indio_dev,
@@ -1056,6 +1208,10 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
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
@@ -1111,6 +1267,10 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 					  st->reg[AD9910_REG_DRG_LIMIT].val64);
 			iio_val_s64_decompose(tmp64, val, val2);
 			return IIO_VAL_INT_64;
+		case AD9910_CHANNEL_OSK:
+			*val = FIELD_GET(AD9910_ASF_SCALE_FACTOR_MSK,
+					 st->reg[AD9910_REG_ASF].val32);
+			return IIO_VAL_INT;
 		default:
 			return -EINVAL;
 		}
@@ -1131,6 +1291,10 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
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
@@ -1292,6 +1456,11 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
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
@@ -1392,6 +1561,15 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 						   AD9910_DRG_LIMIT_LOWER_MSK,
 						   tmp64, true);
 		}
+		case AD9910_CHANNEL_OSK:
+			if (val < 0)
+				return -EINVAL;
+
+			tmp32 = min_t(u32, val, AD9910_ASF_MAX);
+			tmp32 = FIELD_PREP(AD9910_ASF_SCALE_FACTOR_MSK, tmp32);
+			return ad9910_reg32_update(st, AD9910_REG_ASF,
+						   AD9910_ASF_SCALE_FACTOR_MSK,
+						   tmp32, true);
 		default:
 			return -EINVAL;
 		}
@@ -1431,6 +1609,11 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
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
@@ -1507,6 +1690,7 @@ static int ad9910_write_raw_get_fmt(struct iio_dev *indio_dev,
 	case IIO_CHAN_INFO_RAW:
 		switch (chan->channel) {
 		case AD9910_CHANNEL_PROFILE_0 ... AD9910_CHANNEL_PROFILE_7:
+		case AD9910_CHANNEL_OSK:
 			return IIO_VAL_INT;
 		case AD9910_CHANNEL_DRG_RAMP_UP:
 		case AD9910_CHANNEL_DRG_RAMP_DOWN:
@@ -1598,6 +1782,7 @@ static const char * const ad9910_channel_str[] = {
 	[AD9910_CHAN_IDX_DRG_AMP_RAMP_UP] = "drg_rising_amplitude",
 	[AD9910_CHAN_IDX_DRG_AMP_RAMP_DOWN] = "drg_falling_amplitude",
 	[AD9910_CHAN_IDX_RAM] = "ram",
+	[AD9910_CHAN_IDX_OSK] = "osk",
 };
 
 static int ad9910_read_label(struct iio_dev *indio_dev,
@@ -1859,6 +2044,12 @@ static int ad9910_setup(struct device *dev, struct ad9910_state *st,
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

