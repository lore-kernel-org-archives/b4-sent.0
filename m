From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Sun, 14 Apr 2024 14:46:02 +0300
Subject: [PATCH 3/4] ARM: dts: BCM5301X: Add DT for ASUS RT-AC3200
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240414-for-soc-asus-rt-ac3200-ac5300-v1-3-118c90bae6e5@arinc9.com>
References: <20240414-for-soc-asus-rt-ac3200-ac5300-v1-0-118c90bae6e5@arinc9.com>
In-Reply-To: <20240414-for-soc-asus-rt-ac3200-ac5300-v1-0-118c90bae6e5@arinc9.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Hauke Mehrtens <hauke@hauke-m.de>, Rafal Milecki <zajec5@gmail.com>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>
Cc: Tom Brautaset <tbrautaset@gmail.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713095170; l=4685;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=MAxATdfObwh2SOncdJYjGodR/vN2WwSuPYVRn0aQlKc=;
 b=PRe1/NIrZOatc4df/JLRUaxU1oPuCPspVNZkusgetwENt9wtS5yT8DeJTqOa1/XvUueKLITPe
 JpZiX7gsvJhDBSHyzoM8s2WF0bQyEaXXR4DKu/pFZvc6uZlcO9YPxTU
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the device tree for ASUS RT-AC3200 which is an AC3200 router featuring
5 Ethernet ports over the integrated Broadcom switch.

Hardware info:
* Processor: Broadcom BCM4709A0 dual-core @ 1.0 GHz
* Switch: BCM53012 in BCM4709A0
* DDR3 RAM: 256 MB
* Flash: 128 MB
* 2.4GHz: BCM43602 3x3 single chip 802.11b/g/n SoC
* 5GHz: BCM43602 3x3 two chips 802.11a/n/ac SoC
* Ports: 4 LAN Ports, 1 WAN Port

Co-developed-by: Tom Brautaset <tbrautaset@gmail.com>
Signed-off-by: Tom Brautaset <tbrautaset@gmail.com>
Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 arch/arm/boot/dts/broadcom/Makefile                |   1 +
 .../boot/dts/broadcom/bcm4709-asus-rt-ac3200.dts   | 164 +++++++++++++++++++++
 2 files changed, 165 insertions(+)

diff --git a/arch/arm/boot/dts/broadcom/Makefile b/arch/arm/boot/dts/broadcom/Makefile
index 7099d9560033..c61fca514775 100644
--- a/arch/arm/boot/dts/broadcom/Makefile
+++ b/arch/arm/boot/dts/broadcom/Makefile
@@ -64,6 +64,7 @@ dtb-$(CONFIG_ARCH_BCM_5301X) += \
 	bcm47081-luxul-xap-1410.dtb \
 	bcm47081-luxul-xwr-1200.dtb \
 	bcm47081-tplink-archer-c5-v2.dtb \
+	bcm4709-asus-rt-ac3200.dtb \
 	bcm4709-asus-rt-ac87u.dtb \
 	bcm4709-buffalo-wxr-1900dhp.dtb \
 	bcm4709-linksys-ea9200.dtb \
