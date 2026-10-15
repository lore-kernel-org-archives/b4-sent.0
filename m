From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Thu, 15 Oct 2026 13:49:48 -0300
Subject: [PATCH 08/10] iio: frequency: ad9910: support iio backend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-ad9910-backend-support-v1-8-3c21648c8e26@analog.com>
References: <20261015-ad9910-backend-support-v1-0-3c21648c8e26@analog.com>
In-Reply-To: <20261015-ad9910-backend-support-v1-0-3c21648c8e26@analog.com>
To: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux@analog.com, devicetree@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-doc@vger.kernel.org, 
 Jonathan Cameron <jonathan.cameron@oss.qualcomm.com>
Cc: Olivier Moysan <olivier.moysan@foss.st.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792082993; l=17762;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=P3p6O7BPPm0xM0t+cQXxnAtC356E/y9VGIItaRf5Jio=;
 b=2JD1Vk2ih7tQUG2b0n6l9onQuC1aCD5eMpryRlqLm+pc5ygz3bMzoj1T/veo6AfuXioFftGtR
 LUOS3LGpUgsBaHh34L0KDO9c6jvZ8BMF59TUJuTeMuVxnV1g4J68qiD
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AD9910 parallel data port allows modulation of the DDS core parameters
at up to the PDCLK rate, which requires a high-speed data source. Add
support for an optional IIO backend that provides such interface, with
data streamed into the device through an output buffer.

The parallel port channels get scan indexes and scan types according to
the data destination: 14-bit amplitude, 16-bit phase, 16-bit frequency,
or the 8-bit amplitude and phase pair for polar modulation. As only one
destination can be active at a time, this is enforced by the available
scan masks. On buffer enable, the destination is configured in the
backend and the parallel data port is enabled. The sampling_frequency
attribute of the parallel port channels controls the backend data rate.

The backend is also notified about profile changes, as it may drive the
PROFILE[2:0] pins, and the debugfs source attributes now consider the
parallel data port when reporting which channel controls each DDS core
parameter.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/Kconfig  |   1 +
 drivers/iio/frequency/ad9910.c | 215 +++++++++++++++++++++++++++++++++++++++--
 2 files changed, 210 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/frequency/Kconfig b/drivers/iio/frequency/Kconfig
index f7f5c3cce005..8480076c779f 100644
--- a/drivers/iio/frequency/Kconfig
+++ b/drivers/iio/frequency/Kconfig
@@ -32,6 +32,7 @@ config AD9910
 	select CRC32
 	select FW_LOADER
 	select FW_UPLOAD
+	select IIO_BACKEND
 	help
 	  Say yes here to build support for Analog Devices AD9910
 	  1 GSPS, 14-Bit DDS with integrated DAC.
diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index 3d517879dee3..39d65dafd5a1 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -31,6 +31,7 @@
 #include <linux/units.h>
 #include <linux/unaligned.h>
 
+#include <linux/iio/backend.h>
 #include <linux/iio/iio.h>
 #include <linux/iio/sysfs.h>
 
@@ -300,6 +301,15 @@ struct ad9910_ram_fw {
 	__be32 words[] __counted_by_be(wcount);
 } __packed;
 
