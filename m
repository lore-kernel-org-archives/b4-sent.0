From: Dang Huynh <dang.huynh@mainlining.org>
Date: Wed, 17 Sep 2025 03:25:22 +0700
Subject: [PATCH 25/25] dts: unisoc: orangepi-i96: Enable SD Card
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250917-rda8810pl-drivers-v1-25-9ca9184ca977@mainlining.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758054322; l=1432;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=qcvVxoXavmL/qbncOuYL4/AA9pp1j7YRntSv1snSw4A=;
 b=TmsiEoRuyNtRCinPmNRJPzsRLAOD+OfUVej7sM4TKuiv/lAlcCXOZO2yuj/YlaqpZKI2qoRoe
 gli9x6SUlcyCqeLBNQVNnFpfLrzGx9+fwjvYNgu+FokiMeRoJphyvZF
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since we have a SDMMC controller, we can use the SD card slot on the
Orange Pi i96.

Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 arch/arm/boot/dts/unisoc/rda8810pl-orangepi-i96.dts | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-i96.dts b/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-i96.dts
index a1d61ef138d12bb3ecb4b24513cc1a7dfbac3107..fbb7b5be62051627e80d940cb5e5ccff9047c13c 100644
--- a/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-i96.dts
+++ b/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-i96.dts
@@ -6,6 +6,7 @@
 
 /dts-v1/;
 
+#include <dt-bindings/gpio/gpio.h>
 #include "rda8810pl.dtsi"
 
 / {
@@ -27,6 +28,13 @@ memory@80000000 {
 		reg = <0x80000000 0x10000000>;
 	};
 
+	vdd_sdmmc: regulator-fixed {
+		compatible = "regulator-fixed";
+		regulator-name = "vdd_sdmmc";
+		regulator-min-microvolt = <2800000>;
+		regulator-max-microvolt = <2800000>;
+	};
+
 	uart_clk: uart-clk {
 		compatible = "fixed-clock";
 		clock-frequency = <921600>;
@@ -34,6 +42,18 @@ uart_clk: uart-clk {
 	};
 };
 
+&mmc1 {
+	status = "okay";
+	no-sdio;
+	no-mmc;
+	bus-width = <4>;
+	max-frequency = <30000000>;
+	cd-gpios = <&gpiob 4 GPIO_ACTIVE_LOW>;
+	vmmc-supply = <&vdd_sdmmc>;
+	rda,mclk-adj = /bits/ 8 <1>;
+	rda,mclk-inv;
+};
+
 &uart3 {
 	status = "okay";
 	clocks = <&uart_clk>;

-- 
2.51.0

