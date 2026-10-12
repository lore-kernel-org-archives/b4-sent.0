From: fromdisposition <me@fromdisposition.org>
Date: Mon, 12 Oct 2026 02:02:44 +0000
Subject: [PATCH 2/2] arm64: dts: qcom: sm8350: Add CPU dynamic power
 coefficients
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-sm8350-cpu-capacity-v1-2-3d141e0099d5@fromdisposition.org>
References: <20261012-sm8350-cpu-capacity-v1-0-3d141e0099d5@fromdisposition.org>
In-Reply-To: <20261012-sm8350-cpu-capacity-v1-0-3d141e0099d5@fromdisposition.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, fromdisposition <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791770585; l=2954;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=9YQsAJJ10PCMm3NOvwDq8LDOChng3jMGGzkFZbGKX94=;
 b=jTMFiRafgePd8fwXWjQRx2dh96IVRXVW8Aj+VEPFWMg5pvMxvhPIvBwCfKSD9tSqLn9dxO0GB
 rlzyNnSEA0BAzE3x1ioWADeTW1eoN3zGxKmHdO2g3hRNjZ14MNmIqAo
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Without dynamic-power-coefficient no energy model is registered for
these CPUs, so energy aware scheduling stays off.

Take the values from Qualcomm's downstream overlay for v2 silicon
(lahaina-v2.dtsi in msm-5.4): 100, 499 and 760 for the A55, A78 and X1.
For the A78 and the X1 it replaces the 515 and 845 of lahaina.dtsi.

Assisted-by: LLM
Signed-off-by: fromdisposition <me@fromdisposition.org>
---
 arch/arm64/boot/dts/qcom/sm8350.dtsi | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8350.dtsi b/arch/arm64/boot/dts/qcom/sm8350.dtsi
index df6e9d1fa..dcd1fc9c1 100644
--- a/arch/arm64/boot/dts/qcom/sm8350.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8350.dtsi
@@ -61,6 +61,7 @@ cpu0: cpu@0 {
 			clocks = <&cpufreq_hw 0>;
 			enable-method = "psci";
 			capacity-dmips-mhz = <512>;
+			dynamic-power-coefficient = <100>;
 			next-level-cache = <&l2_0>;
 			qcom,freq-domain = <&cpufreq_hw 0>;
 			power-domains = <&cpu_pd0>;
@@ -86,6 +87,7 @@ cpu1: cpu@100 {
 			clocks = <&cpufreq_hw 0>;
 			enable-method = "psci";
 			capacity-dmips-mhz = <512>;
+			dynamic-power-coefficient = <100>;
 			next-level-cache = <&l2_100>;
 			qcom,freq-domain = <&cpufreq_hw 0>;
 			power-domains = <&cpu_pd1>;
@@ -106,6 +108,7 @@ cpu2: cpu@200 {
 			clocks = <&cpufreq_hw 0>;
 			enable-method = "psci";
 			capacity-dmips-mhz = <512>;
+			dynamic-power-coefficient = <100>;
 			next-level-cache = <&l2_200>;
 			qcom,freq-domain = <&cpufreq_hw 0>;
 			power-domains = <&cpu_pd2>;
@@ -126,6 +129,7 @@ cpu3: cpu@300 {
 			clocks = <&cpufreq_hw 0>;
 			enable-method = "psci";
 			capacity-dmips-mhz = <512>;
+			dynamic-power-coefficient = <100>;
 			next-level-cache = <&l2_300>;
 			qcom,freq-domain = <&cpufreq_hw 0>;
 			power-domains = <&cpu_pd3>;
@@ -146,6 +150,7 @@ cpu4: cpu@400 {
 			clocks = <&cpufreq_hw 1>;
 			enable-method = "psci";
 			capacity-dmips-mhz = <973>;
+			dynamic-power-coefficient = <499>;
 			next-level-cache = <&l2_400>;
 			qcom,freq-domain = <&cpufreq_hw 1>;
 			power-domains = <&cpu_pd4>;
@@ -166,6 +171,7 @@ cpu5: cpu@500 {
 			clocks = <&cpufreq_hw 1>;
 			enable-method = "psci";
 			capacity-dmips-mhz = <973>;
+			dynamic-power-coefficient = <499>;
 			next-level-cache = <&l2_500>;
 			qcom,freq-domain = <&cpufreq_hw 1>;
 			power-domains = <&cpu_pd5>;
@@ -186,6 +192,7 @@ cpu6: cpu@600 {
 			clocks = <&cpufreq_hw 1>;
 			enable-method = "psci";
 			capacity-dmips-mhz = <973>;
+			dynamic-power-coefficient = <499>;
 			next-level-cache = <&l2_600>;
 			qcom,freq-domain = <&cpufreq_hw 1>;
 			power-domains = <&cpu_pd6>;
@@ -206,6 +213,7 @@ cpu7: cpu@700 {
 			clocks = <&cpufreq_hw 2>;
 			enable-method = "psci";
 			capacity-dmips-mhz = <1024>;
+			dynamic-power-coefficient = <760>;
 			next-level-cache = <&l2_700>;
 			qcom,freq-domain = <&cpufreq_hw 2>;
 			power-domains = <&cpu_pd7>;

-- 
2.53.0

