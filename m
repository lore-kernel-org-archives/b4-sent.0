From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Sun, 17 May 2026 20:14:23 +0700
Subject: [PATCH v3 4/4] arm64: dts: qcom: sm8550: add UART11 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260517-pocketds-v3-4-d5910c801756@gmail.com>
References: <20260517-pocketds-v3-0-d5910c801756@gmail.com>
In-Reply-To: <20260517-pocketds-v3-0-d5910c801756@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779023659; l=1968;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=g2a8yIPr/NXyccP9E9kuGm/v0j5P1EWZoxrYzuxfC0w=;
 b=FLSZ6DNRRt17NzQZy35jonoFjMneO5VLh/PdOc3lMBEyZu2ZHKF8MMhjBJyS59F/s2F0j4Iwv
 0CGASmlMSMfDCQAxkxG5EPnbu+dRZts1ogvZlSRpTgB9nH5AoWb+uA+
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the QUPv3_2 SE3 High Speed UART (UART11) controller node and its
default pinctrl state to sm8550.dtsi, so boards can enable it through
&uart11 instead of open-coding the controller in their own dts.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
 arch/arm64/boot/dts/qcom/sm8550.dtsi | 26 ++++++++++++++++++++++++++
 1 file changed, 26 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8550.dtsi b/arch/arm64/boot/dts/qcom/sm8550.dtsi
index a9c678fc9cb2..3e71701b18ff 100644
--- a/arch/arm64/boot/dts/qcom/sm8550.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8550.dtsi
@@ -1084,6 +1084,24 @@ &config_noc SLAVE_QUP_2 QCOM_ICC_TAG_ACTIVE_ONLY>,
 				status = "disabled";
 			};
 
+			uart11: serial@88c000 {
+				compatible = "qcom,geni-uart";
+				reg = <0 0x0088c000 0 0x4000>;
+				clock-names = "se";
+				clocks = <&gcc GCC_QUPV3_WRAP2_S3_CLK>;
+				interrupts = <GIC_SPI 585 IRQ_TYPE_LEVEL_HIGH 0>;
+				pinctrl-names = "default";
+				pinctrl-0 = <&qup_uart11_default>;
+				interconnects = <&clk_virt MASTER_QUP_CORE_2 QCOM_ICC_TAG_ALWAYS
+						 &clk_virt SLAVE_QUP_CORE_2 QCOM_ICC_TAG_ALWAYS>,
+						<&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+						 &config_noc SLAVE_QUP_2 QCOM_ICC_TAG_ACTIVE_ONLY>;
+				interconnect-names = "qup-core", "qup-config";
+				operating-points-v2 = <&qup_opp_table_100mhz>;
+				power-domains = <&rpmhpd RPMHPD_CX>;
+				status = "disabled";
+			};
+
 			i2c12: i2c@890000 {
 				compatible = "qcom,geni-i2c";
 				reg = <0 0x00890000 0 0x4000>;
@@ -5102,6 +5120,14 @@ qup_uart7_default: qup-uart7-default-state {
 				bias-disable;
 			};
 
+			qup_uart11_default: qup-uart11-default-state {
+				/* TX, RX */
+				pins = "gpio70", "gpio71";
+				function = "qup2_se3";
+				drive-strength = <2>;
+				bias-disable;
+			};
+
 			qup_uart14_default: qup-uart14-default-state {
 				/* TX, RX */
 				pins = "gpio78", "gpio79";

-- 
2.54.0

