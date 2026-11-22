From: Michael Reeves <michael.reeves077@gmail.com>
Date: Sun, 22 Nov 2026 00:18:26 +0000
Subject: [PATCH v2 5/5] arm64: dts: apple: t6032: Add CPU frequency scaling
 and OPPs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-m3-cpufreq-opp-v2-5-3c19963f55ee@gmail.com>
References: <20261122-m3-cpufreq-opp-v2-0-3c19963f55ee@gmail.com>
In-Reply-To: <20261122-m3-cpufreq-opp-v2-0-3c19963f55ee@gmail.com>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Hector Martin <marcan@marcan.st>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795306712; l=7260;
 i=michael.reeves077@gmail.com; s=20261107; h=from:subject:message-id;
 bh=RP3Tl98EGSTZRq8axcgQ4fI3CuPhgZyAKwc+j8gARmE=;
 b=svqXsQ9xqKQ2cDML9fwZcFlM4sEp5BZ7n1lI8uJa5YfcewBelutV99aoPDkUvqFXERil2zByZ
 pN47QATtRGlA3AdBsj4IwqFCodmEtcTHZ9Jqkbzmi8p6oZ+fMlMO1Gr
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=ykwkLcuByJYb/cdLc2UuoYP03pIzwrscEZg30+4tJL8=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261107 with auth_id=1442
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add operating performance point references, performance domain bindings,
and CPU capacity values for the second die's Sawtooth efficiency and
Everest performance clusters on Apple T6032 (M3 Ultra).

The die1 cores use the same OPP tables and capacity-dmips-mhz values as
die0 (inherited from T6031), paired with the die1 cluster cpufreq
controller nodes instantiated via t6031-dieX.dtsi.

Suggested-by: Janne Grunau <j@jannau.net>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 arch/arm64/boot/dts/apple/t6032.dtsi | 48 ++++++++++++++++++++++++++++++++++++
 1 file changed, 48 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t6032.dtsi b/arch/arm64/boot/dts/apple/t6032.dtsi
