From: Frank Li <Frank.Li@nxp.com>
Date: Fri, 26 Sep 2025 14:19:43 -0400
Subject: [PATCH v4 4/4] arm64: dts: layerscape: add dma-coherent for usb
 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250926-ls_dma_coherence-v4-4-21e9c6bdb5cb@nxp.com>
References: <20250926-ls_dma_coherence-v4-0-21e9c6bdb5cb@nxp.com>
In-Reply-To: <20250926-ls_dma_coherence-v4-0-21e9c6bdb5cb@nxp.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, Shawn Guo <shawnguo@kernel.org>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 bjorn.andersson@oss.qualcomm.com, imx@lists.linux.dev, 
 Frank Li <Frank.Li@nxp.com>, Ze Huang <huang.ze@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758910787; l=8726;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=3lvyIi6EPuFI5jSKT6nJyBbhpNULKOOS4uIt6qtJysI=;
 b=leGYfUfAQDlehredD7ypAlfeodCvH+h1hzmW0R6jOyeA4ftCQip3BgvkhsWNIW0p6DCmMpb0u
 RzTx4OEwQqLBnUVKwzKc7g3Cwnz9IGxXL0CpM8q8RLyQduJD34Nh/Ox
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SOC special compatible string, remove fallback snps,dwc3 to let flatten
dwc3-layerscape driver to be probed and enable dma-coherence for usb node
since commit add layerscape dwc3 support, which set correct gsbustcfg0
value.

Add iommus property to run at old uboot, which use fixup add iommus by
check compatible string snsp,dwc3 compatible string.

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
change in v3 - v4
- none
---
 arch/arm64/boot/dts/freescale/fsl-ls1012a.dtsi | 3 ++-
 arch/arm64/boot/dts/freescale/fsl-ls1028a.dtsi | 8 ++++++--
 arch/arm64/boot/dts/freescale/fsl-ls1043a.dtsi | 9 ++++++---
 arch/arm64/boot/dts/freescale/fsl-ls1046a.dtsi | 9 ++++++---
 arch/arm64/boot/dts/freescale/fsl-ls1088a.dtsi | 8 ++++++--
 arch/arm64/boot/dts/freescale/fsl-lx2160a.dtsi | 8 ++++++--
 6 files changed, 32 insertions(+), 13 deletions(-)

