From: Sercan GOKMEN <gokmensercan@gmail.com>
Date: Fri, 30 Oct 2026 11:56:44 +0300
Subject: [PATCH v2] platform/x86: asus-wmi: Skip keyboard backlight
 read-back on B9406CAA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-b4-asus-wmi-b9406caa-kbd-readback-v2-1-ca93bb9039f6@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/5WOQQ6CMBBFr0K6dgxtkVBX3sOwmHYGqAiYFlBDu
 LugJ3D5kpf//iIiB89RnJNFBJ599EO/gTokwjXY1wyeNhYqVblMlQKbAcYpwrPzYE2W5g4RWks
 QGMmiawGZCmVOmgptxLbzCFz517dxLX8cJ3tjN+7Du9H4OA7h/T0xy937pzdLkFBZrZlMQSTzS
 92hvx/d0IlyXdcPA1Ri6eQAAAA=
X-Change-ID: 20261022-b4-asus-wmi-b9406caa-kbd-readback-aed82953d839
To: Corentin Chary <corentin.chary@gmail.com>, 
 "Luke D. Jones" <luke@ljones.dev>, Denis Benato <denis.benato@linux.dev>, 
 Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: Burak Goncu <burakgon12@gmail.com>, platform-driver-x86@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sercan GOKMEN <gokmensercan@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793350604; l=5986;
 i=gokmensercan@gmail.com; s=20261022; h=from:subject:message-id;
 bh=LMEzwt/5NHrzRt+KkV5MARGp4DLm+R9ldjK5gN4qr6I=;
 b=TjCJTox6gEShP1NnAbClN4EksQLQpz51RuNL5lrJveLze78AteaCLsE5G262VvKzOfhziZ1Sn
 VgDLTtFyLLOAan6uZPmqhQTrSTi2MtBOSTe79syUQV9P6/PQraEuUGY
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

With the quirk, kbd_led_wk keeps the level asus_wmi_led_init() read at
probe time, which on this board is the same constant 0, until the first
write. At boot that write normally comes from systemd-backlight
restoring the saved level; until then the driver reports 0 whatever the
EC is driving, as it does today.

Signed-off-by: Sercan GOKMEN <gokmensercan@gmail.com>
---
Tested on the B9406CAA (BIOS 312) with Linux 7.2.3: after the quirk,
brightness reads back 3/1/2 after the corresponding writes, UPower
reports the same value, and three presses of the Fn backlight key from
level 2 give 2 -> 3 -> 0 -> 1 (the ASUS_EV_BRTTOGGLE wrap), each step
read back correctly. Re-tested on Linux 7.3.0: writes of 3/1/2/0 read
back unchanged. Compile-tested on pdx86 for-next (c339f4010dea) with
W=1 (clang).

The patch is also tracked, with the other B9406CAA upstream patches,
in the community support repo for this laptop:
https://github.com/burakgon/asus-expertbook-linux/tree/main/upstream-patches
---
Changes in v2:
- Shorten the subject (Burak Goncu).
- Say that kbd_led_wk keeps the 0 read at probe until the first write
  (Burak Goncu).
- Move the test details below the cut (Burak Goncu).
- Rebase on current for-next.
- Link to v1: https://patch.msgid.link/20261022-b4-asus-wmi-b9406caa-kbd-readback-v1-1-fb33ed98dd16@gmail.com
---
 drivers/platform/x86/asus-nb-wmi.c | 21 +++++++++++++++++++++
 drivers/platform/x86/asus-wmi.c    |  3 ++-
 drivers/platform/x86/asus-wmi.h    |  5 +++++
 3 files changed, 28 insertions(+), 1 deletion(-)

diff --git a/drivers/platform/x86/asus-nb-wmi.c b/drivers/platform/x86/asus-nb-wmi.c
index 3b0f3346dc..894f622c89 100644
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
index b33ebdb21a..725f827a17 100644
--- a/drivers/platform/x86/asus-wmi.c
+++ b/drivers/platform/x86/asus-wmi.c
@@ -1975,7 +1975,8 @@ static enum led_brightness kbd_led_get(struct led_classdev *led_cdev)
 	asus = container_of(led_cdev, struct asus_wmi, kbd_led);
 
 	scoped_guard(spinlock_irqsave, &asus_ref.lock) {
-		if (!asus->kbd_led_avail)
+		if (!asus->kbd_led_avail ||
+		    asus->driver->quirks->kbd_led_no_readback)
 			return asus->kbd_led_wk;
 	}
 
diff --git a/drivers/platform/x86/asus-wmi.h b/drivers/platform/x86/asus-wmi.h
index b45f81b38a..4f010f6349 100644
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
base-commit: c339f4010dea8b0d754f84ace70cd1b089878ef8
change-id: 20261022-b4-asus-wmi-b9406caa-kbd-readback-aed82953d839

Best regards,
--  
Sercan GOKMEN <gokmensercan@gmail.com>

