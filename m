From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Mon, 06 Oct 2025 18:31:28 +0200
Subject: [PATCH] arm64: dts: freescale: Add GMAC Ethernet for S32G2 EVB and
 RDB2 and S32G3 RDB3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251006-nxp-s32g-boards-v1-1-f70a57b8087f@oss.nxp.com>
X-B4-Tracking: v=1; b=H4sIAN/u42gC/x3MMQqAMAxA0atIZgNtJIJeRRysjTVLlQZEEO9uc
 XzD/w+YFBWDsXmgyKWmR67wbQPrvuQkqLEayBF753rM94nWUcJwLCUaUvTcE3PggaBWZ5FN7/8
 4ze/7AaoG5dxhAAAA
To: Chester Lin <chester62515@gmail.com>, 
 Matthias Brugger <mbrugger@suse.com>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>, 
 NXP S32 Linux Team <s32@nxp.com>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Richard Cochran <richardcochran@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, imx@lists.linux.dev, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org, "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759768312; l=7038;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=TMWFQ/FCO7r1LG54aYnEDegZ7oUI5MIx6sPdhGBxOcA=;
 b=BYkrZtIcJy8FigoNiS7KdvSacfpqLvQ8+glEubaeNymGK1JA+8tu/tR1m9gshcgR22HkuQ5Mw
 Cmy9eQyLBqgD4z5OxjWHaoTIiGXyJAXPiv+S2FEYTssNJq0IC465zL+
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the Ethernet connection over GMAC controller connected to
the Micrel KSZ9031 Ethernet RGMII PHY located on the boards.

The mentioned GMAC controller is one of two network controllers
embedded on the NXP Automotive SoCs S32G2 and S32G3.

The supported boards:
 * EVB:  S32G-VNP-EVB with S32G2 SoC
 * RDB2: S32G-VNP-RDB2
 * RDB3: S32G-VNP-RDB3

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 arch/arm64/boot/dts/freescale/s32g2.dtsi        | 50 ++++++++++++++++++++++++-
 arch/arm64/boot/dts/freescale/s32g274a-evb.dts  | 21 ++++++++++-
 arch/arm64/boot/dts/freescale/s32g274a-rdb2.dts | 19 ++++++++++
 arch/arm64/boot/dts/freescale/s32g3.dtsi        | 50 ++++++++++++++++++++++++-
 arch/arm64/boot/dts/freescale/s32g399a-rdb3.dts | 21 ++++++++++-
 5 files changed, 157 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/freescale/s32g2.dtsi b/arch/arm64/boot/dts/freescale/s32g2.dtsi
index d167624d1f0c..d06103e9564e 100644
--- a/arch/arm64/boot/dts/freescale/s32g2.dtsi
+++ b/arch/arm64/boot/dts/freescale/s32g2.dtsi
@@ -3,7 +3,7 @@
  * NXP S32G2 SoC family
  *
  * Copyright (c) 2021 SUSE LLC
- * Copyright 2017-2021, 2024 NXP
+ * Copyright 2017-2021, 2024-2025 NXP
  */
 
 #include <dt-bindings/interrupt-controller/arm-gic.h>
@@ -738,5 +738,53 @@ gic: interrupt-controller@50800000 {
 			interrupt-controller;
 			#interrupt-cells = <3>;
 		};
