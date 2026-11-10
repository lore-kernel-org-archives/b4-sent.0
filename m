From: Ciro Pedrini <ciro.pedrini@gmail.com>
Date: Tue, 10 Nov 2026 20:29:48 +0000
Subject: [PATCH v2 2/2] HID: lenovo-legion: Add keyboard backlight driver
 for Legion Gen 10
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-legion-lighting-rfc-v2-2-845726afb71c@gmail.com>
References: <20261110-legion-lighting-rfc-v2-0-845726afb71c@gmail.com>
In-Reply-To: <20261110-legion-lighting-rfc-v2-0-845726afb71c@gmail.com>
To: Mark Pearson <mpearson-lenovo@squebb.ca>, 
 "Derek J. Clark" <derekjohn.clark@gmail.com>, Rong Zhang <i@rong.moe>, 
 Ike Panhc <ikepanhc@gmail.com>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: Werner Sembach <wse@tuxedocomputers.com>, 
 Aaron Erhardt <aer@tuxedocomputers.com>, 
 platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-input@vger.kernel.org, Ciro Pedrini <ciro.pedrini@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794342675; l=12358;
 i=ciro.pedrini@gmail.com; h=from:subject:message-id;
 bh=zAhg4HdF8t7gFQEd8ofeNFnmNt/RSMeM6hIcOZhQZoA=;
 b=5fExqUiX7tJD2ygbmi0PQLnqzJcPpw51oTV+5Lr+dEiGB+uJb2lrXG+g6xlIRo379xxD54xTD
 iTgFjK6RDPNA+eYEXlGUQx/LmugmrHPZt9GpmGiVmaeA1Q9/QjL3veg
X-Developer-Key: i=ciro.pedrini@gmail.com; a=ed25519;
 pk=TOSFlPBon1xBHfTrhODxatabgwEJdgKEzG3jMoMQcbc=
X-Endpoint-Received: by B4 Relay for ciro.pedrini@gmail.com/default with auth_id=1468
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The keyboard backlight of the Lenovo Legion Pro 7 16IAX10H (2025) has no
Linux support: on the test unit nothing ever lit, because the keyboard
controller's brightness was 0 from the factory and nothing exposes it.

The ITE 8258 keyboard controller (048d:c197) is the built-in keyboard and
carries a vendor protocol on feature report 0x07 (960 bytes): a request,
answered by reading the report back once the controller has prepared it.
Its hardware brightness, 0..9, is stored in the controller and applies to
every LED of the machine (keys, front strip, rear vents, lid logo). The
firmware handles Fn+Up and Fn+Down itself and reports the new level on
vendor input report 5.

Expose the brightness as a kbd_backlight LED, legion::kbd_backlight, with
brightness_hw_changed for the hotkeys so that desktops show their OSD.
Unregistering keeps the level (LED_RETAIN_AT_SHUTDOWN): switching it off
would be stored by the controller.

The colours stay the controller's own effects, which Fn+Space cycles. The
machine's HID LampArray (048d:c193) is left to hid-generic, or to a
generic LampArray driver.

Tested on the 16IAX10H (83F5) with 7.2 as a module: brightness from sysfs
and KDE, the hotkeys with KDE's OSD, suspend/resume, unbinding and
rebinding, and a userspace LampArray client alongside the driver.

Signed-off-by: Ciro Pedrini <ciro.pedrini@gmail.com>
---
Prepared with Claude Code (Claude Opus 5.5) from measurements on the
laptop (usbmon captures) and analysis of the vendor's Windows software
for interoperability; I reviewed and tested it.
---
 MAINTAINERS                     |   1 +
 drivers/hid/Kconfig             |  13 ++
 drivers/hid/Makefile            |   1 +
 drivers/hid/hid-ids.h           |   1 +
 drivers/hid/hid-lenovo-legion.c | 261 ++++++++++++++++++++++++++++++++++++++++
 5 files changed, 277 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 222b7fc2c3aa..843906a1f9d5 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -15187,6 +15187,7 @@ F:	Documentation/ABI/testing/sysfs-driver-hid-lenovo-go
 F:	Documentation/ABI/testing/sysfs-driver-hid-lenovo-go-s
 F:	drivers/hid/hid-lenovo-go-s.c
 F:	drivers/hid/hid-lenovo-go.c
+F:	drivers/hid/hid-lenovo-legion.c
 F:	drivers/hid/hid-lenovo.c
 
 LENOVO YOGA BOOK 9 KEYBOARD DOCK DRIVER
