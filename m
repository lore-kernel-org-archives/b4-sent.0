From: Amit Sunil Dhamne <amitsd@google.com>
Date: Thu, 18 Dec 2025 22:49:06 +0000
Subject: [PATCH v2 1/5] dt-bindings: mfd: maxim,max77759: add charger child
 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251218-max77759-charger-v2-1-2b259980a686@google.com>
References: <20251218-max77759-charger-v2-0-2b259980a686@google.com>
In-Reply-To: <20251218-max77759-charger-v2-0-2b259980a686@google.com>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Lee Jones <lee@kernel.org>, Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 RD Babiera <rdbabiera@google.com>, Kyle Tso <kyletso@google.com>, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766098181; l=1858;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=7Z+OfAwjbAkzdqPSTAxyljLhXicf0T4G1279sUdm3LY=;
 b=NYQG8juDPo2XeqgvzUfn+5NDPn30xfqT6cDA5knYDKoPM7jhRybeGeNk7u4BE08n2rSr/z1BA
 laoPDdVtOFZDPHqk+OpHYd57jiWUyBcj9PxmtevU7BhZHCTP3QVMoJF
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Maxim MAX77759 MFD includes a charger function. Extend the max77759
binding to include the charger. Also, update the example to include
charger.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
 .../devicetree/bindings/mfd/maxim,max77759.yaml    | 33 ++++++++++++++++++++++
 1 file changed, 33 insertions(+)

diff --git a/Documentation/devicetree/bindings/mfd/maxim,max77759.yaml b/Documentation/devicetree/bindings/mfd/maxim,max77759.yaml
index 525de9ab3c2b..1cffdf2e5776 100644
--- a/Documentation/devicetree/bindings/mfd/maxim,max77759.yaml
+++ b/Documentation/devicetree/bindings/mfd/maxim,max77759.yaml
@@ -37,6 +37,30 @@ properties:
   nvmem-0:
     $ref: /schemas/nvmem/maxim,max77759-nvmem.yaml
 
+  charger:
+    type: object
+    description: This is a dual input switch mode battery charger for portable
+      applications. It supports wired and wireless charging and can operate in
+      buck and boost mode.
+
+    allOf:
+      - $ref: /schemas/power/supply/power-supply.yaml#
+
+    properties:
+      compatible:
+        const: maxim,max77759-charger
+
+      chgin-otg-regulator:
+        type: object
+        description: Provides Boost for sourcing VBUS.
+        $ref: /schemas/regulator/regulator.yaml#
+        unevaluatedProperties: false
+
+    required:
+      - compatible
+
+    unevaluatedProperties: false
+
 required:
   - compatible
   - interrupts
@@ -95,5 +119,14 @@ examples:
                     };
                 };
             };
+
+            charger {
+                compatible = "maxim,max77759-charger";
+                power-supplies = <&maxtcpci>;
+
+                chgin-otg-regulator {
+                    regulator-name = "chgin-otg";
+                };
+            };
         };
     };

-- 
2.52.0.322.g1dd061c0dc-goog

