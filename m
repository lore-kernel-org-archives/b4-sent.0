From: =?utf-8?q?Alexandra_=C3=98stermark?= <alex.cramt@gmail.com>
Date: Thu, 26 Nov 2026 10:47:37 +0100
Subject: [PATCH v2 3/3] arm64: dts: socfpga: agilex5: add support for
 Terasic DE25-Nano
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261126-de25-nano-v2-3-02e43ba72681@gmail.com>
References: <20261126-de25-nano-v2-0-02e43ba72681@gmail.com>
In-Reply-To: <20261126-de25-nano-v2-0-02e43ba72681@gmail.com>
To: Dinh Nguyen <dinguyen@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Mahesh Rao <mahesh.rao@altera.com>, 
 Mohamad Asyraaf Azhar <mohamad.asyraaf.azhar@altera.com>, 
 James Clark <jjc@jclark.com>, 
 =?utf-8?q?Alexandra_=C3=98stermark?= <alex.cramt@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795686456; l=3350;
 i=alex.cramt@gmail.com; s=20261118; h=from:subject:message-id;
 bh=V3m+t24prnHtAV40uETUSwMPIzzcnltdfZUuhWnXUvU=;
 b=0091DnP1cT+Ozo3KkmjOpUkM79VI8nlQNYDhMoZRh5Vx87yNIH6UDuImeRYszSHV2M6RQ9msN
 EqYg0aaRwPZDelg67jfCnsBdGajePK5ZcMulkTh69GedmwT8qSWbp8Z
X-Developer-Key: i=alex.cramt@gmail.com; a=ed25519;
 pk=vQBaXUvFG7cCIaWDKclPMjo3b4XfPEVkuPjaWCkYddc=
X-Endpoint-Received: by B4 Relay for alex.cramt@gmail.com/20261118 with auth_id=1561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DE25-Nano is an Agilex 5 SoC FPGA board with gigabit Ethernet, a
microSD slot wired for 3.3 V only, USB and one HPS LED.

Based on Terasic's and Altera's vendor device trees for the board, which
describe the SD slot on an SDHCI node that upstream doesn't have; this
uses the upstream SD6HC sdmmc node instead.

The HPS LED is active high: the vendor trees mark it active low, which
inverts it.

I2C1 is on the HPS's own pins and reaches the onboard LIS2DW12
accelerometer at 0x19, so unlike the other I2C controllers it doesn't
depend on the FPGA design.

Boot from microSD, gigabit Ethernet, USB, the LED, I2C1 and the watchdog
were tested on the board. The QSPI flash, the other I2C buses and the
SDM hardware monitor are left out until they have been tested.

Signed-off-by: Alexandra Østermark <alex.cramt@gmail.com>
---
 arch/arm64/boot/dts/altera/Makefile                |  1 +
 .../boot/dts/altera/socfpga_agilex5_de25_nano.dts  | 95 ++++++++++++++++++++++
 2 files changed, 96 insertions(+)

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
index 000000000..128095578
--- /dev/null
+++ b/arch/arm64/boot/dts/altera/socfpga_agilex5_de25_nano.dts
@@ -0,0 +1,95 @@
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
+			gpios = <&portb 17 GPIO_ACTIVE_HIGH>;
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
+&i2c1 {
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

