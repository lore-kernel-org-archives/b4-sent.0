From: Ziqiang Xia <xiazq123666@gmail.com>
Date: Thu, 26 Nov 2026 00:21:19 -0800
Subject: [PATCH v3 2/2] platform/x86: Add Emdoor Intel EWMI platform driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-emdoor-intel-wmi-rfc-v3-2-7dfbb70f04a9@gmail.com>
References: <20261126-emdoor-intel-wmi-rfc-v3-0-7dfbb70f04a9@gmail.com>
In-Reply-To: <20261126-emdoor-intel-wmi-rfc-v3-0-7dfbb70f04a9@gmail.com>
To: Armin Wolf <W_Armin@gmx.de>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, Ziqiang Xia <xiazq123666@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795681277; l=18949;
 i=xiazq123666@gmail.com; s=20261113; h=from:subject:message-id;
 bh=vIUQThLzaCd71WvqSSXW9KPesu5TQK2ySlq9u/2ML8k=;
 b=r9mJrL2EJGrHQU1s6QLda/8ZEEhiw0qfMNlUuvS08cZCuXNggUz8MbiILwuS9WvYeLP9mzpf3
 Po4rVDTJZ+VARvvIOVNwC9xKiF2javxA8PBmanWYx/yTYMPosRumO45
X-Developer-Key: i=xiazq123666@gmail.com; a=ed25519;
 pk=mrJQOUoyemvqamFAwqXZF59Z8eZnI11ZI+BEtDNxq7Q=
X-Endpoint-Received: by B4 Relay for xiazq123666@gmail.com/20261113 with auth_id=1513
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a pure-WMI platform driver for the Emdoor Intel EWMI (\_SB.EWMI)
interface (protocol version 1.0.1.0, verified on MECHREVO Wujie 14
2026 / WUJIE Series-Lark4-LNL, BIOS EM_LNL326_V1.0.19), exposing
hwmon dual fan tachometers, platform_profile (balanced/performance),
touchpad_enabled state, and WMI hotkey sparse keymap events without
direct EC register access.

Signed-off-by: Ziqiang Xia <xiazq123666@gmail.com>
---
 MAINTAINERS                             |   1 +
 drivers/platform/x86/Kconfig            |  16 +
 drivers/platform/x86/Makefile           |   1 +
 drivers/platform/x86/emdoor-intel-wmi.c | 565 ++++++++++++++++++++++++++++++++
 4 files changed, 583 insertions(+)

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
index b2c6cc923..27ae34206 100644
--- a/drivers/platform/x86/Kconfig
+++ b/drivers/platform/x86/Kconfig
@@ -120,6 +120,22 @@ config BITLAND_MIFS_WMI
 	  To compile this driver as a module, choose M here: the module will
           be called bitland-mifs-wmi.
 
