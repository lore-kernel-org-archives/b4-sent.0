From: David Heidelberg <david@ixit.cz>
Date: Mon, 22 Dec 2025 20:05:40 +0100
Subject: [PATCH 4/4] arm64: dts: qcom: sdm845-xiaomi-polaris: Update
 firmware paths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251222-oneplus6-new-fw-path-v1-4-a2d366f9eb89@ixit.cz>
References: <20251222-oneplus6-new-fw-path-v1-0-a2d366f9eb89@ixit.cz>
In-Reply-To: <20251222-oneplus6-new-fw-path-v1-0-a2d366f9eb89@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1972; i=david@ixit.cz;
 h=from:subject:message-id; bh=swo1m05oF0FryQny/dPEvXTSWQ2ExoATh0LQPAguHY8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpSZaEjThxymd2HU+OyUtmH2TtgYnJ2vMbiwLE5
 aq48HzzNGiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaUmWhAAKCRBgAj/E00kg
 ckK5EACxhfvbyXN6+MVL71FVM6xZKFmKqSJdit/YydNpJrCUSe2S5egjBO9fKW8myySOKL3y0Wy
 ZJuGx7+gyu1zwP/6bUAfJvjdeQ9EMjr3OW3mAyYJh7bewwaMpIW7J+DPtNJDb/JLwSqz7vNK0lP
 iYen25A8+vCHAXCbmyBo5VHPWG16P13fk4Hc13VRJWiA8oiI4I/DoMQVvInTDQORWyJsWB+dc/q
 e2GgFw5GnyNuCIvLvHtbKAkDb0fm3nYRld5UfOplQ4cTFuYPOuJmo6G51fHY+x79ooug1NzG5lq
 sp5XVvqbOq6pYgdZivJjobku9Q6E92m5p6t0Bs+9qxUcyPAAqZou0R2M1GtiPLsz5bbxMXcgpv6
 lphOF79CadMwyfgdYIysZOTY65QhfieYUhvk0O5TZgOjF9fzSBBZc1/lcs+TN0Dwif4tDV7uTpa
 uq1AmV9L6XTMwnnBB0aRZhUyR8TViiZNMU5isL5F+FAK4dDaFBMkkJ3TNu/zdZKVCp9I+YZCDtm
 W9hOzl4cPKe7mjYDt9NBcK31JEJfwnmwnixeSOj19EspUF7lWqOASA+FrXA1PU3VnOs4o0P7pCh
 KyapvW+DkcXN6TE+7Jnlj1Bg3W7RGB3A6GvB8Fi3Fm5iMi791WjTXdBFdpolRaeJxC0bVkDIhlb
 jUNX93kd1ZM6okw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Conform to the new firmware path scheme.
Includes cosmetic cleanups.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts | 17 +++++++++++------
 1 file changed, 11 insertions(+), 6 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts
index 30e88ff010a39..a44d6e776c82e 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts
@@ -370,7 +370,8 @@ vreg_smp3c_0p6: smps3 {
 };
 
 &cdsp_pas {
-	firmware-name = "qcom/sdm845/polaris/cdsp.mbn";
+	firmware-name = "qcom/sdm845/Xiaomi/polaris/cdsp.mbn";
+
 	status = "okay";
 };
 
@@ -395,7 +396,7 @@ &gpu {
 };
 
 &gpu_zap_shader {
-	firmware-name = "qcom/sdm845/polaris/a630_zap.mbn";
+	firmware-name = "qcom/sdm845/Xiaomi/polaris/a630_zap.mbn";
 };
 
 &ibb {
@@ -410,7 +411,8 @@ &ibb {
 &ipa {
 	qcom,gsi-loader = "self";
 	memory-region = <&ipa_fw_mem>;
-	firmware-name = "qcom/sdm845/polaris/ipa_fws.mbn";
+	firmware-name = "qcom/sdm845/Xiaomi/polaris/ipa_fws.mbn";
+
 	status = "okay";
 };
 
@@ -502,7 +504,9 @@ &mdss_dsi0_phy {
 };
 
 &mss_pil {
-	firmware-name = "qcom/sdm845/polaris/mba.mbn", "qcom/sdm845/polaris/modem.mbn";
+	firmware-name = "qcom/sdm845/Xiaomi/polaris/mba.mbn",
+			"qcom/sdm845/Xiaomi/polaris/modem.mbn";
+
 	status = "okay";
 };
 
@@ -623,7 +627,7 @@ bluetooth {
 		compatible = "qcom,wcn3990-bt";
 
 		/* This path is relative to the qca/ subdir under lib/firmware. */
-		firmware-name = "polaris/crnv21.bin";
+		firmware-name = "Xiaomi/polaris/crnv21.bin";
 
 		vddio-supply = <&vreg_s4a_1p8>;
 		vddxo-supply = <&vreg_l7a_1p8>;
@@ -683,7 +687,8 @@ &ufs_mem_phy {
 };
 
 &venus {
-	firmware-name = "qcom/sdm845/polaris/venus.mbn";
+	firmware-name = "qcom/sdm845/Xiaomi/polaris/venus.mbn";
+
 	status = "okay";
 };
 

-- 
2.51.0

