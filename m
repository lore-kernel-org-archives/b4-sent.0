From: Eric Yang <eric.yang.wiwynn@gmail.com>
Date: Fri, 11 Sep 2026 08:37:16 +0000
Subject: [PATCH linux dev-6.18] hwmon: (pmbus) Add MPQ82D00 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-backport-mpq82d00-dev-6-18-v1-1-6a3f5eb7532b@gmail.com>
X-B4-Tracking: v=1; b=H4sIALu9o2oC/x2MQQ7CIBAAv9Ls2TUsjQT8ivFQYNWNSilo06Tp3
 8UeZzKZFSoX4QrnboXCs1QZUwM6dBAeQ7ozSmwMWmmjHBH6ITzzWD74zpPVUSmMPKNBsuhOgb2
 3veudgTbIhW+y7PMLvCR9l7/d8yNZuG7bDz5b6ql/AAAA
To: tan.siewert@9elements.com, andrew@codeconstruct.com.au, 
 openbmc@lists.ozlabs.org
Cc: Marshall_Zhan@wiwynn.com, joel@jms.id.au, Angela_Cheng@wiwynn.com, 
 Wensheng Wang <wenswang@yeah.net>, Guenter Roeck <linux@roeck-us.net>, 
 Eric Yang <eric.yang.wiwynn@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789115836; l=11563;
 i=eric.yang.wiwynn@gmail.com; s=20260911; h=from:subject:message-id;
 bh=XoIaLLi4TjhqfPrDQKq1cOXhjhSXhuvqpcUKEl4L5eQ=;
 b=7gOuXR/QfEBXeWBJEFF3NpfwlPNDTRZOqL4D6qCj+hhKfu8DthvKJfvHcQtW1IklaEqLcqWbz
 Vl1i23Q3FAvB/ra2DD9qBzkZC2+WHAieX9+8LIY3J/e281kmATnv8eF
X-Developer-Key: i=eric.yang.wiwynn@gmail.com; a=ed25519;
 pk=XYQiwgPZNUCt1JCbsO7zX8ODEiRKocz7fYwt+aWnXBs=
X-Endpoint-Received: by B4 Relay for eric.yang.wiwynn@gmail.com/20260911 with auth_id=1023
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Wensheng Wang <wenswang@yeah.net>

Add support for MPS mpq82d00 controller. This driver exposes
telemetry and limit value readings and writtings.

(cherry picked from commit ff71049f36172fd3590bd170d1bc9cdd9c3e6839)

Signed-off-by: Wensheng Wang <wenswang@yeah.net>
Link: https://lore.kernel.org/r/20260704081952.1701914-2-wenswang@yeah.net
[groeck: Fixed "WARNING: Title underline too short"]
Signed-off-by: Guenter Roeck <linux@roeck-us.net>
Signed-off-by: Eric Yang <eric.yang.wiwynn@gmail.com>
---
 Documentation/hwmon/index.rst    |   1 +
 Documentation/hwmon/mpq82d00.rst |  73 ++++++++++++
 MAINTAINERS                      |   7 ++
 drivers/hwmon/pmbus/Kconfig      |   9 ++
 drivers/hwmon/pmbus/Makefile     |   1 +
 drivers/hwmon/pmbus/mpq82d00.c   | 249 +++++++++++++++++++++++++++++++++++++++
 6 files changed, 340 insertions(+)

diff --git a/Documentation/hwmon/index.rst b/Documentation/hwmon/index.rst
index c5ab1aa5d416..136ffb914ede 100644
--- a/Documentation/hwmon/index.rst
+++ b/Documentation/hwmon/index.rst
@@ -188,6 +188,7 @@ Hardware Monitoring Kernel Drivers
    mp5990
    mp9941
    mp9945
+   mpq82d00
    mpq8785
    nct6683
    nct6775
