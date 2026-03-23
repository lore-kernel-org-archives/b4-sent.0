From: David Heidelberg <david@ixit.cz>
Date: Tue, 24 Mar 2026 00:20:39 +0100
Subject: [PATCH v2 1/2] arm64: dts: qcom: sdm845-oneplus: Enable NFC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260324-oneplus-nfc-v2-1-3eef052c9bc6@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1699; i=david@ixit.cz;
 h=from:subject:message-id; bh=mZudGkYZcNaSxQ/CeRT/N/ZTIKwpfDRvjxNRkrrFQYc=;
 b=kA0DAAgBYAI/xNNJIHIByyZiAGnBysqjzT3RZ4hWQlBtNfrWQuJv4l7WBFalj4taBGlUe1iVb
 YkCMwQAAQgAHRYhBNd6Cc/u3Cu9U6cEdGACP8TTSSByBQJpwcrKAAoJEGACP8TTSSByqFAP/jvb
 Yb8rdRg+E54QdbNUHrZwwcXYfToCR6H0dAblSOa9Fx+wutG+wpP0tSEGNviuh9IbEafhF444Kh+
 Ul7SlfaC3lPkZCeyvyUK/0UxqNZRQtoTWdOlKbKy8U/r6HbhRe1IL4X67n9JcH1he2j1P6z4kda
 RlsVVH4ZD4qKnGf8cuxqxBZ4vDSUgLQ3Wk2f0cx/FeGS4Hs39/7HDToPYd2TTbV98+7LvqwjFlh
 /JTAG+EF+Jmvqd9aP6pvOPb+gnW4DCciFSgmQWdcehqxapuE8NDDUq7VAua4Wu6fyT3IbneImTm
 6Z7UXjgWfS/GiS+W5fh0e/04jW4v7pdJL7XkVdfZ7gCBixssu6DnvORo+RlCnHyY7EqNxVl9b68
 rIrKJ9W0zFHZi50JcQabD51QB8WMbPzJH0eamdFyDyktUffTDdlgg1zNMwo7ZtTIsonuerJDjHW
 UoXxkRcaYOCQiM9ssziqN7EiGJnm3BBjw8/WUBpgc1oRvkG+95pDwVkduN6SOnfC5VEDvvCubsg
 gjqCikdk595D5aJ6BlIA1+B1brxwNbF151BNWlJDJY5AJsiaC/AA5JfF1ZlIql4ygLz7oYdQBfg
 vYACWWZlBfGP19niXbT1SObsC5j61GB1ZC9xIM8fteqyZqp7wAwh41yYCTTy7QkD0JzwyNUahFB
 YUiN4
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: biemster <l.j.beemster@gmail.com>

Enable NFC controller NXP PN553, which is part of the package NXP NQ330
(NFC + eSE).

Signed-off-by: biemster <l.j.beemster@gmail.com>
Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 31 ++++++++++++++++++++++
 1 file changed, 31 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 5b121ea5520f5..4fbce4233a773 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -392,6 +392,25 @@ &gpu_zap_shader {
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
+		pinctrl-names = "default";
+	};
+};
+
 &i2c10 {
 	status = "okay";
 	clock-frequency = <100000>;
@@ -594,6 +613,11 @@ &qupv3_id_0 {
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
@@ -926,6 +950,13 @@ speaker_default: speaker-default-state {
 		bias-pull-up;
 		output-high;
 	};
+
+	nfc_default: nfc-default-state {
+		pins = "gpio12", "gpio62", "gpio63";
+		function = "gpio";
+		drive-strength = <6>;
+		bias-pull-up;
+	};
 };
 
 &venus {

-- 
2.53.0

