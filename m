From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH 0/5] Add support for the IPQ5018 Internal GE PHY
Date: Sun, 25 May 2025 21:56:03 +0400
Message-Id: <20250525-ipq5018-ge-phy-v1-0-ddab8854e253@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALRZM2gC/x2MQQqAIBAAvyJ7TlDTiL4SHUy33IuZQhTh35OOw
 zDzQsFMWGBiL2S8qNARG8iOgQs27sjJNwYllBG6F5zSaYQceTMpPNyvg9F2s9qhhxaljBvd/3B
 eav0Au7tQZmAAAAA=
X-Change-ID: 20250430-ipq5018-ge-phy-db654afa4ced
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-clk@vger.kernel.org, George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748195765; l=1665;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=gAGGrpFaUot6LvUtyb2oJD1jQBlcQMlGQ2LEDzh1XzY=;
 b=ETlaBtS9A4SDI9CPrwyMaAyaR/EcnY1qbqF7EUT62PnT6kmIhqi+xx7bxpZ8AKxo4F5RYUTG2
 88D7dh2zvHaBiTDGz0BT4Ljm5VSX4nmKwdBizoSNLETbp+V2sOXx+qO
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IPQ5018 SoC contains an internal Gigabit Ethernet PHY with its
output pins that provide an MDI interface to either an external switch
in a PHY to PHY link architecture or directly to an attached RJ45
connector.

The PHY supports 10/100/1000 mbps link modes, CDT, auto-negotiation and
802.3az EEE.

The LDO controller found in the IPQ5018 SoC needs to be enabled to drive
power to the CMN Ethernet Block (CMN BLK) which the GE PHY depends on.
The LDO must be enabled in TCSR by writing to a specific register.

In a phy to phy architecture, DAC values need to be set to accommodate
for the short cable length.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
George Moussalem (5):
      dt-bindings: net: qca,ar803x: Add IPQ5018 Internal GE PHY support
      clk: qcom: gcc-ipq5018: fix GE PHY reset
      net: phy: qcom: at803x: Add Qualcomm IPQ5018 Internal PHY support
      arm64: dts: qcom: ipq5018: add MDIO buses
      arm64: dts: qcom: ipq5018: Add GE PHY to internal mdio bus

 .../devicetree/bindings/net/qca,ar803x.yaml        |  23 +++
 arch/arm64/boot/dts/qcom/ipq5018.dtsi              |  51 ++++-
 drivers/clk/qcom/gcc-ipq5018.c                     |   2 +-
 drivers/net/phy/qcom/Kconfig                       |   2 +-
 drivers/net/phy/qcom/at803x.c                      | 221 ++++++++++++++++++++-
 5 files changed, 287 insertions(+), 12 deletions(-)
---
base-commit: ebfff09f63e3efb6b75b0328b3536d3ce0e26565
change-id: 20250430-ipq5018-ge-phy-db654afa4ced

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

