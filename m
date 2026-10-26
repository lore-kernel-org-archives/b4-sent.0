From: Remy Demangeot <remy@demangeot.net>
Date: Mon, 26 Oct 2026 09:57:36 +0100
Subject: [PATCH 2/3] hwmon: (asus-ec-sensors) add fan extension card fans
 for MAXIMUS IX EXTREME
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261026-b4-m9e-ext-sensors-v1-2-644d389b2de1@demangeot.net>
References: <20261026-b4-m9e-ext-sensors-v1-0-644d389b2de1@demangeot.net>
In-Reply-To: <20261026-b4-m9e-ext-sensors-v1-0-644d389b2de1@demangeot.net>
To: Eugene Shalygin <eugene.shalygin@gmail.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Remy Demangeot <remy@demangeot.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793005066; l=7622;
 i=remy@demangeot.net; s=20261015; h=from:subject:message-id;
 bh=LdPDWOOXu5+bn6S2DQij9p3ZSC20bPIIjFmi5NcOJLg=;
 b=jpu8zO8LBvTFr9Xxa/FtBF1iebKBX+xyfsHa2qThl5vOUIZAEyj4ffB36N9himgC16Syf7tTW
 7xEV4jIL3zvBlymCLHCJULaSCthKMN2+fTzMknYg+y/sh57wZVui/Sc
X-Developer-Key: i=remy@demangeot.net; a=ed25519;
 pk=h/s5N2ZlgZ0m+8FpMhSaCNJt0jvb9whRBAdJwpC+VAo=
X-Endpoint-Received: by B4 Relay for remy@demangeot.net/20261015 with auth_id=1194
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the MAXIMUS IX EXTREME, the speeds of the three fans on the
optional ASUS fan extension card (EXT_FAN1-3) are not at fixed EC
addresses. Bank 0 register 0x43 selects which fan a group of registers
describes: after writing 0x0a, 0x0b or 0x0c to it, registers 0x57:0x58
hold the RPM of EXT_FAN1, EXT_FAN2 or EXT_FAN3 (big-endian).

Allow a sensor definition to carry a selector value, using the unused
byte of sensor_address. When reading such a register, the driver
writes the selector first and restores the previous selector value
once the bank has been read. Sensors without a selector are read as
before.

Readings match HWiNFO 8.54 on the same machine, and follow the fan
speed when the fan duty is changed.

Signed-off-by: Remy Demangeot <remy@demangeot.net>
---
 drivers/hwmon/asus-ec-sensors.c | 75 ++++++++++++++++++++++++++++++++++++-----
 1 file changed, 66 insertions(+), 9 deletions(-)

diff --git a/drivers/hwmon/asus-ec-sensors.c b/drivers/hwmon/asus-ec-sensors.c
index 8966053b58173592a19afbab42ccbe8e6e6d7042..11dd7f587530d640b6ccc9b7952dc9da47e11c19 100644
--- a/drivers/hwmon/asus-ec-sensors.c
+++ b/drivers/hwmon/asus-ec-sensors.c
@@ -40,6 +40,11 @@ static char *mutex_path_override;
 
 /* Writing to this EC register switches EC bank */
 #define ASUS_EC_BANK_REGISTER	0xff
+/*
+ * On some boards, writing to this bank 0 register selects which device a
+ * group of registers reports (e.g. one of the fans of the fan extension card).
+ */
+#define ASUS_EC_SELECT_REGISTER	0x43
 #define SENSOR_LABEL_LEN	16
 
 /*
@@ -73,7 +78,8 @@ typedef union {
 		u8 index;
 		u8 bank;
 		u8 size;
-		u8 dummy;
+		/* value to write to ASUS_EC_SELECT_REGISTER first, 0 if none */
+		u8 select;
 	} components;
 } sensor_address;
 
@@ -81,6 +87,11 @@ typedef union {
 		.value = (size << 16) + (bank << 8) + index                    \
 	}
 
