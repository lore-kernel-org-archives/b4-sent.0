From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Thu, 12 Sep 2024 16:50:52 +0100
Subject: [PATCH v2 11/20] dt-bindings: timer: Add SC5xx Timer bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240912-sc5xx-upstreaming-patches-v2-11-1185a80df79e@analog.com>
References: <20240912-sc5xx-upstreaming-patches-v2-0-1185a80df79e@analog.com>
In-Reply-To: <20240912-sc5xx-upstreaming-patches-v2-0-1185a80df79e@analog.com>
To: Tom Rini <trini@konsulko.com>, 
 Nathan Barrett-Morrison <nathan.morrison@timesys.com>, 
 Greg Malysa <greg.malysa@timesys.com>, 
 Ian Roberts <ian.roberts@timesys.com>, 
 Vasileios Bimpikas <vasileios.bimpikas@analog.com>, 
 Utsav Agarwal <utsav.agarwal@analog.com>, 
 Arturs Artamonovs <arturs.artamonovs@analog.com>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>
Cc: u-boot@lists.denx.de, adsp-linux@analog.com, 
 Oliver Gaskell <Oliver.Gaskell@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726156261; l=1973;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=mEovLZ/wl3hrw6y+5H6OxXMs0+bH1On1PvvQ3XQU5bs=;
 b=D730dXfU84Xy1cmlRIK9OJt62vC0xoOAV81JdDSr2cba6aY1QyPjeEeaidJFmv+Zl07vhwoTy
 IbXGVxbSWdYC+6RIxn73WiUAj59icv5UtZPrrXHBMcee7q3KpR2douu
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree schema for the timer peripheral on Analog Devices SC5xx
series SoCs.

Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 MAINTAINERS                                        |  1 +
 .../timer/adi,sc5xx-gptimer.yaml                   | 42 ++++++++++++++++++++++
 2 files changed, 43 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index c196368a72..0bc7f2f22d 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -609,6 +609,7 @@ F:	arch/arm/include/asm/arch-adi/
 F:	arch/arm/mach-sc5xx/
 F:	doc/device-tree-bindings/arm/adi/adi,sc5xx.yaml
 F:	doc/device-tree-bindings/clock/adi,sc5xx-clocks.yaml
+F:	doc/device-tree-bindings/timer/adi,sc5xx-gptimer.yaml
 F:	drivers/clk/adi/
 F:	drivers/serial/serial_adi_uart4.c
 F:	drivers/timer/adi_sc5xx_timer.c
diff --git a/doc/device-tree-bindings/timer/adi,sc5xx-gptimer.yaml b/doc/device-tree-bindings/timer/adi,sc5xx-gptimer.yaml
new file mode 100644
index 0000000000..5e313af6fe
--- /dev/null
+++ b/doc/device-tree-bindings/timer/adi,sc5xx-gptimer.yaml
@@ -0,0 +1,42 @@
+# SPDX-License-Identifier: (GPL-2.0+)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/timer/adi,sc5xx-gptimer.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Analog Devices SC5XX Series SoC Timer Peripherals
+
+maintainers:
+  - Vasileios Bimpikas <vasileios.bimpikas@analog.com>
+  - Utsav Agarwal <utsav.agarwal@analog.com>
+  - Arturs Artamonovs <arturs.artamonovs@analog.com>
+
+properties:
+  compatible:
+    const: adi,sc5xx-gptimer
+
+  reg:
+    minItems: 2
+    maxItems: 2
+
+  clocks:
+    minItems: 1
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+  - clocks
+
+additionalProperties: false
+
+examples:
+  - |
+    timer0: timer@31018000 {
+      compatible = "adi,sc5xx-gptimer";
+      reg = <0x31018004 0x100>,
+            <0x31018060 0x100>;
+      status = "okay";
+      bootph-all;
+    };
+

-- 
2.34.1

