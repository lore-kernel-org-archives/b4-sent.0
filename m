From: Pawel Laszczak <pawell@cadence.com>
Date: Fri, 17 Jul 2026 12:44:14 +0200
Subject: [PATCH 1/3] usb: xhci: Add support for eUSB2v2 1024-byte bulk
 packet size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260717-eusb2v2-packet-size-v1-1-67c611bd0c5b@cadence.com>
References: <20260717-eusb2v2-packet-size-v1-0-67c611bd0c5b@cadence.com>
In-Reply-To: <20260717-eusb2v2-packet-size-v1-0-67c611bd0c5b@cadence.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Mathias Nyman <mathias.nyman@intel.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Pawel Laszczak <pawell@cadence.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784285103; l=6736;
 i=pawell@cadence.com; h=from:subject:message-id;
 bh=LTCb4q5/7G6iDHpjLaDdbnS+2jBj5GhRLQszRhvaYEM=;
 b=iAH3Jy139QeSVFElmQBIxMpji2Sddf36QJL6n89+FneRj355jg3TzP9sIpFR2f/MtOObKYH0E
 Qzg+8D9qt0kCFq+8C6I0WuC+xDwHvxofgh5TIt+xwA87PMoGpdYJTXW
X-Developer-Key: i=pawell@cadence.com; a=ed25519;
 pk=EUPBvLO9CDg7j6defeDl2iqi+z5Ivqu4Z46aiqe7dYc=
X-Endpoint-Received: by B4 Relay for pawell@cadence.com/default with auth_id=707
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The eUSB2 v2 specification (bcdUSB 0x0230) introduces support for
1024-byte maximum packet sizes for Bulk endpoints in High-Speed mode.
However, an eUSB2v2 peripheral will revert its internal maximum packet
size back to 512 bytes after events like a bus reset, disconnect, or
deconfiguration.

To support 1024-byte bulk transfers on capable hosts, add a new
is_eusb2v2 flag to the usb_bus structure, populated via the HCCPARAMS2
E2V2C capability bit in the xHCI driver.

When an eUSB2v2 host configures an eUSB2v2 device, issue a specific
SET_FEATURE (USB_DEVICE_BULK_MAX_PACKET_UPDATE) request during device
configuration to switch the peripheral to 1024-byte packet mode, and
allow the xHCI endpoint initialization to accept up to 1024 bytes for
HS bulk endpoints.

Signed-off-by: Pawel Laszczak <pawell@cadence.com>
---
 drivers/usb/core/config.c   |  4 ++-
 drivers/usb/core/message.c  | 65 ++++++++++++++++++++++++++++++++++++++++++++-
 drivers/usb/host/xhci-mem.c | 18 ++++++++++---
 drivers/usb/host/xhci.c     |  3 +++
 include/linux/usb.h         |  4 +++
 5 files changed, 89 insertions(+), 5 deletions(-)

