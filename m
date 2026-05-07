From: Haritha S K <haritha.k@oss.qualcomm.com>
Date: Thu, 07 May 2026 11:59:50 +0530
Subject: [PATCH] arm64: dts: qcom: glymur: Enable cpufreq cooling devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260507-glymur_cpu_freq-v1-1-d566cc1d32c3@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAF4x/GkC/yXMTQqDMBBA4avIrA1kUnThVYpIjKOOWH8mRiri3
 Zvq8lu8d4InYfJQJCcI7ex5niIwTcD1dupIcRMNRptcZzpT3Xh8glRuCVUrtCq0mBMaaw2+IFa
 LUMvf+/guH/tQD+S2/wau6wf9E9cTcwAAAA==
X-Change-ID: 20260505-glymur_cpu_freq-1a16e12aa213
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, manaf.pallikunhi@oss.qualcomm.com, 
 gaurav.kohli@oss.qualcomm.com, Haritha S K <haritha.k@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778135396; l=4683;
 i=haritha.k@oss.qualcomm.com; s=20260422; h=from:subject:message-id;
 bh=bI7+4pLky4jLFMKlYUdkSEXsFPxmbXV05qBezAGMXV8=;
 b=vd06qx7K61rX/W13PKZ+5bHGXS2kvn3Z8fN6QWD/HgTp8qTCd3NX9xoNYazwfhcKIIdHw3sNu
 laIVCGb84aLBpc1XqtfhowRGd1cxv1KvyXzJ62yLWeAc1UpXv2fJ1aL
X-Developer-Key: i=haritha.k@oss.qualcomm.com; a=ed25519;
 pk=ivp2P9RgsC6IkOe8JaqweeahT9pd0BVtL2d1YD8ICSg=
X-Endpoint-Received: by B4 Relay for haritha.k@oss.qualcomm.com/20260422 with auth_id=745
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add cooling-cells property to the CPU nodes to support cpufreq
cooling devices.

Signed-off-by: Haritha S K <haritha.k@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/glymur.dtsi | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/glymur.dtsi b/arch/arm64/boot/dts/qcom/glymur.dtsi
index f23cf81ddb77..5fb685664370 100644
--- a/arch/arm64/boot/dts/qcom/glymur.dtsi
+++ b/arch/arm64/boot/dts/qcom/glymur.dtsi
@@ -39,6 +39,7 @@ cpu0: cpu@0 {
 			power-domains = <&cpu_pd0>, <&scmi_perf 0>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_0>;
+			#cooling-cells = <2>;
 
 			l2_0: l2-cache {
 				compatible = "cache";
@@ -55,6 +56,7 @@ cpu1: cpu@100 {
 			power-domains = <&cpu_pd1>, <&scmi_perf 0>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_0>;
+			#cooling-cells = <2>;
 		};
 
 		cpu2: cpu@200 {
@@ -65,6 +67,7 @@ cpu2: cpu@200 {
 			power-domains = <&cpu_pd2>, <&scmi_perf 0>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_0>;
+			#cooling-cells = <2>;
 		};
 
 		cpu3: cpu@300 {
@@ -75,6 +78,7 @@ cpu3: cpu@300 {
 			power-domains = <&cpu_pd3>, <&scmi_perf 0>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_0>;
+			#cooling-cells = <2>;
 		};
 
 		cpu4: cpu@400 {
@@ -85,6 +89,7 @@ cpu4: cpu@400 {
 			power-domains = <&cpu_pd4>, <&scmi_perf 0>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_0>;
+			#cooling-cells = <2>;
 		};
 
 		cpu5: cpu@500 {
@@ -95,6 +100,7 @@ cpu5: cpu@500 {
 			power-domains = <&cpu_pd5>, <&scmi_perf 0>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_0>;
+			#cooling-cells = <2>;
 		};
 
 		cpu6: cpu@10000 {
@@ -105,6 +111,7 @@ cpu6: cpu@10000 {
 			power-domains = <&cpu_pd6>, <&scmi_perf 1>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_1>;
+			#cooling-cells = <2>;
 
 			l2_1: l2-cache {
 				compatible = "cache";
@@ -121,6 +128,7 @@ cpu7: cpu@10100 {
 			power-domains = <&cpu_pd7>, <&scmi_perf 1>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_1>;
+			#cooling-cells = <2>;
 		};
 
 		cpu8: cpu@10200 {
@@ -131,6 +139,7 @@ cpu8: cpu@10200 {
 			power-domains = <&cpu_pd8>, <&scmi_perf 1>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_1>;
+			#cooling-cells = <2>;
 		};
 
 		cpu9: cpu@10300 {
@@ -141,6 +150,7 @@ cpu9: cpu@10300 {
 			power-domains = <&cpu_pd9>, <&scmi_perf 1>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_1>;
+			#cooling-cells = <2>;
 		};
 
 		cpu10: cpu@10400 {
@@ -151,6 +161,7 @@ cpu10: cpu@10400 {
 			power-domains = <&cpu_pd10>, <&scmi_perf 1>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_1>;
+			#cooling-cells = <2>;
 		};
 
 		cpu11: cpu@10500 {
@@ -161,6 +172,7 @@ cpu11: cpu@10500 {
 			power-domains = <&cpu_pd11>, <&scmi_perf 1>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_1>;
+			#cooling-cells = <2>;
 		};
 
 		cpu12: cpu@20000 {
@@ -171,6 +183,7 @@ cpu12: cpu@20000 {
 			power-domains = <&cpu_pd12>, <&scmi_perf 2>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_2>;
+			#cooling-cells = <2>;
 
 			l2_2: l2-cache {
 				compatible = "cache";
@@ -187,6 +200,7 @@ cpu13: cpu@20100 {
 			power-domains = <&cpu_pd13>, <&scmi_perf 2>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_2>;
+			#cooling-cells = <2>;
 		};
 
 		cpu14: cpu@20200 {
@@ -197,6 +211,7 @@ cpu14: cpu@20200 {
 			power-domains = <&cpu_pd14>, <&scmi_perf 2>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_2>;
+			#cooling-cells = <2>;
 		};
 
 		cpu15: cpu@20300 {
@@ -207,6 +222,7 @@ cpu15: cpu@20300 {
 			power-domains = <&cpu_pd15>, <&scmi_perf 2>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_2>;
+			#cooling-cells = <2>;
 		};
 
 		cpu16: cpu@20400 {
@@ -217,6 +233,7 @@ cpu16: cpu@20400 {
 			power-domains = <&cpu_pd16>, <&scmi_perf 2>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_2>;
+			#cooling-cells = <2>;
 		};
 
 		cpu17: cpu@20500 {
@@ -227,6 +244,7 @@ cpu17: cpu@20500 {
 			power-domains = <&cpu_pd17>, <&scmi_perf 2>;
 			power-domain-names = "psci", "perf";
 			next-level-cache = <&l2_2>;
+			#cooling-cells = <2>;
 		};
 
 		cpu-map {

---
base-commit: 82a481aae4502d10ebaeeb387a3e0a5462c05b4d
change-id: 20260505-glymur_cpu_freq-1a16e12aa213

Best regards,
--  
Haritha S K <haritha.k@oss.qualcomm.com>