+enum {
+	AD9910_SCAN_IDX_AMP = 0,
+	AD9910_SCAN_IDX_PHASE,
+	AD9910_SCAN_IDX_FREQ,
+	/* polar phase goes first, as it is placed in the lower byte, D[7:0] */
+	AD9910_SCAN_IDX_POLAR_PHASE,
+	AD9910_SCAN_IDX_POLAR_AMP,
+};
+
 enum {
 	AD9910_POWERDOWN,
 	AD9910_DWELL_EN,
@@ -331,6 +341,7 @@ struct ad9910_state {
 	struct gpio_desc *gpio_pwdown;
 	struct gpio_desc *gpio_update;
 	struct gpio_descs *gpio_profile;
+	struct iio_backend *back;
 
 	s64 ramp_up_time_ns;
 	s64 ramp_down_time_ns;
@@ -350,6 +361,7 @@ struct ad9910_state {
 
 	struct ad9910_data data;
 	u8 profile;
+	u8 scan_mask;
 
 	bool ram_fwu_cancel;
 	char ram_fwu_name[20];
@@ -568,6 +580,11 @@ static int ad9910_set_sysclk_freq(struct ad9910_state *st, u32 freq_hz,
 
 	st->data.sysclk_freq_hz = sysclk_freq_hz;
 
+	if (st->back)
+		return iio_backend_set_sampling_freq(st->back,
+						     AD9910_CHAN_IDX_PHY,
+						     sysclk_freq_hz);
+
 	return 0;
 }
 
@@ -579,6 +596,10 @@ static int ad9910_profile_set(struct ad9910_state *st, u8 profile)
 	values[0] = profile;
 	gpiod_multi_set_value_cansleep(st->gpio_profile, values);
 
+	if (st->back)
+		return iio_backend_chan_enable(st->back,
+					       AD9910_CHAN_IDX_PROFILE_0 + profile);
+
 	return 0;
 }
 
@@ -1016,6 +1037,7 @@ static const struct iio_chan_spec_ext_info ad9910_osk_ext_info[] = {
 	.output = 1,						\
 	.channel = AD9910_CHANNEL_PROFILE_ ## idx,		\
 	.address = AD9910_CHAN_IDX_PROFILE_ ## idx,		\
+	.scan_index = -1,					\
 	.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE) |	\
 			      BIT(IIO_CHAN_INFO_FREQUENCY) |	\
 			      BIT(IIO_CHAN_INFO_PHASE) |	\
@@ -1030,6 +1052,7 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.output = 1,
 		.channel = AD9910_CHANNEL_PHY,
 		.address = AD9910_CHAN_IDX_PHY,
+		.scan_index = -1,
 		.info_mask_separate = BIT(IIO_CHAN_INFO_SAMP_FREQ),
 		.info_mask_shared_by_type = BIT(IIO_CHAN_INFO_SCALE),
 		.ext_info = ad9910_phy_ext_info,
@@ -1048,6 +1071,14 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.output = 1,
 		.channel = AD9910_CHANNEL_PARALLEL,
 		.address = AD9910_CHAN_IDX_PARALLEL_AMP,
+		.scan_index = AD9910_SCAN_IDX_AMP,
+		.scan_type = {
+			.sign = 'u',
+			.realbits = 14,
+			.storagebits = 16,
+			.shift = 2,
+		},
+		.info_mask_separate = BIT(IIO_CHAN_INFO_SAMP_FREQ),
 		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
 	},
 	[AD9910_CHAN_IDX_PARALLEL_PHASE] = {
@@ -1056,7 +1087,15 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.output = 1,
 		.channel = AD9910_CHANNEL_PARALLEL,
 		.address = AD9910_CHAN_IDX_PARALLEL_PHASE,
-		.info_mask_separate = BIT(IIO_CHAN_INFO_SCALE),
+		.scan_index = AD9910_SCAN_IDX_PHASE,
+		.scan_type = {
+			.sign = 'u',
+			.realbits = 16,
+			.storagebits = 16,
+			.shift = 0,
+		},
+		.info_mask_separate = BIT(IIO_CHAN_INFO_SAMP_FREQ) |
+				      BIT(IIO_CHAN_INFO_SCALE),
 		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
 	},
 	[AD9910_CHAN_IDX_PARALLEL_FREQ] = {
@@ -1065,7 +1104,15 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.output = 1,
 		.channel = AD9910_CHANNEL_PARALLEL,
 		.address = AD9910_CHAN_IDX_PARALLEL_FREQ,
-		.info_mask_separate = BIT(IIO_CHAN_INFO_OFFSET) |
+		.scan_index = AD9910_SCAN_IDX_FREQ,
+		.scan_type = {
+			.sign = 'u',
+			.realbits = 16,
+			.storagebits = 16,
+			.shift = 0,
+		},
+		.info_mask_separate = BIT(IIO_CHAN_INFO_SAMP_FREQ) |
+				      BIT(IIO_CHAN_INFO_OFFSET) |
 				      BIT(IIO_CHAN_INFO_SCALE),
 		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
 	},
@@ -1075,7 +1122,15 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.output = 1,
 		.channel = AD9910_CHANNEL_PARALLEL_POLAR,
 		.address = AD9910_CHAN_IDX_PARALLEL_POLAR_AMP,
-		.info_mask_separate = BIT(IIO_CHAN_INFO_OFFSET) |
+		.scan_index = AD9910_SCAN_IDX_POLAR_AMP,
+		.scan_type = {
+			.sign = 'u',
+			.realbits = 8,
+			.storagebits = 8,
+			.shift = 0,
+		},
+		.info_mask_separate = BIT(IIO_CHAN_INFO_SAMP_FREQ) |
+				      BIT(IIO_CHAN_INFO_OFFSET) |
 				      BIT(IIO_CHAN_INFO_SCALE),
 		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
 	},
