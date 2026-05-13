From: Pawel Laszczak <pawell@cadence.com>
Date: Wed, 13 May 2026 10:41:21 +0200
Subject: [PATCH v5 1/2] dt-bindings: usb: cdns3: Add no_drd property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260513-b4-no_drd_config-v5-1-1c633a4b9a29@cadence.com>
References: <20260513-b4-no_drd_config-v5-0-1c633a4b9a29@cadence.com>
In-Reply-To: <20260513-b4-no_drd_config-v5-0-1c633a4b9a29@cadence.com>
To: Peter Chen <peter.chen@kernel.org>, Roger Quadros <rogerq@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Pawel Laszczak <pawell@cadence.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778661701; l=4313;
 i=pawell@cadence.com; h=from:subject:message-id;
 bh=70m2WrB+gScioT1IsprmvK92HHYRKuQVzJyfW+KyZbY=;
 b=0l/te2BTU/L20Tg7xd22LeIKnJhrM7zr7sXKEDV+cBr/F0NB/K70bZm5bnK2HMGM6DeflAtmi
 VFDtaE0W8r3BVpjgjZMAcCHfxuiXYk3AWEDelRWQVydkw3dNqsPlLGg
X-Developer-Key: i=pawell@cadence.com; a=ed25519;
 pk=EUPBvLO9CDg7j6defeDl2iqi+z5Ivqu4Z46aiqe7dYc=
X-Endpoint-Received: by B4 Relay for pawell@cadence.com/default with auth_id=707
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a new boolean property 'no_drd' for Cadence USBSS/USBSSP
controllers to support hardware configurations where the Dual-Role
Device (DRD) register block is missing or inaccessible.

When 'no_drd' is present:
- The 'otg' register and interrupt resources are not required.
- The 'reg' and 'interrupts' properties are restricted to 2 items
  (host and device).
- 'dr_mode' must be explicitly set to either 'host' or 'peripheral'.

When 'no_drd' is absent, the binding maintains backward compatibility
by requiring all 3 resource sets (otg, host, dev).

To achieve this, the schema is updated with an if-then-else logic
and 'reg-names'/'interrupt-names' use enums to allow flexible
ordering during validation.

Signed-off-by: Pawel Laszczak <pawell@cadence.com>
---
v5:
- Implemented strict conditional validation using if-then-else logic.
- Enforced 2 register/interrupt items and required 'dr_mode'
  (host or peripheral) when 'no_drd' is present.
- Enforced the standard 3 register/interrupt items (otg, host, dev)
  when 'no_drd' is absent to ensure backward compatibility.
- Updated 'reg-names' and 'interrupt-names' to use enums in the main
  properties section to support flexible resource ordering during
  validation.
---
---
 .../devicetree/bindings/usb/cdns,usb3.yaml         | 67 +++++++++++++++++++---
 1 file changed, 58 insertions(+), 9 deletions(-)

diff --git a/Documentation/devicetree/bindings/usb/cdns,usb3.yaml b/Documentation/devicetree/bindings/usb/cdns,usb3.yaml
index 2d95fb7321af..5d9bea62729c 100644
--- a/Documentation/devicetree/bindings/usb/cdns,usb3.yaml
+++ b/Documentation/devicetree/bindings/usb/cdns,usb3.yaml
@@ -20,19 +20,21 @@ properties:
     const: cdns,usb3
 
   reg:
+    minItems: 2
     items:
       - description: OTG controller registers
       - description: XHCI Host controller registers
       - description: DEVICE controller registers
 
   reg-names:
+    minItems: 2
     items:
-      - const: otg
-      - const: xhci
-      - const: dev
+      - enum: [ otg, xhci, dev ]
+      - enum: [ otg, xhci, dev ]
+      - enum: [ otg, xhci, dev ]
 
   interrupts:
-    minItems: 3
+    minItems: 2
     items:
       - description: XHCI host controller interrupt
       - description: Device controller interrupt
@@ -41,12 +43,12 @@ properties:
                      cleared by xhci core, this interrupt is optional
 
   interrupt-names:
-    minItems: 3
+    minItems: 2
     items:
-      - const: host
-      - const: peripheral
-      - const: otg
-      - const: wakeup
+      - enum: [ host, peripheral, otg, wakeup ]
+      - enum: [ host, peripheral, otg, wakeup ]
+      - enum: [ host, peripheral, otg, wakeup ]
+      - enum: [ host, peripheral, otg, wakeup ]
 
   port:
     $ref: /schemas/graph.yaml#/properties/port
@@ -79,6 +81,13 @@ properties:
     description: Enable resetting of PHY if Rx fail is detected
     type: boolean
 
+  no_drd:
+    description:
+      Indicates that the Dual-Role Device (DRD) register block is not
+      implemented or is inaccessible. In this case, the controller
+      must operate in a fixed peripheral or host mode.
+    type: boolean
+
 dependencies:
   port: [ usb-role-switch ]
 
@@ -93,6 +102,46 @@ allOf:
   - $ref: usb-drd.yaml#
   - $ref: usb-xhci.yaml#
 
+  - if:
+      properties:
+        no_drd: true
+      required:
+        - no_drd
+    then:
+      required:
+        - dr_mode
+      properties:
+        reg:
+          maxItems: 2
+        reg-names:
+          items:
+            - const: xhci
+            - const: dev
+        interrupts:
+          maxItems: 2
+        interrupt-names:
+          items:
+            - const: host
+            - const: peripheral
+        dr_mode:
+          enum: [host, peripheral]
+    else:
+      properties:
+        reg:
+          minItems: 3
+        reg-names:
+          items:
+            - const: otg
+            - const: xhci
+            - const: dev
+        interrupts:
+          minItems: 3
+        interrupt-names:
+          items:
+            - const: host
+            - const: peripheral
+            - const: otg
+
 unevaluatedProperties: false
 
 examples:

-- 
2.43.0

