From: Dang Huynh <dang.huynh@mainlining.org>
Date: Wed, 17 Sep 2025 03:25:08 +0700
Subject: [PATCH 11/25] dts: unisoc: rda8810pl: Enable clock/reset driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250917-rda8810pl-drivers-v1-11-9ca9184ca977@mainlining.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758054322; l=1103;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=iisWV1yQIJV2H6A79OICiudNGMDM/d8wOSexhp4+9s4=;
 b=Uvbh1qdCuPgMg2Cya3wHJFP9B0zxFrsqfkRbRH3160/AsRSPEzMZMlwk9yvCgAuRqcoJQnphz
 LShcA3DOx1LBDlnxtXB3POz/cK5m8ZeoMMoHjCQKsqRFMuyqcxZ4qHk
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable RDA8810PL Clock and Reset driver so we can use it for various
subsystems.

Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 arch/arm/boot/dts/unisoc/rda8810pl.dtsi | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm/boot/dts/unisoc/rda8810pl.dtsi b/arch/arm/boot/dts/unisoc/rda8810pl.dtsi
index 45a2fd3e04cea5aac4fb6b40a6b332ce3eee4f2c..1f7a6908d68367441e5dc865216cc7a5c39feb35 100644
--- a/arch/arm/boot/dts/unisoc/rda8810pl.dtsi
+++ b/arch/arm/boot/dts/unisoc/rda8810pl.dtsi
@@ -8,6 +8,7 @@
 
 #include <dt-bindings/interrupt-controller/arm-gic.h>
 #include <dt-bindings/interrupt-controller/irq.h>
+#include <dt-bindings/clock/rda,8810pl-apclk.h>
 
 / {
 	compatible = "rda,8810pl";
@@ -79,6 +80,13 @@ apb@20900000 {
 		#size-cells = <1>;
 		ranges = <0x0 0x20900000 0x100000>;
 
+		ap_syscon: syscon@0 {
+			compatible = "rda,8810pl-apsyscon", "syscon";
+			reg = <0x0 0x1000>;
+			#clock-cells = <1>;
+			#reset-cells = <1>;
+		};
+
 		timer@10000 {
 			compatible = "rda,8810pl-timer";
 			reg = <0x10000 0x1000>;

-- 
2.51.0

