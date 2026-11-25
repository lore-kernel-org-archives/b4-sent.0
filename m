From: Alexis Calin <alexiscalin@protonmail.com>
Date: Thu, 26 Nov 2026 00:06:12 +0100
Subject: [PATCH] platform/x86: panasonic-laptop: Support the hardware
 wireless switch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-panasonic-wireless-switch-v1-1-97f4e3a207da@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/x3MWwqDMBAF0K0M99sBk1If2Yr0I00ndUCiZKQWx
 L0XehZwTphUFUOgE1U+aroWBHINIc2xvIX1hUDwre+c83feYom2Fk18aJVFzNgO3dPMQ+zG/pb
 7/BwEDWGrkvX7v6fHdf0AQFGnEmsAAAA=
X-Change-ID: 20261125-panasonic-wireless-switch-8a6973f7fb8e
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Kenneth Chan <kenneth.t.chan@gmail.com>
Cc: Alex Yeo <alexyeo362@gmail.com>, platform-driver-x86@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Alexis Calin <alexiscalin@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795647990; l=10330;
 i=alexiscalin@protonmail.com; s=20261114; h=from:subject:message-id;
 bh=cpAQygnhRQC+zvGun1GukJAWmpC+SrBXmDzkX7bdkVc=;
 b=mAqfCFNP0Gw3eOpN7pzwsUMNIUKNhbfqx7rRgUirdxk3vmlFgdrRJSRUeX0mD0VXd4Ds6aNMA
 123GOROxdjmAnrF1wV2nsLLkQH85mExOlRzk9f5N4nQwn4dkU6k7Q4Z
X-Developer-Key: i=alexiscalin@protonmail.com; a=ed25519;
 pk=oNYBG1X8+3bGmJMn0tnt+BbJC1vI7dgqomx4pGPM+4c=
X-Endpoint-Received: by B4 Relay for alexiscalin@protonmail.com/20261114 with auth_id=1528
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Let's Note CF-SV7 has a hardware wireless switch and an ACPI device
MAT0028 ("WLSW"). When the switch is flipped, the firmware queues hotkey
index 0x50 on the HKEY device, which this driver reports as "Unknown
hotkey event: 0x0050". If a driver for MAT0028 is loaded, the vendor
ASL notifies that device instead; no such driver exists in Linux. The
firmware itself cuts Bluetooth but leaves Wi-Fi on, so under Linux the
switch only turns Bluetooth off.

The switch position is available as SINF[0x0B]: the firmware returns
0xC0 when the radios are enabled and 0x80 when they are disabled (vendor
HKEY.SGET(0x0B), from an EC status bit). Bit 7 is used as a check that
the entry is a wireless switch, bit 6 as its position.

When MAT0028 is present and SINF[0x0B] has bit 7 set:
- register a read-only rfkill device whose hard block follows the
  switch, as dell-rbtn does for its slider; NetworkManager and GNOME,
  which take over rfkill handling from rfkill-input, honour it;
- report SW_RFKILL_ALL on the hotkey input device, for systems that
  rely on rfkill-input.
Both are updated at probe, on each 0x50 event and after resume.

SINF is now read before the input device is registered, because the
switch capability depends on it.

Tested on a CF-SV7 (BIOS V3.00L14) only, with this change backported to
Debian's 6.12.118: with GNOME and NetworkManager, Wi-Fi is disabled
while the switch is off and reconnects after it is switched back on,
and evtest shows SW_RFKILL_ALL following the switch.

Assisted-by: LLM
Signed-off-by: Alexis Calin <alexiscalin@protonmail.com>
---
Notes beyond the changelog:

A first version reported only SW_RFKILL_ALL. It had no effect on Wi-Fi
under GNOME, because gsd-rfkill disables rfkill-input and does not act on
the switch event; hence the rfkill hard block, as in dell-rbtn.

The meaning of SINF[0x0B] comes from the CF-SV7 DSDT (HKEY.SGET(0x0B),
WLSW/MAT0028). I checked that the EC status bit behind it (EC RAM 0xA6
bit 0, read with ec_sys) follows the switch, and that the driver, loaded
while the switch is off, starts with the rfkill device hard-blocked.

Built with W=1, with CONFIG_RFKILL=y and =n, on platform-drivers-x86
for-next. Not checked with sparse. checkpatch flags the Assisted-by
trailer as a non-standard signature.

The code and the changelog were drafted with an LLM coding assistant,
which also did the DSDT and firmware analysis behind them. I reviewed
the change and ran the tests on my machine.

Alex, Cc'ing you since you have several Let's Note models: if any of
them has a MAT0028 device, a test there would be very welcome. This is
independent of your pending platform_profile RFC, but both touch probe.
---
 drivers/platform/x86/Kconfig            |   1 +
 drivers/platform/x86/panasonic-laptop.c | 126 ++++++++++++++++++++++++++++++--
 2 files changed, 122 insertions(+), 5 deletions(-)

