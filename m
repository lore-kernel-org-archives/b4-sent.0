From: David Heidelberg <david@ixit.cz>
Date: Mon, 22 Dec 2025 20:05:39 +0100
Subject: [PATCH 3/4] arm64: dts: qcom: sdm845-samsung-starqltechn: Update
 firmware paths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251222-oneplus6-new-fw-path-v1-3-a2d366f9eb89@ixit.cz>
References: <20251222-oneplus6-new-fw-path-v1-0-a2d366f9eb89@ixit.cz>
In-Reply-To: <20251222-oneplus6-new-fw-path-v1-0-a2d366f9eb89@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1689; i=david@ixit.cz;
 h=from:subject:message-id; bh=+cFxlM0/qdKJ4WnDmq/MewWhoYxFFoCkBwVraCL+wRY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpSZaElifyursul5URo8/qUBz95B4hDuqBULgJk
 SU/Z0qBsSOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaUmWhAAKCRBgAj/E00kg
 cqqWEACF2mKYnomZE0WCIRbKZnBJKhGvgd/+jVmDM18/Ry/IJuuzwA2mlISXQqkCOzUwakSNGk0
 fhXdQNcYJSm9uXt59oAf6Nm9UbwA2j1v8NrxAN74tIYp5UwxMscHv+0a74/k1lgR1JAsZNV7beg
 gbJQKJRKAFZ7owyLB4+J51osaaIjgXdpT+xMiSIE/ugmyBSJtkrQKpuYqQLTj3s4yOM7Ltc6KdB
 dGolVEku4mzLITA4UjEm5vsoX9CE3O90nPKficlzoYtZVqvlQY90XkKwu3e87ya40KMm9x4aqVh
 L7Gj4kA9QdzrCwkdYwTTR1Ywm2xNY/vWlKFFOWOPPNSNtq/avq1gFBrURoK3KaXuRPmryD9/TnC
 WKdspHSw2fj1l2eKaP492C5vvh2xM5e1XnO5Kcryp/TNG+GCRH1AQmMguIeU4LISiobtf6q1JMv
 SPUfQUPzq1+LkkHoNK9avCHTzwhWljYM3M7KviZoygloqI0Zi1KFlhmHwpWE0KrOVyt1e1CPWX3
 eZWk/Z2N33OYjvN8wltoDIjn5ySHuPm2SNCK6An76X/4Wwr4ZOK9dxWtkiBd/+WQGI2hufMDHKz
 0sEc7kAZhCvwm4O0XwxYaIHabbRkz481vFeJRh2M2AvZ7Vg/Mrcfx7XwIKetBM1Qx6g351xVZ7o
 /eZmpQ/yYTQ0RVA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Conform to the new firmware path scheme.
Includes cosmetic cleanups.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts | 15 +++++++++------
 1 file changed, 9 insertions(+), 6 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts b/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts
index 5d41a92cfebff..77f5872de6f19 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts
@@ -254,7 +254,7 @@ &gpu {
 };
 
 &gpu_zap_shader {
-	firmware-name = "qcom/sdm845/starqltechn/a630_zap.mbn";
+	firmware-name = "qcom/sdm845/Samsung/starqltechn/a630_zap.mbn";
 };
 
 &mdss {
@@ -699,7 +699,8 @@ touchscreen@48 {
 };
 
 &adsp_pas {
-	firmware-name = "qcom/sdm845/starqltechn/adsp.mbn";
+	firmware-name = "qcom/sdm845/Samsung/starqltechn/adsp.mbn";
+
 	status = "okay";
 };
 
@@ -904,20 +905,22 @@ &wcd9340 {
 };
 
 &mss_pil {
-	firmware-name = "qcom/sdm845/starqltechn/mba.mbn",
-			"qcom/sdm845/starqltechn/modem.mbn";
+	firmware-name = "qcom/sdm845/Samsung/starqltechn/mba.mbn",
+			"qcom/sdm845/Samsung/starqltechn/modem.mbn";
+
 	status = "okay";
 };
 
 &ipa {
 	qcom,gsi-loader = "self";
 	memory-region = <&ipa_fw_mem>;
-	firmware-name = "qcom/sdm845/starqltechn/ipa_fws.mbn";
+	firmware-name = "qcom/sdm845/Samsung/starqltechn/ipa_fws.mbn";
+
 	status = "okay";
 };
 
 &slpi_pas {
-	firmware-name = "qcom/sdm845/starqltechn/slpi.mbn";
+	firmware-name = "qcom/sdm845/Samsung/starqltechn/slpi.mbn";
 	cx-supply = <&slpi_regulator>;
 
 	status = "okay";

-- 
2.51.0

