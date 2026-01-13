From: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
Date: Tue, 13 Jan 2026 15:29:48 +0100
Subject: [PATCH 2/2] dt-bindings: pinctrl: mcp23s08: Add multi-chip example
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260113-mcp23s17-multiple-addr-names-v1-2-f14b60f92c82@yoseli.org>
References: <20260113-mcp23s17-multiple-addr-names-v1-0-f14b60f92c82@yoseli.org>
In-Reply-To: <20260113-mcp23s17-multiple-addr-names-v1-0-f14b60f92c82@yoseli.org>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Himanshu Bhavani <himanshu.bhavani@siliconsignals.io>
Cc: linux-gpio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768314588; l=2399;
 i=jeanmichel.hautbois@yoseli.org; s=20240925; h=from:subject:message-id;
 bh=vD/F25SfezAejm8BqlJHgIvltMMe6SW7utp1RO4apSA=;
 b=SJyU0kBOEkWdKLZeURIaGnlMhZb8uEgNvqdqqHlrCYmi5t46OXmtGVKaVb9LN9FI+u+JNqk+6
 TZf3miIOMVEA80L/Sz2IqTGhGktBF9I2T/6ocwqY7IVDrSxb/+a5FlT
X-Developer-Key: i=jeanmichel.hautbois@yoseli.org; a=ed25519;
 pk=MsMTVmoV69wLIlSkHlFoACIMVNQFyvJzvsJSQsn/kq4=
X-Endpoint-Received: by B4 Relay for jeanmichel.hautbois@yoseli.org/20240925 with auth_id=570
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable gpio-line-names property in the schema and add example showing
how to use it with multiple MCP23S08/17/18 chips sharing the same SPI
chip select. Names are assigned sequentially in hardware address order.

Signed-off-by: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
---
 .../bindings/pinctrl/microchip,mcp23s08.yaml       | 33 ++++++++++++++++++++++
 1 file changed, 33 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/microchip,mcp23s08.yaml b/Documentation/devicetree/bindings/pinctrl/microchip,mcp23s08.yaml
index e07f4723de17..667be31b6da3 100644
--- a/Documentation/devicetree/bindings/pinctrl/microchip,mcp23s08.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/microchip,mcp23s08.yaml
@@ -42,6 +42,8 @@ properties:
   interrupts:
     maxItems: 1
 
+  gpio-line-names: true
+
   reset-gpios:
     description: GPIO specifier for active-low reset pin.
     maxItems: 1
@@ -159,3 +161,34 @@ examples:
             microchip,spi-present-mask = /bits/ 8 <0x01>;
         };
     };
+
+  - |
+    /* Multiple chips sharing same SPI CS with gpio-line-names */
+    spi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        gpio@0 {
+            compatible = "microchip,mcp23s17";
+            reg = <0>;
+            gpio-controller;
+            #gpio-cells = <2>;
+            spi-max-frequency = <10000000>;
+            /* Two chips at hardware addresses 0 and 1 */
+            microchip,spi-present-mask = /bits/ 8 <0x03>;
+            /*
+             * Names assigned sequentially in address order.
+             * First 16 names for chip at address 0 (GPA0-7, GPB0-7).
+             * Next 16 names for chip at address 1 (GPA0-7, GPB0-7).
+             */
+            gpio-line-names =
+                "EXP0_GPA0", "EXP0_GPA1", "EXP0_GPA2", "EXP0_GPA3",
+                "EXP0_GPA4", "EXP0_GPA5", "EXP0_GPA6", "EXP0_GPA7",
+                "EXP0_GPB0", "EXP0_GPB1", "EXP0_GPB2", "EXP0_GPB3",
+                "EXP0_GPB4", "EXP0_GPB5", "EXP0_GPB6", "EXP0_GPB7",
+                "EXP1_GPA0", "EXP1_GPA1", "EXP1_GPA2", "EXP1_GPA3",
+                "EXP1_GPA4", "EXP1_GPA5", "EXP1_GPA6", "EXP1_GPA7",
+                "EXP1_GPB0", "EXP1_GPB1", "EXP1_GPB2", "EXP1_GPB3",
+                "EXP1_GPB4", "EXP1_GPB5", "EXP1_GPB6", "EXP1_GPB7";
+        };
+    };

-- 
2.39.5