@@ -1085,7 +1140,15 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.output = 1,
 		.channel = AD9910_CHANNEL_PARALLEL_POLAR,
 		.address = AD9910_CHAN_IDX_PARALLEL_POLAR_PHASE,
-		.info_mask_separate = BIT(IIO_CHAN_INFO_OFFSET) |
+		.scan_index = AD9910_SCAN_IDX_POLAR_PHASE,
+		.scan_type = {
+			.sign = 'u',
+			.realbits = 8,
+			.storagebits = 8,
+			.shift = 0,
+		},
+		.info_mask_separate = BIT(IIO_CHAN_INFO_SAMP_FREQ) |
+				      BIT(IIO_CHAN_INFO_OFFSET) |
 				      BIT(IIO_CHAN_INFO_SCALE),
 		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
 	},
@@ -1095,6 +1158,7 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.output = 1,
 		.channel = AD9910_CHANNEL_DRG,
 		.address = AD9910_CHAN_IDX_DRG_FREQ,
+		.scan_index = -1,
 		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE) |
 				      BIT(IIO_CHAN_INFO_SCALE),
 		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
@@ -1105,6 +1169,7 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.output = 1,
 		.channel = AD9910_CHANNEL_DRG,
 		.address = AD9910_CHAN_IDX_DRG_PHASE,
+		.scan_index = -1,
 		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE) |
 				      BIT(IIO_CHAN_INFO_SCALE),
 		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
@@ -1115,6 +1180,7 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.output = 1,
 		.channel = AD9910_CHANNEL_DRG,
 		.address = AD9910_CHAN_IDX_DRG_AMP,
+		.scan_index = -1,
 		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE) |
 				      BIT(IIO_CHAN_INFO_SCALE),
 		.parent = &ad9910_channels[AD9910_CHAN_IDX_PHY],
@@ -1125,6 +1191,7 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.output = 1,
 		.channel = AD9910_CHANNEL_DRG_RAMP_UP,
 		.address = AD9910_CHAN_IDX_DRG_FREQ_RAMP_UP,
+		.scan_index = -1,
 		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
 				      BIT(IIO_CHAN_INFO_SAMP_FREQ) |
 				      BIT(IIO_CHAN_INFO_INT_TIME),
@@ -1137,6 +1204,7 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.output = 1,
 		.channel = AD9910_CHANNEL_DRG_RAMP_DOWN,
 		.address = AD9910_CHAN_IDX_DRG_FREQ_RAMP_DOWN,
+		.scan_index = -1,
 		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
 				      BIT(IIO_CHAN_INFO_SAMP_FREQ) |
 				      BIT(IIO_CHAN_INFO_INT_TIME),
@@ -1149,6 +1217,7 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.output = 1,
 		.channel = AD9910_CHANNEL_DRG_RAMP_UP,
 		.address = AD9910_CHAN_IDX_DRG_PHASE_RAMP_UP,
+		.scan_index = -1,
 		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
 				      BIT(IIO_CHAN_INFO_SAMP_FREQ) |
 				      BIT(IIO_CHAN_INFO_INT_TIME),
