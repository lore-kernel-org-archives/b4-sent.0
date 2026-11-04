From: David Heidelberg <david@ixit.cz>
Date: Wed, 04 Nov 2026 13:54:43 +0100
Subject: [PATCH RFC 1/3] dt-bindings: input: touchscreen: edt-ft5x06: Add
 wakeup gestures
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-ft5x06-double-tap-v1-1-5a1bd80449cc@ixit.cz>
References: <20261104-ft5x06-double-tap-v1-0-5a1bd80449cc@ixit.cz>
In-Reply-To: <20261104-ft5x06-double-tap-v1-0-5a1bd80449cc@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2704; i=david@ixit.cz;
 h=from:subject:message-id; bh=CWVg/HPnzh79xLHK286mGUAsBwZwcwLqhHu3WsPOxsc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq6ytMDofKtjnbQG0UW/hiJk4rmQoFmHnSJZOc2
 tOPq7B7Jw2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCausrTAAKCRBgAj/E00kg
 cofEEACZXxqt5oBzQbhOB7g5IHLixtw7MUeaM42qTTdhn5j7Fb+V61I+tEsdB2QfiQXv/AW1NrG
 jU+XpngB3wStXsi4+9tn9GdGhfTs+q0GQb0gJ0WUaMFbnG3tbHC+oUdjY8sbYypMN3fABIvBALV
 nuR5Vxc0LFV9R5OG7Tlm9g++E0V0xEQeGtVksWP6gK7qzJ+NUOSJkgt222KJR3IpZfvb5/yrXyJ
 +XIxA25BdSoDXCxrKKms6q9L0CrzolCbQsIDJJe5osnjv7NNQiJVssJQtIsomt2rikm6JUxei4a
 f6jn3PZx9j1fKKNpmHcJkZMySBef7a71gVemWmJ1XHi0iLpAmblLna6w0pC5uynWxsgYGQ3y1YE
 n8GKhnn0ikhYvQx9J9DAEll8L0uc5uUID7N1bpFfOXAi7GYK1wyhBNf0Xl4S+lEhz4ykt6b4/qb
 GjUKpDzuwW3THwPHyflsy+wu3gllWlrCWe43/OmUMcZ2c6v4Vj/6XH3GqBj0YUlh37NB8dIvUy5
 uovuwmXymPEoirWXKmfHKj4bsZGb7dIhrmN0nG2cnnhGnvn6ybdeO/jPj6BR44MX+Fjaw3vo7Qt
 oRWt2gaEtmge5GGIfQOakj8c6M82xSgyy1IeiY/aMdZMEWKDPa2S+9MmCzaJPvcr2yj14+Mwt5D
 0dPgu7e+jufiMTw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FocalTech controllers have a gesture mode in which the firmware
keeps detecting a configurable set of gestures and signals them on the
interrupt line, so they can wake the system. Describe the gestures as
event child nodes carrying the key code to report, like the Azoteq
IQS7211 binding does, so that the mapping is the board's choice and
more gestures can be added later without changing the driver
interface.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../bindings/input/touchscreen/edt-ft5x06.yaml     | 37 ++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml b/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml
index 68b2f16016543..bfc540665a2d2 100644
--- a/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml
+++ b/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml
@@ -106,16 +106,35 @@ properties:
   threshold:
     description: Allows setting the  "click"-threshold in the range from 0 to 255.
     $ref: /schemas/types.yaml#/definitions/uint32
     minimum: 0
     maximum: 255
 
   interrupt-controller: true
 
+patternProperties:
+  "^event-(tap-double|swipe-(up|down|left|right))$":
+    type: object
+    $ref: ../input.yaml#
+    description:
+      A gesture the controller keeps detecting in its gesture mode, reported
+      as a key on a separate input device. Gesture mode is entered when the
+      touchscreen input device is closed or the system suspends, provided
+      the device may wake up the system. Only controllers whose firmware
+      implements the gesture registers support these nodes.
+
+    properties:
+      linux,code: true
+
+    required:
+      - linux,code
+
+    additionalProperties: false
+
 unevaluatedProperties: false
 
 required:
   - compatible
   - reg
   - interrupts
 
 examples:
@@ -130,9 +149,27 @@ examples:
         reg = <0x38>;
         interrupt-parent = <&gpio2>;
         interrupts = <5 IRQ_TYPE_EDGE_FALLING>;
         reset-gpios = <&gpio2 6 GPIO_ACTIVE_LOW>;
         wake-gpios = <&gpio4 9 GPIO_ACTIVE_HIGH>;
       };
     };
 
+  - |
+    #include <dt-bindings/input/input.h>
+    #include <dt-bindings/interrupt-controller/irq.h>
+    i2c {
+      #address-cells = <1>;
+      #size-cells = <0>;
+      touchscreen@38 {
+        compatible = "focaltech,ft5452";
+        reg = <0x38>;
+        interrupts-extended = <&tlmm 125 IRQ_TYPE_EDGE_FALLING>;
+        wakeup-source;
+
+        event-tap-double {
+          linux,code = <KEY_WAKEUP>;
+        };
+      };
+    };
+
 ...

-- 
2.55.0

