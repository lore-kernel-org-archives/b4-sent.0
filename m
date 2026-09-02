From: David Heidelberg <david@ixit.cz>
Date: Wed, 02 Sep 2026 22:59:13 +0200
Subject: [PATCH 2/3] arm64: dts: qcom: sdm845-google: Improve NFC pins
 description
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260902-sdm670-sargo-nfc-v1-2-bed1cbbffc46@ixit.cz>
References: <20260902-sdm670-sargo-nfc-v1-0-bed1cbbffc46@ixit.cz>
In-Reply-To: <20260902-sdm670-sargo-nfc-v1-0-bed1cbbffc46@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Richard Acayan <mailingradian@gmail.com>
Cc: Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2154; i=david@ixit.cz;
 h=from:subject:message-id; bh=1g5bzY+HsNyCbevfoHcORR+VD1MfbCn1WfNGutR8+KA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqmI4lOhMcUlhuWQwB8IJwJ0OMA0LRE/4ETGGyk
 2h/u6PZJoiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapiOJQAKCRBgAj/E00kg
 cjnmD/96ZqcIp7Pv1yb8cSdUWl6kGkV9H7jNxfyUoqFmPEJWYwJKwD88Q6lPnsJety5miI/0mYL
 B/GAn2NxMheJRMCJlK/58aUTAGekVYWyFbB42vD0IAv5qKMKiBMit/1wkdTvMCOEShthcfwuz86
 KGGD94K+TFIbJ0wGIkAhfvjCzisGoHJGlRM19T/iUuoH2FwMZLDrDrlxFpAD5ZgJk4UQcA22eMe
 GLgHtf9nDWt9YwrDXZS3JArqnxhoCFsgN6suaJFB9TUYfcZOtKDMaGHcs9FKmgKS+21lKjKjLlH
 nEiWin2Yj9A8Kl4Yc7AwdZgZmdHaLdRv9YC6w6zCeA2HfWbabHtpzcbK1wVDVOtc4g3XfaZ1ywK
 +RAtUfm5SYUFunS59EBkWCQAx1WaqUhLCMuLprbE25dCf0NKyNGz6aJ2kU2x16QNmQaMXKiTnHj
 StIuCe30NL5JX3x+egXp71wwqjXIJWZL6EowVtxhVj9ROTa0btsOYASGmkvC5czETOjY9kJD4YD
 HScjpP//QW+jtAiLJ7NxodZQRi11XgxNR1nUMftqAJm/v0CFDyj2oAow3dlZCTWUdtpfdwEb04G
 UPUJCRsSVco76Sosvffn7Ufl59yATUHRt1uO6JiQFWM/Sne6ZSfdKSQMY7XDDVWB902G310tAa+
 ZnaHlOFySJSOAyg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Be more clear with pin description and group all of them into one state.

No functional changes.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 34 ++++++++++++++--------
 1 file changed, 22 insertions(+), 12 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index f73d4ea57705f..f1379857e2742 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -400,17 +400,17 @@ nfc@28 {
 		compatible = "nxp,pn557", "nxp,nxp-nci-i2c";
 		reg = <0x28>;
 
 		interrupts-extended = <&tlmm 63 IRQ_TYPE_EDGE_RISING>;
 
 		enable-gpios = <&tlmm 25 GPIO_ACTIVE_HIGH>;
 		firmware-gpios = <&tlmm 79 GPIO_ACTIVE_HIGH>;
 
-		pinctrl-0 = <&nfc_int_default &nfc_enable_default>;
+		pinctrl-0 = <&nfc_default>;
 		pinctrl-names = "default";
 	};
 };
 
 &i2c12 {
 	/* Bottom spkr (right) CS35L36 @ 40 */
 
 	/* Top spkr (left) CS35L36 @ 41 */
@@ -473,28 +473,38 @@ &qup_uart9_tx {
 	drive-strength = <2>;
 	bias-disable;
 };
 
 &tlmm {
 	gpio-reserved-ranges = < 0 4>, /* SPI (Intel MNH Pixel Visual Core) */
 			       <81 4>; /* SPI (most likely Fingerprint Cards FPC1075) */
 
-	nfc_int_default: nfc-int-default-state {
-		pins = "gpio63";
-		function = "gpio";
-		drive-strength = <2>;
-		bias-pull-down;
-	};
+	nfc_default: nfc-default-state {
+		enable-pins {
+			pins = "gpio25";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-down;
+		};
+
+		irq-pins {
+			pins = "gpio63";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-down;
+		};
+
+		firmware-pins {
+			pins = "gpio79";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-down;
+		};
 
-	nfc_enable_default: nfc-enable-default-state {
-		pins = "gpio25", "gpio79";
-		function = "gpio";
-		drive-strength = <2>;
-		bias-pull-down;
 	};
 
 	touchscreen_reset: ts-reset-state {
 		pins = "gpio99";
 		function = "gpio";
 		drive-strength = <8>;
 		bias-pull-up;
 	};

-- 
2.55.0

