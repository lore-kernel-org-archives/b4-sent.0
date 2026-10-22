From: Sercan GOKMEN <gokmensercan@gmail.com>
Date: Thu, 22 Oct 2026 16:00:52 +0300
Subject: [PATCH] platform/x86: asus-wmi: Add keyboard backlight read-back
 quirk for ASUS ExpertBook Ultra B9406CAA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-b4-asus-wmi-b9406caa-kbd-readback-v1-1-fb33ed98dd16@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXNwQ6CMAyA4VchPdtkFCTMVzEeuq1qJaJZRUkI7
 87U43f5/wVMsorBoVogy1tNH2NBvasgXnm8CGoqBnLU1Y4IQ4tsk+Hnrhh867rIjENImIVT4Dg
 gS+rJ75vUNx5K55nlrPPvcTz9bVO4SXx9w7CuG/Khba2FAAAA
X-Change-ID: 20261022-b4-asus-wmi-b9406caa-kbd-readback-aed82953d839
To: Corentin Chary <corentin.chary@gmail.com>, 
 "Luke D. Jones" <luke@ljones.dev>, Denis Benato <denis.benato@linux.dev>, 
 Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sercan GOKMEN <gokmensercan@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792674051; l=5290;
 i=gokmensercan@gmail.com; s=20261022; h=from:subject:message-id;
 bh=fSTmrfZTjXJhJvDRdGbk0K/+rwI2QBECNtaYIr3fMRU=;
 b=QxmCus+1hrgSGoq6KlRU6n1u9s+4iePiNgCTGkltxKKVejqhos/B/9600VXxtAZJ019OftfT4
 a7biuSGhUQdAdxCD2n1EDzB/o3Cv1Ecz3leVubsy0yrtiz+dvVNfTZj
X-Developer-Key: i=gokmensercan@gmail.com; a=ed25519;
 pk=nFIlLCcGouUfBov8xxW0K4qUtEjdhJniMOO8WCSqghU=
X-Endpoint-Received: by B4 Relay for gokmensercan@gmail.com/20261022 with auth_id=1282
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the ASUS ExpertBook Ultra B9406CAA (BIOS 312) the keyboard backlight
query DSTS(ASUS_WMI_DEVID_KBD_BACKLIGHT) always returns 0x550000: the
presence bit is set but the level bits are 0 regardless of the level the
EC is actually driving. The DSDT's DSTS handler for 0x00050021 builds
its reply from constants (0x400000 | 0x350000, masked by the KBLT flag)
and never reads the level from the EC, so no query variant can return
it. Writes work: DEVS hands the value to the EC method SLKB and the
0x80|level form the driver uses steps the keyboard through all levels.

kbd_led_get() re-reads the firmware on every sysfs read and stores the
result in asus->kbd_led_wk, so on this machine every read overwrites the
cached level with 0. The visible effects are:

 - /sys/class/leds/asus::kbd_backlight/brightness, UPower's
   GetBrightness and brightnessctl always report 0;
 - systemd-backlight saves 0 at shutdown and restores a dark keyboard
   at every boot;
 - the Fn backlight key on this laptop raises ASUS_EV_BRTTOGGLE, and
   asus_wmi_kbd_led_hw_event() computes the next level from the cached
   value, so after any read has zeroed the cache the next press always
   yields level 1 whatever the keyboard was actually showing.

Add a quirk_entry flag, kbd_led_no_readback, which makes kbd_led_get()
return the cached level the way the existing !kbd_led_avail path
already does. Every path that changes the level (do_kbd_led_set(),
kbd_led_set_by_kbd(), the hotkey handler) keeps kbd_led_wk current, so
the cache is the only trustworthy source on this board. Match the
board with the same DMI strings the accepted SoundWire quirk for this
machine uses (sys_vendor "ASUS", board_name "B9406CAA").

Tested on the B9406CAA with Linux 7.2.3: after the quirk, brightness
reads back 3/1/2 after the corresponding writes, UPower reports the same
value, and three presses of the Fn backlight key from level 2 give
2 -> 3 -> 0 -> 1 (the ASUS_EV_BRTTOGGLE wrap), each step read back
correctly. Re-tested on Linux 7.3.0: writes of 3/1/2/0 read back
unchanged. Also compile-tested on this base with W=1 (clang).

