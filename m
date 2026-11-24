From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Date: Tue, 24 Nov 2026 18:43:20 +0100
Subject: [PATCH 1/2] dt-bindings: power: supply: Add Maxim DS28E16
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-ds28e16-v1-1-bed431df0578@proton.me>
References: <20261124-ds28e16-v1-0-bed431df0578@proton.me>
In-Reply-To: <20261124-ds28e16-v1-0-bed431df0578@proton.me>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Armandas Kvietkus <armandas.kvietkus@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795542200; l=1712;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=cPg7Cg+cHTWnzByN+nzFNB6aPtM09Gw/8/P3zoDCNl8=;
 b=kzZxpgDdA7EeVTVwXiwOhTzYrMG9nPBDB/huvJe0pBDOzoz0qpBa6HQCPgvg+VAoEt8CgfwQC
 pJVyeqjVCCKADeJZ7xft72XZ3Vw9vtlqcvtBXoqoSLTfn2E563Lteq8
X-Developer-Key: i=armandas.kvietkus@proton.me; a=ed25519;
 pk=wuqmImJ9sKlDVcwALOvfGhjj7G8EBjjM4TpCdmlrAf8=
X-Endpoint-Received: by B4 Relay for armandas.kvietkus@proton.me/default with auth_id=974
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DS28E16 is a 1-Wire secure authenticator found in some battery
packs. Its decrement counter page holds the cycle count of the pack.

Signed-off-by: Armandas Kvietkus <armandas.kvietkus@proton.me>
---
 .../bindings/power/supply/maxim,ds28e16.yaml       | 39 ++++++++++++++++++++++
 1 file changed, 39 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/supply/maxim,ds28e16.yaml b/Documentation/devicetree/bindings/power/supply/maxim,ds28e16.yaml
new file mode 100644
index 000000000000..b381bdf68239
--- /dev/null
+++ b/Documentation/devicetree/bindings/power/supply/maxim,ds28e16.yaml
@@ -0,0 +1,39 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/power/supply/maxim,ds28e16.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Maxim DS28E16 battery pack authenticator
+
+maintainers:
+  - Armandas Kvietkus <armandas.kvietkus@proton.me>
+
+description:
+  The DS28E16 is a secure authenticator inside some battery packs, for
+  example in Xiaomi SM8250 phones. It is connected to a GPIO that is used as
+  a 1-Wire data line. Page 2 of its memory holds a one way decrement counter
+  that stores the charge cycle count of the pack.
+
+properties:
+  compatible:
+    const: maxim,ds28e16
+
+  onewire-gpios:
+    maxItems: 1
+    description: GPIO used as the 1-Wire data line.
+
+required:
+  - compatible
+  - onewire-gpios
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    battery-id {
+        compatible = "maxim,ds28e16";
+        onewire-gpios = <&tlmm 25 GPIO_ACTIVE_HIGH>;
+    };

-- 
2.56.0

