From: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
Date: Mon, 05 Jan 2026 21:39:40 +0100
Subject: [PATCH 3/6] arm64: dts: imx8mq-librem5: Enable SNVS RTC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-l5-dtb-fixes-v1-3-f491881a7fe7@puri.sm>
References: <20260105-l5-dtb-fixes-v1-0-f491881a7fe7@puri.sm>
In-Reply-To: <20260105-l5-dtb-fixes-v1-0-f491881a7fe7@puri.sm>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 kernel@puri.sm, Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1387;
 i=sebastian.krzyszkowiak@puri.sm; h=from:subject:message-id;
 bh=JNuGNcfI6hOpvAZ8HqyeyXYhlWTDkcA5v2YZJDmxJ28=;
 b=owEBbQKS/ZANAwAKAejyNc8728P/AcsmYgBpXCGhgii/RpPhUf5h5CdefZyyrvNM0EOTExxiV
 fd3xaCeqQyJAjMEAAEKAB0WIQQi3Z+uAGoRQ1g2YXzo8jXPO9vD/wUCaVwhoQAKCRDo8jXPO9vD
 /3/6D/0XaLcU7/jVgEjAVZclOE31jKJh2hGo56atYPkmPm7G/LNt8rE/Frqs7T9YJk757Ee+76i
 iJKhVzimVKvodaL4/23/yknzgpeLW2Z4LGLDf2+WR/AHv491KC97A9PNGNZKq2XUN3xeAZsQTX8
 mwdHYuQG01XV6Y7BA1ijUwGW2/22yUZsH/zHKC+39Z23+/cTo01KBnabOW132d6XRtclB4jrS4T
 M3admKI8Q+O/QaXfWYKoOSDMl+UOrBFAElBKdleBUjW5PQGk7hMGLxeyk8am0SJ/1h3ijBoSSAH
 Pp9NO+bsZzzF+gC/bY/7klzabdyS7kd+mvyiX6oMfaEuXehqXmQJzIUb6XmhlW2PYOsrEVl8g+w
 fS1DQQbO5I2gGNwcLDNodChiPiRheCofr+OaDdX7hSG9tnHjUcNjCg7j5d6YygwdxPPFforjISw
 YPOAFBUQkwqaNEwx/julnaGWMfLTTWKQgfUb8/dHRiivCrHcaiXZWLqLSf2sc4r5dEJorArHQ/F
 DZ84XTn0F/GO7YQummaaVbskJ58pSfOHvGqCCuowhHXAv72FncdQuC6EiZlrVKA2NfnecgSp8rl
 ZukBVHYoPUK7ftZrUHsaRuB3S9I9YjsVvoElo/3m8a87+hMySKSJZYp8/gUJWs2bXfaTHBKMc4X
 LpvB6nF4rMj44Qg==
X-Developer-Key: i=sebastian.krzyszkowiak@puri.sm; a=openpgp;
 fpr=22DD9FAE006A11435836617CE8F235CF3BDBC3FF
X-Endpoint-Received: by B4 Relay for sebastian.krzyszkowiak@puri.sm/default with auth_id=32
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It has been disabled because it was being used for system clock instead
of the discrete RTC. However, SNVS has some features that the discrete
RTC does not, such as being able to turn the device on. Solve that issue
with aliases instead and reenable SNVS RTC.

Signed-off-by: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
---
 arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi | 11 ++++++-----
 1 file changed, 6 insertions(+), 5 deletions(-)

diff --git a/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi b/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
index b92b5f7b2bd7..8c37b1293699 100644
--- a/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
+++ b/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
@@ -17,6 +17,11 @@ / {
 	compatible = "purism,librem5", "fsl,imx8mq";
 	chassis-type = "handset";
 
+	aliases {
+		rtc0 = &rtc;
+		rtc1 = &snvs_rtc;
+	};
+
 	backlight_dsi: backlight-dsi {
 		compatible = "led-backlight";
 		leds = <&led_backlight>;
@@ -1001,7 +1006,7 @@ ldo7_reg: LDO7 {
 		};
 	};
 
-	rtc@68 {
+	rtc: rtc@68 {
 		compatible = "microcrystal,rv4162";
 		reg = <0x68>;
 		pinctrl-names = "default";
@@ -1316,10 +1321,6 @@ &snvs_pwrkey {
 	status = "okay";
 };
 
-&snvs_rtc {
-	status = "disabled";
-};
-
 &uart1 { /* console */
 	pinctrl-names = "default";
 	pinctrl-0 = <&pinctrl_uart1>;

-- 
2.52.0

