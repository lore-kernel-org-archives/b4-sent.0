From: Demeter Barna <me@fromdisposition.org>
Date: Mon, 12 Oct 2026 03:56:04 +0000
Subject: [PATCH v2 1/2] arm64: dts: qcom: sm8350: Add CPU capacities
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-sm8350-cpu-capacity-v2-1-67ce449becf0@fromdisposition.org>
References: <20261012-sm8350-cpu-capacity-v2-0-67ce449becf0@fromdisposition.org>
In-Reply-To: <20261012-sm8350-cpu-capacity-v2-0-67ce449becf0@fromdisposition.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791777425; l=2955;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=u8+scJQOHR1b0/s/1esht/dAa+mGypkRg3dAhGlCBTk=;
 b=cnBsmhtlENeGvcgtC478IxDywDmjTpIP+1CEuUUr931oMMZTUWZa7Bx/Reoy3LWaj8RlqqNRP
 RqvWz0uzBkHB5JloRq1RVPIdf4/NH4u6lHHusyAZZU2/GIn+XesG71C
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Without capacity-dmips-mhz every CPU reports a capacity of 1024, so the
scheduler treats the Cortex-A55, Cortex-A78 and Cortex-X1 cores as
equal and sets up no asymmetric CPU capacity.

Take the values from Qualcomm's downstream device tree for SM8350
(lahaina.dtsi in msm-5.4): 1024, 1946 and 2048, halved so that the X1 is
1024. Only their ratios matter, as the kernel normalizes them. The
downstream overlay for v2 silicon (lahaina-v2.dtsi) keeps them.

Assisted-by: LLM
Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 arch/arm64/boot/dts/qcom/sm8350.dtsi | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8350.dtsi b/arch/arm64/boot/dts/qcom/sm8350.dtsi
index 55b32050c..df6e9d1fa 100644
--- a/arch/arm64/boot/dts/qcom/sm8350.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8350.dtsi
@@ -60,6 +60,7 @@ cpu0: cpu@0 {
 			reg = <0x0 0x0>;
 			clocks = <&cpufreq_hw 0>;
 			enable-method = "psci";
+			capacity-dmips-mhz = <512>;
 			next-level-cache = <&l2_0>;
 			qcom,freq-domain = <&cpufreq_hw 0>;
 			power-domains = <&cpu_pd0>;
@@ -84,6 +85,7 @@ cpu1: cpu@100 {
 			reg = <0x0 0x100>;
 			clocks = <&cpufreq_hw 0>;
 			enable-method = "psci";
+			capacity-dmips-mhz = <512>;
 			next-level-cache = <&l2_100>;
 			qcom,freq-domain = <&cpufreq_hw 0>;
 			power-domains = <&cpu_pd1>;
@@ -103,6 +105,7 @@ cpu2: cpu@200 {
 			reg = <0x0 0x200>;
 			clocks = <&cpufreq_hw 0>;
 			enable-method = "psci";
+			capacity-dmips-mhz = <512>;
 			next-level-cache = <&l2_200>;
 			qcom,freq-domain = <&cpufreq_hw 0>;
 			power-domains = <&cpu_pd2>;
@@ -122,6 +125,7 @@ cpu3: cpu@300 {
 			reg = <0x0 0x300>;
 			clocks = <&cpufreq_hw 0>;
 			enable-method = "psci";
+			capacity-dmips-mhz = <512>;
 			next-level-cache = <&l2_300>;
 			qcom,freq-domain = <&cpufreq_hw 0>;
 			power-domains = <&cpu_pd3>;
@@ -141,6 +145,7 @@ cpu4: cpu@400 {
 			reg = <0x0 0x400>;
 			clocks = <&cpufreq_hw 1>;
 			enable-method = "psci";
+			capacity-dmips-mhz = <973>;
 			next-level-cache = <&l2_400>;
 			qcom,freq-domain = <&cpufreq_hw 1>;
 			power-domains = <&cpu_pd4>;
@@ -160,6 +165,7 @@ cpu5: cpu@500 {
 			reg = <0x0 0x500>;
 			clocks = <&cpufreq_hw 1>;
 			enable-method = "psci";
+			capacity-dmips-mhz = <973>;
 			next-level-cache = <&l2_500>;
 			qcom,freq-domain = <&cpufreq_hw 1>;
 			power-domains = <&cpu_pd5>;
@@ -179,6 +185,7 @@ cpu6: cpu@600 {
 			reg = <0x0 0x600>;
 			clocks = <&cpufreq_hw 1>;
 			enable-method = "psci";
+			capacity-dmips-mhz = <973>;
 			next-level-cache = <&l2_600>;
 			qcom,freq-domain = <&cpufreq_hw 1>;
 			power-domains = <&cpu_pd6>;
@@ -198,6 +205,7 @@ cpu7: cpu@700 {
 			reg = <0x0 0x700>;
 			clocks = <&cpufreq_hw 2>;
 			enable-method = "psci";
+			capacity-dmips-mhz = <1024>;
 			next-level-cache = <&l2_700>;
 			qcom,freq-domain = <&cpufreq_hw 2>;
 			power-domains = <&cpu_pd7>;

-- 
2.53.0

