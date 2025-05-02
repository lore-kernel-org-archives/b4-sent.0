From: George Moussalem <george.moussalem@outlook.com>
Date: Fri, 02 May 2025 14:15:48 +0400
Subject: [PATCH 6/6] arm64: dts: qcom: Update IPQ5018 xo_board_clk to use
 fixed factor clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250502-ipq5018-cmn-pll-v1-6-27902c1c4071@outlook.com>
References: <20250502-ipq5018-cmn-pll-v1-0-27902c1c4071@outlook.com>
In-Reply-To: <20250502-ipq5018-cmn-pll-v1-0-27902c1c4071@outlook.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Luo Jie <quic_luoj@quicinc.com>, 
 Lee Jones <lee@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746180946; l=1998;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=LxxatdRb90i4on9YIidoVQJCRrrcChIjg+ks5OFGzsg=;
 b=qCfczu/hRv/nE0TSXTdWP0CI16lOIV3RTDfLOzPPumJyG3yT7ydLhYyjcaXLKICiDDgcr+qFA
 CdI3ZL5c5YuCAHgmMJF6Tl86pdjVRSigL5rd0vjWq6ufBaUyD7sh4aL
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The xo_board_clk is fixed to 24 MHZ, which is routed from WiFi output
clock 96 MHZ (also being the reference clock of CMN PLL) divided by 4
to the analog block routing channel.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts             | 3 ++-
 arch/arm64/boot/dts/qcom/ipq5018-tplink-archer-ax55-v1.dts | 3 ++-
 arch/arm64/boot/dts/qcom/ipq5018.dtsi                      | 3 ++-
 3 files changed, 6 insertions(+), 3 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts b/arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts
index 8460b538eb6a3e2d6b971bd9637309809e0c0f0c..abb629678c023a2eb387ebf229f6dd1c30133b19 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts
+++ b/arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts
@@ -80,5 +80,6 @@ &usbphy0 {
 };
 
 &xo_board_clk {
-	clock-frequency = <24000000>;
+	clock-div = <4>;
+	clock-mult = <1>;
 };
diff --git a/arch/arm64/boot/dts/qcom/ipq5018-tplink-archer-ax55-v1.dts b/arch/arm64/boot/dts/qcom/ipq5018-tplink-archer-ax55-v1.dts
index 5bb021cb29cd39cb95035bfac1bdbc976439838b..7a25af57749c8e8c9a6a185437886b04b0d99e8e 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018-tplink-archer-ax55-v1.dts
+++ b/arch/arm64/boot/dts/qcom/ipq5018-tplink-archer-ax55-v1.dts
@@ -124,5 +124,6 @@ uart_pins: uart-pins-state {
 };
 
 &xo_board_clk {
-	clock-frequency = <24000000>;
+	clock-div = <4>;
+	clock-mult = <1>;
 };
diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 78368600ba44825b38f737a6d7837a80dc32efb6..7e40f80e4795de25d55b5a19c1beb98e5abcdef3 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -31,7 +31,8 @@ sleep_clk: sleep-clk {
 		};
 
 		xo_board_clk: xo-board-clk {
-			compatible = "fixed-clock";
+			compatible = "fixed-factor-clock";
+			clocks = <&ref_96mhz_clk>;
 			#clock-cells = <0>;
 		};
 

-- 
2.49.0

