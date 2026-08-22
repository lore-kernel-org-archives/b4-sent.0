From: David Heidelberg <david@ixit.cz>
Date: Sat, 22 Aug 2026 07:15:18 +0200
Subject: [PATCH v5 3/3] arm64: dts: qcom: sdm845-shift-axolotl: Add
 actuator for second rear camera
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260822-dw9714v-v5-3-502bc7f43b8f@ixit.cz>
References: <20260822-dw9714v-v5-0-502bc7f43b8f@ixit.cz>
In-Reply-To: <20260822-dw9714v-v5-0-502bc7f43b8f@ixit.cz>
To: Alexander Martinz <amartinz@shiftphones.com>, 
 Bjorn Andersson <andersson@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-media@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2564; i=david@ixit.cz;
 h=from:subject:message-id; bh=MkyskRm5zOC8VqbKWX20phVUAB1U8R05LT18kNWIUpM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqiTB+CyUjVppimaT5DUyiV2e9ZL4gfGthq6h9C
 mUY+80SfqWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaokwfgAKCRBgAj/E00kg
 csfCD/4/ps9N6J2gP7/hTbN7zynmdRUAlJZvBriMBvJpksogXr3sma8kirEKFGCo+zS1Ib/LsXM
 dXCvxsf3ZEywTrFuHBibmXQ65kTuBl4hp8kmgvMSrmySESqQe8KA7SVp9e1ColXl+1J6YJKdEzx
 C7k/CTt8ep4OM0z1baavJVsGQ6PduXlrrMCiMEU3OEK8fGcy3bntex4dFAM9XI986zpQ3huWzNo
 TOrKjvIHvBYHKycWVxl3G8NagEEPz8piaraWaxvVnKKMZ/sqFoh7B6dd5rEnDkrgAihHkOrsCB9
 UcntNKi2EHv8CeqsK7ALYAnffHbOY5sYa6FTlqQTZZXkcY1GalqRy3Ewvc0T1K04wq4BD1speyW
 GvsE/cxL2h1+gh3gqk49Y7gHaQCFTvsWjGML6Rnl0BaVQpwhoebM3NGZEUFUGCVD5wfE92GH5vZ
 +zk32BmMMAUuoqkKoaXnY9dxVcAspCmfzsD55qYlc2mjdK/025mH6XX3UYUDzXpQCwasE8ZYUVw
 4ZNHjM4O3LH3nEz/21i5Jb9GFA6+10+kXJ+VWmzNgbwzHHiLK/ue/k/YPUrHLoM+h0vrTh7WzTR
 LXNPkoL5NdkhDERCJ9tTqZXM3e7xJtqTCx7qNZsrJzW2DCVc6Vi/tQouraFiQk8wzXRj6Tnn8QS
 ylaoqhBaiimYiFg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SHIFT 6MQ has a second rear (auxiliary) camera. Its autofocus
actuator is a Dongwoon DW9714V.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 39 +++++++++++++++++++++++
 1 file changed, 39 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index f14fe8e175e96..3cfc11127f5e1 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -99,16 +99,34 @@ cam_main_af_2p8: regulator-cam-main-af-2p8 {
 		enable-active-high;
 
 		pinctrl-0 = <&cam_main_af_default_state>;
 		pinctrl-names = "default";
 
 		vin-supply = <&vreg_bob>;
 	};
 
+	/* SGM2036-2.8YUDH4G/TR */
+	cam_rear2_af_2p8: regulator-cam-rear2-af-2p8 {
+		compatible = "regulator-fixed";
+
+		regulator-name = "cam_rear2_af_2p8";
+		regulator-min-microvolt = <2800000>;
+		regulator-max-microvolt = <2800000>;
+		regulator-enable-ramp-delay = <100>;
+
+		gpio = <&tlmm 76 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+
+		pinctrl-0 = <&cam_rear2_af_default_state>;
+		pinctrl-names = "default";
+
+		vin-supply = <&vreg_bob>;
+	};
+
 	vph_pwr: vph-pwr-regulator {
 		compatible = "regulator-fixed";
 		regulator-name = "vph_pwr";
 		regulator-min-microvolt = <3700000>;
 		regulator-max-microvolt = <3700000>;
 	};
 
 	vreg_s4a_1p8: pm8998-smps4 {
@@ -484,16 +502,30 @@ camera-lens@c {
 			     "dongwoon,dw9714a",
 			     "dongwoon,dw9714";
 		reg = <0x0c>;
 
 		vcc-supply = <&cam_main_af_2p8>;
 	};
 };
 
+&cci_i2c1 {
+	/* samsung,s5k2x7sp @ 10 */
+
+	/* 2nd rear camera actuator */
+	camera-lens@c {
+		compatible = "dongwoon,dw9714v",
+			     "dongwoon,dw9714a",
+			     "dongwoon,dw9714";
+		reg = <0x0c>;
+
+		vcc-supply = <&cam_rear2_af_2p8>;
+	};
+};
+
 &cdsp_pas {
 	firmware-name = "qcom/sdm845/SHIFT/axolotl/cdsp.mbn";
 
 	status = "okay";
 };
 
 &gcc {
 	protected-clocks = <GCC_QSPI_CORE_CLK>,
@@ -749,16 +781,23 @@ &tlmm {
 
 	cam_main_af_default_state: cam-main-af-default-state {
 		pins = "gpio8";
 		function = "gpio";
 		drive-strength = <2>;
 		bias-disable;
 	};
 
+	cam_rear2_af_default_state: cam-rear2-af-default-state {
+		pins = "gpio76";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
 	sdc2_default_state: sdc2-default-state {
 		clk-pins {
 			pins = "sdc2_clk";
 			drive-strength = <16>;
 			bias-disable;
 		};
 
 		cmd-pins {

-- 
2.55.0

