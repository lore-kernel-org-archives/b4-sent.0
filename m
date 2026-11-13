From: Ziqiang Xia <xiazq123666@gmail.com>
Date: Fri, 13 Nov 2026 10:01:31 -0800
Subject: [PATCH RFC 2/2] platform/x86: Add Emdoor Intel EWMI platform
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-emdoor-intel-wmi-rfc-v1-2-d77ecf23693b@gmail.com>
References: <20261113-emdoor-intel-wmi-rfc-v1-0-d77ecf23693b@gmail.com>
In-Reply-To: <20261113-emdoor-intel-wmi-rfc-v1-0-d77ecf23693b@gmail.com>
To: Armin Wolf <W_Armin@gmx.de>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, Ziqiang Xia <xiazq123666@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794592890; l=27905;
 i=xiazq123666@gmail.com; s=20261113; h=from:subject:message-id;
 bh=HN622j8UCMVXLxBt/mjnq8Z71dVVFGbiImcLPzAcDLE=;
 b=5/WOA+vg7t6Rd30NK5n8XZZ7IFnOFxZ7J3Z92uijTcUPKoItPDmovQDiCPJf+cJpSzhJso7+N
 S/OvKSMbudYCeR4vCCJem0K3yLgT+7+4ebpbNcnUUxuBEWOv976A84S
X-Developer-Key: i=xiazq123666@gmail.com; a=ed25519;
 pk=mrJQOUoyemvqamFAwqXZF59Z8eZnI11ZI+BEtDNxq7Q=
X-Endpoint-Received: by B4 Relay for xiazq123666@gmail.com/20261113 with auth_id=1513
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the Emdoor Intel EWMI (\_SB.EWMI) WMI interface on
MECHREVO Wujie 14 2026 (WUJIE Series-Lark4-LNL, BIOS EM_LNL326_V1.0.19),
exposing hwmon fan and EC temperature sensors, platform_profile
(balanced/performance), Fn/Win lock and touchpad state attributes,
WMI hotkey sparse keymap events, and AC auto-power-on control.

Signed-off-by: Ziqiang Xia <xiazq123666@gmail.com>
---
 MAINTAINERS                             |   1 +
 drivers/platform/x86/Kconfig            |  18 +
 drivers/platform/x86/Makefile           |   1 +
 drivers/platform/x86/emdoor-intel-wmi.c | 873 ++++++++++++++++++++++++++++++++
 4 files changed, 893 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 70c976ffe..1a377dd56 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -9853,6 +9853,7 @@ M:	Ziqiang Xia <xiazq123666@gmail.com>
 L:	platform-driver-x86@vger.kernel.org
 S:	Maintained
 F:	Documentation/ABI/testing/sysfs-bus-wmi-devices-emdoor-ewmi
+F:	drivers/platform/x86/emdoor-intel-wmi.c
 
 EMMC CMDQ HOST CONTROLLER INTERFACE (CQHCI) DRIVER
 M:	Adrian Hunter <adrian.hunter@intel.com>
diff --git a/drivers/platform/x86/Kconfig b/drivers/platform/x86/Kconfig
index b2c6cc923..4682b79e0 100644
--- a/drivers/platform/x86/Kconfig
+++ b/drivers/platform/x86/Kconfig
@@ -120,6 +120,24 @@ config BITLAND_MIFS_WMI
 	  To compile this driver as a module, choose M here: the module will
           be called bitland-mifs-wmi.
 
+config EMDOOR_INTEL_WMI
+	tristate "Emdoor Intel EWMI laptop support"
+	depends on ACPI_EC
+	depends on ACPI_WMI
+	depends on DMI
+	depends on HWMON
+	depends on INPUT
+	select ACPI_PLATFORM_PROFILE
+	select INPUT_SPARSEKMAP
+	help
+	  This is a driver for Emdoor Intel EWMI laptops, initially limited to
+	  the MECHREVO Wujie 14 2026 (WUJIE Series-Lark4-LNL, EM_LNL326_V1.0.19).
+	  It exposes hwmon fan/temperature sensors, platform_profile, hotkeys,
+	  Fn/Win lock controls, and AC auto-power-on control.
+
+	  To compile this driver as a module, choose M here: the module will be
+	  called emdoor-intel-wmi.
+
 config ACERHDF
 	tristate "Acer Aspire One temperature and fan driver"
 	depends on ACPI_EC && THERMAL
diff --git a/drivers/platform/x86/Makefile b/drivers/platform/x86/Makefile
index 88f45e03e..45adabafb 100644
--- a/drivers/platform/x86/Makefile
+++ b/drivers/platform/x86/Makefile
@@ -12,6 +12,7 @@ obj-$(CONFIG_XIAOMI_WMI)		+= xiaomi-wmi.o
 obj-$(CONFIG_REDMI_WMI)			+= redmi-wmi.o
 obj-$(CONFIG_GIGABYTE_WMI)		+= gigabyte-wmi.o
 obj-$(CONFIG_BITLAND_MIFS_WMI)		+= bitland-mifs-wmi.o
