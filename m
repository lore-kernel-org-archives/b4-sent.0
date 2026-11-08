From: Moad Tarrih <tarrihmoad@proton.me>
Date: Sun, 08 Nov 2026 13:43:52 +0000
Subject: [PATCH] platform/x86: asus-wmi: Ignore kbd backlight read-back on
 rejected writes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-asus-wmi-kbd-readback-v1-1-bf38f6400ade@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSwrCQBBF0a2EGluQLmNo3Io46M9Ty2CULqOBk
 L3b6vAM7l3IUBRG+2ahgpea3scKt2koXcJ4BmuuJmmld671HGwyft+Uh5i5IOQY0sCy7aXbwUu
 Gp9o+Ck46/76H4982xSvS8zujdf0ApIqDsnkAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794145433; l=6348;
 i=tarrihmoad@proton.me; s=20261108; h=from:subject:message-id;
 bh=ogqq5dQqAtyFUUMKvHaCTODwgaE29oIxanDP3GCceZQ=;
 b=+FilPRrjGtzfUQ3wv7tLx7b75sphxRuM6phl33jCQeP/Q6M4Qv72xoC6iDmljmMMDAOLby7su
 2y6EFDcQ2XpC+LY7Dm26DVaQ852Yq0pXFHDZ1pKi33qWwKfI8pAqAkk
X-Developer-Key: i=tarrihmoad@proton.me; a=ed25519;
 pk=wtwpmYxZldK7Qebavgtx7P5WmSQOiWjicK0506NOKLg=
X-Endpoint-Received: by B4 Relay for tarrihmoad@proton.me/20261108 with auth_id=1453
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the ASUS ROG Strix G18 G814FP, the brightness attribute of
asus::kbd_backlight always reads 0, and every read breaks the keyboard
brightness keys.

The firmware reports the keyboard backlight WMI device as present, but
DSTS(0x50021) returns 0x50000 (presence bit set, level 0) whatever level
the keyboard shows, and DEVS(0x50021, 0x80..0x83) returns
ASUS_WMI_UNSUPPORTED_METHOD for every level. The backlight is driven by
hid-asus through its asus-wmi listener instead.

