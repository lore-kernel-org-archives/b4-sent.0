From: Michael Riesch <michael.riesch@collabora.com>
Date: Fri, 24 Oct 2025 14:51:47 +0200
Subject: [PATCH v14 18/18] arm64: dts: rockchip: add radxa camera 8m on
 rock 3a csi port
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240220-rk3568-vicap-v14-18-b38b6da0fc80@collabora.com>
References: <20240220-rk3568-vicap-v14-0-b38b6da0fc80@collabora.com>
In-Reply-To: <20240220-rk3568-vicap-v14-0-b38b6da0fc80@collabora.com>
To: Mehdi Djait <mehdi.djait@linux.intel.com>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 =?utf-8?q?Th=C3=A9o_Lebrun?= <theo.lebrun@bootlin.com>, 
 Thomas Petazzoni <thomas.petazzoni@bootlin.com>, 
 Gerald Loacker <gerald.loacker@wolfvision.net>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Markus Elfring <Markus.Elfring@web.de>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh+dt@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Collabora Kernel Team <kernel@collabora.com>, 
 Paul Kocialkowski <paulk@sys-base.io>, 
 Alexander Shiyan <eagle.alexander923@gmail.com>, 
 Val Packett <val@packett.cool>, Rob Herring <robh@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, 
 Michael Riesch <michael.riesch@collabora.com>, 
 Michael Riesch <michael.riesch@collabora.com>, Chen-Yu Tsai <wens@csie.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761310293; l=4423;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=8+gsoG6dBtp0EaQEhGBr2hG0N8BoIt7Rya8dykcaVJk=;
 b=QkRDoMhQXlaFfrn9H71B3EP+aJ/ZFPGMPArrb0cZaFufBhfhco4GYIEBu49GXqLJFY4wL0S/t
 PDmNnpkWsOTAw30EHsw4FTe/oYnr3pBtVS8aiMB9hBhAcr/1fSkeQwf
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a device tree overlay for the Radxa Camera 8M (featuring the
Sony IMX219 image sensor) to be connected to the Radxa ROCK 3A CSI
port.

The image sensor is connected to the RK3568 VICAP MIPI CSI-2
port, since as at the time of writing this there is no mainline
support for the RK3568 ISP.

Reviewed-by: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Reviewed-by: Chen-Yu Tsai <wens@csie.org>
Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 arch/arm64/boot/dts/rockchip/Makefile              |   5 +
 .../dts/rockchip/rk3568-rock-3a-radxa-cam8m.dtso   | 103 +++++++++++++++++++++
 2 files changed, 108 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/Makefile b/arch/arm64/boot/dts/rockchip/Makefile
index ad684e3831bc..d6b969a0dab9 100644
--- a/arch/arm64/boot/dts/rockchip/Makefile
+++ b/arch/arm64/boot/dts/rockchip/Makefile
@@ -146,6 +146,7 @@ dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3568-qnap-ts433.dtb
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3568-radxa-e25.dtb
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3568-roc-pc.dtb
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3568-rock-3a.dtb
+dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3568-rock-3a-radxa-cam8m.dtbo
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3568-rock-3b.dtb
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3568-wolfvision-pf5.dtb
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3568-wolfvision-pf5-display-vz.dtbo
@@ -243,6 +244,10 @@ dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3399-rockpro64-v2-screen.dtb
 rk3399-rockpro64-v2-screen-dtbs := rk3399-rockpro64-v2.dtb \
 	rk3399-rockpro64-screen.dtbo
 
+dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3568-rock-3a-radxa-8m-cam.dtb
+rk3568-rock-3a-radxa-8m-cam-dtbs := rk3568-rock-3a.dtb \
+	rk3568-rock-3a-radxa-cam8m.dtbo
+
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3568-wolfvision-pf5-vz-2-uhd.dtb
 rk3568-wolfvision-pf5-vz-2-uhd-dtbs := rk3568-wolfvision-pf5.dtb \
 	rk3568-wolfvision-pf5-display-vz.dtbo \
diff --git a/arch/arm64/boot/dts/rockchip/rk3568-rock-3a-radxa-cam8m.dtso b/arch/arm64/boot/dts/rockchip/rk3568-rock-3a-radxa-cam8m.dtso
new file mode 100644
index 000000000000..3aa1ffdc22d8
--- /dev/null
+++ b/arch/arm64/boot/dts/rockchip/rk3568-rock-3a-radxa-cam8m.dtso
@@ -0,0 +1,103 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
+/*
+ * Device tree overlay for the Radxa Camera 8M attached to the CSI port of
+ * the Radxa ROCK 3A.
+ */
+
+/dts-v1/;
+/plugin/;
+
+#include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/pinctrl/rockchip.h>
+
+&{/} {
+	clk_camera: clock-camera {
+		compatible = "fixed-clock";
+		clock-frequency = <24000000>;
+		clock-output-names = "clk_camera";
+		#clock-cells = <0>;
+	};
+
+	vana_camera: regulator-vana-camera {
+		compatible = "regulator-fixed";
+		regulator-min-microvolt = <2800000>;
+		regulator-max-microvolt = <2800000>;
+		regulator-name = "vana_camera";
+		vin-supply = <&vcc_cam>;
+	};
+
+	vddl_camera: regulator-vddl-camera {
+		compatible = "regulator-fixed";
+		regulator-min-microvolt = <1200000>;
+		regulator-max-microvolt = <1200000>;
+		regulator-name = "vddl_camera";
+		vin-supply = <&vcc_cam>;
+	};
+
+	vdig_camera: regulator-vdig-camera {
+		compatible = "regulator-fixed";
+		regulator-min-microvolt = <1800000>;
+		regulator-max-microvolt = <1800000>;
+		regulator-name = "vdig_camera";
+		vin-supply = <&vcc_cam>;
+	};
+};
+
+&i2c5 {
+	#address-cells = <1>;
+	#size-cells = <0>;
+	status = "okay";
+
+	imx219: camera-sensor@10 {
+		compatible = "sony,imx219";
+		reg = <0x10>;
+		clocks = <&clk_camera>;
+		clock-names = "xclk";
+		pinctrl-names = "default";
+		pinctrl-0 = <&camera_reset>;
+		reset-gpios = <&gpio4 RK_PD2 GPIO_ACTIVE_HIGH>;
+		VANA-supply = <&vana_camera>;
+		VDDL-supply = <&vddl_camera>;
+		VDIG-supply = <&vdig_camera>;
+
+		port {
+			imx219_output: endpoint {
+				data-lanes = <1 2>;
+				link-frequencies = /bits/ 64 <456000000>;
+				remote-endpoint = <&csi_input>;
+			};
+		};
+	};
+};
+
+&pinctrl {
+	cam {
+		camera_reset: camera-reset-pinctrl {
+			rockchip,pins = <4 RK_PD2 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+	};
+};
+
+&csi {
+	status = "okay";
+};
+
+&csi_dphy {
+	status = "okay";
+};
+
+&csi_in {
+	csi_input: endpoint {
+		data-lanes = <1 2>;
+		link-frequencies = /bits/ 64 <456000000>;
+		remote-endpoint = <&imx219_output>;
+	};
+};
+
+&vicap {
+	status = "okay";
+};
+
+&vicap_mmu {
+	status = "okay";
+};

-- 
2.39.5

