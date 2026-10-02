From: DMS <dms3studio@gmail.com>
Date: Fri, 02 Oct 2026 11:37:42 -0700
Subject: [PATCH] HID: i2c-hid: add quirk to send initial output reports for
 Acer SFA14-I31
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-swift-sfa14-kbd-v1-1-ad312bca1076@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ6DMAxA0asgz7WURJChV0EdQmKDqQRVDLQS4
 u4EOr7h/x2UspDCs9oh0yYq81RgHxXEIUw9oaRicMZ5a4xD/QovqBxsje8uoQ1MyTfEjXdQqk8
 mlt99bF9/69qNFJdrA8dxApEjuO9zAAAA
X-Change-ID: 20261002-swift-sfa14-kbd-1afed65ef562
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 DMS <dms3studio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790966274; l=5013;
 i=dms3studio@gmail.com; s=20261002; h=from:subject:message-id;
 bh=u1O1iFC2D7Dw2S1dibG8iHZiy30p8p5HSOsHgNyzOWM=;
 b=aT7+qGPM9y8ZN7KzP5Qqww6C/qUObvRTJ7G6tMmWekK8O8RY4aLdrSpdcvuQI6MV5jRqTCVX3
 sW2Vnu/nywtDTbk9YUy4FbtpDoAkVy1fabteZQasx0pks91y2/Jk7Ts
X-Developer-Key: i=dms3studio@gmail.com; a=ed25519;
 pk=iEKXvjgvX82Pm5Lmco/mZzbmqo1aPwVXtxvX4fpbgNE=
X-Endpoint-Received: by B4 Relay for dms3studio@gmail.com/20261002 with auth_id=1102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The internal keyboard of the Acer Swift Air 14 (SFA14-I31, ACPI
1025174B, HID 049f:5343) does not send any input reports after probe.
It stays silent, and its GPIO interrupt never fires, until the host has
written an output report to it at least once.

The input core only forwards LED state to the device when it changes.
All LEDs start off, so no output report is written at boot and the
keyboard is unusable until the first suspend/resume cycle, where
input_dev_toggle() re-sends the LED state unconditionally. Closing and
opening the lid is the only way to get a working keyboard.

Add I2C_HID_QUIRK_INIT_OUTPUT_REPORTS, which sends every output report
once with its initial field values right after the HID device has been
added, and enable it for this keyboard.

Tested on an SFA14-I31 (BIOS V1.01) with a 7.2.8 kernel and this change
applied to i2c-hid as a module: the keyboard works from boot without a
suspend/resume cycle, and suspend/resume keeps working. Without it,
writing the LED output report by hand (i2ctransfer) or toggling the
capslock LED through sysfs has the same effect, while resetting or
re-powering the device does not. This version, rebased on hid.git
for-next, was build-tested only.

Assisted-by: LLM
Signed-off-by: DMS <dms3studio@gmail.com>
---
This was debugged and written with the help of an AI coding assistant
(Claude), working over SSH on the affected laptop. It counted keyboard
interrupts, traced i2c-hid with dynamic debug during a pm_test=devices
cycle, and replayed raw I2C transfers to isolate the LED output report
as the trigger. Rebinding i2c-hid (which resets the device), rebinding
the I2C controller and manual SET_POWER commands were ruled out. I
reviewed the change and tested it on my machine as described in the
commit message.

If you would rather handle this generically, e.g. by syncing LED state
when hid-input connects, I am happy to test that instead.
---
 drivers/hid/hid-ids.h              |  3 +++
 drivers/hid/i2c-hid/i2c-hid-core.c | 36 ++++++++++++++++++++++++++++++++++++
 2 files changed, 39 insertions(+)

diff --git a/drivers/hid/hid-ids.h b/drivers/hid/hid-ids.h
index a9537b7bb..5e6096caf 100644
--- a/drivers/hid/hid-ids.h
+++ b/drivers/hid/hid-ids.h
@@ -39,6 +39,9 @@
 #define USB_DEVICE_ID_ACECAD_FLAIR	0x0004
 #define USB_DEVICE_ID_ACECAD_302	0x0008
 
