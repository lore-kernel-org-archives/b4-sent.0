From: Alejandro Enrique <alejandroe1@geotab.com>
Date: Thu, 22 May 2025 18:51:04 +0200
Subject: [PATCH v2 1/2] dt-bindings: gnss: u-blox: add "safeboot-gpios"
 binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250522-ubx-safeboot-v2-1-08c22378b8c9@geotab.com>
References: <20250522-ubx-safeboot-v2-0-08c22378b8c9@geotab.com>
In-Reply-To: <20250522-ubx-safeboot-v2-0-08c22378b8c9@geotab.com>
To: Johan Hovold <johan@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alejandro Enrique <alejandroe1@geotab.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747932696; l=1890;
 i=alejandroe1@geotab.com; s=20250514; h=from:subject:message-id;
 bh=Qgfr/42Hk/Jl7APKEe5TWsDxVDS5VL624ZuNvtX/yFo=;
 b=RR2rXONjgeJOS3q2oViWu/z3Xnbe5J92rwAaRkPUD7Qyz+Y1SzrloMBVy85A836QHokJ3IKM7
 gzG8Zfod1wmASeNBXZSLofMLUo2Cg9EBkYPokgOiwW0SHVU66lhLf1G
X-Developer-Key: i=alejandroe1@geotab.com; a=ed25519;
 pk=xzHMPbqczL/tMsjXr26iLoHwIzLveHVnT+GIU4p1k38=
X-Endpoint-Received: by B4 Relay for alejandroe1@geotab.com/20250514 with auth_id=404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

U-Blox 8/M8/M9 chip have a pin to start it in safeboot mode, to be
used to recover from situations where the flash content has become
corrupted and needs to be restored. Introduce a binding to support
this safeboot pin.

Signed-off-by: Alejandro Enrique <alejandroe1@geotab.com>
---
 Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml | 20 ++++++++++++++++----
 1 file changed, 16 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml b/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml
index 7d4b6d49e5eea2201ac05ba6d54b1c1721172f26..7589327a77da5c70bfebe57685e2a4bbfd95934c 100644
--- a/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml
+++ b/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml
@@ -6,10 +6,6 @@ $schema: http://devicetree.org/meta-schemas/core.yaml#
 
 title: U-blox GNSS Receiver
 
-allOf:
-  - $ref: gnss-common.yaml#
-  - $ref: /schemas/serial/serial-peripheral-props.yaml#
-
 maintainers:
   - Johan Hovold <johan@kernel.org>
 
@@ -32,6 +28,9 @@ properties:
   reset-gpios:
     maxItems: 1
 
+  safeboot-gpios:
+    maxItems: 1
+
   vcc-supply:
     description: >
       Main voltage regulator
@@ -49,6 +48,18 @@ required:
   - compatible
   - vcc-supply
 
+allOf:
+  - $ref: gnss-common.yaml#
+  - $ref: /schemas/serial/serial-peripheral-props.yaml#
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: u-blox,neo-6m
+    then:
+      properties:
+        safeboot-gpios: false
+
 unevaluatedProperties: false
 
 examples:
@@ -61,5 +72,6 @@ examples:
             v-bckp-supply = <&gnss_v_bckp_reg>;
             vcc-supply = <&gnss_vcc_reg>;
             reset-gpios = <&gpio 1 GPIO_ACTIVE_LOW>;
+            safeboot-gpios = <&gpio 2 GPIO_ACTIVE_LOW>;
         };
     };

-- 
2.34.1

