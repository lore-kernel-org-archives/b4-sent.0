From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 12 Feb 2026 10:41:25 -0600
Subject: [PATCH v3] arm64: dts: qcom: sm8550: Add UART15
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260212-sm8550-uart15-v3-1-b90405f94bec@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XMSwrCMBSF4a2UOzaSmz4SHbkPcZBX2wvWSlKDU
 rp3046K4PAc+P4Zog/kI5yLGYJPFGl85FEeCrC9fnSekcsbBBcNF1yyOKi65uylw4Q1OxlpXKW
 8rKSDbJ7Bt/Teetdb3j3FaQyfLZ9wff+VEjJkTlnbyqpxyMWlGzTdj3YcYC0lsdOIv1pkbZwoN
 XcelbF7vSzLF6rTw8/oAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770914492; l=2588;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=mR3/JRYkuGO8CBqOJAZJw6sx5dxfOUEZ5hawmrAeEFo=;
 b=aJx/b4n2h90yqY54V5mcmlCBuCfHejlMSqOOiBQPfP7/OiVeqMfSxHKS6XuTbH+o/eXOGYe+e
 WHBxjMNT5ybAF70oCuuZYYKSFNCnE1UA7pn7RFthPmtrVnoGEkoCysF
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
Changes in v3:
- Properly pad reg address
- Link to v2: https://lore.kernel.org/r/20260211-sm8550-uart15-v2-1-bd23a0de18bc@gmail.com

Changes in v2:
- Use QCOM_ICC_TAG_ define in interconnect paths phandle third argument
- Link to v1: https://lore.kernel.org/r/20260207-sm8550-uart15-v1-1-d8ccf746d102@gmail.com
---
 arch/arm64/boot/dts/qcom/sm8550.dtsi | 24 ++++++++++++++++++++++++
 1 file changed, 24 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8550.dtsi b/arch/arm64/boot/dts/qcom/sm8550.dtsi
index e3f93f4f412ded9583a6bc9215185a0daf5f1b57..eebd5f9663edcc91480097aa39e9ca4dc3592dd9 100644
--- a/arch/arm64/boot/dts/qcom/sm8550.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8550.dtsi
@@ -1251,6 +1251,22 @@ &config_noc SLAVE_QUP_2 QCOM_ICC_TAG_ACTIVE_ONLY>,
 				#size-cells = <0>;
 				status = "disabled";
 			};
+
+			uart15: serial@89c000 {
+				compatible = "qcom,geni-uart";
+				reg = <0 0x0089c000 0 0x4000>;
+				clock-names = "se";
+				clocks = <&gcc GCC_QUPV3_WRAP2_S7_CLK>;
+				pinctrl-names = "default";
+				pinctrl-0 = <&qup_uart15_default>;
+				interrupts = <GIC_SPI 462 IRQ_TYPE_LEVEL_HIGH 0>;
+				interconnects = <&clk_virt MASTER_QUP_CORE_2 QCOM_ICC_TAG_ALWAYS
+						 &clk_virt SLAVE_QUP_CORE_2 QCOM_ICC_TAG_ALWAYS>,
+						<&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+						 &config_noc SLAVE_QUP_2 QCOM_ICC_TAG_ACTIVE_ONLY>;
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

