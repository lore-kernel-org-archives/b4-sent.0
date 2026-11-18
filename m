From: =?utf-8?q?Alexandra_=C3=98stermark?= <alex.cramt@gmail.com>
Date: Wed, 18 Nov 2026 20:07:15 +0100
Subject: [PATCH 3/3] arm64: dts: socfpga: agilex5: add support for Terasic
 DE25-Nano
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261118-de25-nano-v1-3-473d16131f7a@gmail.com>
References: <20261118-de25-nano-v1-0-473d16131f7a@gmail.com>
In-Reply-To: <20261118-de25-nano-v1-0-473d16131f7a@gmail.com>
To: Dinh Nguyen <dinguyen@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Mahesh Rao <mahesh.rao@altera.com>, 
 Mohamad Asyraaf Azhar <mohamad.asyraaf.azhar@altera.com>, 
 =?utf-8?q?Alexandra_=C3=98stermark?= <alex.cramt@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795028833; l=3047;
 i=alex.cramt@gmail.com; s=20261118; h=from:subject:message-id;
 bh=NLTSseE90KgBZKd0dpEYRE0San+zR5ClCX05UXrqrLs=;
 b=DXrw8E5bWhUbGJAdeKAqWl1QOrVUyHuRRBfbjJGYN1ZHku7iTREUODI3fWrZ0Ica8Ilmd9Bmz
 0NSSSTszQoYBopln422YUNzyLpbf3brULRptbgrPkU2tOaOwFMskbGF
X-Developer-Key: i=alex.cramt@gmail.com; a=ed25519;
 pk=vQBaXUvFG7cCIaWDKclPMjo3b4XfPEVkuPjaWCkYddc=
X-Endpoint-Received: by B4 Relay for alex.cramt@gmail.com/20261118 with auth_id=1561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DE25-Nano is an Agilex 5 SoC FPGA board with gigabit Ethernet, a
microSD slot wired for 3.3 V only, USB and one HPS LED.

Based on Terasic's and Altera's vendor device trees for the board, which
describe the SD slot on an SDHCI node that upstream doesn't have; this
uses the upstream SD6HC sdmmc node instead.

Boot from microSD, gigabit Ethernet, USB, the LED and the watchdog were
tested on the board. The QSPI flash, the I2C buses and the SDM hardware
monitor are left out until they have been tested.

Signed-off-by: Alexandra Østermark <alex.cramt@gmail.com>
---
 arch/arm64/boot/dts/altera/Makefile                |  1 +
 .../boot/dts/altera/socfpga_agilex5_de25_nano.dts  | 91 ++++++++++++++++++++++
 2 files changed, 92 insertions(+)

diff --git a/arch/arm64/boot/dts/altera/Makefile b/arch/arm64/boot/dts/altera/Makefile
index d38fe88a1..29170f793 100644
--- a/arch/arm64/boot/dts/altera/Makefile
+++ b/arch/arm64/boot/dts/altera/Makefile
@@ -5,6 +5,7 @@ dtb-$(CONFIG_ARCH_INTEL_SOCFPGA) += socfpga_agilex_n6000.dtb \
 				socfpga_agilex_socdk_multiqspi.dtb \
 				socfpga_agilex_socdk_nand.dtb \
 				socfpga_agilex3_socdk.dtb \
+				socfpga_agilex5_de25_nano.dtb \
 				socfpga_agilex5_socdk.dtb \
 				socfpga_agilex5_socdk_013b.dtb \
 				socfpga_agilex5_socdk_modular.dtb \
diff --git a/arch/arm64/boot/dts/altera/socfpga_agilex5_de25_nano.dts b/arch/arm64/boot/dts/altera/socfpga_agilex5_de25_nano.dts
new file mode 100644
index 000000000..1617600e1
--- /dev/null
+++ b/arch/arm64/boot/dts/altera/socfpga_agilex5_de25_nano.dts
@@ -0,0 +1,91 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (C) 2023, Intel Corporation
+ * Copyright (C) 2026, Alexandra Østermark
+ */
+#include "socfpga_agilex5.dtsi"
+
+/ {
+	model = "Terasic DE25-Nano";
+	compatible = "terasic,de25-nano", "intel,socfpga-agilex5";
+
+	aliases {
+		serial0 = &uart1;
+		ethernet0 = &gmac0;
+	};
+
+	chosen {
+		stdout-path = "serial0:115200n8";
+	};
+
+	leds {
+		compatible = "gpio-leds";
+
+		led-0 {
+			label = "hps_led0";
+			gpios = <&portb 17 GPIO_ACTIVE_LOW>;
+		};
+	};
+
+	memory@80000000 {
+		device_type = "memory";
+		/* We expect the bootloader to fill in the reg */
+		reg = <0x0 0x80000000 0x0 0x0>;
+	};
+};
+
+&gmac0 {
+	/* TX/RX delays are on the PCB */
+	phy-mode = "rgmii";
+	phy-handle = <&emac0_phy0>;
+	max-frame-size = <9000>;
+
+	status = "okay";
+
+	mdio0 {
+		compatible = "snps,dwmac-mdio";
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		emac0_phy0: ethernet-phy@1 {
+			reg = <1>;
+		};
+	};
+};
+
+&gpio1 {
+	status = "okay";
+};
+
+&osc1 {
+	clock-frequency = <25000000>;
+};
+
+&sdmmc {
+	bus-width = <4>;
+	cap-sd-highspeed;
+	disable-wp;
+	no-1-8-v;
+	no-mmc;
+	no-sdio;
+
+	status = "okay";
+};
+
+&smmu {
+	status = "okay";
+};
+
+&uart1 {
+	status = "okay";
+};
+
+&usb0 {
+	disable-over-current;
+
+	status = "okay";
+};
+
+&watchdog0 {
+	status = "okay";
+};

-- 
2.56.0

