From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Subject: [PATCH v3 0/4] can: kvaser_usb: validate values received from the
 device
Date: Thu, 12 Nov 2026 17:27:54 +0000
Message-Id: <20261112-kvaser-usb-validate-v3-0-61587f639508@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABr39WoC/33NQQ6CMBCF4auQrq3ptNqAK+9hXExLgYlATYuNh
 nB3CysWxuU/yftmZtEFcpFdipkFlyiSH3OoQ8Fsh2PrONW5mRRSA4Dgj4R5wl/R8IQ91Tg5rpS
 VTp2MVqZhefkMrqH3pt7uuTuKkw+f7UmC9frfS8AFb6TWpjwjVqK8tgNSf7R+YKuX5N6A34bMB
 lSqtiAsQmX2xrIsX80ZOwL6AAAA
To: mkl@pengutronix.de, mailhol@kernel.org, joasantonio108@gmail.com
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794504474; l=2827;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=XWzeKKvhWdX7todL0hlA4VyWBOX4TkKHC0Wx+Kfy1gI=;
 b=24yTyHwDGxTN5P/VVmUPo8Np8ZGtusXHmYbJoPLgDPF73hV2nHRSP/WuD4ngT/bTyS0AtX3QN
 AD0z2s690LrBSciTkJ2eranhRoPsFqonYDMYqKbxP7eVFQZ+6ybKium
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Four fixes for values that kvaser_usb takes from the USB device without
checking them.

Patch 1 rejects hydra commands whose length is shorter than a standard
command.  A length of zero otherwise stalls the command loops, and a
short extended command makes the handlers read past the command.

Patch 2 rejects devices that report zero max outstanding tx, which
otherwise leads to a division by zero.

Patch 3 stops the hydra command parsers from reading the length of an
extended command before it has been received.

Patch 4 checks the error frame data and the payload of extended rx
commands against the command length.

These issues were found with the help of an LLM-based code review tool
(Claude); patches 3 and 4 address the points of the Sashiko review of
v2.  I checked the code paths by hand against v7.4-rc3 and reviewed the
fixes myself.  They are build-tested only (W=1, arm64); I do not have
the hardware to test them at runtime.  In particular patch 4 assumes
that the firmware includes the error frame data and the payload in the
command length, which follows from how the parsers advance through the
buffer but which I could not confirm on a device.

---
Changes in v3:
- New patch 3: do not read the extended command length before bytes 4
  and 5 are received, in kvaser_usb_hydra_wait_cmd() and
  kvaser_usb_hydra_read_bulk_callback() (sashiko review of v2).
- New patch 4: check err_frame_data and kcan_payload against the command
  length in kvaser_usb_hydra_rx_msg_ext() (sashiko review of v2).
- Patches 1 and 2: unchanged.
- Link to v2: https://lore.kernel.org/r/20261111-kvaser-usb-validate-v2-0-193dc10ca19b@gmail.com

Changes in v2:
- Patch 1: require at least sizeof(struct kvaser_cmd) instead of the
  4-byte header, so that the extended command handlers do not read past
  a short command (sashiko review of v1).  Subject changed, it was
  "can: kvaser_usb: hydra: reject commands shorter than the header".
- Patch 2: unchanged.
- Link to v1: https://lore.kernel.org/r/20261110-kvaser-usb-validate-v1-0-f266b85aa908@gmail.com

---
Joas Antonio dos Santos (4):
      can: kvaser_usb: hydra: reject commands shorter than a standard command
      can: kvaser_usb: reject devices reporting zero max outstanding tx
      can: kvaser_usb: hydra: do not read the command length before it is received
      can: kvaser_usb: hydra: check the payload of extended rx commands

 drivers/net/can/usb/kvaser_usb/kvaser_usb_core.c  |  6 ++
 drivers/net/can/usb/kvaser_usb/kvaser_usb_hydra.c | 67 +++++++++++++++++++++--
 2 files changed, 68 insertions(+), 5 deletions(-)
---
base-commit: b3dfbde62cf1981c4638939c159dfd087b7a72e9
change-id: 20261110-kvaser-usb-validate-33c2e34b63bf

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