Signed-off-by: Sercan GOKMEN <gokmensercan@gmail.com>
---
The patch is also tracked, with the other B9406CAA upstream patches,
in the community support repo for this laptop:
https://github.com/burakgon/asus-expertbook-linux/tree/main/upstream-patches
---
 drivers/platform/x86/asus-nb-wmi.c | 21 +++++++++++++++++++++
 drivers/platform/x86/asus-wmi.c    |  3 ++-
 drivers/platform/x86/asus-wmi.h    |  5 +++++
 3 files changed, 28 insertions(+), 1 deletion(-)

diff --git a/drivers/platform/x86/asus-nb-wmi.c b/drivers/platform/x86/asus-nb-wmi.c
index 3b0f3346d..894f622c8 100644
--- a/drivers/platform/x86/asus-nb-wmi.c
+++ b/drivers/platform/x86/asus-nb-wmi.c
@@ -93,6 +93,18 @@ static struct quirk_entry quirk_asus_unknown = {
 	.wmi_backlight_set_devstate = true,
 };
 
+/*
+ * ASUS ExpertBook Ultra B9406CAA (BIOS 312): the keyboard backlight query,
+ * DSTS(0x00050021), always returns 0x550000, i.e. level 0, whatever the EC is
+ * actually driving. Writes work. Without this quirk every sysfs read
+ * overwrites the cached level with 0, so UPower, brightnessctl and
+ * systemd-backlight all see a dark keyboard and restore level 0 at boot.
+ */
+static struct quirk_entry quirk_asus_b9406caa = {
+	.wmi_backlight_set_devstate = true,
+	.kbd_led_no_readback = true,
+};
+
 static struct quirk_entry quirk_asus_q500a = {
 	.filter_i8042_e1_extended_codes = true,
 	.wmi_backlight_set_devstate = true,
@@ -167,6 +179,15 @@ static int dmi_matched(const struct dmi_system_id *dmi)
 }
 
 static const struct dmi_system_id asus_quirks[] = {
+	{
+		.callback = dmi_matched,
+		.ident = "ASUS ExpertBook Ultra B9406CAA",
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "ASUS"),
+			DMI_MATCH(DMI_BOARD_NAME, "B9406CAA"),
+		},
+		.driver_data = &quirk_asus_b9406caa,
+	},
 	{
 		.callback = dmi_matched,
 		.ident = "ASUSTeK COMPUTER INC. Q500A",
diff --git a/drivers/platform/x86/asus-wmi.c b/drivers/platform/x86/asus-wmi.c
index fb1d4a085..19a0b3a0c 100644
--- a/drivers/platform/x86/asus-wmi.c
+++ b/drivers/platform/x86/asus-wmi.c
@@ -1966,7 +1966,8 @@ static enum led_brightness kbd_led_get(struct led_classdev *led_cdev)
 	asus = container_of(led_cdev, struct asus_wmi, kbd_led);
 
 	scoped_guard(spinlock_irqsave, &asus_ref.lock) {
-		if (!asus->kbd_led_avail)
+		if (!asus->kbd_led_avail ||
+		    asus->driver->quirks->kbd_led_no_readback)
 			return asus->kbd_led_wk;
 	}
 
diff --git a/drivers/platform/x86/asus-wmi.h b/drivers/platform/x86/asus-wmi.h
index b45f81b38..4f010f634 100644
--- a/drivers/platform/x86/asus-wmi.h
+++ b/drivers/platform/x86/asus-wmi.h
@@ -52,6 +52,11 @@ struct quirk_entry {
 	 */
 	int no_display_toggle;
 	u32 xusb2pr;
+	/*
+	 * The firmware never reports the keyboard backlight level (the query
+	 * always returns level 0), so trust the driver's cached value instead.
+	 */
+	bool kbd_led_no_readback;
 };
 
 struct asus_wmi_driver {

---
base-commit: 893018d51f27ec0449155b0afe371aaf65380630
change-id: 20261022-b4-asus-wmi-b9406caa-kbd-readback-aed82953d839

Best regards,
--  
Sercan GOKMEN <gokmensercan@gmail.com>

