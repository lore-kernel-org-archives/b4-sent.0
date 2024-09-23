From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Mon, 23 Sep 2024 16:53:22 +0200
Subject: [PATCH v2 2/2] iio: imu: inv_mpu6050: add support for
 IAM-20680HT/HP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240923-inv-mpu6050-add-iam20680-ht-hp-v2-2-48290e0b9931@tdk.com>
References: <20240923-inv-mpu6050-add-iam20680-ht-hp-v2-0-48290e0b9931@tdk.com>
In-Reply-To: <20240923-inv-mpu6050-add-iam20680-ht-hp-v2-0-48290e0b9931@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727103209; l=4819;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=/ldj+ehtICzWHkHGTke2yP8V+ZJuIQcCfLCxa5OZgXg=;
 b=OTzZplcLjGZjfqicjharfREu1ibD25Dz1ovfVdAT/MlhsqduSpbnb5d/V+D9KB96DKTJ8xA5O
 ugvQQPeszuuD91dSDs6aamelS+bwSaUFz3ayZrI8H0262EElJ0+66Xa
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IAM-20680HT & HP are 2 variants of IAM-20680 with better specs,
wider temperature range, and a bigger FIFO (4k).

Fully compatible with IAM-20680, FIFO is 512 bytes by default and
with correct register setting we expand it to full 4k.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_mpu6050/inv_mpu_core.c | 20 ++++++++++++++++++++
 drivers/iio/imu/inv_mpu6050/inv_mpu_i2c.c  | 10 ++++++++++
 drivers/iio/imu/inv_mpu6050/inv_mpu_iio.h  |  4 ++++
 drivers/iio/imu/inv_mpu6050/inv_mpu_spi.c  | 10 ++++++++++
 4 files changed, 44 insertions(+)

diff --git a/drivers/iio/imu/inv_mpu6050/inv_mpu_core.c b/drivers/iio/imu/inv_mpu6050/inv_mpu_core.c
index 14d95f34e981c8b71dd0892fbeb12735a8857d6c..6b0adb7f9ae301878d9b4d6febec0309bd77a256 100644
--- a/drivers/iio/imu/inv_mpu6050/inv_mpu_core.c
+++ b/drivers/iio/imu/inv_mpu6050/inv_mpu_core.c
@@ -286,6 +286,24 @@ static const struct inv_mpu6050_hw hw_info[] = {
 		.temp = {INV_ICM20608_TEMP_OFFSET, INV_ICM20608_TEMP_SCALE},
 		.startup_time = {INV_MPU6500_GYRO_STARTUP_TIME, INV_MPU6500_ACCEL_STARTUP_TIME},
 	},