diff --git a/drivers/hid/Kconfig b/drivers/hid/Kconfig
index 2481bc01c435..55d25afddb69 100644
--- a/drivers/hid/Kconfig
+++ b/drivers/hid/Kconfig
@@ -652,6 +652,19 @@ config HID_LENOVO_GO_S
 	S. Say M here to compile this driver as a module. The module will be called
 	hid-lenovo-go-s.
 
+config HID_LENOVO_LEGION
+	tristate "Lenovo Legion laptop keyboard backlight"
+	depends on USB_HID
+	depends on LEDS_CLASS
+	help
+	Support for the keyboard backlight of 2025 Lenovo Legion laptops
+	(Legion Pro 7 Gen 10): the hardware brightness of the ITE keyboard
+	controller as a kbd_backlight LED, with the Fn+Up/Down changes
+	reported to userspace.
+
+	Say M here to compile this driver as a module. The module will be called
+	hid-lenovo-legion.
+
 config HID_LETSKETCH
 	tristate "Letsketch WP9620N tablets"
 	depends on USB_HID
diff --git a/drivers/hid/Makefile b/drivers/hid/Makefile
index 43a8eb0f389b..713bb1c89861 100644
--- a/drivers/hid/Makefile
+++ b/drivers/hid/Makefile
@@ -78,6 +78,7 @@ obj-$(CONFIG_HID_LCPOWER)	+= hid-lcpower.o
 obj-$(CONFIG_HID_LENOVO)	+= hid-lenovo.o
 obj-$(CONFIG_HID_LENOVO_GO)	+= hid-lenovo-go.o
 obj-$(CONFIG_HID_LENOVO_GO_S)	+= hid-lenovo-go-s.o
+obj-$(CONFIG_HID_LENOVO_LEGION)	+= hid-lenovo-legion.o
 obj-$(CONFIG_HID_LETSKETCH)	+= hid-letsketch.o
 obj-$(CONFIG_HID_LOGITECH)	+= hid-logitech.o
 obj-$(CONFIG_HID_LOGITECH)	+= hid-lg-g15.o
diff --git a/drivers/hid/hid-ids.h b/drivers/hid/hid-ids.h
index 91319aa6516d..992b9b147e95 100644
--- a/drivers/hid/hid-ids.h
+++ b/drivers/hid/hid-ids.h
@@ -773,6 +773,7 @@
 #define USB_DEVICE_ID_ITE_LENOVO_YOGA2  0x8350
 #define I2C_DEVICE_ID_ITE_LENOVO_LEGION_Y720	0x837a
 #define USB_DEVICE_ID_ITE_LENOVO_YOGA900	0x8396
+#define USB_DEVICE_ID_ITE_LENOVO_LEGION_GEN10_KBD	0xc197
 #define I2C_DEVICE_ID_ITE_LENOVO_YOGA_SLIM_7X_KEYBOARD	0x8987
 #define I2C_DEVICE_ID_ITE_LENOVO_YOGA_SLIM_7X_G11_KEYBOARD	0x83db
 #define USB_DEVICE_ID_ITE8595		0x8595
