From: David Heidelberg <david@ixit.cz>
Date: Sun, 22 Mar 2026 15:24:19 +0100
Subject: [PATCH QUESTION 1/2] arm64: dts: qcom: sdm845-oneplus: Enable NFC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260322-oneplus-nfc-v1-1-5f22f544f0e2@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1590; i=david@ixit.cz;
 h=from:subject:message-id; bh=B1C0GWCfqNHFWEdIAzeVJqcuVPnC+PV2R/DBk8wqZEA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpv/uUrj18m0kn1GKpoXoftxMYSLKQDCiSUyZY+
 HsoiCa3+16JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCab/7lAAKCRBgAj/E00kg
 chU0D/0S4ZkvpDlFswm/YVkPovbK0CMXvwEphCN1YnahYdU0y72Hjqf/YZRgK5RPET+22p7rzSE
 BWolE7URerc38MO7O9uxJso0yekaNLdr2TvN18V5tX4JmrMah7HdINoVzIcyqK0xWMa4Cg09Ywu
 6+WFqtEOj9l26Lj7Xc3pJqRUCGdGyqHdj7Ny5mogStApQmP72/z3SisOYHyTncx5DpvodRHkvX2
 WKIhsatNN73X/giocFL277Z+nMqa6YKZRyuEy24manxshZQNnOiMfbMqkQ/FoDFVljU6jv++sjP
 XLRuFE1nhxKGNczYVkkweA9eK4zMJHMmEHhIsJeGq0gUTx/UxVXtExstEdtjdLGJfWDJ84l5vEi
 LYNdltdZkXNzmG9LIgUufxBCjsKbH6/OAjM5kmrpJRLb2xcOe4hWbf5rwVPYWY8fcneCjujD5jl
 05tiAY8m3Up/Qy+4VyUSBlPQFPqR3wpfViywNxvyY80rFVzkLBBjTZX3HxHmFwFCYz0hCTak5h+
 G1eXk525aegw/PJ5rE15hVlpxVCIGEGIH6iyoTtCIMYHK9yBnqgZFm8qUJ+HP62Ofh+GghqKIOs
 2jbqCc2drFi88cRBooZx89gkjKL2zY1rMggDDerGkE0+e83CXavKHcGP1WdJhHP1w2gQRhDEpaw
 iGlXUjR4C5RCKlg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: biemster <l.j.beemster@gmail.com>

Definition of the NFC.

Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 32 ++++++++++++++++++++++
 1 file changed, 32 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 5b121ea5520f5..34f476299b114 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -392,6 +392,26 @@ &gpu_zap_shader {
 	firmware-name = "qcom/sdm845/OnePlus/enchilada/a630_zap.mbn";
 };
 
+&i2c3 {
+	clock-frequency = <400000>;
+
+	status = "okay";
+
+	nfc@28 {
+		compatible = "nxp,nxp-nci-i2c";
+		reg = <0x28>;
+
+		interrupt-parent = <&tlmm>;
+		interrupts = <63 IRQ_TYPE_EDGE_RISING>;
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
@@ -594,6 +614,11 @@ &qupv3_id_0 {
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
@@ -926,6 +951,13 @@ speaker_default: speaker-default-state {
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