@@ -1161,6 +1230,7 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.output = 1,
 		.channel = AD9910_CHANNEL_DRG_RAMP_DOWN,
 		.address = AD9910_CHAN_IDX_DRG_PHASE_RAMP_DOWN,
+		.scan_index = -1,
 		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
 				      BIT(IIO_CHAN_INFO_SAMP_FREQ) |
 				      BIT(IIO_CHAN_INFO_INT_TIME),
@@ -1173,6 +1243,7 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.output = 1,
 		.channel = AD9910_CHANNEL_DRG_RAMP_UP,
 		.address = AD9910_CHAN_IDX_DRG_AMP_RAMP_UP,
+		.scan_index = -1,
 		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
 				      BIT(IIO_CHAN_INFO_SAMP_FREQ) |
 				      BIT(IIO_CHAN_INFO_INT_TIME),
@@ -1185,6 +1256,7 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.output = 1,
 		.channel = AD9910_CHANNEL_DRG_RAMP_DOWN,
 		.address = AD9910_CHAN_IDX_DRG_AMP_RAMP_DOWN,
+		.scan_index = -1,
 		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
 				      BIT(IIO_CHAN_INFO_SAMP_FREQ) |
 				      BIT(IIO_CHAN_INFO_INT_TIME),
@@ -1197,6 +1269,7 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.output = 1,
 		.channel = AD9910_CHANNEL_RAM,
 		.address = AD9910_CHAN_IDX_RAM,
+		.scan_index = -1,
 		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE) |
 				      BIT(IIO_CHAN_INFO_FREQUENCY) |
 				      BIT(IIO_CHAN_INFO_PHASE) |
@@ -1209,6 +1282,7 @@ static const struct iio_chan_spec ad9910_channels[] = {
 		.output = 1,
 		.channel = AD9910_CHANNEL_OSK,
 		.address = AD9910_CHAN_IDX_OSK,
+		.scan_index = -1,
 		.info_mask_separate = BIT(IIO_CHAN_INFO_ENABLE) |
 				      BIT(IIO_CHAN_INFO_RAW) |
 				      BIT(IIO_CHAN_INFO_SAMP_FREQ),
@@ -1322,6 +1396,12 @@ static int ad9910_read_raw(struct iio_dev *indio_dev,
 		case AD9910_CHANNEL_PHY:
 			*val = st->data.sysclk_freq_hz;
 			return IIO_VAL_INT;
+		case AD9910_CHANNEL_PARALLEL:
+		case AD9910_CHANNEL_PARALLEL_POLAR:
+			if (!st->back)
+				return -EOPNOTSUPP;
+
+			return iio_backend_read_raw(st->back, chan, val, val2, info);
 		case AD9910_CHANNEL_DRG_RAMP_UP:
 			tmp32 = FIELD_GET(AD9910_DRG_RATE_INC_MSK,
 					  st->reg[AD9910_REG_DRG_RATE].val32);
@@ -1631,6 +1711,17 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 		if (chan->channel == AD9910_CHANNEL_PHY)
 			return ad9910_set_sysclk_freq(st, val, true);
 
+		if (chan->channel == AD9910_CHANNEL_PARALLEL ||
+		    chan->channel == AD9910_CHANNEL_PARALLEL_POLAR) {
+			if (!st->back)
+				return -EOPNOTSUPP;
+			if (val < 0)
+				return -EINVAL;
+
+			return iio_backend_set_sampling_freq(st->back,
+							     chan->address, val);
+		}
+
 		if (val < 0 || val2 < 0 || val > st->data.sysclk_freq_hz / 4)
 			return -EINVAL;
 
@@ -1773,9 +1864,14 @@ static int ad9910_write_raw_get_fmt(struct iio_dev *indio_dev,
 			return -EINVAL;
 		}
 	case IIO_CHAN_INFO_SAMP_FREQ:
-		if (chan->channel == AD9910_CHANNEL_PHY)
+		switch (chan->channel) {
+		case AD9910_CHANNEL_PHY:
+		case AD9910_CHANNEL_PARALLEL:
+		case AD9910_CHANNEL_PARALLEL_POLAR:
 			return IIO_VAL_INT;
-		return IIO_VAL_INT_PLUS_MICRO;
+		default:
+			return IIO_VAL_INT_PLUS_MICRO;
+		}
 	case IIO_CHAN_INFO_SCALE:
 		return IIO_VAL_INT_PLUS_NANO;
 	case IIO_CHAN_INFO_OFFSET:
@@ -2164,6 +2260,12 @@ static inline const char *ad9910_frequency_source_get(struct ad9910_state *st)
 				 st->reg[AD9910_REG_CFR2].val32))
 		return ad9910_channel_str[AD9910_CHAN_IDX_DRG_FREQ];
 
