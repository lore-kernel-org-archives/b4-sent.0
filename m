From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 20 Mar 2026 16:27:26 +0000
Subject: [PATCH v9 1/9] dt-bindings: iio: frequency: add adf41513
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260320-adf41513-iio-driver-v9-1-132f0d076374@analog.com>
References: <20260320-adf41513-iio-driver-v9-0-132f0d076374@analog.com>
In-Reply-To: <20260320-adf41513-iio-driver-v9-0-132f0d076374@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Andrew Morton <akpm@linux-foundation.org>, Petr Mladek <pmladek@suse.com>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rasmus Villemoes <linux@rasmusvillemoes.dk>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774024051; l=9281;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=4Hl6eJr1otWGgODbMYmIlLBwYdB04tVhvMYABjcX1S8=;
 b=91kd9Bq0X0tqT/sb6hdlzYx3D06cWhNO6LPDLCtWtWSRYscw4fzzNCPYwSkIhm0r8CPEzYwPo
 dWnTfwyXgwBC6pJSxx5hpMfIAvMFEVzONsdFelx34tPgzREoB0zAu70
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DT-bindings for ADF41513, an ultralow noise PLL frequency synthesizer that
can be used to implement local oscillators (LOs) as high as 26.5 GHz.
Some properties are based upon an existing PLL device properties
(e.g. ADF4350).

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 .../bindings/iio/frequency/adi,adf41513.yaml       | 215 +++++++++++++++++++++
 MAINTAINERS                                        |   7 +
 2 files changed, 222 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/frequency/adi,adf41513.yaml b/Documentation/devicetree/bindings/iio/frequency/adi,adf41513.yaml
