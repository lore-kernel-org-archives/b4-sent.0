From: Demeter Barna <me@fromdisposition.org>
Date: Fri, 16 Oct 2026 06:01:15 +0000
Subject: [PATCH 1/2] arm64: dts: qcom: sm8350: Add the EPSS L3 provider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-sm8350-cpu-bw-v1-1-044ac6dc9565@fromdisposition.org>
References: <20261016-sm8350-cpu-bw-v1-0-044ac6dc9565@fromdisposition.org>
In-Reply-To: <20261016-sm8350-cpu-bw-v1-0-044ac6dc9565@fromdisposition.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792130480; l=1532;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=/8vPgqfKiT1bODMQ7BHGvpeDWEcW7hqSYkyAN5jFK/E=;
 b=AwMtaTQ/0Ajx9T0j+KWWd4rdW+6qKGq0XlAzX6tCYmM0Jl241K6p0jinn9ygJBvI1/uM7B/K8
 +6wVBeM1rihDnQQcEw/nRwcdSkr3buxcTehOkSEd5R7GUfhqWIs0sc1
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the EPSS L3 block, already documented as qcom,sm8350-epss-l3, so
that the CPUs can vote for the L3 frequency.

Unlike on SM8250, the L3 is voted through the L3_VOTE register, as the
downstream driver for this SoC does. The generic qcom,epss-l3 fallback
selects that, so no driver change is needed.

Assisted-by: LLM
Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 arch/arm64/boot/dts/qcom/sm8350.dtsi | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8350.dtsi b/arch/arm64/boot/dts/qcom/sm8350.dtsi
index 55b32050c..52e8c2963 100644
--- a/arch/arm64/boot/dts/qcom/sm8350.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8350.dtsi
@@ -15,6 +15,7 @@
 #include <dt-bindings/firmware/qcom,scm.h>
 #include <dt-bindings/gpio/gpio.h>
 #include <dt-bindings/interconnect/qcom,icc.h>
+#include <dt-bindings/interconnect/qcom,osm-l3.h>
 #include <dt-bindings/interconnect/qcom,sm8350.h>
 #include <dt-bindings/mailbox/qcom-ipcc.h>
 #include <dt-bindings/phy/phy-qcom-qmp.h>
@@ -3798,6 +3799,16 @@ apps_bcm_voter: bcm-voter {
 			};
 		};
 
+		epss_l3: interconnect@18590000 {
+			compatible = "qcom,sm8350-epss-l3", "qcom,epss-l3";
+			reg = <0 0x18590000 0 0x1000>;
+
+			clocks = <&rpmhcc RPMH_CXO_CLK>, <&gcc GCC_GPLL0>;
+			clock-names = "xo", "alternate";
+
+			#interconnect-cells = <1>;
+		};
+
 		cpufreq_hw: cpufreq@18591000 {
 			compatible = "qcom,sm8350-cpufreq-epss", "qcom,cpufreq-epss";
 			reg = <0 0x18591000 0 0x1000>,

-- 
2.53.0

