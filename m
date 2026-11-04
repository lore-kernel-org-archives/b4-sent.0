From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Wed, 04 Nov 2026 21:59:23 +0100
Subject: [PATCH v2 3/3] arm64: dts: rockchip: add support for NanoPi M6V2
 board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-nanopi-m6v2-v2-3-dfcd8714f48a@gmail.com>
References: <20261104-nanopi-m6v2-v2-0-dfcd8714f48a@gmail.com>
In-Reply-To: <20261104-nanopi-m6v2-v2-0-dfcd8714f48a@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Shawn Lin <Shawn.lin@rock-chips.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793825992; l=3730;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=HHQTMsbiHoDvV4k5fOgzM7R6OF8pxLzbRe7t3xi4I0Q=;
 b=pLoioa4DXzOYLFPjeycLv5Si+yS1Jb3O+ClLo26AW0tG4GB0AluSmJgjF0544wpfj4ardxT8A
 GpaGGu0SohEAjGdqxVsOU0rXxfkeSoRkUgo6zQJ/vkRcC67hx4jeaAO
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The NanoPi M6V2 board is an updated version of the original M6 board
with the following changes.
* New audio CODEC (Everest ES8389)
* New Ethernet PHY (MotorComm YT8531C)
* 1 extra user button
* Misc connector changes on the board

The codec_es_3v3 regulator enable pin is hardwired to the 5V input rail.

See link below for detailed information:
https://wiki.friendlyelec.com/wiki/index.php/NanoPi_M6V2

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
 arch/arm64/boot/dts/rockchip/Makefile              |  1 +
 .../boot/dts/rockchip/rk3588s-nanopi-m6v2.dts      | 94 ++++++++++++++++++++++
 2 files changed, 95 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/Makefile b/arch/arm64/boot/dts/rockchip/Makefile
index 57a1f41986377..3df63c35b4bf0 100644
--- a/arch/arm64/boot/dts/rockchip/Makefile
+++ b/arch/arm64/boot/dts/rockchip/Makefile
@@ -240,6 +240,7 @@ dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588s-indiedroid-nova.dtb
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588s-khadas-edge2.dtb
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588s-lubancat-4.dtb
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588s-nanopi-m6v1.dtb
+dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588s-nanopi-m6v2.dtb
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588s-nanopi-r6s.dtb
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588s-nanopi-r6c.dtb
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588s-odroid-m2.dtb
diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-m6v2.dts b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-m6v2.dts
new file mode 100644
index 0000000000000..b343c1e08c263
--- /dev/null
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi-m6v2.dts
@@ -0,0 +1,94 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
+
+/dts-v1/;
+
+#include "rk3588s-nanopi-m6.dtsi"
+
+/ {
+	model = "FriendlyElec NanoPi M6V2";
+	compatible = "friendlyarm,nanopi-m6v2", "rockchip,rk3588s";
+
+	analog-sound {
+		compatible = "audio-graph-card";
+		label = "rk3588s-es8389";
+
+		pinctrl-names = "default";
+		pinctrl-0 = <&hp_det>;
+		hp-det-gpios = <&gpio1 RK_PC4 GPIO_ACTIVE_LOW>;
+
+		dais = <&i2s0_8ch_p0>;
+		routing =
+			"Headphones", "HPOL",
+			"Headphones", "HPOR",
+			"INPUT1", "Microphone Jack",
+			"INPUT2", "Microphone Jack";
+		widgets =
+			"Headphone", "Headphones",
+			"Microphone", "Microphone Jack";
+	};
+
+	codec_es_3v3: regulator-codec-es-3v3 {
+		compatible = "regulator-fixed";
+		regulator-always-on;
+		regulator-boot-on;
+		regulator-min-microvolt = <3300000>;
+		regulator-max-microvolt = <3300000>;
+		regulator-name = "codec_es_3v3";
+		vin-supply = <&vcc5v0_sys>;
+	};
+
+	gpio-keys {
+		compatible = "gpio-keys";
+		pinctrl-names = "default";
+		pinctrl-0 = <&user_btn>;
+
+		user-button {
+			label = "User";
+			linux,code = <BTN_1>;
+			gpios = <&gpio0 RK_PD3 GPIO_ACTIVE_LOW>;
+			debounce-interval = <50>;
+		};
+	};
+};
+
+&i2c7 {
+	audio-codec@10 {
+		compatible = "everest,es8389";
+		reg = <0x10>;
+		assigned-clocks = <&cru I2S0_8CH_MCLKOUT_TO_IO>;
+		assigned-clock-rates = <12288000>;
+		clocks = <&cru I2S0_8CH_MCLKOUT_TO_IO>;
+		clock-names = "mclk";
+		vddd-supply = <&vcc_1v8_s3>;
+		vdda-supply = <&codec_es_3v3>;
+		#sound-dai-cells = <0>;
+
+		port {
+			es8389_p0: endpoint {
+				remote-endpoint = <&i2s0_8ch_p0_0>;
+			};
+		};
+	};
+};
+
+&i2s0_8ch {
+	i2s0_8ch_p0: port {
+		i2s0_8ch_p0_0: endpoint {
+			dai-format = "i2s";
+			mclk-fs = <256>;
+			remote-endpoint = <&es8389_p0>;
+		};
+	};
+};
+
+&pinctrl {
+	buttons {
+		user_btn: user-btn {
+			rockchip,pins = <0 RK_PD3 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+	};
+};
+
+&rgmii_phy1 { /* MotorComm YT8531C */
+	compatible = "ethernet-phy-id4f51.e91b";
+};

-- 
2.56.0

