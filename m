From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 16 Nov 2026 16:39:57 +0000
Subject: [PATCH v4 05/12] dt-bindings: iio: frequency: add
 adi,ad9910-axi-backend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-ad9910-backend-support-v4-5-fcf1ad364ed5@analog.com>
References: <20261116-ad9910-backend-support-v4-0-fcf1ad364ed5@analog.com>
In-Reply-To: <20261116-ad9910-backend-support-v4-0-fcf1ad364ed5@analog.com>
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
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794847197; l=3737;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=BlveSXTBkrVMa7jHBGiJtSUp2f/q4Ub0i4UsjmjsZ+4=;
 b=BVUU10xdaf7Mb9RdndNTU2RBmYkqeDwV+d2p8/AA8Jzw64w7xJTrKWdgvFf5D8PzIWnaimpvI
 CohJx//207JDVXT5SkMpFJmv8ASxF9A8pQuqDf+SHxphxQALdJ94QJs
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for the AD9910 AXI backend IP core. The FPGA IP core
interfaces with the data and control pins of the AD9910 DDS, streaming
data from memory via DMA into the 18-bit parallel data port (F[1:0] and
D[15:0] pins), which is clocked by the PDCLK output of the device. It
also drives the PROFILE[2:0] pins and the DRCTL pin, which controls the
slope direction of the digital ramp generator (DRG). The DRCTL pin is
driven by a PWM generator, so the IP core is described both as an IIO
backend and as a PWM provider.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 .../iio/frequency/adi,ad9910-axi-backend.yaml      | 74 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 75 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/frequency/adi,ad9910-axi-backend.yaml b/Documentation/devicetree/bindings/iio/frequency/adi,ad9910-axi-backend.yaml
new file mode 100644
index 000000000000..0015a92aeaea
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/frequency/adi,ad9910-axi-backend.yaml
@@ -0,0 +1,74 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/frequency/adi,ad9910-axi-backend.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Analog Devices AD9910 AXI Backend IP core
+
+maintainers:
+  - Rodrigo Alencar <rodrigo.alencar@analog.com>
+
+description:
+  FPGA IP core that interfaces with the data and control pins of the AD9910
+  Direct Digital Synthesizer. The SPI bus is used as the control interface
+  of the AD9910 device, while this IP core streams data from memory via DMA
+  into the 18-bit parallel data port (F[1:0] and D[15:0] pins), which is
+  clocked by the PDCLK output of the AD9910. The IP core also drives the
+  PROFILE[2:0] pins for profile selection and provides a PWM generator that
+  drives the DRCTL pin, controlling the digital ramp generator (DRG) slope
+  direction.
+
+  https://developer.analog.com/docs/hdl/latest/library/axi_ad9910/index.html
+
+properties:
+  compatible:
+    const: adi,ad9910-axi-backend
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    maxItems: 1
+    description: AXI bus clock (s_axi_aclk).
+
+  dmas:
+    maxItems: 1
+
+  dma-names:
+    items:
+      - const: tx
+
+  '#io-backend-cells':
+    const: 0
+
+  '#pwm-cells':
+    const: 3
+    description:
+      The first cell is the PWM channel index, which must be 0 (DRCTL output).
+      The second cell is the PWM period in nanoseconds and the third cell
+      holds the PWM flags.
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - dmas
+  - dma-names
+  - '#io-backend-cells'
+  - '#pwm-cells'
+
+additionalProperties: false
+
+examples:
+  - |
+    ad9910_backend: dds-backend@44a00000 {
+        compatible = "adi,ad9910-axi-backend";
+        reg = <0x44a00000 0x10000>;
+        clocks = <&clkc 15>;
+        dmas = <&tx_dma 0>;
+        dma-names = "tx";
+        #io-backend-cells = <0>;
+        #pwm-cells = <3>;
+    };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index 02015eaec312..1913532d96b3 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1774,6 +1774,7 @@ S:	Supported
 W:	https://ez.analog.com/linux-software-drivers
 F:	Documentation/ABI/testing/debugfs-iio-ad9910
 F:	Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910
+F:	Documentation/devicetree/bindings/iio/frequency/adi,ad9910-axi-backend.yaml
 F:	Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
 F:	Documentation/iio/ad9910.rst
 F:	drivers/iio/frequency/ad9910.c

-- 
2.43.0