+	{
+		.whoami = INV_IAM20680HP_WHOAMI_VALUE,
+		.name = "IAM20680HP",
+		.reg = &reg_set_6500,
+		.config = &chip_config_6500,
+		.fifo_size = 4 * 1024,
+		.temp = {INV_ICM20608_TEMP_OFFSET, INV_ICM20608_TEMP_SCALE},
+		.startup_time = {INV_MPU6500_GYRO_STARTUP_TIME, INV_MPU6500_ACCEL_STARTUP_TIME},
+	},
+	{
+		.whoami = INV_IAM20680HT_WHOAMI_VALUE,
+		.name = "IAM20680HT",
+		.reg = &reg_set_6500,
+		.config = &chip_config_6500,
+		.fifo_size = 4 * 1024,
+		.temp = {INV_ICM20608_TEMP_OFFSET, INV_ICM20608_TEMP_SCALE},
+		.startup_time = {INV_MPU6500_GYRO_STARTUP_TIME, INV_MPU6500_ACCEL_STARTUP_TIME},
+	},
 };
 
 static int inv_mpu6050_pwr_mgmt_1_write(struct inv_mpu6050_state *st, bool sleep,
@@ -510,6 +528,8 @@ static int inv_mpu6050_set_accel_lpf_regs(struct inv_mpu6050_state *st,
 		return 0;
 	case INV_ICM20689:
 	case INV_ICM20690:
+	case INV_IAM20680HT:
+	case INV_IAM20680HP:
 		/* set FIFO size to maximum value */
 		val |= INV_ICM20689_BITS_FIFO_SIZE_MAX;
 		break;
diff --git a/drivers/iio/imu/inv_mpu6050/inv_mpu_i2c.c b/drivers/iio/imu/inv_mpu6050/inv_mpu_i2c.c
index 0e03137fb3d40d4753989522cf5168ef358a1014..7a5926ba6b97d5e5fbdd08e0c90b58afb3f0131a 100644
--- a/drivers/iio/imu/inv_mpu6050/inv_mpu_i2c.c
+++ b/drivers/iio/imu/inv_mpu6050/inv_mpu_i2c.c
@@ -188,6 +188,8 @@ static const struct i2c_device_id inv_mpu_id[] = {
 	{"icm20602", INV_ICM20602},
 	{"icm20690", INV_ICM20690},
 	{"iam20680", INV_IAM20680},
+	{"iam20680hp", INV_IAM20680HP},
+	{"iam20680ht", INV_IAM20680HT},
 	{}
 };
 
@@ -254,6 +256,14 @@ static const struct of_device_id inv_of_match[] = {
 		.compatible = "invensense,iam20680",
 		.data = (void *)INV_IAM20680
 	},
+	{
+		.compatible = "invensense,iam20680hp",
+		.data = (void *)INV_IAM20680HP
+	},
+	{
+		.compatible = "invensense,iam20680ht",
+		.data = (void *)INV_IAM20680HT
+	},
 	{ }
 };
 MODULE_DEVICE_TABLE(of, inv_of_match);
diff --git a/drivers/iio/imu/inv_mpu6050/inv_mpu_iio.h b/drivers/iio/imu/inv_mpu6050/inv_mpu_iio.h
index e1c0c51468761ab18188a224e44e09f919d81f9a..a6862cf426396cbaf3452bb3451cd58e4f30a4ec 100644
--- a/drivers/iio/imu/inv_mpu6050/inv_mpu_iio.h
+++ b/drivers/iio/imu/inv_mpu6050/inv_mpu_iio.h
@@ -85,6 +85,8 @@ enum inv_devices {
 	INV_ICM20602,
 	INV_ICM20690,
 	INV_IAM20680,
+	INV_IAM20680HP,
+	INV_IAM20680HT,
 	INV_NUM_PARTS
 };
 
@@ -424,6 +426,8 @@ struct inv_mpu6050_state {
 #define INV_ICM20602_WHOAMI_VALUE		0x12
 #define INV_ICM20690_WHOAMI_VALUE		0x20
 #define INV_IAM20680_WHOAMI_VALUE		0xA9
+#define INV_IAM20680HP_WHOAMI_VALUE		0xF8
+#define INV_IAM20680HT_WHOAMI_VALUE		0xFA
 
 /* scan element definition for generic MPU6xxx devices */
 enum inv_mpu6050_scan {
diff --git a/drivers/iio/imu/inv_mpu6050/inv_mpu_spi.c b/drivers/iio/imu/inv_mpu6050/inv_mpu_spi.c
index 05451ca1580b637a66a30efe82fbd2a2b63e55d5..e6a291fcda958c56e889e58151929a2f602b0426 100644
--- a/drivers/iio/imu/inv_mpu6050/inv_mpu_spi.c
+++ b/drivers/iio/imu/inv_mpu6050/inv_mpu_spi.c
@@ -80,6 +80,8 @@ static const struct spi_device_id inv_mpu_id[] = {
 	{"icm20602", INV_ICM20602},
 	{"icm20690", INV_ICM20690},
 	{"iam20680", INV_IAM20680},
+	{"iam20680hp", INV_IAM20680HP},
+	{"iam20680ht", INV_IAM20680HT},
 	{}
 };
 
@@ -142,6 +144,14 @@ static const struct of_device_id inv_of_match[] = {
 		.compatible = "invensense,iam20680",
 		.data = (void *)INV_IAM20680
 	},
+	{
+		.compatible = "invensense,iam20680hp",
+		.data = (void *)INV_IAM20680HP
+	},
+	{
+		.compatible = "invensense,iam20680ht",
+		.data = (void *)INV_IAM20680HT
+	},
 	{ }
 };
 MODULE_DEVICE_TABLE(of, inv_of_match);

-- 
2.34.1

