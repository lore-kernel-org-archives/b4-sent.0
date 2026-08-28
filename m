From: Matt Eaton <linux@divinehawk.com>
Subject: [PATCH 0/2] usb: xhci: add xhci-no-soft-retry-quirk
Date: Fri, 28 Aug 2026 14:37:54 +0200
Message-Id: <20260828-xhci-no-soft-retry-v1-0-b9c264b56601@divinehawk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACKBkWoC/yXMwQ6CMAyA4VchPdsEpwH0VYwH6Dooh82000AI7
 +6U43f4/w2MVdjgXm2g/BGTFAvOpwpo6uPIKL4YXO2aunMdLhMJxoSWQkblrCte+9DQ7eKp9Q5
 K+FIOsvynj+dhew8zU/6dYN+/xQH0bHYAAAA=
X-Change-ID: 20260828-xhci-no-soft-retry-4af6c93dc7d2
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Mathias Nyman <mathias.nyman@intel.com>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Matt Eaton <linux@divinehawk.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787920681; l=1395;
 i=linux@divinehawk.com; s=20260828; h=from:subject:message-id;
 bh=zT+ccwsVbDtmhy4mHNgwYuK8CPx9UNRBC8oZGrS4HfM=;
 b=Gia0aSsr++SsY5Pr7hEjjZEnaNMwgsU1wIyG7TA4uR/9knq0iYiuHDVPzlTXWMTFIqvZFnDkr
 TyjBMHoIEwBC6RUXZJN+UXWPiNo8r4vRWPuP3rFtltfnFolE5XGQcD1
X-Developer-Key: i=linux@divinehawk.com; a=ed25519;
 pk=UG4KnKXGwxjTNdirUPh/nySblET4aRxWYWSMTQwzlMw=
X-Endpoint-Received: by B4 Relay for linux@divinehawk.com/20260828 with auth_id=982
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds an opt-in device property so platform xHCI hosts can
request the XHCI_NO_SOFT_RETRY quirk, currently only reachable from
xhci-pci matched against two AMD Promontory PCI ids.

Motivating case: the Synopsys DWC3 xHCI instances on Qualcomm IPQ4019
mishandle xHCI 1.0 Soft Retry. A Stop Endpoint command landing on a
just-soft-retry-reset endpoint wedges the command ring; the
stop-endpoint watchdog then kills the host five seconds later. Setting
the property falls back to the pre-Soft-Retry recovery path (full
endpoint reset), which the vendor's 4.4 kernel uses unconditionally
and which is well tolerated on this hardware.

Patch 1 documents the property. Patch 2 wires it into xhci-plat.c.

The devicetree change enabling this on IPQ4019 is being sent
separately to linux-arm-msm, since this series only adds the
mechanism.

Signed-off-by: Matt Eaton <linux@divinehawk.com>
---
Matt Eaton (2):
      dt-bindings: usb: xhci: add xhci-no-soft-retry-quirk
      usb: xhci-plat: add xhci-no-soft-retry-quirk device property

 Documentation/devicetree/bindings/usb/usb-xhci.yaml | 4 ++++
 drivers/usb/host/xhci-plat.c                        | 3 +++
 2 files changed, 7 insertions(+)
---
base-commit: 45c13f3f9e3bb15fd89ff2864c6f627a3b4b4229
change-id: 20260828-xhci-no-soft-retry-4af6c93dc7d2

Best regards,
--  
Matt Eaton <linux@divinehawk.com>

