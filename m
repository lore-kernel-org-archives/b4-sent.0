From: Radu Sabau <radu.sabau@analog.com>
Date: Fri, 23 Oct 2026 12:30:25 +0300
Subject: [PATCH v4 8/8] iio: imu: adis16607: Add calibration bias support
 for gyro/accel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-adis16607-v4-8-a4d541ebfd13@analog.com>
References: <20261023-adis16607-v4-0-a4d541ebfd13@analog.com>
In-Reply-To: <20261023-adis16607-v4-0-a4d541ebfd13@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792747820; l=3210;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=2O9Md9H/5f7xIz5zm5QLl/OmXDIIRisepJv+lS3NV6M=;
 b=VKqFNgw5lTiUNcpM2vXGhumkljtk+VCaPs9sBUh0ipEVin+u1qW2b+4aEGWMkmDi+ZEsL7Up8
 EEfKW21pLZ9DKRQjPbntCWk3ANo61BYENuNlO8NVb7oppXZciqxSo9d
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add IIO_CHAN_INFO_CALIBBIAS support for the gyroscope and
accelerometer axes, backed by the device's per-axis bias registers
(XA/YA/ZA_BIAS, XG/YG/ZG_BIAS).

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/imu/adis16607.c | 35 ++++++++++++++++++++++++++++++++++-
 1 file changed, 34 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/imu/adis16607.c b/drivers/iio/imu/adis16607.c
index 3c5b59820be1..f73df022e819 100644
--- a/drivers/iio/imu/adis16607.c
+++ b/drivers/iio/imu/adis16607.c
@@ -55,6 +55,12 @@
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
@@ -153,6 +159,15 @@ enum {
 	ADIS16607_SCAN_TEMP,
 };
 
+static const u32 adis16607_calib_bias[] = {
+	[ADIS16607_SCAN_ACCEL_X] = ADIS16607_REG_XA_BIAS,
+	[ADIS16607_SCAN_ACCEL_Y] = ADIS16607_REG_YA_BIAS,
+	[ADIS16607_SCAN_ACCEL_Z] = ADIS16607_REG_ZA_BIAS,
+	[ADIS16607_SCAN_GYRO_X] = ADIS16607_REG_XG_BIAS,
+	[ADIS16607_SCAN_GYRO_Y] = ADIS16607_REG_YG_BIAS,
+	[ADIS16607_SCAN_GYRO_Z] = ADIS16607_REG_ZG_BIAS,
+};
+
 /*
  * SPI Half-Duplex read operation for ADIS16607.
  * Protocol:
@@ -863,6 +878,7 @@ static int adis16607_read_raw(struct iio_dev *indio_dev,
 			      int *val, int *val2, long info)
 {
 	struct adis16607 *st = iio_priv(indio_dev);
+	const int idx = chan->scan_index;
 	int ret;
 	u32 tmp;
 
@@ -900,6 +916,16 @@ static int adis16607_read_raw(struct iio_dev *indio_dev,
 		*val = 5000;
 		return IIO_VAL_INT;
 
+	case IIO_CHAN_INFO_CALIBBIAS: {
+		u16 tmp16;
+
+		ret = adis_read_reg_16(&st->adis, adis16607_calib_bias[idx], &tmp16);
+		if (ret)
+			return ret;
+		*val = sign_extend32(tmp16, 15);
+		return IIO_VAL_INT;
+	}
+
 	case IIO_CHAN_INFO_SAMP_FREQ:
 		ret = adis16607_get_freq(st, &tmp);
 		if (ret)
@@ -918,6 +944,7 @@ static int adis16607_write_raw(struct iio_dev *indio_dev,
 			       int val, int val2, long info)
 {
 	struct adis16607 *st = iio_priv(indio_dev);
+	const int idx = chan->scan_index;
 	u32 tmp;
 
 	switch (info) {
@@ -925,6 +952,11 @@ static int adis16607_write_raw(struct iio_dev *indio_dev,
 		tmp = val * 1000 + val2 / 1000;
 		return adis16607_set_freq(st, tmp);
 
+	case IIO_CHAN_INFO_CALIBBIAS:
+		if (val < S16_MIN || val > S16_MAX)
+			return -EINVAL;
+		return adis_write_reg_16(&st->adis, adis16607_calib_bias[idx], val);
+
 	default:
 		return -EINVAL;
 	}
@@ -934,7 +966,8 @@ static int adis16607_write_raw(struct iio_dev *indio_dev,
 	.type = (_type), \
 	.modified = 1, \
 	.channel2 = (_mod), \
-	.info_mask_separate = BIT(IIO_CHAN_INFO_RAW), \
+	.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) | \
+			      BIT(IIO_CHAN_INFO_CALIBBIAS), \
 	.info_mask_shared_by_type = BIT(IIO_CHAN_INFO_SCALE), \
 	.info_mask_shared_by_all = BIT(IIO_CHAN_INFO_SAMP_FREQ), \
 	.address = (_address), \

-- 
2.43.0

