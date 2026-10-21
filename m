From: Cunhao Lu <1579567540@qq.com>
Date: Thu, 22 Oct 2026 00:11:23 +0800
Subject: [PATCH 26/27] arm64: dts: rockchip: Add RK3572 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-add-board-ok3572-c-v1-26-0b0fd85a31ee@qq.com>
References: <20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com>
In-Reply-To: <20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com>
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Elaine Zhang <zhangqing@rock-chips.com>, Lee Jones <lee@kernel.org>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Richard Cochran <richardcochran@gmail.com>, Ulf Hansson <ulfh@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Jisheng Zhang <jszhang@kernel.org>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 David Wu <david.wu@rock-chips.com>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, 
 Shawn Lin <shawn.lin@rock-chips.com>
Cc: Cunhao Lu <1579567540@qq.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 mfd@lists.linux.dev, linux-gpio@vger.kernel.org, netdev@vger.kernel.org, 
 linux-pm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-serial@vger.kernel.org, linux-mmc@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, linux-phy@lists.infradead.org, 
 linux-usb@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792599138; l=130722;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=cY+mWghtJUNgwsbDpp/amORYZrVUGeTcOGhytmmRGa0=;
 b=HFKQUKPeUD3EjLri7TYoZZOgpJLLcrq+IDYO+h4T7nZTGEB/A6P8oB5pBVJs1K/0iXDNcmrZB
 p5GQ7M6jfrkD5qVqcBvuct0cLttI/88RhJ/i/UnAL5x3wNkKTTdjUti
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the RK3572 CPU, SCMI, thermal, pinctrl, and boot-peripheral
blocks.

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
 arch/arm64/boot/dts/rockchip/rk3572-opp.dtsi     |  165 +
 arch/arm64/boot/dts/rockchip/rk3572-pinctrl.dtsi | 3935 ++++++++++++++++++++++
 arch/arm64/boot/dts/rockchip/rk3572.dtsi         | 1325 ++++++++
 3 files changed, 5425 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3572-opp.dtsi b/arch/arm64/boot/dts/rockchip/rk3572-opp.dtsi
