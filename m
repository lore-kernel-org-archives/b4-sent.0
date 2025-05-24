From: George Moussalem <george.moussalem@outlook.com>
Date: Sat, 24 May 2025 16:31:31 +0400
Subject: [PATCH v2] arm64: dts: qcom: ipq5018: Add crypto nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250524-ipq5018-crypto-v2-1-faa26aedc4cf@outlook.com>
X-B4-Tracking: v=1; b=H4sIACK8MWgC/3XMQQ6CMBCF4auQWVszrVQnrriHYQGlykRlaotEQ
 ri7lb3L/yXvWyD5yD7BuVgg+okTy5DD7ApwfTPcvOIuNxg0Fq05KA4vi5qUi3MYRaE52pbIli0
 6yKcQ/ZU/G3ipc/ecRonz5k/6t/6lJq20QtKE5amjRlMl7/Ehct87eUK9rusXPKCAw64AAAA=
X-Change-ID: 20250523-ipq5018-crypto-0265b8854b0c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748089894; l=1977;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=jiSu2brkAB+drch8iI9SatYPuZQZCSdgzO/6G8YlqTo=;
 b=gsBBt/IwZPLredb8H5qjyhqegJwbNZiUPk6cHuz0sEvD1lHRY0C2dCa1nG5sXkLG2XQt01bAy
 vf2HK3DM9E5D7Ke2mSZxzQak3OxUqp2t2cKZ5d+mpe6o7swsdzmQ4pg
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IPQ5018 uses Qualcomm QCE crypto engine v5.1 which is already supported.
So let's add the dts nodes for its DMA v1.7.4 and QCE itself.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
Changes in v2:
- As per Konrad's comment, the BAM DMA controller is v1.7.4, so updated
  the dma controller node accordingly.
- Link to v1: https://lore.kernel.org/r/20250523-ipq5018-crypto-v1-1-0818047d8a18@outlook.com
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 30 ++++++++++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 130360014c5e14c778e348d37e601f60325b0b14..558a97a050c6b87ffa9ab45e80ede18c1eaffcc2 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -182,6 +182,36 @@ pcie0_phy: phy@86000 {
 			status = "disabled";
 		};
 
+		cryptobam: dma-controller@704000 {
+			compatible = "qcom,bam-v1.7.4", "qcom,bam-v1.7.0";
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

