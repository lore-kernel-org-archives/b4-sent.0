From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sun, 23 Aug 2026 10:35:29 +0200
Subject: [PATCH 2/2] arm64: dts: qcom: sc8280xp-microsoft-blackrock: enable
 4-lane DP altmode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260823-blackrock-audio-v1-2-f319387fc6a6@oldschoolsolutions.biz>
References: <20260823-blackrock-audio-v1-0-f319387fc6a6@oldschoolsolutions.biz>
In-Reply-To: <20260823-blackrock-audio-v1-0-f319387fc6a6@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787474149; l=2037;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=I7UKGMSk+s4dyW5AvgjG/TZCmq97eEd3LiG6adDQR/4=;
 b=/BdBee6Uq0Z/jqdf9lcGcx2a2obr8yN0u1TYyKWAl3NYqjaEM47SWXjG58PaI5+nl4LaBJStR
 2pqepi312DyD8IeD0fstKTWghPTwLzaejCXoACQgYiyx2w7VNjwTUYe
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow up to 4 lanes for the DisplayPort links on the USB-C ports and
the mini-DP connector. Add the standard link-frequencies and move
data-lanes to the out endpoints where required by the current bindings.

Also enable mode-switch on the QMP combo PHYs so that altmode events
can reach them (same treatment as on the X13s).

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts | 15 +++++++++++----
 1 file changed, 11 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
index a94141d670f62..aceeda96911db 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
@@ -564,7 +564,9 @@ &mdss0_dp0 {
 };
 
 &mdss0_dp0_out {
-	data-lanes = <0 1>;
+	data-lanes = <0 1 2 3>;
+
+	link-frequencies = /bits/ 64 <1620000000 2700000000 5400000000 8100000000>;
 	remote-endpoint = <&usb_0_qmpphy_dp_in>;
 };
 
@@ -574,7 +576,9 @@ &mdss0_dp1 {
 };
 
 &mdss0_dp1_out {
-	data-lanes = <0 1>;
+	data-lanes = <0 1 2 3>;
+	link-frequencies = /bits/ 64 <1620000000 2700000000 5400000000 8100000000>;
+
 	remote-endpoint = <&usb_1_qmpphy_dp_in>;
 };
 
@@ -582,12 +586,13 @@ &mdss0_dp2 {
 	sound-name-prefix = "DisplayPort2";
 	compatible = "qcom,sc8280xp-dp";
 
-	data-lanes = <0 1 2 3>;
-
 	status = "okay";
 };
 
 &mdss0_dp2_out {
+	data-lanes = <0 1 2 3>;
+	link-frequencies = /bits/ 64 <1620000000 2700000000 5400000000 8100000000>;
+
 	remote-endpoint = <&dp1_connector_in>;
 };
 
@@ -932,6 +937,7 @@ &usb_0_qmpphy {
 	vdda-phy-supply = <&vreg_l9d>;
 	vdda-pll-supply = <&vreg_l4d>;
 
+	mode-switch;
 	orientation-switch;
 
 	status = "okay";
@@ -969,6 +975,7 @@ &usb_1_qmpphy {
 	vdda-phy-supply = <&vreg_l4b>;
 	vdda-pll-supply = <&vreg_l3b>;
 
+	mode-switch;
 	orientation-switch;
 
 	status = "okay";

-- 
2.53.0

