From: Radu Sabau <radu.sabau@analog.com>
Date: Thu, 15 Oct 2026 12:33:02 +0300
Subject: [PATCH v3 5/6] iio: imu: adis16607: Add external clock sync
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-adis16607-v3-5-f972d4efee85@analog.com>
References: <20261015-adis16607-v3-0-f972d4efee85@analog.com>
In-Reply-To: <20261015-adis16607-v3-0-f972d4efee85@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Nuno Sa <nuno.sa@analog.com>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Radu Sabau <radu.sabau@analog.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792056783; l=6480;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=F+hJzk7sMS1cBWe21WHcHg94eU6gujSkFcy4gH0tA6k=;
 b=u5pB/SM7wu+e7X6IFUuipaLtZQ0pE6QiV8e1a51tT+YF5nVT7qIkWrDohPNx//8OND3MsH3bo
 O9aaj6yHzGjCg/vwdfqSY5lK3pYV6zru8wBNaRx3IL3ZKcTCF+gXksK
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for an optional external clock (clocks property),
selecting between SYNC_DIRECT and SYNC_SCALED modes depending on the
supplied frequency, with the internal 8 kHz clock used as the default
when no clock is provided.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/imu/adis16607.c | 115 +++++++++++++++++++++++++++++++++++++++++---
 1 file changed, 108 insertions(+), 7 deletions(-)

diff --git a/drivers/iio/imu/adis16607.c b/drivers/iio/imu/adis16607.c
index dac146645415..c16a33ee773f 100644
--- a/drivers/iio/imu/adis16607.c
+++ b/drivers/iio/imu/adis16607.c
@@ -6,6 +6,7 @@
  */
 #include <linux/bitfield.h>
 #include <linux/bitops.h>
+#include <linux/clk.h>
 #include <linux/debugfs.h>
 #include <linux/delay.h>
 #include <linux/iio/buffer.h>
@@ -46,6 +47,7 @@
 #define ADIS16607_REG_FIFO_WORD_CNT	0x2B
 #define ADIS16607_REG_USER_GPIO_CFG	0x2F
 #define ADIS16607_REG_SPI_HALFDUPLEX	0x32
+#define ADIS16607_REG_USER_SYNC		0x33
 #define ADIS16607_REG_USER_DATA_CFG	0x34
 #define ADIS16607_REG_USER_FIFO_CFG	0x35
 #define ADIS16607_REG_SOFT_RESET	0x36
@@ -58,10 +60,12 @@
 
 /* Masks */
 #define ADIS16607_RESET_GPIO_MASK	GENMASK(2, 0)
+#define ADIS16607_SYNC_GPIO_MASK	GENMASK(8, 6)
 #define ADIS16607_DR_GPIO_MASK		GENMASK(11, 9)
 #define ADIS16607_DEV_NOK_MASK		GENMASK(14, 12)
 #define ADIS16607_DATA_CNTR_EN_MASK	BIT(14)
 #define ADIS16607_BURST32_MASK		BIT(15)
+#define ADIS16607_SYNC_MODE_MASK	BIT(15)
 #define ADIS16607_BOOTLOADER_BUSY_MASK	BIT(0)
 
 /* FIFO masks */
@@ -88,8 +92,22 @@
 #define ADIS16607_ACCEL_Z_DELTA_MAX	4000
 #define ADIS16607_GYRO_DELTA_MAX	2600
 
