From: Petar Stoykov <pd.pstoykov@gmail.com>
Date: Tue, 02 Jul 2024 16:59:08 +0200
Subject: [PATCH v3 1/3] dt-bindings: iio: pressure: Add Sensirion SDP500
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240702-mainline_sdp500-v3-1-0902047b3eee@gmail.com>
References: <20240702-mainline_sdp500-v3-0-0902047b3eee@gmail.com>
In-Reply-To: <20240702-mainline_sdp500-v3-0-0902047b3eee@gmail.com>
To: linux-iio@vger.kernel.org, Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Cc: Petar Stoykov <pd.pstoykov@gmail.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719932376; l=1616;
 i=pd.pstoykov@gmail.com; s=20240702; h=from:subject:message-id;
 bh=co7y2IA3A8lUnRV2yOyd68cdyraGpDiPDlleT9qTLEs=;
 b=OdN36Pkms9PAOJLXPbrQ9jHayJKTbixUhL6AwCVekRyssELGGFA2KesB50+m15TS0231TbyYz
 Nr/uKxvNgMqDj7iSHDCNUnbk5PKXaIaoU33ZgVIQanvebgrM2nWFefB
X-Developer-Key: i=pd.pstoykov@gmail.com; a=ed25519;
 pk=oxcGqcVV5O6wqlTh+39SbOwfbpD763i5x4TavUAHiCg=
X-Endpoint-Received: by B4 Relay for pd.pstoykov@gmail.com/20240702 with auth_id=179
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sensirion SDP500 is a digital differential pressure sensor. It provides
a digital I2C output. Add devicetree bindings requiring the compatible
string and I2C slave address (reg).

Signed-off-by: Petar Stoykov <pd.pstoykov@gmail.com>
---
 .../bindings/iio/pressure/sensirion,sdp500.yaml    | 41 ++++++++++++++++++++++
 1 file changed, 41 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/pressure/sensirion,sdp500.yaml b/Documentation/devicetree/bindings/iio/pressure/sensirion,sdp500.yaml
new file mode 100644
index 000000000000..6b3e54def367
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/pressure/sensirion,sdp500.yaml
@@ -0,0 +1,41 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/pressure/sdp500.yaml#
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
+    enum:
+      - sensirion,sdp500
+      - sensirion,sdp510
+
+  reg:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
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

