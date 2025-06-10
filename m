From: Sven Peter <sven@kernel.org>
Date: Tue, 10 Jun 2025 15:29:44 +0000
Subject: [PATCH v7 03/10] dt-bindings: mfd: Add Apple Mac System Management
 Controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250610-smc-6-15-v7-3-556cafd771d3@kernel.org>
References: <20250610-smc-6-15-v7-0-556cafd771d3@kernel.org>
In-Reply-To: <20250610-smc-6-15-v7-0-556cafd771d3@kernel.org>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3512; i=sven@kernel.org;
 h=from:subject:message-id; bh=MBhTLFSa+MA8vJScnTlr0fsDm4OGdrB/SyplsXOEjuQ=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4aHf3FjV13HK+arrw96pNce/r7x/cGsvjkNtx8+Uhadv
 C//ftfSjlIWBjEOBlkxRZbt++1Nnzx8I7h006X3MHNYmUCGMHBxCsBE7B4x/Pdgd2xU5+ll2ytw
 bi6L02P2DtejZy2WvgieKndy2jo77i2MDCe+LGPj3LOmoH0e//eDD1Qni87zyQ3JSo83eaFZXnW
 5kBEA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>

Add a DT binding for the Apple Mac System Management Controller.

Signed-off-by: Russell King (Oracle) <rmk+kernel@armlinux.org.uk>
Reviewed-by: Linus Walleij <linus.walleij@linaro.org>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Reviewed-by: Alyssa Rosenzweig <alyssa@rosenzweig.io>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 .../devicetree/bindings/mfd/apple,smc.yaml         | 79 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 80 insertions(+)

diff --git a/Documentation/devicetree/bindings/mfd/apple,smc.yaml b/Documentation/devicetree/bindings/mfd/apple,smc.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..8a10e270d421ecd703848f64af597de351fcfd74
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
+  - Sven Peter <sven@kernel.org>
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
index 1dd004f7dff669e3a3609e5f1702887129d8ff35..329b2df08d4b1039948e54353c5815e23ae65e77 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2339,6 +2339,7 @@ F:	Documentation/devicetree/bindings/iommu/apple,dart.yaml
 F:	Documentation/devicetree/bindings/iommu/apple,sart.yaml
 F:	Documentation/devicetree/bindings/leds/backlight/apple,dwi-bl.yaml
 F:	Documentation/devicetree/bindings/mailbox/apple,mailbox.yaml
+F:	Documentation/devicetree/bindings/mfd/apple,smc.yaml
 F:	Documentation/devicetree/bindings/net/bluetooth/brcm,bcm4377-bluetooth.yaml
 F:	Documentation/devicetree/bindings/nvme/apple,nvme-ans.yaml
 F:	Documentation/devicetree/bindings/nvmem/apple,efuses.yaml

-- 
2.34.1

