From: George Moussalem <george.moussalem@outlook.com>
Date: Fri, 18 Jul 2025 11:38:04 +0400
Subject: [PATCH v14 2/2] arm64: dts: qcom: ipq5018: Update tsens node and
 thermal zones
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250718-ipq5018-tsens-v14-2-28d8a2472418@outlook.com>
References: <20250718-ipq5018-tsens-v14-0-28d8a2472418@outlook.com>
In-Reply-To: <20250718-ipq5018-tsens-v14-0-28d8a2472418@outlook.com>
To: Amit Kucheria <amitk@kernel.org>, 
 Thara Gopinath <thara.gopinath@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Sricharan Ramabadhran <quic_srichara@quicinc.com>, 
 George Moussalem <george.moussalem@outlook.com>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752824290; l=3848;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=SwJcY4cCvc+nIankAMt5+SCPwBFBGOQVItGhlf/eWGU=;
 b=GTCG1e6Toew3AUfHJHm9fwJ3pdtIkfCn7Hc6H/MDUo7DhW7lN6TNtlWiBmnIszihuvS55+XRT
 QC8elkaStAMAQ2KryJ8HLRI+nrydf4RXeSzSECjxfKU9qW6V/ucn/9q
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sricharan Ramabadhran <quic_srichara@quicinc.com>

Remove qcom,tsens-v1 as fallback since this IP has no RPM and, as such,
must use its own init routine available in the driver.
Also adding a cooling device to the CPU thermal zone which uses CPU
frequency scaling.
In addition, remove superfluous polling-delay properties for which the
default is already set to zero, correctly set hysteresis properties
measured in milli Celsius as opposed to Celsius, and replace an
underscore in an alias with a hyphen to align with device tree coding
guidelines.

Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@linaro.org>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Sricharan Ramabadhran <quic_srichara@quicinc.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 41 +++++++++++++++++++++--------------
 1 file changed, 25 insertions(+), 16 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index ee0001741d211b187e89a39a3caaa576251aff03..1b33ccf1a1b1af721b9690ae2c35eb82985205f5 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -9,6 +9,7 @@
 #include <dt-bindings/interrupt-controller/arm-gic.h>
 #include <dt-bindings/clock/qcom,gcc-ipq5018.h>
 #include <dt-bindings/reset/qcom,gcc-ipq5018.h>
+#include <dt-bindings/thermal/thermal.h>
 
 / {
 	interrupt-parent = <&intc>;
@@ -39,6 +40,7 @@ cpu0: cpu@0 {
 			next-level-cache = <&l2_0>;
 			clocks = <&apcs_glb APCS_ALIAS0_CORE_CLK>;
 			operating-points-v2 = <&cpu_opp_table>;
+			#cooling-cells = <2>;
 		};
 
 		cpu1: cpu@1 {
@@ -49,6 +51,7 @@ cpu1: cpu@1 {
 			next-level-cache = <&l2_0>;
 			clocks = <&apcs_glb APCS_ALIAS0_CORE_CLK>;
 			operating-points-v2 = <&cpu_opp_table>;
+			#cooling-cells = <2>;
 		};
 
 		l2_0: l2-cache {
@@ -255,9 +258,9 @@ tsens_s4_p2: s4-p2@254 {
 		};
 
 		tsens: thermal-sensor@4a9000 {
-			compatible = "qcom,ipq5018-tsens", "qcom,tsens-v1";
-			reg = <0x004a9000 0x1000>, /* TM */
-			      <0x004a8000 0x1000>; /* SROT */
+			compatible = "qcom,ipq5018-tsens";
+			reg = <0x004a9000 0x1000>,
+			      <0x004a8000 0x1000>;
 
 			nvmem-cells = <&tsens_mode>,
 				      <&tsens_base1>,
@@ -744,56 +747,62 @@ pcie@0 {
 
 	thermal-zones {
 		cpu-thermal {
-			polling-delay-passive = <0>;
-			polling-delay = <0>;
 			thermal-sensors = <&tsens 2>;
 
 			trips {
 				cpu-critical {
 					temperature = <120000>;
-					hysteresis = <2>;
+					hysteresis = <1000>;
 					type = "critical";
 				};
+
+				cpu_alert: cpu-passive {
+					temperature = <100000>;
+					hysteresis = <1000>;
+					type = "passive";
+				};
+			};
+
+			cooling-maps {
+				map0 {
+					trip = <&cpu_alert>;
+					cooling-device = <&cpu0 THERMAL_NO_LIMIT THERMAL_NO_LIMIT>,
+							 <&cpu1 THERMAL_NO_LIMIT THERMAL_NO_LIMIT>;
+				};
 			};
 		};
 
 		gephy-thermal {
-			polling-delay-passive = <0>;
-			polling-delay = <0>;
 			thermal-sensors = <&tsens 4>;
 
 			trips {
 				gephy-critical {
 					temperature = <120000>;
-					hysteresis = <2>;
+					hysteresis = <1000>;
 					type = "critical";
 				};
 			};
 		};
 
 		top-glue-thermal {
-			polling-delay-passive = <0>;
-			polling-delay = <0>;
 			thermal-sensors = <&tsens 3>;
 
 			trips {
-				top_glue-critical {
+				top-glue-critical {
 					temperature = <120000>;
-					hysteresis = <2>;
+					hysteresis = <1000>;
 					type = "critical";
 				};
 			};
 		};
 
 		ubi32-thermal {
-			polling-delay-passive = <0>;
-			polling-delay = <0>;
 			thermal-sensors = <&tsens 1>;
 
 			trips {
 				ubi32-critical {
 					temperature = <120000>;
-					hysteresis = <2>;
+					hysteresis = <1000>;
 					type = "critical";
 				};
 			};

-- 
2.50.1

