From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v3 0/2] usb: core: Pair ports of different host controllers
 through their connector
Date: Fri, 13 Nov 2026 16:39:33 +0000
Message-Id: <20261113-usb-port-pairing-v3-0-d6c6edb4341c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NQQ6CMBCF4auQrq1pB8HgynsYFwWmMEZo00KjI
 dzdFjcsjMs/efPNwjw6Qs8u2cIcBvJkxhj5IWNNr8YOObWxGQgopZSCz77m1riJW0WOxo4rLXR
 ZaqFqQBbPrENNr4283b/t5/qBzZSctOjJT8a9t59Bpt0fPkgueJWLM0LVArZw7QZFz2NjBpb4A
 HsAfgAQgVOhCyUVVFrqPbCu6wd/qm1JAwEAAA==
X-Change-ID: 20261110-usb-port-pairing-af0f66f0ab2e
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Alan Stern <stern@rowland.harvard.edu>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mathias Nyman <mathias.nyman@intel.com>, Chen-Yu Tsai <wenst@chromium.org>, 
 Chen-Yu Tsai <wens@kernel.org>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794587973; l=3327;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=94ljvUhZfOwcriwlLh+HVppbDrBWPBP8YRlEjtdMTao=;
 b=yRzdjuLIBZz2A126kliJbvh1YvnIeRw1y5fu8QBIot7q1f80EXqrlI3kteaqoUIwqlR6DpKnj
 YWHvVDy0DBoDPdejeeLbJ/9Vsn/H8xiduWQgZ39crdMjL0XcLOWBwq1
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Chen-Yu Tsai pointed out that root hub graph ports use the raw xHCI
port number, as in DT and ACPI; v3 does that.

On the RK3588, USB 3.0 host 2 is a SuperSpeed-only xHCI and the USB 2.0
lines of its connector go to a separate EHCI. The USB core pairs the
SuperSpeed port with the dead USB 2.0 port of the same xHCI. On the
Orange Pi 5, whose USB 3 Type-A port has VBUS always on, a USB 3 device
present at boot connects at 480 Mb/s to the EHCI before the xHCI is up
and stays there.

Patch 1 pairs the two ports through a usb-connector whose halves lead
to different hubs or host controllers. Patch 2 resets such a device
once when the SuperSpeed root hub starts, so that it retries
SuperSpeed. A device that ignores the reset (SanDisk Ultra Fit) stays
at high speed.

The Orange Pi 5/5B DT goes to the Rockchip tree separately; its EHCI
"ports" node needs Chen-Yu's usb-hcd binding [1].
usb_of_get_connect_type() still looks up root hub ports by root hub
port number; Chen-Yu has fixes for those lookups. His M.2 series [2]
finds a hub port's graph port with fwnode_graph_get_port_by_id(); this
series does not depend on it.

Tested on an Orange Pi 5 (RK3588S) with a v7.3 based kernel: a USB 3
device present at boot came up at 5 Gb/s on host 2 in 4/4 boots and
stayed there across 8 s2idle cycles, xHCI rebinds and unbind races.
Type-C port pairing is unchanged. Not tested with an external USB 3 hub.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

[1] https://lore.kernel.org/all/20261014082037.1774672-2-wenst@chromium.org/
[2] https://lore.kernel.org/all/20260916075745.3549953-1-wenst@chromium.org/

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
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

 drivers/usb/core/hub.c  | 109 ++++++++++++++++++++++++++++++++++++++++++++++++
 drivers/usb/core/hub.h  |   3 ++
 drivers/usb/core/of.c   |  98 +++++++++++++++++++++++++++++++++++++++++++
 drivers/usb/core/port.c |  67 +++++++++++++++++++++++++++--
 include/linux/usb/of.h  |   8 ++++
 5 files changed, 281 insertions(+), 4 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-usb-port-pairing-af0f66f0ab2e

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

