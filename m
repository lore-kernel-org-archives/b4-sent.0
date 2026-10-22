From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Thu, 22 Oct 2026 12:19:02 -0300
Subject: [PATCH v2 04/10] dt-bindings: iio: frequency: ad9910: add
 io-backends property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-ad9910-backend-support-v2-4-0ff7f0bff326@analog.com>
References: <20261022-ad9910-backend-support-v2-0-0ff7f0bff326@analog.com>
In-Reply-To: <20261022-ad9910-backend-support-v2-0-0ff7f0bff326@analog.com>
To: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux@analog.com, devicetree@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-doc@vger.kernel.org, 
 Jonathan Cameron <jonathan.cameron@oss.qualcomm.com>
Cc: Olivier Moysan <olivier.moysan@foss.st.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792682347; l=2580;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=j5dklZUTaCzTsmtRwls0MFDoIhZtjambNyK1FFjRxqs=;
 b=BsBOHVrPcRaqCnqD4VjmxeKnUFNL37ft9mauZkQYeiH7Dh5zw1B2NjNd5fVxFfd8mSvZZU9lZ
 rWk/dEVGvOqAluy7AvsMnkS+trqT9dnGz4d3NEEcB2AdsOo82aU+KoU
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AD9910 parallel data port allows high-speed modulation of the DDS
core parameters, which requires a data source such as an FPGA IP core
connected to the F[1:0] and D[15:0] pins. Add the io-backends property,
so that an IIO backend providing such interface can be referenced.

The property is optional as the parallel port is. The device remains
functional through the SPI control interface only, as other modes can
be used to drive the DDS core.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 .../bindings/iio/frequency/adi,ad9910.yaml         | 38 ++++++++++++++++++++++
 1 file changed, 38 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml b/Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
index 4eebbd388b27..02fd49db93ff 100644
--- a/Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
+++ b/Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
@@ -120,6 +120,13 @@ properties:
     items:
       - const: drctl
 
+  io-backends:
+    maxItems: 1
+    description:
+      IIO backend that interfaces with the parallel data port, enabling data
+      streaming into the device. The backend may also drive the PROFILE[2:0]
+      and DRCTL pins, the latter being exposed as a PWM provider.
+
   adi,pll-enable:
     type: boolean
     description:
@@ -206,4 +213,35 @@ examples:
             adi,refclk-out-drive-strength = "disabled";
         };
     };
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    spi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+        dds@0 {
+            compatible = "adi,ad9910";
+            reg = <0>;
+            spi-max-frequency = <1000000>;
+
+            #clock-cells = <1>;
+            clock-output-names = "sync_clk", "pdclk", "sync_out";
+
+            clocks = <&ad9910_refclk>;
+            clock-names = "ref_clk";
+
+            dvdd-io33-supply = <&vdd_io33>;
+            avdd33-supply = <&vdd_a33>;
+            dvdd18-supply = <&vdd_d18>;
+            avdd18-supply = <&vdd_a18>;
+
+            reset-gpios = <&gpio 0 GPIO_ACTIVE_HIGH>;
+            io-reset-gpios = <&gpio 1 GPIO_ACTIVE_HIGH>;
+            powerdown-gpios = <&gpio 2 GPIO_ACTIVE_HIGH>;
+            update-gpios = <&gpio 3 GPIO_ACTIVE_HIGH>;
+
+            io-backends = <&ad9910_backend>;
+            pwms = <&ad9910_backend 0 1000000 0>;
+            pwm-names = "drctl";
+        };
+    };
 ...

-- 
2.43.0

