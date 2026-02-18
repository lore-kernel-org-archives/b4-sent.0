From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 18 Feb 2026 12:16:20 -0600
Subject: [PATCH v2 3/3] arm64: dts: qcom: sm8550: add cpu OPP table with
 DDR, LLCC & L3 bandwidths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260218-sm8550-ddr-bw-scaling-v2-3-43a2b6d47e70@gmail.com>
References: <20260218-sm8550-ddr-bw-scaling-v2-0-43a2b6d47e70@gmail.com>
In-Reply-To: <20260218-sm8550-ddr-bw-scaling-v2-0-43a2b6d47e70@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Georgi Djakov <djakov@kernel.org>, 
 Sibi Sankar <sibi.sankar@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771438580; l=12245;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=85HscMMOyXUPnbY+5BZN+EPpT/ZXYecdKO3kDfW5w1o=;
 b=HolGef5kdVqtWB/NY4ohDeuOoHBvhbBfNINyMuLp8mAW/rF5Iq/Br8FsqeTrJtFK2kKxhmC48
 3ZIwxMNVQIyDdIDTTNQcDxg0zvk6PXSdpPnnqk4bSVj598ucme+o3Yo
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

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/qcom/sm8550.dtsi | 308 +++++++++++++++++++++++++++++++++++
 1 file changed, 308 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8550.dtsi b/arch/arm64/boot/dts/qcom/sm8550.dtsi
index e6cb8bf40f9f8ed6d02db124056c5814af32fa08..de4d43f7b8d2416997db70c98b0fc36d25f3c2a6 100644
--- a/arch/arm64/boot/dts/qcom/sm8550.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8550.dtsi
@@ -79,6 +79,7 @@ cpu0: cpu@0 {
 			qcom,freq-domain = <&cpufreq_hw 0>;
 			capacity-dmips-mhz = <1024>;
 			dynamic-power-coefficient = <100>;
+			operating-points-v2 = <&cpu0_opp_table>;
 			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
 					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
 					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
@@ -111,6 +112,7 @@ cpu1: cpu@100 {
 			qcom,freq-domain = <&cpufreq_hw 0>;
 			capacity-dmips-mhz = <1024>;
 			dynamic-power-coefficient = <100>;
+			operating-points-v2 = <&cpu0_opp_table>;
 			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
 					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
 					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
@@ -138,6 +140,7 @@ cpu2: cpu@200 {
 			qcom,freq-domain = <&cpufreq_hw 0>;
 			capacity-dmips-mhz = <1024>;
 			dynamic-power-coefficient = <100>;
+			operating-points-v2 = <&cpu0_opp_table>;
 			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
 					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
 					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
@@ -165,6 +168,7 @@ cpu3: cpu@300 {
 			qcom,freq-domain = <&cpufreq_hw 1>;
 			capacity-dmips-mhz = <1792>;
 			dynamic-power-coefficient = <270>;
+			operating-points-v2 = <&cpu3_opp_table>;
 			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
 					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
 					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
@@ -192,6 +196,7 @@ cpu4: cpu@400 {
 			qcom,freq-domain = <&cpufreq_hw 1>;
 			capacity-dmips-mhz = <1792>;
 			dynamic-power-coefficient = <270>;
+			operating-points-v2 = <&cpu3_opp_table>;
 			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
 					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
 					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
@@ -219,6 +224,7 @@ cpu5: cpu@500 {
 			qcom,freq-domain = <&cpufreq_hw 1>;
 			capacity-dmips-mhz = <1792>;
 			dynamic-power-coefficient = <270>;
+			operating-points-v2 = <&cpu3_opp_table>;
 			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
 					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
 					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
@@ -246,6 +252,7 @@ cpu6: cpu@600 {
 			qcom,freq-domain = <&cpufreq_hw 1>;
 			capacity-dmips-mhz = <1792>;
 			dynamic-power-coefficient = <270>;
+			operating-points-v2 = <&cpu3_opp_table>;
 			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
 					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
 					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
@@ -273,6 +280,7 @@ cpu7: cpu@700 {
 			qcom,freq-domain = <&cpufreq_hw 2>;
 			capacity-dmips-mhz = <1894>;
 			dynamic-power-coefficient = <588>;
+			operating-points-v2 = <&cpu7_opp_table>;
 			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
 					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
 					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
@@ -446,6 +454,306 @@ memory@a0000000 {
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

-- 
2.52.0

