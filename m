From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 30 Mar 2026 16:50:20 -0500
Subject: [PATCH v4] arm64: dts: qcom: sm8550: add cpu OPP table with DDR,
 LLCC & L3 bandwidths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260330-sm8550-ddr-bw-scaling-v4-1-5020c06983a0@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XPTQqDMBAF4KtI1k1JJtGYrnqP0kVMogb8KUmxL
 eLdO7qSgnT5HjPfMDNJPgafyCWbSfRTSGEcMMhTRmxrhsbT4DATYFAwYIqmvsxzRp2LtHrRZE0
 XhoZWPAdZgqpxhODuI/o6vDf3dsfchvQc42c7M/G1/SdOnGKnCytqoY2V1bXpTejOduzJKk6wU
 3h5pAAqUhioCieVV+xXEXtFHykCFZVbrvFNr4HvlWVZvu+wKBxGAQAA
X-Change-ID: 20260207-sm8550-ddr-bw-scaling-b1524827f207
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Georgi Djakov <djakov@kernel.org>, 
 Sibi Sankar <sibi.sankar@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774907421; l=16213;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=MviJMfCzXuwRQrPnbut1Q4KDvJa/L9E82uU8Q9FShqk=;
 b=4qNDLTcTj68/lwip3FG/NrOr+KNPKUYCbMBBElETf1EVphVB7NtEt6eHfNqkU+LXil0qiw5SB
 mXz9iE9boUdC3ryUdHa/XZ24qZT+ZEOc7GzF4/wqiQ/D14h1k2BB7GI
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the OPP tables for each CPU clusters (cpu0-1-2, cpu3-4-5-6 & cpu7)
to permit scaling the Last Level Cache Controller (LLCC), DDR and L3 cache
frequency by aggregating bandwidth requests of all CPU core with referenc
to the current OPP they are configured in by the LMH/EPSS hardware.

The effect is a proper caches & DDR frequency scaling when CPU cores
changes frequency.

The OPP tables were built using the downstream memlat ddr, llcc & l3
tables for each cluster types with the actual EPSS cpufreq LUT tables
from running a QCS8550 device.

Also add the OSC L3 Cache controller node.

Also add the interconnect entry for each cpu, with 3 different paths:
- CPU to Last Level Cache Controller (LLCC)
- Last Level Cache Controller (LLCC) to DDR
- L3 Cache from CPU to DDR interface

Tested-by: Neil Armstrong <neil.armstrong@linaro.org> # on SM8550-HDK
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Add the OSM L3 controller node then add the necessary interconnect
properties with the appropriate OPP table for each CPU cluster to
allow the DDR, LLCC & L3 CPU bandwidth to scale along the CPU
cluster operating point.
---
Changes in v4:
- Rebase on -next and resolve merge conflicts
- Drop patch 1 as it was already picked up
- Link to v3: https://lore.kernel.org/r/20260219-sm8550-ddr-bw-scaling-v3-0-75c19152e921@gmail.com

Changes in v3:
- Squash the last two patches
- Link to v2: https://lore.kernel.org/r/20260218-sm8550-ddr-bw-scaling-v2-0-43a2b6d47e70@gmail.com

Changes in v2:
- Squash first two patches
- Update opp tables in last patch to match how the downstream driver
  parses those tables
- Link to v1: https://lore.kernel.org/r/20260207-sm8550-ddr-bw-scaling-v1-0-d96c3f39ac4b@gmail.com
---
 arch/arm64/boot/dts/qcom/sm8550.dtsi | 367 +++++++++++++++++++++++++++++++++++
 1 file changed, 367 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8550.dtsi b/arch/arm64/boot/dts/qcom/sm8550.dtsi
index 912525e9bca6f5e1cbb8887ee0bf9e39650dc4ff..b7a7c49db077bd36f5705efeae427287eb23ffe4 100644
--- a/arch/arm64/boot/dts/qcom/sm8550.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8550.dtsi
@@ -17,6 +17,7 @@
 #include <dt-bindings/interrupt-controller/arm-gic.h>
 #include <dt-bindings/interconnect/qcom,icc.h>
 #include <dt-bindings/interconnect/qcom,sm8550-rpmh.h>
