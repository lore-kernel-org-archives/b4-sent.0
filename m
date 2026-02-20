From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 20 Feb 2026 16:46:10 +0000
Subject: [PATCH RFC 6/8] iio: frequency: ad9910: add RAM mode support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260220-ad9910-iio-driver-v1-6-3b264aa48a10@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771605986; l=24545;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=40I0rilF1cHROAoMlCMzfANWq5mVGiNIdWyQOhmms9c=;
 b=VvkTsGZI/KknPTpJ6PpEwHZMg41CzEw4eJh6QVnAG0FyZ116KzVuLojAIM9qIpfB/tOvbUrq4
 XQ04+jWCktXBISaHrvtQcjZ1GujuE3GyKBkUl8/VOO2XsGau7FR9U56
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add RAM channel with support for profile-based control. This includes:
- RAM data loading via binary sysfs attribute (ram_data);
- Per-profile RAM configuration (start/end address, step rate, operating
  mode, dwell control);
- RAM destination control (frequency, phase, amplitude, polar);
- RAM operating modes (direct switch, ramp up, bidirectional ramp,
  continuous bidirectional, continuous recirculate);
- Profile switching for RAM playback;
- Sampling frequency control via profile step rate;
- ram_en-aware read/write paths that redirect single tone
  frequency/phase/amplitude access through reg_profile cache when RAM is
  active;

When RAM is enabled, the DDS core parameters (frequency, phase, amplitude)
for the single tone channel are sourced from a shadow register cache
(reg_profile[]) since the profile registers are repurposed for RAM control.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/ad9910.c | 474 +++++++++++++++++++++++++++++++++++++++--
 1 file changed, 455 insertions(+), 19 deletions(-)

diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index 84698bf2dc4e..8fd7ebe7e6b0 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -150,6 +150,15 @@
 #define AD9910_PROFILE_ST_POW_MSK		GENMASK_ULL(47, 32)
 #define AD9910_PROFILE_ST_FTW_MSK		AD9910_REG_LOW32_MSK
 
+/* Profile Register Format (RAM Mode) */
+#define AD9910_PROFILE_RAM_OPEN_MSK		GENMASK_ULL(61, 57)
+#define AD9910_PROFILE_RAM_STEP_RATE_MSK	GENMASK_ULL(55, 40)
+#define AD9910_PROFILE_RAM_END_ADDR_MSK		GENMASK_ULL(39, 30)
+#define AD9910_PROFILE_RAM_START_ADDR_MSK	GENMASK_ULL(23, 14)
+#define AD9910_PROFILE_RAM_NO_DWELL_HIGH_MSK	BIT_ULL(5)
+#define AD9910_PROFILE_RAM_ZERO_CROSSING_MSK	BIT_ULL(3)
+#define AD9910_PROFILE_RAM_MODE_CONTROL_MSK	GENMASK_ULL(2, 0)
+
 /* Device constants */
 #define AD9910_PI_NANORAD		3141592653UL
 
@@ -164,6 +173,14 @@
 #define AD9910_NUM_PROFILES		8
 
 #define AD9910_DRG_DEST_NUM		3
+#define AD9910_RAM_DEST_NUM		4
+
+#define AD9910_RAM_SIZE_MAX_WORDS	1024
+#define AD9910_RAM_WORD_SIZE		sizeof(u32)
+#define AD9910_RAM_SIZE_MAX_BYTES	(AD9910_RAM_SIZE_MAX_WORDS * AD9910_RAM_WORD_SIZE)
+#define AD9910_RAM_ADDR_MAX		(AD9910_RAM_SIZE_MAX_WORDS - 1)
+
+#define AD9910_RAM_PROFILE_CTL_CONT_MSK	BIT(4)
 
 /* PLL constants */
 #define AD9910_PLL_MIN_N		12
