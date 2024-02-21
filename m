From: Janne Grunau <j@jannau.net>
Date: Wed, 21 Feb 2024 08:25:04 +0100
Subject: [PATCH 4/6] usb: kbd: Ignore Yubikeys
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-asahi-keyboards-v1-4-814b2e741790@jannau.net>
References: <20240221-asahi-keyboards-v1-0-814b2e741790@jannau.net>
In-Reply-To: <20240221-asahi-keyboards-v1-0-814b2e741790@jannau.net>
To: Bin Meng <bmeng.cn@gmail.com>, Marek Vasut <marex@denx.de>, 
 Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, asahi@lists.linux.dev, 
 Janne Grunau <j@jannau.net>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1802; i=j@jannau.net;
 h=from:subject:message-id; bh=Skl/l5JT0ZXzNGK38C7Z1Yy3xS+vbisq7v96Lch2Hkk=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtSrS6OaihRjt+uJPnx35LPEscrmrT9WJTRe2e7WEXO+t
 oBzufP1jlIWBjEuBlkxRZYk7ZcdDKtrFGNqH4TBzGFlAhnCwMUpABMxvsrwP+a9gfZJk1krpf/N
 jFa5scCk63Ox7LLvXbK7uvIT3Of+Wc7wT5ttF/dHj/p5Gt9Fuuc/Yd2axbd02d5cl7+xUq+yDv/
 O5gIA
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

We currently only support one USB keyboard device, but some devices
emulate keyboards for other purposes. Most commonly, people run into
this with Yubikeys, so let's ignore those.

Even if we end up supporting multiple keyboards in the future, it's
safer to ignore known non-keyboard devices.

Signed-off-by: Hector Martin <marcan@marcan.st>
---
 common/usb_kbd.c | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/common/usb_kbd.c b/common/usb_kbd.c
index 4cbc9acb73..774d3555d9 100644
--- a/common/usb_kbd.c
+++ b/common/usb_kbd.c
@@ -120,6 +120,15 @@ struct usb_kbd_pdata {
 
 extern int __maybe_unused net_busy_flag;
 
+/*
+ * Since we only support one usbkbd device in the iomux,
+ * ignore common keyboard-emulating devices that aren't
+ * real keyboards.
+ */
+const uint16_t vid_blocklist[] = {
+	0x1050, /* Yubico */
+};
+
 /* The period of time between two calls of usb_kbd_testc(). */
 static unsigned long kbd_testc_tms;
 
@@ -465,6 +474,7 @@ static int usb_kbd_probe_dev(struct usb_device *dev, unsigned int ifnum)
 	struct usb_endpoint_descriptor *ep;
 	struct usb_kbd_pdata *data;
 	int epNum;
+	int i;
 
 	if (dev->descriptor.bNumConfigurations != 1)
 		return 0;
@@ -480,6 +490,15 @@ static int usb_kbd_probe_dev(struct usb_device *dev, unsigned int ifnum)
 	if (iface->desc.bInterfaceProtocol != USB_PROT_HID_KEYBOARD)
 		return 0;
 
+	for (i = 0; i < ARRAY_SIZE(vid_blocklist); i++) {
+		if (dev->descriptor.idVendor == vid_blocklist[i]) {
+			printf("Ignoring keyboard device 0x%x:0x%x\n",
+			       dev->descriptor.idVendor,
+			       dev->descriptor.idProduct);
+			return 0;
+		}
+	}
+
 	for (epNum = 0; epNum < iface->desc.bNumEndpoints; epNum++) {
 		ep = &iface->ep_desc[epNum];
 

-- 
2.43.2

