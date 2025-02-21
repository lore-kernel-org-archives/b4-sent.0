From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH v3 0/2] can: flexcan: add transceiver capabilities
Date: Fri, 21 Feb 2025 08:40:03 +0100
Message-Id: <20250221-flexcan-add-transceiver-caps-v3-0-a947bde55a62@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANMtuGcC/4XNsQ6CMBSF4Vchna25tyKlTr6HcWjLrTRBIC1pM
 IR3tzAZBx3/M3xnYZGCp8guxcICJR/90Oc4HQpmW90/iPsmNxMgShSguOtotrrnumn4FHQfLfl
 EgVs9Ri6tc6oEsEpULBNjIOfnnb/dc7c+TkN47W8Jt3WDzyAQf8MJOXBbaWNkjdKAu3aeTEshH
 O3wZJudxIcn4I8nsqdrVBIcYl1WX966rm9se3khGwEAAA==
X-Change-ID: 20241209-flexcan-add-transceiver-caps-7cff9400c926
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740123678; l=1632;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=6jSgqIeR0c/xLJD5vzRfWmph7ikgHRiGHWzqjbobJj8=;
 b=qzOLZ9cXPue92g9sUo39JYmSXkvp/5FgZFy5Bg7sW9iFjdTL/jxrICP0c9+q6ELMqGf/NRiN/
 Arkr4WgzQ13DhEhAcn1wLfwyxXewGGr2uB1vNwBBrSbGbyzR/1xJHud
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently the flexcan driver does only support adding PHYs by using the
"old" regulator bindings. Add support for CAN transceivers as a PHY. Add
the capability to ensure that the PHY is in operational state when the link
is set to an "up" state.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v3:
- Have xceiver-supply or phys properties in bindings
- Switch do dev_err_probe in flexcan_probe when checking error of call
  devm_phy_optional_get
- Link to v2: https://lore.kernel.org/r/20250220-flexcan-add-transceiver-caps-v2-0-a81970f11846@liebherr.com

Changes in v2:
- Rename variable xceiver to transceiver in struct flexcan_priv and in
  flexcan_probe
- Set priv->can.bitrate_max if transceiver is found
- Fix commit messages which claim that transceivers are not supported
- Do not print error on EPROBE_DEFER after calling devm_phy_optional_get in
  flexcan_probe
- Link to v1: https://lore.kernel.org/r/20250211-flexcan-add-transceiver-caps-v1-0-c6abb7817b0f@liebherr.com

---
Dimitri Fedrau (2):
      dt-bindings: can: fsl,flexcan: add transceiver capabilities
      can: flexcan: add transceiver capabilities

 .../devicetree/bindings/net/can/fsl,flexcan.yaml   | 15 ++++++++++++
 drivers/net/can/flexcan/flexcan-core.c             | 27 +++++++++++++++++-----
 drivers/net/can/flexcan/flexcan.h                  |  1 +
 3 files changed, 37 insertions(+), 6 deletions(-)
---
base-commit: 6a24171b9625471abfc90c7b28c4b45bee64b3a4
change-id: 20241209-flexcan-add-transceiver-caps-7cff9400c926

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

