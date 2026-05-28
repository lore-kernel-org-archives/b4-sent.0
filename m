From: Rudraksha Gupta <guptarud@gmail.com>
Date: Wed, 27 May 2026 20:39:30 -0700
Subject: [PATCH v2 3/3] ARM: dts: qcom: msm8960: Add CPU frequency scaling
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-expressatt_cpufreq-v2-3-b9b7726ccb6d@gmail.com>
References: <20260527-expressatt_cpufreq-v2-0-b9b7726ccb6d@gmail.com>
In-Reply-To: <20260527-expressatt_cpufreq-v2-0-b9b7726ccb6d@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andy Gross <agross@kernel.org>, 
 Ilia Lin <ilia.lin@kernel.org>, Viresh Kumar <vireshk@kernel.org>, 
 Nishanth Menon <nm@ti.com>, Stephen Boyd <sboyd@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779939570; l=5719;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=WlqrFZxEtlslS92JpD8deBZvwae3glnW+krKqNCk7sI=;
 b=wIHakbLcgl2Yb+LsQMAyCOtD+o3Er80lkUYw6OeRoWlKaEQjEV9tuRe8Ls9cBuNICtzRzPLFX
 sM2CzwKqIXgDfCa5j4LQH5TR21RmpbynpFq+e/6ShOOX2uRlzCEfYPi
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable Krait DVFS on MSM8960 by adding the required device tree nodes:

- OPP table with 12 operating points from 384 MHz to 1.512 GHz, with
  per-PVS voltages for slow, nominal, and fast silicon bins.
- Krait clock controller (krait-cc-v1) driving the CPU muxes from
  PLL9/PLL10, ACC aux outputs, and PXO.
- PVS efuse nvmem cell in qfprom for the cpufreq-nvmem driver to
  read the speed-bin and process voltage class.
- CPU idle state for Standalone Power Collapse (SPC).
- operating-points-v2, clocks, cpu-supply, and cpu-idle-states wired
  into both CPU nodes.

Link: https://github.com/CyanogenMod/android_kernel_samsung_d2/blob/0dbe2b56847b304d30b809dfd08ba3b4a61d9af8/arch/arm/mach-msm/acpuclock-8960.c#L120-L235
Assisted-by: Claude:claude-opus-4.6
Tested-by: Antony Kurniawan Soemardi <linux@smankusors.com>
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 arch/arm/boot/dts/qcom/qcom-msm8960.dtsi | 129 +++++++++++++++++++++++++++++++
 1 file changed, 129 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
