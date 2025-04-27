From: Kurt Borja <kuurtb@gmail.com>
Date: Sun, 27 Apr 2025 03:24:48 -0300
Subject: [PATCH v2 1/2] platform/x86: alienware-wmi-wmax: Expose GPIO debug
 methods
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250427-awcc-gpio-v2-1-c731373b5d02@gmail.com>
References: <20250427-awcc-gpio-v2-0-c731373b5d02@gmail.com>
In-Reply-To: <20250427-awcc-gpio-v2-0-c731373b5d02@gmail.com>
To: Hans de Goede <hdegoede@redhat.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Armin Wolf <W_Armin@gmx.de>
Cc: Gabriel Marcano <gabemarcano@yahoo.com>, 
 platform-driver-x86@vger.kernel.org, Dell.Client.Kernel@dell.com, 
 linux-kernel@vger.kernel.org, Kurt Borja <kuurtb@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6152; i=kuurtb@gmail.com;
 h=from:subject:message-id; bh=PjTxT/MddMmROi/3VFQbwJotJF1sMRpyb3LM+xRIsXY=;
 b=owGbwMvMwCUmluBs8WX+lTTG02pJDBm8Z8+Uilf3HGba8DLzOf/b6WtL1/+9cOxv6l2ON4W71
 zwtuhV9qqOUhUGMi0FWTJGlPWHRt0dReW/9DoTeh5nDygQyhIGLUwAmcsGKkeFekiJDo6Hu9R1F
 0983r/p+aLPr9adSmUZ/WPdPfj/j6dJmRobFosrHzkxM77J40pqWab6qZY3R1qS3h0X6xW7eS3t
 Y+YUXAA==
X-Developer-Key: i=kuurtb@gmail.com; a=openpgp;
 fpr=54D3BE170AEF777983C3C63B57E3B6585920A69A
X-Endpoint-Received: by B4 Relay for kuurtb@gmail.com/default with auth_id=387
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Devices with the AWCC interface come with a USB RGB-lighting STM32 MCU,
which has two GPIO pins with debug capabilities:

 - Device Firmware Update mode (DFU)
 - Negative Reset (NRST)

The WMAX device has methods to toggle or read the state of these GPIO
pins. Expose these methods through DebugFS, hidden behind an unsafe
module parameter to avoid common users from toying with these without
consideration.

Suggested-by: Gabriel Marcano <gabemarcano@yahoo.com>
Reviewed-by: Armin Wolf <W_Armin@gmx.de>
Signed-off-by: Kurt Borja <kuurtb@gmail.com>
---
 Documentation/ABI/testing/debugfs-alienware-wmi |  20 +++++
 drivers/platform/x86/dell/alienware-wmi-wmax.c  | 108 +++++++++++++++++++++++-
 2 files changed, 127 insertions(+), 1 deletion(-)

diff --git a/Documentation/ABI/testing/debugfs-alienware-wmi b/Documentation/ABI/testing/debugfs-alienware-wmi
index 48cfd4d0b002efd7b68d9c1d3aa91a3a05f49db5..d20b8627ac5f1528396549a81481e26889bc410e 100644
--- a/Documentation/ABI/testing/debugfs-alienware-wmi
+++ b/Documentation/ABI/testing/debugfs-alienware-wmi
@@ -42,3 +42,23 @@ Description:
 		details.
 
 		RO
+
+What:		/sys/kernel/debug/alienware-wmi-<wmi_device_name>/gpio_ctl/total_gpios
+Date:		May 2025
+KernelVersion:	6.16
+Contact:	Kurt Borja <kuurtb@gmail.com>
+Description:
+		Total number of GPIO pins reported by the device.
+
+		RO
+
+What:		/sys/kernel/debug/alienware-wmi-<wmi_device_name>/gpio_ctl/<pin_name>_pin
+Date:		May 2025
+KernelVersion:	6.16
+Contact:	Kurt Borja <kuurtb@gmail.com>
+Description:
+		This file controls <pin_name> status.
+
+		See Documentation/wmi/devices/alienware-wmi.rst for details.
+
+		RW
diff --git a/drivers/platform/x86/dell/alienware-wmi-wmax.c b/drivers/platform/x86/dell/alienware-wmi-wmax.c
index faeddfe3b79e0aa51e7c8c6b23aa4ac5c7218706..8e682427580a629f48530d7c926db4587352c04c 100644
--- a/drivers/platform/x86/dell/alienware-wmi-wmax.c
+++ b/drivers/platform/x86/dell/alienware-wmi-wmax.c
@@ -38,6 +38,9 @@
 #define AWCC_METHOD_GET_FAN_SENSORS		0x13
 #define AWCC_METHOD_THERMAL_INFORMATION		0x14
 #define AWCC_METHOD_THERMAL_CONTROL		0x15
+#define AWCC_METHOD_FWUP_GPIO_CONTROL		0x20
+#define AWCC_METHOD_READ_TOTAL_GPIOS		0x21
+#define AWCC_METHOD_READ_GPIO_STATUS		0x22
 #define AWCC_METHOD_GAME_SHIFT_STATUS		0x25
 
 #define AWCC_FAILURE_CODE			0xFFFFFFFF
