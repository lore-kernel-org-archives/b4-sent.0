From: Matt Eaton <linux@divinehawk.com>
Subject: [PATCH v2 0/3] usb: xhci: add xhci-no-soft-retry-quirk
Date: Sat, 29 Aug 2026 22:04:09 +0200
Message-Id: <20260829-xhci-no-soft-retry-v2-0-0efe22f1c2f8@divinehawk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADk7k2oC/32NwQ6CMBAFf4X07JpSsYIn/8NwoO1iV2Nr2lohh
 H8X8O5xknnzJhYxEEZ2LiYWMFMk7xYQu4Jp27kbApmFmeBC8lrUMFhN4DxE3ycImMIIVddL3Ry
 MPhnBluErYE/DFr22P45vdUed1tJqWIrJh3F7zeXq/T3IJXBQjRayUkcpeXkxlMmh7T6PvfZP1
 s7z/AUq87jjywAAAA==
X-Change-ID: 20260828-xhci-no-soft-retry-4af6c93dc7d2
To: Mathias Nyman <mathias.nyman@intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Matt Eaton <linux@divinehawk.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788033855; l=2142;
 i=linux@divinehawk.com; s=20260828; h=from:subject:message-id;
 bh=ZsVboOaElz1fshbAtApbyNEwQi9OTkk/MIHXqoY+l/w=;
 b=pJ9FzabRTijMqGGViWZE3UpnKnL2rty/NfNQ6n0yRb4LvaTCcZ1zQX4fU19Zvj9p/TnVWlV9s
 1a2gOXPpJ6mBWLfPEwKEMNCDXlnLZgMXDIDJvEFMYKdFZiedcdHX0tl
X-Developer-Key: i=linux@divinehawk.com; a=ed25519;
 pk=UG4KnKXGwxjTNdirUPh/nySblET4aRxWYWSMTQwzlMw=
X-Endpoint-Received: by B4 Relay for linux@divinehawk.com/20260828 with auth_id=982
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dwc3 instances on Qualcomm IPQ4019 mishandle xHCI 1.0 Soft Retry. A
Stop Endpoint command landing on a just-soft-retry-reset endpoint wedges
the command ring, and the stop-endpoint watchdog kills the host five
seconds later. Reproducible by unplugging a USB-tethered phone
mid-transfer; the port stays dead until the platform device is rebound.

XHCI_NO_SOFT_RETRY already exists for this class of defect but is only
reachable from xhci-pci, matched against two AMD Promontory PCI ids.

Patch 1 adds a device property so platform hosts can request it. Patch 2
carries it through the dwc3 core as a software property. Patch 3 sets it
from the qcom glue on the SoC compatible.

The match entry in patch 3 has no effect until the ipq4019 devicetree
moves to the qcom,snps-dwc3 glue, sent separately:
https://lore.kernel.org/r/20260829-ipq4019-dwc3-migration-v1-0-cc66b54ce21c@divinehawk.com

This series applies and builds independently of that.

Tested on a Ubiquiti UniFi Travel Router.

Signed-off-by: Matt Eaton <linux@divinehawk.com>
---
Changes in v2:
- Drop the dt-bindings patch; Krzysztof pointed out this is implied by
  compatible and shouldn't be a devicetree property.
- Set the quirk from the dwc3 core instead, via a new dwc3_properties
  field carried as match data in the qcom glue, per Thinh's review.
- Link to v1: https://lore.kernel.org/r/20260828-xhci-no-soft-retry-v1-0-b9c264b56601@divinehawk.com

---
Matt Eaton (3):
      usb: xhci-plat: add xhci-no-soft-retry-quirk device property
      usb: dwc3: add xhci_no_soft_retry software property
      usb: dwc3: qcom: set xhci_no_soft_retry for IPQ4019

 drivers/usb/dwc3/core.c      |  3 +++
 drivers/usb/dwc3/core.h      |  3 +++
 drivers/usb/dwc3/dwc3-qcom.c | 17 ++++++++++++++++-
 drivers/usb/dwc3/glue.h      |  3 +++
 drivers/usb/dwc3/host.c      |  5 ++++-
 drivers/usb/host/xhci-plat.c |  3 +++
 6 files changed, 32 insertions(+), 2 deletions(-)
---
base-commit: 45c13f3f9e3bb15fd89ff2864c6f627a3b4b4229
change-id: 20260828-xhci-no-soft-retry-4af6c93dc7d2

Best regards,
--  
Matt Eaton <linux@divinehawk.com>