@@ -208,6 +225,7 @@ enum ad9910_channel {
 	AD9910_CHANNEL_SINGLE_TONE,
 	AD9910_CHANNEL_PARALLEL_PORT,
 	AD9910_CHANNEL_DRG,
+	AD9910_CHANNEL_RAM,
 };
 
 /**
@@ -235,6 +253,27 @@ enum ad9910_drg_oper_mode {
 	AD9910_DRG_OPER_MODE_BIDIR_CONT,
 };
 
+/**
+ * enum ad9910_ram_oper_mode - AD9910 RAM Playback Operating Mode
+ *
+ * @AD9910_RAM_MODE_DIRECT_SWITCH: Direct profile switching between profiles
+ * @AD9910_RAM_MODE_RAMP_UP: Ramp up for current profile
+ * @AD9910_RAM_MODE_BIDIR: Ramp up/down for profile 0
+ * @AD9910_RAM_MODE_BIDIR_CONT: Continuous ramp up/down for current profile
+ * @AD9910_RAM_MODE_RAMP_UP_CONT: Continuous ramp up for current profile
+ * @AD9910_RAM_MODE_SEQ: Sequenced playback of RAM profiles up to target profile
+ * @AD9910_RAM_MODE_SEQ_CONT: Continuous sequenced playback of RAM profiles
+ */
+enum ad9910_ram_oper_mode {
+	AD9910_RAM_MODE_DIRECT_SWITCH,
+	AD9910_RAM_MODE_RAMP_UP,
+	AD9910_RAM_MODE_BIDIR,
+	AD9910_RAM_MODE_BIDIR_CONT,
+	AD9910_RAM_MODE_RAMP_UP_CONT,
+	AD9910_RAM_MODE_SEQ,
+	AD9910_RAM_MODE_SEQ_CONT,
+};
+
 enum {
 	AD9910_PROFILE,
 	AD9910_POWERDOWN,
@@ -256,6 +295,8 @@ enum {
 	AD9910_DRG_AMP_DEC_STEP,
 	AD9910_DRG_INC_STEP_RATE,
 	AD9910_DRG_DEC_STEP_RATE,
+	AD9910_RAM_START_ADDR,
+	AD9910_RAM_END_ADDR,
 };
 
 struct ad9910_data {
@@ -294,6 +335,13 @@ struct ad9910_state {
 		u16 val16;
 	} reg[AD9910_REG_NUM_CACHED];
 
+	/*
+	 * alternate profile registers used to store RAM profile settings when
+	 * RAM mode is disabled and Single Tone profile settings when RAM mode
+	 * is enabled.
+	 */
+	u64 reg_profile[AD9910_NUM_PROFILES];
+
 	/*
 	 * Lock for accessing device registers and state variables.
 	 */
@@ -331,6 +379,16 @@ static const char * const ad9910_drg_oper_mode_str[] = {
 	[AD9910_DRG_OPER_MODE_BIDIR_CONT] = "bidirectional_continuous",
 };
 
+static const char * const ad9910_ram_oper_mode_str[] = {
+	[AD9910_RAM_MODE_DIRECT_SWITCH] = "direct_switch",
+	[AD9910_RAM_MODE_RAMP_UP] = "ramp_up",
+	[AD9910_RAM_MODE_BIDIR] = "bidirectional",
+	[AD9910_RAM_MODE_BIDIR_CONT] = "bidirectional_continuous",
+	[AD9910_RAM_MODE_RAMP_UP_CONT] = "ramp_up_continuous",
+	[AD9910_RAM_MODE_SEQ] = "sequenced",
+	[AD9910_RAM_MODE_SEQ_CONT] = "sequenced_continuous",
+};
+
 /**
  * ad9910_rational_scale() - Perform scaling of input given a reference.
  * @input: The input value to be scaled.
@@ -377,6 +435,18 @@ static inline int ad9910_spi_write(struct ad9910_state *st, u8 reg, size_t len,
 	return ret;
 }
 
+static inline int ad9910_ram_load(struct ad9910_state *st, void *data,
+				  size_t count)
+{
+	struct spi_transfer t[] = {
+		{ .tx_buf = st->buf, .len = 1, },
+		{ .tx_buf = data, .len = count, },
+	};
+
+	st->buf[0] = AD9910_REG_RAM;
+	return spi_sync_transfer(st->spi, t, ARRAY_SIZE(t));
+}
+
 #define AD9910_REG_READ_FN(nb)						\
 static inline int ad9910_reg##nb##_read(struct ad9910_state *st,	\
 					u8 reg, u##nb * data)		\
@@ -464,6 +534,14 @@ static int ad9910_chan_destination_set(struct iio_dev *indio_dev,
 					   AD9910_CFR2_DRG_DEST_MSK,
 					   FIELD_PREP(AD9910_CFR2_DRG_DEST_MSK, val),
 					   true);
+	case AD9910_CHANNEL_RAM:
+		if (FIELD_GET(AD9910_CFR1_RAM_ENABLE_MSK, st->reg[AD9910_REG_CFR1].val32))
+			return -EBUSY;
+
+		return ad9910_reg32_update(st, AD9910_REG_CFR1,
+					   AD9910_CFR1_RAM_PLAYBACK_DEST_MSK,
+					   FIELD_PREP(AD9910_CFR1_RAM_PLAYBACK_DEST_MSK, val),
+					   true);
 	default:
 		return -EINVAL;
 	}
@@ -480,6 +558,9 @@ static int ad9910_chan_destination_get(struct iio_dev *indio_dev,
 	case AD9910_CHANNEL_DRG:
 		return FIELD_GET(AD9910_CFR2_DRG_DEST_MSK,
 				 st->reg[AD9910_REG_CFR2].val32);
+	case AD9910_CHANNEL_RAM:
+		return FIELD_GET(AD9910_CFR1_RAM_PLAYBACK_DEST_MSK,
+				 st->reg[AD9910_REG_CFR1].val32);
 	default:
 		return -EINVAL;
 	}
@@ -510,6 +591,93 @@ static int ad9910_drg_oper_mode_get(struct iio_dev *indio_dev,
 			 st->reg[AD9910_REG_CFR2].val32);
 }
 
+static int ad9910_ram_oper_mode_set(struct iio_dev *indio_dev,
+				    const struct iio_chan_spec *chan,
+				    unsigned int val)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+	u32 profile_ctl;
+	int ret;
+
+	guard(mutex)(&st->lock);
+
+	/*
+	 * RAM sequenced modes use the internal profile control:
+	 *  - Sequence mode takes precedence over regular profile modes
+	 *  - Active profile defines the internal profile control target
+	 *  - Profile 0 cannot be used as sequenced mode target
+	 *  - Profile X cannot be set as sequenced mode target if another
+	 *    profile is currently set.
+	 */
+	profile_ctl = FIELD_GET(AD9910_CFR1_INT_PROFILE_CTL_MSK,
+				st->reg[AD9910_REG_CFR1].val32);
+	if (AD9910_RAM_PROFILE_CTL_CONT_MSK & profile_ctl)
+		profile_ctl = (profile_ctl & ~AD9910_RAM_PROFILE_CTL_CONT_MSK) + 1;
+
+	if (val >= AD9910_RAM_MODE_SEQ) {
+		if (!st->profile)
+			return -EINVAL;
+
+		if (profile_ctl && profile_ctl != st->profile)
+			return -EBUSY;
+
+		/* update profile control */
+		profile_ctl = st->profile;
+		if (val == AD9910_RAM_MODE_SEQ_CONT)
+			profile_ctl = AD9910_RAM_PROFILE_CTL_CONT_MSK | (profile_ctl - 1);
+		profile_ctl = FIELD_PREP(AD9910_CFR1_INT_PROFILE_CTL_MSK, profile_ctl);
+		return ad9910_reg32_update(st, AD9910_REG_CFR1,
+					   AD9910_CFR1_INT_PROFILE_CTL_MSK,
+					   profile_ctl, true);
+	}
+
+	if (profile_ctl && profile_ctl == st->profile) {
+		/* clear internal profile control */
+		ret = ad9910_reg32_update(st, AD9910_REG_CFR1,
+					  AD9910_CFR1_INT_PROFILE_CTL_MSK,
+					  0, true);
+		if (ret)
+			return ret;
+	}
+
+	if (FIELD_GET(AD9910_CFR1_RAM_ENABLE_MSK, st->reg[AD9910_REG_CFR1].val32))
+		return ad9910_reg64_update(st, AD9910_REG_PROFILE(st->profile),
+					   AD9910_PROFILE_RAM_MODE_CONTROL_MSK,
+					   FIELD_PREP(AD9910_PROFILE_RAM_MODE_CONTROL_MSK, val),
+					   true);
+
+	FIELD_MODIFY(AD9910_PROFILE_RAM_MODE_CONTROL_MSK,
+		     &st->reg_profile[st->profile], val);
+	return 0;
+}
+
+static int ad9910_ram_oper_mode_get(struct iio_dev *indio_dev,
+				    const struct iio_chan_spec *chan)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+	u32 profile_ctl;
+	bool seq_cont = false;
+
+	guard(mutex)(&st->lock);
+
+	profile_ctl = FIELD_GET(AD9910_CFR1_INT_PROFILE_CTL_MSK,
+				st->reg[AD9910_REG_CFR1].val32);
+	if (AD9910_RAM_PROFILE_CTL_CONT_MSK & profile_ctl) {
+		seq_cont = true;
+		profile_ctl = (profile_ctl & ~AD9910_RAM_PROFILE_CTL_CONT_MSK) + 1;
+	}
+
+	if (profile_ctl && profile_ctl == st->profile)
+		return (seq_cont) ? AD9910_RAM_MODE_SEQ_CONT : AD9910_RAM_MODE_SEQ;
+
+	if (FIELD_GET(AD9910_CFR1_RAM_ENABLE_MSK, st->reg[AD9910_REG_CFR1].val32))
+		return FIELD_GET(AD9910_PROFILE_RAM_MODE_CONTROL_MSK,
+				 st->reg[AD9910_REG_PROFILE(st->profile)].val64);
+	else
+		return FIELD_GET(AD9910_PROFILE_RAM_MODE_CONTROL_MSK,
+				 st->reg_profile[st->profile]);
+}
+
 static ssize_t ad9910_ext_info_read(struct iio_dev *indio_dev,
 				    uintptr_t private,
 				    const struct iio_chan_spec *chan,
@@ -532,6 +700,22 @@ static ssize_t ad9910_ext_info_read(struct iio_dev *indio_dev,
 		val = BIT(FIELD_GET(AD9910_CFR2_FM_GAIN_MSK,
 				    st->reg[AD9910_REG_CFR2].val32));
 		break;
+	case AD9910_RAM_START_ADDR:
+		if (FIELD_GET(AD9910_CFR1_RAM_ENABLE_MSK, st->reg[AD9910_REG_CFR1].val32))
+			val = FIELD_GET(AD9910_PROFILE_RAM_START_ADDR_MSK,
+					st->reg[AD9910_REG_PROFILE(st->profile)].val64);
+		else
+			val = FIELD_GET(AD9910_PROFILE_RAM_START_ADDR_MSK,
+					st->reg_profile[st->profile]);
+		break;
+	case AD9910_RAM_END_ADDR:
+		if (FIELD_GET(AD9910_CFR1_RAM_ENABLE_MSK, st->reg[AD9910_REG_CFR1].val32))
+			val = FIELD_GET(AD9910_PROFILE_RAM_END_ADDR_MSK,
+					st->reg[AD9910_REG_PROFILE(st->profile)].val64);
+		else
+			val = FIELD_GET(AD9910_PROFILE_RAM_END_ADDR_MSK,
+					st->reg_profile[st->profile]);
+		break;
 	default:
 		return -EINVAL;
 	}
@@ -576,6 +760,33 @@ static ssize_t ad9910_ext_info_write(struct iio_dev *indio_dev,
 					  AD9910_CFR2_FM_GAIN_MSK,
 					  val32, true);
 		break;
+	case AD9910_RAM_START_ADDR:
+		if (FIELD_GET(AD9910_CFR1_RAM_ENABLE_MSK, st->reg[AD9910_REG_CFR1].val32))
+			return -EBUSY;
+
+		if (val32 > AD9910_RAM_ADDR_MAX)
+			return -EINVAL;
+
+		if (val32 > FIELD_GET(AD9910_PROFILE_RAM_END_ADDR_MSK,
+				      st->reg_profile[st->profile]))
+			FIELD_MODIFY(AD9910_PROFILE_RAM_END_ADDR_MSK,
+				     &st->reg_profile[st->profile], val32);
+
+		FIELD_MODIFY(AD9910_PROFILE_RAM_START_ADDR_MSK,
+			     &st->reg_profile[st->profile], val32);
+		break;
+	case AD9910_RAM_END_ADDR:
+		if (FIELD_GET(AD9910_CFR1_RAM_ENABLE_MSK, st->reg[AD9910_REG_CFR1].val32))
+			return -EBUSY;
+
+		if (val32 > AD9910_RAM_ADDR_MAX ||
+		    val32 < FIELD_GET(AD9910_PROFILE_RAM_START_ADDR_MSK,
+				      st->reg_profile[st->profile]))
+			return -EINVAL;
+
+		FIELD_MODIFY(AD9910_PROFILE_RAM_END_ADDR_MSK,
+			     &st->reg_profile[st->profile], val32);
+		break;
 	default:
 		return -EINVAL;
 	}
