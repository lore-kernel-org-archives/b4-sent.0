From: Rudraksha Gupta <guptarud@gmail.com>
Date: Wed, 31 Jan 2024 01:04:46 -0800
Subject: [PATCH v2 1/2] ARM: dts: qcom: msm8960: Add gsbi3 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240131-expressatt_mxt224s_touchscreen-v2-1-4463ae0414b5@gmail.com>
References: <20240131-expressatt_mxt224s_touchscreen-v2-0-4463ae0414b5@gmail.com>
In-Reply-To: <20240131-expressatt_mxt224s_touchscreen-v2-0-4463ae0414b5@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706691886; l=2107;
 i=guptarud@gmail.com; s=20240120; h=from:subject:message-id;
 bh=G6XPs19Hk+i3uuDKqNqjvb4ePyJrYWEvOCZGE4iK36g=;
 b=01IhAm1m43JwSoG5qVDfjpK8EYKpRI+iitc0eh5r8bOoHY63CcTmbb+icdnyO8w6DpwEG2+9h
 MKJA/e9ZOBMC/McxNWDd0JY00M+xsKWcXn+e7C9iU3zQYOWdu2t+XwZ
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=RGmug3GRHS4XYTXDcT2VrlTGXlEF2gY4L9/swGIU1ko=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240120 with auth_id=114
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Copy gsbi3 node from qcom-apq8064.dtsi and set appropriate properties

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 arch/arm/boot/dts/qcom/qcom-msm8960-pins.dtsi | 21 ++++++++++++++++++++
 arch/arm/boot/dts/qcom/qcom-msm8960.dtsi      | 28 +++++++++++++++++++++++++++
 2 files changed, 49 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-pins.dtsi b/arch/arm/boot/dts/qcom/qcom-msm8960-pins.dtsi
new file mode 100644
index 000000000000..4fa982771288
--- /dev/null
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-pins.dtsi
@@ -0,0 +1,21 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+&msmgpio {
+	i2c3_default_state: i2c3-default-state {
+		i2c3-pins {
+			pins = "gpio16", "gpio17";
+			function = "gsbi3";
+			drive-strength = <8>;
+			bias-disable;
+		};
+	};
+
+	i2c3_sleep_state: i2c3-sleep-state {
+		i2c3-pins {
+			pins = "gpio16", "gpio17";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-bus-hold;
+		};
+	};
+};
diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
index f420740e068e..93365298c5ae 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
@@ -359,5 +359,33 @@ usb_hs1_phy: phy {
 				};
 			};
 		};
+
+		gsbi3: gsbi@16200000 {
+			compatible = "qcom,gsbi-v1.0.0";
+			reg = <0x16200000 0x100>;
+			ranges;
+			cell-index = <3>;
+			clocks = <&gcc GSBI3_H_CLK>;
+			clock-names = "iface";
+			#address-cells = <1>;
+			#size-cells = <1>;
+			status = "disabled";
+
+			gsbi3_i2c: i2c@16280000 {
+				compatible = "qcom,i2c-qup-v1.1.1";
+				reg = <0x16280000 0x1000>;
+				pinctrl-0 = <&i2c3_default_state>;
+				pinctrl-1 = <&i2c3_sleep_state>;
+				pinctrl-names = "default", "sleep";
+				interrupts = <GIC_SPI 151 IRQ_TYPE_LEVEL_HIGH>;
+				clocks = <&gcc GSBI3_QUP_CLK>,
+					 <&gcc GSBI3_H_CLK>;
+				clock-names = "core", "iface";
+				#address-cells = <1>;
+				#size-cells = <0>;
+				status = "disabled";
+			};
+		};
 	};
 };
+#include "qcom-msm8960-pins.dtsi"

-- 
2.43.0

