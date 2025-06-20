From: Max Shevchenko <wctrl@proton.me>
Date: Fri, 20 Jun 2025 18:40:48 +0300
Subject: [PATCH 09/11] ARM: dts: mediatek: add basic support for MT6572 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250620-mt6572-v1-9-e2d47820f042@proton.me>
References: <20250620-mt6572-v1-0-e2d47820f042@proton.me>
In-Reply-To: <20250620-mt6572-v1-0-e2d47820f042@proton.me>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Thomas Gleixner <tglx@linutronix.de>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Sean Wang <sean.wang@mediatek.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-watchdog@vger.kernel.org, 
 Max Shevchenko <wctrl@proton.me>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750434231; l=3093;
 i=wctrl@proton.me; s=20250603; h=from:subject:message-id;
 bh=yLz+8+oRVysKR8AFBuER+Y8kTu+TRBNb+mijfqNvpZQ=;
 b=bCdHvRnt9g7pM6K/Ch8qxCTRPC38eiYofcpVy4YvxOPA4ID6G44+elWtfszhzVGa1ZXYT7DJs
 kT9NpWpkFrmDlt9SWyPb/lyzmJm32pt4TRwrG0EeUR4ebCiFm0wdJGp
X-Developer-Key: i=wctrl@proton.me; a=ed25519;
 pk=JXUx3mL/OrnRvbK57HXgugBjEBKq4QgDKJqp7BALm74=
X-Endpoint-Received: by B4 Relay for wctrl@proton.me/20250603 with auth_id=421
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add basic support for the MediaTek MT6572 SoC.

Signed-off-by: Max Shevchenko <wctrl@proton.me>
---
 arch/arm/boot/dts/mediatek/mt6572.dtsi | 105 +++++++++++++++++++++++++++++++++
 1 file changed, 105 insertions(+)

diff --git a/arch/arm/boot/dts/mediatek/mt6572.dtsi b/arch/arm/boot/dts/mediatek/mt6572.dtsi
new file mode 100644
index 0000000000000000000000000000000000000000..dd12231ca745be7455e99391abd2d708f2f1a8a9
--- /dev/null
+++ b/arch/arm/boot/dts/mediatek/mt6572.dtsi
@@ -0,0 +1,105 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2025 Max Shevchenko <wctrl@proton.me>
+ */
+
+#include <dt-bindings/interrupt-controller/irq.h>
+#include <dt-bindings/interrupt-controller/arm-gic.h>
+
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+	compatible = "mediatek,mt6572";
+	interrupt-parent = <&sysirq>;
+
+	cpus {
+		#address-cells = <1>;
+		#size-cells = <0>;
+		enable-method = "mediatek,mt6589-smp";
+
+		cpu@0 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a7";
+			reg = <0x0>;
+		};
+		cpu@1 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a7";
+			reg = <0x1>;
+		};
+	};
+
+	system_clk: dummy13m {
+		compatible = "fixed-clock";
+		clock-frequency = <13000000>;
+		#clock-cells = <0>;
+	};
+
+	rtc_clk: dummy32k {
+		compatible = "fixed-clock";
+		clock-frequency = <32000>;
+		#clock-cells = <0>;
+	};
+
+	uart_clk: dummy26m {
+		compatible = "fixed-clock";
+		clock-frequency = <26000000>;
+		#clock-cells = <0>;
+	};
+
+	watchdog: watchdog@10007000 {
+		compatible = "mediatek,mt6572-wdt",
+			     "mediatek,mt6589-wdt";
+		reg = <0x10007000 0x100>;
+		interrupts = <GIC_SPI 126 IRQ_TYPE_LEVEL_LOW>;
+		timeout-sec = <15>;
+		#reset-cells = <1>;
+	};
+
+	timer: timer@10008000 {
+		compatible = "mediatek,mt6572-timer",
+			     "mediatek,mt6577-timer";
+		reg = <0x10008000 0x80>;
+		interrupts = <GIC_SPI 74 IRQ_TYPE_LEVEL_LOW>;
+		clocks = <&system_clk>, <&rtc_clk>;
+		clock-names = "system-clk", "rtc-clk";
+	};
+
+	sysirq: interrupt-controller@10200100 {
+		compatible = "mediatek,mt6572-sysirq",
+			     "mediatek,mt6577-sysirq";
+		interrupt-controller;
+		#interrupt-cells = <3>;
+		interrupt-parent = <&gic>;
+		reg = <0x10200100 0x1c>;
+	};
+
+	gic: interrupt-controller@10211000 {
+		compatible = "arm,cortex-a7-gic";
+		interrupt-controller;
+		#interrupt-cells = <3>;
+		interrupt-parent = <&gic>;
+		reg = <0x10211000 0x1000>,
+		      <0x10212000 0x2000>,
+		      <0x10214000 0x2000>,
+		      <0x10216000 0x2000>;
+	};
+
+	uart0: serial@11005000 {
+		compatible = "mediatek,mt6572-uart",
+			     "mediatek,mt6577-uart";
+		reg = <0x11005000 0x400>;
+		interrupts = <GIC_SPI 31 IRQ_TYPE_LEVEL_LOW>;
+		clocks = <&uart_clk>;
+		status = "disabled";
+	};
+
+	uart1: serial@11006000 {
+		compatible = "mediatek,mt6572-uart",
+			     "mediatek,mt6577-uart";
+		reg = <0x11006000 0x400>;
+		interrupts = <GIC_SPI 32 IRQ_TYPE_LEVEL_LOW>;
+		clocks = <&uart_clk>;
+		status = "disabled";
+	};
+};

-- 
2.50.0

