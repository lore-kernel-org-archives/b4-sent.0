From: Mikael Gonella-Bolduc <mgonellabolduc@dimonoff.com>
Date: Tue, 19 Nov 2024 15:36:56 -0500
Subject: [PATCH 1/2] dt-bindings: iio: light: Add APDS9160 binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241119-apds9160-driver-v1-1-fa00675b4ea4@dimonoff.com>
References: <20241119-apds9160-driver-v1-0-fa00675b4ea4@dimonoff.com>
In-Reply-To: <20241119-apds9160-driver-v1-0-fa00675b4ea4@dimonoff.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>
Cc: Mikael Gonella-Bolduc <m.gonella.bolduc@gmail.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, llvm@lists.linux.dev, 
 Mikael Gonella-Bolduc <mgonellabolduc@dimonoff.com>, 
 Hugo Villeneuve <hvilleneuve@dimonoff.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732048621; l=1677;
 i=mgonellabolduc@dimonoff.com; s=20241119; h=from:subject:message-id;
 bh=MyhZj/K793WP3q4NesJzysEVuCCKb6IcZKJIuThoJ/Y=;
 b=vjNvPdct8qXA1+JHHHHkGD75WVzMdskg5mJkJne7yODyjuOPp4cmXSFLAJ7q7oq9jfrAIYgj/
 UXBRSVznXPRAPeuyq0UnghbHSeSh/i3U1v8dDg/lWtgwu95G/+0w5hs
X-Developer-Key: i=mgonellabolduc@dimonoff.com; a=ed25519;
 pk=p4tvPfGPfXRyChsgHc6s7HwB6YBl2JqqcP3BXtoDitE=
X-Endpoint-Received: by B4 Relay for mgonellabolduc@dimonoff.com/20241119 with auth_id=279
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree bindings for APDS9160 driver

Signed-off-by: Mikael Gonella-Bolduc <mgonellabolduc@dimonoff.com>
---
 .../bindings/iio/light/avago,apds9160.yaml         | 50 ++++++++++++++++++++++
 1 file changed, 50 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/light/avago,apds9160.yaml b/Documentation/devicetree/bindings/iio/light/avago,apds9160.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..12e196b297fe523e4d324156041ef9c6900676eb
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/light/avago,apds9160.yaml
@@ -0,0 +1,50 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/light/avago,apds9160.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Broadcom Combined Proximity & Ambient light sensor
+
+maintainers:
+  - Mikael Gonella-Bolduc <m.gonella.bolduc@gmail.com>
+
+description: |
+  Datasheet: https://docs.broadcom.com/docs/APDS-9160-003-DS
+
+properties:
+  compatible:
+    enum:
+      - avago,apds9160
+      - broadmobi,apds9160
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  vdd-supply: true
+
+additionalProperties: false
+
+required:
+  - compatible
+  - reg
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        apds9160@53 {
+          compatible = "broadmobi,apds9160";
+          reg = <0x53>;
+          interrupts = <29 IRQ_TYPE_EDGE_FALLING>;
+          interrupt-parent = <&pinctrl>;
+        };
+    };
+...

-- 
2.34.1

