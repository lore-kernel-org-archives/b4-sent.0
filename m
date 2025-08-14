From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Thu, 14 Aug 2025 11:52:25 +0100
Subject: [PATCH 3/6] dt-binbings: hwmon: Add bindings for the LTC4283 Swap
 Controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250814-ltc4283-support-v1-3-88b2cef773f2@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755168752; l=6973;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=HsDdoBnjwJgf7HxiAniojdoW83Qd+owHP8CXaML6ml4=;
 b=27DMRJsVWDaaEnYZxcgcr1RPm+1aGmpgHyXN6+ElU4OO6MijcnZbwKuFjtle603REtvrHnXt8
 6WuU+XcNdczC7Vq78GUn/aJ7QykX/fjLWcYAasrgDsFaJrrXyz4HwJ2
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the bindings for the Hardware monitoring functions of the
LTC4283 Hot Swap Controller.

Special note for the "adi,vpower-drns-enable" property. It allows to choose
between the attenuated MOSFET drain voltage or the attenuated input
voltage at the RTNS pin (effectively choosing between input or output
power). This is a system level decision not really intended to change at
runtime and hence is being added as Firmware property.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 .../devicetree/bindings/hwmon/adi,ltc4283.yaml     | 159 +++++++++++++++++++++
 MAINTAINERS                                        |   1 +
 2 files changed, 160 insertions(+)

