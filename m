From: Dang Huynh <dang.huynh@mainlining.org>
Date: Wed, 17 Sep 2025 03:25:20 +0700
Subject: [PATCH 23/25] dts: unisoc: rda8810pl: Add SDMMC controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250917-rda8810pl-drivers-v1-23-9ca9184ca977@mainlining.org>
References: <20250917-rda8810pl-drivers-v1-0-9ca9184ca977@mainlining.org>
In-Reply-To: <20250917-rda8810pl-drivers-v1-0-9ca9184ca977@mainlining.org>
To: Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Sebastian Reichel <sre@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Ulf Hansson <ulf.hansson@linaro.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-unisoc@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-rtc@vger.kernel.org, 
 linux-clk@vger.kernel.org, linux-pm@vger.kernel.org, 
 dmaengine@vger.kernel.org, linux-hardening@vger.kernel.org, 
 linux-mmc@vger.kernel.org, Dang Huynh <dang.huynh@mainlining.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758054322; l=1669;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=+rjfqyC6diLcCcMZpXzmNwIY3Xd0ao4URhi7mY7MeOo=;
 b=g36+c8BMuiizyAkQU5g2SVhGELtdZOZL7VmLGm9NJ65TH2ylz89Z6tGkVFMsW4PUF6yXDm1fJ
 gSr5M9xIH80CvABquDEQg1EdtLnBDMt1j/TqnDGY86xGtT9UTnG1g4P
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SDMMC1 and 2 controllers for the RDA8810PL platform.

Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 arch/arm/boot/dts/unisoc/rda8810pl.dtsi | 25 +++++++++++++++++++++++++
 1 file changed, 25 insertions(+)

diff --git a/arch/arm/boot/dts/unisoc/rda8810pl.dtsi b/arch/arm/boot/dts/unisoc/rda8810pl.dtsi
index 4b3ae19e9da41ee9ffa76dd4fff01824c07ce045..e68f8330ce2c4750b6944612bee03b42694137e4 100644
--- a/arch/arm/boot/dts/unisoc/rda8810pl.dtsi
+++ b/arch/arm/boot/dts/unisoc/rda8810pl.dtsi
@@ -9,6 +9,7 @@
 #include <dt-bindings/interrupt-controller/arm-gic.h>
 #include <dt-bindings/interrupt-controller/irq.h>
 #include <dt-bindings/clock/rda,8810pl-apclk.h>
+#include <dt-bindings/dma/rda-ifc.h>
 
 / {
 	compatible = "rda,8810pl";
@@ -199,6 +200,30 @@ uart1: serial@0 {
 			status = "disabled";
 		};
 
+		mmc1: mmc@50000 {
+			compatible = "rda,8810pl-mmc";
+			reg = <0x50000 0x1000>;
+			interrupts = <3 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&ap_syscon CLK_APB2>;
+			clock-names = "apb";
+			resets = <&ap_syscon RST_APB2_SDMMC1>;
+			dmas = <&ifc IFC_SDMMC1_TX>, <&ifc IFC_SDMMC1_RX>;
+			dma-names = "tx", "rx";
+			status = "disabled";
+		};
+
+		mmc2: mmc@60000 {
+			compatible = "rda,8810pl-mmc";
+			reg = <0x60000 0x1000>;
+			interrupts = <4 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&ap_syscon CLK_APB2>;
+			clock-names = "apb";
+			resets = <&ap_syscon RST_APB2_SDMMC2>;
+			dmas = <&ifc IFC_SDMMC2_TX>, <&ifc IFC_SDMMC2_RX>;
+			dma-names = "tx", "rx";
+			status = "disabled";
+		};
+
 		uart2: serial@10000 {
 			compatible = "rda,8810pl-uart";
 			reg = <0x10000 0x1000>;

-- 
2.51.0

