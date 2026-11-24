From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Date: Tue, 24 Nov 2026 18:43:02 +0100
Subject: [PATCH 3/4] dt-bindings: misc: Add FPC1540 fingerprint sensor
 driven by a QSEE app
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-fpc1540-tee-v1-3-6c6985f05b06@proton.me>
References: <20261124-fpc1540-tee-v1-0-6c6985f05b06@proton.me>
In-Reply-To: <20261124-fpc1540-tee-v1-0-6c6985f05b06@proton.me>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Armandas Kvietkus <armandas.kvietkus@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795542180; l=2873;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=r+50ATdWgwMvyyU3S4K6ZQcnyzT6AuxDtEZt9y0AbfU=;
 b=fJH/tEfkZk9mLQMLKJcMuRw42M4pDgfk61eaJPpnbpTy2RODsXCpkaF6GfE6TD9RrmCm/15p3
 vvqFRRYO8xrAsQcW6rr2OckeP+bLxi6uAp9C1nkvRDG6ElpmgbRUiRs
X-Developer-Key: i=armandas.kvietkus@proton.me; a=ed25519;
 pk=wuqmImJ9sKlDVcwALOvfGhjj7G8EBjjM4TpCdmlrAf8=
X-Endpoint-Received: by B4 Relay for armandas.kvietkus@proton.me/default with auth_id=974
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On some Qualcomm phones the FPC1540 sits on a QUP owned by the secure
world and a QSEE app drives it. Linux only powers and resets it, takes
the interrupt and loads the app.

Signed-off-by: Armandas Kvietkus <armandas.kvietkus@proton.me>
---
 .../devicetree/bindings/misc/fpc,fpc1540-tee.yaml  | 74 ++++++++++++++++++++++
 1 file changed, 74 insertions(+)

diff --git a/Documentation/devicetree/bindings/misc/fpc,fpc1540-tee.yaml b/Documentation/devicetree/bindings/misc/fpc,fpc1540-tee.yaml
new file mode 100644
index 000000000000..0c2ec847c2d7
--- /dev/null
+++ b/Documentation/devicetree/bindings/misc/fpc,fpc1540-tee.yaml
@@ -0,0 +1,74 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/misc/fpc,fpc1540-tee.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: FPC1540 fingerprint sensor driven by a QSEE trusted application
+
+maintainers:
+  - Armandas Kvietkus <armandas.kvietkus@proton.me>
+
+description:
+  The FPC1540 is connected to a QUP serial engine that the secure world owns.
+  A QSEE trusted application drives the sensor. Linux powers and resets the
+  sensor, receives the finger interrupt and loads the trusted application.
+
+properties:
+  compatible:
+    const: fpc,fpc1540-tee
+
+  firmware-name:
+    minItems: 1
+    items:
+      - description: Path of the trusted application, without the .mdt suffix.
+      - description:
+          Path of the QSEE common library the trusted application needs,
+          without the .mdt suffix.
+
+  vdd-supply: true
+
+  reset-gpios:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  irq-gpios:
+    maxItems: 1
+    description:
+      The interrupt line read as a GPIO, so that edges where the line is
+      already low again are not reported as a finger.
+
+  memory-region:
+    maxItems: 1
+    description:
+      Region used to pass the trusted application image to QSEE. The whole
+      region is shared with QSEE because QSEE reads past the end of the image
+      while it starts the application.
+
+required:
+  - compatible
+  - firmware-name
+  - vdd-supply
+  - reset-gpios
+  - interrupts
+  - memory-region
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    fingerprint {
+        compatible = "fpc,fpc1540-tee";
+        firmware-name = "qcom/sm8250/xiaomi/alioth/fpcali",
+                        "qcom/sm8250/xiaomi/alioth/cmnlib64";
+        vdd-supply = <&vreg_l13a_3p3>;
+        reset-gpios = <&tlmm 24 GPIO_ACTIVE_LOW>;
+        interrupts-extended = <&tlmm 23 IRQ_TYPE_EDGE_RISING>;
+        irq-gpios = <&tlmm 23 GPIO_ACTIVE_HIGH>;
+        memory-region = <&fpc_ta_mem>;
+    };

-- 
2.56.0

