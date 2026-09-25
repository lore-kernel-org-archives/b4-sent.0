From: Michael Reeves <michael.reeves077@gmail.com>
Subject: [PATCH 00/13] wifi: brcmfmac: Add BCM4388 support
Date: Fri, 25 Sep 2026 23:43:35 +1000
Message-Id: <20260925-brcm4388-submit-v1-0-b5cbc2cde2fb@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MSw7CMAwA0atUXmNRUhIFrlKxyMdQS8SguEClq
 ncnsHyLmRWUKpPCuVuh0puVH9Jw2HWQpiA3Qs7NYHrj+pOxGGsqx8F71FcsPKNN0eeBXHbBQqu
 ela68/I/jpTkGpRYFSdPv8+FKd1JFoWXel8AC2/YFSIfTIIYAAAA=
X-Change-ID: 20260925-brcm4388-submit-5cb8d3e6d6a5
To: Arend van Spriel <arend.vanspriel@broadcom.com>, 
 Pieter-Paul Giesberts <pieterpg@broadcom.com>, 
 "Franky Lin (Zhenhui)" <frankyl@broadcom.com>, 
 Mathy Vanhoef <vanhoefm@gmail.com>, Kalle Valo <kvalo@kernel.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-wireless@vger.kernel.org, brcm80211@lists.linux.dev, 
 brcm80211-dev-list.pdl@broadcom.com, asahi@lists.linux.dev, 
 Hector Martin <marcan@marcan.st>, Daniel Berlin <dberlin@dberlin.org>, 
 Janne Grunau <j@jannau.net>, linux-kernel@vger.kernel.org, 
 Hante Meuleman <meuleman@broadcom.com>, linux-hardening@vger.kernel.org, 
 Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790343821; l=3446;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=5hnr3fAyqdNNH4Z/RHXKEByNtheCTZZ0q+ta1pJAZc4=;
 b=2zb9vdF2U2FJDxFeenmSGQAJOSIzHQXiK9t30lcN+L0v6QhVIQgtkg/RsJbZaTxd71l0QYYey
 HZ5HraR1EVYAaQ5L1OGgep2DC+ENDJ2b9Vbhh0AKYyNALZBZZrGOt0r
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=VJ0TvyQ9TvfzYZa908YSE9kpkjFLLD5luv0bERu+boc=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/fedora-20260918 with auth_id=1035
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Broadcom BCM4388 chipset requires new PCIe initialization and
firmware interfaces. Add support for these interfaces to brcmfmac to
enable basic station operation.

This series adds:
- Signed firmware loading and mailbox transport
- Fixes for chip identification and firmware capability matching
- Versioned scan and join requests, and extended PMK payloads
- Updated event mask handling

These changes include work by Hector Martin and Daniel Berlin from Asahi
Linux, refactored where needed for upstream inclusion.

The series provides basic station support only. 6 GHz support is planned
for a follow-up patchset after this lands. The driver retains legacy
interfaces for older firmware.

Tested on an Apple M3 MacBook Air (J613):
- Device boot and network scanning
- 5 GHz WPA2-PSK association and DHCP
- Bidirectional TCP traffic

Testing required separate Apple PCIe and devicetree patches, as well as
Janne Grunau's port-authorization fix [1].

[1] https://lore.kernel.org/linux-wireless/20260915-brcmfmac-4way-handshake-offload-authenticated-event-v2-1-fbb9cc7ac177@jannau.net/

---
Daniel Berlin (1):
      wifi: brcmfmac: Support versioned scan parameter layouts

Hector Martin (6):
      wifi: brcmfmac: Support newer PCIe core startup and interrupts
      wifi: brcmfmac: Negotiate PCIe mailbox transport with firmware
      wifi: brcmfmac: Load signed PCIe firmware images
      wifi: brcmfmac: Accept newer BSS information versions
      wifi: brcmfmac: Support versioned join requests
      wifi: brcmfmac: Add BCM4388 support

Michael Reeves (6):
      wifi: brcmfmac: pcie: Report the detected chip ID to the bus
      wifi: brcmfmac: Match complete firmware capability names
      wifi: brcmfmac: Fall back to RSSI-only default join preferences
      wifi: brcmfmac: Use event_msgs_ext for event masks
      wifi: brcmfmac: Handle larger firmware band lists
      wifi: brcmfmac: Handle extended PMK command payloads

 .../wireless/broadcom/brcm80211/brcmfmac/Makefile  |   1 +
 .../net/wireless/broadcom/brcm80211/brcmfmac/bus.h |   9 +
 .../broadcom/brcm80211/brcmfmac/cfg80211.c         | 368 +++++++-------
 .../wireless/broadcom/brcm80211/brcmfmac/chip.c    |  36 +-
 .../wireless/broadcom/brcm80211/brcmfmac/common.c  |  27 +-
 .../wireless/broadcom/brcm80211/brcmfmac/core.c    |   5 +-
 .../wireless/broadcom/brcm80211/brcmfmac/core.h    |  18 +
 .../wireless/broadcom/brcm80211/brcmfmac/feature.c | 124 ++++-
 .../wireless/broadcom/brcm80211/brcmfmac/feature.h |   2 +
 .../wireless/broadcom/brcm80211/brcmfmac/fweh.c    | 130 ++++-
 .../wireless/broadcom/brcm80211/brcmfmac/fweh.h    |   1 +
 .../broadcom/brcm80211/brcmfmac/fwil_types.h       | 141 +++++-
 .../wireless/broadcom/brcm80211/brcmfmac/msgbuf.c  |  65 ++-
 .../wireless/broadcom/brcm80211/brcmfmac/msgbuf.h  |   9 +-
 .../wireless/broadcom/brcm80211/brcmfmac/pcie.c    | 560 +++++++++++++++++----
 .../broadcom/brcm80211/brcmfmac/scan_param.c       | 416 +++++++++++++++
 .../broadcom/brcm80211/brcmfmac/scan_param.h       |  13 +
 .../broadcom/brcm80211/include/brcm_hw_ids.h       |   2 +
 .../broadcom/brcm80211/include/chipcommon.h        |   5 +
 19 files changed, 1593 insertions(+), 339 deletions(-)
---
base-commit: 42a9fb3382fc2573e92f41d203b095d9a372cfc9
change-id: 20260925-brcm4388-submit-5cb8d3e6d6a5

Best regards,
-- 
Michael Reeves <michael.reeves077@gmail.com>

