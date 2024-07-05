From: Yang Li <yang.li@amlogic.com>
Date: Fri, 05 Jul 2024 19:13:25 +0800
Subject: [PATCH 1/3] dt-bindings: power: Add power sequence for Amloigc WCN
 chips
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240705-pwrseq-v1-1-31829b47fc72@amlogic.com>
References: <20240705-pwrseq-v1-0-31829b47fc72@amlogic.com>
In-Reply-To: <20240705-pwrseq-v1-0-31829b47fc72@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@bgdev.pl>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720178006; l=2253;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=Auw5UiFZ9CP6p9qGv3EDPmIfB9jiHZ0hXlsvvoTN/ac=;
 b=A3eWNA2Xhb2xqKFtC1NDx9O6zNPk8xO2nQ2dBMcUTAi9r8HL2TjivlHCg5VDBH6AYeEOK2Ear
 1bvNUV8YZQHAuYjZKvMOISrEVof3wJSwqigoXnWT8ZWMn5eoq8SQYtK
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add binding document to introduce power sequence of
Amlogic WCN chips.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 .../bindings/power/amlogic,w155s2-pwrseq.yaml      | 62 ++++++++++++++++++++++
 1 file changed, 62 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/amlogic,w155s2-pwrseq.yaml b/Documentation/devicetree/bindings/power/amlogic,w155s2-pwrseq.yaml
new file mode 100644
index 000000000000..f99a775fcf9b
--- /dev/null
+++ b/Documentation/devicetree/bindings/power/amlogic,w155s2-pwrseq.yaml
@@ -0,0 +1,62 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/power/amlogic,w155s2-pwrseq.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Amlogic power sequence for WCN chips
+
+maintainers:
+  - Yang Li <yang.li@amlogic.com>
+
+description:
+  The Amlogic WCN chip contains discrete modules for WLAN and Bluetooth. Power on
+  Bluetooth and Wi-Fi respectively, including chip_en pull-up and bt_en pull-up,
+  and generation of the 32.768KHz clock.
+
+properties:
+  compatible:
+    oneOf:
+      - const: amlogic,w155s2-pwrseq
+      - items:
+          - enum:
+              - amlogic,w265s1-pwrseq
+              - amlogic,w265p1-pwrseq
+              - amlogic,w265s2-pwrseq
+          - const: amlogic,w155s2-pwrseq
+
+  clocks:
+    maxItems: 1
+    description: clock provided to the controller (32.768KHz)
+
+  clock-names:
+    items:
+      - const: ext_clock
+
+  amlogic,chip-enable-gpios:
+    maxItems: 1
+    description: gpio specifier used to enable chipset
+
+  amlogic,bt-enable-gpios:
+    maxItems: 1
+    description: gpio specifier used to enable BT
+
+required:
+  - compatible
+  - clocks
+  - clock-names
+  - amlogic,chip-enable-gpios
+  - amlogic,bt-enable-gpios
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    wcn_pwrseq {
+        compatible = "amlogic,w155s2-pwrseq";
+        clocks = <&extclk>;
+        clock-names = "ext_clock";
+        amlogic,chip-enable-gpios = <&gpio 7 GPIO_ACTIVE_HIGH>;
+        amlogic,bt-enable-gpios = <&gpio 17 GPIO_ACTIVE_HIGH>;
+    };

-- 
2.42.0

