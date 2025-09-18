From: Dang Huynh <dang.huynh@mainlining.org>
Date: Fri, 19 Sep 2025 01:48:42 +0700
Subject: [PATCH 02/10] dt-bindings: clock: Add RDA Micro RDA8810PL
 clock/reset controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250919-rda8810pl-mmc-v1-2-d4f08a05ba4d@mainlining.org>
References: <20250919-rda8810pl-mmc-v1-0-d4f08a05ba4d@mainlining.org>
In-Reply-To: <20250919-rda8810pl-mmc-v1-0-d4f08a05ba4d@mainlining.org>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Ulf Hansson <ulf.hansson@linaro.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-unisoc@lists.infradead.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 dmaengine@vger.kernel.org, linux-mmc@vger.kernel.org, 
 linux-hardening@vger.kernel.org, Dang Huynh <dang.huynh@mainlining.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758221395; l=3620;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=yG1beL4lbbZE3Cyw7kV4xFP4ZLuCcjFcdAuQ/q4oW2c=;
 b=JF6dfaJsAusUyjBVwoIXfKUz19P5AWybOy4EvgWhd2pjj31nJtH6FOD0h+2fiLlOazh9s+xlj
 HEwzlje4oP5DeSea12PeZ2gEI5kYukFumlHp1Rs2zLRm4HdqCrnp6ZZ
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation describing the RDA8810PL Clock and Reset
controller.

Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 .../bindings/clock/rda,8810pl-apsyscon.yaml        | 43 +++++++++++++
 include/dt-bindings/clock/rda,8810pl-apclk.h       | 70 ++++++++++++++++++++++
 2 files changed, 113 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/rda,8810pl-apsyscon.yaml b/Documentation/devicetree/bindings/clock/rda,8810pl-apsyscon.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..d90dae8ebaa270aa822e4855d2a4a892168c5eea
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/rda,8810pl-apsyscon.yaml
@@ -0,0 +1,43 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/rda,8810pl-apsyscon.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: RDA Micro RDA8810PL AP Clock Controller
+
+maintainers:
+  - Dang Huynh <dang.huynh@mainlining.org>
+
+properties:
+  compatible:
+    items:
+      - const: rda,8810pl-apsyscon
+      - const: syscon
+
+  reg:
+    maxItems: 1
+
+  '#clock-cells':
+    const: 1
+
+  '#reset-cells':
+    const: 1
+
+required:
+  - compatible
+  - reg
+  - '#clock-cells'
+  - '#reset-cells'
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/clock/rda,8810pl-apclk.h>
+    syscon@0 {
+      compatible = "rda,8810pl-apsyscon", "syscon";
+      reg = <0x0 0x1000>;
+      #clock-cells = <1>;
+      #reset-cells = <1>;
+    };
diff --git a/include/dt-bindings/clock/rda,8810pl-apclk.h b/include/dt-bindings/clock/rda,8810pl-apclk.h
new file mode 100644
index 0000000000000000000000000000000000000000..b6d68af9596a7ef827f6d18f1f19ed359e147629
--- /dev/null
+++ b/include/dt-bindings/clock/rda,8810pl-apclk.h
@@ -0,0 +1,70 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-3-Clause) */
+
+#ifndef _DT_BINDINGS_CLK_RDA8810_H_
+#define _DT_BINDINGS_CLK_RDA8810_H_
+
+/* soc clocks */
+#define CLK_CPU			0
+#define CLK_BUS			1
+#define CLK_MEM			2
+#define CLK_USB			3
+#define CLK_AXI			4
+#define CLK_GCG			5
+#define CLK_AHB1			6
+#define CLK_APB1			7
+#define CLK_APB2			8
+#define CLK_GPU			9
+#define CLK_VPU			10
+#define CLK_VOC			11
+#define CLK_SFLSH			12
+#define CLK_UART1			13
+#define CLK_UART2			14
+#define CLK_UART3			15
+#define CLK_VOC2			16
+#define CLK_EMMC			17
+
+/* resets */
+#define RST_CPU			0
+
+#define RST_AXI_VOC			1
+#define RST_AXI_DMA			2
+#define RST_AXI_CONNECT		3
+#define RST_AXI_VPU			4
+
+#define RST_GCG_GOUDA			5
+#define RST_GCG_CAMERA			6
+#define RST_GCG_LCDC			7
+
+#define RST_AHB1_USBC			8
+#define RST_AHB1_SPIFLASH		9
+#define RST_APB1_TIMER			10
+#define RST_APB1_KEYPAD		11
+#define RST_APB1_GPIO			12
+#define RST_APB1_PWM			13
+#define RST_APB1_AIF			14
+#define RST_APB1_AUIFC			15
+#define RST_APB1_I2C1			16
+#define RST_APB1_I2C2			17
+#define RST_APB1_I2C3			18
+#define RST_APB1_COMREGS		19
+#define RST_APB1_DMC			20
+#define RST_APB1_DDRPHY_P		21
+
+#define RST_APB2_IFC			22
+#define RST_APB2_UART1			23
+#define RST_APB2_UART2			24
+#define RST_APB2_UART3			25
+#define RST_APB2_SPI1			26
+#define RST_APB2_SPI2			27
+#define RST_APB2_SPI3			28
+#define RST_APB2_SDMMC1		29
+#define RST_APB2_SDMMC2		30
+#define RST_APB2_SDMMC3		31
+#define RST_APB2_NAND			32
+
+#define RST_MEM_GPU			33
+#define RST_MEM_VPU			34
+#define RST_MEM_DMC			35
+#define RST_MEM_DDRPHY_P		36
+
+#endif /* _DT_BINDINGS_CLK_RDA8810_H_ */

-- 
2.51.0

