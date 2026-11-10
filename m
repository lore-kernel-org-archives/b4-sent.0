From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Subject: [PATCH 0/2] can: kvaser_usb: validate values received from the
 device
Date: Tue, 10 Nov 2026 03:56:41 +0000
Message-Id: <20261110-kvaser-usb-validate-v1-0-f266b85aa908@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPmV8moC/x3MTQqAIBBA4avIrBvwJ1p0lWihNtVQWGhJEN49a
 fkW33shUWRK0IsXImVOfIQaqhHgVxsWQp5qg5a6U0pJ3LKtBO/kMNudJ3sRGuM1mdZ1xs1Q5Rl
 p5ue/DmMpH243goJlAAAA
To: mkl@pengutronix.de, mailhol@kernel.org, joasantonio108@gmail.com
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794283001; l=1136;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=EPk1ni/Kaeh4ujfokyWdtrgUBNNRLNvf/WMEh31WoiY=;
 b=nkNiEMfXBkaVQ/nlluzDvnFqTBmhnBLKAMCzqrXuFqIE/imjRTn1LgKkuRcSHdQhGvzcbuHrE
 jdVyAqsUB13BICwH3ukTIUxgLf0vob/yTcOIz8AX/cl3KEUxgnS7uqE
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two fixes for values that kvaser_usb takes from the USB device without
checking them.

Patch 1 rejects hydra commands whose length is shorter than the command
header, which otherwise stall the command loops.

Patch 2 rejects devices that report zero max outstanding tx, which
otherwise leads to a division by zero.

These issues were found with the help of an LLM-based code review tool
(Claude).  I checked the code paths by hand against v7.4-rc3 and
reviewed the fixes myself.  They are build-tested only (W=1, arm64); I
do not have the hardware to test them at runtime.

---
Joas Antonio dos Santos (2):
      can: kvaser_usb: hydra: reject commands shorter than the header
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

