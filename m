From: Rudraksha Gupta <guptarud@gmail.com>
Date: Mon, 29 Jan 2024 18:43:06 -0800
Subject: [PATCH 1/2] ARM: dts: qcom: msm8960: Add gsbi3 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240129-expressatt_mxt224s_touchscreen-v1-1-fb8552e1c32c@gmail.com>
References: <20240129-expressatt_mxt224s_touchscreen-v1-0-fb8552e1c32c@gmail.com>
In-Reply-To: <20240129-expressatt_mxt224s_touchscreen-v1-0-fb8552e1c32c@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706582586; l=2174;
 i=guptarud@gmail.com; s=20240120; h=from:subject:message-id;
 bh=71iD1TcYIaHc5nmS/5IyoaavDQDYXrkg8rcaJA80YFE=;
 b=+YgFjGIGrCn96fSpHtUZX/Eau/zRUk1I3kDEu6G3B/hIxpJgS+376e0e0TsFJMmPnUYU8cO3v
 nrQuuGBZAzkCAWlmG+vDRL434BGJCgGI43bFp1zjWn7H0UYUzzeP4x1
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=RGmug3GRHS4XYTXDcT2VrlTGXlEF2gY4L9/swGIU1ko=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240120 with auth_id=114
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Copy gsbi3 node from qcom-apq8064.dtsi and set appropriate properties

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 arch/arm/boot/dts/qcom/qcom-msm8960-pins.dtsi | 29 +++++++++++++++++++++++++++
 arch/arm/boot/dts/qcom/qcom-msm8960.dtsi      | 27 +++++++++++++++++++++++++
 2 files changed, 56 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-pins.dtsi b/arch/arm/boot/dts/qcom/qcom-msm8960-pins.dtsi
new file mode 100644
index 000000000000..c74c6625d276
--- /dev/null
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-pins.dtsi
@@ -0,0 +1,29 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+&msmgpio {
+	i2c3_pins: i2c3 {
+		mux {
+			pins = "gpio16", "gpio17";
+			function = "gsbi3";
+		};
+
+		pinconf {
+			pins = "gpio16", "gpio17";
+			drive-strength = <8>;
+			bias-disable;
+		};
+	};
+
+	i2c3_pins_sleep: i2c3_pins_sleep {
+		mux {
+			pins = "gpio16", "gpio17";
+			function = "gpio";
+		};
+
+		pinconf {
+			pins = "gpio16", "gpio17";
+			drive-strength = <2>;
+			bias-bus-hold;
+		};
+	};
+};
diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
index f420740e068e..62a5a9622e82 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
@@ -359,5 +359,32 @@ usb_hs1_phy: phy {
 				};
 			};
 		};
+
+		gsbi3: gsbi@16200000 {
+			status = "disabled";
+			compatible = "qcom,gsbi-v1.0.0";
+			cell-index = <3>;
+			reg = <0x16200000 0x100>;
+			clocks = <&gcc GSBI3_H_CLK>;
+			clock-names = "iface";
+			#address-cells = <1>;
+			#size-cells = <1>;
+			ranges;
+			gsbi3_i2c: i2c@16280000 {
+				compatible = "qcom,i2c-qup-v1.1.1";
+				pinctrl-0 = <&i2c3_pins>;
+				pinctrl-1 = <&i2c3_pins_sleep>;
+				pinctrl-names = "default", "sleep";
+				reg = <0x16280000 0x1000>;
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