@@ -217,6 +220,11 @@ enum AWCC_TEMP_SENSOR_TYPES {
 	AWCC_TEMP_SENSOR_GPU			= 0x06,
 };
 
+enum AWCC_GPIO_PINS {
+	AWCC_GPIO_PIN_DFU			= 0x00,
+	AWCC_GPIO_PIN_NRST			= 0x01,
+};
+
 enum awcc_thermal_profile {
 	AWCC_PROFILE_USTT_BALANCED,
 	AWCC_PROFILE_USTT_BALANCED_PERFORMANCE,
@@ -571,6 +579,38 @@ static int awcc_thermal_information(struct wmi_device *wdev, u8 operation, u8 ar
 	return awcc_wmi_command(wdev, AWCC_METHOD_THERMAL_INFORMATION, &args, out);
 }
 
+static int awcc_fwup_gpio_control(struct wmi_device *wdev, u8 pin, u8 status)
+{
+	struct wmax_u32_args args = {
+		.operation = pin,
+		.arg1 = status,
+		.arg2 = 0,
+		.arg3 = 0,
+	};
+	u32 out;
+
+	return awcc_wmi_command(wdev, AWCC_METHOD_FWUP_GPIO_CONTROL, &args, &out);
+}
+
+static int awcc_read_total_gpios(struct wmi_device *wdev, u32 *count)
+{
+	struct wmax_u32_args args = {};
+
+	return awcc_wmi_command(wdev, AWCC_METHOD_READ_TOTAL_GPIOS, &args, count);
+}
+
+static int awcc_read_gpio_status(struct wmi_device *wdev, u8 pin, u32 *status)
+{
+	struct wmax_u32_args args = {
+		.operation = pin,
+		.arg1 = 0,
+		.arg2 = 0,
+		.arg3 = 0,
+	};
+
+	return awcc_wmi_command(wdev, AWCC_METHOD_READ_GPIO_STATUS, &args, status);
+}
+
 static int awcc_game_shift_status(struct wmi_device *wdev, u8 operation,
 				  u32 *out)
 {
@@ -1318,6 +1358,63 @@ static int awcc_debugfs_pprof_data_read(struct seq_file *seq, void *data)
 	return 0;
 }
 
+static int awcc_debugfs_total_gpios_read(struct seq_file *seq, void *data)
+{
+	struct device *dev = seq->private;
+	struct wmi_device *wdev = to_wmi_device(dev);
+	u32 count;
+	int ret;
+
+	ret = awcc_read_total_gpios(wdev, &count);
+	if (ret)
+		return ret;
+
+	seq_printf(seq, "%u\n", count);
+
+	return 0;
+}
+
+static int awcc_gpio_pin_show(struct seq_file *seq, void *data)
+{
+	unsigned long pin = debugfs_get_aux_num(seq->file);
+	struct wmi_device *wdev = seq->private;
+	u32 status;
+	int ret;
+
+	ret = awcc_read_gpio_status(wdev, pin, &status);
+	if (ret)
+		return ret;
+
+	seq_printf(seq, "%u\n", status);
+
+	return 0;
+}
+
+static ssize_t awcc_gpio_pin_write(struct file *file, const char __user *buf,
+				   size_t count, loff_t *ppos)
+{
+	unsigned long pin = debugfs_get_aux_num(file);
+	struct seq_file *seq = file->private_data;
+	struct wmi_device *wdev = seq->private;
+	bool status;
+	int ret;
+
+	if (!ppos || *ppos)
+		return -EINVAL;
+
+	ret = kstrtobool_from_user(buf, count, &status);
+	if (ret)
+		return ret;
+
+	ret = awcc_fwup_gpio_control(wdev, pin, status);
+	if (ret)
+		return ret;
+
+	return count;
+}
+
+DEFINE_SHOW_STORE_ATTRIBUTE(awcc_gpio_pin);
+
 static void awcc_debugfs_remove(void *data)
 {
 	struct dentry *root = data;
@@ -1327,7 +1424,7 @@ static void awcc_debugfs_remove(void *data)
 
 static void awcc_debugfs_init(struct wmi_device *wdev)
 {
-	struct dentry *root;
+	struct dentry *root, *gpio_ctl;
 	char name[64];
 
 	scnprintf(name, sizeof(name), "%s-%s", "alienware-wmi", dev_name(&wdev->dev));
@@ -1344,6 +1441,15 @@ static void awcc_debugfs_init(struct wmi_device *wdev)
 		debugfs_create_devm_seqfile(&wdev->dev, "pprof_data", root,
 					    awcc_debugfs_pprof_data_read);
 
+	gpio_ctl = debugfs_create_dir("gpio_ctl", root);
+
+	debugfs_create_devm_seqfile(&wdev->dev, "total_gpios", gpio_ctl,
+				    awcc_debugfs_total_gpios_read);
+	debugfs_create_file_aux_num("dfu_pin", 0644, gpio_ctl, wdev,
+				    AWCC_GPIO_PIN_DFU, &awcc_gpio_pin_fops);
+	debugfs_create_file_aux_num("nrst_pin", 0644, gpio_ctl, wdev,
+				    AWCC_GPIO_PIN_NRST, &awcc_gpio_pin_fops);
+
 	devm_add_action_or_reset(&wdev->dev, awcc_debugfs_remove, root);
 }
 

-- 
2.49.0

