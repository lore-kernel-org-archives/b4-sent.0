From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 02 Jun 2026 10:50:39 +0400
Subject: [PATCH v2 3/4] arm64: qcom: ipq5018: Add GEPHY RX and TX clocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260602-ipq5018-gephy-clocks-v2-3-65a1f1d881f3@outlook.com>
References: <20260602-ipq5018-gephy-clocks-v2-0-65a1f1d881f3@outlook.com>
In-Reply-To: <20260602-ipq5018-gephy-clocks-v2-0-65a1f1d881f3@outlook.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780383045; l=821;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=ZUcDzKT3pAn1GyMp8FWZKORP9V8n09/s7Z10uOma/1w=;
 b=hYmsbMQ3fMK4DDwf3ak4gIISvaF2g/SUFPxa+jH6K/jRD+NdcwfZrCKIF2+fxWqVJc4XB2d5y
 yYpto1t9q0jBUCeVMlkeTguvV5chLRkX84lzcm7RqAD2dI/lHrWH9RR
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add RX and TX clocks for the IPQ5018 GEPHY to enable the datapath.

Fixes: f5f2b835e316 ("arm64: dts: qcom: ipq5018: Add GE PHY to internal mdio bus")
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 6f8004a22a1f..60c27a6f2b10 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -229,6 +229,9 @@ ge_phy: ethernet-phy@7 {
 				compatible = "ethernet-phy-id004d.d0c0";
 				reg = <7>;
 
+				clocks = <&gcc GCC_GEPHY_RX_CLK>,
+					 <&gcc GCC_GEPHY_TX_CLK>;
+				clock-names = "rx", "tx";
 				resets = <&gcc GCC_GEPHY_MISC_ARES>;
 			};
 		};

-- 
2.53.0

