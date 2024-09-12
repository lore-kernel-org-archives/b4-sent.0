From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Thu, 12 Sep 2024 16:50:50 +0100
Subject: [PATCH v2 09/20] dt-bindings: arm: Add SC5xx Series binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240912-sc5xx-upstreaming-patches-v2-9-1185a80df79e@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726156261; l=2238;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=dFVq21MzW+Qn8vGlIPcqV15XX2w4OewWsH/lJyVSE3A=;
 b=X788CBIrdvqg7X7j3tG5p2VxjCkpZTRQ5ywrkvGNsZT9EbHyOgocVyFrMfwsclYDDmVj1nklL
 Jw3snbTaIXgCGtWR69VIZ+jNgEiPS/S4MU5lRCPSewqueSRtZrqKf32
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree schema for Analog Devices SC5xx series SoCs.

Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 MAINTAINERS                                     |  1 +
 doc/device-tree-bindings/arm/adi/adi,sc5xx.yaml | 46 +++++++++++++++++++++++++
 2 files changed, 47 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index b172e1ea95..38ac172c03 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -607,6 +607,7 @@ T:	git https://github.com/analogdevicesinc/lnxdsp-u-boot
 F:	arch/arm/dts/sc5*
 F:	arch/arm/include/asm/arch-adi/
 F:	arch/arm/mach-sc5xx/
+F:	doc/device-tree-bindings/arm/adi/adi,sc5xx.yaml
 F:	drivers/clk/adi/
 F:	drivers/serial/serial_adi_uart4.c
 F:	drivers/timer/adi_sc5xx_timer.c
diff --git a/doc/device-tree-bindings/arm/adi/adi,sc5xx.yaml b/doc/device-tree-bindings/arm/adi/adi,sc5xx.yaml
new file mode 100644
index 0000000000..df976c7ae7
--- /dev/null
+++ b/doc/device-tree-bindings/arm/adi/adi,sc5xx.yaml
@@ -0,0 +1,46 @@
+# SPDX-License-Identifier: (GPL-2.0+)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/arm/adi/adi,sc5xx.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Analog Devices SC5XX ARM-based SoCs
+
+maintainers:
+  - Vasileios Bimpikas <vasileios.bimpikas@analog.com>
+  - Utsav Agarwal <utsav.agarwal@analog.com>
+  - Arturs Artamonovs <arturs.artamonovs@analog.com>
+
+properties:
+  $nodename:
+    const: '/'
+  compatible:
+    oneOf:
+      - description: SC57X Series Boards
+        items:
+          - const: adi,sc573-ezkit
+          - const: adi,sc57x
+
+      - description: SC58X Series Boards
+        items:
+          - enum:
+            - adi,sc584-ezkit
+            - adi,sc589-ezkit
+            - adi,sc589-mini
+          - const: adi,sc58x
+
+      - description: SC59X Series 32-bit Boards
+        items:
+          - enum:
+            - adi,sc594-som-ezkit
+            - adi,sc594-som-ezlite
+          - const: adi,sc59x
+
+      - description: SC59X Series 64-bit Boards
+        items:
+          - enum:
+            - adi,sc598-som-ezkit
+            - adi,sc598-som-ezlite
+          - const: adi,sc59x-64
+
+additionalProperties: true

-- 
2.34.1

