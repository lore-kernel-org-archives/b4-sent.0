From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v6 0/3] usb: core: Pair ports of different host controllers
 through their connector
Date: Thu, 19 Nov 2026 10:03:22 +0000
Message-Id: <20261119-usb-port-pairing-v6-0-32bd7e36e426@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33OTW7DIBAF4KtErEsEw49DVrlH1AWGwaFqbAscq
 1XkuxcnG2RZXT7pzffmSTKmiJmcD0+ScI45Dn0J+uNA3M32HdLoSybAQHPOGX3klo5DmuhoY4p
 9R21gQevAbAtIytmYMMSfF3n9fOf8aL/QTauzNm4xT0P6fW3OfO39w8+cMmoEaxCMB/Rw6e42f
 h/dcCcrP0MNwA4ABZAqKMstmMDDFhA1IHYAUQCvnUbfSiG52wKyBtQOIAsAygtnrHcO+BZQNXD
 aAVQBVCj/6+ZkoGE1sCzLH5uCoEfGAQAA
X-Change-ID: 20261110-usb-port-pairing-af0f66f0ab2e
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Alan Stern <stern@rowland.harvard.edu>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mathias Nyman <mathias.nyman@intel.com>, Chen-Yu Tsai <wenst@chromium.org>, 
 Rob Herring <robh@kernel.org>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795082602; l=2316;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=6CIS3Zz+uxxB5Ymy9015y4VAUN2CMOYvUFqsT9mtKDk=;
 b=3DQ4h/0Fas3BsxHJQkWNbWc+qo9pYsJq/nAG5sclV/uGQG3RsVaDAojjuSqdSBEZVpra4FIRt
 1DNMMJTzRd6DVtx/MRPxIrIpqxGXhny4MZPIcCf/PYAf92w6BBOBmAA
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the RK3588, the USB 2.0 lines of the USB 3.0 host 2 connector go to
a separate EHCI, so the USB core pairs its SuperSpeed port with the
wrong USB 2.0 port, and a USB 3 device present at boot stays at 480 Mb/s.

Patch 1 pairs the ports through their usb-connector. Patch 2 fixes the
connect_type of a dwc3 SuperSpeed port with a USB 2.0 device node. Patch
3 resets the USB 2.0 port of such a device once, so that it retries
SuperSpeed. The Orange Pi 5 DT follows separately and needs Chen-Yu
Tsai's usb-hcd binding [1].

Tested on an Orange Pi 5 (7.3-based kernel with KASAN): a USB 3 disk
that enumerated on the USB 2.0 port moved to 5 Gb/s in 3/3 boots, 6/6
xHCI rebinds and 2/2 runtime-suspended resets. With DT overlays: ports
whose connector peer is not a USB node are paired by default, and a
SuperSpeed port shaped like the lckfb one reads hotplug. Not tested with
an external USB 3 hub; a device that stays at high speed was tested on
v5 only.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

[1] https://lore.kernel.org/all/20261014082037.1774672-2-wenst@chromium.org/

---
Changes in v6:
- Patch 1: take a connector peer only if it is or is under a "usb" node
  (Sashiko)
- Patch 1: connector_peer as a :1 bitfield, set before the port is
  registered (Alan Stern, Sashiko)
- New patch 2: dwc3 SuperSpeed port connect_type from the graph first (Sashiko)
- Link to v5: https://patch.msgid.link/20261118-usb-port-pairing-v5-0-5f1a26789270@gmail.com

---
Arun Iyengar (3):
      usb: core: Pair ports of different hubs through their connector
      usb: core: Prefer the graph for a dwc3 SuperSpeed port's connect_type
      usb: hub: Retry SuperSpeed for a device stuck on its USB 2.0 peer

 drivers/usb/core/hub.c  | 158 ++++++++++++++++++++++++++++++++++++++++++++++++
 drivers/usb/core/hub.h  |   5 ++
 drivers/usb/core/of.c   | 148 ++++++++++++++++++++++++++++++++++++++++-----
 drivers/usb/core/port.c |  89 ++++++++++++++++++++++++---
 include/linux/usb/of.h  |  13 ++++
 5 files changed, 390 insertions(+), 23 deletions(-)
---
base-commit: f11fe7603df07fbb9fa02b0d385c1696c87a6dab
change-id: 20261110-usb-port-pairing-af0f66f0ab2e

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

