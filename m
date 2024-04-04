From: Janne Grunau <j@jannau.net>
Date: Thu, 04 Apr 2024 08:25:53 +0200
Subject: [PATCH v4 5/6] usb: kbd: support Apple Magic Keyboards (2021)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240404-asahi-keyboards-v4-5-2266033feaff@jannau.net>
References: <20240404-asahi-keyboards-v4-0-2266033feaff@jannau.net>
In-Reply-To: <20240404-asahi-keyboards-v4-0-2266033feaff@jannau.net>
To: Bin Meng <bmeng.cn@gmail.com>, Marek Vasut <marex@denx.de>, 
 Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Joe Hershberger <joe.hershberger@ni.com>
Cc: u-boot@lists.denx.de, asahi@lists.linux.dev, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=7097; i=j@jannau.net;
 h=from:subject:message-id; bh=P+aywpOW3f5+9ZY1LlcprP3UqLhWTiCGQg2stJjsQPw=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhjQ+988NbI/W3VQIbitXrGRgLC7YdGPB5+MfZC+ej8u7t
 6Z1UcvMjlIWBjEuBlkxRZYk7ZcdDKtrFGNqH4TBzGFlAhnCwMUpABMRn8jwk/HVCyu2b3az6j70
 zPz5l+F13etp0eIc5hOF565x3Dgv6z/D/6oXtQtbnL49Ph9+MPVYzwqLMotnsmUtZx52vi8qiLm
 kzAoA
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apple USB keyboards (Magic Keyboard from 2021 (product id 0x029c)) carry
the HID keyboard boot protocol on the second interface descriptor.
Probe via vendor and product IDs since the class/subclass/protocol match
uses the first interface descriptor.
Probe the two first interface descriptors for the HID keyboard boot
protocol.

USB configuration descriptor for reference:

| Bus 003 Device 002: ID 05ac:029c Apple, Inc. Magic Keyboard
| Device Descriptor:
|   bLength                18
|   bDescriptorType         1
|   bcdUSB               2.00
|   bDeviceClass            0 [unknown]
|   bDeviceSubClass         0 [unknown]
|   bDeviceProtocol         0
|   bMaxPacketSize0        64
|   idVendor           0x05ac Apple, Inc.
|   idProduct          0x029c Magic Keyboard
|   bcdDevice            3.90
|   iManufacturer           1 Apple Inc.
|   iProduct                2 Magic Keyboard
|   iSerial                 3 ...
|   bNumConfigurations      1
|   Configuration Descriptor:
|     bLength                 9
|     bDescriptorType         2
|     wTotalLength       0x003b
|     bNumInterfaces          2
|     bConfigurationValue     1
|     iConfiguration          4 Keyboard
|     bmAttributes         0xa0
|       (Bus Powered)
|       Remote Wakeup
|     MaxPower              500mA
|     Interface Descriptor:
|       bLength                 9
|       bDescriptorType         4
|       bInterfaceNumber        0
|       bAlternateSetting       0
|       bNumEndpoints           1
|       bInterfaceClass         3 Human Interface Device
|       bInterfaceSubClass      0 [unknown]
|       bInterfaceProtocol      0
|       iInterface              5 Device Management
|         HID Device Descriptor:
|           bLength                 9
|           bDescriptorType        33
|           bcdHID               1.10
|           bCountryCode            0 Not supported
|           bNumDescriptors         1
|           bDescriptorType        34 Report
|           wDescriptorLength      83
|           Report Descriptors:
|             ** UNAVAILABLE **
|       Endpoint Descriptor:
|         bLength                 7
|         bDescriptorType         5
|         bEndpointAddress     0x81  EP 1 IN
|         bmAttributes            3
|           Transfer Type            Interrupt
|           Synch Type               None
|           Usage Type               Data
|         wMaxPacketSize     0x0010  1x 16 bytes
|         bInterval               8
|     Interface Descriptor:
|       bLength                 9
|       bDescriptorType         4
|       bInterfaceNumber        1
|       bAlternateSetting       0
|       bNumEndpoints           1
|       bInterfaceClass         3 Human Interface Device
|       bInterfaceSubClass      1 Boot Interface Subclass
|       bInterfaceProtocol      1 Keyboard
|       iInterface              6 Keyboard / Boot
|         HID Device Descriptor:
|           bLength                 9
|           bDescriptorType        33
|           bcdHID               1.10
|           bCountryCode           13 International (ISO)
|           bNumDescriptors         1
|           bDescriptorType        34 Report
|           wDescriptorLength     207
|           Report Descriptors:
|             ** UNAVAILABLE **
|       Endpoint Descriptor:
|         bLength                 7
|         bDescriptorType         5
|         bEndpointAddress     0x82  EP 2 IN
|         bmAttributes            3
|           Transfer Type            Interrupt
|           Synch Type               None
|           Usage Type               Data
|         wMaxPacketSize     0x0010  1x 16 bytes
|         bInterval               8

