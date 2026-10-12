From: Fabricio Akio <fabricioakio@gmail.com>
Date: Sun, 11 Oct 2026 23:18:07 -0300
Subject: [PATCH 1/2] arm64: dts: qcom: sdm630: Drop the cluster idle states
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-sdm630-idle-states-v1-1-3181d488dc0f@gmail.com>
References: <20261011-sdm630-idle-states-v1-0-3181d488dc0f@gmail.com>
In-Reply-To: <20261011-sdm630-idle-states-v1-0-3181d488dc0f@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Abel Vesa <abelvesa@kernel.org>, 
 Alexey Minnekhanov <alexeymin@postmarketos.org>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Martin Botka <martin.botka@somainline.org>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791771486; l=6930;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=23wncA73vW8glTOQmjH0aK0yqRBNCdDuOK1PAtCF2Rk=;
 b=8ezxlID7sWRSwVFzsKCD/cZgl+WwuBlr58tiE5bbRuBoKrIUqqoidIeoHbAyBYFBCXt2b7ToW
 MY0thRkuZWnCxEkTnQy3HU9PepsYQq21i+N+tehu8bUjBkLHvGDyR0Z
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The cluster idle states use PSCI parameters 0x400000f2-0x400000f4. The
vendor kernel encodes a cluster state differently: it puts the cluster
mode in StateID bits 7:4 and sets an affinity-level field, bits 25:24,
to 1, so cluster power collapse is 0x41000043, and only the last
running CPU of a cluster requests one. A flat cpu-idle-states list
cannot express that condition.

cpuidle records no successful entry into any of these states, and every
request for one fails. Because they are the deepest, an idle CPU keeps
choosing one, each attempt returns at once, and the CPU spends its idle
time retrying instead of sleeping. On a Motorola Moto X4 (SDM630) with
the screen off, the CPUs made about 133,000 failed idle entries per
second and spent about 10% of the time in an idle state, and the
battery supplied 277 mA. Without these states they spend nearly all of
it in one, and the battery supplies 115 mA.

Fixes: b190fb010664 ("arm64: dts: qcom: sdm630: Add sdm630 dts file")
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
 arch/arm64/boot/dts/qcom/sdm630.dtsi | 108 +++--------------------------------
 1 file changed, 8 insertions(+), 100 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm630.dtsi b/arch/arm64/boot/dts/qcom/sdm630.dtsi
