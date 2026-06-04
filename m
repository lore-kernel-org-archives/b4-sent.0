From: =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
Date: Thu, 04 Jun 2026 18:18:38 +0200
Subject: [PATCH v3 02/10] arm64: dts: qcom: sc8280xp-arcata: Enable the eDP
 display
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260604-surface-sp9-5g-for-next-v3-2-6aa6f6612c10@gmail.com>
References: <20260604-surface-sp9-5g-for-next-v3-0-6aa6f6612c10@gmail.com>
In-Reply-To: <20260604-surface-sp9-5g-for-next-v3-0-6aa6f6612c10@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Johan Hovold <johan@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Krzysztof Kozlowski <krzk@kernel.org>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780589927; l=2658;
 i=jerome.debretagne@gmail.com; s=20260520; h=from:subject:message-id;
 bh=ArT83CzUHU9cMXn/mN7oML+/ug0Ds8jF1qJcB4FmuvI=;
 b=lANYZAicxjZ8LNulmHH0rOmW7fIAuJ/s77PgW1FVIg/FdZMQlI/7PYoukgJikvcg0qILuh8Pi
 qJkVjNdYEgCAutYGtV5ighRqnKkKA/F5EbOzOxmRlTBtBZx28v91fGX
X-Developer-Key: i=jerome.debretagne@gmail.com; a=ed25519;
 pk=3/JYhgYjGg5V9mlFxc0A0+pFiyjsuDB/TtDlNMId9fk=
X-Endpoint-Received: by B4 Relay for jerome.debretagne@gmail.com/20260520 with auth_id=785
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the vreg_edp_3p3, edp_reg_en and mdss0_dp3 nodes to enable the
Surface Pro 9 5G eDP-based LCD display (LG LP129WT232166).

Signed-off-by: Jérôme de Bretagne <jerome.debretagne@gmail.com>
---
 .../boot/dts/qcom/sc8280xp-microsoft-arcata.dts    | 64 ++++++++++++++++++++--
 1 file changed, 59 insertions(+), 5 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
index f24f60dc73afea6eeee0ea26472cda3223811752..476e17415da273330e3638e040db9cd4ed408bf1 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
@@ -136,6 +136,22 @@ pmic_glink_con1_sbu: endpoint {
 		};
 	};
 
+	vreg_edp_3p3: regulator-edp-3p3 {
+		compatible = "regulator-fixed";
+
+		regulator-name = "VREG_EDP_3P3";
+		regulator-min-microvolt = <3300000>;
+		regulator-max-microvolt = <3300000>;
+
+		gpio = <&tlmm 36 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+
+		pinctrl-0 = <&edp_reg_en>;
+		pinctrl-names = "default";
+
+		regulator-boot-on;
+	};
+
 	vreg_nvme: regulator-nvme {
 		compatible = "regulator-fixed";
 
@@ -344,7 +360,6 @@ vreg_l6b: ldo6 {
 			regulator-max-microvolt = <880000>;
 			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
 			regulator-boot-on;
-			regulator-always-on;	// FIXME: VDD_A_EDP_0_0P9
 		};
 	};
 
@@ -448,10 +463,6 @@ &dispcc0 {
 	status = "okay";
 };
 
-&dispcc1 {
-	status = "okay";
-};
-
 &gpi_dma0 {
 	status = "okay";
 };
@@ -494,6 +505,42 @@ &mdss0_dp1_out {
 	remote-endpoint = <&usb_1_qmpphy_dp_in>;
 };
 
+&mdss0_dp3 {
+	compatible = "qcom,sc8280xp-edp";
+	/delete-property/ #sound-dai-cells;
+
+	data-lanes = <0 1 2 3>;
+
+	status = "okay";
+
+	aux-bus {
+		panel {
+			compatible = "edp-panel";
+
+			backlight = <&backlight>;
+			power-supply = <&vreg_edp_3p3>;
+
+			port {
+				edp_panel_in: endpoint {
+					remote-endpoint = <&mdss0_dp3_out>;
+				};
+			};
+		};
+	};
+};
+
+&mdss0_dp3_out {
+	remote-endpoint = <&edp_panel_in>;
+};
+
+&mdss0_dp3_phy {
+	compatible = "qcom,sc8280xp-edp-phy";
+	vdda-phy-supply = <&vreg_l6b>;
+	vdda-pll-supply = <&vreg_l3b>;
+
+	status = "okay";
+};
+
 &pcie2a {
 	perst-gpios = <&tlmm 143 GPIO_ACTIVE_LOW>;
 	wake-gpios = <&tlmm 145 GPIO_ACTIVE_LOW>;
@@ -910,6 +957,13 @@ hstp-sw-ctrl-pins {
 		};
 	};
 
+	edp_reg_en: edp-reg-en-state {
+		pins = "gpio36";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
 	nvme_reg_en: nvme-reg-en-state {
 		pins = "gpio135";
 		function = "gpio";

-- 
2.47.3

