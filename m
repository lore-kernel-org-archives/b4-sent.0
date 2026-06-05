From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 05 Jun 2026 17:36:37 -0500
Subject: [PATCH] arm64: dts: qcom: sm8750: add cpu OPP table with DDR and
 LLCC bandwidths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-sm8750-ddr-bw-scaling-v1-1-f39f918c95a7@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDMwNT3eJcC3NTA92UlCLdpHLd4uTEnMy8dF3LZGOjJAtjM4PEJAsloN6
 CotS0zAqwudGxtbUAu47vY2cAAAA=
X-Change-ID: 20260605-sm8750-ddr-bw-scaling-9c32b8360ab8
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780699006; l=9235;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=kbb/4boOUdkbOmNk6sJ8HJw1jKtiEVCgZD941A51xxk=;
 b=Fo8YhRp3cJyhsK/swh443JmVamp3uQSrN2QczJXtXVicwUpeFWbeMejJg109ZAdKdruZDRczb
 OLNmKMG5QKJAVLkDtBclmAPXK7Mar0EAjYWXTUhYZ5RwVLjgQFkO7Yt
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the OPP tables for each CPU cluster (cpu0-1-2-3-4-5 & cpu6-7) to
permit scaling the Last Level Cache Controller (LLCC) and DDR frequency
by aggregating bandwidth requests of all CPU core with reference to the
current OPP they are configured in by the hardware.

The effect is proper caches & DDR frequency scaling when CPU cores
change frequency.

The OPP tables were built using the downstream memlat ddr & llcc tables
for each cluster types with the actual cpufreq LUT tables from running a
CQ8725S device.

Also add the interconnect entry for each cpu, with 2 different paths:
- CPU to Last Level Cache Controller (LLCC)
- Last Level Cache Controller (LLCC) to DDR

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
arm64: dts: qcom: sm8750: add cpu OPP table with DDR and LLCC bandwidths
---
 arch/arm64/boot/dts/qcom/sm8750.dtsi | 200 +++++++++++++++++++++++++++++++++++
 1 file changed, 200 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8750.dtsi b/arch/arm64/boot/dts/qcom/sm8750.dtsi
