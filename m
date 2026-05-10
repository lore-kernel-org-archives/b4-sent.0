From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Mon, 11 May 2026 01:32:10 +0700
Subject: [PATCH v2 2/3] dt-bindings: usb: add Rohm BM92TXX Type-C
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-bm92t-v2-2-2145e4f4386b@gmail.com>
References: <20260511-bm92t-v2-0-2145e4f4386b@gmail.com>
In-Reply-To: <20260511-bm92t-v2-0-2145e4f4386b@gmail.com>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, CTCaer <ctcaer@gmail.com>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778437929; l=5274;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=ozSJxakD3nLP0mwcFo/HHRulxXgmVTFqvb1G9vOg8aA=;
 b=str+uEhL/W9VY7JlxX7kSsLWdT7JI0aIsKLlqJz09RBsFKPPY4IND5RjuKH50gVlG0A2fQbSL
 K/CwdLQTmreBlHnFg81lWVYhP31zm1Q642MeL7WKw3NExLONdsB66bC
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the device-tree binding documentation for the Rohm BM92TXX family
of USB Type-C and Power Delivery controllers. The device is controlled
over I2C and signals state changes through a dedicated interrupt line.

Document the rohm,* properties consumed by the driver: the optional
VCONN-enable GPIO, the DisplayPort alternate-mode toggles
(rohm,dp-disable, rohm,dp-alerts-enable, rohm,dp-signal-toggle-on-resume,
rohm,dp-lanes), the suspend/dock tunables (rohm,led-static-on-suspend,
rohm,dock-power-limit-disable) and the four
rohm,pd-{5,9,12,15}v-current-limit-ma per-PDO charging current limits.
A graph port is required to link the controller to a USB role switch
consumer.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
 .../devicetree/bindings/usb/rohm,bm92t.yaml        | 128 +++++++++++++++++++++
 MAINTAINERS                                        |   1 +
 2 files changed, 129 insertions(+)

diff --git a/Documentation/devicetree/bindings/usb/rohm,bm92t.yaml b/Documentation/devicetree/bindings/usb/rohm,bm92t.yaml
new file mode 100644
index 000000000000..007f70a8f5bb
--- /dev/null
+++ b/Documentation/devicetree/bindings/usb/rohm,bm92t.yaml
@@ -0,0 +1,128 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/usb/rohm,bm92t.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Rohm BM92TXX USB Type-C and Power Delivery controller
+
+maintainers:
+  - CTCaer <ctcaer@gmail.com>
+  - Alexandre Hamamdjian <azkali.limited@gmail.com>
+
+description:
+  The Rohm BM92TXX is a family of USB Type-C and Power Delivery
+  controllers with an integrated MCU. The host communicates with the
+  device over I2C and is notified of state changes through a dedicated
+  interrupt line.
+
+properties:
+  compatible:
+    const: rohm,bm92t
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  vbus-supply:
+    description: VBUS sink regulator.
+
+  vbus-source-supply:
+    description: VBUS source (provider) regulator.
+
+  pd_bat_chg-supply:
+    description: Battery charger regulator gated by Power Delivery state.
+
+  rohm,vconn-en-gpio:
+    maxItems: 1
+    description: GPIO controlling the external VCONN switch.
+
+  rohm,dp-disable:
+    type: boolean
+    description: Disable DisplayPort alternate-mode handling.
+
+  rohm,dp-alerts-enable:
+    type: boolean
+    description: Enable DisplayPort status alerts.
+
+  rohm,dp-signal-toggle-on-resume:
+    type: boolean
+    description:
+      Toggle the DisplayPort signal on resume to work around sinks that
+      do not re-train after system resume.
+
+  rohm,dp-lanes:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    enum: [2, 4]
+    default: 2
+    description: Number of DisplayPort lanes to negotiate.
+
+  rohm,led-static-on-suspend:
+    type: boolean
+    description:
+      Keep the charge LED in a static state during system suspend
+      instead of letting the controller animate it.
+
+  rohm,dock-power-limit-disable:
+    type: boolean
+    description:
+      Disable the lower power limit applied when a dock is detected.
+
+  rohm,pd-5v-current-limit-ma:
+    description: Charging current limit in mA when 5V PD contract is active.
+
+  rohm,pd-9v-current-limit-ma:
+    description: Charging current limit in mA when 9V PD contract is active.
+
+  rohm,pd-12v-current-limit-ma:
+    description: Charging current limit in mA when 12V PD contract is active.
+
+  rohm,pd-15v-current-limit-ma:
+    description: Charging current limit in mA when 15V PD contract is active.
+
+  port:
+    $ref: /schemas/graph.yaml#/properties/port
+    description:
+      Output port linking to a USB role switch consumer endpoint.
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - port
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        typec@18 {
+            compatible = "rohm,bm92t";
+            reg = <0x18>;
+            interrupt-parent = <&gpio>;
+            interrupts = <42 IRQ_TYPE_LEVEL_LOW>;
+
+            vbus-supply = <&vbus_reg>;
+            vbus-source-supply = <&vbus_src_reg>;
+            pd_bat_chg-supply = <&pd_bat_chg_reg>;
+
+            rohm,dp-lanes = <4>;
+            rohm,pd-5v-current-limit-ma = <2000>;
+            rohm,pd-9v-current-limit-ma = <2000>;
+            rohm,pd-12v-current-limit-ma = <1500>;
+            rohm,pd-15v-current-limit-ma = <1200>;
+
+            port {
+                bm92t_ep: endpoint {
+                    remote-endpoint = <&usb_role_sw>;
+                };
+            };
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 01e06d87b926..8e8a23cad7c8 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -23311,6 +23311,7 @@ M:	CTCaer <ctcaer@gmail.com>
 M:	Alexandre Hamamdjian <azkali.limited@gmail.com>
 L:	linux-usb@vger.kernel.org
 S:	Maintained
+F:	Documentation/devicetree/bindings/usb/rohm,bm92t.yaml
 F:	drivers/usb/typec/bm92txx.c
 
 ROHM BU270xx LIGHT SENSOR DRIVERs

-- 
2.54.0

