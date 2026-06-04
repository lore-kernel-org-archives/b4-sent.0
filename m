From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Thu, 04 Jun 2026 19:40:14 +0200
Subject: [PATCH RFC] arm64: dts: qcom: hamoa: Drop cluster_cl5 idle state
 from CPU clusters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260604-dc_zva_mitigation-v1-1-d1148c1c0259@oldschoolsolutions.biz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDMwMT3ZTk+KqyxPjczJLM9MQSoGpdIxPT1OQU0xRzS/M0JaC+gqLUtMw
 KsJnRSkFuzkqxtbUAfq78lGgAAAA=
X-Change-ID: 20260604-dc_zva_mitigation-245ecd5d797f
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Steev Klimaszewski <threeway@gmail.com>, 
 Icecream95 <ixn@disroot.org>, Marc Zyngier <maz@kernel.org>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780594933; l=3529;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=/rH8YcV139zvO6dOehQpAdl9iLkHcjBRC9U6y6wbGdg=;
 b=9nM7259tcv1rWqzpQGOxVIgH+Ja+KagwMrfG70GmEKBMtFuhyS9sZa2hxWLqYVfAl1CTu8T2h
 +GRKvt1wTwQA6FPWM8I3yihdh7YQ2ct+nGbWLHdWZuPR0gQUtMrsAr8
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The cluster_cl5 idle state triggers DC ZVA misbehavior that resets
X1 SoCs. Remove it from cluster_pd0/1/2 domain-idle-states for now.

Suggested-by: Marc Zyngier <maz@kernel.org>
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
This is an RFC for a mitigation of a stability issue observed on
Snapdragon X1-based SoCs (Hamoa and Purwa).

Affected systems experience spontaneous resets under the following
conditions:
 - During intensive `git fetch` / `git pull` activity
 - During mostly idle periods (Bitburner and similar workloads were
   frequently mentioned)

Steev Klimaszewski first connected the crashes to git operations.
Subsequent discussion in #aarch64-laptops led icecream95 to isolate
DC ZVA as the triggering instruction and to create a reliable
reproducer [1].

Further debugging showed that the issue is strongly related to deep
cluster idle states. Marc Zyngier suggested removing the deepest
cluster state (`cluster_cl5`), which resolved the problem on all tested
consumer hardware.

This patch implements that change by removing `&cluster_cl5` from the
`domain-idle-states` of `cluster_pd0`, `cluster_pd1`, and `cluster_pd2`.

Testing:
 - Lenovo ThinkPad T14s G6 (X1E-78-100, Hamoa)
 - Lenovo ThinkBook 16 G7 QOY (X1P-42-100, Purwa)
 - Lenovo IdeaPad 5 2-in-1 14Q8X9 (X1P-42-100, Purwa)
 - Lenovo IdeaPad Slim 3x 15Q8X10 (X1-26-100, Purwa)

All consumer devices became stable with this change.

On the Snapdragon Dev Kit (X1E-001-DE, Hamoa) the situation is
different: the firmware does not advertise OSI mode. Even with this
patch the device still crashes with the x1e-crash reproducer. Stability
is only achieved by passing `cpuidle.off=1`, which of course increases
power consumption but makes the devkit a bit faster, so there's that.

The different behaviour correlates with PSCI mode:
- Consumer firmwares enable OSI mode
- Devkit firmware stays in platform-coordinated mode

This patch is therefore only a band-aid. All evidence points to a
firmware/microcode issue where DC ZVA can hit caches that have been
powered down by PSCI idle states. A proper fix would be either a
Qualcomm firmware update or a kernel erratum that disables DZE on
these SoCs.

[1] https://github.com/icecream95/x1e-crash
---
 arch/arm64/boot/dts/qcom/hamoa.dtsi | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/hamoa.dtsi b/arch/arm64/boot/dts/qcom/hamoa.dtsi
index 4ba751a65142b..8ec39ba621946 100644
--- a/arch/arm64/boot/dts/qcom/hamoa.dtsi
+++ b/arch/arm64/boot/dts/qcom/hamoa.dtsi
@@ -442,19 +442,19 @@ cpu_pd11: power-domain-cpu11 {
 
 		cluster_pd0: power-domain-cpu-cluster0 {
 			#power-domain-cells = <0>;
-			domain-idle-states = <&cluster_cl4>, <&cluster_cl5>;
+			domain-idle-states = <&cluster_cl4>;
 			power-domains = <&system_pd>;
 		};
 
 		cluster_pd1: power-domain-cpu-cluster1 {
 			#power-domain-cells = <0>;
-			domain-idle-states = <&cluster_cl4>, <&cluster_cl5>;
+			domain-idle-states = <&cluster_cl4>;
 			power-domains = <&system_pd>;
 		};
 
 		cluster_pd2: power-domain-cpu-cluster2 {
 			#power-domain-cells = <0>;
-			domain-idle-states = <&cluster_cl4>, <&cluster_cl5>;
+			domain-idle-states = <&cluster_cl4>;
 			power-domains = <&system_pd>;
 		};
 

---
base-commit: a225caacc36546a09586e3ece36c0313146e7da9
change-id: 20260604-dc_zva_mitigation-245ecd5d797f

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