+/* Sync modes */
+enum adis16607_sync_mode {
+	ADIS16607_SYNC_DEFAULT,
+	ADIS16607_SYNC_DIRECT,
+	ADIS16607_SYNC_SCALED,
+};
+
+struct adis16607_sync {
+	u16 sync_mode;
+	u16 min_rate;
+	u16 max_rate;
+};
+
 struct adis16607_chip_info {
 	const struct iio_chan_spec *channels;
+	const struct adis16607_sync *sync_mode;
 	const char *name;
 	u32 num_channels;
 	u32 gyro_max_val;
@@ -101,6 +119,7 @@ struct adis16607_chip_info {
 	u32 deltvel_max_val;
 	u32 int_clk;
 	u16 max_dec;
+	u8 num_sync;
 };
 
 struct adis16607 {
@@ -108,6 +127,7 @@ struct adis16607 {
 	struct adis adis;
 	unsigned long clk_freq;	/* millihertz */
 	u64 sample_period_ns;
+	u32 sync_mode;
 	u16 fifo_watermark;
 	/* Scratch buffer used for FIFO pop operations, see adis16607_fifo_pop() */
 	u8 *fifo_buf;
@@ -1106,6 +1126,12 @@ static const struct iio_info adis16607_info = {
 	.hwfifo_set_watermark = adis16607_set_watermark,
 };
 
+static const struct adis16607_sync adis16607_sync_modes[] = {
+	{ ADIS16607_SYNC_DEFAULT, 0, 0 },
+	{ ADIS16607_SYNC_DIRECT, 401, 8000 },
+	{ ADIS16607_SYNC_SCALED, 1, 400 },
+};
+
 static const char * const adis16607_status_error_msgs[] = {
 	[9] = "Boot Memory Failure",
 	[11] = "Power Supply Failure",
@@ -1145,7 +1171,9 @@ static const struct adis_data adis16607_data = {
 	.temp_scale	= 5,						\
 	.deltvel_max_val = IIO_G_TO_M_S_2(40),				\
 	.int_clk	= 8000,						\
-	.max_dec	= 65535
+	.max_dec	= 65535,					\
+	.sync_mode	= adis16607_sync_modes,				\
+	.num_sync	= ARRAY_SIZE(adis16607_sync_modes)
 
 static const struct adis16607_chip_info adis16607_2_chip_info = {
 	ADIS16607_CHIP_INFO_COMMON,
@@ -1163,15 +1191,88 @@ static const struct adis16607_chip_info adis16607_3_chip_info = {
 	.deltang_max_val = IIO_DEGREE_TO_RAD(2000),
 };
 
-/*
- * No external clock sync support yet: always run on the internal clock.
- * Default dec=0 after reset, so period = 1 / clk_freq.
- */
 static int adis16607_config_clk(struct adis16607 *st)
 {
-	st->clk_freq = (unsigned long)st->info->int_clk * 1000;
+	struct device *dev = &st->adis.spi->dev;
+	const struct adis16607_sync *sync_mode_data = NULL;
+	unsigned long ext_clk_hz = 0;
+	u16 sync_scale = 0;
+	struct clk *clk;
+	int ret, i;
+
+	clk = devm_clk_get_optional_enabled(dev, NULL);
+	if (IS_ERR(clk))
+		return PTR_ERR(clk);
+
+	if (clk) {
+		ext_clk_hz = clk_get_rate(clk);
+
+		for (i = 1; i < st->info->num_sync; i++) {
+			if (ext_clk_hz >= st->info->sync_mode[i].min_rate &&
+			    ext_clk_hz <= st->info->sync_mode[i].max_rate) {
+				sync_mode_data = &st->info->sync_mode[i];
+				break;
+			}
+		}
+
+		if (!sync_mode_data)
+			return dev_err_probe(dev, -EINVAL,
+					     "Clk rate: %lu not in a valid range\n",
+					     ext_clk_hz);
+
+		st->sync_mode = sync_mode_data->sync_mode;
+	} else {
+		st->sync_mode = ADIS16607_SYNC_DEFAULT;
+	}
+
+	/*
+	 * Write the full desired sync state explicitly for every mode,
+	 * rather than only when enabling non-default sync: USER_SYNC's
+	 * documented reset default (0x0000, direct mode / scale 0) means
+	 * this isn't fixing a known reset-state issue, but each mode
+	 * establishing its own complete state here, instead of only
+	 * touching bits conditionally, is simpler to reason about and
+	 * doesn't depend on that default holding true.
+	 */
+	ret = adis_update_bits_base(&st->adis, ADIS16607_REG_USER_GPIO_CFG,
+				    ADIS16607_SYNC_GPIO_MASK,
+				    FIELD_PREP(ADIS16607_SYNC_GPIO_MASK,
+					       st->sync_mode != ADIS16607_SYNC_DEFAULT), 2);
+	if (ret)
+		return ret;
+
+	if (st->sync_mode == ADIS16607_SYNC_SCALED)
+		sync_scale = DIV_ROUND_CLOSEST(st->info->int_clk, ext_clk_hz);
+
+	ret = adis_write_reg_16(&st->adis, ADIS16607_REG_USER_SYNC,
+				(st->sync_mode == ADIS16607_SYNC_SCALED) ?
+				ADIS16607_SYNC_MODE_MASK | sync_scale : 0);
+	if (ret)
+		return ret;
+
+	switch (st->sync_mode) {
+	case ADIS16607_SYNC_SCALED:
+		/*
+		 * sync_scale is a rounded integer, so the hardware's actual
+		 * effective rate is ext_clk_hz * sync_scale, not necessarily
+		 * int_clk - use the real value here so sample_period_ns (and
+		 * therefore FIFO sample timestamps) don't drift from it.
+		 */
+		st->clk_freq = (unsigned long)ext_clk_hz * sync_scale * 1000;
+		break;
+	case ADIS16607_SYNC_DIRECT:
+		/* DIRECT: external clock is the effective internal rate */
+		st->clk_freq = ext_clk_hz * 1000;
+		break;
+	default:
+		st->clk_freq = (unsigned long)st->info->int_clk * 1000;
+		break;
+	}
+
+	/* Default dec=0 after reset: period = 1 / clk_freq */
 	st->sample_period_ns = DIV_ROUND_CLOSEST_ULL((u64)NSEC_PER_SEC * 1000ULL,
-						     st->clk_freq);
+						      st->clk_freq);
+
 	return 0;
 }
 

-- 
2.43.0

