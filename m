From: Radu Sabau <radu.sabau@analog.com>
Date: Mon, 02 Nov 2026 11:25:40 +0200
Subject: [PATCH v5 4/8] dt-bindings: iio: imu: Add bindings for ADI
 ADIS16607
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261102-adis16607-v5-4-4f98b0d271ac@analog.com>
References: <20261102-adis16607-v5-0-4f98b0d271ac@analog.com>
In-Reply-To: <20261102-adis16607-v5-0-4f98b0d271ac@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Nuno Sa <nuno.sa@analog.com>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Radu Sabau <radu.sabau@analog.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux@analog.com, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793611539; l=4444;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=SAtl7dLGUqcgnJ9wSgDpOErMnjHQjhHS0GOiEvJSp/U=;
 b=N1Ieq1xugQ9fMbqx2H94p0OiSk/pgVVVw5eyP9QZQMHS6RH9q95IlqXdD4tm1AXfCoDSOYC6s
 +pqBevb7g8tAxHKDHcyZN5YKe4DjNhSa+712Qc8qTCb+0YoKlsP4p5I
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree bindings for the Analog Devices ADIS16607 Precision
MEMS Inertial Measurement Unit. The ADIS16607 integrates a triaxial
gyroscope, triaxial accelerometer, and temperature sensor, and
communicates over SPI Half-Duplex.

Two variants are supported, adis16607-2 and adis16607-3, differing
only in gyroscope full-scale range (±450°/s and ±2000°/s
respectively).

The binding exposes optional properties for:
  - An external clock for sync mode (falling back to the internal 8 kHz
    clock when absent)
  - A hardware reset GPIO (active low)

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 .../devicetree/bindings/iio/imu/adi,adis16607.yaml | 94 ++++++++++++++++++++++
 MAINTAINERS                                        |  7 ++
 2 files changed, 101 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/imu/adi,adis16607.yaml b/Documentation/devicetree/bindings/iio/imu/adi,adis16607.yaml
new file mode 100644
index 000000000000..4545f942365c
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/imu/adi,adis16607.yaml
@@ -0,0 +1,94 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/imu/adi,adis16607.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Analog Devices ADIS16607 IMU
+
+maintainers:
+  - Radu Sabau <radu.sabau@analog.com>
+
+description: |
+  Analog Devices ADIS16607 Precision MEMS Inertial Measurement Unit (IMU)
+  with a triaxial gyroscope, triaxial accelerometer, and temperature sensor.
+  Uses SPI Half-Duplex communication protocol.
+
+  The device has five GPIO pins (GPIO0-GPIO4 in the datasheet), each
+  independently selectable for a single fixed function. This binding
+  exposes GPIO0's reset function as reset-gpios; GPIO2's sync function
+  is modeled via the clocks property, and GPIO4's DEV_NOK interrupt via
+  the interrupts property. GPIO3 (data-ready) is required internally
+  regardless of board wiring and isn't exposed. GPIO1 (wake) gates
+  whether the bootloader auto-loads its NVM contents after reset; it
+  defaults to enabled with a weak pull-up, which already gives normal
+  operation with no configuration needed, so it isn't exposed either.
+
+properties:
+  compatible:
+    enum:
+      - adi,adis16607-2
+      - adi,adis16607-3
+
+  reg:
+    maxItems: 1
+
+  spi-cpha: true
+
+  spi-cpol: true
+
+  spi-max-frequency:
+    maximum: 10000000
+
+  vdd-supply: true
+
+  interrupts:
+    maxItems: 1
+
+  clocks:
+    description:
+      Optional external clock for sync mode. If not provided, the internal
+      8 kHz clock is used.
+    maxItems: 1
+
+  reset-gpios:
+    description:
+      Optional GPIO for hardware reset, active low. Routes to the
+      device's GPIO0 pin, which can be independently set to the reset
+      function or left idle via an on-chip register.
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - spi-cpha
+  - spi-cpol
+  - vdd-supply
+
+allOf:
+  - $ref: /schemas/spi/spi-peripheral-props.yaml#
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+    #include <dt-bindings/gpio/gpio.h>
+    spi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        imu@0 {
+            compatible = "adi,adis16607-2";
+            reg = <0>;
+            spi-cpha;
+            spi-cpol;
+            spi-max-frequency = <10000000>;
+            vdd-supply = <&vdd>;
+            interrupts = <4 IRQ_TYPE_LEVEL_HIGH>;
+            interrupt-parent = <&gpio>;
+            clocks = <&sync_clk>;
+            reset-gpios = <&gpio 10 GPIO_ACTIVE_LOW>;
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index f53047aa8d3c..d5679e8d0ffd 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1792,6 +1792,13 @@ S:	Supported
 W:	https://ez.analog.com/linux-software-drivers
 F:	Documentation/devicetree/bindings/iio/imu/adi,adis16550.yaml
 
+ANALOG DEVICES INC ADIS16607 DRIVER
+M:	Radu Sabau <radu.sabau@analog.com>
+L:	linux-iio@vger.kernel.org
+S:	Supported
+W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/devicetree/bindings/iio/imu/adi,adis16607.yaml
+
 ANALOG DEVICES INC ADL8113 DRIVER
 M:	Antoniu Miclaus <antoniu.miclaus@analog.com>
 L:	linux-iio@vger.kernel.org

-- 
2.43.0