+#define MAKE_SENSOR_ADDRESS_SELECT(size, bank, index, select) {               \
+		.value = ((u32)(select) << 24) + ((size) << 16) +            \
+			 ((bank) << 8) + (index)                               \
+	}
+
 static u32 hwmon_attributes[hwmon_max] = {
 	[hwmon_chip] = HWMON_C_REGISTER_TZ,
 	[hwmon_temp] = HWMON_T_INPUT | HWMON_T_LABEL,
@@ -100,6 +111,12 @@ struct ec_sensor_info {
 		.addr = MAKE_SENSOR_ADDRESS(size, bank, index),                \
 	}
 
+/* A sensor read after writing @select to ASUS_EC_SELECT_REGISTER */
+#define EC_SENSOR_SELECT(sensor_label, sensor_type, size, bank, index, select) {\
+		.label = sensor_label, .type = sensor_type,                    \
+		.addr = MAKE_SENSOR_ADDRESS_SELECT(size, bank, index, select), \
+	}
+
 enum ec_sensors {
 	/* chipset temperature [℃] */
 	ec_sensor_temp_chipset,
@@ -155,6 +172,10 @@ enum ec_sensors {
 	ec_sensor_temp_sensor_extra_2,
 	/* "Extra_3" temperature sensor reading [℃] */
 	ec_sensor_temp_sensor_extra_3,
+	/* fan extension card fans [RPM] */
+	ec_sensor_fan_ext_1,
+	ec_sensor_fan_ext_2,
+	ec_sensor_fan_ext_3,
 };
 
 #define SENSOR_TEMP_CHIPSET BIT(ec_sensor_temp_chipset)
@@ -184,6 +205,9 @@ enum ec_sensors {
 #define SENSOR_TEMP_SENSOR_EXTRA_1 BIT(ec_sensor_temp_sensor_extra_1)
 #define SENSOR_TEMP_SENSOR_EXTRA_2 BIT(ec_sensor_temp_sensor_extra_2)
 #define SENSOR_TEMP_SENSOR_EXTRA_3 BIT(ec_sensor_temp_sensor_extra_3)
+#define SENSOR_FAN_EXT_1 BIT(ec_sensor_fan_ext_1)
+#define SENSOR_FAN_EXT_2 BIT(ec_sensor_fan_ext_2)
+#define SENSOR_FAN_EXT_3 BIT(ec_sensor_fan_ext_3)
 
 /*
  * The values for temperature sensor readings without physical sensors connected.
@@ -367,6 +391,12 @@ static const struct ec_sensor_info sensors_family_intel_200[] = {
 		EC_SENSOR("Extra_3", hwmon_temp, 1, 0x00, 0x62),
 	[ec_sensor_fan_cpu_opt] =
 		EC_SENSOR("CPU_Opt", hwmon_fan, 2, 0x00, 0xbc),
+	[ec_sensor_fan_ext_1] =
+		EC_SENSOR_SELECT("EXT_FAN1", hwmon_fan, 2, 0x00, 0x57, 0x0a),
+	[ec_sensor_fan_ext_2] =
+		EC_SENSOR_SELECT("EXT_FAN2", hwmon_fan, 2, 0x00, 0x57, 0x0b),
+	[ec_sensor_fan_ext_3] =
+		EC_SENSOR_SELECT("EXT_FAN3", hwmon_fan, 2, 0x00, 0x57, 0x0c),
 };
 
 static const struct ec_sensor_info sensors_family_intel_300[] = {
@@ -530,7 +560,8 @@ static const struct ec_board_info board_info_maximus_vi_hero = {
 static const struct ec_board_info board_info_maximus_ix_extreme = {
 	.sensors = SENSOR_TEMP_CHIPSET | SENSOR_TEMP_T_SENSOR |
 		SENSOR_TEMP_VRM | SENSOR_TEMP_SENSOR_EXTRA_1 |
-		SENSOR_TEMP_SENSOR_EXTRA_2 | SENSOR_TEMP_SENSOR_EXTRA_3,
+		SENSOR_TEMP_SENSOR_EXTRA_2 | SENSOR_TEMP_SENSOR_EXTRA_3 |
+		SENSOR_FAN_EXT_1 | SENSOR_FAN_EXT_2 | SENSOR_FAN_EXT_3,
 	.mutex_path = ASUS_HW_ACCESS_MUTEX_SB_PCI0_LPCB_SIO1_MUT0,
 	.family = family_intel_200_series,
 };
@@ -1074,8 +1105,11 @@ struct ec_sensors_data {
 	const struct ec_board_info *board_info;
 	const struct ec_sensor_info *sensors_info;
 	struct ec_sensor *sensors;
-	/* EC registers to read from */
-	u16 *registers;
+	/*
+	 * EC registers to read from: (select << 16) + (bank << 8) + index,
+	 * see register_select()
+	 */
+	u32 *registers;
 	u8 *read_buffer;
 	/* sorted list of unique register banks */
 	u8 banks[ASUS_EC_MAX_BANK + 1];
@@ -1093,16 +1127,21 @@ struct ec_sensors_data {
 	u8 nr_banks;
 };
 
-static u8 register_bank(u16 reg)
+static u8 register_bank(u32 reg)
 {
-	return reg >> 8;
+	return (reg >> 8) & 0xff;
 }
 
-static u8 register_index(u16 reg)
+static u8 register_index(u32 reg)
 {
 	return reg & 0x00ff;
 }
 
+static u8 register_select(u32 reg)
+{
+	return (reg >> 16) & 0xff;
+}
+
 static bool is_sensor_data_signed(const struct ec_sensor_info *si)
 {
 	/*
@@ -1185,6 +1224,7 @@ static void fill_ec_registers(struct ec_sensors_data *ec)
 		si = get_sensor_info(ec, i);
 		for (j = 0; j < si->addr.components.size; ++j, ++register_idx) {
 			ec->registers[register_idx] =
+				(si->addr.components.select << 16) +
 				(si->addr.components.bank << 8) +
 				si->addr.components.index + j;
 		}
@@ -1239,7 +1279,8 @@ static int asus_ec_block_read(const struct device *dev,
 			      struct ec_sensors_data *ec)
 {
 	int ireg, ibank, status;
-	u8 bank, reg_bank, prev_bank;
+	u8 bank, reg_bank, prev_bank, select, prev_select;
+	bool select_saved;
 
 	bank = 0;
 	status = asus_ec_bank_switch(bank, &prev_bank);
@@ -1264,14 +1305,30 @@ static int asus_ec_block_read(const struct device *dev,
 				break;
 			}
 		}
+		select_saved = false;
 		for (ireg = 0; ireg < ec->nr_registers; ireg++) {
 			reg_bank = register_bank(ec->registers[ireg]);
 			if (reg_bank != bank) {
 				continue;
 			}
+			select = register_select(ec->registers[ireg]);
+			if (select) {
+				if (!select_saved) {
+					if (ec_read(ASUS_EC_SELECT_REGISTER,
+						    &prev_select))
+						continue;
+					select_saved = true;
+				}
+				if (ec_write(ASUS_EC_SELECT_REGISTER, select))
+					continue;
+			}
 			ec_read(register_index(ec->registers[ireg]),
 				ec->read_buffer + ireg);
 		}
+		/* restore the selector while still in its bank */
+		if (select_saved &&
+		    ec_write(ASUS_EC_SELECT_REGISTER, prev_select))
+			dev_warn(dev, "EC selector restore failed");
 	}
 
 	status = asus_ec_bank_switch(prev_bank, NULL);
@@ -1556,7 +1613,7 @@ static int asus_ec_probe(struct platform_device *pdev)
 
 	setup_sensor_data(ec_data);
 	ec_data->registers = devm_kcalloc(dev, ec_data->nr_registers,
-					  sizeof(u16), GFP_KERNEL);
+					  sizeof(*ec_data->registers), GFP_KERNEL);
 	ec_data->read_buffer = devm_kcalloc(dev, ec_data->nr_registers,
 					    sizeof(u8), GFP_KERNEL);
 

-- 
2.47.3

