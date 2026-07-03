From: George Moussalem <george.moussalem@outlook.com>
Date: Fri, 03 Jul 2026 09:01:53 +0400
Subject: [PATCH v3 5/6] arm64: dts: qcom: ipq5018: add nodes required for
 Bluetooth support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260703-ipq5018-bluetooth-v3-5-62da72818ab3@outlook.com>
References: <20260703-ipq5018-bluetooth-v3-0-62da72818ab3@outlook.com>
In-Reply-To: <20260703-ipq5018-bluetooth-v3-0-62da72818ab3@outlook.com>
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783054918; l=1634;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=W34SYW/fjbOsDklvwrwSAhVsxNGBAP8d0fG4MddytFo=;
 b=odimwWqx4LOzTR3PXrfLhZJHoOeqpZSyfolbErDBbi4U7QejQr3mrRdwJlblQGu9ncqCpWzvW
 UkDUEWENAMmBphY0kKnIvOUrCNbRxV+D4PvhQOmHbE9BBslrwcCLJbX
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add nodes for the reserved memory carveout and Bluetooth.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 25 ++++++++++++++++++++++++-
 1 file changed, 24 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 6f8004a22a1f..65a47ba7d3a3 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -17,6 +17,23 @@ / {
 	#address-cells = <2>;
 	#size-cells = <2>;
 
+	bluetooth: bluetooth {
+		compatible = "qcom,ipq5018-bt";
+
+		firmware-name = "qca/bt_fw_patch.mbn";
+
+		clocks = <&gcc GCC_BTSS_LPO_CLK>;
+		clock-names = "lpo";
+		resets = <&gcc GCC_BTSS_BCR>;
+
+		qcom,ipc = <&apcs_glb 8 23>;
+		interrupts = <GIC_SPI 162 IRQ_TYPE_EDGE_RISING>;
+
+		memory-region = <&btss_region>;
+
+		status = "disabled";
+	};
+
 	clocks {
 		gephy_rx_clk: gephy-rx-clk {
 			compatible = "fixed-clock";
@@ -136,6 +153,11 @@ reserved-memory {
 		#size-cells = <2>;
 		ranges;
 
+		btss_region: bluetooth@7000000 {
+			reg = <0x0 0x07000000 0x0 0x58000>;
+			no-map;
+		};
+
 		bootloader@4a800000 {
 			reg = <0x0 0x4a800000 0x0 0x200000>;
 			no-map;
@@ -647,7 +669,8 @@ watchdog: watchdog@b017000 {
 
 		apcs_glb: mailbox@b111000 {
 			compatible = "qcom,ipq5018-apcs-apps-global",
-				     "qcom,ipq6018-apcs-apps-global";
+				     "qcom,ipq6018-apcs-apps-global",
+				     "syscon";
 			reg = <0x0b111000 0x1000>;
 			#clock-cells = <1>;
 			clocks = <&a53pll>, <&xo_board_clk>, <&gcc GPLL0>;

-- 
2.53.0

