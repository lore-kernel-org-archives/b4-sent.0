From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Thu, 20 Jul 2023 14:29:35 +0300
Subject: [PATCH v3 35/42] ARM: dts: ep93xx: add ts7250 board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230605-ep93xx-v3-35-3d63a5f1103e@maquefel.me>
References: <20230605-ep93xx-v3-0-3d63a5f1103e@maquefel.me>
In-Reply-To: <20230605-ep93xx-v3-0-3d63a5f1103e@maquefel.me>
To: Hartley Sweeten <hsweeten@visionengravers.com>, 
 Lennert Buytenhek <kernel@wantstofly.org>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Lukasz Majewski <lukma@denx.de>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Nikita Shubin <nikita.shubin@maquefel.me>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, 
 Thomas Gleixner <tglx@linutronix.de>, 
 Alessandro Zummo <a.zummo@towertech.it>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Sebastian Reichel <sre@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 Mark Brown <broonie@kernel.org>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Vinod Koul <vkoul@kernel.org>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Damien Le Moal <dlemoal@kernel.org>, Sergey Shtylyov <s.shtylyov@omp.ru>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Arnd Bergmann <arnd@arndb.de>, 
 Olof Johansson <olof@lixom.net>, soc@kernel.org, 
 Liam Girdwood <lgirdwood@gmail.com>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>, Andy Shevchenko <andy@kernel.org>, 
 Michael Peters <mpeters@embeddedTS.com>, Kris Bahnsen <kris@embeddedTS.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-clk@vger.kernel.org, linux-rtc@vger.kernel.org, 
 linux-watchdog@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-pwm@vger.kernel.org, linux-spi@vger.kernel.org, 
 netdev@vger.kernel.org, dmaengine@vger.kernel.org, 
 linux-mtd@lists.infradead.org, linux-ide@vger.kernel.org, 
 linux-input@vger.kernel.org, alsa-devel@alsa-project.org
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1689852591; l=6188;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=ha5ittSqqPfphW5CaHdpis/fQLU7CJDCkNuAv0g4BaA=;
 b=QmSYbABUx60eGH/7OzXmpMZCEJ2vVIKzXtwvNv88OtTJ5ioQKGH3bz0TfpH+wkNkwvYH1nC/bjub
 Y7QPRfoqC0ilRI3fMDaF9idHBkcMV2tZrtOdW6l5ZrgsyS9pER9y
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree file for Technologic Systems ts7250 board and
Liebherr bk3 board which have many in common, both are based on
ep9302 SoC variant.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 arch/arm/boot/dts/cirrus/Makefile          |   3 +
 arch/arm/boot/dts/cirrus/ep93xx-bk3.dts    | 126 +++++++++++++++++++++++++
 arch/arm/boot/dts/cirrus/ep93xx-ts7250.dts | 145 +++++++++++++++++++++++++++++
 3 files changed, 274 insertions(+)

diff --git a/arch/arm/boot/dts/cirrus/Makefile b/arch/arm/boot/dts/cirrus/Makefile
index e944d3e2129d..211a7e2f2115 100644
--- a/arch/arm/boot/dts/cirrus/Makefile
+++ b/arch/arm/boot/dts/cirrus/Makefile
@@ -3,3 +3,6 @@ dtb-$(CONFIG_ARCH_CLPS711X) += \
 	ep7211-edb7211.dtb
 dtb-$(CONFIG_ARCH_CLPS711X) += \
 	ep7211-edb7211.dtb