index a427f0f41cd1..3bb78a704850 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
@@ -54,6 +54,10 @@ cpu@0 {
 			reg = <0>;
 			enable-method = "qcom,kpss-acc-v1";
 			device_type = "cpu";
+			operating-points-v2 = <&cpu_opp_table>;
+			clocks = <&kraitcc 0>;
+			cpu-supply = <&saw0_vreg>;
+			cpu-idle-states = <&cpu_spc>;
 			next-level-cache = <&l2>;
 			qcom,acc = <&acc0>;
 			qcom,saw = <&saw0>;
@@ -64,6 +68,10 @@ cpu@1 {
 			reg = <1>;
 			enable-method = "qcom,kpss-acc-v1";
 			device_type = "cpu";
+			operating-points-v2 = <&cpu_opp_table>;
+			clocks = <&kraitcc 1>;
+			cpu-supply = <&saw1_vreg>;
+			cpu-idle-states = <&cpu_spc>;
 			next-level-cache = <&l2>;
 			qcom,acc = <&acc1>;
 			qcom,saw = <&saw1>;
@@ -74,6 +82,123 @@ l2: l2-cache {
 			cache-level = <2>;
 			cache-unified;
 		};
+
+		idle-states {
+			cpu_spc: cpu-spc {
+				compatible = "qcom,idle-state-spc", "arm,idle-state";
+				entry-latency-us = <400>;
+				exit-latency-us = <900>;
+				min-residency-us = <3000>;
+			};
+		};
+	};
+
+	cpu_opp_table: opp-table-cpu {
+		compatible = "operating-points-v2-krait-cpu";
+		nvmem-cells = <&pvs_efuse>;
+
+		opp-384000000 {
+			opp-hz = /bits/ 64 <384000000>;
+			opp-microvolt-speed0-pvs0-v0 = <950000>;
+			opp-microvolt-speed0-pvs1-v0 = <900000>;
+			opp-microvolt-speed0-pvs3-v0 = <850000>;
+			opp-supported-hw = <0x1>;
+		};
+
+		opp-486000000 {
+			opp-hz = /bits/ 64 <486000000>;
+			opp-microvolt-speed0-pvs0-v0 = <975000>;
+			opp-microvolt-speed0-pvs1-v0 = <925000>;
+			opp-microvolt-speed0-pvs3-v0 = <875000>;
+			opp-supported-hw = <0x1>;
+		};
+
+		opp-594000000 {
+			opp-hz = /bits/ 64 <594000000>;
+			opp-microvolt-speed0-pvs0-v0 = <1000000>;
+			opp-microvolt-speed0-pvs1-v0 = <950000>;
+			opp-microvolt-speed0-pvs3-v0 = <900000>;
+			opp-supported-hw = <0x1>;
+		};
+
+		opp-702000000 {
+			opp-hz = /bits/ 64 <702000000>;
+			opp-microvolt-speed0-pvs0-v0 = <1025000>;
+			opp-microvolt-speed0-pvs1-v0 = <975000>;
+			opp-microvolt-speed0-pvs3-v0 = <925000>;
+			opp-supported-hw = <0x1>;
+		};
+
+		opp-810000000 {
+			opp-hz = /bits/ 64 <810000000>;
+			opp-microvolt-speed0-pvs0-v0 = <1075000>;
+			opp-microvolt-speed0-pvs1-v0 = <1025000>;
+			opp-microvolt-speed0-pvs3-v0 = <975000>;
+			opp-supported-hw = <0x1>;
+		};
+
+		opp-918000000 {
+			opp-hz = /bits/ 64 <918000000>;
+			opp-microvolt-speed0-pvs0-v0 = <1100000>;
+			opp-microvolt-speed0-pvs1-v0 = <1050000>;
+			opp-microvolt-speed0-pvs3-v0 = <1000000>;
+			opp-supported-hw = <0x1>;
+		};
+
+		opp-1026000000 {
+			opp-hz = /bits/ 64 <1026000000>;
+			opp-microvolt-speed0-pvs0-v0 = <1125000>;
+			opp-microvolt-speed0-pvs1-v0 = <1075000>;
+			opp-microvolt-speed0-pvs3-v0 = <1025000>;
+			opp-supported-hw = <0x1>;
+		};
+
+		opp-1134000000 {
+			opp-hz = /bits/ 64 <1134000000>;
+			opp-microvolt-speed0-pvs0-v0 = <1175000>;
+			opp-microvolt-speed0-pvs1-v0 = <1125000>;
+			opp-microvolt-speed0-pvs3-v0 = <1075000>;
+			opp-supported-hw = <0x1>;
+		};
+
+		opp-1242000000 {
+			opp-hz = /bits/ 64 <1242000000>;
+			opp-microvolt-speed0-pvs0-v0 = <1200000>;
+			opp-microvolt-speed0-pvs1-v0 = <1150000>;
+			opp-microvolt-speed0-pvs3-v0 = <1100000>;
+			opp-supported-hw = <0x1>;
+		};
+
+		opp-1350000000 {
+			opp-hz = /bits/ 64 <1350000000>;
+			opp-microvolt-speed0-pvs0-v0 = <1225000>;
+			opp-microvolt-speed0-pvs1-v0 = <1175000>;
+			opp-microvolt-speed0-pvs3-v0 = <1125000>;
+			opp-supported-hw = <0x1>;
+		};
+
+		opp-1458000000 {
+			opp-hz = /bits/ 64 <1458000000>;
+			opp-microvolt-speed0-pvs0-v0 = <1237500>;
+			opp-microvolt-speed0-pvs1-v0 = <1187500>;
+			opp-microvolt-speed0-pvs3-v0 = <1137500>;
+			opp-supported-hw = <0x1>;
+		};
+
+		opp-1512000000 {
+			opp-hz = /bits/ 64 <1512000000>;
+			opp-microvolt-speed0-pvs0-v0 = <1250000>;
+			opp-microvolt-speed0-pvs1-v0 = <1200000>;
+			opp-microvolt-speed0-pvs3-v0 = <1150000>;
+			opp-supported-hw = <0x1>;
+		};
+	};
+
+	kraitcc: clock-controller {
+		compatible = "qcom,krait-cc-v1";
+		clocks = <&gcc PLL9>, <&gcc PLL10>, <&acc0>, <&acc1>, <&pxo_board>;
+		clock-names = "hfpll0", "hfpll1", "acpu0_aux", "acpu1_aux", "qsb";
+		#clock-cells = <1>;
 	};
 
 	memory@80000000 {
@@ -112,6 +237,10 @@ qfprom: efuse@700000 {
 			#address-cells = <1>;
 			#size-cells = <1>;
 
+			pvs_efuse: pvs@c0 {
+				reg = <0xc0 0x04>;
+			};
+
 			tsens_calib: calib@404 {
 				reg = <0x404 0x10>;
 			};

-- 
2.54.0

