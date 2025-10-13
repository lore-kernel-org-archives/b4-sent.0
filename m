From: Sven Peter <sven@kernel.org>
Date: Mon, 13 Oct 2025 16:03:25 +0000
Subject: [PATCH 1/5] dt-bindings: usb: Add Apple dwc3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251013-b4-aplpe-dwc3-v1-1-12a78000c014@kernel.org>
References: <20251013-b4-aplpe-dwc3-v1-0-12a78000c014@kernel.org>
In-Reply-To: <20251013-b4-aplpe-dwc3-v1-0-12a78000c014@kernel.org>
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sven Peter <sven@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3194; i=sven@kernel.org;
 h=from:subject:message-id; bh=z/OSrLCIdtmRJvitAMSoC1V/ZcKkiBQ7+CQlgJR3nQ4=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8Zbpccz9skv/7P7evUj9/3eN09drrF6fvLsnTceX5qnG
 M+asmPpy45SFgYxDgZZMUWW7fvtTZ88fCO4dNOl9zBzWJlAhjBwcQrARAy8Gf7Xai0MeXTJam+Z
 ieivNVYa5yYdPLF49uZJSt9POjYGGKyVZPjD0bVG/wLTh+Qd/q9ElDZP/NRx85Cq9jGjRMsis6U
 ZFZV8AA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apple Silicon uses Synopsys DesignWare dwc3 based USB controllers for
their Type-C ports.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 .../devicetree/bindings/usb/apple,dwc3.yaml        | 80 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 81 insertions(+)

diff --git a/Documentation/devicetree/bindings/usb/apple,dwc3.yaml b/Documentation/devicetree/bindings/usb/apple,dwc3.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..f70c33f32c5d6172224c524fe8e7218071eb4e9b
--- /dev/null
+++ b/Documentation/devicetree/bindings/usb/apple,dwc3.yaml
@@ -0,0 +1,80 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/usb/apple,dwc3.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Apple Silicon DWC3 USB controller
+
+maintainers:
+  - Sven Peter <sven@kernel.org>
+
+description:
+  Apple Silicon SoCs use a Synopsys DesignWare DWC3 based controller for each of
+  their Type-C ports.
+
+allOf:
+  - $ref: snps,dwc3-common.yaml#
+
+properties:
+  compatible:
+    oneOf:
+      - items:
+          - enum:
+              - apple,t6000-dwc3
+              - apple,t6020-dwc3
+              - apple,t8112-dwc3
+          - const: apple,t8103-dwc3
+      - const: apple,t8103-dwc3
+
+  reg:
+    items:
+      - description: Core DWC3 region
+      - description: Apple-specific DWC3 region
+
+  reg-names:
+    items:
+      - const: dwc3-core
+      - const: dwc3-apple
+
+  interrupts:
+    maxItems: 1
+
+  iommus:
+    maxItems: 2
+
+  resets:
+    maxItems: 1
+
+  power-domains:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+  - reg-names
+  - interrupts
+  - iommus
+  - resets
+  - power-domains
+  - usb-role-switch
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/apple-aic.h>
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    usb@82280000 {
+      compatible = "apple,t8103-dwc3";
+      reg = <0x82280000 0xcd00>, <0x8228cd00 0x3200>;
+      reg-names = "dwc3-core", "dwc3-apple";
+      interrupts = <AIC_IRQ 777 IRQ_TYPE_LEVEL_HIGH>;
+      iommus = <&dwc3_0_dart_0 0>, <&dwc3_0_dart_1 1>;
+
+      power-domains = <&ps_atc0_usb>;
+      resets = <&atcphy0>;
+
+      usb-role-switch;
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 46126ce2f968e4f9260263f1574ee29f5ff0de1c..fa238b5371b9c5942dc89ec4fa6b1d28e2d4dda3 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2437,6 +2437,7 @@ F:	Documentation/devicetree/bindings/power/reset/apple,smc-reboot.yaml
 F:	Documentation/devicetree/bindings/pwm/apple,s5l-fpwm.yaml
 F:	Documentation/devicetree/bindings/spi/apple,spi.yaml
 F:	Documentation/devicetree/bindings/spmi/apple,spmi.yaml
+F:	Documentation/devicetree/bindings/usb/apple,dwc3.yaml
 F:	Documentation/devicetree/bindings/watchdog/apple,wdt.yaml
 F:	arch/arm64/boot/dts/apple/
 F:	drivers/bluetooth/hci_bcm4377.c

-- 
2.34.1