diff --git a/drivers/usb/core/config.c b/drivers/usb/core/config.c
index 45e20c6d76c0..0c7ab3f44cd9 100644
--- a/drivers/usb/core/config.c
+++ b/drivers/usb/core/config.c
@@ -491,7 +491,9 @@ static int usb_parse_endpoint(struct device *ddev, int cfgno,
 	 * be able to handle that particular bug, so let's warn...
 	 */
 	if (udev->speed == USB_SPEED_HIGH && usb_endpoint_xfer_bulk(d)) {
-		if (maxp != 512)
+		struct usb_hcd *hcd =  bus_to_hcd(udev->bus);
+
+		if (maxp != 512 && (bcdUSB != 0x230 || !hcd->self.is_eusb2v2))
 			dev_notice(ddev, "config %d interface %d altsetting %d "
 				"bulk endpoint 0x%X has invalid maxpacket %d\n",
 				cfgno, inum, asnum, d->bEndpointAddress,
diff --git a/drivers/usb/core/message.c b/drivers/usb/core/message.c
index 75e2bfd744a9..3b4f7aedd381 100644
--- a/drivers/usb/core/message.c
+++ b/drivers/usb/core/message.c
@@ -2007,6 +2007,65 @@ int usb_set_wireless_status(struct usb_interface *iface,
 }
 EXPORT_SYMBOL_GPL(usb_set_wireless_status);
 
+/*
+ * eusb_update_max_packet - set or restore max packet size
+ * @udev: target device
+ * @cp: if NULL restore MPS to 512 else set 1024
+ *
+ * This request is specific to eUSB2v2.
+ * An eUSB2v2 peripheral will revert the maximum packet size to 512
+ * for bulk endpoints after bus reset, disconnect and deconfiguration.
+ * This function allows updating the max packet size for BULK endpoints
+ * to 1024 after above events.
+ */
+static void eusb_update_max_packet(struct usb_device *udev, struct usb_host_config *cp)
+{
+	struct usb_host_config *config = cp ? cp : udev->actconfig;
+	struct usb_hcd *hcd = bus_to_hcd(udev->bus);
+	struct usb_interface_cache *intfc;
+	struct usb_host_interface *alt;
+	struct usb_host_endpoint *ep;
+	u16 mps = 512;
+	int i, j, a;
+	int ret;
+
+	if (le16_to_cpu(udev->descriptor.bcdUSB) != 0x0230 ||
+	    !hcd->self.is_eusb2v2)
+		return;
+
+	if (cp) {
+		ret = usb_control_msg(udev, usb_sndctrlpipe(udev, 0),
+				      USB_REQ_SET_FEATURE, USB_RECIP_DEVICE,
+				      USB_DEVICE_BULK_MAX_PACKET_UPDATE, 0, NULL, 0,
+				      USB_CTRL_SET_TIMEOUT);
+		if (ret < 0) {
+			dev_warn(&udev->dev, "eUSB2v2 1KB update failed: %d\n", ret);
+			return;
+		}
+
+		mps = 1024;
+	} else if (!udev->actconfig)
+		return;
+
+	for (i = 0; i < config->desc.bNumInterfaces; i++) {
+		intfc = config->intf_cache[i];
+
+		if (!intfc)
+			continue;
+
+		for (a = 0; a < intfc->num_altsetting; a++) {
+			alt = &intfc->altsetting[a];
+
+			for (j = 0; j < alt->desc.bNumEndpoints; j++) {
+				ep = &alt->endpoint[j];
+
+				if (usb_endpoint_xfer_bulk(&ep->desc))
+					ep->desc.wMaxPacketSize = cpu_to_le16(mps);
+			}
+		}
+	}
+}
+
 /*
  * usb_set_configuration - Makes a particular device setting be current
  * @dev: the device whose configuration is being updated
@@ -2120,8 +2179,12 @@ int usb_set_configuration(struct usb_device *dev, int configuration)
 	/* if it's already configured, clear out old state first.
 	 * getting rid of old interfaces means unbinding their drivers.
 	 */
-	if (dev->state != USB_STATE_ADDRESS)
+	if (dev->state != USB_STATE_ADDRESS) {
+		eusb_update_max_packet(dev, NULL);
 		usb_disable_device(dev, 1);	/* Skip ep0 */
+	}
+
+	eusb_update_max_packet(dev, cp);
 
 	/* Get rid of pending async Set-Config requests for this device */
 	cancel_async_set_config(dev);
diff --git a/drivers/usb/host/xhci-mem.c b/drivers/usb/host/xhci-mem.c
index 997fe90f54e5..a4d3e03f9e14 100644
--- a/drivers/usb/host/xhci-mem.c
+++ b/drivers/usb/host/xhci-mem.c
@@ -1479,10 +1479,22 @@ int xhci_endpoint_init(struct xhci_hcd *xhci,
 	/* Allow 3 retries for everything but isoc, set CErr = 3 */
 	if (!usb_endpoint_xfer_isoc(&ep->desc))
 		err_count = 3;
-	/* HS bulk max packet should be 512, FS bulk supports 8, 16, 32 or 64 */
+
+	/*
+	 * HS bulk max packet should be 512 (or 1024 for eUSB2v2),
+	 * FS bulk supports 8, 16, 32 or 64.
+	 */
 	if (usb_endpoint_xfer_bulk(&ep->desc)) {
-		if (udev->speed == USB_SPEED_HIGH)
-			max_packet = 512;
+		if (udev->speed == USB_SPEED_HIGH) {
+			if (le16_to_cpu(udev->descriptor.bcdUSB) == 0x0230 &&
+			    xhci->hcc_params2 & HCC2_E2V2C) {
+				max_packet = rounddown_pow_of_two(max_packet);
+				max_packet = clamp_val(max_packet, 512, 1024);
+			} else {
+				max_packet = 512;
+			}
+		}
+
 		if (udev->speed == USB_SPEED_FULL) {
 			max_packet = rounddown_pow_of_two(max_packet);
 			max_packet = clamp_val(max_packet, 8, 64);
diff --git a/drivers/usb/host/xhci.c b/drivers/usb/host/xhci.c
index a54f5b57f205..254638dc1e18 100644
--- a/drivers/usb/host/xhci.c
+++ b/drivers/usb/host/xhci.c
@@ -5548,6 +5548,9 @@ int xhci_gen_setup(struct usb_hcd *hcd, xhci_get_quirks_t get_quirks)
 	else
 		xhci_hcd_init_usb2_data(xhci, hcd);
 
+	if (xhci->hcc_params2 & HCC2_E2V2C)
+		hcd->self.is_eusb2v2 = 1;
+
 	xhci_info(xhci, "hcc params 0x%08x hci version 0x%x quirks 0x%016llx\n",
 		  xhci->hcc_params, xhci->hci_version, xhci->quirks);
 
diff --git a/include/linux/usb.h b/include/linux/usb.h
index 25a203ac7a7e..790c2295aec6 100644
--- a/include/linux/usb.h
+++ b/include/linux/usb.h
@@ -464,6 +464,10 @@ struct usb_bus {
 					 * the ep queue on a short transfer
 					 * with the URB_SHORT_NOT_OK flag set.
 					 */
+	unsigned is_eusb2v2:1;		/*
+					 * true when HC controller supports
+					 * eusb2v2
+					 */
 	unsigned no_sg_constraint:1;	/* no sg constraint */
 	unsigned sg_tablesize;		/* 0 or largest number of sg list entries */
 

-- 
2.43.0

