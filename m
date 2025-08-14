From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Thu, 14 Aug 2025 11:52:23 +0100
Subject: [PATCH 1/6] dt-binbings: mfd: Add bindings for the LTC4283 Swap
 Controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250814-ltc4283-support-v1-1-88b2cef773f2@analog.com>
References: <20250814-ltc4283-support-v1-0-88b2cef773f2@analog.com>
In-Reply-To: <20250814-ltc4283-support-v1-0-88b2cef773f2@analog.com>
To: linux-hwmon@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org
Cc: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755168752; l=3762;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=jZczKELD9tr25sgoyyPTOyUqiGRTqVv0NPtNl4m1Aps=;
 b=x3h8XfOKIQ6nRfIb0Dexb7UHnFFxW4fEypnSf0LYhdxBmnaR8xSL/pbeFnelzNOpzH7C3BAX2
 GOt4VD2POJQDt2PWoijtrlPD0qnZ7eMuRYmcXo+PoImyoe4kLVbPXCQ
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LTC4283 is a negative voltage hot swap controller that drives an
external N-channel MOSFET to allow a board to be safely inserted and
removed from a live backplane.

Main usage is as an Hardware Monitoring device. However, it has up to 8
pins that can be configured and used as GPIOs and hence, the device can
also be a GPIO controller.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 .../devicetree/bindings/mfd/adi,ltc4283.yaml       | 85 ++++++++++++++++++++++
 MAINTAINERS                                        |  7 ++
 2 files changed, 92 insertions(+)

diff --git a/Documentation/devicetree/bindings/mfd/adi,ltc4283.yaml b/Documentation/devicetree/bindings/mfd/adi,ltc4283.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..c5e8aec887d9cfad9052a7c28783396efd6804a9
--- /dev/null
+++ b/Documentation/devicetree/bindings/mfd/adi,ltc4283.yaml
@@ -0,0 +1,85 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/mfd/adi,ltc4283.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: LTC4283 I2C Negative Voltage Hot Swap Controller
+
+maintainers:
+  - Nuno Sá <nuno.sa@analog.com>
+
+description: |
+  The LTC4283 negative voltage hot swap controller drives an external N-channel
+  MOSFET to allow a board to be safely inserted and removed from a live
+  backplane.
+
+  https://www.analog.com/media/en/technical-documentation/data-sheets/ltc4283.pdf
+
+properties:
+  compatible:
+    enum:
+      - adi,ltc4283
+
+  reg:
+    maxItems: 1
+
+  gpio:
+    $ref: /schemas/gpio/adi,ltc4283.yaml
+  hwmon:
+    $ref: /schemas/hwmon/adi,ltc4283.yaml
+
+  adi,gpio-pins:
+    description:
+      The pins to use as GPIOs. The device has 4 ADIO and 4 PGIO
+      pins than can be used as GPIOs. The ADIO pins are numbered from 0 to 3
+      and the PGIO pins are numbered from 4 to 7.
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+    minItems: 1
+    maxItems: 8
+    items:
+      minimum: 0
+      maximum: 7
+
+dependencies:
+  gpio:
+    - adi,gpio-pins
+
+required:
+  - compatible
+  - reg
+  - hwmon
+
+additionalProperties: false
+
+examples:
+  - |
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        swap-controller@15 {
+            compatible = "adi,ltc4283";
+            reg = <0x15>;
+
+            /* pgio1 to pgio4 as gpios */
+            adi,gpio-pins = <0 1 2 3>;
+
+            gpio {
+                compatible = "adi,ltc4283-gpio";
+                gpio-controller;
+                #gpio-cells = <2>;
+            };
+
+            hwmon {
+                compatible = "adi,ltc4283-hwmon";
+
+                adi,rsense-nano-ohms = <500>;
+                adi,current-limit-sense-microvolt = <25000>;
+                adi,current-limit-foldback-factor = <10>;
+                adi,cooling-delay-ms = <8190>;
+                adi,fet-bad-timer-delay-ms = <512>;
+            };
+        };
+    };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index e90710a9b40d7b32c151472a9ac3b02efd95f346..413bb77d5eebe2b51aa9c3af86e7cfd5ab142044 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -14500,6 +14500,13 @@ F:	Documentation/devicetree/bindings/hwmon/adi,ltc4282.yaml
 F:	Documentation/hwmon/ltc4282.rst
 F:	drivers/hwmon/ltc4282.c
 
+lTC4283 HARDWARE MONITOR AND GPIO DRIVER
+M:	Nuno Sá <nuno.sa@analog.com>
+L:	linux-hwmon@vger.kernel.org
+L:	linux-gpio@vger.kernel.org
+S:	Supported
+F:	Documentation/devicetree/bindings/mfd/adi,ltc4283.yaml
+
 LTC4286 HARDWARE MONITOR DRIVER
 M:	Delphine CC Chiu <Delphine_CC_Chiu@Wiwynn.com>
 L:	linux-hwmon@vger.kernel.org

-- 
2.50.1