index 6115ab8db5ef..b5ddaa00a7e0 100644
--- a/arch/arm64/boot/dts/apple/t6032.dtsi
+++ b/arch/arm64/boot/dts/apple/t6032.dtsi
@@ -107,9 +107,12 @@ cpu_e10: cpu@800 {
 			cpu-release-addr = <0 0>; /* to be filled by loader */
 			enable-method = "spin-table";
 
+			capacity-dmips-mhz = <870>;
 			d-cache-size = <0x10000>;
 			i-cache-size = <0x20000>;
 			next-level-cache = <&l2_cache_3>;
+			operating-points-v2 = <&sawtooth_opp>;
+			performance-domains = <&cpufreq_e_die1>;
 		};
 
 		cpu_e11: cpu@801 {
@@ -119,9 +122,12 @@ cpu_e11: cpu@801 {
 			cpu-release-addr = <0 0>; /* to be filled by loader */
 			enable-method = "spin-table";
 
+			capacity-dmips-mhz = <870>;
 			d-cache-size = <0x10000>;
 			i-cache-size = <0x20000>;
 			next-level-cache = <&l2_cache_3>;
+			operating-points-v2 = <&sawtooth_opp>;
+			performance-domains = <&cpufreq_e_die1>;
 		};
 
 		cpu_e12: cpu@802 {
@@ -131,9 +137,12 @@ cpu_e12: cpu@802 {
 			cpu-release-addr = <0 0>; /* to be filled by loader */
 			enable-method = "spin-table";
 
+			capacity-dmips-mhz = <870>;
 			d-cache-size = <0x10000>;
 			i-cache-size = <0x20000>;
 			next-level-cache = <&l2_cache_3>;
+			operating-points-v2 = <&sawtooth_opp>;
+			performance-domains = <&cpufreq_e_die1>;
 		};
 
 		cpu_e13: cpu@803 {
@@ -143,9 +152,12 @@ cpu_e13: cpu@803 {
 			cpu-release-addr = <0 0>; /* to be filled by loader */
 			enable-method = "spin-table";
 
+			capacity-dmips-mhz = <870>;
 			d-cache-size = <0x10000>;
 			i-cache-size = <0x20000>;
 			next-level-cache = <&l2_cache_3>;
+			operating-points-v2 = <&sawtooth_opp>;
+			performance-domains = <&cpufreq_e_die1>;
 		};
 
 		cpu_p20: cpu@10900 {
@@ -155,9 +167,12 @@ cpu_p20: cpu@10900 {
 			cpu-release-addr = <0 0>; /* To be filled by loader */
 			enable-method = "spin-table";
 
+			capacity-dmips-mhz = <1024>;
 			d-cache-size = <0x20000>;
 			i-cache-size = <0x30000>;
 			next-level-cache = <&l2_cache_4>;
+			operating-points-v2 = <&everest_opp>;
+			performance-domains = <&cpufreq_p0_die1>;
 		};
 
 		cpu_p21: cpu@10901 {
@@ -167,9 +182,12 @@ cpu_p21: cpu@10901 {
 			cpu-release-addr = <0 0>; /* To be filled by loader */
 			enable-method = "spin-table";
 
+			capacity-dmips-mhz = <1024>;
 			d-cache-size = <0x20000>;
 			i-cache-size = <0x30000>;
 			next-level-cache = <&l2_cache_4>;
+			operating-points-v2 = <&everest_opp>;
+			performance-domains = <&cpufreq_p0_die1>;
 		};
 
 		cpu_p22: cpu@10902 {
@@ -179,9 +197,12 @@ cpu_p22: cpu@10902 {
 			cpu-release-addr = <0 0>; /* To be filled by loader */
 			enable-method = "spin-table";
 
+			capacity-dmips-mhz = <1024>;
 			d-cache-size = <0x20000>;
 			i-cache-size = <0x30000>;
 			next-level-cache = <&l2_cache_4>;
+			operating-points-v2 = <&everest_opp>;
+			performance-domains = <&cpufreq_p0_die1>;
 		};
 
 		cpu_p23: cpu@10903 {
@@ -191,9 +212,12 @@ cpu_p23: cpu@10903 {
 			cpu-release-addr = <0 0>; /* To be filled by loader */
 			enable-method = "spin-table";
 
+			capacity-dmips-mhz = <1024>;
 			d-cache-size = <0x20000>;
 			i-cache-size = <0x30000>;
 			next-level-cache = <&l2_cache_4>;
+			operating-points-v2 = <&everest_opp>;
+			performance-domains = <&cpufreq_p0_die1>;
 		};
 
 		cpu_p24: cpu@10904 {
@@ -203,9 +227,12 @@ cpu_p24: cpu@10904 {
 			cpu-release-addr = <0 0>; /* To be filled by loader */
 			enable-method = "spin-table";
 
+			capacity-dmips-mhz = <1024>;
 			d-cache-size = <0x20000>;
 			i-cache-size = <0x30000>;
 			next-level-cache = <&l2_cache_4>;
+			operating-points-v2 = <&everest_opp>;
+			performance-domains = <&cpufreq_p0_die1>;
 		};
 
 		cpu_p25: cpu@10905 {
@@ -215,9 +242,12 @@ cpu_p25: cpu@10905 {
 			cpu-release-addr = <0 0>; /* To be filled by loader */
 			enable-method = "spin-table";
 
+			capacity-dmips-mhz = <1024>;
 			d-cache-size = <0x20000>;
 			i-cache-size = <0x30000>;
 			next-level-cache = <&l2_cache_4>;
+			operating-points-v2 = <&everest_opp>;
+			performance-domains = <&cpufreq_p0_die1>;
 		};
 
 		cpu_p30: cpu@10a00 {
@@ -227,9 +257,12 @@ cpu_p30: cpu@10a00 {
 			cpu-release-addr = <0 0>; /* To be filled by loader */
 			enable-method = "spin-table";
 
+			capacity-dmips-mhz = <1024>;
 			d-cache-size = <0x20000>;
 			i-cache-size = <0x30000>;
 			next-level-cache = <&l2_cache_5>;
+			operating-points-v2 = <&everest_opp>;
+			performance-domains = <&cpufreq_p1_die1>;
 		};
 
 		cpu_p31: cpu@10a01 {
@@ -239,9 +272,12 @@ cpu_p31: cpu@10a01 {
 			cpu-release-addr = <0 0>; /* To be filled by loader */
 			enable-method = "spin-table";
 
+			capacity-dmips-mhz = <1024>;
 			d-cache-size = <0x20000>;
 			i-cache-size = <0x30000>;
 			next-level-cache = <&l2_cache_5>;
+			operating-points-v2 = <&everest_opp>;
+			performance-domains = <&cpufreq_p1_die1>;
 		};
 
 		cpu_p32: cpu@10a02 {
@@ -251,9 +287,12 @@ cpu_p32: cpu@10a02 {
 			cpu-release-addr = <0 0>; /* To be filled by loader */
 			enable-method = "spin-table";
 
+			capacity-dmips-mhz = <1024>;
 			d-cache-size = <0x20000>;
 			i-cache-size = <0x30000>;
 			next-level-cache = <&l2_cache_5>;
+			operating-points-v2 = <&everest_opp>;
+			performance-domains = <&cpufreq_p1_die1>;
 		};
 
 		cpu_p33: cpu@10a03 {
@@ -263,9 +302,12 @@ cpu_p33: cpu@10a03 {
 			cpu-release-addr = <0 0>; /* To be filled by loader */
 			enable-method = "spin-table";
 
+			capacity-dmips-mhz = <1024>;
 			d-cache-size = <0x20000>;
 			i-cache-size = <0x30000>;
 			next-level-cache = <&l2_cache_5>;
+			operating-points-v2 = <&everest_opp>;
+			performance-domains = <&cpufreq_p1_die1>;
 		};
 
 		cpu_p34: cpu@10a04 {
@@ -275,9 +317,12 @@ cpu_p34: cpu@10a04 {
 			cpu-release-addr = <0 0>; /* To be filled by loader */
 			enable-method = "spin-table";
 
+			capacity-dmips-mhz = <1024>;
 			d-cache-size = <0x20000>;
 			i-cache-size = <0x30000>;
 			next-level-cache = <&l2_cache_5>;
+			operating-points-v2 = <&everest_opp>;
+			performance-domains = <&cpufreq_p1_die1>;
 		};
 
 		cpu_p35: cpu@10a05 {
@@ -287,9 +332,12 @@ cpu_p35: cpu@10a05 {
 			cpu-release-addr = <0 0>; /* To be filled by loader */
 			enable-method = "spin-table";
 
+			capacity-dmips-mhz = <1024>;
 			d-cache-size = <0x20000>;
 			i-cache-size = <0x30000>;
 			next-level-cache = <&l2_cache_5>;
+			operating-points-v2 = <&everest_opp>;
+			performance-domains = <&cpufreq_p1_die1>;
 		};
 
 		l2_cache_3: l2-cache-3 {

-- 
2.56.0

