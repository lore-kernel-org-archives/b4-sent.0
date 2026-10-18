From: Rinat Muhamedgaliev <rinat.muhamedgaliev@gmail.com>
Date: Mon, 19 Oct 2026 00:15:54 +0300
Subject: [PATCH v6] power: supply: bq27xxx: detect bq27541 behind bq27411
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-master-v6-1-c4b36129721e@gmail.com>
References: <20261019-master-v6-0-c4b36129721e@gmail.com>
In-Reply-To: <20261019-master-v6-0-c4b36129721e@gmail.com>
To: linux-pm@vger.kernel.org
Cc: pali@kernel.org, sre@kernel.org, afd@ti.com, 
 konrad.dybcio@oss.qualcomm.com, david@ixit.cz, krzk@kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Rinat Muhamedgaliev <rinat.muhamedgaliev@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792358153; l=3244;
 i=rinat.muhamedgaliev@gmail.com; s=default; h=from:subject:message-id;
 bh=dnSe8ElLLTi2cXIlSrqfQn/BXIYt61P1i6EIAmfkKr8=;
 b=/ST+FNyeZG01G+kV01s7Im7B+oRn2yOXN6CpWOAVIHy0oGmRrpBYE2GaLOyvqv2qUzCd9DZvA
 ej56nyWnGxVACFTtwpDPi73XzotMWN+jR9NVOwCTIyZWd9cKy/mRVi6
X-Developer-Key: i=rinat.muhamedgaliev@gmail.com; a=ed25519;
 pk=qkYQO8LRlRErWiLzlpK8jHbRIxv8+7v06+ytcxX8mec=
X-Endpoint-Received: by B4 Relay for rinat.muhamedgaliev@gmail.com/default with auth_id=1072
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

OnePlus 6 and 6T replacement battery packs may contain either a bq27411
or a bq27541 fuel gauge at I2C address 0x55. The device tree currently
identifies the gauge as bq27411, but a bq27541 uses a different register
map and then reports invalid battery values.

Read the DeviceType control subcommand when probing a bq27411. Keep the
existing profile for DeviceType 0x0421, but select the bq27541 profile
for DeviceType 0x0541. This retains the established DT ABI and supports
replacement packs without introducing a generic compatible.

Tested on OnePlus 6T (fajita) with DeviceType 0x0541: voltage, state of
charge, and temperature were reported correctly. Testing on hardware with
DeviceType 0x0421 would be appreciated.

Signed-off-by: Rinat Muhamedgaliev <rinat.muhamedgaliev@gmail.com>
---
 drivers/power/supply/bq27xxx_battery_i2c.c | 57 ++++++++++++++++++++++++++++++
 1 file changed, 57 insertions(+)

diff --git a/drivers/power/supply/bq27xxx_battery_i2c.c b/drivers/power/supply/bq27xxx_battery_i2c.c
index 94b00bb89c17..0b957888ad2b 100644
--- a/drivers/power/supply/bq27xxx_battery_i2c.c
+++ b/drivers/power/supply/bq27xxx_battery_i2c.c
@@ -16,6 +16,11 @@
 static DEFINE_IDR(battery_id);
 static DEFINE_MUTEX(battery_mutex);
 
+#define BQ27XXX_REG_CTRL		0x00
+#define BQ27XXX_DEVICE_TYPE		0x0001
+#define BQ27411_DEVICE_TYPE		0x0421
+#define BQ27541_DEVICE_TYPE		0x0541
+
 static irqreturn_t bq27xxx_battery_irq_handler_thread(int irq, void *data)
 {
 	struct bq27xxx_device_info *di = data;
@@ -136,6 +141,46 @@ static int bq27xxx_battery_i2c_bulk_write(struct bq27xxx_device_info *di,
 	return 0;
 }
 
+static int bq27xxx_battery_i2c_check_device_type(struct bq27xxx_device_info *di)
+{
+	enum bq27xxx_chip detected_chip;
+	int expected_type;
+	int ret;
+
+	ret = di->bus.write(di, BQ27XXX_REG_CTRL, BQ27XXX_DEVICE_TYPE,
+			    false);
+	if (ret < 0)
+		return ret;
+
+	ret = di->bus.read(di, BQ27XXX_REG_CTRL, false);
+	if (ret < 0)
+		return ret;
+
+	switch (ret) {
+	case BQ27411_DEVICE_TYPE:
+		detected_chip = BQ27411;
+		break;
+	case BQ27541_DEVICE_TYPE:
+		detected_chip = BQ27541;
+		break;
+	default:
+		dev_err(di->dev, "unrecognized DeviceType 0x%04x\n", ret);
+		return -ENODEV;
+	}
+
+	if (detected_chip == di->chip)
+		return 0;
+
+	expected_type = di->chip == BQ27411 ? BQ27411_DEVICE_TYPE :
+		BQ27541_DEVICE_TYPE;
+	dev_warn(di->dev,
+		 "detected DeviceType 0x%04x instead of expected 0x%04x\n",
+		 ret, expected_type);
+	di->chip = detected_chip;
+
+	return 0;
+}
+
 static int bq27xxx_battery_i2c_probe(struct i2c_client *client,
 				     const struct i2c_device_id *id)
 {
@@ -169,6 +214,18 @@ static int bq27xxx_battery_i2c_probe(struct i2c_client *client,
 	di->bus.read_bulk = bq27xxx_battery_i2c_bulk_read;
 	di->bus.write_bulk = bq27xxx_battery_i2c_bulk_write;
 
+	/* BQ27411 and BQ27541 may be interchanged in replacement battery packs. */
+	switch (di->chip) {
+	case BQ27411:
+	case BQ27541:
+		ret = bq27xxx_battery_i2c_check_device_type(di);
+		if (ret)
+			goto err_failed;
+		break;
+	default:
+		break;
+	}
+
 	ret = bq27xxx_battery_setup(di);
 	if (ret)
 		goto err_failed;

-- 
2.56.0

