From: Oleh Kurudz <admin@or1k.net>
Date: Fri, 20 Nov 2026 00:22:26 +0200
Subject: [PATCH 2/2] USB: quirks: Add USB_QUIRK_DISCONNECT_PARENT_SUSPEND
 for HyperX QuadCast S
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-quadcast-s-suspend-v1-2-add8ccf12c8f@or1k.net>
References: <20261120-quadcast-s-suspend-v1-0-add8ccf12c8f@or1k.net>
In-Reply-To: <20261120-quadcast-s-suspend-v1-0-add8ccf12c8f@or1k.net>
To: Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Alan Stern <stern@rowland.harvard.edu>, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-usb@vger.kernel.org, 
 Oleh Kurudz <admin@or1k.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795126946; l=2798;
 i=admin@or1k.net; s=20261120; h=from:subject:message-id;
 bh=sclMB3qQjz0MBOArJBKgrL60LLle/8DQgPez0+3yPqM=;
 b=X9dZki4l1j1PUxCwmeR20wUozH0CTxA+s5sv2LERkuY9ZwuP8CnndsPklvU/BQ2hAvlnbmqbG
 WjcH/6+z817Dehe73O0Qkf3feiPDX4XddKFuib320qp/aCPHuaW/8X/
X-Developer-Key: i=admin@or1k.net; a=ed25519;
 pk=99OKf9VLJkjldneE6gRk0c6oTl7G+EdqRiFo4h8sH6Q=
X-Endpoint-Received: by B4 Relay for admin@or1k.net/20261120 with auth_id=1577
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HyperX QuadCast S microphone has a built-in Huasheng 214b:7250 hub
with two functions behind it: an audio device (0951:171d) and an HID
device for the RGB lighting (0951:171f). During system suspend the HID
function drops off the built-in hub, and the hub wakes the system even
though remote wakeup is disabled. On an AMD laptop using s2idle the
first suspend after boot comes back within about a second:

  [   68.618009] PM: suspend entry (s2idle)
  [   69.752213] usb 1-1.3.1: usb suspend, wakeup 0
  [   69.753139] usb 1-1.3.4: usb suspend, wakeup 0
  [   69.753876] hub 1-1.3:1.0: hub_suspend
  [   69.754488] usb 1-1.3: usb suspend, wakeup 0
  [   69.775275] PM: suspend-to-idle
  [   69.775287] ACPI: PM: ACPI non-EC GPE wakeup
  [   69.775305] PM: resume from suspend-to-idle
  [   69.775319] amd_pmc AMDI0009:00: Last suspend didn't reach deepest state
  [   69.780417] usb 1-1.3-port1: status 0101 change 0001
  [   69.793138] PM: suspend exit

Here 1-1.3 is the built-in hub, 1-1.3.1 the HID function and 1-1.3.4
the audio function.

Disconnect the built-in hub during system suspend. Both functions get
the quirk, so it still applies if one of them failed to enumerate. The
microphone then cannot wake the system, which it is not expected to do
anyway, and on resume the hub is reset and both functions come back as
the same devices.

Tested on an AMD laptop (s2idle) with the microphone behind an external
hub that also carries a keyboard and a mouse: with this patch the system
stays in s2idle, the keyboard behind the external hub still wakes it,
and the microphone records normally after resume. Booting with
usbcore.quirks=0951:171d:s,0951:171f:s, which clears the quirk again,
brings the bouncing suspend back.

This patch and its changelog were written with the help of an AI
coding assistant (Claude, claude-opus-5-5). I reviewed the result and
ran the tests described above.

Signed-off-by: Oleh Kurudz <admin@or1k.net>
---
 drivers/usb/core/quirks.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/usb/core/quirks.c b/drivers/usb/core/quirks.c
index 3933cf9c0..97c63aabb 100644
--- a/drivers/usb/core/quirks.c
+++ b/drivers/usb/core/quirks.c
@@ -428,6 +428,12 @@ static const struct usb_device_id usb_quirk_list[] = {
 	/* Kingston DataTraveler 3.0 */
 	{ USB_DEVICE(0x0951, 0x1666), .driver_info = USB_QUIRK_NO_LPM },
 
+	/* HyperX QuadCast S, audio and HID functions behind its built-in hub */
+	{ USB_DEVICE(0x0951, 0x171d), .driver_info =
+			USB_QUIRK_DISCONNECT_PARENT_SUSPEND },
+	{ USB_DEVICE(0x0951, 0x171f), .driver_info =
+			USB_QUIRK_DISCONNECT_PARENT_SUSPEND },
+
 	/* TOSHIBA TransMemory-Mx */
 	{ USB_DEVICE(0x0930, 0x1408), .driver_info = USB_QUIRK_NO_LPM },
 

-- 
2.56.1

