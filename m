From: David Heidelberg <david@ixit.cz>
Date: Fri, 03 Apr 2026 19:08:40 +0200
Subject: [PATCH WIP v3 11/11] arm64: dts: qcom: sdm845-google: Add STM FTS
 touchscreen support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-stmfts5-v3-11-5da768cfd201@ixit.cz>
References: <20260403-stmfts5-v3-0-5da768cfd201@ixit.cz>
In-Reply-To: <20260403-stmfts5-v3-0-5da768cfd201@ixit.cz>
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
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1795; i=david@ixit.cz;
 h=from:subject:message-id; bh=TQFq+PWyeQhZg/mK5NDBcGQfwDmMOnudDkXhMTWZo0k=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpz/QQaX/GLHPgoCPSGD4vNqAN8c8Vp77YqqTST
 i8q9/7tueKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac/0EAAKCRBgAj/E00kg
 cnt3EAC9+/iOdH/C6Es8Y3zt7BHJHf73YRjGK9TxmQWh0Se913LW/Ngdu9eFlAJWY68ZVPNjmVQ
 fz1LCUrEtsNRrP6s7heETZ+K/mqf/w2eUlTxqf1HET5boZNzsCktlhmZdoKCssdMlnv43oebS10
 I5Vk+JD8virH49O9TKrew6a+jI1giQqXSwSz3LfCGo0TaVTPYhmui1VI50ths7OddPmZ6HXHi3N
 XV4Gz2OWsBluDhNmPrCVBCwFXcjNolDz5jpeZcUEAlIczTmx0NdhGx+6djhB0HZ3We7WsbdyjL2
 6AGdgeIbfDwb/Wkx5YjSFgk+3fb+aqDi1DCobwtW12vOmp4E1LUNq8Vn2Cu8k8Jvpd5HccMpjDK
 Yk1r5QGsPcrwnH/9LX69W+5nT74tYVGtULwB8Rkd5q9E0QFp0XST3zfBGdT+RwuJL7PhHuGMh6U
 O1vX5VOfABaqlEAVllwLw06IcmAUPhtO229992eu/kc3i5RAdybgdklByl4cMq8qTwdcuCB3kbB
 DC1Fj6lCVj5NJ27yaa4GiQ0ZlfC1/cHmBYNhnk+9oAe12lDGa0YoZruthb6uyZMSbDb2qgeEqY/
 zurHwlr0x55LAv4y5pM00T9QB3Rc+fGWK4RJoWy+zJLIyrQwKTaDeZxf3LtdeO6ZKtpbf5D7zvD
 iYVCEiUAlCVnGyg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Petr Hodina <petr.hodina@protonmail.com>

Basic touchscreen connected to second i2c bus.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts | 19 ++++++++++++++++++-
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi  |  2 +-
 2 files changed, 19 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
index fa89be500fb85..8fb988130b551 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
@@ -26,7 +26,24 @@ &i2c2 {
 
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
+		avdd-supply = <&vreg_l14a_1p8>;
+		vdd-supply = <&vreg_l19a_3p3>;
+
+		touchscreen-size-x = <1080>;
+		touchscreen-size-y = <2160>;
+	};
 };
 
 &mdss_dsi0 {
diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 6930066857768..4653c63ec26d2 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -466,7 +466,7 @@ touchscreen_reset: ts-reset-state {
 		bias-pull-up;
 	};
 
-	touchscreen_pins: ts-pins-gpio-state {
+	touchscreen_irq_n: ts-irq-n-gpio-state {
 		pins = "gpio125";
 		function = "gpio";
 		drive-strength = <2>;

-- 
2.53.0

