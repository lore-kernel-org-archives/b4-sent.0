From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Subject: [PATCH v2 0/2] can: kvaser_usb: validate values received from the
 device
Date: Wed, 11 Nov 2026 17:23:57 +0000
Message-Id: <20261111-kvaser-usb-validate-v2-0-193dc10ca19b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAK2k9GoC/32NSw6CQBAFr0J6bZv56ARdeQ/Dogca6MjHzOBEQ
 7i7IwdwWS+peitEDsIRrsUKgZNEmacM5lBA3dPUMUqTGYwyTmut8JEoK/iKHhMN0tDCaG1t2J6
 8s76FbD4Dt/Leq/cqcy9xmcNnP0n6t/7vJY0KW+OcL89EF1XeupFkONbzCNW2bV9ZfaaetgAAA
 A==
To: mkl@pengutronix.de, mailhol@kernel.org, joasantonio108@gmail.com
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794417838; l=1654;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=xx6KoRG8pHta6iZo+MzyuW/1BziusnRXyXorD/1oFmM=;
 b=jO7IM++jqzS8buM6ErxiVZmK1Ojp+dt0W8rNGZYFRHnpaOXp/XUc2R+p49nGR32/Eyo6bnDrj
 qot04vOMFDwCa4/fF9AQeh9JWzUxWs40baGH858bVwdNDwUC7KBEpPv
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two fixes for values that kvaser_usb takes from the USB device without
checking them.

Patch 1 rejects hydra commands whose length is shorter than a standard
command.  A length of zero otherwise stalls the command loops, and a
short extended command makes the handlers read past the command.

Patch 2 rejects devices that report zero max outstanding tx, which
otherwise leads to a division by zero.

These issues were found with the help of an LLM-based code review tool
(Claude).  I checked the code paths by hand against v7.4-rc3 and
reviewed the fixes myself.  They are build-tested only (W=1, arm64); I
do not have the hardware to test them at runtime.

---
Changes in v2:
- Patch 1: require at least sizeof(struct kvaser_cmd) instead of the
  4-byte header, so that the extended command handlers do not read past
  a short command (sashiko review of v1).  Subject changed, it was
  "can: kvaser_usb: hydra: reject commands shorter than the header".
- Patch 2: unchanged.
- Link to v1: https://lore.kernel.org/r/20261110-kvaser-usb-validate-v1-0-f266b85aa908@gmail.com

---
Joas Antonio dos Santos (2):
      can: kvaser_usb: hydra: reject commands shorter than a standard command
      can: kvaser_usb: reject devices reporting zero max outstanding tx

 drivers/net/can/usb/kvaser_usb/kvaser_usb_core.c  | 6 ++++++
 drivers/net/can/usb/kvaser_usb/kvaser_usb_hydra.c | 8 +++++++-
 2 files changed, 13 insertions(+), 1 deletion(-)
---
base-commit: b3dfbde62cf1981c4638939c159dfd087b7a72e9
change-id: 20261110-kvaser-usb-validate-33c2e34b63bf

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

