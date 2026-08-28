From: Matt Eaton <linux@divinehawk.com>
Date: Fri, 28 Aug 2026 14:37:56 +0200
Subject: [PATCH 2/2] usb: xhci-plat: add xhci-no-soft-retry-quirk device
 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260828-xhci-no-soft-retry-v1-2-b9c264b56601@divinehawk.com>
References: <20260828-xhci-no-soft-retry-v1-0-b9c264b56601@divinehawk.com>
In-Reply-To: <20260828-xhci-no-soft-retry-v1-0-b9c264b56601@divinehawk.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Mathias Nyman <mathias.nyman@intel.com>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Matt Eaton <linux@divinehawk.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787920681; l=1564;
 i=linux@divinehawk.com; s=20260828; h=from:subject:message-id;
 bh=hre3DhXtEdMtBActPCAC6ChtUOOZ9DzGbOAgxtv43Gk=;
 b=XAbaNZQo5priU8H5STolVWtvAB0wfYM/0PrITDc5tHB9fDkQ4+lyydfBmcHBIOMcyT9qf2EkL
 raRHLj6xlj3DLGYY5Or4LjFYOureX42HUbMEc7/Yqx3RBz6V+id0N1G
X-Developer-Key: i=linux@divinehawk.com; a=ed25519;
 pk=UG4KnKXGwxjTNdirUPh/nySblET4aRxWYWSMTQwzlMw=
X-Endpoint-Received: by B4 Relay for linux@divinehawk.com/20260828 with auth_id=982
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

XHCI_NO_SOFT_RETRY exists for hosts that can't perform xHCI 1.0 Soft Retry
correctly, but it's only reachable from xhci-pci, matched against two AMD
Promontory PCI ids. Platform hosts have no way to ask for it.

Add it as a device property, the same way as quirk-broken-port-ped and its
neighbors. It's opt-in, so no existing platform is affected.

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

