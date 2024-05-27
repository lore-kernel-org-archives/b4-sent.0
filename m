From: Arthur Becker <arthur.becker@sentec.com>
Date: Mon, 27 May 2024 17:12:09 +0200
Subject: [PATCH v3 2/2] dt-bindings: iio: light: add VEML6040 RGBW-LS
 bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240527-veml6040-v3-2-6f3bbfd42960@sentec.com>
References: <20240527-veml6040-v3-0-6f3bbfd42960@sentec.com>
In-Reply-To: <20240527-veml6040-v3-0-6f3bbfd42960@sentec.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, Arthur Becker <arthur.becker@sentec.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716822728; l=1571;
 i=arthur.becker@sentec.com; s=20240521; h=from:subject:message-id;
 bh=u0p4w65fUlznIRwbLv+oCbf01W5aOcq+erfwbBRKE9w=;
 b=zCjYc68+a0u7/fUR6r+IMPoQXLqxz9nMLelPqjfSZeibSwRIsayNYpLVecj3SxZ04uGnDNdds
 xHdNaM8x2ouCb9AywBmXkiBFbEgqbcvrUAYlYgiCst0uUGksoXqr+92
X-Developer-Key: i=arthur.becker@sentec.com; a=ed25519;
 pk=1GLsDBF6GZKt9oNFsvdnAB6sHyKKrSISlwM3AyWbx/k=
X-Endpoint-Received: by B4 Relay for arthur.becker@sentec.com/20240521 with auth_id=163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Device tree bindings for the vishay VEML6040 RGBW light sensor iio
driver

Signed-off-by: Arthur Becker <arthur.becker@sentec.com>
---
V1 -> V3: Addressed review comments (v1 of the dt-bindings was sent
along with v2 of the driver but not in a set)
---
 .../bindings/iio/light/vishay,veml6040.yaml        | 44 ++++++++++++++++++++++
 1 file changed, 44 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/light/vishay,veml6040.yaml b/Documentation/devicetree/bindings/iio/light/vishay,veml6040.yaml
new file mode 100644
index 000000000000..101c2cc6506e
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/light/vishay,veml6040.yaml
@@ -0,0 +1,44 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/light/vishay,veml6040.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: VEML6040 RGBW Light Sensor
+
+maintainers:
+  - Arthur Becker <arthur.becker@sentec.com>
+
+description:
+  Datasheet at https://www.vishay.com/docs/84276/veml6040.pdf
+
+properties:
+  compatible:
+    const: vishay,veml6040
+
+  reg:
+    enum:
+      - 0x10
+
+  vdd-supply: true
+
+required:
+  - compatible
+  - reg
+  - vdd-supply
+
+additionalProperties: false
+
+examples:
+  - |
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        light-sensor@10 {
+            compatible = "vishay,veml6040";
+            reg = <0x10>;
+            vdd-supply = <&vdd_reg>;
+        };
+    };
+...

-- 
2.34.1

