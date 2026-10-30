From: Jonah Dybas <jonah.w.dybas@protonmail.com>
Date: Fri, 30 Oct 2026 11:20:49 -0400
Subject: [PATCH] HID: asus: add support for the GL553VW keyboard
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-gl553vw-kbd-v1-1-cbbd88493511@protonmail.com>
X-B4-Tracking: v=1; b=H4sIANC15GoC/yXMTQ5AMBBA4avIrDVpSwlXEQutwSBI6y8Rd1csv
 8V7Fzi0hA7y4AKLOzmaJw8RBmC6amqRUe0NkstE8IizdlQq2g826JplcaVSZaQUOgVfLBYbOr9
 bUf52m+7RrO8C7vsBeLuSt28AAAA=
X-Change-ID: 20261030-gl553vw-kbd-94a575c221b7
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonah Dybas <jonah.w.dybas@protonmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793373648; l=3905;
 i=jonah.w.dybas@protonmail.com; s=20261030; h=from:subject:message-id;
 bh=MLUYdGu6qDugl1acxLXpGGQXtKgpDGo2n+A1gQJjwFM=;
 b=ftLtJr/eej3b1KrFKugwpb2CftenPPYelJ4Db2+1A8KPOTC65Bu06xiLORpx579mIIHqR6SIE
 ruSIK/eN2Y3BmmRVmy3QmEDom0LBgAneHpWJIi5B7lb77YzPBnqm2zC
X-Developer-Key: i=jonah.w.dybas@protonmail.com; a=ed25519;
 pk=xj+D5YSRYYNylSntmoQSj9kbGTB3QprYsXr53ZDSP0c=
X-Endpoint-Received: by B4 Relay for jonah.w.dybas@protonmail.com/20261030 with auth_id=1363
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The built-in keyboard of the ASUS GL553VW (ITE Device(8910),
USB 0b05:8176) is handled by hid-generic, so its backlight cannot be
controlled and the Fn+F3 and Fn+F4 backlight keys arrive as plain F3
and F4.

The laptop's BIOS (306) offers no working WMI path either. DSTS for
ASUS_WMI_DEVID_KBD_BACKLIGHT always returns 0x8000 and the related
DEVS handler is an empty stub, so asus-wmi never registers
asus::kbd_backlight on its own.

The keyboard does implement the vendor interface used by other ROG
keyboards (usage page 0xff31, report 0x5a). After the "ASUS Tech.Inc."
handshake it reports backlight support in the functions query and
accepts "5a ba c5 c4 <level>" to set the brightness (0-3). The
backlight keys are reported on the same report:

  5a c5 -> Fn+F3 (backlight down)
  5a c4 -> Fn+F4 (backlight up)

Add the device ID with QUIRK_USE_KBD_BACKLIGHT |
QUIRK_ROG_NKEY_KEYBOARD.

Tested on a GL553VW (BIOS 306) by binding the keyboard to hid-asus
with these quirks through new_id on a 7.0-based kernel. The keyboard
backlight (asus::kbd_backlight) is registered through the asus-wmi
listener and can be changed from sysfs and the desktop. Fn+F3/Fn+F4
adjust it, and the level is restored after suspend/resume.

The investigation, this change and a first draft of this changelog
were produced with the help of Claude Code (Claude Opus 5.5), then
reviewed and tested on the hardware above.

Signed-off-by: Jonah Dybas <jonah.w.dybas@protonmail.com>
---
- The handshake readback does not match the request, so probe logs
  "Asus handshake 5a returned invalid response". It is only a warning.
  The keyboard answers the handshake read with
  "5a 05 20 31 00 08 01 00 ...", which looks like the reply to the
  functions query, so it does not seem to echo the handshake at all.
  The functions query that follows works and reports backlight support
  (byte 6 = 0x01). Worth keeping in mind if the handshake check is ever
  made strict.
- Compile-tested against hid/for-next. I could not boot-test the
  for-next build because Secure Boot on this machine rejects unsigned
  modules. The hardware testing above used the distro 7.0 hid-asus with
  the same quirks via new_id.
- The investigation (ACPI table analysis, HID descriptor decoding,
  hidraw experiments), this patch and a first draft of the changelog
  were produced with the help of Claude Code. I reviewed the result
  and ran the tests on my hardware.
---
 drivers/hid/hid-asus.c | 3 +++
 drivers/hid/hid-ids.h  | 1 +
 2 files changed, 4 insertions(+)

diff --git a/drivers/hid/hid-asus.c b/drivers/hid/hid-asus.c
index f6aa1be09..97b601f20 100644
--- a/drivers/hid/hid-asus.c
+++ b/drivers/hid/hid-asus.c
@@ -1814,6 +1814,9 @@ static const struct hid_device_id asus_devices[] = {
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ASUSTEK,
 		USB_DEVICE_ID_ASUSTEK_FX503VD_KEYBOARD),
 	  QUIRK_USE_KBD_BACKLIGHT },
+	{ HID_USB_DEVICE(USB_VENDOR_ID_ASUSTEK,
+		USB_DEVICE_ID_ASUSTEK_GL553VW_KEYBOARD),
+	  QUIRK_USE_KBD_BACKLIGHT | QUIRK_ROG_NKEY_KEYBOARD },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ASUSTEK,
 	    USB_DEVICE_ID_ASUSTEK_ROG_NKEY_KEYBOARD),
 	  QUIRK_USE_KBD_BACKLIGHT | QUIRK_ROG_NKEY_KEYBOARD },
diff --git a/drivers/hid/hid-ids.h b/drivers/hid/hid-ids.h
index 91319aa65..edf7bdd37 100644
--- a/drivers/hid/hid-ids.h
+++ b/drivers/hid/hid-ids.h
@@ -234,6 +234,7 @@
 #define USB_DEVICE_ID_ASUSTEK_ROG_NKEY_ALLY_X		0x1b4c
 #define USB_DEVICE_ID_ASUSTEK_ROG_CLAYMORE_II_KEYBOARD	0x196b
 #define USB_DEVICE_ID_ASUSTEK_FX503VD_KEYBOARD	0x1869
+#define USB_DEVICE_ID_ASUSTEK_GL553VW_KEYBOARD	0x8176
 #define USB_DEVICE_ID_ASUSTEK_XGM_2022	0x1970
 #define USB_DEVICE_ID_ASUSTEK_XGM_2023	0x1a9a
 

---
base-commit: 720806515cb6921ab05caaa6f470f7054b56385e
change-id: 20261030-gl553vw-kbd-94a575c221b7

Best regards,
--  
Jonah Dybas <jonah.w.dybas@protonmail.com>

