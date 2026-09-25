From: David Heidelberg <david@ixit.cz>
Date: Fri, 25 Sep 2026 23:22:23 +0200
Subject: [PATCH v8 5/5] arm64: dts: qcom: sdm845-google: Add STM FTS
 touchscreen support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-stmfts5-v8-5-0fcf49e2c85f@ixit.cz>
References: <20260925-stmfts5-v8-0-0fcf49e2c85f@ixit.cz>
In-Reply-To: <20260925-stmfts5-v8-0-0fcf49e2c85f@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, linux-input@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Abel Vesa <abel.vesa@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2339; i=david@ixit.cz;
 h=from:subject:message-id; bh=uByqGmdgQrcbmESUA0mr/va47Uf9HHtA6cjJdf5std0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtuYMtuSAMZngZy19YCnOrmZ2QrkIiPZUKVdob
 v+EV9XZgeaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarbmDAAKCRBgAj/E00kg
 ciWRD/4rOU0tR8/3StLODI1Ciqe6j7mo43XwWt5DDIunIagZE0HuwAxILx+Zi3wpm1hYzPW6c92
 0VqthbFCm7F8edtttgnZ4MaEgJ+DOqBxd0/4v+k3Kb1GMJVwztdoF6WBBk2Gmq1jAqSz3el/hyW
 /HhBVa7O3SxhSZmiSYs9A76e6+StgDfbA6EGArgW9dgQSs90nzXiXcXZsbM65LcH5+TKrppQFLj
 0KHP5VUaWGMjW++CeZmfXArhKqz/SZbtAldBikIwZZwWdjEGY4f4avqiGKBr+HNfKyv23AYpV3B
 MEsiE4R3Gb2AYopull/wuFNotXIdkpS71S21VogyE75ADHAYMq1ROPoKVMLHm88B/ozQdpJQqpr
 Q+OfvsxY0tamEWYgi7wx7L4lbsBuWH91I3vZMC6yAmsyISraP8TIGxJjDLgAzJW9TC9enBrP1PI
 C8NvNaxag63ehjVfOUIqrhY0fixXBzNZ2xpxTeB+6dlHFO1/V5gpuqc4WzL08YYhHiuUbHpW3Hf
 5AWx2yOocdMDjfOyaR5/PiSamZe1k0P5VFSp94j5u77Y4rA5bMYNrI6P/aT4NYUyLT9I/Zv1CiD
 U0yxdU57THR1xeZ8nd9kWuBckhcqKkFuqih30SJEDJCwDkX3olBExeXi4/1L8ivRf+uTWWXwFJp
 rpDm8eZDL1KRNrw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Petr Hodina <petr.hodina@protonmail.com>

Basic touchscreen connected to second i2c bus.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Reviewed-by: Abel Vesa <abel.vesa@oss.qualcomm.com>
Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts | 19 ++++++++++++++++++-
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi  |  2 +-
 2 files changed, 19 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
index fa89be500fb85..51c835dca43f1 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
@@ -21,17 +21,34 @@ &framebuffer0 {
 	stride = <(1080 * 4)>;
 };
 
 &i2c2 {
 	clock-frequency = <1000000>;
 
 	status = "okay";
 
-	/* ST,FTS @ 49 */
+	touchscreen@49 {
+		compatible = "st,stmfts5";
+		reg = <0x49>;
+
+		pinctrl-0 = <&touchscreen_irq_n>, <&touchscreen_reset>;
+		pinctrl-names = "default";
+
+		interrupts-extended = <&tlmm 125 IRQ_TYPE_LEVEL_LOW>;
+
+		mode-switch-gpios = <&tlmm 136 GPIO_ACTIVE_HIGH>;
+		reset-gpios = <&tlmm 99 GPIO_ACTIVE_LOW>;
+
+		avdd-supply = <&vreg_l19a_3p3>;
+		vdd-supply = <&vreg_l14a_1p8>;
+
+		touchscreen-size-x = <1080>;
+		touchscreen-size-y = <2160>;
+	};
 };
 
 &mdss_dsi0 {
 	vdda-supply = <&vdda_mipi_dsi0_1p2>;
 
 	status = "okay";
 
 	panel@0 {
diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index f1379857e2742..6ae1973aa8ac7 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -504,17 +504,17 @@ firmware-pins {
 
 	touchscreen_reset: ts-reset-state {
 		pins = "gpio99";
 		function = "gpio";
 		drive-strength = <8>;
 		bias-pull-up;
 	};
 
-	touchscreen_pins: ts-pins-gpio-state {
+	touchscreen_irq_n: ts-irq-n-gpio-state {
 		pins = "gpio125";
 		function = "gpio";
 		drive-strength = <2>;
 		bias-disable;
 	};
 
 	touchscreen_i2c_pins: qup-i2c2-gpio-state {
 		pins = "gpio27", "gpio28";

-- 
2.55.0

