From: Joseph Telaak <joseph@telaak.dev>
Date: Tue, 27 Oct 2026 19:38:35 -0400
Subject: [PATCH v2 2/2] usb: ehci-pci: Set has_hostpc for TDI EHCI on Intel
 CE5300
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-ehci-ce5300-hostpc-v2-2-375e9d362d74@telaak.dev>
References: <20261027-ehci-ce5300-hostpc-v2-0-375e9d362d74@telaak.dev>
In-Reply-To: <20261027-ehci-ce5300-hostpc-v2-0-375e9d362d74@telaak.dev>
To: Alan Stern <stern@rowland.harvard.edu>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793144314; l=3297;
 i=joseph@telaak.dev; s=default; h=from:subject:message-id;
 bh=mAomdJY7vVHiH3SZhOh4pFTjDcxX+9QU//lNz5w7C8k=;
 b=vSS727hInN79mdgdbbEnxkaH9nfyw29I2eqlH5yTXBpHRWd+JBkXWIjomvRCLL0svZjIC5Ss0
 XkqjJgR+XxyBDTttuhbQowaE/9gCd6BlQ6t4rSjhBGu++LLcV/MRK3D
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=vbM2RxVf3De5c1pQhdR2zZNLas2GaS+BXNVRR5qg3hI=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/default with auth_id=1203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TransDimension EHCI core in the Intel CE5300 SoCs (192e:0101,
revision >= 6) has the Moorestown-style register extensions: host
mode is selected in USBMODE_EX rather than USBMODE, and the port speed
is reported in HOSTPC.

Without has_hostpc, ehci_reset() never programs USBMODE_EX, so the
core stays in idle mode: USBMODE_EX reads back 0, USBCMD.RS never
sets and no device is ever reported as connected, even though the
probe itself succeeds. With it, USBMODE_EX reads back 0x23 and
devices enumerate.

USBMODE itself always reads back 0 on this core, so
tdi_in_host_mode() would report a running controller as not in host
mode and ehci_halt() would return without stopping it. Add
has_usbmode_ex so that, for this core only, tdi_in_host_mode() reads
host mode back from USBMODE_EX. ChipIdea also sets has_hostpc but
keeps host mode in USBMODE, so it is unaffected.

Intel's CE5300 BSP sets has_hostpc for device 0x0101, revision >= 6.

Tested on a Control4 EA-3 (Intel Atom CE5310) with v7.3-rc6: a
full-speed CP2104 USB-UART bridge (10c4:ea60) and a high-speed USB
flash drive (0781:5575) enumerate with this change, and
ehci_shutdown() leaves the controller halted (USBCMD.RS clear,
USBSTS.HCHalted set); without the USBMODE_EX check it stays running.

Assisted-by: LLM
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/usb/host/ehci-hcd.c |  5 +++++
 drivers/usb/host/ehci-pci.c | 10 ++++++++++
 drivers/usb/host/ehci.h     |  1 +
 3 files changed, 16 insertions(+)

diff --git a/drivers/usb/host/ehci-hcd.c b/drivers/usb/host/ehci-hcd.c
index 75f780ec3b..fd7b47c0f0 100644
--- a/drivers/usb/host/ehci-hcd.c
+++ b/drivers/usb/host/ehci-hcd.c
@@ -170,6 +170,11 @@ static int tdi_in_host_mode (struct ehci_hcd *ehci)
 {
 	u32		tmp;
 
+	if (ehci->has_usbmode_ex) {
+		tmp = ehci_readl(ehci, &ehci->regs->usbmode_ex);
+		return (tmp & USBMODE_EX_HC) == USBMODE_EX_HC;
+	}
+
 	tmp = ehci_readl(ehci, &ehci->regs->usbmode);
 	return (tmp & 3) == USBMODE_CM_HC;
 }
diff --git a/drivers/usb/host/ehci-pci.c b/drivers/usb/host/ehci-pci.c
index 3c7430a06e..183002ed7d 100644
--- a/drivers/usb/host/ehci-pci.c
+++ b/drivers/usb/host/ehci-pci.c
@@ -155,6 +155,16 @@ static int ehci_pci_setup(struct usb_hcd *hcd)
 	case PCI_VENDOR_ID_TDI:
 		if (pdev->device == PCI_DEVICE_ID_TDI_EHCI)
 			hcd->has_tt = 1;
+		/*
+		 * The Intel CE5300 core selects host mode in USBMODE_EX and
+		 * reports port speed in HOSTPC, as on Moorestown. USBMODE
+		 * reads as 0 on it, so host mode is read back from
+		 * USBMODE_EX too.
+		 */
+		if (is_intel_ce_tdi(pdev)) {
+			ehci->has_hostpc = 1;
+			ehci->has_usbmode_ex = 1;
+		}
 		break;
 	case PCI_VENDOR_ID_AMD:
 		/* AMD PLL quirk */
diff --git a/drivers/usb/host/ehci.h b/drivers/usb/host/ehci.h
index 855a9d08b0..e26e913ad5 100644
--- a/drivers/usb/host/ehci.h
+++ b/drivers/usb/host/ehci.h
@@ -248,6 +248,7 @@ struct ehci_hcd {			/* one per controller */
 	#define OHCI_HCCTRL_LEN         0x4
 	__hc32			*ohci_hcctrl_reg;
 	unsigned		has_hostpc:1;
+	unsigned		has_usbmode_ex:1; /* host mode is in USBMODE_EX */
 	unsigned		has_tdi_phy_lpm:1;
 	unsigned		has_ppcd:1; /* support per-port change bits */
 	u8			sbrn;		/* packed release number */

-- 
Git-155)

