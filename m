From: Chuan Liu <chuan.liu@amlogic.com>
Date: Tue, 30 Sep 2025 17:37:23 +0800
Subject: [PATCH 10/19] arm64: dts: amlogic: A4: Add PLL controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250930-a4_a5_add_clock_driver-v1-10-a9acf7951589@amlogic.com>
References: <20250930-a4_a5_add_clock_driver-v1-0-a9acf7951589@amlogic.com>
In-Reply-To: <20250930-a4_a5_add_clock_driver-v1-0-a9acf7951589@amlogic.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759225047; l=1225;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=oAaJfXCorPN/I+5LCtKFDD1NM9mVnKs2qOf9ZPCvDw8=;
 b=d6myvlj/U/L13Tj+S+Ji4Dk0XtVUxazgUUq9FsVE1ThmjBA/nzBhUa5xmY5macDs7lO7hGqSI
 M9QAVPVu/svDybUns5YQEHYuQU2bWzRntvXYsqFUQFx2sqtfKKQZrZT
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the PLL controller node for A4 SoC family.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
index 75a87f093d8d..aca81e658654 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
@@ -7,6 +7,9 @@
 #include "amlogic-a4-reset.h"
 #include <dt-bindings/power/amlogic,a4-pwrc.h>
 #include <dt-bindings/pinctrl/amlogic,pinctrl.h>
+#include <dt-bindings/clock/amlogic,a4-pll-clkc.h>
+#include <dt-bindings/clock/amlogic,a4-scmi-clkc.h>
+
 / {
 	cpus {
 		#address-cells = <2>;
@@ -198,6 +201,16 @@ gpio_intc: interrupt-controller@4080 {
 			<10 11 12 13 14 15 16 17 18 19 20 21>;
 	};
 
+	clkc_pll: clock-controller@8000 {
+		compatible = "amlogic,a4-pll-clkc";
+		reg = <0x0 0x8000 0x0 0x1a4>;
+		#clock-cells = <1>;
+		clocks = <&xtal>,
+			 <&scmi_clk CLKID_FIXED_PLL>;
+		clock-names = "xtal",
+			      "fix";
+	};
+
 	ao_pinctrl: pinctrl@8e700 {
 		compatible = "amlogic,pinctrl-a4";
 		#address-cells = <2>;

-- 
2.42.0

