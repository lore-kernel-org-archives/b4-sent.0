From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 03 Sep 2024 15:00:45 +0800
Subject: [PATCH v2 1/3] dt-bindings: rtc: Add Amlogic A4 and A5 rtc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240903-rtc-v2-1-05da5755b8d9@amlogic.com>
References: <20240903-rtc-v2-0-05da5755b8d9@amlogic.com>
In-Reply-To: <20240903-rtc-v2-0-05da5755b8d9@amlogic.com>
To: Yiting Deng <yiting.deng@amlogic.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-rtc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725346845; l=2215;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=6EOnWaPKquIIloeXnJxYL8qcuh/homZJSOyDiv+sQAI=;
 b=c5sxbiBQLtdl3PtkTuITSGLV8md0Cj2hMnZUzjO5fG4hot1b0Q2H7lO+bTCW8iB88qbs3PoSN
 8YlvLQKBrwVDjIGNmtDLpj1/58DMflSjiLEcIUXb9cRXDGvHyXR9W6f
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Yiting Deng <yiting.deng@amlogic.com>

Add documentation describing the Amlogic A4(A113L2) and A5(A113X2)
rtc controller.

Signed-off-by: Yiting Deng <yiting.deng@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../bindings/rtc/amlogic,amlogic-rtc.yaml          | 66 ++++++++++++++++++++++
 1 file changed, 66 insertions(+)

diff --git a/Documentation/devicetree/bindings/rtc/amlogic,amlogic-rtc.yaml b/Documentation/devicetree/bindings/rtc/amlogic,amlogic-rtc.yaml
new file mode 100644
index 000000000000..128c60b623e1
--- /dev/null
+++ b/Documentation/devicetree/bindings/rtc/amlogic,amlogic-rtc.yaml
@@ -0,0 +1,66 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+# Copyright (C) 2024 Amlogic, Inc. All rights reserved
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/rtc/amlogic,amlogic-rtc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Amlogic Real Time Clock controller include a4, a5
+
+maintainers:
+  - Yiting Deng <yiting.deng@amlogic.com>
+  - Xianwei Zhao <xianwei.zhao@amlogic.com>
+
+description:
+  The Amlogic new chips used RTC module.
+
+allOf:
+  - $ref: rtc.yaml#
+
+properties:
+  compatible:
+    enum:
+      - amlogic,a4-rtc
+      - amlogic,a5-rtc
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    items:
+      - description: RTC clock source, available 24M or 32K crystal
+          oscillator source. when using 24M, need to divide 24M into 32K.
+      - description: RTC module accesses the clock of the apb bus.
+
+  clock-names:
+    items:
+      - const: osc
+      - const: sys
+
+  interrupts:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - clocks
+  - clock-names
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+    apb {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        rtc@8e600 {
+            compatible = "amlogic,a4-rtc";
+            reg = <0x0 0x8e600 0x0 0x38>;
+            interrupts = <GIC_SPI 131 IRQ_TYPE_EDGE_RISING>;
+            clocks = <&xtal_32k>, <&clkc_periphs 1>;
+            clock-names = "osc", "sys";
+        };
+    };

-- 
2.37.1

