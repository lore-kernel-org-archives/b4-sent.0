From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 29 Jan 2026 01:46:32 -0600
Subject: [PATCH 3/3] arm64: dts: qcom: sm8550: Fix DTBO boot failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260129-sm8550-abl-dtbo-v1-3-abca3be14024@gmail.com>
References: <20260129-sm8550-abl-dtbo-v1-0-abca3be14024@gmail.com>
In-Reply-To: <20260129-sm8550-abl-dtbo-v1-0-abca3be14024@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Kumar Sharma <quic_vksharma@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Pavan Kondeti <pavan.kondeti@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769672821; l=1325;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=1QhN7qYUAYY4kDlWLSrCOTr9aoermzedi1sIaXcq8p8=;
 b=s5S4Ku95A0azWVC3DErKg8BiBODrzC+n9GJ2cMLZBE2m2txOGWZVoLMBpRm3txKTwBoahXtU3
 3woZ5ZOsH5JDSiEcOu8ukPN0r4omwB/GPWcL7HxkNZ0X/61v76Va44d
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Pavan Kondeti <pavan.kondeti@oss.qualcomm.com>

ABL requires certain things in the base dtb to apply a dtbo. Namely:

* The scm node must be named qcom_scm
* The timer node must have a label named arch_timer

This aligns the sm8550 soc dtsi with those requirements. Without these
in the base dtb, when ABL attempts to apply any dtbo, it will fail to
the bootloader menu.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/qcom/sm8550.dtsi | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8550.dtsi b/arch/arm64/boot/dts/qcom/sm8550.dtsi
index 740e3c238e8ed0f162dd168291f6e307ace66e80..d7cc20e1931904e7c603b800089f00955ecec3b7 100644
--- a/arch/arm64/boot/dts/qcom/sm8550.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8550.dtsi
@@ -329,7 +329,7 @@ cluster_sleep_1: cluster-sleep-1 {
 	};
 
 	firmware {
-		scm: scm {
+		scm: qcom_scm {
 			compatible = "qcom,scm-sm8550", "qcom,scm";
 			qcom,dload-mode = <&tcsr 0x19000>;
 			interconnects = <&aggre2_noc MASTER_CRYPTO QCOM_ICC_TAG_ALWAYS
@@ -6764,7 +6764,7 @@ trip-point2 {
 		};
 	};
 
-	timer {
+	arch_timer: timer {
 		compatible = "arm,armv8-timer";
 		interrupts = <GIC_PPI 13 (GIC_CPU_MASK_SIMPLE(8) | IRQ_TYPE_LEVEL_LOW) 0>,
 			     <GIC_PPI 14 (GIC_CPU_MASK_SIMPLE(8) | IRQ_TYPE_LEVEL_LOW) 0>,

-- 
2.52.0

