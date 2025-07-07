From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 07 Jul 2025 21:54:25 +0200
Subject: [PATCH 1/2] dt-bindings: input: syna,rmi4: Document F1A function
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250707-rmi4_f1a-v1-1-838d83c72e7f@apitzsch.eu>
References: <20250707-rmi4_f1a-v1-0-838d83c72e7f@apitzsch.eu>
In-Reply-To: <20250707-rmi4_f1a-v1-0-838d83c72e7f@apitzsch.eu>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751918097; l=1574;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=x6gb2zqcsU2SCeUMlPPeDX08TtoXkuo2DiW8v+WxDNM=;
 b=CP3W0/DjntK/rKWetcgQ7kkDFo2qbGZljiIiBTGWeZs6roaKxqIEsiOw0qI2H3ULgZCApRqJ1
 W4xtD1mVcNqCBzE8XhyR2lfOh4p0Ku2QKd2BHySjtrCmLb5s4Z55ctU
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In some configurations the touch controller can support touch keys.
Document the linux,keycodes property that enables those keys and
specifies the keycodes that should be used to report the key events.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 .../devicetree/bindings/input/syna,rmi4.yaml         | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/Documentation/devicetree/bindings/input/syna,rmi4.yaml b/Documentation/devicetree/bindings/input/syna,rmi4.yaml
index b522c8d3ce0db719ff379f2fefbdca79e73d027c..f369385ffaf0227412b908242de84cd7dbeb08f7 100644
--- a/Documentation/devicetree/bindings/input/syna,rmi4.yaml
+++ b/Documentation/devicetree/bindings/input/syna,rmi4.yaml
@@ -89,6 +89,24 @@ properties:
     required:
       - reg
 
+  rmi4-f1a@1a:
+    type: object
+    additionalProperties: false
+    $ref: input.yaml#
+    description:
+      RMI4 Function 1A is for capacitive keys.
+
+    properties:
+      reg:
+        maxItems: 1
+
+      linux,keycodes:
+        minItems: 1
+        maxItems: 4
+
+    required:
+      - reg
+
 patternProperties:
   "^rmi4-f1[12]@1[12]$":
     type: object
@@ -201,6 +219,7 @@ allOf:
 
 examples:
   - |
+    #include <dt-bindings/input/linux-event-codes.h>
     #include <dt-bindings/interrupt-controller/irq.h>
 
     i2c {
@@ -234,6 +253,7 @@ examples:
 
             rmi4-f1a@1a {
                 reg = <0x1a>;
+                linux,keycodes = <KEY_BACK KEY_HOME KEY_MENU>;
             };
         };
     };

-- 
2.50.0

