From: Rinat Muhamedgaliev <rinat.muhamedgaliev@gmail.com>
Date: Mon, 19 Oct 2026 22:08:16 +0300
Subject: [PATCH v8] power: supply: bq27xxx: detect bq27541 behind bq27411
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261019-master-v8-1-2517e41c8992@gmail.com>
References: <20261019-master-v8-0-2517e41c8992@gmail.com>
In-Reply-To: <20261019-master-v8-0-2517e41c8992@gmail.com>
To: linux-pm@vger.kernel.org
Cc: pali@kernel.org, sre@kernel.org, afd@ti.com, 
 konrad.dybcio@oss.qualcomm.com, david@ixit.cz, krzk@kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Rinat Muhamedgaliev <rinat.muhamedgaliev@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792436896; l=3577;
 i=rinat.muhamedgaliev@gmail.com; s=default; h=from:subject:message-id;
 bh=3741MIanP4eFbNiDO101+hIyxN0viS5/BgzVbL3dkKk=;
 b=icd4FdYOvvtF0nDiVUfRgQBEguyYF8F9b5Li4YWGRUthZ7ALJJFjXznzxol7XHQlLHKx8W53k
 DDTMgr8NLuHBV/sv1jZ9mFJxxduTgrMkGtwkC3aEAB46LBD+NKs6k5L
X-Developer-Key: i=rinat.muhamedgaliev@gmail.com; a=ed25519;
 pk=qkYQO8LRlRErWiLzlpK8jHbRIxv8+7v06+ytcxX8mec=
X-Endpoint-Received: by B4 Relay for rinat.muhamedgaliev@gmail.com/default with auth_id=1072
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

OnePlus 6 and 6T replacement battery packs may contain either a bq27411
or a bq27541 fuel gauge at I2C address 0x55. The device tree currently
identifies the gauge as bq27411, but a bq27541 uses a different register
map and then reports invalid battery values.

During setup, query the DeviceType control subcommand for bq27411 and
bq27541. Keep the profile whose DeviceType matches the compatible, or
switch to the profile returned by the fuel gauge. This retains the
established DT ABI and supports replacement packs without introducing a
generic compatible.

Keep this logic in the bus-neutral core so it uses the existing register
maps and control-register access helpers.

Tested on OnePlus 6T (fajita) with DeviceType 0x0541: voltage, state of
charge, and temperature were reported correctly. Testing on hardware with
DeviceType 0x0421 would be appreciated.

Signed-off-by: Rinat Muhamedgaliev <rinat.muhamedgaliev@gmail.com>
---
 drivers/power/supply/bq27xxx_battery.c | 61 ++++++++++++++++++++++++++++++++++
 1 file changed, 61 insertions(+)

diff --git a/drivers/power/supply/bq27xxx_battery.c b/drivers/power/supply/bq27xxx_battery.c
index 8bf048fbd36a..57b51348ff2b 100644
--- a/drivers/power/supply/bq27xxx_battery.c
+++ b/drivers/power/supply/bq27xxx_battery.c
@@ -86,6 +86,10 @@
 #define BQ27XXX_SET_CFGUPDATE		0x13
 #define BQ27XXX_SOFT_RESET		0x42
 #define BQ27XXX_RESET			0x41
+#define BQ27XXX_DEVICE_TYPE		0x0001
+
+#define BQ27411_DEVICE_TYPE		0x0421
+#define BQ27541_DEVICE_TYPE		0x0541
 
 #define BQ27XXX_RS			(20) /* Resistor sense mOhm */
 #define BQ27XXX_POWER_CONSTANT		(29200) /* 29.2 µV^2 * 1000 */
@@ -1141,6 +1145,56 @@ static inline int bq27xxx_write(struct bq27xxx_device_info *di, int reg_index,
 	return ret;
 }
 
+static int bq27xxx_battery_check_device_type(struct bq27xxx_device_info *di)
+{
+	enum bq27xxx_chip detected_chip;
+	int expected_type;
+	int ret;
+
+	/* Add fuel gauges with supported DeviceType reporting to this list. */
+	switch (di->chip) {
+	case BQ27411:
+		expected_type = BQ27411_DEVICE_TYPE;
+		break;
+	case BQ27541:
+		expected_type = BQ27541_DEVICE_TYPE;
+		break;
+	default:
+		return 0;
+	}
+
+	ret = bq27xxx_write(di, BQ27XXX_REG_CTRL, BQ27XXX_DEVICE_TYPE,
+			    false);
+	if (ret < 0)
+		return ret;
+
+	ret = bq27xxx_read(di, BQ27XXX_REG_CTRL, false);
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
+	dev_warn(di->dev,
+		 "detected DeviceType 0x%04x instead of expected 0x%04x\n",
+		 ret, expected_type);
+	di->chip = detected_chip;
+
+	return 0;
+}
+
 static inline int bq27xxx_read_block(struct bq27xxx_device_info *di, int reg_index,
 				     u8 *data, int len)
 {
@@ -2089,10 +2143,17 @@ int bq27xxx_battery_setup(struct bq27xxx_device_info *di)
 		.of_node = di->dev->of_node,
 		.drv_data = di,
 	};
+	int ret;
 
 	INIT_DELAYED_WORK(&di->work, bq27xxx_battery_poll);
 	mutex_init(&di->lock);
 
+	di->regs       = bq27xxx_chip_data[di->chip].regs;
+
+	ret = bq27xxx_battery_check_device_type(di);
+	if (ret)
+		return ret;
+
 	di->regs       = bq27xxx_chip_data[di->chip].regs;
 	di->unseal_key = bq27xxx_chip_data[di->chip].unseal_key;
 	di->dm_regs    = bq27xxx_chip_data[di->chip].dm_regs;

-- 
2.56.0

