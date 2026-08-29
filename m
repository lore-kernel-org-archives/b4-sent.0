From: Matt Eaton <linux@divinehawk.com>
Date: Sat, 29 Aug 2026 22:04:10 +0200
Subject: [PATCH v2 1/3] usb: xhci-plat: add xhci-no-soft-retry-quirk device
 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260829-xhci-no-soft-retry-v2-1-0efe22f1c2f8@divinehawk.com>
References: <20260829-xhci-no-soft-retry-v2-0-0efe22f1c2f8@divinehawk.com>
In-Reply-To: <20260829-xhci-no-soft-retry-v2-0-0efe22f1c2f8@divinehawk.com>
To: Mathias Nyman <mathias.nyman@intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Matt Eaton <linux@divinehawk.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788033855; l=1705;
 i=linux@divinehawk.com; s=20260828; h=from:subject:message-id;
 bh=sndU+dSNuXWaAlu2q681N0vXtGCZqmqdL+gk7E3DkYk=;
 b=iB+7Y0HLPV/GYjwgVDDm98ttHlP+n3feG+H7hEhJkQyckhQz4E8J+ASxtS/m0VtTw+blvc8sO
 RR7qWGIqCtzBzJPs2N2qQoP9PiUlTgjYyhkxYPVpvYU2r2tfJ0Xb8gU
X-Developer-Key: i=linux@divinehawk.com; a=ed25519;
 pk=UG4KnKXGwxjTNdirUPh/nySblET4aRxWYWSMTQwzlMw=
X-Endpoint-Received: by B4 Relay for linux@divinehawk.com/20260828 with auth_id=982
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

XHCI_NO_SOFT_RETRY exists for hosts that can't perform xHCI 1.0 Soft Retry
correctly, but it's only reachable from xhci-pci, matched against two AMD
Promontory PCI ids. Platform hosts have no way to ask for it.

Add it as a device property, read in the same parent-walk block as
quirk-broken-port-ped and its neighbors. It's opt-in, so no existing
platform is affected. The following patches set it from the dwc3 core
on behalf of hardware known to need it, rather than from devicetree.

Needed for the Synopsys DWC3 on a Qualcomm IPQ4019, whose command ring
wedges when a Stop Endpoint command lands on a just-soft-retry-reset
endpoint -- exactly what unplugging a device mid-transfer triggers:

xhci-hcd xhci-hcd.1.auto: xHCI host not responding to stop endpoint command
xhci-hcd xhci-hcd.1.auto: xHCI host controller not responding, assume dead
xhci-hcd xhci-hcd.1.auto: HC died; cleaning up

Signed-off-by: Matt Eaton <linux@divinehawk.com>
---
 drivers/usb/host/xhci-plat.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/usb/host/xhci-plat.c b/drivers/usb/host/xhci-plat.c
index 6fd595f81a30..22057493f935 100644
--- a/drivers/usb/host/xhci-plat.c
+++ b/drivers/usb/host/xhci-plat.c
@@ -265,6 +265,9 @@ int xhci_plat_probe(struct platform_device *pdev, struct device *sysdev, const s
 		if (device_property_read_bool(tmpdev, "quirk-broken-port-ped"))
 			xhci->quirks |= XHCI_BROKEN_PORT_PED;
 
+		if (device_property_read_bool(tmpdev, "xhci-no-soft-retry-quirk"))
+			xhci->quirks |= XHCI_NO_SOFT_RETRY;
+
 		if (device_property_read_bool(tmpdev, "xhci-sg-trb-cache-size-quirk"))
 			xhci->quirks |= XHCI_SG_TRB_CACHE_SIZE_QUIRK;
 

-- 
2.43.0

