From: David Heidelberg <david@ixit.cz>
Date: Sun, 22 Mar 2026 15:24:20 +0100
Subject: [PATCH QUESTION 2/2] arm64: dts: qcom: sdm845-shift-axolotl:
 Enable NFC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260322-oneplus-nfc-v1-2-5f22f544f0e2@ixit.cz>
References: <20260322-oneplus-nfc-v1-0-5f22f544f0e2@ixit.cz>
In-Reply-To: <20260322-oneplus-nfc-v1-0-5f22f544f0e2@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 biemster <l.j.beemster@gmail.com>, netdev@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, oe-linux-nfc@lists.linux.dev, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1522; i=david@ixit.cz;
 h=from:subject:message-id; bh=bg/8Mn64amhNeliB/CDjN88OEUAaoSKykTAgAGciekI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpv/uUH1GaubGxzAbpeIoZHLVihTMq2aub8E8R/
 HEKSiFPJvCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCab/7lAAKCRBgAj/E00kg
 ciRmD/4ocnaCQSjo5z+kVKbzx56vvvy5UY4RX218IPBYHq7G+VUq2b5ofKiz3WvOb5kGXEbsJoi
 AJF7U8/PLvcEvOaylm8BOlLjBM5BQ0XsTRzIRKg9emYKmTpXgDjnfGijCzAhL6FdsEVbcwjp0bL
 NUDyy9p7ZN2cjA1HZJ0T0d6TuIrgDb5vTILZQ0lgL/f57A0lfudJkVoFF0dpDbLrjdpZgRfDqF1
 FWzKNN2SkFCDKj2J8tv4lGgu4XUnLPIGVHrhtx4Z/GtazO7owFj1j+fKC5CiNifsQFcbj0eV/Np
 BZ6HLiTrr/tQ2cKt+YN6MRIhMt8YGX7kJT3wzbkeVPf57QEznZK3RRRhB1nAQw4fX1s1l+zISgQ
 CASZl+kmtMO/1k89mVvgQVBr505ApP1ildlMeOJzmUlVI1ikWviKvogH2Nck81X6RTnBFRkUG+P
 PvNwfj00GgXktjexXgH41LTlijfDc7+AZFzeOYuHpJblsicWanHo0cUp2vEq3lK6LgBlj7m9pvT
 NdSryJeqI5B0gSd7Z4ziZAotDvKaGZXcOVx7Ngrhe4sW/UAtvqOAo2+R7/BaHBYTXYzUQHe05sG
 Rsf/6jVVUs8PeQq6NILxAEFVWhouE6xRjZUlib+y4+nyaTkoKbl5Sopp7GmTrgSPpC6WqJLlJDe
 2g7ekbKaDy4+wtw==
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
index 51b041f91d3e2..bc336584c9fb9 100644
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
+		compatible = "nxp,nq310", "nxp,nxp-nci-i2c";
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

