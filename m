From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v4 0/2] usb: core: Pair ports of different host controllers
 through their connector
Date: Sun, 15 Nov 2026 08:57:17 +0000
Message-Id: <20261115-usb-port-pairing-v4-0-25d3c9adcc21@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NQQ6CMBCF4auYrq1pp1CDK+9hXJR2imMUSAtEQ
 7i7BTfEEJd/8uabkUUMhJGddiMLOFCkpk6R7XfM3kxdISeXmoEALaUUvI8lb5vQ8dZQoLrixgu
 vtRemBGTprA3o6bWQl+u3Y1/e0XazMy9uFLsmvJefg5x3f/hBcsELJY4IhQN0cK6ehh4H2zzZz
 A+wBmADgARkuc+NNFB46X8BtQbUBqAS4LTV6MpMZdKugWmaPpmXcqlEAQAA
X-Change-ID: 20261110-usb-port-pairing-af0f66f0ab2e
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Alan Stern <stern@rowland.harvard.edu>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mathias Nyman <mathias.nyman@intel.com>, Chen-Yu Tsai <wenst@chromium.org>, 
 Rob Herring <robh@kernel.org>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794733037; l=3267;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=TNyqfCrClCiQ9PSmIf1hoQLCJm8Psl9gD1KGnA7LIco=;
 b=t/vzdDXfhNvY/T1LvtcHpWF8Sfx2XFWLlEhpAbqAtqwyI7jejNlJ+aTHmA4Z5IC7qBD0Gc3iG
 vkG5e/jIER1B9+zFGn+QLiz0sgFDqTTHvP7D2uIHeTBNj4SMrIcPSNk
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the RK3588, USB 3.0 host 2 is a SuperSpeed-only xHCI; the USB 2.0
lines of its connector go to a separate EHCI. The USB core pairs the
SuperSpeed port with a dead USB 2.0 port of the same xHCI. On the
Orange Pi 5 (VBUS always on) a USB 3 device present at boot connects
to the EHCI before the xHCI is up and stays at 480 Mb/s.

Patch 1 pairs the two ports through their usb-connector and marks them
hotplug. Patch 2 resets the USB 2.0 port of such a device when the
SuperSpeed root hub starts, so that it retries SuperSpeed.

The Orange Pi 5/5B DT goes to the Rockchip tree separately; its EHCI
"ports" node needs Chen-Yu Tsai's usb-hcd binding [1]. This series
does not depend on his M.2 series [2].

Tested on an Orange Pi 5 (7.3-based kernel): a USB 3 disk present at
boot came up at 5 Gb/s in 3/3 boots and after 8/8 xHCI rebinds; a
high-speed-only disk kept its drivers bound and its data. Not tested
with an external USB 3 hub.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

[1] https://lore.kernel.org/all/20261014082037.1774672-2-wenst@chromium.org/
[2] https://lore.kernel.org/all/20260916075745.3549953-1-wenst@chromium.org/

---
Changes in v4:
- Patch 1: say that dwc3-numbered graphs keep today's pairing (Sashiko)
- Patch 1: mark a connector-paired port hotplug (Sashiko)
- Patch 2: stop the peer reset work when the hub is quiescing (Sashiko)
- Patch 2: don't leave the EHCI port with its companion: reset once
- Patch 2: resume a runtime-suspended device before the reset
- Fewer, shorter comments; shorter cover
- Link to v3: https://patch.msgid.link/20261113-usb-port-pairing-v3-0-d6c6edb4341c@gmail.com

Changes in v3:
- Patch 1: find root hub ports in the graph by the raw controller port
  number (usb_hcd_find_raw_port_number()) on both sides (Chen-Yu Tsai)
- Patch 1: don't skip a connector peer whose connect_type is "not
  used"
- Shorter commit messages and comments; patch 2 code unchanged
- Link to v2: https://patch.msgid.link/20261112-usb-port-pairing-v2-0-45f5a1a29f1f@gmail.com

Changes in v2:
- Dropped v1 patch 1 (generic-ehci binding) for Chen-Yu Tsai's
  usb-hcd binding (Chen-Yu Tsai, Rob Herring)
- Patch 2: reset only when the SuperSpeed root hub starts, never a hub,
  only on USB 2.0 root hub ports of another controller; cancel in
  hub_quiesce(), runtime PM reference, freezable hub_wq (Sashiko)
- v1 patch 4 (DTS) split out (Krzysztof Kozlowski)
- Link to v1: https://patch.msgid.link/20261110-usb-port-pairing-v1-0-9307e29d2ed2@gmail.com

---
Arun Iyengar (2):
      usb: core: Pair ports of different hubs through their connector
      usb: hub: Retry SuperSpeed for a device stuck on its USB 2.0 peer

 drivers/usb/core/hub.c  | 132 ++++++++++++++++++++++++++++++++++++++++++++++++
 drivers/usb/core/hub.h  |   3 ++
 drivers/usb/core/of.c   |  87 +++++++++++++++++++++++++++++++
 drivers/usb/core/port.c |  62 +++++++++++++++++++++--
 include/linux/usb/of.h  |   8 +++
 5 files changed, 288 insertions(+), 4 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-usb-port-pairing-af0f66f0ab2e

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

