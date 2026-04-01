From: Rudraksha Gupta <guptarud@gmail.com>
Date: Wed, 01 Apr 2026 13:32:14 -0700
Subject: [PATCH v3 2/4] ARM: dts: qcom: msm8960: Flatten I2C pinctrl state
 subnodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260401-expressatt_fuel_guage-v3-2-9674cfc0b5a2@gmail.com>
References: <20260401-expressatt_fuel_guage-v3-0-9674cfc0b5a2@gmail.com>
In-Reply-To: <20260401-expressatt_fuel_guage-v3-0-9674cfc0b5a2@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775075533; l=5002;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=uGSuJpabkXo+b2760NIqVXSdmHC8oQgQfvmWmQRFFVI=;
 b=ONbsK8sMeCl2/DeiWXCNx3++3J1t0bEpuhnxGHZ+z2WYkYlihNnEdNlg3UrK5TWLoOpnYT4Hf
 t1HlT9312XbBNp/ccfGeNz7oCNG2nzZgMA7qhDwtbMQnqCVmt4ll55x
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove unnecessary inner i2c*-pins {} wrapper nodes from the I2C
pinctrl state definitions. Properties are moved directly under the
-state {} node, consistent with modern DT style.

Assisted-by: Claude:claude-opus-4.6
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 arch/arm/boot/dts/qcom/qcom-msm8960.dtsi | 140 +++++++++++++------------------
 1 file changed, 56 insertions(+), 84 deletions(-)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
index fd28401cebb5..6069fb925672 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
@@ -132,129 +132,101 @@ tlmm: pinctrl@800000 {
 			#interrupt-cells = <2>;
 
 			i2c1_default_state: i2c1-default-state {
-				i2c1-pins {
-					pins = "gpio8", "gpio9";
-					function = "gsbi1";
-					drive-strength = <8>;
-					bias-disable;
-				};
+				pins = "gpio8", "gpio9";
+				function = "gsbi1";
+				drive-strength = <8>;
+				bias-disable;
 			};
 
 			i2c1_sleep_state: i2c1-sleep-state {
-				i2c1-pins {
-					pins = "gpio8", "gpio9";
-					function = "gpio";
-					drive-strength = <2>;
-					bias-bus-hold;
-				};
+				pins = "gpio8", "gpio9";
+				function = "gpio";
+				drive-strength = <2>;
+				bias-bus-hold;
 			};
 
 			i2c2_default_state: i2c2-default-state {
-				i2c2-pins {
-					pins = "gpio12", "gpio13";
-					function = "gsbi2";
-					drive-strength = <8>;
-					bias-disable;
-				};
+				pins = "gpio12", "gpio13";
+				function = "gsbi2";
+				drive-strength = <8>;
+				bias-disable;
 			};
 
 			i2c2_sleep_state: i2c2-sleep-state {
-				i2c2-pins {
-					pins = "gpio12", "gpio13";
-					function = "gpio";
-					drive-strength = <2>;
-					bias-bus-hold;
-				};
+				pins = "gpio12", "gpio13";
+				function = "gpio";
+				drive-strength = <2>;
+				bias-bus-hold;
 			};
 
 			i2c3_default_state: i2c3-default-state {
-				i2c3-pins {
-					pins = "gpio16", "gpio17";
-					function = "gsbi3";
-					drive-strength = <8>;
-					bias-disable;
-				};
+				pins = "gpio16", "gpio17";
+				function = "gsbi3";
+				drive-strength = <8>;
+				bias-disable;
 			};
 
 			i2c3_sleep_state: i2c3-sleep-state {
-				i2c3-pins {
-					pins = "gpio16", "gpio17";
-					function = "gpio";
-					drive-strength = <2>;
-					bias-bus-hold;
-				};
+				pins = "gpio16", "gpio17";
+				function = "gpio";
+				drive-strength = <2>;
+				bias-bus-hold;
 			};
 
 			i2c7_default_state: i2c7-default-state {
-				i2c7-pins {
-					pins = "gpio32", "gpio33";
-					function = "gsbi7";
-					drive-strength = <8>;
-					bias-disable;
-				};
+				pins = "gpio32", "gpio33";
+				function = "gsbi7";
+				drive-strength = <8>;
+				bias-disable;
 			};
 
 			i2c7_sleep_state: i2c7-sleep-state {
-				i2c7-pins {
-					pins = "gpio32", "gpio33";
-					function = "gpio";
-					drive-strength = <2>;
-					bias-bus-hold;
-				};
+				pins = "gpio32", "gpio33";
+				function = "gpio";
+				drive-strength = <2>;
+				bias-bus-hold;
 			};
 
 			i2c8_default_state: i2c8-default-state {
-				i2c8-pins {
-					pins = "gpio36", "gpio37";
-					function = "gsbi8";
-					drive-strength = <8>;
-					bias-disable;
-				};
+				pins = "gpio36", "gpio37";
+				function = "gsbi8";
+				drive-strength = <8>;
+				bias-disable;
 			};
 
 			i2c8_sleep_state: i2c8-sleep-state {
-				i2c8-pins {
-					pins = "gpio36", "gpio37";
-					function = "gpio";
-					drive-strength = <2>;
-					bias-bus-hold;
-				};
+				pins = "gpio36", "gpio37";
+				function = "gpio";
+				drive-strength = <2>;
+				bias-bus-hold;
 			};
 
 			i2c10_default_state: i2c10-default-state {
-				i2c10-pins {
-					pins = "gpio73", "gpio74";
-					function = "gsbi10";
-					drive-strength = <8>;
-					bias-disable;
-				};
+				pins = "gpio73", "gpio74";
+				function = "gsbi10";
+				drive-strength = <8>;
+				bias-disable;
 			};
 
 			i2c10_sleep_state: i2c10-sleep-state {
-				i2c10-pins {
-					pins = "gpio73", "gpio74";
-					function = "gpio";
-					drive-strength = <2>;
-					bias-bus-hold;
-				};
+				pins = "gpio73", "gpio74";
+				function = "gpio";
+				drive-strength = <2>;
+				bias-bus-hold;
 			};
 
 			i2c12_default_state: i2c12-default-state {
-				i2c12-pins {
-					pins = "gpio44", "gpio45";
-					function = "gsbi12";
-					drive-strength = <8>;
-					bias-disable;
-				};
+				pins = "gpio44", "gpio45";
+				function = "gsbi12";
+				drive-strength = <8>;
+				bias-disable;
 			};
 
 			i2c12_sleep_state: i2c12-sleep-state {
-				i2c12-pins {
-					pins = "gpio44", "gpio45";
-					function = "gpio";
-					drive-strength = <2>;
-					bias-bus-hold;
-				};
+				pins = "gpio44", "gpio45";
+				function = "gpio";
+				drive-strength = <2>;
+				bias-bus-hold;
 			};
 
 			sdcc3_default_state: sdcc3-default-state {

-- 
2.53.0

