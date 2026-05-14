From: Colin Huang <u8813345@gmail.com>
Date: Thu, 14 May 2026 18:49:43 +0800
Subject: [PATCH linux dev-6.6 3/3] hwmon: (pmbus) add support for Delta
 E50SN12051
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260514-backport-dev-6-6-e50sn12051-driver-v1-3-44d2ef6c18dd@gmail.com>
References: <20260514-backport-dev-6-6-e50sn12051-driver-v1-0-44d2ef6c18dd@gmail.com>
In-Reply-To: <20260514-backport-dev-6-6-e50sn12051-driver-v1-0-44d2ef6c18dd@gmail.com>
To: openbmc@lists.ozlabs.org, joel@jms.id.au, andrew@codeconstruct.com.au
Cc: Colin Huang <colin.huang2@amd.com>, Colin Huang <u8813345@gmail.com>, 
 Guenter Roeck <linux@roeck-us.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778755785; l=3559;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=2rz+C1dqYzxrgqZAGjitlJyEgxXTPBWZesnlebJDpVg=;
 b=aMtqpBsEa52a3ZJFX42vg9Uukt/D9qayQVhNuOguhdvhZQ/O/u68HGhj5hO39yBwgGizi9721
 pyeBPAVzQPuDpth1KEAYDzYEr3zzA+7JFPJh+4+4qLpOo7LheclcoP3
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the pmbus driver for Delta E50SN12051 600W Non-isolated
1/8th Brick DCDC Power Modules.

Signed-off-by: Colin Huang <u8813345@gmail.com>
Reviewed-by: Guenter Roeck <linux@roeck-us.net>
Link: https://lore.kernel.org/r/20260508-add-e50sn12051-v5-3-abebdcc29665@gmail.com
Signed-off-by: Guenter Roeck <linux@roeck-us.net>
---
 drivers/hwmon/pmbus/Kconfig      |  9 +++++++
 drivers/hwmon/pmbus/Makefile     |  1 +
 drivers/hwmon/pmbus/e50sn12051.c | 52 ++++++++++++++++++++++++++++++++++++++++
 3 files changed, 62 insertions(+)

diff --git a/drivers/hwmon/pmbus/Kconfig b/drivers/hwmon/pmbus/Kconfig
index 60e74ced989a..a17050857da2 100644
--- a/drivers/hwmon/pmbus/Kconfig
+++ b/drivers/hwmon/pmbus/Kconfig
@@ -123,6 +123,15 @@ config SENSORS_DPS920AB
 	  This driver can also be built as a module. If so, the module will
 	  be called dps920ab.
 
+config SENSORS_E50SN12051
+	tristate "Delta E50SN12051 Power Modules"
+	help
+	  If you say yes here you get hardware monitoring support for Delta
+	  E50SN12051 Power Modules.
+
+	  This driver can also be built as a module. If so, the module will
+	  be called e50sn12051.
+
 config SENSORS_INA233
 	tristate "Texas Instruments INA233 and compatibles"
 	help
diff --git a/drivers/hwmon/pmbus/Makefile b/drivers/hwmon/pmbus/Makefile
index 741eee9128b7..80e9d3a72906 100644
--- a/drivers/hwmon/pmbus/Makefile
+++ b/drivers/hwmon/pmbus/Makefile
@@ -14,6 +14,7 @@ obj-$(CONFIG_SENSORS_DELTA_AHE50DC_FAN) += delta-ahe50dc-fan.o
 obj-$(CONFIG_SENSORS_FSP_3Y)	+= fsp-3y.o
 obj-$(CONFIG_SENSORS_IBM_CFFPS)	+= ibm-cffps.o
 obj-$(CONFIG_SENSORS_DPS920AB)	+= dps920ab.o
+obj-$(CONFIG_SENSORS_E50SN12051) += e50sn12051.o
 obj-$(CONFIG_SENSORS_INA233)	+= ina233.o
 obj-$(CONFIG_SENSORS_INSPUR_IPSPS) += inspur-ipsps.o
 obj-$(CONFIG_SENSORS_IR35221)	+= ir35221.o
diff --git a/drivers/hwmon/pmbus/e50sn12051.c b/drivers/hwmon/pmbus/e50sn12051.c
new file mode 100644
index 000000000000..efb4d62b2603
--- /dev/null
+++ b/drivers/hwmon/pmbus/e50sn12051.c
@@ -0,0 +1,52 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Hardware monitoring driver for E50SN12051
+ */
+
+#include <linux/i2c.h>
+#include <linux/module.h>
+#include <linux/mod_devicetable.h>
+#include "pmbus.h"
+
+static struct pmbus_driver_info e50sn12051_info = {
+	.pages = 1,
+	.format[PSC_VOLTAGE_IN] = linear,
+	.format[PSC_VOLTAGE_OUT] = linear,
+	.format[PSC_CURRENT_OUT] = linear,
+	.format[PSC_TEMPERATURE] = linear,
+	.func[0] = PMBUS_HAVE_VIN | PMBUS_HAVE_STATUS_INPUT |
+		   PMBUS_HAVE_VOUT | PMBUS_HAVE_STATUS_VOUT |
+		   PMBUS_HAVE_IOUT | PMBUS_HAVE_STATUS_IOUT |
+		   PMBUS_HAVE_TEMP | PMBUS_HAVE_STATUS_TEMP,
+};
+
+static const struct i2c_device_id e50sn12051_id[] = { { "e50sn12051", 0 }, {} };
+MODULE_DEVICE_TABLE(i2c, e50sn12051_id);
+
+static const struct of_device_id e50sn12051_of_match[] = {
+	{ .compatible = "delta,e50sn12051" },
+	{},
+};
+MODULE_DEVICE_TABLE(of, e50sn12051_of_match);
+
+static int e50sn12051_probe(struct i2c_client *client)
+{
+	return pmbus_do_probe(client, &e50sn12051_info);
+}
+
+static struct i2c_driver e50sn12051_driver = {
+	.driver = {
+		.name = "e50sn12051",
+		.of_match_table = e50sn12051_of_match,
+	},
+	.probe = e50sn12051_probe,
+
+	.id_table = e50sn12051_id,
+};
+
+module_i2c_driver(e50sn12051_driver);
+
+MODULE_AUTHOR("Kevin Chang <kevin.chang2@amd.com>");
+MODULE_DESCRIPTION("PMBus driver for E50SN12051");
+MODULE_LICENSE("GPL");
+MODULE_IMPORT_NS("PMBUS");

-- 
2.34.1

