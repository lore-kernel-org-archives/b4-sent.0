From: George Moussalem <george.moussalem@outlook.com>
Date: Sun, 25 May 2025 21:56:08 +0400
Subject: [PATCH 5/5] arm64: dts: qcom: ipq5018: Add GE PHY to internal mdio
 bus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250525-ipq5018-ge-phy-v1-5-ddab8854e253@outlook.com>
References: <20250525-ipq5018-ge-phy-v1-0-ddab8854e253@outlook.com>
In-Reply-To: <20250525-ipq5018-ge-phy-v1-0-ddab8854e253@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748195765; l=1843;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=RbZYI9mHUjINGh38wXyVEQGgEtjNvQeZPMy+hpynOhA=;
 b=VYUp3FjEr6voXpngVWA+ruIyKayYUaXPmgTAd4U/eODjiXYYjWK3ETaw/TxwWWlHt2kUfaiox
 8HhdPvf0hFaCND7OBVCC0uXcmYJy+ASmjLbH4aV7OY1jhuVkTc4GNSZ
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IPQ5018 SoC contains an internal GE PHY, always at phy address 7.
As such, let's add the GE PHY node to the SoC dtsi.

In addition, the GE PHY outputs both the RX and TX clocks to the GCC
which gate controls them and routes them back to the PHY itself.
So let's create two DT fixed clocks and register them in the GCC node.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 27 +++++++++++++++++++++++++--
 1 file changed, 25 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 03ebc3e305b267c98a034c41ce47a39269afce75..ff2de44f9b85993fb2d426f85676f7d54c5cf637 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -16,6 +16,18 @@ / {
 	#size-cells = <2>;
 
 	clocks {
+		gephy_rx_clk: gephy-rx-clk {
+			compatible = "fixed-clock";
+			clock-frequency = <125000000>;
+			#clock-cells = <0>;
+		};
+
+		gephy_tx_clk: gephy-tx-clk {
+			compatible = "fixed-clock";
+			clock-frequency = <125000000>;
+			#clock-cells = <0>;
+		};
+
 		sleep_clk: sleep-clk {
 			compatible = "fixed-clock";
 			#clock-cells = <0>;
@@ -192,6 +204,17 @@ mdio0: mdio@88000 {
 			clock-names = "gcc_mdio_ahb_clk";
 
 			status = "disabled";
+
+			ge_phy: ethernet-phy@7 {
+				reg = <7>;
+
+				clocks = <&gcc GCC_GEPHY_RX_CLK>,
+					 <&gcc GCC_GEPHY_TX_CLK>;
+
+				resets = <&gcc GCC_GEPHY_MISC_ARES>;
+
+				qca,eth-ldo-ready = <&tcsr 0x105c4>;
+			};
 		};
 
 		mdio1: mdio@90000 {
@@ -232,8 +255,8 @@ gcc: clock-controller@1800000 {
 				 <&pcie0_phy>,
 				 <&pcie1_phy>,
 				 <0>,
-				 <0>,
-				 <0>,
+				 <&gephy_rx_clk>,
+				 <&gephy_tx_clk>,
 				 <0>,
 				 <0>;
 			#clock-cells = <1>;

-- 
2.49.0

