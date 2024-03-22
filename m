From: Janne Grunau <j@jannau.net>
Date: Fri, 22 Mar 2024 08:47:09 +0100
Subject: [PATCH v3 6/6] usb: kbd: Add probe quirk for Apple and Keychron
 keyboards
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240322-asahi-keyboards-v3-6-3106dd4c4e19@jannau.net>
References: <20240322-asahi-keyboards-v3-0-3106dd4c4e19@jannau.net>
In-Reply-To: <20240322-asahi-keyboards-v3-0-3106dd4c4e19@jannau.net>
To: Bin Meng <bmeng.cn@gmail.com>, Marek Vasut <marex@denx.de>, 
 Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Joe Hershberger <joe.hershberger@ni.com>
Cc: u-boot@lists.denx.de, asahi@lists.linux.dev, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2657; i=j@jannau.net;
 h=from:subject:message-id; bh=bgC5VMp6aw6U5Uhn14jI61Gw7z5YE8JE2SujySRwwJE=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtS/5i1aaTURbQt9l8j7GcpkLAuZxvorW+Dnlv16Nmvyt
 7WHZcd3lLIwiHExyIopsiRpv+xgWF2jGFP7IAxmDisTyBAGLk4BmIjxJob/EbWB1zbcZM4xWM6l
 PDFgS8aWyX+3fGQ8wdzxIsTbRGN/JCND2wrPpN1p15QF6jTZpHV+cbdu2zMpL2qOxirh16ynX/3
 kAwA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Those keyboards do not return the current device state. Polling will
timeout unless there are key presses. This is not a problem during
operation but the initial device state query during probing will fail.
Skip this step in usb_kbd_probe_dev() to make these devices useable.
Not all Apple keyboards behave like this. A keyboard with USB
vendor/product ID 05ac:0221 is reported to work with the current code.
Unfortunately some Keychron keyboards "re-use" Apple's vendor ID and
show the same behavior (Keychron C2, 05ac:024f for example).

Reviewed-by: Marek Vasut <marex@denx.de>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 common/usb_kbd.c | 22 ++++++++++++++++++++++
 1 file changed, 22 insertions(+)

diff --git a/common/usb_kbd.c b/common/usb_kbd.c
index b2361bbf18..820f591fc5 100644
--- a/common/usb_kbd.c
+++ b/common/usb_kbd.c
@@ -31,6 +31,10 @@
 #define USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_FINGERPRINT_2021	0x029a
 #define USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_NUMPAD_2021		0x029f
 
+#define USB_VENDOR_ID_KEYCHRON	0x3434
+
+#define USB_HID_QUIRK_POLL_NO_REPORT_IDLE	BIT(0)
+
 /*
  * If overwrite_console returns 1, the stdin, stderr and stdout
  * are switched to the serial port, else the settings in the
@@ -474,6 +478,7 @@ static int usb_kbd_probe_dev(struct usb_device *dev, unsigned int ifnum)
 	struct usb_interface *iface;
 	struct usb_endpoint_descriptor *ep;
 	struct usb_kbd_pdata *data;
+	unsigned int quirks = 0;
 	int epNum;
 
 	if (dev->descriptor.bNumConfigurations != 1)
@@ -506,6 +511,15 @@ static int usb_kbd_probe_dev(struct usb_device *dev, unsigned int ifnum)
 
 	debug("USB KBD: found interrupt EP: 0x%x\n", ep->bEndpointAddress);
 
+	switch (dev->descriptor.idVendor) {
+	case USB_VENDOR_ID_APPLE:
+	case USB_VENDOR_ID_KEYCHRON:
+		quirks |= USB_HID_QUIRK_POLL_NO_REPORT_IDLE;
+		break;
+	default:
+		break;
+	}
+
 	data = malloc(sizeof(struct usb_kbd_pdata));
 	if (!data) {
 		printf("USB KBD: Error allocating private data\n");
@@ -546,6 +560,14 @@ static int usb_kbd_probe_dev(struct usb_device *dev, unsigned int ifnum)
 	usb_set_idle(dev, iface->desc.bInterfaceNumber, 0, 0);
 #endif
 
+	/*
+	 * Apple and Keychron keyboards do not report the device state. Reports
+	 * are only returned during key presses.
+	 */
+	if (quirks & USB_HID_QUIRK_POLL_NO_REPORT_IDLE) {
+		debug("USB KBD: quirk: skip testing device state\n");
+		return 1;
+	}
 	debug("USB KBD: enable interrupt pipe...\n");
 #ifdef CONFIG_SYS_USB_EVENT_POLL_VIA_INT_QUEUE
 	data->intq = create_int_queue(dev, data->intpipe, 1,

-- 
2.44.0

