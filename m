From: Kurt Borja <kuurtb@gmail.com>
Date: Mon, 05 May 2025 15:43:31 -0300
Subject: [PATCH v4 1/2] platform/x86: alienware-wmi-wmax: Expose GPIO debug
 methods
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250505-awcc-gpio-v4-1-edda44c3a0dc@gmail.com>
References: <20250505-awcc-gpio-v4-0-edda44c3a0dc@gmail.com>
In-Reply-To: <20250505-awcc-gpio-v4-0-edda44c3a0dc@gmail.com>
To: Hans de Goede <hdegoede@redhat.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Armin Wolf <W_Armin@gmx.de>
Cc: Gabriel Marcano <gabemarcano@yahoo.com>, 
 platform-driver-x86@vger.kernel.org, Dell.Client.Kernel@dell.com, 
 linux-kernel@vger.kernel.org, Kurt Borja <kuurtb@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6088; i=kuurtb@gmail.com;
 h=from:subject:message-id; bh=VhjdIaye3R/a9OKG1gJhjtj9h7gjZ1ZcB47ONQBNzIg=;
 b=owGbwMvMwCUmluBs8WX+lTTG02pJDBmSbC9S2+9uPXe29UrO75VfZ6or8vtsND3z7GfwKs4r6
 lwtNhdfdJSyMIhxMciKKbK0Jyz69igq763fgdD7MHNYmUCGMHBxCsBEDiUy/A/aqK1kWPHkZ2LV
 qp3vXtxS2/kxwPH/x/x5M9vqzu8RceVm+B8j8Pz5l4kPl8kyHHqRP0t/a3TmT5+frZNmFqmXWyo
 xKvABAA==
X-Developer-Key: i=kuurtb@gmail.com; a=openpgp;
 fpr=54D3BE170AEF777983C3C63B57E3B6585920A69A
X-Endpoint-Received: by B4 Relay for kuurtb@gmail.com/default with auth_id=387
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Expose GPIO control methods present on the AWCC interface through
DebugFS.

These models come with an RGB lighting STM32 MCU, which usually has two
GPIO pins with debug capabilities:

 - Pin 0: Device Firmware Update mode (DFU)
 - Pin 1: Negative Reset (NRST)

Suggested-by: Gabriel Marcano <gabemarcano@yahoo.com>
Reviewed-by: Armin Wolf <W_Armin@gmx.de>
Signed-off-by: Kurt Borja <kuurtb@gmail.com>
---
 Documentation/ABI/testing/debugfs-alienware-wmi |  20 +++++
 drivers/platform/x86/dell/alienware-wmi-wmax.c  | 104 +++++++++++++++++++++++-
 2 files changed, 123 insertions(+), 1 deletion(-)

diff --git a/Documentation/ABI/testing/debugfs-alienware-wmi b/Documentation/ABI/testing/debugfs-alienware-wmi
index 48cfd4d0b002efd7b68d9c1d3aa91a3a05f49db5..c7f525d6baac962be82780608f8da5c0368600cc 100644
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
+What:		/sys/kernel/debug/alienware-wmi-<wmi_device_name>/gpio_ctl/pinX
+Date:		May 2025
+KernelVersion:	6.16
+Contact:	Kurt Borja <kuurtb@gmail.com>
+Description:
+		This file controls GPIO pin X status.
+
+		See Documentation/wmi/devices/alienware-wmi.rst for details.
+
+		RW
diff --git a/drivers/platform/x86/dell/alienware-wmi-wmax.c b/drivers/platform/x86/dell/alienware-wmi-wmax.c
index f3ad47c9edfac47fae181046acae2190e388306c..f0e6a36abc278d95059dfc007414894dee79b587 100644
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
@@ -281,6 +284,8 @@ struct awcc_priv {
 	struct device *hwdev;
 	struct awcc_fan_data **fan_data;
 	unsigned long temp_sensors[AWCC_ID_BITMAP_LONGS];
+
+	u32 gpio_count;
 };
 
 static const enum platform_profile_option awcc_mode_to_platform_profile[AWCC_PROFILE_LAST] = {
@@ -571,6 +576,38 @@ static int awcc_thermal_information(struct wmi_device *wdev, u8 operation, u8 ar
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
@@ -1317,6 +1354,47 @@ static int awcc_debugfs_pprof_data_read(struct seq_file *seq, void *data)
 	return 0;
 }
 
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
@@ -1326,8 +1404,11 @@ static void awcc_debugfs_remove(void *data)
 
 static void awcc_debugfs_init(struct wmi_device *wdev)
 {
-	struct dentry *root;
+	struct awcc_priv *priv = dev_get_drvdata(&wdev->dev);
+	struct dentry *root, *gpio_ctl;
+	u32 gpio_count;
 	char name[64];
+	int ret;
 
 	scnprintf(name, sizeof(name), "%s-%s", "alienware-wmi", dev_name(&wdev->dev));
 	root = debugfs_create_dir(name, NULL);
@@ -1343,6 +1424,27 @@ static void awcc_debugfs_init(struct wmi_device *wdev)
 		debugfs_create_devm_seqfile(&wdev->dev, "pprof_data", root,
 					    awcc_debugfs_pprof_data_read);
 
+	ret = awcc_read_total_gpios(wdev, &gpio_count);
+	if (ret) {
+		dev_dbg(&wdev->dev, "Failed to get total GPIO Pin count\n");
+		goto out_add_action;
+	} else if (gpio_count > AWCC_MAX_RES_COUNT) {
+		dev_dbg(&wdev->dev, "Reported GPIO Pin count may be incorrect: %u\n", gpio_count);
+		goto out_add_action;
+	}
+
+	gpio_ctl = debugfs_create_dir("gpio_ctl", root);
+
+	priv->gpio_count = gpio_count;
+	debugfs_create_u32("total_gpios", 0444, gpio_ctl, &priv->gpio_count);
+
+	for (unsigned int i = 0; i < gpio_count; i++) {
+		scnprintf(name, sizeof(name), "pin%u", i);
+		debugfs_create_file_aux_num(name, 0644, gpio_ctl, wdev, i,
+					    &awcc_gpio_pin_fops);
+	}
+
+out_add_action:
 	devm_add_action_or_reset(&wdev->dev, awcc_debugfs_remove, root);
 }
 

-- 
2.49.0

