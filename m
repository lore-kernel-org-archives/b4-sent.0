From: Remy Demangeot <remy@demangeot.net>
Date: Mon, 26 Oct 2026 09:57:37 +0100
Subject: [PATCH 3/3] hwmon: (asus-ec-sensors) add water temperatures for
 MAXIMUS IX EXTREME
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261026-b4-m9e-ext-sensors-v1-3-644d389b2de1@demangeot.net>
References: <20261026-b4-m9e-ext-sensors-v1-0-644d389b2de1@demangeot.net>
In-Reply-To: <20261026-b4-m9e-ext-sensors-v1-0-644d389b2de1@demangeot.net>
To: Eugene Shalygin <eugene.shalygin@gmail.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Remy Demangeot <remy@demangeot.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793005066; l=10011;
 i=remy@demangeot.net; s=20261015; h=from:subject:message-id;
 bh=TPAvbhS6jnpAL1X7c9NHXFhPyY3rAbsLBapIyIKDCes=;
 b=zzramXvzY2vlgWbwaPWr/ciBzSHaqesXoVTc+vy2Y5niIPHgRtxjRymK2z47K0SxHT1/EH9Cm
 mwQmZeaVacRAUCgXTNEfe34489dwyn1lmMB7/ciXto/mZwD4OLhQ5i9
X-Developer-Key: i=remy@demangeot.net; a=ed25519;
 pk=h/s5N2ZlgZ0m+8FpMhSaCNJt0jvb9whRBAdJwpC+VAo=
X-Endpoint-Received: by B4 Relay for remy@demangeot.net/20261015 with auth_id=1194
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MAXIMUS IX EXTREME has a second EC (firmware ID "RGE2-Z270-0109"),
not handled by the ACPI EC driver, at I/O ports 0x68 (data) and 0x6c
(command/status). It uses the standard EC protocol (0x80 read, 0x81
write) and the same bank register (0xff). Its bank 1 holds the water
temperatures: WATER_IN 0x0d, WATER_OUT 0x0b, WATER_IN2 0x13 and
WATER_OUT2 0x11, as signed degrees Celsius with -60 for an absent
probe. Water_In and Water_Out are at the same offsets as on the AMD
400-series boards.

Describe registers of the second EC by setting ASUS_EC2_BANK_FLAG in
the sensor bank. Banks are sorted, so such registers are read last;
the second EC bank is saved and restored like the first one, under the
same hardware access mutex. The I/O ports are only requested for
boards using these sensors.

Add Water_In 2 and Water_Out 2 sensors and enable the four water
temperatures for the board. Readings match HWiNFO 8.54 on the same
machine.

Signed-off-by: Remy Demangeot <remy@demangeot.net>
---
 drivers/hwmon/asus-ec-sensors.c | 145 +++++++++++++++++++++++++++++++++++++---
 1 file changed, 136 insertions(+), 9 deletions(-)

diff --git a/drivers/hwmon/asus-ec-sensors.c b/drivers/hwmon/asus-ec-sensors.c
index 11dd7f587530d640b6ccc9b7952dc9da47e11c19..c1969169de6531c11a4c3485eafd54af97874991 100644
--- a/drivers/hwmon/asus-ec-sensors.c
+++ b/drivers/hwmon/asus-ec-sensors.c
@@ -26,7 +26,10 @@
 #include <linux/dev_printk.h>
 #include <linux/dmi.h>
 #include <linux/hwmon.h>
+#include <linux/delay.h>
 #include <linux/init.h>
+#include <linux/io.h>
+#include <linux/ioport.h>
 #include <linux/jiffies.h>
 #include <linux/kernel.h>
 #include <linux/module.h>
@@ -45,6 +48,21 @@ static char *mutex_path_override;
  * group of registers reports (e.g. one of the fans of the fan extension card).
  */
 #define ASUS_EC_SELECT_REGISTER	0x43
