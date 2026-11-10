From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/2] usb: dwc3: Keep the host bus across suspend-to-idle
Date: Tue, 10 Nov 2026 07:16:42 +0000
Message-Id: <20261110-dwc3-s2idle-v1-0-2ef4cc3f8130@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0MD3ZTyZGPdYqPMlJxUXbNUY2MjQ3OTZFPzJCWgjoKi1LTMCrBp0bE
 QfnFpUlZqcgnICKXaWgC3GCXQbwAAAA==
X-Change-ID: 20261110-dwc3-s2idle-6e332174c57b
To: Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295002; l=3467;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=PwjfIXRd+K+b78KtgZc1IBgteLcDSdF0UU+U6AOrVfo=;
 b=MfuwgkRtd7OQMwCdUOasDnUYZU/UDYBYlvntOc9sKjXx18dHJg3Cm7pMuWGpf+iDqsX8p7f5S
 hbQiLIx8R9+CO0Hjwmun3x8u0k4OMgIZwUAk60OPPKnwO27CTfWFK1d
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In host mode, dwc3_suspend_common() tears the core down for every
system suspend unless the controller is a wakeup source
(dwc3_core_exit(): PHYs off, core reset). That has two consequences
for xhci-plat on top of it:

1. xhci_resume() is not told that the controller was reset. It writes
   the saved operational registers back and asks for a state restore
   (USBCMD.CRS), which fails on a freshly reset core, and only then
   falls back to a reinit:

     xhci-hcd xhci-hcd.1.auto: xHC error in resume, USBSTS 0x401, Reinit

   xhci-plat already has xhci_plat_priv.power_lost for this (cdns3 sets
   it). Patch 1 sets it from dwc3 whenever the core was re-initialised
   and clears it when the core was kept for wakeup.

2. Every device behind the root ports was put into U3 by the bus
   suspend and expects to keep its power session; resetting the core
   ends all of them. On resume the USB core has to reset-resume every
   device, which only works for devices that come back within the 2 s
   usb_port_resume() waits. A SanDisk Extreme SSD and a card reader
   behind a hub do not (2.4-3 s, measured): they are disconnected and
   enumerated again after each resume, which kills a mounted filesystem.
   Patch 2 keeps the core, its PHYs and the suspended bus across
   suspend-to-idle, as the wakeup path already does and as PCI xHCI
   controllers do, and marks the device as being on the awake path so a
   power domain with GENPD_FLAG_ACTIVE_WAKEUP stays on. Suspend-to-RAM,
   hibernation and needs_full_reinit controllers are unchanged.

Patch 2 depends on patch 1 (it clears power_lost on the kept-core path).
Both are changes to the dwc3 core; no glue driver is involved (the
RK3588 nodes bind to the "snps,dwc3" core driver directly).

Tested on an Orange Pi 5 (RK3588S), suspend-to-idle through rtcwake:
- Patch 1: 55 cycles on a kernel with patch 1 (and an ohci-platform
  change sent separately); the "xHC error in resume, USBSTS 0x401"
  message is gone, the controller re-initialises without the failed
  restore, no other change in behaviour.
- Patch 2: 47 cycles on a kernel with both patches: every USB device
  kept its device number, all 7 SuperSpeed links were back after each
  resume, no "root hub lost power or was reset" and no re-enumeration
  in dmesg, USB drives readable afterwards. Without patch 2 the SSD and
  the card reader were disconnected and re-enumerated after every
  resume and their mounted filesystems went offline.
- Not tested: suspend-to-RAM and hibernation (unchanged by this series;
  the test platform has no working deep suspend), other dwc3 platforms.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages, and I reviewed and tested
every change as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (2):
      usb: dwc3: Tell xhci-plat when the core lost its state on resume
      usb: dwc3: Keep the host bus suspended, not torn down, across suspend-to-idle

 drivers/usb/dwc3/core.c | 43 +++++++++++++++++++++++++++++++++++++++----
 drivers/usb/dwc3/core.h |  5 +++++
 drivers/usb/dwc3/host.c | 29 ++++++++++++++++++++++++++---
 3 files changed, 70 insertions(+), 7 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-dwc3-s2idle-6e332174c57b

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