+
+		gmac0: ethernet@4033c000 {
+			compatible = "nxp,s32g2-dwmac";
+			reg = <0x4033c000 0x2000>, /* gmac IP */
+			      <0x4007c004 0x4>;    /* GMAC_0_CTRL_STS */
+			interrupt-parent = <&gic>;
+			interrupts = <GIC_SPI 57 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "macirq";
+			snps,mtl-rx-config = <&mtl_rx_setup>;
+			snps,mtl-tx-config = <&mtl_tx_setup>;
+			status = "disabled";
+
+			mtl_rx_setup: rx-queues-config {
+				snps,rx-queues-to-use = <5>;
+
+				queue0 {
+				};
+				queue1 {
+				};
+				queue2 {
+				};
+				queue3 {
+				};
+				queue4 {
+				};
+			};
+
+			mtl_tx_setup: tx-queues-config {
+				snps,tx-queues-to-use = <5>;
+
+				queue0 {
+				};
+				queue1 {
+				};
+				queue2 {
+				};
+				queue3 {
+				};
+				queue4 {
+				};
+			};
+
+			gmac0mdio: mdio {
+				#address-cells = <1>;
+				#size-cells = <0>;
+				compatible = "snps,dwmac-mdio";
+			};
+		};
 	};
 };
diff --git a/arch/arm64/boot/dts/freescale/s32g274a-evb.dts b/arch/arm64/boot/dts/freescale/s32g274a-evb.dts
index c4a195dd67bf..f020da03979a 100644
--- a/arch/arm64/boot/dts/freescale/s32g274a-evb.dts
+++ b/arch/arm64/boot/dts/freescale/s32g274a-evb.dts
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: GPL-2.0-or-later OR MIT
 /*
  * Copyright (c) 2021 SUSE LLC
- * Copyright 2019-2021, 2024 NXP
+ * Copyright 2019-2021, 2024-2025 NXP
  */
 
 /dts-v1/;
