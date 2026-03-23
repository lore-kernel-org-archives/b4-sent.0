From: David Heidelberg <david@ixit.cz>
Date: Tue, 24 Mar 2026 00:20:40 +0100
Subject: [PATCH v2 2/2] arm64: dts: qcom: sdm845-shift-axolotl: Enable NFC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260324-oneplus-nfc-v2-2-3eef052c9bc6@ixit.cz>
References: <20260324-oneplus-nfc-v2-0-3eef052c9bc6@ixit.cz>
In-Reply-To: <20260324-oneplus-nfc-v2-0-3eef052c9bc6@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alexander Martinz <amartinz@shift.eco>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 biemster <l.j.beemster@gmail.com>, netdev@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, oe-linux-nfc@lists.linux.dev, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1522; i=david@ixit.cz;
 h=from:subject:message-id; bh=nWZzFQkA77a3+M7i1r6AFAsRI1+jPOUl0p3IE4kIYfk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpwcrK6dFijYi4UpbhBhIPecppSkhn2JMpk9UGQ
 xH38mse6uCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCacHKygAKCRBgAj/E00kg
 cuLkEADOkzgA6n0vsqx13ZVeQgB6DOUm4GOMyzWTpPa6Sw8aZ7dCfRMTjOsUFjpKDU3goiBy2hq
 zD0I8cBagm+pIj6wq6iH+gGVK3k7Bm5enzHbRuCk/AB/ioaNCzZ5QmOqkZXHsSak0yCaAPvpRCt
 dWmGRWixFtXO1afuayonfgpLjs0OipDQKhLJyK6kAICqnlJzmr0wrfaYPb0JwJqQoZOZLX6Prgk
 D1wjE9chEodPGE7fBm156DLBhuMWANjyKdRYQ7zcfFSjuFqtpo4lg64n4LFQOtL6LeX05m+iOUD
 8bBWdgRVVdwaUWE3VAhd3hglghS/Ow/kiwTI2XG7RpayO44nb8o4hDdhmOc3DuOSrgZJkujfc8I
 jzZSd85OYJwKHNmAKA5Q1WlmAMCVMiSTj+ffbEe0SYOT878ZNAJVWA4dHypR1FSWPdarlv+4ZRF
 QhLbxLE6UzYYdOyBgQgIRYN88qj8U2dk2dcnN0kS9rCsfrdjq+DxAkTfyVu1WUKXFmclyehuIkO
 hurPRwdV94FsDJ+Wql/Muqb821HHL0LrF5a9/hOTOcVW/qWAnke3XAgpdTZfDjk1lyLTkd4yr9w
 OgYxadgfxP60sOkqbsc6PEmbkhti6jhcEn06PyZjzkObpFIXUO2ZiMCL60ZgAbyII5yKyJ/7yJP
 1JSNrk68YPRHT3g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Definition of the NFC.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 33 +++++++++++++++++++++++
 1 file changed, 33 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 51b041f91d3e2..eea63aa170b16 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -431,6 +431,25 @@ &gpu_zap_shader {
 	firmware-name = "qcom/sdm845/SHIFT/axolotl/a630_zap.mbn";
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
+		pinctrl-0 = <&nfc_int_default &nfc_enable_default>;
+		pinctrl-names = "default";
+	};
+};
+
 &i2c5 {
 	status = "okay";
 
@@ -609,6 +628,20 @@ &slpi_pas {
 &tlmm {
 	gpio-reserved-ranges = <0 4>, <81 4>;
 
+	nfc_int_default: nfc-int-default-state {
+		pins = "gpio63";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-pull-up;
+	};
+
+	nfc_enable_default: nfc-enable-default-state {
+		pins = "gpio12", "gpio62";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-pull-up;
+	};
+
 	sde_dsi_active: sde-dsi-active-state {
 		pins = "gpio6", "gpio11";
 		function = "gpio";

-- 
2.53.0

