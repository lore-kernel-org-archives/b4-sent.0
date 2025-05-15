From: Sven Peter <sven@svenpeter.dev>
Date: Thu, 15 May 2025 06:21:15 +0000
Subject: [PATCH v6 03/10] dt-bindings: mfd: Add Apple Mac System Management
 Controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250515-smc-6-15-v6-3-c47b1ef4b0ae@svenpeter.dev>
References: <20250515-smc-6-15-v6-0-c47b1ef4b0ae@svenpeter.dev>
In-Reply-To: <20250515-smc-6-15-v6-0-c47b1ef4b0ae@svenpeter.dev>
To: Sven Peter <sven@svenpeter.dev>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Neal Gompa <neal@gompa.dev>, 
 Hector Martin <marcan@marcan.st>, Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sebastian Reichel <sre@kernel.org>, 
 Lee Jones <lee@kernel.org>, Marc Zyngier <maz@kernel.org>, 
 "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3518; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=24GvFN6ibXD4G73jz0oF1G3/fyuiC8WVouHqMv8StLw=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4ZqB9fBZ2K12x/ufr+hQvX0tV3KPwXPvvxe+DexTnOPx
 ZEbS6N+dZSyMIhxMMiKKbJs329v+uThG8Glmy69h5nDygQyhIGLUwAmcusoI8PzBWcnPbpvrOZg
 sbQ06MOZY/W/j+UWMR5SqCt8Y72t+2I3w38nTdHf0+PLAt6uXb0o8rVEwH72ypx1Okbv2peYyNW
 ls7ACAA==
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>

Add a DT binding for the Apple Mac System Management Controller.

Signed-off-by: Russell King (Oracle) <rmk+kernel@armlinux.org.uk>
Reviewed-by: Linus Walleij <linus.walleij@linaro.org>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Reviewed-by: Alyssa Rosenzweig <alyssa@rosenzweig.io>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 .../devicetree/bindings/mfd/apple,smc.yaml         | 79 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 80 insertions(+)

diff --git a/Documentation/devicetree/bindings/mfd/apple,smc.yaml b/Documentation/devicetree/bindings/mfd/apple,smc.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..1937fb3d2578dcf69991e83095e3e1e29958ef37
--- /dev/null
+++ b/Documentation/devicetree/bindings/mfd/apple,smc.yaml
@@ -0,0 +1,79 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/mfd/apple,smc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Apple Mac System Management Controller
+
+maintainers:
+  - Sven Peter <sven@svenpeter.dev>
+
+description:
+  Apple Mac System Management Controller implements various functions
+  such as GPIO, RTC, power, reboot.
+
+properties:
+  compatible:
+    items:
+      - enum:
+          - apple,t6000-smc
+          - apple,t8103-smc
+          - apple,t8112-smc
+      - const: apple,smc
+
+  reg:
+    items:
+      - description: SMC area
+      - description: SRAM area
+
+  reg-names:
+    items:
+      - const: smc
+      - const: sram
+
+  mboxes:
+    maxItems: 1
+
+  gpio:
+    $ref: /schemas/gpio/apple,smc-gpio.yaml
+
+  reboot:
+    $ref: /schemas/power/reset/apple,smc-reboot.yaml
+
+additionalProperties: false
+
+required:
+  - compatible
+  - reg
+  - reg-names
+  - mboxes
+
+examples:
+  - |
+    soc {
+      #address-cells = <2>;
+      #size-cells = <2>;
+
+      smc@23e400000 {
+        compatible = "apple,t8103-smc", "apple,smc";
+        reg = <0x2 0x3e400000 0x0 0x4000>,
+               <0x2 0x3fe00000 0x0 0x100000>;
+        reg-names = "smc", "sram";
+        mboxes = <&smc_mbox>;
+
+        smc_gpio: gpio {
+          compatible = "apple,smc-gpio";
+          gpio-controller;
+          #gpio-cells = <2>;
+        };
+
+        reboot {
+          compatible = "apple,smc-reboot";
+          nvmem-cells = <&shutdown_flag>, <&boot_stage>,
+                        <&boot_error_count>, <&panic_count>;
+          nvmem-cell-names = "shutdown_flag", "boot_stage",
+                             "boot_error_count", "panic_count";
+        };
+      };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 3f32d028ab49994a0da9f3882f37b9c3b183f5b4..27caedc40262ee9b9fdb6478f7624422517375a7 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2275,6 +2275,7 @@ F:	Documentation/devicetree/bindings/iommu/apple,dart.yaml
 F:	Documentation/devicetree/bindings/iommu/apple,sart.yaml
 F:	Documentation/devicetree/bindings/leds/backlight/apple,dwi-bl.yaml
 F:	Documentation/devicetree/bindings/mailbox/apple,mailbox.yaml
+F:	Documentation/devicetree/bindings/mfd/apple,smc.yaml
 F:	Documentation/devicetree/bindings/net/bluetooth/brcm,bcm4377-bluetooth.yaml
 F:	Documentation/devicetree/bindings/nvme/apple,nvme-ans.yaml
 F:	Documentation/devicetree/bindings/nvmem/apple,efuses.yaml

-- 
2.34.1

