From: Pawel Laszczak <pawell@cadence.com>
Date: Thu, 21 May 2026 10:16:23 +0200
Subject: [PATCH v9 1/2] dt-bindings: usb: cdns3: Add cdns,cdnsp compatible
 string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260521-no_drd_config_v9-v9-1-2512cef10104@cadence.com>
References: <20260521-no_drd_config_v9-v9-0-2512cef10104@cadence.com>
In-Reply-To: <20260521-no_drd_config_v9-v9-0-2512cef10104@cadence.com>
To: Peter Chen <peter.chen@kernel.org>, Roger Quadros <rogerq@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Pawel Laszczak <pawell@cadence.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779351391; l=5213;
 i=pawell@cadence.com; h=from:subject:message-id;
 bh=aEGYxRlbH6so/Rcq6gM9uAtHD2TdYB9lVfqtKa4oDlw=;
 b=IrBb9TgdEMIWe9ygOquRluhb9IAOubXzcm5bnJidU/3DOEklleMP/Q5g6rZviQf1JX51lTgDn
 F3561MxwDYXD6Fj6YsKH2KF6RmBmk9eBkgSlo5JyYrmKLJUiZUuKU+A
X-Developer-Key: i=pawell@cadence.com; a=ed25519;
 pk=EUPBvLO9CDg7j6defeDl2iqi+z5Ivqu4Z46aiqe7dYc=
X-Endpoint-Received: by B4 Relay for pawell@cadence.com/default with auth_id=707
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a new generic fallback compatible string 'cdns,cdnsp' for
Cadence USBSSP controllers to support hardware configurations where
the Dual-Role Device (DRD) register block is missing or inaccessible.

Following the maintainer's feedback, avoid generic property-like naming
(such as "-no-drd") and use a clean generic fallback. To keep the schema
resource-driven and strictly validated, define a two-string compatible
matrix using an empty schema ({}) wildcard. This allows future vendor
SoC compatibles to be prepended while safely falling back to the 2-resource
USBSSP configuration.

When 'cdns,cdnsp' is matched:
- The 'otg' register and interrupt resources are not required.
- The 'reg' and 'interrupts' properties are restricted to 2 items
  (host and device).
- 'dr_mode' must be explicitly set to either 'host' or 'peripheral'.

The standard 'cdns,usb3' compatible remains unchanged, maintaining
backward compatibility by requiring all 3 resource sets (otg, host, dev).

Signed-off-by: Pawel Laszczak <pawell@cadence.com>
---
v9:
- Dropped the "cdns,cdnsp-no-drd" string to avoid generic property-like
  naming as requested by Conor.
- Introduced the clean generic fallback "cdns,cdnsp".

v8:
- Update commit message to reflect schema changes.
- Removed 'cdns,no-drd' boolean property as per Rob Herring's suggestion.
- Introduced a new compatible string 'cdns,cdnsp-no-drd' for controller
  variants that lack the DRD/OTG register block.

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
 .../devicetree/bindings/usb/cdns,usb3.yaml         | 63 ++++++++++++++++++----
 1 file changed, 53 insertions(+), 10 deletions(-)

diff --git a/Documentation/devicetree/bindings/usb/cdns,usb3.yaml b/Documentation/devicetree/bindings/usb/cdns,usb3.yaml
index 2d95fb7321af..e8082c5c05a2 100644
--- a/Documentation/devicetree/bindings/usb/cdns,usb3.yaml
+++ b/Documentation/devicetree/bindings/usb/cdns,usb3.yaml
@@ -17,22 +17,24 @@ description:
 
 properties:
   compatible:
-    const: cdns,usb3
+    oneOf:
+      - const: cdns,usb3
+      - items:
+          - {}
+          - const: cdns,cdnsp
 
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
@@ -41,7 +43,7 @@ properties:
                      cleared by xhci core, this interrupt is optional
 
   interrupt-names:
-    minItems: 3
+    minItems: 2
     items:
       - const: host
       - const: peripheral
@@ -93,6 +95,47 @@ allOf:
   - $ref: usb-drd.yaml#
   - $ref: usb-xhci.yaml#
 
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: cdns,cdnsp
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