+
+/*
+ * Some boards have a second EC, not handled by the ACPI EC driver, at these
+ * I/O ports. It uses the standard EC protocol and the same bank register.
+ * Its registers are described by sensors whose bank is ASUS_EC2_BANK(n).
+ */
+#define ASUS_EC2_DATA_PORT	0x68
+#define ASUS_EC2_CMD_PORT	0x6c
+#define ASUS_EC2_BANK_FLAG	0x80
+#define ASUS_EC2_BANK(bank)	(ASUS_EC2_BANK_FLAG | (bank))
+#define ASUS_EC2_STATUS_OBF	0x01
+#define ASUS_EC2_STATUS_IBF	0x02
+#define ASUS_EC2_CMD_READ	0x80
+#define ASUS_EC2_CMD_WRITE	0x81
+#define ASUS_EC2_TIMEOUT_US	20000
 #define SENSOR_LABEL_LEN	16
 
 /*
@@ -176,6 +194,10 @@ enum ec_sensors {
 	ec_sensor_fan_ext_1,
 	ec_sensor_fan_ext_2,
 	ec_sensor_fan_ext_3,
+	/* "Water_In 2" temperature sensor reading [℃] */
+	ec_sensor_temp_water_in_2,
+	/* "Water_Out 2" temperature sensor reading [℃] */
+	ec_sensor_temp_water_out_2,
 };
 
 #define SENSOR_TEMP_CHIPSET BIT(ec_sensor_temp_chipset)