diff --git a/arch/arm64/boot/dts/freescale/fsl-ls1012a.dtsi b/arch/arm64/boot/dts/freescale/fsl-ls1012a.dtsi
index fc3e138077b86cd5e3cf95c3d336cb3c6e1c45ef..ef80bf6a604f475c670e2d626a727e94fcb2a17a 100644
--- a/arch/arm64/boot/dts/freescale/fsl-ls1012a.dtsi
+++ b/arch/arm64/boot/dts/freescale/fsl-ls1012a.dtsi
@@ -493,10 +493,11 @@ QORIQ_CLK_PLL_DIV(4)>,
 		};
 
 		usb0: usb@2f00000 {
-			compatible = "snps,dwc3";
+			compatible = "fsl,ls1012a-dwc3", "fsl,ls1028a-dwc3";
 			reg = <0x0 0x2f00000 0x0 0x10000>;
 			interrupts = <GIC_SPI 60 IRQ_TYPE_LEVEL_HIGH>;
 			dr_mode = "host";
+			dma-coherent;
 			snps,quirk-frame-length-adjustment = <0x20>;
 			snps,dis_rxdet_inp3_quirk;
 			snps,incr-burst-type-adjustment = <1>, <4>, <8>, <16>;
diff --git a/arch/arm64/boot/dts/freescale/fsl-ls1028a.dtsi b/arch/arm64/boot/dts/freescale/fsl-ls1028a.dtsi
index 7d172d7e5737c4b6e42ee88676c5763fa7415260..e7f9c9319319a69d8c70d1e26446b899c3599f95 100644
--- a/arch/arm64/boot/dts/freescale/fsl-ls1028a.dtsi
+++ b/arch/arm64/boot/dts/freescale/fsl-ls1028a.dtsi
@@ -613,9 +613,11 @@ gpio3: gpio@2320000 {
 		};
 
 		usb0: usb@3100000 {
-			compatible = "fsl,ls1028a-dwc3", "snps,dwc3";
+			compatible = "fsl,ls1028a-dwc3";
 			reg = <0x0 0x3100000 0x0 0x10000>;
 			interrupts = <GIC_SPI 80 IRQ_TYPE_LEVEL_HIGH>;
+			iommus = <&smmu 1>;
+			dma-coherent;
 			snps,dis_rxdet_inp3_quirk;
 			snps,quirk-frame-length-adjustment = <0x20>;
 			snps,incr-burst-type-adjustment = <1>, <4>, <8>, <16>;
@@ -623,9 +625,11 @@ usb0: usb@3100000 {
 		};
 
 		usb1: usb@3110000 {
-			compatible = "fsl,ls1028a-dwc3", "snps,dwc3";
+			compatible = "fsl,ls1028a-dwc3";
 			reg = <0x0 0x3110000 0x0 0x10000>;
 			interrupts = <GIC_SPI 81 IRQ_TYPE_LEVEL_HIGH>;
+			iommus = <&smmu 2>;
+			dma-coherent;
 			snps,dis_rxdet_inp3_quirk;
 			snps,quirk-frame-length-adjustment = <0x20>;
 			snps,incr-burst-type-adjustment = <1>, <4>, <8>, <16>;
diff --git a/arch/arm64/boot/dts/freescale/fsl-ls1043a.dtsi b/arch/arm64/boot/dts/freescale/fsl-ls1043a.dtsi
index 73315c51703943d9ee5e1aa300c388ff6482423f..50d9b03a284a2aa4e13aa3323c25bbc5fe08f3d0 100644
--- a/arch/arm64/boot/dts/freescale/fsl-ls1043a.dtsi
+++ b/arch/arm64/boot/dts/freescale/fsl-ls1043a.dtsi
@@ -833,10 +833,11 @@ aux_bus: bus {
 			dma-ranges = <0x0 0x0 0x0 0x0 0x100 0x00000000>;
 
 			usb0: usb@2f00000 {
-				compatible = "snps,dwc3";
+				compatible = "fsl,ls1043a-dwc3", "fsl,ls1028a-dwc3";
 				reg = <0x0 0x2f00000 0x0 0x10000>;
 				interrupts = <GIC_SPI 60 IRQ_TYPE_LEVEL_HIGH>;
 				dr_mode = "host";
+				dma-coherent;
 				snps,quirk-frame-length-adjustment = <0x20>;
 				snps,dis_rxdet_inp3_quirk;
 				usb3-lpm-capable;
@@ -845,10 +846,11 @@ usb0: usb@2f00000 {
 			};
 
 			usb1: usb@3000000 {
-				compatible = "snps,dwc3";
+				compatible = "fsl,ls1043a-dwc3", "fsl,ls1028a-dwc3";
 				reg = <0x0 0x3000000 0x0 0x10000>;
 				interrupts = <GIC_SPI 61 IRQ_TYPE_LEVEL_HIGH>;
 				dr_mode = "host";
+				dma-coherent;
 				snps,quirk-frame-length-adjustment = <0x20>;
 				snps,dis_rxdet_inp3_quirk;
 				usb3-lpm-capable;
@@ -857,10 +859,11 @@ usb1: usb@3000000 {
 			};
 
 			usb2: usb@3100000 {
-				compatible = "snps,dwc3";
+				compatible = "fsl,ls1043a-dwc3", "fsl,ls1028a-dwc3";
 				reg = <0x0 0x3100000 0x0 0x10000>;
 				interrupts = <GIC_SPI 63 IRQ_TYPE_LEVEL_HIGH>;
 				dr_mode = "host";
+				dma-coherent;
 				snps,quirk-frame-length-adjustment = <0x20>;
 				snps,dis_rxdet_inp3_quirk;
 				usb3-lpm-capable;
diff --git a/arch/arm64/boot/dts/freescale/fsl-ls1046a.dtsi b/arch/arm64/boot/dts/freescale/fsl-ls1046a.dtsi
index 770d91ef0310d971d044a1f55cc5e2cb738acc47..22173d69713d1bd2abca986e76668ad437dd34e4 100644
--- a/arch/arm64/boot/dts/freescale/fsl-ls1046a.dtsi
+++ b/arch/arm64/boot/dts/freescale/fsl-ls1046a.dtsi
@@ -749,10 +749,11 @@ aux_bus: bus {
 			dma-ranges = <0x0 0x0 0x0 0x0 0x100 0x00000000>;
 
 			usb0: usb@2f00000 {
-				compatible = "snps,dwc3";
+				compatible = "fsl,ls1046a-dwc3", "fsl,ls1028a-dwc3";
 				reg = <0x0 0x2f00000 0x0 0x10000>;
 				interrupts = <GIC_SPI 60 IRQ_TYPE_LEVEL_HIGH>;
 				dr_mode = "host";
+				dma-coherent;
 				snps,quirk-frame-length-adjustment = <0x20>;
 				snps,dis_rxdet_inp3_quirk;
 				snps,incr-burst-type-adjustment = <1>, <4>, <8>, <16>;
@@ -760,10 +761,11 @@ usb0: usb@2f00000 {
 			};
 
 			usb1: usb@3000000 {
-				compatible = "snps,dwc3";
+				compatible = "fsl,ls1046a-dwc3", "fsl,ls1028a-dwc3";
 				reg = <0x0 0x3000000 0x0 0x10000>;
 				interrupts = <GIC_SPI 61 IRQ_TYPE_LEVEL_HIGH>;
 				dr_mode = "host";
+				dma-coherent;
 				snps,quirk-frame-length-adjustment = <0x20>;
 				snps,dis_rxdet_inp3_quirk;
 				snps,incr-burst-type-adjustment = <1>, <4>, <8>, <16>;
@@ -771,10 +773,11 @@ usb1: usb@3000000 {
 			};
 
 			usb2: usb@3100000 {
-				compatible = "snps,dwc3";
+				compatible = "fsl,ls1046a-dwc3", "fsl,ls1028a-dwc3";
 				reg = <0x0 0x3100000 0x0 0x10000>;
 				interrupts = <GIC_SPI 63 IRQ_TYPE_LEVEL_HIGH>;
 				dr_mode = "host";
+				dma-coherent;
 				snps,quirk-frame-length-adjustment = <0x20>;
 				snps,dis_rxdet_inp3_quirk;
 				snps,incr-burst-type-adjustment = <1>, <4>, <8>, <16>;
diff --git a/arch/arm64/boot/dts/freescale/fsl-ls1088a.dtsi b/arch/arm64/boot/dts/freescale/fsl-ls1088a.dtsi
index 9d5726378aa015eff10578bf095908a58b9d9eee..b2f6cd237be046123de9342e2167aa32248a8a16 100644
--- a/arch/arm64/boot/dts/freescale/fsl-ls1088a.dtsi
+++ b/arch/arm64/boot/dts/freescale/fsl-ls1088a.dtsi
@@ -489,10 +489,12 @@ esdhc: mmc@2140000 {
 		};
 
 		usb0: usb@3100000 {
-			compatible = "snps,dwc3";
+			compatible = "fsl,ls1088a-dwc3", "fsl,ls1028a-dwc3";
 			reg = <0x0 0x3100000 0x0 0x10000>;
 			interrupts = <GIC_SPI 80 IRQ_TYPE_LEVEL_HIGH>;
 			dr_mode = "host";
+			iommus = <&smmu 1>;
+			dma-coherent;
 			snps,quirk-frame-length-adjustment = <0x20>;
 			snps,dis_rxdet_inp3_quirk;
 			snps,incr-burst-type-adjustment = <1>, <4>, <8>, <16>;
@@ -500,10 +502,12 @@ usb0: usb@3100000 {
 		};
 
 		usb1: usb@3110000 {
-			compatible = "snps,dwc3";
+			compatible = "fsl,ls1088a-dwc3", "fsl,ls1028a-dwc3";
 			reg = <0x0 0x3110000 0x0 0x10000>;
 			interrupts = <GIC_SPI 81 IRQ_TYPE_LEVEL_HIGH>;
 			dr_mode = "host";
+			iommus = <&smmu 2>;
+			dma-coherent;
 			snps,quirk-frame-length-adjustment = <0x20>;
 			snps,dis_rxdet_inp3_quirk;
 			snps,incr-burst-type-adjustment = <1>, <4>, <8>, <16>;
diff --git a/arch/arm64/boot/dts/freescale/fsl-lx2160a.dtsi b/arch/arm64/boot/dts/freescale/fsl-lx2160a.dtsi
index c9541403bcd8239a48d4ef79c7c4f9e3b607b556..d899c0355e51dd457a4e7259709cea98a488f557 100644
--- a/arch/arm64/boot/dts/freescale/fsl-lx2160a.dtsi
+++ b/arch/arm64/boot/dts/freescale/fsl-lx2160a.dtsi
@@ -1094,24 +1094,28 @@ ftm_alarm0: rtc@2800000 {
 		};
 
 		usb0: usb@3100000 {
-			compatible = "snps,dwc3";
+			compatible = "fsl,lx2160a-dwc3", "fsl,ls1028a-dwc3";
 			reg = <0x0 0x3100000 0x0 0x10000>;
 			interrupts = <GIC_SPI 80 IRQ_TYPE_LEVEL_HIGH>;
 			dr_mode = "host";
 			snps,quirk-frame-length-adjustment = <0x20>;
 			usb3-lpm-capable;
+			iommus = <&smmu 1>;
+			dma-coherent;
 			snps,dis_rxdet_inp3_quirk;
 			snps,incr-burst-type-adjustment = <1>, <4>, <8>, <16>;
 			status = "disabled";
 		};
 
 		usb1: usb@3110000 {
-			compatible = "snps,dwc3";
+			compatible = "fsl,lx2160a-dwc3", "fsl,ls1028a-dwc3";
 			reg = <0x0 0x3110000 0x0 0x10000>;
 			interrupts = <GIC_SPI 81 IRQ_TYPE_LEVEL_HIGH>;
 			dr_mode = "host";
 			snps,quirk-frame-length-adjustment = <0x20>;
 			usb3-lpm-capable;
+			iommus = <&smmu 2>;
+			dma-coherent;
 			snps,dis_rxdet_inp3_quirk;
 			snps,incr-burst-type-adjustment = <1>, <4>, <8>, <16>;
 			status = "disabled";

-- 
2.34.1