+config EMDOOR_INTEL_WMI
+	tristate "Emdoor Intel EWMI laptop support"
+	depends on ACPI_WMI
+	depends on HWMON
+	depends on INPUT
+	select ACPI_PLATFORM_PROFILE
+	select INPUT_SPARSEKMAP
+	help
+	  This is a pure-WMI driver for Emdoor Intel EWMI laptops implementing
+	  protocol version 1.0.1.0 (such as the MECHREVO Wujie 14 2026). It
+	  exposes hwmon fan tachometers, platform_profile, touchpad state, and
+	  WMI hotkey events.
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
index 000000000..f530462e2
--- /dev/null
+++ b/drivers/platform/x86/emdoor-intel-wmi.c
@@ -0,0 +1,565 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Emdoor Intel EWMI platform driver.
+ *
+ * Verified on MECHREVO Wujie 14 2026 (WUJIE Series-Lark4-LNL,
+ * BIOS EM_LNL326_V1.0.19).
+ */
+
+#include <linux/array_size.h>
+#include <linux/bitops.h>
+#include <linux/cleanup.h>
+#include <linux/container_of.h>
+#include <linux/delay.h>
+#include <linux/dev_printk.h>
+#include <linux/device.h>
+#include <linux/devm-helpers.h>
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
+#include <linux/stddef.h>
+#include <linux/string.h>
+#include <linux/sysfs.h>
+#include <linux/types.h>
+#include <linux/unaligned.h>
+#include <linux/wmi.h>
+#include <linux/workqueue.h>
+
+#define EWMI_METHOD_GUID	"0B30FD67-1B62-4FCA-B10B-50DC7ADE6A39"
+#define EWMI_EVENT_GUID		"0B30FD67-1B62-4FCA-B10B-50DC7ADE6DDD"
+
+#define EWMI_INPUT_SIZE		64
+#define EWMI_OUTPUT_SIZE	256
+
+#define EWMI_GRP_SYSTEM			0x01
+#define EWMI_CMD_GET_VERSION		0x01
+
+#define EWMI_GRP_SENSOR			0x02
+#define EWMI_CMD_GET_FAN_RPM		0x01
+
+#define EWMI_GRP_CONTROL		0x03
+#define EWMI_CMD_GET_TOUCHPAD		0x07
+#define EWMI_CMD_GET_PROFILE		0x09
+#define EWMI_CMD_SET_PROFILE		0x0a
+
+#define EWMI_PROFILE_BALANCED		1
+#define EWMI_PROFILE_PERFORMANCE	2
+
+#define EWMI_EVENT_PROFILE_NOTIFY	0x00
+#define EWMI_EVENT_KBD_BL_OFF		0x20
+#define EWMI_EVENT_KBD_BL_HALF		0x21
+#define EWMI_EVENT_KBD_BL_ON		0x22
+#define EWMI_EVENT_TOUCHPAD_OFF		0x30
+#define EWMI_EVENT_TOUCHPAD_ON		0x31
+#define EWMI_EVENT_PROFILE_BALANCED	0x41
+#define EWMI_EVENT_PROFILE_PERFORMANCE	0x42
+#define EWMI_EVENT_FN_UNLOCK		0x50
+#define EWMI_EVENT_FN_LOCK		0x51
+#define EWMI_EVENT_PROG1		0xa0
+#define EWMI_EVENT_PROG2		0xa1
+#define EWMI_EVENT_PROG3		0xa2
+
+enum {
+	EWMI_PROFILE_RETRIES = 3,
+	EWMI_PROFILE_SETTLE_MS = 100,
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
+	struct mutex lock; /* Serializes WMCD firmware calls. */
+	struct device *profile;
+	struct notifier_block event_nb;
+	struct work_struct profile_work;
+	bool profile_dirty; /* A partial set must not become a successful no-op. */
+};
+
+struct ewmi_event {
+	struct input_dev *input;
+	struct mutex lock; /* Serializes input press/release sequences. */
+};
+
+static BLOCKING_NOTIFIER_HEAD(ewmi_event_chain);
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
+	u8 request[EWMI_INPUT_SIZE] = { group, command, argument };
+	struct wmi_buffer in = { .length = sizeof(request), .data = request };
+	struct wmi_buffer out = { };
+	int ret;
+
+	lockdep_assert_held(&priv->lock);
+	if (firmware_failure)
+		*firmware_failure = false;
+	if (result_len > sizeof_field(struct ewmi_reply, data))
+		return -EINVAL;
+
+	ret = wmidev_invoke_method(priv->wdev, 0, 1, &in, &out,
+				   sizeof(struct ewmi_reply));
+	if (ret) {
+		dev_warn_ratelimited(&priv->wdev->dev,
+				     "WMCD %02x/%02x transport error %d\n",
+				     group, command, ret);
+		return ret;
+	}
+
+	const struct ewmi_reply *reply __free(kfree) = out.data;
+
+	if (reply->status) {
+		if (firmware_failure && reply->status == 1)
+			*firmware_failure = true;
+		dev_warn_ratelimited(&priv->wdev->dev,
+				     "WMCD %02x/%02x firmware status %u, data %8ph\n",
+				     group, command, reply->status, reply->data);
+		return -EIO;
+	}
+	if (result_len)
+		memcpy(result, reply->data, result_len);
+
+	return 0;
+}
+
+static int ewmi_call(struct ewmi_method *priv, u8 group, u8 command,
+		     u8 argument, void *result, size_t result_len)
+{
+	return ewmi_call_status(priv, group, command, argument, result,
+				result_len, NULL);
+}
+
+static ssize_t touchpad_enabled_show(struct device *dev,
+				     struct device_attribute *attr, char *buf)
+{
+	struct ewmi_method *priv = dev_get_drvdata(dev);
+	u8 value;
+	int ret;
+
+	guard(mutex)(&priv->lock);
+	ret = ewmi_call(priv, EWMI_GRP_CONTROL, EWMI_CMD_GET_TOUCHPAD, 0,
+			&value, sizeof(value));
+	if (ret)
+		return ret;
+	if (value > 1)
+		return -EPROTO;
+
+	return sysfs_emit(buf, "%u\n", value);
+}
+static DEVICE_ATTR_RO(touchpad_enabled);
+
+static struct attribute *ewmi_attrs[] = {
+	&dev_attr_touchpad_enabled.attr,
+	NULL
+};
+ATTRIBUTE_GROUPS(ewmi);
+
+static const char * const ewmi_fan_labels[] = {
+	"Fan 1", "Fan 2"
+};
+
+static int ewmi_hwmon_read(struct device *dev, enum hwmon_sensor_types type,
+			   u32 attr, int channel, long *value)
+{
+	struct ewmi_method *priv = dev_get_drvdata(dev);
+	__le16 rpm;
+	int ret;
+
+	if (type != hwmon_fan || attr != hwmon_fan_input)
+		return -EOPNOTSUPP;
+	if (channel < 0 || channel >= ARRAY_SIZE(ewmi_fan_labels))
+		return -EOPNOTSUPP;
+
+	guard(mutex)(&priv->lock);
+	ret = ewmi_call(priv, EWMI_GRP_SENSOR, EWMI_CMD_GET_FAN_RPM, channel,
+			&rpm, sizeof(rpm));
+	if (!ret)
+		*value = le16_to_cpu(rpm);
+
+	return ret;
+}
+
+static int ewmi_hwmon_read_string(struct device *dev,
+				  enum hwmon_sensor_types type, u32 attr,
+				  int channel, const char **str)
+{
+	if (type != hwmon_fan || attr != hwmon_fan_label)
+		return -EOPNOTSUPP;
+	if (channel < 0 || channel >= ARRAY_SIZE(ewmi_fan_labels))
+		return -EOPNOTSUPP;
+
+	*str = ewmi_fan_labels[channel];
+	return 0;
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
+	ret = ewmi_call(priv, EWMI_GRP_CONTROL, EWMI_CMD_GET_PROFILE, 0,
+			&mode, sizeof(mode));
+	if (ret)
+		return ret;
+
+	switch (mode) {
+	case EWMI_PROFILE_BALANCED:
+		*profile = PLATFORM_PROFILE_BALANCED;
+		return 0;
+	case EWMI_PROFILE_PERFORMANCE:
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
+		mode = EWMI_PROFILE_BALANCED;
+		break;
+	case PLATFORM_PROFILE_PERFORMANCE:
+		mode = EWMI_PROFILE_PERFORMANCE;
+		break;
+	default:
+		return -EOPNOTSUPP;
+	}
+
+	guard(mutex)(&priv->lock);
+	ret = ewmi_call(priv, EWMI_GRP_CONTROL, EWMI_CMD_GET_PROFILE, 0,
+			&actual, sizeof(actual));
+	if (ret)
+		return ret;
+
+	/* Avoid a redundant firmware command when userspace reapplies this profile. */
+	if (actual == mode && !priv->profile_dirty)
+		return 0;
+
+	/*
+	 * SPFM arms the EC (ZZTT/TIZZ) before Notify(IETM, 0x88) and before
+	 * writing EC5F, so an EC scan during the notify can consume a stale
+	 * EC5F and return RTNC=0 without updating PPMD; SPFM can also report
+	 * RTNC=1 after changing mode. Reissue this absolute mode command up
+	 * to three times when RTNC=1 or GPFM still reads back the old mode.
+	 */
+	priv->profile_dirty = true;
+	for (attempt = 1; attempt <= EWMI_PROFILE_RETRIES; attempt++) {
+		ret = ewmi_call_status(priv, EWMI_GRP_CONTROL,
+				       EWMI_CMD_SET_PROFILE, mode, NULL, 0,
+				       &firmware_failure);
+		if (ret) {
+			if (!firmware_failure || attempt == EWMI_PROFILE_RETRIES)
+				return ret;
+
+			msleep(EWMI_PROFILE_SETTLE_MS);
+			continue;
+		}
+
+		ret = ewmi_call(priv, EWMI_GRP_CONTROL, EWMI_CMD_GET_PROFILE, 0,
+				&actual, sizeof(actual));
+		if (ret)
+			return ret;
+		if (actual == mode) {
+			priv->profile_dirty = false;
+			return 0;
+		}
+
+		msleep(EWMI_PROFILE_SETTLE_MS);
+
+		ret = ewmi_call(priv, EWMI_GRP_CONTROL, EWMI_CMD_GET_PROFILE, 0,
+				&actual, sizeof(actual));
+		if (ret)
+			return ret;
+		if (actual == mode) {
+			priv->profile_dirty = false;
+			return 0;
+		}
+
+		if (attempt < EWMI_PROFILE_RETRIES) {
+			dev_dbg(dev,
+				"Profile set requested %u, readback %u on attempt %d/%d; retrying\n",
+				mode, actual, attempt, EWMI_PROFILE_RETRIES);
+		}
+	}
+
+	dev_warn_ratelimited(dev,
+			     "Profile set requested %u, settled readback %u\n",
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
+	if (code == EWMI_EVENT_PROFILE_NOTIFY ||
+	    code == EWMI_EVENT_PROFILE_BALANCED ||
+	    code == EWMI_EVENT_PROFILE_PERFORMANCE)
+		schedule_work(&priv->profile_work);
+
+	return NOTIFY_OK;
+}
+
+static void ewmi_method_stop(void *data)
+{
+	struct ewmi_method *priv = data;
+
+	blocking_notifier_chain_unregister(&ewmi_event_chain, &priv->event_nb);
+}
+
+static int ewmi_method_probe(struct wmi_device *wdev, const void *context)
+{
+	static const u8 expected_version[] = { 1, 0, 1, 0 };
+	struct ewmi_method *priv;
+	struct device *hwmon;
+	u8 version[4];
+	int ret;
+
+	priv = devm_kzalloc(&wdev->dev, sizeof(*priv), GFP_KERNEL);
+	if (!priv)
+		return -ENOMEM;
+	priv->wdev = wdev;
+
+	ret = devm_mutex_init(&wdev->dev, &priv->lock);
+	if (ret)
+		return ret;
+
+	ret = devm_work_autocancel(&wdev->dev, &priv->profile_work,
+				   ewmi_profile_work);
+	if (ret)
+		return ret;
+
+	dev_set_drvdata(&wdev->dev, priv);
+
+	scoped_guard(mutex, &priv->lock) {
+		ret = ewmi_call(priv, EWMI_GRP_SYSTEM, EWMI_CMD_GET_VERSION, 0,
+				version, sizeof(version));
+		if (ret) {
+			return dev_err_probe(&wdev->dev, ret,
+					     "Cannot query protocol version\n");
+		}
+	}
+	if (memcmp(version, expected_version, sizeof(version))) {
+		return dev_err_probe(&wdev->dev, -ENODEV,
+				     "Unsupported protocol version\n");
+	}
+
+	priv->profile = devm_platform_profile_register(&wdev->dev,
+						       "emdoor-intel-wmi",
+						       priv, &ewmi_profile_ops);
+	if (IS_ERR(priv->profile)) {
+		return dev_err_probe(&wdev->dev, PTR_ERR(priv->profile),
+				     "Cannot register platform profile\n");
+	}
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
+	if (IS_ERR(hwmon)) {
+		return dev_err_probe(&wdev->dev, PTR_ERR(hwmon),
+				     "Cannot register hwmon\n");
+	}
+
+	return 0;
+}
+
+/* Firmware already changes these states; never request a second toggle. */
+static const struct key_entry ewmi_keymap[] = {
+	{ KE_KEY, EWMI_EVENT_TOUCHPAD_OFF, { KEY_TOUCHPAD_OFF } },
+	{ KE_KEY, EWMI_EVENT_TOUCHPAD_ON, { KEY_TOUCHPAD_ON } },
+	{ KE_KEY, EWMI_EVENT_PROG1, { KEY_PROG1 } },
+	{ KE_KEY, EWMI_EVENT_PROG2, { KEY_PROG2 } },
+	{ KE_KEY, EWMI_EVENT_PROG3, { KEY_PROG3 } },
+	{ KE_IGNORE, EWMI_EVENT_PROFILE_NOTIFY, { KEY_RESERVED } },
+	{ KE_IGNORE, EWMI_EVENT_PROFILE_BALANCED, { KEY_RESERVED } },
+	{ KE_IGNORE, EWMI_EVENT_PROFILE_PERFORMANCE, { KEY_RESERVED } },
+	{ KE_IGNORE, EWMI_EVENT_KBD_BL_OFF, { KEY_KBDILLUMTOGGLE } },
+	{ KE_IGNORE, EWMI_EVENT_KBD_BL_HALF, { KEY_KBDILLUMTOGGLE } },
+	{ KE_IGNORE, EWMI_EVENT_KBD_BL_ON, { KEY_KBDILLUMTOGGLE } },
+	{ KE_IGNORE, EWMI_EVENT_FN_UNLOCK, { KEY_FN_ESC } },
+	{ KE_IGNORE, EWMI_EVENT_FN_LOCK, { KEY_FN_ESC } },
+	{ KE_END, 0 }
+};
+
+static int ewmi_event_probe(struct wmi_device *wdev, const void *context)
+{
+	struct ewmi_event *priv;
+	int ret;
+
+	priv = devm_kzalloc(&wdev->dev, sizeof(*priv), GFP_KERNEL);
+	if (!priv)
+		return -ENOMEM;
+
+	ret = devm_mutex_init(&wdev->dev, &priv->lock);
+	if (ret)
+		return ret;
+
+	priv->input = devm_input_allocate_device(&wdev->dev);
+	if (!priv->input)
+		return -ENOMEM;
+
+	priv->input->name = "Emdoor EWMI hotkeys";
+	priv->input->phys = "wmi/input0";
+	priv->input->id.bustype = BUS_HOST;
+	ret = sparse_keymap_setup(priv->input, ewmi_keymap, NULL);
+	if (ret)
+		return ret;
+
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
+static int __init ewmi_init(void)
+{
+	int ret;
+
+	ret = wmi_driver_register(&ewmi_method_driver);
+	if (ret)
+		return ret;
+	ret = wmi_driver_register(&ewmi_event_driver);
+	if (ret)
+		wmi_driver_unregister(&ewmi_method_driver);
+	return ret;
+}
+
+static void __exit ewmi_exit(void)
+{
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