diff --git a/drivers/hid/hid-lenovo-legion.c b/drivers/hid/hid-lenovo-legion.c
new file mode 100644
index 000000000000..6d0b4adc6f49
--- /dev/null
+++ b/drivers/hid/hid-lenovo-legion.c
@@ -0,0 +1,261 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * HID driver for the keyboard backlight of Lenovo Legion laptops (2025).
+ *
+ * The ITE 8258 keyboard controller (048d:c197) is the built-in keyboard and
+ * carries Lenovo's vendor lighting protocol: feature report 0x07, 960 bytes,
+ * a request (struct legion_msg) answered by reading the report back with a
+ * GET_FEATURE once the controller has prepared it (up to ~50 ms).
+ *
+ * The backlight brightness is op 0xCE (set) / 0xCD (get), 0..9, stored in the
+ * controller; it applies to every LED of the machine (keys, front strip, rear
+ * vents, lid logo). The firmware handles Fn+Up / Fn+Down itself and reports
+ * the new level on vendor input report 5 (struct legion_event).
+ *
+ * The colours are the controller's own effects. The LEDs can also be handed
+ * to the HID LampArray of the "Lenovo Lighting" device (048d:c193), which
+ * this driver leaves to others.
+ */
+
+#include <linux/cleanup.h>
+#include <linux/compiler.h>
+#include <linux/container_of.h>
+#include <linux/delay.h>
+#include <linux/device.h>
+#include <linux/hid.h>
+#include <linux/leds.h>
+#include <linux/lockdep.h>
+#include <linux/minmax.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/slab.h>
+#include <linux/string.h>
+#include <linux/types.h>
+
+#include <asm/byteorder.h>
+
+#include "hid-ids.h"
+
+#define LEGION_REPORT_ID		0x07
+#define LEGION_REPORT_SIZE		960
+#define LEGION_ANSWER_DELAY_MS		100
+
+#define LEGION_OP_GET_BRIGHTNESS	0xcd
+#define LEGION_OP_SET_BRIGHTNESS	0xce
+#define LEGION_MAX_BRIGHTNESS		9
+
+#define LEGION_EVENT_REPORT_ID		0x05
+#define LEGION_EVENT_BRIGHTNESS_UP	0x02
+#define LEGION_EVENT_BRIGHTNESS_DOWN	0x03
+
+/* Request, and its answer: the value is params[0]. */
+struct legion_msg {
+	u8 report_id;
+	u8 op;
+	__le16 len;			/* of params */
+	u8 params[];
+} __packed;
+
+struct legion_event {
+	u8 report_id;
+	u8 event;
+	u8 level;			/* brightness after the change */
+} __packed;
+
+struct legion_kbd {
+	struct hid_device *hdev;
+	struct mutex lock;		/* one request/answer exchange at a time */
+	struct legion_msg *msg;		/* LEGION_REPORT_SIZE, DMA-safe */
+	struct led_classdev led;
+};
+
+/*
+ * Send one request. When @answer is non-NULL, wait for the controller to
+ * prepare its answer and return its value there.
+ */
+static int legion_exchange(struct legion_kbd *kbd, u8 op, const u8 *params,
+			   u16 len, u8 *answer)
+{
+	struct hid_device *hdev = kbd->hdev;
+	struct legion_msg *msg = kbd->msg;
+	int ret;
+
+	lockdep_assert_held(&kbd->lock);
+
+	memset(msg, 0, LEGION_REPORT_SIZE);
+	msg->report_id = LEGION_REPORT_ID;
+	msg->op = op;
+	msg->len = cpu_to_le16(len);
+	memcpy(msg->params, params, len);
+
+	ret = hid_hw_raw_request(hdev, LEGION_REPORT_ID, (u8 *)msg,
+				 LEGION_REPORT_SIZE, HID_FEATURE_REPORT,
+				 HID_REQ_SET_REPORT);
+	if (ret < 0)
+		return ret;
+	if (!answer)
+		return 0;
+
+	msleep(LEGION_ANSWER_DELAY_MS);
+
+	memset(msg, 0, LEGION_REPORT_SIZE);
+	ret = hid_hw_raw_request(hdev, LEGION_REPORT_ID, (u8 *)msg,
+				 LEGION_REPORT_SIZE, HID_FEATURE_REPORT,
+				 HID_REQ_GET_REPORT);
+	if (ret < 0)
+		return ret;
+	if (ret <= (int)sizeof(*msg) || msg->report_id != LEGION_REPORT_ID ||
+	    msg->op != op) {
+		hid_warn(hdev, "unexpected answer to 0x%02x: %*ph\n", op,
+			 min(ret, 8), msg);
+		return -EIO;
+	}
+
+	*answer = msg->params[0];
+	return 0;
+}
+
+static int legion_brightness_set(struct led_classdev *led,
+				 enum led_brightness value)
+{
+	struct legion_kbd *kbd = container_of(led, struct legion_kbd, led);
+	u8 level = min_t(unsigned int, value, LEGION_MAX_BRIGHTNESS);
+
+	guard(mutex)(&kbd->lock);
+	return legion_exchange(kbd, LEGION_OP_SET_BRIGHTNESS, &level,
+			       sizeof(level), NULL);
+}
+
+static enum led_brightness legion_brightness_get(struct led_classdev *led)
+{
+	struct legion_kbd *kbd = container_of(led, struct legion_kbd, led);
+	u8 zero = 0, value;
+	int ret;
+
+	guard(mutex)(&kbd->lock);
+	ret = legion_exchange(kbd, LEGION_OP_GET_BRIGHTNESS, &zero,
+			      sizeof(zero), &value);
+	if (ret)
+		return led->brightness;	/* keep the last known level */
+
+	return min_t(unsigned int, value, LEGION_MAX_BRIGHTNESS);
+}
+
+static int legion_raw_event(struct hid_device *hdev, struct hid_report *report,
+			    u8 *data, int size)
+{
+	const struct legion_event *ev = (const struct legion_event *)data;
+	struct legion_kbd *kbd = hid_get_drvdata(hdev);
+	unsigned int level;
+
+	if (size < (int)sizeof(*ev) || ev->report_id != LEGION_EVENT_REPORT_ID)
+		return 0;
+
+	if (ev->event != LEGION_EVENT_BRIGHTNESS_UP &&
+	    ev->event != LEGION_EVENT_BRIGHTNESS_DOWN)
+		return 0;
+
+	/*
+	 * hid-core calls this only after probe() has returned and not once
+	 * remove() has started, so the LED is registered. The controller has
+	 * already changed the level: keep led_cdev.brightness in step with it.
+	 */
+	level = min_t(unsigned int, ev->level, LEGION_MAX_BRIGHTNESS);
+	WRITE_ONCE(kbd->led.brightness, level);
+	led_classdev_notify_brightness_hw_changed(&kbd->led, level);
+
+	return 0;	/* let hid-core handle the report as usual */
+}
+
+static int legion_probe(struct hid_device *hdev, const struct hid_device_id *id)
+{
+	struct legion_kbd *kbd;
+	int ret;
+
+	/* As hid-generic: one input device per application collection. */
+	hdev->quirks |= HID_QUIRK_INPUT_PER_APP;
+
+	ret = hid_parse(hdev);
+	if (ret)
+		return ret;
+
+	kbd = devm_kzalloc_obj(&hdev->dev, *kbd);
+	if (!kbd)
+		return -ENOMEM;
+
+	kbd->msg = devm_kzalloc(&hdev->dev, LEGION_REPORT_SIZE, GFP_KERNEL);
+	if (!kbd->msg)
+		return -ENOMEM;
+
+	ret = devm_mutex_init(&hdev->dev, &kbd->lock);
+	if (ret)
+		return ret;
+
+	kbd->hdev = hdev;
+	hid_set_drvdata(hdev, kbd);
+
+	ret = hid_hw_start(hdev, HID_CONNECT_DEFAULT);
+	if (ret)
+		return ret;
+
+	/* Keep the interrupt endpoint polled so hotkey reports always arrive. */
+	ret = hid_hw_open(hdev);
+	if (ret)
+		goto err_stop;
+
+	kbd->led.name = "legion::kbd_backlight";
+	kbd->led.max_brightness = LEGION_MAX_BRIGHTNESS;
+	kbd->led.brightness_set_blocking = legion_brightness_set;
+	kbd->led.brightness_get = legion_brightness_get;
+	/*
+	 * LED_RETAIN_AT_SHUTDOWN: unregistering (unload, unbind) must not
+	 * switch the backlight off, the controller would store 0.
+	 * LED_BRIGHT_HW_CHANGED: Fn+Up/Down are reported to userspace.
+	 */
+	kbd->led.flags = LED_RETAIN_AT_SHUTDOWN | LED_BRIGHT_HW_CHANGED;
+
+	/*
+	 * Not devm: the LED must be gone before remove() stops the device,
+	 * devm would release it only after that.
+	 */
+	ret = led_classdev_register(&hdev->dev, &kbd->led);
+	if (ret)
+		goto err_close;
+
+	return 0;
+
+err_close:
+	hid_hw_close(hdev);
+err_stop:
+	hid_hw_stop(hdev);
+	return ret;
+}
+
+static void legion_remove(struct hid_device *hdev)
+{
+	struct legion_kbd *kbd = hid_get_drvdata(hdev);
+
+	/* hid-core no longer calls legion_raw_event(): the LED can go. */
+	led_classdev_unregister(&kbd->led);
+	hid_hw_close(hdev);
+	hid_hw_stop(hdev);
+}
+
+static const struct hid_device_id legion_devices[] = {
+	{ HID_USB_DEVICE(USB_VENDOR_ID_ITE, USB_DEVICE_ID_ITE_LENOVO_LEGION_GEN10_KBD) },
+	{ }
+};
+MODULE_DEVICE_TABLE(hid, legion_devices);
+
+static struct hid_driver legion_driver = {
+	.name = "hid-lenovo-legion",
+	.id_table = legion_devices,
+	.probe = legion_probe,
+	.remove = legion_remove,
+	.raw_event = legion_raw_event,
+};
+module_hid_driver(legion_driver);
+
+MODULE_AUTHOR("Ciro Pedrini <ciro.pedrini@gmail.com>");
+MODULE_DESCRIPTION("Keyboard backlight of Lenovo Legion laptops (2025)");
+MODULE_LICENSE("GPL");

-- 
2.56.0

