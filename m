From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 29 Jun 2026 17:01:48 +0400
Subject: [PATCH v2 5/6] arm64: dts: qcom: ipq5018: add nodes required for
 Bluetooth support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-ipq5018-bluetooth-v2-5-02770f03b6bb@outlook.com>
References: <20260629-ipq5018-bluetooth-v2-0-02770f03b6bb@outlook.com>
In-Reply-To: <20260629-ipq5018-bluetooth-v2-0-02770f03b6bb@outlook.com>
To: Jens Axboe <axboe@kernel.dk>, Ulf Hansson <ulfh@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Jeff Johnson <jjohnson@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Balakrishna Godavarthi <quic_bgodavar@quicinc.com>, 
 Rocky Liao <quic_rjliao@quicinc.com>, 
 Saravana Kannan <saravanak@kernel.org>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-block@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mmc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-wireless@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 netdev@vger.kernel.org, linux-remoteproc@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782738117; l=1634;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=W34SYW/fjbOsDklvwrwSAhVsxNGBAP8d0fG4MddytFo=;
 b=oUXepPIoZQZWOrMOBVDWDI1KZEwPjMySuVBdKARHDks7qO8DfbPjALaRGumGeA5tgohxao793
 eqYNBk+cA+LBvKxHJZVks0oNvCfE51OLd5bf8ADJkiDprO/xit1mU6I
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

