From: Hrishabh Rajput <hrishabh.rajput@oss.qualcomm.com>
Date: Wed, 03 Sep 2025 19:33:59 +0000
Subject: [PATCH 1/2] dt-bindings: Add binding for gunyah watchdog
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250903-gunyah_watchdog-v1-1-3ae690530e4b@oss.qualcomm.com>
References: <20250903-gunyah_watchdog-v1-0-3ae690530e4b@oss.qualcomm.com>
In-Reply-To: <20250903-gunyah_watchdog-v1-0-3ae690530e4b@oss.qualcomm.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hrishabh Rajput <hrishabh.rajput@oss.qualcomm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756928065; l=3492;
 i=hrishabh.rajput@oss.qualcomm.com; s=20250903; h=from:subject:message-id;
 bh=12mv1xnCm68+mV1cO5nlkW0+E3MQXZbHMWHwIp/NcZc=;
 b=qkUoVFWdbjWAoQfKRxKiRBGxhdVw4DOqAVLkp0OdTPsi7asOUUgp2H6GBPAlISkEYQvIQLQPJ
 6ia4WubGpXuCD+oUMeXuoEarrwRppe27z3h0y+gtE01MxxGY/Wgvxo4
X-Developer-Key: i=hrishabh.rajput@oss.qualcomm.com; a=ed25519;
 pk=syafMitrjr3b/OYAtA2Im06AUb3fxZY2vJ/t4iCPmgw=
X-Endpoint-Received: by B4 Relay for hrishabh.rajput@oss.qualcomm.com/20250903 with auth_id=509
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Gunyah Hypervisor applies a devicetree overlay providing the
pretimeout interrupt for the Gunyah Watchdog that it will be using to
notify watchdog's pretimeout event. Add the DT bindings that Gunyah
adheres to for the hypervisor and watchdog.

Signed-off-by: Hrishabh Rajput <hrishabh.rajput@oss.qualcomm.com>
---
 .../bindings/watchdog/qcom,gh-watchdog.yaml        | 76 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 77 insertions(+)

diff --git a/Documentation/devicetree/bindings/watchdog/qcom,gh-watchdog.yaml b/Documentation/devicetree/bindings/watchdog/qcom,gh-watchdog.yaml
new file mode 100644
index 000000000000..bde8438c6242
--- /dev/null
+++ b/Documentation/devicetree/bindings/watchdog/qcom,gh-watchdog.yaml
@@ -0,0 +1,76 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/watchdog/qcom,gh-watchdog.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Qualcomm Gunyah Virtual Watchdog
+
+maintainers:
+  - Hrishabh Rajput <hrishabh.rajput@oss.qualcomm.com>
+
+description: |+
+  The Gunyah Hypervisor provides an SMC-based watchdog interface for its virtual
+  machines. The virtual machines use this information to determine the
+  pretimeout IRQ which the hypervisor will be using to communicate pretimeout
+  event.
+  See also: [1]
+
+  [1]: https://github.com/quic/gunyah-resource-manager/blob/1b23ceb0dfa010b3b6b5a5f7a4ec1e95b93ab99d/src/vm_creation/dto_construct.c#L519
+
+properties:
+  compatible:
+    allOf:
+      - const: gunyah-hypervisor
+      - const: simple-bus
+
+  "#address-cells":
+    description: Number of cells needed to represent 64-bit capability IDs.
+    const: 2
+
+  "#size-cells":
+    description: must be 0, because capability IDs are not memory address
+                  ranges and do not have a size.
+    const: 0
+
+patternProperties:
+  "^gh-watchdog":
+    type: object
+    description:
+      Watchdog node which provides information about the pretimeout IRQ which
+      will be used to communicate the pretimeout event.
+
+    properties:
+      compatible:
+        const: qcom,gh-watchdog
+
+      interrupts:
+        items:
+          description: Interrupt for the pretimeout.
+
+    additionalProperties: false
+
+    required:
+      - compatible
+      - interrupts
+
+additionalProperties: false
+
+required:
+  - compatible
+  - "#address-cells"
+  - "#size-cells"
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+
+    hypervisor {
+        compatible = "gunyah-hypervisor", "simple-bus";
+        #address-cells = <2>;
+        #size-cells = <0>;
+
+        gh-watchdog {
+            compatible = "qcom,gh-watchdog";
+            interrupts = <GIC_SPI 0 IRQ_TYPE_EDGE_RISING>; /* Pretimeout IRQ */
+        };
diff --git a/MAINTAINERS b/MAINTAINERS
index c0b444e5fd5a..03b74513e4ac 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -3076,6 +3076,7 @@ F:	Documentation/devicetree/bindings/cache/qcom,llcc.yaml
 F:	Documentation/devicetree/bindings/firmware/qcom,scm.yaml
 F:	Documentation/devicetree/bindings/reserved-memory/qcom*
 F:	Documentation/devicetree/bindings/soc/qcom/
+F:	Documentation/devicetree/bindings/watchdog/qcom,gh-watchdog.yaml
 F:	arch/arm/boot/dts/qcom/
 F:	arch/arm/configs/qcom_defconfig
 F:	arch/arm/mach-qcom/

-- 
2.43.0