@@ -15,6 +15,7 @@ / {
 
 	aliases {
 		serial0 = &uart0;
+		ethernet0 = &gmac0;
 	};
 
 	chosen {
@@ -43,3 +44,21 @@ &usdhc0 {
 	no-1-8-v;
 	status = "okay";
 };
+
+&gmac0 {
+	clocks = <&clks 24>, <&clks 19>, <&clks 18>, <&clks 15>;
+	clock-names = "stmmaceth", "tx", "rx", "ptp_ref";
+	phy-mode = "rgmii-id";
+	phy-handle = <&rgmiiaphy4>;
+	status = "okay";
+};
+
+&gmac0mdio {
+	#address-cells = <1>;
+	#size-cells = <0>;
+
+	/* KSZ 9031 on RGMII */
+	rgmiiaphy4: ethernet-phy@4 {
+		reg = <4>;
+	};
+};
diff --git a/arch/arm64/boot/dts/freescale/s32g274a-rdb2.dts b/arch/arm64/boot/dts/freescale/s32g274a-rdb2.dts
index 4f58be68c818..b9c2f964b3f7 100644
--- a/arch/arm64/boot/dts/freescale/s32g274a-rdb2.dts
+++ b/arch/arm64/boot/dts/freescale/s32g274a-rdb2.dts
@@ -16,6 +16,7 @@ / {
 	aliases {
 		serial0 = &uart0;
 		serial1 = &uart1;
+		ethernet0 = &gmac0;
 	};
 
 	chosen {
@@ -77,3 +78,21 @@ &usdhc0 {
 	no-1-8-v;
 	status = "okay";
 };
+
+&gmac0 {
+	clocks = <&clks 24>, <&clks 19>, <&clks 18>, <&clks 15>;
+	clock-names = "stmmaceth", "tx", "rx", "ptp_ref";
+	phy-mode = "rgmii-id";
+	phy-handle = <&rgmiiaphy1>;
+	status = "okay";
+};
+
+&gmac0mdio {
+	#address-cells = <1>;
+	#size-cells = <0>;
+
+	/* KSZ 9031 on RGMII */
+	rgmiiaphy1: ethernet-phy@1 {
+		reg = <1>;
+	};
+};
diff --git a/arch/arm64/boot/dts/freescale/s32g3.dtsi b/arch/arm64/boot/dts/freescale/s32g3.dtsi
index be3a582ebc1b..e31184847371 100644
--- a/arch/arm64/boot/dts/freescale/s32g3.dtsi
+++ b/arch/arm64/boot/dts/freescale/s32g3.dtsi
@@ -1,6 +1,6 @@
 // SPDX-License-Identifier: (GPL-2.0+ OR BSD-3-Clause)
 /*
- * Copyright 2021-2024 NXP
+ * Copyright 2021-2025 NXP
  *
  * Authors: Ghennadi Procopciuc <ghennadi.procopciuc@nxp.com>
  *          Ciprian Costea <ciprianmarian.costea@nxp.com>
@@ -883,6 +883,54 @@ gic: interrupt-controller@50800000 {
 			      <0x50420000 0x2000>;
 			interrupts = <GIC_PPI 9 IRQ_TYPE_LEVEL_HIGH>;
 		};
+
+		gmac0: ethernet@4033c000 {
+			compatible = "nxp,s32g2-dwmac";
+			reg = <0x4033c000 0x2000>, /* gmac IP */
+			      <0x4007c004 0x4>;    /* GMAC_0_CTRL_STS */
+			interrupt-parent = <&gic>;
+			interrupts = <GIC_SPI 57 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "macirq";
+			snps,mtl-rx-config = <&mtl_rx_setup>;
+			snps,mtl-tx-config = <&mtl_tx_setup>;
+			status = "disabled";
+
+			mtl_rx_setup: rx-queues-config {
+				snps,rx-queues-to-use = <5>;
+
+				queue0 {
+				};
+				queue1 {
+				};
+				queue2 {
+				};
+				queue3 {
+				};
+				queue4 {
+				};
+			};
+
+			mtl_tx_setup: tx-queues-config {
+				snps,tx-queues-to-use = <5>;
+
+				queue0 {
+				};
+				queue1 {
+				};
+				queue2 {
+				};
+				queue3 {
+				};
+				queue4 {
+				};
+			};
+
+			gmac0mdio: mdio {
+				#address-cells = <1>;
+				#size-cells = <0>;
+				compatible = "snps,dwmac-mdio";
+			};
+		};
 	};
 
 	timer {
diff --git a/arch/arm64/boot/dts/freescale/s32g399a-rdb3.dts b/arch/arm64/boot/dts/freescale/s32g399a-rdb3.dts
index e94f70ad82d9..4a74923789ae 100644
--- a/arch/arm64/boot/dts/freescale/s32g399a-rdb3.dts
+++ b/arch/arm64/boot/dts/freescale/s32g399a-rdb3.dts
@@ -1,6 +1,6 @@
 // SPDX-License-Identifier: (GPL-2.0+ OR BSD-3-Clause)
 /*
- * Copyright 2021-2024 NXP
+ * Copyright 2021-2025 NXP
  *
  * NXP S32G3 Reference Design Board 3 (S32G-VNP-RDB3)
  */
@@ -18,6 +18,7 @@ aliases {
 		mmc0 = &usdhc0;
 		serial0 = &uart0;
 		serial1 = &uart1;
+		ethernet0 = &gmac0;
 	};
 
 	chosen {
@@ -93,3 +94,21 @@ &usdhc0 {
 	disable-wp;
 	status = "okay";
 };
+
+&gmac0 {
+	clocks = <&clks 24>, <&clks 19>, <&clks 18>, <&clks 15>;
+	clock-names = "stmmaceth", "tx", "rx", "ptp_ref";
+	phy-mode = "rgmii-id";
+	phy-handle = <&rgmiiaphy1>;
+	status = "okay";
+};
+
+&gmac0mdio {
+	#address-cells = <1>;
+	#size-cells = <0>;
+
+	/* KSZ 9031 on RGMII */
+	rgmiiaphy1: ethernet-phy@1 {
+		reg = <1>;
+	};
+};

---
base-commit: fd94619c43360eb44d28bd3ef326a4f85c600a07
change-id: 20251006-nxp-s32g-boards-2d156255b592

Best regards,
-- 
Jan Petrous (OSS) <jan.petrous@oss.nxp.com>

