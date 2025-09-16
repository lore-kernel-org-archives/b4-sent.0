From: Dang Huynh <dang.huynh@mainlining.org>
Date: Wed, 17 Sep 2025 03:25:10 +0700
Subject: [PATCH 13/25] dts: unisoc: orangepi: Disable UART with no users
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250917-rda8810pl-drivers-v1-13-9ca9184ca977@mainlining.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758054322; l=1477;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=XPO5kEJS5ocnBL76vZ0w5j7Lye5wuRkS9bNnKxmO9oo=;
 b=2zBM9XKo6rOYbZUNQpD9eFH0E5hNGPLBqV3M7IJCdwPx3vmKRrOd+pPLTcttmUftfCu1MJTme
 +esbSs3Nw5mA0QSS7+wm41hH4xrahHriqA1Ce8uMeTupFJtX3yQzKCr
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

By default, we should keep unused peripherals disabled.

Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 arch/arm/boot/dts/unisoc/rda8810pl-orangepi-2g-iot.dts | 10 ----------
 arch/arm/boot/dts/unisoc/rda8810pl-orangepi-i96.dts    | 10 ----------
 2 files changed, 20 deletions(-)

diff --git a/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-2g-iot.dts b/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-2g-iot.dts
index 98e34248ae80b1fcd673ff01fe045db412d5bcc9..46ccb9ad510c0df142b845d6fc5633b69c2298dd 100644
--- a/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-2g-iot.dts
+++ b/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-2g-iot.dts
@@ -34,16 +34,6 @@ uart_clk: uart-clk {
 	};
 };
 
-&uart1 {
-	status = "okay";
-	clocks = <&uart_clk>;
-};
-
-&uart2 {
-	status = "okay";
-	clocks = <&uart_clk>;
-};
-
 &uart3 {
 	status = "okay";
 	clocks = <&uart_clk>;
diff --git a/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-i96.dts b/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-i96.dts
index 728f76931b995fdfc036b586f899b15a7f07528b..a1d61ef138d12bb3ecb4b24513cc1a7dfbac3107 100644
--- a/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-i96.dts
+++ b/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-i96.dts
@@ -34,16 +34,6 @@ uart_clk: uart-clk {
 	};
 };
 
-&uart1 {
-	status = "okay";
-	clocks = <&uart_clk>;
-};
-
-&uart2 {
-	status = "okay";
-	clocks = <&uart_clk>;
-};
-
 &uart3 {
 	status = "okay";
 	clocks = <&uart_clk>;

-- 
2.51.0

