From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 08 May 2026 18:00:20 +0100
Subject: [PATCH RFC v4 04/10] iio: frequency: ad9910: add basic parallel
 port support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-ad9910-iio-driver-v4-4-d26bfd20ee3d@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778259632; l=7839;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=kvZo4+/XP77JxfC4hABFIew9wF5fiYbwMIWzRex6qc4=;
 b=Bkplm+5lV0b3CK+nwOKrfGVpDhROtkElbNFA2zWdCnZM7PfcPbFjeNk6Ap/hstaDWYmbukiwz
 NCxAC/NehccAL7ZaO+ZzRSp6hi1iGKKdp1d2VEXjpenqylTwT7GNTFL
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add parallel port channel with frequency scale, frequency offset, phase
offset, and amplitude offset extended attributes for configuring the
parallel data path. Enabling and disabling of parallel mode will be
implemented with buffer setup ops when an IIO backend integration is in
place.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/ad9910.c | 153 +++++++++++++++++++++++++++++++++++++++++
 1 file changed, 153 insertions(+)

diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index c75f2ef178c2..b069b849e8d7 100644
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
 
 #define AD9910_ASF_MAX			GENMASK(13, 0)
+#define AD9910_ASF_PP_LSB_MAX		GENMASK(5, 0)
 #define AD9910_POW_MAX			GENMASK(15, 0)
+#define AD9910_POW_PP_LSB_MAX		GENMASK(7, 0)
 #define AD9910_NUM_PROFILES		8
 
 /* PLL constants */
@@ -189,6 +195,7 @@
  * @AD9910_CHANNEL_PROFILE_5: Profile 5 output channel
  * @AD9910_CHANNEL_PROFILE_6: Profile 6 output channel
  * @AD9910_CHANNEL_PROFILE_7: Profile 7 output channel
+ * @AD9910_CHANNEL_PARALLEL_PORT: Parallel Port output channel
  */
 enum ad9910_channel {
 	AD9910_CHANNEL_PHY = 100,
@@ -200,6 +207,7 @@ enum ad9910_channel {
 	AD9910_CHANNEL_PROFILE_5 = 106,
 	AD9910_CHANNEL_PROFILE_6 = 107,
 	AD9910_CHANNEL_PROFILE_7 = 108,
+	AD9910_CHANNEL_PARALLEL_PORT = 110,
 };
 
 enum {
@@ -212,10 +220,15 @@ enum {
 	AD9910_CHAN_IDX_PROFILE_5,
 	AD9910_CHAN_IDX_PROFILE_6,
 	AD9910_CHAN_IDX_PROFILE_7,
+	AD9910_CHAN_IDX_PARALLEL_PORT,
 };
 
 enum {
 	AD9910_POWERDOWN,
+	AD9910_PP_FREQ_SCALE,
+	AD9910_PP_FREQ_OFFSET,
+	AD9910_PP_PHASE_OFFSET,
+	AD9910_PP_AMP_OFFSET,
 };
 
 struct ad9910_data {
@@ -483,6 +496,10 @@ static ssize_t ad9910_ext_info_read(struct iio_dev *indio_dev,
 	case AD9910_POWERDOWN:
 		val = ad9910_sw_powerdown_get(st);
 		break;
+	case AD9910_PP_FREQ_SCALE:
+		val = BIT(FIELD_GET(AD9910_CFR2_FM_GAIN_MSK,
+				    st->reg[AD9910_REG_CFR2].val32));
+		break;
 	default:
 		return -EINVAL;
 	}
@@ -511,6 +528,121 @@ static ssize_t ad9910_ext_info_write(struct iio_dev *indio_dev,
 		if (ret)
 			return ret;
 		break;
+	case AD9910_PP_FREQ_SCALE:
+		if (val32 > BIT(15) || !is_power_of_2(val32))
+			return -EINVAL;
+
+		val32 = FIELD_PREP(AD9910_CFR2_FM_GAIN_MSK, ilog2(val32));
+		ret = ad9910_reg32_update(st, AD9910_REG_CFR2,
+					  AD9910_CFR2_FM_GAIN_MSK,
+					  val32, true);
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
+		vals[0] = tmp64 >> 32;
+		vals[1] = ((tmp64 & GENMASK_ULL(31, 0)) * MICRO) >> 32;
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
+		if (ret)
+			return ret;
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
+		if (ret)
+			return ret;
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
+		if (ret)
+			return ret;
+		break;
 	default:
 		return -EINVAL;
 	}
@@ -529,11 +661,22 @@ static ssize_t ad9910_ext_info_write(struct iio_dev *indio_dev,
 #define AD9910_EXT_INFO(_name, _ident, _shared) \
 	AD9910_EXT_INFO_TMPL(_name, _ident, _shared, ext_info)
 
+#define AD9910_PP_EXT_INFO(_name, _ident) \
+	AD9910_EXT_INFO_TMPL(_name, _ident, IIO_SEPARATE, pp_attrs)
+
 static const struct iio_chan_spec_ext_info ad9910_phy_ext_info[] = {
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
 #define AD9910_PROFILE_CHAN(idx) {				\
 	.type = IIO_ALTVOLTAGE,					\
 	.indexed = 1,						\
@@ -564,6 +707,15 @@ static const struct iio_chan_spec ad9910_channels[] = {
 	[AD9910_CHAN_IDX_PROFILE_5] = AD9910_PROFILE_CHAN(5),
 	[AD9910_CHAN_IDX_PROFILE_6] = AD9910_PROFILE_CHAN(6),
 	[AD9910_CHAN_IDX_PROFILE_7] = AD9910_PROFILE_CHAN(7),
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
@@ -816,6 +968,7 @@ static const char * const ad9910_channel_str[] = {
 	[AD9910_CHAN_IDX_PROFILE_5] = "profile[5]",
 	[AD9910_CHAN_IDX_PROFILE_6] = "profile[6]",
 	[AD9910_CHAN_IDX_PROFILE_7] = "profile[7]",
+	[AD9910_CHAN_IDX_PARALLEL_PORT] = "parallel_port",
 };
 
 static int ad9910_read_label(struct iio_dev *indio_dev,

-- 
2.43.0