diff --git a/Documentation/devicetree/bindings/hwmon/adi,ltc4283.yaml b/Documentation/devicetree/bindings/hwmon/adi,ltc4283.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..5630623fd3dafa1d86e1877de6cd8844e2826ed2
--- /dev/null
+++ b/Documentation/devicetree/bindings/hwmon/adi,ltc4283.yaml
@@ -0,0 +1,159 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/hwmon/adi,ltc4283.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: HWMON LTC4283 Negative Voltage Hot Swap Controller
+
+maintainers:
+  - Nuno Sá <nuno.sa@analog.com>
+
+description: |
+  This module is part of the LTC4283 MFD device.
+  See Documentation/devicetree/bindings/mfd/adi,ltc4283.yaml
+  This implements the HWMON bindings for the LTC4283 negative voltage hot swap
+  controller.
+
+properties:
+  compatible:
+    enum:
+      - adi,ltc4283-hwmon
+
+  adi,rsense-nano-ohms:
+    description: Value of the sense resistor.
+
+  adi,current-limit-sense-microvolt:
+    description:
+      The current limit sense voltage of the chip is adjustable between
+      15mV and 30mV in 1mV steps. This effectively limits the current
+      on the load.
+    minimum: 15000
+    maximum: 30000
+    default: 15000
+
+  adi,current-limit-foldback-factor:
+    description:
+      Specifies the foldback factor for the current limit. The current limit
+      can be reduced (folded back) to one of four preset levels. The value
+      represents the percentage of the current limit sense voltage to use
+      during foldback. A value of 100 means no foldback.
+    $ref: /schemas/types.yaml#/definitions/uint32
+    enum: [10, 20, 50, 100]
+    default: 100
+
+  adi,cooling-delay-ms:
+    description:
+      Cooling time to apply after an overcurrent fault, FET bad or
+      external fault.
+    enum: [512, 1002, 2005, 4100, 8190, 16400, 32800, 65600]
+    default: 512
+
+  adi,fet-bad-timer-delay-ms:
+    description:
+      FET bad timer delay. After a FET bad status condition is detected,
+      this timer is started. If the condition persists for the
+      specified time, the FET is turned off and a fault is logged.
+    enum: [256, 512, 1002, 2005]
+    default: 256
+
+  adi,power-good-reset-on-fet:
+    description:
+      If set, resets the power good status when the MOSFET is turned off.
+      Otherwise, it resets when a low output voltage is detected.
+    type: boolean
+
+  adi,fet-turn-off-disable:
+    description:
+      If set, the MOSFET is turned off immediately when a FET fault is detected.
+    type: boolean
+
+  adi,tmr-pull-down-disable:
+    description: Disables 2uA pull-down current on the TMR pin.
+    type: boolean
+
+  adi,dvdt-inrush-control-disable:
+    description:
+      Enables dV/dt inrush control during startup. In dV/dt mode, the inrush
+      current is limited by controlling a constant output voltage ramp rate.
+      If not set, the inrush control mechanism is active current limiting.
+    type: boolean
+
+  adi,fault-log-enable:
+    description:
+      If set, enables logging fault registers and ADC data into EEPROM upon a
+      fault.
+    type: boolean
+
+  adi,vpower-drns-enable:
+    description:
+      If set, enables the attenuated MOSFET drain voltage to be monitored. This
+      effectively means that the MOSFET power is monitored. If not set, the
+      attenuated input voltage (and hence input power) is monitored.
+    type: boolean
+
+  adi,external-fault-fet-off-enable:
+    description: Turns MOSFET off following an external fault.
+    type: boolean
+
+  adi,undervoltage-retry-disable:
+    description: Do not retry to turn on the MOSFET after an undervoltage fault.
+    type: boolean
+
+  adi,overvoltage-retry-disable:
+    description: Do not retry to turn on the MOSFET after an overvoltage fault.
+    type: boolean
+
+  adi,external-fault-retry-enable:
+    description: Retry to turn on the MOSFET retry after an external fault.
+    type: boolean
+
+  adi,overcurrent-retries:
+    description: Configures auto-retry following an Overcurrent fault.
+    $ref: /schemas/types.yaml#/definitions/string
+    enum: [latch-off, "1", "7", unlimited]
+    default: latch-off
+
+  adi,fet-bad-retries:
+    description:
+      Configures auto-retry following a FET bad fault and a consequent MOSFET
+      turn off.
+    $ref: /schemas/types.yaml#/definitions/string
+    enum: [latch-off, "1", "7", unlimited]
+    default: latch-off
+
+  adi,pgio1-func:
+    description: Configures the function of the PGIO1 pin.
+    $ref: /schemas/types.yaml#/definitions/string
+    enum: [inverted_power_good, power_good]
+    default: inverted_power_good
+
+  adi,pgio2-func:
+    description: Configures the function of the PGIO2 pin.
+    $ref: /schemas/types.yaml#/definitions/string
+    enum: [inverted_power_good, power_good, active_current_limiting]
+    default: inverted_power_good
+
+  adi,pgio3-func:
+    description: Configures the function of the PGIO3 pin.
+    $ref: /schemas/types.yaml#/definitions/string
+    enum: [inverted_power_good_input, power_good_input]
+    default: inverted_power_good_input
+
+  adi,pgio4-func:
+    description: Configures the function of the PGIO4 pin.
+    $ref: /schemas/types.yaml#/definitions/string
+    enum: [inverted_external_fault, external_fault]
+    default: inverted_external_fault
+
+dependencies:
+  adi,external-fault-retry-enable:
+    - adi,pgio4-func
+  adi,external-fault-fet-off-enable:
+    - adi,pgio4-func
+
+required:
+  - compatible
+  - adi,rsense-nano-ohms
+
+additionalProperties: false
diff --git a/MAINTAINERS b/MAINTAINERS
index b5f4f1c41c64b738d57c1fb5552a60b4c6b9985c..5f344ed81c80c9c30d6b2ee81bb00a44874e3b4c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -14505,6 +14505,7 @@ M:	Nuno Sá <nuno.sa@analog.com>
 L:	linux-hwmon@vger.kernel.org
 L:	linux-gpio@vger.kernel.org
 S:	Supported
+F:	Documentation/devicetree/bindings/hwmon/adi,ltc4283.yaml
 F:	Documentation/devicetree/bindings/mfd/adi,ltc4283.yaml
 F:	drivers/mfd/ltc4283.c
 F:	include/linux/mfd/ltc4283.h

-- 
2.50.1

