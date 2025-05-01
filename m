From: George Moussalem <george.moussalem@outlook.com>
Date: Thu, 01 May 2025 13:20:52 +0400
Subject: [PATCH 2/2] arm64: dts: qcom: ipq5018: Add SPI nand support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250501-ipq5018-spi-qpic-snand-v1-2-31e01fbb606f@outlook.com>
References: <20250501-ipq5018-spi-qpic-snand-v1-0-31e01fbb606f@outlook.com>
In-Reply-To: <20250501-ipq5018-spi-qpic-snand-v1-0-31e01fbb606f@outlook.com>
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, sadre Alam <quic_mdalam@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-spi@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746091263; l=1584;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=SBXgAzr3U3+TwfIxnK19bwzVraHDh3dGsR1Xo4qgNv0=;
 b=mOvM1N4u8d1/IEZw8j0dzk/IDbEQ63omKyGqY3Qw62xStrm5RIXFeKb/XZ1Abm9r71DWrnzgd
 ilacLtBDzj+ArC+MzCc7OEDVFwAz8XvCKtbJdMoVFFFvdLPczjca1hB
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add QPIC SPI NAND support for IPQ5018 SoC.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 38 +++++++++++++++++++++++++++++++++++
 1 file changed, 38 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 8914f2ef0bc47fda243b19174f77ce73fc10757d..b7454ed64474edb71c284bdb8e9f1e781b128437 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -238,6 +238,44 @@ blsp1_spi1: spi@78b5000 {
 			status = "disabled";
 		};
 
+		qpic_bam: dma-controller@7984000 {
+			compatible = "qcom,bam-v1.7.4", "qcom,bam-v1.7.0";
+			reg = <0x07984000 0x1c000>;
+
+			interrupts = <GIC_SPI 146 IRQ_TYPE_LEVEL_HIGH>;
+
+			clocks = <&gcc GCC_QPIC_AHB_CLK>;
+			clock-names = "bam_clk";
+
+			#dma-cells = <1>;
+			qcom,ee = <0>;
+
+			status = "disabled";
+		};
+
+		qpic_nand: spi@79b0000 {
+			compatible = "qcom,ipq5018-snand", "qcom,ipq9574-snand";
+			reg = <0x079b0000 0x10000>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+
+			clocks = <&gcc GCC_QPIC_CLK>,
+				 <&gcc GCC_QPIC_AHB_CLK>,
+				 <&gcc GCC_QPIC_IO_MACRO_CLK>;
+			clock-names = "core",
+				      "aon",
+				      "iom";
+
+			dmas = <&qpic_bam 0>,
+			       <&qpic_bam 1>,
+			       <&qpic_bam 2>;
+			dma-names = "tx",
+				    "rx",
+				    "cmd";
+
+			status = "disabled";
+		};
+
 		usb: usb@8af8800 {
 			compatible = "qcom,ipq5018-dwc3", "qcom,dwc3";
 			reg = <0x08af8800 0x400>;

-- 
2.49.0

