From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 18 Mar 2026 17:56:05 +0000
Subject: [PATCH RFC v2 5/9] iio: frequency: ad9910: add RAM mode support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260318-ad9910-iio-driver-v2-5-e79f93becf11@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773856569; l=27152;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=f87YRyYgMlZ1bM+LRFDR1AdWyuDGLtwNgYqb09iYYj4=;
 b=YSM4wxkcPhVIbp0mxURc15ASTMke6nFf7jjhlp3ZyKCxb/sixvljOcdrAnhSv3MVGfz3R+yNT
 F+P8bXmQ79gBcyZlbdcZqqLagCcx2C2aWeWH/sGzA+JuOSgMW5Q5E2z
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add RAM channel with support for profile-based control. This includes:
- RAM data loading via firmware upload interface;
- Per-profile RAM configuration (start/end address, step rate, operating
  mode, dwell control);
- RAM destination control (frequency, phase, amplitude, polar);
- RAM operating modes (direct switch, ramp up, bidirectional ramp,
  continuous bidirectional, continuous recirculate);
- Profile switching for RAM playback;
- Sampling frequency control via profile step rate;
- ram-enable-aware read/write paths that redirect single tone
  frequency/phase/amplitude access through reg_profile cache when RAM is
  active;

When RAM is enabled, the DDS core parameters (frequency, phase, amplitude)
for the single tone channel are sourced from a shadow register cache
(reg_profile[]) since the profile registers are repurposed for RAM control.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/Kconfig  |   2 +
 drivers/iio/frequency/ad9910.c | 464 ++++++++++++++++++++++++++++++++++++++++-
 2 files changed, 462 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/frequency/Kconfig b/drivers/iio/frequency/Kconfig
index 180e74f62d11..a5b2e5cb5269 100644
--- a/drivers/iio/frequency/Kconfig
+++ b/drivers/iio/frequency/Kconfig
@@ -29,6 +29,8 @@ config AD9910
 	tristate "Analog Devices AD9910 Direct Digital Synthesizer"
 	depends on SPI
 	depends on GPIOLIB
+	select FW_LOADER
+	select FW_UPLOAD
 	help
 	  Say yes here to build support for Analog Devices AD9910
 	  1 GSPS, 14-Bit DDS with integrated DAC.
diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index d3367e211dcf..747f4f407536 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -8,9 +8,11 @@
 #include <linux/array_size.h>
 #include <linux/bitfield.h>
 #include <linux/clk.h>
+#include <linux/debugfs.h>
 #include <linux/delay.h>
 #include <linux/device.h>
 #include <linux/err.h>
+#include <linux/firmware.h>
 #include <linux/gpio/consumer.h>
 #include <linux/log2.h>
 #include <linux/math64.h>
@@ -149,6 +151,15 @@
 #define AD9910_PROFILE_ST_POW_MSK		GENMASK_ULL(47, 32)
 #define AD9910_PROFILE_ST_FTW_MSK		GENMASK_ULL(31, 0)
 
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
 
@@ -163,6 +174,17 @@
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
+
+#define AD9910_RAM_ENABLED(st)		\
+	FIELD_GET(AD9910_CFR1_RAM_ENABLE_MSK, (st)->reg[AD9910_REG_CFR1].val32)
 
 /* PLL constants */
 #define AD9910_PLL_MIN_N		12
@@ -195,7 +217,7 @@
 #define AD9910_REFDIV2_MAX_FREQ_HZ	(1900 * HZ_PER_MHZ)
 
 #define AD9910_SPI_DATA_IDX		1
-#define AD9910_SPI_DATA_LEN_MAX		sizeof(__be64)
+#define AD9910_SPI_DATA_LEN_MAX		AD9910_RAM_SIZE_MAX_BYTES
 #define AD9910_SPI_MESSAGE_LEN_MAX	(AD9910_SPI_DATA_IDX + AD9910_SPI_DATA_LEN_MAX)
 #define AD9910_SPI_READ_MSK		BIT(7)
 #define AD9910_SPI_ADDR_MSK		GENMASK(4, 0)
