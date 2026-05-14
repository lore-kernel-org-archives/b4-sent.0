From: Pawel Laszczak <pawell@cadence.com>
Date: Thu, 14 May 2026 08:00:51 +0200
Subject: [PATCH v7 1/2] dt-bindings: usb: cdns3: Add cdns,no-drd property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260514-b4-no_drd_config-v7-1-18cc40e363fd@cadence.com>
References: <20260514-b4-no_drd_config-v7-0-18cc40e363fd@cadence.com>
In-Reply-To: <20260514-b4-no_drd_config-v7-0-18cc40e363fd@cadence.com>
To: Peter Chen <peter.chen@kernel.org>, Roger Quadros <rogerq@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Pawel Laszczak <pawell@cadence.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778738460; l=4746;
 i=pawell@cadence.com; h=from:subject:message-id;
 bh=tbJcxqWliRwq9sOBLnSckORm/H18puu1GemD56Jsc9s=;
 b=yaW2SLS6nFayNCohlvSbaQa7f6LIdZFfX9fzVmiFw8rcN0B2aYBRSnT/3FhsAwAI/urKgSX6u
 SnOfW89s6NxCycqnk2NWaDxGO9SKtaWH+7Jop8NPHcFN+RpkctsqUGD
X-Developer-Key: i=pawell@cadence.com; a=ed25519;
 pk=EUPBvLO9CDg7j6defeDl2iqi+z5Ivqu4Z46aiqe7dYc=
X-Endpoint-Received: by B4 Relay for pawell@cadence.com/default with auth_id=707
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a new boolean property 'cdns,no-drd' for Cadence USBSS/USBSSP
controllers to support hardware configurations where the Dual-Role
Device (DRD) register block is missing or inaccessible.

When 'cdns,no-drd' is present:
- The 'otg' register and interrupt resources are not required.
- The 'reg' and 'interrupts' properties are restricted to 2 items
  (host and device).
- 'dr_mode' must be explicitly set to either 'host' or 'peripheral'.

When 'cdns,no-drd' is absent, the binding maintains backward compatibility
by requiring all 3 resource sets (otg, host, dev).

To achieve this, the schema is updated with an if-then-else logic
and 'reg-names' use enums to allow flexible
ordering during validation.

Signed-off-by: Pawel Laszczak <pawell@cadence.com>
---
v7:
- Rename 'no_drd' to 'cdns,no-drd'.
- Update commit message to reflect property renaming and schema changes.
- Simplify 'reg-names' using a single enum.
- Revert 'interrupt-names' to a list of constants.
- Move 'reg' item descriptions to if/else blocks for accuracy.
- Clean up 'if/then' logic (remove redundant checks).
- Add explicit 'items' list for 'interrupt-names' in the 'else' block.

v6:
- Fixed validation error for 'interrupt-names' by correcting
  the items definition.
- Adjusted 'minItems'/'maxItems' to properly support the optional
 'wakeup' interrupt.
- Fixed 'too long' schema error in examples.

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
 .../devicetree/bindings/usb/cdns,usb3.yaml         | 62 ++++++++++++++++++----
 1 file changed, 53 insertions(+), 9 deletions(-)

diff --git a/Documentation/devicetree/bindings/usb/cdns,usb3.yaml b/Documentation/devicetree/bindings/usb/cdns,usb3.yaml
index 2d95fb7321af..068fb55a5414 100644
--- a/Documentation/devicetree/bindings/usb/cdns,usb3.yaml
+++ b/Documentation/devicetree/bindings/usb/cdns,usb3.yaml
@@ -20,19 +20,17 @@ properties:
     const: cdns,usb3
 
   reg:
-    items:
-      - description: OTG controller registers
-      - description: XHCI Host controller registers
-      - description: DEVICE controller registers
+    minItems: 2
+    maxItems: 3
 
   reg-names:
+    minItems: 2
+    maxItems: 3
     items:
-      - const: otg
-      - const: xhci
-      - const: dev
+      enum: [ otg, xhci, dev ]
 
   interrupts:
-    minItems: 3
+    minItems: 2
     items:
       - description: XHCI host controller interrupt
       - description: Device controller interrupt
@@ -41,7 +39,7 @@ properties:
                      cleared by xhci core, this interrupt is optional
 
   interrupt-names:
-    minItems: 3
+    minItems: 2
     items:
       - const: host
       - const: peripheral
@@ -79,6 +77,13 @@ properties:
     description: Enable resetting of PHY if Rx fail is detected
     type: boolean
 
+  cdns,no-drd:
+    description:
+      Indicates that the Dual-Role Device (DRD) register block is not
+      implemented or is inaccessible. In this case, the controller
+      must operate in a fixed peripheral or host mode.
+    type: boolean
+
 dependencies:
   port: [ usb-role-switch ]
 
@@ -93,6 +98,45 @@ allOf:
   - $ref: usb-drd.yaml#
   - $ref: usb-xhci.yaml#
 
+  - if:
+      required:
+        - cdns,no-drd
+    then:
+      properties:
+        reg:
+          items:
+            - description: XHCI Host controller registers
+            - description: DEVICE controller registers
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
+          items:
+            - description: OTG controller registers
+            - description: XHCI Host controller registers
+            - description: DEVICE controller registers
+        reg-names:
+          items:
+            - const: otg
+            - const: xhci
+            - const: dev
+        interrupts:
+          minItems: 3
+          maxItems: 4
+        interrupt-names:
+          minItems: 3
+
 unevaluatedProperties: false
 
 examples:

-- 
2.43.0