diff --git a/Documentation/hwmon/mpq82d00.rst b/Documentation/hwmon/mpq82d00.rst
new file mode 100644
index 000000000000..0749c130bd11
--- /dev/null
+++ b/Documentation/hwmon/mpq82d00.rst
@@ -0,0 +1,73 @@
+.. SPDX-License-Identifier: GPL-2.0
+
+Kernel driver mpq82d00
+======================
+
+Supported chips:
+
+  * MPS mpq82d00
+
+    Prefix: 'mpq82d00'
+
+Author:
+
+	Wensheng Wang <wenswang@yeah.net>
+
+Description
+-----------
+
+This driver implements support for Monolithic Power Systems, Inc. (MPS)
+MPQ82D00 Step-Down Controller.
+
+Device compliant with:
+
+- PMBus rev 1.3 interface.
+
+The driver exports the following attributes via the 'sysfs' files
+for input voltage:
+
+**in1_input**
+
+**in1_label**
+
+**in1_alarm**
+
+The driver provides the following attributes for output voltage:
+
+**in2_input**
+
+**in2_label**
+
+**in2_alarm**
+
+The driver provides the following attributes for output current:
+
+**curr1_input**
+
+**curr1_label**
+
+**curr1_crit**
+
+**curr1_crit_alarm**
+
+The driver provides the following attributes for input power:
+
+**power1_input**
+
+**power1_label**
+
+**power1_alarm**
+
+The driver provides the following attributes for output power:
+
+**power2_input**
+
+**power2_label**
+
+The driver provides the following attributes for temperature:
+
+**temp1_input**
+
+**temp1_crit**
+
+**temp1_crit_alarm**
diff --git a/MAINTAINERS b/MAINTAINERS
index 1f2873fe5a84..1d8b181b55e2 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -17562,6 +17562,13 @@ S:	Maintained
 F:	Documentation/hwmon/mp9945.rst
 F:	drivers/hwmon/pmbus/mp9945.c
 
+MPS MPQ82D00 DRIVER
+M:	Wensheng Wang <wenswang@yeah.net>
+L:	linux-hwmon@vger.kernel.org
+S:	Maintained
+F:	Documentation/hwmon/mpq82d00.rst
+F:	drivers/hwmon/pmbus/mpq82d00.c
+
 MR800 AVERMEDIA USB FM RADIO DRIVER
 M:	Alexey Klimov <alexey.klimov@linaro.org>
 L:	linux-media@vger.kernel.org
diff --git a/drivers/hwmon/pmbus/Kconfig b/drivers/hwmon/pmbus/Kconfig
index 3043d1899a7e..730b6b0d1a4f 100644
--- a/drivers/hwmon/pmbus/Kconfig
+++ b/drivers/hwmon/pmbus/Kconfig
@@ -523,6 +523,15 @@ config SENSORS_MPQ7932
 	  This driver can also be built as a module. If so, the module will
 	  be called mpq7932.
 
+config SENSORS_MPQ82D00
+	tristate "MPS MPQ82D00"
+	help
+	  If you say yes here you get hardware monitoring functionality support
+	  for power management IC MPS MPQ82D00.
+
+	  This driver can also be built as a module. If so, the module will
+	  be called mpq82d00.
+
 config SENSORS_MPQ8785
 	tristate "MPS MPQ8785"
 	help
diff --git a/drivers/hwmon/pmbus/Makefile b/drivers/hwmon/pmbus/Makefile
index bd2dd3bb2e48..60a0c5770ac4 100644
--- a/drivers/hwmon/pmbus/Makefile
+++ b/drivers/hwmon/pmbus/Makefile
@@ -52,6 +52,7 @@ obj-$(CONFIG_SENSORS_MP5990)	+= mp5990.o
 obj-$(CONFIG_SENSORS_MP9941)	+= mp9941.o
 obj-$(CONFIG_SENSORS_MP9945)	+= mp9945.o
 obj-$(CONFIG_SENSORS_MPQ7932)	+= mpq7932.o
+obj-$(CONFIG_SENSORS_MPQ82D00)	+= mpq82d00.o
 obj-$(CONFIG_SENSORS_MPQ8785)	+= mpq8785.o
 obj-$(CONFIG_SENSORS_PLI1209BC)	+= pli1209bc.o
 obj-$(CONFIG_SENSORS_PM6764TR)	+= pm6764tr.o