Reviewed-by: Marek Vasut <marex@denx.de>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 common/usb_kbd.c | 37 ++++++++++++++++++++++++++++++++++---
 1 file changed, 34 insertions(+), 3 deletions(-)

diff --git a/common/usb_kbd.c b/common/usb_kbd.c
index 4cbc9acb73..b2361bbf18 100644
--- a/common/usb_kbd.c
+++ b/common/usb_kbd.c
@@ -23,6 +23,14 @@
 
 #include <usb.h>
 
+/*
+ * USB vendor and product IDs used for quirks.
+ */
+#define USB_VENDOR_ID_APPLE	0x05ac
+#define USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_2021			0x029c
+#define USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_FINGERPRINT_2021	0x029a
+#define USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_NUMPAD_2021		0x029f
+
 /*
  * If overwrite_console returns 1, the stdin, stderr and stdout
  * are switched to the serial port, else the settings in the
@@ -106,6 +114,8 @@ struct usb_kbd_pdata {
 	unsigned long	last_report;
 	struct int_queue *intq;
 
+	uint32_t	ifnum;
+
 	uint32_t	repeat_delay;
 
 	uint32_t	usb_in_pointer;
@@ -150,8 +160,8 @@ static void usb_kbd_put_queue(struct usb_kbd_pdata *data, u8 c)
  */
 static void usb_kbd_setled(struct usb_device *dev)
 {
-	struct usb_interface *iface = &dev->config.if_desc[0];
 	struct usb_kbd_pdata *data = dev->privptr;
+	struct usb_interface *iface = &dev->config.if_desc[data->ifnum];
 	ALLOC_ALIGN_BUFFER(uint32_t, leds, 1, USB_DMA_MINALIGN);
 
 	*leds = data->flags & USB_KBD_LEDMASK;
@@ -365,7 +375,7 @@ static inline void usb_kbd_poll_for_event(struct usb_device *dev)
 #if defined(CONFIG_SYS_USB_EVENT_POLL_VIA_CONTROL_EP)
 	struct usb_interface *iface;
 	struct usb_kbd_pdata *data = dev->privptr;
-	iface = &dev->config.if_desc[0];
+	iface = &dev->config.if_desc[data->ifnum];
 	usb_get_report(dev, iface->desc.bInterfaceNumber,
 		       1, 0, data->new, USB_KBD_BOOT_REPORT_SIZE);
 	if (memcmp(data->old, data->new, USB_KBD_BOOT_REPORT_SIZE)) {
@@ -509,6 +519,8 @@ static int usb_kbd_probe_dev(struct usb_device *dev, unsigned int ifnum)
 	data->new = memalign(USB_DMA_MINALIGN,
 		roundup(USB_KBD_BOOT_REPORT_SIZE, USB_DMA_MINALIGN));
 
+	data->ifnum = ifnum;
+
 	/* Insert private data into USB device structure */
 	dev->privptr = data;
 
@@ -561,10 +573,17 @@ static int probe_usb_keyboard(struct usb_device *dev)
 {
 	char *stdinname;
 	struct stdio_dev usb_kbd_dev;
+	unsigned int ifnum;
+	unsigned int max_ifnum = min((unsigned int)USB_MAX_ACTIVE_INTERFACES,
+				     (unsigned int)dev->config.no_of_if);
 	int error;
 
 	/* Try probing the keyboard */
-	if (usb_kbd_probe_dev(dev, 0) != 1)
+	for (ifnum = 0; ifnum < max_ifnum; ifnum++) {
+		if (usb_kbd_probe_dev(dev, ifnum) == 1)
+			break;
+	}
+	if (ifnum >= max_ifnum)
 		return -ENOENT;
 
 	/* Register the keyboard */
@@ -731,6 +750,18 @@ static const struct usb_device_id kbd_id_table[] = {
 		.bInterfaceSubClass = USB_SUB_HID_BOOT,
 		.bInterfaceProtocol = USB_PROT_HID_KEYBOARD,
 	},
+	{
+		USB_DEVICE(USB_VENDOR_ID_APPLE,
+			   USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_2021),
+	},
+	{
+		USB_DEVICE(USB_VENDOR_ID_APPLE,
+			   USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_FINGERPRINT_2021),
+	},
+	{
+		USB_DEVICE(USB_VENDOR_ID_APPLE,
+			   USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_NUMPAD_2021),
+	},
 	{ }		/* Terminating entry */
 };
 

-- 
2.44.0

