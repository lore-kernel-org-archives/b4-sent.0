From: Erlend Jacobsen <erlendjacobsen@pm.me>
Date: Mon, 23 Nov 2026 16:49:30 +0100
Subject: [PATCH v2] HID: rdmctmzt: add RDMCTMZT keyboard battery driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-rdmctmzt-v2-1-8c18d7dac4bc@pm.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/23NQQ6CMBCF4as0s6bGmSIBVt7DsAA6lZoUSFuJS
 np3U9y6fMmf7+0Q2FsO0IodPG822GWGVlAhYJz6+c7SamgF0JkqRCI5lNJrN0b3ibLCplG91sS
 GoBCwejb2dWi37rfDc3jwGDORi8mGuPj3cbdh7v7LG0qUurzUtWI0rNR1dSfH0KWUviMXKYq0A
 AAA
X-Change-ID: 20261122-b4-rdmctmzt-61993add2ef2
To: linux-input@vger.kernel.org
Cc: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>, 
 linux-kernel@vger.kernel.org, Erlend Jacobsen <erlendjacobsen@pm.me>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795448969; l=25449;
 i=erlendjacobsen@pm.me; s=20261122; h=from:subject:message-id;
 bh=+p7o13s39A2nxHpwELaGH1o6VCOb7lRVOe5srtrwbQ0=;
 b=pRkZc11cKLghx9mKJB+EXfMQK6QNIdu75TNOUjuw9h93ssgyYG5JilRNSmldJVIfPsHRkjER8
 upR9zeR6aCwA/DkE/IUiBbd7rKloUzicIafC4YJqfDGEp1lGLGbBeL6
X-Developer-Key: i=erlendjacobsen@pm.me; a=ed25519;
 pk=SkKXYooGBruZNtA629wl2v9ZJA3VdxTcmrehQAecfrc=
X-Endpoint-Received: by B4 Relay for erlendjacobsen@pm.me/20261122 with auth_id=1609
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Keyboards with the USB vendor ID 0x36b0 (manufacturer string
"RDMCTMZT"), such as the Focus Lab CTRL87, report their battery level
only on a vendor channel: the HID interface with the raw-HID application
collection (usage page 0xff60, usage 0x61). The 2.4 GHz dongle (0x2002)
forwards the query to the keyboard over the air; the keyboard (0x2009)
answers it directly over USB. The query is a request/response session,
so neither hid-input's battery strength usage nor a report descriptor
fixup can expose it.

Query the battery once a minute (session start 0xaa 0x10, battery status
0xaa 0x30, session end 0xaa 0x11) and register a device-scope
power_supply once the keyboard has answered, so that user space does not
see a battery whose capacity cannot be read. A lost answer is retried
after 5 s; the battery is marked not present after three polls in a row
without the battery status, or at once when the dongle reports no link.
The battery is named after the USB product ID and serial number, as
hid-asus does, so that its name survives a replug; the keyboard and its
dongle share a serial number.

On the dongle, also read its link status (0xaa 0xd0), which it sends by
itself on each link change, and report the link as the USB interface's
wireless_status, as hid-logitech-hidpp and hid-corsair-void do. Byte 13
of that report is 0x02 while the dongle has no link, but no other value
proves an active link (the dongle with bcdDevice 0x0102 reports 0x00
both when connected and when no connection has succeeded since
power-up), so the link is taken as up only once the keyboard answers.

All other interfaces are handled as by hid-generic.

Tested with keyboard firmware 1.13 over USB and through the dongle
(bcdDevice 0x0102 and 0x0105), including a switch between the two and
the vendor's WebHID configurator in use on the same interface; and
through the dongle with an open-source keyboard firmware: module reload,
replug and system suspend/resume.

Signed-off-by: Erlend Jacobsen <erlendjacobsen@pm.me>
---
Known dongle issue, not handled by the driver: a USB reset while the dongle
(bcdDevice 0x0102 and 0x0105) holds an unread report on its vendor
interface stops that interface until the dongle is replugged; keys still
work.
---
Changes in v2:
- End the polling only on the driver's own stop (-ESHUTDOWN); any
  transport error, -ENODEV included, is a lost poll (Sashiko review).
- Reset the poll counters while the dongle reports no link, so a
  reconnected keyboard is retried after 5 s, not 60 s (Sashiko review).