+#include <dt-bindings/interconnect/qcom,osm-l3.h>
 #include <dt-bindings/mailbox/qcom-ipcc.h>
 #include <dt-bindings/power/qcom-rpmpd.h>
 #include <dt-bindings/power/qcom,rpmhpd.h>
@@ -78,6 +79,13 @@ cpu0: cpu@0 {
 			qcom,freq-domain = <&cpufreq_hw 0>;
 			capacity-dmips-mhz = <326>;
 			dynamic-power-coefficient = <251>;
+			operating-points-v2 = <&cpu0_opp_table>;
+			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&epss_l3 MASTER_EPSS_L3_APPS
+					 &epss_l3 SLAVE_EPSS_L3_SHARED>;
 			#cooling-cells = <2>;
 			l2_0: l2-cache {
 				compatible = "cache";
@@ -104,6 +112,13 @@ cpu1: cpu@100 {
 			qcom,freq-domain = <&cpufreq_hw 0>;
 			capacity-dmips-mhz = <326>;
 			dynamic-power-coefficient = <251>;
+			operating-points-v2 = <&cpu0_opp_table>;
+			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&epss_l3 MASTER_EPSS_L3_APPS
+					 &epss_l3 SLAVE_EPSS_L3_SHARED>;
 			#cooling-cells = <2>;
 			l2_100: l2-cache {
 				compatible = "cache";
@@ -125,6 +140,13 @@ cpu2: cpu@200 {
 			qcom,freq-domain = <&cpufreq_hw 0>;
 			capacity-dmips-mhz = <326>;
 			dynamic-power-coefficient = <251>;
+			operating-points-v2 = <&cpu0_opp_table>;
+			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&epss_l3 MASTER_EPSS_L3_APPS
+					 &epss_l3 SLAVE_EPSS_L3_SHARED>;
 			#cooling-cells = <2>;
 			l2_200: l2-cache {
 				compatible = "cache";
@@ -146,6 +168,13 @@ cpu3: cpu@300 {
 			qcom,freq-domain = <&cpufreq_hw 1>;
 			capacity-dmips-mhz = <693>;
 			dynamic-power-coefficient = <447>;
+			operating-points-v2 = <&cpu3_opp_table>;
+			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&epss_l3 MASTER_EPSS_L3_APPS
+					 &epss_l3 SLAVE_EPSS_L3_SHARED>;
 			#cooling-cells = <2>;
 			l2_300: l2-cache {
 				compatible = "cache";
@@ -167,6 +196,13 @@ cpu4: cpu@400 {
 			qcom,freq-domain = <&cpufreq_hw 1>;
 			capacity-dmips-mhz = <693>;
 			dynamic-power-coefficient = <447>;
+			operating-points-v2 = <&cpu3_opp_table>;
+			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&epss_l3 MASTER_EPSS_L3_APPS
+					 &epss_l3 SLAVE_EPSS_L3_SHARED>;
 			#cooling-cells = <2>;
 			l2_400: l2-cache {
 				compatible = "cache";
@@ -188,6 +224,13 @@ cpu5: cpu@500 {
 			qcom,freq-domain = <&cpufreq_hw 1>;
 			capacity-dmips-mhz = <693>;
 			dynamic-power-coefficient = <447>;
+			operating-points-v2 = <&cpu3_opp_table>;
+			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&epss_l3 MASTER_EPSS_L3_APPS
+					 &epss_l3 SLAVE_EPSS_L3_SHARED>;
 			#cooling-cells = <2>;
 			l2_500: l2-cache {
 				compatible = "cache";
@@ -209,6 +252,13 @@ cpu6: cpu@600 {
 			qcom,freq-domain = <&cpufreq_hw 1>;
 			capacity-dmips-mhz = <693>;
 			dynamic-power-coefficient = <447>;
+			operating-points-v2 = <&cpu3_opp_table>;
+			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&epss_l3 MASTER_EPSS_L3_APPS
+					 &epss_l3 SLAVE_EPSS_L3_SHARED>;
 			#cooling-cells = <2>;
 			l2_600: l2-cache {
 				compatible = "cache";
@@ -230,6 +280,13 @@ cpu7: cpu@700 {
 			qcom,freq-domain = <&cpufreq_hw 2>;
 			capacity-dmips-mhz = <1024>;
 			dynamic-power-coefficient = <1057>;
+			operating-points-v2 = <&cpu7_opp_table>;
+			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&epss_l3 MASTER_EPSS_L3_APPS
+					 &epss_l3 SLAVE_EPSS_L3_SHARED>;
 			#cooling-cells = <2>;
 			l2_700: l2-cache {
 				compatible = "cache";
@@ -397,6 +454,306 @@ memory@a0000000 {
 		reg = <0 0xa0000000 0 0>;
 	};
 
+	cpu0_opp_table: opp-table-cpu0 {
+		compatible = "operating-points-v2";
+		opp-shared;
+
+		opp-307200000 {
+			opp-hz = /bits/ 64 <307200000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (307200 * 32)>;
+		};
+
+		opp-441600000 {
+			opp-hz = /bits/ 64 <441600000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (384000 * 32)>;
+		};
+
+		opp-556800000 {
+			opp-hz = /bits/ 64 <556800000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (499200 * 32)>;
+		};
+
+		opp-672000000 {
+			opp-hz = /bits/ 64 <672000000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (499200 * 32)>;
+		};
+
+		opp-787200000 {
+			opp-hz = /bits/ 64 <787200000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (729600 * 32)>;
+		};
+
+		opp-902400000 {
+			opp-hz = /bits/ 64 <902400000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (844800 * 32)>;
+		};
+
+		opp-1017600000 {
+			opp-hz = /bits/ 64 <1017600000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (940800 * 32)>;
+		};
+
+		opp-1113600000 {
+			opp-hz = /bits/ 64 <1113600000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (1056000 * 32)>;
+		};
+
+		opp-1228800000 {
+			opp-hz = /bits/ 64 <1228800000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (1152000 * 32)>;
+		};
+
+		opp-1344000000 {
+			opp-hz = /bits/ 64 <1344000000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (1267200 * 32)>;
+		};
+
+		opp-1459200000 {
+			opp-hz = /bits/ 64 <1459200000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (1267200 * 32)>;
+		};
+
+		opp-1555200000 {
+			opp-hz = /bits/ 64 <1555200000>;
+			opp-peak-kBps = <(466000 * 16) (768000 * 4) (1478400 * 32)>;
+		};
+
+		opp-1670400000 {
+			opp-hz = /bits/ 64 <1670400000>;
+			opp-peak-kBps = <(466000 * 16) (768000 * 4) (1478400 * 32)>;
+		};
+
+		opp-1785600000 {
+			opp-hz = /bits/ 64 <1785600000>;
+			opp-peak-kBps = <(466000 * 16) (768000 * 4) (1478400 * 32)>;
+		};
+
+		opp-1900800000 {
+			opp-hz = /bits/ 64 <1900800000>;
+			opp-peak-kBps = <(466000 * 16) (768000 * 4) (1689600 * 32)>;
+		};
+
+		opp-2016000000 {
+			opp-hz = /bits/ 64 <2016000000>;
+			opp-peak-kBps = <(600000 * 16) (1555000 * 4) (1804800 * 32)>;
+		};
+	};
+
+	cpu3_opp_table: opp-table-cpu3 {
+		compatible = "operating-points-v2";
+		opp-shared;
+
+		opp-499200000 {
+			opp-hz = /bits/ 64 <499200000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (307200 * 32)>;
+		};
+
+		opp-614400000 {
+			opp-hz = /bits/ 64 <614400000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (499200 * 32)>;
+		};
+
+		opp-729600000 {
+			opp-hz = /bits/ 64 <729600000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (499200 * 32)>;
+		};
+
+		opp-844800000 {
+			opp-hz = /bits/ 64 <844800000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (499200 * 32)>;
+		};
+
+		opp-940800000 {
+			opp-hz = /bits/ 64 <940800000>;
+			opp-peak-kBps = <(300000 * 16) (768000 * 4) (729600 * 32)>;
+		};
+
+		opp-1056000000 {
+			opp-hz = /bits/ 64 <1056000000>;
+			opp-peak-kBps = <(300000 * 16) (768000 * 4) (729600 * 32)>;
+		};
+
+		opp-1171200000 {
+			opp-hz = /bits/ 64 <1171200000>;
+			opp-peak-kBps = <(466000 * 16) (1555000 * 4) (940800 * 32)>;
+		};
+
+		opp-1286400000 {
+			opp-hz = /bits/ 64 <1286400000>;
+			opp-peak-kBps = <(466000 * 16) (1555000 * 4) (940800 * 32)>;
+		};
+
+		opp-1401600000 {
+			opp-hz = /bits/ 64 <1401600000>;
+			opp-peak-kBps = <(600000 * 16) (1708000 * 4) (1056000 * 32)>;
+		};
+
+		opp-1536000000 {
+			opp-hz = /bits/ 64 <1536000000>;
+			opp-peak-kBps = <(600000 * 16) (1708000 * 4) (1056000 * 32)>;
+		};
+
+		opp-1651200000 {
+			opp-hz = /bits/ 64 <1651200000>;
+			opp-peak-kBps = <(600000 * 16) (1708000 * 4) (1267200 * 32)>;
+		};
+
+		opp-1785600000 {
+			opp-hz = /bits/ 64 <1785600000>;
+			opp-peak-kBps = <(600000 * 16) (1708000 * 4) (1267200 * 32)>;
+		};
+
+		opp-1920000000 {
+			opp-hz = /bits/ 64 <1920000000>;
+			opp-peak-kBps = <(806000 * 16) (2736000 * 4) (1267200 * 32)>;
+		};
+
+		opp-2054400000 {
+			opp-hz = /bits/ 64 <2054400000>;
+			opp-peak-kBps = <(806000 * 16) (2736000 * 4) (1478400 * 32)>;
+		};
+
+		opp-2188800000 {
+			opp-hz = /bits/ 64 <2188800000>;
+			opp-peak-kBps = <(806000 * 16) (2736000 * 4) (1478400 * 32)>;
+		};
+
+		opp-2323200000 {
+			opp-hz = /bits/ 64 <2323200000>;
+			opp-peak-kBps = <(806000 * 16) (2736000 * 4) (1478400 * 32)>;
+		};
+
+		opp-2457600000 {
+			opp-hz = /bits/ 64 <2457600000>;
+			opp-peak-kBps = <(806000 * 16) (2736000 * 4) (1478400 * 32)>;
+		};
+
+		opp-2592000000 {
+			opp-hz = /bits/ 64 <2592000000>;
+			opp-peak-kBps = <(806000 * 16) (2736000 * 4) (1478400 * 32)>;
+		};
+
+		opp-2707200000 {
+			opp-hz = /bits/ 64 <2707200000>;
+			opp-peak-kBps = <(933000 * 16) (2736000 * 4) (1478400 * 32)>;
+		};
+
+		opp-2803200000 {
+			opp-hz = /bits/ 64 <2803200000>;
+			opp-peak-kBps = <(933000 * 16) (3686000 * 4) (1689600 * 32)>;
+		};
+	};
+
+	cpu7_opp_table: opp-table-cpu7 {
+		compatible = "operating-points-v2";
+		opp-shared;
+
+		opp-595200000 {
+			opp-hz = /bits/ 64 <595200000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (307200 * 32)>;
+		};
+
+		opp-729600000 {
+			opp-hz = /bits/ 64 <729600000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (499200 * 32)>;
+		};
+
+		opp-864000000 {
+			opp-hz = /bits/ 64 <864000000>;
+			opp-peak-kBps = <(300000 * 16) (547000 * 4) (499200 * 32)>;
+		};
+
+		opp-998400000 {
+			opp-hz = /bits/ 64 <998400000>;
+			opp-peak-kBps = <(300000 * 16) (768000 * 4) (729600 * 32)>;
+		};
+
+		opp-1132800000 {
+			opp-hz = /bits/ 64 <1132800000>;
+			opp-peak-kBps = <(300000 * 16) (768000 * 4) (729600 * 32)>;
+		};
+
+		opp-1248000000 {
+			opp-hz = /bits/ 64 <1248000000>;
+			opp-peak-kBps = <(466000 * 16) (1555000 * 4) (940800 * 32)>;
+		};
+
+		opp-1363200000 {
+			opp-hz = /bits/ 64 <1363200000>;
+			opp-peak-kBps = <(466000 * 16) (1555000 * 4) (940800 * 32)>;
+		};
+
+		opp-1478400000 {
+			opp-hz = /bits/ 64 <1478400000>;
+			opp-peak-kBps = <(600000 * 16) (1708000 * 4) (1056000 * 32)>;
+		};
+
+		opp-1593600000 {
+			opp-hz = /bits/ 64 <1593600000>;
+			opp-peak-kBps = <(600000 * 16) (1708000 * 4) (1056000 * 32)>;
+		};
+
+		opp-1708800000 {
+			opp-hz = /bits/ 64 <1708800000>;
+			opp-peak-kBps = <(600000 * 16) (1708000 * 4) (1267200 * 32)>;
+		};
+
+		opp-1843200000 {
+			opp-hz = /bits/ 64 <1843200000>;
+			opp-peak-kBps = <(600000 * 16) (1708000 * 4) (1267200 * 32)>;
+		};
+
+		opp-1977600000 {
+			opp-hz = /bits/ 64 <1977600000>;
+			opp-peak-kBps = <(806000 * 16) (2736000 * 4) (1267200 * 32)>;
+		};
+
+		opp-2092800000 {
+			opp-hz = /bits/ 64 <2092800000>;
+			opp-peak-kBps = <(806000 * 16) (2736000 * 4) (1478400 * 32)>;
+		};
+
+		opp-2227200000 {
+			opp-hz = /bits/ 64 <2227200000>;
+			opp-peak-kBps = <(806000 * 16) (2736000 * 4) (1478400 * 32)>;
+		};
+
+		opp-2342400000 {
+			opp-hz = /bits/ 64 <2342400000>;
+			opp-peak-kBps = <(806000 * 16) (2736000 * 4) (1478400 * 32)>;
+		};
+
+		opp-2476800000 {
+			opp-hz = /bits/ 64 <2476800000>;
+			opp-peak-kBps = <(806000 * 16) (2736000 * 4) (1478400 * 32)>;
+		};
+
+		opp-2592000000 {
+			opp-hz = /bits/ 64 <2592000000>;
+			opp-peak-kBps = <(806000 * 16) (2736000 * 4) (1478400 * 32)>;
+		};
+
+		opp-2726400000 {
+			opp-hz = /bits/ 64 <2726400000>;
+			opp-peak-kBps = <(933000 * 16) (3686000 * 4) (1478400 * 32)>;
+		};
+
+		opp-2841600000 {
+			opp-hz = /bits/ 64 <2841600000>;
+			opp-peak-kBps = <(933000 * 16) (3686000 * 4) (1689600 * 32)>;
+		};
+
+		opp-2956800000 {
+			opp-hz = /bits/ 64 <2956800000>;
+			opp-peak-kBps = <(933000 * 16) (3686000 * 4) (1689600 * 32)>;
+		};
+
+		opp-3187200000 {
+			opp-hz = /bits/ 64 <3187200000>;
+			opp-peak-kBps = <(933000 * 16) (3686000 * 4) (1689600 * 32)>;
+		};
+	};
+
 	pmu-a510 {
 		compatible = "arm,cortex-a510-pmu";
 		interrupts = <GIC_PPI 7 IRQ_TYPE_LEVEL_LOW &ppi_cluster0>;
@@ -5482,6 +5839,16 @@ rpmhpd_opp_turbo_l1: opp-416 {
 			};
 		};
 
+		epss_l3: interconnect@17d90000 {
+			compatible = "qcom,sm8550-epss-l3", "qcom,epss-l3";
+			reg = <0 0x17d90000 0 0x1000>;
+
+			clocks = <&bi_tcxo_div2>, <&gcc GCC_GPLL0>;
+			clock-names = "xo", "alternate";
+
+			#interconnect-cells = <1>;
+		};
+
 		cpufreq_hw: cpufreq@17d91000 {
 			compatible = "qcom,sm8550-cpufreq-epss", "qcom,cpufreq-epss";
 			reg = <0 0x17d91000 0 0x1000>,

---
base-commit: cf7c3c02fdd0dfccf4d6611714273dcb538af2cb
change-id: 20260207-sm8550-ddr-bw-scaling-b1524827f207

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