+	/* Parallel data port enabled and data destination is frequency */
+	mode_en = FIELD_GET(AD9910_CFR2_PARALLEL_DATA_PORT_EN_MSK,
+			    st->reg[AD9910_REG_CFR2].val32);
+	if (mode_en && (st->scan_mask & BIT(AD9910_SCAN_IDX_FREQ)))
+		return ad9910_channel_str[AD9910_CHAN_IDX_PARALLEL_FREQ];
+
 	/* FTW: RAM enabled and data destination is phase, amplitude, or polar */
 	if (ram_en)
 		return ad9910_channel_str[AD9910_CHAN_IDX_RAM];
@@ -2204,6 +2306,16 @@ static inline const char *ad9910_phase_source_get(struct ad9910_state *st)
 				 st->reg[AD9910_REG_CFR2].val32))
 		return ad9910_channel_str[AD9910_CHAN_IDX_DRG_PHASE];
 
+	/* Parallel data port enabled and data destination is phase */
+	mode_en = FIELD_GET(AD9910_CFR2_PARALLEL_DATA_PORT_EN_MSK,
+			    st->reg[AD9910_REG_CFR2].val32);
+	if (mode_en) {
+		if (st->scan_mask & BIT(AD9910_SCAN_IDX_PHASE))
+			return ad9910_channel_str[AD9910_CHAN_IDX_PARALLEL_PHASE];
+		if (st->scan_mask & BIT(AD9910_SCAN_IDX_POLAR_PHASE))
+			return ad9910_channel_str[AD9910_CHAN_IDX_PARALLEL_POLAR_PHASE];
+	}
+
 	/* POW: RAM enabled and data destination is frequency or amplitude */
 	if (ram_en)
 		return ad9910_channel_str[AD9910_CHAN_IDX_RAM];
@@ -2250,6 +2362,16 @@ static inline const char *ad9910_amplitude_source_get(struct ad9910_state *st)
 				 st->reg[AD9910_REG_CFR2].val32))
 		return ad9910_channel_str[AD9910_CHAN_IDX_DRG_AMP];
 
+	/* Parallel data port enabled and data destination is amplitude */
+	mode_en = FIELD_GET(AD9910_CFR2_PARALLEL_DATA_PORT_EN_MSK,
+			    st->reg[AD9910_REG_CFR2].val32);
+	if (mode_en) {
+		if (st->scan_mask & BIT(AD9910_SCAN_IDX_AMP))
+			return ad9910_channel_str[AD9910_CHAN_IDX_PARALLEL_AMP];
+		if (st->scan_mask & BIT(AD9910_SCAN_IDX_POLAR_AMP))
+			return ad9910_channel_str[AD9910_CHAN_IDX_PARALLEL_POLAR_AMP];
+	}
+
 	/* only way to control amplitude at this point is through OSK */
 	if (ram_en)
 		return ad9910_channel_str[AD9910_CHAN_IDX_OSK];
@@ -2278,6 +2400,72 @@ static inline void ad9910_debugfs_init(struct ad9910_state *st,
 			    &ad9910_amplitude_source_fops);
 }
 
