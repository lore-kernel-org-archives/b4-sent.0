From: Petar Stoykov <pd.pstoykov@gmail.com>
Date: Thu, 25 Jul 2024 17:37:27 +0200
Subject: [PATCH v4 1/3] dt-bindings: iio: pressure: Add Sensirion SDP500
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240725-mainline_sdp500-v4-1-ea2f5b189958@gmail.com>
References: <20240725-mainline_sdp500-v4-0-ea2f5b189958@gmail.com>
In-Reply-To: <20240725-mainline_sdp500-v4-0-ea2f5b189958@gmail.com>
To: linux-iio@vger.kernel.org, Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Cc: Petar Stoykov <pd.pstoykov@gmail.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721921965; l=1741;
 i=pd.pstoykov@gmail.com; s=20240702; h=from:subject:message-id;
 bh=cENh+/xF32OA/T3EWLu9J0STlExFqa0Gg1TOizqGn2k=;
 b=iI57uw6+stMrgYDIPBqiB1P+4gMO6pVCpRLFNu1ExAf2Bkqauqioz+oInk5S+HHU1OBm/rBvx
 zCNSdyhzfhLBrTqnqnfTr2VV1m1dAtsggXiOLy1xgHVdAEAMbIAS+th
X-Developer-Key: i=pd.pstoykov@gmail.com; a=ed25519;
 pk=oxcGqcVV5O6wqlTh+39SbOwfbpD763i5x4TavUAHiCg=
X-Endpoint-Received: by B4 Relay for pd.pstoykov@gmail.com/20240702 with auth_id=179
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sensirion SDP500 is a digital differential pressure sensor. It provides
a digital I2C output. Add devicetree bindings requiring the compatible
string and I2C slave address (reg).

Signed-off-by: Petar Stoykov <pd.pstoykov@gmail.com>
---
 .../bindings/iio/pressure/sensirion,sdp500.yaml    | 46 ++++++++++++++++++++++
 1 file changed, 46 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/pressure/sensirion,sdp500.yaml b/Documentation/devicetree/bindings/iio/pressure/sensirion,sdp500.yaml
new file mode 100644
index 000000000000..813239f6879a
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/pressure/sensirion,sdp500.yaml
@@ -0,0 +1,46 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/pressure/sensirion,sdp500.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: sdp500/sdp510 pressure sensor with I2C bus interface
+
+maintainers:
+  - Petar Stoykov <petar.stoykov@prodrive-technologies.com>
+
+description: |
+  Pressure sensor from Sensirion with I2C bus interface.
+  There is no software difference between sdp500 and sdp510.
+
+properties:
+  compatible:
+    oneOf:
+      - items:
+          - const: sensirion,sdp510
+          - const: sensirion,sdp500
+      - const: sensirion,sdp500
+
+  reg:
+    maxItems: 1
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
+      #address-cells = <1>;
+      #size-cells = <0>;
+      pressure@40 {
+        compatible = "sensirion,sdp500";
+        reg = <0x40>;
+        vdd-supply = <&foo>;
+      };
+    };

-- 
2.39.2

