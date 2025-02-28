From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 28 Feb 2025 18:32:50 +0100
Subject: [PATCH v2 1/3] dt-bindings: net: Convert fsl,gianfar-{mdio,tbi} to
 YAML
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250228-gianfar-yaml-v2-1-6beeefbd4818@posteo.net>
References: <20250228-gianfar-yaml-v2-0-6beeefbd4818@posteo.net>
In-Reply-To: <20250228-gianfar-yaml-v2-0-6beeefbd4818@posteo.net>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Claudiu Manoil <claudiu.manoil@nxp.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740763971; l=6137;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=FCfdH7CYgs2HMWUtgO2Kr9tfttQkVuvNzc3Tc1aCf2A=;
 b=8irhqlR2weuPW/6zc6rywF4fLk+LFj0/mTGaobz+UPw2FG2CLoeL0AtZ1Eh7r51BK76I2qZW3
 0tCOXs+XfvaBN+uxU6d4JkxMCSseq3DITbgq5IzKo26Rvl1UkQKfDFB
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the information related to the Freescale Gianfar (TSEC) MDIO bus
and the Ten-Bit Interface (TBI) from fsl-tsec-phy.txt to a new binding
file in YAML format, fsl,gianfar-mdio.yaml.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

V2:
- remove definitions of #address/size-cells (already in mdio.yaml)
- disambiguate compatible = "gianfar" schemas by using a "select:" schema
---
 .../devicetree/bindings/net/fsl,gianfar-mdio.yaml  | 113 +++++++++++++++++++++
 .../devicetree/bindings/net/fsl-tsec-phy.txt       |  41 +-------
 2 files changed, 115 insertions(+), 39 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/fsl,gianfar-mdio.yaml b/Documentation/devicetree/bindings/net/fsl,gianfar-mdio.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..22369771c13614875845b6d6e6d6031b933cb152
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/fsl,gianfar-mdio.yaml
@@ -0,0 +1,113 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/net/fsl,gianfar-mdio.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Freescale Gianfar (TSEC) MDIO Device
+
+description:
+  This binding describes the MDIO is a bus to which the PHY devices are
+  connected. For each device that exists on this bus, a child node should be
+  created.
+
+  As of this writing, every TSEC is associated with an internal Ten-Bit
+  Interface (TBI) PHY. This PHY is accessed through the local MDIO bus. These
+  buses are defined similarly to the mdio buses, except they are compatible
+  with "fsl,gianfar-tbi". The TBI PHYs underneath them are similar to normal
+  PHYs, but the reg property is considered instructive, rather than
+  descriptive. The reg property should be chosen so it doesn't interfere with
+  other PHYs on the bus.
+
+maintainers:
+  - J. Neuschäfer <j.ne@posteo.net>
+
+# This is needed to distinguish gianfar.yaml and gianfar-mdio.yaml, because
+# both use compatible = "gianfar" (with different device_type values)
+select:
+  oneOf:
+    - properties:
+        compatible:
+          contains:
+            const: gianfar
+        device_type:
+          const: mdio
+      required:
+        - device_type
+
+    - properties:
+        compatible:
+          contains:
+            enum:
+              - fsl,gianfar-tbi
+              - fsl,gianfar-mdio
+              - fsl,etsec2-tbi
+              - fsl,etsec2-mdio
+              - fsl,ucc-mdio
+              - ucc_geth_phy
+
+  required:
+    - compatible
+
+properties:
+  compatible:
+    enum:
+      - fsl,gianfar-tbi
+      - fsl,gianfar-mdio
+      - fsl,etsec2-tbi
+      - fsl,etsec2-mdio
+      - fsl,ucc-mdio
+      - gianfar
+      - ucc_geth_phy
+
+  reg:
+    minItems: 1
+    items:
+      - description:
+          Offset and length of the register set for the device
+
+      - description:
+          Optionally, the offset and length of the TBIPA register (TBI PHY
+          address register). If TBIPA register is not specified, the driver
+          will attempt to infer it from the register set specified (your
+          mileage may vary).
+
+  device_type:
+    const: mdio
+
+required:
+  - reg
+  - "#address-cells"
+  - "#size-cells"
+
+allOf:
+  - $ref: mdio.yaml#
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: ucc_geth_phy
+    then:
+      required:
+        - device_type
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    soc {
+        #address-cells = <1>;
+        #size-cells = <1>;
+
+        mdio@24520 {
+            reg = <0x24520 0x20>;
+            compatible = "fsl,gianfar-mdio";
+            #address-cells = <1>;
+            #size-cells = <0>;
+
+            ethernet-phy@0 {
+                reg = <0>;
+            };
+        };
+    };
diff --git a/Documentation/devicetree/bindings/net/fsl-tsec-phy.txt b/Documentation/devicetree/bindings/net/fsl-tsec-phy.txt
index 9c9668c1b6a24edff7b7cf625b9f14c3cbc2e0c8..0e55e0af7d6f59cfb571dd3fcff704b7f4c140d2 100644
--- a/Documentation/devicetree/bindings/net/fsl-tsec-phy.txt
+++ b/Documentation/devicetree/bindings/net/fsl-tsec-phy.txt
@@ -1,47 +1,10 @@
 * MDIO IO device
 
-The MDIO is a bus to which the PHY devices are connected.  For each
-device that exists on this bus, a child node should be created.  See
-the definition of the PHY node in booting-without-of.txt for an example
-of how to define a PHY.
-
-Required properties:
-  - reg : Offset and length of the register set for the device, and optionally
-          the offset and length of the TBIPA register (TBI PHY address
-	  register).  If TBIPA register is not specified, the driver will
-	  attempt to infer it from the register set specified (your mileage may
-	  vary).
-  - compatible : Should define the compatible device type for the
-    mdio. Currently supported strings/devices are:
-	- "fsl,gianfar-tbi"
-	- "fsl,gianfar-mdio"
-	- "fsl,etsec2-tbi"
-	- "fsl,etsec2-mdio"
-	- "fsl,ucc-mdio"
-	- "fsl,fman-mdio"
-    When device_type is "mdio", the following strings are also considered:
-	- "gianfar"
-	- "ucc_geth_phy"
-
-Example:
-
-	mdio@24520 {
-		reg = <24520 20>;
-		compatible = "fsl,gianfar-mdio";
-
-		ethernet-phy@0 {
-			......
-		};
-	};
+Refer to Documentation/devicetree/bindings/net/fsl,gianfar-mdio.yaml
 
 * TBI Internal MDIO bus
 
-As of this writing, every tsec is associated with an internal TBI PHY.
-This PHY is accessed through the local MDIO bus.  These buses are defined
-similarly to the mdio buses, except they are compatible with "fsl,gianfar-tbi".
-The TBI PHYs underneath them are similar to normal PHYs, but the reg property
-is considered instructive, rather than descriptive.  The reg property should
-be chosen so it doesn't interfere with other PHYs on the bus.
+Refer to Documentation/devicetree/bindings/net/fsl,gianfar-mdio.yaml
 
 * Gianfar-compatible ethernet nodes
 

-- 
2.48.0.rc1.219.gb6b6757d772

