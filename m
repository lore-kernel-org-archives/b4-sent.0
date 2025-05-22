From: Alejandro Enrique <alejandroe1@geotab.com>
Date: Thu, 22 May 2025 18:18:53 +0200
Subject: [PATCH v2] dt-bindings: gnss: add u-blox,neo-9m compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250522-ubx-m9-v2-1-6ecd470527bc@geotab.com>
X-B4-Tracking: v=1; b=H4sIAGxOL2gC/2XMSw6DIBSF4a2YOy4NL6N05D4aB4AXZaA0YImNY
 e+lTjv8T06+ExJGjwkezQkRs08+bDX4rQG76G1G4qfawClvacskeZuDrIp0dHLUTb2VvYF6fkV
 0/rig51h78WkP8XO5mf3WPyIzQglTQnVCSyesHmYMuzZ3G1YYSylfcOKvU50AAAA=
X-Change-ID: 20250514-ubx-m9-70df0fd8c48b
To: Johan Hovold <johan@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Alejandro Enrique <alejandroe1@geotab.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747930772; l=2006;
 i=alejandroe1@geotab.com; s=20250514; h=from:subject:message-id;
 bh=t0h9nv36tZoG6bCZ31dIAWWzsXZFdgQLmDpUFpX3zjs=;
 b=EhlRZpfjBQLxmdyD8lQdg6w8IHy+r4AlzNb+4MatuJ3P0EVtYYbxqRBPgFdJfFxnOxavcDWEH
 hmJj0sr1djpDg9WMCqanO1aja/WbhQUJt7KJ4MT1i+xqUdV6lcE6w0l
X-Developer-Key: i=alejandroe1@geotab.com; a=ed25519;
 pk=xzHMPbqczL/tMsjXr26iLoHwIzLveHVnT+GIU4p1k38=
X-Endpoint-Received: by B4 Relay for alejandroe1@geotab.com/20250514 with auth_id=404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible for u-blox NEO-9M GPS module.

Signed-off-by: Alejandro Enrique <alejandroe1@geotab.com>
---
This series just add the compatible string for u-blox NEO-9M module,
using neo-m8 as fallback. I have tested the driver with such a module
and it is working fine.
---
Changes in v2:
- Modify the binding to allow falling back to neo-m8
- Remove compatible string from u-blox driver
- Link to v1: https://lore.kernel.org/r/20250514-ubx-m9-v1-0-193973a4f3ca@geotab.com
---
 Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml | 25 +++++++++++++++++++++----
 1 file changed, 21 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml b/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml
index 7d4b6d49e5eea2201ac05ba6d54b1c1721172f26..215f8931ca08c1b0954fc2f70eabe3ec8d89edea 100644
--- a/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml
+++ b/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml
@@ -18,10 +18,16 @@ description: >
 
 properties:
   compatible:
-    enum:
-      - u-blox,neo-6m
-      - u-blox,neo-8
-      - u-blox,neo-m8
+    oneOf:
+      - items:
+          - enum:
+              - u-blox,neo-6m
+              - u-blox,neo-8
+              - u-blox,neo-m8
+
+      - items:
+          - const: u-blox,neo-m9
+          - const: u-blox,neo-m8
 
   reg:
     description: >
@@ -63,3 +69,14 @@ examples:
             reset-gpios = <&gpio 1 GPIO_ACTIVE_LOW>;
         };
     };
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    serial {
+        gnss {
+            compatible = "u-blox,neo-m9", "u-blox,neo-m8";
+            v-bckp-supply = <&gnss_v_bckp_reg>;
+            vcc-supply = <&gnss_vcc_reg>;
+            reset-gpios = <&gpio 1 GPIO_ACTIVE_LOW>;
+        };
+    };

---
base-commit: 9c32cda43eb78f78c73aee4aa344b777714e259b
change-id: 20250514-ubx-m9-70df0fd8c48b

Best regards,
-- 
Alejandro Enrique <alejandroe1@geotab.com>

