From: Zane Hunt <git@turtledev.nz>
Date: Mon, 19 Oct 2026 19:35:18 +1300
Subject: [PATCH v4] platform/x86: asus-wmi: fix camera key LED on Zenbook
 S14
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261019-asus-wmi-camera-led-v4-1-7744c125bcc9@turtledev.nz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NyQ6CMBCGX4XM2TFdWD35HoZDhVFqBEyn1IXw7
 ha8e/zyL98MTM4SwyGZwVGwbMchQrpLoOnMcCW0bWRQQuVSyAINT4zP3mJjenIG79SiyE1OIrs
 ISQri8uHoYl/b66n+MU/nGzV+vVobnWU/uvemDXrt/TcEjRLLNDOl0oWuquLoJ+djQmE/fKBel
 uULk+Yk58sAAAA=
X-Change-ID: 20261017-asus-wmi-camera-led-06a6e05f01e2
To: Corentin Chary <corentin.chary@gmail.com>, 
 "Luke D. Jones" <luke@ljones.dev>, Denis Benato <denis.benato@linux.dev>, 
 Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 platform-driver-x86@vger.kernel.org
Cc: =?utf-8?q?Jos=C3=A9_Guilherme_de_Castro_Rodrigues?= <jose.guilherme.cr.bh@gmail.com>, 
 linux-kernel@vger.kernel.org, Zane Hunt <git@turtledev.nz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792391727; l=8814;
 i=git@turtledev.nz; s=20261016; h=from:subject:message-id;
 bh=AyQeJsVv3Fvj/hhwEjxbvqi52N6/K7t7CxQK2jV7yZQ=;
 b=iVahtRUtnbKMAQhxGYCqHy1eS/Zhk1sFZazzgBTEw12G4fRTcs0QsAh/EMXAV95Mw5otTmCf3
 RHl7AxV6KVQB7NOsccV0s/aPvOTfidH5nBV9K+/x9jMqDZTq/wePimu
X-Developer-Key: i=git@turtledev.nz; a=ed25519;
 pk=7P3HBZD1ukp3nMYpf+9Dcl3ryKIU5pYgOUKe/HOox6c=
X-Endpoint-Received: by B4 Relay for git@turtledev.nz/20261016 with auth_id=1217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On some newer Zenbooks (Zenbook S 14 UX5406SA, Zenbook S 16 UM5606WA) the
camera key turns the camera off in firmware, but the LED on the key never
lights up under Linux. These machines don't have
ASUS_WMI_DEVID_CAMERA_LED, so asus-wmi never registers asus::camera. The
firmware exposes the state through ASUS_WMI_DEVID_CAMERA_LED_NEG instead.

Reading CAMERA_LED_NEG is what drives the LED: the DSTS handler reads the
camera state from the EC and writes it to the LED GPIO before returning
it. The set side can't be used, the firmware only accepts DEVS on this
device once per boot.

When CAMERA_LED is missing but CAMERA_LED_NEG is there, register
asus::camera as a read-only LED backed by CAMERA_LED_NEG, and read it
after every camera key event, sending a brightness_hw_changed event.
Registering the LED reads it as well, which fixes the LED being dark after
a cold boot with the camera disabled.

While at it, include <linux/container_of.h>, which this file already
relied on.

Link: https://lore.kernel.org/r/adg6GzkykThAB_4u@djouze-zen
Closes: https://bugzilla.kernel.org/show_bug.cgi?id=221752
Assisted-by: Claude:claude-opus-5-5 iasl
Co-developed-by: José Guilherme de Castro Rodrigues <jose.guilherme.cr.bh@gmail.com>
Signed-off-by: José Guilherme de Castro Rodrigues <jose.guilherme.cr.bh@gmail.com>
Signed-off-by: Zane Hunt <git@turtledev.nz>
---
Changes in v4:
- Keep José's Signed-off-by from v2 and add his Co-developed-by
- Use my full name in the tags
- Include <linux/container_of.h>
- Reuse the existing asus::camera registration block, only the
  handlers and flags differ
- camera_neg_led_available is now only set when CAMERA_LED is missing,
  so asus::camera is always the CAMERA_LED_NEG one when it's set. That
  makes the LED_BRIGHT_HW_CHANGED check in the event handler unneeded,
  so it's gone
- Drop the explicit read at probe, led_classdev_register() already
  reads the state through brightness_get
- Link to v3: https://patch.msgid.link/20261017-asus-wmi-camera-led-v3-1-845a82373997@turtledev.nz

