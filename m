From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Fri, 06 Nov 2026 21:56:29 +0100
Subject: [PATCH v2 1/2] dt-bindings: iio: light: Add Capella CM3217
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-upstream-iio-cm3217-v2-1-d97adde9171c@tsv-stahl-riesa.de>
References: <20261106-upstream-iio-cm3217-v2-0-d97adde9171c@tsv-stahl-riesa.de>
In-Reply-To: <20261106-upstream-iio-cm3217-v2-0-d97adde9171c@tsv-stahl-riesa.de>
To: Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Kevin Tsai <ktsai@capellamicro.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793998608; l=2155;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=RVztLRvLE2XHZl0smZ+iXBmMb3aWuOAd6PH4N53y5GY=;
 b=C4AieDI9YGOFjRxPrCLPVknDSODMUmQygjomFWzyROfdpHyk1AkmT5fVQJ62JM3+b9ZfuXIGx
 eSMzXKx1f7mAZTW8s3c5uML/kKZ6zXiQgBNfc1UOh8KgnlpzJOe+7y5
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Capella CM3217 is an ambient light sensor with an I2C interface but
without registers and without an interrupt line. It always answers on
the two addresses 0x10 and 0x11. The node describes the first address;
the second one is fixed.

The sensor is used in the NVIDIA Tegra Note 7 and the NVIDIA Shield
Tablet.

Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 .../bindings/iio/light/capella,cm3217.yaml         | 51 ++++++++++++++++++++++
 1 file changed, 51 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/light/capella,cm3217.yaml b/Documentation/devicetree/bindings/iio/light/capella,cm3217.yaml
new file mode 100644
index 000000000000..7f2a0d5d0243
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/light/capella,cm3217.yaml
@@ -0,0 +1,51 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/light/capella,cm3217.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Capella CM3217 ambient light sensor
+
+maintainers:
+  - Patrick Fischer <admin@tsv-stahl-riesa.de>
+
+description:
+  The CM3217 is an I2C ambient light sensor without registers or interrupt
+  line.
+
+properties:
+  compatible:
+    const: capella,cm3217
+
+  reg:
+    description:
+      The sensor always occupies the two fixed I2C addresses 0x10 and 0x11.
+      Writing a byte to 0x10 sets command byte 1 (shutdown and IT_T), reading
+      a byte from it returns the high byte of the light count. Writing a byte
+      to 0x11 sets command byte 2 (FD_IT), reading a byte from it returns the
+      low byte. Only the first address is given here, the second one is
+      implied.
+    const: 0x10
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
+            compatible = "capella,cm3217";
+            reg = <0x10>;
+            vdd-supply = <&vdd_2v85_sen>;
+        };
+    };
+...

-- 
2.56.0

