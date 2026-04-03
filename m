From: Aastha Pandey <aastha.pandey@oss.qualcomm.com>
Date: Fri, 03 Apr 2026 17:26:33 +0530
Subject: [PATCH] arm64: dts: qcom: sm8750: Enable cpufreq cooling devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-cpufreq-v1-1-9d465988c3f9@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAPCqz2kC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDEwNj3eSC0rSi1ELdRBPztFRDSwszEzNLJaDqgqLUtMwKsEnRsRB+cWl
 SVmpyCUi7Um0tAPwz9alrAAAA
X-Change-ID: 20260403-cpufreq-a47fe1986469
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Aastha Pandey <aastha.pandey@oss.qualcomm.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775217399; l=2411;
 i=aastha.pandey@oss.qualcomm.com; s=20260403; h=from:subject:message-id;
 bh=pWCKzSBAkycqtXHkJIG6H/zPrgLnVC5AlewOSyTpRrk=;
 b=3AVtCFAUZN2NXOPlr9WgYjlX8Q/S0igw0nhafXY/HBVgDz+FCZVIU0Sfc/Blgdzs+MsPF39hs
 JXvrOgR6gPPBak2T1z9w3Wf6kNuo3EAvJqNjJzvxV8NeQMw7j6HMkpP
X-Developer-Key: i=aastha.pandey@oss.qualcomm.com; a=ed25519;
 pk=d6/MXR/csKllB5RHkSN8v/2MfXzvzd7m1vH2PJXwpB0=
X-Endpoint-Received: by B4 Relay for aastha.pandey@oss.qualcomm.com/20260403 with auth_id=718
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add cooling-cells property to the CPU nodes to support cpufreq
cooling devices.

Signed-off-by: Aastha Pandey <aastha.pandey@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/sm8750.dtsi | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8750.dtsi b/arch/arm64/boot/dts/qcom/sm8750.dtsi
index 18fb52c14acd..417f28d8c919 100644
--- a/arch/arm64/boot/dts/qcom/sm8750.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8750.dtsi
@@ -42,6 +42,7 @@ cpu0: cpu@0 {
 			next-level-cache = <&l2_0>;
 			power-domains = <&cpu_pd0>, <&scmi_dvfs 0>;
 			power-domain-names = "psci", "perf";
+			#cooling-cells = <2>;
 
 			l2_0: l2-cache {
 				compatible = "cache";
@@ -58,6 +59,7 @@ cpu1: cpu@100 {
 			next-level-cache = <&l2_0>;
 			power-domains = <&cpu_pd1>, <&scmi_dvfs 0>;
 			power-domain-names = "psci", "perf";
+			#cooling-cells = <2>;
 		};
 
 		cpu2: cpu@200 {
@@ -68,6 +70,7 @@ cpu2: cpu@200 {
 			next-level-cache = <&l2_0>;
 			power-domains = <&cpu_pd2>, <&scmi_dvfs 0>;
 			power-domain-names = "psci", "perf";
+			#cooling-cells = <2>;
 		};
 
 		cpu3: cpu@300 {
@@ -78,6 +81,7 @@ cpu3: cpu@300 {
 			next-level-cache = <&l2_0>;
 			power-domains = <&cpu_pd3>, <&scmi_dvfs 0>;
 			power-domain-names = "psci", "perf";
+			#cooling-cells = <2>;
 		};
 
 		cpu4: cpu@400 {
@@ -88,6 +92,7 @@ cpu4: cpu@400 {
 			next-level-cache = <&l2_0>;
 			power-domains = <&cpu_pd4>, <&scmi_dvfs 0>;
 			power-domain-names = "psci", "perf";
+			#cooling-cells = <2>;
 		};
 
 		cpu5: cpu@500 {
@@ -98,6 +103,7 @@ cpu5: cpu@500 {
 			next-level-cache = <&l2_0>;
 			power-domains = <&cpu_pd5>, <&scmi_dvfs 0>;
 			power-domain-names = "psci", "perf";
+			#cooling-cells = <2>;
 		};
 
 		cpu6: cpu@10000 {
@@ -108,6 +114,7 @@ cpu6: cpu@10000 {
 			next-level-cache = <&l2_1>;
 			power-domains = <&cpu_pd6>, <&scmi_dvfs 1>;
 			power-domain-names = "psci", "perf";
+			#cooling-cells = <2>;
 
 			l2_1: l2-cache {
 				compatible = "cache";
@@ -124,6 +131,7 @@ cpu7: cpu@10100 {
 			next-level-cache = <&l2_1>;
 			power-domains = <&cpu_pd7>, <&scmi_dvfs 1>;
 			power-domain-names = "psci", "perf";
+			#cooling-cells = <2>;
 		};
 
 		cpu-map {

---
base-commit: cc13002a9f984d37906e9476f3e532a8cdd126f5
change-id: 20260403-cpufreq-a47fe1986469

Best regards,
--  
Aastha Pandey <aastha.pandey@oss.qualcomm.com>

