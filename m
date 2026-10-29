From: Remy Demangeot <remy@demangeot.net>
Date: Thu, 29 Oct 2026 08:48:03 +0100
Subject: [PATCH v2 2/2] hwmon: (asus-ec-sensors) add water temperatures for
 MAXIMUS IX EXTREME
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261029-m9e-ec2-v2-2-e9c4e2ba8415@demangeot.net>
References: <20261029-m9e-ec2-v2-0-e9c4e2ba8415@demangeot.net>
In-Reply-To: <20261029-m9e-ec2-v2-0-e9c4e2ba8415@demangeot.net>
To: "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>, 
 Eugene Shalygin <eugene.shalygin@gmail.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: Armin Wolf <W_Armin@gmx.de>, linux-acpi@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 Remy Demangeot <remy@demangeot.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793260087; l=10014;
 i=remy@demangeot.net; s=20261015; h=from:subject:message-id;
 bh=bUddSZOomQug0bdUPvkiczwVgRtc9pjFwg8Y2RnEwlc=;
 b=6/E6I0xBfvQBa8TMBSI7k6fv/DBNQgk0reaYz2Di/ZGUZH5W4MpUvksdOlH559kKQm7GOOBTz
 Ipl9J9oS2A4D1WhjwHnZZaJ8d3f4ZvR5YLAKUKmBKdM5sJGSFZru8cH
X-Developer-Key: i=remy@demangeot.net; a=ed25519;
 pk=h/s5N2ZlgZ0m+8FpMhSaCNJt0jvb9whRBAdJwpC+VAo=
X-Endpoint-Received: by B4 Relay for remy@demangeot.net/20261015 with auth_id=1194
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MAXIMUS IX EXTREME has a second EC (firmware ID "RGE2-Z270-0109"),
not described in the ACPI tables, at I/O ports 0x68 (data) and 0x6c
(command/status). It uses the standard EC protocol and the same bank
register (0xff). Its bank 1 holds the water temperatures: WATER_IN
0x0d, WATER_OUT 0x0b, WATER_IN2 0x13 and WATER_OUT2 0x11, as signed
degrees Celsius with -60 for an absent probe. Water_In and Water_Out
are at the same offsets as on the AMD 400-series boards.

Describe registers of the second EC by setting ASUS_EC2_BANK_FLAG in
the sensor bank. Banks are sorted, so such registers are read last;
the second EC bank is saved and restored like the first one, under the
same hardware access mutex. The second EC is accessed through
acpi_ec_create_polled(), only for boards using these sensors.

Sort banks as unsigned values, otherwise a bank with
ASUS_EC2_BANK_FLAG set would be sorted first.

Add Water_In 2 and Water_Out 2 sensors and enable the four water
temperatures for the board. Tested on that board: the readings match
HWiNFO 8.54, a second EC transaction takes about 1.4 ms and a full
update about 110 ms, mostly spent on the first EC.

Signed-off-by: Remy Demangeot <remy@demangeot.net>
---
 drivers/hwmon/asus-ec-sensors.c | 108 ++++++++++++++++++++++++++++++++++------
 1 file changed, 94 insertions(+), 14 deletions(-)

diff --git a/drivers/hwmon/asus-ec-sensors.c b/drivers/hwmon/asus-ec-sensors.c
index 11dd7f587530d640b6ccc9b7952dc9da47e11c19..5e59117ee332bee87cda71260630bf34a22df736 100644
--- a/drivers/hwmon/asus-ec-sensors.c
+++ b/drivers/hwmon/asus-ec-sensors.c
@@ -45,6 +45,16 @@ static char *mutex_path_override;
  * group of registers reports (e.g. one of the fans of the fan extension card).
  */
 #define ASUS_EC_SELECT_REGISTER	0x43
+
+/*
+ * Some boards have a second EC, not described in the ACPI tables, at these
+ * I/O ports. It uses the standard EC protocol and the same bank register.
+ * Its registers are described by sensors whose bank is ASUS_EC2_BANK(n).
+ */
+#define ASUS_EC2_DATA_PORT	0x68
+#define ASUS_EC2_CMD_PORT	0x6c
+#define ASUS_EC2_BANK_FLAG	0x80
+#define ASUS_EC2_BANK(bank)	(ASUS_EC2_BANK_FLAG | (bank))
 #define SENSOR_LABEL_LEN	16
 
 /*
@@ -176,6 +186,10 @@ enum ec_sensors {
 	ec_sensor_fan_ext_1,
 	ec_sensor_fan_ext_2,
 	ec_sensor_fan_ext_3,
+	/* "Water_In 2" temperature sensor reading [℃] */
+	ec_sensor_temp_water_in_2,
+	/* "Water_Out 2" temperature sensor reading [℃] */
+	ec_sensor_temp_water_out_2,
 };
 
 #define SENSOR_TEMP_CHIPSET BIT(ec_sensor_temp_chipset)
