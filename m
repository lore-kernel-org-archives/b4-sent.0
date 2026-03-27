From: David Heidelberg <david@ixit.cz>
Date: Fri, 27 Mar 2026 14:07:08 +0100
Subject: [PATCH RFC 1/2] arm64: dts: qcom: sdm845-google: Describe Wi-Fi/BT
 properly
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260327-wcn3990-pwrctl-sdm845-v1-1-3f5c34e3fdd0@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2285; i=david@ixit.cz;
 h=from:subject:message-id; bh=ZdsZlqRm3/oxciwUtKAmARcIeJyJp34l/WYfXSWVTDk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpxoD8X3UHY8pX88+zhKXwHwfDLK4KyevZawF/N
 WB8LSP1NLOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCacaA/AAKCRBgAj/E00kg
 cql4D/0fFQTGC79+QPPPwY4Zs53+E9cFblgQy0wmQmkicMTkYG5vExKjTaarCUaglJ/Xfjw/1jM
 N6rkezDgcASHcKi+9OWujRB8An1lZzyRORGc4UOhYiM1p0nAI/mavcu24SLQfub6SfEjHVx0VVd
 9HxISKgtDUMeLwEmv9gt+WqXNs85ILPrEdedgpGnwjTTdLRM30z2hDLEvF7yZvtM4rpd+cRDHZu
 PXAcwNCmbO4IDr8CiqjMhdTq3M2gVEJJvhJQvC+LUsHWXesQ/aaUIzWfEHLmVeWrSYMt62rhFlN
 6TZhXQR/AgswhvTkqida71CU93U36v9uLyYQdvZLq3+icerOwBx8Em/5Bbw1QLJizJqDGeb6Wyo
 FoXONlDEhUoUD3CEHJkwUFH7F3lRqTlJXU9ZIJILAoT+EuquxsEG3SvdN90h5GuxYfernAewprc
 fxzuVxSE+w3+BL6W6VVMstOdoQv8LiE5w7QD0wy3NK6wQwakqtyL1LSnlMje6at1Cf0Ix+d0TFm
 Otlh6DU8KTmLTBJf5jkDiwiKtZFUlBzkDkjf6M/FSMWsN885ctAKi0tLAjqOveYBwbTg2HC/V1F
 caIHO8iZhViJvg41o8F8+K42VrhWLx9Lgx4nlFt2ZMh3ADBXRGP/4hNbxjzo3hfQk+dg/TCJ26+
 MX3RxiMjtBWhL3A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The onboard Wi-Fi / BT device, WCN3990, has a simple on-chip PMU, which
further spreads generated voltage. Describe the PMU in the device tree
and rewire Bluetooth and Wi-Fi supply properties to use the PMU LDO
outputs instead of referencing the SoC regulators directly.

Couldn't verify the swctrl GPIO thus omitted.

Assisted-by: Claude:claude-opus-4.6
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 42 ++++++++++++++++++----
 1 file changed, 35 insertions(+), 7 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index fd9788d5c3f54..6930066857768 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -131,6 +131,33 @@ vreg_s4a_1p8: regulator-vreg-s4a-1p8 {
 
 		vin-supply = <&vph_pwr>;
 	};
+
+	wcn3990-pmu {
+		compatible = "qcom,wcn3990-pmu";
+
+		vddio-supply = <&vreg_s4a_1p8>;
+		vddxo-supply = <&vreg_l7a_1p8>;
+		vddrf-supply = <&vreg_l17a_1p3>;
+		vddch0-supply = <&vreg_l25a_3p3>;
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
+		};
+	};
 };
 
 &adsp_pas {
@@ -462,10 +489,11 @@ &uart6 {
 	bluetooth {
 		compatible = "qcom,wcn3990-bt";
 
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
@@ -526,9 +554,9 @@ &venus {
 
 &wifi {
 	vdd-0.8-cx-mx-supply = <&vreg_l5a_0p8>;
-	vdd-1.8-xo-supply = <&vreg_l7a_1p8>;
-	vdd-1.3-rfa-supply = <&vreg_l17a_1p3>;
-	vdd-3.3-ch0-supply = <&vreg_l25a_3p3>;
+	vdd-1.8-xo-supply = <&vreg_pmu_xo>;
+	vdd-1.3-rfa-supply = <&vreg_pmu_rf>;
+	vdd-3.3-ch0-supply = <&vreg_pmu_ch0>;
 
 	qcom,snoc-host-cap-8bit-quirk;
 

-- 
2.53.0

