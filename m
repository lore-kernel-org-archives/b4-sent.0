From: David Heidelberg <david@ixit.cz>
Date: Fri, 03 Apr 2026 15:58:50 +0200
Subject: [PATCH v3 5/5] arm64: dts: qcom: sdm845-google-common: Enable NFC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-oneplus-nfc-v3-5-fbdce57d63c1@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1608; i=david@ixit.cz;
 h=from:subject:message-id; bh=GYUicW68fG/miT4fpCJcJRDrwDdpD5Q04+imeBK0nmc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpz8eb2K+Gwlr9QWsSM1v9oBdK1S2SAvB9/E4xL
 2LhhQW1i5+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac/HmwAKCRBgAj/E00kg
 cq9HD/9AkeypBBRzR+ukT0gktwlzP53iCY0ZVU6vxr8NMrhKAt7MMJdejsJkaZMB8YJ0O34Rofl
 ehwKaU7Mkr7ht+lHkelAZr4lKt2KZtLFcn6vjf1YUEY/Kui3mQcuDkn+moJgZ9oHLnVKPyZNMi9
 Ol7aUjiMw4H70Me4CJLRXSWEhLsSypauGR2+7zhbbo8b9AzXkyNT23/kB262F1eShNlOIjTAlvS
 cvvdSGYfup2iYVLW52Q/WaDB/rgYLMrK7StwEJwbHoAYCbEd0/dariNnabqjgdGyaTI7eM7XMdx
 AvuAXrS9tcbYhJiGzltr9ZjAaWr4xUMyyCuvSoL4RcnkZPnbD71cA6QBYQy1/TXrNNw1qhNHn0t
 xy0jfblAyyAf3JQmq34W2pr9ke1xH7qqGBF42bieM1r06YMNntOWDKCxGlV4w314Zp1z8dFjfcL
 FFit9f4D0oRkf2QNNLWPSaowEtcyO4UYzRE6g98buIRNvFvUmmOtyFN3FWVKyD0hQBDWBnnbD87
 j92E5424S0J71SY2WHshTdWEra3LY4ekJK3TuxKj4y8lbgMv6vu46xcaoq1vMfoMTfKpqai6fAR
 BsKO2HSZYMAm8F2R3FLRlV3G0jJ7OLbwBOZV2owAl5WjVU/zoEN9ijbFmeVziddLGnK7fVb+o22
 td4aUNF0xxAcFdg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable NFC controller NXP PN557.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 31 ++++++++++++++++++++++
 1 file changed, 31 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 6930066857768..b2dc0327dff85 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -391,6 +391,23 @@ &gpu_zap_shader {
 	firmware-name = "qcom/sdm845/Google/blueline/a630_zap.mbn";
 };
 
+&i2c3 {
+	status = "okay";
+
+	nfc@28 {
+		compatible = "nxp,pn557", "nxp,nxp-nci-i2c";
+		reg = <0x28>;
+
+		interrupts-extended = <&tlmm 63 IRQ_TYPE_EDGE_RISING>;
+
+		enable-gpios = <&tlmm 25 GPIO_ACTIVE_HIGH>;
+		firmware-gpios = <&tlmm 79 GPIO_ACTIVE_HIGH>;
+
+		pinctrl-0 = <&nfc_int_default &nfc_enable_default>;
+		pinctrl-names = "default";
+	};
+};
+
 &i2c12 {
 	/* Bottom spkr (right) CS35L36 @ 40 */
 
@@ -459,6 +476,20 @@ &tlmm {
 	gpio-reserved-ranges = < 0 4>, /* SPI (Intel MNH Pixel Visual Core) */
 			       <81 4>; /* SPI (most likely Fingerprint Cards FPC1075) */
 
+	nfc_int_default: nfc-int-default-state {
+		pins = "gpio63";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-pull-down;
+	};
+
+	nfc_enable_default: nfc-enable-default-state {
+		pins = "gpio25", "gpio79";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-pull-down;
+	};
+
 	touchscreen_reset: ts-reset-state {
 		pins = "gpio99";
 		function = "gpio";

-- 
2.53.0

