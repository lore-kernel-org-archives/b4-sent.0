From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 30 Jun 2025 16:35:01 +0400
Subject: [PATCH v6 2/3] arm64: dts: qcom: ipq5018: Add MDIO buses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250630-ipq5018-ge-phy-v6-2-01be06378c15@outlook.com>
References: <20250630-ipq5018-ge-phy-v6-0-01be06378c15@outlook.com>
In-Reply-To: <20250630-ipq5018-ge-phy-v6-0-01be06378c15@outlook.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751286906; l=1519;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=jA4BQsaw0tlEf36IZrwvZtR6C1am2pcwyAdrevsj4Hk=;
 b=zhpJIuMeUf1JRn427l7eFVhR1EPJ/rB+EyanEchKtvoBAEd02pDGr8SV7up81RN8ZX1b8UOCT
 M6NL0ziSVpKD8aqeexhAp9s85HOEOYu/sAO7joD8qvnnoS3/CqoFWaI
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IPQ5018 contains two mdio buses of which one bus is used to control the
SoC's internal GE PHY, while the other bus is connected to external PHYs
or switches.

There's already support for IPQ5018 in the mdio-ipq4019 driver, so let's
simply add the mdio nodes for them.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 24 ++++++++++++++++++++++++
 1 file changed, 24 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 130360014c5e14c778e348d37e601f60325b0b14..03ebc3e305b267c98a034c41ce47a39269afce75 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -182,6 +182,30 @@ pcie0_phy: phy@86000 {
 			status = "disabled";
 		};
 
+		mdio0: mdio@88000 {
+			compatible = "qcom,ipq5018-mdio";
+			reg = <0x00088000 0x64>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+
+			clocks = <&gcc GCC_MDIO0_AHB_CLK>;
+			clock-names = "gcc_mdio_ahb_clk";
+
+			status = "disabled";
+		};
+
+		mdio1: mdio@90000 {
+			compatible = "qcom,ipq5018-mdio";
+			reg = <0x00090000 0x64>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+
+			clocks = <&gcc GCC_MDIO1_AHB_CLK>;
+			clock-names = "gcc_mdio_ahb_clk";
+
+			status = "disabled";
+		};
+
 		tlmm: pinctrl@1000000 {
 			compatible = "qcom,ipq5018-tlmm";
 			reg = <0x01000000 0x300000>;

-- 
2.49.0

