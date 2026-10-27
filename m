From: Joseph Telaak <joseph@telaak.dev>
Subject: [PATCH v2 0/2] usb: ehci-pci: Intel CE5300 TDI EHCI support
Date: Tue, 27 Oct 2026 19:38:33 -0400
Message-Id: <20261027-ehci-ce5300-hostpc-v2-0-375e9d362d74@telaak.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/32NQQ6CMBBFr0Jm7Zi2SEFX3sOwqMNgq4aStjYaw
 t0F3Lt8yfvvTxA5OI5wKiYInF10flhA7Qoga4Ybo+sWBiWUlkJWyJYcElelEGh9TCNhUytFvdA
 9NQ0swzFw795b9NL+OL6ud6a0llbDuph8+GyvWa7e34MsUWJJhnVNUh4P+pz4acxj33GGdp7nL
 1GgCVjHAAAA
X-Change-ID: 20261015-ehci-ce5300-hostpc-8722cf06fc88
To: Alan Stern <stern@rowland.harvard.edu>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793144314; l=1649;
 i=joseph@telaak.dev; s=default; h=from:subject:message-id;
 bh=PAirIQfrTAEvPYMrQ2CqBNCn+EoDZypmUrkIoD9ioHY=;
 b=EtCjWR7eFV6pB71cSePi2Nb15DZSZidFhoT7vbsiKmxsno2Oa3wvZX80q3cTGKlPTd026NNvA
 +yrm/h6tpTkCt13NsePpgOYlaWfeYJPyru/wekfi0Hg68Vk7s6WtBjC
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=vbM2RxVf3De5c1pQhdR2zZNLas2GaS+BXNVRR5qg3hI=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/default with auth_id=1203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TDI EHCI core in the Intel CE5300 SoCs needs two quirks: its PCI
config space has no EHCI registers at 0x60 (patch 1), and host mode
lives in USBMODE_EX rather than USBMODE (patch 2). Without them no
device is ever detected, and the controller is not stopped on
shutdown.

CONFIG_USB_EHCI_ROOT_HUB_TT=y is still required, as for any TDI
core. These are device quirks rather than regression fixes, so there
are no Fixes: tags; they may be suitable for stable if you think so.

Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
Changes in v2:
- 1/2: new; skip the SBRN and port-wake reads at PCI config
  0x60-0x62, which this core doesn't have. A zero SBRN made
  ehci_shutdown() a no-op. Adds the is_intel_ce_tdi() helper used
  by 2/2.
- 2/2: tdi_in_host_mode() reads host mode back from USBMODE_EX on
  this core (new has_usbmode_ex flag); in v1 ehci_halt() returned
  without stopping the controller. Reported by the Sashiko AI review.
- Dropped CE2600 from the subjects: only the CE5300 was tested.
- Link to v1: https://patch.msgid.link/20261015-ehci-ce5300-hostpc-v1-1-3cae67c11946@telaak.dev

---
Joseph Telaak (2):
      usb: ehci-pci: Skip SBRN and port-wake reads on Intel CE5300
      usb: ehci-pci: Set has_hostpc for TDI EHCI on Intel CE5300

 drivers/usb/host/ehci-hcd.c |  5 +++++
 drivers/usb/host/ehci-pci.c | 22 +++++++++++++++++++++-
 drivers/usb/host/ehci.h     |  1 +
 3 files changed, 27 insertions(+), 1 deletion(-)
---
base-commit: bbf6b99a57b2479bf51c3c8ad0946f4b8c33ed69
change-id: 20261015-ehci-ce5300-hostpc-8722cf06fc88

Best regards,
--  
Joseph Telaak <joseph@telaak.dev>