+obj-$(CONFIG_EMDOOR_INTEL_WMI)		+= emdoor-intel-wmi.o
 
 # Acer
 obj-$(CONFIG_ACERHDF)		+= acerhdf.o
diff --git a/drivers/platform/x86/emdoor-intel-wmi.c b/drivers/platform/x86/emdoor-intel-wmi.c
new file mode 100644
index 000000000..6edd09f6f
--- /dev/null
+++ b/drivers/platform/x86/emdoor-intel-wmi.c
@@ -0,0 +1,873 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Emdoor Intel EWMI platform driver for MECHREVO Wujie 14 2026
+ * (WUJIE Series-Lark4-LNL, BIOS EM_LNL326_V1.0.19).
+ */
+
+#include <linux/acpi.h>
+#include <linux/atomic.h>
+#include <linux/bits.h>
+#include <linux/cleanup.h>
+#include <linux/container_of.h>
+#include <linux/delay.h>
+#include <linux/device.h>
+#include <linux/dmi.h>
+#include <linux/err.h>
+#include <linux/errno.h>
+#include <linux/hwmon.h>
+#include <linux/input.h>
+#include <linux/input/sparse-keymap.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/notifier.h>
+#include <linux/platform_profile.h>
+#include <linux/slab.h>
+#include <linux/string.h>
+#include <linux/sysfs.h>
+#include <linux/types.h>
+#include <linux/unaligned.h>
+#include <linux/wmi.h>
+#include <linux/workqueue.h>
+
+#define EWMI_METHOD_GUID	"0B30FD67-1B62-4FCA-B10B-50DC7ADE6A39"
+#define EWMI_EVENT_GUID		"0B30FD67-1B62-4FCA-B10B-50DC7ADE6DDD"
+#define EWMI_AUTOPOWER_GUID	"C75665A3-4382-4646-ADC8-C81AE146E455"
+
+#define EWMI_INPUT_SIZE		64
+#define EWMI_OUTPUT_SIZE	256
+
+enum {
+	EWMI_FAN_COUNT = 2,
+	EWMI_TEMP_COUNT = 4,
+	EWMI_MAILBOX_RETRIES = 3,
+};
+
+struct ewmi_board_config {
+	u8 mailbox_reg;
+	u8 autopower_reg;
+	unsigned int query_settle_ms;
+	unsigned int setter_settle_ms;
+	u8 temp_regs[EWMI_TEMP_COUNT];
+};
+
+struct ewmi_reply {
+	u8 reserved[4];
+	u8 status;
+	u8 data[EWMI_OUTPUT_SIZE - 1];
+};
+
+static_assert(sizeof(struct ewmi_reply) == 260);
+
+struct ewmi_method {
+	struct wmi_device *wdev;
+	const struct ewmi_board_config *board;
+	struct mutex lock; /* Serializes firmware calls and EC sensor reads. */
+	struct device *profile;
+	struct notifier_block event_nb;
+	struct work_struct profile_work;
+	atomic_t mailbox_event_seq; /* EC5D hotkeys invalidate in-flight queries. */
+	bool profile_dirty; /* A partial set must not become a successful no-op. */
+	u8 lock_dirty; /* Uncertain lock settings must be explicitly restored. */
+};
+
+struct ewmi_event {
+	struct input_dev *input;
+	struct mutex lock; /* Serializes input press/release sequences. */
+};
+
+struct ewmi_autopower {
+	struct wmi_device *wdev;
+	const struct ewmi_board_config *board;
+	struct mutex lock; /* Serializes auto-power-on queries and settings. */
+	bool dirty; /* A failed setting may have partially applied. */
+};
+
+static BLOCKING_NOTIFIER_HEAD(ewmi_event_chain);
+
+/* Offsets apply only to the verified MECHREVO Lark4 Lunar Lake BIOS. */
+static const struct ewmi_board_config ewmi_lark4_lnl_config = {
+	.mailbox_reg = 0x5d,
+	.autopower_reg = 0xf5,
+	.query_settle_ms = 100,
+	.setter_settle_ms = 100,
+	.temp_regs = { 0x70, 0x73, 0x72, 0x62 },
+};
+
+static const struct dmi_system_id ewmi_dmi_table[] = {
+	{
+		.ident = "MECHREVO Wujie 14 2026 Lark4 Lunar Lake",
+		.matches = {
+			DMI_EXACT_MATCH(DMI_SYS_VENDOR, "MECHREVO"),
+			DMI_EXACT_MATCH(DMI_BOARD_NAME, "WUJIE Series-Lark4-LNL"),
+			DMI_EXACT_MATCH(DMI_BIOS_VERSION, "EM_LNL326_V1.0.19"),
+		},
+		.driver_data = (void *)&ewmi_lark4_lnl_config,
+	},
+	{ }
+};
+
+static const struct ewmi_board_config *ewmi_get_board_config(void)
+{
+	const struct dmi_system_id *id;
+
+	id = dmi_first_match(ewmi_dmi_table);
+	return id ? id->driver_data : NULL;
+}
+
+/*
+ * GWLS (0x03/0x01) and GFLS (0x03/0x03) read the shared EC mailbox register
+ * (EC5D) after settling without sending a second overlapping command.
+ */
+static int ewmi_mailbox_reply(struct ewmi_method *priv, u8 command,
+			      u8 *value)
+{
+	u8 raw;
+	int ret;
+
+	lockdep_assert_held(&priv->lock);
+	ret = ec_read(priv->board->mailbox_reg, &raw);
+	if (ret)
+		return ret;
+
+	switch (command) {
+	case 0x01:
+		if (raw != 0 && raw != 2)
+			goto invalid;
+		*value = raw == 2;
+		return 0;
+	case 0x03:
+		if (raw > 1)
+			goto invalid;
+		*value = raw;
+		return 0;
+	default:
+		return -EOPNOTSUPP;
+	}
+
+invalid:
+	dev_dbg(&priv->wdev->dev,
+		"Settled mailbox 03/%02x transient/invalid raw 0x%02x\n",
+		command, raw);
+	return -EIO;
+}
+
+/*
+ * WMCD returns Package(Buffer(4), Buffer(256)). The WMI core marshals
+ * both buffers into 260 bytes; the firmware status is at byte 4.
+ * Always check the full result size before accessing the payload.
+ */
+static int ewmi_call_status(struct ewmi_method *priv, u8 group, u8 command,
+			    u8 argument, void *result, size_t result_len,
+			    bool *firmware_failure)
+{
+	bool mailbox_query = group == 0x03 && (command == 0x01 || command == 0x03);
+	u8 request[EWMI_INPUT_SIZE] = { group, command, argument };
+	struct wmi_buffer in = { .length = sizeof(request), .data = request };
+	struct wmi_buffer out = { };
+	const struct ewmi_reply *reply;
+	int attempt, ret = -EIO;
+
+	lockdep_assert_held(&priv->lock);
+	if (firmware_failure)
+		*firmware_failure = false;
+	if (result_len > sizeof(reply->data))
+		return -EINVAL;
+	if (mailbox_query && result_len != sizeof(u8))
+		return -EINVAL;
+
+	for (attempt = 0; attempt < EWMI_MAILBOX_RETRIES; attempt++) {
+		int seq = atomic_read(&priv->mailbox_event_seq);
+
+		ret = wmidev_invoke_method(priv->wdev, 0, 1, &in, &out,
+					   sizeof(*reply));
+		if (ret) {
+			dev_warn_ratelimited(&priv->wdev->dev,
+					     "WMCD %02x/%02x transport error %d\n",
+					     group, command, ret);
+			return ret;
+		}
+		if (!mailbox_query)
+			break;
+
+		/*
+		 * GWLS/GFLS share EC5D with each other and with _QF6/_QF9
+		 * hotkey notifications. Wait for the EC to settle and retry
+		 * if an in-flight hotkey overwrites the mailbox.
+		 */
+		kfree(out.data);
+		out = (struct wmi_buffer) { };
+		msleep(priv->board->query_settle_ms);
+		ret = ewmi_mailbox_reply(priv, command, result);
+		if (!ret && atomic_read(&priv->mailbox_event_seq) != seq)
+			ret = -EAGAIN;
+		if (!ret)
+			return 0;
+		if ((ret == -EIO || ret == -EAGAIN) &&
+		    attempt + 1 < EWMI_MAILBOX_RETRIES)
+			continue;
+		if (ret == -EAGAIN)
+			ret = -EIO;
+		dev_warn_ratelimited(&priv->wdev->dev,
+				     "WMCD %02x/%02x settled mailbox error %d\n",
+				     group, command, ret);
+		return ret;
+	}
+
+	reply = out.data;
+	if (reply->status) {
+		if (firmware_failure && reply->status == 1)
+			*firmware_failure = true;
+		dev_warn_ratelimited(&priv->wdev->dev,
+				     "WMCD %02x/%02x firmware status %u, data %8ph\n",
+				     group, command, reply->status, reply->data);
+		ret = -EIO;
+	} else if (result_len) {
+		memcpy(result, reply->data, result_len);
+	}
+	kfree(out.data);
+	return ret;
+}
+
+static int ewmi_call(struct ewmi_method *priv, u8 group, u8 command,
+		     u8 argument, void *result, size_t result_len)
+{
+	return ewmi_call_status(priv, group, command, argument, result,
+				result_len, NULL);
+}
+
+static ssize_t ewmi_switch_show(struct device *dev, u8 command, char *buf)
+{
+	struct ewmi_method *priv = dev_get_drvdata(dev);
+	u8 value;
+	int ret;
+
+	guard(mutex)(&priv->lock);
+	ret = ewmi_call(priv, 0x03, command, 0, &value, sizeof(value));
+	if (ret)
+		return ret;
+	if (value > 1)
+		return -EPROTO;
+	return sysfs_emit(buf, "%u\n", value);
+}
+
+static ssize_t ewmi_switch_store(struct device *dev, u8 command,
+				 const char *buf, size_t count)
+{
+	struct ewmi_method *priv = dev_get_drvdata(dev);
+	bool value;
+	u8 actual, mask;
+	int ret;
+
+	if (command != 0x02 && command != 0x04)
+		return -EINVAL;
+	mask = command == 0x02 ? BIT(0) : BIT(1);
+	ret = kstrtobool(buf, &value);
+	if (ret)
+		return ret;
+
+	guard(mutex)(&priv->lock);
+	ret = ewmi_call(priv, 0x03, command - 1, 0, &actual, sizeof(actual));
+	if (ret) {
+		dev_warn_ratelimited(&priv->wdev->dev,
+				     "Lock 03/%02x before-set query error %d\n",
+				     command, ret);
+		return ret;
+	}
+	if (actual == value && !(priv->lock_dirty & mask))
+		return count;
+	priv->lock_dirty |= mask;
+	ret = ewmi_call(priv, 0x03, command, value, NULL, 0);
+	if (ret)
+		return ret;
+	/* SFLS/SWLS do not wait: a query can overwrite the pending set command. */
+	msleep(priv->board->setter_settle_ms);
+	/* The paired query waits for the EC reply before returning its state. */
+	ret = ewmi_call(priv, 0x03, command - 1, 0, &actual, sizeof(actual));
+	if (ret) {
+		dev_warn_ratelimited(&priv->wdev->dev,
+				     "Lock 03/%02x after-set query error %d\n",
+				     command, ret);
+		return ret;
+	}
+	if (actual != value) {
+		dev_warn_ratelimited(&priv->wdev->dev,
+				     "Lock 03/%02x requested %u, settled readback %u\n",
+				     command, value, actual);
+		return -EIO;
+	}
+	priv->lock_dirty &= ~mask;
+	return count;
+}
+
+static ssize_t fn_lock_show(struct device *dev, struct device_attribute *attr,
+			    char *buf)
+{
+	return ewmi_switch_show(dev, 0x03, buf);
+}
+
+static ssize_t fn_lock_store(struct device *dev, struct device_attribute *attr,
+			     const char *buf, size_t count)
+{
+	return ewmi_switch_store(dev, 0x04, buf, count);
+}
+static DEVICE_ATTR_RW(fn_lock);
+
+static ssize_t win_lock_show(struct device *dev, struct device_attribute *attr,
+			     char *buf)
+{
+	return ewmi_switch_show(dev, 0x01, buf);
+}
+
+static ssize_t win_lock_store(struct device *dev, struct device_attribute *attr,
+			      const char *buf, size_t count)
+{
+	return ewmi_switch_store(dev, 0x02, buf, count);
+}
+static DEVICE_ATTR_RW(win_lock);
+
+static ssize_t touchpad_enabled_show(struct device *dev,
+				     struct device_attribute *attr, char *buf)
+{
+	return ewmi_switch_show(dev, 0x07, buf);
+}
+static DEVICE_ATTR_RO(touchpad_enabled);
+
+static struct attribute *ewmi_attrs[] = {
+	&dev_attr_fn_lock.attr,
+	&dev_attr_win_lock.attr,
+	&dev_attr_touchpad_enabled.attr,
+	NULL
+};
+ATTRIBUTE_GROUPS(ewmi);
+
+static const char * const ewmi_temp_labels[EWMI_TEMP_COUNT] = {
+	"CPU", "GT VR", "Ambient", "Charger"
+};
+
+static const char * const ewmi_fan_labels[EWMI_FAN_COUNT] = {
+	"Fan 1", "Fan 2"
+};
+
+static int ewmi_hwmon_read(struct device *dev, enum hwmon_sensor_types type,
+			   u32 attr, int channel, long *value)
+{
+	struct ewmi_method *priv = dev_get_drvdata(dev);
+	u8 temperature;
+	__le16 rpm;
+	int ret;
+
+	guard(mutex)(&priv->lock);
+	if (type == hwmon_fan && attr == hwmon_fan_input) {
+		if (channel < 0 || channel >= EWMI_FAN_COUNT)
+			return -EOPNOTSUPP;
+		ret = ewmi_call(priv, 0x02, 0x01, channel, &rpm, sizeof(rpm));
+		if (!ret)
+			*value = le16_to_cpu(rpm);
+		return ret;
+	}
+	if (type == hwmon_temp && attr == hwmon_temp_input) {
+		if (channel < 0 || channel >= EWMI_TEMP_COUNT)
+			return -EOPNOTSUPP;
+		ret = ec_read(priv->board->temp_regs[channel], &temperature);
+		if (!ret) {
+			if (temperature == 0xff)
+				return -ENODATA;
+			*value = temperature * 1000L;
+		}
+		return ret;
+	}
+	return -EOPNOTSUPP;
+}
+
+static int ewmi_hwmon_read_string(struct device *dev,
+				  enum hwmon_sensor_types type, u32 attr,
+				  int channel, const char **str)
+{
+	if (type == hwmon_fan && attr == hwmon_fan_label &&
+	    channel >= 0 && channel < EWMI_FAN_COUNT) {
+		*str = ewmi_fan_labels[channel];
+		return 0;
+	}
+	if (type == hwmon_temp && attr == hwmon_temp_label &&
+	    channel >= 0 && channel < EWMI_TEMP_COUNT) {
+		*str = ewmi_temp_labels[channel];
+		return 0;
+	}
+	return -EOPNOTSUPP;
+}
+
+static const struct hwmon_ops ewmi_hwmon_ops = {
+	.visible = 0444,
+	.read = ewmi_hwmon_read,
+	.read_string = ewmi_hwmon_read_string,
+};
+
+static const struct hwmon_channel_info * const ewmi_hwmon_info[] = {
+	HWMON_CHANNEL_INFO(fan,
+			   HWMON_F_INPUT | HWMON_F_LABEL,
+			   HWMON_F_INPUT | HWMON_F_LABEL),
+	HWMON_CHANNEL_INFO(temp,
+			   HWMON_T_INPUT | HWMON_T_LABEL,
+			   HWMON_T_INPUT | HWMON_T_LABEL,
+			   HWMON_T_INPUT | HWMON_T_LABEL,
+			   HWMON_T_INPUT | HWMON_T_LABEL),
+	NULL
+};
+
+static const struct hwmon_chip_info ewmi_hwmon_chip = {
+	.ops = &ewmi_hwmon_ops,
+	.info = ewmi_hwmon_info,
+};
+
+static int ewmi_profile_probe(void *drvdata, unsigned long *choices)
+{
+	set_bit(PLATFORM_PROFILE_BALANCED, choices);
+	set_bit(PLATFORM_PROFILE_PERFORMANCE, choices);
+	return 0;
+}
+
+static int ewmi_profile_get(struct device *dev,
+			    enum platform_profile_option *profile)
+{
+	struct ewmi_method *priv = dev_get_drvdata(dev);
+	u8 mode;
+	int ret;
+
+	guard(mutex)(&priv->lock);
+	ret = ewmi_call(priv, 0x03, 0x09, 0, &mode, sizeof(mode));
+	if (ret)
+		return ret;
+	switch (mode) {
+	case 1:
+		*profile = PLATFORM_PROFILE_BALANCED;
+		return 0;
+	case 2:
+		*profile = PLATFORM_PROFILE_PERFORMANCE;
+		return 0;
+	default:
+		return -EPROTO;
+	}
+}
+
+static int ewmi_profile_set(struct device *dev,
+			    enum platform_profile_option profile)
+{
+	struct ewmi_method *priv = dev_get_drvdata(dev);
+	bool firmware_failure;
+	u8 mode, actual;
+	int attempt, ret;
+
+	switch (profile) {
+	case PLATFORM_PROFILE_BALANCED:
+		mode = 1;
+		break;
+	case PLATFORM_PROFILE_PERFORMANCE:
+		mode = 2;
+		break;
+	default:
+		return -EOPNOTSUPP;
+	}
+
+	guard(mutex)(&priv->lock);
+	/* Avoid a redundant EC command when userspace reapplies this profile. */
+	ret = ewmi_call(priv, 0x03, 0x09, 0, &actual, sizeof(actual));
+	if (ret)
+		return ret;
+	if (actual == mode && !priv->profile_dirty)
+		return 0;
+
+	/*
+	 * SPFM arms the EC (ZZTT/TIZZ) before Notify(IETM, 0x88) and before
+	 * writing EC5F, so an EC scan during the notify can consume a stale
+	 * EC5F and return RTNC=0 without updating PPMD; SPFM can also report
+	 * RTNC=1 after changing mode. Reissue this absolute mode command up
+	 * to three times when RTNC=1 or 03/09 still reads back the old mode.
+	 */
+	priv->profile_dirty = true;
+	for (attempt = 0; attempt < EWMI_MAILBOX_RETRIES; attempt++) {
+		ret = ewmi_call_status(priv, 0x03, 0x0a, mode, NULL, 0,
+				       &firmware_failure);
+		if (ret) {
+			if (!firmware_failure ||
+			    attempt + 1 == EWMI_MAILBOX_RETRIES)
+				return ret;
+			msleep(priv->board->setter_settle_ms);
+			continue;
+		}
+		ret = ewmi_call(priv, 0x03, 0x09, 0, &actual, sizeof(actual));
+		if (ret)
+			return ret;
+		if (actual == mode) {
+			priv->profile_dirty = false;
+			return 0;
+		}
+		msleep(priv->board->setter_settle_ms);
+		ret = ewmi_call(priv, 0x03, 0x09, 0, &actual, sizeof(actual));
+		if (ret)
+			return ret;
+		if (actual == mode) {
+			priv->profile_dirty = false;
+			return 0;
+		}
+		if (attempt + 1 < EWMI_MAILBOX_RETRIES)
+			dev_dbg(dev,
+				"Profile 03/0a requested %u, readback %u on attempt %d/%d; retrying\n",
+				mode, actual, attempt + 1,
+				EWMI_MAILBOX_RETRIES);
+	}
+	dev_warn_ratelimited(dev,
+			     "Profile 03/0a requested %u, settled readback %u\n",
+			     mode, actual);
+	return -EIO;
+}
+
+static const struct platform_profile_ops ewmi_profile_ops = {
+	.probe = ewmi_profile_probe,
+	.profile_get = ewmi_profile_get,
+	.profile_set = ewmi_profile_set,
+};
+
+static void ewmi_profile_work(struct work_struct *work)
+{
+	struct ewmi_method *priv = container_of(work, struct ewmi_method,
+						profile_work);
+
+	platform_profile_notify(priv->profile);
+}
+
+static int ewmi_method_event(struct notifier_block *nb, unsigned long code,
+			     void *data)
+{
+	struct ewmi_method *priv = container_of(nb, struct ewmi_method,
+						event_nb);
+	struct wmi_device *event_wdev = data;
+
+	if (event_wdev->dev.parent != priv->wdev->dev.parent)
+		return NOTIFY_DONE;
+	/* _QF6 (0x50/0x51) and _QF9 (0x20-0x22) share EC5D with WMCD queries. */
+	if (code == 0x20 || code == 0x21 || code == 0x22 ||
+	    code == 0x50 || code == 0x51)
+		atomic_inc(&priv->mailbox_event_seq);
+	if (code == 0 || code == 0x41 || code == 0x42)
+		schedule_work(&priv->profile_work);
+	return NOTIFY_OK;
+}
+
+static void ewmi_method_stop(void *data)
+{
+	struct ewmi_method *priv = data;
+
+	blocking_notifier_chain_unregister(&ewmi_event_chain, &priv->event_nb);
+	cancel_work_sync(&priv->profile_work);
+}
+
+static int ewmi_method_probe(struct wmi_device *wdev, const void *context)
+{
+	static const u8 expected_version[] = { 1, 0, 1, 0 };
+	const struct ewmi_board_config *board;
+	struct ewmi_method *priv;
+	struct device *hwmon;
+	u8 version[4];
+	int ret;
+
+	board = ewmi_get_board_config();
+	if (!board)
+		return -ENODEV;
+	priv = devm_kzalloc(&wdev->dev, sizeof(*priv), GFP_KERNEL);
+	if (!priv)
+		return -ENOMEM;
+	priv->wdev = wdev;
+	priv->board = board;
+	mutex_init(&priv->lock);
+	INIT_WORK(&priv->profile_work, ewmi_profile_work);
+	dev_set_drvdata(&wdev->dev, priv);
+
+	scoped_guard(mutex, &priv->lock)
+		ret = ewmi_call(priv, 0x01, 0x01, 0, version, sizeof(version));
+	if (ret)
+		return dev_err_probe(&wdev->dev, ret,
+				     "Cannot query protocol version\n");
+	if (memcmp(version, expected_version, sizeof(version)))
+		return dev_err_probe(&wdev->dev, -ENODEV,
+				     "Unsupported protocol version\n");
+
+	priv->profile = devm_platform_profile_register(&wdev->dev,
+						       "emdoor-intel-wmi",
+						       priv, &ewmi_profile_ops);
+	if (IS_ERR(priv->profile))
+		return dev_err_probe(&wdev->dev, PTR_ERR(priv->profile),
+				     "Cannot register platform profile\n");
+
+	priv->event_nb.notifier_call = ewmi_method_event;
+	ret = blocking_notifier_chain_register(&ewmi_event_chain,
+					       &priv->event_nb);
+	if (ret)
+		return ret;
+	ret = devm_add_action_or_reset(&wdev->dev, ewmi_method_stop, priv);
+	if (ret)
+		return ret;
+
+	hwmon = devm_hwmon_device_register_with_info(&wdev->dev, "emdoor_ewmi",
+						     priv, &ewmi_hwmon_chip,
+						     NULL);
+	if (IS_ERR(hwmon))
+		return dev_err_probe(&wdev->dev, PTR_ERR(hwmon),
+				     "Cannot register hwmon\n");
+
+	return 0;
+}
+
+/* Firmware already changes these states; never request a second toggle. */
+static const struct key_entry ewmi_keymap[] = {
+	{ KE_KEY, 0x30, { KEY_TOUCHPAD_OFF } },
+	{ KE_KEY, 0x31, { KEY_TOUCHPAD_ON } },
+	{ KE_KEY, 0xa0, { KEY_PROG1 } },
+	{ KE_KEY, 0xa1, { KEY_PROG2 } },
+	{ KE_KEY, 0xa2, { KEY_PROG3 } },
+	{ KE_IGNORE, 0x00, { 0 } },
+	{ KE_IGNORE, 0x41, { 0 } },
+	{ KE_IGNORE, 0x42, { 0 } },
+	{ KE_IGNORE, 0x20, { 0 } },
+	{ KE_IGNORE, 0x21, { 0 } },
+	{ KE_IGNORE, 0x22, { 0 } },
+	{ KE_IGNORE, 0x50, { 0 } },
+	{ KE_IGNORE, 0x51, { 0 } },
+	{ KE_END, 0 }
+};
+
+static int ewmi_event_probe(struct wmi_device *wdev, const void *context)
+{
+	struct ewmi_event *priv;
+	int ret;
+
+	if (!ewmi_get_board_config())
+		return -ENODEV;
+	priv = devm_kzalloc(&wdev->dev, sizeof(*priv), GFP_KERNEL);
+	if (!priv)
+		return -ENOMEM;
+	mutex_init(&priv->lock);
+	priv->input = devm_input_allocate_device(&wdev->dev);
+	if (!priv->input)
+		return -ENOMEM;
+	priv->input->name = "Emdoor EWMI hotkeys";
+	priv->input->phys = "wmi/input0";
+	priv->input->id.bustype = BUS_HOST;
+	ret = sparse_keymap_setup(priv->input, ewmi_keymap, NULL);
+	if (ret)
+		return ret;
+	dev_set_drvdata(&wdev->dev, priv);
+	return input_register_device(priv->input);
+}
+
+static void ewmi_event_notify(struct wmi_device *wdev,
+			      const struct wmi_buffer *event)
+{
+	struct ewmi_event *priv = dev_get_drvdata(&wdev->dev);
+	u32 code = get_unaligned_le32(event->data);
+
+	blocking_notifier_call_chain(&ewmi_event_chain, code, wdev);
+	guard(mutex)(&priv->lock);
+	if (!sparse_keymap_report_event(priv->input, code, 1, true))
+		dev_dbg(&wdev->dev, "Unknown event 0x%x\n", code);
+}
+
+static const struct wmi_device_id ewmi_method_ids[] = {
+	{ EWMI_METHOD_GUID, NULL },
+	{ }
+};
+MODULE_DEVICE_TABLE(wmi, ewmi_method_ids);
+
+static const struct wmi_device_id ewmi_event_ids[] = {
+	{ EWMI_EVENT_GUID, NULL },
+	{ }
+};
+MODULE_DEVICE_TABLE(wmi, ewmi_event_ids);
+
+static struct wmi_driver ewmi_method_driver = {
+	.driver = {
+		.name = "emdoor-ewmi",
+		.probe_type = PROBE_PREFER_ASYNCHRONOUS,
+		.dev_groups = ewmi_groups,
+	},
+	.id_table = ewmi_method_ids,
+	.no_singleton = true,
+	.probe = ewmi_method_probe,
+};
+
+static struct wmi_driver ewmi_event_driver = {
+	.driver = {
+		.name = "emdoor-ewmi-events",
+		.probe_type = PROBE_PREFER_ASYNCHRONOUS,
+	},
+	.id_table = ewmi_event_ids,
+	.no_singleton = true,
+	.min_event_size = sizeof(__le32),
+	.probe = ewmi_event_probe,
+	.notify_new = ewmi_event_notify,
+};
+
+static int ewmi_autopower_get(struct ewmi_autopower *priv, bool *enabled)
+{
+	u8 raw;
+	int ret;
+
+	lockdep_assert_held(&priv->lock);
+	ret = ec_read(priv->board->autopower_reg, &raw);
+	if (ret)
+		return ret;
+	if (raw != 0 && raw != 0xa0)
+		return -EPROTO;
+	*enabled = raw == 0xa0;
+	return 0;
+}
+
+static int ewmi_autopower_set(struct ewmi_autopower *priv, bool enabled)
+{
+	__le64 argument = cpu_to_le64(enabled);
+	struct wmi_buffer in = { .length = sizeof(argument), .data = &argument };
+	struct wmi_buffer out = { };
+	bool actual;
+	u8 status;
+	int ret;
+
+	lockdep_assert_held(&priv->lock);
+	ret = ewmi_autopower_get(priv, &actual);
+	if (ret || (actual == enabled && !priv->dirty))
+		return ret;
+	priv->dirty = true;
+	ret = wmidev_invoke_method(priv->wdev, 0, 1, &in, &out, 8);
+	if (ret) {
+		dev_warn_ratelimited(&priv->wdev->dev,
+				     "WMCC transport error %d\n", ret);
+		return ret;
+	}
+	status = ((u8 *)out.data)[0];
+	ret = status ? -EIO : 0;
+	kfree(out.data);
+	msleep(priv->board->setter_settle_ms);
+	if (ret) {
+		dev_warn_ratelimited(&priv->wdev->dev,
+				     "WMCC firmware status %u\n", status);
+		return ret;
+	}
+	ret = ewmi_autopower_get(priv, &actual);
+	if (ret) {
+		dev_warn_ratelimited(&priv->wdev->dev,
+				     "WMCC readback error %d\n", ret);
+		return ret;
+	}
+	if (actual != enabled) {
+		dev_warn_ratelimited(&priv->wdev->dev,
+				     "WMCC requested %u, readback %u\n",
+				     enabled, actual);
+		return -EIO;
+	}
+	priv->dirty = false;
+	return 0;
+}
+
+static ssize_t auto_power_on_show(struct device *dev,
+				  struct device_attribute *attr, char *buf)
+{
+	struct ewmi_autopower *priv = dev_get_drvdata(dev);
+	bool enabled;
+	int ret;
+
+	guard(mutex)(&priv->lock);
+	ret = ewmi_autopower_get(priv, &enabled);
+	if (ret)
+		return ret;
+	return sysfs_emit(buf, "%u\n", enabled);
+}
+
+static ssize_t auto_power_on_store(struct device *dev,
+				   struct device_attribute *attr,
+				   const char *buf, size_t count)
+{
+	struct ewmi_autopower *priv = dev_get_drvdata(dev);
+	bool enabled;
+	int ret;
+
+	ret = kstrtobool(buf, &enabled);
+	if (ret)
+		return ret;
+	guard(mutex)(&priv->lock);
+	ret = ewmi_autopower_set(priv, enabled);
+	return ret ? ret : count;
+}
+static DEVICE_ATTR_RW(auto_power_on);
+
+static struct attribute *ewmi_autopower_attrs[] = {
+	&dev_attr_auto_power_on.attr,
+	NULL
+};
+ATTRIBUTE_GROUPS(ewmi_autopower);
+
+static int ewmi_autopower_probe(struct wmi_device *wdev, const void *context)
+{
+	const struct ewmi_board_config *board;
+	struct ewmi_autopower *priv;
+
+	board = ewmi_get_board_config();
+	if (!board)
+		return -ENODEV;
+	priv = devm_kzalloc(&wdev->dev, sizeof(*priv), GFP_KERNEL);
+	if (!priv)
+		return -ENOMEM;
+	priv->wdev = wdev;
+	priv->board = board;
+	mutex_init(&priv->lock);
+	dev_set_drvdata(&wdev->dev, priv);
+	return 0;
+}
+
+static const struct wmi_device_id ewmi_autopower_ids[] = {
+	{ EWMI_AUTOPOWER_GUID, NULL },
+	{ }
+};
+MODULE_DEVICE_TABLE(wmi, ewmi_autopower_ids);
+
+static struct wmi_driver ewmi_autopower_driver = {
+	.driver = {
+		.name = "emdoor-ewmi-autopower",
+		.probe_type = PROBE_PREFER_ASYNCHRONOUS,
+		.dev_groups = ewmi_autopower_groups,
+	},
+	.id_table = ewmi_autopower_ids,
+	.no_singleton = true,
+	.probe = ewmi_autopower_probe,
+};
+
+static int __init ewmi_init(void)
+{
+	int ret;
+
+	ret = wmi_driver_register(&ewmi_method_driver);
+	if (ret)
+		return ret;
+	ret = wmi_driver_register(&ewmi_event_driver);
+	if (ret) {
+		wmi_driver_unregister(&ewmi_method_driver);
+		return ret;
+	}
+	ret = wmi_driver_register(&ewmi_autopower_driver);
+	if (ret) {
+		wmi_driver_unregister(&ewmi_event_driver);
+		wmi_driver_unregister(&ewmi_method_driver);
+	}
+	return ret;
+}
+
+static void __exit ewmi_exit(void)
+{
+	wmi_driver_unregister(&ewmi_autopower_driver);
+	wmi_driver_unregister(&ewmi_event_driver);
+	wmi_driver_unregister(&ewmi_method_driver);
+}
+
+module_init(ewmi_init);
+module_exit(ewmi_exit);
+
+MODULE_AUTHOR("Ziqiang Xia <xiazq123666@gmail.com>");
+MODULE_DESCRIPTION("Emdoor Intel EWMI platform driver");
+MODULE_LICENSE("GPL");

-- 
2.56.1