@@ -208,6 +230,8 @@ enum ec_sensors {
 #define SENSOR_FAN_EXT_1 BIT(ec_sensor_fan_ext_1)
 #define SENSOR_FAN_EXT_2 BIT(ec_sensor_fan_ext_2)
 #define SENSOR_FAN_EXT_3 BIT(ec_sensor_fan_ext_3)
+#define SENSOR_TEMP_WATER_IN_2 BIT(ec_sensor_temp_water_in_2)
+#define SENSOR_TEMP_WATER_OUT_2 BIT(ec_sensor_temp_water_out_2)
 
 /*
  * The values for temperature sensor readings without physical sensors connected.
@@ -221,7 +245,8 @@ static const s32 environment_temp_sensors =
 	SENSOR_TEMP_WATER_IN | SENSOR_TEMP_WATER_OUT |
 	SENSOR_TEMP_WATER_BLOCK_IN | SENSOR_TEMP_WATER_BLOCK_OUT |
 	SENSOR_TEMP_T_SENSOR_2 | SENSOR_TEMP_SENSOR_EXTRA_1 |
-	SENSOR_TEMP_SENSOR_EXTRA_2 | SENSOR_TEMP_SENSOR_EXTRA_3;
+	SENSOR_TEMP_SENSOR_EXTRA_2 | SENSOR_TEMP_SENSOR_EXTRA_3 |
+	SENSOR_TEMP_WATER_IN_2 | SENSOR_TEMP_WATER_OUT_2;
 
 enum board_family {
 	family_unknown,
@@ -397,6 +422,14 @@ static const struct ec_sensor_info sensors_family_intel_200[] = {
 		EC_SENSOR_SELECT("EXT_FAN2", hwmon_fan, 2, 0x00, 0x57, 0x0b),
 	[ec_sensor_fan_ext_3] =
 		EC_SENSOR_SELECT("EXT_FAN3", hwmon_fan, 2, 0x00, 0x57, 0x0c),
+	[ec_sensor_temp_water_out] =
+		EC_SENSOR("Water_Out", hwmon_temp, 1, ASUS_EC2_BANK(0x01), 0x0b),
+	[ec_sensor_temp_water_in] =
+		EC_SENSOR("Water_In", hwmon_temp, 1, ASUS_EC2_BANK(0x01), 0x0d),
+	[ec_sensor_temp_water_out_2] =
+		EC_SENSOR("Water_Out 2", hwmon_temp, 1, ASUS_EC2_BANK(0x01), 0x11),
+	[ec_sensor_temp_water_in_2] =
+		EC_SENSOR("Water_In 2", hwmon_temp, 1, ASUS_EC2_BANK(0x01), 0x13),
 };
 
 static const struct ec_sensor_info sensors_family_intel_300[] = {
@@ -561,7 +594,9 @@ static const struct ec_board_info board_info_maximus_ix_extreme = {
 	.sensors = SENSOR_TEMP_CHIPSET | SENSOR_TEMP_T_SENSOR |
 		SENSOR_TEMP_VRM | SENSOR_TEMP_SENSOR_EXTRA_1 |
 		SENSOR_TEMP_SENSOR_EXTRA_2 | SENSOR_TEMP_SENSOR_EXTRA_3 |
-		SENSOR_FAN_EXT_1 | SENSOR_FAN_EXT_2 | SENSOR_FAN_EXT_3,
+		SENSOR_FAN_EXT_1 | SENSOR_FAN_EXT_2 | SENSOR_FAN_EXT_3 |
+		SENSOR_SET_TEMP_WATER | SENSOR_TEMP_WATER_IN_2 |
+		SENSOR_TEMP_WATER_OUT_2,
 	.mutex_path = ASUS_HW_ACCESS_MUTEX_SB_PCI0_LPCB_SIO1_MUT0,
 	.family = family_intel_200_series,
 };
@@ -1263,15 +1298,84 @@ static int setup_lock_data(struct device *dev)
 	return 0;
 }
 
+static int asus_ec2_wait(bool want_obf)
+{
+	unsigned int t;
+	u8 status;
+
+	for (t = 0; t < ASUS_EC2_TIMEOUT_US; t += 10) {
+		status = inb(ASUS_EC2_CMD_PORT);
+		if (want_obf ? (status & ASUS_EC2_STATUS_OBF) :
+			       !(status & ASUS_EC2_STATUS_IBF))
+			return 0;
+		udelay(10);
+	}
+	return -ETIMEDOUT;
+}
+
+static int asus_ec2_read(u8 index, u8 *val)
+{
+	int status;
+
+	/* drop a stale byte left in the output buffer */
+	if (inb(ASUS_EC2_CMD_PORT) & ASUS_EC2_STATUS_OBF)
+		inb(ASUS_EC2_DATA_PORT);
+	status = asus_ec2_wait(false);
+	if (status)
+		return status;
+	outb(ASUS_EC2_CMD_READ, ASUS_EC2_CMD_PORT);
+	status = asus_ec2_wait(false);
+	if (status)
+		return status;
+	outb(index, ASUS_EC2_DATA_PORT);
+	status = asus_ec2_wait(true);
+	if (status)
+		return status;
+	*val = inb(ASUS_EC2_DATA_PORT);
+	return 0;
+}
+
+static int asus_ec2_write(u8 index, u8 val)
+{
+	int status;
+
+	status = asus_ec2_wait(false);
+	if (status)
+		return status;
+	outb(ASUS_EC2_CMD_WRITE, ASUS_EC2_CMD_PORT);
+	status = asus_ec2_wait(false);
+	if (status)
+		return status;
+	outb(index, ASUS_EC2_DATA_PORT);
+	status = asus_ec2_wait(false);
+	if (status)
+		return status;
+	outb(val, ASUS_EC2_DATA_PORT);
+	return asus_ec2_wait(false);
+}
+
+/* @bank may carry ASUS_EC2_BANK_FLAG to address the second EC */
+static int asus_ec_read_byte(u8 bank, u8 index, u8 *val)
+{
+	if (bank & ASUS_EC2_BANK_FLAG)
+		return asus_ec2_read(index, val);
+	return ec_read(index, val);
+}
+
 static int asus_ec_bank_switch(u8 bank, u8 *old)
 {
 	int status = 0;
 
 	if (old) {
-		status = ec_read(ASUS_EC_BANK_REGISTER, old);
+		status = asus_ec_read_byte(bank, ASUS_EC_BANK_REGISTER, old);
+		if (!status)
+			*old |= bank & ASUS_EC2_BANK_FLAG;
 	}
 	if (status || (old && (*old == bank)))
 		return status;
+	if (bank & ASUS_EC2_BANK_FLAG)
+		return asus_ec2_write(ASUS_EC_BANK_REGISTER,
+				      bank & ~ASUS_EC2_BANK_FLAG);
 	return ec_write(ASUS_EC_BANK_REGISTER, bank);
 }
 
