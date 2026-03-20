From: David Heidelberg <david@ixit.cz>
Date: Fri, 20 Mar 2026 17:29:05 +0100
Subject: [PATCH 1/3] arm64: dts: qcom: sdm845-shift-axolotl: Enable sdcard
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260320-axolotl-misc-p1-v1-1-89c9b5ecb26e@ixit.cz>
References: <20260320-axolotl-misc-p1-v1-0-89c9b5ecb26e@ixit.cz>
In-Reply-To: <20260320-axolotl-misc-p1-v1-0-89c9b5ecb26e@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dylan Van Assche <me@dylanvanassche.be>
Cc: linux-arm-msm@vger.kernel.org, Petr Hodina <phodina@protonmail.com>, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Casey Connolly <casey.connolly@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1789; i=david@ixit.cz;
 h=from:subject:message-id; bh=jZO6RkyutFnu2NFrOOzkyEjsVHSpesifd5WE85Z/RmE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpvXXRdYH4W+qUXzbbUndVRsatOwXb2a309gCvv
 zqPM5oESviJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCab110QAKCRBgAj/E00kg
 clUlD/48j1vAEhcWFXyxiu/UVuPgCrqekUX4DO1dS63Tn6e2NYb1oQfFFN8b2/xqGHFAVPqS0Um
 7wL1AGSKToVdx7JEDCDMoZ7VYui9FRb857Yc3XxSgpCgEJahc7MOOOt80AIsL595vk7ssPsB+gK
 NR9waaudEvul7DtLTFcVq5zQlFNcqdpfnRXxcVM3bz2mHGZeQO7qptjc4bXEKPFW/j8Y9SUsjWq
 Rpgye1oI248d0GaFJheG9pdeGGbIxL/ZdoDi9xCOM86dWnCMeS+zGbMmQzd1rhGkoZcn8TZJrvl
 FzJCPjVRAH+5lgmuGoKEq3LEeCMd0tvxrS/lNo3Lkd3kcjsVjHmDRJbcErFHt8YNMUjUkp0R1mV
 O8u9Paw/jB2Wbkga4AopT17YQpcPS2LC+d4ql5U0/theUzFQN2rfqEUgqgWBlfKfi9qyTnc0Qcb
 UOc/xDtPjG/JUQOGf8dgz7BijLD0CZEIsFxiPLCFZPeR0jmpONT8DfFU6+sq6C8V3V8eoBAtquM
 wjsiC3rd2HFUrkksLXdN/NsjKyeTg0P/XfBxdKjatpkoqfR8hqhQqIfQ3rE7PPnIKOoJUkMVVXt
 eNMNoio5yq3P1+Fb2+MsfwLyhFNCxZPGrzm3SFZsV4c2R49cO1vbHnU061XNCbLINeuUVGGoMfy
 FjKYKvgRLnY945w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

The SHIFT6mq features an sdcard slot, add it.

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 43 +++++++++++++++++++++++
 1 file changed, 43 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 51b041f91d3e2..1f21da310b762 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -600,6 +600,23 @@ &qupv3_id_1 {
 	status = "okay";
 };
 
+&sdhc_2 {
+	status = "okay";
+
+	pinctrl-names = "default";
+	pinctrl-0 = <&sdc2_default_state &sdc2_card_det_n>;
+
+	vmmc-supply = <&vreg_l21a_2p95>;
+	vqmmc-supply = <&vreg_l13a_2p95>;
+
+	bus-width = <4>;
+	/* card detection is broken, but because the battery must be removed
+	 * to insert the card, we use this rather than the broken-cd property
+	 * which would just waste CPU cycles polling.
+	 */
+	non-removable;
+};
+
 &slpi_pas {
 	firmware-name = "qcom/sdm845/SHIFT/axolotl/slpi.mbn";
 
@@ -609,6 +626,32 @@ &slpi_pas {
 &tlmm {
 	gpio-reserved-ranges = <0 4>, <81 4>;
 
+	sdc2_default_state: sdc2-default-state {
+		clk-pins {
+			pins = "sdc2_clk";
+			bias-disable;
+			drive-strength = <16>;
+		};
+
+		cmd-pins {
+			pins = "sdc2_cmd";
+			bias-pull-up;
+			drive-strength = <10>;
+		};
+
+		data-pins {
+			pins = "sdc2_data";
+			bias-pull-up;
+			drive-strength = <10>;
+		};
+	};
+
+	sdc2_card_det_n: sd-card-det-n-state {
+		pins = "gpio126";
+		function = "gpio";
+		bias-pull-up;
+	};
+
 	sde_dsi_active: sde-dsi-active-state {
 		pins = "gpio6", "gpio11";
 		function = "gpio";

-- 
2.53.0

