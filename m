From: Jakub Jatczak <jjatczak@antmicro.com>
Date: Thu, 19 Nov 2026 15:18:45 +0100
Subject: [PATCH] usbip: Don't print port status error for full-speed
 devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-usbip-fix-v1-1-e6c04690115d@antmicro.com>
X-B4-Tracking: v=1; b=H4sIAEQF/2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0NL3dLipMwC3bTMCl1jEyNTS0vzRNMUcwMloPqColSgMNis6FgIv7g
 0KSs1uQRkgFJtLQCE5RM8bQAAAA==
X-Change-ID: 20261119-usbip-fix-3425997a5d70
To: Valentina Manea <valentina.manea.m@gmail.com>, 
 Shuah Khan <shuah@kernel.org>, Hongren Zheng <i@zenithal.me>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, 
 Zee Yudenko <zyudenko@internships.antmicro.com>, 
 Jakub Jatczak <jjatczak@antmicro.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795097930; l=1347;
 i=jjatczak@antmicro.com; s=20261119; h=from:subject:message-id;
 bh=OS8UqiwHqBptFTeFSM2QQKndU+D8JiAutl3gaRQ0HY8=;
 b=DylVeDElqJMVpp2f6JinhL8i9vgioHQURK0gg2v4oqaXy1cB7wEK7K+8MDgrGKhGfA9fuudn3
 0Ls4bYkfewzC8yByy9zpxSiuafhQU1XA+WHD6xxr5p9ScDK1bAIOdGr
X-Developer-Key: i=jjatczak@antmicro.com; a=ed25519;
 pk=cNMAGqBjphJgwMUhAbseW6DasEAKdiJqPK/Zbl523Kc=
X-Endpoint-Received: by B4 Relay for jjatczak@antmicro.com/20261119 with auth_id=1572
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Zee Yudenko <zyudenko@internships.antmicro.com>

When getting port status for USBIP, we only check for high- and low-speed
settings, but not for the full-speed, which causes an 'vhci_device speed
not set' error to be printed whenever a full-speed device is attached. A
full-speed device is the default status, so we don't need to set any port
status bits.

Signed-off-by: Zee Yudenko <zyudenko@internships.antmicro.com>
Signed-off-by: Jakub Jatczak <jjatczak@antmicro.com>
---
Patch authored by Zee Yudenko; I'm submitting it on their behalf.
Please direct feedback to me.
---
 drivers/usb/usbip/vhci_hcd.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/usb/usbip/vhci_hcd.c b/drivers/usb/usbip/vhci_hcd.c
index 39e8faf4c18c..936b98629921 100644
--- a/drivers/usb/usbip/vhci_hcd.c
+++ b/drivers/usb/usbip/vhci_hcd.c
@@ -480,6 +480,9 @@ static int vhci_hub_control(struct usb_hcd *hcd, u16 typeReq, u16 wValue,
 					vhci_hcd->port_status[rhport] |=
 					      USB_PORT_STAT_HIGH_SPEED;
 					break;
+				case USB_SPEED_FULL:
+					/* this is the default, no flag needed */
+					break;
 				case USB_SPEED_LOW:
 					vhci_hcd->port_status[rhport] |=
 						USB_PORT_STAT_LOW_SPEED;

---
base-commit: 4405c18c95d2d0f99f6c581ef0ee8591a1aa6ccd
change-id: 20261119-usbip-fix-3425997a5d70

Best regards,
--  
Jakub Jatczak <jjatczak@antmicro.com>

