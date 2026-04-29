From: David Heidelberg <david@ixit.cz>
Date: Wed, 29 Apr 2026 15:16:53 +0200
Subject: [PATCH] arm64: dts: qcom: sdm845-xiaomi-beryllium: Correct IPA FW
 path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260429-beryllium-ipa-fix-v1-1-816326ba9047@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAMQE8mkC/x2MWw5AMBAAr9Lst02qFcpVxIfHYhNKtiFE3F3jc
 yaZeSCQMAWo1ANCJwfefIQ0UdDPrZ8IeYgMRptcZ6bEjuReFj5W5L3FkS8sqHRF7pzV1kHsdqG
 o/2fdvO8H65RbMmMAAAA=
X-Change-ID: 20260429-beryllium-ipa-fix-7e9876883038
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Robert Eckelmann <longnoserob@gmail.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Joel Selvaraj <foss@joelselvaraj.com>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1313; i=david@ixit.cz;
 h=from:subject:message-id; bh=XlrWu6+s0yzcZbPOuqwUJ1OG+3gH3ACkoRurIxaFbys=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp8gTUUmKZ9rMDMP4he+SdSlNbVNxIugNU0O8Ni
 MZMl2tA2MSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCafIE1AAKCRBgAj/E00kg
 cvzGEACNCAxF/J4o22AFXb6r0uX1FmcnZjznlEbXhaWpLqT4+tAJcREq+AkxPDRwQ9VVZbSkIqr
 EUEAt32Mhyd2jZJDWBUNcjIXPqLXLtYREyiGYNf9cPS9Y/c4EKdRugBUwW33ks/GBAtnEJOvbAC
 QsmF2eiyOJBvezknOrj9Hhru1Ov1BOSGN3ECAb2Hk4mYBPugnDPfAp5Fj16j+35MZb8/d2YL73O
 JrPk0R4qSjfy8AooCsNx81my9fZU+3JNCV3aIYxvrIeIjf8ZVlVRTp83kqcaBNcs2A3e2WEIYhn
 r7SLguPkJp8G8bJenvHWRFPeC6Kl1jadJSeI1NSJcNbMMQNucSN77b5OrCch/Tgb8J9QToYddac
 MWHIn04OC6pWSHW/Me9ZT2EpegMrYBMNmz1wdIZjzQrKw6Vgus2rkLjmLCOjlTwGaIoqgVIi4kT
 U869bTS/4JTP2mZrXBKkmwfATqKTCWSlf3PAfdpjU/1CC6uV8yMnU11sqFk2uC6+0Ju2YQHjBAj
 bpOVb+pXFtpJ8sKF2H+fXulDdJjiq1bXqb3VMYIKs2jbxsTSaZan3GRe+Aqeh6iYbxwwWyJmdLq
 uZoTP6cCZDa/iNSy4Xs/j1AgPfmZBwpe28hcIGQYoCY4h4vL4bCNAfun2aQc8D4tkHGeawbdGdA
 dA2J159BbDNZxPA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Joel Selvaraj <foss@joelselvaraj.com>

The path was accidentally reverted back to old while refactoring of the
device-tree.

Fixes: 5bde31dc7b17 ("arm64: dts: qcom: sdm845-xiaomi-beryllium: Add placeholders and sort")
Signed-off-by: Joel Selvaraj <foss@joelselvaraj.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 1298485c42142..22354968aeaa3 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -266,17 +266,17 @@ &ibb {
 	regulator-pull-down;
 	regulator-soft-start;
 	qcom,discharge-resistor-kohms = <300>;
 };
 
 &ipa {
 	qcom,gsi-loader = "self";
 	memory-region = <&ipa_fw_mem>;
-	firmware-name = "qcom/sdm845/beryllium/ipa_fws.mbn";
+	firmware-name = "qcom/sdm845/Xiaomi/beryllium/ipa_fws.mbn";
 
 	status = "okay";
 };
 
 &i2c5 {
 	clock-frequency = <400000>;
 
 	status = "okay";

---
base-commit: dca922e019dd758b4c1b4bec8f1d509efddeaab4
change-id: 20260429-beryllium-ipa-fix-7e9876883038

Best regards,
-- 
David Heidelberg <david@ixit.cz>

