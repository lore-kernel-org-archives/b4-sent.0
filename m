From: David Heidelberg <david@ixit.cz>
Date: Fri, 27 Mar 2026 14:07:09 +0100
Subject: [PATCH RFC 2/2] arm64: dts: qcom: sdm845-oneplus: Describe
 Wi-Fi/BT properly
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260327-wcn3990-pwrctl-sdm845-v1-2-3f5c34e3fdd0@ixit.cz>
References: <20260327-wcn3990-pwrctl-sdm845-v1-0-3f5c34e3fdd0@ixit.cz>
In-Reply-To: <20260327-wcn3990-pwrctl-sdm845-v1-0-3f5c34e3fdd0@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Paul Sajna <sajattack@postmarketos.org>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3019; i=david@ixit.cz;
 h=from:subject:message-id; bh=NCuUO0OX7Mr016a4HOAuAhnhl+ajm2fLd9iQQBmLAt0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpxoD8Qe4h2VZLhPgPoUe4sAXGVqdILj/8ed33v
 db8HIPKYVuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCacaA/AAKCRBgAj/E00kg
 cvgpD/0bABCwRGI5o4Z960vl++GWAX4kCXkOXuW3WQNFLlMPU5T24inK5paz+KoLvmHaztP6plX
 8SHbWQLRs1wKrKH4bOpnY9WzTokua6nepHJqlVC2ONOrzcqfF9WDIyW8kPVWGS8R1Ddlf0yEuef
 jCIDQad1qCR6CgL91KQOp/7cpeEANQ1jdb6I6KFtc9owS79dlCoZQBFtUToqQADpq6AKXD9Q4B6
 24D2ZLnLuuij3A0oV2ST1uQxL13lQ2SM5n+sbP+6Zzke4JUl4fKXiXLaoGirtKn3d32t1Stivc+
 2PRspSajo3iva68wnZxnoUY1s7h5iZ4ExsxL9f9L6raafiXwxo9ekQyuKkcyDYvFleHAAmc4iM8
 Al+NkluL9D6NIGt7evGEpabp1GCqJyeHJqOOKEqNbBaYxYuglcsapfBT8Zoa5I2t7arJouLvEIT
 W34GN4JBSyURsuuxCLC5GByU9wDjLfTjZzf0D1uSYhYZ3moTJRV6EC1544yF8j75ZO4gCAUgy+L
 KKu7ToLPi56qpzkLMonNHuzedgCxv3Bq3UqQpU7Ajbam4qF1oERmuxkJr9c2fkYYFhVo+E7bLll
 3/wJIn2yU74hnIaocpLO0RrRZ0A/AATQb+Esj+x/CJ5Vip7aly5RFoFXxC2QEljo4HvzZX6J9ku
 DjzKW9Kk/YGOGMQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The onboard Wi-Fi / BT device, WCN3990, has a simple on-chip PMU, which
further spreads generated voltage. Describe the PMU in the device tree
and rewire Bluetooth and WiFi supply properties to use the PMU LDO
outputs instead of referencing the SoC regulators directly.

Verified against the datasheet.

Assisted-by: Claude:claude-opus-4.6
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 65 +++++++++++++++++++---
 1 file changed, 56 insertions(+), 9 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index ea187244c92a9..6b7378cf4d493 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -230,6 +230,43 @@ panel_vddi_poc_1p8: panel-vddi-poc-regulator {
 		pinctrl-names = "default";
 		regulator-boot-on;
 	};
+
+	wcn3990-pmu {
+		compatible = "qcom,wcn3990-pmu";
+
+		pinctrl-0 = <&sw_ctrl_default>;
+		pinctrl-names = "default";
+
+		vddio-supply = <&vreg_s4a_1p8>;
+		vddxo-supply = <&vreg_l7a_1p8>;
+		vddrf-supply = <&vreg_l17a_1p3>;
+		vddch0-supply = <&vreg_l25a_3p3>;
+		vddch1-supply = <&vreg_l23a_3p3>;
+
+		swctrl-gpios = <&pm8998_gpios 3 GPIO_ACTIVE_HIGH>;
+
+		regulators {
+			vreg_pmu_io: ldo0 {
+				regulator-name = "vreg_pmu_io";
+			};
+
+			vreg_pmu_xo: ldo1 {
+				regulator-name = "vreg_pmu_xo";
+			};
+
+			vreg_pmu_rf: ldo2 {
+				regulator-name = "vreg_pmu_rf";
+			};
+
+			vreg_pmu_ch0: ldo3 {
+				regulator-name = "vreg_pmu_ch0";
+			};
+
+			vreg_pmu_ch1: ldo4 {
+				regulator-name = "vreg_pmu_ch1";
+			};
+		};
+	};
 };
 
 &adsp_pas {
@@ -536,6 +573,14 @@ &mss_pil {
 };
 
 &pm8998_gpios {
+	sw_ctrl_default: sw-ctrl-default-state {
+		pins = "gpio3";
+		function = "normal";
+
+		input-enable;
+		bias-pull-down;
+	};
+
 	volume_down_gpio: pm8998-gpio5-state {
 		pinconf {
 			pins = "gpio5";
@@ -804,10 +849,11 @@ bluetooth {
 		 */
 		firmware-name = "OnePlus/enchilada/crnv21.bin";
 
-		vddio-supply = <&vreg_s4a_1p8>;
-		vddxo-supply = <&vreg_l7a_1p8>;
-		vddrf-supply = <&vreg_l17a_1p3>;
-		vddch0-supply = <&vreg_l25a_3p3>;
+		vddio-supply = <&vreg_pmu_io>;
+		vddxo-supply = <&vreg_pmu_xo>;
+		vddrf-supply = <&vreg_pmu_rf>;
+		vddch0-supply = <&vreg_pmu_ch0>;
+
 		max-speed = <3200000>;
 	};
 };
@@ -981,13 +1027,14 @@ &wcd9340 {
 };
 
 &wifi {
-	status = "okay";
 	vdd-0.8-cx-mx-supply = <&vreg_l5a_0p8>;
-	vdd-1.8-xo-supply = <&vreg_l7a_1p8>;
-	vdd-1.3-rfa-supply = <&vreg_l17a_1p3>;
-	vdd-3.3-ch0-supply = <&vreg_l25a_3p3>;
-	vdd-3.3-ch1-supply = <&vreg_l23a_3p3>;
+	vdd-1.8-xo-supply = <&vreg_pmu_xo>;
+	vdd-1.3-rfa-supply = <&vreg_pmu_rf>;
+	vdd-3.3-ch0-supply = <&vreg_pmu_ch0>;
+	vdd-3.3-ch1-supply = <&vreg_pmu_ch1>;
 
 	qcom,calibration-variant = "oneplus_sdm845";
 	qcom,snoc-host-cap-8bit-quirk;
+
+	status = "okay";
 };

-- 
2.53.0

