From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 25 Aug 2026 16:37:29 +0400
Subject: [PATCH v3 12/12] arm64: dts: qcom: ipq5018: Enable USB Super-Speed
 PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-ipq5018-usb3-v3-12-39be0955a6aa@outlook.com>
References: <20260825-ipq5018-usb3-v3-0-39be0955a6aa@outlook.com>
In-Reply-To: <20260825-ipq5018-usb3-v3-0-39be0955a6aa@outlook.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Praveenkumar I <praveenkumar.i@oss.qualcomm.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Nitheesh Sekar <quic_nsekar@quicinc.com>, 
 Wesley Cheng <quic_wcheng@quicinc.com>, 
 Manivannan Sadhasivam <mani@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787661450; l=1078;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=mqT4fUHiS6tNRhSdjnTI3aemIVcVL9vUJPPDNDpgcvM=;
 b=Zbh5XdZj5kfib84EvhnO+1xUv69j2kvgZlvOlgYPrI6hfVGPf812sBi6fbEFwZkzDzuN8g92X
 zu3GBxeoPA+BP2pHmBTWaCK2dYjZLRiSjy+BermATV6GSCSAqPfpC8b
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the 5V supply regulator and enable USB Super-Speed PHY support.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts b/arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts
index 8efb2b21ed9e..ca29f271e673 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts
+++ b/arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts
@@ -22,6 +22,14 @@ aliases {
 	chosen {
 		stdout-path = "serial0:115200n8";
 	};
+
+	regulator_fixed_5p0: regulator-s0500 {
+		compatible = "regulator-fixed";
+		regulator-min-microvolt = <5000000>;
+		regulator-max-microvolt = <5000000>;
+		regulator-name = "fixed_5p0";
+		gpios = <&tlmm 24 GPIO_ACTIVE_LOW>;
+	};
 };
 
 &blsp1_uart1 {
@@ -119,6 +127,12 @@ &usbphy0 {
 	status = "okay";
 };
 
+&usbphy1 {
+	vdd-supply = <&regulator_fixed_5p0>;
+
+	status = "okay";
+};
+
 &xo_board_clk {
 	clock-div = <4>;
 	clock-mult = <1>;

-- 
2.53.0

