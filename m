From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 31 Oct 2025 12:31:22 +0000
Subject: [PATCH v3 01/10] dt-bindings: iio: dac: Document AD5446 and
 similar devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251031-dev-add-ad5542-v3-1-d3541036c0e6@analog.com>
References: <20251031-dev-add-ad5542-v3-0-d3541036c0e6@analog.com>
In-Reply-To: <20251031-dev-add-ad5542-v3-0-d3541036c0e6@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761913895; l=5117;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=ilsaRzkJ8yfckQSj+fp3nBx94rCUsN0wDViEmHKqLcY=;
 b=LW+YfTsxc66zAfFngVgjqxsnZge7ZEacFrgQfSweDqr7iazsWVFUv1z9wTitpxAVSxrwQy1Cl
 pGC4lexVyEyD5goBvOC6bEEuhHkZL9L2nmNtm8+256MLM6R0c1wN8Y0
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree binding documentation for the Analog Devices AD5446
family of Digital-to-Analog Converters and derivative devices from
Texas Instruments. There's both SPI and I2C interfaces and feature
resolutions ranging from 8-bit to 16-bit.

The binding covers 29 derivatives devices including the AD5446 series,
AD5600 series, AD5620/5640/5660 variants with different voltage ranges,
and TI DAC081s101/DAC101s101/DAC121s101 devices.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 .../devicetree/bindings/iio/dac/adi,ad5446.yaml    | 138 +++++++++++++++++++++
 MAINTAINERS                                        |   8 ++
 2 files changed, 146 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/dac/adi,ad5446.yaml b/Documentation/devicetree/bindings/iio/dac/adi,ad5446.yaml
new file mode 100644
index 000000000000..2669d2c4948b
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/dac/adi,ad5446.yaml
@@ -0,0 +1,138 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/dac/adi,ad5446.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Analog Devices AD5446 and similar DACs
+
+maintainers:
+  - Michael Hennerich <michael.hennerich@analog.com>
+  - Nuno Sá <nuno.sa@analog.com>
+
+description:
+  Digital to Analog Converter devices supporting both SPI and I2C interfaces.
+  These devices feature a range of resolutions from 8-bit to 16-bit.
+
+properties:
+  compatible:
+    oneOf:
+      - description: SPI DACs
+        enum:
+          - adi,ad5300
+          - adi,ad5310
+          - adi,ad5320
+          - adi,ad5444
+          - adi,ad5446
+          - adi,ad5450
+          - adi,ad5451
+          - adi,ad5452
+          - adi,ad5453
+          - adi,ad5512a
+          - adi,ad5541a
+          - adi,ad5542
+          - adi,ad5542a
+          - adi,ad5543
+          - adi,ad5553
+          - adi,ad5600
+          - adi,ad5601
+          - adi,ad5611
+          - adi,ad5621
+          - adi,ad5641
+          - adi,ad5620-2500
+          - adi,ad5620-1250
+          - adi,ad5640-2500
+          - adi,ad5640-1250
+          - adi,ad5660-2500
+          - adi,ad5660-1250
+          - adi,ad5662
+          - ti,dac081s101
+          - ti,dac101s101
+          - ti,dac121s101
+      - description: I2C DACs
+        enum:
+          - adi,ad5301
+          - adi,ad5311
+          - adi,ad5321
+          - adi,ad5602
+          - adi,ad5612
+          - adi,ad5622
+
+  reg:
+    maxItems: 1
+
+  vcc-supply:
+    description:
+      Reference voltage supply. If not supplied, devices with internal
+      voltage reference will use that.
+
+required:
+  - compatible
+  - reg
+
+allOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - adi,ad5300
+              - adi,ad5310
+              - adi,ad5320
+              - adi,ad5444
+              - adi,ad5446
+              - adi,ad5450
+              - adi,ad5451
+              - adi,ad5452
+              - adi,ad5453
+              - adi,ad5512a
+              - adi,ad5541a
+              - adi,ad5542
+              - adi,ad5542a
+              - adi,ad5543
+              - adi,ad5553
+              - adi,ad5600
+              - adi,ad5601
+              - adi,ad5611
+              - adi,ad5621
+              - adi,ad5641
+              - adi,ad5620-2500
+              - adi,ad5620-1250
+              - adi,ad5640-2500
+              - adi,ad5640-1250
+              - adi,ad5660-2500
+              - adi,ad5660-1250
+              - adi,ad5662
+              - ti,dac081s101
+              - ti,dac101s101
+              - ti,dac121s101
+    then:
+      allOf:
+        - $ref: /schemas/spi/spi-peripheral-props.yaml#
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
+            compatible = "adi,ad5446";
+            reg = <0>;
+            vcc-supply = <&dac_vref>;
+        };
+    };
+  - |
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        dac@42 {
+            compatible = "adi,ad5622";
+            reg = <0x42>;
+            vcc-supply = <&dac_vref>;
+        };
+    };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index 8082081ea742..9654f0c25423 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -440,6 +440,14 @@ W:	http://wiki.analog.com/AD5398
 W:	https://ez.analog.com/linux-software-drivers
 F:	drivers/regulator/ad5398.c
 
+AD5446	ANALOG DEVICES INC AD5446 DAC DRIVER
+M:	Michael Hennerich <michael.hennerich@analog.com>
+M:	Nuno Sá <nuno.sa@analog.com>
+L:	linux-iio@vger.kernel.org
+S:	Supported
+W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/devicetree/bindings/iio/dac/adi,ad5446.yaml
+
 AD714X CAPACITANCE TOUCH SENSOR DRIVER (AD7142/3/7/8/7A)
 M:	Michael Hennerich <michael.hennerich@analog.com>
 S:	Supported

-- 
2.51.0

