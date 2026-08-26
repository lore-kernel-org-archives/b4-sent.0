From: Pawel Laszczak <pawell@cadence.com>
Date: Wed, 26 Aug 2026 13:24:36 +0200
Subject: [PATCH v2 1/3] usb: xhci: Add support for eUSB2v2 1024-byte bulk
 packet size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260826-eusb2v2-packet-size-v2-1-950f19f38ef0@cadence.com>
References: <20260826-eusb2v2-packet-size-v2-0-950f19f38ef0@cadence.com>
In-Reply-To: <20260826-eusb2v2-packet-size-v2-0-950f19f38ef0@cadence.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Mathias Nyman <mathias.nyman@intel.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Pawel Laszczak <pawell@cadence.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787743495; l=9267;
 i=pawell@cadence.com; h=from:subject:message-id;
 bh=yO0IkkHAwTAYKxm01qJMuWmSxRRO8IsvCrEFHtmxw7g=;
 b=KTLdok1RV3qE4ZlvISUystteWtDU/LAKTvHg8izaNVeTgQlzW0Ir7SA9k3oyTCCwPgOdGmLBR
 hcfTyuBpUu2Cx7p9CIvI6WX1ei41kbPs/z/ONS7i/Z2RJDqaX/KgVjY
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
Changes in v2:
- Removed change in config.c: per eUSB2v2 spec section 5.2, conformant
  devices always report wMaxPacketSize=512 in their descriptor regardless
  of operating mode, so the warning suppression was unnecessary.
- xhci-mem.c: simplified HS bulk clamp
- xhci.c: moved is_eusb2v2 assignment into xhci_hcd_init_usb2_data()
- eusb_update_max_packet(): changed from void to int; returns error on
  SET_FEATURE failure.
- Added eusb2v2_mps_active flag to struct usb_device to track whether
  SET_FEATURE(BULK_MAX_PACKET_UPDATE) succeeded.
- Added hub.c: usb_reset_and_verify_device() now re-issues SET_FEATURE
  after bus reset to restore 1KB mode. Failure triggers re-enumeration
  to prevent a driver from operating with inconsistent MPS state.
---
 drivers/usb/core/hub.c      | 16 ++++++++++
 drivers/usb/core/message.c  | 74 ++++++++++++++++++++++++++++++++++++++++++++-
 drivers/usb/core/usb.h      |  2 ++
 drivers/usb/host/xhci-mem.c | 18 +++++++++--
 drivers/usb/host/xhci.c     |  4 +++
 include/linux/usb.h         |  7 +++++
 6 files changed, 117 insertions(+), 4 deletions(-)

diff --git a/drivers/usb/core/hub.c b/drivers/usb/core/hub.c
index 24960ba9caa9..34cfc44c5df8 100644
--- a/drivers/usb/core/hub.c
+++ b/drivers/usb/core/hub.c
@@ -6252,6 +6252,22 @@ static int usb_reset_and_verify_device(struct usb_device *udev)
 		mutex_unlock(hcd->bandwidth_mutex);
 		goto re_enumerate;
 	}
