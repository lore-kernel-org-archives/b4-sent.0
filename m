From: Frank Li <Frank.Li@nxp.com>
Date: Sun, 06 Jul 2025 14:47:02 -0400
Subject: [PATCH 06/11] ARM: dts: lpc: add cfg surfix in pinctrl child node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250706-lpc18xxx_dts-v1-6-7ae8cdfe8d7d@nxp.com>
References: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
In-Reply-To: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vladimir Zapolskiy <vz@mleia.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, vz@mleia.com, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751827628; l=2395;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=C46qx9YdKR7+A8ab/w/tK7krHL9bwS57NbQPc2tNY80=;
 b=mONXrEurSKEf03/G3au1NNn/+xNJ+nsG8ew8/egbYiET3eBCC0K+YSx5zLKNvFL/0fKBlnvlX
 LRSdFVwJ1zxB0oOaNEs1069aCBI2DFTNS9nze09PLJ3zm98zs36rV1C
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add cfg surfix in pinctrl child node to fix below CHECK_DTB warning:
arch/arm/boot/dts/nxp/lpc/lpc4337-ciaa.dtb: pinctrl@40086000 (nxp,lpc1850-scu): ssp-pins: 'ssp1_cs', 'ssp1_miso_mosi', 'ssp1_sck' do not match any of the regexes: '^pinctrl-[0-9]+$', '_cfg$'
        from schema $id: http://devicetree.org/schemas/pinctrl/nxp,lpc1850-scu.yaml#

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
 arch/arm/boot/dts/nxp/lpc/lpc4337-ciaa.dts          | 6 +++---
 arch/arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dts | 8 ++++----
 2 files changed, 7 insertions(+), 7 deletions(-)

diff --git a/arch/arm/boot/dts/nxp/lpc/lpc4337-ciaa.dts b/arch/arm/boot/dts/nxp/lpc/lpc4337-ciaa.dts
index beddaba85393e61a07da5175fa9e7fb081bbac3f..5ff43c825944dcfa523e8be2fdf49f1ad8e0a884 100644
--- a/arch/arm/boot/dts/nxp/lpc/lpc4337-ciaa.dts
+++ b/arch/arm/boot/dts/nxp/lpc/lpc4337-ciaa.dts
@@ -108,14 +108,14 @@ i2c0_pins_cfg {
 	};
 
 	ssp_pins: ssp-pins {
-		ssp1_cs {
+		ssp1_cs_cfg {
 			pins = "p6_7";
 			function = "gpio";
 			bias-pull-up;
 			bias-disable;
 		};
 
-		ssp1_miso_mosi {
+		ssp1_miso_mosi_cfg {
 			pins = "p1_3", "p1_4";
 			function = "ssp1";
 			slew-rate = <1>;
@@ -124,7 +124,7 @@ ssp1_miso_mosi {
 			input-schmitt-disable;
 		};
 
-		ssp1_sck {
+		ssp1_sck_cfg {
 			pins = "pf_4";
 			function = "ssp1";
 			slew-rate = <1>;
diff --git a/arch/arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dts b/arch/arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dts
index 60bcfa5e0518e55eb3e642f146d1c96f2ebd5267..9dc8c3cc2211001f30a5a15c3a04a240e4acd86b 100644
--- a/arch/arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dts
+++ b/arch/arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dts
@@ -403,7 +403,7 @@ spifi_cs_cfg {
 	};
 
 	ssp0_pins: ssp0-pins {
-		ssp0_sck_miso_mosi {
+		ssp0_sck_miso_mosi_cfg {
 			pins = "pf_0", "pf_2", "pf_3";
 			function = "ssp0";
 			slew-rate = <1>;
@@ -412,7 +412,7 @@ ssp0_sck_miso_mosi {
 			input-schmitt-disable;
 		};
 
-		ssp0_ssel {
+		ssp0_ssel_cfg {
 			pins = "pf_1";
 			function = "ssp0";
 			bias-pull-up;
@@ -452,12 +452,12 @@ uart3_tx_cfg {
 	};
 
 	usb0_pins: usb0-pins {
-		usb0_pwr_enable {
+		usb0_pwr_enable_cfg {
 			pins = "p2_3";
 			function = "usb0";
 		};
 
-		usb0_pwr_fault {
+		usb0_pwr_fault_cfg {
 			pins = "p8_0";
 			function = "usb0";
 			bias-disable;

-- 
2.34.1

