From: David Heidelberg <david@ixit.cz>
Date: Fri, 03 Apr 2026 15:58:47 +0200
Subject: [PATCH v3 2/5] arm64: dts: qcom: sdm845-oneplus: Enable NFC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-oneplus-nfc-v3-2-fbdce57d63c1@ixit.cz>
References: <20260403-oneplus-nfc-v3-0-fbdce57d63c1@ixit.cz>
In-Reply-To: <20260403-oneplus-nfc-v3-0-fbdce57d63c1@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alexander Martinz <amartinz@shift.eco>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Alexander Martinz <amartinz@shiftphones.com>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 biemster <l.j.beemster@gmail.com>, netdev@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, oe-linux-nfc@lists.linux.dev, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Krzysztof Kozlowski <krzk@kernel.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2115; i=david@ixit.cz;
 h=from:subject:message-id; bh=XjHS4NuCx7fAMVlZG2ITyhuQL05ri2G40fQqssoq1r0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpz8ebutw/eNqUEQTHgvd0Dgc/Yo9d5GISqlvQC
 Loj1cKUs1CJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac/HmwAKCRBgAj/E00kg
 cpOhEACTMnYjl+0txKZmP0qO2F1r13eawzZ+jEy/BJACx7B28uNuVatro3naOMEtw8vf33HbTf2
 dCw1QiViihzBelNqdrJQaIYah5dnhWVIETf6eTJFC9geA0HEmUFkcVMwZfl0XF0YYJXTaDBBiv3
 kjbJSuPcUcbq9d4qJcCmbmkUv9NJinNs612MCwv8uOKHzMVEKTtwFTMmafh7n8Kljj269SBFiXA
 3zDxNHUgJ6KHpp4ARCugs64Cp+GJgOCznLmotaiMSJVG38Q/gq3g48URr5JCf8lOHT22Y1zkncT
 hCDfVhmK6jLkvvmylCuVDaxpo2lgDecfc/1T2vtkRpX0vj2x4E4fc0jtjSdazQGP2Qo2BmtQbH6
 uq4IVYe+CIt3Jv7WJk7Lx+DMBOUhG0xWpkXOXhkTDTQX7Goccqw+qj5p8GuKamuX2/mk9k4FKFO
 qutLfDko7CHqrOiciN1qg1qZk5xo3sJxP4JqmllAgbzyqXhUBJjzXUgijSLdTgBS3sbqyGIKbG8
 Q6i71mqxymUnrCvauu1PQNCVCaEPzU1OGmWcMHlhXRBBDFqlLsh2SsMYykug5rcFfLcol0e3fBv
 udNROSLEJRjVtNvqjZmjNgwGcI7uEMftRRTQw7hymIXyUDhj8HBMo6ZBh6+Ieu1G2+vGT/EasR7
 P0ges/E46aez6iA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable NFC controller NXP PN553, which is part of the package NXP NQ330
(NFC + eSE).

Based on work of biemster <l.j.beemster@gmail.com>.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 57 ++++++++++++++++++++++
 1 file changed, 57 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 6b7378cf4d493..f5a5f1fbc1fb6 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -464,6 +464,26 @@ &gpu_zap_shader {
 	firmware-name = "qcom/sdm845/OnePlus/enchilada/a630_zap.mbn";
 };
 
+&i2c3 {
+	clock-frequency = <400000>;
+
+	status = "okay";
+
+	nfc@28 {
+		compatible = "nxp,pn553", "nxp,nxp-nci-i2c";
+		reg = <0x28>;
+
+		interrupts-extended = <&tlmm 63 IRQ_TYPE_EDGE_RISING>;
+
+		enable-gpios = <&tlmm 12 GPIO_ACTIVE_HIGH>;
+		firmware-gpios = <&tlmm 62 GPIO_ACTIVE_HIGH>;
+
+		pinctrl-0 = <&nfc_default>;
+		pinctrl-1 = <&nfc_sleep>;
+		pinctrl-names = "default", "sleep";
+	};
+};
+
 &i2c10 {
 	status = "okay";
 	clock-frequency = <100000>;
@@ -674,6 +694,11 @@ &qupv3_id_0 {
 	status = "okay";
 };
 
+&qup_i2c3_default {
+	drive-strength = <2>;
+	bias-disable;
+};
+
 &qup_i2c10_default {
 	drive-strength = <2>;
 	bias-disable;
@@ -1007,6 +1032,38 @@ speaker_default: speaker-default-state {
 		bias-pull-up;
 		output-high;
 	};
+
+	nfc_default: nfc-default-state {
+		enable-pins {
+			pins = "gpio12", "gpio62";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-up;
+		};
+
+		int-pins {
+			pins = "gpio63";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-up;
+		};
+	};
+
+	nfc_sleep: nfc-sleep-state {
+		enable-pins {
+			pins = "gpio12", "gpio62";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-disable;
+		};
+
+		int-pins {
+			pins = "gpio63";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-up;
+		};
+	};
 };
 
 &venus {

-- 
2.53.0