index fafed417c66fc2..6f44c393649918 100644
--- a/arch/arm64/boot/dts/qcom/sm8750.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8750.dtsi
@@ -44,6 +44,11 @@ cpu0: cpu@0 {
 			next-level-cache = <&l2_0>;
 			power-domains = <&cpu_pd0>, <&scmi_dvfs 0>;
 			power-domain-names = "psci", "perf";
+			operating-points-v2 = <&cpu0_opp_table>;
+			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ACTIVE_ONLY>;
 			#cooling-cells = <2>;
 
 			l2_0: l2-cache {
@@ -61,6 +66,11 @@ cpu1: cpu@100 {
 			next-level-cache = <&l2_0>;
 			power-domains = <&cpu_pd1>, <&scmi_dvfs 0>;
 			power-domain-names = "psci", "perf";
+			operating-points-v2 = <&cpu0_opp_table>;
+			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ACTIVE_ONLY>;
 			#cooling-cells = <2>;
 		};
 
@@ -72,6 +82,11 @@ cpu2: cpu@200 {
 			next-level-cache = <&l2_0>;
 			power-domains = <&cpu_pd2>, <&scmi_dvfs 0>;
 			power-domain-names = "psci", "perf";
+			operating-points-v2 = <&cpu0_opp_table>;
+			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ACTIVE_ONLY>;
 			#cooling-cells = <2>;
 		};
 
@@ -83,6 +98,11 @@ cpu3: cpu@300 {
 			next-level-cache = <&l2_0>;
 			power-domains = <&cpu_pd3>, <&scmi_dvfs 0>;
 			power-domain-names = "psci", "perf";
+			operating-points-v2 = <&cpu0_opp_table>;
+			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ACTIVE_ONLY>;
 			#cooling-cells = <2>;
 		};
 
@@ -94,6 +114,11 @@ cpu4: cpu@400 {
 			next-level-cache = <&l2_0>;
 			power-domains = <&cpu_pd4>, <&scmi_dvfs 0>;
 			power-domain-names = "psci", "perf";
+			operating-points-v2 = <&cpu0_opp_table>;
+			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ACTIVE_ONLY>;
 			#cooling-cells = <2>;
 		};
 
@@ -105,6 +130,11 @@ cpu5: cpu@500 {
 			next-level-cache = <&l2_0>;
 			power-domains = <&cpu_pd5>, <&scmi_dvfs 0>;
 			power-domain-names = "psci", "perf";
+			operating-points-v2 = <&cpu0_opp_table>;
+			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ACTIVE_ONLY>;
 			#cooling-cells = <2>;
 		};
 
@@ -116,6 +146,11 @@ cpu6: cpu@10000 {
 			next-level-cache = <&l2_1>;
 			power-domains = <&cpu_pd6>, <&scmi_dvfs 1>;
 			power-domain-names = "psci", "perf";
+			operating-points-v2 = <&cpu6_opp_table>;
+			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ACTIVE_ONLY>;
 			#cooling-cells = <2>;
 
 			l2_1: l2-cache {
@@ -133,6 +168,11 @@ cpu7: cpu@10100 {
 			next-level-cache = <&l2_1>;
 			power-domains = <&cpu_pd7>, <&scmi_dvfs 1>;
 			power-domain-names = "psci", "perf";
+			operating-points-v2 = <&cpu6_opp_table>;
+			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>,
+					<&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ACTIVE_ONLY>;
 			#cooling-cells = <2>;
 		};
 
@@ -256,6 +296,166 @@ memory@a0000000 {
 		reg = <0x0 0xa0000000 0x0 0x0>;
 	};
 
+	cpu0_opp_table: opp-table-cpu0 {
+		compatible = "operating-points-v2";
+		opp-shared;
+
+		opp-384000000 {
+			opp-hz = /bits/ 64 <384000000>;
+			opp-peak-kBps = <(547000 * 16) (350000 * 4)>;
+		};
+
+		opp-556800000 {
+			opp-hz = /bits/ 64 <556800000>;
+			opp-peak-kBps = <(547000 * 16) (350000 * 4)>;
+		};
+
+		opp-748800000 {
+			opp-hz = /bits/ 64 <748800000>;
+			opp-peak-kBps = <(547000 * 16) (350000 * 4)>;
+		};
+
+		opp-960000000 {
+			opp-hz = /bits/ 64 <960000000>;
+			opp-peak-kBps = <(1353000 * 16) (350000 * 4)>;
+		};
+
+		opp-1152000000 {
+			opp-hz = /bits/ 64 <1152000000>;
+			opp-peak-kBps = <(1353000 * 16) (350000 * 4)>;
+		};
+
+		opp-1363200000 {
+			opp-hz = /bits/ 64 <1363200000>;
+			opp-peak-kBps = <(1555000 * 16) (350000 * 4)>;
+		};
+
+		opp-1555200000 {
+			opp-hz = /bits/ 64 <1555200000>;
+			opp-peak-kBps = <(1555000 * 16) (350000 * 4)>;
+		};
+
+		opp-1785600000 {
+			opp-hz = /bits/ 64 <1785600000>;
+			opp-peak-kBps = <(2092000 * 16) (533000 * 4)>;
+		};
+
+		opp-1996800000 {
+			opp-hz = /bits/ 64 <1996800000>;
+			opp-peak-kBps = <(2092000 * 16) (533000 * 4)>;
+		};
+
+		opp-2227200000 {
+			opp-hz = /bits/ 64 <2227200000>;
+			opp-peak-kBps = <(2092000 * 16) (533000 * 4)>;
+		};
+
+		opp-2400000000 {
+			opp-hz = /bits/ 64 <2400000000>;
+			opp-peak-kBps = <(2092000 * 16) (533000 * 4)>;
+		};
+
+		opp-2745600000 {
+			opp-hz = /bits/ 64 <2745600000>;
+			opp-peak-kBps = <(3187000 * 16) (806000 * 4)>;
+		};
+
+		opp-2918400000 {
+			opp-hz = /bits/ 64 <2918400000>;
+			opp-peak-kBps = <(3187000 * 16) (806000 * 4)>;
+		};
+
+		opp-3072000000 {
+			opp-hz = /bits/ 64 <3072000000>;
+			opp-peak-kBps = <(3686000 * 16) (933000 * 4)>;
+		};
+
+		opp-3321600000 {
+			opp-hz = /bits/ 64 <3321600000>;
+			opp-peak-kBps = <(3686000 * 16) (933000 * 4)>;
+		};
+
+		opp-3532800000 {
+			opp-hz = /bits/ 64 <3532800000>;
+			opp-peak-kBps = <(3686000 * 16) (933000 * 4)>;
+		};
+	};
+
+	cpu6_opp_table: opp-table-cpu6 {
+		compatible = "operating-points-v2";
+		opp-shared;
+
+		opp-1017600000 {
+			opp-hz = /bits/ 64 <1017600000>;
+			opp-peak-kBps = <(1353000 * 16) (350000 * 4)>;
+		};
+
+		opp-1209600000 {
+			opp-hz = /bits/ 64 <1209600000>;
+			opp-peak-kBps = <(1353000 * 16) (350000 * 4)>;
+		};
+
+		opp-1401600000 {
+			opp-hz = /bits/ 64 <1401600000>;
+			opp-peak-kBps = <(1353000 * 16) (350000 * 4)>;
+		};
+
+		opp-1689600000 {
+			opp-hz = /bits/ 64 <1689600000>;
+			opp-peak-kBps = <(2092000 * 16) (533000 * 4)>;
+		};
+
+		opp-1958400000 {
+			opp-hz = /bits/ 64 <1958400000>;
+			opp-peak-kBps = <(2092000 * 16) (533000 * 4)>;
+		};
+
+		opp-2246400000 {
+			opp-hz = /bits/ 64 <2246400000>;
+			opp-peak-kBps = <(3187000 * 16) (806000 * 4)>;
+		};
+
+		opp-2438400000 {
+			opp-hz = /bits/ 64 <2438400000>;
+			opp-peak-kBps = <(3187000 * 16) (806000 * 4)>;
+		};
+
+		opp-2649600000 {
+			opp-hz = /bits/ 64 <2649600000>;
+			opp-peak-kBps = <(3187000 * 16) (806000 * 4)>;
+		};
+
+		opp-2841600000 {
+			opp-hz = /bits/ 64 <2841600000>;
+			opp-peak-kBps = <(3686000 * 16) (933000 * 4)>;
+		};
+
+		opp-3072000000 {
+			opp-hz = /bits/ 64 <3072000000>;
+			opp-peak-kBps = <(3686000 * 16) (933000 * 4)>;
+		};
+
+		opp-3283200000 {
+			opp-hz = /bits/ 64 <3283200000>;
+			opp-peak-kBps = <(3686000 * 16) (933000 * 4)>;
+		};
+
+		opp-3513600000 {
+			opp-hz = /bits/ 64 <3513600000>;
+			opp-peak-kBps = <(4224000 * 16) (1066000 * 4)>;
+		};
+
+		opp-3801600000 {
+			opp-hz = /bits/ 64 <3801600000>;
+			opp-peak-kBps = <(4224000 * 16) (1066000 * 4)>;
+		};
+
+		opp-4089600000 {
+			opp-hz = /bits/ 64 <4089600000>;
+			opp-peak-kBps = <(4224000 * 16) (1066000 * 4)>;
+		};
+	};
+
 	pmu {
 		compatible = "arm,armv8-pmuv3";
 		interrupts = <GIC_PPI 7 IRQ_TYPE_LEVEL_LOW>;

---
base-commit: 6e845bcb78c95af935094040bd4edc3c2b6dd784
change-id: 20260605-sm8750-ddr-bw-scaling-9c32b8360ab8

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

