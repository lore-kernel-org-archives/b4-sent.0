From: Serv Pol <servpol@tuta.io>
Date: Mon, 05 Oct 2026 22:25:25 +0000
Subject: [PATCH 2/2] power: supply: Add GL.iNet GL-E750 MCU battery driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261005-gl-e750-mcu-v1-2-499d2e31f786@tuta.io>
References: <20261005-gl-e750-mcu-v1-0-499d2e31f786@tuta.io>
In-Reply-To: <20261005-gl-e750-mcu-v1-0-499d2e31f786@tuta.io>
To: Serv Pol <servpol@tuta.io>, Sebastian Reichel <sre@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791239123; l=13339;
 i=servpol@tuta.io; s=20261005; h=from:subject:message-id;
 bh=rcgI0nZmKFG3g5c+fhrZDMdvXPcReybCrASp7IB4yxw=;
 b=AX6ou7+uEHrr6OE+DsLlq1wRwblaE711F83M7CtD8FAEFBczJsDn6tEG8bIqDFjlldOloIhJs
 SBXOyHOCF8rC2FUL4O/zsL8WM8lpFBmvi6rL6eJi9Mdgg9eImOPWPeE
X-Developer-Key: i=servpol@tuta.io; a=ed25519;
 pk=2HCjaqYjXxgwTYu30Nem9DOHT8mtKgjitt1vEXKpwrE=
X-Endpoint-Received: by B4 Relay for servpol@tuta.io/20261005 with auth_id=1120
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The status MCU of the GL.iNet GL-E750 (Mudi) travel router sits on the
SoC UART and talks in text lines: the host sends JSON objects whose values
are all strings, and a request containing "mcu_status": "1" is answered
with

  {OK},<percent>,<temperature>,<charging>,<cycles>

Poll that every 30 seconds and expose the result as a power_supply.

When the power switch is turned off, the MCU sends {"shut_down": "1"},
without a line ending, and cuts the power a few seconds later. Shut the
system down cleanly in that case.

The MCU also renders the status screen from JSON fields (SSIDs, clients,
cellular state...). That vendor-specific content is not handled here.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Serv Pol <servpol@tuta.io>
---
 MAINTAINERS                        |   1 +
 drivers/power/supply/Kconfig       |  13 ++
 drivers/power/supply/Makefile      |   1 +
 drivers/power/supply/gl-e750-mcu.c | 352 +++++++++++++++++++++++++++++++++++++
 4 files changed, 367 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 247432449..505aa205c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -11110,6 +11110,7 @@ M:	Serv Pol <servpol@tuta.io>
 L:	linux-pm@vger.kernel.org
 S:	Maintained
 F:	Documentation/devicetree/bindings/power/supply/glinet,gl-e750-mcu.yaml
+F:	drivers/power/supply/gl-e750-mcu.c
 
 GNSS SUBSYSTEM
 M:	Johan Hovold <johan@kernel.org>
diff --git a/drivers/power/supply/Kconfig b/drivers/power/supply/Kconfig
index ee7dc5f26..e87c76c18 100644
--- a/drivers/power/supply/Kconfig
+++ b/drivers/power/supply/Kconfig
@@ -1203,4 +1203,17 @@ config MACSMC_POWER
 
 	  Say Y or M here if you have an Apple Silicon based Mac.
 
+config BATTERY_GL_E750_MCU
+	tristate "GL.iNet GL-E750 status MCU battery driver"
+	depends on SERIAL_DEV_BUS
+	depends on OF || COMPILE_TEST
+	help
+	  Say Y or M here to enable the battery driver for the status
+	  microcontroller of the GL.iNet GL-E750 (Mudi) travel router.
+	  It reports the battery state and shuts the system down when
+	  the power switch is turned off.
+
+	  To compile this driver as a module, choose M here: the module
+	  will be called gl-e750-mcu.
+
 endif # POWER_SUPPLY
diff --git a/drivers/power/supply/Makefile b/drivers/power/supply/Makefile
index f3c0d1006..5d405556e 100644
--- a/drivers/power/supply/Makefile
+++ b/drivers/power/supply/Makefile
@@ -78,6 +78,7 @@ obj-$(CONFIG_CHARGER_TWL4030)	+= twl4030_charger.o
 obj-$(CONFIG_CHARGER_TWL6030)	+= twl6030_charger.o
 obj-$(CONFIG_CHARGER_LP8727)	+= lp8727_charger.o
 obj-$(CONFIG_CHARGER_LP8788)	+= lp8788-charger.o
+obj-$(CONFIG_BATTERY_GL_E750_MCU)	+= gl-e750-mcu.o
 obj-$(CONFIG_CHARGER_GPIO)	+= gpio-charger.o
 obj-$(CONFIG_CHARGER_MANAGER)	+= charger-manager.o
 obj-$(CONFIG_CHARGER_LT3651)	+= lt3651-charger.o
