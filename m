From: Pawel Laszczak <pawell@cadence.com>
Date: Fri, 17 Jul 2026 12:44:15 +0200
Subject: [PATCH 2/3] usb: gadget: composite: Support eUSB2v2 bulk MPS
 update request
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260717-eusb2v2-packet-size-v1-2-67c611bd0c5b@cadence.com>
References: <20260717-eusb2v2-packet-size-v1-0-67c611bd0c5b@cadence.com>
In-Reply-To: <20260717-eusb2v2-packet-size-v1-0-67c611bd0c5b@cadence.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Mathias Nyman <mathias.nyman@intel.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Pawel Laszczak <pawell@cadence.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784285103; l=4930;
 i=pawell@cadence.com; h=from:subject:message-id;
 bh=BinsopW6J/BJzPhINKchDQl5qlxVOPT1dCsHQoufo9s=;
 b=oRplN9glS7CnNkMYW7suoV3GQopKgyXSB/iq9eO1ojSik5QaZ9d/OiPelyBkpH4lVH2LTyj/S
 qvtbOUejU3/C599lzN7feIVEe5jgGZkEy1ietqklrbsV5AhcSjUH1Du
X-Developer-Key: i=pawell@cadence.com; a=ed25519;
 pk=EUPBvLO9CDg7j6defeDl2iqi+z5Ivqu4Z46aiqe7dYc=
X-Endpoint-Received: by B4 Relay for pawell@cadence.com/default with auth_id=707
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for eUSB2v2 1024-byte Bulk MPS negotiation to the Gadget
Composite framework.

If 'gadget->is_eusb2v2' is set, force bcdUSB to 0x0230 and bMaxPacketSize0
to 64 bytes. Handle the USB_DEVICE_BULK_MAX_PACKET_UPDATE feature request
by introducing eusb2_update_mps_bulk(), which dynamically updates the
wMaxPacketSize of all HS Bulk endpoint descriptors to 1024 bytes before
the device is configured.

Signed-off-by: Pawel Laszczak <pawell@cadence.com>
---
 drivers/usb/gadget/composite.c | 67 ++++++++++++++++++++++++++++++++++++++----
 include/linux/usb/gadget.h     |  2 ++
 2 files changed, 63 insertions(+), 6 deletions(-)

diff --git a/drivers/usb/gadget/composite.c b/drivers/usb/gadget/composite.c
index dc3664374596..e009f8c4281c 100644
--- a/drivers/usb/gadget/composite.c
+++ b/drivers/usb/gadget/composite.c
@@ -924,6 +924,48 @@ static void device_qual(struct usb_composite_dev *cdev)
 }
 
 /*-------------------------------------------------------------------------*/