+static const u8 ad9910_scan_chan_idx[] = {
+	[AD9910_SCAN_IDX_AMP] = AD9910_CHAN_IDX_PARALLEL_AMP,
+	[AD9910_SCAN_IDX_PHASE] = AD9910_CHAN_IDX_PARALLEL_PHASE,
+	[AD9910_SCAN_IDX_FREQ] = AD9910_CHAN_IDX_PARALLEL_FREQ,
+	[AD9910_SCAN_IDX_POLAR_PHASE] = AD9910_CHAN_IDX_PARALLEL_POLAR_PHASE,
+	[AD9910_SCAN_IDX_POLAR_AMP] = AD9910_CHAN_IDX_PARALLEL_POLAR_AMP,
+};
+
+static u32 ad9910_buffer_chan_idx(struct iio_dev *indio_dev)
+{
+	unsigned int scan_idx = find_first_bit(indio_dev->active_scan_mask,
+					       iio_get_masklength(indio_dev));
+
+	return ad9910_scan_chan_idx[scan_idx];
+}
+
+static int ad9910_buffer_preenable(struct iio_dev *indio_dev)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+	int ret;
+
+	guard(mutex)(&st->lock);
+
+	st->scan_mask = *indio_dev->active_scan_mask;
+	ret = iio_backend_chan_enable(st->back,
+				      ad9910_buffer_chan_idx(indio_dev));
+	if (ret)
+		return ret;
+
+	return ad9910_reg32_update(st, AD9910_REG_CFR2,
+				   AD9910_CFR2_PARALLEL_DATA_PORT_EN_MSK,
+				   AD9910_CFR2_PARALLEL_DATA_PORT_EN_MSK,
+				   true);
+}
+
+static int ad9910_buffer_postdisable(struct iio_dev *indio_dev)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+	int ret;
+
+	guard(mutex)(&st->lock);
+
+	st->scan_mask = 0;
+	ret = ad9910_reg32_update(st, AD9910_REG_CFR2,
+				  AD9910_CFR2_PARALLEL_DATA_PORT_EN_MSK,
+				  0, true);
+	if (ret)
+		return ret;
+
+	return iio_backend_chan_disable(st->back,
+					ad9910_buffer_chan_idx(indio_dev));
+}
+
+static const struct iio_buffer_setup_ops ad9910_buffer_setup_ops = {
+	.preenable = ad9910_buffer_preenable,
+	.postdisable = ad9910_buffer_postdisable,
+};
+
+static const unsigned long ad9910_available_scan_masks[] = {
+	BIT(AD9910_SCAN_IDX_AMP),
+	BIT(AD9910_SCAN_IDX_PHASE),
+	BIT(AD9910_SCAN_IDX_FREQ),
+	BIT(AD9910_SCAN_IDX_POLAR_AMP) | BIT(AD9910_SCAN_IDX_POLAR_PHASE),
+	0
+};
+
 static int ad9910_probe(struct spi_device *spi)
 {
 	static const char * const supplies[] = {
@@ -2321,6 +2509,20 @@ static int ad9910_probe(struct spi_device *spi)
 		return dev_err_probe(dev, PTR_ERR(dev_rst),
 				     "failed to get device reset control\n");
 
+	st->back = devm_iio_backend_get_optional(dev, NULL);
+	if (IS_ERR(st->back))
+		return dev_err_probe(dev, PTR_ERR(st->back),
+				     "failed to get iio backend\n");
+	if (st->back) {
+		ret = devm_iio_backend_request_buffer(dev, st->back, indio_dev);
+		if (ret)
+			return dev_err_probe(dev, ret,
+					     "failed to request iio backend buffer\n");
+
+		indio_dev->setup_ops = &ad9910_buffer_setup_ops;
+		indio_dev->available_scan_masks = ad9910_available_scan_masks;
+	}
+
 	/*
 	 * The IO RESET pin is not used in this driver, as we assume that all
 	 * SPI transfers are complete, but if it is wired up, we need to make
@@ -2424,3 +2626,4 @@ module_spi_driver(ad9910_driver);
 MODULE_AUTHOR("Rodrigo Alencar <rodrigo.alencar@analog.com>");
 MODULE_DESCRIPTION("Analog Devices AD9910 DDS driver");
 MODULE_LICENSE("GPL");
+MODULE_IMPORT_NS("IIO_BACKEND");

-- 
2.43.0