- Link to v1: https://patch.msgid.link/20261122-b4-rdmctmzt-v1-1-d45883e1fe33@pm.me
---
 MAINTAINERS                |   6 +
 drivers/hid/Kconfig        |  12 +
 drivers/hid/Makefile       |   1 +
 drivers/hid/hid-ids.h      |   4 +
 drivers/hid/hid-rdmctmzt.c | 657 +++++++++++++++++++++++++++++++++++++++++++++
 5 files changed, 680 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 4a69da715c58..d3adacc5053f 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -11703,6 +11703,12 @@ L:	linux-input@vger.kernel.org
 S:	Maintained
 F:	drivers/hid/hid-pulsar.c
 
+HID RDMCTMZT DRIVER
+M:	Erlend Jacobsen <erlendjacobsen@pm.me>
+L:	linux-input@vger.kernel.org
+S:	Maintained
+F:	drivers/hid/hid-rdmctmzt.c
+
 HID SENSOR HUB DRIVERS
 M:	Jiri Kosina <jikos@kernel.org>
 M:	Jonathan Cameron <jic23@kernel.org>
diff --git a/drivers/hid/Kconfig b/drivers/hid/Kconfig
index d17d960ab5e2..c3aeee7e71db 100644
--- a/drivers/hid/Kconfig
+++ b/drivers/hid/Kconfig
@@ -1105,6 +1105,18 @@ config HID_RAZER
 	Support for Razer devices that are not fully compliant with the
 	HID standard.
 
+config HID_RDMCTMZT
+	tristate "RDMCTMZT keyboards and 2.4 GHz dongles"
+	depends on USB_HID
+	select POWER_SUPPLY
+	help
+	  Support for the battery level and wireless link status of RDMCTMZT
+	  keyboards (USB vendor ID 0x36b0), such as the Focus Lab CTRL87,
+	  over USB and through their 2.4 GHz dongle.
+
+	  To compile this driver as a module, choose M here: the
+	  module will be called hid-rdmctmzt.
+
 config HID_PRIMAX
 	tristate "Primax non-fully HID-compliant devices"
 	help
diff --git a/drivers/hid/Makefile b/drivers/hid/Makefile
index dc30faaac969..d0ca9933eb95 100644
--- a/drivers/hid/Makefile
+++ b/drivers/hid/Makefile
@@ -123,6 +123,7 @@ obj-$(CONFIG_HID_PXRC)		+= hid-pxrc.o
 obj-$(CONFIG_HID_RAKK)		+= hid-rakk.o
 obj-$(CONFIG_HID_RAPOO) += hid-rapoo.o
 obj-$(CONFIG_HID_RAZER)	+= hid-razer.o
+obj-$(CONFIG_HID_RDMCTMZT)	+= hid-rdmctmzt.o
 obj-$(CONFIG_HID_REDRAGON)	+= hid-redragon.o
 obj-$(CONFIG_HID_RETRODE)	+= hid-retrode.o
 obj-$(CONFIG_HID_ROCCAT)	+= hid-roccat.o hid-roccat-common.o \
diff --git a/drivers/hid/hid-ids.h b/drivers/hid/hid-ids.h
index c40d818417a2..59549ff57583 100644
--- a/drivers/hid/hid-ids.h
+++ b/drivers/hid/hid-ids.h
@@ -1275,6 +1275,10 @@
 #define USB_DEVICE_ID_RAZER_BLACKWIDOW_CLASSIC    0x011b
 #define USB_DEVICE_ID_RAZER_BLADE_14   0x011D
 
+#define USB_VENDOR_ID_RDMCTMZT			0x36b0
+#define USB_DEVICE_ID_RDMCTMZT_DONGLE		0x2002
+#define USB_DEVICE_ID_RDMCTMZT_CTRL87		0x2009
+
 #define USB_VENDOR_ID_REALTEK		0x0bda
 #define USB_DEVICE_ID_REALTEK_READER	0x0152
 
