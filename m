From: Moad Tarrih <tarrihmoad@proton.me>
Date: Wed, 11 Nov 2026 23:36:26 +0000
Subject: [PATCH v4] platform/x86: asus-wmi: Ignore unusable kbd backlight
 WMI device on ROG Strix G814FP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-asus-wmi-kbd-readback-v4-1-79df1567476d@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XQTQ7CIBAF4KsY1mJgQIKuvIdxwc+gaGwrtFVje
 nepumhijMuXzHwvMw+SMUXMZD17kIR9zLGuSpDzGXEHU+2RRl8yAQaKc6apyV2m13OkJ+tpQuO
 tcScKQoFcogaPmpTdJmGIt5e73b1z7uwRXTti48Qh5rZO91dxz8e5fx09p5zaIHRQkjHjcdOku
 q2rxRnJ2NHDVFn9UqAojkkd3FJ4jV+KmCic/VJEUZRUxgewWsFqqgzvgxNeuvLP9vOFYXgCZ4/
 i6G0BAAA=
X-Change-ID: 20261108-asus-wmi-kbd-readback-236245e82de8
To: Corentin Chary <corentin.chary@gmail.com>, 
 "Luke D. Jones" <luke@ljones.dev>, Denis Benato <denis.benato@linux.dev>, 
 Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Antheas Kapenekakis <lkml@antheas.dev>, 
 Benjamin Tissoires <bentiss@kernel.org>
Cc: Sercan GOKMEN <gokmensercan@gmail.com>, 
 Burak Goncu <burakgon12@gmail.com>, Denis Benato <benato.denis96@gmail.com>, 
 platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Moad Tarrih <tarrihmoad@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794440189; l=5327;
 i=tarrihmoad@proton.me; s=20261108; h=from:subject:message-id;
 bh=2DuMrNPPbmG4EK58GjRCWYX3JTlzq8zk3x5L5iXO+R4=;
 b=DbfGtdQqmZnbH4vi8ozqbeJ1yzktm11TKJN/TvPIGdcGufMdLcRthxvFIiwFN4hfWw5zlLrk5
 kLi6/0+BDieD2VqhRZ2b+G9sGC2eVtj5ajvv4kwbykYP/MDb7KTdTX4
X-Developer-Key: i=tarrihmoad@proton.me; a=ed25519;
 pk=wtwpmYxZldK7Qebavgtx7P5WmSQOiWjicK0506NOKLg=
X-Endpoint-Received: by B4 Relay for tarrihmoad@proton.me/20261108 with auth_id=1453
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the ASUS ROG Strix G18 G814FP, writing a level to the keyboard
backlight brightness in sysfs works, but reading it back always gives
0, and the read makes the Fn brightness keys misbehave.

The firmware reports the keyboard backlight WMI device as present
without implementing it, and the backlight is actually driven by
hid-asus. DSTS(0x00050021) always returns 0x50000, which is level 0
regardless of what the actual level is, and every DEVS(0x00050021)
write is rejected as an unsupported method.

Add a kbd_led_no_wmi quirk that makes asus-wmi treat the keyboard
backlight WMI device as absent, and set it for this board, matched on
the DMI board name. asus-wmi then keeps the LED registered for hid-asus
and no longer reads from or writes to the WMI device.

As a side effect, the kbd_rgb_mode and kbd_rgb_mode_index attributes are
no longer created on this board, they never worked here since the firmware
rejects those writes as well.

Fixes: fac55d29581f ("platform/x86: asus-wmi: Add support for multiple kbd led handlers")
Suggested-by: Antheas Kapenekakis <lkml@antheas.dev>
Suggested-by: Denis Benato <denis.benato@linux.dev>
Cc: stable@vger.kernel.org
Signed-off-by: Moad Tarrih <tarrihmoad@proton.me>
Reviewed-by: Antheas Kapenekakis <lkml@antheas.dev>
---
Tested on an ASUS ROG Strix G18 (board G814FP, BIOS G814FP.317) on
7.2.14: the brightness attribute reads back the level that was set, the
Fn keys step from it, and this survives suspend and reboot. W=1 and
checkpatch --strict are clean. v4 only changes the commit message.

Sercan GOKMEN's B9406CAA patch also adds a field to struct quirk_entry
and a DMI entry, so whichever lands second may need a trivial rebase.

AI assistance: Claude Code (Claude Opus 5.5) was used to trace the
asus-wmi code, write the patch and draft the commit message. I reviewed
it and tested it on the hardware.
---
Changes in v4:
- Trim the commit message and move the AI assistance note below the
  --- line (Ilpo).
