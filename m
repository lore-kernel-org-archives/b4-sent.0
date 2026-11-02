From: Radu Sabau <radu.sabau@analog.com>
Date: Mon, 02 Nov 2026 11:25:44 +0200
Subject: [PATCH v5 8/8] iio: imu: adis16607: Add calibration bias support
 for gyro/accel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261102-adis16607-v5-8-4f98b0d271ac@analog.com>
References: <20261102-adis16607-v5-0-4f98b0d271ac@analog.com>
In-Reply-To: <20261102-adis16607-v5-0-4f98b0d271ac@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Nuno Sa <nuno.sa@analog.com>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Radu Sabau <radu.sabau@analog.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux@analog.com, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793611539; l=3771;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=XSKYww/o1vH0pbkIDQNdQXg29aw/PkeH3UrhLPjkzlQ=;
 b=AQqlRshKUVcwEgILUz+Pmk2VkN9dl1ZhYGnb/t46KdI8SRdj+ZpPcXYRIKyArxjfa79E5ycTT
 u57HfkB9Bg/CNH9r/EQlzxUe0DR4J94G61oo0keLkZh+8Xx6RsRnpN3
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add IIO_CHAN_INFO_CALIBBIAS support for the gyroscope and
accelerometer axes, backed by the device's per-axis bias registers
(XA/YA/ZA_BIAS, XG/YG/ZG_BIAS).

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/imu/adis16607.c | 39 ++++++++++++++++++++++++++++++++-------
 1 file changed, 32 insertions(+), 7 deletions(-)

diff --git a/drivers/iio/imu/adis16607.c b/drivers/iio/imu/adis16607.c
index 58504d351de1..ab80e0909bf6 100644
--- a/drivers/iio/imu/adis16607.c
+++ b/drivers/iio/imu/adis16607.c
@@ -57,6 +57,12 @@
 #define ADIS16607_REG_SOFT_RESET	0x36
 #define ADIS16607_REG_SELF_TEST		0x39
 #define ADIS16607_REG_DEC_RATE		0x3A
+#define ADIS16607_REG_XA_BIAS		0x3B
+#define ADIS16607_REG_YA_BIAS		0x3C
+#define ADIS16607_REG_ZA_BIAS		0x3D
+#define ADIS16607_REG_XG_BIAS		0x3E
+#define ADIS16607_REG_YG_BIAS		0x3F
+#define ADIS16607_REG_ZG_BIAS		0x40
 #define ADIS16607_REG_DIGITAL_STATUS	0x4E
 
 /* SPI Half-Duplex lock value */
@@ -168,15 +174,16 @@ enum {
 
 struct adis16607_chan_regs {
 	u16 raw_reg;
+	u16 calib_bias_reg;	/* 0 if the channel has no calibbias support */
 };
 
 static const struct adis16607_chan_regs adis16607_chan_regs[] = {
-	[ADIS16607_SCAN_ACCEL_X]   = { ADIS16607_REG_X_ACCEL },
-	[ADIS16607_SCAN_ACCEL_Y]   = { ADIS16607_REG_Y_ACCEL },
-	[ADIS16607_SCAN_ACCEL_Z]   = { ADIS16607_REG_Z_ACCEL },
-	[ADIS16607_SCAN_GYRO_X]    = { ADIS16607_REG_X_GYRO },
-	[ADIS16607_SCAN_GYRO_Y]    = { ADIS16607_REG_Y_GYRO },
-	[ADIS16607_SCAN_GYRO_Z]    = { ADIS16607_REG_Z_GYRO },
+	[ADIS16607_SCAN_ACCEL_X]   = { ADIS16607_REG_X_ACCEL, ADIS16607_REG_XA_BIAS },
+	[ADIS16607_SCAN_ACCEL_Y]   = { ADIS16607_REG_Y_ACCEL, ADIS16607_REG_YA_BIAS },
+	[ADIS16607_SCAN_ACCEL_Z]   = { ADIS16607_REG_Z_ACCEL, ADIS16607_REG_ZA_BIAS },
+	[ADIS16607_SCAN_GYRO_X]    = { ADIS16607_REG_X_GYRO, ADIS16607_REG_XG_BIAS },
+	[ADIS16607_SCAN_GYRO_Y]    = { ADIS16607_REG_Y_GYRO, ADIS16607_REG_YG_BIAS },
+	[ADIS16607_SCAN_GYRO_Z]    = { ADIS16607_REG_Z_GYRO, ADIS16607_REG_ZG_BIAS },
 	[ADIS16607_SCAN_DELTVEL_X] = { ADIS16607_REG_X_DELTVEL },
 	[ADIS16607_SCAN_DELTVEL_Y] = { ADIS16607_REG_Y_DELTVEL },
 	[ADIS16607_SCAN_DELTVEL_Z] = { ADIS16607_REG_Z_DELTVEL },
@@ -1030,6 +1037,16 @@ static int adis16607_read_raw(struct iio_dev *indio_dev,
 		/* Temperature: 0 raw counts = 25°C; offset = 25000 mdeg / 5 mdeg per LSB = 5000 */
 		*val = 5000;
 		return IIO_VAL_INT;
+	case IIO_CHAN_INFO_CALIBBIAS: {
+		u16 reg = adis16607_chan_regs[chan->address].calib_bias_reg;
+		u16 tmp16;
+
+		ret = adis_read_reg_16(&st->adis, reg, &tmp16);
+		if (ret)
+			return ret;
+		*val = sign_extend32(tmp16, 15);
+		return IIO_VAL_INT;
+	}
 	case IIO_CHAN_INFO_SAMP_FREQ:
 		ret = adis16607_get_freq(st, &tmp);
 		if (ret)
@@ -1067,6 +1084,13 @@ static int adis16607_write_raw(struct iio_dev *indio_dev,
 		      val2 / (MICROHZ_PER_HZ / MILLIHZ_PER_HZ);
 		return adis16607_set_freq(st, tmp);
 	}
+	case IIO_CHAN_INFO_CALIBBIAS: {
+		u16 reg = adis16607_chan_regs[chan->address].calib_bias_reg;
+
+		if (val < S16_MIN || val > S16_MAX)
+			return -EINVAL;
+		return adis_write_reg_16(&st->adis, reg, val);
+	}
 	default:
 		return -EINVAL;
 	}
@@ -1081,7 +1105,8 @@ static int adis16607_write_raw(struct iio_dev *indio_dev,
 		.type = (_type),					       \
 		.modified = 1,						       \
 		.channel2 = (_mod),					       \
-		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW),		       \
+		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |		       \
+				      BIT(IIO_CHAN_INFO_CALIBBIAS),	       \
 		.info_mask_shared_by_type = BIT(IIO_CHAN_INFO_SCALE),	       \
 		.info_mask_shared_by_all = BIT(IIO_CHAN_INFO_SAMP_FREQ),       \
 		.address = (_idx),					       \

-- 
2.43.0