diff --git a/arch/arm/boot/dts/broadcom/bcm4709-asus-rt-ac3200.dts b/arch/arm/boot/dts/broadcom/bcm4709-asus-rt-ac3200.dts
new file mode 100644
index 000000000000..8640dda211ae
--- /dev/null
+++ b/arch/arm/boot/dts/broadcom/bcm4709-asus-rt-ac3200.dts
@@ -0,0 +1,164 @@
+// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
+/*
+ * Author: Tom Brautaset <tbrautaset@gmail.com>
+ */
+
+/dts-v1/;
+
+#include "bcm4709.dtsi"
+#include "bcm5301x-nand-cs0-bch8.dtsi"
+
+#include <dt-bindings/leds/common.h>
+
+/ {
+	compatible = "asus,rt-ac3200", "brcm,bcm4709", "brcm,bcm4708";
+	model = "ASUS RT-AC3200";
+
+	chosen {
+		bootargs = "console=ttyS0,115200 earlycon";
+	};
+
+	memory@0 {
+		device_type = "memory";
+		reg = <0x00000000 0x08000000>,
+		      <0x88000000 0x08000000>;
+	};
+
+	nvram@1c080000 {
+		compatible = "brcm,nvram";
+		reg = <0x1c080000 0x00180000>;
+
+		et0macaddr: et0macaddr {
+			#nvmem-cell-cells = <1>;
+		};
+	};
+
+	leds {
+		compatible = "gpio-leds";
+
+		led-power {
+			color = <LED_COLOR_ID_WHITE>;
+			function = LED_FUNCTION_POWER;
+			gpios = <&chipcommon 3 GPIO_ACTIVE_LOW>;
+			linux,default-trigger = "default-on";
+		};
+
+		led-wan-red {
+			color = <LED_COLOR_ID_RED>;
+			function = LED_FUNCTION_WAN;
+			gpios = <&chipcommon 5 GPIO_ACTIVE_HIGH>;
+		};
+
+		led-wps {
+			color = <LED_COLOR_ID_WHITE>;
+			function = LED_FUNCTION_WPS;
+			gpios = <&chipcommon 14 GPIO_ACTIVE_LOW>;
+		};
+	};
+
+	gpio-keys {
+		compatible = "gpio-keys";
+
+		button-reset {
+			label = "Reset";
+			linux,code = <KEY_RESTART>;
+			gpios = <&chipcommon 11 GPIO_ACTIVE_LOW>;
+		};
+
+		button-wifi {
+			label = "Wi-Fi";
+			linux,code = <KEY_RFKILL>;
+			gpios = <&chipcommon 4 GPIO_ACTIVE_LOW>;
+		};
+
+		button-wps {
+			label = "WPS";
+			linux,code = <KEY_WPS_BUTTON>;
+			gpios = <&chipcommon 7 GPIO_ACTIVE_LOW>;
+		};
+	};
+};
+
+&usb2 {
+	vcc-gpio = <&chipcommon 9 GPIO_ACTIVE_HIGH>;
+};
+
+&usb3_phy {
+	status = "okay";
+};
+
+&gmac0 {
+	nvmem-cells = <&et0macaddr 0>;
+	nvmem-cell-names = "mac-address";
+};
+
+&gmac1 {
+	nvmem-cells = <&et0macaddr 1>;
+	nvmem-cell-names = "mac-address";
+};
+
+&gmac2 {
+	nvmem-cells = <&et0macaddr 2>;
+	nvmem-cell-names = "mac-address";
+};
+
+&srab {
+	status = "okay";
+
+	ports {
+		port@0 {
+			label = "wan";
+			nvmem-cells = <&et0macaddr 0>;
+			nvmem-cell-names = "mac-address";
+		};
+
+		port@1 {
+			label = "lan1";
+			nvmem-cells = <&et0macaddr 1>;
+			nvmem-cell-names = "mac-address";
+		};
+
+		port@2 {
+			label = "lan2";
+			nvmem-cells = <&et0macaddr 2>;
+			nvmem-cell-names = "mac-address";
+		};
+
+		port@3 {
+			label = "lan3";
+			nvmem-cells = <&et0macaddr 3>;
+			nvmem-cell-names = "mac-address";
+		};
+
+		port@4 {
+			label = "lan4";
+			nvmem-cells = <&et0macaddr 4>;
+			nvmem-cell-names = "mac-address";
+		};
+	};
+};
+
+&nandcs {
+	partitions {
+		compatible = "fixed-partitions";
+		#address-cells = <1>;
+		#size-cells = <1>;
+
+		partition@0 {
+			label = "boot";
+			reg = <0x00000000 0x00080000>;
+			read-only;
+		};
+
+		partition@80000 {
+			label = "nvram";
+			reg = <0x00080000 0x00180000>;
+		};
+
+		partition@200000 {
+			label = "firmware";
+			reg = <0x00200000 0x07e00000>;
+			compatible = "brcm,trx";
+		};
+	};
+};

-- 
2.40.1