+#define I2C_VENDOR_ID_ACER_KBD		0x049f
+#define I2C_PRODUCT_ID_ACER_SFA14_KBD	0x5343
+
 #define USB_VENDOR_ID_ACRUX		0x1a34
 
 #define USB_VENDOR_ID_ACTIONSTAR	0x2101
diff --git a/drivers/hid/i2c-hid/i2c-hid-core.c b/drivers/hid/i2c-hid/i2c-hid-core.c
index a8a985485..f54671092 100644
--- a/drivers/hid/i2c-hid/i2c-hid-core.c
+++ b/drivers/hid/i2c-hid/i2c-hid-core.c
@@ -52,6 +52,7 @@
 #define I2C_HID_QUIRK_NO_SLEEP_ON_SUSPEND	BIT(5)
 #define I2C_HID_QUIRK_DELAY_WAKEUP_AFTER_RESUME BIT(6)
 #define I2C_HID_QUIRK_RE_POWER_ON		BIT(7)
+#define I2C_HID_QUIRK_INIT_OUTPUT_REPORTS	BIT(8)
 
 /* Command opcodes */
 #define I2C_HID_OPCODE_RESET			0x01
@@ -155,6 +156,12 @@ static const struct i2c_hid_quirks {
 		 I2C_HID_QUIRK_DELAY_WAKEUP_AFTER_RESUME },
 	{ I2C_VENDOR_ID_BLTP, I2C_PRODUCT_ID_BLTP7853,
 		I2C_HID_QUIRK_NO_IRQ_AFTER_RESET },
+	/*
+	 * The Acer Swift SFA14-I31 keyboard sends no input until the host
+	 * has written an output (LED) report at least once
+	 */
+	{ I2C_VENDOR_ID_ACER_KBD, I2C_PRODUCT_ID_ACER_SFA14_KBD,
+		I2C_HID_QUIRK_INIT_OUTPUT_REPORTS },
 	{ 0, 0 }
 };
 
@@ -1079,6 +1086,32 @@ static int __i2c_hid_core_probe(struct i2c_hid *ihid)
 	return 0;
 }
 
+/*
+ * The input core only writes LED state when it changes (and on resume), so
+ * a device that waits for an output report never gets one at boot. Send
+ * every output report once with its initial field values.
+ */
+static void i2c_hid_send_initial_output_reports(struct hid_device *hid)
+{
+	struct hid_report_enum *report_enum = &hid->report_enum[HID_OUTPUT_REPORT];
+	struct hid_report *report;
+	u8 *buf;
+	int ret;
+
+	list_for_each_entry(report, &report_enum->report_list, list) {
+		buf = hid_alloc_report_buf(report, GFP_KERNEL);
+		if (!buf)
+			return;
+
+		hid_output_report(report, buf);
+		ret = i2c_hid_output_report(hid, buf, hid_report_len(report));
+		if (ret < 0)
+			hid_warn(hid, "failed to send initial output report %u: %d\n",
+				 report->id, ret);
+		kfree(buf);
+	}
+}
+
 static int i2c_hid_core_register_hid(struct i2c_hid *ihid)
 {
 	struct i2c_client *client = ihid->client;
@@ -1099,6 +1132,9 @@ static int i2c_hid_core_register_hid(struct i2c_hid *ihid)
 	if (ihid->quirks & I2C_HID_QUIRK_RE_POWER_ON)
 		ret = i2c_hid_set_power(ihid, I2C_HID_PWR_ON);
 
+	if (ihid->quirks & I2C_HID_QUIRK_INIT_OUTPUT_REPORTS)
+		i2c_hid_send_initial_output_reports(hid);
+
 	return ret;
 }
 

---
base-commit: 145c2b2e9a5c0f794fb4009bcb072ab19f8ccfcd
change-id: 20261002-swift-sfa14-kbd-1afed65ef562

Best regards,
--  
DMS <dms3studio@gmail.com>