diff --git a/drivers/power/supply/gl-e750-mcu.c b/drivers/power/supply/gl-e750-mcu.c
new file mode 100644
index 000000000..0799e41d5
--- /dev/null
+++ b/drivers/power/supply/gl-e750-mcu.c
@@ -0,0 +1,352 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * GL.iNet GL-E750 (Mudi) status MCU battery driver
+ *
+ * The MCU sits on the SoC UART. It drives the OLED screen, monitors the
+ * battery and watches the power switch. The host sends one JSON object per
+ * line, where every value is a string. When a line contains
+ * "mcu_status": "1", the MCU answers with
+ *
+ *	{OK},<percent>,<temperature>,<charging>,<cycles>
+ *
+ * When the power switch is turned off, the MCU sends {"shut_down": "1"} and
+ * cuts the power a few seconds later.
+ *
+ * Copyright (C) 2026 Serv Pol <servpol@tuta.io>
+ */
+
+#include <linux/completion.h>
+#include <linux/ctype.h>
+#include <linux/devm-helpers.h>
+#include <linux/math.h>
+#include <linux/mod_devicetable.h>
+#include <linux/module.h>
+#include <linux/power_supply.h>
+#include <linux/property.h>
+#include <linux/reboot.h>
+#include <linux/serdev.h>
+#include <linux/spinlock.h>
+#include <linux/string.h>
+#include <linux/workqueue.h>
+
+#define MCU_BAUDRATE		115200
+#define MCU_RX_LINE_MAX		128
+#define MCU_POLL_INTERVAL_MS	30000
+#define MCU_REPLY_TIMEOUT_MS	1500
+
+static const u8 mcu_status_req[] = "{ \"mcu_status\": \"1\" }\n";
+
+struct gl_e750_mcu {
+	struct serdev_device *serdev;
+	struct power_supply *psy;
+	struct delayed_work poll_work;
+	struct work_struct poweroff_work;
+	struct completion reply;
+
+	/* receive buffer and battery state, filled from the serdev callback */
+	spinlock_t lock;
+	char rx_line[MCU_RX_LINE_MAX];
+	size_t rx_len;
+	bool valid;
+	int capacity;		/* percent */
+	int temp;		/* tenths of a degree Celsius */
+	bool charging;
+	int cycles;
+};
+
+/* "37.4", "40" or "-1.5" -> tenths of a degree */
+static int mcu_parse_tenths(const char *s, int *out)
+{
+	const char *dot = strchr(s, '.');
+	char whole_str[8];
+	int whole, frac = 0;
+
+	if (!dot) {
+		if (kstrtoint(s, 10, &whole))
+			return -EINVAL;
+		*out = whole * 10;
+		return 0;
+	}
+
+	if (dot == s || dot - s >= sizeof(whole_str))
+		return -EINVAL;
+	memcpy(whole_str, s, dot - s);
+	whole_str[dot - s] = '\0';
+	if (kstrtoint(whole_str, 10, &whole))
+		return -EINVAL;
+	if (isdigit(dot[1]))
+		frac = dot[1] - '0';
+	*out = whole * 10 + (*s == '-' ? -frac : frac);
+	return 0;
+}
+
+/*
+ * "{OK},<percent>,<temperature>,<charging>,<cycles>", called with the lock
+ * held. Returns true if the line was a valid status reply.
+ */
+static bool mcu_parse_status(struct gl_e750_mcu *mcu, char *line)
+{
+	char *p = line + 4, *f[4];
+	int capacity, temp, charging, cycles, i;
+	bool changed;
+
+	if (*p++ != ',')
+		return false;
+	for (i = 0; i < ARRAY_SIZE(f); i++) {
+		f[i] = strsep(&p, ",");
+		if (!f[i] || !*f[i])
+			return false;
+	}
+
+	if (kstrtoint(f[0], 10, &capacity) || mcu_parse_tenths(f[1], &temp) ||
+	    kstrtoint(f[2], 10, &charging) || kstrtoint(f[3], 10, &cycles))
+		return false;
+	if (capacity < 0 || capacity > 100)
+		return false;
+
+	changed = !mcu->valid || mcu->capacity != capacity ||
+		  mcu->charging != !!charging || mcu->cycles != cycles ||
+		  abs(mcu->temp - temp) >= 10;
+	mcu->capacity = capacity;
+	mcu->temp = temp;
+	mcu->charging = !!charging;
+	mcu->cycles = cycles;
+	mcu->valid = true;
+
+	complete(&mcu->reply);
+	if (changed)
+		power_supply_changed(mcu->psy);
+	return true;
+}
+
+/* called with the lock held */
+static void mcu_handle_line(struct gl_e750_mcu *mcu, char *line)
+{
+	if (!strncmp(line, "{OK}", 4))
+		mcu_parse_status(mcu, line);
+	else if (strstr(line, "\"shut_down\""))
+		schedule_work(&mcu->poweroff_work);
+	else
+		dev_dbg_ratelimited(&mcu->serdev->dev, "unhandled: %s\n", line);
+}
+
+static size_t mcu_receive_buf(struct serdev_device *serdev, const u8 *data,
+			      size_t count)
+{
+	struct gl_e750_mcu *mcu = serdev_device_get_drvdata(serdev);
+	unsigned long flags;
+	size_t i;
+
+	spin_lock_irqsave(&mcu->lock, flags);
+	for (i = 0; i < count; i++) {
+		char c = data[i];
+
+		if (c == '\r' || c == '\n') {
+			if (mcu->rx_len) {
+				mcu->rx_line[mcu->rx_len] = '\0';
+				mcu_handle_line(mcu, mcu->rx_line);
+				mcu->rx_len = 0;
+			}
+			continue;
+		}
+		if (mcu->rx_len < MCU_RX_LINE_MAX - 1)
+			mcu->rx_line[mcu->rx_len++] = c;
+
+		/* JSON events from the MCU come without a line ending */
+		if (c == '}' && mcu->rx_line[0] == '{' &&
+		    strncmp(mcu->rx_line, "{OK}", 4)) {
+			mcu->rx_line[mcu->rx_len] = '\0';
+			mcu_handle_line(mcu, mcu->rx_line);
+			mcu->rx_len = 0;
+		}
+	}
+	spin_unlock_irqrestore(&mcu->lock, flags);
+
+	return count;
+}
+
+static const struct serdev_device_ops mcu_serdev_ops = {
+	.receive_buf = mcu_receive_buf,
+	.write_wakeup = serdev_device_write_wakeup,
+};
+
+static void mcu_poll_work(struct work_struct *work)
+{
+	struct gl_e750_mcu *mcu = container_of(to_delayed_work(work),
+					       struct gl_e750_mcu, poll_work);
+	unsigned long timeout = msecs_to_jiffies(MCU_REPLY_TIMEOUT_MS);
+	unsigned long flags;
+	int ret;
+
+	spin_lock_irqsave(&mcu->lock, flags);
+	mcu->rx_len = 0;
+	reinit_completion(&mcu->reply);
+	spin_unlock_irqrestore(&mcu->lock, flags);
+
+	ret = serdev_device_write(mcu->serdev, mcu_status_req,
+				  sizeof(mcu_status_req) - 1, timeout);
+	if (ret < 0) {
+		dev_warn_ratelimited(&mcu->serdev->dev, "write failed: %d\n", ret);
+	} else if (!wait_for_completion_timeout(&mcu->reply, timeout)) {
+		/* the reply may also come without a line ending */
+		spin_lock_irqsave(&mcu->lock, flags);
+		mcu->rx_line[mcu->rx_len] = '\0';
+		if (!(mcu->rx_len > 4 && !strncmp(mcu->rx_line, "{OK}", 4) &&
+		      mcu_parse_status(mcu, mcu->rx_line)))
+			dev_dbg(&mcu->serdev->dev, "no status reply\n");
+		mcu->rx_len = 0;
+		spin_unlock_irqrestore(&mcu->lock, flags);
+	}
+
+	schedule_delayed_work(&mcu->poll_work,
+			      msecs_to_jiffies(MCU_POLL_INTERVAL_MS));
+}
+
+static void mcu_poweroff_work(struct work_struct *work)
+{
+	struct gl_e750_mcu *mcu = container_of(work, struct gl_e750_mcu,
+					       poweroff_work);
+
+	/* the MCU cuts the power a few seconds after reporting the switch */
+	dev_info(&mcu->serdev->dev, "power switch turned off, shutting down\n");
+	orderly_poweroff(true);
+}
+
+static const enum power_supply_property mcu_battery_props[] = {
+	POWER_SUPPLY_PROP_PRESENT,
+	POWER_SUPPLY_PROP_STATUS,
+	POWER_SUPPLY_PROP_TECHNOLOGY,
+	POWER_SUPPLY_PROP_CAPACITY,
+	POWER_SUPPLY_PROP_TEMP,
+	POWER_SUPPLY_PROP_CYCLE_COUNT,
+};
+
+static int mcu_battery_get_property(struct power_supply *psy,
+				    enum power_supply_property psp,
+				    union power_supply_propval *val)
+{
+	struct gl_e750_mcu *mcu = power_supply_get_drvdata(psy);
+	unsigned long flags;
+	int ret = 0;
+
+	spin_lock_irqsave(&mcu->lock, flags);
+	switch (psp) {
+	case POWER_SUPPLY_PROP_PRESENT:
+		val->intval = 1;
+		break;
+	case POWER_SUPPLY_PROP_TECHNOLOGY:
+		val->intval = POWER_SUPPLY_TECHNOLOGY_LION;
+		break;
+	case POWER_SUPPLY_PROP_STATUS:
+		if (!mcu->valid)
+			val->intval = POWER_SUPPLY_STATUS_UNKNOWN;
+		else if (mcu->charging)
+			val->intval = mcu->capacity >= 100 ?
+				      POWER_SUPPLY_STATUS_FULL :
+				      POWER_SUPPLY_STATUS_CHARGING;
+		else
+			val->intval = POWER_SUPPLY_STATUS_DISCHARGING;
+		break;
+	case POWER_SUPPLY_PROP_CAPACITY:
+		if (mcu->valid)
+			val->intval = mcu->capacity;
+		else
+			ret = -ENODATA;
+		break;
+	case POWER_SUPPLY_PROP_TEMP:
+		if (mcu->valid)
+			val->intval = mcu->temp;
+		else
+			ret = -ENODATA;
+		break;
+	case POWER_SUPPLY_PROP_CYCLE_COUNT:
+		if (mcu->valid)
+			val->intval = mcu->cycles;
+		else
+			ret = -ENODATA;
+		break;
+	default:
+		ret = -EINVAL;
+	}
+	spin_unlock_irqrestore(&mcu->lock, flags);
+
+	return ret;
+}
+
+static const struct power_supply_desc mcu_battery_desc = {
+	.name = "gl-e750-battery",
+	.type = POWER_SUPPLY_TYPE_BATTERY,
+	.properties = mcu_battery_props,
+	.num_properties = ARRAY_SIZE(mcu_battery_props),
+	.get_property = mcu_battery_get_property,
+};
+
+static int gl_e750_mcu_probe(struct serdev_device *serdev)
+{
+	struct device *dev = &serdev->dev;
+	struct power_supply_config psy_cfg = {};
+	struct gl_e750_mcu *mcu;
+	int ret;
+
+	mcu = devm_kzalloc(dev, sizeof(*mcu), GFP_KERNEL);
+	if (!mcu)
+		return -ENOMEM;
+
+	mcu->serdev = serdev;
+	spin_lock_init(&mcu->lock);
+	init_completion(&mcu->reply);
+	serdev_device_set_drvdata(serdev, mcu);
+	serdev_device_set_client_ops(serdev, &mcu_serdev_ops);
+
+	/*
+	 * devm teardown runs in reverse: the poll work is cancelled before the
+	 * port is closed, the power-off work (queued from the receive path)
+	 * and the battery only after it.
+	 */
+	psy_cfg.drv_data = mcu;
+	psy_cfg.fwnode = dev_fwnode(dev);
+	mcu->psy = devm_power_supply_register(dev, &mcu_battery_desc, &psy_cfg);
+	if (IS_ERR(mcu->psy))
+		return dev_err_probe(dev, PTR_ERR(mcu->psy),
+				     "failed to register battery\n");
+
+	ret = devm_work_autocancel(dev, &mcu->poweroff_work, mcu_poweroff_work);
+	if (ret)
+		return ret;
+
+	ret = devm_serdev_device_open(dev, serdev);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to open serdev\n");
+
+	serdev_device_set_baudrate(serdev, MCU_BAUDRATE);
+	serdev_device_set_flow_control(serdev, false);
+	ret = serdev_device_set_parity(serdev, SERDEV_PARITY_NONE);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to set parity\n");
+
+	ret = devm_delayed_work_autocancel(dev, &mcu->poll_work, mcu_poll_work);
+	if (ret)
+		return ret;
+
+	schedule_delayed_work(&mcu->poll_work, 0);
+	return 0;
+}
+
+static const struct of_device_id gl_e750_mcu_of_match[] = {
+	{ .compatible = "glinet,gl-e750-mcu" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, gl_e750_mcu_of_match);
+
+static struct serdev_device_driver gl_e750_mcu_driver = {
+	.probe = gl_e750_mcu_probe,
+	.driver = {
+		.name = "gl-e750-mcu",
+		.of_match_table = gl_e750_mcu_of_match,
+	},
+};
+module_serdev_device_driver(gl_e750_mcu_driver);
+
+MODULE_AUTHOR("Serv Pol <servpol@tuta.io>");
+MODULE_DESCRIPTION("GL.iNet GL-E750 status MCU battery driver");
+MODULE_LICENSE("GPL");

-- 
2.47.3

