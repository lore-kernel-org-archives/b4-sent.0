From: Michael Riesch <michael.riesch@collabora.com>
Date: Tue, 17 Mar 2026 10:32:25 +0100
Subject: [PATCH v2 7/9] arm64: dts: rockchip: add radxa camera 4k on rock
 5b+ cam0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250430-rk3588-vicap-v2-7-77de5ee9048e@collabora.com>
References: <20250430-rk3588-vicap-v2-0-77de5ee9048e@collabora.com>
In-Reply-To: <20250430-rk3588-vicap-v2-0-77de5ee9048e@collabora.com>
To: Mehdi Djait <mehdi.djait@linux.intel.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Jagan Teki <jagan@amarulasolutions.com>, 
 =?utf-8?q?=D0=9A=D1=83=D0=B7=D0=BD=D0=B5=D1=86=D0=BE=D0=B2_=D0=9C=D0=B8=D1=85=D0=B0=D0=B8=D0=BB?= <mai.kuznetsov.misha@gmail.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Collabora Kernel Team <kernel@collabora.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773739942; l=3957;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=0IGxS8JbtLH7trkBy9V2Ur/nAvpqj7WKMLLd/LMBhQs=;
 b=bjZl9IwqOmybyyMWJZUOQLn6j/43QSGHZEYxDQkRk2vqof/aQ498l5lF1T9jzTcxJH+/d4Nyt
 UGZv3PZw0vbDOPVfoRLY7uuaE72p0/kd3/hrrF3lOfaed2vOSeUsVbj
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree overlay for the Radxa Camera 4K (featuring the
Sony IMX415 image sensor) to applied on the Radxa ROCK 5B+
CAM0 port.

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 arch/arm64/boot/dts/rockchip/Makefile              |  5 ++
 .../rk3588-rock-5b-plus-radxa-cam4k-cam0.dtso      | 89 ++++++++++++++++++++++
 2 files changed, 94 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/Makefile b/arch/arm64/boot/dts/rockchip/Makefile
index 4d384f153c13..77c587f43dda 100644
--- a/arch/arm64/boot/dts/rockchip/Makefile
+++ b/arch/arm64/boot/dts/rockchip/Makefile
@@ -199,6 +199,7 @@ dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588-rock-5b.dtb
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588-rock-5b-pcie-ep.dtbo
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588-rock-5b-pcie-srns.dtbo
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588-rock-5b-plus.dtb
+dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588-rock-5b-plus-radxa-cam4k-cam0.dtbo
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588-rock-5t.dtb
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588-tiger-haikou.dtb
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588-tiger-haikou-video-demo.dtbo
@@ -298,6 +299,10 @@ dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588-rock-5b-pcie-srns.dtb
 rk3588-rock-5b-pcie-srns-dtbs := rk3588-rock-5b.dtb \
 	rk3588-rock-5b-pcie-srns.dtbo
 
+dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588-rock-5b-plus-radxa-4k-cam.dtb
+rk3588-rock-5b-plus-radxa-4k-cam-dtbs := rk3588-rock-5b-plus.dtb \
+	rk3588-rock-5b-plus-radxa-cam4k-cam0.dtbo
+
 dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588-tiger-haikou-haikou-video-demo.dtb
 rk3588-tiger-haikou-haikou-video-demo-dtbs := rk3588-tiger-haikou.dtb \
 	rk3588-tiger-haikou-video-demo.dtbo
diff --git a/arch/arm64/boot/dts/rockchip/rk3588-rock-5b-plus-radxa-cam4k-cam0.dtso b/arch/arm64/boot/dts/rockchip/rk3588-rock-5b-plus-radxa-cam4k-cam0.dtso
new file mode 100644
index 000000000000..c107c74c2188
--- /dev/null
+++ b/arch/arm64/boot/dts/rockchip/rk3588-rock-5b-plus-radxa-cam4k-cam0.dtso
@@ -0,0 +1,89 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
+/*
+ * Device tree overlay for the Radxa Camera 4K attached to the CAM0 port of
+ * the Radxa ROCK 5B+.
+ */
+
+/dts-v1/;
+/plugin/;
+
+#include <dt-bindings/clock/rockchip,rk3588-cru.h>
+#include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/pinctrl/rockchip.h>
+
+&{/} {
+	vcc_cam0: regulator-vcc-cam0 {
+		compatible = "regulator-fixed";
+		enable-active-high;
+		gpio = <&gpio1 RK_PB0 GPIO_ACTIVE_HIGH>;
+		pinctrl-names = "default";
+		pinctrl-0 = <&cam0_power0_en>;
+		regulator-name = "vcc_cam0";
+		vin-supply = <&vcc_3v3_s3>;
+	};
+};
+
+&i2c3 {
+	#address-cells = <1>;
+	#size-cells = <0>;
+	status = "okay";
+
+	imx415: camera-sensor@1a {
+		compatible = "sony,imx415";
+		reg = <0x1a>;
+		assigned-clocks = <&cru CLK_MIPI_CAMARAOUT_M3>;
+		assigned-clock-rates = <37125000>;
+		avdd-supply = <&vcc_cam0>;
+		clocks = <&cru CLK_MIPI_CAMARAOUT_M3>;
+		dvdd-supply = <&vcc_cam0>;
+		orientation = <2>; /* External */
+		ovdd-supply = <&vcc_cam0>;
+		pinctrl-names = "default";
+		pinctrl-0 = <&cam0_rstn &mipim0_camera3_clk>;
+		reset-gpios = <&gpio4 RK_PA0 GPIO_ACTIVE_LOW>;
+
+		port {
+			imx415_output: endpoint {
+				data-lanes = <1 2 3 4>;
+				link-frequencies = /bits/ 64 <445500000>;
+				remote-endpoint = <&csi2_input>;
+			};
+		};
+	};
+};
+
+&pinctrl {
+	cam0 {
+		cam0_power0_en: cam0-power0-en-pinctrl {
+			rockchip,pins = <1 RK_PB0 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+
+		cam0_rstn: cam0-rstn-pinctrl {
+			rockchip,pins = <4 RK_PA0 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+	};
+};
+
+&csi2 {
+	status = "okay";
+};
+
+&csi2_in {
+	csi2_input: endpoint {
+		data-lanes = <1 2 3 4>;
+		link-frequencies = /bits/ 64 <445500000>;
+		remote-endpoint = <&imx415_output>;
+	};
+};
+
+&csi_dphy0 {
+	status = "okay";
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

