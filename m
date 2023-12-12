From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Tue, 12 Dec 2023 11:20:50 +0300
Subject: [PATCH v6 33/40] ARM: dts: ep93xx: Add EDB9302 DT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231212-ep93xx-v6-33-c307b8ac9aa8@maquefel.me>
References: <20231212-ep93xx-v6-0-c307b8ac9aa8@maquefel.me>
In-Reply-To: <20231212-ep93xx-v6-0-c307b8ac9aa8@maquefel.me>
To: Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andre Przywara <andre.przywara@arm.com>, 
 Nikita Shubin <nikita.shubin@maquefel.me>, 
 Kunihiko Hayashi <hayashi.kunihiko@socionext.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Enric Balletbo i Serra <eballetbo@gmail.com>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>
Cc: Baruch Siach <baruch@tkos.co.il>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Claudiu Beznea <claudiu.beznea@tuxon.dev>, Rob Herring <robh@kernel.org>, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702369322; l=4429;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=KR6AhAHkrEaDtUcRyLyul6gEHO42boKFUOuHc7e+r74=;
 b=P975mHbEaDzx0iqk6K6KrUHQWm03I2i73dl6+3CctgiN2cYYn38cJ1w5CpL/vGXxCkvtGVdDJrE8
 6+4TpwvXC+HwjQT4bdgolQ7psIaD16UuwOgK6Jt+Cj+vd90McTVN
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Alexander Sverdlin <alexander.sverdlin@gmail.com>

Add device tree for Cirrus EDB9302.

Signed-off-by: Alexander Sverdlin <alexander.sverdlin@gmail.com>
Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 arch/arm/boot/dts/cirrus/Makefile           |   1 +
 arch/arm/boot/dts/cirrus/ep93xx-edb9302.dts | 182 ++++++++++++++++++++++++++++
 2 files changed, 183 insertions(+)

diff --git a/arch/arm/boot/dts/cirrus/Makefile b/arch/arm/boot/dts/cirrus/Makefile
index 211a7e2f2115..e6015983e464 100644
--- a/arch/arm/boot/dts/cirrus/Makefile
+++ b/arch/arm/boot/dts/cirrus/Makefile
@@ -4,5 +4,6 @@ dtb-$(CONFIG_ARCH_CLPS711X) += \
 dtb-$(CONFIG_ARCH_CLPS711X) += \
 	ep7211-edb7211.dtb
 dtb-$(CONFIG_ARCH_EP93XX) += \
+	ep93xx-edb9302.dtb \
 	ep93xx-bk3.dtb \
 	ep93xx-ts7250.dtb
diff --git a/arch/arm/boot/dts/cirrus/ep93xx-edb9302.dts b/arch/arm/boot/dts/cirrus/ep93xx-edb9302.dts
new file mode 100644
index 000000000000..f015c6b8c802
--- /dev/null
+++ b/arch/arm/boot/dts/cirrus/ep93xx-edb9302.dts
@@ -0,0 +1,182 @@
+// SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+/*
+ * Device Tree file for Cirrus Logic EDB9302 board based on EP9302 SoC
+ */
+/dts-v1/;
+#include "ep93xx.dtsi"
+
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+	compatible = "cirrus,edb9302", "cirrus,ep9301";
+	model = "cirrus,edb9302";
+
+	chosen {
+	};
+
+	memory@0 {
+		device_type = "memory";
+		/* should be set from ATAGS */
+		reg = <0x0000000 0x800000>,
+		      <0x1000000 0x800000>,
+		      <0x4000000 0x800000>,
+		      <0x5000000 0x800000>;
+	};
+
+	sound {
+		compatible = "audio-graph-card2";
+		label = "EDB93XX";
+		links = <&i2s_port>;
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
+&adc {
+	status = "okay";
+};
+
+&ebi {
+	flash@60000000 {
+		compatible = "cfi-flash";
+		reg = <0x60000000 0x1000000>;
+		bank-width = <2>;
+	};
+};
+
+&eth0 {
+	phy-handle = <&phy0>;
+};
+
+&gpio0 {
+	gpio-ranges = <&syscon 0 153 1>,
+		      <&syscon 1 152 1>,
+		      <&syscon 2 151 1>,
+		      <&syscon 3 148 1>,
+		      <&syscon 4 147 1>,
+		      <&syscon 5 146 1>,
+		      <&syscon 6 145 1>,
+		      <&syscon 7 144 1>;
+};
+
+&gpio1 {
+	gpio-ranges = <&syscon 0 143 1>,
+		      <&syscon 1 142 1>,
+		      <&syscon 2 141 1>,
+		      <&syscon 3 140 1>,
+		      <&syscon 4 165 1>,
+		      <&syscon 5 164 1>,
+		      <&syscon 6 163 1>,
+		      <&syscon 7 160 1>;
+};
+
+&gpio2 {
+	gpio-ranges = <&syscon 0 115 1>;
+};
+
+/* edb9302 doesn't have GPIO Port D present */
+&gpio3 {
+	status = "disabled";
+};
+
+&gpio4 {
+	gpio-ranges = <&syscon 0 97 2>;
+};
+
+&gpio5 {
+	gpio-ranges = <&syscon 1 170 1>,
+		      <&syscon 2 169 1>,
+		      <&syscon 3 168 1>;
+};
+
+&gpio6 {
+	gpio-ranges = <&syscon 0 87 2>;
+};
+
+&gpio7 {
+	gpio-ranges = <&syscon 2 199 4>;
+};
+
+&i2s {
+	pinctrl-names = "default";
+	pinctrl-0 = <&i2s_on_ac97_pins>;
+	status = "okay";
+	i2s_port: port {
+		i2s_ep: endpoint {
+			system-clock-direction-out;
+			frame-master;
+			bitclock-master;
+			mclk-fs = <256>;
+			dai-format = "i2s";
+			convert-channels = <2>;
+			convert-sample-format = "s32_le";
+			remote-endpoint = <&codec_ep>;
+		};
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
+&spi0 {
+	cs-gpios = <&gpio0 6 GPIO_ACTIVE_LOW
+		    &gpio0 7 GPIO_ACTIVE_LOW>;
+	dmas = <&dma1 10 2>, <&dma1 10 1>;
+	dma-names = "rx", "tx";
+	status = "okay";
+
+	cs4271: codec@0 {
+		compatible = "cirrus,cs4271";
+		reg = <0>;
+		#sound-dai-cells = <0>;
+		spi-max-frequency = <6000000>;
+		spi-cpol;
+		spi-cpha;
+		reset-gpio = <&gpio0 1 GPIO_ACTIVE_HIGH>;
+		port {
+			codec_ep: endpoint {
+				remote-endpoint = <&i2s_ep>;
+			};
+		};
+	};
+
+	at25f1024: eeprom@1 {
+		compatible = "atmel,at25";
+		reg = <1>;
+		address-width = <8>;
+		size = <0x20000>;
+		pagesize = <256>;
+		spi-max-frequency = <20000000>;
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

-- 
2.41.0

