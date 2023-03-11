From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Sat, 11 Mar 2023 06:11:12 +0100
Subject: [PATCH v9 4/5] arm64: dts: apple: t600x: Add PWM controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230214-fpwm-v9-4-dbe26bccabd6@gmail.com>
References: <20230214-fpwm-v9-0-dbe26bccabd6@gmail.com>
In-Reply-To: <20230214-fpwm-v9-0-dbe26bccabd6@gmail.com>
To: Thierry Reding <thierry.reding@gmail.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 - <asahi@lists.linux.dev>, Sasha Finkelstein <fnkl.kernel@gmail.com>, 
 Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Sasha Finkelstein <7d578vix8hzw@opayq.net>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1678511469; l=2061;
 i=fnkl.kernel@gmail.com; s=20230213; h=from:subject:message-id;
 bh=kC8e0IqG+WMbKwdUXKBwuQCvwcxm5IAUASQM0mxJcPI=;
 b=ylBTfjRjGzHWvEqIWhhn18jeSZMEbiaeiZg+M/rcRcOJhWSSI10M/YUir9QQPA/sTAAL13MGP
 lmTlMYqmrZgCLZym5lvq6Ad9O/zAvhiaf6Rbbtb4MUvfKfkLO1OyK5n
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=7LFSAJtxIWAs9LzCIyX0sSvCZy2wQTyEIu1zch6o804=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20230213 with auth_id=28
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sasha Finkelstein <7d578vix8hzw@opayq.net>

Adds PWM controller and keyboard backlight bindings for M1 Pro/Max MacBook Pros

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
Acked-by: Hector Martin <marcan@marcan.st>
---
 arch/arm64/boot/dts/apple/t600x-die0.dtsi      |  9 +++++++++
 arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi | 18 ++++++++++++++++++
 2 files changed, 27 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t600x-die0.dtsi b/arch/arm64/boot/dts/apple/t600x-die0.dtsi
index 1c41954e3899..9157ae2a9f7f 100644
--- a/arch/arm64/boot/dts/apple/t600x-die0.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-die0.dtsi
@@ -71,6 +71,15 @@ sio_dart_1: iommu@39b008000 {
 		power-domains = <&ps_sio_cpu>;
 	};
 
+	fpwm0: pwm@39b030000 {
+		compatible = "apple,t6000-fpwm", "apple,s5l-fpwm";
+		reg = <0x3 0x9b030000 0x0 0x4000>;
+		power-domains = <&ps_fpwm0>;
+		clocks = <&clkref>;
+		#pwm-cells = <2>;
+		status = "disabled";
+	};
+
 	i2c0: i2c@39b040000 {
 		compatible = "apple,t6000-i2c", "apple,i2c";
 		reg = <0x3 0x9b040000 0x0 0x4000>;
diff --git a/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi b/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
index 34906d522f0a..96de7165df6d 100644
--- a/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
@@ -9,6 +9,8 @@
  * Copyright The Asahi Linux Contributors
  */
 
+#include <dt-bindings/leds/common.h>
+
 / {
 	aliases {
 		serial0 = &serial0;
@@ -34,6 +36,18 @@ memory@10000000000 {
 		device_type = "memory";
 		reg = <0x100 0 0x2 0>; /* To be filled by loader */
 	};
+
+	led-controller {
+		compatible = "pwm-leds";
+		led-0 {
+			pwms = <&fpwm0 0 40000>;
+			label = "kbd_backlight";
+			function = LED_FUNCTION_KBD_BACKLIGHT;
+			color = <LED_COLOR_ID_WHITE>;
+			max-brightness = <255>;
+			default-state = "keep";
+		};
+	};
 };
 
 &serial0 {
@@ -110,5 +124,9 @@ &pcie0_dart_3 {
 	status = "disabled";
 };
 
+&fpwm0 {
+	status = "okay";
+};
+
 /delete-node/ &port02;
 /delete-node/ &port03;

-- 
Git-137.1)

