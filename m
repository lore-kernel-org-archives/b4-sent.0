From: George Chan <gchan9527@gmail.com>
Date: Tue, 15 Oct 2024 20:53:31 +0800
Subject: [PATCH RFC/RFT 3/3] dts: sm7125-xiaomi-joyeuse: Sample device tree
 for reference
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241015-nt36xxx-v1-3-3919d0bffee6@gmail.com>
References: <20241015-nt36xxx-v1-0-3919d0bffee6@gmail.com>
In-Reply-To: <20241015-nt36xxx-v1-0-3919d0bffee6@gmail.com>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Del Regno <kholk11@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728996810; l=6157;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=tWQZcmPANb4gyYg3Iy7tm37YDTp8/euoXHalxbM18xI=;
 b=LpMt6KwLQJJNw2ApXjiVTFev3urGDEjLrV4ifAm4rghDhKju/6l5pSvCF1By3ymwJAdwDXGAl
 4I6CBpnVE/IACDBLermLo56NxcrYbTBr/dDOEjn2heqvCAV/cAjwTXP
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Provide a include-made-easy devicetree file for demo.
This sample file aimed including novatek touch support.

Reviewers please ignore this patch.

The full device tree is at below:
https://github.com/99degree/linux/tree/working-20241015/arch/arm64/boot/dts/qcom

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 arch/arm64/boot/dts/qcom/Makefile                  |   1 +
 .../boot/dts/qcom/sm7125-xiaomi-joyeuse-touch.dts  | 183 +++++++++++++++++++++
 2 files changed, 184 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/Makefile b/arch/arm64/boot/dts/qcom/Makefile
