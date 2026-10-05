From: Pawel Laszczak <pawell@cadence.com>
Subject: [PATCH v3 0/3] usb: Add support for eUSB2v2 1024-byte Bulk
 MaxPacketSize
Date: Mon, 05 Oct 2026 10:18:23 +0200
Message-Id: <20261005-eusb2v2-packet-size-v3-0-fde610a3c47a@cadence.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE9dw2oC/22NQQ6CMBQFr0K6tqYttIAr72Fc0M+vVCMQCo1Ku
 LstLIwJy0nem5mJw8GiI6dkJgN662zXBkgPCYGmam9IbR2YCCYUU6ykODktvKB9BQ8cqbMfpBl
 opYpMykxJEp79gMa+VuvlurGb9B1hjKq4aKwbu+G9Zj2Pu62Q83y34DllVOWgONc1A6nPUNXYA
 h6he5LY8OJnKYTat4hgKSUzvDRpgYb9W5Zl+QLyLe87EAEAAA==
X-Change-ID: 20260609-eusb2v2-packet-size-4cb668455465
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Mathias Nyman <mathias.nyman@intel.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Pawel Laszczak <pawell@cadence.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791188311; l=5323;
 i=pawell@cadence.com; h=from:subject:message-id;
 bh=XJ43BI9VFUSRx8MVKu/7AuJD4tr7EI9+wQIfvS3p4JE=;
 b=ggmN0eyLfU/Ud+FiOZJYPCcgjkuaINQnqs9BVCwnn3ePycjSTIx80pzlbRcqxuUfMztwtqNXx
 bwtwdfAKt5ICZ42TwYaoBrXHu2yewJ9kQSUp06IPLLRrx273Fop+MW6
X-Developer-Key: i=pawell@cadence.com; a=ed25519;
 pk=EUPBvLO9CDg7j6defeDl2iqi+z5Ivqu4Z46aiqe7dYc=
X-Endpoint-Received: by B4 Relay for pawell@cadence.com/default with auth_id=707
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Embedded USB2 (eUSB2) v2 specification (bcdUSB 0x0230) introduces a
mechanism that allows High-Speed Bulk endpoints to support a maximum
packet size (MPS) of 1024 bytes, expanding it from the traditional
512-byte limit defined in the standard USB 2.0 specification.
This capability is highly beneficial for Mass Storage Class (MSC)
devices, significantly improving overall throughput.

Per the eUSB2v2 specification, a peripheral device will revert its
internal Bulk MPS back to 512 bytes after major bus events, including a
bus reset, disconnect, or deconfiguration. To establish and maintain
the 1024-byte mode, the host controller must explicitly issue
a device-recipient SET_FEATURE request called
USB_DEVICE_BULK_MAX_PACKET_UPDATE. This must occur after the device enters
the ADDRESSED state, but strictly before it transitions to the CONFIGURED
state.

This patch series implements the required infrastructure on both the host
and gadget sides, and enables it for the Cadence (cdnsp) controller.

Structure of the series:
- Patch 1: Introduces host-side core support in usb_set_configuration() to
  detect eUSB2v2 devices and issue the SET_FEATURE update request prior to
  activating the device configuration. Adds eusb2v2_mps_active flag to
  struct usb_device to track negotiation state. Extends hub.c to re-issue
  SET_FEATURE after bus reset in usb_reset_and_verify_device(); on failure
  triggers re-enumeration to prevent driver from operating with
  inconsistent MPS state. Also updates xHCI endpoint initialization
  to allow 1024-byte packets for High-Speed Bulk endpoints when HCC2_E2V2C
  is present.

- Patch 2: Extends the USB Gadget Composite framework to advertise bcdUSB
  0x0230 when eUSB2v2 is supported, intercept the incoming feature
  request, and dynamically update the wMaxPacketSize fields across all
  High-Speed Bulk descriptors before configuration is completed.
  
