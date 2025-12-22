From: David Heidelberg <david@ixit.cz>
Date: Mon, 22 Dec 2025 20:05:37 +0100
Subject: [PATCH 1/4] arm64: dts: qcom: sdm845-oneplus: Update firmware
 paths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251222-oneplus6-new-fw-path-v1-1-a2d366f9eb89@ixit.cz>
References: <20251222-oneplus6-new-fw-path-v1-0-a2d366f9eb89@ixit.cz>
In-Reply-To: <20251222-oneplus6-new-fw-path-v1-0-a2d366f9eb89@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2531; i=david@ixit.cz;
 h=from:subject:message-id; bh=vp0zUfKVDYHpsWqgWOnL5t1xkywRwF2t5wwVa5hJJj4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpSZaDkU1MP1d4SggMLqFvBmPmynCNuTEu2YSgs
 k6JwICpAeKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaUmWgwAKCRBgAj/E00kg
 cvIdD/9V4moFgFLiu3e8rcdeBm1XWnRCng+u9y9ej6V0sHoqbevqpDpEzkIbPCr1SgSXMKGnKOT
 Vdjy8RQVt9qcEsL+mZdrGnN8Wcs9aNnoqV9coM/YACMihPgsjsAl7IW1UV2Umk/LNgV95BXFpPQ
 saln0tpZB60F4Pvxu9Dzg1z0sYyJUorfTXs/rTdFda1hadsWpZFzvkRZEg2rra/xeylqNzui7V8
 ehZUaVdzmzpaNfkk51l12GKMtN3rvOPQ6xNOldzrl9uzcM0JErJaetMG6nmK87bhfNSDJfc9t5X
 3T2eJZ5oAvitZFtKjA8OwnbF1Sk/IvMKYGY9JfOb9G9QMKnJ8bL1VmygwueQAhzTnqz6BfkazWE
 bEn+bAQYLNL9jCirYBof+gfLR7V9rTAhsd1ygWNzc+DT6ZczQGjP/SIi2/OpLRJyZ898fnMlk7p
 EbYuj2JrnA7OWJ947aVFBL9ZVnXxtRWTX4QkvJvRC2AtKkjIo8exX6SZxbeWDJ0+MVfIBXhKAWm
 cAinA6hLMpn2UFlw8LW7Vc6VSW1+gJua0S9ZiMwLwx1Om3QW4urm7wrkr/SvpLafDuGH2q+u6Fb
 AvzhQrtmfhZHZdpiXXt6AEKttsTk2YGpohwwt4YeMp7cs3W9e1R/ldv7ZsCAoiVWsxrTYePcsj6
 6eO8nBaIjF7br9g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Conform to the new firmware path scheme.
Includes cosmetic cleanups.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 23 ++++++++++++++--------
 1 file changed, 15 insertions(+), 8 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index db6dd04c51bb5..f1c63794db979 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -181,8 +181,9 @@ panel_vddi_poc_1p8: panel-vddi-poc-regulator {
 };
 
 &adsp_pas {
+	firmware-name = "qcom/sdm845/OnePlus/enchilada/adsp.mbn";
+
 	status = "okay";
-	firmware-name = "qcom/sdm845/oneplus6/adsp.mbn";
 };
 
 &apps_rsc {
@@ -353,8 +354,9 @@ vreg_s3c_0p6: smps3 {
 };
 
 &cdsp_pas {
+	firmware-name = "qcom/sdm845/OnePlus/enchilada/cdsp.mbn";
+
 	status = "okay";
-	firmware-name = "qcom/sdm845/oneplus6/cdsp.mbn";
 };
 
 &gcc {
@@ -370,7 +372,7 @@ &gpu {
 };
 
 &gpu_zap_shader {
-	firmware-name = "qcom/sdm845/oneplus6/a630_zap.mbn";
+	firmware-name = "qcom/sdm845/OnePlus/enchilada/a630_zap.mbn";
 };
 
 &i2c10 {
@@ -422,7 +424,8 @@ rmi4_f12: rmi4-f12@12 {
 &ipa {
 	qcom,gsi-loader = "self";
 	memory-region = <&ipa_fw_mem>;
-	firmware-name = "qcom/sdm845/oneplus6/ipa_fws.mbn";
+	firmware-name = "qcom/sdm845/OnePlus/enchilada/ipa_fws.mbn";
+
 	status = "okay";
 };
 
@@ -474,8 +477,10 @@ &mdss_dsi0_phy {
 
 /* Modem/wifi */
 &mss_pil {
+	firmware-name = "qcom/sdm845/OnePlus/enchilada/mba.mbn",
+			"qcom/sdm845/OnePlus/enchilada/modem.mbn";
+
 	status = "okay";
-	firmware-name = "qcom/sdm845/oneplus6/mba.mbn", "qcom/sdm845/oneplus6/modem.mbn";
 };
 
 &pm8998_gpios {
@@ -593,7 +598,8 @@ &qup_uart9_tx {
 };
 
 &slpi_pas {
-	firmware-name = "qcom/sdm845/oneplus6/slpi.mbn";
+	firmware-name = "qcom/sdm845/OnePlus/enchilada/slpi.mbn";
+
 	status = "okay";
 };
 
@@ -744,7 +750,7 @@ bluetooth {
 		 * This path is relative to the qca/
 		 * subdir under lib/firmware.
 		 */
-		firmware-name = "oneplus6/crnv21.bin";
+		firmware-name = "OnePlus/enchilada/crnv21.bin";
 
 		vddio-supply = <&vreg_s4a_1p8>;
 		vddxo-supply = <&vreg_l7a_1p8>;
@@ -906,8 +912,9 @@ speaker_default: speaker-default-state {
 };
 
 &venus {
+	firmware-name = "qcom/sdm845/OnePlus/enchilada/venus.mbn";
+
 	status = "okay";
-	firmware-name = "qcom/sdm845/oneplus6/venus.mbn";
 };
 
 &wcd9340 {

-- 
2.51.0