Changes in v3 (picking up José's v2, which had stalled):
- Rebased on pdx86 for-next
- Also read CAMERA_LED_NEG at probe, so the LED is right after a cold boot
- Register a read-only asus::camera LED when only CAMERA_LED_NEG exists,
  with brightness_hw_changed on key presses (Ilpo's suggestion on v2)
- Comment on why the read is what updates the LED (also from v2 review)
- v2: https://lore.kernel.org/r/adg6GzkykThAB_4u@djouze-zen

Tested again on the Zenbook S 14 UX5406SA (BIOS 309), on Fedora's 7.2.9
kernel with the same change applied: camera key presses keep the LED,
asus::camera and the camera output in sync, and with the camera disabled
and the LED forced off, loading the driver turns the LED back on.

I used Claude while working on this. It helped
me read through the DSDT, drafted the changes on top of v2 and wrote the
test scripts. I went through the patch myself and ran the tests on my
laptop.
---
 drivers/platform/x86/asus-wmi.c            | 75 ++++++++++++++++++++++++++++--
 include/linux/platform_data/x86/asus-wmi.h |  2 +-
 2 files changed, 73 insertions(+), 4 deletions(-)

diff --git a/drivers/platform/x86/asus-wmi.c b/drivers/platform/x86/asus-wmi.c
index fb1d4a0..93b51c8 100644
--- a/drivers/platform/x86/asus-wmi.c
+++ b/drivers/platform/x86/asus-wmi.c
@@ -17,6 +17,7 @@
 #include <linux/backlight.h>
 #include <linux/bits.h>
 #include <linux/cleanup.h>
+#include <linux/container_of.h>
 #include <linux/debugfs.h>
 #include <linux/delay.h>
 #include <linux/dmi.h>
@@ -72,6 +73,8 @@ module_param(fnlock_default, bool, 0444);
 #define NOTIFY_KBD_TTP			0xae
 #define NOTIFY_LID_FLIP			0xfa
 #define NOTIFY_LID_FLIP_ROG		0xbd
+#define NOTIFY_CAMERA_TOGGLE_1		0x82
+#define NOTIFY_CAMERA_TOGGLE_2		0x85
 #define NOTIFY_KEYSTONE			0xb4
 
 #define ASUS_WMI_FNLOCK_BIOS_DISABLED	BIT(0)
@@ -312,6 +315,7 @@ struct asus_wmi {
 	u32 kbd_rgb_dev;
 	bool kbd_rgb_state_available;
 	bool oobe_state_available;
+	bool camera_neg_led_available;
 
 	u8 throttle_thermal_policy_mode;
 	u32 throttle_thermal_policy_dev;
@@ -2096,6 +2100,54 @@ static int camera_led_set(struct led_classdev *led_cdev,
 	return err < 0 ? err : 0;
 }
 
+static bool is_camera_toggle(int code)
+{
+	return code == NOTIFY_CAMERA_TOGGLE_1 || code == NOTIFY_CAMERA_TOGGLE_2;
+}
+
+/*
+ * Some models (e.g. Zenbook S 14 UX5406SA, Zenbook S 16 UM5606WA) have no
+ * ASUS_WMI_DEVID_CAMERA_LED. The firmware handles the camera key itself and
+ * only exposes the state through ASUS_WMI_DEVID_CAMERA_LED_NEG, and reading
+ * that has a side effect: the firmware copies the state to the LED GPIO.
+ * Nothing else updates the LED, so read it after every camera key event.
+ * Registering asus::camera reads it too (via brightness_get), which sets the
+ * LED at probe. Setting it is no use, the firmware accepts DEVS on this
+ * device only once per boot.
+ *
+ * Returns 1 if the camera is disabled (LED lit), 0 if enabled, or -errno.
+ */
+static int camera_neg_led_sync(struct asus_wmi *asus)
+{
+	u32 result;
+	int err;
+
+	err = asus_wmi_get_devstate(asus, ASUS_WMI_DEVID_CAMERA_LED_NEG, &result);
+	if (err)
+		return err;
+
+	return !(result & ASUS_WMI_DSTS_STATUS_BIT);
+}
+
+static enum led_brightness camera_neg_led_get(struct led_classdev *led_cdev)
+{
+	struct asus_wmi *asus = container_of(led_cdev, struct asus_wmi, camera_led);
+	int state = camera_neg_led_sync(asus);
+
+	return state < 0 ? LED_OFF : state;
+}
+
+/* The firmware owns this LED; a write just resyncs it with the camera state. */
+static int camera_neg_led_set(struct led_classdev *led_cdev,
+			      enum led_brightness brightness)
+{
+	struct asus_wmi *asus = container_of(led_cdev, struct asus_wmi, camera_led);
+
+	if (!(led_cdev->flags & LED_UNREGISTERING))
+		camera_neg_led_sync(asus);
+	return 0;
+}
+
 static void asus_wmi_led_exit(struct asus_wmi *asus)
 {
 	scoped_guard(spinlock_irqsave, &asus_ref.lock)
@@ -2227,11 +2279,18 @@ static int asus_wmi_led_init(struct asus_wmi *asus)
 			goto error;
 	}
 
-	if (asus_wmi_dev_is_present(asus, ASUS_WMI_DEVID_CAMERA_LED)) {
+	if (asus->camera_neg_led_available ||
+	    asus_wmi_dev_is_present(asus, ASUS_WMI_DEVID_CAMERA_LED)) {
 		asus->camera_led.name = "asus::camera";
 		asus->camera_led.max_brightness = 1;
-		asus->camera_led.brightness_get = camera_led_get;
-		asus->camera_led.brightness_set_blocking = camera_led_set;
+		if (asus->camera_neg_led_available) {
+			asus->camera_led.flags = LED_BRIGHT_HW_CHANGED;
+			asus->camera_led.brightness_get = camera_neg_led_get;
+			asus->camera_led.brightness_set_blocking = camera_neg_led_set;
+		} else {
+			asus->camera_led.brightness_get = camera_led_get;
+			asus->camera_led.brightness_set_blocking = camera_led_set;
+		}
 
 		rv = led_classdev_register(&asus->platform_device->dev,
 						&asus->camera_led);
@@ -4733,6 +4792,13 @@ static void asus_wmi_handle_event_code(int code, struct asus_wmi *asus)
 	if (is_display_toggle(code) && asus->driver->quirks->no_display_toggle)
 		return;
 
+	if (is_camera_toggle(code) && asus->camera_neg_led_available) {
+		int state = camera_neg_led_sync(asus);
+
+		if (state >= 0)
+			led_classdev_notify_brightness_hw_changed(&asus->camera_led, state);
+	}
+
 	if (!sparse_keymap_report_event(asus->inputdev, code,
 					key_value, autorelease))
 		pr_info("Unknown key code 0x%x\n", code);
@@ -5210,6 +5276,9 @@ static int asus_wmi_add(struct platform_device *pdev)
 #endif /* IS_ENABLED(CONFIG_ASUS_WMI_DEPRECATED_ATTRS) */
 
 	asus->oobe_state_available = asus_wmi_dev_is_present(asus, ASUS_WMI_DEVID_OOBE);
+	asus->camera_neg_led_available =
+		!asus_wmi_dev_is_present(asus, ASUS_WMI_DEVID_CAMERA_LED) &&
+		asus_wmi_dev_is_present(asus, ASUS_WMI_DEVID_CAMERA_LED_NEG);
 
 	if (asus_wmi_dev_is_present(asus, ASUS_WMI_DEVID_THROTTLE_THERMAL_POLICY))
 		asus->throttle_thermal_policy_dev = ASUS_WMI_DEVID_THROTTLE_THERMAL_POLICY;
diff --git a/include/linux/platform_data/x86/asus-wmi.h b/include/linux/platform_data/x86/asus-wmi.h
index 4ea1ccc..5964063 100644
--- a/include/linux/platform_data/x86/asus-wmi.h
+++ b/include/linux/platform_data/x86/asus-wmi.h
@@ -57,7 +57,7 @@
 #define ASUS_WMI_DEVID_MUTE_LED	0x0004001C
 
 /* Disable Camera LED */
-#define ASUS_WMI_DEVID_CAMERA_LED_NEG	0x00060078 /* 0 = on (unused) */
+#define ASUS_WMI_DEVID_CAMERA_LED_NEG	0x00060078 /* 0 = on */
 #define ASUS_WMI_DEVID_CAMERA_LED	0x00060079 /* 1 = on */
 
 /* Backlight and Brightness */

---
base-commit: ea40f1e9f07aab937b9a217633be7a1f66260394
change-id: 20261017-asus-wmi-camera-led-06a6e05f01e2

Best regards,
--  
Zane Hunt <git@turtledev.nz>

