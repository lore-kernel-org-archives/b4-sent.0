From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Wed, 09 Jul 2025 19:05:55 +0800
Subject: [PATCH v2 4/9] MIPS: dts: loongson: Add LSGZ_1B_DEV board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250709-loongson1-arch-v2-4-bcff6e518c09@gmail.com>
References: <20250709-loongson1-arch-v2-0-bcff6e518c09@gmail.com>
In-Reply-To: <20250709-loongson1-arch-v2-0-bcff6e518c09@gmail.com>
To: Thomas Bogendoerfer <tsbogend@alpha.franken.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Keguang Zhang <keguang.zhang@gmail.com>
Cc: linux-mips@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752059245; l=3407;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=2bhEPmFaIZuk42qpq2GGxygw19k6CrRSCdaYJDRk9is=;
 b=meTphHFzCDa4sXNbWgmR8uaXFl26PDn5U4zGF38hz0eGSxixOOa8SzdGvJq15eR/NnIaPj/Q6
 HQdD4zZpox2CWU4FNsrzg6LD/gSnwmOy2u+e9YRRZbM5AVwDuxAabZC
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a device tree for LSGZ_1B_DEV board.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 arch/mips/boot/dts/loongson/Makefile        |   1 +
 arch/mips/boot/dts/loongson/lsgz_1b_dev.dts | 145 ++++++++++++++++++++++++++++
 2 files changed, 146 insertions(+)

diff --git a/arch/mips/boot/dts/loongson/Makefile b/arch/mips/boot/dts/loongson/Makefile
index 2facf251fb6a..1123d08dbfbe 100644
--- a/arch/mips/boot/dts/loongson/Makefile
+++ b/arch/mips/boot/dts/loongson/Makefile
@@ -10,4 +10,5 @@ ifneq ($(CONFIG_BUILTIN_DTB_NAME),)
 dtb-y	:= $(addsuffix .dtb, $(CONFIG_BUILTIN_DTB_NAME))
 else
 dtb-$(CONFIG_MACH_LOONGSON32)	+= ls1b-demo.dtb
+dtb-$(CONFIG_MACH_LOONGSON32)	+= lsgz_1b_dev.dtb
 endif
diff --git a/arch/mips/boot/dts/loongson/lsgz_1b_dev.dts b/arch/mips/boot/dts/loongson/lsgz_1b_dev.dts
new file mode 100644
index 000000000000..c4f9a4499fad
--- /dev/null
+++ b/arch/mips/boot/dts/loongson/lsgz_1b_dev.dts
@@ -0,0 +1,145 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2023-2025 Keguang Zhang <keguang.zhang@gmail.com>
+ */
+
+/dts-v1/;
+
+#include <dt-bindings/gpio/gpio.h>
+
+#include "loongson1b.dtsi"
+
+/ {
+	compatible = "loongson,lsgz-1b-dev", "loongson,ls1b";
+	model = "LSGZ_1B_DEV Board";
+
+	memory@0 {
+		device_type = "memory";
+		reg = <0x0 0x4000000>;
+	};
+
+	aliases {
+		ethernet0 = &gmac0;
+		ethernet1 = &gmac1;
+		gpio0 = &gpio0;
+		gpio1 = &gpio1;
+		serial0 = &uart2;
+		serial1 = &uart3;
+	};
+
+	chosen {
+		bootargs = "mtdparts=ls1x-nand:16m(kernel),-(rootfs)";
+		stdout-path = "serial0:115200n8";
+	};
+
+	leds {
+		compatible = "gpio-leds";
+
+		led9 {
+			label = "led9";
+			gpios = <&gpio1 6 GPIO_ACTIVE_LOW>;
+			linux,default-trigger = "heartbeat";
+		};
+
+		led6 {
+			label = "led6";
+			gpios = <&gpio1 7 GPIO_ACTIVE_LOW>;
+			linux,default-trigger = "nand-disk";
+		};
+	};
+
+	codec: audio-codec {
+		compatible = "realtek,alc203";
+		#sound-dai-cells = <0>;
+	};
+
+	sound {
+		compatible = "simple-audio-card";
+		simple-audio-card,name = "ls1b-alc655";
+		simple-audio-card,format = "ac97";
+		simple-audio-card,widgets =
+			"Speaker", "Line Out Jack",
+			"Line", "Line In Jack",
+			"Microphone", "Microphone Jack";
+		simple-audio-card,routing =
+			"Line Out Jack", "TX",
+			"RX", "Line In Jack",
+			"RX", "Microphone Jack";
+
+		simple-audio-card,cpu {
+			sound-dai = <&ac97>;
+		};
+
+		simple-audio-card,codec {
+			sound-dai = <&codec>;
+		};
+	};
+};
+
+&gmac0 {
+	phy-handle = <&phy0>;
+	phy-mode = "mii";
+	status = "okay";
+
+	mdio {
+		#address-cells = <1>;
+		#size-cells = <0>;
+		compatible = "snps,dwmac-mdio";
+
+		phy0: ethernet-phy@0 {
+			reg = <0x0>;
+		};
+	};
+};
+
+&gmac1 {
+	phy-handle = <&phy1>;
+	phy-mode = "mii";
+	status = "okay";
+
+	mdio {
+		compatible = "snps,dwmac-mdio";
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		phy1: ethernet-phy@0 {
+			reg = <0x0>;
+		};
+	};
+};
+
+&xtal {
+	clock-frequency = <33000000>;
+};
+
+&ac97 {
+	status = "okay";
+};
+
+&ehci {
+	status = "okay";
+};
+
+&ohci {
+	status = "okay";
+};
+
+&nand {
+	status = "okay";
+};
+
+&rtc {
+	status = "okay";
+};
+
+&uart2 {
+	status = "okay";
+};
+
+&uart3 {
+	status = "okay";
+};
+
+&watchdog {
+	status = "okay";
+};

-- 
2.43.0

