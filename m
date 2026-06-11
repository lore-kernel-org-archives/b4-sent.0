From: Jia Wang <wangjia@ultrarisc.com>
Date: Thu, 11 Jun 2026 17:40:53 +0800
Subject: [PATCH 1/2] dt-bindings: clock: ultrarisc: Add DP1000 Clock
 Controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260611-ultrarisc-clock-v1-1-2d93ebb4cc13@ultrarisc.com>
References: <20260611-ultrarisc-clock-v1-0-2d93ebb4cc13@ultrarisc.com>
In-Reply-To: <20260611-ultrarisc-clock-v1-0-2d93ebb4cc13@ultrarisc.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781170862; l=4324;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=ZVECvPlV5OOnNMLzfwPIxc7AenY8bgWHzITK/jxqUj0=;
 b=4DRmJtjrXmJ9Z8UAKcGcnou2Dxhc0J1R1j4MoYiLhrqXVwTuqy692+ftw0Q0kYBK5WW/tRnji
 6ZVlRxuy5bhBR9+6a/QH8qSM+Q60EubMrUcSHqtZSmF0Uws0plQOFdo
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add doc for the clock controller on the UltraRISC DP1000 RISC-V SoC.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 .../bindings/clock/ultrarisc,dp1000-clk.yaml       | 72 ++++++++++++++++++++++
 MAINTAINERS                                        |  7 +++
 include/dt-bindings/clock/ultrarisc,dp1000-clk.h   | 29 +++++++++
 3 files changed, 108 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/ultrarisc,dp1000-clk.yaml b/Documentation/devicetree/bindings/clock/ultrarisc,dp1000-clk.yaml
new file mode 100644
index 000000000000..d4d3d851a079
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/ultrarisc,dp1000-clk.yaml
@@ -0,0 +1,72 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/ultrarisc,dp1000-clk.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: UltraRISC DP1000 Clock Controller
+
+maintainers:
+  - Jia Wang <wangjia@ultrarisc.com>
+
+description: |
+  The UltraRISC DP1000 clock controller is driven from a single external
+  oscillator input. It provides a system PLL with fractional multiplier
+  and post-divider stages, several fixed-ratio derived clocks for
+  the on-chip subsystem, Clock Configuration Register (CCR) divider
+  outputs for GMAC and the UART, I2C, and SPI root clocks, and
+  per-instance gate clocks for UART0-3, I2C0-3, and SPI0-1.
+
+  All available clocks are defined as preprocessor macros in
+  include/dt-bindings/clock/ultrarisc,dp1000-clk.h
+
+properties:
+  compatible:
+    const: ultrarisc,dp1000-clk
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    maxItems: 1
+    description:
+      External oscillator input clock used as the parent of the PLLs.
+
+  clock-names:
+    items:
+      - const: osc
+
+  "#clock-cells":
+    const: 1
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - clock-names
+  - "#clock-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/clock/ultrarisc,dp1000-clk.h>
+
+    osc: oscillator {
+      compatible = "fixed-clock";
+      #clock-cells = <0>;
+      clock-frequency = <24000000>;
+    };
+
+    soc {
+      #address-cells = <2>;
+      #size-cells = <2>;
+
+      clock-controller@11080000 {
+        compatible = "ultrarisc,dp1000-clk";
+        reg = <0x0 0x11080000 0x0 0x1000>;
+        clocks = <&osc>;
+        clock-names = "osc";
+        #clock-cells = <1>;
+      };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index e035a3be797c..3331f1edf002 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -27357,6 +27357,13 @@ S:	Maintained
 F:	drivers/usb/common/ulpi.c
 F:	include/linux/ulpi/
 
+ULTRARISC DP1000 CLOCK DRIVER
+M:	Jia Wang <wangjia@ultrarisc.com>
+L:	linux-clk@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/clock/ultrarisc,dp1000-clk.yaml
+F:	include/dt-bindings/clock/ultrarisc,dp1000-clk.h
+
 ULTRATRONIK BOARD SUPPORT
 M:	Goran Rađenović <goran.radni@gmail.com>
 M:	Börge Strümpfel <boerge.struempfel@gmail.com>
diff --git a/include/dt-bindings/clock/ultrarisc,dp1000-clk.h b/include/dt-bindings/clock/ultrarisc,dp1000-clk.h
new file mode 100644
index 000000000000..5e484f652b08
--- /dev/null
+++ b/include/dt-bindings/clock/ultrarisc,dp1000-clk.h
@@ -0,0 +1,29 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+#ifndef _DT_BINDINGS_CLOCK_ULTRARISC_DP1000_CLK_H
+#define _DT_BINDINGS_CLOCK_ULTRARISC_DP1000_CLK_H
+
+#define DP1000_CLK_SYSPLL		0
+#define DP1000_CLK_SYSPLL_DIV2		1
+#define DP1000_CLK_SUBSYS		2
+#define DP1000_CLK_GMAC			3
+#define DP1000_CLK_UART_ROOT		4
+#define DP1000_CLK_I2C_ROOT		5
+#define DP1000_CLK_SPI_ROOT		6
+#define DP1000_CLK_PCIE_DBI		7
+#define DP1000_CLK_PCIEX4_CORE		8
+#define DP1000_CLK_PCIEX16_CORE		9
+#define DP1000_CLK_PCIE_AUX		10
+#define DP1000_CLK_UART0		11
+#define DP1000_CLK_UART1		12
+#define DP1000_CLK_UART2		13
+#define DP1000_CLK_UART3		14
+#define DP1000_CLK_I2C0			15
+#define DP1000_CLK_I2C1			16
+#define DP1000_CLK_I2C2			17
+#define DP1000_CLK_I2C3			18
+#define DP1000_CLK_SPI0			19
+#define DP1000_CLK_SPI1			20
+
+#define DP1000_CLK_NUM			21
+
+#endif /* _DT_BINDINGS_CLOCK_ULTRARISC_DP1000_CLK_H */

-- 
2.34.1

