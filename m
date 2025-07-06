From: Frank Li <Frank.Li@nxp.com>
Date: Sun, 06 Jul 2025 14:47:01 -0400
Subject: [PATCH 05/11] ARM: dts: lpc: add #address-cells and #size-cells
 for sram node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250706-lpc18xxx_dts-v1-5-7ae8cdfe8d7d@nxp.com>
References: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
In-Reply-To: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vladimir Zapolskiy <vz@mleia.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, vz@mleia.com, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751827628; l=2843;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=yvvtJHJXDcnE0guh0XGz0S0J+meX4MaeJw6QQIBdQLE=;
 b=ao040rLyQCrvsptZMb83xw9LeuTKXIy4k1TgT+im38fHu+on8uL8bCw8ocBn0S7ZliPdqArib
 VVGVrgH9vqdCho9A7QSObzsmEWMmF2jiU8ZSDi/TruSF4l4GF6zYW2D
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add #address-cells and #size-cells for sram node to fix below DTB_CHECK
warnings:
  arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dtb: sram@2,0 (mmio-sram): '#address-cells' is a required property

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
 arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts | 3 +++
 arch/arm/boot/dts/nxp/lpc/lpc4350.dtsi           | 9 +++++++++
 arch/arm/boot/dts/nxp/lpc/lpc4357.dtsi           | 9 +++++++++
 3 files changed, 21 insertions(+)

diff --git a/arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts b/arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts
index 8fc89fb6eef1e839ad256ae33942e607fed862c6..9d36283efe0f6ea26efedae9f7246c04f00cbdb7 100644
--- a/arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts
+++ b/arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts
@@ -406,6 +406,9 @@ cs2 {
 		ext_sram: sram@2,0 {
 			compatible = "mmio-sram";
 			reg = <2 0 0x80000>; /* 512 KiB SRAM on IS62WV25616 */
+			#address-cells = <1>;
+			#size-cells = <1>;
+			ranges = <0 2 0 0x80000>;
 		};
 	};
 };
diff --git a/arch/arm/boot/dts/nxp/lpc/lpc4350.dtsi b/arch/arm/boot/dts/nxp/lpc/lpc4350.dtsi
index c4422f5870556bd19272b976845cc2b7b5729911..707d22a219d8312381419dba952912b99e2400b2 100644
--- a/arch/arm/boot/dts/nxp/lpc/lpc4350.dtsi
+++ b/arch/arm/boot/dts/nxp/lpc/lpc4350.dtsi
@@ -24,16 +24,25 @@ soc {
 		sram0: sram@10000000 {
 			compatible = "mmio-sram";
 			reg = <0x10000000 0x20000>; /* 96 + 32 KiB local SRAM */
+			#address-cells = <1>;
+			#size-cells = <1>;
+			ranges;
 		};
 
 		sram1: sram@10080000 {
 			compatible = "mmio-sram";
 			reg = <0x10080000 0x12000>; /* 64 + 8 KiB local SRAM */
+			#address-cells = <1>;
+			#size-cells = <1>;
+			ranges;
 		};
 
 		sram2: sram@20000000 {
 			compatible = "mmio-sram";
 			reg = <0x20000000 0x10000>; /* 4 x 16 KiB AHB SRAM */
+			#address-cells = <1>;
+			#size-cells = <1>;
+			ranges;
 		};
 	};
 };
diff --git a/arch/arm/boot/dts/nxp/lpc/lpc4357.dtsi b/arch/arm/boot/dts/nxp/lpc/lpc4357.dtsi
index 72f12db8d53a7d5e8e297762e89e2c11967c26ab..d138ee7869ff3ad3255ebc454d9b7fbbbf3f495a 100644
--- a/arch/arm/boot/dts/nxp/lpc/lpc4357.dtsi
+++ b/arch/arm/boot/dts/nxp/lpc/lpc4357.dtsi
@@ -24,16 +24,25 @@ soc {
 		sram0: sram@10000000 {
 			compatible = "mmio-sram";
 			reg = <0x10000000 0x8000>; /* 32 KiB local SRAM */
+			#address-cells = <1>;
+			#size-cells = <1>;
+			ranges;
 		};
 
 		sram1: sram@10080000 {
 			compatible = "mmio-sram";
 			reg = <0x10080000 0xa000>; /* 32 + 8 KiB local SRAM */
+			#address-cells = <1>;
+			#size-cells = <1>;
+			ranges;
 		};
 
 		sram2: sram@20000000 {
 			compatible = "mmio-sram";
 			reg = <0x20000000 0x10000>; /* 4 x 16 KiB AHB SRAM */
+			#address-cells = <1>;
+			#size-cells = <1>;
+			ranges;
 		};
 	};
 };

-- 
2.34.1

