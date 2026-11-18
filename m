From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v5 0/2] usb: core: Pair ports of different host controllers
 through their connector
Date: Wed, 18 Nov 2026 04:34:57 +0000
Message-Id: <20261118-usb-port-pairing-v5-0-5f1a26789270@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NTWrDMBCG4asEraugGf0Ed9V7lC5kaeRMaWwjO
 aYl+O6Vk40JJssXvnnmJgplpiLeDzeRaebCQ1/Dvh1EOPu+I8mxtkCFDgCUvJZWjkOe5Og5c99
 Jn1RyLinfIol6NmZK/HsnP78eXa7tN4VpddbFmcs05L/7zxnW3Qt+Bqlko9WJsIlIET+6i+efY
 xguYuVn3AK4A2AFjE3Wg8cmQXoG9BbQO4CuQHTBUWyNNhCeAbMF7A5gKoA26tD4GALCFliW5R+
 tLDc7hQEAAA==
X-Change-ID: 20261110-usb-port-pairing-af0f66f0ab2e
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Alan Stern <stern@rowland.harvard.edu>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mathias Nyman <mathias.nyman@intel.com>, Chen-Yu Tsai <wenst@chromium.org>, 
 Rob Herring <robh@kernel.org>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794976497; l=2005;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=W6RRPgLj/J961XutA4b1O7EtaSTpv9juv7uvo92JAp8=;
 b=I657dMRDQIVEhbu7V0keIZF62n+9Y32jpGwBeXV0imoXToH1EmURS8gD1cTy+IaViNbdsmueO
 /UcFxd1RVNZA4JzILx3850q09Ytim8JYewsRFAUnzlebQixkJUCvdf0
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the RK3588, the USB 2.0 lines of the USB 3.0 host 2 connector go to
a separate EHCI, so the USB core pairs its SuperSpeed port with the
wrong USB 2.0 port, and a USB 3 device present at boot stays at 480 Mb/s.

Patch 1 pairs the ports through their usb-connector. Patch 2 resets the
USB 2.0 port of such a device once, so that it retries SuperSpeed. The
Orange Pi 5 DT follows separately and needs Chen-Yu Tsai's usb-hcd
binding [1].

Tested on an Orange Pi 5 (7.3-based kernel): a USB 3 disk moved to
5 Gb/s in 3/3 boots, 6/6 xHCI rebinds and 2/2 runtime-suspended resets;
a device that stays at high speed kept its driver and a running read.
Not tested with an external USB 3 hub.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

[1] https://lore.kernel.org/all/20261014082037.1774672-2-wenst@chromium.org/

---
Changes in v5 (all from Sashiko):
- Patch 1: look up connect_type by the controller port number; don't hold
  back a port without a matching peer; connector_peer is not a bitfield
- Patch 2: reset through usb_reset_device(); keep the device if the
  SuperSpeed port can't be read or is connected; hold its lock until the
  USB 2.0 device is gone
- Link to v4: https://patch.msgid.link/20261115-usb-port-pairing-v4-0-25d3c9adcc21@gmail.com

---
Arun Iyengar (2):
      usb: core: Pair ports of different hubs through their connector
      usb: hub: Retry SuperSpeed for a device stuck on its USB 2.0 peer

 drivers/usb/core/hub.c  | 158 ++++++++++++++++++++++++++++++++++++++++++++++++
 drivers/usb/core/hub.h  |   5 ++
 drivers/usb/core/of.c   |  87 ++++++++++++++++++++++++++
 drivers/usb/core/port.c |  70 +++++++++++++++++++--
 include/linux/usb/of.h  |   8 +++
 5 files changed, 323 insertions(+), 5 deletions(-)
---
base-commit: f11fe7603df07fbb9fa02b0d385c1696c87a6dab
change-id: 20261110-usb-port-pairing-af0f66f0ab2e

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

