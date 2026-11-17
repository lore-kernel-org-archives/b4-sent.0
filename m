From: Robin Tetour <git@robtet.dev>
Date: Tue, 17 Nov 2026 14:01:40 +0100
Subject: [PATCH] HID: logitech-hidpp: Add MX Anywhere 2S over BT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-hidpp-mx-anywhere-2s-bt-v1-1-e35f46d3c668@robtet.dev>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/yXMTQ6CMBBA4auQWTsJU+MPXsWwaOlAx8TadAAxh
 LtbZfkt3ltBOQsr3KoVMs+i8ooFdKigCzYOjOKLwdTmTEQXDOJTwueCNn7egTOjUXQj9pZc05y
 8O15rKHXK3MvyP9/b3Tq5B3fjbwfb9gXKGpztewAAAA==
X-Change-ID: 20261117-hidpp-mx-anywhere-2s-bt-fa1b995db380
To: =?utf-8?q?Filipe_La=C3=ADns?= <lains@riseup.net>, 
 Bastien Nocera <hadess@hadess.net>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robin Tetour <git@robtet.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794920502; l=1331;
 i=git@robtet.dev; s=20261117; h=from:subject:message-id;
 bh=Ev+AfgsKii5S0dicVZKg/JxOksO8loG6ebX12jOZnYg=;
 b=LlC0m+6U/LVGNy32lI1wgeoOUn+lncpo2FYX52P/nWGG1jDRCgWMgi6viRHuj+yO/IYCoqTYi
 HZS3to78x6fCcGqgeJj6+kXtjvZRkn9Q/iehZkGo7x8iwZAlsKdxEcn
X-Developer-Key: i=git@robtet.dev; a=ed25519;
 pk=BJPkYl/vUfMfH9kETH7XwcLHLfC45Gy9+aWTTMkyFSs=
X-Endpoint-Received: by B4 Relay for git@robtet.dev/20261117 with auth_id=1549
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MX Anywhere 2S (046d:b01a) is missing from hidpp_devices[], so
when connected over Bluetooth it is bound by hid-generic and its
HID++ features, including high-resolution scrolling, are unavailable.

Tested by adding the ID via new_id: hid-logitech-hidpp binds and
detects the hi-res scroll wheel.

Signed-off-by: Robin Tetour <git@robtet.dev>
---
 drivers/hid/hid-logitech-hidpp.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/hid/hid-logitech-hidpp.c b/drivers/hid/hid-logitech-hidpp.c
index 27d83b8bbaa..4b266997568 100644
--- a/drivers/hid/hid-logitech-hidpp.c
+++ b/drivers/hid/hid-logitech-hidpp.c
@@ -4936,6 +4936,8 @@ static const struct hid_device_id hidpp_devices[] = {
 	  HID_BLUETOOTH_DEVICE(USB_VENDOR_ID_LOGITECH, 0xb015) },
 	{ /* MX Master 2S mouse over Bluetooth */
 	  HID_BLUETOOTH_DEVICE(USB_VENDOR_ID_LOGITECH, 0xb019) },
+	{ /* MX Anywhere 2S mouse over Bluetooth */
+	  HID_BLUETOOTH_DEVICE(USB_VENDOR_ID_LOGITECH, 0xb01a) },
 	{ /* MX Ergo trackball over Bluetooth */
 	  HID_BLUETOOTH_DEVICE(USB_VENDOR_ID_LOGITECH, 0xb01d) },
 	{ HID_BLUETOOTH_DEVICE(USB_VENDOR_ID_LOGITECH, 0xb01e) },

---
base-commit: 720806515cb6921ab05caaa6f470f7054b56385e
change-id: 20261117-hidpp-mx-anywhere-2s-bt-fa1b995db380

Best regards,
--  
Robin Tetour <git@robtet.dev>