new file mode 100644
index 000000000000..2d09cb94b6ff
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/frequency/adi,adf41513.yaml
@@ -0,0 +1,215 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/frequency/adi,adf41513.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Analog Devices ADF41513 PLL Frequency Synthesizer
+
+maintainers:
+  - Rodrigo Alencar <rodrigo.alencar@analog.com>
+
+description:
+  The ADF41513 is an ultralow noise frequency synthesizer that can be used to
+  implement local oscillators (LOs) as high as 26.5 GHz in the upconversion and
+  downconversion sections of wireless receivers and transmitters. The ADF41510
+  supports frequencies up to 10 GHz.
+
+  https://www.analog.com/en/products/adf41510.html
+  https://www.analog.com/en/products/adf41513.html
+
+$ref: /schemas/spi/spi-peripheral-props.yaml#
+
+properties:
+  compatible:
+    enum:
+      - adi,adf41510
+      - adi,adf41513
+
+  reg:
+    maxItems: 1
+
+  spi-max-frequency:
+    maximum: 25000000
+
+  clocks:
+    maxItems: 1
+    description: Clock that provides the reference input frequency.
+
+  avdd1-supply:
+    description: PFD and Up and Down Digital Driver Power Supply (3.3 V)
+
+  avdd2-supply:
+    description: RF Buffer and Prescaler Power Supply (3.3 V)
+
+  avdd3-supply:
+    description: N Divider Power Supply (3.3 V)
+
+  avdd4-supply:
+    description: R Divider and Lock Detector Power Supply (3.3 V)
+
+  avdd5-supply:
+    description: Sigma-Delta Modulator and SPI Power Supply (3.3 V)
+
+  vp-supply:
+    description: Charge Pump Power Supply (3.3 V)
+
+  enable-gpios:
+    description:
+      GPIO that controls the chip enable pin. A logic low on this pin
+      powers down the device and puts the charge pump output into
+      three-state mode.
+    maxItems: 1
+
+  lock-detect-gpios:
+    description:
+      GPIO for lock detect functionality. When configured for digital lock
+      detect, this pin will output a logic high when the PLL is locked.
+    maxItems: 1
+
+  adi,power-up-frequency-mhz:
+    minimum: 1000
+    maximum: 26500
+    default: 10000
+    description:
+      The PLL tunes to this frequency during the initialization sequence.
+      This property should be set to a frequency supported by the loop filter
+      and VCO used in the design. Range is 1 GHz to 26.5 GHz for ADF41513,
+      and 1 GHz to 10 GHz for ADF41510.
+
+  adi,reference-div-factor:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    minimum: 1
+    maximum: 32
+    default: 1
+    description:
+      Value for the reference division factor (R Counter). The driver will
+      increment R Counter as needed to achieve a PFD frequency within the
+      allowed range. High R counter values will reduce the PFD frequency, which
+      lowers the frequency resolution, and affects phase noise performance.
+      As it affects the PFD frequency, this value depends on the loop filter
+      design.
+
+  adi,reference-doubler-enable:
+    description:
+      Enables the reference doubler when deriving the PFD frequency.
+      The maximum reference frequency when the doubler is enabled is 225 MHz.
+      As it affects the PFD frequency, this value depends on the loop filter
+      design.
+    type: boolean
+
+  adi,reference-div2-enable:
+    description:
+      Enables the reference divide-by-2 function when deriving the PFD
+      frequency. As it affects the PFD frequency, this value depends on the
+      loop filter design.
+    type: boolean
+
+  adi,charge-pump-resistor-ohms:
+    minimum: 1800
+    maximum: 10000
+    default: 2700
+    description:
+      External charge pump resistor (R_SET) value in ohms. This sets the maximum
+      charge pump current along with the charge pump current setting.
+
+  adi,charge-pump-current-microamp:
+    description:
+      Charge pump current (I_CP) in microamps. The value will be rounded to the
+      nearest supported value. Range of acceptable values depends on the
+      charge pump resistor value, such that 810 mV <= I_CP * R_SET <= 12960 mV.
+      This value depends on the loop filter and the VCO design.
+
+  adi,logic-level-1v8-enable:
+    description:
+      Set MUXOUT and DLD logic levels to 1.8V. Default is 3.3V.
+    type: boolean
+
+  adi,phase-detector-polarity-positive-enable:
+    description:
+      Set phase detector polarity to positive. Default is negative.
+      Use positive polarity with non-inverting loop filter and VCO with
+      positive tuning slope, or with inverting loop filter and VCO with
+      negative tuning slope.
+    type: boolean
+
+  adi,lock-detector-count:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    default: 64
+    description:
+      Sets the value for Lock Detector count of the PLL, which determines the
+      number of consecutive phase detector cycles that must be within the lock
+      detector window before lock is declared. Lower values increase the lock
+      detection sensitivity, while higher values provides a more stable lock
+      detection. Applications that consume the lock detect signal may require
+      different settings based on system requirements.
+    enum: [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192]
+
+  adi,phase-resync-period-ns:
+    default: 0
+    description:
+      When this value is non-zero, enable phase resync functionality, which
+      produces a consistent output phase offset with respect to the input
+      reference. The value specifies the resync period in nanoseconds, used
+      to configure clock dividers with respect to the PFD frequency. This value
+      should be set to a value that is at least as long as the worst case lock
+      time, i.e., it depends mostly on the loop filter design.
+
+  adi,le-sync-enable:
+    description:
+      Synchronizes Load Enable (LE) transitions with the reference signal to
+      avoid asynchronous glitches in the output. This is recommended when using
+      the PLL as a frequency synthesizer, where the reference signal will always
+      be present while the device is being configured. When using the PLL as a
+      frequency tracker, where the reference signal may be absent, LE sync
+      should be left disabled.
+    type: boolean
+
+dependencies:
+  adi,charge-pump-resistor-ohms: [ 'adi,charge-pump-current-microamp' ]
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - avdd1-supply
+  - avdd2-supply
+  - avdd3-supply
+  - avdd4-supply
+  - avdd5-supply
+  - vp-supply
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    spi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        pll@0 {
+            compatible = "adi,adf41513";
+            reg = <0>;
+            spi-max-frequency = <25000000>;
+            clocks = <&ref_clk>;
+            avdd1-supply = <&avdd1_3v3>;
+            avdd2-supply = <&avdd2_3v3>;
+            avdd3-supply = <&avdd3_3v3>;
+            avdd4-supply = <&avdd4_3v3>;
+            avdd5-supply = <&avdd5_3v3>;
+            vp-supply = <&vp_3v3>;
+            enable-gpios = <&gpio0 10 GPIO_ACTIVE_HIGH>;
+            lock-detect-gpios = <&gpio0 11 GPIO_ACTIVE_HIGH>;
+
+            adi,power-up-frequency-mhz = <15500>;
+            adi,charge-pump-current-microamp = <3600>;
+            adi,charge-pump-resistor-ohms = <2700>;
+            adi,reference-doubler-enable;
+            adi,lock-detector-count = <64>;
+            adi,phase-resync-period-ns = <0>;
+            adi,phase-detector-polarity-positive-enable;
+            adi,le-sync-enable;
+        };
+    };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index 08d8ddf4ef68..e3568f08ea55 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1654,6 +1654,13 @@ W:	https://ez.analog.com/linux-software-drivers
 F:	Documentation/devicetree/bindings/iio/adc/adi,ade9000.yaml
 F:	drivers/iio/adc/ade9000.c
 
+ANALOG DEVICES INC ADF41513 DRIVER
+M:	Rodrigo Alencar <rodrigo.alencar@analog.com>
+L:	linux-iio@vger.kernel.org
+S:	Supported
+W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/devicetree/bindings/iio/frequency/adi,adf41513.yaml
+
 ANALOG DEVICES INC ADF4377 DRIVER
 M:	Antoniu Miclaus <antoniu.miclaus@analog.com>
 L:	linux-iio@vger.kernel.org

-- 
2.43.0

