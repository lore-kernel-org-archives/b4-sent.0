From: Joe Sandom <jsandom@axon.com>
Date: Thu, 09 Apr 2026 16:26:55 +0100
Subject: [PATCH v3 3/5] arm64: dts: qcom: sm8550: move IPA properties to
 SoC device tree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260409-rb5gen2-dts-v3-3-be736355d4b4@axon.com>
References: <20260409-rb5gen2-dts-v3-0-be736355d4b4@axon.com>
In-Reply-To: <20260409-rb5gen2-dts-v3-0-be736355d4b4@axon.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joe Sandom <jsandom@axon.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775748414; l=2013;
 i=jsandom@axon.com; s=20260319; h=from:subject:message-id;
 bh=2Hf81fBazRw+MMKDG2/cNY2JsBcSjh+sphR62doLGW8=;
 b=xD0wu3dYCtlLNv6B0W0ajhsBSMrO23mvlsSycyxbjV9y+Sb6h4KdeiNTkkUlzNq3dkpvocVG6
 9WHVUasggR0AWD8ft45a9TmiW2WfBNnVpqJLjG1fNOaA1VrAGrAhQPp
X-Developer-Key: i=jsandom@axon.com; a=ed25519;
 pk=Q/yflwj2WhkgBVTskrS9Vl5oScD0Bp3vTzDi+OxskTo=
X-Endpoint-Received: by B4 Relay for jsandom@axon.com/20260319 with auth_id=687
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move qcom,gsi-loader and memory-region properties from individual board
DTS files into the SoC DTSI, since these are common to all SM8550-based
boards.

Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: Joe Sandom <jsandom@axon.com>
---
 arch/arm64/boot/dts/qcom/sm8550-hdk.dts | 2 --
 arch/arm64/boot/dts/qcom/sm8550-qrd.dts | 2 --
 arch/arm64/boot/dts/qcom/sm8550.dtsi    | 2 ++
 3 files changed, 2 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8550-hdk.dts b/arch/arm64/boot/dts/qcom/sm8550-hdk.dts
index e821b731bdc496c872703723df02ae9b9b0233b5..b795589385520acd74eecc7701cab82f4f7da200 100644
--- a/arch/arm64/boot/dts/qcom/sm8550-hdk.dts
+++ b/arch/arm64/boot/dts/qcom/sm8550-hdk.dts
@@ -939,8 +939,6 @@ &i2c_master_hub_0 {
 };
 
 &ipa {
-	qcom,gsi-loader = "self";
-	memory-region = <&ipa_fw_mem>;
 	firmware-name = "qcom/sm8550/ipa_fws.mbn";
 	status = "okay";
 };
diff --git a/arch/arm64/boot/dts/qcom/sm8550-qrd.dts b/arch/arm64/boot/dts/qcom/sm8550-qrd.dts
index cf63109ff7bf7b6fc827f108e22e82b8b04273c1..f2effa55d8197819175bfd5a89d2fddb20561548 100644
--- a/arch/arm64/boot/dts/qcom/sm8550-qrd.dts
+++ b/arch/arm64/boot/dts/qcom/sm8550-qrd.dts
@@ -818,8 +818,6 @@ fsa4480_sbu_mux: endpoint {
 };
 
 &ipa {
-	qcom,gsi-loader = "self";
-	memory-region = <&ipa_fw_mem>;
 	firmware-name = "qcom/sm8550/ipa_fws.mbn";
 	status = "okay";
 };
diff --git a/arch/arm64/boot/dts/qcom/sm8550.dtsi b/arch/arm64/boot/dts/qcom/sm8550.dtsi
index 54308cbde40732da072177eab533582c155df590..d292dfce6b66fff6cff918b8bd6ac0b9cd22c4b3 100644
--- a/arch/arm64/boot/dts/qcom/sm8550.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8550.dtsi
@@ -2730,6 +2730,8 @@ &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>,
 			qcom,smem-state-names = "ipa-clock-enabled-valid",
 						"ipa-clock-enabled";
 
+			qcom,gsi-loader = "self";
+			memory-region = <&ipa_fw_mem>;
 			sram = <&ipa_modem_tables>;
 
 			status = "disabled";

-- 
2.34.1

