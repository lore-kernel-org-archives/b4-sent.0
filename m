From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 07 Feb 2026 20:18:17 -0600
Subject: [PATCH] arm64: dts: qcom: sm8550: Add UART15
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260207-sm8550-uart15-v1-1-d8ccf746d102@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDIwNz3eJcC1NTA93SxKISQ1NdyyTzpBQTi1RzE/MUJaCegqLUtMwKsHn
 RsbW1AIDYp4hfAAAA
X-Change-ID: 20260207-sm8550-uart15-9b7bd48e747d
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xilin Wu <wuxilin123@gmail.com>, 
 Molly Sophia <mollysophia379@gmail.com>, 
 Aaron Kling <webgeek1234@gmail.com>, Dmitry Baryshkov <lumag@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770517098; l=2180;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=+xWn2WhENfNTFixOvMZt/E1OqwTYGEWhm9jN/K555L8=;
 b=zsCsd4WBYCQ3ad1VdrolbnoKVsVFbum74EIONdI8W+uuNw2jTQRJAPTixw18xVQ+TKSvD2Lhd
 fEhjj/F48a5CvoECb62xOgC4H9MVzRkaO8R7j3swTzrk+cPP15Fppkl
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Xilin Wu <wuxilin123@gmail.com>

Add uart15 node for UART bus present on sm8550 SoC.

Signed-off-by: Molly Sophia <mollysophia379@gmail.com>
Signed-off-by: Xilin Wu <wuxilin123@gmail.com>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@linaro.org>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
This patch was originally submitted as part of a series to support the
AYN Odin 2 [0]. That series stalled, so submitting separately.

[0] https://lore.kernel.org/all/20240424-ayn-odin2-initial-v1-0-e0aa05c991fd@gmail.com/
---
 arch/arm64/boot/dts/qcom/sm8550.dtsi | 24 ++++++++++++++++++++++++
 1 file changed, 24 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8550.dtsi b/arch/arm64/boot/dts/qcom/sm8550.dtsi
index e3f93f4f412ded9583a6bc9215185a0daf5f1b57..ec172c22d928c4d73313c7b4980807760995ecaa 100644
--- a/arch/arm64/boot/dts/qcom/sm8550.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8550.dtsi
@@ -1251,6 +1251,22 @@ &config_noc SLAVE_QUP_2 QCOM_ICC_TAG_ACTIVE_ONLY>,
 				#size-cells = <0>;
 				status = "disabled";
 			};
+
+			uart15: serial@89c000 {
+				compatible = "qcom,geni-uart";
+				reg = <0 0x89c000 0 0x4000>;
+				clock-names = "se";
+				clocks = <&gcc GCC_QUPV3_WRAP2_S7_CLK>;
+				pinctrl-names = "default";
+				pinctrl-0 = <&qup_uart15_default>;
+				interrupts = <GIC_SPI 462 IRQ_TYPE_LEVEL_HIGH 0>;
+				interconnects = <&clk_virt MASTER_QUP_CORE_2 0
+						 &clk_virt SLAVE_QUP_CORE_2 0>,
+						<&gem_noc MASTER_APPSS_PROC 0
+						 &config_noc SLAVE_QUP_2 0>;
+				interconnect-names = "qup-core", "qup-config";
+				status = "disabled";
+			};
 		};
 
 		i2c_master_hub_0: geniqup@9c0000 {
@@ -5095,6 +5111,14 @@ qup_uart14_cts_rts: qup-uart14-cts-rts-state {
 				bias-pull-down;
 			};
 
+			qup_uart15_default: qup-uart15-default-state {
+				/* TX, RX */
+				pins = "gpio74", "gpio75";
+				function = "qup2_se7";
+				drive-strength = <2>;
+				bias-pull-up;
+			};
+
 			sdc2_sleep: sdc2-sleep-state {
 				clk-pins {
 					pins = "sdc2_clk";

---
base-commit: 9845cf73f7db6094c0d8419d6adb848028f4a921
change-id: 20260207-sm8550-uart15-9b7bd48e747d

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

