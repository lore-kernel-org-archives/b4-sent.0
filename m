From: Radu Sabau <radu.sabau@analog.com>
Date: Fri, 13 Nov 2026 14:33:38 +0200
Subject: [PATCH v6 8/8] iio: imu: adis16607: Add calibration bias support
 for gyro/accel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261113-adis16607-v6-8-3f678719942a@analog.com>
References: <20261113-adis16607-v6-0-3f678719942a@analog.com>
In-Reply-To: <20261113-adis16607-v6-0-3f678719942a@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Nuno Sa <nuno.sa@analog.com>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Radu Sabau <radu.sabau@analog.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Antoniu Miclaus <antoniu.miclaus@analog.com>, 
 Robert Budai <robert.budai@analog.com>, 
 Ramona Gradinariu <ramona.gradinariu@analog.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux@analog.com, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794573212; l=3726;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=VnNIhnMUl2LvvkzsAw4PqZBgigIcUBDk4HP4t1NObL4=;
 b=LQjI363kyoQL/kJnjvxraTjBXjQYGku4ZXXvaMwlJrNhzabo+kpKO20Rcr+GG8tzM6Gz5L3dy
 UE1fQznpC4TDaTEOT0S0DGyCp1vl+UV5dFWiLs25arkUcHl2vuh517B
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add IIO_CHAN_INFO_CALIBBIAS support for the gyroscope and
accelerometer axes, backed by the device's per-axis bias registers
(XA/YA/ZA_BIAS, XG/YG/ZG_BIAS).

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/imu/adis16607.c | 40 +++++++++++++++++++++++++++++++++-------
 1 file changed, 33 insertions(+), 7 deletions(-)

diff --git a/drivers/iio/imu/adis16607.c b/drivers/iio/imu/adis16607.c
index cd5f875d4c56..84fd5b9ad8a5 100644
--- a/drivers/iio/imu/adis16607.c
+++ b/drivers/iio/imu/adis16607.c
@@ -56,6 +56,12 @@
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
@@ -167,15 +173,16 @@ enum {
 
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
@@ -1043,6 +1050,16 @@ static int adis16607_read_raw(struct iio_dev *indio_dev,
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
@@ -1081,6 +1098,14 @@ static int adis16607_write_raw(struct iio_dev *indio_dev,
 		return adis16607_set_freq(st, tmp);
 	}
 
+	case IIO_CHAN_INFO_CALIBBIAS: {
+		u16 reg = adis16607_chan_regs[chan->address].calib_bias_reg;
+
+		if (val < S16_MIN || val > S16_MAX)
+			return -EINVAL;
+		return adis_write_reg_16(&st->adis, reg, val);
+	}
+
 	default:
 		return -EINVAL;
 	}
@@ -1095,7 +1120,8 @@ static int adis16607_write_raw(struct iio_dev *indio_dev,
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