new file mode 100644
index 000000000000..e5432fe06705
--- /dev/null
+++ b/arch/arm64/boot/dts/rockchip/rk3572-opp.dtsi
@@ -0,0 +1,165 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
+/*
+ * Copyright (c) 2025 Rockchip Electronics Co., Ltd.
+ */
+
+/ {
+	cluster0_opp_table: opp-table-cluster0 {
+		compatible = "operating-points-v2";
+		opp-shared;
+
+		opp-600000000 {
+			clock-latency-ns = <40000>;
+			opp-hz = /bits/ 64 <600000000>;
+			opp-microvolt = <850000 850000 950000>;
+		};
+
+		opp-816000000 {
+			clock-latency-ns = <40000>;
+			opp-hz = /bits/ 64 <816000000>;
+			opp-microvolt = <850000 850000 950000>;
+		};
+
+		opp-1008000000 {
+			clock-latency-ns = <40000>;
+			opp-hz = /bits/ 64 <1008000000>;
+			opp-microvolt = <850000 850000 950000>;
+		};
+
+		opp-1200000000 {
+			clock-latency-ns = <40000>;
+			opp-hz = /bits/ 64 <1200000000>;
+			opp-microvolt = <850000 850000 950000>;
+		};
+	};
+
+	cluster1_opp_table: opp-table-cluster1 {
+		compatible = "operating-points-v2";
+		opp-shared;
+
+		opp-600000000 {
+			clock-latency-ns = <40000>;
+			opp-hz = /bits/ 64 <600000000>;
+			opp-microvolt = <850000 850000 950000>;
+		};
+
+		opp-816000000 {
+			clock-latency-ns = <40000>;
+			opp-hz = /bits/ 64 <816000000>;
+			opp-microvolt = <850000 850000 950000>;
+		};
+
+		opp-1008000000 {
+			clock-latency-ns = <40000>;
+			opp-hz = /bits/ 64 <1008000000>;
+			opp-microvolt = <850000 850000 950000>;
+		};
+
+		opp-1200000000 {
+			clock-latency-ns = <40000>;
+			opp-hz = /bits/ 64 <1200000000>;
+			opp-microvolt = <850000 850000 950000>;
+		};
+	};
+
+	cluster2_opp_table: opp-table-cluster2 {
+		compatible = "operating-points-v2";
+		opp-shared;
+
+		opp-600000000 {
+			clock-latency-ns = <40000>;
+			opp-hz = /bits/ 64 <600000000>;
+			opp-microvolt = <850000 850000 950000>;
+		};
+
+		opp-816000000 {
+			clock-latency-ns = <40000>;
+			opp-hz = /bits/ 64 <816000000>;
+			opp-microvolt = <850000 850000 950000>;
+		};
+
+		opp-1008000000 {
+			clock-latency-ns = <40000>;
+			opp-hz = /bits/ 64 <1008000000>;
+			opp-microvolt = <850000 850000 950000>;
+		};
+
+		opp-1200000000 {
+			clock-latency-ns = <40000>;
+			opp-hz = /bits/ 64 <1200000000>;
+			opp-microvolt = <850000 850000 950000>;
+		};
+	};
+};
+
+&cpu_b0 {
+	#cooling-cells = <2>;
+	operating-points-v2 = <&cluster2_opp_table>;
+};
+
+&cpu_b1 {
+	operating-points-v2 = <&cluster2_opp_table>;
+};
+
+&cpu_l0 {
+	#cooling-cells = <2>;
+	operating-points-v2 = <&cluster0_opp_table>;
+};
+
+&cpu_l1 {
+	operating-points-v2 = <&cluster0_opp_table>;
+};
+
+&cpu_l2 {
+	operating-points-v2 = <&cluster0_opp_table>;
+};
+
+&cpu_l3 {
+	operating-points-v2 = <&cluster0_opp_table>;
+};
+
+&cpu_l4 {
+	#cooling-cells = <2>;
+	operating-points-v2 = <&cluster1_opp_table>;
+};
+
+&cpu_l5 {
+	operating-points-v2 = <&cluster1_opp_table>;
+};
+
+&big_core_thermal {
+	cooling-maps {
+		map0 {
+			cooling-device =
+				<&cpu_b0 THERMAL_NO_LIMIT THERMAL_NO_LIMIT>;
+			trip = <&big_core_hot>;
+		};
+	};
+
+	trips {
+		big_core_hot: big-core-hot {
+			hysteresis = <2000>;
+			temperature = <85000>;
+			type = "passive";
+		};
+	};
+};
+
+&little_core_thermal {
+	cooling-maps {
+		map0 {
+			cooling-device =
+				<&cpu_l0 THERMAL_NO_LIMIT THERMAL_NO_LIMIT>,
+				<&cpu_l4 THERMAL_NO_LIMIT THERMAL_NO_LIMIT>;
+			trip = <&little_core_hot>;
+		};
+	};
+
+	trips {
+		little_core_hot: little-core-hot {
+			hysteresis = <2000>;
+			temperature = <85000>;
+			type = "passive";
+		};
+	};
+};
diff --git a/arch/arm64/boot/dts/rockchip/rk3572-pinctrl.dtsi b/arch/arm64/boot/dts/rockchip/rk3572-pinctrl.dtsi
new file mode 100644
index 000000000000..8440feea419b
--- /dev/null
+++ b/arch/arm64/boot/dts/rockchip/rk3572-pinctrl.dtsi
@@ -0,0 +1,3935 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
+/*
+ * Copyright (c) 2025 Rockchip Electronics Co., Ltd.
+ */
+
+#include <dt-bindings/pinctrl/rockchip.h>
+#include "rockchip-pinconf.dtsi"
+
+&pinctrl {
+	aupll_clk {
+		/omit-if-no-ref/
+		aupll_clk_pins: aupll-clk-pins {
+			rockchip,pins =
+				<0 RK_PA0 3 &pcfg_pull_none>;
+		};
+	};
+
+	cam_clk0 {
+		/omit-if-no-ref/
+		cam_clk0m0_clk0_pins: cam-clk0m0-clk0-pins {
+			rockchip,pins =
+				<3 RK_PD7 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		cam_clk0m1_clk0_pins: cam-clk0m1-clk0-pins {
+			rockchip,pins =
+				<2 RK_PD4 3 &pcfg_pull_none>;
+		};
+	};
+
+	cam_clk1 {
+		/omit-if-no-ref/
+		cam_clk1m0_clk1_pins: cam-clk1m0-clk1-pins {
+			rockchip,pins =
+				<4 RK_PA0 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		cam_clk1m1_clk1_pins: cam-clk1m1-clk1-pins {
+			rockchip,pins =
+				<2 RK_PD5 3 &pcfg_pull_none>;
+		};
+	};
+
+	cam_clk2 {
+		/omit-if-no-ref/
+		cam_clk2m0_clk2_pins: cam-clk2m0-clk2-pins {
+			rockchip,pins =
+				<4 RK_PA1 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		cam_clk2m1_clk2_pins: cam-clk2m1-clk2-pins {
+			rockchip,pins =
+				<2 RK_PD6 3 &pcfg_pull_none>;
+		};
+	};
+
+	can0 {
+		/omit-if-no-ref/
+		can0m0_pins: can0m0-pins {
+			rockchip,pins =
+				<2 RK_PA2 13 &pcfg_pull_none>,
+				<2 RK_PA3 13 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		can0m1_pins: can0m1-pins {
+			rockchip,pins =
+				<4 RK_PB3 14 &pcfg_pull_none>,
+				<4 RK_PB2 14 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		can0m2_pins: can0m2-pins {
+			rockchip,pins =
+				<2 RK_PB3 13 &pcfg_pull_none>,
+				<2 RK_PB1 13 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		can0m3_pins: can0m3-pins {
+			rockchip,pins =
+				<3 RK_PC1 13 &pcfg_pull_none>,
+				<3 RK_PC4 13 &pcfg_pull_none>;
+		};
+	};
+
+	can1 {
+		/omit-if-no-ref/
+		can1m0_pins: can1m0-pins {
+			rockchip,pins =
+				<2 RK_PA0 13 &pcfg_pull_none>,
+				<2 RK_PA1 13 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		can1m1_pins: can1m1-pins {
+			rockchip,pins =
+				<4 RK_PB7 13 &pcfg_pull_none>,
+				<4 RK_PB6 13 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		can1m2_pins: can1m2-pins {
+			rockchip,pins =
+				<2 RK_PC2 13 &pcfg_pull_none>,
+				<2 RK_PC3 13 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		can1m3_pins: can1m3-pins {
+			rockchip,pins =
+				<2 RK_PD7 13 &pcfg_pull_none>,
+				<2 RK_PD6 13 &pcfg_pull_none>;
+		};
+	};
+
+	can2 {
+		/omit-if-no-ref/
+		can2m0_pins: can2m0-pins {
+			rockchip,pins =
+				<2 RK_PA4 13 &pcfg_pull_none>,
+				<2 RK_PA5 13 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		can2m1_pins: can2m1-pins {
+			rockchip,pins =
+				<1 RK_PC2 13 &pcfg_pull_none>,
+				<1 RK_PC3 13 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		can2m2_pins: can2m2-pins {
+			rockchip,pins =
+				<3 RK_PB7 13 &pcfg_pull_none>,
+				<3 RK_PC0 13 &pcfg_pull_none>;
+		};
+	};
+
+	can3 {
+		/omit-if-no-ref/
+		can3m0_pins: can3m0-pins {
+			rockchip,pins =
+				<1 RK_PD6 13 &pcfg_pull_none>,
+				<1 RK_PD5 13 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		can3m1_pins: can3m1-pins {
+			rockchip,pins =
+				<2 RK_PD5 13 &pcfg_pull_none>,
+				<2 RK_PD4 13 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		can3m2_pins: can3m2-pins {
+			rockchip,pins =
+				<3 RK_PC2 13 &pcfg_pull_none>,
+				<3 RK_PC3 13 &pcfg_pull_none>;
+		};
+	};
+
+	clk0_32k {
+		/omit-if-no-ref/
+		clk0_32k_pins: clk0-32k-pins {
+			rockchip,pins =
+				<0 RK_PA2 10 &pcfg_pull_none>;
+		};
+	};
+
+	clk1_32k {
+		/omit-if-no-ref/
+		clk1_32k_pins: clk1-32k-pins {
+			rockchip,pins =
+				<1 RK_PD5 7 &pcfg_pull_none>;
+		};
+	};
+
+	clk_32k {
+		/omit-if-no-ref/
+		clk_32k_pins: clk-32k-pins {
+			rockchip,pins =
+				<0 RK_PA2 9 &pcfg_pull_none>;
+		};
+	};
+
+	cpubig {
+		/omit-if-no-ref/
+		cpubig_pins: cpubig-pins {
+			rockchip,pins =
+				<0 RK_PD2 13 &pcfg_pull_none>;
+		};
+	};
+
+	cpulit {
+		/omit-if-no-ref/
+		cpulit_pins: cpulit-pins {
+			rockchip,pins =
+				<0 RK_PC0 13 &pcfg_pull_none>;
+		};
+	};
+
+	dsm_aud {
+		/omit-if-no-ref/
+		dsm_audm0_ln_pins: dsm-audm0-ln-pins {
+			rockchip,pins =
+				<2 RK_PA1 3 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		dsm_audm0_lp_pins: dsm-audm0-lp-pins {
+			rockchip,pins =
+				<2 RK_PA0 3 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		dsm_audm0_rn_pins: dsm-audm0-rn-pins {
+			rockchip,pins =
+				<2 RK_PA3 3 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		dsm_audm0_rp_pins: dsm-audm0-rp-pins {
+			rockchip,pins =
+				<2 RK_PA2 3 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		dsm_audm1_ln_pins: dsm-audm1-ln-pins {
+			rockchip,pins =
+				<4 RK_PB1 3 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		dsm_audm1_lp_pins: dsm-audm1-lp-pins {
+			rockchip,pins =
+				<4 RK_PB0 3 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		dsm_audm1_rn_pins: dsm-audm1-rn-pins {
+			rockchip,pins =
+				<4 RK_PB3 3 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		dsm_audm1_rp_pins: dsm-audm1-rp-pins {
+			rockchip,pins =
+				<4 RK_PB2 3 &pcfg_pull_none>;
+		};
+	};
+
+	dsmc {
+		/omit-if-no-ref/
+		dsmc_bus16_pins: dsmc-bus16-pins {
+			rockchip,pins =
+				<3 RK_PD6 2 &pcfg_pull_none>,
+				<3 RK_PD5 2 &pcfg_pull_none>,
+				<3 RK_PD3 2 &pcfg_pull_none>,
+				<3 RK_PB0 2 &pcfg_pull_none>,
+				<3 RK_PD1 2 &pcfg_pull_none>,
+				<3 RK_PD2 2 &pcfg_pull_none>,
+				<3 RK_PD4 2 &pcfg_pull_none>,
+				<3 RK_PD0 2 &pcfg_pull_none>,
+				<3 RK_PC7 2 &pcfg_pull_none>,
+				<3 RK_PC6 2 &pcfg_pull_none>,
+				<3 RK_PC5 2 &pcfg_pull_none>,
+				<3 RK_PC4 2 &pcfg_pull_none>,
+				<3 RK_PC1 2 &pcfg_pull_none>,
+				<3 RK_PC0 2 &pcfg_pull_none>,
+				<3 RK_PB5 2 &pcfg_pull_none>,
+				<3 RK_PB4 2 &pcfg_pull_none>,
+				<3 RK_PB3 2 &pcfg_pull_none>,
+				<3 RK_PB2 2 &pcfg_pull_none>,
+				<3 RK_PB1 2 &pcfg_pull_none>,
+				<3 RK_PA7 2 &pcfg_pull_none>,
+				<3 RK_PA6 2 &pcfg_pull_none>,
+				<3 RK_PA5 2 &pcfg_pull_none>,
+				<3 RK_PB7 2 &pcfg_pull_none>,
+				<3 RK_PB6 2 &pcfg_pull_none>,
+				<4 RK_PA0 2 &pcfg_pull_none>,
+				<3 RK_PC2 2 &pcfg_pull_none>,
+				<4 RK_PA1 2 &pcfg_pull_none>,
+				<3 RK_PC3 2 &pcfg_pull_none>,
+				<3 RK_PA4 2 &pcfg_pull_none>,
+				<3 RK_PD7 2 &pcfg_pull_none>;
+		};
+	};
+
+	edp_tx {
+		/omit-if-no-ref/
+		edp_txm0_pins: edp-txm0-pins {
+			rockchip,pins =
+				<4 RK_PB1 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		edp_txm1_pins: edp-txm1-pins {
+			rockchip,pins =
+				<0 RK_PB6 10 &pcfg_pull_none>;
+		};
+	};
+
+	emmc {
+		/omit-if-no-ref/
+		emmc_rstnout_pins: emmc-rstnout-pins {
+			rockchip,pins =
+				<1 RK_PB3 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		emmc_bus8_pins: emmc-bus8-pins {
+			rockchip,pins =
+				<1 RK_PA0 1 &pcfg_pull_up_drv_level_2>,
+				<1 RK_PA1 1 &pcfg_pull_up_drv_level_2>,
+				<1 RK_PA2 1 &pcfg_pull_up_drv_level_2>,
+				<1 RK_PA3 1 &pcfg_pull_up_drv_level_2>,
+				<1 RK_PA4 1 &pcfg_pull_up_drv_level_2>,
+				<1 RK_PA5 1 &pcfg_pull_up_drv_level_2>,
+				<1 RK_PA6 1 &pcfg_pull_up_drv_level_2>,
+				<1 RK_PA7 1 &pcfg_pull_up_drv_level_2>;
+		};
+
+		/omit-if-no-ref/
+		emmc_clk_pins: emmc-clk-pins {
+			rockchip,pins =
+				<1 RK_PB1 1 &pcfg_pull_up_drv_level_2>;
+		};
+
+		/omit-if-no-ref/
+		emmc_cmd_pins: emmc-cmd-pins {
+			rockchip,pins =
+				<1 RK_PB0 1 &pcfg_pull_up_drv_level_2>;
+		};
+
+		/omit-if-no-ref/
+		emmc_strb_pins: emmc-strb-pins {
+			rockchip,pins =
+				<1 RK_PB2 1 &pcfg_pull_none>;
+		};
+	};
+
+	eth0 {
+		/omit-if-no-ref/
+		eth0_miim_pins: eth0-miim-pins {
+			rockchip,pins =
+				<2 RK_PC6 1 &pcfg_pull_none>,
+				<2 RK_PC5 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth0_rx_bus2_pins: eth0-rx-bus2-pins {
+			rockchip,pins =
+				<2 RK_PC7 1 &pcfg_pull_none>,
+				<2 RK_PD2 1 &pcfg_pull_none>,
+				<2 RK_PD1 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth0_tx_bus2_pins: eth0-tx-bus2-pins {
+			rockchip,pins =
+				<2 RK_PD3 1 &pcfg_pull_none>,
+				<2 RK_PD4 1 &pcfg_pull_none>,
+				<2 RK_PD5 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth0_rgmii_clk_pins: eth0-rgmii-clk-pins {
+			rockchip,pins =
+				<2 RK_PD7 1 &pcfg_pull_none>,
+				<2 RK_PD6 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth0_rgmii_bus_pins: eth0-rgmii-bus-pins {
+			rockchip,pins =
+				<2 RK_PC1 1 &pcfg_pull_none>,
+				<2 RK_PC0 1 &pcfg_pull_none>,
+				<2 RK_PC2 1 &pcfg_pull_none>,
+				<2 RK_PC3 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth0_mclk_pins: eth0-mclk-pins {
+			rockchip,pins =
+				<2 RK_PD0 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth0_ppsclk_pins: eth0-ppsclk-pins {
+			rockchip,pins =
+				<2 RK_PB6 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth0_ppstrig_pins: eth0-ppstrig-pins {
+			rockchip,pins =
+				<2 RK_PB7 1 &pcfg_pull_none>;
+		};
+	};
+
+	eth0_ptp {
+		/omit-if-no-ref/
+		eth0_ptp_refclk_pins: eth0-ptp-refclk-pins {
+			rockchip,pins =
+				<2 RK_PB5 1 &pcfg_pull_none>;
+		};
+	};
+
+	eth1 {
+		/omit-if-no-ref/
+		eth1m0_miim_pins: eth1m0-miim-pins {
+			rockchip,pins =
+				<3 RK_PA6 1 &pcfg_pull_none>,
+				<3 RK_PA5 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth1m0_rx_bus2_pins: eth1m0-rx-bus2-pins {
+			rockchip,pins =
+				<3 RK_PA7 1 &pcfg_pull_none>,
+				<3 RK_PB2 1 &pcfg_pull_none>,
+				<3 RK_PB1 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth1m0_tx_bus2_pins: eth1m0-tx-bus2-pins {
+			rockchip,pins =
+				<3 RK_PB3 1 &pcfg_pull_none>,
+				<3 RK_PB5 1 &pcfg_pull_none>,
+				<3 RK_PB4 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth1m0_rgmii_clk_pins: eth1m0-rgmii-clk-pins {
+			rockchip,pins =
+				<3 RK_PD1 1 &pcfg_pull_none>,
+				<3 RK_PB6 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth1m0_rgmii_bus_pins: eth1m0-rgmii-bus-pins {
+			rockchip,pins =
+				<3 RK_PD3 1 &pcfg_pull_none>,
+				<3 RK_PD2 1 &pcfg_pull_none>,
+				<3 RK_PC3 1 &pcfg_pull_none>,
+				<3 RK_PC2 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth1m0_mclk_pins: eth1m0-mclk-pins {
+			rockchip,pins =
+				<3 RK_PB0 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth1m0_ppsclk_pins: eth1m0-ppsclk-pins {
+			rockchip,pins =
+				<3 RK_PC0 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth1m0_ppstrig_pins: eth1m0-ppstrig-pins {
+			rockchip,pins =
+				<3 RK_PB7 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth1m1_miim_pins: eth1m1-miim-pins {
+			rockchip,pins =
+				<1 RK_PD2 1 &pcfg_pull_none>,
+				<1 RK_PD3 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth1m1_rx_bus2_pins: eth1m1-rx-bus2-pins {
+			rockchip,pins =
+				<1 RK_PD1 1 &pcfg_pull_none>,
+				<1 RK_PC7 1 &pcfg_pull_none>,
+				<1 RK_PD0 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth1m1_tx_bus2_pins: eth1m1-tx-bus2-pins {
+			rockchip,pins =
+				<1 RK_PC6 1 &pcfg_pull_none>,
+				<1 RK_PC4 1 &pcfg_pull_none>,
+				<1 RK_PC5 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth1m1_rgmii_clk_pins: eth1m1-rgmii-clk-pins {
+			rockchip,pins =
+				<1 RK_PB6 1 &pcfg_pull_none>,
+				<1 RK_PC1 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth1m1_rgmii_bus_pins: eth1m1-rgmii-bus-pins {
+			rockchip,pins =
+				<1 RK_PB4 1 &pcfg_pull_none>,
+				<1 RK_PB5 1 &pcfg_pull_none>,
+				<1 RK_PB7 1 &pcfg_pull_none>,
+				<1 RK_PC0 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth1m1_mclk_pins: eth1m1-mclk-pins {
+			rockchip,pins =
+				<1 RK_PD4 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth1m1_ppsclk_pins: eth1m1-ppsclk-pins {
+			rockchip,pins =
+				<1 RK_PC2 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth1m1_ppstrig_pins: eth1m1-ppstrig-pins {
+			rockchip,pins =
+				<1 RK_PC3 1 &pcfg_pull_none>;
+		};
+	};
+
+	eth1_ptp {
+		/omit-if-no-ref/
+		eth1m0_ptp_refclk_pins: eth1m0-ptp-refclk-pins {
+			rockchip,pins =
+				<3 RK_PC1 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		eth1m1_ptp_refclk_pins: eth1m1-ptp-refclk-pins {
+			rockchip,pins =
+				<1 RK_PD6 1 &pcfg_pull_none>;
+		};
+	};
+
+	eth_clk0_25m {
+		/omit-if-no-ref/
+		eth_clk0_25m_out_pins: eth-clk0-25m-out-pins {
+			rockchip,pins =
+				<2 RK_PC4 1 &pcfg_pull_none>;
+		};
+	};
+
+	eth_clk1_25m {
+		/omit-if-no-ref/
+		ethm0_clk1_25m_out_pins: ethm0-clk1-25m-out-pins {
+			rockchip,pins =
+				<3 RK_PA4 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		ethm1_clk1_25m_out_pins: ethm1-clk1-25m-out-pins {
+			rockchip,pins =
+				<1 RK_PD5 1 &pcfg_pull_none>;
+		};
+	};
+
+	fspi0 {
+		/omit-if-no-ref/
+		fspi0_pins: fspi0-pins {
+			rockchip,pins =
+				<1 RK_PB1 2 &pcfg_pull_none>,
+				<1 RK_PA0 2 &pcfg_pull_none>,
+				<1 RK_PA1 2 &pcfg_pull_none>,
+				<1 RK_PA2 2 &pcfg_pull_none>,
+				<1 RK_PA3 2 &pcfg_pull_none>,
+				<1 RK_PA4 2 &pcfg_pull_none>,
+				<1 RK_PA5 2 &pcfg_pull_none>,
+				<1 RK_PA6 2 &pcfg_pull_none>,
+				<1 RK_PA7 2 &pcfg_pull_none>,
+				<1 RK_PB2 2 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		fspi0_csn0_pins: fspi0-csn0-pins {
+			rockchip,pins =
+				<1 RK_PB3 2 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		fspi0_csn1_pins: fspi0-csn1-pins {
+			rockchip,pins =
+				<1 RK_PB0 2 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		fspi0_rst_pins: fspi0-rst-pins {
+			rockchip,pins =
+				<1 RK_PB0 3 &pcfg_pull_none>;
+		};
+	};
+
+	fspi1 {
+		/omit-if-no-ref/
+		fspi1m0_pins: fspi1m0-pins {
+			rockchip,pins =
+				<2 RK_PA5 1 &pcfg_pull_none>,
+				<2 RK_PA0 1 &pcfg_pull_none>,
+				<2 RK_PA1 1 &pcfg_pull_none>,
+				<2 RK_PA2 1 &pcfg_pull_none>,
+				<2 RK_PA3 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		fspi1m0_csn0_pins: fspi1m0-csn0-pins {
+			rockchip,pins =
+				<2 RK_PA4 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		fspi1m1_pins: fspi1m1-pins {
+			rockchip,pins =
+				<2 RK_PD5 2 &pcfg_pull_none>,
+				<2 RK_PD3 2 &pcfg_pull_none>,
+				<2 RK_PD2 2 &pcfg_pull_none>,
+				<2 RK_PD1 2 &pcfg_pull_none>,
+				<2 RK_PD0 2 &pcfg_pull_none>,
+				<2 RK_PC7 2 &pcfg_pull_none>,
+				<2 RK_PC6 2 &pcfg_pull_none>,
+				<2 RK_PC5 2 &pcfg_pull_none>,
+				<2 RK_PC4 2 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		fspi1m1_csn0_pins: fspi1m1-csn0-pins {
+			rockchip,pins =
+				<2 RK_PD6 2 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		fspi1m1_csn1_pins: fspi1m1-csn1-pins {
+			rockchip,pins =
+				<2 RK_PD7 2 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		fspi1_pins: fspi1-pins {
+			rockchip,pins =
+				<2 RK_PD4 2 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		fspi1_rst_pins: fspi1-rst-pins {
+			rockchip,pins =
+				<2 RK_PD7 3 &pcfg_pull_none>;
+		};
+	};
+
+	gpu {
+		/omit-if-no-ref/
+		gpu_pins: gpu-pins {
+			rockchip,pins =
+				<0 RK_PD3 13 &pcfg_pull_none>;
+		};
+	};
+
+	hdmi_tx {
+		/omit-if-no-ref/
+		hdmi_txm0_cec_pins: hdmi-txm0-cec-pins {
+			rockchip,pins =
+				<4 RK_PB0 13 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		hdmi_txm0_hpdin_pins: hdmi-txm0-hpdin-pins {
+			rockchip,pins =
+				<4 RK_PB1 13 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		hdmi_txm0_ddc_pins: hdmi-txm0-ddc-pins {
+			rockchip,pins =
+				<4 RK_PB2 13 &pcfg_pull_none>,
+				<4 RK_PB3 13 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		hdmi_txm1_cec_pins: hdmi-txm1-cec-pins {
+			rockchip,pins =
+				<0 RK_PC3 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		hdmi_txm1_hpdin_pins: hdmi-txm1-hpdin-pins {
+			rockchip,pins =
+				<0 RK_PB6 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		hdmi_txm1_ddc_pins: hdmi-txm1-ddc-pins {
+			rockchip,pins =
+				<1 RK_PC6 14 &pcfg_pull_none>,
+				<1 RK_PC7 14 &pcfg_pull_none>;
+		};
+	};
+
+	i2c0 {
+		/omit-if-no-ref/
+		i2c0m0_xfer_pins: i2c0m0-xfer-pins {
+			rockchip,pins =
+				<0 RK_PB0 11 &pcfg_pull_none_smt>,
+				<0 RK_PB1 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c0m1_xfer_pins: i2c0m1-xfer-pins {
+			rockchip,pins =
+				<0 RK_PC1 11 &pcfg_pull_none_smt>,
+				<0 RK_PC2 11 &pcfg_pull_none_smt>;
+		};
+	};
+
+	i2c1 {
+		/omit-if-no-ref/
+		i2c1m0_xfer_pins: i2c1m0-xfer-pins {
+			rockchip,pins =
+				<0 RK_PB2 11 &pcfg_pull_none_smt>,
+				<0 RK_PB3 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c1m1_xfer_pins: i2c1m1-xfer-pins {
+			rockchip,pins =
+				<0 RK_PB4 11 &pcfg_pull_none_smt>,
+				<0 RK_PB5 11 &pcfg_pull_none_smt>;
+		};
+	};
+
+	i2c2 {
+		/omit-if-no-ref/
+		i2c2m0_xfer_pins: i2c2m0-xfer-pins {
+			rockchip,pins =
+				<0 RK_PB7 11 &pcfg_pull_none_smt>,
+				<0 RK_PC0 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c2m1_xfer_pins: i2c2m1-xfer-pins {
+			rockchip,pins =
+				<1 RK_PA0 11 &pcfg_pull_none_smt>,
+				<1 RK_PA1 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c2m2_xfer_pins: i2c2m2-xfer-pins {
+			rockchip,pins =
+				<2 RK_PB1 11 &pcfg_pull_none_smt>,
+				<2 RK_PB3 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c2m3_xfer_pins: i2c2m3-xfer-pins {
+			rockchip,pins =
+				<4 RK_PB2 11 &pcfg_pull_none_smt>,
+				<4 RK_PB3 11 &pcfg_pull_none_smt>;
+		};
+	};
+
+	i2c3 {
+		/omit-if-no-ref/
+		i2c3m0_xfer_pins: i2c3m0-xfer-pins {
+			rockchip,pins =
+				<2 RK_PC3 11 &pcfg_pull_none_smt>,
+				<2 RK_PC2 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c3m1_xfer_pins: i2c3m1-xfer-pins {
+			rockchip,pins =
+				<0 RK_PC6 11 &pcfg_pull_none_smt>,
+				<0 RK_PC7 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c3m2_xfer_pins: i2c3m2-xfer-pins {
+			rockchip,pins =
+				<3 RK_PD4 11 &pcfg_pull_none_smt>,
+				<3 RK_PD5 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c3m3_xfer_pins: i2c3m3-xfer-pins {
+			rockchip,pins =
+				<4 RK_PB0 11 &pcfg_pull_none_smt>,
+				<4 RK_PB1 11 &pcfg_pull_none_smt>;
+		};
+	};
+
+	i2c4 {
+		/omit-if-no-ref/
+		i2c4m0_xfer_pins: i2c4m0-xfer-pins {
+			rockchip,pins =
+				<0 RK_PD2 11 &pcfg_pull_none_smt>,
+				<0 RK_PD3 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c4m1_xfer_pins: i2c4m1-xfer-pins {
+			rockchip,pins =
+				<2 RK_PB2 11 &pcfg_pull_none_smt>,
+				<2 RK_PB4 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c4m2_xfer_pins: i2c4m2-xfer-pins {
+			rockchip,pins =
+				<2 RK_PD6 11 &pcfg_pull_none_smt>,
+				<2 RK_PD7 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c4m3_xfer_pins: i2c4m3-xfer-pins {
+			rockchip,pins =
+				<3 RK_PC0 11 &pcfg_pull_none_smt>,
+				<3 RK_PB7 11 &pcfg_pull_none_smt>;
+		};
+	};
+
+	i2c5 {
+		/omit-if-no-ref/
+		i2c5m0_xfer_pins: i2c5m0-xfer-pins {
+			rockchip,pins =
+				<2 RK_PA5 11 &pcfg_pull_none_smt>,
+				<2 RK_PA4 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c5m1_xfer_pins: i2c5m1-xfer-pins {
+			rockchip,pins =
+				<1 RK_PD4 11 &pcfg_pull_none_smt>,
+				<1 RK_PD5 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c5m2_xfer_pins: i2c5m2-xfer-pins {
+			rockchip,pins =
+				<2 RK_PD4 11 &pcfg_pull_none_smt>,
+				<2 RK_PD5 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c5m3_xfer_pins: i2c5m3-xfer-pins {
+			rockchip,pins =
+				<3 RK_PC4 11 &pcfg_pull_none_smt>,
+				<3 RK_PC1 11 &pcfg_pull_none_smt>;
+		};
+	};
+
+	i2c6 {
+		/omit-if-no-ref/
+		i2c6m0_xfer_pins: i2c6m0-xfer-pins {
+			rockchip,pins =
+				<0 RK_PA2 11 &pcfg_pull_none_smt>,
+				<0 RK_PA5 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c6m1_xfer_pins: i2c6m1-xfer-pins {
+			rockchip,pins =
+				<1 RK_PC2 11 &pcfg_pull_none_smt>,
+				<1 RK_PC3 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c6m2_xfer_pins: i2c6m2-xfer-pins {
+			rockchip,pins =
+				<2 RK_PD2 11 &pcfg_pull_none_smt>,
+				<2 RK_PD3 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c6m3_xfer_pins: i2c6m3-xfer-pins {
+			rockchip,pins =
+				<4 RK_PB6 11 &pcfg_pull_none_smt>,
+				<4 RK_PB7 11 &pcfg_pull_none_smt>;
+		};
+	};
+
+	i2c7 {
+		/omit-if-no-ref/
+		i2c7m0_xfer_pins: i2c7m0-xfer-pins {
+			rockchip,pins =
+				<1 RK_PB0 11 &pcfg_pull_none_smt>,
+				<1 RK_PB3 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c7m1_xfer_pins: i2c7m1-xfer-pins {
+			rockchip,pins =
+				<2 RK_PD0 11 &pcfg_pull_none_smt>,
+				<2 RK_PD1 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c7m2_xfer_pins: i2c7m2-xfer-pins {
+			rockchip,pins =
+				<4 RK_PA0 11 &pcfg_pull_none_smt>,
+				<4 RK_PA1 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c7m3_xfer_pins: i2c7m3-xfer-pins {
+			rockchip,pins =
+				<4 RK_PB4 11 &pcfg_pull_none_smt>,
+				<4 RK_PB5 11 &pcfg_pull_none_smt>;
+		};
+	};
+
+	i2c8 {
+		/omit-if-no-ref/
+		i2c8m0_xfer_pins: i2c8m0-xfer-pins {
+			rockchip,pins =
+				<2 RK_PA0 11 &pcfg_pull_none_smt>,
+				<2 RK_PA1 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c8m1_xfer_pins: i2c8m1-xfer-pins {
+			rockchip,pins =
+				<1 RK_PC6 11 &pcfg_pull_none_smt>,
+				<1 RK_PC7 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c8m2_xfer_pins: i2c8m2-xfer-pins {
+			rockchip,pins =
+				<2 RK_PC4 11 &pcfg_pull_none_smt>,
+				<2 RK_PC5 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c8m3_xfer_pins: i2c8m3-xfer-pins {
+			rockchip,pins =
+				<3 RK_PB3 11 &pcfg_pull_none_smt>,
+				<3 RK_PB2 11 &pcfg_pull_none_smt>;
+		};
+	};
+
+	i2c9 {
+		/omit-if-no-ref/
+		i2c9m0_xfer_pins: i2c9m0-xfer-pins {
+			rockchip,pins =
+				<1 RK_PA5 11 &pcfg_pull_none_smt>,
+				<1 RK_PA6 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c9m1_xfer_pins: i2c9m1-xfer-pins {
+			rockchip,pins =
+				<1 RK_PB5 11 &pcfg_pull_none_smt>,
+				<1 RK_PB4 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c9m2_xfer_pins: i2c9m2-xfer-pins {
+			rockchip,pins =
+				<2 RK_PC7 11 &pcfg_pull_none_smt>,
+				<2 RK_PC6 11 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i2c9m3_xfer_pins: i2c9m3-xfer-pins {
+			rockchip,pins =
+				<3 RK_PC2 11 &pcfg_pull_none_smt>,
+				<3 RK_PC3 11 &pcfg_pull_none_smt>;
+		};
+	};
+
+	i3c0 {
+		/omit-if-no-ref/
+		i3c0m0_xfer_pins: i3c0m0-xfer-pins {
+			rockchip,pins =
+				<0 RK_PC1 12 &pcfg_pull_none_smt>,
+				<0 RK_PC2 12 &pcfg_pull_none_smt>;
+		};
+
+		/omit-if-no-ref/
+		i3c0m1_xfer_pins: i3c0m1-xfer-pins {
+			rockchip,pins =
+				<1 RK_PD2 11 &pcfg_pull_none_smt>,
+				<1 RK_PD3 11 &pcfg_pull_none_smt>;
+		};
+	};
+
+	i3c0_sda {
+		/omit-if-no-ref/
+		i3c0_sdam0_pu_pins: i3c0-sdam0-pu-pins {
+			rockchip,pins =
+				<0 RK_PC5 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		i3c0_sdam1_pu_pins: i3c0-sdam1-pu-pins {
+			rockchip,pins =
+				<1 RK_PD1 11 &pcfg_pull_none>;
+		};
+	};
+
+	isp_flash {
+		/omit-if-no-ref/
+		isp_flashm0_pins: isp-flashm0-pins {
+			rockchip,pins =
+				<2 RK_PD0 7 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		isp_flashm1_pins: isp-flashm1-pins {
+			rockchip,pins =
+				<4 RK_PB5 1 &pcfg_pull_none>;
+		};
+	};
+
+	isp_prelight {
+		/omit-if-no-ref/
+		isp_prelightm0_pins: isp-prelightm0-pins {
+			rockchip,pins =
+				<2 RK_PC7 7 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		isp_prelightm1_pins: isp-prelightm1-pins {
+			rockchip,pins =
+				<4 RK_PB4 1 &pcfg_pull_none>;
+		};
+	};
+
+	jtag {
+		/omit-if-no-ref/
+		jtagm0_pins: jtagm0-pins {
+			rockchip,pins =
+				<2 RK_PA2 11 &pcfg_pull_none>,
+				<2 RK_PA3 11 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		jtagm1_pins: jtagm1-pins {
+			rockchip,pins =
+				<0 RK_PD4 10 &pcfg_pull_none>,
+				<0 RK_PD5 10 &pcfg_pull_none>;
+		};
+	};
+
+	mipi {
+		/omit-if-no-ref/
+		mipim0_pins: mipim0-pins {
+			rockchip,pins =
+				<2 RK_PC2 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		mipim1_pins: mipim1-pins {
+			rockchip,pins =
+				<2 RK_PD6 14 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		mipim2_pins: mipim2-pins {
+			rockchip,pins =
+				<4 RK_PA0 13 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		mipim3_pins: mipim3-pins {
+			rockchip,pins =
+				<1 RK_PB3 13 &pcfg_pull_none>;
+		};
+	};
+
+	npu {
+		/omit-if-no-ref/
+		npu_pins: npu-pins {
+			rockchip,pins =
+				<0 RK_PB7 13 &pcfg_pull_none>;
+		};
+	};
+
+	pcie0 {
+		/omit-if-no-ref/
+		pcie0m0_pins: pcie0m0-pins {
+			rockchip,pins =
+				<2 RK_PD0 14 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		pcie0m1_pins: pcie0m1-pins {
+			rockchip,pins =
+				<1 RK_PB6 14 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		pcie0m2_pins: pcie0m2-pins {
+			rockchip,pins =
+				<2 RK_PC3 14 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		pcie0m3_pins: pcie0m3-pins {
+			rockchip,pins =
+				<4 RK_PB1 14 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		pcie0_buttonrstn_pins: pcie0-buttonrstn-pins {
+			rockchip,pins =
+				<1 RK_PC4 14 &pcfg_pull_none>;
+		};
+	};
+
+	pcie1 {
+		/omit-if-no-ref/
+		pcie1m0_pins: pcie1m0-pins {
+			rockchip,pins =
+				<2 RK_PD1 14 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		pcie1m1_pins: pcie1m1-pins {
+			rockchip,pins =
+				<1 RK_PB4 14 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		pcie1m2_pins: pcie1m2-pins {
+			rockchip,pins =
+				<2 RK_PB3 14 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		pcie1m3_pins: pcie1m3-pins {
+			rockchip,pins =
+				<4 RK_PB6 14 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		pcie1_buttonrstn_pins: pcie1-buttonrstn-pins {
+			rockchip,pins =
+				<1 RK_PC5 14 &pcfg_pull_none>;
+		};
+	};
+
+	pdm {
+		/omit-if-no-ref/
+		pdmm0_clk0_pins: pdmm0-clk0-pins {
+			rockchip,pins =
+				<0 RK_PC4 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm0_clk1_pins: pdmm0-clk1-pins {
+			rockchip,pins =
+				<0 RK_PC3 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm0_sdi0_pins: pdmm0-sdi0-pins {
+			rockchip,pins =
+				<0 RK_PD0 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm0_sdi1_pins: pdmm0-sdi1-pins {
+			rockchip,pins =
+				<0 RK_PD1 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm0_sdi2_pins: pdmm0-sdi2-pins {
+			rockchip,pins =
+				<0 RK_PD2 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm0_sdi3_pins: pdmm0-sdi3-pins {
+			rockchip,pins =
+				<0 RK_PD3 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm1_clk0_pins: pdmm1-clk0-pins {
+			rockchip,pins =
+				<2 RK_PB2 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm1_clk1_pins: pdmm1-clk1-pins {
+			rockchip,pins =
+				<2 RK_PB4 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm1_sdi0_pins: pdmm1-sdi0-pins {
+			rockchip,pins =
+				<2 RK_PC1 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm1_sdi1_pins: pdmm1-sdi1-pins {
+			rockchip,pins =
+				<2 RK_PC0 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm1_sdi2_pins: pdmm1-sdi2-pins {
+			rockchip,pins =
+				<2 RK_PB7 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm1_sdi3_pins: pdmm1-sdi3-pins {
+			rockchip,pins =
+				<2 RK_PB6 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm2_clk0_pins: pdmm2-clk0-pins {
+			rockchip,pins =
+				<1 RK_PC1 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm2_clk1_pins: pdmm2-clk1-pins {
+			rockchip,pins =
+				<1 RK_PD5 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm2_sdi0_pins: pdmm2-sdi0-pins {
+			rockchip,pins =
+				<1 RK_PC6 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm2_sdi1_pins: pdmm2-sdi1-pins {
+			rockchip,pins =
+				<1 RK_PC7 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm2_sdi2_pins: pdmm2-sdi2-pins {
+			rockchip,pins =
+				<1 RK_PC0 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm2_sdi3_pins: pdmm2-sdi3-pins {
+			rockchip,pins =
+				<1 RK_PD4 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm3_clk0_pins: pdmm3-clk0-pins {
+			rockchip,pins =
+				<2 RK_PC5 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm3_clk1_pins: pdmm3-clk1-pins {
+			rockchip,pins =
+				<2 RK_PC7 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm3_sdi0_pins: pdmm3-sdi0-pins {
+			rockchip,pins =
+				<2 RK_PC4 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm3_sdi1_pins: pdmm3-sdi1-pins {
+			rockchip,pins =
+				<2 RK_PC6 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm3_sdi2_pins: pdmm3-sdi2-pins {
+			rockchip,pins =
+				<2 RK_PD0 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm3_sdi3_pins: pdmm3-sdi3-pins {
+			rockchip,pins =
+				<2 RK_PD1 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm4_clk0_pins: pdmm4-clk0-pins {
+			rockchip,pins =
+				<3 RK_PB1 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm4_clk1_pins: pdmm4-clk1-pins {
+			rockchip,pins =
+				<3 RK_PA7 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm4_sdi0_pins: pdmm4-sdi0-pins {
+			rockchip,pins =
+				<3 RK_PB3 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm4_sdi1_pins: pdmm4-sdi1-pins {
+			rockchip,pins =
+				<3 RK_PB2 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm4_sdi2_pins: pdmm4-sdi2-pins {
+			rockchip,pins =
+				<3 RK_PA6 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm4_sdi3_pins: pdmm4-sdi3-pins {
+			rockchip,pins =
+				<3 RK_PA5 5 &pcfg_pull_none>;
+		};
+	};
+
+	pmic {
+		/omit-if-no-ref/
+		pmic_pins: pmic-pins {
+			rockchip,pins =
+				<0 RK_PA6 9 &pcfg_pull_none>;
+		};
+	};
+
+	pwm0 {
+		/omit-if-no-ref/
+		pwm0m0_ch0_pins: pwm0m0-ch0-pins {
+			rockchip,pins =
+				<0 RK_PC4 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm0m0_ch1_pins: pwm0m0-ch1-pins {
+			rockchip,pins =
+				<0 RK_PC3 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm0m1_ch0_pins: pwm0m1-ch0-pins {
+			rockchip,pins =
+				<1 RK_PC0 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm0m1_ch1_pins: pwm0m1-ch1-pins {
+			rockchip,pins =
+				<4 RK_PB1 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm0m2_ch0_pins: pwm0m2-ch0-pins {
+			rockchip,pins =
+				<2 RK_PD1 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm0m2_ch1_pins: pwm0m2-ch1-pins {
+			rockchip,pins =
+				<3 RK_PB6 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm0m3_ch0_pins: pwm0m3-ch0-pins {
+			rockchip,pins =
+				<3 RK_PB0 12 &pcfg_pull_none>;
+		};
+	};
+
+	pwm1 {
+		/omit-if-no-ref/
+		pwm1m0_ch0_pins: pwm1m0-ch0-pins {
+			rockchip,pins =
+				<0 RK_PB4 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m0_ch1_pins: pwm1m0-ch1-pins {
+			rockchip,pins =
+				<0 RK_PB5 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m0_ch2_pins: pwm1m0-ch2-pins {
+			rockchip,pins =
+				<0 RK_PB6 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m0_ch3_pins: pwm1m0-ch3-pins {
+			rockchip,pins =
+				<0 RK_PC0 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m0_ch4_pins: pwm1m0-ch4-pins {
+			rockchip,pins =
+				<0 RK_PB7 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m0_ch5_pins: pwm1m0-ch5-pins {
+			rockchip,pins =
+				<0 RK_PD2 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m1_ch0_pins: pwm1m1-ch0-pins {
+			rockchip,pins =
+				<1 RK_PB4 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m1_ch1_pins: pwm1m1-ch1-pins {
+			rockchip,pins =
+				<1 RK_PB5 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m1_ch2_pins: pwm1m1-ch2-pins {
+			rockchip,pins =
+				<1 RK_PD6 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m1_ch3_pins: pwm1m1-ch3-pins {
+			rockchip,pins =
+				<1 RK_PD2 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m1_ch4_pins: pwm1m1-ch4-pins {
+			rockchip,pins =
+				<1 RK_PD3 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m1_ch5_pins: pwm1m1-ch5-pins {
+			rockchip,pins =
+				<4 RK_PB0 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m2_ch0_pins: pwm1m2-ch0-pins {
+			rockchip,pins =
+				<3 RK_PA4 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m2_ch1_pins: pwm1m2-ch1-pins {
+			rockchip,pins =
+				<3 RK_PA5 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m2_ch2_pins: pwm1m2-ch2-pins {
+			rockchip,pins =
+				<2 RK_PD0 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m2_ch3_pins: pwm1m2-ch3-pins {
+			rockchip,pins =
+				<2 RK_PD2 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m2_ch4_pins: pwm1m2-ch4-pins {
+			rockchip,pins =
+				<2 RK_PD3 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m2_ch5_pins: pwm1m2-ch5-pins {
+			rockchip,pins =
+				<3 RK_PB5 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m3_ch2_pins: pwm1m3-ch2-pins {
+			rockchip,pins =
+				<3 RK_PA6 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m3_ch3_pins: pwm1m3-ch3-pins {
+			rockchip,pins =
+				<3 RK_PB1 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m3_ch4_pins: pwm1m3-ch4-pins {
+			rockchip,pins =
+				<3 RK_PB4 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm1m3_ch5_pins: pwm1m3-ch5-pins {
+			rockchip,pins =
+				<1 RK_PD4 12 &pcfg_pull_none>;
+		};
+	};
+
+	pwm2 {
+		/omit-if-no-ref/
+		pwm2m0_ch0_pins: pwm2m0-ch0-pins {
+			rockchip,pins =
+				<0 RK_PD3 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m0_ch1_pins: pwm2m0-ch1-pins {
+			rockchip,pins =
+				<1 RK_PB3 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m0_ch2_pins: pwm2m0-ch2-pins {
+			rockchip,pins =
+				<2 RK_PA0 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m0_ch3_pins: pwm2m0-ch3-pins {
+			rockchip,pins =
+				<2 RK_PA1 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m0_ch4_pins: pwm2m0-ch4-pins {
+			rockchip,pins =
+				<2 RK_PA4 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m0_ch5_pins: pwm2m0-ch5-pins {
+			rockchip,pins =
+				<2 RK_PB0 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m0_ch6_pins: pwm2m0-ch6-pins {
+			rockchip,pins =
+				<2 RK_PB5 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m0_ch7_pins: pwm2m0-ch7-pins {
+			rockchip,pins =
+				<2 RK_PC1 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m1_ch0_pins: pwm2m1-ch0-pins {
+			rockchip,pins =
+				<4 RK_PB2 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m1_ch1_pins: pwm2m1-ch1-pins {
+			rockchip,pins =
+				<4 RK_PB3 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m1_ch2_pins: pwm2m1-ch2-pins {
+			rockchip,pins =
+				<4 RK_PB6 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m1_ch3_pins: pwm2m1-ch3-pins {
+			rockchip,pins =
+				<4 RK_PB7 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m1_ch4_pins: pwm2m1-ch4-pins {
+			rockchip,pins =
+				<2 RK_PB1 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m1_ch5_pins: pwm2m1-ch5-pins {
+			rockchip,pins =
+				<4 RK_PB5 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m1_ch6_pins: pwm2m1-ch6-pins {
+			rockchip,pins =
+				<4 RK_PB4 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m1_ch7_pins: pwm2m1-ch7-pins {
+			rockchip,pins =
+				<1 RK_PB1 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m2_ch0_pins: pwm2m2-ch0-pins {
+			rockchip,pins =
+				<3 RK_PC2 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m2_ch1_pins: pwm2m2-ch1-pins {
+			rockchip,pins =
+				<3 RK_PC3 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m2_ch2_pins: pwm2m2-ch2-pins {
+			rockchip,pins =
+				<2 RK_PD6 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m2_ch3_pins: pwm2m2-ch3-pins {
+			rockchip,pins =
+				<2 RK_PD7 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m2_ch4_pins: pwm2m2-ch4-pins {
+			rockchip,pins =
+				<2 RK_PC4 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m2_ch5_pins: pwm2m2-ch5-pins {
+			rockchip,pins =
+				<2 RK_PC5 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m2_ch6_pins: pwm2m2-ch6-pins {
+			rockchip,pins =
+				<3 RK_PD6 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m2_ch7_pins: pwm2m2-ch7-pins {
+			rockchip,pins =
+				<3 RK_PD7 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m3_ch2_pins: pwm2m3-ch2-pins {
+			rockchip,pins =
+				<3 RK_PC5 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m3_ch3_pins: pwm2m3-ch3-pins {
+			rockchip,pins =
+				<3 RK_PD0 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m3_ch4_pins: pwm2m3-ch4-pins {
+			rockchip,pins =
+				<3 RK_PD2 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwm2m3_ch5_pins: pwm2m3-ch5-pins {
+			rockchip,pins =
+				<3 RK_PD3 12 &pcfg_pull_none>;
+		};
+	};
+
+	pwr {
+		/omit-if-no-ref/
+		pwr_ctrl1_pins: pwr-ctrl1-pins {
+			rockchip,pins =
+				<0 RK_PA3 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwr_ctrl2_pins: pwr-ctrl2-pins {
+			rockchip,pins =
+				<0 RK_PA4 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pwr_ctrl3_pins: pwr-ctrl3-pins {
+			rockchip,pins =
+				<0 RK_PA5 9 &pcfg_pull_none>;
+		};
+	};
+
+	ref_clk0 {
+		/omit-if-no-ref/
+		ref_clk0_clk0_pins: ref-clk0-clk0-pins {
+			rockchip,pins =
+				<0 RK_PA0 1 &pcfg_pull_none>;
+		};
+	};
+
+	ref_clk1 {
+		/omit-if-no-ref/
+		ref_clk1_clk1_pins: ref-clk1-clk1-pins {
+			rockchip,pins =
+				<0 RK_PB4 1 &pcfg_pull_none>;
+		};
+	};
+
+	ref_clk2 {
+		/omit-if-no-ref/
+		ref_clk2_clk2_pins: ref-clk2-clk2-pins {
+			rockchip,pins =
+				<0 RK_PB5 1 &pcfg_pull_none>;
+		};
+	};
+
+	sai0 {
+		/omit-if-no-ref/
+		sai0m0_lrck_pins: sai0m0-lrck-pins {
+			rockchip,pins =
+				<2 RK_PD1 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m0_mclk_pins: sai0m0-mclk-pins {
+			rockchip,pins =
+				<2 RK_PC7 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m0_sclk_pins: sai0m0-sclk-pins {
+			rockchip,pins =
+				<2 RK_PD0 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m0_sdi0_pins: sai0m0-sdi0-pins {
+			rockchip,pins =
+				<2 RK_PD3 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m0_sdi1_pins: sai0m0-sdi1-pins {
+			rockchip,pins =
+				<2 RK_PC5 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m0_sdi2_pins: sai0m0-sdi2-pins {
+			rockchip,pins =
+				<2 RK_PC4 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m0_sdi3_pins: sai0m0-sdi3-pins {
+			rockchip,pins =
+				<2 RK_PD6 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m0_sdo0_pins: sai0m0-sdo0-pins {
+			rockchip,pins =
+				<2 RK_PD2 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m0_sdo1_pins: sai0m0-sdo1-pins {
+			rockchip,pins =
+				<2 RK_PC6 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m0_sdo2_pins: sai0m0-sdo2-pins {
+			rockchip,pins =
+				<2 RK_PD4 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m0_sdo3_pins: sai0m0-sdo3-pins {
+			rockchip,pins =
+				<2 RK_PD5 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m1_lrck_pins: sai0m1-lrck-pins {
+			rockchip,pins =
+				<0 RK_PC7 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m1_mclk_pins: sai0m1-mclk-pins {
+			rockchip,pins =
+				<0 RK_PC4 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m1_sclk_pins: sai0m1-sclk-pins {
+			rockchip,pins =
+				<0 RK_PC6 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m1_sdi0_pins: sai0m1-sdi0-pins {
+			rockchip,pins =
+				<0 RK_PD0 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m1_sdi1_pins: sai0m1-sdi1-pins {
+			rockchip,pins =
+				<0 RK_PD1 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m1_sdi2_pins: sai0m1-sdi2-pins {
+			rockchip,pins =
+				<0 RK_PD2 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m1_sdi3_pins: sai0m1-sdi3-pins {
+			rockchip,pins =
+				<0 RK_PD3 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m1_sdo0_pins: sai0m1-sdo0-pins {
+			rockchip,pins =
+				<0 RK_PC5 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m1_sdo1_pins: sai0m1-sdo1-pins {
+			rockchip,pins =
+				<0 RK_PD3 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m1_sdo2_pins: sai0m1-sdo2-pins {
+			rockchip,pins =
+				<0 RK_PD2 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m1_sdo3_pins: sai0m1-sdo3-pins {
+			rockchip,pins =
+				<0 RK_PD1 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m2_lrck_pins: sai0m2-lrck-pins {
+			rockchip,pins =
+				<2 RK_PB4 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m2_mclk_pins: sai0m2-mclk-pins {
+			rockchip,pins =
+				<2 RK_PB0 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m2_sclk_pins: sai0m2-sclk-pins {
+			rockchip,pins =
+				<2 RK_PB2 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m2_sdi0_pins: sai0m2-sdi0-pins {
+			rockchip,pins =
+				<2 RK_PB5 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m2_sdi1_pins: sai0m2-sdi1-pins {
+			rockchip,pins =
+				<2 RK_PB1 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m2_sdi2_pins: sai0m2-sdi2-pins {
+			rockchip,pins =
+				<2 RK_PB3 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m2_sdi3_pins: sai0m2-sdi3-pins {
+			rockchip,pins =
+				<2 RK_PC2 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai0m2_sdo0_pins: sai0m2-sdo0-pins {
+			rockchip,pins =
+				<2 RK_PC1 5 &pcfg_pull_none>;
+		};
+	};
+
+	sai1 {
+		/omit-if-no-ref/
+		sai1m0_lrck_pins: sai1m0-lrck-pins {
+			rockchip,pins =
+				<2 RK_PB3 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m0_mclk_pins: sai1m0-mclk-pins {
+			rockchip,pins =
+				<2 RK_PB0 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m0_sclk_pins: sai1m0-sclk-pins {
+			rockchip,pins =
+				<2 RK_PB1 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m0_sdi0_pins: sai1m0-sdi0-pins {
+			rockchip,pins =
+				<2 RK_PC1 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m0_sdi1_pins: sai1m0-sdi1-pins {
+			rockchip,pins =
+				<2 RK_PC0 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m0_sdi2_pins: sai1m0-sdi2-pins {
+			rockchip,pins =
+				<2 RK_PB7 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m0_sdi3_pins: sai1m0-sdi3-pins {
+			rockchip,pins =
+				<2 RK_PB6 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m0_sdo0_pins: sai1m0-sdo0-pins {
+			rockchip,pins =
+				<2 RK_PB5 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m0_sdo1_pins: sai1m0-sdo1-pins {
+			rockchip,pins =
+				<2 RK_PB6 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m0_sdo2_pins: sai1m0-sdo2-pins {
+			rockchip,pins =
+				<2 RK_PB7 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m0_sdo3_pins: sai1m0-sdo3-pins {
+			rockchip,pins =
+				<2 RK_PC0 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m1_lrck_pins: sai1m1-lrck-pins {
+			rockchip,pins =
+				<4 RK_PA1 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m1_mclk_pins: sai1m1-mclk-pins {
+			rockchip,pins =
+				<3 RK_PB0 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m1_sclk_pins: sai1m1-sclk-pins {
+			rockchip,pins =
+				<3 RK_PA4 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m1_sdi0_pins: sai1m1-sdi0-pins {
+			rockchip,pins =
+				<3 RK_PB7 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m1_sdi1_pins: sai1m1-sdi1-pins {
+			rockchip,pins =
+				<3 RK_PD4 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m1_sdi2_pins: sai1m1-sdi2-pins {
+			rockchip,pins =
+				<3 RK_PD5 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m1_sdi3_pins: sai1m1-sdi3-pins {
+			rockchip,pins =
+				<3 RK_PD6 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m1_sdo0_pins: sai1m1-sdo0-pins {
+			rockchip,pins =
+				<4 RK_PA0 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m1_sdo1_pins: sai1m1-sdo1-pins {
+			rockchip,pins =
+				<3 RK_PD7 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m1_sdo2_pins: sai1m1-sdo2-pins {
+			rockchip,pins =
+				<3 RK_PC1 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai1m1_sdo3_pins: sai1m1-sdo3-pins {
+			rockchip,pins =
+				<3 RK_PC0 5 &pcfg_pull_none>;
+		};
+	};
+
+	sai2 {
+		/omit-if-no-ref/
+		sai2m0_lrck_pins: sai2m0-lrck-pins {
+			rockchip,pins =
+				<1 RK_PD2 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai2m0_mclk_pins: sai2m0-mclk-pins {
+			rockchip,pins =
+				<1 RK_PD4 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai2m0_sclk_pins: sai2m0-sclk-pins {
+			rockchip,pins =
+				<1 RK_PD1 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai2m0_sdi_pins: sai2m0-sdi-pins {
+			rockchip,pins =
+				<1 RK_PD3 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai2m0_sdo_pins: sai2m0-sdo-pins {
+			rockchip,pins =
+				<1 RK_PD0 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai2m1_lrck_pins: sai2m1-lrck-pins {
+			rockchip,pins =
+				<3 RK_PC3 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai2m1_mclk_pins: sai2m1-mclk-pins {
+			rockchip,pins =
+				<3 RK_PC4 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai2m1_sclk_pins: sai2m1-sclk-pins {
+			rockchip,pins =
+				<3 RK_PC2 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai2m1_sdi_pins: sai2m1-sdi-pins {
+			rockchip,pins =
+				<3 RK_PD2 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai2m1_sdo_pins: sai2m1-sdo-pins {
+			rockchip,pins =
+				<3 RK_PD3 5 &pcfg_pull_none>;
+		};
+	};
+
+	sai3 {
+		/omit-if-no-ref/
+		sai3m0_lrck_pins: sai3m0-lrck-pins {
+			rockchip,pins =
+				<1 RK_PA6 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai3m0_mclk_pins: sai3m0-mclk-pins {
+			rockchip,pins =
+				<1 RK_PA4 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai3m0_sclk_pins: sai3m0-sclk-pins {
+			rockchip,pins =
+				<1 RK_PA5 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai3m0_sdi_pins: sai3m0-sdi-pins {
+			rockchip,pins =
+				<1 RK_PA7 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai3m0_sdo_pins: sai3m0-sdo-pins {
+			rockchip,pins =
+				<1 RK_PB2 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai3m1_lrck_pins: sai3m1-lrck-pins {
+			rockchip,pins =
+				<2 RK_PA2 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai3m1_mclk_pins: sai3m1-mclk-pins {
+			rockchip,pins =
+				<2 RK_PA1 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai3m1_sclk_pins: sai3m1-sclk-pins {
+			rockchip,pins =
+				<2 RK_PA5 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai3m1_sdi_pins: sai3m1-sdi-pins {
+			rockchip,pins =
+				<2 RK_PA3 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai3m1_sdo_pins: sai3m1-sdo-pins {
+			rockchip,pins =
+				<2 RK_PA4 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai3m2_lrck_pins: sai3m2-lrck-pins {
+			rockchip,pins =
+				<4 RK_PB2 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai3m2_mclk_pins: sai3m2-mclk-pins {
+			rockchip,pins =
+				<4 RK_PB0 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai3m2_sclk_pins: sai3m2-sclk-pins {
+			rockchip,pins =
+				<4 RK_PB3 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai3m2_sdi_pins: sai3m2-sdi-pins {
+			rockchip,pins =
+				<4 RK_PB1 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai3m2_sdo_pins: sai3m2-sdo-pins {
+			rockchip,pins =
+				<4 RK_PB4 4 &pcfg_pull_none>;
+		};
+	};
+
+	sai4 {
+		/omit-if-no-ref/
+		sai4m0_lrck_pins: sai4m0-lrck-pins {
+			rockchip,pins =
+				<1 RK_PA1 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai4m0_mclk_pins: sai4m0-mclk-pins {
+			rockchip,pins =
+				<1 RK_PA4 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai4m0_sclk_pins: sai4m0-sclk-pins {
+			rockchip,pins =
+				<1 RK_PA0 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai4m0_sdi0_pins: sai4m0-sdi0-pins {
+			rockchip,pins =
+				<1 RK_PB2 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai4m0_sdi1_pins: sai4m0-sdi1-pins {
+			rockchip,pins =
+				<1 RK_PB1 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai4m0_sdi2_pins: sai4m0-sdi2-pins {
+			rockchip,pins =
+				<1 RK_PA3 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai4m0_sdi3_pins: sai4m0-sdi3-pins {
+			rockchip,pins =
+				<1 RK_PA2 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai4m0_sdo0_pins: sai4m0-sdo0-pins {
+			rockchip,pins =
+				<1 RK_PA7 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai4m0_sdo1_pins: sai4m0-sdo1-pins {
+			rockchip,pins =
+				<1 RK_PA2 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai4m0_sdo2_pins: sai4m0-sdo2-pins {
+			rockchip,pins =
+				<1 RK_PA3 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai4m0_sdo3_pins: sai4m0-sdo3-pins {
+			rockchip,pins =
+				<1 RK_PB1 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai4m1_lrck_pins: sai4m1-lrck-pins {
+			rockchip,pins =
+				<1 RK_PB5 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai4m1_mclk_pins: sai4m1-mclk-pins {
+			rockchip,pins =
+				<1 RK_PB4 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai4m1_sclk_pins: sai4m1-sclk-pins {
+			rockchip,pins =
+				<1 RK_PC0 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai4m1_sdi0_pins: sai4m1-sdi0-pins {
+			rockchip,pins =
+				<1 RK_PB6 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sai4m1_sdo0_pins: sai4m1-sdo0-pins {
+			rockchip,pins =
+				<1 RK_PB7 4 &pcfg_pull_none>;
+		};
+	};
+
+	sata0 {
+		/omit-if-no-ref/
+		sata0m0_sata_pins: sata0m0-sata-pins {
+			rockchip,pins =
+				<1 RK_PC3 14 &pcfg_pull_none>,
+				<1 RK_PC2 14 &pcfg_pull_none>,
+				<1 RK_PD6 14 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sata0m1_sata_pins: sata0m1-sata-pins {
+			rockchip,pins =
+				<3 RK_PD0 14 &pcfg_pull_none>,
+				<3 RK_PC7 14 &pcfg_pull_none>,
+				<3 RK_PC4 14 &pcfg_pull_none>;
+		};
+	};
+
+	sata1 {
+		/omit-if-no-ref/
+		sata1m0_sata_pins: sata1m0-sata-pins {
+			rockchip,pins =
+				<1 RK_PD2 14 &pcfg_pull_none>,
+				<1 RK_PD1 14 &pcfg_pull_none>,
+				<1 RK_PD3 14 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sata1m1_sata_pins: sata1m1-sata-pins {
+			rockchip,pins =
+				<4 RK_PA1 14 &pcfg_pull_none>,
+				<4 RK_PA0 14 &pcfg_pull_none>,
+				<3 RK_PD7 14 &pcfg_pull_none>;
+		};
+	};
+
+	sata30_port0 {
+		/omit-if-no-ref/
+		sata30_port0m0_port0_pins: sata30-port0m0-port0-pins {
+			rockchip,pins =
+				<2 RK_PD2 7 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sata30_port0m1_port0_pins: sata30-port0m1-port0-pins {
+			rockchip,pins =
+				<4 RK_PB5 6 &pcfg_pull_none>;
+		};
+	};
+
+	sata30_port1 {
+		/omit-if-no-ref/
+		sata30_port1m0_port1_pins: sata30-port1m0-port1-pins {
+			rockchip,pins =
+				<2 RK_PD1 7 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sata30_port1m1_port1_pins: sata30-port1m1-port1-pins {
+			rockchip,pins =
+				<4 RK_PB6 6 &pcfg_pull_none>;
+		};
+	};
+
+	sdmmc0 {
+		/omit-if-no-ref/
+		sdmmc0m0_bus4_pins: sdmmc0m0-bus4-pins {
+			rockchip,pins =
+				<2 RK_PA0 2 &pcfg_pull_up_drv_level_2>,
+				<2 RK_PA1 2 &pcfg_pull_up_drv_level_2>,
+				<2 RK_PA2 2 &pcfg_pull_up_drv_level_2>,
+				<2 RK_PA3 2 &pcfg_pull_up_drv_level_2>;
+		};
+
+		/omit-if-no-ref/
+		sdmmc0m0_clk_pins: sdmmc0m0-clk-pins {
+			rockchip,pins =
+				<2 RK_PA5 2 &pcfg_pull_up_drv_level_2>;
+		};
+
+		/omit-if-no-ref/
+		sdmmc0m0_cmd_pins: sdmmc0m0-cmd-pins {
+			rockchip,pins =
+				<2 RK_PA4 2 &pcfg_pull_up_drv_level_2>;
+		};
+
+		/omit-if-no-ref/
+		sdmmc0m0_det_pins: sdmmc0m0-det-pins {
+			rockchip,pins =
+				<0 RK_PA7 1 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		sdmmc0m1_bus4_pins: sdmmc0m1-bus4-pins {
+			rockchip,pins =
+				<2 RK_PC4 3 &pcfg_pull_up_drv_level_2>,
+				<2 RK_PC5 3 &pcfg_pull_up_drv_level_2>,
+				<2 RK_PC6 3 &pcfg_pull_up_drv_level_2>,
+				<2 RK_PC7 3 &pcfg_pull_up_drv_level_2>;
+		};
+
+		/omit-if-no-ref/
+		sdmmc0m1_clk_pins: sdmmc0m1-clk-pins {
+			rockchip,pins =
+				<2 RK_PD1 3 &pcfg_pull_up_drv_level_2>;
+		};
+
+		/omit-if-no-ref/
+		sdmmc0m1_cmd_pins: sdmmc0m1-cmd-pins {
+			rockchip,pins =
+				<2 RK_PD0 3 &pcfg_pull_up_drv_level_2>;
+		};
+
+		/omit-if-no-ref/
+		sdmmc0m1_det_pins: sdmmc0m1-det-pins {
+			rockchip,pins =
+				<2 RK_PD3 3 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		sdmmc0m1_pwren_pins: sdmmc0m1-pwren-pins {
+			rockchip,pins =
+				<2 RK_PD2 3 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		sdmmc0_pwren_pins: sdmmc0-pwren-pins {
+			rockchip,pins =
+				<0 RK_PB6 1 &pcfg_pull_none>;
+		};
+	};
+
+	sdmmc1 {
+		/omit-if-no-ref/
+		sdmmc1m0_det_pins: sdmmc1m0-det-pins {
+			rockchip,pins =
+				<1 RK_PC3 2 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		sdmmc1m1_det_pins: sdmmc1m1-det-pins {
+			rockchip,pins =
+				<0 RK_PB6 2 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		sdmmc1_bus4_pins: sdmmc1-bus4-pins {
+			rockchip,pins =
+				<1 RK_PB4 2 &pcfg_pull_up_drv_level_2>,
+				<1 RK_PB5 2 &pcfg_pull_up_drv_level_2>,
+				<1 RK_PB6 2 &pcfg_pull_up_drv_level_2>,
+				<1 RK_PB7 2 &pcfg_pull_up_drv_level_2>;
+		};
+
+		/omit-if-no-ref/
+		sdmmc1_clk_pins: sdmmc1-clk-pins {
+			rockchip,pins =
+				<1 RK_PC1 2 &pcfg_pull_up_drv_level_2>;
+		};
+
+		/omit-if-no-ref/
+		sdmmc1_cmd_pins: sdmmc1-cmd-pins {
+			rockchip,pins =
+				<1 RK_PC0 2 &pcfg_pull_up_drv_level_2>;
+		};
+
+		/omit-if-no-ref/
+		sdmmc1_pwren_pins: sdmmc1-pwren-pins {
+			rockchip,pins =
+				<1 RK_PC2 2 &pcfg_pull_none>;
+		};
+	};
+
+	spdif {
+		/omit-if-no-ref/
+		spdifm0_rx0_pins: spdifm0-rx0-pins {
+			rockchip,pins =
+				<2 RK_PC2 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spdifm0_tx0_pins: spdifm0-tx0-pins {
+			rockchip,pins =
+				<2 RK_PC3 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spdifm0_tx1_pins: spdifm0-tx1-pins {
+			rockchip,pins =
+				<2 RK_PB4 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spdifm1_rx0_pins: spdifm1-rx0-pins {
+			rockchip,pins =
+				<1 RK_PD4 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spdifm1_tx0_pins: spdifm1-tx0-pins {
+			rockchip,pins =
+				<1 RK_PD5 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spdifm1_tx1_pins: spdifm1-tx1-pins {
+			rockchip,pins =
+				<1 RK_PD6 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spdifm2_rx0_pins: spdifm2-rx0-pins {
+			rockchip,pins =
+				<2 RK_PD6 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spdifm2_tx0_pins: spdifm2-tx0-pins {
+			rockchip,pins =
+				<2 RK_PD7 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spdifm2_tx1_pins: spdifm2-tx1-pins {
+			rockchip,pins =
+				<2 RK_PD5 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spdifm3_rx0_pins: spdifm3-rx0-pins {
+			rockchip,pins =
+				<3 RK_PB4 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spdifm3_tx0_pins: spdifm3-tx0-pins {
+			rockchip,pins =
+				<3 RK_PB5 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spdifm3_tx1_pins: spdifm3-tx1-pins {
+			rockchip,pins =
+				<3 RK_PB6 5 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spdifm4_rx0_pins: spdifm4-rx0-pins {
+			rockchip,pins =
+				<4 RK_PA0 6 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spdifm4_tx0_pins: spdifm4-tx0-pins {
+			rockchip,pins =
+				<4 RK_PA1 6 &pcfg_pull_none>;
+		};
+	};
+
+	spdif_rx0 {
+		/omit-if-no-ref/
+		spdif_rx0_rx0_pins: spdif-rx0-rx0-pins {
+			rockchip,pins =
+				<2 RK_PB7 7 &pcfg_pull_none>;
+		};
+	};
+
+	spdif_rx1 {
+		/omit-if-no-ref/
+		spdif_rx1_rx1_pins: spdif-rx1-rx1-pins {
+			rockchip,pins =
+				<1 RK_PD6 7 &pcfg_pull_none>;
+		};
+	};
+
+	spi0 {
+		/omit-if-no-ref/
+		spi0m0_pins: spi0m0-pins {
+			rockchip,pins =
+				<0 RK_PC7 10 &pcfg_pull_none>,
+				<0 RK_PD1 10 &pcfg_pull_none>,
+				<0 RK_PD0 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi0m0_csn0_pins: spi0m0-csn0-pins {
+			rockchip,pins =
+				<0 RK_PC6 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi0m0_csn1_pins: spi0m0-csn1-pins {
+			rockchip,pins =
+				<0 RK_PC3 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi0m1_pins: spi0m1-pins {
+			rockchip,pins =
+				<2 RK_PA5 10 &pcfg_pull_none>,
+				<2 RK_PA1 10 &pcfg_pull_none>,
+				<2 RK_PA0 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi0m1_csn0_pins: spi0m1-csn0-pins {
+			rockchip,pins =
+				<2 RK_PA4 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi0m1_csn1_pins: spi0m1-csn1-pins {
+			rockchip,pins =
+				<2 RK_PA2 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi0m2_pins: spi0m2-pins {
+			rockchip,pins =
+				<1 RK_PA7 10 &pcfg_pull_none>,
+				<1 RK_PA6 10 &pcfg_pull_none>,
+				<1 RK_PA5 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi0m2_csn0_pins: spi0m2-csn0-pins {
+			rockchip,pins =
+				<1 RK_PA4 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi0m2_csn1_pins: spi0m2-csn1-pins {
+			rockchip,pins =
+				<1 RK_PB2 10 &pcfg_pull_none>;
+		};
+	};
+
+	spi1 {
+		/omit-if-no-ref/
+		spi1m0_pins: spi1m0-pins {
+			rockchip,pins =
+				<1 RK_PB4 10 &pcfg_pull_none>,
+				<1 RK_PB6 10 &pcfg_pull_none>,
+				<1 RK_PB5 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi1m0_csn0_pins: spi1m0-csn0-pins {
+			rockchip,pins =
+				<1 RK_PB7 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi1m0_csn1_pins: spi1m0-csn1-pins {
+			rockchip,pins =
+				<1 RK_PC0 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi1m1_pins: spi1m1-pins {
+			rockchip,pins =
+				<2 RK_PD3 10 &pcfg_pull_none>,
+				<2 RK_PD1 10 &pcfg_pull_none>,
+				<2 RK_PD0 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi1m1_csn0_pins: spi1m1-csn0-pins {
+			rockchip,pins =
+				<2 RK_PD2 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi1m1_csn1_pins: spi1m1-csn1-pins {
+			rockchip,pins =
+				<2 RK_PC7 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi1m2_pins: spi1m2-pins {
+			rockchip,pins =
+				<3 RK_PC7 10 &pcfg_pull_none>,
+				<3 RK_PC5 10 &pcfg_pull_none>,
+				<3 RK_PC6 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi1m2_csn0_pins: spi1m2-csn0-pins {
+			rockchip,pins =
+				<3 RK_PD0 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi1m2_csn1_pins: spi1m2-csn1-pins {
+			rockchip,pins =
+				<4 RK_PA0 10 &pcfg_pull_none>;
+		};
+	};
+
+	spi2 {
+		/omit-if-no-ref/
+		spi2m0_pins: spi2m0-pins {
+			rockchip,pins =
+				<0 RK_PB2 10 &pcfg_pull_none>,
+				<0 RK_PB1 10 &pcfg_pull_none>,
+				<0 RK_PB3 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi2m0_csn0_pins: spi2m0-csn0-pins {
+			rockchip,pins =
+				<0 RK_PB0 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi2m0_csn1_pins: spi2m0-csn1-pins {
+			rockchip,pins =
+				<0 RK_PA7 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi2m1_pins: spi2m1-pins {
+			rockchip,pins =
+				<1 RK_PD5 10 &pcfg_pull_none>,
+				<1 RK_PC5 10 &pcfg_pull_none>,
+				<1 RK_PC4 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi2m1_csn0_pins: spi2m1-csn0-pins {
+			rockchip,pins =
+				<1 RK_PC6 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi2m1_csn1_pins: spi2m1-csn1-pins {
+			rockchip,pins =
+				<1 RK_PC7 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi2m2_pins: spi2m2-pins {
+			rockchip,pins =
+				<3 RK_PA4 10 &pcfg_pull_none>,
+				<3 RK_PC1 10 &pcfg_pull_none>,
+				<3 RK_PB0 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi2m2_csn0_pins: spi2m2-csn0-pins {
+			rockchip,pins =
+				<3 RK_PC4 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi2m2_csn1_pins: spi2m2-csn1-pins {
+			rockchip,pins =
+				<3 RK_PA5 10 &pcfg_pull_none>;
+		};
+	};
+
+	spi3 {
+		/omit-if-no-ref/
+		spi3m0_pins: spi3m0-pins {
+			rockchip,pins =
+				<2 RK_PD4 10 &pcfg_pull_none>,
+				<2 RK_PD6 10 &pcfg_pull_none>,
+				<2 RK_PD5 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi3m0_csn0_pins: spi3m0-csn0-pins {
+			rockchip,pins =
+				<2 RK_PD7 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi3m0_csn1_pins: spi3m0-csn1-pins {
+			rockchip,pins =
+				<2 RK_PC6 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi3m1_pins: spi3m1-pins {
+			rockchip,pins =
+				<3 RK_PD4 10 &pcfg_pull_none>,
+				<3 RK_PD5 10 &pcfg_pull_none>,
+				<3 RK_PD6 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi3m1_csn0_pins: spi3m1-csn0-pins {
+			rockchip,pins =
+				<3 RK_PB6 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi3m1_csn1_pins: spi3m1-csn1-pins {
+			rockchip,pins =
+				<3 RK_PD3 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi3m2_pins: spi3m2-pins {
+			rockchip,pins =
+				<2 RK_PB5 10 &pcfg_pull_none>,
+				<2 RK_PB4 10 &pcfg_pull_none>,
+				<2 RK_PB2 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi3m2_csn0_pins: spi3m2-csn0-pins {
+			rockchip,pins =
+				<2 RK_PB1 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi3m2_csn1_pins: spi3m2-csn1-pins {
+			rockchip,pins =
+				<2 RK_PC1 11 &pcfg_pull_none>;
+		};
+	};
+
+	spi4 {
+		/omit-if-no-ref/
+		spi4m0_pins: spi4m0-pins {
+			rockchip,pins =
+				<4 RK_PB7 10 &pcfg_pull_none>,
+				<4 RK_PB6 10 &pcfg_pull_none>,
+				<4 RK_PB5 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi4m0_csn0_pins: spi4m0-csn0-pins {
+			rockchip,pins =
+				<4 RK_PB4 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi4m0_csn1_pins: spi4m0-csn1-pins {
+			rockchip,pins =
+				<4 RK_PB0 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi4m1_pins: spi4m1-pins {
+			rockchip,pins =
+				<3 RK_PD1 10 &pcfg_pull_none>,
+				<3 RK_PC2 10 &pcfg_pull_none>,
+				<3 RK_PC3 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi4m1_csn0_pins: spi4m1-csn0-pins {
+			rockchip,pins =
+				<3 RK_PB1 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi4m1_csn1_pins: spi4m1-csn1-pins {
+			rockchip,pins =
+				<3 RK_PD2 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi4m2_pins: spi4m2-pins {
+			rockchip,pins =
+				<2 RK_PB6 10 &pcfg_pull_none>,
+				<2 RK_PC0 10 &pcfg_pull_none>,
+				<2 RK_PB7 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi4m2_csn0_pins: spi4m2-csn0-pins {
+			rockchip,pins =
+				<2 RK_PC1 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		spi4m2_csn1_pins: spi4m2-csn1-pins {
+			rockchip,pins =
+				<2 RK_PB3 10 &pcfg_pull_none>;
+		};
+	};
+
+	tsadc {
+		/omit-if-no-ref/
+		tsadcm0_pins: tsadcm0-pins {
+			rockchip,pins =
+				<0 RK_PA1 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		tsadcm1_pins: tsadcm1-pins {
+			rockchip,pins =
+				<0 RK_PA3 10 &pcfg_pull_none>;
+		};
+	};
+
+	tsadc_ctrl {
+		/omit-if-no-ref/
+		tsadc_ctrl_pins: tsadc-ctrl-pins {
+			rockchip,pins =
+				<0 RK_PA1 10 &pcfg_pull_none>;
+		};
+	};
+
+	uart0 {
+		/omit-if-no-ref/
+		uart0m0_xfer_pins: uart0m0-xfer-pins {
+			rockchip,pins =
+				<0 RK_PD5 9 &pcfg_pull_up>,
+				<0 RK_PD4 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart0m1_xfer_pins: uart0m1-xfer-pins {
+			rockchip,pins =
+				<2 RK_PA0 9 &pcfg_pull_up>,
+				<2 RK_PA1 9 &pcfg_pull_up>;
+		};
+	};
+
+	uart1 {
+		/omit-if-no-ref/
+		uart1m0_xfer_pins: uart1m0-xfer-pins {
+			rockchip,pins =
+				<0 RK_PC0 9 &pcfg_pull_up>,
+				<0 RK_PB7 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart1m0_ctsn_pins: uart1m0-ctsn-pins {
+			rockchip,pins =
+				<0 RK_PD2 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart1m0_rtsn_pins: uart1m0-rtsn-pins {
+			rockchip,pins =
+				<0 RK_PD3 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart1m1_xfer_pins: uart1m1-xfer-pins {
+			rockchip,pins =
+				<2 RK_PD3 9 &pcfg_pull_up>,
+				<2 RK_PD2 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart1m1_ctsn_pins: uart1m1-ctsn-pins {
+			rockchip,pins =
+				<2 RK_PD0 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart1m1_rtsn_pins: uart1m1-rtsn-pins {
+			rockchip,pins =
+				<2 RK_PD1 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart1m2_xfer_pins: uart1m2-xfer-pins {
+			rockchip,pins =
+				<3 RK_PA6 9 &pcfg_pull_up>,
+				<3 RK_PA7 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart1m2_ctsn_pins: uart1m2-ctsn-pins {
+			rockchip,pins =
+				<3 RK_PA4 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart1m2_rtsn_pins: uart1m2-rtsn-pins {
+			rockchip,pins =
+				<3 RK_PA5 9 &pcfg_pull_none>;
+		};
+	};
+
+	uart2 {
+		/omit-if-no-ref/
+		uart2m0_xfer_pins: uart2m0-xfer-pins {
+			rockchip,pins =
+				<1 RK_PC7 9 &pcfg_pull_up>,
+				<1 RK_PC6 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart2m0_ctsn_pins: uart2m0-ctsn-pins {
+			rockchip,pins =
+				<1 RK_PC5 11 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart2m0_rtsn_pins: uart2m0-rtsn-pins {
+			rockchip,pins =
+				<1 RK_PC4 11 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart2m1_xfer_pins: uart2m1-xfer-pins {
+			rockchip,pins =
+				<2 RK_PB4 9 &pcfg_pull_up>,
+				<2 RK_PB5 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart2m1_ctsn_pins: uart2m1-ctsn-pins {
+			rockchip,pins =
+				<2 RK_PB7 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart2m1_rtsn_pins: uart2m1-rtsn-pins {
+			rockchip,pins =
+				<2 RK_PB6 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart2m2_xfer_pins: uart2m2-xfer-pins {
+			rockchip,pins =
+				<3 RK_PB7 9 &pcfg_pull_up>,
+				<3 RK_PC0 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart2m2_ctsn_pins: uart2m2-ctsn-pins {
+			rockchip,pins =
+				<3 RK_PD3 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart2m2_rtsn_pins: uart2m2-rtsn-pins {
+			rockchip,pins =
+				<3 RK_PD2 9 &pcfg_pull_none>;
+		};
+	};
+
+	uart3 {
+		/omit-if-no-ref/
+		uart3m0_xfer_pins: uart3m0-xfer-pins {
+			rockchip,pins =
+				<2 RK_PD5 9 &pcfg_pull_up>,
+				<2 RK_PD4 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart3m0_ctsn_pins: uart3m0-ctsn-pins {
+			rockchip,pins =
+				<2 RK_PD6 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart3m0_rtsn_pins: uart3m0-rtsn-pins {
+			rockchip,pins =
+				<2 RK_PD7 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart3m1_xfer_pins: uart3m1-xfer-pins {
+			rockchip,pins =
+				<3 RK_PB2 9 &pcfg_pull_up>,
+				<3 RK_PB3 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart3m1_ctsn_pins: uart3m1-ctsn-pins {
+			rockchip,pins =
+				<3 RK_PB5 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart3m1_rtsn_pins: uart3m1-rtsn-pins {
+			rockchip,pins =
+				<3 RK_PB4 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart3m2_xfer_pins: uart3m2-xfer-pins {
+			rockchip,pins =
+				<1 RK_PC1 9 &pcfg_pull_up>,
+				<1 RK_PC0 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart3m2_ctsn_pins: uart3m2-ctsn-pins {
+			rockchip,pins =
+				<1 RK_PB6 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart3m2_rtsn_pins: uart3m2-rtsn-pins {
+			rockchip,pins =
+				<1 RK_PB7 9 &pcfg_pull_none>;
+		};
+	};
+
+	uart4 {
+		/omit-if-no-ref/
+		uart4m0_xfer_pins: uart4m0-xfer-pins {
+			rockchip,pins =
+				<3 RK_PC1 9 &pcfg_pull_up>,
+				<3 RK_PC4 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart4m0_ctsn_pins: uart4m0-ctsn-pins {
+			rockchip,pins =
+				<3 RK_PC3 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart4m0_rtsn_pins: uart4m0-rtsn-pins {
+			rockchip,pins =
+				<3 RK_PC2 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart4m1_xfer_pins: uart4m1-xfer-pins {
+			rockchip,pins =
+				<1 RK_PC5 9 &pcfg_pull_up>,
+				<1 RK_PC4 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart4m1_ctsn_pins: uart4m1-ctsn-pins {
+			rockchip,pins =
+				<1 RK_PC3 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart4m1_rtsn_pins: uart4m1-rtsn-pins {
+			rockchip,pins =
+				<1 RK_PC2 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart4m2_xfer_pins: uart4m2-xfer-pins {
+			rockchip,pins =
+				<0 RK_PB5 9 &pcfg_pull_up>,
+				<0 RK_PB4 9 &pcfg_pull_up>;
+		};
+	};
+
+	uart5 {
+		/omit-if-no-ref/
+		uart5m0_xfer_pins: uart5m0-xfer-pins {
+			rockchip,pins =
+				<3 RK_PD4 9 &pcfg_pull_up>,
+				<3 RK_PD5 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart5m0_ctsn_pins: uart5m0-ctsn-pins {
+			rockchip,pins =
+				<3 RK_PD6 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart5m0_rtsn_pins: uart5m0-rtsn-pins {
+			rockchip,pins =
+				<3 RK_PD7 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart5m1_xfer_pins: uart5m1-xfer-pins {
+			rockchip,pins =
+				<2 RK_PC2 9 &pcfg_pull_up>,
+				<2 RK_PC3 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart5m1_ctsn_pins: uart5m1-ctsn-pins {
+			rockchip,pins =
+				<2 RK_PC1 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart5m1_rtsn_pins: uart5m1-rtsn-pins {
+			rockchip,pins =
+				<2 RK_PC0 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart5m2_xfer_pins: uart5m2-xfer-pins {
+			rockchip,pins =
+				<2 RK_PA4 9 &pcfg_pull_up>,
+				<2 RK_PA5 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart5m2_ctsn_pins: uart5m2-ctsn-pins {
+			rockchip,pins =
+				<2 RK_PA3 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart5m2_rtsn_pins: uart5m2-rtsn-pins {
+			rockchip,pins =
+				<2 RK_PA2 9 &pcfg_pull_none>;
+		};
+	};
+
+	uart6 {
+		/omit-if-no-ref/
+		uart6m0_xfer_pins: uart6m0-xfer-pins {
+			rockchip,pins =
+				<2 RK_PB0 9 &pcfg_pull_up>,
+				<2 RK_PB1 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart6m0_ctsn_pins: uart6m0-ctsn-pins {
+			rockchip,pins =
+				<2 RK_PB3 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart6m0_rtsn_pins: uart6m0-rtsn-pins {
+			rockchip,pins =
+				<2 RK_PB2 12 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart6m1_xfer_pins: uart6m1-xfer-pins {
+			rockchip,pins =
+				<4 RK_PB1 9 &pcfg_pull_up>,
+				<4 RK_PB0 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart6m1_ctsn_pins: uart6m1-ctsn-pins {
+			rockchip,pins =
+				<4 RK_PB3 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart6m1_rtsn_pins: uart6m1-rtsn-pins {
+			rockchip,pins =
+				<4 RK_PB2 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart6m2_xfer_pins: uart6m2-xfer-pins {
+			rockchip,pins =
+				<1 RK_PB3 9 &pcfg_pull_up>,
+				<1 RK_PB0 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart6m2_ctsn_pins: uart6m2-ctsn-pins {
+			rockchip,pins =
+				<1 RK_PA5 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart6m2_rtsn_pins: uart6m2-rtsn-pins {
+			rockchip,pins =
+				<1 RK_PA4 9 &pcfg_pull_none>;
+		};
+	};
+
+	uart7 {
+		/omit-if-no-ref/
+		uart7m0_xfer_pins: uart7m0-xfer-pins {
+			rockchip,pins =
+				<1 RK_PD1 9 &pcfg_pull_up>,
+				<1 RK_PD0 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart7m0_ctsn_pins: uart7m0-ctsn-pins {
+			rockchip,pins =
+				<1 RK_PD5 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart7m0_rtsn_pins: uart7m0-rtsn-pins {
+			rockchip,pins =
+				<1 RK_PD4 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart7m1_xfer_pins: uart7m1-xfer-pins {
+			rockchip,pins =
+				<1 RK_PA3 9 &pcfg_pull_up>,
+				<1 RK_PA2 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart7m1_ctsn_pins: uart7m1-ctsn-pins {
+			rockchip,pins =
+				<1 RK_PA1 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart7m1_rtsn_pins: uart7m1-rtsn-pins {
+			rockchip,pins =
+				<1 RK_PA0 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart7m2_xfer_pins: uart7m2-xfer-pins {
+			rockchip,pins =
+				<2 RK_PA0 14 &pcfg_pull_up>,
+				<2 RK_PA1 14 &pcfg_pull_up>;
+		};
+	};
+
+	uart8 {
+		/omit-if-no-ref/
+		uart8m0_xfer_pins: uart8m0-xfer-pins {
+			rockchip,pins =
+				<3 RK_PC5 9 &pcfg_pull_up>,
+				<3 RK_PC6 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart8m0_ctsn_pins: uart8m0-ctsn-pins {
+			rockchip,pins =
+				<3 RK_PD0 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart8m0_rtsn_pins: uart8m0-rtsn-pins {
+			rockchip,pins =
+				<3 RK_PC7 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart8m1_xfer_pins: uart8m1-xfer-pins {
+			rockchip,pins =
+				<0 RK_PC2 9 &pcfg_pull_up>,
+				<0 RK_PC1 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart8m1_ctsn_pins: uart8m1-ctsn-pins {
+			rockchip,pins =
+				<0 RK_PC7 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart8m1_rtsn_pins: uart8m1-rtsn-pins {
+			rockchip,pins =
+				<0 RK_PC6 9 &pcfg_pull_none>;
+		};
+	};
+
+	uart9 {
+		/omit-if-no-ref/
+		uart9m0_xfer_pins: uart9m0-xfer-pins {
+			rockchip,pins =
+				<4 RK_PB5 9 &pcfg_pull_up>,
+				<4 RK_PB4 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart9m0_ctsn_pins: uart9m0-ctsn-pins {
+			rockchip,pins =
+				<4 RK_PB6 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart9m0_rtsn_pins: uart9m0-rtsn-pins {
+			rockchip,pins =
+				<4 RK_PB7 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart9m1_xfer_pins: uart9m1-xfer-pins {
+			rockchip,pins =
+				<4 RK_PA1 9 &pcfg_pull_up>,
+				<4 RK_PA0 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart9m1_ctsn_pins: uart9m1-ctsn-pins {
+			rockchip,pins =
+				<3 RK_PB7 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart9m1_rtsn_pins: uart9m1-rtsn-pins {
+			rockchip,pins =
+				<3 RK_PC0 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart9m2_xfer_pins: uart9m2-xfer-pins {
+			rockchip,pins =
+				<2 RK_PB3 9 &pcfg_pull_up>,
+				<2 RK_PB2 9 &pcfg_pull_up>;
+		};
+	};
+
+	uart10 {
+		/omit-if-no-ref/
+		uart10m0_xfer_pins: uart10m0-xfer-pins {
+			rockchip,pins =
+				<3 RK_PB0 9 &pcfg_pull_up>,
+				<3 RK_PB1 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart10m0_ctsn_pins: uart10m0-ctsn-pins {
+			rockchip,pins =
+				<3 RK_PA6 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart10m0_rtsn_pins: uart10m0-rtsn-pins {
+			rockchip,pins =
+				<3 RK_PA7 10 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart10m1_xfer_pins: uart10m1-xfer-pins {
+			rockchip,pins =
+				<2 RK_PC5 9 &pcfg_pull_up>,
+				<2 RK_PC4 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart10m1_ctsn_pins: uart10m1-ctsn-pins {
+			rockchip,pins =
+				<2 RK_PC6 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart10m1_rtsn_pins: uart10m1-rtsn-pins {
+			rockchip,pins =
+				<2 RK_PC7 9 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		uart10m2_xfer_pins: uart10m2-xfer-pins {
+			rockchip,pins =
+				<0 RK_PC5 9 &pcfg_pull_up>,
+				<0 RK_PC4 9 &pcfg_pull_up>;
+		};
+	};
+
+	uart11 {
+		/omit-if-no-ref/
+		uart11m0_xfer_pins: uart11m0-xfer-pins {
+			rockchip,pins =
+				<0 RK_PD1 9 &pcfg_pull_up>,
+				<0 RK_PD0 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart11m1_xfer_pins: uart11m1-xfer-pins {
+			rockchip,pins =
+				<2 RK_PB7 9 &pcfg_pull_up>,
+				<2 RK_PB6 9 &pcfg_pull_up>;
+		};
+
+		/omit-if-no-ref/
+		uart11m2_xfer_pins: uart11m2-xfer-pins {
+			rockchip,pins =
+				<2 RK_PC7 12 &pcfg_pull_up>,
+				<2 RK_PC6 12 &pcfg_pull_up>;
+		};
+	};
+
+	ufs {
+		/omit-if-no-ref/
+		ufs_refclk_pins: ufs-refclk-pins {
+			rockchip,pins =
+				<4 RK_PC1 1 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		ufs_rst_pins: ufs-rst-pins {
+			rockchip,pins =
+				<4 RK_PC0 1 &pcfg_pull_none>;
+		};
+	};
+
+	vi_cif {
+		/omit-if-no-ref/
+		vi_cif_pins: vi-cif-pins {
+			rockchip,pins =
+				<2 RK_PD7 6 &pcfg_pull_none>,
+				<2 RK_PD6 6 &pcfg_pull_none>,
+				<2 RK_PD3 6 &pcfg_pull_none>,
+				<2 RK_PD2 6 &pcfg_pull_none>,
+				<2 RK_PD1 6 &pcfg_pull_none>,
+				<2 RK_PD0 6 &pcfg_pull_none>,
+				<2 RK_PC7 6 &pcfg_pull_none>,
+				<2 RK_PC6 6 &pcfg_pull_none>,
+				<2 RK_PC5 6 &pcfg_pull_none>,
+				<2 RK_PC4 6 &pcfg_pull_none>,
+				<2 RK_PC1 2 &pcfg_pull_none>,
+				<2 RK_PC0 2 &pcfg_pull_none>,
+				<2 RK_PB7 2 &pcfg_pull_none>,
+				<2 RK_PB6 2 &pcfg_pull_none>,
+				<2 RK_PB5 2 &pcfg_pull_none>,
+				<2 RK_PB4 2 &pcfg_pull_none>,
+				<2 RK_PB3 2 &pcfg_pull_none>,
+				<2 RK_PB2 2 &pcfg_pull_none>,
+				<2 RK_PD4 6 &pcfg_pull_none>,
+				<2 RK_PD5 6 &pcfg_pull_none>;
+		};
+	};
+
+	vo_ebc {
+		/omit-if-no-ref/
+		vo_ebc_pins: vo-ebc-pins {
+			rockchip,pins =
+				<4 RK_PA0 4 &pcfg_pull_none>,
+				<4 RK_PA1 4 &pcfg_pull_none>,
+				<3 RK_PD5 4 &pcfg_pull_none>,
+				<3 RK_PA6 4 &pcfg_pull_none>,
+				<3 RK_PA5 4 &pcfg_pull_none>,
+				<3 RK_PB3 4 &pcfg_pull_none>,
+				<3 RK_PB2 4 &pcfg_pull_none>,
+				<3 RK_PB1 4 &pcfg_pull_none>,
+				<3 RK_PB0 4 &pcfg_pull_none>,
+				<3 RK_PD6 4 &pcfg_pull_none>,
+				<3 RK_PD3 4 &pcfg_pull_none>,
+				<3 RK_PD2 4 &pcfg_pull_none>,
+				<3 RK_PD1 4 &pcfg_pull_none>,
+				<3 RK_PD0 4 &pcfg_pull_none>,
+				<3 RK_PC7 4 &pcfg_pull_none>,
+				<3 RK_PC6 4 &pcfg_pull_none>,
+				<3 RK_PC5 4 &pcfg_pull_none>,
+				<3 RK_PC4 4 &pcfg_pull_none>,
+				<3 RK_PC3 4 &pcfg_pull_none>,
+				<3 RK_PC2 4 &pcfg_pull_none>,
+				<3 RK_PC1 4 &pcfg_pull_none>,
+				<3 RK_PC0 4 &pcfg_pull_none>,
+				<3 RK_PB7 4 &pcfg_pull_none>,
+				<3 RK_PB6 4 &pcfg_pull_none>,
+				<3 RK_PB5 4 &pcfg_pull_none>,
+				<3 RK_PB4 4 &pcfg_pull_none>,
+				<4 RK_PB0 5 &pcfg_pull_none>,
+				<4 RK_PB1 5 &pcfg_pull_none>,
+				<4 RK_PB2 5 &pcfg_pull_none>,
+				<4 RK_PB3 5 &pcfg_pull_none>,
+				<4 RK_PB4 5 &pcfg_pull_none>,
+				<4 RK_PB5 5 &pcfg_pull_none>,
+				<4 RK_PB6 5 &pcfg_pull_none>,
+				<4 RK_PB7 5 &pcfg_pull_none>,
+				<3 RK_PD4 4 &pcfg_pull_none>,
+				<3 RK_PD7 4 &pcfg_pull_none>,
+				<3 RK_PA4 4 &pcfg_pull_none>,
+				<3 RK_PA7 4 &pcfg_pull_none>;
+		};
+	};
+
+	vo_lcdc {
+		/omit-if-no-ref/
+		vo_lcdc_pins: vo-lcdc-pins {
+			rockchip,pins =
+				<3 RK_PD7 3 &pcfg_pull_none>,
+				<3 RK_PD3 3 &pcfg_pull_none>,
+				<3 RK_PD2 3 &pcfg_pull_none>,
+				<3 RK_PD1 3 &pcfg_pull_none>,
+				<3 RK_PD0 3 &pcfg_pull_none>,
+				<3 RK_PC7 3 &pcfg_pull_none>,
+				<3 RK_PC6 3 &pcfg_pull_none>,
+				<3 RK_PC5 3 &pcfg_pull_none>,
+				<3 RK_PC4 3 &pcfg_pull_none>,
+				<3 RK_PC3 3 &pcfg_pull_none>,
+				<3 RK_PC2 3 &pcfg_pull_none>,
+				<3 RK_PC1 3 &pcfg_pull_none>,
+				<3 RK_PC0 3 &pcfg_pull_none>,
+				<3 RK_PB7 3 &pcfg_pull_none>,
+				<3 RK_PB6 3 &pcfg_pull_none>,
+				<3 RK_PB5 3 &pcfg_pull_none>,
+				<3 RK_PB4 3 &pcfg_pull_none>,
+				<3 RK_PB3 3 &pcfg_pull_none>,
+				<3 RK_PB2 3 &pcfg_pull_none>,
+				<3 RK_PB1 3 &pcfg_pull_none>,
+				<3 RK_PB0 3 &pcfg_pull_none>,
+				<3 RK_PA7 3 &pcfg_pull_none>,
+				<3 RK_PA6 3 &pcfg_pull_none>,
+				<3 RK_PA5 3 &pcfg_pull_none>,
+				<3 RK_PA4 3 &pcfg_pull_none>,
+				<3 RK_PD4 3 &pcfg_pull_none>,
+				<3 RK_PD5 3 &pcfg_pull_none>,
+				<3 RK_PD6 3 &pcfg_pull_none>;
+		};
+	};
+
+	vo_post {
+		/omit-if-no-ref/
+		vo_post_pins: vo-post-pins {
+			rockchip,pins =
+				<4 RK_PA1 3 &pcfg_pull_none>;
+		};
+	};
+
+	vp0_sync {
+		/omit-if-no-ref/
+		vp0_sync_pins: vp0-sync-pins {
+			rockchip,pins =
+				<4 RK_PB5 3 &pcfg_pull_none>;
+		};
+	};
+
+	vp1_sync {
+		/omit-if-no-ref/
+		vp1_sync_pins: vp1-sync-pins {
+			rockchip,pins =
+				<4 RK_PB6 3 &pcfg_pull_none>;
+		};
+	};
+};
+
+&pinctrl {
+	ebc {
+		/omit-if-no-ref/
+		ebc_24bit_pins: ebc-24bit-pins {
+			rockchip,pins =
+				<3 RK_PD5 4 &pcfg_pull_none>,
+				<3 RK_PA6 4 &pcfg_pull_none>,
+				<3 RK_PA5 4 &pcfg_pull_none>,
+				<3 RK_PB3 4 &pcfg_pull_none>,
+				<3 RK_PD6 4 &pcfg_pull_none>,
+				<3 RK_PD3 4 &pcfg_pull_none>,
+				<3 RK_PD2 4 &pcfg_pull_none>,
+				<3 RK_PD1 4 &pcfg_pull_none>,
+				<3 RK_PD0 4 &pcfg_pull_none>,
+				<3 RK_PC7 4 &pcfg_pull_none>,
+				<3 RK_PC6 4 &pcfg_pull_none>,
+				<3 RK_PC5 4 &pcfg_pull_none>,
+				<3 RK_PC4 4 &pcfg_pull_none>,
+				<3 RK_PC3 4 &pcfg_pull_none>,
+				<3 RK_PC2 4 &pcfg_pull_none>,
+				<3 RK_PC1 4 &pcfg_pull_none>,
+				<3 RK_PC0 4 &pcfg_pull_none>,
+				<3 RK_PB7 4 &pcfg_pull_none>,
+				<3 RK_PB6 4 &pcfg_pull_none>,
+				<3 RK_PB5 4 &pcfg_pull_none>,
+				<3 RK_PB4 4 &pcfg_pull_none>,
+				<4 RK_PB0 5 &pcfg_pull_none>,
+				<4 RK_PB1 5 &pcfg_pull_none>,
+				<4 RK_PB2 5 &pcfg_pull_none>,
+				<4 RK_PB3 5 &pcfg_pull_none>,
+				<4 RK_PB4 5 &pcfg_pull_none>,
+				<4 RK_PB5 5 &pcfg_pull_none>,
+				<4 RK_PB6 5 &pcfg_pull_none>,
+				<4 RK_PB7 5 &pcfg_pull_none>,
+				<3 RK_PD4 4 &pcfg_pull_none>,
+				<3 RK_PD7 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		ebc_16bit_pins: ebc-16bit-pins {
+			rockchip,pins =
+				<3 RK_PD5 4 &pcfg_pull_none>,
+				<3 RK_PA6 4 &pcfg_pull_none>,
+				<3 RK_PA5 4 &pcfg_pull_none>,
+				<3 RK_PB3 4 &pcfg_pull_none>,
+				<3 RK_PD6 4 &pcfg_pull_none>,
+				<3 RK_PD3 4 &pcfg_pull_none>,
+				<3 RK_PD2 4 &pcfg_pull_none>,
+				<3 RK_PD1 4 &pcfg_pull_none>,
+				<3 RK_PD0 4 &pcfg_pull_none>,
+				<3 RK_PC7 4 &pcfg_pull_none>,
+				<3 RK_PC6 4 &pcfg_pull_none>,
+				<3 RK_PC5 4 &pcfg_pull_none>,
+				<3 RK_PC4 4 &pcfg_pull_none>,
+				<3 RK_PC3 4 &pcfg_pull_none>,
+				<3 RK_PC2 4 &pcfg_pull_none>,
+				<3 RK_PC1 4 &pcfg_pull_none>,
+				<3 RK_PC0 4 &pcfg_pull_none>,
+				<3 RK_PB7 4 &pcfg_pull_none>,
+				<3 RK_PB6 4 &pcfg_pull_none>,
+				<3 RK_PB5 4 &pcfg_pull_none>,
+				<3 RK_PB4 4 &pcfg_pull_none>,
+				<3 RK_PD4 4 &pcfg_pull_none>,
+				<3 RK_PD7 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		ebc_8bit_pins: ebc-8bit-pins {
+			rockchip,pins =
+				<3 RK_PD5 4 &pcfg_pull_none>,
+				<3 RK_PA6 4 &pcfg_pull_none>,
+				<3 RK_PA5 4 &pcfg_pull_none>,
+				<3 RK_PB3 4 &pcfg_pull_none>,
+				<3 RK_PD6 4 &pcfg_pull_none>,
+				<3 RK_PD3 4 &pcfg_pull_none>,
+				<3 RK_PD2 4 &pcfg_pull_none>,
+				<3 RK_PD1 4 &pcfg_pull_none>,
+				<3 RK_PD0 4 &pcfg_pull_none>,
+				<3 RK_PC7 4 &pcfg_pull_none>,
+				<3 RK_PC6 4 &pcfg_pull_none>,
+				<3 RK_PC5 4 &pcfg_pull_none>,
+				<3 RK_PC4 4 &pcfg_pull_none>,
+				<3 RK_PD4 4 &pcfg_pull_none>,
+				<3 RK_PD7 4 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		ebc_extern: ebc-extern {
+			rockchip,pins =
+				<3 RK_PB2 4 &pcfg_pull_none>,
+				<3 RK_PB1 4 &pcfg_pull_none>,
+				<3 RK_PB0 4 &pcfg_pull_none>,
+				<3 RK_PA4 4 &pcfg_pull_none>,
+				<3 RK_PA7 4 &pcfg_pull_none>;
+		};
+	};
+
+	pdm {
+		/omit-if-no-ref/
+		pdmm0_clk0_idle: pdmm0-clk0-idle {
+			rockchip,pins =
+				<0 RK_PC4 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm0_clk1_idle: pdmm0-clk1-idle {
+			rockchip,pins =
+				<0 RK_PC3 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm1_clk0_idle: pdmm1-clk0-idle {
+			rockchip,pins =
+				<2 RK_PB2 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm1_clk1_idle: pdmm1-clk1-idle {
+			rockchip,pins =
+				<2 RK_PB4 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm2_clk0_idle: pdmm1-clk0-idle {
+			rockchip,pins =
+				<1 RK_PC1 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm2_clk1_idle: pdmm1-clk1-idle {
+			rockchip,pins =
+				<1 RK_PD5 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm3_clk0_idle: pdmm1-clk0-idle {
+			rockchip,pins =
+				<2 RK_PC5 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm3_clk1_idle: pdmm1-clk1-idle {
+			rockchip,pins =
+				<2 RK_PC7 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm4_clk0_idle: pdmm1-clk0-idle {
+			rockchip,pins =
+				<3 RK_PB1 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		pdmm4_clk1_idle: pdmm1-clk1-idle {
+			rockchip,pins =
+				<3 RK_PA7 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+	};
+
+	ufs {
+		/omit-if-no-ref/
+		ufs_rstgpio: ufs-rstgpio {
+			rockchip,pins =
+				<4 RK_PC0 RK_FUNC_GPIO &pcfg_pull_down>;
+		};
+	};
+
+	vo {
+		/omit-if-no-ref/
+		bt1120_pins: bt1120-pins {
+			rockchip,pins =
+				<3 RK_PD7 3 &pcfg_pull_none>,
+				<3 RK_PD0 3 &pcfg_pull_none>,
+				<3 RK_PC7 3 &pcfg_pull_none>,
+				<3 RK_PC6 3 &pcfg_pull_none>,
+				<3 RK_PC5 3 &pcfg_pull_none>,
+				<3 RK_PC4 3 &pcfg_pull_none>,
+				<3 RK_PC1 3 &pcfg_pull_none>,
+				<3 RK_PC0 3 &pcfg_pull_none>,
+				<3 RK_PB7 3 &pcfg_pull_none>,
+				<3 RK_PB6 3 &pcfg_pull_none>,
+				<3 RK_PB5 3 &pcfg_pull_none>,
+				<3 RK_PB4 3 &pcfg_pull_none>,
+				<3 RK_PB0 3 &pcfg_pull_none>,
+				<3 RK_PA7 3 &pcfg_pull_none>,
+				<3 RK_PA6 3 &pcfg_pull_none>,
+				<3 RK_PA5 3 &pcfg_pull_none>,
+				<3 RK_PA4 3 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		bt656_pins: bt656-pins {
+			rockchip,pins =
+				<3 RK_PD7 3 &pcfg_pull_none>,
+				<3 RK_PD0 3 &pcfg_pull_none>,
+				<3 RK_PC7 3 &pcfg_pull_none>,
+				<3 RK_PC6 3 &pcfg_pull_none>,
+				<3 RK_PC5 3 &pcfg_pull_none>,
+				<3 RK_PC4 3 &pcfg_pull_none>,
+				<3 RK_PC1 3 &pcfg_pull_none>,
+				<3 RK_PC0 3 &pcfg_pull_none>,
+				<3 RK_PB7 3 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		rgb3x8_pins_m0: rgb3x8-pins-m0 {
+			rockchip,pins =
+				<3 RK_PD7 3 &pcfg_pull_none>,
+				<3 RK_PD0 3 &pcfg_pull_none>,
+				<3 RK_PC7 3 &pcfg_pull_none>,
+				<3 RK_PC6 3 &pcfg_pull_none>,
+				<3 RK_PC5 3 &pcfg_pull_none>,
+				<3 RK_PC4 3 &pcfg_pull_none>,
+				<3 RK_PC1 3 &pcfg_pull_none>,
+				<3 RK_PC0 3 &pcfg_pull_none>,
+				<3 RK_PB7 3 &pcfg_pull_none>,
+				<3 RK_PD4 3 &pcfg_pull_none>,
+				<3 RK_PD5 3 &pcfg_pull_none>,
+				<3 RK_PD6 3 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		rgb3x8_pins_m1: rgb3x8-pins-m1 {
+			rockchip,pins =
+				<3 RK_PB6 3 &pcfg_pull_none>,
+				<3 RK_PB5 3 &pcfg_pull_none>,
+				<3 RK_PB4 3 &pcfg_pull_none>,
+				<3 RK_PB0 3 &pcfg_pull_none>,
+				<3 RK_PA7 3 &pcfg_pull_none>,
+				<3 RK_PA6 3 &pcfg_pull_none>,
+				<3 RK_PA5 3 &pcfg_pull_none>,
+				<3 RK_PA4 3 &pcfg_pull_none>,
+				<3 RK_PD4 3 &pcfg_pull_none>,
+				<3 RK_PD5 3 &pcfg_pull_none>,
+				<3 RK_PD6 3 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		rgb565_pins: rgb565-pins {
+			rockchip,pins =
+				<3 RK_PD7 3 &pcfg_pull_none>,
+				<3 RK_PD0 3 &pcfg_pull_none>,
+				<3 RK_PC7 3 &pcfg_pull_none>,
+				<3 RK_PC6 3 &pcfg_pull_none>,
+				<3 RK_PC5 3 &pcfg_pull_none>,
+				<3 RK_PC4 3 &pcfg_pull_none>,
+				<3 RK_PC1 3 &pcfg_pull_none>,
+				<3 RK_PC0 3 &pcfg_pull_none>,
+				<3 RK_PB7 3 &pcfg_pull_none>,
+				<3 RK_PB6 3 &pcfg_pull_none>,
+				<3 RK_PB5 3 &pcfg_pull_none>,
+				<3 RK_PB4 3 &pcfg_pull_none>,
+				<3 RK_PB0 3 &pcfg_pull_none>,
+				<3 RK_PA7 3 &pcfg_pull_none>,
+				<3 RK_PA6 3 &pcfg_pull_none>,
+				<3 RK_PA5 3 &pcfg_pull_none>,
+				<3 RK_PA4 3 &pcfg_pull_none>,
+				<3 RK_PD4 3 &pcfg_pull_none>,
+				<3 RK_PD5 3 &pcfg_pull_none>,
+				<3 RK_PD6 3 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		rgb666_pins: rgb666-pins {
+			rockchip,pins =
+				<3 RK_PD7 3 &pcfg_pull_none>,
+				<3 RK_PD1 3 &pcfg_pull_none>,
+				<3 RK_PD0 3 &pcfg_pull_none>,
+				<3 RK_PC7 3 &pcfg_pull_none>,
+				<3 RK_PC6 3 &pcfg_pull_none>,
+				<3 RK_PC5 3 &pcfg_pull_none>,
+				<3 RK_PC4 3 &pcfg_pull_none>,
+				<3 RK_PC1 3 &pcfg_pull_none>,
+				<3 RK_PC0 3 &pcfg_pull_none>,
+				<3 RK_PB7 3 &pcfg_pull_none>,
+				<3 RK_PB6 3 &pcfg_pull_none>,
+				<3 RK_PB5 3 &pcfg_pull_none>,
+				<3 RK_PB4 3 &pcfg_pull_none>,
+				<3 RK_PB1 3 &pcfg_pull_none>,
+				<3 RK_PB0 3 &pcfg_pull_none>,
+				<3 RK_PA7 3 &pcfg_pull_none>,
+				<3 RK_PA6 3 &pcfg_pull_none>,
+				<3 RK_PA5 3 &pcfg_pull_none>,
+				<3 RK_PA4 3 &pcfg_pull_none>,
+				<3 RK_PD4 3 &pcfg_pull_none>,
+				<3 RK_PD5 3 &pcfg_pull_none>,
+				<3 RK_PD6 3 &pcfg_pull_none>;
+		};
+
+		/omit-if-no-ref/
+		rgb888_pins: rgb888-pins {
+			rockchip,pins =
+				<3 RK_PD7 3 &pcfg_pull_none>,
+				<3 RK_PD3 3 &pcfg_pull_none>,
+				<3 RK_PD2 3 &pcfg_pull_none>,
+				<3 RK_PD1 3 &pcfg_pull_none>,
+				<3 RK_PD0 3 &pcfg_pull_none>,
+				<3 RK_PC7 3 &pcfg_pull_none>,
+				<3 RK_PC6 3 &pcfg_pull_none>,
+				<3 RK_PC5 3 &pcfg_pull_none>,
+				<3 RK_PC4 3 &pcfg_pull_none>,
+				<3 RK_PC3 3 &pcfg_pull_none>,
+				<3 RK_PC2 3 &pcfg_pull_none>,
+				<3 RK_PC1 3 &pcfg_pull_none>,
+				<3 RK_PC0 3 &pcfg_pull_none>,
+				<3 RK_PB7 3 &pcfg_pull_none>,
+				<3 RK_PB6 3 &pcfg_pull_none>,
+				<3 RK_PB5 3 &pcfg_pull_none>,
+				<3 RK_PB4 3 &pcfg_pull_none>,
+				<3 RK_PB3 3 &pcfg_pull_none>,
+				<3 RK_PB2 3 &pcfg_pull_none>,
+				<3 RK_PB1 3 &pcfg_pull_none>,
+				<3 RK_PB0 3 &pcfg_pull_none>,
+				<3 RK_PA7 3 &pcfg_pull_none>,
+				<3 RK_PA6 3 &pcfg_pull_none>,
+				<3 RK_PA5 3 &pcfg_pull_none>,
+				<3 RK_PA4 3 &pcfg_pull_none>,
+				<3 RK_PD4 3 &pcfg_pull_none>,
+				<3 RK_PD5 3 &pcfg_pull_none>,
+				<3 RK_PD6 3 &pcfg_pull_none>;
+		};
+	};
+};
diff --git a/arch/arm64/boot/dts/rockchip/rk3572.dtsi b/arch/arm64/boot/dts/rockchip/rk3572.dtsi
new file mode 100644
index 000000000000..db415b6da843
--- /dev/null
+++ b/arch/arm64/boot/dts/rockchip/rk3572.dtsi
@@ -0,0 +1,1325 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
+/*
+ * Copyright (c) 2025 Rockchip Electronics Co., Ltd.
+ */
+
+#include <dt-bindings/clock/rockchip,rk3572-cru.h>
+#include <dt-bindings/interrupt-controller/arm-gic.h>
+#include <dt-bindings/interrupt-controller/irq.h>
+#include <dt-bindings/phy/phy.h>
+#include <dt-bindings/pinctrl/rockchip.h>
+#include <dt-bindings/power/rockchip,rk3572-power-controller.h>
+#include <dt-bindings/reset/rockchip,rk3572-cru.h>
+#include <dt-bindings/thermal/thermal.h>
+
+/ {
+	compatible = "rockchip,rk3572";
+	#address-cells = <2>;
+	interrupt-parent = <&gic>;
+	#size-cells = <2>;
+
+	aliases {
+		i2c0 = &i2c0;
+		i2c1 = &i2c1;
+		i2c2 = &i2c2;
+		i2c3 = &i2c3;
+		i2c4 = &i2c4;
+		i2c5 = &i2c5;
+		i2c6 = &i2c6;
+		i2c7 = &i2c7;
+		i2c8 = &i2c8;
+		i2c9 = &i2c9;
+		serial0 = &uart0;
+		serial1 = &uart1;
+		serial2 = &uart2;
+		serial3 = &uart3;
+		serial4 = &uart4;
+		serial5 = &uart5;
+		serial6 = &uart6;
+		serial7 = &uart7;
+		serial8 = &uart8;
+		serial9 = &uart9;
+		serial10 = &uart10;
+		serial11 = &uart11;
+	};
+
+	spll: clock-spll {
+		compatible = "fixed-clock";
+		#clock-cells = <0>;
+		clock-frequency = <702000000>;
+		clock-output-names = "spll";
+	};
+
+	cpus {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		cpu-map {
+			cluster0 {
+				core0 {
+					cpu = <&cpu_l0>;
+				};
+
+				core1 {
+					cpu = <&cpu_l1>;
+				};
+
+				core2 {
+					cpu = <&cpu_l2>;
+				};
+
+				core3 {
+					cpu = <&cpu_l3>;
+				};
+			};
+
+			cluster1 {
+				core0 {
+					cpu = <&cpu_l4>;
+				};
+
+				core1 {
+					cpu = <&cpu_l5>;
+				};
+			};
+
+			cluster2 {
+				core0 {
+					cpu = <&cpu_b0>;
+				};
+
+				core1 {
+					cpu = <&cpu_b1>;
+				};
+			};
+		};
+
+		cpu_l0: cpu@0 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a53";
+			reg = <0x0>;
+			capacity-dmips-mhz = <669>;
+			clocks = <&scmi_clk ARMCLK_L0>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			d-cache-size = <0x8000>;
+			enable-method = "psci";
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			i-cache-size = <0x8000>;
+			next-level-cache = <&l2_cache_l0>;
+		};
+
+		cpu_l1: cpu@1 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a53";
+			reg = <0x1>;
+			capacity-dmips-mhz = <669>;
+			clocks = <&scmi_clk ARMCLK_L0>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			d-cache-size = <0x8000>;
+			enable-method = "psci";
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			i-cache-size = <0x8000>;
+			next-level-cache = <&l2_cache_l0>;
+		};
+
+		cpu_l2: cpu@2 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a53";
+			reg = <0x2>;
+			capacity-dmips-mhz = <669>;
+			clocks = <&scmi_clk ARMCLK_L0>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			d-cache-size = <0x8000>;
+			enable-method = "psci";
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			i-cache-size = <0x8000>;
+			next-level-cache = <&l2_cache_l0>;
+		};
+
+		cpu_l3: cpu@3 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a53";
+			reg = <0x3>;
+			capacity-dmips-mhz = <669>;
+			clocks = <&scmi_clk ARMCLK_L0>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			d-cache-size = <0x8000>;
+			enable-method = "psci";
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			i-cache-size = <0x8000>;
+			next-level-cache = <&l2_cache_l0>;
+		};
+
+		cpu_l4: cpu@100 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a53";
+			reg = <0x100>;
+			capacity-dmips-mhz = <563>;
+			clocks = <&scmi_clk ARMCLK_L1>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			d-cache-size = <0x8000>;
+			enable-method = "psci";
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			i-cache-size = <0x8000>;
+			next-level-cache = <&l2_cache_l1>;
+		};
+
+		cpu_l5: cpu@101 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a53";
+			reg = <0x101>;
+			capacity-dmips-mhz = <563>;
+			clocks = <&scmi_clk ARMCLK_L1>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			d-cache-size = <0x8000>;
+			enable-method = "psci";
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			i-cache-size = <0x8000>;
+			next-level-cache = <&l2_cache_l1>;
+		};
+
+		cpu_b0: cpu@200 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a73";
+			reg = <0x200>;
+			capacity-dmips-mhz = <1024>;
+			clocks = <&scmi_clk ARMCLK_B>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			d-cache-size = <0x8000>;
+			enable-method = "psci";
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			i-cache-size = <0x10000>;
+			next-level-cache = <&l2_cache_b>;
+		};
+
+		cpu_b1: cpu@201 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a73";
+			reg = <0x201>;
+			capacity-dmips-mhz = <1024>;
+			clocks = <&scmi_clk ARMCLK_B>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			d-cache-size = <0x8000>;
+			enable-method = "psci";
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			i-cache-size = <0x10000>;
+			next-level-cache = <&l2_cache_b>;
+		};
+
+		l2_cache_l0: l2-cache-cluster0 {
+			compatible = "cache";
+			cache-level = <2>;
+			cache-line-size = <64>;
+			cache-sets = <512>;
+			cache-size = <0x80000>;
+			cache-unified;
+		};
+
+		l2_cache_l1: l2-cache-cluster1 {
+			compatible = "cache";
+			cache-level = <2>;
+			cache-line-size = <64>;
+			cache-sets = <256>;
+			cache-size = <0x40000>;
+			cache-unified;
+		};
+
+		l2_cache_b: l2-cache-cluster2 {
+			compatible = "cache";
+			cache-level = <2>;
+			cache-line-size = <64>;
+			cache-sets = <512>;
+			cache-size = <0x80000>;
+			cache-unified;
+		};
+	};
+
+	firmware {
+		scmi: scmi {
+			compatible = "arm,scmi-smc";
+			#address-cells = <1>;
+			shmem = <&scmi_shmem>;
+			#size-cells = <0>;
+			arm,smc-id = <0x82000010>;
+
+			scmi_clk: protocol@14 {
+				reg = <0x14>;
+				#clock-cells = <1>;
+			};
+		};
+	};
+
+	pinctrl: pinctrl {
+		compatible = "rockchip,rk3572-pinctrl";
+		ranges;
+		#address-cells = <2>;
+		#size-cells = <2>;
+		rockchip,grf = <&ioc_grf>;
+
+		gpio0: gpio@26300000 {
+			compatible = "rockchip,rk3572-gpio-bank";
+			reg = <0x0 0x26300000 0x0 0x200>;
+			clocks = <&cru PCLK_GPIO0>, <&cru DBCLK_GPIO0>;
+			#gpio-cells = <2>;
+			gpio-controller;
+			gpio-ranges = <&pinctrl 0 0 32>;
+			#interrupt-cells = <2>;
+			interrupt-controller;
+			interrupts = <GIC_SPI 104 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 105 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 106 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 107 IRQ_TYPE_LEVEL_HIGH>;
+		};
+
+		gpio1: gpio@2b200000 {
+			compatible = "rockchip,rk3572-gpio-bank";
+			reg = <0x0 0x2b200000 0x0 0x200>;
+			clocks = <&cru PCLK_GPIO1>, <&cru DBCLK_GPIO1>;
+			#gpio-cells = <2>;
+			gpio-controller;
+			gpio-ranges = <&pinctrl 0 32 32>;
+			#interrupt-cells = <2>;
+			interrupt-controller;
+			interrupts = <GIC_SPI 108 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 109 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 110 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 111 IRQ_TYPE_LEVEL_HIGH>;
+		};
+
+		gpio2: gpio@2b300000 {
+			compatible = "rockchip,rk3572-gpio-bank";
+			reg = <0x0 0x2b300000 0x0 0x200>;
+			clocks = <&cru PCLK_GPIO2>, <&cru DBCLK_GPIO2>;
+			#gpio-cells = <2>;
+			gpio-controller;
+			gpio-ranges = <&pinctrl 0 64 32>;
+			#interrupt-cells = <2>;
+			interrupt-controller;
+			interrupts = <GIC_SPI 112 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 113 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 114 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 115 IRQ_TYPE_LEVEL_HIGH>;
+		};
+
+		gpio3: gpio@2b400000 {
+			compatible = "rockchip,rk3572-gpio-bank";
+			reg = <0x0 0x2b400000 0x0 0x200>;
+			clocks = <&cru PCLK_GPIO3>, <&cru DBCLK_GPIO3>;
+			#gpio-cells = <2>;
+			gpio-controller;
+			gpio-ranges = <&pinctrl 0 96 32>;
+			#interrupt-cells = <2>;
+			interrupt-controller;
+			interrupts = <GIC_SPI 116 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 117 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 118 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 119 IRQ_TYPE_LEVEL_HIGH>;
+		};
+
+		gpio4: gpio@2b500000 {
+			compatible = "rockchip,rk3572-gpio-bank";
+			reg = <0x0 0x2b500000 0x0 0x200>;
+			clocks = <&cru PCLK_GPIO4>, <&cru DBCLK_GPIO4>;
+			#gpio-cells = <2>;
+			gpio-controller;
+			gpio-ranges = <&pinctrl 0 128 32>;
+			#interrupt-cells = <2>;
+			interrupt-controller;
+			interrupts = <GIC_SPI 120 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 121 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 122 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 123 IRQ_TYPE_LEVEL_HIGH>;
+		};
+	};
+
+	psci: psci {
+		compatible = "arm,psci-1.0";
+		method = "smc";
+	};
+
+	soc {
+		compatible = "simple-bus";
+		ranges;
+		#address-cells = <2>;
+		#size-cells = <2>;
+
+		usb_drd0_dwc3: usb@24000000 {
+			compatible = "rockchip,rk3572-dwc3";
+			reg = <0x0 0x24000000 0x0 0x400000>;
+			clocks = <&cru CLK_REF_USB3OTG0>,
+				 <&cru CLK_SUSPEND_USB3OTG0>,
+				 <&cru ACLK_USB3OTG0>;
+			clock-names = "ref_clk", "suspend_clk", "bus_clk";
+			dma-coherent;
+			interrupts = <GIC_SPI 253 IRQ_TYPE_LEVEL_HIGH>;
+			phy_type = "utmi_wide";
+			phys = <&u2phy0_otg>, <&combphy0_psu PHY_TYPE_USB3>;
+			phy-names = "usb2-phy", "usb3-phy";
+			power-domains = <&power RK3572_PD_PHP>;
+			resets = <&cru SRST_ARESETN_USB3OTG0>;
+			rockchip,grf = <&php_grf 0x14>;
+			snps,dis-u1-entry-quirk;
+			snps,dis-u2-entry-quirk;
+			snps,dis-u2-freeclk-exists-quirk;
+			snps,dis_enblslpm_quirk;
+			snps,parkmode-disable-hs-quirk;
+			snps,parkmode-disable-ss-quirk;
+
+			status = "disabled";
+		};
+
+		usb_drd1_dwc3: usb@24400000 {
+			compatible = "rockchip,rk3572-dwc3";
+			reg = <0x0 0x24400000 0x0 0x400000>;
+			clocks = <&cru CLK_REF_USB3OTG1>,
+				 <&cru CLK_SUSPEND_USB3OTG1>,
+				 <&cru ACLK_USB3OTG1>;
+			clock-names = "ref_clk", "suspend_clk", "bus_clk";
+			dma-coherent;
+			interrupts = <GIC_SPI 254 IRQ_TYPE_LEVEL_HIGH>;
+			phy_type = "utmi_wide";
+			phys = <&u2phy1_otg>, <&combphy1_psu PHY_TYPE_USB3>;
+			phy-names = "usb2-phy", "usb3-phy";
+			power-domains = <&power RK3572_PD_PHP>;
+			resets = <&cru SRST_ARESETN_USB3OTG1>;
+			rockchip,grf = <&php_grf 0x34>;
+			snps,dis-u1-entry-quirk;
+			snps,dis-u2-entry-quirk;
+			snps,dis-u2-freeclk-exists-quirk;
+			snps,dis_enblslpm_quirk;
+			snps,parkmode-disable-hs-quirk;
+			snps,parkmode-disable-ss-quirk;
+
+			status = "disabled";
+		};
+
+		sys_grf: syscon@26010000 {
+			compatible = "rockchip,rk3572-sys-grf", "syscon";
+			reg = <0x0 0x26010000 0x0 0x2000>;
+		};
+
+		php_grf: syscon@26026000 {
+			compatible = "rockchip,rk3572-php-grf", "syscon";
+			reg = <0x0 0x26026000 0x0 0x1000>;
+			clocks = <&cru PCLK_PHPSUBSYS_ROOT>;
+		};
+
+		nvm0_grf: syscon@2602a000 {
+			compatible = "rockchip,rk3572-nvm0-grf", "syscon";
+			reg = <0x0 0x2602a000 0x0 0x1000>;
+			clocks = <&cru PCLK_NVM0_ROOT>;
+		};
+
+		pmu0_grf: syscon@26040000 {
+			compatible = "rockchip,rk3572-pmu0-grf", "syscon";
+			reg = <0x0 0x26040000 0x0 0x1000>;
+		};
+
+		pipe_phy0_grf: syscon@2604e000 {
+			compatible = "rockchip,rk3572-pipe-phy-grf", "syscon";
+			reg = <0x0 0x2604e000 0x0 0x2000>;
+			clocks = <&cru PCLK_PHPSUBSYS_ROOT>;
+		};
+
+		pipe_phy1_grf: syscon@26050000 {
+			compatible = "rockchip,rk3572-pipe-phy-grf", "syscon";
+			reg = <0x0 0x26050000 0x0 0x2000>;
+			clocks = <&cru PCLK_PHPSUBSYS_ROOT>;
+		};
+
+		usb2phy_grf: syscon@26054000 {
+			compatible = "rockchip,rk3572-usb2phy-grf",
+				     "syscon",
+				     "simple-mfd";
+			reg = <0x0 0x26054000 0x0 0x4000>;
+			#address-cells = <1>;
+			clocks = <&cru PCLK_PHPSUBSYS_ROOT>;
+			#size-cells = <1>;
+
+			u2phy0: usb2phy@0 {
+				compatible = "rockchip,rk3572-usb2phy";
+				reg = <0x0 0x10>;
+				#clock-cells = <0>;
+				clock-output-names = "usb480m_phy0";
+				clocks = <&xin24m>, <&cru PCLK_PHPSUBSYS_ROOT>;
+				clock-names = "phyclk", "pclk";
+				resets = <&cru SRST_RESETN_OTGPHY_0>,
+					 <&cru SRST_PRESETN_USBPHY_GRF_0>;
+				reset-names = "phy", "apb";
+
+				status = "disabled";
+
+				u2phy0_otg: otg-port {
+					interrupts = <GIC_SPI 288
+						     IRQ_TYPE_LEVEL_HIGH>,
+						     <GIC_SPI 289
+						     IRQ_TYPE_LEVEL_HIGH>,
+						     <GIC_SPI 290
+						     IRQ_TYPE_LEVEL_HIGH>;
+					interrupt-names = "otg-bvalid",
+							  "otg-id",
+							  "linestate";
+					#phy-cells = <0>;
+
+					status = "disabled";
+				};
+			};
+
+			u2phy1: usb2phy@2000 {
+				compatible = "rockchip,rk3572-usb2phy";
+				reg = <0x2000 0x10>;
+				#clock-cells = <0>;
+				clock-output-names = "usb480m_phy1";
+				clocks = <&xin24m>, <&cru PCLK_PHPSUBSYS_ROOT>;
+				clock-names = "phyclk", "pclk";
+				resets = <&cru SRST_RESETN_OTGPHY_1>,
+					 <&cru SRST_PRESETN_USBPHY_GRF_1>;
+				reset-names = "phy", "apb";
+
+				status = "disabled";
+
+				u2phy1_otg: otg-port {
+					interrupts = <GIC_SPI 293
+						     IRQ_TYPE_LEVEL_HIGH>,
+						     <GIC_SPI 294
+						     IRQ_TYPE_LEVEL_HIGH>,
+						     <GIC_SPI 295
+						     IRQ_TYPE_LEVEL_HIGH>;
+					interrupt-names = "otg-bvalid",
+							  "otg-id",
+							  "linestate";
+					#phy-cells = <0>;
+
+					status = "disabled";
+				};
+			};
+		};
+
+		ioc_grf: syscon@26072000 {
+			compatible = "rockchip,rk3572-ioc-grf", "syscon";
+			reg = <0x0 0x26072000 0x0 0x16000>;
+		};
+
+		cru: clock-controller@26090000 {
+			compatible = "rockchip,rk3572-cru";
+			reg = <0x0 0x26090000 0x0 0x60000>;
+			assigned-clock-rates = <1000000000>,
+					       <18432000>,
+					       <96000000>,
+					       <128000000>;
+			assigned-clocks = <&cru PLL_CPLL>,
+					  <&cru CLK_UART_FRAC_0>,
+					  <&cru CLK_UART_FRAC_1>,
+					  <&cru CLK_UART_FRAC_2>;
+			#clock-cells = <1>;
+			clocks = <&xin24m>;
+			clock-names = "xin24m";
+			#reset-cells = <1>;
+			rockchip,grf = <&pmu0_grf>;
+		};
+
+		uart1: serial@26500000 {
+			compatible = "rockchip,rk3572-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x26500000 0x0 0x100>;
+			clocks = <&cru SCLK_UART1>, <&cru PCLK_UART1>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupts = <GIC_SPI 125 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&uart1m0_xfer_pins>;
+			pinctrl-names = "default";
+			reg-io-width = <4>;
+			reg-shift = <2>;
+
+			status = "disabled";
+		};
+
+		i2c0: i2c@26520000 {
+			compatible = "rockchip,rk3572-i2c",
+				     "rockchip,rk3399-i2c";
+			reg = <0x0 0x26520000 0x0 0x1000>;
+			#address-cells = <1>;
+			clocks = <&cru CLK_I2C0>, <&cru PCLK_I2C0>;
+			clock-names = "i2c", "pclk";
+			interrupts = <GIC_SPI 89 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&i2c0m0_xfer_pins>;
+			pinctrl-names = "default";
+			#size-cells = <0>;
+
+			status = "disabled";
+		};
+
+		pmu: power-management@26550000 {
+			compatible = "rockchip,rk3572-pmu",
+				     "syscon",
+				     "simple-mfd";
+			reg = <0x0 0x26550000 0x0 0x1000>;
+
+			power: power-controller {
+				compatible = "rockchip,rk3572-power-controller";
+				#address-cells = <1>;
+				#power-domain-cells = <1>;
+				#size-cells = <0>;
+				rockchip,grf = <&sys_grf>;
+
+				power-domain@3 {
+					reg = <RK3572_PD_NVM1>;
+					pm_qos = <&qos_fspi1>, <&qos_sdmmc0>;
+					#power-domain-cells = <0>;
+				};
+
+				power-domain@5 {
+					reg = <RK3572_PD_PHP>;
+					pm_qos = <&qos_gmac0>,
+						 <&qos_pcie0>,
+						 <&qos_pcie1>,
+						 <&qos_sata0>,
+						 <&qos_sata1>,
+						 <&qos_ufshc>,
+						 <&qos_usb0>,
+						 <&qos_usb1>;
+					#power-domain-cells = <0>;
+				};
+
+				power-domain@c {
+					reg = <RK3572_PD_VOP>;
+					#address-cells = <1>;
+					pm_qos = <&qos_vop_m0>, <&qos_vop_m1ro>;
+					#power-domain-cells = <0>;
+					#size-cells = <0>;
+
+					power-domain@2 {
+						reg = <RK3572_PD_NVM0>;
+						pm_qos = <&qos_emmc>,
+							 <&qos_fspi0>,
+							 <&qos_gmac1>,
+							 <&qos_sdmmc1>;
+						#power-domain-cells = <0>;
+					};
+				};
+			};
+		};
+
+		qos_fspi1: qos@27802000 {
+			compatible = "rockchip,rk3572-qos", "syscon";
+			reg = <0x0 0x27802000 0x0 0x20>;
+		};
+
+		qos_sdmmc0: qos@27802080 {
+			compatible = "rockchip,rk3572-qos", "syscon";
+			reg = <0x0 0x27802080 0x0 0x20>;
+		};
+
+		qos_emmc: qos@27809000 {
+			compatible = "rockchip,rk3572-qos", "syscon";
+			reg = <0x0 0x27809000 0x0 0x20>;
+		};
+
+		qos_fspi0: qos@27809080 {
+			compatible = "rockchip,rk3572-qos", "syscon";
+			reg = <0x0 0x27809080 0x0 0x20>;
+		};
+
+		qos_gmac1: qos@27809100 {
+			compatible = "rockchip,rk3572-qos", "syscon";
+			reg = <0x0 0x27809100 0x0 0x20>;
+		};
+
+		qos_sdmmc1: qos@27809180 {
+			compatible = "rockchip,rk3572-qos", "syscon";
+			reg = <0x0 0x27809180 0x0 0x20>;
+		};
+
+		qos_gmac0: qos@2780a000 {
+			compatible = "rockchip,rk3572-qos", "syscon";
+			reg = <0x0 0x2780a000 0x0 0x20>;
+		};
+
+		qos_pcie0: qos@2780a080 {
+			compatible = "rockchip,rk3572-qos", "syscon";
+			reg = <0x0 0x2780a080 0x0 0x20>;
+		};
+
+		qos_pcie1: qos@2780a100 {
+			compatible = "rockchip,rk3572-qos", "syscon";
+			reg = <0x0 0x2780a100 0x0 0x20>;
+		};
+
+		qos_sata0: qos@2780a180 {
+			compatible = "rockchip,rk3572-qos", "syscon";
+			reg = <0x0 0x2780a180 0x0 0x20>;
+		};
+
+		qos_sata1: qos@2780a200 {
+			compatible = "rockchip,rk3572-qos", "syscon";
+			reg = <0x0 0x2780a200 0x0 0x20>;
+		};
+
+		qos_ufshc: qos@2780a280 {
+			compatible = "rockchip,rk3572-qos", "syscon";
+			reg = <0x0 0x2780a280 0x0 0x20>;
+		};
+
+		qos_usb0: qos@2780a300 {
+			compatible = "rockchip,rk3572-qos", "syscon";
+			reg = <0x0 0x2780a300 0x0 0x20>;
+		};
+
+		qos_usb1: qos@2780a380 {
+			compatible = "rockchip,rk3572-qos", "syscon";
+			reg = <0x0 0x2780a380 0x0 0x20>;
+		};
+
+		qos_vop_m0: qos@27812800 {
+			compatible = "rockchip,rk3572-qos", "syscon";
+			reg = <0x0 0x27812800 0x0 0x20>;
+		};
+
+		qos_vop_m1ro: qos@27812880 {
+			compatible = "rockchip,rk3572-qos", "syscon";
+			reg = <0x0 0x27812880 0x0 0x20>;
+		};
+
+		gmac0: ethernet@29d20000 {
+			compatible = "rockchip,rk3572-gmac", "snps,dwmac-4.20a";
+			reg = <0x0 0x29d20000 0x0 0x10000>;
+			clocks = <&cru CLK_GMAC0_125M_SRC>,
+				 <&cru CLK_GMAC0_RMII_CRU>,
+				 <&cru PCLK_GMAC0>,
+				 <&cru ACLK_GMAC0>,
+				 <&cru CLK_GMAC0_PTP_REF_SRC>;
+			clock-names = "stmmaceth", "clk_mac_ref",
+				      "pclk_mac", "aclk_mac",
+				      "ptp_ref";
+			dma-coherent;
+			interrupts = <GIC_SPI 228 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 233 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "macirq", "eth_wake_irq";
+			power-domains = <&power RK3572_PD_PHP>;
+			resets = <&cru SRST_ARESETN_GMAC0>;
+			reset-names = "stmmaceth";
+			rockchip,grf = <&php_grf>;
+			rockchip,php-grf = <&ioc_grf>;
+			snps,axi-config = <&gmac0_stmmac_axi_setup>;
+			snps,mixed-burst;
+			snps,mtl-rx-config = <&gmac0_mtl_rx_setup>;
+			snps,mtl-tx-config = <&gmac0_mtl_tx_setup>;
+			snps,tso;
+
+			status = "disabled";
+
+			mdio0: mdio {
+				compatible = "snps,dwmac-mdio";
+				#address-cells = <0x1>;
+				#size-cells = <0x0>;
+			};
+
+			gmac0_mtl_rx_setup: rx-queues-config {
+				snps,rx-queues-to-use = <1>;
+
+				queue0 {
+				};
+			};
+
+			gmac0_stmmac_axi_setup: stmmac-axi-config {
+				snps,blen = <0 0 0 0 16 8 4>;
+				snps,rd_osr_lmt = <8>;
+				snps,wr_osr_lmt = <4>;
+			};
+
+			gmac0_mtl_tx_setup: tx-queues-config {
+				snps,tx-queues-to-use = <1>;
+
+				queue0 {
+				};
+			};
+		};
+
+		sdhci: mmc@2a010000 {
+			compatible = "rockchip,rk3572-dwcmshc",
+				     "rockchip,rk3576-dwcmshc";
+			reg = <0x0 0x2a010000 0x0 0x10000>;
+			assigned-clock-rates = <200000000>,
+					       <24000000>,
+					       <200000000>;
+			assigned-clocks = <&cru BCLK_EMMC>,
+					  <&cru TCLK_EMMC>,
+					  <&cru CCLK_SRC_EMMC>;
+			clocks = <&cru CCLK_SRC_EMMC>, <&cru HCLK_EMMC>,
+				 <&cru ACLK_EMMC>, <&cru BCLK_EMMC>,
+				 <&cru TCLK_EMMC>;
+			clock-names = "core", "bus", "axi", "block", "timer";
+			interrupts = <GIC_SPI 243 IRQ_TYPE_LEVEL_HIGH>;
+			max-frequency = <200000000>;
+			power-domains = <&power RK3572_PD_NVM0>;
+			resets = <&cru SRST_CRESETN_EMMC>,
+				 <&cru SRST_HRESETN_EMMC>,
+				 <&cru SRST_ARESETN_EMMC>,
+				 <&cru SRST_BRESETN_EMMC>,
+				 <&cru SRST_TRESETN_EMMC>;
+			reset-names = "core", "bus", "axi", "block", "timer";
+			supports-cqe;
+
+			status = "disabled";
+		};
+
+		gmac1: ethernet@2a040000 {
+			compatible = "rockchip,rk3572-gmac", "snps,dwmac-4.20a";
+			reg = <0x0 0x2a040000 0x0 0x10000>;
+			clocks = <&cru CLK_GMAC1_125M_SRC>,
+				 <&cru CLK_GMAC1_RMII_CRU>,
+				 <&cru PCLK_GMAC1>,
+				 <&cru ACLK_GMAC1>,
+				 <&cru CLK_GMAC1_PTP_REF>;
+			clock-names = "stmmaceth", "clk_mac_ref",
+				      "pclk_mac", "aclk_mac",
+				      "ptp_ref";
+			dma-coherent;
+			interrupts = <GIC_SPI 236 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 241 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "macirq", "eth_wake_irq";
+			power-domains = <&power RK3572_PD_NVM0>;
+			resets = <&cru SRST_ARESETN_GMAC1>;
+			reset-names = "stmmaceth";
+			rockchip,grf = <&nvm0_grf>;
+			rockchip,php-grf = <&ioc_grf>;
+			snps,axi-config = <&gmac1_stmmac_axi_setup>;
+			snps,mixed-burst;
+			snps,mtl-rx-config = <&gmac1_mtl_rx_setup>;
+			snps,mtl-tx-config = <&gmac1_mtl_tx_setup>;
+			snps,tso;
+
+			status = "disabled";
+
+			mdio1: mdio {
+				compatible = "snps,dwmac-mdio";
+				#address-cells = <0x1>;
+				#size-cells = <0x0>;
+			};
+
+			gmac1_mtl_rx_setup: rx-queues-config {
+				snps,rx-queues-to-use = <1>;
+
+				queue0 {
+				};
+			};
+
+			gmac1_stmmac_axi_setup: stmmac-axi-config {
+				snps,blen = <0 0 0 0 16 8 4>;
+				snps,rd_osr_lmt = <8>;
+				snps,wr_osr_lmt = <4>;
+			};
+
+			gmac1_mtl_tx_setup: tx-queues-config {
+				snps,tx-queues-to-use = <1>;
+
+				queue0 {
+				};
+			};
+		};
+
+		sdmmc0: mmc@2a090000 {
+			compatible = "rockchip,rk3572-dw-mshc",
+				     "rockchip,rk3576-dw-mshc";
+			reg = <0x0 0x2a090000 0x0 0x4000>;
+			clocks = <&cru HCLK_SDMMC0>, <&cru CCLK_SRC_SDMMC0>;
+			clock-names = "biu", "ciu";
+			fifo-depth = <0x100>;
+			interrupts = <GIC_SPI 244 IRQ_TYPE_LEVEL_HIGH>;
+			max-frequency = <200000000>;
+			pinctrl-0 = <&sdmmc0m0_bus4_pins &sdmmc0m0_clk_pins
+				    &sdmmc0m0_cmd_pins &sdmmc0m0_det_pins>;
+			pinctrl-names = "default";
+			power-domains = <&power RK3572_PD_NVM1>;
+			resets = <&cru SRST_HRESETN_SDMMC0>;
+			reset-names = "reset";
+
+			status = "disabled";
+		};
+
+		gic: interrupt-controller@2a601000 {
+			compatible = "arm,gic-400";
+			reg = <0x0 0x2a601000 0 0x1000>,
+			      <0x0 0x2a602000 0 0x2000>,
+			      <0x0 0x2a604000 0 0x2000>,
+			      <0x0 0x2a606000 0 0x2000>;
+			#address-cells = <0>;
+			#interrupt-cells = <3>;
+			interrupt-controller;
+			interrupts = <GIC_PPI 9 (GIC_CPU_MASK_SIMPLE(8) |
+				     IRQ_TYPE_LEVEL_LOW)>;
+		};
+
+		i2c1: i2c@2c030000 {
+			compatible = "rockchip,rk3572-i2c",
+				     "rockchip,rk3399-i2c";
+			reg = <0x0 0x2c030000 0x0 0x1000>;
+			#address-cells = <1>;
+			clocks = <&cru CLK_I2C1>, <&cru PCLK_I2C1>;
+			clock-names = "i2c", "pclk";
+			interrupts = <GIC_SPI 90 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&i2c1m0_xfer_pins>;
+			pinctrl-names = "default";
+			#size-cells = <0>;
+
+			status = "disabled";
+		};
+
+		i2c2: i2c@2c040000 {
+			compatible = "rockchip,rk3572-i2c",
+				     "rockchip,rk3399-i2c";
+			reg = <0x0 0x2c040000 0x0 0x1000>;
+			#address-cells = <1>;
+			clocks = <&cru CLK_I2C2>, <&cru PCLK_I2C2>;
+			clock-names = "i2c", "pclk";
+			interrupts = <GIC_SPI 91 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&i2c2m0_xfer_pins>;
+			pinctrl-names = "default";
+			#size-cells = <0>;
+
+			status = "disabled";
+		};
+
+		i2c3: i2c@2c050000 {
+			compatible = "rockchip,rk3572-i2c",
+				     "rockchip,rk3399-i2c";
+			reg = <0x0 0x2c050000 0x0 0x1000>;
+			#address-cells = <1>;
+			clocks = <&cru CLK_I2C3>, <&cru PCLK_I2C3>;
+			clock-names = "i2c", "pclk";
+			interrupts = <GIC_SPI 92 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&i2c3m0_xfer_pins>;
+			pinctrl-names = "default";
+			#size-cells = <0>;
+
+			status = "disabled";
+		};
+
+		i2c4: i2c@2c060000 {
+			compatible = "rockchip,rk3572-i2c",
+				     "rockchip,rk3399-i2c";
+			reg = <0x0 0x2c060000 0x0 0x1000>;
+			#address-cells = <1>;
+			clocks = <&cru CLK_I2C4>, <&cru PCLK_I2C4>;
+			clock-names = "i2c", "pclk";
+			interrupts = <GIC_SPI 93 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&i2c4m0_xfer_pins>;
+			pinctrl-names = "default";
+			#size-cells = <0>;
+
+			status = "disabled";
+		};
+
+		i2c5: i2c@2c070000 {
+			compatible = "rockchip,rk3572-i2c",
+				     "rockchip,rk3399-i2c";
+			reg = <0x0 0x2c070000 0x0 0x1000>;
+			#address-cells = <1>;
+			clocks = <&cru CLK_I2C5>, <&cru PCLK_I2C5>;
+			clock-names = "i2c", "pclk";
+			interrupts = <GIC_SPI 94 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&i2c5m0_xfer_pins>;
+			pinctrl-names = "default";
+			#size-cells = <0>;
+
+			status = "disabled";
+		};
+
+		i2c6: i2c@2c080000 {
+			compatible = "rockchip,rk3572-i2c",
+				     "rockchip,rk3399-i2c";
+			reg = <0x0 0x2c080000 0x0 0x1000>;
+			#address-cells = <1>;
+			clocks = <&cru CLK_I2C6>, <&cru PCLK_I2C6>;
+			clock-names = "i2c", "pclk";
+			interrupts = <GIC_SPI 95 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&i2c6m0_xfer_pins>;
+			pinctrl-names = "default";
+			#size-cells = <0>;
+
+			status = "disabled";
+		};
+
+		i2c7: i2c@2c090000 {
+			compatible = "rockchip,rk3572-i2c",
+				     "rockchip,rk3399-i2c";
+			reg = <0x0 0x2c090000 0x0 0x1000>;
+			#address-cells = <1>;
+			clocks = <&cru CLK_I2C7>, <&cru PCLK_I2C7>;
+			clock-names = "i2c", "pclk";
+			interrupts = <GIC_SPI 96 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&i2c7m0_xfer_pins>;
+			pinctrl-names = "default";
+			#size-cells = <0>;
+
+			status = "disabled";
+		};
+
+		i2c8: i2c@2c0a0000 {
+			compatible = "rockchip,rk3572-i2c",
+				     "rockchip,rk3399-i2c";
+			reg = <0x0 0x2c0a0000 0x0 0x1000>;
+			#address-cells = <1>;
+			clocks = <&cru CLK_I2C8>, <&cru PCLK_I2C8>;
+			clock-names = "i2c", "pclk";
+			interrupts = <GIC_SPI 97 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&i2c8m0_xfer_pins>;
+			pinctrl-names = "default";
+			#size-cells = <0>;
+
+			status = "disabled";
+		};
+
+		i2c9: i2c@2c0b0000 {
+			compatible = "rockchip,rk3572-i2c",
+				     "rockchip,rk3399-i2c";
+			reg = <0x0 0x2c0b0000 0x0 0x1000>;
+			#address-cells = <1>;
+			clocks = <&cru CLK_I2C9>, <&cru PCLK_I2C9>;
+			clock-names = "i2c", "pclk";
+			interrupts = <GIC_SPI 98 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&i2c9m0_xfer_pins>;
+			pinctrl-names = "default";
+			#size-cells = <0>;
+
+			status = "disabled";
+		};
+
+		wdt: watchdog@2c0c0000 {
+			compatible = "snps,dw-wdt";
+			reg = <0x0 0x2c0c0000 0x0 0x100>;
+			clocks = <&cru TCLK_WDT0>, <&cru PCLK_WDT0>;
+			clock-names = "tclk", "pclk";
+			interrupts = <GIC_SPI 25 IRQ_TYPE_LEVEL_HIGH>;
+
+			status = "disabled";
+		};
+
+		uart0: serial@2c130000 {
+			compatible = "rockchip,rk3572-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x2c130000 0x0 0x100>;
+			clocks = <&cru SCLK_UART0>, <&cru PCLK_UART0>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupts = <GIC_SPI 124 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&uart0m0_xfer_pins>;
+			pinctrl-names = "default";
+			reg-io-width = <4>;
+			reg-shift = <2>;
+
+			status = "disabled";
+		};
+
+		uart2: serial@2c140000 {
+			compatible = "rockchip,rk3572-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x2c140000 0x0 0x100>;
+			clocks = <&cru SCLK_UART2>, <&cru PCLK_UART2>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupts = <GIC_SPI 126 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&uart2m0_xfer_pins>;
+			pinctrl-names = "default";
+			reg-io-width = <4>;
+			reg-shift = <2>;
+
+			status = "disabled";
+		};
+
+		uart3: serial@2c150000 {
+			compatible = "rockchip,rk3572-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x2c150000 0x0 0x100>;
+			clocks = <&cru SCLK_UART3>, <&cru PCLK_UART3>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupts = <GIC_SPI 127 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&uart3m0_xfer_pins>;
+			pinctrl-names = "default";
+			reg-io-width = <4>;
+			reg-shift = <2>;
+
+			status = "disabled";
+		};
+
+		uart4: serial@2c160000 {
+			compatible = "rockchip,rk3572-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x2c160000 0x0 0x100>;
+			clocks = <&cru SCLK_UART4>, <&cru PCLK_UART4>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupts = <GIC_SPI 128 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&uart4m0_xfer_pins>;
+			pinctrl-names = "default";
+			reg-io-width = <4>;
+			reg-shift = <2>;
+
+			status = "disabled";
+		};
+
+		uart5: serial@2c170000 {
+			compatible = "rockchip,rk3572-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x2c170000 0x0 0x100>;
+			clocks = <&cru SCLK_UART5>, <&cru PCLK_UART5>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupts = <GIC_SPI 129 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&uart5m0_xfer_pins>;
+			pinctrl-names = "default";
+			reg-io-width = <4>;
+			reg-shift = <2>;
+
+			status = "disabled";
+		};
+
+		uart6: serial@2c180000 {
+			compatible = "rockchip,rk3572-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x2c180000 0x0 0x100>;
+			clocks = <&cru SCLK_UART6>, <&cru PCLK_UART6>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupts = <GIC_SPI 130 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&uart6m0_xfer_pins>;
+			pinctrl-names = "default";
+			reg-io-width = <4>;
+			reg-shift = <2>;
+
+			status = "disabled";
+		};
+
+		uart7: serial@2c190000 {
+			compatible = "rockchip,rk3572-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x2c190000 0x0 0x100>;
+			clocks = <&cru SCLK_UART7>, <&cru PCLK_UART7>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupts = <GIC_SPI 131 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&uart7m0_xfer_pins>;
+			pinctrl-names = "default";
+			reg-io-width = <4>;
+			reg-shift = <2>;
+
+			status = "disabled";
+		};
+
+		uart8: serial@2c1a0000 {
+			compatible = "rockchip,rk3572-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x2c1a0000 0x0 0x100>;
+			clocks = <&cru SCLK_UART8>, <&cru PCLK_UART8>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupts = <GIC_SPI 132 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&uart8m0_xfer_pins>;
+			pinctrl-names = "default";
+			reg-io-width = <4>;
+			reg-shift = <2>;
+
+			status = "disabled";
+		};
+
+		uart9: serial@2c1b0000 {
+			compatible = "rockchip,rk3572-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x2c1b0000 0x0 0x100>;
+			clocks = <&cru SCLK_UART9>, <&cru PCLK_UART9>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupts = <GIC_SPI 133 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&uart9m0_xfer_pins>;
+			pinctrl-names = "default";
+			reg-io-width = <4>;
+			reg-shift = <2>;
+
+			status = "disabled";
+		};
+
+		uart10: serial@2c1c0000 {
+			compatible = "rockchip,rk3572-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x2c1c0000 0x0 0x100>;
+			clocks = <&cru SCLK_UART10>, <&cru PCLK_UART10>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupts = <GIC_SPI 134 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&uart10m0_xfer_pins>;
+			pinctrl-names = "default";
+			reg-io-width = <4>;
+			reg-shift = <2>;
+
+			status = "disabled";
+		};
+
+		uart11: serial@2c1d0000 {
+			compatible = "rockchip,rk3572-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x2c1d0000 0x0 0x100>;
+			clocks = <&cru SCLK_UART11>, <&cru PCLK_UART11>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupts = <GIC_SPI 135 IRQ_TYPE_LEVEL_HIGH>;
+			pinctrl-0 = <&uart11m0_xfer_pins>;
+			pinctrl-names = "default";
+			reg-io-width = <4>;
+			reg-shift = <2>;
+
+			status = "disabled";
+		};
+
+		tsadc: tsadc@2c1f0000 {
+			compatible = "rockchip,rk3572-tsadc";
+			reg = <0x0 0x2c1f0000 0x0 0x1000>;
+			assigned-clock-rates = <2000000>;
+			assigned-clocks = <&cru CLK_TSADC>;
+			clocks = <&cru CLK_TSADC>, <&cru PCLK_TSADC>;
+			clock-names = "tsadc", "apb_pclk";
+			interrupts = <GIC_SPI 88 IRQ_TYPE_LEVEL_HIGH>;
+			resets = <&cru SRST_PRESETN_TSADC>,
+				 <&cru SRST_RESETN_TSADC>;
+			reset-names = "tsadc-apb", "tsadc";
+			#thermal-sensor-cells = <1>;
+			rockchip,hw-tshut-mode = <0>; /* 0: CRU, 1: GPIO */
+			rockchip,hw-tshut-polarity = <0>; /* 0: LOW, 1: HIGH */
+			rockchip,hw-tshut-temp = <120000>;
+
+			status = "disabled";
+		};
+
+		combphy0_psu: phy@2c410000 {
+			compatible = "rockchip,rk3572-naneng-combphy";
+			reg = <0x0 0x2c410000 0x0 0x100>;
+			assigned-clock-rates = <24000000>;
+			assigned-clocks = <&cru CLK_REF_PCIE0_INNER_PHY>;
+			clocks = <&cru CLK_REF_PCIE0_INNER_PHY>,
+				 <&cru PCLK_PCIE2_COMBOPHY0>;
+			clock-names = "ref", "apb";
+			#phy-cells = <1>;
+			resets = <&cru SRST_RESETN_PCIE0_PIPE_PHY>;
+			reset-names = "phy";
+			rockchip,pipe-grf = <&php_grf>;
+			rockchip,pipe-phy-grf = <&pipe_phy0_grf>;
+
+			status = "disabled";
+		};
+
+		combphy1_psu: phy@2c420000 {
+			compatible = "rockchip,rk3572-naneng-combphy";
+			reg = <0x0 0x2c420000 0x0 0x100>;
+			assigned-clock-rates = <24000000>;
+			assigned-clocks = <&cru CLK_REF_PCIE1_INNER_PHY>;
+			clocks = <&cru CLK_REF_PCIE1_INNER_PHY>,
+				 <&cru PCLK_PCIE2_COMBOPHY1>;
+			clock-names = "ref", "apb";
+			#phy-cells = <1>;
+			resets = <&cru SRST_RESETN_PCIE1_PIPE_PHY>;
+			reset-names = "phy";
+			rockchip,pipe-grf = <&php_grf>;
+			rockchip,pipe-phy-grf = <&pipe_phy1_grf>;
+
+			status = "disabled";
+		};
+
+		sram: sram@4010f000 {
+			compatible = "mmio-sram";
+			reg = <0x0 0x4010f000 0x0 0x100>;
+			ranges = <0x0 0x0 0x4010f000 0x100>;
+			#address-cells = <1>;
+			#size-cells = <1>;
+
+			scmi_shmem: scmi-sram-section@0 {
+				compatible = "arm,scmi-shmem";
+				reg = <0x0 0x100>;
+			};
+		};
+	};
+
+	thermal-zones {
+		big_core_thermal: big-core-thermal {
+			polling-delay = <1000>;
+			polling-delay-passive = <100>;
+			thermal-sensors = <&tsadc 4>;
+
+			trips {
+				big-core-crit {
+					hysteresis = <2000>;
+					temperature = <115000>;
+					type = "critical";
+				};
+			};
+		};
+
+		center-thermal {
+			polling-delay = <1000>;
+			polling-delay-passive = <100>;
+			thermal-sensors = <&tsadc 0>;
+
+			trips {
+				center-crit {
+					hysteresis = <2000>;
+					temperature = <115000>;
+					type = "critical";
+				};
+			};
+		};
+
+		ddr-thermal {
+			polling-delay = <1000>;
+			polling-delay-passive = <100>;
+			thermal-sensors = <&tsadc 2>;
+
+			trips {
+				ddr-crit {
+					hysteresis = <2000>;
+					temperature = <115000>;
+					type = "critical";
+				};
+			};
+		};
+
+		gpu-npu-thermal {
+			polling-delay = <1000>;
+			polling-delay-passive = <100>;
+			thermal-sensors = <&tsadc 1>;
+
+			trips {
+				gpu-npu-crit {
+					hysteresis = <2000>;
+					temperature = <115000>;
+					type = "critical";
+				};
+			};
+		};
+
+		little_core_thermal: little-core-thermal {
+			polling-delay = <1000>;
+			polling-delay-passive = <100>;
+			thermal-sensors = <&tsadc 3>;
+
+			trips {
+				little-core-crit {
+					hysteresis = <2000>;
+					temperature = <115000>;
+					type = "critical";
+				};
+			};
+		};
+	};
+
+	timer {
+		compatible = "arm,armv8-timer";
+		interrupts = <GIC_PPI 13 (GIC_CPU_MASK_SIMPLE(8) |
+			     IRQ_TYPE_LEVEL_LOW)>,
+			     <GIC_PPI 14 (GIC_CPU_MASK_SIMPLE(8) |
+			     IRQ_TYPE_LEVEL_LOW)>,
+			     <GIC_PPI 11 (GIC_CPU_MASK_SIMPLE(8) |
+			     IRQ_TYPE_LEVEL_LOW)>,
+			     <GIC_PPI 10 (GIC_CPU_MASK_SIMPLE(8) |
+			     IRQ_TYPE_LEVEL_LOW)>;
+	};
+
+	xin24m: xin24m {
+		compatible = "fixed-clock";
+		#clock-cells = <0>;
+		clock-frequency = <24000000>;
+		clock-output-names = "xin24m";
+	};
+};
+
+#include "rk3572-pinctrl.dtsi"

-- 
2.34.1

