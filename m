From: Fabricio Akio <fabricioakio@gmail.com>
Date: Sun, 11 Oct 2026 23:18:08 -0300
Subject: [PATCH 2/2] arm64: dts: qcom: sdm630: Fix the CPU retention idle
 state parameter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-sdm630-idle-states-v1-2-3181d488dc0f@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791771486; l=1587;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=JPfucNV2H7AMDe9ybxbNQCBK1Hyzzm9nRs65fQ2KOPs=;
 b=oQp29R2EyUSznPiQGQnc1SYh2rurX09E6rz6/LF2N6c5QUF5eqrvTIMJEs5rI4W5EAZUvXEFG
 D3oqHL25NynAR61z3Hk/8dKEyVGFtGfa+2+Yi2vE6+i4m00sRXxQyNL
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CPU retention states set bit 30 of their PSCI power_state, which
marks a state that loses context. Retention keeps it, and the vendor
kernel requests it as 0x00000002.

With bit 30 set, no entry into these states succeeds on a Motorola Moto
X4 (SDM630). With it clear they are entered about 50 times per second
across the CPUs, and the failed idle entries across all states drop
from about 30 to about 9 per second.

Fixes: b190fb010664 ("arm64: dts: qcom: sdm630: Add sdm630 dts file")
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
 arch/arm64/boot/dts/qcom/sdm630.dtsi | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm630.dtsi b/arch/arm64/boot/dts/qcom/sdm630.dtsi
index 222ec5886818..a58bad0fb638 100644
--- a/arch/arm64/boot/dts/qcom/sdm630.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm630.dtsi
@@ -192,7 +192,7 @@ idle-states {
 			pwr_cpu_sleep_0: cpu-sleep-0-0 {
 				compatible = "arm,idle-state";
 				idle-state-name = "pwr-retention";
-				arm,psci-suspend-param = <0x40000002>;
+				arm,psci-suspend-param = <0x00000002>;
 				entry-latency-us = <338>;
 				exit-latency-us = <423>;
 				min-residency-us = <200>;
@@ -211,7 +211,7 @@ pwr_cpu_sleep_1: cpu-sleep-0-1 {
 			perf_cpu_sleep_0: cpu-sleep-1-0 {
 				compatible = "arm,idle-state";
 				idle-state-name = "perf-retention";
-				arm,psci-suspend-param = <0x40000002>;
+				arm,psci-suspend-param = <0x00000002>;
 				entry-latency-us = <154>;
 				exit-latency-us = <87>;
 				min-residency-us = <200>;

-- 
2.56.0

