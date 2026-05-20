From: =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
Date: Wed, 20 May 2026 18:40:06 +0200
Subject: [PATCH 02/11] arm64: dts: qcom: sc8280xp-arcata: Enable backlight
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260520-surface-sp9-5g-for-next-v1-2-9df52552bf87@gmail.com>
References: <20260520-surface-sp9-5g-for-next-v1-0-9df52552bf87@gmail.com>
In-Reply-To: <20260520-surface-sp9-5g-for-next-v1-0-9df52552bf87@gmail.com>
To: Douglas Anderson <dianders@chromium.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779295238; l=3493;
 i=jerome.debretagne@gmail.com; s=20260520; h=from:subject:message-id;
 bh=qcsZWoxgvAPoNCEU3iLxOiyoEaAbYrCyLBf3CtjwWsI=;
 b=pg6Ci5b4cO+EwOsQYRLjgYTLWy1eAa40DvuFHFVwe/4NIQi3pUQuOu86a9d3eA4CSrvGmoFHC
 v2RdHso2LUPAHPU8MgHtwkURigBe0K8SeN32HZCFnR6XjAwnsRTkO8T
X-Developer-Key: i=jerome.debretagne@gmail.com; a=ed25519;
 pk=3/JYhgYjGg5V9mlFxc0A0+pFiyjsuDB/TtDlNMId9fk=
X-Endpoint-Received: by B4 Relay for jerome.debretagne@gmail.com/20260520 with auth_id=785
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add backlight nodes and enable backlight so that it can be controlled
with the corresponding buttons found on Surface Pro Type Cover keyboards.

The nodes are almost identical to the ones from the ThinkPad X13s with
a different enable GPIO for the vreg_edp_bl node.

The difference was found by looking at the output of /sys/kernel/debug/gpio
on the ThinkPad X13s to see the properties of its enable gpio9:

  gpiochip1: GPIOs 742-751, parent: platform/c440000.spmi:pmic@1:gpio@8800, c440000.spmi:pmic@1:gpio@8800:
   ...
   gpio9 : out  high normal  vin-1 pull-down 10uA              push-pull  medium  atest-1 dtest-0
   ...

The same gpio9 on the Surface Pro 9 5G has different properties:

  gpiochip0: 10 GPIOs, parent: platform/c440000.spmi:pmic@1:gpio@8800, c440000.spmi:pmic@1:gpio@8800:
   ...
   gpio9 : in   high normal  vin-1 pull-up 30uA                push-pull  low     atest-1 dtest-0
   ...

Looking for a match on the Surface Pro 9 5G pointed to this only one:

  gpiochip2: 10 GPIOs, parent: platform/c440000.spmi:pmic@3:gpio@8800, c440000.spmi:pmic@3:gpio@8800:
   ...
   gpio6 : out  high normal  vin-1 pull-down 10uA              push-pull  medium  atest-1 dtest-0
   ...

Signed-off-by: Jérôme de Bretagne <jerome.debretagne@gmail.com>
---
 .../boot/dts/qcom/sc8280xp-microsoft-arcata.dts    | 49 ++++++++++++++++++++++
 1 file changed, 49 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
index f2b4470d4407fb5b6a3dbac8bc972c010c31bd06..14287092fb07ea15e527fd318f7ea2155448b26c 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
@@ -46,6 +46,16 @@ wcd938x: audio-codec {
 		#sound-dai-cells = <1>;
 	};
 
+	backlight: backlight {
+		compatible = "pwm-backlight";
+		pwms = <&pmc8280c_lpg 3 1000000>;
+		enable-gpios = <&pmc8280_1_gpios 8 GPIO_ACTIVE_HIGH>;
+		power-supply = <&vreg_edp_bl>;
+
+		pinctrl-0 = <&edp_bl_en>, <&edp_bl_pwm>;
+		pinctrl-names = "default";
+	};
+
 	pmic-glink {
 		compatible = "qcom,sc8280xp-pmic-glink", "qcom,pmic-glink";
 
@@ -127,6 +137,22 @@ pmic_glink_con1_sbu: endpoint {
 		};
 	};
 
+	vreg_edp_bl: regulator-edp-bl {
+		compatible = "regulator-fixed";
+
+		regulator-name = "VREG_EDP_BL";
+		regulator-min-microvolt = <3600000>;
+		regulator-max-microvolt = <3600000>;
+
+		gpio = <&pmc8280c_gpios 6 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+
+		pinctrl-0 = <&edp_bl_reg_en>;
+		pinctrl-names = "default";
+
+		regulator-boot-on;
+	};
+
 	vreg_nvme: regulator-nvme {
 		compatible = "regulator-fixed";
 
@@ -553,6 +579,10 @@ &pcie4_phy {
 	status = "okay";
 };
 
+&pmc8280c_lpg {
+	status = "okay";
+};
+
 &pmk8280_pon_pwrkey {
 	status = "okay";
 };
@@ -853,6 +883,13 @@ &lpass_tlmm {
 	status = "okay";
 };
 
+&pmc8280_1_gpios {
+	edp_bl_en: edp-bl-en-state {
+		pins = "gpio8";
+		function = "normal";
+	};
+};
+
 &pmc8280_2_gpios {
 	wwan_sw_en: wwan-sw-en-state {
 		pins = "gpio1";
@@ -860,6 +897,18 @@ wwan_sw_en: wwan-sw-en-state {
 	};
 };
 
+&pmc8280c_gpios {
+	edp_bl_pwm: edp-bl-pwm-state {
+		pins = "gpio8";
+		function = "func1";
+	};
+
+	edp_bl_reg_en: edp-bl-reg-en-state {
+		pins = "gpio6";
+		function = "normal";
+	};
+};
+
 &pmr735a_gpios {
 	hastings_reg_en: hastings-reg-en-state {
 		pins = "gpio1";

-- 
2.47.3

