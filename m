From: Rudraksha Gupta <guptarud@gmail.com>
Date: Sat, 20 Jan 2024 00:45:23 -0800
Subject: [PATCH] ARM: dts: qcom: msm8960: expressatt: Add gpio-keys
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240120-expressatt-gpio-keys-v1-1-4da7e37440b1@gmail.com>
X-B4-Tracking: v=1; b=H4sIACKIq2UC/x2MWwqAIBAAryL73YLak64SfYRttQQWrkQR3j3pc
 2BmXhAKTAK9eiHQxcKHz2AKBW6b/ErIc2aw2lbaWI10n4FEphhxPfnAnR5B17i608vcmpIgp1l
 Z+P63w5jSBwpOfn9mAAAA
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705740324; l=2136;
 i=guptarud@gmail.com; s=20240120; h=from:subject:message-id;
 bh=T+B5s38HvE5wvfTx+enY1qi1SBEpEVBTYASUCLQBqwU=;
 b=5UsFmbupML19LrX80fkEWOLZlRS9ScDP+D8wWQsRQdb5oi45aWI0aU0X8kJPWiAA2zsSUDwt8
 JJWsV1VM4FBCOU6k8dRT6Emu/ieTQkcfTXdNy7HOfdTvgUn6zzY5diW
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=RGmug3GRHS4XYTXDcT2VrlTGXlEF2gY4L9/swGIU1ko=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240120 with auth_id=114
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds volume up, volume down, and home keys to expressatt

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
Adds volume up, volume down, and home keys to expressatt.

Applies on top of 5c903b859aaced384c0cd01d515f3e43a115fd9e
---
 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   | 40 ++++++++++++++++++++++
 1 file changed, 40 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
index 1a5116336ff0..47e0e26ad9f0 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
@@ -4,6 +4,9 @@
 
 #include "qcom-msm8960.dtsi"
 #include "pm8921.dtsi"
+#include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/pinctrl/qcom,pmic-gpio.h>
+#include <dt-bindings/input/gpio-keys.h>
 
 / {
 	model = "Samsung Galaxy Express SGH-I437";
@@ -19,6 +22,36 @@ aliases {
 	chosen {
 		stdout-path = "serial0:115200n8";
 	};
+
+	gpio-keys {
+		compatible = "gpio-keys";
+
+		pinctrl-names = "default";
+		pinctrl-0 = <&gpio_keys_pin_a>;
+
+		key-home {
+			label = "Home";
+			gpios = <&msmgpio 40 GPIO_ACTIVE_LOW>;
+			debounce-interval = <5>;
+			linux,code = <KEY_HOMEPAGE>;
+			wakeup-event-action = <EV_ACT_ASSERTED>;
+			wakeup-source;
+		};
+
+		key-volume-up {
+			label = "Volume Up";
+			gpios = <&msmgpio 50 GPIO_ACTIVE_LOW>;
+			debounce-interval = <5>;
+			linux,code = <KEY_VOLUMEUP>;
+		};
+
+		key-volume-down {
+			label = "Volume Down";
+			gpios = <&msmgpio 81 GPIO_ACTIVE_LOW>;
+			debounce-interval = <5>;
+			linux,code = <KEY_VOLUMEDOWN>;
+		};
+	};
 };
 
 &gsbi5 {
@@ -83,6 +116,13 @@ clk-pins {
 			bias-disable;
 		};
 	};
+
+	gpio_keys_pin_a: gpio-keys-active-state {
+		pins = "gpio40", "gpio50", "gpio81";
+		function = "gpio";
+		drive-strength = <8>;
+		bias-disable;
+	};
 };
 
 &pm8921 {

---
base-commit: 9d64bf433c53cab2f48a3fff7a1f2a696bc5229a
change-id: 20240120-expressatt-gpio-keys-c6c580fd713e

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

