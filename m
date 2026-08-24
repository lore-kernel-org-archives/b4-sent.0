From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Mon, 24 Aug 2026 22:58:22 +0700
Subject: [PATCH v6 4/4] arm64: dts: qcom: qcs8550-ayaneo-pocket-ds: add the
 lower DSI panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260824-pocketds-v6-4-370161574ca2@gmail.com>
References: <20260824-pocketds-v6-0-370161574ca2@gmail.com>
In-Reply-To: <20260824-pocketds-v6-0-370161574ca2@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787587098; l=4952;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=awleFrCmpPFN90BPSQOiVC+g+5SKQU6evS103lfDdww=;
 b=EzxjVbypyuklUc/NKIYnzEHclEtqVACsFpTGizN9DW6MKINpX5L8YQIuKIL0Lzsof4/BZpckT
 O6DEllO5b6QBE5w9TeaTyAFFMrimkc2/YsFfgQRzTxwyUzY5Oi74d8r
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Pocket DS drives two panels. The lower one is a 768x1024 IPS LCD on
a Sitronix ST7703 DDIC hanging off mdss_dsi1, and all of the pieces it
needs have now landed: the ayaneo,pocket-ds-lower-panel compatible in
the ST7703 binding, the SGMicro SGM3804 dual-rail charge pump driver and
the Silergy SY7758 backlight driver.

The SGM3804 on i2c0 supplies the panel bias. Its two rails are enabled
by separate GPIOs and both are programmed to 5.2 V; that figure is the
vendor register configuration (0x00 = 0x0c, 0x01 = 0x0c), which lands on
5.2 V in the driver's 4.0 V + 100 mV linear range. tlmm 152 enables the
positive rail and tlmm 153 the negative one. Only the positive rail has
a consumer, because the ST7703 binding models a single vcc-supply, so
the negative rail is marked regulator-always-on to keep AVEE up while
the panel is on; a better modelling of the pair is welcome.

The SY7758 backlight sits on the same bus. Its enable line was
determined on the device: driving tlmm 42 low makes the chip stop
acknowledging on i2c while the TCA6408 on the same segment keeps
responding, so tlmm 42 gates the SY7758 alone rather than the bus.

The TCA6408 expander supplies the rest: line 0 gates the panel IOVCC
rail, modelled as a fixed regulator, and line 2 is the panel reset.

sde_dsi1_active keeps its output-high because tlmm 137 has no GPIO
consumer anywhere in the tree; pinctrl is the only thing asserting it.

The upper panel is not added here. Its Chipone ICNA3512 binding makes
disp-supply and blvdd-supply mandatory, and this board has no separately
controllable rail for either; the vendor device tree drives the upper
panel purely through a platform enable GPIO and points the panel node at
the simulator supply list. It will follow once that wiring is confirmed.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
 .../boot/dts/qcom/qcs8550-ayaneo-pocket-ds.dts     | 97 ++++++++++++++++++++++
 1 file changed, 97 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/qcs8550-ayaneo-pocket-ds.dts b/arch/arm64/boot/dts/qcom/qcs8550-ayaneo-pocket-ds.dts
index 09b1c86cc3d3..72c81667c085 100644
--- a/arch/arm64/boot/dts/qcom/qcs8550-ayaneo-pocket-ds.dts
+++ b/arch/arm64/boot/dts/qcom/qcs8550-ayaneo-pocket-ds.dts
@@ -314,6 +314,17 @@ upd720201_vdd33_reg: upd720201-vdd33-regulator {
 		pinctrl-names = "default";
 	};
 
+	vreg_panel1_iovcc: panel1-iovcc-regulator {
+		compatible = "regulator-fixed";
+
+		regulator-name = "panel1_iovcc";
+		regulator-min-microvolt = <1800000>;
+		regulator-max-microvolt = <1800000>;
+
+		gpios = <&tca6408 0 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+	};
+
 	vdd_fan_5v0: vdd-fan-5v0-regulator {
 		compatible = "regulator-fixed";
 
@@ -829,6 +840,38 @@ tca6408: gpio@20 {
 
 		vcc-supply = <&tca6424_vcc>;
 	};
+
+	backlight: backlight@2e {
+		compatible = "silergy,sy7758";
+		reg = <0x2e>;
+
+		enable-gpios = <&tlmm 42 GPIO_ACTIVE_HIGH>;
+	};
+
+	sgm3804: regulator@3e {
+		compatible = "sgmicro,sgm3804";
+		reg = <0x3e>;
+
+		vin-supply = <&vph_pwr>;
+
+		sgm3804_pos: pos {
+			regulator-name = "panel1_avdd";
+			regulator-min-microvolt = <5200000>;
+			regulator-max-microvolt = <5200000>;
+
+			enable-gpios = <&tlmm 152 GPIO_ACTIVE_HIGH>;
+		};
+
+		sgm3804_neg: neg {
+			regulator-name = "panel1_avee";
+			regulator-min-microvolt = <5200000>;
+			regulator-max-microvolt = <5200000>;
+
+			enable-gpios = <&tlmm 153 GPIO_ACTIVE_HIGH>;
+
+			regulator-always-on;
+		};
+	};
 };
 
 &i2c2 {
@@ -960,6 +1003,45 @@ &mdss_dp0_out {
 	data-lanes = <0 1 2 3>;
 };
 
+&mdss_dsi1 {
+	vdda-supply = <&vreg_l3e_1p2>;
+
+	status = "okay";
+
+	panel@0 {
+		compatible = "ayaneo,pocket-ds-lower-panel";
+		reg = <0>;
+
+		vcc-supply = <&sgm3804_pos>;
+		iovcc-supply = <&vreg_panel1_iovcc>;
+
+		reset-gpios = <&tca6408 2 GPIO_ACTIVE_LOW>;
+		backlight = <&backlight>;
+		rotation = <270>;
+
+		pinctrl-0 = <&sde_dsi1_active>;
+		pinctrl-1 = <&sde_dsi1_suspend>;
+		pinctrl-names = "default", "sleep";
+
+		port {
+			panel1_in: endpoint {
+				remote-endpoint = <&mdss_dsi1_out>;
+			};
+		};
+	};
+};
+
+&mdss_dsi1_out {
+	remote-endpoint = <&panel1_in>;
+	data-lanes = <0 1 2 3>;
+};
+
+&mdss_dsi1_phy {
+	vdds-supply = <&vreg_l1e_0p88>;
+
+	status = "okay";
+};
+
 &pcie0 {
 	wake-gpios = <&tlmm 96 GPIO_ACTIVE_HIGH>;
 	perst-gpios = <&tlmm 94 GPIO_ACTIVE_LOW>;
@@ -1558,6 +1640,21 @@ ts2_irq: ts2-irq-state {
 		bias-disable;
 	};
 
+	sde_dsi1_active: sde-dsi1-active-state {
+		pins = "gpio137";
+		function = "gpio";
+		drive-strength = <8>;
+		bias-disable;
+		output-high;
+	};
+
+	sde_dsi1_suspend: sde-dsi1-suspend-state {
+		pins = "gpio137";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-pull-down;
+	};
+
 	ts2_reset: ts2-reset-state {
 		pins = "gpio38";
 		function = "gpio";

-- 
2.55.0

