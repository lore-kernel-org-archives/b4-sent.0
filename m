From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 20 Nov 2026 04:32:17 +0000
Subject: [PATCH v2 1/2] dt-bindings: i2c: Add the slave EEPROM backend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-i2c-slave-eeprom-of-match-v2-1-0444790a0b76@gmail.com>
References: <20261120-i2c-slave-eeprom-of-match-v2-0-0444790a0b76@gmail.com>
In-Reply-To: <20261120-i2c-slave-eeprom-of-match-v2-0-0444790a0b76@gmail.com>
To: Andi Shyti <andi.shyti@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Wolfram Sang <wsa+renesas@sang-engineering.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 =?utf-8?q?Bj=C3=B6rn_Ard=C3=B6?= <bjorn.ardo@axis.com>, 
 linux-i2c@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795149136; l=2337;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=7TThpKM3y4oAcfYvPrtWKqq71G20/x2Yu5tN6fE5i94=;
 b=SXO3Q2HU0xgiVbOLTq31+B7KOpMHsyp0zTrka1rKDGNntY27IxHKG0Ng+T2sJKPOe56EB925y
 a9JPwhasTMDBqYFNrgUJLNc7FvbmEnrKRHFuIwporo61oD+n0e0deJv
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A node with one of the i2c-slave-eeprom names as compatible and
I2C_OWN_SLAVE_ADDRESS in reg already binds to the backend, because the
I2C core names the client after the compatible and matches the I2C id.
The driver also reads firmware-name. None of this is documented.

Document the names without a vendor prefix, as the driver and
Documentation/i2c spell them (ipmb-dev and mctp-i2c-controller are
unprefixed too).

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../devicetree/bindings/i2c/slave-eeprom.yaml      | 59 ++++++++++++++++++++++
 1 file changed, 59 insertions(+)

diff --git a/Documentation/devicetree/bindings/i2c/slave-eeprom.yaml b/Documentation/devicetree/bindings/i2c/slave-eeprom.yaml
new file mode 100644
index 000000000000..b7a6e6653a64
--- /dev/null
+++ b/Documentation/devicetree/bindings/i2c/slave-eeprom.yaml
@@ -0,0 +1,59 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/i2c/slave-eeprom.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: I2C target EEPROM backend
+
+maintainers:
+  - Arun Iyengar <aiyengar1990@gmail.com>
+
+description:
+  The I2C controller answers on its own address as a target and behaves
+  like a 24Cxx EEPROM towards the other controllers on the bus. The
+  compatible selects the EEPROM type that is simulated. The "ro" variants
+  ignore writes from the bus.
+
+properties:
+  compatible:
+    enum:
+      - slave-24c02
+      - slave-24c02ro
+      - slave-24c32
+      - slave-24c32ro
+      - slave-24c64
+      - slave-24c64ro
+      - slave-24c512
+      - slave-24c512ro
+
+  reg:
+    maxItems: 1
+    description:
+      Own address of the controller on the bus. The I2C_OWN_SLAVE_ADDRESS
+      flag must be set.
+
+  firmware-name:
+    maxItems: 1
+    description:
+      File with the initial content. Without it all bytes start as 0xff.
+
+required:
+  - compatible
+  - reg
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/i2c/i2c.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        eeprom@64 {
+            compatible = "slave-24c02";
+            reg = <(0x64 | I2C_OWN_SLAVE_ADDRESS)>;
+        };
+    };

-- 
2.55.0

