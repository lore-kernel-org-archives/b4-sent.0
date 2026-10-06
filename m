From: Hans van Essen <hans@kilurion.com>
Date: Tue, 06 Oct 2026 12:39:22 +0200
Subject: [PATCH] HID: asus: Resume the device before sending feature
 reports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-hid-asus-autosuspend-v1-1-0c3df3121063@kilurion.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqEMAyF4atI1gZqwSpzlcFFbaPGRZXGilC8u
 3Vm9fgW788gFJkEPlWGSCcLb6GgqStwiw0zIfti0EqbRimDC3u0kgRtOrayOwWPhrSZ2r7rO+u
 gXPdIE1+/7Hf4W9K4kjveFtz3A+Kq7Ol4AAAA
X-Change-ID: 20261006-hid-asus-autosuspend-6e26f58787ac
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hans van Essen <hans@kilurion.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791283169; l=2846;
 i=hans@kilurion.com; s=20261006; h=from:subject:message-id;
 bh=9QfnflIXuuK4jOk4CkZW1MI0rh7BoL+EnE3PHnQPEZM=;
 b=AtXjKp1O0PfU//ZOMoRQLAoKgYF+1v+nFH4i6vT9zEu/0ReaRSS2l8K2cioWMYldKx2pdbT2d
 AZ3MqtBhpVuCYDdCtLWNKfKwzmGZGR9KGHF5K17Nteae9IbLd5CArc8
X-Developer-Key: i=hans@kilurion.com; a=ed25519;
 pk=1Qqd7FQOGBgV4kpJP4kZLbjH4wFg7+EdQaxwe+dr7Bs=
X-Endpoint-Received: by B4 Relay for hans@kilurion.com/20261006 with auth_id=1123
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

asus_kbd_set_report() sends a SET_REPORT control request through
hid_hw_raw_request(). usbhid does not take a runtime PM reference for
raw requests, so the request fails while the keyboard is runtime
suspended. On a ROG Zephyrus G16 (GU605CW, N-KEY 0b05:19b6) with
power/control set to auto, every deferred backlight change from
asus_work() is lost:

  asus 0003:0B05:19B6.0002: Asus failed to set keyboard backlight: -108

Wrap the request in hid_hw_power(), as hidraw does, so the device is
resumed for the write and can autosuspend again afterwards.

Assisted-by: LLM
Signed-off-by: Hans van Essen <hans@kilurion.com>
---
Tested on an ASUS ROG Zephyrus G16 (GU605CW) with v7.3-rc5: with
power/control=auto and usbhid.ignoreled=1 the N-KEY keyboard
autosuspends. Backlight changes via asus::kbd_backlight now resume it,
apply, and the device suspends again after autosuspend_delay_ms. Before
this patch every change failed with -108.

Taking an autopm reference in usbhid's raw request path would fix this
for every driver, but hidraw, hiddev and several HID drivers
(hid-cp2112, hid-steelseries, hid-google-hammer, ...) already call
hid_hw_power() themselves, so this keeps the fix local to hid-asus.

No Fixes: tag: the write path never handled runtime suspend, it only
shows once autosuspend is enabled for the keyboard.

The fix was developed with an AI coding assistant (GitHub Copilot);
I reviewed the change and tested it on the hardware above.
---
 drivers/hid/hid-asus.c | 12 ++++++++++--
 1 file changed, 10 insertions(+), 2 deletions(-)

diff --git a/drivers/hid/hid-asus.c b/drivers/hid/hid-asus.c
index 7dc6417fe..bdb2c8b64 100644
--- a/drivers/hid/hid-asus.c
+++ b/drivers/hid/hid-asus.c
@@ -576,16 +576,24 @@ static int asus_raw_event(struct hid_device *hdev,
 
 static int asus_kbd_set_report(struct hid_device *hdev, const u8 *buf, size_t buf_size)
 {
+	int ret;
 	u8 *dmabuf __free(kfree) = kmemdup(buf, buf_size, GFP_KERNEL);
 	if (!dmabuf)
 		return -ENOMEM;
 
+	/* The device may be runtime suspended, e.g. for a deferred backlight change */
+	ret = hid_hw_power(hdev, PM_HINT_FULLON);
+	if (ret < 0)
+		return ret;
+
 	/*
 	 * The report ID should be set from the incoming buffer due to LED and key
 	 * interfaces having different pages
 	 */
-	return hid_hw_raw_request(hdev, buf[0], dmabuf, buf_size, HID_FEATURE_REPORT,
-				  HID_REQ_SET_REPORT);
+	ret = hid_hw_raw_request(hdev, buf[0], dmabuf, buf_size, HID_FEATURE_REPORT,
+				 HID_REQ_SET_REPORT);
+	hid_hw_power(hdev, PM_HINT_NORMAL);
+	return ret;
 }
 
 static int asus_kbd_init(struct hid_device *hdev, u8 report_id)

---
base-commit: 145c2b2e9a5c0f794fb4009bcb072ab19f8ccfcd
change-id: 20261006-hid-asus-autosuspend-6e26f58787ac

Best regards,
--  
Hans van Essen <hans@kilurion.com>

