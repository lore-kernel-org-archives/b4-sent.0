From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sat, 05 Sep 2026 11:29:01 +0200
Subject: [PATCH 6/7] arm64: dts: qcom: ideacentre-mini: Wire up DP sound
 names and VA macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260905-x1-ideacentre-mini-prettify-v1-6-9a87882973bb@oldschoolsolutions.biz>
References: <20260905-x1-ideacentre-mini-prettify-v1-0-9a87882973bb@oldschoolsolutions.biz>
In-Reply-To: <20260905-x1-ideacentre-mini-prettify-v1-0-9a87882973bb@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788600555; l=1496;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=q0Klq8CCwMTL3nScIUXlwBoWcQQvy4wXunu4Khr0rQQ=;
 b=CeYlvvFJxoUQ8DkappLev9pCIMW7NeGVqZGEVMJNa9pd3Hw1dymUmif6pV12uoZx8y6CdSQtA
 bsV/OJt0exGC/IaNpHVwOYepSsjz8tGrbQ5uNWcfo9k3/EgMYSgG2z1
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mdss_dp0/1/2 had no sound-name-prefix, so the three DisplayPort
backends were not distinct DAIs on the card. Add the prefixes.

Enable the LPASS VA macro with the 2.4 MHz rate. This chassis has no
onboard DMICs; the node still provides the fsgen clock to tx_macro and
rx_macro. Without it both codecs fail to probe (-ENOENT).

Tested-on: IdeaCentre Mini 01Q8X10, Purwa (X1-26-100)

Assisted-by: Grok 4.5 (xAI)
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 .../arm64/boot/dts/qcom/x1-lenovo-ideacentre-mini-01q8x10.dtsi | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/x1-lenovo-ideacentre-mini-01q8x10.dtsi b/arch/arm64/boot/dts/qcom/x1-lenovo-ideacentre-mini-01q8x10.dtsi
index 76a9f745b279d..5a2db91d5e587 100644
--- a/arch/arm64/boot/dts/qcom/x1-lenovo-ideacentre-mini-01q8x10.dtsi
+++ b/arch/arm64/boot/dts/qcom/x1-lenovo-ideacentre-mini-01q8x10.dtsi
@@ -665,6 +665,10 @@ eusb6_repeater: redriver@4f {
 	};
 };
 
+&lpass_vamacro {
+	qcom,dmic-sample-rate = <2400000>;
+};
+
 &gpu {
 	status = "okay";
 };
@@ -674,6 +678,8 @@ &mdss {
 };
 
 &mdss_dp0 {
+	sound-name-prefix = "DisplayPort0";
+
 	status = "okay";
 };
 
@@ -682,6 +688,8 @@ &mdss_dp0_out {
 };
 
 &mdss_dp1 {
+	sound-name-prefix = "DisplayPort1";
+
 	status = "okay";
 };
 
@@ -690,6 +698,8 @@ &mdss_dp1_out {
 };
 
 &mdss_dp2 {
+	sound-name-prefix = "DisplayPort2";
+
 	status = "okay";
 };
 

-- 
2.53.0