Since commit fac55d29581f ("platform/x86: asus-wmi: Add support for
multiple kbd led handlers"), kbd_led_get() stores the level it reads in
kbd_led_wk, and the brightness key handlers step from kbd_led_wk. Any
read of the attribute, for example by a desktop environment or
systemd-backlight, therefore resets the stored level to 0, and the next
brightness-up press sets the keyboard to the lowest level instead of
stepping up:

  # echo 3 > /sys/class/leds/asus::kbd_backlight/brightness
  (keyboard goes to high)
  # cat /sys/class/leds/asus::kbd_backlight/brightness
  0
  (brightness-up key: keyboard drops to low)

systemd-backlight also saves 0 at shutdown, so the level is lost across
reboots.

Remember when the firmware rejects a write with -ENODEV, and from then
on return the stored level from kbd_led_get(), as is already done when
the WMI device is not available. The first write is queued right after
the LED is registered, so the read-back is only trusted before any
level has been set.

The cause was found and this fix written with the help of an AI coding
assistant (Claude Code, Claude Opus 5.5). I reviewed the change and
tested it on the affected laptop.

Fixes: fac55d29581f ("platform/x86: asus-wmi: Add support for multiple kbd led handlers")
Cc: stable@vger.kernel.org
Signed-off-by: Moad Tarrih <tarrihmoad@proton.me>
---
Tested on an ASUS ROG Strix G18 (board G814FP, BIOS G814FP.317,
keyboard 0b05:19b6) only, on 7.2.14 as a DKMS module. With the patch,
the attribute reads back low, medium and high correctly, the brightness
keys step from the real level, and the level survives suspend/resume
and reboots. Build-tested with W=1 against pdx86 for-next
(c339f4010dea): no warnings. checkpatch --strict is clean.

Limitation: a machine whose firmware rejects writes but changes the
brightness by itself would now report a stale level. I don't know of
such a machine.

Sercan GOKMEN posted a patch for the same symptom on the B9406CAA:
https://lore.kernel.org/platform-driver-x86/20261030-b4-asus-wmi-b9406caa-kbd-readback-v2-1-ca93bb9039f6@gmail.com/
On that board writes succeed and only the read-back is constant, so it
uses a DMI quirk. The two patches are complementary: the rejected-write
check doesn't catch the B9406CAA, and the quirk doesn't catch the
G814FP. They touch the same condition in kbd_led_get(), so whichever
lands second needs a trivial rebase; I'm happy to rebase onto it.

This touches different code from Bartu Alev's pending series
'[PATCH 0/2] platform/x86: asus-wmi: fix and unify keyboard brightness
key handling' and applies cleanly before or after it.

A more general option would be to ignore the WMI read-back whenever a
hid-asus listener is registered, since hid-asus drives the backlight on
the G814FP. I didn't do that because it could report stale levels on
machines where the firmware does change the brightness itself, but I can
rework the patch that way if preferred.

AI assistance: Claude Code was used over several sessions to trace the
read-back path in asus-wmi and hid-asus, run the debugfs DSTS/DEVS
probes, write the patch and draft this message. Testing and final
review were done by me on the hardware.
---
 drivers/platform/x86/asus-wmi.c | 24 ++++++++++++++++++++----
 1 file changed, 20 insertions(+), 4 deletions(-)

diff --git a/drivers/platform/x86/asus-wmi.c b/drivers/platform/x86/asus-wmi.c
index b33ebdb21aa2..c47ebc1f184a 100644
--- a/drivers/platform/x86/asus-wmi.c
+++ b/drivers/platform/x86/asus-wmi.c
@@ -258,6 +258,7 @@ struct asus_wmi {
 	struct led_classdev kbd_led;
 	int kbd_led_wk;
 	bool kbd_led_notify;
+	bool kbd_led_write_rejected;
 	bool kbd_led_avail;
 	bool kbd_led_registered;
 	struct led_classdev lightbar_led;
@@ -1724,8 +1725,9 @@ static struct asus_hid_ref asus_ref = {
 	.listeners = LIST_HEAD_INIT(asus_ref.listeners),
 	.asus = NULL,
 	/*
-	 * Protects .asus, .asus.kbd_led_{wk,notify}, and .listener refs. Other
-	 * asus variables are read-only after .asus is set.
+	 * Protects .asus, .asus.kbd_led_{wk,notify,write_rejected}, and
+	 * .listener refs. Other asus variables are read-only after .asus is
+	 * set.
 	 *
 	 * The led cdev device is not protected because it calls backlight_get
 	 * during initialization, which would result in a nested lock attempt.
@@ -1896,10 +1898,24 @@ static enum led_brightness tpd_led_get(struct led_classdev *led_cdev)
 static void kbd_led_update(struct asus_wmi *asus)
 {
 	int ctrl_param = 0;
+	int err;
 
 	scoped_guard(spinlock_irqsave, &asus_ref.lock)
 		ctrl_param = 0x80 | (asus->kbd_led_wk & 0x7F);
-	asus_wmi_set_devstate(ASUS_WMI_DEVID_KBD_BACKLIGHT, ctrl_param, NULL);
+	err = asus_wmi_set_devstate(ASUS_WMI_DEVID_KBD_BACKLIGHT, ctrl_param,
+				    NULL);
+
+	/*
+	 * Some firmware reports the device as present but rejects writes,
+	 * and its read-back does not follow the level set through other
+	 * paths, such as hid-asus. Stop trusting the read-back once a
+	 * write has been rejected.
+	 */
+	if (err == -ENODEV) {
+		pr_debug("Keyboard backlight write rejected, ignoring read-back\n");
+		scoped_guard(spinlock_irqsave, &asus_ref.lock)
+			asus->kbd_led_write_rejected = true;
+	}
 }
 
 static int kbd_led_read(struct asus_wmi *asus, int *level, int *env)
@@ -1975,7 +1991,7 @@ static enum led_brightness kbd_led_get(struct led_classdev *led_cdev)
 	asus = container_of(led_cdev, struct asus_wmi, kbd_led);
 
 	scoped_guard(spinlock_irqsave, &asus_ref.lock) {
-		if (!asus->kbd_led_avail)
+		if (!asus->kbd_led_avail || asus->kbd_led_write_rejected)
 			return asus->kbd_led_wk;
 	}
 

---
base-commit: c339f4010dea8b0d754f84ace70cd1b089878ef8
change-id: 20261108-asus-wmi-kbd-readback-236245e82de8

Best regards,
--  
Moad Tarrih <tarrihmoad@proton.me>

