From: Arturs Artamonovs <arturs.artamonovs@analog.com>
Date: Thu, 12 Sep 2024 19:24:55 +0100
Subject: [PATCH 10/21] dt-bindings: gpio: adi,adsp-port-gpio: add bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240912-test-v1-10-458fa57c8ccf@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726165513; l=2563;
 i=arturs.artamonovs@analog.com; s=20240909; h=from:subject:message-id;
 bh=cfOfuzOPLZMfuiN15jp5jl3DQDp54rB8wtv1oWhiCQQ=;
 b=sCywtZ4XrQYa/PO5ZEQL4TN0cv+Zg4tyhTVMbmf3ThpCbmUIkz2SdELt230uY5LEcIXMW/KtL
 jeBKoWMuk8dAQE3Ql2FcLeK81laxlcnGLBAVzEhv+u8dGAgfPzQM8be
X-Developer-Key: i=arturs.artamonovs@analog.com; a=ed25519;
 pk=UXODIid/MrmBXvqkX4PeEfetDaNAw9xKMINHIc5oZCk=
X-Endpoint-Received: by B4 Relay for arturs.artamonovs@analog.com/20240909 with auth_id=206
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ADSP-SC5xx GPIO driver bindings.

Signed-off-by: Arturs Artamonovs <Arturs.Artamonovs@analog.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Signed-off-by: Greg Malysa <greg.malysa@timesys.com>
---
 .../bindings/gpio/adi,adsp-port-gpio.yaml          | 69 ++++++++++++++++++++++
 1 file changed, 69 insertions(+)

diff --git a/Documentation/devicetree/bindings/gpio/adi,adsp-port-gpio.yaml b/Documentation/devicetree/bindings/gpio/adi,adsp-port-gpio.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..3d7899ce759193296ce787d09d742824277f37f8
--- /dev/null
+++ b/Documentation/devicetree/bindings/gpio/adi,adsp-port-gpio.yaml
@@ -0,0 +1,69 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/gpio/adi,adsp-port-gpio.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Analog Devices GPIO Port Driver for SC5XX-family processors
+
+maintainers:
+  - Arturs Artamonovs <arturs.artamonovs@analog.com>
+  - Utsav Agarwal <Utsav.Agarwal@analog.com>
+
+description: |
+  Analog Devices GPIO Port Driver for SC5XX-family processors
+
+properties:
+  compatible:
+    enum:
+      - adi,adsp-port-gpio
+
+  gpio-controller: true
+
+  "#gpio-cells":
+    const: 2
+
+  gpio-ranges:
+    description: Associated pinmux controller and the GPIO range values
+
+  adi,pint:
+    $ref: /schemas/types.yaml#/definitions/phandle-array
+    description: Associated pin interrupt controller driver
+    items:
+      - items:
+          - description: phandle to pin interrupt controller driver
+          - description: interrupt value
+
+  reg:
+    description: PORT GPIO control registers
+
+required:
+  - compatible
+  - reg
+  - "#gpio-cells"
+  - gpio-controller
+  - gpio-ranges
+  - adi,pint
+
+additionalProperties: false
+
+examples:
+  - |
+    gpa: gport@31004000 {
+      compatible = "adi,adsp-port-gpio";
+      gpio-controller;
+      #gpio-cells = <2>;
+      reg = <0x31004000 0x7F>;
+      gpio-ranges = <&pinctrl0 0 0 16>;
+      adi,pint = <&pint0 1>;
+    };
+
+    gpb: gport@31004080 {
+      compatible = "adi,adsp-port-gpio";
+      gpio-controller;
+      #gpio-cells = <2>;
+      reg = <0x31004080 0x7F>;
+      gpio-ranges = <&pinctrl0 0 16 16>;
+      adi,pint = <&pint0 0>;
+    };
+...

-- 
2.25.1