index aea1d69db5..ba9786555b 100644
--- a/arch/arm64/boot/dts/qcom/Makefile
+++ b/arch/arm64/boot/dts/qcom/Makefile
@@ -235,6 +235,7 @@ dtb-$(CONFIG_ARCH_QCOM)	+= sm6350-sony-xperia-lena-pdx213.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= sm6375-sony-xperia-murray-pdx225.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= sm7125-xiaomi-curtana.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= sm7125-xiaomi-joyeuse.dtb
+dtb-$(CONFIG_ARCH_QCOM)	+= sm7125-xiaomi-joyeuse-touch.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= sm7225-fairphone-fp4.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= sm8150-hdk.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= sm8150-microsoft-surface-duo.dtb
diff --git a/arch/arm64/boot/dts/qcom/sm7125-xiaomi-joyeuse-touch.dts b/arch/arm64/boot/dts/qcom/sm7125-xiaomi-joyeuse-touch.dts
new file mode 100644
index 0000000000..4a43db701d
--- /dev/null
+++ b/arch/arm64/boot/dts/qcom/sm7125-xiaomi-joyeuse-touch.dts
@@ -0,0 +1,183 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
+
+#ifndef SM7125_XIAOMI_JOYEUSE_TOUCH_DTS
+#define SM7125_XIAOMI_JOYEUSE_TOUCH_DTS
+
+#include <dt-bindings/dma/qcom-gpi.h>
+#include <dt-bindings/gpio/gpio.h>
+
+#include "sm7125-xiaomi-joyeuse-display.dts"
+
+&soc {
+	gpi_dma0: dma-controller@800000  {
+		compatible = "qcom,sm7125-gpi-dma", "qcom,sm6350-gpi-dma";
+		reg = <0 0x00800000 0 0x60000>;
+		interrupts = <GIC_SPI 244 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 245 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 246 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 247 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 248 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 249 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 250 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 251 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 252 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 253 IRQ_TYPE_LEVEL_HIGH>;
+		dma-channels = <10>;
+		dma-channel-mask = <0x1f>;
+		iommus = <&apps_smmu 0x56 0x0>;
+		#dma-cells = <3>;
+		
+		status = "disabled";
+	};
+
+	gpi_dma1: dma-controller@a00000 {
+		compatible = "qcom,sm7125-gpi-dma", "qcom,sm6350-gpi-dma";
+		reg = <0 0x00a00000 0 0x60000>;
+		interrupts = <GIC_SPI 645 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 646 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 647 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 648 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 649 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 650 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 651 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 652 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 653 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 654 IRQ_TYPE_LEVEL_HIGH>;
+		dma-channels = <10>;
+		dma-channel-mask = <0x3f>;
+		iommus = <&apps_smmu 0x4d6 0x0>;
+		#dma-cells = <3>;
+		
+		status = "disabled";
+	};
+};
+
+//spi@880000
+&spi0 {
+	dmas = <&gpi_dma0 0 0 QCOM_GPI_SPI>,
+		<&gpi_dma0 1 0 QCOM_GPI_SPI>;
+	dma-names = "tx", "rx";
+};
+
+//spi@884000
+&spi1 {
+	dmas = <&gpi_dma0 0 1 QCOM_GPI_SPI>,
+		<&gpi_dma0 1 1 QCOM_GPI_SPI>;
+	dma-names = "tx", "rx";
+};
+//spi@88c000
+&spi3 {
+	dmas = <&gpi_dma0 0 3 QCOM_GPI_SPI>,
+		<&gpi_dma0 1 3 QCOM_GPI_SPI>;
+	dma-names = "tx", "rx";
+};
+
+//spi@88c000
+&spi3 {
+	dmas = <&gpi_dma0 0 3 QCOM_GPI_SPI>,
+		<&gpi_dma0 1 3 QCOM_GPI_SPI>;
+	dma-names = "tx", "rx";
+};
+
+//spi@894000
+&spi5 {
+        dmas = <&gpi_dma0 0 5 QCOM_GPI_SPI>,
+                <&gpi_dma0 1 5 QCOM_GPI_SPI>;
+        dma-names = "tx", "rx";
+};
+
+//spi@a80000
+&spi6 {
+	dmas = <&gpi_dma1 0 0 QCOM_GPI_SPI>,
+		<&gpi_dma1 1 0 QCOM_GPI_SPI>;
+	dma-names = "tx", "rx";
+};
+
+//spi@a88000
+&spi8 {
+	dmas = <&gpi_dma1 0 2 QCOM_GPI_SPI>,
+		<&gpi_dma1 1 2 QCOM_GPI_SPI>;
+	dma-names = "tx", "rx";
+};
+
+//spi@a90000
+&spi10 {
+	dma-names = "tx", "rx";
+        dmas = <&gpi_dma1 0 4 QCOM_GPI_SPI>,
+                <&gpi_dma1 1 4 QCOM_GPI_SPI>;
+};
+
+//spi@a94000
+&spi11 {
+	dma-names = "tx", "rx";
+	dmas = <&gpi_dma1 0 5 QCOM_GPI_SPI>,
+		<&gpi_dma1 1 5 QCOM_GPI_SPI>;
+};
+
+&spi11 {
+        status = "okay";
+
+        touchscreen: touchscreen@0 {
+                compatible = "novatek,nt36675-spi",
+				"novatek,nt36xxx-spi",
+				"novatek,NVT-ts-spi";
+			
+                reg = <0>;
+
+                /* caught from joyeuse dtb*/
+                spi-max-frequency = <4000000>;
+
+                /* ts->irq report 194 */
+                /* interrupts = <&tlmm 194 IRQ_TYPE_EDGE_FALLING>; */
+                /* interrupt= <&tlmm 13 2>; */ //dtb specified, but GPIO13 is CAM_MCLK0
+
+                novatek,reset-gpio = <&tlmm 8 0x00>;
+                novatek,irq-gpio = <&tlmm 9 0x2001>;
+
+                /* 672C */
+                novatek,swrst-n8-addr = <0x03F0FE>;
+                novatek,spi-rd-fast-addr = <0x03F310>;
+
+                reset-gpio = <&tlmm 8 0x00>;
+                /* dtb show <&tlmm 13 2>*/
+                irq-gpio = <&tlmm 9 0x2001>;
+
+/*
+                touch_ibb-supply = <0x241>; //lcdb_ncp
+                touch_lab-supply = <0x240>; //qcom,qpnp-lcdb-regulator ldo
+                touch_vddio-supply = <0x33c>; //pm6150_l18
+*/
+
+                vio-supply = <&vreg_l18a_3p0>;
+                vdd-supply = <&vreg_l18a_3p0>;
+
+                panel = <&panel0>;
+                status = "okay";
+        };
+};
+
+
+&qup_spi11_spi {
+        drive-strength = <2>;
+        //bias-disable;
+};
+
+&qup_spi11_cs {
+        drive-strength = <2>;
+        //bias-disable;
+};
+
+&qup_spi11_cs_gpio {
+        drive-strength = <2>;
+        bias-disable;
+};
+
+&gpi_dma0 {
+	status = "okay";
+};
+
+&gpi_dma1 {
+        status = "okay";
+};
+
+#endif

-- 
2.43.0