+
+	/*
+	 * Restore eUSB2v2 1KB bulk mode after reset (device reverts to 512
+	 * after any bus reset per eUSB2v2 spec section 5.2).
+	 * Only retry if the initial SET_FEATURE had succeeded.
+	 */
+	if (udev->eusb2v2_mps_active) {
+		ret = eusb_update_max_packet(udev, udev->actconfig);
+		if (ret < 0) {
+			dev_err(&udev->dev,
+				"eUSB2v2: failed to restore 1KB mode after reset (%d)\n", ret);
+			mutex_unlock(hcd->bandwidth_mutex);
+			goto re_enumerate;
+		}
+	}
+
 	ret = usb_control_msg(udev, usb_sndctrlpipe(udev, 0),
 			USB_REQ_SET_CONFIGURATION, 0,
 			udev->actconfig->desc.bConfigurationValue, 0,
diff --git a/drivers/usb/core/message.c b/drivers/usb/core/message.c
index 75e2bfd744a9..18bedc7f91a3 100644
--- a/drivers/usb/core/message.c
+++ b/drivers/usb/core/message.c
@@ -2007,6 +2007,67 @@ int usb_set_wireless_status(struct usb_interface *iface,
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
+int eusb_update_max_packet(struct usb_device *udev, struct usb_host_config *cp)
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
+		return 0;
+
+	if (cp) {
+		ret = usb_control_msg(udev, usb_sndctrlpipe(udev, 0),
+				      USB_REQ_SET_FEATURE, USB_RECIP_DEVICE,
+				      USB_DEVICE_BULK_MAX_PACKET_UPDATE, 0, NULL, 0,
+				      USB_CTRL_SET_TIMEOUT);
+		if (ret < 0) {
+			dev_warn(&udev->dev, "eUSB2v2 1KB update failed: %d\n", ret);
+			return ret;
+		}
+
+		mps = 1024;
+	} else if (!udev->actconfig)
+		return 0;
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
+
+	return 0;
+}
+
 /*
  * usb_set_configuration - Makes a particular device setting be current
  * @dev: the device whose configuration is being updated
@@ -2120,8 +2181,19 @@ int usb_set_configuration(struct usb_device *dev, int configuration)
 	/* if it's already configured, clear out old state first.
 	 * getting rid of old interfaces means unbinding their drivers.
 	 */
-	if (dev->state != USB_STATE_ADDRESS)
+	if (dev->state != USB_STATE_ADDRESS) {
+		eusb_update_max_packet(dev, NULL);
 		usb_disable_device(dev, 1);	/* Skip ep0 */
+	}
+
+	ret = eusb_update_max_packet(dev, cp);
+	if (ret < 0)
+		dev->eusb2v2_mps_active = 0;
+	else if (le16_to_cpu(dev->descriptor.bcdUSB) == 0x0230 &&
+		 hcd->self.is_eusb2v2)
+		dev->eusb2v2_mps_active = 1;
+	else
+		dev->eusb2v2_mps_active = 0;
 
 	/* Get rid of pending async Set-Config requests for this device */
 	cancel_async_set_config(dev);
diff --git a/drivers/usb/core/usb.h b/drivers/usb/core/usb.h
index a9b37aeb515b..c36fe2a2acea 100644
--- a/drivers/usb/core/usb.h
+++ b/drivers/usb/core/usb.h
@@ -89,6 +89,8 @@ extern int usb_major_init(void);
 extern void usb_major_cleanup(void);
 extern int usb_device_supports_lpm(struct usb_device *udev);
 extern int usb_port_disable(struct usb_device *udev);
+extern int eusb_update_max_packet(struct usb_device *udev,
+				  struct usb_host_config *cp);
 
 #ifdef	CONFIG_PM
 
diff --git a/drivers/usb/host/xhci-mem.c b/drivers/usb/host/xhci-mem.c
index 997fe90f54e5..8ccbfaf57612 100644
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
+				if (max_packet != 1024)
+					max_packet = 512;
+			} else {
+				max_packet = 512;
+			}
+		}
+
 		if (udev->speed == USB_SPEED_FULL) {
 			max_packet = rounddown_pow_of_two(max_packet);
 			max_packet = clamp_val(max_packet, 8, 64);
diff --git a/drivers/usb/host/xhci.c b/drivers/usb/host/xhci.c
index a54f5b57f205..ba3cdc5c732d 100644
--- a/drivers/usb/host/xhci.c
+++ b/drivers/usb/host/xhci.c
@@ -5371,6 +5371,10 @@ static void xhci_hcd_init_usb2_data(struct xhci_hcd *xhci, struct usb_hcd *hcd)
 	xhci->usb2_rhub.hcd = hcd;
 	hcd->speed = HCD_USB2;
 	hcd->self.root_hub->speed = USB_SPEED_HIGH;
+
+	if (xhci->hcc_params2 & HCC2_E2V2C)
+		hcd->self.is_eusb2v2 = 1;
+
 	/*
 	 * USB 2.0 roothub under xHCI has an integrated TT,
 	 * (rate matching hub) as opposed to having an OHCI/UHCI
diff --git a/include/linux/usb.h b/include/linux/usb.h
index 25a203ac7a7e..57fb4c552740 100644
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
 
@@ -625,6 +629,8 @@ struct usb3_lpm_parameters {
  * @usb2_hw_lpm_allowed: Userspace allows USB 2.0 LPM to be enabled
  * @usb3_lpm_u1_enabled: USB3 hardware U1 LPM enabled
  * @usb3_lpm_u2_enabled: USB3 hardware U2 LPM enabled
+ * @eusb2v2_mps_active: 1024-byte bulk mode is active and must be restored
+ *	 after bus reset.
  * @string_langid: language ID for strings
  * @product: iProduct string, if present (static)
  * @manufacturer: iManufacturer string, if present (static)
@@ -708,6 +714,7 @@ struct usb_device {
 	unsigned usb2_hw_lpm_allowed:1;
 	unsigned usb3_lpm_u1_enabled:1;
 	unsigned usb3_lpm_u2_enabled:1;
+	unsigned eusb2v2_mps_active:1;
 	int string_langid;
 
 	/* static strings from the device */

-- 
2.43.0

