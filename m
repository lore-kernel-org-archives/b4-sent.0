From: Victor Gillholm <victor.gillholm@gmail.com>
Date: Sat, 17 Oct 2026 20:13:22 +0200
Subject: [PATCH] platform/x86: asus-nb-wmi: map ScreenPad and Task Swap
 keys
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-zenbook-duo-keys-v1-1-45f72d3db5ed@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWTtJCwjRqxgXFH5gJGlNR4xAu
 LtVlt/ivY0UUaB0zTaKeItK8An2lFE7Nn4AS5dMuckra2zNK7wLYeJuDjxhUa5hXNFfyuJcNpS
 yZ0Qvn//ydj+ss3ugff0+tO9fcy23MXQAAAA=
X-Change-ID: 20261017-zenbook-duo-keys-7e0b3f94354a
To: Corentin Chary <corentin.chary@gmail.com>, 
 "Luke D. Jones" <luke@ljones.dev>, Denis Benato <denis.benato@linux.dev>, 
 Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Victor Gillholm <victor.gillholm@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792260866; l=2859;
 i=victor.gillholm@gmail.com; s=zenbook; h=from:subject:message-id;
 bh=6M3/+PEfY8fXb3qd10LtNrTk5fn9SKJDEffvIOgCHXs=;
 b=scn521DZ4w8eaVPtdBD2nLMX3gBL/11Zo5At0nSm2J5VHoCgnsTSDI3GLfAB/xQ6wE3KZ6FnN
 ZLWn4aDLt35CZpmPnRqcbQyYGtzSVPAnSN27+zkvtBXpIEWCi2DKyXV
X-Developer-Key: i=victor.gillholm@gmail.com; a=ed25519;
 pk=eD1INWVbRo2RgAKLHQOmsC14YPzQqjCdECtcWSZ9mg0=
X-Endpoint-Received: by B4 Relay for victor.gillholm@gmail.com/zenbook with auth_id=1224
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ASUS Zenbook Duo 14 UX482EG has two keys next to the power button:
one toggles the ScreenPad Plus, the second screen above the keyboard,
and one swaps windows between the two screens (Task Swap in ASUS'
ScreenXpert software). They emit ASUS WMI event codes 0x6a and 0x9c.
Neither code is in the asus-nb-wmi sparse keymap, so pressing them only
logs "Unknown key code 0x6a" or "Unknown key code 0x9c", and both keys
are reported as KEY_UNKNOWN, so ordinary desktop key bindings cannot
tell them apart.

Map 0x6a to KEY_F13, the same keycode hid-asus already uses for the
ScreenPad toggle code 0x6a. No existing keycode describes moving windows
between screens, so map 0x9c to KEY_F14, following the existing use of
KEY_F13 and KEY_F14 for other ASUS-specific keys in this keymap. Both
keys then emit distinct, bindable events.

Tested on an ASUS Zenbook Duo 14 UX482EG: with this change the keys
arrive in userspace as KEY_F13 and KEY_F14 and the "Unknown key code"
messages are gone.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Victor Gillholm <victor.gillholm@gmail.com>
---
Tested by building asus-nb-wmi against 7.2.5 and loading it in place of
the stock module. The key mapping was checked with wev: before the change
both keys arrived as keycode 248 with no keysym, after it as XF86Tools
(KEY_F13) and XF86Launch5 (KEY_F14).
---
 drivers/platform/x86/asus-nb-wmi.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/platform/x86/asus-nb-wmi.c b/drivers/platform/x86/asus-nb-wmi.c
index 3b0f3346d..c6eb525ec 100644
--- a/drivers/platform/x86/asus-nb-wmi.c
+++ b/drivers/platform/x86/asus-nb-wmi.c
@@ -641,6 +641,7 @@ static const struct key_entry asus_nb_wmi_keymap[] = {
 	{ KE_KEY, 0x65, { KEY_SWITCHVIDEOMODE } }, /* SDSP LCD + TV */
 	{ KE_KEY, 0x66, { KEY_SWITCHVIDEOMODE } }, /* SDSP CRT + TV */
 	{ KE_KEY, 0x67, { KEY_SWITCHVIDEOMODE } }, /* SDSP LCD + CRT + TV */
+	{ KE_KEY, 0x6A, { KEY_F13 } }, /* ScreenPad toggle on Zenbook Duo */
 	{ KE_KEY, 0x6B, { KEY_TOUCHPAD_TOGGLE } },
 	{ KE_IGNORE, 0x6E, },  /* Low Battery notification */
 	{ KE_KEY, 0x71, { KEY_F13 } }, /* General-purpose button */
@@ -666,6 +667,7 @@ static const struct key_entry asus_nb_wmi_keymap[] = {
 	{ KE_KEY, 0x93, { KEY_SWITCHVIDEOMODE } }, /* SDSP LCD + CRT + TV + DVI */
 	{ KE_KEY, 0x95, { KEY_MEDIA } },
 	{ KE_KEY, 0x99, { KEY_PHONE } }, /* Conflicts with fan mode switch */
+	{ KE_KEY, 0x9C, { KEY_F14 } }, /* Task Swap key on Zenbook Duo */
 	{ KE_KEY, 0X9D, { KEY_FN_F } },
 	{ KE_KEY, 0xA0, { KEY_SWITCHVIDEOMODE } }, /* SDSP HDMI only */
 	{ KE_KEY, 0xA1, { KEY_SWITCHVIDEOMODE } }, /* SDSP LCD + HDMI */

---
base-commit: ea40f1e9f07aab937b9a217633be7a1f66260394
change-id: 20261017-zenbook-duo-keys-7e0b3f94354a

Best regards,
--  
Victor Gillholm <victor.gillholm@gmail.com>

