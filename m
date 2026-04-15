From: Dipa Mantre <dipa.mantre@oss.qualcomm.com>
Date: Wed, 15 Apr 2026 16:27:08 +0530
Subject: [PATCH] arm64: dts: qcom: kaanapali: Enable cpufreq cooling
 devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260415-cpufreq_kaanapali-v1-1-1fa94105d5c2@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAANv32kC/x3MQQqAIBBA0avErBNSzKKrRMRgYw2FmVIE0d2Tl
 m/x/wOJIlOCrngg0sWJd58hywLsgn4mwVM2qEqZSkstbDhdpGNcET0G3Fg41RqDsq1NYyF3IZL
 j+3/2w/t+TOglfGMAAAA=
X-Change-ID: 20260414-cpufreq_kaanapali-f2866a18567c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dipa Mantre <dipa.mantre@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776250633; l=2252;
 i=dipa.mantre@oss.qualcomm.com; s=20260415; h=from:subject:message-id;
 bh=qRlPI1bp3rfMHl7Ftdun6TIjf61wRmlS2KEJHHF/2v8=;
 b=qNqvbAR4egJ6GWZqWKqT9ABaOPEAGXRaIL9qKVvArzFmcnKe8OoaDzesdTly5yTJiT9UAbOR+
 I8EtSgUX73UDv5rHckmAuAfOog4XJIeo9LARNMb9XzlbnbC24c4TFYz
X-Developer-Key: i=dipa.mantre@oss.qualcomm.com; a=ed25519;
 pk=IcrgHu2jFHNILPVydQwFqCQq05WcA8wBixw5s+yRMVI=
X-Endpoint-Received: by B4 Relay for dipa.mantre@oss.qualcomm.com/20260415 with auth_id=736
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add cooling-cells property to the CPU nodes to support cpufreq
cooling devices.

Signed-off-by: Dipa Mantre <dipa.mantre@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/kaanapali.dtsi | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/kaanapali.dtsi b/arch/arm64/boot/dts/qcom/kaanapali.dtsi
index 7cc326aa1a1a..81c493668b51 100644
--- a/arch/arm64/boot/dts/qcom/kaanapali.dtsi
+++ b/arch/arm64/boot/dts/qcom/kaanapali.dtsi
@@ -48,6 +48,7 @@ cpu0: cpu@0 {
 			power-domains = <&cpu_pd0>;
 			power-domain-names = "psci";
 			clocks = <&pdp_scmi_perf 0>;
+			#cooling-cells = <2>;
 
 			l2_0: l2-cache {
 				compatible = "cache";
@@ -65,6 +66,7 @@ cpu1: cpu@100 {
 			power-domains = <&cpu_pd1>;
 			power-domain-names = "psci";
 			clocks = <&pdp_scmi_perf 0>;
+			#cooling-cells = <2>;
 		};
 
 		cpu2: cpu@200 {
@@ -76,6 +78,7 @@ cpu2: cpu@200 {
 			power-domains = <&cpu_pd2>;
 			power-domain-names = "psci";
 			clocks = <&pdp_scmi_perf 0>;
+			#cooling-cells = <2>;
 		};
 
 		cpu3: cpu@300 {
@@ -87,6 +90,7 @@ cpu3: cpu@300 {
 			power-domains = <&cpu_pd3>;
 			power-domain-names = "psci";
 			clocks = <&pdp_scmi_perf 0>;
+			#cooling-cells = <2>;
 		};
 
 		cpu4: cpu@400 {
@@ -98,6 +102,7 @@ cpu4: cpu@400 {
 			power-domains = <&cpu_pd4>;
 			power-domain-names = "psci";
 			clocks = <&pdp_scmi_perf 0>;
+			#cooling-cells = <2>;
 		};
 
 		cpu5: cpu@500 {
@@ -109,6 +114,7 @@ cpu5: cpu@500 {
 			power-domains = <&cpu_pd5>;
 			power-domain-names = "psci";
 			clocks = <&pdp_scmi_perf 0>;
+			#cooling-cells = <2>;
 		};
 
 		cpu6: cpu@10000 {
@@ -120,6 +126,7 @@ cpu6: cpu@10000 {
 			power-domains = <&cpu_pd6>;
 			power-domain-names = "psci";
 			clocks = <&pdp_scmi_perf 1>;
+			#cooling-cells = <2>;
 
 			l2_1: l2-cache {
 				compatible = "cache";
@@ -137,6 +144,7 @@ cpu7: cpu@10100 {
 			power-domains = <&cpu_pd7>;
 			power-domain-names = "psci";
 			clocks = <&pdp_scmi_perf 1>;
+			#cooling-cells = <2>;
 		};
 
 		cpu-map {

---
base-commit: e6efabc0afca02efa263aba533f35d90117ab283
change-id: 20260414-cpufreq_kaanapali-f2866a18567c

Best regards,
-- 
Dipa Ramesh Mantre <dipa.mantre@oss.qualcomm.com>