@@ -209,6 +231,7 @@
  * @AD9910_CHANNEL_DRG: Digital Ramp Generator output channel
  * @AD9910_CHANNEL_DRG_RAMP_UP: DRG ramp up channel
  * @AD9910_CHANNEL_DRG_RAMP_DOWN: DRG ramp down channel
+ * @AD9910_CHANNEL_RAM: RAM control output channel
  */
 enum ad9910_channel {
 	AD9910_CHANNEL_PHY = 100,
@@ -217,6 +240,7 @@ enum ad9910_channel {
 	AD9910_CHANNEL_DRG = 130,
 	AD9910_CHANNEL_DRG_RAMP_UP = 131,
 	AD9910_CHANNEL_DRG_RAMP_DOWN = 132,
+	AD9910_CHANNEL_RAM = 140,
 };
 
 /**
@@ -249,6 +273,27 @@ enum ad9910_drg_oper_mode {
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
 	AD9910_CHAN_IDX_PHY,
 	AD9910_CHAN_IDX_SINGLE_TONE,
@@ -270,6 +315,8 @@ enum {
 	AD9910_DRG_FREQ_STEP,
 	AD9910_DRG_PHASE_STEP,
 	AD9910_DRG_AMP_STEP,
+	AD9910_RAM_START_ADDR,
+	AD9910_RAM_END_ADDR,
 };
 
 struct ad9910_data {
@@ -284,6 +331,7 @@ struct ad9910_data {
 struct ad9910_state {
 	struct spi_device *spi;
 	struct clk *refclk;
+	struct fw_upload *ram_fwu;
 
 	struct gpio_desc *gpio_pwdown;
 	struct gpio_desc *gpio_update;
@@ -296,12 +344,22 @@ struct ad9910_state {
 		u16 val16;
 	} reg[AD9910_REG_NUM_CACHED];
 
+	/*
+	 * alternate profile registers used to store RAM profile settings when
+	 * RAM mode is disabled and Single Tone profile settings when RAM mode
+	 * is enabled.
+	 */
+	u64 reg_profile[AD9910_NUM_PROFILES];
+
 	/* Lock for accessing device registers and state variables */
 	struct mutex lock;
 
 	struct ad9910_data data;
 	u8 profile;
 
+	bool ram_fwu_cancel;
+	char ram_fwu_name[20];
+
 	union {
 		__be64 be64;
 		__be32 be32;
@@ -337,6 +395,16 @@ static const char * const ad9910_drg_oper_mode_str[] = {
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
@@ -352,6 +420,22 @@ static const char * const ad9910_drg_oper_mode_str[] = {
 	mul_u64_add_u64_div_u64(input, scale, _tmp >> 1, _tmp);	\
 })
 
+static inline u64 ad9910_ram_profile_val(struct ad9910_state *st)
+{
+	if (AD9910_RAM_ENABLED(st))
+		return st->reg_profile[st->profile];
+	else
+		return st->reg[st->profile].val64;
+}
+
+static inline u64 ad9910_st_profile_val(struct ad9910_state *st)
+{
+	if (AD9910_RAM_ENABLED(st))
+		return st->reg[st->profile].val64;
+	else
+		return st->reg_profile[st->profile];
+}
+
 static int ad9910_io_update(struct ad9910_state *st)
 {
 	if (st->gpio_update) {
@@ -544,6 +628,14 @@ static int ad9910_chan_destination_set(struct iio_dev *indio_dev,
 					   AD9910_CFR2_DRG_DEST_MSK,
 					   FIELD_PREP(AD9910_CFR2_DRG_DEST_MSK, val),
 					   true);
+	case AD9910_CHANNEL_RAM:
+		if (AD9910_RAM_ENABLED(st))
+			return -EBUSY;
+
+		return ad9910_reg32_update(st, AD9910_REG_CFR1,
+					   AD9910_CFR1_RAM_PLAYBACK_DEST_MSK,
+					   FIELD_PREP(AD9910_CFR1_RAM_PLAYBACK_DEST_MSK, val),
+					   true);
 	default:
 		return -EINVAL;
 	}
@@ -560,6 +652,9 @@ static int ad9910_chan_destination_get(struct iio_dev *indio_dev,
 	case AD9910_CHANNEL_DRG:
 		return FIELD_GET(AD9910_CFR2_DRG_DEST_MSK,
 				 st->reg[AD9910_REG_CFR2].val32);
+	case AD9910_CHANNEL_RAM:
+		return FIELD_GET(AD9910_CFR1_RAM_PLAYBACK_DEST_MSK,
+				 st->reg[AD9910_REG_CFR1].val32);
 	default:
 		return -EINVAL;
 	}
@@ -590,6 +685,93 @@ static int ad9910_drg_oper_mode_get(struct iio_dev *indio_dev,
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
+	if (AD9910_RAM_ENABLED(st))
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
+	if (AD9910_RAM_ENABLED(st))
+		return FIELD_GET(AD9910_PROFILE_RAM_MODE_CONTROL_MSK,
+				 st->reg[AD9910_REG_PROFILE(st->profile)].val64);
+
+	return FIELD_GET(AD9910_PROFILE_RAM_MODE_CONTROL_MSK,
+			 st->reg_profile[st->profile]);
+}
+
 static ssize_t ad9910_ext_info_read(struct iio_dev *indio_dev,
 				    uintptr_t private,
 				    const struct iio_chan_spec *chan,
@@ -612,6 +794,14 @@ static ssize_t ad9910_ext_info_read(struct iio_dev *indio_dev,
 		val = BIT(FIELD_GET(AD9910_CFR2_FM_GAIN_MSK,
 				    st->reg[AD9910_REG_CFR2].val32));
 		break;
+	case AD9910_RAM_START_ADDR:
+		val = FIELD_GET(AD9910_PROFILE_RAM_START_ADDR_MSK,
+				ad9910_ram_profile_val(st));
+		break;
+	case AD9910_RAM_END_ADDR:
+		val = FIELD_GET(AD9910_PROFILE_RAM_END_ADDR_MSK,
+				ad9910_ram_profile_val(st));
+		break;
 	default:
 		return -EINVAL;
 	}
@@ -656,6 +846,33 @@ static ssize_t ad9910_ext_info_write(struct iio_dev *indio_dev,
 					  AD9910_CFR2_FM_GAIN_MSK,
 					  val32, true);
 		break;
+	case AD9910_RAM_START_ADDR:
+		if (AD9910_RAM_ENABLED(st))
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
+		if (AD9910_RAM_ENABLED(st))
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
@@ -919,6 +1136,20 @@ static const struct iio_enum ad9910_drg_oper_mode_enum = {
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
 static const struct iio_chan_spec_ext_info ad9910_phy_ext_info[] = {
 	AD9910_EXT_INFO("profile", AD9910_PROFILE, IIO_SEPARATE),
 	AD9910_EXT_INFO("powerdown", AD9910_POWERDOWN, IIO_SEPARATE),
@@ -948,6 +1179,16 @@ static const struct iio_chan_spec_ext_info ad9910_drg_ramp_ext_info[] = {
 	{ }
 };
 
+static const struct iio_chan_spec_ext_info ad9910_ram_ext_info[] = {
+	IIO_ENUM("destination", IIO_SEPARATE, &ad9910_ram_destination_enum),
+	IIO_ENUM_AVAILABLE("destination", IIO_SEPARATE, &ad9910_ram_destination_enum),
+	IIO_ENUM("operating_mode", IIO_SEPARATE, &ad9910_ram_oper_mode_enum),
+	IIO_ENUM_AVAILABLE("operating_mode", IIO_SEPARATE, &ad9910_ram_oper_mode_enum),
+	AD9910_EXT_INFO("address_start", AD9910_RAM_START_ADDR, IIO_SEPARATE),
+	AD9910_EXT_INFO("address_end", AD9910_RAM_END_ADDR, IIO_SEPARATE),
+	{ }
+};
+
 static const struct iio_chan_spec ad9910_channels[] = {
 	[AD9910_CHAN_IDX_PHY] = {
 		.type = IIO_ALTVOLTAGE,
@@ -1015,6 +1256,19 @@ static const struct iio_chan_spec ad9910_channels[] = {
 				      BIT(IIO_CHAN_INFO_SAMP_FREQ),
 		.ext_info = ad9910_drg_ramp_ext_info,
 	},
+	[AD9910_CHAN_IDX_RAM] = {
+		.type = IIO_ALTVOLTAGE,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_RAM,
+		.address = AD9910_CHAN_IDX_RAM,
+		.scan_index = -1,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE) |
+				      BIT(IIO_CHAN_INFO_FREQUENCY) |
+				      BIT(IIO_CHAN_INFO_PHASE) |
+				      BIT(IIO_CHAN_INFO_SAMP_FREQ),
+		.ext_info = ad9910_ram_ext_info,
+	},
 };
 
 static int ad9910_read_raw(struct iio_dev *indio_dev,
@@ -1038,6 +1292,10 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 			*val = FIELD_GET(AD9910_CFR2_DRG_ENABLE_MSK,
 					 st->reg[AD9910_REG_CFR2].val32);
 			break;
+		case AD9910_CHANNEL_RAM:
+			*val = FIELD_GET(AD9910_CFR1_RAM_ENABLE_MSK,
+					 st->reg[AD9910_REG_CFR1].val32);
+			break;
 		default:
 			return -EINVAL;
 		}
@@ -1046,7 +1304,7 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 		switch (chan->channel) {
 		case AD9910_CHANNEL_SINGLE_TONE:
 			tmp32 = FIELD_GET(AD9910_PROFILE_ST_FTW_MSK,
-					  st->reg[AD9910_REG_PROFILE(st->profile)].val64);
+					  ad9910_st_profile_val(st));
 			break;
 		case AD9910_CHANNEL_DRG_RAMP_UP:
 			tmp32 = FIELD_GET(AD9910_DRG_LIMIT_UPPER_MSK,
@@ -1056,6 +1314,9 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 			tmp32 = FIELD_GET(AD9910_DRG_LIMIT_LOWER_MSK,
 					  st->reg[AD9910_REG_DRG_LIMIT].val64);
 			break;
+		case AD9910_CHANNEL_RAM:
+			tmp32 = st->reg[AD9910_REG_FTW].val32;
+			break;
 		default:
 			return -EINVAL;
 		}
@@ -1067,7 +1328,7 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 		switch (chan->channel) {
 		case AD9910_CHANNEL_SINGLE_TONE:
 			tmp64 = FIELD_GET(AD9910_PROFILE_ST_POW_MSK,
-					  st->reg[AD9910_REG_PROFILE(st->profile)].val64);
+					  ad9910_st_profile_val(st));
 			tmp32 = (tmp64 * AD9910_MAX_PHASE_MICRORAD) >> 16;
 			*val = tmp32 / MICRO;
 			*val2 = tmp32 % MICRO;
@@ -1084,6 +1345,12 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 			tmp64 = (tmp64 * AD9910_PI_NANORAD) >> 31;
 			*val = div_u64_rem(tmp64, NANO, val2);
 			return IIO_VAL_INT_PLUS_NANO;
+		case AD9910_CHANNEL_RAM:
+			tmp64 = st->reg[AD9910_REG_POW].val16;
+			tmp32 = (tmp64 * AD9910_MAX_PHASE_MICRORAD) >> 16;
+			*val = tmp32 / MICRO;
+			*val2 = tmp32 % MICRO;
+			return IIO_VAL_INT_PLUS_MICRO;
 		default:
 			return -EINVAL;
 		}
@@ -1091,7 +1358,7 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 		switch (chan->channel) {
 		case AD9910_CHANNEL_SINGLE_TONE:
 			tmp64 = FIELD_GET(AD9910_PROFILE_ST_ASF_MSK,
-					  st->reg[AD9910_REG_PROFILE(st->profile)].val64);
+					  ad9910_st_profile_val(st));
 			*val = 0;
 			*val2 = tmp64 * MICRO >> 14;
 			return IIO_VAL_INT_PLUS_MICRO;
@@ -1123,6 +1390,10 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 			tmp32 = FIELD_GET(AD9910_DRG_RATE_DEC_MSK,
 					  st->reg[AD9910_REG_DRG_RATE].val32);
 			break;
+		case AD9910_CHANNEL_RAM:
+			tmp32 = FIELD_GET(AD9910_PROFILE_RAM_STEP_RATE_MSK,
+					  ad9910_ram_profile_val(st));
+			break;
 		default:
 			return -EINVAL;
 		}
@@ -1144,6 +1415,7 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 	struct ad9910_state *st = iio_priv(indio_dev);
 	u64 tmp64;
 	u32 tmp32;
+	int ret, i;
 
 	guard(mutex)(&st->lock);
 
@@ -1161,6 +1433,26 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			return ad9910_reg32_update(st, AD9910_REG_CFR2,
 						   AD9910_CFR2_DRG_ENABLE_MSK,
 						   tmp32, true);
+		case AD9910_CHANNEL_RAM:
+			if (AD9910_RAM_ENABLED(st) == val)
+				return 0;
+
+			/* switch profile configs */
+			for (i = 0; i < AD9910_NUM_PROFILES; i++) {
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
@@ -1173,6 +1465,11 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 		tmp64 = min(tmp64, U32_MAX);
 		switch (chan->channel) {
 		case AD9910_CHANNEL_SINGLE_TONE:
+			if (AD9910_RAM_ENABLED(st)) {
+				FIELD_MODIFY(AD9910_PROFILE_ST_FTW_MSK,
+					     &st->reg_profile[st->profile], tmp64);
+				return 0;
+			}
 			tmp64 = FIELD_PREP(AD9910_PROFILE_ST_FTW_MSK, tmp64);
 			return ad9910_reg64_update(st, AD9910_REG_PROFILE(st->profile),
 						   AD9910_PROFILE_ST_FTW_MSK,
@@ -1187,6 +1484,8 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			return ad9910_reg64_update(st, AD9910_REG_DRG_LIMIT,
 						   AD9910_DRG_LIMIT_LOWER_MSK,
 						   tmp64, true);
+		case AD9910_CHANNEL_RAM:
+			return ad9910_reg32_write(st, AD9910_REG_FTW, tmp64, true);
 		default:
 			return -EINVAL;
 		}
@@ -1203,6 +1502,13 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			tmp64 <<= 16;
 			tmp64 = DIV_U64_ROUND_CLOSEST(tmp64, AD9910_MAX_PHASE_MICRORAD);
 			tmp64 = min(tmp64, AD9910_POW_MAX);
+
+			if (AD9910_RAM_ENABLED(st)) {
+				FIELD_MODIFY(AD9910_PROFILE_ST_POW_MSK,
+					     &st->reg_profile[st->profile], tmp64);
+				return 0;
+			}
+
 			tmp64 = FIELD_PREP(AD9910_PROFILE_ST_POW_MSK, tmp64);
 			return ad9910_reg64_update(st, AD9910_REG_PROFILE(st->profile),
 						   AD9910_PROFILE_ST_POW_MSK,
@@ -1231,6 +1537,15 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			return ad9910_reg64_update(st, AD9910_REG_DRG_LIMIT,
 						   AD9910_DRG_LIMIT_LOWER_MSK,
 						   tmp64, true);
+		case AD9910_CHANNEL_RAM:
+			tmp64 = (u64)val * MICRO + val2;
+			if (tmp64 >= AD9910_MAX_PHASE_MICRORAD)
+				return -EINVAL;
+
+			tmp64 <<= 16;
+			tmp64 = DIV_U64_ROUND_CLOSEST(tmp64, AD9910_MAX_PHASE_MICRORAD);
+			tmp64 = min(tmp64, AD9910_POW_MAX);
+			return ad9910_reg16_write(st, AD9910_REG_POW, tmp64, true);
 		default:
 			return -EINVAL;
 		}
@@ -1243,6 +1558,13 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			tmp64 = ((u64)val * MICRO + val2) << 14;
 			tmp64 = DIV_U64_ROUND_CLOSEST(tmp64, MICRO);
 			tmp64 = min(tmp64, AD9910_ASF_MAX);
+
+			if (AD9910_RAM_ENABLED(st)) {
+				FIELD_MODIFY(AD9910_PROFILE_ST_ASF_MSK,
+					     &st->reg_profile[st->profile], tmp64);
+				return 0;
+			}
+
 			tmp64 = FIELD_PREP(AD9910_PROFILE_ST_ASF_MSK, tmp64);
 			return ad9910_reg64_update(st, AD9910_REG_PROFILE(st->profile),
 						   AD9910_PROFILE_ST_ASF_MSK,
@@ -1288,12 +1610,26 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			return ad9910_reg32_update(st, AD9910_REG_DRG_RATE,
 						   AD9910_DRG_RATE_DEC_MSK,
 						   tmp32, true);
+		case AD9910_CHANNEL_RAM:
+			if (!AD9910_RAM_ENABLED(st)) {
+				FIELD_MODIFY(AD9910_PROFILE_RAM_STEP_RATE_MSK,
+					     &st->reg_profile[st->profile], tmp32);
+				return 0;
+			}
+
+			tmp64 = FIELD_PREP(AD9910_PROFILE_RAM_STEP_RATE_MSK, tmp32);
+			return ad9910_reg64_update(st, AD9910_REG_PROFILE(st->profile),
+						   AD9910_PROFILE_RAM_STEP_RATE_MSK,
+						   tmp64, true);
+
 		default:
 			return -EINVAL;
 		}
 	default:
 		return -EINVAL;
 	}
+
+	return ret;
 }
 
 static int ad9910_write_raw_get_fmt(struct iio_dev *indio_dev,
@@ -1309,6 +1645,7 @@ static int ad9910_write_raw_get_fmt(struct iio_dev *indio_dev,
 	case IIO_CHAN_INFO_SCALE:
 		switch (chan->channel) {
 		case AD9910_CHANNEL_SINGLE_TONE:
+		case AD9910_CHANNEL_RAM:
 			return IIO_VAL_INT_PLUS_MICRO;
 		case AD9910_CHANNEL_DRG_RAMP_UP:
 		case AD9910_CHANNEL_DRG_RAMP_DOWN:
@@ -1401,6 +1738,88 @@ static int ad9910_reg_access(struct iio_dev *indio_dev,
 	return ret;
 }
 
+static enum fw_upload_err ad9910_ram_fwu_prepare(struct fw_upload *fw_upload,
+						 const u8 *data, u32 size)
+{
+	struct ad9910_state *st = fw_upload->dd_handle;
+
+	if (size == 0 || size > AD9910_RAM_SIZE_MAX_BYTES ||
+	    size % AD9910_RAM_WORD_SIZE)
+		return FW_UPLOAD_ERR_INVALID_SIZE;
+
+	guard(mutex)(&st->lock);
+	st->ram_fwu_cancel = false;
+	return FW_UPLOAD_ERR_NONE;
+}
+
+static enum fw_upload_err ad9910_ram_fwu_write(struct fw_upload *fw_upload,
+					       const u8 *data, u32 offset,
+					       u32 size, u32 *written)
+{
+	struct ad9910_state *st = fw_upload->dd_handle;
+	u64 tmp64, backup;
+	int ret, ret2, idx;
+
+	if (offset != 0)
+		return FW_UPLOAD_ERR_INVALID_SIZE;
+
+	guard(mutex)(&st->lock);
+
+	if (st->ram_fwu_cancel)
+		return FW_UPLOAD_ERR_CANCELED;
+
+	if (AD9910_RAM_ENABLED(st))
+		return FW_UPLOAD_ERR_HW_ERROR;
+
+	/* ensure profile is selected */
+	ret = ad9910_profile_set(st, st->profile);
+	if (ret)
+		return FW_UPLOAD_ERR_HW_ERROR;
+
+	/* backup profile register */
+	backup = st->reg[AD9910_REG_PROFILE(st->profile)].val64;
+	tmp64 = AD9910_PROFILE_RAM_STEP_RATE_MSK |
+		FIELD_PREP(AD9910_PROFILE_RAM_START_ADDR_MSK, 0) |
+		FIELD_PREP(AD9910_PROFILE_RAM_END_ADDR_MSK,
+			   size / AD9910_RAM_WORD_SIZE - 1);
+	ret = ad9910_reg64_write(st, AD9910_REG_PROFILE(st->profile), tmp64, true);
+	if (ret)
+		return FW_UPLOAD_ERR_RW_ERROR;
+
+	/* reverse data into tx_buf[1:] */
+	for (idx = 0; idx < size; idx++)
+		st->tx_buf[size - idx] = data[idx];
+
+	/* write ram data and restore profile register */
+	ret = ad9910_spi_write(st, AD9910_REG_RAM, size, false);
+	ret2 = ad9910_reg64_write(st, AD9910_REG_PROFILE(st->profile), backup, true);
+	if (ret || ret2)
+		return FW_UPLOAD_ERR_RW_ERROR;
+
+	*written = size;
+	return FW_UPLOAD_ERR_NONE;
+}
+
+static enum fw_upload_err ad9910_ram_fwu_poll_complete(struct fw_upload *fw_upload)
+{
+	return FW_UPLOAD_ERR_NONE;
+}
+
+static void ad9910_ram_fwu_cancel(struct fw_upload *fw_upload)
+{
+	struct ad9910_state *st = fw_upload->dd_handle;
+
+	guard(mutex)(&st->lock);
+	st->ram_fwu_cancel = true;
+}
+
+static const struct fw_upload_ops ad9910_ram_fwu_ops = {
+	.prepare = ad9910_ram_fwu_prepare,
+	.write = ad9910_ram_fwu_write,
+	.poll_complete = ad9910_ram_fwu_poll_complete,
+	.cancel = ad9910_ram_fwu_cancel
+};
+
 static const struct iio_info ad9910_info = {
 	.read_raw = ad9910_read_raw,
 	.write_raw = ad9910_write_raw,
@@ -1503,6 +1922,13 @@ static int ad9910_setup(struct ad9910_state *st, struct reset_control *dev_rst)
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
 
@@ -1510,6 +1936,8 @@ static void ad9910_release(void *data)
 {
 	struct ad9910_state *st = data;
 
+	firmware_upload_unregister(st->ram_fwu);
+
 	if (!ad9910_powerdown_set(st, true))
 		return;
 
@@ -1519,6 +1947,24 @@ static void ad9910_release(void *data)
 			    true);
 }
 
+static inline void ad9910_debugfs_init(struct ad9910_state *st,
+				       struct iio_dev *indio_dev)
+{
+#ifdef CONFIG_DEBUG_FS
+	char buf[64];
+
+	/*
+	 * symlinks are created here so iio userspace tools can refer to them
+	 * as debug attributes.
+	 */
+	snprintf(buf, sizeof(buf), "/sys/class/firmware/%s/loading", st->ram_fwu_name);
+	debugfs_create_symlink("ram_loading", iio_get_debugfs_dentry(indio_dev), buf);
+
+	snprintf(buf, sizeof(buf), "/sys/class/firmware/%s/data", st->ram_fwu_name);
+	debugfs_create_symlink("ram_data", iio_get_debugfs_dentry(indio_dev), buf);
+#endif
+}
+
 static int ad9910_probe(struct spi_device *spi)
 {
 	struct reset_control *dev_rst;
@@ -1606,6 +2052,16 @@ static int ad9910_probe(struct spi_device *spi)
 	if (ret)
 		return ret;
 
+	snprintf(st->ram_fwu_name, sizeof(st->ram_fwu_name), "%s:ram",
+		 dev_name(&indio_dev->dev));
+	st->ram_fwu = firmware_upload_register(THIS_MODULE, dev, st->ram_fwu_name,
+					       &ad9910_ram_fwu_ops, st);
+	if (IS_ERR(st->ram_fwu))
+		return dev_err_probe(dev, PTR_ERR(st->ram_fwu),
+				     "failed to register to the RAM Upload\n");
+
+	ad9910_debugfs_init(st, indio_dev);
+
 	return devm_add_action_or_reset(dev, ad9910_release, st);
 }
 

-- 
2.43.0