@@ -1279,8 +1383,8 @@ static int asus_ec_block_read(const struct device *dev,
 			      struct ec_sensors_data *ec)
 {
 	int ireg, ibank, status;
-	u8 bank, reg_bank, prev_bank, select, prev_select;
-	bool select_saved;
+	u8 bank, reg_bank, prev_bank, prev_bank2, select, prev_select;
+	bool select_saved, ec2_used = false;
 
 	bank = 0;
 	status = asus_ec_bank_switch(bank, &prev_bank);
@@ -1299,7 +1403,14 @@ static int asus_ec_block_read(const struct device *dev,
 	for (ibank = 0; ibank < ec->nr_banks; ibank++) {
 		if (bank != ec->banks[ibank]) {
 			bank = ec->banks[ibank];
-			if (asus_ec_bank_switch(bank, NULL)) {
+			/* first bank of the second EC: save its bank too */
+			if ((bank & ASUS_EC2_BANK_FLAG) && !ec2_used) {
+				if (asus_ec_bank_switch(bank, &prev_bank2)) {
+					dev_warn(dev, "second EC bank switch failed");
+					break;
+				}
+				ec2_used = true;
+			} else if (asus_ec_bank_switch(bank, NULL)) {
 				dev_warn(dev, "EC bank switch to %d failed",
 					 bank);
 				break;
@@ -1312,7 +1423,7 @@ static int asus_ec_block_read(const struct device *dev,
 				continue;
 			}
 			select = register_select(ec->registers[ireg]);
-			if (select) {
+			if (select && !(bank & ASUS_EC2_BANK_FLAG)) {
 				if (!select_saved) {
 					if (ec_read(ASUS_EC_SELECT_REGISTER,
 						    &prev_select))
@@ -1322,8 +1433,9 @@ static int asus_ec_block_read(const struct device *dev,
 				if (ec_write(ASUS_EC_SELECT_REGISTER, select))
 					continue;
 			}
-			ec_read(register_index(ec->registers[ireg]),
-				ec->read_buffer + ireg);
+			asus_ec_read_byte(bank,
+					  register_index(ec->registers[ireg]),
+					  ec->read_buffer + ireg);
 		}
 		/* restore the selector while still in its bank */
 		if (select_saved &&
@@ -1331,6 +1443,9 @@ static int asus_ec_block_read(const struct device *dev,
 			dev_warn(dev, "EC selector restore failed");
 	}
 
+	if (ec2_used && asus_ec_bank_switch(prev_bank2, NULL))
+		dev_warn(dev, "second EC bank restore failed");
+
 	status = asus_ec_bank_switch(prev_bank, NULL);
 	return status;
 }
@@ -1612,6 +1727,18 @@ static int asus_ec_probe(struct platform_device *pdev)
 	}
 
 	setup_sensor_data(ec_data);
+
+	/* banks are sorted: the second EC, if used, comes last */
+	if (ec_data->nr_banks &&
+	    (ec_data->banks[ec_data->nr_banks - 1] & ASUS_EC2_BANK_FLAG)) {
+		if (!devm_request_region(dev, ASUS_EC2_DATA_PORT, 1,
+					 dev_name(dev)) ||
+		    !devm_request_region(dev, ASUS_EC2_CMD_PORT, 1,
+					 dev_name(dev))) {
+			dev_err(dev, "I/O ports of the second EC are busy");
+			return -EBUSY;
+		}
+	}
 	ec_data->registers = devm_kcalloc(dev, ec_data->nr_registers,
 					  sizeof(*ec_data->registers), GFP_KERNEL);
 	ec_data->read_buffer = devm_kcalloc(dev, ec_data->nr_registers,

-- 
2.47.3

