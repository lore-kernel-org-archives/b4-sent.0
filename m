From: Maud Spierings <maudspierings@gocontroll.com>
Date: Fri, 22 Aug 2025 11:20:06 +0200
Subject: [PATCH 2/2] arm64: dts: freescale: imx8mp-moduline-display-106:
 Use phys to replace xceiver-supply
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250822-can_phy3-v1-2-73b3ba1690ee@gocontroll.com>
References: <20250822-can_phy3-v1-0-73b3ba1690ee@gocontroll.com>
In-Reply-To: <20250822-can_phy3-v1-0-73b3ba1690ee@gocontroll.com>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Aswath Govindraju <a-govindraju@ti.com>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: linux-can@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755854408; l=3211;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=3qC9ijohg7RvMYciIPYZcn8wTBRyjIFHSL6DEIr3OxU=;
 b=etRLer/PNIwaB1X431+vRlpBjcg9LUm8EiVCrz7CK1y4hesXitJfyrd9pcRa7f5lbqI0qYT+E
 c5x7VddteCgD6MmYywIbqzzkgLHv9mu28Lq9wywz0Jmsfk32wkWEmK9
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the can tranceivers to actually use the new phy description instead
of the regulator tweak.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 .../imx8mp-tx8p-ml81-moduline-display-106.dts      | 46 +++++++++++-----------
 1 file changed, 22 insertions(+), 24 deletions(-)

diff --git a/arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81-moduline-display-106.dts b/arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81-moduline-display-106.dts
index afd886dd590ff6f125d1d0e91aa71ae0063b5fd1..88ad422c27603b77c1099f2efe61953999c35f77 100644
--- a/arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81-moduline-display-106.dts
+++ b/arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81-moduline-display-106.dts
@@ -36,6 +36,24 @@ external-sensor-supply {
 		vout-supply = <&reg_5v0_sensor>;
 	};
 
+	flexcan1_phy: can-phy0 {
+		compatible = "ti,tcan1051", "ti,tcan1042";
+		#phy-cells = <0>;
+		pinctrl-0 = <&pinctrl_flexcan1_stby>;
+		pinctrl-names = "default";
+		max-bitrate = <5000000>;
+		standby-gpios = <&gpio4 3 GPIO_ACTIVE_HIGH>;
+	};
+
+	flexcan2_phy: can-phy1 {
+		compatible = "ti,tcan1051", "ti,tcan1042";
+		#phy-cells = <0>;
+		pinctrl-0 = <&pinctrl_flexcan2_stby>;
+		pinctrl-names = "default";
+		max-bitrate = <5000000>;
+		standby-gpios = <&gpio5 9 GPIO_ACTIVE_HIGH>;
+	};
+
 	reg_1v8_per: regulator-1v8-per {
 		compatible = "regulator-fixed";
 		pinctrl-0 = <&pinctrl_reg_1v8>;
@@ -85,26 +103,6 @@ reg_6v4: regulator-6v4 {
 		regulator-name = "6v4";
 	};
 
-	reg_can1_stby: regulator-can1-stby {
-		compatible = "regulator-fixed";
-		pinctrl-0 = <&pinctrl_flexcan1_reg>;
-		pinctrl-names = "default";
-		regulator-max-microvolt = <3300000>;
-		regulator-min-microvolt = <3300000>;
-		regulator-name = "can1-stby";
-		gpio = <&gpio4 3 GPIO_ACTIVE_LOW>;
-	};
-
-	reg_can2_stby: regulator-can2-stby {
-		compatible = "regulator-fixed";
-		pinctrl-0 = <&pinctrl_flexcan2_reg>;
-		pinctrl-names = "default";
-		regulator-max-microvolt = <3300000>;
-		regulator-min-microvolt = <3300000>;
-		regulator-name = "can2-stby";
-		gpio = <&gpio5 9 GPIO_ACTIVE_LOW>;
-	};
-
 	sound {
 		compatible = "simple-audio-card";
 		simple-audio-card,bitclock-master = <&cpudai>;
@@ -180,16 +178,16 @@ adc@2 {
 };
 
 &flexcan1 {
+	phys = <&flexcan1_phy>;
 	pinctrl-0 = <&pinctrl_flexcan1>;
 	pinctrl-names = "default";
-	xceiver-supply = <&reg_can1_stby>;
 	status = "okay";
 };
 
 &flexcan2 {
+	phys = <&flexcan2_phy>;
 	pinctrl-0 = <&pinctrl_flexcan2>;
 	pinctrl-names = "default";
-	xceiver-supply = <&reg_can2_stby>;
 	status = "okay";
 };
 
@@ -278,7 +276,7 @@ MX8MP_IOMUXC_SPDIF_TX__CAN1_TX
 		>;
 	};
 
-	pinctrl_flexcan1_reg: flexcan1reggrp {
+	pinctrl_flexcan1_stby: flexcan1stbygrp {
 		fsl,pins = <
 			MX8MP_IOMUXC_SAI1_RXD1__GPIO4_IO03
 				(MX8MP_DSE_X2 | MX8MP_FSEL_FAST | MX8MP_PULL_UP | MX8MP_PULL_ENABLE)
@@ -294,7 +292,7 @@ MX8MP_IOMUXC_UART3_RXD__CAN2_TX
 		>;
 	};
 
-	pinctrl_flexcan2_reg: flexcan2reggrp {
+	pinctrl_flexcan2_stby: flexcan2stbygrp {
 		fsl,pins = <
 			MX8MP_IOMUXC_ECSPI1_SS0__GPIO5_IO09
 				(MX8MP_DSE_X2 | MX8MP_FSEL_FAST | MX8MP_PULL_UP | MX8MP_PULL_ENABLE)

-- 
2.50.1