diff --git a/drivers/hid/hid-rdmctmzt.c b/drivers/hid/hid-rdmctmzt.c
new file mode 100644
index 000000000000..cad89c22577d
--- /dev/null
+++ b/drivers/hid/hid-rdmctmzt.c
@@ -0,0 +1,657 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * HID driver for RDMCTMZT keyboards and their 2.4 GHz dongles (USB vendor
+ * ID 0x36b0): the battery level.
+ *
+ * The keyboard firmware answers a battery query on its vendor channel, the
+ * HID interface with the raw-HID application collection (usage page 0xff60,
+ * usage 0x61, no report IDs): 32-byte reports on the dongle, 64-byte reports
+ * on the keyboard over USB. The dongle passes the query to the keyboard over
+ * the air and the answer back.
+ *
+ * Every request and answer starts with 0xaa and the command byte:
+ *   0x10  start a session; other commands are only answered within one
+ *   0x30  battery status
+ *   0x11  end the session
+ * Byte 4 of a request is the report size. An answer repeats the request up to
+ * byte 6; byte 7 is 0x55 when the command was carried out (0x0f when it was
+ * refused, for instance before the keyboard has measured its battery). The
+ * battery status has the charge (0-100 %) in byte 8 and the charger state in
+ * byte 9 (0 on battery, 1 charging, 2 full).
+ *
+ * The dongle answers 0xd0 itself, and sends one by itself when its link state
+ * changes: byte 13 is 0x02 while it has no link to the keyboard (keyboard off,
+ * or on USB). Any other value does not prove a link: dongle firmware 0x0102
+ * reports 0x00 when connected, after a failed reconnect, and when the keyboard
+ * has never connected since power-up. So the driver takes the link as up only
+ * once the keyboard answers, and as down when byte 13 is 0x02 or after
+ * RDM_MAX_FAILS polls without any answer. It reports this as the USB
+ * interface's wireless_status, so user space hides the battery of a keyboard
+ * that is not connected.
+ *
+ * A lost answer does not hide the battery: it is retried after RDM_RETRY_MS,
+ * and the battery is marked not present only after RDM_MAX_FAILS polls in a
+ * row without the battery status, or at once when the dongle reports no link.
+ */
+
+#include <linux/cleanup.h>
+#include <linux/completion.h>
+#include <linux/device.h>
+#include <linux/hid.h>
+#include <linux/jiffies.h>
+#include <linux/limits.h>
+#include <linux/minmax.h>
+#include <linux/module.h>
+#include <linux/power_supply.h>
+#include <linux/slab.h>
+#include <linux/spinlock.h>
+#include <linux/string.h>
+#include <linux/usb.h>
+#include <linux/workqueue.h>
+
+#include "hid-ids.h"
+
+#define RDM_VENDOR_USAGE		0xff600061
+#define RDM_VENDOR_PREFIX		"RDMCTMZT "
+
+#define RDM_PREFIX			0xaa
+#define RDM_CMD_START			0x10
+#define RDM_CMD_STOP			0x11
+#define RDM_CMD_BATTERY			0x30
+/* The dongle's own link status, sent when the link changes */
+#define RDM_DONGLE_STATUS		0xd0
+
+#define RDM_PREFIX_BYTE			0
+#define RDM_CMD_BYTE			1
+#define RDM_SIZE_BYTE			4
+#define RDM_STATUS_BYTE			7
+#define RDM_CAPACITY_BYTE		8
+#define RDM_CHARGE_BYTE			9
+#define RDM_LINK_BYTE			13
+#define RDM_ANSWER_LEN			(RDM_LINK_BYTE + 1)
+
+#define RDM_STATUS_OK			0x55
+#define RDM_MAX_CAPACITY		100
+
+#define RDM_LINK_NONE			0x02
+#define RDM_LINK_UNKNOWN		0xff
+
+enum rdm_charge_state {
+	RDM_CHARGE_DISCHARGING	= 0,
+	RDM_CHARGE_CHARGING	= 1,
+	RDM_CHARGE_FULL		= 2,
+};
+
+/* Over the air an answer takes up to two connection events of 100 ms */
+#define RDM_TIMEOUT_MS			1000
+#define RDM_FIRST_POLL_MS		2000
+/* After a poll without the battery status */
+#define RDM_RETRY_MS			5000
+/* While the dongle's link byte allows a link, but the keyboard is silent */
+#define RDM_SEARCH_MS			10000
+#define RDM_POLL_MS			60000
+#define RDM_MAX_FAILS			3
+
+struct rdm_device {
+	struct hid_device *hdev;
+	const char *model_name;
+	/* Registered once the keyboard first answers */
+	struct power_supply *battery;
+	struct power_supply_desc battery_desc;
+	struct delayed_work work;
+	struct completion done;
+	/* The dongle: report the radio link as wireless_status */
+	bool dongle;
+	/*
+	 * Protects expect, answer, link, present, status, capacity,
+	 * and stopping.
+	 */
+	spinlock_t lock;
+	u8 *buf;
+	size_t len;
+	u8 expect;
+	u8 answer[RDM_ANSWER_LEN];
+	/* Byte 13 of the dongle's last 0xd0 */
+	u8 link;
+	bool present;
+	int status;
+	u8 capacity;
+	bool stopping;
+	/* Only used by the work; both count only polls with a link */
+	unsigned int fails;	/* polls in a row without the battery status */
+	unsigned int silent;	/* polls in a row without any answer */
+	enum usb_wireless_status wireless;
+};
+
+static const enum power_supply_property rdm_battery_props[] = {
+	POWER_SUPPLY_PROP_PRESENT,
+	POWER_SUPPLY_PROP_STATUS,
+	POWER_SUPPLY_PROP_CAPACITY,
+	POWER_SUPPLY_PROP_SCOPE,
+	POWER_SUPPLY_PROP_MODEL_NAME,
+	POWER_SUPPLY_PROP_MANUFACTURER,
+};
+
+static int rdm_battery_get_property(struct power_supply *psy,
+				    enum power_supply_property psp,
+				    union power_supply_propval *val)
+{
+	struct rdm_device *rdm = power_supply_get_drvdata(psy);
+
+	switch (psp) {
+	case POWER_SUPPLY_PROP_PRESENT:
+		scoped_guard(spinlock_irqsave, &rdm->lock)
+			val->intval = rdm->present;
+		return 0;
+	case POWER_SUPPLY_PROP_STATUS:
+		scoped_guard(spinlock_irqsave, &rdm->lock)
+			val->intval = rdm->present ? rdm->status :
+						     POWER_SUPPLY_STATUS_UNKNOWN;
+		return 0;
+	case POWER_SUPPLY_PROP_CAPACITY:
+		scoped_guard(spinlock_irqsave, &rdm->lock) {
+			if (!rdm->present)
+				return -ENODATA;
+			val->intval = rdm->capacity;
+		}
+		return 0;
+	case POWER_SUPPLY_PROP_SCOPE:
+		val->intval = POWER_SUPPLY_SCOPE_DEVICE;
+		return 0;
+	case POWER_SUPPLY_PROP_MODEL_NAME:
+		val->strval = rdm->model_name;
+		return 0;
+	case POWER_SUPPLY_PROP_MANUFACTURER:
+		val->strval = "RDMCTMZT";
+		return 0;
+	default:
+		return -EINVAL;
+	}
+}
+
+/* Only 0x02 rules out a link; the keyboard's answers decide the rest */
+static bool rdm_link_may_be_up(u8 link)
+{
+	return link != RDM_LINK_NONE && link != RDM_LINK_UNKNOWN;
+}
+
+static int rdm_decode_status(struct rdm_device *rdm, u8 charge)
+{
+	switch (charge) {
+	case RDM_CHARGE_DISCHARGING:
+		return POWER_SUPPLY_STATUS_DISCHARGING;
+	case RDM_CHARGE_CHARGING:
+		return POWER_SUPPLY_STATUS_CHARGING;
+	case RDM_CHARGE_FULL:
+		return POWER_SUPPLY_STATUS_FULL;
+	default:
+		hid_dbg(rdm->hdev, "unknown charger state: %u\n", charge);
+		return POWER_SUPPLY_STATUS_UNKNOWN;
+	}
+}
+
+/* Send one command; its answer arrives in rdm_raw_event() */
+static int rdm_send(struct rdm_device *rdm, u8 cmd)
+{
+	size_t raw_len = rdm->len + 1;
+	int ret;
+
+	memset(rdm->buf, 0, raw_len);
+	rdm->buf[0] = 0x00; /* unnumbered report ID */
+	rdm->buf[1 + RDM_PREFIX_BYTE] = RDM_PREFIX;
+	rdm->buf[1 + RDM_CMD_BYTE] = cmd;
+	rdm->buf[1 + RDM_SIZE_BYTE] = rdm->len;
+
+	ret = hid_hw_output_report(rdm->hdev, rdm->buf, raw_len);
+	/*
+	 * -ESHUTDOWN from the transport (an endpoint flushed by a USB reset)
+	 * is a lost poll; only rdm->stopping may end the polling.
+	 */
+	if (ret == -ESHUTDOWN)
+		return -EIO;
+	if (ret < 0)
+		return ret;
+	if (ret != raw_len)
+		return -EIO;
+
+	return 0;
+}
+
+/*
+ * Send one command and wait for its answer: 0 once it is copied into @reply
+ * (carried out or refused, checked via RDM_STATUS_BYTE).
+ */
+static int rdm_command(struct rdm_device *rdm, u8 cmd, u8 *reply)
+{
+	long time_left;
+	int ret;
+
+	scoped_guard(spinlock_irqsave, &rdm->lock) {
+		if (rdm->stopping)
+			return -ESHUTDOWN;
+		rdm->expect = cmd;
+		rdm->answer[RDM_CMD_BYTE] = 0;
+		reinit_completion(&rdm->done);
+	}
+
+	ret = rdm_send(rdm, cmd);
+	if (ret)
+		goto out_clear;
+
+	time_left = wait_for_completion_interruptible_timeout(&rdm->done,
+							      msecs_to_jiffies(RDM_TIMEOUT_MS));
+	if (time_left <= 0) {
+		ret = time_left ? (int)time_left : -ETIMEDOUT;
+		goto out_clear;
+	}
+
+	scoped_guard(spinlock_irqsave, &rdm->lock) {
+		rdm->expect = 0;
+		if (rdm->stopping)
+			return -ESHUTDOWN;
+		if (rdm->answer[RDM_CMD_BYTE] != cmd)
+			return -ENOLINK;
+		memcpy(reply, rdm->answer, RDM_ANSWER_LEN);
+	}
+	return 0;
+
+out_clear:
+	scoped_guard(spinlock_irqsave, &rdm->lock) {
+		rdm->expect = 0;
+		if (rdm->stopping)
+			ret = -ESHUTDOWN;
+	}
+	return ret;
+}
+
+/*
+ * Register the battery once the keyboard has answered: user space (UPower)
+ * ignores a device battery whose capacity cannot be read when it appears.
+ * Without an answer (the dongle with the keyboard on USB) there is none.
+ */
+static void rdm_battery_register(struct rdm_device *rdm)
+{
+	struct power_supply_config cfg = { .drv_data = rdm };
+	struct power_supply *battery;
+	int ret;
+
+	battery = devm_power_supply_register(&rdm->hdev->dev,
+					     &rdm->battery_desc, &cfg);
+	if (IS_ERR(battery)) {
+		hid_err_ratelimited(rdm->hdev,
+				    "cannot register the battery: %pe\n",
+				    battery);
+		return;
+	}
+
+	ret = power_supply_powers(battery, &rdm->hdev->dev);
+	if (ret)
+		hid_warn(rdm->hdev, "cannot link battery to device: %d\n", ret);
+
+	rdm->battery = battery;
+}
+
+/* The dongle's link byte, asked for now: an 0xd0 may have been missed */
+static int rdm_dongle_linked(struct rdm_device *rdm, bool *linked)
+{
+	u8 reply[RDM_ANSWER_LEN];
+	int ret;
+
+	ret = rdm_command(rdm, RDM_DONGLE_STATUS, reply);
+	if (ret == -ESHUTDOWN)
+		return ret;
+
+	scoped_guard(spinlock_irqsave, &rdm->lock) {
+		if (!ret)
+			rdm->link = reply[RDM_LINK_BYTE];
+		*linked = rdm_link_may_be_up(rdm->link);
+	}
+	if (ret)
+		hid_dbg(rdm->hdev, "no link status: %d\n", ret);
+	return 0;
+}
+
+static int rdm_poll_keyboard(struct rdm_device *rdm, bool *linked,
+			     bool *answered, bool *got, u8 *capacity,
+			     int *status)
+{
+	u8 reply[RDM_ANSWER_LEN];
+	int ret;
+
+	ret = rdm_command(rdm, RDM_CMD_START, reply);
+	if (ret == -ESHUTDOWN)
+		return ret;
+	if (ret == -ENOLINK) {
+		*linked = false;
+		return 0;
+	}
+	if (ret)
+		return 0;
+
+	/* Any answer, even a refusal, shows that the keyboard is linked */
+	*answered = true;
+	if (reply[RDM_STATUS_BYTE] == RDM_STATUS_OK) {
+		ret = rdm_command(rdm, RDM_CMD_BATTERY, reply);
+		if (ret == -ESHUTDOWN)
+			return ret;
+		if (ret == -ENOLINK) {
+			*linked = false;
+			return 0;
+		}
+		if (!ret && reply[RDM_STATUS_BYTE] == RDM_STATUS_OK) {
+			*got = true;
+			*capacity = min_t(u8, reply[RDM_CAPACITY_BYTE],
+					  RDM_MAX_CAPACITY);
+			*status = rdm_decode_status(rdm, reply[RDM_CHARGE_BYTE]);
+		}
+	}
+
+	ret = rdm_command(rdm, RDM_CMD_STOP, reply);
+	if (ret == -ESHUTDOWN)
+		return ret;
+	if (ret == -ENOLINK)
+		*linked = false;
+
+	return 0;
+}
+
+static void rdm_battery_work(struct work_struct *work)
+{
+	struct rdm_device *rdm = container_of(to_delayed_work(work),
+					      struct rdm_device, work);
+	enum usb_wireless_status wireless = rdm->wireless;
+	bool linked = true, answered = false, got = false;
+	bool changed, present;
+	unsigned int delay;
+	u8 capacity = 0;
+	int status = 0;
+
+	if (rdm->dongle && rdm_dongle_linked(rdm, &linked))
+		return;
+
+	if (linked && rdm_poll_keyboard(rdm, &linked, &answered, &got,
+					&capacity, &status))
+		return;
+
+	if (!got)
+		hid_dbg(rdm->hdev, "no battery status (linked %d, answered %d)\n",
+			linked, answered);
+
+	if (!linked) {
+		/* A keyboard that comes back starts with fresh counts */
+		rdm->silent = 0;
+		rdm->fails = 0;
+		wireless = USB_WIRELESS_STATUS_DISCONNECTED;
+	} else {
+		rdm->silent = answered ? 0 : min(rdm->silent + 1, RDM_MAX_FAILS);
+		rdm->fails = got ? 0 : min(rdm->fails + 1, RDM_MAX_FAILS);
+		if (answered)
+			wireless = USB_WIRELESS_STATUS_CONNECTED;
+		else if (rdm->silent >= RDM_MAX_FAILS ||
+			 rdm->wireless == USB_WIRELESS_STATUS_NA)
+			wireless = USB_WIRELESS_STATUS_DISCONNECTED;
+	}
+
+	/* Without a link the dongle reports when it comes back */
+	if (got || !linked)
+		delay = RDM_POLL_MS;
+	else if (rdm->fails < RDM_MAX_FAILS)
+		delay = RDM_RETRY_MS;
+	else if (rdm->dongle && rdm->silent >= RDM_MAX_FAILS)
+		delay = RDM_SEARCH_MS;
+	else
+		delay = RDM_POLL_MS;
+
+	scoped_guard(spinlock_irqsave, &rdm->lock) {
+		if (rdm->stopping)
+			return;
+		present = linked &&
+			  (got || (rdm->present && rdm->fails < RDM_MAX_FAILS));
+		changed = rdm->present != present ||
+			  (got && (rdm->capacity != capacity ||
+				   rdm->status != status));
+		rdm->present = present;
+		if (got) {
+			rdm->capacity = capacity;
+			rdm->status = status;
+		}
+		queue_delayed_work(system_dfl_wq, &rdm->work,
+				   msecs_to_jiffies(delay));
+	}
+
+	if (rdm->dongle && wireless != rdm->wireless) {
+		rdm->wireless = wireless;
+		usb_set_wireless_status(to_usb_interface(rdm->hdev->dev.parent),
+					wireless);
+	}
+
+	if (present && got && !rdm->battery)
+		rdm_battery_register(rdm);
+	else if (changed && rdm->battery)
+		power_supply_changed(rdm->battery);
+}
+
+static int rdm_raw_event(struct hid_device *hdev, struct hid_report *report,
+			 u8 *data, int size)
+{
+	struct rdm_device *rdm = hid_get_drvdata(hdev);
+
+	if (!rdm || size < RDM_ANSWER_LEN || data[RDM_PREFIX_BYTE] != RDM_PREFIX)
+		return 0;
+
+	guard(spinlock_irqsave)(&rdm->lock);
+	if (rdm->expect && data[RDM_CMD_BYTE] == rdm->expect) {
+		memcpy(rdm->answer, data, RDM_ANSWER_LEN);
+		rdm->expect = 0;
+		complete(&rdm->done);
+	} else if (data[RDM_CMD_BYTE] == RDM_DONGLE_STATUS && rdm->dongle &&
+		   data[RDM_LINK_BYTE] != rdm->link) {
+		/* The link to the keyboard came or went: ask now */
+		rdm->link = data[RDM_LINK_BYTE];
+		if (rdm->expect && !rdm_link_may_be_up(rdm->link)) {
+			rdm->expect = 0;
+			complete(&rdm->done);
+		}
+		if (!rdm->stopping)
+			mod_delayed_work(system_dfl_wq, &rdm->work, 0);
+	}
+	return 0;
+}
+
+static bool rdm_is_vendor_interface(struct hid_device *hdev)
+{
+	for (unsigned int i = 0; i < hdev->maxcollection; i++) {
+		if (hdev->collection[i].type == HID_COLLECTION_APPLICATION &&
+		    hdev->collection[i].usage == RDM_VENDOR_USAGE)
+			return true;
+	}
+	return false;
+}
+
+/* End the work and any wait; rdm_resume_common() restarts it */
+static void rdm_stop_polling(struct rdm_device *rdm)
+{
+	scoped_guard(spinlock_irqsave, &rdm->lock) {
+		rdm->stopping = true;
+		complete_all(&rdm->done);
+	}
+	cancel_delayed_work_sync(&rdm->work);
+}
+
+static int rdm_probe(struct hid_device *hdev, const struct hid_device_id *id)
+{
+	struct hid_report *report_in, *report_out;
+	struct rdm_device *rdm;
+	size_t prefix_len;
+	u32 report_len;
+	int ret;
+
+	hdev->quirks |= HID_QUIRK_INPUT_PER_APP;
+
+	ret = hid_parse(hdev);
+	if (ret)
+		return ret;
+
+	/* Only the vendor interface has the query; the others work as usual */
+	if (!rdm_is_vendor_interface(hdev))
+		return hid_hw_start(hdev, HID_CONNECT_DEFAULT);
+
+	report_in = hdev->report_enum[HID_INPUT_REPORT].report_id_hash[0];
+	report_out = hdev->report_enum[HID_OUTPUT_REPORT].report_id_hash[0];
+	if (!report_in || !report_out ||
+	    hdev->report_enum[HID_INPUT_REPORT].numbered ||
+	    hdev->report_enum[HID_OUTPUT_REPORT].numbered) {
+		hid_warn(hdev, "missing unnumbered vendor reports\n");
+		return hid_hw_start(hdev, HID_CONNECT_DEFAULT);
+	}
+
+	report_len = hid_report_len(report_out);
+	if (hid_report_len(report_in) < RDM_ANSWER_LEN ||
+	    report_len < RDM_ANSWER_LEN || report_len > U8_MAX) {
+		hid_warn(hdev, "unexpected vendor report length\n");
+		return hid_hw_start(hdev, HID_CONNECT_DEFAULT);
+	}
+
+	rdm = devm_kzalloc(&hdev->dev, sizeof(*rdm), GFP_KERNEL);
+	if (!rdm)
+		return -ENOMEM;
+
+	rdm->len = report_len;
+	/* Leading byte 0 holds the unnumbered report ID (0x00) */
+	rdm->buf = devm_kzalloc(&hdev->dev, rdm->len + 1, GFP_KERNEL);
+	if (!rdm->buf)
+		return -ENOMEM;
+
+	rdm->hdev = hdev;
+	prefix_len = str_has_prefix(hdev->name, RDM_VENDOR_PREFIX);
+	rdm->model_name = hdev->name[prefix_len] ? hdev->name + prefix_len :
+						   hdev->name;
+	rdm->dongle = hid_is_usb(hdev) &&
+		      hdev->product == USB_DEVICE_ID_RDMCTMZT_DONGLE;
+	rdm->link = RDM_LINK_UNKNOWN;
+	rdm->wireless = USB_WIRELESS_STATUS_NA;
+	spin_lock_init(&rdm->lock);
+	init_completion(&rdm->done);
+	INIT_DELAYED_WORK(&rdm->work, rdm_battery_work);
+
+	/*
+	 * Name the battery after the USB product ID and serial number, as
+	 * hid-asus does: the HID device name changes with every replug, and
+	 * user space keeps per-battery settings by name. The keyboard and its
+	 * dongle share a serial number, so the product ID keeps them apart.
+	 */
+	if (hdev->uniq[0])
+		rdm->battery_desc.name = devm_kasprintf(&hdev->dev, GFP_KERNEL,
+							"rdmctmzt-%04x-%s-battery",
+							hdev->product, hdev->uniq);
+	else
+		rdm->battery_desc.name = devm_kasprintf(&hdev->dev, GFP_KERNEL,
+							"rdmctmzt-%s-battery",
+							dev_name(&hdev->dev));
+	if (!rdm->battery_desc.name)
+		return -ENOMEM;
+
+	rdm->battery_desc.type = POWER_SUPPLY_TYPE_BATTERY;
+	rdm->battery_desc.properties = rdm_battery_props;
+	rdm->battery_desc.num_properties = ARRAY_SIZE(rdm_battery_props);
+	rdm->battery_desc.get_property = rdm_battery_get_property;
+
+	hid_set_drvdata(hdev, rdm);
+
+	ret = hid_hw_start(hdev, HID_CONNECT_DEFAULT);
+	if (ret)
+		goto err_clear_drvdata;
+
+	/* Answers arrive as input reports, so keep the interface open */
+	ret = hid_hw_open(hdev);
+	if (ret)
+		goto err_stop;
+
+	queue_delayed_work(system_dfl_wq, &rdm->work,
+			   msecs_to_jiffies(RDM_FIRST_POLL_MS));
+	return 0;
+
+err_stop:
+	/* A dongle status may already have queued the work */
+	rdm_stop_polling(rdm);
+	hid_hw_stop(hdev);
+err_clear_drvdata:
+	hid_set_drvdata(hdev, NULL);
+	return ret;
+}
+
+static void rdm_remove(struct hid_device *hdev)
+{
+	struct rdm_device *rdm = hid_get_drvdata(hdev);
+
+	if (rdm) {
+		rdm_stop_polling(rdm);
+		if (rdm->dongle && rdm->wireless != USB_WIRELESS_STATUS_NA)
+			usb_set_wireless_status(to_usb_interface(hdev->dev.parent),
+						USB_WIRELESS_STATUS_NA);
+		hid_hw_close(hdev);
+	}
+	hid_hw_stop(hdev);
+}
+
+static int rdm_suspend(struct hid_device *hdev, pm_message_t message)
+{
+	struct rdm_device *rdm = hid_get_drvdata(hdev);
+
+	if (rdm)
+		rdm_stop_polling(rdm);
+	return 0;
+}
+
+static int rdm_resume_common(struct hid_device *hdev, bool reset)
+{
+	struct rdm_device *rdm = hid_get_drvdata(hdev);
+
+	if (!rdm)
+		return 0;
+
+	scoped_guard(spinlock_irqsave, &rdm->lock) {
+		rdm->stopping = false;
+		if (reset)
+			rdm->link = RDM_LINK_UNKNOWN;
+		queue_delayed_work(system_dfl_wq, &rdm->work, 0);
+	}
+	return 0;
+}
+
+static int rdm_resume(struct hid_device *hdev)
+{
+	return rdm_resume_common(hdev, false);
+}
+
+static int rdm_reset_resume(struct hid_device *hdev)
+{
+	if (hdev->claimed & HID_CLAIMED_INPUT)
+		hidinput_reset_resume(hdev);
+
+	return rdm_resume_common(hdev, true);
+}
+
+static const struct hid_device_id rdm_devices[] = {
+	{ HID_USB_DEVICE(USB_VENDOR_ID_RDMCTMZT,
+			 USB_DEVICE_ID_RDMCTMZT_DONGLE) },
+	{ HID_USB_DEVICE(USB_VENDOR_ID_RDMCTMZT,
+			 USB_DEVICE_ID_RDMCTMZT_CTRL87) },
+	{ }
+};
+MODULE_DEVICE_TABLE(hid, rdm_devices);
+
+static struct hid_driver rdm_driver = {
+	.name = "rdmctmzt",
+	.id_table = rdm_devices,
+	.probe = rdm_probe,
+	.remove = rdm_remove,
+	.raw_event = rdm_raw_event,
+	.suspend = pm_ptr(rdm_suspend),
+	.resume = pm_ptr(rdm_resume),
+	.reset_resume = pm_ptr(rdm_reset_resume),
+};
+module_hid_driver(rdm_driver);
+
+MODULE_DESCRIPTION("HID driver for RDMCTMZT keyboards: battery level and link status");
+MODULE_LICENSE("GPL");

---
base-commit: 4a30b295fc34467e0468a0c8aeef73ecbe876d07
change-id: 20261122-b4-rdmctmzt-61993add2ef2

Best regards,
--  
Erlend Jacobsen <erlendjacobsen@pm.me>

