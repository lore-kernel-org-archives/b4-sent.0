From: Marc Paolo Sosa <marcpaolo.sosa@analog.com>
Date: Mon, 23 Feb 2026 19:03:39 +0800
Subject: [PATCH 1/2] dt-bindings: input: add adi,max16150.yaml
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260223-max16150-v1-1-38e2a4f0d0f1@analog.com>
References: <20260223-max16150-v1-0-38e2a4f0d0f1@analog.com>
In-Reply-To: <20260223-max16150-v1-0-38e2a4f0d0f1@analog.com>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Marc Paolo Sosa <marcpaolo.sosa@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771844627; l=2157;
 i=marcpaolo.sosa@analog.com; s=20260223; h=from:subject:message-id;
 bh=FCRMkpPyY7JkXoCOu/8LiDptZShSrNSW8K5xYAqx4ys=;
 b=/XLmGgLq5Q+a/wtPXa90y3m5gsY+TuTX6gKxip/zEjIWh0QoWtmDkEpqQZ4NAjso1GaReEUdb
 nlOUbN9sbfHBf19dUrxL9yr/ZMvT0ZJiBAN23MxxeuUag3HSmcxi9SJ
X-Developer-Key: i=marcpaolo.sosa@analog.com; a=ed25519;
 pk=RR72PZYRimO/84huVqlVyHN3IM3AL984DRKCEXnOJuE=
X-Endpoint-Received: by B4 Relay for marcpaolo.sosa@analog.com/20260223 with auth_id=646
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation for device tree bindings for MAX16150/MAX16169

Signed-off-by: Marc Paolo Sosa <marcpaolo.sosa@analog.com>
---
 .../devicetree/bindings/input/adi,max16150.yaml    | 57 ++++++++++++++++++++++
 1 file changed, 57 insertions(+)

diff --git a/Documentation/devicetree/bindings/input/adi,max16150.yaml b/Documentation/devicetree/bindings/input/adi,max16150.yaml
new file mode 100644
index 000000000000..327811e1ebd4
--- /dev/null
+++ b/Documentation/devicetree/bindings/input/adi,max16150.yaml
@@ -0,0 +1,57 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/input/adi,max16150.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Analog Devices MAX16150/MAX16169 nanoPower Pushbutton On/Off Controller
+
+maintainers:
+  - Marc Paolo Sosa <marcpaolo.sosa@analog.com>
+
+description:
+  The MAX16150/MAX16169 is a low-power pushbutton on/off controller with a
+  switch debouncer and built-in latch. It accepts a noisy input from a
+  mechanical switch and produces a clean latched output, as well as a one-shot
+  interrupt output.
+
+properties:
+  compatible:
+    description:
+      Specifies the supported device variants. The MAX16150 and MAX16169 are supported.
+    enum:
+      - adi,max16150a
+      - adi,max16150b
+      - adi,max16169a
+      - adi,max16169b
+
+  interrupt-gpio:
+    maxItems: 1
+
+  clr-gpios:
+    description:
+      Clear Input. Pulling CLR low deasserts the latched OUT signal. If OUT is
+      already deasserted when CLR is pulled low, the state of OUT is unchanged.
+    maxItems: 1
+
+  linux,code:
+    default: KEY_POWER
+
+required:
+  - compatible
+  - interrupt-gpios
+  - clr-gpios
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/input/linux-event-codes.h>
+    #include <dt-bindings/gpio/gpio.h>
+
+    power-button {
+        compatible = "adi,max16150a";
+        interrupt-gpios = <&gpio 17 GPIO_ACTIVE_HIGH>;
+        clr-gpios = <&gpio 4 GPIO_ACTIVE_LOW>;
+        linux,code = <KEY_POWER>;
+    };

-- 
2.34.1

