From: George Moussalem <george.moussalem@outlook.com>
Date: Fri, 16 May 2025 16:36:11 +0400
Subject: [PATCH v4 4/5] arm64: dts: ipq5018: Add CMN PLL node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250516-ipq5018-cmn-pll-v4-4-389a6b30e504@outlook.com>
References: <20250516-ipq5018-cmn-pll-v4-0-389a6b30e504@outlook.com>
In-Reply-To: <20250516-ipq5018-cmn-pll-v4-0-389a6b30e504@outlook.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Luo Jie <quic_luoj@quicinc.com>, 
 Lee Jones <lee@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747398968; l=2487;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=/8MkwsA8tkiEOngrTa6pfTHAzpGz2h90R2FK3FYJTt8=;
 b=XYGqWejlJkkk2QOrQ4iHC4vWGyTQHibWeBLP+ybPHgM+4pWwEHKPBsAsi+8tB1JI7Fzf+TmZu
 mEDeGuE2AtGCDD6oxgjgNAXdj7UMQ2bsRXsZ+UAQFwPLVDgyV9huMHe
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add CMN PLL node for enabling output clocks to the networking
hardware blocks on IPQ5018 devices.

The reference clock of CMN PLL is routed from XO to the CMN PLL
through the internal WiFi block.
.XO (48 MHZ) --> WiFi (multiplier/divider)--> 96 MHZ to CMN PLL.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 33 +++++++++++++++++++++++++++++++--
 1 file changed, 31 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 130360014c5e14c778e348d37e601f60325b0b14..632caa94df51197ddaa85d172412553e87cf89f3 100644
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
 
 / {
@@ -16,6 +17,14 @@ / {
 	#size-cells = <2>;
 
 	clocks {
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
@@ -25,6 +34,12 @@ xo_board_clk: xo-board-clk {
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
@@ -182,6 +197,20 @@ pcie0_phy: phy@86000 {
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
 		tlmm: pinctrl@1000000 {
 			compatible = "qcom,ipq5018-tlmm";
 			reg = <0x01000000 0x300000>;

-- 
2.49.0

