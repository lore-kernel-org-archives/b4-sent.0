From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Wed, 09 Jul 2025 19:05:57 +0800
Subject: [PATCH v2 6/9] MIPS: dts: loongson: Add CQ-T300B board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250709-loongson1-arch-v2-6-bcff6e518c09@gmail.com>
References: <20250709-loongson1-arch-v2-0-bcff6e518c09@gmail.com>
In-Reply-To: <20250709-loongson1-arch-v2-0-bcff6e518c09@gmail.com>
To: Thomas Bogendoerfer <tsbogend@alpha.franken.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Keguang Zhang <keguang.zhang@gmail.com>
Cc: linux-mips@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752059245; l=2574;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=CirtBr6NDZ066YElVjV3KiB97Vdt6gZ9zvL1Pmzb1hg=;
 b=kvAfWR6SSXvzg0B4jrlBM7okim7IrA65cnw88olc57ShmHBgOaK55pbGYG9DuAS3SLIuHcX29
 +kDMrNP3ukaCXJUHlzM3crOpjqZQjngKO9v/4EJV5Zobd2AFVqhxdmS
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a device tree for CQ-T300B board.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 arch/mips/boot/dts/loongson/Makefile     |  1 +
 arch/mips/boot/dts/loongson/cq-t300b.dts | 93 ++++++++++++++++++++++++++++++++
 2 files changed, 94 insertions(+)

diff --git a/arch/mips/boot/dts/loongson/Makefile b/arch/mips/boot/dts/loongson/Makefile
index 633d95848f76..66d65a56a491 100644
--- a/arch/mips/boot/dts/loongson/Makefile
+++ b/arch/mips/boot/dts/loongson/Makefile
@@ -9,6 +9,7 @@ dtb-$(CONFIG_MACH_LOONGSON64)	+= loongson64v_4core_virtio.dtb
 ifneq ($(CONFIG_BUILTIN_DTB_NAME),)
 dtb-y	:= $(addsuffix .dtb, $(CONFIG_BUILTIN_DTB_NAME))
 else
+dtb-$(CONFIG_MACH_LOONGSON32)	+= cq-t300b.dtb
 dtb-$(CONFIG_MACH_LOONGSON32)	+= ls1b-demo.dtb
 dtb-$(CONFIG_MACH_LOONGSON32)	+= lsgz_1b_dev.dtb
 dtb-$(CONFIG_MACH_LOONGSON32)	+= smartloong-1c.dtb
diff --git a/arch/mips/boot/dts/loongson/cq-t300b.dts b/arch/mips/boot/dts/loongson/cq-t300b.dts
new file mode 100644
index 000000000000..78a3d7d83aff
--- /dev/null
+++ b/arch/mips/boot/dts/loongson/cq-t300b.dts
@@ -0,0 +1,93 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2023-2025 Keguang Zhang <keguang.zhang@gmail.com>
+ */
+
+/dts-v1/;
+
+#include <dt-bindings/gpio/gpio.h>
+
+#include "loongson1c.dtsi"
+
+/ {
+	compatible = "loongson,cq-t300b", "loongson,ls1c";
+	model = "CQ-T300B Board";
+
+	memory@0 {
+		device_type = "memory";
+		reg = <0x0 0x8000000>;
+	};
+
+	aliases {
+		gpio0 = &gpio0;
+		gpio1 = &gpio1;
+		gpio2 = &gpio2;
+		gpio3 = &gpio3;
+		serial0 = &uart2;
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
+		led0 {
+			label = "led0";
+			gpios = <&gpio1 20 GPIO_ACTIVE_LOW>;
+			linux,default-trigger = "heartbeat";
+		};
+
+		led1 {
+			label = "led1";
+			gpios = <&gpio1 21 GPIO_ACTIVE_LOW>;
+			linux,default-trigger = "nand-disk";
+		};
+	};
+};
+
+&emac {
+	phy-handle = <&phy0>;
+	phy-mode = "rmii";
+	status = "okay";
+
+	mdio {
+		compatible = "snps,dwmac-mdio";
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		phy0: ethernet-phy@13 {
+			reg = <0x13>;
+		};
+	};
+};
+
+&xtal {
+	clock-frequency = <24000000>;
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
+&watchdog {
+	status = "okay";
+};

-- 
2.43.0

