From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Sun, 17 May 2026 19:37:53 +0100
Subject: [PATCH v5 09/13] iio: frequency: ad9910: add RAM mode support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260517-ad9910-iio-driver-v5-9-31599c88314a@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779043094; l=21842;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=xi2uZfWodHYt7pHoERh1xg+AUqNn7Aukay6n47JQtRY=;
 b=BDcqb/hXLH+fzFtD+TtLvUbJPHgLtkemq0ARKdUO24pb1tbGM6Mq4BaorxAWlRB1ebfF0mMsQ
 c5YC2RJt4PKAQfOU9Kan5kld/7Kd4d6+OqxkQoiHALFczdOsgaZqSx8
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add RAM control channel, which includes:
- RAM data loading via firmware upload interface;
- Per-profile configuration and DDS core parameter destination as firmware
  metadata;
- Profile switching relying on profile channels;
- Sampling frequency control of the active profile;
- ram-enable-aware read/write paths that redirect single tone
  frequency/phase/amplitude access through reg_profile cache when RAM is
  active;

When RAM is enabled, the DDS profile parameters (frequency, phase,
amplitude) for the single tone mode are sourced from a shadow register
cache (reg_profile[]) since the profile registers are repurposed for RAM
control.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/Kconfig  |   3 +
 drivers/iio/frequency/ad9910.c | 356 ++++++++++++++++++++++++++++++++++++++++-
 2 files changed, 353 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/frequency/Kconfig b/drivers/iio/frequency/Kconfig
index 180e74f62d11..0b058dce2a6f 100644
--- a/drivers/iio/frequency/Kconfig
+++ b/drivers/iio/frequency/Kconfig
@@ -29,6 +29,9 @@ config AD9910
 	tristate "Analog Devices AD9910 Direct Digital Synthesizer"
 	depends on SPI
 	depends on GPIOLIB
+	select CRC32
+	select FW_LOADER
+	select FW_UPLOAD
 	help
 	  Say yes here to build support for Analog Devices AD9910
 	  1 GSPS, 14-Bit DDS with integrated DAC.
diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index 4ad80475139d..86ed350011cf 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -8,9 +8,12 @@
 #include <linux/array_size.h>
 #include <linux/bitfield.h>
 #include <linux/clk.h>
+#include <linux/crc32.h>
+#include <linux/debugfs.h>
 #include <linux/delay.h>
 #include <linux/device/devres.h>
 #include <linux/err.h>
+#include <linux/firmware.h>
 #include <linux/gpio/consumer.h>
 #include <linux/log2.h>
 #include <linux/math64.h>
@@ -147,6 +150,15 @@
 #define AD9910_PROFILE_ST_POW_MSK		GENMASK_ULL(47, 32)
 #define AD9910_PROFILE_ST_FTW_MSK		GENMASK_ULL(31, 0)
 
+/* Profile Register Format (RAM Mode) */
+#define AD9910_PROFILE_RAM_OPEN_MSK		GENMASK_ULL(61, 56)
+#define AD9910_PROFILE_RAM_STEP_RATE_MSK	GENMASK_ULL(55, 40)
+#define AD9910_PROFILE_RAM_END_ADDR_MSK		GENMASK_ULL(39, 30)
+#define AD9910_PROFILE_RAM_START_ADDR_MSK	GENMASK_ULL(23, 14)
+#define AD9910_PROFILE_RAM_NO_DWELL_HIGH_MSK	BIT_ULL(5)
+#define AD9910_PROFILE_RAM_ZERO_CROSSING_MSK	BIT_ULL(3)
+#define AD9910_PROFILE_RAM_MODE_CONTROL_MSK	GENMASK_ULL(2, 0)
+
 /* Device constants */
 #define AD9910_PI_NANORAD		3141592653UL
 
@@ -160,6 +172,16 @@
 #define AD9910_STEP_RATE_MAX		GENMASK(15, 0)
 #define AD9910_NUM_PROFILES		8
 
