From: Ahmad Fatoum <a.fatoum@barebox.org>
Date: Mon, 14 Oct 2024 17:32:38 +0200
Subject: [PATCH] input: usb_kbd: make polling interval configurable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241014-usb_kbd-polling_interval-v1-1-92309deabaf2@barebox.org>
X-B4-Tracking: v=1; b=H4sIAJU5DWcC/x3M0QpAMBSA4VfRubbaGMmrSMI55mSNNqS0d7dcf
 hf//0IgzxSgzV7wdHPg3SWoPIN5HZ0hwZgMhSy0kkqLK0zDNqE4dmvZmYHdSf4erZDUaJQ1Nlh
 WkPLD08LPv+76GD/JiObWagAAAA==
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Ahmad Fatoum <a.fatoum@barebox.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1232; i=a.fatoum@barebox.org;
 h=from:subject:message-id; bh=+oTe0y6oPSO9CGWeM1TS2pqbtm7feOiUaQ80clLoiBI=;
 b=owEBbQKS/ZANAwAIAcPqw96TIdWbAcsmYgBnDTmbsunNEfFmGcgfmWhpxfDVMBa8MYSF07Npf
 98m9VIDaHiJAjMEAAEIAB0WIQTK3+EIrTqYqXmq7ubD6sPekyHVmwUCZw05mwAKCRDD6sPekyHV
 m3HmD/0akWU9RghUv9cKcB5XbMJ5HC705NvtYd89i6bZE17FTjN52K/CkXjXjgYrn9O97MX6PWS
 xMDn8sHRpOOc5V6juYg3XSqCcR99dSfhvc3U7nCUJ8O/bxlVmsSEZTPpcgw5PueRxb9cvrlC6oR
 Yw/cEFKIcmbun2QmCVnxCFYfKHoQP/nOnuBu4McxqeqqLKL1pPYDZJOLxaIkoOQxEl52YMzOQGa
 CLpPeF1lv2nRXy9xqpz2s1IiFsw7Z/mfkbPsR5j1qtPqXawtPrQ73EZaMNQd9ks4DzGe3G/skCc
 JK7TSSRy/zzYjqD7l8E83Gq2tsOLXyUFFIqsntjHXzyIkXtPgt0qW1ahbwxYGfulSliAmlO+4vx
 ubNOHZjCFyeoX4OHe3CP1I3hwgBHE6Lj+pjRryRYusR3rbqW5QwwpOc64YPAk+LA8YnSfukc1NI
 8lbBBLI734SUXndWTYeT/XJNB9MvdsgUwFmv4UdUXI+fWh96Pms6X+gw86n3TuafJr6JhwSzecA
 Jwf54FQ/aLfXZJ4E7qfwR8y8yB77QGq1FXZ2Ws8Rt52FxqfS5A79QH7TapdwMlGxKK1QtXrH/+0
 eL7m803ADIW8sLKDecm+CJpb+9dMGfS8UJo7ZIsPgDSaNlPPqhY3sVgdKXcIxkG0WDB7vBq0xcW
 c23xMv2LGunMREg==
X-Developer-Key: i=a.fatoum@barebox.org; a=openpgp;
 fpr=CADFE108AD3A98A979AAEEE6C3EAC3DE9321D59B
X-Endpoint-Received: by B4 Relay for a.fatoum@barebox.org/default with auth_id=246
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We currently use whatever polling interval the keyboard reports, but in
some keyboard it can be useful to set a lower interval, e.g. for better
control of the snake in the barebox demo[1].

Add a parameter to make this possible.

[1]: https://fosstodon.org/@barebox/112983807569839989

Signed-off-by: Ahmad Fatoum <a.fatoum@barebox.org>
---
 drivers/input/usb_kbd.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/input/usb_kbd.c b/drivers/input/usb_kbd.c
index 2e75aabf3da4..d47e760a89ee 100644
--- a/drivers/input/usb_kbd.c
+++ b/drivers/input/usb_kbd.c
@@ -169,6 +169,11 @@ static int usb_kbd_probe(struct usb_device *usbdev,
 	data->intpktsize = min(usb_maxpacket(usbdev, data->intpipe),
 			       USB_KBD_BOOT_REPORT_SIZE);
 	data->intinterval = data->ep->bInterval;
+
+	dev_add_param_uint32(&usbdev->dev, "polling_interval",
+			     NULL, NULL, &data->intinterval, "%u",
+			     NULL);
+
 	/* test polling via interrupt endpoint */
 	data->do_poll = usb_kbd_int_poll;
 	ret = data->do_poll(data);

---
base-commit: ac1be0df8dce0a220e254005e1e07a0d23299f6b
change-id: 20241014-usb_kbd-polling_interval-0e84d06d8d35

Best regards,
-- 
Ahmad Fatoum <a.fatoum@barebox.org>

