From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Mon, 28 Jul 2025 17:39:29 +0200
Subject: [PATCH 1/2] dt-bindings: phy: add support for NXPs TJA1145 CAN
 transceiver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250728-tja1145-support-v1-1-ebd8494d545c@liebherr.com>
References: <20250728-tja1145-support-v1-0-ebd8494d545c@liebherr.com>
In-Reply-To: <20250728-tja1145-support-v1-0-ebd8494d545c@liebherr.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753717177; l=2250;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=yrzBTmcx39zZhA3B4Bmom+/Ve4V+seQpPo+U7ONsiAo=;
 b=KhSNFKffrIFnWTTO5yAeLdNiDimIL6feKrhTGJYwDBLXzqpYOUY4N+2UQtYk8nL2VCutAXa6J
 Psy8g12k+CxCavpUNWBF14bOtn8HX2E64ftVkl10v0ieITrJjqSGBbK
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adding documentation for NXPs TJA1145 CAN transceiver.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 .../devicetree/bindings/phy/nxp,tja1145-can.yaml   | 79 ++++++++++++++++++++++
 1 file changed, 79 insertions(+)

diff --git a/Documentation/devicetree/bindings/phy/nxp,tja1145-can.yaml b/Documentation/devicetree/bindings/phy/nxp,tja1145-can.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..10bf2bce1b35788b3284c42e544a56eda6d79947
--- /dev/null
+++ b/Documentation/devicetree/bindings/phy/nxp,tja1145-can.yaml
@@ -0,0 +1,79 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/phy/nxp,tja1145-can.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: TJA1145 CAN transceiver
+
+maintainers:
+  - Dimitri Fedrau <dimitri.fedrau@liebherr.com>
+
+allOf:
+  - $ref: /schemas/spi/spi-peripheral-props.yaml#
+
+properties:
+  compatible:
+    const: nxp,tja1145
+
+  "#phy-cells":
+    const: 0
+
+  reg:
+    maxItems: 1
+
+  spi-max-frequency:
+    maximum: 4000000
+
+  spi-cpha: true
+
+  spi-cs-setup-delay-ns:
+    minimum: 50
+    default: 50
+
+  spi-cs-hold-delay-ns:
+    minimum: 50
+    default: 50
+
+  spi-cs-inactive-delay-ns:
+    minimum: 250
+    default: 250
+
+  vcc-supply:
+    description:
+      CAN transceiver supply voltage
+
+  vio-supply:
+    description:
+      Supply voltage for I/O level adaptor
+
+  vbat-supply:
+    description:
+      Battery supply voltage
+
+required:
+  - compatible
+  - "#phy-cells"
+  - reg
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    spi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+        canphy@0 {
+            compatible = "nxp,tja1145";
+            #phy-cells = <0>;
+            reg = <0>;
+            spi-max-frequency = <4000000>;
+            spi-cpha;
+            spi-cs-setup-delay-ns = <50>;
+            spi-cs-hold-delay-ns = <50>;
+            spi-cs-inactive-delay-ns = <250>;
+            vcc-supply = <&reg_5v0>;
+            vio-supply = <&reg_3v3>;
+            vbat-supply = <&reg_24v0>;
+        };
+    };

-- 
2.39.5