+#define AD9910_RAM_FW_MAGIC		0x00AD9910
+#define AD9910_RAM_FW_V1		0x0001
+#define AD9910_RAM_SIZE_MAX_WORDS	1024
+#define AD9910_RAM_WORD_SIZE		sizeof(u32)
+#define AD9910_RAM_SIZE_MAX_BYTES	(AD9910_RAM_SIZE_MAX_WORDS * AD9910_RAM_WORD_SIZE)
+#define AD9910_RAM_ADDR_MAX		(AD9910_RAM_SIZE_MAX_WORDS - 1)
+
+#define AD9910_RAM_ENABLED(st)		\
+	FIELD_GET(AD9910_CFR1_RAM_ENABLE_MSK, (st)->reg[AD9910_REG_CFR1].val32)
+
 /* PLL constants */
 #define AD9910_PLL_MIN_N		12
 #define AD9910_PLL_MAX_N		127
@@ -191,7 +213,7 @@
 #define AD9910_REFDIV2_MAX_FREQ_HZ	(1900 * HZ_PER_MHZ)
 
 #define AD9910_SPI_DATA_IDX		1
-#define AD9910_SPI_DATA_LEN_MAX		sizeof(__be64)
+#define AD9910_SPI_DATA_LEN_MAX		AD9910_RAM_SIZE_MAX_BYTES
 #define AD9910_SPI_MESSAGE_LEN_MAX	(AD9910_SPI_DATA_IDX + AD9910_SPI_DATA_LEN_MAX)
 #define AD9910_SPI_READ_MSK		BIT(7)
 #define AD9910_SPI_ADDR_MSK		GENMASK(4, 0)
@@ -212,6 +234,7 @@
  * @AD9910_CHANNEL_DRG: Digital Ramp Generator output channel
  * @AD9910_CHANNEL_DRG_RAMP_UP: DRG ramp up channel
  * @AD9910_CHANNEL_DRG_RAMP_DOWN: DRG ramp down channel
