From: Arturs Artamonovs <arturs.artamonovs@analog.com>
Date: Thu, 12 Sep 2024 19:24:59 +0100
Subject: [PATCH 14/21] dt-bindings: pinctrl: adi,adsp-pinctrl: add bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240912-test-v1-14-458fa57c8ccf@analog.com>
References: <20240912-test-v1-0-458fa57c8ccf@analog.com>
In-Reply-To: <20240912-test-v1-0-458fa57c8ccf@analog.com>
To: Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, Greg Malysa <greg.malysa@timesys.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Utsav Agarwal <Utsav.Agarwal@analog.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Thomas Gleixner <tglx@linutronix.de>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Arnd Bergmann <arnd@arndb.de>, 
 Olof Johansson <olof@lixom.net>, soc@kernel.org
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-serial@vger.kernel.org, 
 Arturs Artamonovs <arturs.artamonovs@analog.com>, adsp-linux@analog.com, 
 Arturs Artamonovs <Arturs.Artamonovs@analog.com>, 
 Nathan Barrett-Morrison <nathan.morrison@timesys.com>
X-Mailer: b4 0.15-dev-7be4f
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726165513; l=3857;
 i=arturs.artamonovs@analog.com; s=20240909; h=from:subject:message-id;
 bh=8cIHFW2VHjXFP2WdC7ohf0MOYH4XA2BareGL3V29WFU=;
 b=fK46p873AmYdSJ17NDk9Nq0m1iWXpEzwV7H2MptZzhNyghpOJrlmoWDjpnQS17mhBhGwihE3U
 SVtUZ+iSYzCB+MHGX3zfxt3/UF5DP84N3NJOWd5Mmeie3LXzznZn1XN
X-Developer-Key: i=arturs.artamonovs@analog.com; a=ed25519;
 pk=UXODIid/MrmBXvqkX4PeEfetDaNAw9xKMINHIc5oZCk=
X-Endpoint-Received: by B4 Relay for arturs.artamonovs@analog.com/20240909 with auth_id=206
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add PINCTRL driver bindings.

Signed-off-by: Arturs Artamonovs <Arturs.Artamonovs@analog.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Signed-off-by: Greg Malysa <greg.malysa@timesys.com>
---
 .../bindings/pinctrl/adi,adsp-pinctrl.yaml         | 83 ++++++++++++++++++++++
 include/dt-bindings/pinctrl/adi-adsp.h             | 19 +++++
 2 files changed, 102 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/adi,adsp-pinctrl.yaml b/Documentation/devicetree/bindings/pinctrl/adi,adsp-pinctrl.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..073442b4f680bf536f631b4c17a1d3195c2233d6
--- /dev/null
+++ b/Documentation/devicetree/bindings/pinctrl/adi,adsp-pinctrl.yaml
@@ -0,0 +1,83 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pinctrl/adi,adsp-pinctrl.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Analog Devices Pinmuxing Control for SC5XX Processor Family
+
+maintainers:
+  - Arturs Artamonovs <arturs.artamonovs@analog.com>
+  - Utsav Agarwal <Utsav.Agarwal@analog.com>
+
+description: |
+  Pinmuxing Control Driver for Configuring Processor Pins/Pads
+
+properties:
+  compatible:
+    enum:
+      - adi,adsp-pinctrl
+
+  "#address-cells":
+    const: 1
+
+  "#size-cells":
+    const: 1
+
+  reg:
+    maxItems: 1
+
+  "adi,port-sizes":
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+    maxItems: 9
+    description: Space delimited integer list denoting number of pins per port
+      Ports A-I exist, so this is up to 9 items long
+
+  "adi,no-drive-strength":
+    type: boolean
+    description: Indicate missing drive strength registers
+
+  "adi,no-pull-up-down":
+    type: boolean
+    description: Indicate missing pull up/down enable registers
+
+patternProperties:
+  '-pins$':
+    type: object
+    additionalProperties: false
+
+    properties:
+      pins:
+        type: object
+        description: |
+          A pinctrl node should contain a pin property, specifying the actual
+          pins to use.
+
+        properties:
+          pinmux:
+            $ref: /schemas/types.yaml#/definitions/uint32-array
+            description: |
+              pinmux is used to specify which of the available functionalities
+              for a given pin are actually used.
+
+        additionalProperties: false
+
+required:
+  - compatible
+  - "#address-cells"
+  - "#size-cells"
+  - reg
+  - "adi,port-sizes"
+
+additionalProperties: false
+
+examples:
+  - |
+    pinctrl0: pinctrl@31004600 {
+      compatible = "adi,adsp-pinctrl";
+      #address-cells = <1>;
+      #size-cells = <1>;
+      reg = <0x31004600 0x400>;
+      adi,port-sizes = <16 16 16 16 16 16 16 16 7>;
+    };
+
diff --git a/include/dt-bindings/pinctrl/adi-adsp.h b/include/dt-bindings/pinctrl/adi-adsp.h
new file mode 100644
index 0000000000000000000000000000000000000000..dc5b86a0d9190acdd242a6ba4972c3aac7a61821
--- /dev/null
+++ b/include/dt-bindings/pinctrl/adi-adsp.h
@@ -0,0 +1,19 @@
+/* SPDX-License-Identifier: GPL-2.0*/
+/*
+ * Macros for populating pinmux properties on the pincontroller
+ *
+ * Copyright 2022-2024 - Analog Devices Inc.
+ */
+
+#ifndef DT_BINDINGS_PINCTRL_ADI_ADSP_H
+#define DT_BINDINGS_PINCTRL_ADI_ADSP_H
+
+#define ADI_ADSP_PINFUNC_GPIO     0
+#define ADI_ADSP_PINFUNC_ALT0     1
+#define ADI_ADSP_PINFUNC_ALT1     2
+#define ADI_ADSP_PINFUNC_ALT2     3
+#define ADI_ADSP_PINFUNC_ALT3     4
+
+#define ADI_ADSP_PINMUX(port, pin, func) ((((port - 'A')*16 + pin) << 8) + func)
+
+#endif

-- 
2.25.1

