From: David Heidelberg <david@ixit.cz>
Date: Mon, 22 Dec 2025 20:05:38 +0100
Subject: [PATCH 2/4] arm64: dts: qcom: sdm845-axolotl: Update firmware
 paths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251222-oneplus6-new-fw-path-v1-2-a2d366f9eb89@ixit.cz>
References: <20251222-oneplus6-new-fw-path-v1-0-a2d366f9eb89@ixit.cz>
In-Reply-To: <20251222-oneplus6-new-fw-path-v1-0-a2d366f9eb89@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2393; i=david@ixit.cz;
 h=from:subject:message-id; bh=gmKwzuBv7UHtjeBZQPr7qEsNrdAI8RsOWmVH6i7DmVY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpSZaDta1QvfEIlC4YNp2HOihztt2Ewk21sm50C
 15QMDBZxOeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaUmWgwAKCRBgAj/E00kg
 ct8YD/9kSaB5COvmTTS4pYCX9fUxSSGXDVtx364dCAGJHrN0cdhbL8VLMbsmUuO1GAE84vSqDb2
 xH9FfHoP7s/gtzp8Q3V7Y/3YuxdEJJyFF3EeDvnDtlHzNraKqSzSbN205UdcRh3wBgjm6GA6+aV
 HVByZ0l2gRjhq5+y9zcvwAOnQGpq8TmQq1naqKC1OJ7tuG6Tn88C+LDwhvu9/RUYWe7tTRYOTlE
 SBggYfaY/TyfTzcIWanM1H1wtk2NtWdb5WWwUGMcvU57W0CVNIuk44CEYNWzA25hTWvL/7/hWk6
 jkAZNhUidMYoK0npwahrLEvbZYf7mjZZRnoLLxd16ab3ywD7uDcybosaZRTaqBHGufTa3JUwenU
 L2wDV7aV5SorobdkhV+3CTrmuZRNNuds4S9vttMluY1DVoSK1SWk6UmWCGOdegaA/+pAlxSBZ1V
 57uZmTVFYZkjP71vkiXfBFbFeEJy7zolB03gLZ5eBYZiERB9iqicbej7a9T/dUvKgGe+BZKtDf2
 4iaWK4/7oFPEhkLt1YfTFGaRZMjsq6HI2aXXbG9vGezhxVyZoZLwA+NSzH5KRI1jrn5Nxdaf/4O
 5UmV1M0fuALSDm2ylVxmXQ2fcdKUN3TWbK+o5kImtYiByD8/uuCLMgDiuLUiIBDEecBgKYf4NT2
 6r80fFETBG7UQuQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Conform to the new firmware path scheme.
Includes cosmetic cleanups.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 22 ++++++++++++++--------
 1 file changed, 14 insertions(+), 8 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index ddc2b3ca3bc57..a35c120361c19 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -108,8 +108,9 @@ vreg_s4a_1p8: pm8998-smps4 {
 };
 
 &adsp_pas {
+	firmware-name = "qcom/sdm845/SHIFT/axolotl/adsp.mbn";
+
 	status = "okay";
-	firmware-name = "qcom/sdm845/axolotl/adsp.mbn";
 };
 
 &apps_rsc {
@@ -409,8 +410,9 @@ vreg_s3c_0p6: smps3 {
 };
 
 &cdsp_pas {
+	firmware-name = "qcom/sdm845/SHIFT/axolotl/cdsp.mbn";
+
 	status = "okay";
-	firmware-name = "qcom/sdm845/axolotl/cdsp.mbn";
 };
 
 &gcc {
@@ -426,7 +428,7 @@ &gpu {
 };
 
 &gpu_zap_shader {
-	firmware-name = "qcom/sdm845/axolotl/a630_zap.mbn";
+	firmware-name = "qcom/sdm845/SHIFT/axolotl/a630_zap.mbn";
 };
 
 &i2c5 {
@@ -458,7 +460,8 @@ &i2c10 {
 &ipa {
 	qcom,gsi-loader = "self";
 	memory-region = <&ipa_fw_mem>;
-	firmware-name = "qcom/sdm845/axolotl/ipa_fws.mbn";
+	firmware-name = "qcom/sdm845/SHIFT/axolotl/ipa_fws.mbn";
+
 	status = "okay";
 };
 
@@ -502,8 +505,9 @@ &mdss_dsi0_phy {
 };
 
 &mss_pil {
+	firmware-name = "qcom/sdm845/SHIFT/axolotl/mba.mbn", "qcom/sdm845/SHIFT/axolotl/modem.mbn";
+
 	status = "okay";
-	firmware-name = "qcom/sdm845/axolotl/mba.mbn", "qcom/sdm845/axolotl/modem.mbn";
 };
 
 &pm8998_gpios {
@@ -597,7 +601,8 @@ &qupv3_id_1 {
 };
 
 &slpi_pas {
-	firmware-name = "qcom/sdm845/axolotl/slpi.mbn";
+	firmware-name = "qcom/sdm845/SHIFT/axolotl/slpi.mbn";
+
 	status = "okay";
 };
 
@@ -673,7 +678,7 @@ bluetooth {
 		 * This path is relative to the qca/
 		 * subdir under lib/firmware.
 		 */
-		firmware-name = "axolotl/crnv21.bin";
+		firmware-name = "SHIFT/axolotl/crnv21.bin";
 
 		vddio-supply = <&vreg_s4a_1p8>;
 		vddxo-supply = <&vreg_l7a_1p8>;
@@ -727,8 +732,9 @@ &usb_1_qmpphy {
 };
 
 &venus {
+	firmware-name = "qcom/sdm845/SHIFT/axolotl/venus.mbn";
+
 	status = "okay";
-	firmware-name = "qcom/sdm845/axolotl/venus.mbn";
 };
 
 &wifi {

-- 
2.51.0