@@ -967,6 +1178,20 @@ static const struct iio_enum ad9910_drg_oper_mode_enum = {
 	.get = ad9910_drg_oper_mode_get,
 };
 
+static const struct iio_enum ad9910_ram_destination_enum = {
+	.items = ad9910_destination_str,
+	.num_items = AD9910_RAM_DEST_NUM,
+	.set = ad9910_chan_destination_set,
+	.get = ad9910_chan_destination_get,
+};
+
+static const struct iio_enum ad9910_ram_oper_mode_enum = {
+	.items = ad9910_ram_oper_mode_str,
+	.num_items = ARRAY_SIZE(ad9910_ram_oper_mode_str),
+	.set = ad9910_ram_oper_mode_set,
+	.get = ad9910_ram_oper_mode_get,
+};
+
 static const struct iio_chan_spec_ext_info ad9910_shared_ext_info[] = {
 	AD9910_EXT_INFO("profile", AD9910_PROFILE, IIO_SHARED_BY_TYPE),
 	AD9910_EXT_INFO("powerdown", AD9910_POWERDOWN, IIO_SHARED_BY_TYPE),
@@ -1003,6 +1228,16 @@ static const struct iio_chan_spec_ext_info ad9910_drg_ext_info[] = {
 	{ },
 };
 
+static const struct iio_chan_spec_ext_info ad9910_ram_ext_info[] = {
+	IIO_ENUM("destination", IIO_SEPARATE, &ad9910_ram_destination_enum),
+	IIO_ENUM_AVAILABLE("destination", IIO_SEPARATE, &ad9910_ram_destination_enum),
+	IIO_ENUM("operating_mode", IIO_SEPARATE, &ad9910_ram_oper_mode_enum),
+	IIO_ENUM_AVAILABLE("operating_mode", IIO_SEPARATE, &ad9910_ram_oper_mode_enum),
+	AD9910_EXT_INFO("address_start", AD9910_RAM_START_ADDR, IIO_SEPARATE),
+	AD9910_EXT_INFO("address_end", AD9910_RAM_END_ADDR, IIO_SEPARATE),
+	{ },
+};
+
 static const struct iio_chan_spec ad9910_channels[] = {
 	[AD9910_CHANNEL_SINGLE_TONE] = {
 		.type = IIO_ALTVOLTAGE,
@@ -1032,6 +1267,18 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE),
 		.ext_info = ad9910_drg_ext_info,
 	},
+	[AD9910_CHANNEL_RAM] = {
+		.type = IIO_ALTVOLTAGE,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_RAM,
+		.scan_index = -1,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE) |
+				      BIT(IIO_CHAN_INFO_FREQUENCY) |
+				      BIT(IIO_CHAN_INFO_PHASE) |
+				      BIT(IIO_CHAN_INFO_SAMP_FREQ),
+		.ext_info = ad9910_ram_ext_info,
+	},
 };
 
 static int ad9910_read_raw(struct iio_dev *indio_dev,
@@ -1040,10 +1287,13 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 {
 	struct ad9910_state *st = iio_priv(indio_dev);
 	u64 tmp64;
-	u32 tmp32;
+	u32 tmp32, ram_en;
 
 	guard(mutex)(&st->lock);
 
+	ram_en = FIELD_GET(AD9910_CFR1_RAM_ENABLE_MSK,
+			   st->reg[AD9910_REG_CFR1].val32);
+
 	switch (info) {
 	case IIO_CHAN_INFO_ENABLE:
 		switch (chan->channel) {
@@ -1055,30 +1305,77 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 			*val = FIELD_GET(AD9910_CFR2_DRG_ENABLE_MSK,
 					 st->reg[AD9910_REG_CFR2].val32);
 			break;
+		case AD9910_CHANNEL_RAM:
+			*val = ram_en;
+			break;
 		default:
 			return -EINVAL;
 		}
 		return IIO_VAL_INT;
 	case IIO_CHAN_INFO_FREQUENCY:
-		tmp32 = FIELD_GET(AD9910_PROFILE_ST_FTW_MSK,
-				  st->reg[AD9910_REG_PROFILE(st->profile)].val64);
+		if (chan->channel == AD9910_CHANNEL_SINGLE_TONE) {
+			if (!ram_en)
+				tmp32 = FIELD_GET(AD9910_PROFILE_ST_FTW_MSK,
+						  st->reg[AD9910_REG_PROFILE(st->profile)].val64);
+			else
+				tmp32 = FIELD_GET(AD9910_PROFILE_ST_FTW_MSK,
+						  st->reg_profile[st->profile]);
+		} else {
+			tmp32 = st->reg[AD9910_REG_FTW].val32;
+		}
 		tmp64 = (u64)tmp32 * st->data.sysclk_freq_hz;
 		*val = upper_32_bits(tmp64);
 		*val2 = upper_32_bits((u64)lower_32_bits(tmp64) * MICRO);
 		return IIO_VAL_INT_PLUS_MICRO;
 	case IIO_CHAN_INFO_PHASE:
-		tmp32 = FIELD_GET(AD9910_PROFILE_ST_POW_MSK,
-				  st->reg[AD9910_REG_PROFILE(st->profile)].val64);
+		if (chan->channel == AD9910_CHANNEL_SINGLE_TONE) {
+			if (!ram_en)
+				tmp32 = FIELD_GET(AD9910_PROFILE_ST_POW_MSK,
+						  st->reg[AD9910_REG_PROFILE(st->profile)].val64);
+			else
+				tmp32 = FIELD_GET(AD9910_PROFILE_ST_POW_MSK,
+						  st->reg_profile[st->profile]);
+		} else {
+			tmp32 = st->reg[AD9910_REG_POW].val16;
+		}
 		tmp32 = ((u64)tmp32 * AD9910_MAX_PHASE_MICRORAD) >> 16;
 		*val = tmp32 / MICRO;
 		*val2 = tmp32 % MICRO;
 		return IIO_VAL_INT_PLUS_MICRO;
 	case IIO_CHAN_INFO_SCALE:
-		tmp32 = FIELD_GET(AD9910_PROFILE_ST_ASF_MSK,
-				  st->reg[AD9910_REG_PROFILE(st->profile)].val64);
+		if (chan->channel == AD9910_CHANNEL_SINGLE_TONE) {
+			if (!ram_en)
+				tmp32 = FIELD_GET(AD9910_PROFILE_ST_ASF_MSK,
+						  st->reg[AD9910_REG_PROFILE(st->profile)].val64);
+			else
+				tmp32 = FIELD_GET(AD9910_PROFILE_ST_ASF_MSK,
+						  st->reg_profile[st->profile]);
+		} else {
+			tmp32 = FIELD_GET(AD9910_ASF_SCALE_FACTOR_MSK,
+					  st->reg[AD9910_REG_ASF].val32);
+		}
 		*val = 0;
 		*val2 = (u64)tmp32 * MICRO >> 14;
 		return IIO_VAL_INT_PLUS_MICRO;
+	case IIO_CHAN_INFO_SAMP_FREQ:
+		switch (chan->channel) {
+		case AD9910_CHANNEL_RAM:
+			if (ram_en)
+				tmp32 = FIELD_GET(AD9910_PROFILE_RAM_STEP_RATE_MSK,
+						  st->reg[AD9910_REG_PROFILE(st->profile)].val64);
+			else
+				tmp32 = FIELD_GET(AD9910_PROFILE_RAM_STEP_RATE_MSK,
+						  st->reg_profile[st->profile]);
+			break;
+		default:
+			return -EINVAL;
+		}
+		if (!tmp32)
+			return -ERANGE;
+		tmp32 *= 4;
+		*val = st->data.sysclk_freq_hz / tmp32;
+		*val2 = div_u64((u64)(st->data.sysclk_freq_hz % tmp32) * MICRO, tmp32);
+		return IIO_VAL_INT_PLUS_MICRO;
 	default:
 		return -EINVAL;
 	}
@@ -1092,9 +1389,13 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 	u64 tmp64;
 	u32 tmp32;
 	u16 tmp16;
+	int ram_en, ret = 0;
 
 	guard(mutex)(&st->lock);
 
+	ram_en = FIELD_GET(AD9910_CFR1_RAM_ENABLE_MSK,
+			   st->reg[AD9910_REG_CFR1].val32);
+
 	switch (info) {
 	case IIO_CHAN_INFO_ENABLE:
 		val = val ? 1 : 0;
@@ -1109,6 +1410,26 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			return ad9910_reg32_update(st, AD9910_REG_CFR2,
 						   AD9910_CFR2_DRG_ENABLE_MSK,
 						   tmp32, true);
+		case AD9910_CHANNEL_RAM:
+			if (ram_en == val)
+				return 0;
+
+			/* switch profile configs */
+			for (int i = 0; i < AD9910_NUM_PROFILES; i++) {
+				tmp64 = st->reg[AD9910_REG_PROFILE(i)].val64;
+				ret = ad9910_reg64_write(st,
+							 AD9910_REG_PROFILE(i),
+							 st->reg_profile[i],
+							 false);
+				if (ret)
+					return ret;
+				st->reg_profile[i] = tmp64;
+			}
+
+			tmp32 = FIELD_PREP(AD9910_CFR1_RAM_ENABLE_MSK, val);
+			return ad9910_reg32_update(st, AD9910_REG_CFR1,
+						   AD9910_CFR1_RAM_ENABLE_MSK,
+						   tmp32, true);
 		default:
 			return -EINVAL;
 		}
@@ -1118,10 +1439,18 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 
 		tmp32 = ad9910_rational_scale((u64)val * MICRO + val2, BIT_ULL(32),
 					      (u64)MICRO * st->data.sysclk_freq_hz);
-		return ad9910_reg64_update(st, AD9910_REG_PROFILE(st->profile),
-					   AD9910_PROFILE_ST_FTW_MSK,
-					   FIELD_PREP(AD9910_PROFILE_ST_FTW_MSK, tmp32),
-					   true);
+		if (chan->channel != AD9910_CHANNEL_SINGLE_TONE)
+			return ad9910_reg32_write(st, AD9910_REG_FTW, tmp32, true);
+
+		if (!ram_en)
+			return ad9910_reg64_update(st, AD9910_REG_PROFILE(st->profile),
+						   AD9910_PROFILE_ST_FTW_MSK,
+						   FIELD_PREP(AD9910_PROFILE_ST_FTW_MSK, tmp32),
+						   true);
+
+		FIELD_MODIFY(AD9910_PROFILE_ST_FTW_MSK,
+			     &st->reg_profile[st->profile], tmp32);
+		break;
 	case IIO_CHAN_INFO_PHASE:
 		tmp64 = (u64)val * MICRO + val2;
 		if (val < 0 || val2 < 0 || tmp64 >= AD9910_MAX_PHASE_MICRORAD)
@@ -1129,10 +1458,19 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 
 		tmp32 = DIV_U64_ROUND_CLOSEST(tmp64 << 16, AD9910_MAX_PHASE_MICRORAD);
 		tmp16 = min(tmp32, AD9910_POW_MAX);
-		return ad9910_reg64_update(st, AD9910_REG_PROFILE(st->profile),
-					   AD9910_PROFILE_ST_POW_MSK,
-					   FIELD_PREP(AD9910_PROFILE_ST_POW_MSK, tmp16),
-					   true);
+
+		if (chan->channel != AD9910_CHANNEL_SINGLE_TONE)
+			return ad9910_reg16_write(st, AD9910_REG_POW, tmp16, true);
+
+		if (!ram_en)
+			return ad9910_reg64_update(st, AD9910_REG_PROFILE(st->profile),
+						   AD9910_PROFILE_ST_POW_MSK,
+						   FIELD_PREP(AD9910_PROFILE_ST_POW_MSK, tmp16),
+						   true);
+
+		FIELD_MODIFY(AD9910_PROFILE_ST_POW_MSK,
+			     &st->reg_profile[st->profile], tmp16);
+		break;
 	case IIO_CHAN_INFO_SCALE:
 		if (val < 0 || val > 1 || (val == 1 && val2 > 0))
 			return -EINVAL;
@@ -1140,13 +1478,51 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 		tmp64 = ((u64)val * MICRO + val2) << 14;
 		tmp64 = DIV_U64_ROUND_CLOSEST(tmp64, MICRO);
 		tmp16 = min(tmp64, AD9910_ASF_MAX);
-		return ad9910_reg64_update(st, AD9910_REG_PROFILE(st->profile),
-					   AD9910_PROFILE_ST_ASF_MSK,
-					   FIELD_PREP(AD9910_PROFILE_ST_ASF_MSK, tmp16),
-					   true);
+
+		if (chan->channel != AD9910_CHANNEL_SINGLE_TONE)
+			return ad9910_reg32_update(st, AD9910_REG_ASF,
+						   AD9910_ASF_SCALE_FACTOR_MSK,
+						   FIELD_PREP(AD9910_ASF_SCALE_FACTOR_MSK, tmp16),
+						   true);
+
+		if (!ram_en)
+			return ad9910_reg64_update(st, AD9910_REG_PROFILE(st->profile),
+						   AD9910_PROFILE_ST_ASF_MSK,
+						   FIELD_PREP(AD9910_PROFILE_ST_ASF_MSK, tmp16),
+						   true);
+
+		FIELD_MODIFY(AD9910_PROFILE_ST_ASF_MSK,
+			     &st->reg_profile[st->profile], tmp16);
+		break;
+	case IIO_CHAN_INFO_SAMP_FREQ:
+		tmp64 = ((u64)val * MICRO + val2) * 4;
+		if (!tmp64)
+			return -EINVAL;
+
+		tmp64 = DIV64_U64_ROUND_CLOSEST((u64)st->data.sysclk_freq_hz * MICRO, tmp64);
+		tmp32 = clamp(tmp64, 1U, AD9910_STEP_RATE_MAX);
+
+		switch (chan->channel) {
+		case AD9910_CHANNEL_RAM:
+			if (ram_en) {
+				tmp64 = FIELD_PREP(AD9910_PROFILE_RAM_STEP_RATE_MSK, tmp32);
+				return ad9910_reg64_update(st, AD9910_REG_PROFILE(st->profile),
+							   AD9910_PROFILE_RAM_STEP_RATE_MSK,
+							   tmp64, true);
+			}
+
+			FIELD_MODIFY(AD9910_PROFILE_RAM_STEP_RATE_MSK,
+				     &st->reg_profile[st->profile], tmp32);
+			break;
+		default:
+			return -EINVAL;
+		}
+		break;
 	default:
 		return -EINVAL;
 	}
+
+	return ret;
 }
 
 static int ad9910_write_raw_get_fmt(struct iio_dev *indio_dev,
@@ -1159,6 +1535,7 @@ static int ad9910_write_raw_get_fmt(struct iio_dev *indio_dev,
 	case IIO_CHAN_INFO_FREQUENCY:
 	case IIO_CHAN_INFO_PHASE:
 	case IIO_CHAN_INFO_SCALE:
+	case IIO_CHAN_INFO_SAMP_FREQ:
 		return IIO_VAL_INT_PLUS_MICRO;
 	default:
 		return -EINVAL;
@@ -1247,13 +1624,65 @@ static ssize_t sysclk_frequency_show(struct device *dev,
 
 static IIO_DEVICE_ATTR_RO(sysclk_frequency, 0);
 
+static ssize_t ram_data_write(struct file *filp, struct kobject *kobj,
+			      const struct bin_attribute *attr, char *buf,
+			      loff_t off, size_t count)
+{
+	struct ad9910_state *st = iio_priv(dev_to_iio_dev(kobj_to_dev(kobj)));
+	u64 tmp64, backup;
+	u32 start, end;
+	int ret, ret2;
+
+	if (off + count > AD9910_RAM_SIZE_MAX_BYTES || !count ||
+	    off % AD9910_RAM_WORD_SIZE != 0 ||
+	    count % AD9910_RAM_WORD_SIZE != 0)
+		return -EINVAL;
+
+	guard(mutex)(&st->lock);
+
+	if (FIELD_GET(AD9910_CFR1_RAM_ENABLE_MSK, st->reg[AD9910_REG_CFR1].val32))
+		return -EBUSY;
+
+	/* ensure profile is selected */
+	ret = ad9910_profile_set(st, st->profile);
+	if (ret)
+		return ret;
+
+	/* backup profile register */
+	backup = st->reg[AD9910_REG_PROFILE(st->profile)].val64;
+	start = off / AD9910_RAM_WORD_SIZE;
+	end = (off + count) / AD9910_RAM_WORD_SIZE - 1;
+	tmp64 = AD9910_PROFILE_RAM_STEP_RATE_MSK |
+		FIELD_PREP(AD9910_PROFILE_RAM_START_ADDR_MSK, start) |
+		FIELD_PREP(AD9910_PROFILE_RAM_END_ADDR_MSK, end);
+	ret = ad9910_reg64_write(st, AD9910_REG_PROFILE(st->profile), tmp64, true);
+	if (ret)
+		return ret;
+
+	/* write ram data and restore profile register */
+	ret = ad9910_ram_load(st, buf, count);
+	ret2 = ad9910_reg64_write(st, AD9910_REG_PROFILE(st->profile), backup, true);
+	if (!ret)
+		ret = ret2;
+
+	return ret ?: count;
+}
+
+static const BIN_ATTR_WO(ram_data, AD9910_RAM_SIZE_MAX_BYTES);
+
 static struct attribute *ad9910_attrs[] = {
 	&iio_dev_attr_sysclk_frequency.dev_attr.attr,
 	NULL
 };
 
+static const struct bin_attribute *const ad9910_bin_attrs[] = {
+	&bin_attr_ram_data,
+	NULL
+};
+
 static const struct attribute_group ad9910_attrs_group = {
 	.attrs = ad9910_attrs,
+	.bin_attrs = ad9910_bin_attrs,
 };
 
 static const struct iio_info ad9910_info = {
@@ -1426,6 +1855,13 @@ static int ad9910_setup(struct ad9910_state *st, struct reset_control *dev_rst)
 	if (ret)
 		return ret;
 
+	for (int i = 0; i < AD9910_NUM_PROFILES; i++) {
+		st->reg_profile[i] = AD9910_PROFILE_RAM_OPEN_MSK;
+		st->reg_profile[i] |= FIELD_PREP(AD9910_PROFILE_RAM_STEP_RATE_MSK, 1);
+		st->reg_profile[i] |= FIELD_PREP(AD9910_PROFILE_RAM_END_ADDR_MSK,
+						 AD9910_RAM_ADDR_MAX);
+	}
+
 	return ad9910_io_update(st);
 }
 

-- 
2.43.0

