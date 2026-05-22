From: =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
Date: Fri, 22 May 2026 12:43:17 +0200
Subject: [PATCH v2 01/10] arm64: dts: qcom: sc8280xp-arcata: Enable
 backlight
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260522-surface-sp9-5g-for-next-v2-1-dd9d477407f5@gmail.com>
References: <20260522-surface-sp9-5g-for-next-v2-0-dd9d477407f5@gmail.com>
In-Reply-To: <20260522-surface-sp9-5g-for-next-v2-0-dd9d477407f5@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Johan Hovold <johan@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Krzysztof Kozlowski <krzk@kernel.org>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779446623; l=1778;
 i=jerome.debretagne@gmail.com; s=20260520; h=from:subject:message-id;
 bh=eap9AjvywFW4CRahWMk+1c1QXImrokJWDaGBrZsuJlM=;
 b=XPMffnR1UEI6XAIYI8LnzZLMO9Qf+UkXBu7f0lTlr1wcPCEoazlIvaYQIsO++welVcNLcdtRo
 5mPotzXc+0ZCAiPMWlrNYZ5cPwu3GJfXY6FZAHYW1nrSOmYA9fu/kd1
X-Developer-Key: i=jerome.debretagne@gmail.com; a=ed25519;
 pk=3/JYhgYjGg5V9mlFxc0A0+pFiyjsuDB/TtDlNMId9fk=
X-Endpoint-Received: by B4 Relay for jerome.debretagne@gmail.com/20260520 with auth_id=785
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add backlight nodes and enable backlight so that it can be controlled
with the corresponding buttons found on Surface Pro Type Cover keyboards.

Signed-off-by: Jérôme de Bretagne <jerome.debretagne@gmail.com>
---
 .../boot/dts/qcom/sc8280xp-microsoft-arcata.dts    | 27 ++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
index f2b4470d4407fb5b6a3dbac8bc972c010c31bd06..f24f60dc73afea6eeee0ea26472cda3223811752 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
@@ -46,6 +46,15 @@ wcd938x: audio-codec {
 		#sound-dai-cells = <1>;
 	};
 
+	backlight: backlight {
+		compatible = "pwm-backlight";
+		pwms = <&pmc8280c_lpg 3 1000000>;
+		enable-gpios = <&pmc8280_1_gpios 8 GPIO_ACTIVE_HIGH>;
+
+		pinctrl-0 = <&edp_bl_en>, <&edp_bl_pwm>;
+		pinctrl-names = "default";
+	};
+
 	pmic-glink {
 		compatible = "qcom,sc8280xp-pmic-glink", "qcom,pmic-glink";
 
@@ -553,6 +562,10 @@ &pcie4_phy {
 	status = "okay";
 };
 
+&pmc8280c_lpg {
+	status = "okay";
+};
+
 &pmk8280_pon_pwrkey {
 	status = "okay";
 };
@@ -853,6 +866,13 @@ &lpass_tlmm {
 	status = "okay";
 };
 
+&pmc8280_1_gpios {
+	edp_bl_en: edp-bl-en-state {
+		pins = "gpio8";
+		function = "normal";
+	};
+};
+
 &pmc8280_2_gpios {
 	wwan_sw_en: wwan-sw-en-state {
 		pins = "gpio1";
@@ -860,6 +880,13 @@ wwan_sw_en: wwan-sw-en-state {
 	};
 };
 
+&pmc8280c_gpios {
+	edp_bl_pwm: edp-bl-pwm-state {
+		pins = "gpio8";
+		function = "func1";
+	};
+};
+
 &pmr735a_gpios {
 	hastings_reg_en: hastings-reg-en-state {
 		pins = "gpio1";

-- 
2.47.3