index 3a1014804fb0..222ec5886818 100644
--- a/arch/arm64/boot/dts/qcom/sdm630.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm630.dtsi
@@ -55,11 +55,7 @@ cpu0: cpu@100 {
 			compatible = "arm,cortex-a53";
 			reg = <0x0 0x100>;
 			enable-method = "psci";
-			cpu-idle-states = <&perf_cpu_sleep_0
-						&perf_cpu_sleep_1
-						&perf_cluster_sleep_0
-						&perf_cluster_sleep_1
-						&perf_cluster_sleep_2>;
+			cpu-idle-states = <&perf_cpu_sleep_0 &perf_cpu_sleep_1>;
 			capacity-dmips-mhz = <1126>;
 			#cooling-cells = <2>;
 			next-level-cache = <&l2_1>;
@@ -75,11 +71,7 @@ cpu1: cpu@101 {
 			compatible = "arm,cortex-a53";
 			reg = <0x0 0x101>;
 			enable-method = "psci";
-			cpu-idle-states = <&perf_cpu_sleep_0
-						&perf_cpu_sleep_1
-						&perf_cluster_sleep_0
-						&perf_cluster_sleep_1
-						&perf_cluster_sleep_2>;
+			cpu-idle-states = <&perf_cpu_sleep_0 &perf_cpu_sleep_1>;
 			capacity-dmips-mhz = <1126>;
 			#cooling-cells = <2>;
 			next-level-cache = <&l2_1>;
@@ -90,11 +82,7 @@ cpu2: cpu@102 {
 			compatible = "arm,cortex-a53";
 			reg = <0x0 0x102>;
 			enable-method = "psci";
-			cpu-idle-states = <&perf_cpu_sleep_0
-						&perf_cpu_sleep_1
-						&perf_cluster_sleep_0
-						&perf_cluster_sleep_1
-						&perf_cluster_sleep_2>;
+			cpu-idle-states = <&perf_cpu_sleep_0 &perf_cpu_sleep_1>;
 			capacity-dmips-mhz = <1126>;
 			#cooling-cells = <2>;
 			next-level-cache = <&l2_1>;
@@ -105,11 +93,7 @@ cpu3: cpu@103 {
 			compatible = "arm,cortex-a53";
 			reg = <0x0 0x103>;
 			enable-method = "psci";
-			cpu-idle-states = <&perf_cpu_sleep_0
-						&perf_cpu_sleep_1
-						&perf_cluster_sleep_0
-						&perf_cluster_sleep_1
-						&perf_cluster_sleep_2>;
+			cpu-idle-states = <&perf_cpu_sleep_0 &perf_cpu_sleep_1>;
 			capacity-dmips-mhz = <1126>;
 			#cooling-cells = <2>;
 			next-level-cache = <&l2_1>;
@@ -120,11 +104,7 @@ cpu4: cpu@0 {
 			compatible = "arm,cortex-a53";
 			reg = <0x0 0x0>;
 			enable-method = "psci";
-			cpu-idle-states = <&pwr_cpu_sleep_0
-						&pwr_cpu_sleep_1
-						&pwr_cluster_sleep_0
-						&pwr_cluster_sleep_1
-						&pwr_cluster_sleep_2>;
+			cpu-idle-states = <&pwr_cpu_sleep_0 &pwr_cpu_sleep_1>;
 			capacity-dmips-mhz = <1024>;
 			#cooling-cells = <2>;
 			next-level-cache = <&l2_0>;
@@ -140,11 +120,7 @@ cpu5: cpu@1 {
 			compatible = "arm,cortex-a53";
 			reg = <0x0 0x1>;
 			enable-method = "psci";
-			cpu-idle-states = <&pwr_cpu_sleep_0
-						&pwr_cpu_sleep_1
-						&pwr_cluster_sleep_0
-						&pwr_cluster_sleep_1
-						&pwr_cluster_sleep_2>;
+			cpu-idle-states = <&pwr_cpu_sleep_0 &pwr_cpu_sleep_1>;
 			capacity-dmips-mhz = <1024>;
 			#cooling-cells = <2>;
 			next-level-cache = <&l2_0>;
@@ -155,11 +131,7 @@ cpu6: cpu@2 {
 			compatible = "arm,cortex-a53";
 			reg = <0x0 0x2>;
 			enable-method = "psci";
-			cpu-idle-states = <&pwr_cpu_sleep_0
-						&pwr_cpu_sleep_1
-						&pwr_cluster_sleep_0
-						&pwr_cluster_sleep_1
-						&pwr_cluster_sleep_2>;
+			cpu-idle-states = <&pwr_cpu_sleep_0 &pwr_cpu_sleep_1>;
 			capacity-dmips-mhz = <1024>;
 			#cooling-cells = <2>;
 			next-level-cache = <&l2_0>;
@@ -170,11 +142,7 @@ cpu7: cpu@3 {
 			compatible = "arm,cortex-a53";
 			reg = <0x0 0x3>;
 			enable-method = "psci";
-			cpu-idle-states = <&pwr_cpu_sleep_0
-						&pwr_cpu_sleep_1
-						&pwr_cluster_sleep_0
-						&pwr_cluster_sleep_1
-						&pwr_cluster_sleep_2>;
+			cpu-idle-states = <&pwr_cpu_sleep_0 &pwr_cpu_sleep_1>;
 			capacity-dmips-mhz = <1024>;
 			#cooling-cells = <2>;
 			next-level-cache = <&l2_0>;
@@ -258,66 +226,6 @@ perf_cpu_sleep_1: cpu-sleep-1-1 {
 				min-residency-us = <1000>;
 				local-timer-stop;
 			};
-
-			pwr_cluster_sleep_0: cluster-sleep-0-0 {
-				compatible = "arm,idle-state";
-				idle-state-name = "pwr-cluster-dynamic-retention";
-				arm,psci-suspend-param = <0x400000f2>;
-				entry-latency-us = <284>;
-				exit-latency-us = <384>;
-				min-residency-us = <9987>;
-				local-timer-stop;
-			};
-
-			pwr_cluster_sleep_1: cluster-sleep-0-1 {
-				compatible = "arm,idle-state";
-				idle-state-name = "pwr-cluster-retention";
-				arm,psci-suspend-param = <0x400000f3>;
-				entry-latency-us = <338>;
-				exit-latency-us = <423>;
-				min-residency-us = <9987>;
-				local-timer-stop;
-			};
-
-			pwr_cluster_sleep_2: cluster-sleep-0-2 {
-				compatible = "arm,idle-state";
-				idle-state-name = "pwr-cluster-retention";
-				arm,psci-suspend-param = <0x400000f4>;
-				entry-latency-us = <515>;
-				exit-latency-us = <1821>;
-				min-residency-us = <9987>;
-				local-timer-stop;
-			};
-
-			perf_cluster_sleep_0: cluster-sleep-1-0 {
-				compatible = "arm,idle-state";
-				idle-state-name = "perf-cluster-dynamic-retention";
-				arm,psci-suspend-param = <0x400000f2>;
-				entry-latency-us = <272>;
-				exit-latency-us = <329>;
-				min-residency-us = <9987>;
-				local-timer-stop;
-			};
-
-			perf_cluster_sleep_1: cluster-sleep-1-1 {
-				compatible = "arm,idle-state";
-				idle-state-name = "perf-cluster-retention";
-				arm,psci-suspend-param = <0x400000f3>;
-				entry-latency-us = <332>;
-				exit-latency-us = <368>;
-				min-residency-us = <9987>;
-				local-timer-stop;
-			};
-
-			perf_cluster_sleep_2: cluster-sleep-1-2 {
-				compatible = "arm,idle-state";
-				idle-state-name = "perf-cluster-retention";
-				arm,psci-suspend-param = <0x400000f4>;
-				entry-latency-us = <545>;
-				exit-latency-us = <1609>;
-				min-residency-us = <9987>;
-				local-timer-stop;
-			};
 		};
 	};
 

-- 
2.56.0