@@ -208,6 +222,8 @@ enum ec_sensors {
 #define SENSOR_FAN_EXT_1 BIT(ec_sensor_fan_ext_1)
 #define SENSOR_FAN_EXT_2 BIT(ec_sensor_fan_ext_2)
 #define SENSOR_FAN_EXT_3 BIT(ec_sensor_fan_ext_3)
+#define SENSOR_TEMP_WATER_IN_2 BIT(ec_sensor_temp_water_in_2)
+#define SENSOR_TEMP_WATER_OUT_2 BIT(ec_sensor_temp_water_out_2)
 
 /*
  * The values for temperature sensor readings without physical sensors connected.
@@ -221,7 +237,8 @@ static const s32 environment_temp_sensors =
 	SENSOR_TEMP_WATER_IN | SENSOR_TEMP_WATER_OUT |
 	SENSOR_TEMP_WATER_BLOCK_IN | SENSOR_TEMP_WATER_BLOCK_OUT |
 	SENSOR_TEMP_T_SENSOR_2 | SENSOR_TEMP_SENSOR_EXTRA_1 |
-	SENSOR_TEMP_SENSOR_EXTRA_2 | SENSOR_TEMP_SENSOR_EXTRA_3;
+	SENSOR_TEMP_SENSOR_EXTRA_2 | SENSOR_TEMP_SENSOR_EXTRA_3 |
+	SENSOR_TEMP_WATER_IN_2 | SENSOR_TEMP_WATER_OUT_2;
 
 enum board_family {
 	family_unknown,
@@ -397,6 +414,14 @@ static const struct ec_sensor_info sensors_family_intel_200[] = {
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
@@ -561,7 +586,9 @@ static const struct ec_board_info board_info_maximus_ix_extreme = {
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
@@ -1116,6 +1143,8 @@ struct ec_sensors_data {
 	/* in jiffies */
 	u64 next_update;
 	struct lock_data lock_data;
+	/* second EC, if the board has sensors there */
+	struct acpi_ec *ec2;
 	/* number of board EC sensors */
 	u8 nr_sensors;
 	/*
@@ -1180,7 +1209,7 @@ static int find_ec_sensor_index(const struct ec_sensors_data *ec,
 
 static int bank_compare(const void *a, const void *b)
 {
-	return *((const s8 *)a) - *((const s8 *)b);
+	return *((const u8 *)a) - *((const u8 *)b);
 }
 
 static void setup_sensor_data(struct ec_sensors_data *ec)
@@ -1263,27 +1292,47 @@ static int setup_lock_data(struct device *dev)
 	return 0;
 }
 
-static int asus_ec_bank_switch(u8 bank, u8 *old)
+/* @bank may carry ASUS_EC2_BANK_FLAG to address the second EC */
+static int asus_ec_read_byte(struct ec_sensors_data *ec, u8 bank, u8 index,
+			     u8 *val)
+{
+	if (bank & ASUS_EC2_BANK_FLAG)
+		return acpi_ec_read_byte(ec->ec2, index, val);
+	return ec_read(index, val);
+}
+
+static int asus_ec_write_byte(struct ec_sensors_data *ec, u8 bank, u8 index,
+			      u8 val)
+{
+	if (bank & ASUS_EC2_BANK_FLAG)
+		return acpi_ec_write_byte(ec->ec2, index, val);
+	return ec_write(index, val);
+}
+
+static int asus_ec_bank_switch(struct ec_sensors_data *ec, u8 bank, u8 *old)
 {
 	int status = 0;
 
 	if (old) {
-		status = ec_read(ASUS_EC_BANK_REGISTER, old);
+		status = asus_ec_read_byte(ec, bank, ASUS_EC_BANK_REGISTER, old);
+		if (!status)
+			*old |= bank & ASUS_EC2_BANK_FLAG;
 	}
 	if (status || (old && (*old == bank)))
 		return status;
-	return ec_write(ASUS_EC_BANK_REGISTER, bank);
+	return asus_ec_write_byte(ec, bank, ASUS_EC_BANK_REGISTER,
+				  bank & ~ASUS_EC2_BANK_FLAG);
 }
 
 static int asus_ec_block_read(const struct device *dev,
 			      struct ec_sensors_data *ec)
 {
 	int ireg, ibank, status;
-	u8 bank, reg_bank, prev_bank, select, prev_select;
-	bool select_saved;
+	u8 bank, reg_bank, prev_bank, prev_bank2, select, prev_select;
+	bool select_saved, ec2_used = false;
 
 	bank = 0;
-	status = asus_ec_bank_switch(bank, &prev_bank);
+	status = asus_ec_bank_switch(ec, bank, &prev_bank);
 	if (status) {
 		dev_warn(dev, "EC bank switch failed");
 		return status;
@@ -1299,7 +1348,14 @@ static int asus_ec_block_read(const struct device *dev,
 	for (ibank = 0; ibank < ec->nr_banks; ibank++) {
 		if (bank != ec->banks[ibank]) {
 			bank = ec->banks[ibank];
-			if (asus_ec_bank_switch(bank, NULL)) {
+			/* first bank of the second EC: save its bank too */
+			if ((bank & ASUS_EC2_BANK_FLAG) && !ec2_used) {
+				if (asus_ec_bank_switch(ec, bank, &prev_bank2)) {
+					dev_warn(dev, "second EC bank switch failed");
+					break;
+				}
+				ec2_used = true;
+			} else if (asus_ec_bank_switch(ec, bank, NULL)) {
 				dev_warn(dev, "EC bank switch to %d failed",
 					 bank);
 				break;
@@ -1312,7 +1368,7 @@ static int asus_ec_block_read(const struct device *dev,
 				continue;
 			}
 			select = register_select(ec->registers[ireg]);
-			if (select) {
+			if (select && !(bank & ASUS_EC2_BANK_FLAG)) {
 				if (!select_saved) {
 					if (ec_read(ASUS_EC_SELECT_REGISTER,
 						    &prev_select))
@@ -1322,8 +1378,9 @@ static int asus_ec_block_read(const struct device *dev,
 				if (ec_write(ASUS_EC_SELECT_REGISTER, select))
 					continue;
 			}
-			ec_read(register_index(ec->registers[ireg]),
-				ec->read_buffer + ireg);
+			asus_ec_read_byte(ec, bank,
+					  register_index(ec->registers[ireg]),
+					  ec->read_buffer + ireg);
 		}
 		/* restore the selector while still in its bank */
 		if (select_saved &&
@@ -1331,7 +1388,10 @@ static int asus_ec_block_read(const struct device *dev,
 			dev_warn(dev, "EC selector restore failed");
 	}
 
-	status = asus_ec_bank_switch(prev_bank, NULL);
+	if (ec2_used && asus_ec_bank_switch(ec, prev_bank2, NULL))
+		dev_warn(dev, "second EC bank restore failed");
+
+	status = asus_ec_bank_switch(ec, prev_bank, NULL);
 	return status;
 }
 
@@ -1531,6 +1591,11 @@ static const struct ec_board_info *get_board_info(void)
 	return dmi_entry ? dmi_entry->driver_data : NULL;
 }
 
+static void asus_ec2_destroy(void *ec2)
+{
+	acpi_ec_destroy_polled(ec2);
+}
+
 static int asus_ec_probe(struct platform_device *pdev)
 {
 	const struct hwmon_channel_info **ptr_asus_ec_ci;
@@ -1612,6 +1677,21 @@ static int asus_ec_probe(struct platform_device *pdev)
 	}
 
 	setup_sensor_data(ec_data);
+
+	/* banks are sorted: the second EC, if used, comes last */
+	if (ec_data->nr_banks &&
+	    (ec_data->banks[ec_data->nr_banks - 1] & ASUS_EC2_BANK_FLAG)) {
+		ec_data->ec2 = acpi_ec_create_polled(ASUS_EC2_CMD_PORT,
+						     ASUS_EC2_DATA_PORT,
+						     dev_name(dev));
+		if (IS_ERR(ec_data->ec2))
+			return dev_err_probe(dev, PTR_ERR(ec_data->ec2),
+					     "Failed to set up the second EC");
+		status = devm_add_action_or_reset(dev, asus_ec2_destroy,
+						  ec_data->ec2);
+		if (status)
+			return status;
+	}
 	ec_data->registers = devm_kcalloc(dev, ec_data->nr_registers,
 					  sizeof(*ec_data->registers), GFP_KERNEL);
 	ec_data->read_buffer = devm_kcalloc(dev, ec_data->nr_registers,

-- 
2.47.3

