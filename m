From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 28 Mar 2024 14:22:31 +0100
Subject: [PATCH 07/10] dt-bindings: iio: dac: add bindings doc for AD9739A
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240328-iio-backend-axi-dac-v1-7-afc808b3fde3@analog.com>
References: <20240328-iio-backend-axi-dac-v1-0-afc808b3fde3@analog.com>
In-Reply-To: <20240328-iio-backend-axi-dac-v1-0-afc808b3fde3@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Dragos Bogdan <dragos.bogdan@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711632149; l=3209;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=TE1EDYOt04eltj6msTlmY+mlUAyPqDFwW+KyyJ0QXLE=;
 b=+z5TTXiIpoIbMI/90ZEzXqH9KKeD/j57PmBH4iqcpJdLju0YEWY28zwvGZNRhcCz4Y+6FQf50
 O7PWdgpFjS8BOw5qQ5lWjo4WmGF3GCklKm3boh0sFFghKMkJ1qC+vs7
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds the bindings documentation for the 14 bit
RF Digital-to-Analog converter.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 .../devicetree/bindings/iio/dac/adi,ad9739a.yaml   | 88 ++++++++++++++++++++++
 MAINTAINERS                                        |  8 ++
 2 files changed, 96 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/dac/adi,ad9739a.yaml b/Documentation/devicetree/bindings/iio/dac/adi,ad9739a.yaml
new file mode 100644
index 000000000000..24bcec763a9b
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/dac/adi,ad9739a.yaml
@@ -0,0 +1,88 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/dac/adi,ad9739a.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Analog Devices AD9739A RF DAC
+
+maintainers:
+  - Dragos Bogdan <dragos.bogdan@analog.com>
+  - Nuno Sa <nuno.sa@analog.com>
+
+description: |
+  The AD9739A is a 14-bit, 2.5 GSPS high performance RF DACs that are capable
+  of synthesizing wideband signals from dc up to 3 GHz.
+
+  https://www.analog.com/media/en/technical-documentation/data-sheets/ad9737a_9739a.pdf
+
+properties:
+  compatible:
+    enum:
+      - adi,ad9739a
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    maxItems: 1
+
+  reset-gpios:
+    maxItems: 1
+
+  vdd_3_3-supply:
+    description: 3.3V Digital input supply.
+
+  vdd-supply:
+    description: 1.8V Digital input supply.
+
+  vdda-supply:
+    description: 3.3V Analog input supply.
+
+  vddc-supply:
+    description: 1.8V Clock input supply.
+
+  io-backends:
+    maxItems: 1
+
+  adi,full-scale-microamp:
+    description: This property represents the DAC full scale current.
+    minimum: 8700
+    maximum: 31700
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - io-backends
+  - vdd_3_3-supply
+  - vdd-supply
+  - vdda-supply
+  - vddc-supply
+
+allOf:
+  - $ref: /schemas/spi/spi-peripheral-props.yaml#
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    spi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        dac@0 {
+            compatible = "adi,ad9739a";
+            reg = <0>;
+
+            clocks = <&dac_clk>;
+
+            io-backends = <&iio_backend>;
+
+            vdd_3_3-supply = <&vdd_3_3>;
+            vdd-supply = <&vdd>;
+            vdda-supply = <&vdd_3_3>;
+            vddc-supply = <&vdd>;
+        };
+    };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index 2137eb452376..76e872e320d7 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1234,6 +1234,14 @@ W:	https://ez.analog.com/linux-software-drivers
 F:	Documentation/devicetree/bindings/iio/adc/adi,ad7780.yaml
 F:	drivers/iio/adc/ad7780.c
 
+ANALOG DEVICES INC AD9739a DRIVER
+M:	Nuno Sa <nuno.sa@analog.com>
+M:	Dragos Bogdan <dragos.bogdan@analog.com>
+L:	linux-iio@vger.kernel.org
+S:	Supported
+W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/devicetree/bindings/iio/dac/adi,ad9739a.yaml
+
 ANALOG DEVICES INC ADA4250 DRIVER
 M:	Antoniu Miclaus <antoniu.miclaus@analog.com>
 L:	linux-iio@vger.kernel.org

-- 
2.44.0

