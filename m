From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Tue, 25 Aug 2026 16:07:46 +0200
Subject: [PATCH v2 2/2] arm64: dts: qcom: sc8280xp-microsoft-blackrock:
 Enable 4-lane DP altmode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-blackrock-audio-v2-2-659cc4724d57@oldschoolsolutions.biz>
References: <20260825-blackrock-audio-v2-0-659cc4724d57@oldschoolsolutions.biz>
In-Reply-To: <20260825-blackrock-audio-v2-0-659cc4724d57@oldschoolsolutions.biz>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787666870; l=2296;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=UOYmIKEvjesIgzM9RnafIQQv3nkJi5f0ENtDPOfY/KA=;
 b=Ymt877u44T9QDIPfPY/byASOzTcJmxgEnC7hQ5ZlRYocOj87YaekyznvysD1F846ZCLmXJJ3P
 WOPRIs/9XbMAm/Ki0gfcQggTlM0SlNndCtJ+4AZzCuWnGspPoKNcVki
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow up to 4 lanes for the DisplayPort links on the USB-C ports and
the mini-DP connector. Add the standard link-frequencies and move
data-lanes to the out endpoints where required by the current bindings.

Also enable mode-switch on the QMP combo PHYs so that altmode events
can reach them.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts | 13 +++++++++----
 arch/arm64/boot/dts/qcom/sc8280xp.dtsi                    |  4 ++++
 2 files changed, 13 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
index ac22f44020a64..f5140d3985503 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
@@ -563,7 +563,9 @@ &mdss0_dp0 {
 };
 
 &mdss0_dp0_out {
-	data-lanes = <0 1>;
+	data-lanes = <0 1 2 3>;
+
+	link-frequencies = /bits/ 64 <1620000000 2700000000 5400000000 8100000000>;
 	remote-endpoint = <&usb_0_qmpphy_dp_in>;
 };
 
@@ -572,19 +574,22 @@ &mdss0_dp1 {
 };
 
 &mdss0_dp1_out {
-	data-lanes = <0 1>;
+	data-lanes = <0 1 2 3>;
+	link-frequencies = /bits/ 64 <1620000000 2700000000 5400000000 8100000000>;
+
 	remote-endpoint = <&usb_1_qmpphy_dp_in>;
 };
 
 &mdss0_dp2 {
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
 
diff --git a/arch/arm64/boot/dts/qcom/sc8280xp.dtsi b/arch/arm64/boot/dts/qcom/sc8280xp.dtsi
index baca36b151853..1c8836c1aae63 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp.dtsi
+++ b/arch/arm64/boot/dts/qcom/sc8280xp.dtsi
@@ -3692,6 +3692,8 @@ usb_0_qmpphy: phy@88eb000 {
 			#clock-cells = <1>;
 			#phy-cells = <1>;
 
+			mode-switch;
+
 			status = "disabled";
 
 			ports {
@@ -3807,6 +3809,8 @@ usb_1_qmpphy: phy@8903000 {
 			#clock-cells = <1>;
 			#phy-cells = <1>;
 
+			mode-switch;
+
 			status = "disabled";
 
 			ports {

-- 
2.53.0

