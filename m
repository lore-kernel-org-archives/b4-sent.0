From: Alejandro Enrique <alejandroe1@geotab.com>
Date: Thu, 11 Sep 2025 14:58:28 +0200
Subject: [PATCH v3 1/2] dt-bindings: gnss: u-blox: add "safeboot-gpios"
 binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250911-ubx-safeboot-v3-1-32fe6b882a3c@geotab.com>
References: <20250911-ubx-safeboot-v3-0-32fe6b882a3c@geotab.com>
In-Reply-To: <20250911-ubx-safeboot-v3-0-32fe6b882a3c@geotab.com>
To: Johan Hovold <johan@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alejandro Enrique <alejandroe1@geotab.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757595528; l=1952;
 i=alejandroe1@geotab.com; s=20250514; h=from:subject:message-id;
 bh=1ldch3c4U2m2MqNI+Cr7cERTwlAa2OI1tnsluUcBNnI=;
 b=pFXFeRqnm3Od9CO9o83iea3ZVX1+/GHp5vN85DN49o/G5Ox9Yo4l1kn7qKQ03osft92s/8LHg
 bIyagquwKIPC3y2+ZJr6w2g1j6JZ6nUkTfcKCGwxs0LKbPT7j7qD5rt
X-Developer-Key: i=alejandroe1@geotab.com; a=ed25519;
 pk=xzHMPbqczL/tMsjXr26iLoHwIzLveHVnT+GIU4p1k38=
X-Endpoint-Received: by B4 Relay for alejandroe1@geotab.com/20250514 with auth_id=404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

U-Blox 8/M8/M9 chip have a pin to start it in safeboot mode, to be
used to recover from situations where the flash content has become
corrupted and needs to be restored. Introduce a binding to support
this safeboot pin.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Alejandro Enrique <alejandroe1@geotab.com>
---
 .../devicetree/bindings/gnss/u-blox,neo-6m.yaml      | 20 ++++++++++++++++----
 1 file changed, 16 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml b/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml
index c0c2bfaa606fb01f7efee1ce7e5d30b1640783f3..44c9421cbe0b377661ef99a9e8c0dcebf3f9c894 100644
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
 
@@ -36,6 +32,9 @@ properties:
   reset-gpios:
     maxItems: 1
 
+  safeboot-gpios:
+    maxItems: 1
+
   vcc-supply:
     description: >
       Main voltage regulator
@@ -53,6 +52,18 @@ required:
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
@@ -65,5 +76,6 @@ examples:
             v-bckp-supply = <&gnss_v_bckp_reg>;
             vcc-supply = <&gnss_vcc_reg>;
             reset-gpios = <&gpio 1 GPIO_ACTIVE_LOW>;
+            safeboot-gpios = <&gpio 2 GPIO_ACTIVE_LOW>;
         };
     };

-- 
2.34.1