- Patch 3: Implements peripheral-specific handling in the Cadence (cdnsp)
  driver, reading HCCPARAMS2 to discover the hardware capability and
  adapting cdnsp_endpoint_init() boundaries to allow for the larger
  packet size.

Testing:
The flow has been validated using the Cadence eUSB2v2 Host and Device
controllers, ensuring seamless transition to 1024-byte mode during early
enumeration stages and successful verification under USB-IF Compliance
Verification (CV) tooling.

Signed-off-by: Pawel Laszczak <pawell@cadence.com>
---
Changes in v3:
- message.c: Add check for bulk endpoint existence before sending
  BULK_MAX_PACKET_UPDATE. This avoids sending the request to devices that
  only use isochronous endpoints, as they do not support it.
- host & gadget: Do not overwrite ep->desc.wMaxPacketSize to 1024.
  According to eUSB2v2 spec section 5.2, the endpoint descriptor must
  always report 512 bytes regardless of the current operating mode.
- host: Rely on the eusb2v2_mps_active flag in xhci_usb_endpoint_maxp()
  to dynamically return 1024 for HS bulk endpoints when the 1KB mode
  is active.
- gadget: Introduce gadget->eusb2v2_mps_active flag to let the composite
  framework report 512 bytes while the UDC dynamically sets 1KB max packet
  size in hardware.
- Link to v2: https://patch.msgid.link/20260826-eusb2v2-packet-size-v2-0-950f19f38ef0@cadence.com

Changes in v2:
- Removed config.c change: per eUSB2v2 spec section 5.2, conformant devices
  always report wMaxPacketSize=512 in their descriptor regardless of operating
  mode, so the warning suppression was unnecessary.
- eusb_update_max_packet(): changed from void to int; added error propagation
  and eusb2v2_mps_active state tracking.
- Added hub.c handling to restore 1KB mode after bus reset, with re-enumeration
  on failure (addresses Oliver Neukum's review comments).
- xhci-mem.c: simplified HS bulk clamp logic.
- xhci.c: moved is_eusb2v2 assignment into xhci_hcd_init_usb2_data().
- composite.c: stall CLEAR_FEATURE(BULK_MAX_PACKET_UPDATE) as it is not
  defined by the eUSB2v2 spec.
- cdnsp-mem.c: simplified HS bulk clamp logic, consistent with xhci-mem.c.
- Link to v1: https://patch.msgid.link/20260717-eusb2v2-packet-size-v1-0-67c611bd0c5b@cadence.com

---
Pawel Laszczak (3):
      usb: xhci: Add support for eUSB2v2 1024-byte bulk packet size
      usb: gadget: composite: Support eUSB2v2 bulk MPS update
      usb: cdns3: cdnsp: Enable eUSB2v2 1KB bulk packet capability

 drivers/usb/cdns3/cdnsp-ep0.c    |  2 ++
 drivers/usb/cdns3/cdnsp-gadget.c |  4 +++
 drivers/usb/cdns3/cdnsp-gadget.h |  8 +++++
 drivers/usb/cdns3/cdnsp-mem.c    |  9 +++--
 drivers/usb/common/debug.c       |  2 ++
 drivers/usb/core/hub.c           | 16 +++++++++
 drivers/usb/core/message.c       | 74 ++++++++++++++++++++++++++++++++++++++++
 drivers/usb/core/usb.h           |  2 ++
 drivers/usb/gadget/composite.c   | 28 +++++++++++----
 drivers/usb/host/xhci-mem.c      | 15 ++++++--
 drivers/usb/host/xhci.c          | 10 ++++++
 include/linux/usb.h              |  7 ++++
 include/linux/usb/gadget.h       |  4 +++
 13 files changed, 169 insertions(+), 12 deletions(-)
---
base-commit: 1d52b92ce8748624f84eca7eaea3ac31ed7b09a5
change-id: 20260609-eusb2v2-packet-size-4cb668455465

Best regards,
--  
Pawel Laszczak <pawell@cadence.com>

