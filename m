From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 05 Jun 2026 17:49:39 -0500
Subject: [PATCH] arm64: dts: qcom: sm8750: Add UART15
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-sm8750-uart15-v1-1-93e660722e61@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDMwNT3eJcC3NTA93SxKISQ1PdVIsk41QDi9Q0c+NkJaCegqLUtMwKsHn
 RsbW1AOmha7RfAAAA
X-Change-ID: 20260605-sm8750-uart15-e8b3e08ef73c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Teguh Sobirin <teguh@sobir.in>, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780699788; l=1912;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=cnBDgWatb+kdVa9LW2HFaAdpkUIfcK/vxUADNmoNfHU=;
 b=QoVvI1ABaISVQU2ftzSbF0cIwLI2Ra8zvNpyX3GCxMWG+S/D/GizN1QTg1ySudIsGE5O9fmF0
 79SPeJapK0pDz3lnRGFk4x5AmM2U6TLDCrCXZ93dzcCkivY8yTNi2nM
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Teguh Sobirin <teguh@sobir.in>

Add uart15 node for the UART bus present on the sm8750 SoC.

Signed-off-by: Teguh Sobirin <teguh@sobir.in>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
arm64: dts: qcom: sm8750: Add UART15
---
 arch/arm64/boot/dts/qcom/sm8750.dtsi | 30 ++++++++++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8750.dtsi b/arch/arm64/boot/dts/qcom/sm8750.dtsi
index fafed417c66fc2..7591ebb7086f91 100644
--- a/arch/arm64/boot/dts/qcom/sm8750.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8750.dtsi
@@ -1218,6 +1218,28 @@ &config_noc SLAVE_QUP_2 QCOM_ICC_TAG_ALWAYS>,
 
 				status = "disabled";
 			};
+
+			uart15: serial@89c000 {
+				compatible = "qcom,geni-uart";
+				reg = <0x0 0x0089c000 0x0 0x4000>;
+
+				interrupts = <GIC_SPI 462 IRQ_TYPE_LEVEL_HIGH>;
+
+				clocks = <&gcc GCC_QUPV3_WRAP2_S7_CLK>;
+				clock-names = "se";
+
+				interconnects = <&clk_virt MASTER_QUP_CORE_2 QCOM_ICC_TAG_ALWAYS
+						 &clk_virt SLAVE_QUP_CORE_2 QCOM_ICC_TAG_ALWAYS>,
+						<&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ALWAYS
+						 &config_noc SLAVE_QUP_2 QCOM_ICC_TAG_ALWAYS>;
+				interconnect-names = "qup-core",
+						     "qup-config";
+
+				pinctrl-0 = <&qup_uart15_default>;
+				pinctrl-names = "default";
+
+				status = "disabled";
+			};
 		};
 
 		i2c_master_hub_0: geniqup@9c0000 {
@@ -4055,6 +4077,14 @@ qup_uart14_cts_rts: qup-uart14-cts-rts-state {
 				bias-pull-down;
 			};
 
+			qup_uart15_default: qup-uart15-default-state {
+				/* TX, RX */
+				pins = "gpio30", "gpio31";
+				function = "qup2_se7";
+				drive-strength = <2>;
+				bias-pull-up;
+			};
+
 			sdc2_sleep: sdc2-sleep-state {
 				clk-pins {
 					pins = "sdc2_clk";

---
base-commit: 6e845bcb78c95af935094040bd4edc3c2b6dd784
change-id: 20260605-sm8750-uart15-e8b3e08ef73c

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