diff --git a/drivers/platform/x86/Kconfig b/drivers/platform/x86/Kconfig
index 78e39cafea91..6ee410f4d490 100644
--- a/drivers/platform/x86/Kconfig
+++ b/drivers/platform/x86/Kconfig
@@ -677,6 +677,7 @@ config PANASONIC_LAPTOP
 	depends on BACKLIGHT_CLASS_DEVICE
 	depends on ACPI_VIDEO=n || ACPI_VIDEO
 	depends on SERIO_I8042 || SERIO_I8042 = n
+	depends on RFKILL || RFKILL = n
 	select INPUT_SPARSEKMAP
 	help
 	  This driver adds support for access to backlight control and hotkeys
diff --git a/drivers/platform/x86/panasonic-laptop.c b/drivers/platform/x86/panasonic-laptop.c
index ef2ada1ba627..6d24dc0f8363 100644
--- a/drivers/platform/x86/panasonic-laptop.c
+++ b/drivers/platform/x86/panasonic-laptop.c
@@ -132,6 +132,7 @@
 #include <linux/kernel.h>
 #include <linux/module.h>
 #include <linux/platform_device.h>
+#include <linux/rfkill.h>
 #include <linux/seq_file.h>
 #include <linux/serio.h>
 #include <linux/slab.h>
@@ -157,6 +158,15 @@ MODULE_LICENSE("GPL");
 #define METHOD_HKEY_SSET	"SSET"
 #define METHOD_ECWR		"\\_SB.ECWR"
 #define HKEY_NOTIFY		0x80
+/*
+ * Hardware wireless switch (Let's Note models with a MAT0028 "WLSW" device,
+ * e.g. CF-SV7). Each flip queues hotkey index 0x50 and SINF[SINF_WIRELESS_SW]
+ * reports the position: bit 7 = switch present, bit 6 = radios on.
+ */
+#define PCC_WIRELESS_SW_HID	"MAT0028"
+#define PCC_WIRELESS_SW_KEY	0x50
+#define PCC_WIRELESS_SW_PRESENT	BIT(7)
+#define PCC_WIRELESS_SW_ON	BIT(6)
 #define ECO_MODE_OFF		0x00
 #define ECO_MODE_ON		0x80
 
@@ -178,6 +188,7 @@ enum SINF_BITS { SINF_NUM_BATTERIES = 0,
 		 SINF_MUTE,
 		 SINF_RESERVED,
 		 SINF_ECO_MODE = 0x0A,
+		 SINF_WIRELESS_SW = 0x0B,
 		 SINF_CUR_BRIGHT = 0x0D,
 		 SINF_STICKY_KEY = 0x80,
 	};
