From: David Heidelberg <david@ixit.cz>
Date: Fri, 03 Apr 2026 15:58:49 +0200
Subject: [PATCH v3 4/5] arm64: dts: qcom: sdm845-shift-axolotl: Enable NFC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-oneplus-nfc-v3-4-fbdce57d63c1@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1823; i=david@ixit.cz;
 h=from:subject:message-id; bh=s22pJ5rTEtiXwSmEEiYHretFehUi77jUBIFY7CCGWZE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpz8eb82gH++yptm6T8ADjzBk2D5EZflA3/byGV
 1ebat1IbiiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac/HmwAKCRBgAj/E00kg
 ci5FD/kBnCx6eNjtESPBu0C549OsGknPfQK1othvKtMzd6Z+vLl/Z1Z3ugvieA/f9w+e5w22n8f
 ovkUW1jx7Y2+2y0w7wx6gcS6oO52HG2d4D8GlhrGUxJXXpd1/vxz1Mn3To2o0fP+DLutnQI/k4A
 /apctd1AaoXKSmx9IG7vw6eFIYTmH/K1i9/uDIP3ZX4034FPKcqBSyeqwyw3V1oUaLkAgjrTcJ6
 rw2zzAmdEq91c78pTFuc4Bx22pEOSmdfXRBlIuBDeSbdDytI+S+LuzMjbDA428128GouJVx9wwW
 N9Ifaq/f26mvwNNrN7EmpuS7+H/yvIcDv48hLxInxNPr3ftqx+gsOJ4LS/Sc5VOpjnOCTBePj1X
 Mnx0D4nEPxCIhYtxI+zMJidbAfs9kT1X6630r5r3YaPbPp7VI6+pWVzM1Mbu+kBv84BLWPy5Tl0
 xSmFawwM+RVYYY8BON5qh17SZtwGEAcX65xxC9uVXnmPyOsqKmv3wayxazSQlJErcXqxZ/SVoNp
 55L/qToeWFqvELDOyUFD3tnLMqNE/BCC4WwlyDWhriCP0u9Fv0usFeb28N5jXQKa7nNw3zgmV/L
 DGncZq8l8C9viTYjjxXPpbidGE6iGm/gIjPHEmDOqDuM6Y75vBbG6xKuecJ1zImeCIYM3KNptd9
 /f9WSc6bLIioWEg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable NFC controller NXP PN553.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 52 +++++++++++++++++++++++
 1 file changed, 52 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 783d66cf5b0f8..101597c666332 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -431,6 +431,26 @@ &gpu_zap_shader {
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
+		pinctrl-0 = <&nfc_default>;
+		pinctrl-1 = <&nfc_sleep>;
+		pinctrl-names = "default", "sleep";
+	};
+};
+
 &i2c5 {
 	status = "okay";
 
@@ -609,6 +629,38 @@ &slpi_pas {
 &tlmm {
 	gpio-reserved-ranges = <0 4>, <81 4>;
 
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
+
 	sde_dsi_active: sde-dsi-active-state {
 		pins = "gpio6", "gpio11";
 		function = "gpio";

-- 
2.53.0

