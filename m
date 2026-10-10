From: Joe Finzel <joe@sudmix.de>
Date: Sun, 11 Oct 2026 01:16:10 +0200
Subject: [PATCH] mei: me: do not bind the 700 series PCH-S xHCI controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-mei-xhci-v1-1-38c28b5f3f99@sudmix.de>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0ND3dzUTN2KjORMXQMjc3OjFANTA7NUYyWg8oKi1LTMCrBR0bG1tQA
 IRGYDWgAAAA==
X-Change-ID: 20261011-mei-xhci-02772d0506e3
To: Alexander Usyskin <alexander.usyskin@intel.com>, 
 Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Joe Finzel <joe@sudmix.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791674185; l=2786;
 i=joe@sudmix.de; s=default; h=from:subject:message-id;
 bh=dHPRvinmj3gT398vg7KB5i9657nu0BvpUvNDZSpaljo=;
 b=Q1saQ00ra3W30vwtbtKVqcmZeHPBryR0R+4L9jmFjm7pJf4wDTp5vS30Crm6vwvpcJb4Tu4hc
 OSpVoNHJk1SApao/OySbAIcwUFn8T6I/pT96vSUiwvZBTWAnXQxHkpi
X-Developer-Key: i=joe@sudmix.de; a=ed25519;
 pk=vaX11uVm57me/1N8otNmzMMnsE+f0U3/Hi9TCPbnvZM=
X-Endpoint-Received: by B4 Relay for joe@sudmix.de/default with auth_id=1151
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PCI ID 8086:7a60 is listed as the "Alder Lake Point LP" HECI device, but
on the 700 series PCH-S (Raptor Lake-S) the same ID belongs to the USB 3.2
xHCI controller (class 0x0c0330). The HECI device there is 8086:7a68.

With CONFIG_INTEL_MEI_ME=y, drivers/misc is linked before drivers/usb, so
mei_me probes the xHCI controller before xhci_pci can claim it. The probe
writes the HECI host CSR into the xHCI MMIO space, waits out three
hw_start timeouts and gives up, blocking boot for about 5.5 s:

  mei mei1: H_RST is not set = 0x18000840
  mei mei1: wait hw ready failed
  mei mei1: hw_start failed ret = -62 fw status = 803401FD 00000000 00006032 00000000 00000000 00000000
  ...
  mei mei1: reset: reached maximal consecutive resets: disabling the device
  mei_me 0000:00:14.0: init hw failure.
  mei_me 0000:00:14.0: initialization failed.
  xhci_hcd 0000:00:14.0: xHCI Host Controller

When mei_me is a module, xhci_pci is usually bound first, which is why
this has gone unnoticed since the ID was added.

Match the entry on the communication controller class as well, so it can
never bind a device of another class.

Seen on an ASUS ROG STRIX Z790-F GAMING WIFI (BIOS 3201), i7-13700K.

Fixes: 930c922a987a ("mei: me: add adler lake point LP DID")
Cc: stable@vger.kernel.org
Signed-off-by: Joe Finzel <joe@sudmix.de>
---
Seen on an ASUS ROG STRIX Z790-F with CONFIG_INTEL_MEI_ME=y (the log in
the commit message is from that board). With mei_me built as a module,
xhci_pci binds first and the stall is gone, which hid the problem so far.
The patch is compile-tested on 7.2.9 and applies to char-misc-next; I
can test it on the board with mei_me built in if that helps.
---
 drivers/misc/mei/pci-me.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/misc/mei/pci-me.c b/drivers/misc/mei/pci-me.c
index 790a46478..26e89140f 100644
--- a/drivers/misc/mei/pci-me.c
+++ b/drivers/misc/mei/pci-me.c
@@ -113,7 +113,10 @@ static const struct pci_device_id mei_me_pci_tbl[] = {
 	{ PCI_DEVICE_DATA(INTEL, MEI_EBG, MEI_ME_PCH15_SPS_CFG) },
 
 	{ PCI_DEVICE_DATA(INTEL, MEI_ADP_S, MEI_ME_PCH15_CFG) },
-	{ PCI_DEVICE_DATA(INTEL, MEI_ADP_LP, MEI_ME_PCH15_CFG) },
+	/* 8086:7a60 is also the xHCI controller of the 700 series PCH-S */
+	{ PCI_DEVICE(PCI_VENDOR_ID_INTEL, PCI_DEVICE_ID_INTEL_MEI_ADP_LP),
+	  .class = PCI_CLASS_COMMUNICATION_OTHER << 8, .class_mask = 0xffff00,
+	  .driver_data = (kernel_ulong_t)MEI_ME_PCH15_CFG },
 	{ PCI_DEVICE_DATA(INTEL, MEI_ADP_P, MEI_ME_PCH15_CFG) },
 	{ PCI_DEVICE_DATA(INTEL, MEI_ADP_N, MEI_ME_PCH15_CFG) },
 

---
base-commit: c26cc979e28f5193310e4379e14aa6417375c565
change-id: 20261011-mei-xhci-02772d0506e3

Best regards,
-- 
Joe Finzel <joe@sudmix.de>