+dtb-$(CONFIG_ARCH_EP93XX) += \
+	ep93xx-bk3.dtb \
+	ep93xx-ts7250.dtb
diff --git a/arch/arm/boot/dts/cirrus/ep93xx-bk3.dts b/arch/arm/boot/dts/cirrus/ep93xx-bk3.dts
new file mode 100644
index 000000000000..91d76a1a8571
--- /dev/null
+++ b/arch/arm/boot/dts/cirrus/ep93xx-bk3.dts
@@ -0,0 +1,126 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Device Tree file for Liebherr controller BK3.1 based on Cirrus EP9302 SoC
+ */
+/dts-v1/;
+#include "ep93xx.dtsi"
+
+/ {
+	model = "Liebherr controller BK3.1";
+	compatible = "liebherr,bk3", "cirrus,ep9301";
+	#address-cells = <1>;
+	#size-cells = <1>;
+
+	chosen {
+	};
+
+	memory@0 {
+		device_type = "memory";
+		/* should be set from ATAGS */
+		reg = <0x00000000 0x02000000>,
+		      <0x000530c0 0x01fdd000>;
+	};
+
+	nand-controller@60000000 {
+		compatible = "technologic,ts7200-nand";
+		reg = <0x60000000 0x8000000>;
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		nand@0 {
+			reg = <0>;
+			partitions {
+				compatible = "fixed-partitions";
+				#address-cells = <1>;
+				#size-cells = <1>;
+
+				partition@0 {
+					label = "System";
+					reg = <0x00000000 0x01e00000>;
+					read-only;
+				};
+
+				partition@1e00000 {
+					label = "Data";
+					reg = <0x01e00000 0x05f20000>;
+				};
+
+				partition@7d20000 {
+					label = "RedBoot";
+					reg = <0x07d20000 0x002e0000>;
+					read-only;
+				};
+			};
+		};
+	};
+
+	leds {
+		compatible = "gpio-leds";
+		led-0 {
+			label = "grled";
+			gpios = <&gpio4 0 GPIO_ACTIVE_HIGH>;
+			linux,default-trigger = "heartbeat";
+			function = LED_FUNCTION_HEARTBEAT;
+		};
+
+		led-1 {
+			label = "rdled";
+			gpios = <&gpio4 1 GPIO_ACTIVE_HIGH>;
+			function = LED_FUNCTION_FAULT;
+		};
+	};
+};
+
+&eth0 {
+	phy-handle = <&phy0>;
+};
+
+&i2c0 {
+	status = "okay";
+};
+
+&i2s {
+	pinctrl-names = "default";
+	pinctrl-0 = <&i2s_on_ac97_pins>;
+	status = "okay";
+};
+
+&gpio1 {
+	/* PWM */
+	gpio-ranges = <&pinctrl 6 163 1>;
+};
+
+&gpio4 {
+	gpio-ranges = <&pinctrl 0 97 2>;
+	status = "okay";
+};
+
+&gpio6 {
+	gpio-ranges = <&pinctrl 0 87 2>;
+	status = "okay";
+};
+
+&gpio7 {
+	gpio-ranges = <&pinctrl 2 199 4>;
+	status = "okay";
+};
+
+&mdio0 {
+	phy0: ethernet-phy@1 {
+		reg = <1>;
+		device_type = "ethernet-phy";
+	};
+};
+
+&uart0 {
+	status = "okay";
+};
+
+&uart1 {
+	status = "okay";
+};
+
+&usb0 {
+	status = "okay";
+};
+
diff --git a/arch/arm/boot/dts/cirrus/ep93xx-ts7250.dts b/arch/arm/boot/dts/cirrus/ep93xx-ts7250.dts
new file mode 100644
index 000000000000..625202f8cd25
--- /dev/null
+++ b/arch/arm/boot/dts/cirrus/ep93xx-ts7250.dts
@@ -0,0 +1,145 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Device Tree file for Technologic Systems ts7250 board based on Cirrus EP9302 SoC
+ */
+/dts-v1/;
+#include "ep93xx.dtsi"
+#include <dt-bindings/dma/cirrus,ep93xx-dma.h>
+
+/ {
+	compatible = "technologic,ts7250", "cirrus,ep9301";
+	model = "TS-7250 SBC";
+	#address-cells = <1>;
+	#size-cells = <1>;
+
+	chosen {
+	};
+
+	memory@0 {
+		device_type = "memory";
+		/* should be set from ATAGS */
+		reg = <0x00000000 0x02000000>,
+		      <0x000530c0 0x01fdd000>;
+	};
+
+	nand-controller@60000000 {
+		compatible = "technologic,ts7200-nand";
+		reg = <0x60000000 0x8000000>;
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		nand@0 {
+			reg = <0>;
+			partitions {
+				compatible = "fixed-partitions";
+				#address-cells = <1>;
+				#size-cells = <1>;
+
+				partition@0 {
+					label = "TS-BOOTROM";
+					reg = <0x00000000 0x00020000>;
+					read-only;
+				};
+
+				partition@20000 {
+					label = "Linux";
+					reg = <0x00020000 0x07d00000>;
+				};
+
+				partition@7d20000 {
+					label = "RedBoot";
+					reg = <0x07d20000 0x002e0000>;
+					read-only;
+				};
+			};
+		};
+	};
+
+	rtc1: rtc@10800000 {
+		compatible = "st,m48t86";
+		reg = <0x10800000 0x1>,
+		      <0x11700000 0x1>;
+	};
+
+	watchdog1: watchdog@23800000 {
+		compatible = "technologic,ts7200-wdt";
+		reg = <0x23800000 0x01>,
+		      <0x23c00000 0x01>;
+		timeout-sec = <30>;
+	};
+
+	leds {
+		compatible = "gpio-leds";
+		led-0 {
+			label = "grled";
+			gpios = <&gpio4 0 GPIO_ACTIVE_HIGH>;
+			linux,default-trigger = "heartbeat";
+			function = LED_FUNCTION_HEARTBEAT;
+		};
+
+		led-1 {
+			label = "rdled";
+			gpios = <&gpio4 1 GPIO_ACTIVE_HIGH>;
+			function = LED_FUNCTION_FAULT;
+		};
+	};
+};
+
+&eth0 {
+	phy-handle = <&phy0>;
+};
+
+&gpio1 {
+	/* PWM */
+	gpio-ranges = <&pinctrl 6 163 1>;
+};
+
+&gpio4 {
+	gpio-ranges = <&pinctrl 0 97 2>;
+	status = "okay";
+};
+
+&gpio6 {
+	gpio-ranges = <&pinctrl 0 87 2>;
+	status = "okay";
+};
+
+&gpio7 {
+	gpio-ranges = <&pinctrl 2 199 4>;
+	status = "okay";
+};
+
+&i2c0 {
+	status = "okay";
+};
+
+&spi0 {
+	cs-gpios = <&gpio5 2 GPIO_ACTIVE_HIGH>;
+	dmas = <&dma1 EP93XX_DMA_SSP>;
+	status = "okay";
+
+	tmp122_spi: tmp122@0 {
+		compatible = "ti,tmp122";
+		reg = <0>;
+		spi-max-frequency = <2000000>;
+	};
+};
+
+&mdio0 {
+	phy0: ethernet-phy@1 {
+		reg = <1>;
+		device_type = "ethernet-phy";
+	};
+};
+
+&uart0 {
+	status = "okay";
+};
+
+&uart1 {
+	status = "okay";
+};
+
+&usb0 {
+	status = "okay";
+};

-- 
2.39.2

