From: Vidhu Sarwal <vidhu.linux@gmail.com>
Date: Sat, 31 Oct 2026 00:23:29 +0530
Subject: [PATCH v2 2/3] dt-bindings: iio: proximity: Add Benewake TF-Luna
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-tf-luna-v2-2-ce403579bb8a@gmail.com>
References: <20261031-tf-luna-v2-0-ce403579bb8a@gmail.com>
In-Reply-To: <20261031-tf-luna-v2-0-ce403579bb8a@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vidhu Sarwal <vidhu.linux@gmail.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-iio@vger.kernel.org, Shuah Khan <skhan@linuxfoundation.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793386408; l=3211;
 i=vidhu.linux@gmail.com; s=20260713; h=from:subject:message-id;
 bh=ocYeyqYoBl3HVzLcvJavpWYsClFy28D0KPq7x1fpZtk=;
 b=mW6j3+3+quNnEyG314nQuPlWdij1s9csYRJfc/7JZI5uprtNNcWI8ZYNBE6Y4QhyuclPdyvCS
 fY+jnFEKkuDCGISJypY0qM9qqDRKb388XPvK92kUjX5DuvqCqyyCwBz
X-Developer-Key: i=vidhu.linux@gmail.com; a=ed25519;
 pk=xDu3Cbesz76CQXwY8lteI74n3ELVIV7wCsuYAvcX1Q4=
X-Endpoint-Received: by B4 Relay for vidhu.linux@gmail.com/20260713 with auth_id=869
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add binding for the Benewake TF-Luna, a single point ToF
LiDAR distance sensor with a range of 0.2 m to 8 m.

The sensor talks either UART or I2C, selected by the level of pin 5 at
power-up. This binding covers both interfaces. Pin 6 is a data ready
output and is described as an interrupt.

Signed-off-by: Vidhu Sarwal <vidhu.linux@gmail.com>
---
 .../bindings/iio/proximity/benewake,tf-luna.yaml   | 66 ++++++++++++++++++++++
 MAINTAINERS                                        |  6 ++
 2 files changed, 72 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/proximity/benewake,tf-luna.yaml b/Documentation/devicetree/bindings/iio/proximity/benewake,tf-luna.yaml
new file mode 100644
index 000000000000..607a71a6ab39
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/proximity/benewake,tf-luna.yaml
@@ -0,0 +1,66 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/proximity/benewake,tf-luna.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Benewake TF-Luna LiDAR distance sensor
+
+maintainers:
+  - Vidhu Sarwal <vidhu.linux@gmail.com>
+
+description: |
+  Single-point time-of-flight LiDAR ranging sensor with a range of 0.2 m to
+  8 m. The sensor talks either UART or I2C, selected at power-up by the level
+  of pin 5: tied to ground for I2C, unconnected or tied to 3.3 V for UART.
+
+  Datasheet: https://en.benewake.com/uploadfiles/2025/04/20250430174501874.pdf
+
+properties:
+  compatible:
+    const: benewake,tf-luna
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    description:
+      Output on pin 6. In I2C mode it is a data ready signal that goes high
+      when a new measurement is available and goes low again once any
+      register has been read. In UART mode it can be configured as an on/off
+      output.
+    maxItems: 1
+
+  vcc-supply:
+    description: Power supply, 3.7 V to 5.2 V.
+
+required:
+  - compatible
+  - vcc-supply
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        proximity@10 {
+            compatible = "benewake,tf-luna";
+            reg = <0x10>;
+            vcc-supply = <&reg_5v>;
+            interrupt-parent = <&gpio>;
+            interrupts = <17 IRQ_TYPE_EDGE_RISING>;
+        };
+    };
+  - |
+    serial {
+        proximity {
+            compatible = "benewake,tf-luna";
+            vcc-supply = <&reg_5v>;
+        };
+    };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index 52024397dc78..24fa7cdf6a57 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -4662,6 +4662,12 @@ T:	git git://git.kernel.org/pub/scm/linux/kernel/git/luisbg/linux-befs.git
 F:	Documentation/filesystems/befs.rst
 F:	fs/befs/
 
+BENEWAKE TF-LUNA LIDAR IIO DRIVER
+M:	Vidhu Sarwal <vidhu.linux@gmail.com>
+L:	linux-iio@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/iio/proximity/benewake,tf-luna.yaml
+
 BFQ I/O SCHEDULER
 M:	Yu Kuai <yukuai@fygo.io>
 L:	linux-block@vger.kernel.org

-- 
2.53.0

