From: David Heidelberg <david@ixit.cz>
Date: Mon, 10 Aug 2026 17:21:42 +0200
Subject: [PATCH v5 3/3] arm64: dts: qcom: sdm845-google: Add STM FTS
 touchscreen support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-stmfts5-v5-3-0c737d929976@ixit.cz>
References: <20260810-stmfts5-v5-0-0c737d929976@ixit.cz>
In-Reply-To: <20260810-stmfts5-v5-0-0c737d929976@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, linux-input@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2317; i=david@ixit.cz;
 h=from:subject:message-id; bh=d6YK9/d3irC15CmqRTIkg+K9fEKI6TWqUJRSUAdOn6Q=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqeeyNsdiADDYBlWx/cvqY0/5sRpxPIa7fit5dT
 IjmHoCYePmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCannsjQAKCRBgAj/E00kg
 cpWVD/9E+vEBGkXkM8+Icj5A+8/3CIY0oIa5AxZPuPiDkjbj+hHLFMQPNEuE707RuXuftQIMnYJ
 +JzV5rSNWMWkqQMMNXEJHB/EBDLuMc8nOucjFNnU9ejWWAObJhSx25qXeWHeJQLclGEtvun/GOR
 qBB56PLN2lEVluuXHzATSHyIcHpJWpJMCMyLlJdefNZ7PXwA6U38LEBdQ/mkdwqMqn42NK4whmn
 Tq8IksgVenoFfwvq9Z3txKYfKqp3qHFFG7MXFzEZextTw8t/ljL8CBNekk4R92NaEXKqmDuMvXD
 uvstkdstxIWOj/SOlwdTopmiuZSFJuEz3i9vS8NRiiTYrbwEEvKG6RdfesxyrjgNul+kKxRxM4G
 k2ho3VI6mhGPT6V/Yi7YAAU0NXnnsA52ZEhquJeA8C7hIVMTG6rLJ+m4jq04yGElAYUIUo+Zvo2
 4hjFoicVbeX/5TOHAsSRkeruabsGgG7+lO5ONFDomQmO2vXvTS+TcYGZ3RuhuBPWqct1yfklZo2
 tH35Bl31NoHvUpp7o5Oc+57DfjnZQbOhkUG4XBbFEQF0sYihvagogeIrLCCLIvfjwkjtPxwTkAS
 A0QMJc6zsIknEh3lSuDdTctwdS7uP2wU4GJPUngDtWxIPiQ/TH01P/ocmmLgApjNbzbQUC9HSju
 ZqCPrRV6CM+3BdQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Petr Hodina <petr.hodina@protonmail.com>

Basic touchscreen connected to second i2c bus.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts | 19 ++++++++++++++++++-
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi  |  2 +-
 2 files changed, 19 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
index fa89be500fb85..51c835dca43f1 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
@@ -21,17 +21,34 @@ &framebuffer0 {
 	stride = <(1080 * 4)>;
 };
 
 &i2c2 {
 	clock-frequency = <1000000>;
 
 	status = "okay";
 
-	/* ST,FTS @ 49 */
+	touchscreen@49 {
+		compatible = "st,stmfts5";
+		reg = <0x49>;
+
+		pinctrl-0 = <&touchscreen_irq_n>, <&touchscreen_reset>;
+		pinctrl-names = "default";
+
+		interrupts-extended = <&tlmm 125 IRQ_TYPE_LEVEL_LOW>;
+
+		mode-switch-gpios = <&tlmm 136 GPIO_ACTIVE_HIGH>;
+		reset-gpios = <&tlmm 99 GPIO_ACTIVE_LOW>;
+
+		avdd-supply = <&vreg_l19a_3p3>;
+		vdd-supply = <&vreg_l14a_1p8>;
+
+		touchscreen-size-x = <1080>;
+		touchscreen-size-y = <2160>;
+	};
 };
 
 &mdss_dsi0 {
 	vdda-supply = <&vdda_mipi_dsi0_1p2>;
 
 	status = "okay";
 
 	panel@0 {
diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 9368fd6b87515..bd3b5d7b7396e 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -492,17 +492,17 @@ nfc_enable_default: nfc-enable-default-state {
 
 	touchscreen_reset: ts-reset-state {
 		pins = "gpio99";
 		function = "gpio";
 		drive-strength = <8>;
 		bias-pull-up;
 	};
 
-	touchscreen_pins: ts-pins-gpio-state {
+	touchscreen_irq_n: ts-irq-n-gpio-state {
 		pins = "gpio125";
 		function = "gpio";
 		drive-strength = <2>;
 		bias-disable;
 	};
 
 	touchscreen_i2c_pins: qup-i2c2-gpio-state {
 		pins = "gpio27", "gpio28";

-- 
2.55.0

