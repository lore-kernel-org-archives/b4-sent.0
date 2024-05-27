From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Mon, 27 May 2024 20:02:34 +0300
Subject: [PATCH v3 1/6] dt-bindings: adc: ad7173: add support for ad411x
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240527-ad4111-v3-1-7e9eddbbd3eb@analog.com>
References: <20240527-ad4111-v3-0-7e9eddbbd3eb@analog.com>
In-Reply-To: <20240527-ad4111-v3-0-7e9eddbbd3eb@analog.com>
To: Ceclan Dumitru <dumitru.ceclan@analog.com>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dumitru Ceclan <mitrutzceclan@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716829358; l=6275;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=1wlr2he6NWLwHETQMfKvuBxqnB76wNWQ32VnB84HEfw=;
 b=vTzxYkwa9zI0HtMfB9xsqifGgN/WZjj48pt+23AfJ+HUyWSFb24JLQQP5ljYv+04azI5NtDMi
 hZ1UKXZLrFtB1N3DEgAziWJscJb3SKX0moKipQWtfG/YMHFjsMGkxVU
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for: AD4111, AD4112, AD4114, AD4115, AD4116.

AD411x family ADCs support a VCOM pin, dedicated for single-ended usage.
AD4111/AD4112 support current channels, usage is implemented by
 specifying channel reg values bigger than 15.

Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 .../devicetree/bindings/iio/adc/adi,ad7173.yaml    | 122 ++++++++++++++++++++-
 1 file changed, 120 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/iio/adc/adi,ad7173.yaml b/Documentation/devicetree/bindings/iio/adc/adi,ad7173.yaml
index ea6cfcd0aff4..5b1af382dad3 100644
--- a/Documentation/devicetree/bindings/iio/adc/adi,ad7173.yaml
+++ b/Documentation/devicetree/bindings/iio/adc/adi,ad7173.yaml
@@ -19,7 +19,18 @@ description: |
   primarily for measurement of signals close to DC but also delivers
   outstanding performance with input bandwidths out to ~10kHz.
 
+  Analog Devices AD411x ADC's:
+  The AD411X family encompasses a series of low power, low noise, 24-bit,
+  sigma-delta analog-to-digital converters that offer a versatile range of
+  specifications. They integrate an analog front end suitable for processing
+  fully differential/single-ended and bipolar voltage inputs.
+
   Datasheets for supported chips:
+    https://www.analog.com/media/en/technical-documentation/data-sheets/AD4111.pdf
+    https://www.analog.com/media/en/technical-documentation/data-sheets/AD4112.pdf
+    https://www.analog.com/media/en/technical-documentation/data-sheets/AD4114.pdf
+    https://www.analog.com/media/en/technical-documentation/data-sheets/AD4115.pdf
+    https://www.analog.com/media/en/technical-documentation/data-sheets/AD4116.pdf
     https://www.analog.com/media/en/technical-documentation/data-sheets/AD7172-2.pdf
     https://www.analog.com/media/en/technical-documentation/data-sheets/AD7172-4.pdf
     https://www.analog.com/media/en/technical-documentation/data-sheets/AD7173-8.pdf
@@ -31,6 +42,11 @@ description: |
 properties:
   compatible:
     enum:
+      - adi,ad4111
+      - adi,ad4112
+      - adi,ad4114
+      - adi,ad4115
+      - adi,ad4116
       - adi,ad7172-2
       - adi,ad7172-4
       - adi,ad7173-8
@@ -129,10 +145,36 @@ patternProperties:
         maximum: 15
 
       diff-channels:
+        description: |
+          For using current channels specify select the current inputs
+           and enable the adi,current-channel property.
+
+          Family AD411x supports a dedicated VINCOM voltage input.
+          To select it set the second channel to 16.
+            (VIN2, VINCOM) -> diff-channels = <2 16>
+
+          There are special values that can be selected besides the voltage
+          analog inputs:
+            21: REF+
+            22: REF−
+          Supported only by AD7172-2, AD7172-4, AD7175-2, AD7175-8, AD7177-2:
+            19: ((AVDD1 − AVSS)/5)+
+            20: ((AVDD1 − AVSS)/5)−
+
         items:
           minimum: 0
           maximum: 31
 
+      single-channel:
+        description: |
+          Models AD4111 and AD4112 support single-ended current channels.
+          To select the desired current input, specify the desired input pair:
+            (IIN2+, IIN2−) -> single-channel = <2>
+
+        items:
+          minimum: 1
+          maximum: 16
+
       adi,reference-select:
         description: |
           Select the reference source to use when converting on
@@ -154,9 +196,26 @@ patternProperties:
           - avdd
         default: refout-avss
 
+      adi,current-channel:
+        description: |
+          Signal that the selected inputs are current channels.
+          Only available on AD4111 and AD4112.
+        type: boolean
+
+      adi,channel-type:
+        description:
+          Used to differentiate between different channel types as the device
+           register configurations are the same for all usage types.
+          Both pseudo-differential and single-ended channels will use the
+           single-ended specifier.
+        $ref: /schemas/types.yaml#/definitions/string
+        enum:
+          - single-ended
+          - differential
+        default: differential
+
     required:
       - reg
-      - diff-channels
 
 required:
   - compatible
@@ -166,7 +225,6 @@ allOf:
   - $ref: /schemas/spi/spi-peripheral-props.yaml#
 
   # Only ad7172-4, ad7173-8 and ad7175-8 support vref2
-  # Other models have [0-3] channel registers
   - if:
       properties:
         compatible:
@@ -187,6 +245,37 @@ allOf:
                 - vref
                 - refout-avss
                 - avdd
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - adi,ad4114
+              - adi,ad4115
+              - adi,ad4116
+              - adi,ad7173-8
+              - adi,ad7175-8
+    then:
+      patternProperties:
+        "^channel@[0-9a-f]$":
+          properties:
+            reg:
+              maximum: 15
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - adi,ad7172-2
+              - adi,ad7175-2
+              - adi,ad7176-2
+              - adi,ad7177-2
+    then:
+      patternProperties:
+        "^channel@[0-9a-f]$":
+          properties:
             reg:
               maximum: 3
 
@@ -210,6 +299,35 @@ allOf:
           required:
             - adi,reference-select
 
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - adi,ad4111
+              - adi,ad4112
+              - adi,ad4114
+              - adi,ad4115
+              - adi,ad4116
+    then:
+      properties:
+        avdd2-supply: false
+
+  - if:
+      properties:
+        compatible:
+          not:
+            contains:
+              enum:
+                - adi,ad4111
+                - adi,ad4112
+    then:
+      patternProperties:
+        "^channel@[0-9a-f]$":
+          properties:
+            single-channel: false
+            adi,current-channel: false
+
   - if:
       anyOf:
         - required: [clock-names]

-- 
2.43.0

