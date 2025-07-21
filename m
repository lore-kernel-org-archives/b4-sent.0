From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 21 Jul 2025 10:04:35 +0400
Subject: [PATCH v5 1/2] arm64: dts: ipq5018: Add CMN PLL node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250721-ipq5018-cmn-pll-v5-1-4cbf3479af65@outlook.com>
References: <20250721-ipq5018-cmn-pll-v5-0-4cbf3479af65@outlook.com>
In-Reply-To: <20250721-ipq5018-cmn-pll-v5-0-4cbf3479af65@outlook.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753077887; l=2619;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=Jc7mpYMgCxpITcEYnscgFXztbHy0Q20lBLLi8g9IFDY=;
 b=ZlhpHZYcU/pvY451fXhFyhUUQlQkmIA98V5BkMy/NBGcOpKwYuiesMbF60fN8bh1mFZ/AtuOO
 Nq0FP0/K73kAehBojSK3M402uuZSqXJOoXmo+NGqzQZdJPgAdwtfTRD
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add CMN PLL node for enabling output clocks to the networking
hardware blocks on IPQ5018 devices.

The reference clock of CMN PLL is routed from XO to the CMN PLL
through the internal WiFi block.
.XO (48 MHZ) --> WiFi (multiplier/divider)--> 96 MHZ to CMN PLL.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 33 +++++++++++++++++++++++++++++++--
 1 file changed, 31 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 9ce73682e4ae7cde90f151dfcd41a5201ced2aa6..3ddcceaf760dccb39914a117d5dcc8955fdb94fe 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -2,12 +2,13 @@
 /*
  * IPQ5018 SoC device tree source
  *
- * Copyright (c) 2023 The Linux Foundation. All rights reserved.
+ * Copyright (c) 2023-2025 The Linux Foundation. All rights reserved.
  */
 
 #include <dt-bindings/clock/qcom,apss-ipq.h>
-#include <dt-bindings/interrupt-controller/arm-gic.h>
 #include <dt-bindings/clock/qcom,gcc-ipq5018.h>
+#include <dt-bindings/clock/qcom,ipq5018-cmn-pll.h>
+#include <dt-bindings/interrupt-controller/arm-gic.h>
 #include <dt-bindings/reset/qcom,gcc-ipq5018.h>
 #include <dt-bindings/thermal/thermal.h>
 
@@ -29,6 +30,14 @@ gephy_tx_clk: gephy-tx-clk {
 			#clock-cells = <0>;
 		};
 
+		ref_96mhz_clk: ref-96mhz-clk {
+			compatible = "fixed-factor-clock";
+			clocks = <&xo_clk>;
+			#clock-cells = <0>;
+			clock-div = <1>;
+			clock-mult = <2>;
+		};
+
 		sleep_clk: sleep-clk {
 			compatible = "fixed-clock";
 			#clock-cells = <0>;
@@ -38,6 +47,12 @@ xo_board_clk: xo-board-clk {
 			compatible = "fixed-clock";
 			#clock-cells = <0>;
 		};
+
+		xo_clk: xo-clk {
+			compatible = "fixed-clock";
+			#clock-cells = <0>;
+			clock-frequency = <48000000>;
+		};
 	};
 
 	cpus {
@@ -229,6 +244,20 @@ mdio1: mdio@90000 {
 			status = "disabled";
 		};
 
+		cmn_pll: clock-controller@9b000 {
+			compatible = "qcom,ipq5018-cmn-pll";
+			reg = <0x0009b000 0x800>;
+			clocks = <&ref_96mhz_clk>,
+				 <&gcc GCC_CMN_BLK_AHB_CLK>,
+				 <&gcc GCC_CMN_BLK_SYS_CLK>;
+			clock-names = "ref",
+				      "ahb",
+				      "sys";
+			#clock-cells = <1>;
+			assigned-clocks = <&cmn_pll IPQ5018_CMN_PLL_CLK>;
+			assigned-clock-rates-u64 = /bits/ 64 <9600000000>;
+		};
+
 		qfprom: qfprom@a0000 {
 			compatible = "qcom,ipq5018-qfprom", "qcom,qfprom";
 			reg = <0x000a0000 0x1000>;

-- 
2.50.1