+static void eusb2_update_ep_mps(struct usb_descriptor_header *header, __le16 mps)
+{
+	struct usb_endpoint_descriptor *epd;
+
+	if (header->bDescriptorType != USB_DT_ENDPOINT)
+		return;
+
+	epd = (void *)header;
+	if (usb_endpoint_xfer_bulk(epd))
+		epd->wMaxPacketSize = mps;
+}
+
+static int eusb2_update_mps_bulk(struct usb_composite_dev *cdev, bool set)
+{
+	__le16 mps = cpu_to_le16(set ? 1024 : 512);
+	struct usb_gadget *gadget = cdev->gadget;
+	struct usb_configuration *config;
+	struct usb_function *f;
+
+	if (!gadget->is_eusb2v2)
+		return -EINVAL;
+
+	if (set && gadget->state >= USB_STATE_CONFIGURED)
+		return -EINVAL;
+
+	list_for_each_entry(config, &cdev->configs, list) {
+		if (!config->highspeed)
+			continue;
+
+		list_for_each_entry(f, &config->functions, list) {
+			struct usb_descriptor_header **desc = f->hs_descriptors;
+
+			if (!desc)
+				continue;
+
+			for (; *desc; desc++)
+				eusb2_update_ep_mps(*desc, mps);
+		}
+	}
+
+	return 0;
+}
 
 static void reset_config(struct usb_composite_dev *cdev)
 {
@@ -971,8 +1013,10 @@ static int set_config(struct usb_composite_dev *cdev,
 		if (result < 0)
 			goto done;
 	} else { /* Zero configuration value - need to reset the config */
-		if (cdev->config)
+		if (cdev->config) {
 			reset_config(cdev);
+			eusb2_update_mps_bulk(cdev, false);
+		}
 		result = 0;
 	}
 
@@ -1807,7 +1851,11 @@ composite_setup(struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 				count_configs(cdev, USB_DT_DEVICE);
 			cdev->desc.bMaxPacketSize0 =
 				cdev->gadget->ep0->maxpacket;
-			if (gadget_is_superspeed(gadget)) {
+
+			if (gadget->is_eusb2v2) {
+				cdev->desc.bcdUSB = cpu_to_le16(0x0230);
+				cdev->desc.bMaxPacketSize0 = 64;
+			} else if (gadget_is_superspeed(gadget)) {
 				if (gadget->speed >= USB_SPEED_SUPER) {
 					cdev->desc.bcdUSB = cpu_to_le16(0x0320);
 					cdev->desc.bMaxPacketSize0 = 9;
@@ -2005,12 +2053,18 @@ composite_setup(struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 	 */
 	case USB_REQ_CLEAR_FEATURE:
 	case USB_REQ_SET_FEATURE:
-		if (!gadget_is_superspeed(gadget))
-			goto unknown;
-		if (ctrl->bRequestType != (USB_DIR_OUT | USB_RECIP_INTERFACE))
-			goto unknown;
 		switch (w_value) {
+		case USB_DEVICE_BULK_MAX_PACKET_UPDATE:
+			if (ctrl->bRequestType != (USB_DIR_OUT | USB_RECIP_DEVICE))
+				goto unknown;
+
+			value = eusb2_update_mps_bulk(cdev, true);
+			break;
 		case USB_INTRF_FUNC_SUSPEND:
+			if (!gadget_is_superspeed(gadget))
+				goto unknown;
+			if (ctrl->bRequestType != (USB_DIR_OUT | USB_RECIP_INTERFACE))
+				goto unknown;
 			if (!cdev->config || intf >= MAX_CONFIG_INTERFACES)
 				break;
 			f = cdev->config->interface[intf];
@@ -2303,6 +2357,7 @@ static void __composite_disconnect(struct usb_gadget *gadget)
 
 void composite_disconnect(struct usb_gadget *gadget)
 {
+	eusb2_update_mps_bulk(get_gadget_data(gadget), false);
 	usb_gadget_vbus_draw(gadget, 0);
 	__composite_disconnect(gadget);
 }
diff --git a/include/linux/usb/gadget.h b/include/linux/usb/gadget.h
index 8285b19a25e0..3c554fe95f87 100644
--- a/include/linux/usb/gadget.h
+++ b/include/linux/usb/gadget.h
@@ -420,6 +420,7 @@ struct usb_gadget_ops {
  * @wakeup_armed: True if gadget is armed by the host for remote wakeup.
  * @irq: the interrupt number for device controller.
  * @id_number: a unique ID number for ensuring that gadget names are distinct
+ * @is_eusb2v2: True if controller is Embedded usb2.
  *
  * Gadgets have a mostly-portable "gadget driver" implementing device
  * functions, handling all usb configurations and interfaces.  Gadget
@@ -483,6 +484,7 @@ struct usb_gadget {
 	unsigned			lpm_capable:1;
 	unsigned			wakeup_capable:1;
 	unsigned			wakeup_armed:1;
+	unsigned			is_eusb2v2:1;
 	int				irq;
 	int				id_number;
 };

-- 
2.43.0

