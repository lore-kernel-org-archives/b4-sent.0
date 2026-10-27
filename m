From: Joseph Telaak <joseph@telaak.dev>
Date: Tue, 27 Oct 2026 19:38:34 -0400
Subject: [PATCH v2 1/2] usb: ehci-pci: Skip SBRN and port-wake reads on
 Intel CE5300
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-ehci-ce5300-hostpc-v2-1-375e9d362d74@telaak.dev>
References: <20261027-ehci-ce5300-hostpc-v2-0-375e9d362d74@telaak.dev>
In-Reply-To: <20261027-ehci-ce5300-hostpc-v2-0-375e9d362d74@telaak.dev>
To: Alan Stern <stern@rowland.harvard.edu>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793144314; l=2537;
 i=joseph@telaak.dev; s=default; h=from:subject:message-id;
 bh=XLKlRgT0Je/buuDmBCEauwUFMUUQyJz51xcNAqZXxSg=;
 b=kfwdbBmD8UehZmnWWRj4NgwPHQF5ecjlbq3la82/pcyNQnhlsonqILVijjnOqVZYDG5J0ttVa
 JXccqemsQ9EAUaVUj30roFBhwtE2gk5cIHT7+MzdIGD0b+kvTRp8nGB
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=vbM2RxVf3De5c1pQhdR2zZNLas2GaS+BXNVRR5qg3hI=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/default with auth_id=1203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TDI EHCI core in the Intel CE5300 SoCs (192e:0101, revision >= 6)
has no EHCI-specific PCI config registers at 0x60: those bytes shadow
BAR3. ehci_pci_setup() reads two of them anyway.

SBRN (0x60) reads as 0 and overwrites the HCD_USB2 default, so the
controller reports "USB 0.0 started" and ehci_shutdown() returns
early because sbrn is 0, so the controller is never stopped on reboot
or kexec. The port-wake word (0x62) is whatever BAR3 holds, so on
some instances bit 0 is set and the driver prints "Enabling legacy
PCI PM" and marks the controller wakeup-capable.

Skip both reads for this core, as is already done for SBRN on the ST
ConneXT and HiSilicon Kunpeng920 controllers. The new helper is also
used by the next patch.

Tested on a Control4 EA-3 (Intel Atom CE5310) with v7.3-rc6: the
controllers report "USB 2.0 started" and the legacy PCI PM message is
gone.

Assisted-by: LLM
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/usb/host/ehci-pci.c | 12 +++++++++++-
 1 file changed, 11 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/host/ehci-pci.c b/drivers/usb/host/ehci-pci.c
index bd3a635555..3c7430a06e 100644
--- a/drivers/usb/host/ehci-pci.c
+++ b/drivers/usb/host/ehci-pci.c
@@ -31,6 +31,14 @@ static inline bool is_intel_quark_x1000(struct pci_dev *pdev)
 		pdev->device == PCI_DEVICE_ID_INTEL_QUARK_X1000_SOC;
 }
 
+/* The TDI EHCI core in the Intel CE5300 SoCs */
+static inline bool is_intel_ce_tdi(struct pci_dev *pdev)
+{
+	return pdev->vendor == PCI_VENDOR_ID_TDI &&
+		pdev->device == PCI_DEVICE_ID_TDI_EHCI &&
+		pdev->revision >= 0x6;
+}
+
 /*
  * This is the list of PCI IDs for the devices that have EHCI USB class and
  * specific drivers for that. One of the example is a ChipIdea device installed
@@ -312,6 +320,8 @@ static int ehci_pci_setup(struct usb_hcd *hcd)
 	else if (pdev->vendor == PCI_VENDOR_ID_HUAWEI
 			 && pdev->device == 0xa239)
 		;	/* HUAWEI Kunpeng920 USB EHCI has no sbrn register */
+	else if (is_intel_ce_tdi(pdev))
+		;	/* no EHCI registers at 0x60; those bytes shadow a BAR */
 	else
 		pci_read_config_byte(pdev, 0x60, &ehci->sbrn);
 
@@ -320,7 +330,7 @@ static int ehci_pci_setup(struct usb_hcd *hcd)
 	 * can be removed on 17 Dec 2009 if the dev_warn() hasn't
 	 * been triggered by then.
 	 */
-	if (!device_can_wakeup(&pdev->dev)) {
+	if (!device_can_wakeup(&pdev->dev) && !is_intel_ce_tdi(pdev)) {
 		u16	port_wake;
 
 		pci_read_config_word(pdev, 0x62, &port_wake);

-- 
Git-155)