diff --git a/drivers/hwmon/pmbus/mpq82d00.c b/drivers/hwmon/pmbus/mpq82d00.c
new file mode 100644
index 000000000000..d51fcffcc6d9
--- /dev/null
+++ b/drivers/hwmon/pmbus/mpq82d00.c
@@ -0,0 +1,249 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Hardware monitoring driver for MPS Synchronous Step-Down Converter(MPQ82D00)
+ */
+
+#include <linux/bitfield.h>
+#include <linux/err.h>
+#include <linux/i2c.h>
+#include <linux/init.h>
+#include <linux/kernel.h>
+#include <linux/module.h>
+#include "pmbus.h"
+
+#define MPQ82D00_VOUT_DIV	64
+
+#define MPQ82D00_PAGE_NUM	1
+
+#define MPQ82D00_RAIL1_FUNC	(PMBUS_HAVE_VIN | PMBUS_HAVE_VOUT | \
+							PMBUS_HAVE_IOUT | PMBUS_HAVE_TEMP | \
+							PMBUS_HAVE_POUT | PMBUS_HAVE_PIN | \
+							PMBUS_HAVE_STATUS_VOUT | \
+							PMBUS_HAVE_STATUS_IOUT | \
+							PMBUS_HAVE_STATUS_TEMP | \
+							PMBUS_HAVE_STATUS_INPUT)
+
+struct mpq82d00_data {
+	struct pmbus_driver_info info;
+	int vout_scale;
+};
+
+#define to_mpq82d00_data(x) container_of(x, struct mpq82d00_data, info)
+
+static u16 mpq82d00_linear_exp_transfer(u16 word, u16 expect_exponent)
+{
+	s16 exponent, mantissa, target_exponent;
+
+	exponent = ((s16)word) >> 11;
+	mantissa = ((s16)((word & 0x7ff) << 5)) >> 5;
+	target_exponent = (s16)((expect_exponent & 0x1f) << 11) >> 11;
+
+	/*
+	 * The MPQ82D00 does not support negtive limit value, if a negtive
+	 * limit value is written, the limit value will become to 0. And
+	 * the maximum positive limit value is limitted to 0x3FF.
+	 */
+	if (mantissa < 0) {
+		mantissa = 0;
+	} else {
+		if (exponent > target_exponent) {
+			mantissa = (1023 >> (exponent - target_exponent)) >= mantissa ?
+						mantissa << (exponent - target_exponent) :
+						0x3FF;
+		} else {
+			mantissa = clamp_val(mantissa >> (target_exponent - exponent),
+					     0, 0x3FF);
+		}
+	}
+
+	return mantissa | ((expect_exponent << 11) & 0xf800);
+}
+
+static int mpq82d00_read_byte_data(struct i2c_client *client, int page, int reg)
+{
+	int ret;
+
+	switch (reg) {
+	case PMBUS_VOUT_MODE:
+		/*
+		 * The MPQ82D00 does not follow standard PMBus protocol completely,
+		 * and the calculation of vout in this driver is based on direct
+		 * format. As a result, the format of vout is enforced to direct.
+		 */
+		ret = PB_VOUT_MODE_DIRECT;
+		break;
+	default:
+		/*
+		 * These registers are not explicitly handled by the driver,
+		 * as a result, return -ENODATA directly.
+		 */
+		ret = -ENODATA;
+		break;
+	}
+
+	return ret;
+}
+
+static int mpq82d00_read_word_data(struct i2c_client *client, int page,
+				   int phase, int reg)
+{
+	const struct pmbus_driver_info *info = pmbus_get_driver_info(client);
+	struct mpq82d00_data *data = to_mpq82d00_data(info);
+	int ret;
+
+	switch (reg) {
+	case PMBUS_STATUS_WORD:
+	case PMBUS_READ_VIN:
+	case PMBUS_READ_IOUT:
+	case PMBUS_READ_POUT:
+	case PMBUS_READ_PIN:
+	case PMBUS_READ_TEMPERATURE_1:
+	case PMBUS_IOUT_OC_FAULT_LIMIT:
+	case PMBUS_OT_FAULT_LIMIT:
+		/*
+		 * These registers are not explicitly handled by the driver,
+		 * as a result, return -ENODATA directly.
+		 */
+		ret = -ENODATA;
+		break;
+	case PMBUS_READ_VOUT:
+		ret = pmbus_read_word_data(client, page, phase, reg);
+		if (ret < 0)
+			return ret;
+
+		ret = DIV_ROUND_CLOSEST((ret & GENMASK(11, 0)) * data->vout_scale,
+					MPQ82D00_VOUT_DIV);
+		break;
+	default:
+		/*
+		 * The MPQ82D00 do not support other telemetry and limit
+		 * value reading, so, return -EINVAL directly.
+		 */
+		ret = -EINVAL;
+		break;
+	}
+
+	return ret;
+}
+
+static int mpq82d00_write_word_data(struct i2c_client *client, int page, int reg,
+				    u16 word)
+{
+	int ret;
+
+	switch (reg) {
+	case PMBUS_OT_FAULT_LIMIT:
+		/*
+		 * The PMBUS_OT_FAULT_LIMIT of MPQ82D00 is linear11 format,
+		 * and the exponent is a constant value(5'b00000), so the
+		 * exponent of word parameter should be converted to 5'b00000.
+		 */
+		ret = pmbus_write_word_data(client, page, reg,
+					    mpq82d00_linear_exp_transfer(word, 0x00));
+		break;
+	case PMBUS_IOUT_OC_FAULT_LIMIT:
+		/*
+		 * The PMBUS_IOUT_OC_FAULT_LIMIT of MPQ82D00 is linear11 format,
+		 * and the exponent is a constant value(5'b11100), so the
+		 * exponent of word parameter should be converted to 5'b11100.
+		 */
+		ret = pmbus_write_word_data(client, page, reg,
+					    mpq82d00_linear_exp_transfer(word, 0x1C));
+		break;
+	default:
+		/*
+		 * The MPQ82D00 do not support other limit value configuration,
+		 * so, return -EINVAL directly.
+		 */
+		ret = -EINVAL;
+		break;
+	}
+
+	return ret;
+}
+
+static int mpq82d00_identify(struct i2c_client *client, struct pmbus_driver_info *info)
+{
+	struct mpq82d00_data *data = to_mpq82d00_data(info);
+	int ret;
+
+	ret = i2c_smbus_write_byte_data(client, PMBUS_PAGE, 0);
+	if (ret < 0)
+		return ret;
+
+	ret = i2c_smbus_read_byte_data(client, PMBUS_VOUT_MODE);
+	if (ret < 0)
+		return ret;
+
+	/*
+	 * The MPQ82D00 supports three vout mode. If PMBUS_VOUT_MODE
+	 * bit5 is 1, the vout scale is 5mv/LSB.If PMBUS_VOUT_MODE bit5
+	 * is 0, it is linear mode, the vout scale is 1.953125mv/LSB.
+	 */
+	if (FIELD_GET(GENMASK(5, 5), ret))
+		data->vout_scale = 320;
+	else
+		data->vout_scale = 125;
+
+	return 0;
+}
+
+static struct pmbus_driver_info mpq82d00_info = {
+	.pages = MPQ82D00_PAGE_NUM,
+	.format[PSC_VOLTAGE_IN] = linear,
+	.format[PSC_CURRENT_OUT] = linear,
+	.format[PSC_TEMPERATURE] = linear,
+	.format[PSC_VOLTAGE_OUT] = direct,
+	.format[PSC_POWER] = linear,
+
+	.m[PSC_VOLTAGE_OUT] = 1,
+	.R[PSC_VOLTAGE_OUT] = 3,
+	.b[PSC_VOLTAGE_OUT] = 0,
+
+	.func[0] = MPQ82D00_RAIL1_FUNC,
+	.read_word_data = mpq82d00_read_word_data,
+	.read_byte_data = mpq82d00_read_byte_data,
+	.write_word_data = mpq82d00_write_word_data,
+	.identify = mpq82d00_identify,
+};
+
+static int mpq82d00_probe(struct i2c_client *client)
+{
+	struct mpq82d00_data *data;
+
+	data = devm_kzalloc(&client->dev, sizeof(struct mpq82d00_data), GFP_KERNEL);
+	if (!data)
+		return -ENOMEM;
+
+	memcpy(&data->info, &mpq82d00_info, sizeof(mpq82d00_info));
+
+	return pmbus_do_probe(client, &data->info);
+}
+
+static const struct i2c_device_id mpq82d00_id[] = {
+	{.name = "mpq82d00"},
+	{}
+};
+MODULE_DEVICE_TABLE(i2c, mpq82d00_id);
+
+static const struct of_device_id __maybe_unused mpq82d00_of_match[] = {
+	{.compatible = "mps,mpq82d00"},
+	{}
+};
+MODULE_DEVICE_TABLE(of, mpq82d00_of_match);
+
+static struct i2c_driver mpq82d00_driver = {
+	.driver = {
+		.name = "mpq82d00",
+		.of_match_table = mpq82d00_of_match,
+	},
+	.probe = mpq82d00_probe,
+	.id_table = mpq82d00_id,
+};
+
+module_i2c_driver(mpq82d00_driver);
+
+MODULE_AUTHOR("Wensheng Wang <wenswang@yeah.net");
+MODULE_DESCRIPTION("PMBus driver for MPS MPQ82D00 device");
+MODULE_LICENSE("GPL");
+MODULE_IMPORT_NS("PMBUS");

---
base-commit: 3a7b2a135e6b2628768fef537590c5b5bdb6fe7a
change-id: 20260911-backport-mpq82d00-dev-6-18-95cebb839396

Best regards,
-- 
Eric Yang <eric.yang.wiwynn@gmail.com>

