From: Teo Casares <teo@nakora.fi>
Date: Sun, 18 Oct 2026 19:56:50 -0400
Subject: [PATCH] HID: multitouch: use Win8 class for ELAN 04F3:3358
 (Surface Laptop Ultra)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-elan-3358-v1-1-31770ebecfe3@nakora.fi>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0ML3dScxDxdY2NTC92UtFSTFDMLS4PUVBMloPqCotS0zAqwWdGxEH5
 xaVJWanIJyACl2loAcv70SW0AAAA=
X-Change-ID: 20261018-elan-3358-dfe4d6890ee4
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Teo Casares <teo@nakora.fi>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792367811; l=2541;
 i=teo@nakora.fi; s=20261018; h=from:subject:message-id;
 bh=UgpHOe8bXIQbdG9aTq6ED0je/Z/6mXB/BG2rJb4/+fc=;
 b=S2fX9n+OrIDybyluIOLb7LakD/mWJDYSgO7FdrgKbRK3Xt4S0gGHatp5S7DnGQ6LEaDaaDFfF
 e2kab1GL1EcDiDGi+jJ6cpZ82O/2B1EAQAkbIVtpugugJIouovh76EY
X-Developer-Key: i=teo@nakora.fi; a=ed25519;
 pk=gQlDjO8thAfg2FOuRC8JG101i211dGw9bNBbyYUZcZs=
X-Endpoint-Received: by B4 Relay for teo@nakora.fi/20261018 with auth_id=1232
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Surface Laptop Ultra touchpad declares its PTPHQA blob on the
Digitizers usage page (0x000d00c5) instead of the vendor page
(0xff0000c5), so it is not detected as a Win8 device and gets the
generic class, which ignores Confidence. Palms are then reported as
fingers.

Add a device entry with MT_CLS_WIN_8 so Confidence maps to
MT_TOOL_PALM. The entry matches HID_GROUP_MULTITOUCH on purpose: if
the firmware is ever fixed, the generic Win8 entry takes over.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Teo Casares <teo@nakora.fi>
---
Report descriptor excerpt (MSHW0734, 1129 bytes):

  836: 06 00 ff      Usage Page (Vendor 0xff00)
  839: 05 0d         Usage Page (Digitizers)
  ...
  1060: 85 06        Report ID (6)
  1062: 09 c5        Usage (0xc5)
  ...
  1072: 75 08 96 00 01 b1 02   Report Size (8), Report Count (256), Feature

The device stays in the generic group, so HID_QUIRK_MULTI_INPUT is
still set; as with other PTPs, MT_CLS_WIN_8 also exports the legacy
Mouse collection as an extra input node. Haptics are unaffected: the
descriptor has no Auto Trigger usage.

Tested on a Surface Laptop Ultra running 7.2.8 with the same hunk:
the touchpad reports MT_TOOL_PALM for palm contacts, and clicks,
click-and-drag and long stationary contacts behave as before.
Build-tested on hid.git for-next.

Root-cause analysis, patch and changelog were drafted with an LLM coding
assistant (Claude Opus 5.5 via Claude Code); I reviewed the change and
tested it on the hardware. A HID-BPF descriptor fixup restoring the
vendor usage page should also work; happy to send that instead or in
addition if preferred.
---
 drivers/hid/hid-multitouch.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/hid/hid-multitouch.c b/drivers/hid/hid-multitouch.c
index 4e19a0c4d2..4e969438b2 100644
--- a/drivers/hid/hid-multitouch.c
+++ b/drivers/hid/hid-multitouch.c
@@ -2425,6 +2425,11 @@ static const struct hid_device_id mt_devices[] = {
 		HID_DEVICE(BUS_I2C, HID_GROUP_MULTITOUCH_WIN_8,
 			USB_VENDOR_ID_ELAN, 0x32ae) },
 
+	/* Surface Laptop Ultra: PTPHQA blob not on the vendor page */
+	{ .driver_data = MT_CLS_WIN_8,
+		HID_DEVICE(BUS_I2C, HID_GROUP_MULTITOUCH,
+			USB_VENDOR_ID_ELAN, 0x3358) },
+
 	/* Elitegroup panel */
 	{ .driver_data = MT_CLS_SERIAL,
 		MT_USB_DEVICE(USB_VENDOR_ID_ELITEGROUP,

---
base-commit: ae6927c533a4454570950125ca8ba909c45f20f9
change-id: 20261018-elan-3358-dfe4d6890ee4

Best regards,
--  
Teo Casares <teo@nakora.fi>

