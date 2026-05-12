From: Pawel Laszczak <pawell@cadence.com>
Date: Tue, 12 May 2026 13:44:24 +0200
Subject: [PATCH v4 1/2] dt-bindings: usb: cdns3: Add no_drd property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260512-b4-no_drd_config-v4-1-7b4e5dc96f81@cadence.com>
References: <20260512-b4-no_drd_config-v4-0-7b4e5dc96f81@cadence.com>
In-Reply-To: <20260512-b4-no_drd_config-v4-0-7b4e5dc96f81@cadence.com>
To: Peter Chen <peter.chen@kernel.org>, Roger Quadros <rogerq@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Pawel Laszczak <pawell@cadence.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778586339; l=2180;
 i=pawell@cadence.com; h=from:subject:message-id;
 bh=/kNcPspzXZFYJBg5ohgq9BtuLbmn3AUVI191xj7NPV4=;
 b=jOT6HoVOR3goRlmKhYCr203RCP3s5A0sz8h3MZC86tRERzH6mzLZC8vKaEXOwn36S0Pr9fZvV
 mYnFcY+BJC/BbLOoO7FvHSMoJIPnNbqQ7mnkJ7QDTrAZfS2BfxLA0ld
X-Developer-Key: i=pawell@cadence.com; a=ed25519;
 pk=EUPBvLO9CDg7j6defeDl2iqi+z5Ivqu4Z46aiqe7dYc=
X-Endpoint-Received: by B4 Relay for pawell@cadence.com/default with auth_id=707
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a new boolean property 'no_drd' for Cadence USBSS/USBSSP
controllers.

Some hardware configurations of this controller are designed without
the Dual-Role Device (DRD) register block or have it inaccessible.
In such cases, the driver must skip all OTG/DRD register accesses
to avoid bus errors and cannot rely on hardware-based role switching.

To accommodate these configurations, also relax the requirements for
the 'reg' and 'interrupts' properties, making the 'otg' resources
optional.

Signed-off-by: Pawel Laszczak <pawell@cadence.com>
---
 Documentation/devicetree/bindings/usb/cdns,usb3.yaml | 13 +++++++++++--
 1 file changed, 11 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/usb/cdns,usb3.yaml b/Documentation/devicetree/bindings/usb/cdns,usb3.yaml
index 2d95fb7321af..8c7dc81708fb 100644
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
       - const: otg
       - const: xhci
       - const: dev
 
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
 

-- 
2.43.0

