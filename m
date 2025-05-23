From: George Moussalem <george.moussalem@outlook.com>
Date: Fri, 23 May 2025 16:30:57 +0400
Subject: [PATCH] arm64: dts: qcom: ipq5018: Add crypto nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250523-ipq5018-crypto-v1-1-0818047d8a18@outlook.com>
X-B4-Tracking: v=1; b=H4sIAIBqMGgC/x3MQQ5AMBBA0avIrDUZZaRxFbGgBrOpakWI9O4ay
 7f4/4XIQThCV7wQ+JIou8uoygLsNrqVlczZoFETkq6V+IOwMsqGx5+7Qt3SZAw1E1rIkQ+8yP0
 P+yGlDy8IbJVgAAAA
X-Change-ID: 20250523-ipq5018-crypto-0265b8854b0c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748003464; l=1660;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=ineOdeuF7pypv/3WmasEmTw596e4Gn4lKAa9inTMryA=;
 b=NkSy9lIFJDZAYFs5H2LeInXpsalg4huxzmDYBVApJ6Qg0iSTNfZ6sHmmT6l6ct7LwsuC5DDuP
 9FQRgSDZfSNDwC+QOnfs5uB2/sNWO/xlUd4JQudZZAqqh+IMmc/b5+R
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IPQ5018 uses Qualcom QCE crypto engine v5.1 which is already supported.
So let's add the dts nodes for its DMA and QCE itself.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 30 ++++++++++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 130360014c5e14c778e348d37e601f60325b0b14..09ed9c34c1c6129174143ae770f8542dbf61128b 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -182,6 +182,36 @@ pcie0_phy: phy@86000 {
 			status = "disabled";
 		};
 
+		cryptobam: dma-controller@704000 {
+			compatible = "qcom,bam-v1.7.0";
+			reg = <0x00704000 0x20000>;
+			interrupts = <GIC_SPI 207 IRQ_TYPE_LEVEL_HIGH>;
+
+			clocks = <&gcc GCC_CRYPTO_AHB_CLK>;
+			clock-names = "bam_clk";
+
+			#dma-cells = <1>;
+			qcom,ee = <1>;
+			qcom,controlled-remotely;
+		};
+
+		crypto: crypto@73a000 {
+			compatible = "qcom,crypto-v5.1";
+			reg = <0x0073a000 0x6000>;
+
+			clocks = <&gcc GCC_CRYPTO_AHB_CLK>,
+				 <&gcc GCC_CRYPTO_AXI_CLK>,
+				 <&gcc GCC_CRYPTO_CLK>;
+			clock-names = "iface",
+				      "bus",
+				      "core";
+
+			dmas = <&cryptobam 2>,
+			       <&cryptobam 3>;
+			dma-names = "rx",
+				    "tx";
+		};
+
 		tlmm: pinctrl@1000000 {
 			compatible = "qcom,ipq5018-tlmm";
 			reg = <0x01000000 0x300000>;

---
base-commit: 176e917e010cb7dcc605f11d2bc33f304292482b
change-id: 20250523-ipq5018-crypto-0265b8854b0c

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

