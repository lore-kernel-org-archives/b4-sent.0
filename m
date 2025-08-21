From: Sven Peter <sven@kernel.org>
Date: Thu, 21 Aug 2025 15:38:54 +0000
Subject: [PATCH RFC 02/22] dt-bindings: usb: Add Apple dwc3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250821-atcphy-6-17-v1-2-172beda182b8@kernel.org>
References: <20250821-atcphy-6-17-v1-0-172beda182b8@kernel.org>
In-Reply-To: <20250821-atcphy-6-17-v1-0-172beda182b8@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Felipe Balbi <balbi@kernel.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3081; i=sven@kernel.org;
 h=from:subject:message-id; bh=KhK3tFPXEaW8oRX7V89m4hRJe9gH2p2NAg0H4Auc1J0=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8Zy2wXG8elX/z7wf6pRNDWlUGz1Lavf3wXntPbXsL/Jt
 qvav1y3o5SFQYyDQVZMkWX7fnvTJw/fCC7ddOk9zBxWJpAhDFycAjCRBYUM/xMniTx1iDprul9L
 btaFe48znky+dG2yUJPMcmsRV2mLFUUM/+sbU98riQeZlR2oeVjyYaLWA86evHlV///c7r+50lZ
 BjAkA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apple Silicon uses Synopsys DesignWare dwc3 based USB controllers for
their Type-C ports.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 .../devicetree/bindings/usb/apple,dwc3.yaml        | 82 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 83 insertions(+)

diff --git a/Documentation/devicetree/bindings/usb/apple,dwc3.yaml b/Documentation/devicetree/bindings/usb/apple,dwc3.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..dfea726a6c053ad0c8f3d973a95b45bbf1724234
--- /dev/null
+++ b/Documentation/devicetree/bindings/usb/apple,dwc3.yaml
@@ -0,0 +1,82 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/usb/apple,dwc3.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Apple Silicon DWC3 USB controller
+
+maintainers:
+  - Sven Peter <sven@svenpeter.dev>
+
+description:
+  Apple Silicon SoCs use a Synopsys DesignWare DWC3 based controller for each of
+  their Type-C ports.
+
+  The common content of the node is defined in snps,dwc3.yaml.
+
+allOf:
+  - $ref: snps,dwc3.yaml#
+
+select:
+  properties:
+    compatible:
+      contains:
+        const: apple,t8103-dwc3
+  required:
+    - compatible
+
+properties:
+  compatible:
+    oneOf:
+      - items:
+        - enum:
+            - apple,t6000-dwc3
+            - apple,t6020-dwc3
+            - apple,t8112-dwc3
+        - const: apple,t8103-dwc3
+        - const: snps,dwc3
+      - items:
+        - const: apple,t8103-dwc3
+        - const: snps,dwc3
+
+  reg:
+    maxItems: 1
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
+unevaluatedProperties: false
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - iommus
+  - resets
+  - power-domains
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/apple-aic.h>
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    usb@82280000 {
+      compatible = "apple,t8103-dwc3", "snps,dwc3";
+      reg = <0x82280000 0x10000>;
+      interrupts = <AIC_IRQ 777 IRQ_TYPE_LEVEL_HIGH>;
+      iommus = <&dwc3_0_dart_0 0>, <&dwc3_0_dart_1 1>;
+
+      dr_mode = "otg";
+      usb-role-switch;
+      role-switch-default-mode = "host";
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index fe168477caa45799dfe07de2f54de6d6a1ce0615..0e085cb0762f765958d67be61ae0d3d773503431 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2399,6 +2399,7 @@ F:	Documentation/devicetree/bindings/power/reset/apple,smc-reboot.yaml
 F:	Documentation/devicetree/bindings/pwm/apple,s5l-fpwm.yaml
 F:	Documentation/devicetree/bindings/spi/apple,spi.yaml
 F:	Documentation/devicetree/bindings/spmi/apple,spmi.yaml
+F:	Documentation/devicetree/bindings/usb/apple,dwc3.yaml
 F:	Documentation/devicetree/bindings/watchdog/apple,wdt.yaml
 F:	arch/arm64/boot/dts/apple/
 F:	drivers/bluetooth/hci_bcm4377.c

-- 
2.34.1