+ * @AD9910_CHANNEL_RAM: RAM control output channel
  */
 enum ad9910_channel {
 	AD9910_CHANNEL_PHY = 100,
@@ -227,6 +250,7 @@ enum ad9910_channel {
 	AD9910_CHANNEL_DRG = 130,
 	AD9910_CHANNEL_DRG_RAMP_UP = 131,
 	AD9910_CHANNEL_DRG_RAMP_DOWN = 132,
+	AD9910_CHANNEL_RAM = 140,
 };
 
 /**
@@ -244,6 +268,29 @@ enum ad9910_destination {
 	AD9910_DEST_POLAR,
 };
 
+/**
+ * struct ad9910_ram_fw - AD9910 RAM firmware format
+ * @magic:	Magic number for RAM firmware validation
+ * @version:	Firmware version number
+ * @wcount:	Number of RAM words to be written
+ * @crc:	CRC32 checksum of the RAM data for integrity verification
+ * @cfr1:	Value of CFR1 register to be configured (not all fields are
+ *		used, but this is included here for convenience)
+ * @profiles:	Array of RAM profile configurations
+ * @words:	Array of RAM words to be written. Data pattern should be set in
+ *		reverse order and wcount specifies the number of words in this
+ *		array
+ */
+struct ad9910_ram_fw {
+	__be32 magic;
+	__be16 version;
+	__be16 wcount;
+	__be32 crc;
+	__be32 cfr1;
+	__be64 profiles[AD9910_NUM_PROFILES];
+	__be32 words[] __counted_by_be(wcount);
+} __packed;
+
 enum {
 	AD9910_CHAN_IDX_PHY,
 	AD9910_CHAN_IDX_PROFILE_0,
@@ -258,6 +305,7 @@ enum {
 	AD9910_CHAN_IDX_DRG,
 	AD9910_CHAN_IDX_DRG_RAMP_UP,
 	AD9910_CHAN_IDX_DRG_RAMP_DOWN,
+	AD9910_CHAN_IDX_RAM,
 };
 
 enum {
@@ -290,6 +338,7 @@ union ad9910_reg {
 struct ad9910_state {
 	struct spi_device *spi;
 	struct clk *refclk;
+	struct fw_upload *ram_fwu;
 
 	struct gpio_desc *gpio_pwdown;
 	struct gpio_desc *gpio_update;
@@ -298,12 +347,22 @@ struct ad9910_state {
 	/* cached registers */
 	union ad9910_reg reg[AD9910_REG_NUM_CACHED];
 
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
 	/*
 	 * RAM loading requires a reasonable amount of bytes, at the same time
 	 * DMA capable SPI drivers requires the transfer buffers to live in
@@ -327,6 +386,22 @@ static inline u64 ad9910_rational_scale(u64 input, u64 scale, u64 reference)
 	return mul_u64_add_u64_div_u64(input, scale, reference >> 1, reference);
 }
 
+static inline u64 ad9910_ram_profile_val(struct ad9910_state *st)
+{
+	if (AD9910_RAM_ENABLED(st))
+		return st->reg[AD9910_REG_PROFILE(st->profile)].val64;
+	else
+		return st->reg_profile[st->profile];
+}
+
+static inline u64 ad9910_st_profile_val(struct ad9910_state *st, u8 profile)
+{
+	if (AD9910_RAM_ENABLED(st))
+		return st->reg_profile[profile];
+	else
+		return st->reg[AD9910_REG_PROFILE(profile)].val64;
+}
+
 static int ad9910_io_update(struct ad9910_state *st)
 {
 	if (st->gpio_update) {
@@ -1015,6 +1090,18 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.ext_info = ad9910_drg_ramp_ext_info,
 		.parent = &ad9910_channels[AD9910_CHAN_IDX_DRG],
 	},
+	[AD9910_CHAN_IDX_RAM] = {
+		.type = IIO_ALTVOLTAGE,
+		.indexed = 1,
+		.output = 1,
+		.channel = AD9910_CHANNEL_RAM,
+		.address = AD9910_CHAN_IDX_RAM,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE) |
+				      BIT(IIO_CHAN_INFO_FREQUENCY) |
+				      BIT(IIO_CHAN_INFO_PHASE) |
+				      BIT(IIO_CHAN_INFO_SAMP_FREQ),
+		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
+	},
 };
 
 static int ad9910_read_raw(struct iio_dev *indio_dev,
@@ -1043,6 +1130,10 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
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
@@ -1052,7 +1143,7 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 		case AD9910_CHANNEL_PROFILE_0 ... AD9910_CHANNEL_PROFILE_7:
 			tmp32 = chan->channel - AD9910_CHANNEL_PROFILE_0;
 			tmp64 = FIELD_GET(AD9910_PROFILE_ST_FTW_MSK,
-					  st->reg[AD9910_REG_PROFILE(tmp32)].val64);
+					  ad9910_st_profile_val(st, tmp32));
 			break;
 		case AD9910_CHANNEL_DRG_RAMP_UP:
 			ret = ad9910_drg_destination_assert(st, AD9910_DEST_FREQUENCY);
@@ -1070,6 +1161,9 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 			tmp64 = FIELD_GET(AD9910_DRG_LIMIT_LOWER_MSK,
 					  st->reg[AD9910_REG_DRG_LIMIT].val64);
 			break;
+		case AD9910_CHANNEL_RAM:
+			tmp64 = st->reg[AD9910_REG_FTW].val32;
+			break;
 		default:
 			return -EINVAL;
 		}
@@ -1082,7 +1176,7 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 		case AD9910_CHANNEL_PROFILE_0 ... AD9910_CHANNEL_PROFILE_7:
 			tmp32 = chan->channel - AD9910_CHANNEL_PROFILE_0;
 			tmp64 = FIELD_GET(AD9910_PROFILE_ST_POW_MSK,
-					  st->reg[AD9910_REG_PROFILE(tmp32)].val64);
+					  ad9910_st_profile_val(st, tmp32));
 			tmp32 = (tmp64 * AD9910_MAX_PHASE_MICRORAD) >> 16;
 			*val = tmp32 / MICRO;
 			*val2 = tmp32 % MICRO;
@@ -1107,6 +1201,12 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 			tmp64 = (tmp64 * AD9910_PI_NANORAD) >> 31;
 			*val = div_s64_rem(tmp64, NANO, val2);
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
@@ -1115,7 +1215,7 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 		case AD9910_CHANNEL_PROFILE_0 ... AD9910_CHANNEL_PROFILE_7:
 			tmp32 = chan->channel - AD9910_CHANNEL_PROFILE_0;
 			tmp64 = FIELD_GET(AD9910_PROFILE_ST_ASF_MSK,
-					  st->reg[AD9910_REG_PROFILE(tmp32)].val64);
+					  ad9910_st_profile_val(st, tmp32));
 			*val = 0;
 			*val2 = tmp64 * MICRO >> 14;
 			return IIO_VAL_INT_PLUS_MICRO;
@@ -1155,6 +1255,10 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
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
@@ -1176,7 +1280,7 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 	struct ad9910_state *st = iio_priv(indio_dev);
 	u64 tmp64;
 	u32 tmp32;
-	int ret;
+	int ret, i;
 
 	guard(mutex)(&st->lock);
 
@@ -1202,6 +1306,41 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			return ad9910_reg32_update(st, AD9910_REG_CFR2,
 						   AD9910_CFR2_DRG_ENABLE_MSK,
 						   tmp32, true);
+		case AD9910_CHANNEL_RAM:
+			if (AD9910_RAM_ENABLED(st) == !!val)
+				return 0;
+
+			/* swap profile configs */
+			for (i = 0; i < AD9910_NUM_PROFILES; i++) {
+				tmp64 = st->reg[AD9910_REG_PROFILE(i)].val64;
+				ret = ad9910_reg64_write(st,
+							 AD9910_REG_PROFILE(i),
+							 st->reg_profile[i],
+							 false);
+				if (ret)
+					break;
+				st->reg_profile[i] = tmp64;
+			}
+
+			if (ret) {
+				/*
+				 * After the write failure, profiles 0..i-1 were
+				 * already swapped in SW, but Hw registers are
+				 * still pending an IO update, so swap them back
+				 * in SW to keep the state consistent.
+				 */
+				while (i--) {
+					tmp64 = st->reg[AD9910_REG_PROFILE(i)].val64;
+					st->reg[AD9910_REG_PROFILE(i)].val64 = st->reg_profile[i];
+					st->reg_profile[i] = tmp64;
+				}
+				return ret;
+			}
+
+			tmp32 = FIELD_PREP(AD9910_CFR1_RAM_ENABLE_MSK, !!val);
+			return ad9910_reg32_update(st, AD9910_REG_CFR1,
+						   AD9910_CFR1_RAM_ENABLE_MSK,
+						   tmp32, true);
 		default:
 			return -EINVAL;
 		}
@@ -1215,6 +1354,11 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 		switch (chan->channel) {
 		case AD9910_CHANNEL_PROFILE_0 ... AD9910_CHANNEL_PROFILE_7:
 			tmp32 = chan->channel - AD9910_CHANNEL_PROFILE_0;
+			if (AD9910_RAM_ENABLED(st)) {
+				FIELD_MODIFY(AD9910_PROFILE_ST_FTW_MSK,
+					     &st->reg_profile[tmp32], tmp64);
+				return 0;
+			}
 			tmp64 = FIELD_PREP(AD9910_PROFILE_ST_FTW_MSK, tmp64);
 			return ad9910_reg64_update(st, AD9910_REG_PROFILE(tmp32),
 						   AD9910_PROFILE_ST_FTW_MSK,
@@ -1241,6 +1385,8 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			return ad9910_reg64_update(st, AD9910_REG_DRG_LIMIT,
 						   AD9910_DRG_LIMIT_LOWER_MSK,
 						   tmp64, true);
+		case AD9910_CHANNEL_RAM:
+			return ad9910_reg32_write(st, AD9910_REG_FTW, tmp64, true);
 		default:
 			return -EINVAL;
 		}
@@ -1258,6 +1404,13 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			tmp64 <<= 16;
 			tmp64 = DIV_U64_ROUND_CLOSEST(tmp64, AD9910_MAX_PHASE_MICRORAD);
 			tmp64 = min(tmp64, AD9910_POW_MAX);
+
+			if (AD9910_RAM_ENABLED(st)) {
+				FIELD_MODIFY(AD9910_PROFILE_ST_POW_MSK,
+					     &st->reg_profile[tmp32], tmp64);
+				return 0;
+			}
+
 			tmp64 = FIELD_PREP(AD9910_PROFILE_ST_POW_MSK, tmp64);
 			return ad9910_reg64_update(st, AD9910_REG_PROFILE(tmp32),
 						   AD9910_PROFILE_ST_POW_MSK,
@@ -1296,6 +1449,15 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
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
@@ -1309,6 +1471,13 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			tmp64 = ((u64)val * MICRO + val2) << 14;
 			tmp64 = DIV_U64_ROUND_CLOSEST(tmp64, MICRO);
 			tmp64 = min(tmp64, AD9910_ASF_MAX);
+
+			if (AD9910_RAM_ENABLED(st)) {
+				FIELD_MODIFY(AD9910_PROFILE_ST_ASF_MSK,
+					     &st->reg_profile[tmp32], tmp64);
+				return 0;
+			}
+
 			tmp64 = FIELD_PREP(AD9910_PROFILE_ST_ASF_MSK, tmp64);
 			return ad9910_reg64_update(st, AD9910_REG_PROFILE(tmp32),
 						   AD9910_PROFILE_ST_ASF_MSK,
@@ -1369,6 +1538,17 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
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
 		default:
 			return -EINVAL;
 		}
@@ -1390,6 +1570,7 @@ static int ad9910_write_raw_get_fmt(struct iio_dev *indio_dev,
 	case IIO_CHAN_INFO_SCALE:
 		switch (chan->channel) {
 		case AD9910_CHANNEL_PROFILE_0 ... AD9910_CHANNEL_PROFILE_7:
+		case AD9910_CHANNEL_RAM:
 			return IIO_VAL_INT_PLUS_MICRO;
 		case AD9910_CHANNEL_DRG_RAMP_UP:
 		case AD9910_CHANNEL_DRG_RAMP_DOWN:
@@ -1466,6 +1647,7 @@ static const char * const ad9910_channel_str[] = {
 	[AD9910_CHAN_IDX_DRG] = "digital_ramp_generator",
 	[AD9910_CHAN_IDX_DRG_RAMP_UP] = "digital_ramp_up",
 	[AD9910_CHAN_IDX_DRG_RAMP_DOWN] = "digital_ramp_down",
+	[AD9910_CHAN_IDX_RAM] = "ram_control",
 };
 
 static int ad9910_read_label(struct iio_dev *indio_dev,
@@ -1475,6 +1657,126 @@ static int ad9910_read_label(struct iio_dev *indio_dev,
 	return sysfs_emit(label, "%s\n", ad9910_channel_str[chan->address]);
 }
 
+static enum fw_upload_err ad9910_ram_fwu_prepare(struct fw_upload *fw_upload,
+						 const u8 *data, u32 size)
+{
+	struct ad9910_state *st = fw_upload->dd_handle;
+	const struct ad9910_ram_fw *fw_data = (const struct ad9910_ram_fw *)data;
+	size_t wcount, bcount;
+
+	if (size < sizeof(struct ad9910_ram_fw))
+		return FW_UPLOAD_ERR_INVALID_SIZE;
+
+	if (get_unaligned_be32(&fw_data->magic) != AD9910_RAM_FW_MAGIC)
+		return FW_UPLOAD_ERR_FW_INVALID;
+
+	if (get_unaligned_be16(&fw_data->version) != AD9910_RAM_FW_V1)
+		return FW_UPLOAD_ERR_FW_INVALID;
+
+	wcount = get_unaligned_be16(&fw_data->wcount);
+	bcount = size - sizeof(struct ad9910_ram_fw);
+	if (wcount > AD9910_RAM_SIZE_MAX_WORDS ||
+	    bcount != (wcount * AD9910_RAM_WORD_SIZE))
+		return FW_UPLOAD_ERR_INVALID_SIZE;
+
+	bcount += sizeof(fw_data->cfr1) + sizeof(fw_data->profiles);
+	if (crc32(0, &fw_data->cfr1, bcount) != get_unaligned_be32(&fw_data->crc))
+		return FW_UPLOAD_ERR_FW_INVALID;
+
+	guard(mutex)(&st->lock);
+	st->ram_fwu_cancel = false;
+
+	return FW_UPLOAD_ERR_NONE;
+}
+
+static enum fw_upload_err ad9910_ram_fwu_write(struct fw_upload *fw_upload,
+					       const u8 *data, u32 offset,
+					       u32 size, u32 *written)
+{
+	const struct ad9910_ram_fw *fw_data = (const struct ad9910_ram_fw *)data;
+	struct ad9910_state *st = fw_upload->dd_handle;
+	int ret, ret2, idx, wcount;
+	u64 tmp64, backup;
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
+	for (idx = 0; idx < AD9910_NUM_PROFILES; idx++)
+		st->reg_profile[idx] = get_unaligned_be64(&fw_data->profiles[idx]) |
+				       AD9910_PROFILE_RAM_OPEN_MSK;
+
+	ret = ad9910_reg32_update(st, AD9910_REG_CFR1,
+				  AD9910_CFR1_RAM_PLAYBACK_DEST_MSK |
+				  AD9910_CFR1_INT_PROFILE_CTL_MSK,
+				  get_unaligned_be32(&fw_data->cfr1), true);
+	if (ret)
+		return FW_UPLOAD_ERR_RW_ERROR;
+
+	wcount = get_unaligned_be16(&fw_data->wcount);
+	if (!wcount) {
+		*written = size;
+		return FW_UPLOAD_ERR_NONE; /* nothing else to write */
+	}
+
+	ret = ad9910_profile_set(st, st->profile);
+	if (ret)
+		return FW_UPLOAD_ERR_HW_ERROR;
+
+	/* backup profile register and update it with required address range */
+	backup = st->reg[AD9910_REG_PROFILE(st->profile)].val64;
+	tmp64 = AD9910_PROFILE_RAM_STEP_RATE_MSK |
+		FIELD_PREP(AD9910_PROFILE_RAM_START_ADDR_MSK, 0) |
+		FIELD_PREP(AD9910_PROFILE_RAM_END_ADDR_MSK, wcount - 1);
+	ret = ad9910_reg64_write(st, AD9910_REG_PROFILE(st->profile), tmp64, true);
+	if (ret)
+		return FW_UPLOAD_ERR_RW_ERROR;
+
+	memcpy(&st->tx_buf[1], fw_data->words, wcount * AD9910_RAM_WORD_SIZE);
+
+	/* write ram data and restore profile register */
+	ret = ad9910_spi_write(st, AD9910_REG_RAM,
+			       wcount * AD9910_RAM_WORD_SIZE, false);
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
+static void ad9910_ram_fwu_unregister(void *data)
+{
+	firmware_upload_unregister(data);
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
@@ -1601,9 +1903,33 @@ static int ad9910_setup(struct device *dev, struct ad9910_state *st,
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
 
+static inline void ad9910_debugfs_init(struct ad9910_state *st,
+				       struct iio_dev *indio_dev)
+{
+	struct dentry *d = iio_get_debugfs_dentry(indio_dev);
+	char buf[64];
+
+	/*
+	 * symlinks are created here so iio userspace tools can refer to them
+	 * as debug attributes.
+	 */
+	snprintf(buf, sizeof(buf), "/sys/class/firmware/%s/loading", st->ram_fwu_name);
+	debugfs_create_symlink("ram_loading", d, buf);
+
+	snprintf(buf, sizeof(buf), "/sys/class/firmware/%s/data", st->ram_fwu_name);
+	debugfs_create_symlink("ram_data", d, buf);
+}
+
 static int ad9910_probe(struct spi_device *spi)
 {
 	static const char * const supplies[] = {
@@ -1688,7 +2014,25 @@ static int ad9910_probe(struct spi_device *spi)
 	if (ret)
 		return dev_err_probe(dev, ret, "device setup failed\n");
 
-	return devm_iio_device_register(dev, indio_dev);
+	snprintf(st->ram_fwu_name, sizeof(st->ram_fwu_name), "%s:ram",
+		 dev_name(&indio_dev->dev));
+	st->ram_fwu = firmware_upload_register(THIS_MODULE, dev, st->ram_fwu_name,
+					       &ad9910_ram_fwu_ops, st);
+	if (IS_ERR(st->ram_fwu))
+		return dev_err_probe(dev, PTR_ERR(st->ram_fwu),
+				     "failed to register ram upload ops\n");
+
+	ret = devm_add_action_or_reset(dev, ad9910_ram_fwu_unregister, st->ram_fwu);
+	if (ret)
+		return dev_err_probe(dev, ret,
+				     "failed to add ram upload unregister action\n");
+
+	ret = devm_iio_device_register(dev, indio_dev);
+	if (ret)
+		return ret;
+
+	ad9910_debugfs_init(st, indio_dev);
+	return 0;
 }
 
 static const struct spi_device_id ad9910_id[] = {

-- 
2.43.0