@@ -247,6 +258,8 @@ struct pcc_acpi {
 	int			ac_brightness;
 	int			dc_brightness;
 	int			current_brightness;
+	bool			has_wireless_sw;
+	struct rfkill		*wireless_sw_rfkill;
 	struct acpi_device	*device;
 	struct input_dev	*input_dev;
 	struct backlight_device	*backlight;
@@ -838,6 +851,85 @@ static const struct attribute_group pcc_attr_group = {
 
 /* hotkey input device driver */
 
+/* Returns 1 if the switch enables the radios, 0 if not, -errno on error. */
+static int acpi_pcc_wireless_sw_on(struct pcc_acpi *pcc)
+{
+	if (!acpi_pcc_retrieve_biosdata(pcc))
+		return -EIO;
+
+	return !!(pcc->sinf[SINF_WIRELESS_SW] & PCC_WIRELESS_SW_ON);
+}
+
+/*
+ * Report the switch position as the rfkill master switch (for rfkill-input)
+ * and as the hard block of a read-only rfkill device (for userspace that
+ * takes over rfkill handling, such as NetworkManager and GNOME). On the
+ * CF-SV7 the firmware does not cut the Wi-Fi radio itself.
+ */
+static void acpi_pcc_report_wireless_sw(struct pcc_acpi *pcc)
+{
+	int on;
+
+	if (!pcc->has_wireless_sw)
+		return;
+
+	on = acpi_pcc_wireless_sw_on(pcc);
+	if (on < 0)
+		return;
+
+	if (pcc->wireless_sw_rfkill)
+		rfkill_set_hw_state(pcc->wireless_sw_rfkill, !on);
+
+	input_report_switch(pcc->input_dev, SW_RFKILL_ALL, on);
+	input_sync(pcc->input_dev);
+}
+
+static int acpi_pcc_wireless_sw_set_block(void *data, bool blocked)
+{
+	/* the switch is read-only, it has no soft block */
+	return -EINVAL;
+}
+
+static const struct rfkill_ops acpi_pcc_wireless_sw_ops = {
+	.set_block = acpi_pcc_wireless_sw_set_block,
+};
+
+static void acpi_pcc_wireless_sw_rfkill_init(struct pcc_acpi *pcc)
+{
+	struct rfkill *rfkill;
+
+	if (!pcc->has_wireless_sw)
+		return;
+
+	/* the switch acts on all radios; rfkill has no "any" type, use WLAN */
+	rfkill = rfkill_alloc("panasonic-wireless-sw", &pcc->device->dev,
+			      RFKILL_TYPE_WLAN, &acpi_pcc_wireless_sw_ops, pcc);
+	if (IS_ERR_OR_NULL(rfkill))
+		return;
+
+	/* pcc->sinf was just read by probe */
+	rfkill_set_hw_state(rfkill,
+			    !(pcc->sinf[SINF_WIRELESS_SW] & PCC_WIRELESS_SW_ON));
+
+	if (rfkill_register(rfkill)) {
+		pr_warn("Couldn't register the wireless switch rfkill device\n");
+		rfkill_destroy(rfkill);
+		return;
+	}
+
+	pcc->wireless_sw_rfkill = rfkill;
+}
+
+static void acpi_pcc_wireless_sw_rfkill_exit(struct pcc_acpi *pcc)
+{
+	if (!pcc->wireless_sw_rfkill)
+		return;
+
+	rfkill_unregister(pcc->wireless_sw_rfkill);
+	rfkill_destroy(pcc->wireless_sw_rfkill);
+	pcc->wireless_sw_rfkill = NULL;
+}
+
 static int sleep_keydown_seen;
 static void acpi_pcc_generate_keyinput(struct pcc_acpi *pcc)
 {
@@ -857,6 +949,11 @@ static void acpi_pcc_generate_keyinput(struct pcc_acpi *pcc)
 	key = result & GENMASK(6, 0);
 	updown = result & BIT(7); /* 0x80 == key down; 0x00 = key up */
 
+	if (key == PCC_WIRELESS_SW_KEY && pcc->has_wireless_sw) {
+		acpi_pcc_report_wireless_sw(pcc);
+		return;
+	}
+
 	/* hack: some firmware sends no key down for sleep / hibernate */
 	if (key == 7 || key == 10) {
 		if (updown)
@@ -965,6 +1062,9 @@ static int acpi_pcc_init_input(struct pcc_acpi *pcc)
 		goto err_free_dev;
 	}
 
+	if (pcc->has_wireless_sw)
+		input_set_capability(input_dev, EV_SW, SW_RFKILL_ALL);
+
 	error = input_register_device(input_dev);
 	if (error) {
 		pr_err("Unable to register input device\n");
@@ -996,6 +1096,9 @@ static int acpi_pcc_hotkey_resume(struct device *dev)
 	if (pcc->num_sifr > SINF_CUR_BRIGHT)
 		acpi_pcc_write_sset(pcc, SINF_CUR_BRIGHT, pcc->current_brightness);
 
+	/* the switch may have been flipped while suspended */
+	acpi_pcc_report_wireless_sw(pcc);
+
 	return 0;
 }
 #endif
@@ -1039,17 +1142,24 @@ static int acpi_pcc_hotkey_probe(struct platform_device *pdev)
 	pcc->handle = device->handle;
 	device->driver_data = pcc;
 
+	/* read before the input device is set up: it decides the switch capability */
+	if (!acpi_pcc_retrieve_biosdata(pcc)) {
+		result = -EIO;
+		pr_err("Couldn't retrieve BIOS data\n");
+		goto out_hotkey;
+	}
+
+	pcc->has_wireless_sw = pcc->num_sifr > SINF_WIRELESS_SW &&
+			       (pcc->sinf[SINF_WIRELESS_SW] & PCC_WIRELESS_SW_PRESENT) &&
+			       acpi_dev_present(PCC_WIRELESS_SW_HID, NULL, -1);
+
 	result = acpi_pcc_init_input(pcc);
 	if (result) {
 		pr_err("Error installing keyinput handler\n");
 		goto out_hotkey;
 	}
 
-	if (!acpi_pcc_retrieve_biosdata(pcc)) {
-		result = -EIO;
-		pr_err("Couldn't retrieve BIOS data\n");
-		goto out_input;
-	}
+	acpi_pcc_report_wireless_sw(pcc);
 
 	if (acpi_video_get_backlight_type() == acpi_backlight_vendor) {
 		/* initialize backlight */
@@ -1110,6 +1220,9 @@ static int acpi_pcc_hotkey_probe(struct platform_device *pdev)
 	}
 
 	i8042_install_filter(panasonic_i8042_filter, NULL);
+
+	/* not fatal: the SW_RFKILL_ALL event still works without it */
+	acpi_pcc_wireless_sw_rfkill_init(pcc);
 	return 0;
 
 out_platform:
@@ -1146,6 +1259,9 @@ static void acpi_pcc_hotkey_remove(struct platform_device *pdev)
 	acpi_dev_remove_notify_handler(device, ACPI_DEVICE_NOTIFY,
 				       acpi_pcc_hotkey_notify);
 
+	/* after the notify handler is gone: switch events use the rfkill */
+	acpi_pcc_wireless_sw_rfkill_exit(pcc);
+
 	sysfs_remove_group(&device->dev.kobj, &pcc_attr_group);
 
 	backlight_device_unregister(pcc->backlight);

---
base-commit: 61c0dac952b9308884936d05cce97565a5c89af4
change-id: 20261125-panasonic-wireless-switch-8a6973f7fb8e

Best regards,
-- 
Alexis Calin <alexiscalin@protonmail.com>