- Link to v3: https://patch.msgid.link/20261110-asus-wmi-kbd-readback-v3-1-646adf2b8629@proton.me

Changes in v3:
- Drop the comment on kbd_led_no_wmi (Antheas).
- Don't set wmi_backlight_set_devstate for this board: the firmware
  rejects both DSTS and DEVS on 0x00050012, so the write did nothing
  (Antheas).
- Add Antheas's Reviewed-by.
- Link to v2: https://patch.msgid.link/20261109-asus-wmi-kbd-readback-v2-1-c048fc53d8ee@proton.me

Changes in v2:
- Add a quirk that makes asus-wmi skip the keyboard backlight WMI
  device on this board instead of detecting rejected writes at
  runtime (Antheas), so no more WMI writes that are known to fail
  are issued (Denis).
- Link to v1: https://patch.msgid.link/20261108-asus-wmi-kbd-readback-v1-1-bf38f6400ade@proton.me
---
 drivers/platform/x86/asus-nb-wmi.c | 13 +++++++++++++
 drivers/platform/x86/asus-wmi.c    |  3 ++-
 drivers/platform/x86/asus-wmi.h    |  1 +
 3 files changed, 16 insertions(+), 1 deletion(-)

diff --git a/drivers/platform/x86/asus-nb-wmi.c b/drivers/platform/x86/asus-nb-wmi.c
index 3b0f3346dc60..9b2a4b829885 100644
--- a/drivers/platform/x86/asus-nb-wmi.c
+++ b/drivers/platform/x86/asus-nb-wmi.c
@@ -93,6 +93,10 @@ static struct quirk_entry quirk_asus_unknown = {
 	.wmi_backlight_set_devstate = true,
 };
 
+static struct quirk_entry quirk_asus_g814fp = {
+	.kbd_led_no_wmi = true,
+};
+
 static struct quirk_entry quirk_asus_q500a = {
 	.filter_i8042_e1_extended_codes = true,
 	.wmi_backlight_set_devstate = true,
@@ -167,6 +171,15 @@ static int dmi_matched(const struct dmi_system_id *dmi)
 }
 
 static const struct dmi_system_id asus_quirks[] = {
+	{
+		.callback = dmi_matched,
+		.ident = "ASUS ROG Strix G18 G814FP",
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "ASUSTeK COMPUTER INC."),
+			DMI_MATCH(DMI_BOARD_NAME, "G814FP"),
+		},
+		.driver_data = &quirk_asus_g814fp,
+	},
 	{
 		.callback = dmi_matched,
 		.ident = "ASUSTeK COMPUTER INC. Q500A",
diff --git a/drivers/platform/x86/asus-wmi.c b/drivers/platform/x86/asus-wmi.c
index b33ebdb21aa2..51fea21ff247 100644
--- a/drivers/platform/x86/asus-wmi.c
+++ b/drivers/platform/x86/asus-wmi.c
@@ -2165,7 +2165,8 @@ static int asus_wmi_led_init(struct asus_wmi *asus)
 	asus->kbd_led.brightness_set_blocking = kbd_led_set;
 	asus->kbd_led.brightness_get = kbd_led_get;
 	asus->kbd_led.max_brightness = ASUS_EV_MAX_BRIGHTNESS;
-	asus->kbd_led_avail = !kbd_led_read(asus, &led_val, NULL);
+	asus->kbd_led_avail = !asus->driver->quirks->kbd_led_no_wmi &&
+			      !kbd_led_read(asus, &led_val, NULL);
 	INIT_WORK(&asus->kbd_led_work, kbd_led_update_all);
 
 	if (asus->kbd_led_avail) {
diff --git a/drivers/platform/x86/asus-wmi.h b/drivers/platform/x86/asus-wmi.h
index b45f81b38a47..e53c6b3fc619 100644
--- a/drivers/platform/x86/asus-wmi.h
+++ b/drivers/platform/x86/asus-wmi.h
@@ -41,6 +41,7 @@ struct quirk_entry {
 	bool wmi_force_als_set;
 	bool wmi_ignore_fan;
 	bool filter_i8042_e1_extended_codes;
+	bool kbd_led_no_wmi;
 	int key_wlan_event;
 	enum asus_wmi_tablet_switch_mode tablet_switch_mode;
 	int wapf;

---
base-commit: c339f4010dea8b0d754f84ace70cd1b089878ef8
change-id: 20261108-asus-wmi-kbd-readback-236245e82de8

Best regards,
--  
Moad Tarrih <tarrihmoad@proton.me>

