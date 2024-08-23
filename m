From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 23 Aug 2024 17:19:44 +0800
Subject: [PATCH 1/3] dt-bindings: rtc: Add Amlogic A311L2 and A113X2 rtc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240823-rtc-v1-1-6f70381da283@amlogic.com>
References: <20240823-rtc-v1-0-6f70381da283@amlogic.com>
In-Reply-To: <20240823-rtc-v1-0-6f70381da283@amlogic.com>
To: Yiting Deng <yiting.deng@amlogic.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-rtc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724404784; l=2235;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=OuCbmduzBkZkzatxp6faWcdgmpE7uNtqHqmhQseAr7Q=;
 b=dISvZXk6kBMEY4QicOnnOG4EnavSgL5tgiaHxWNMtJlC1IK0M9ZC0Mk+6UrV4a7/RyGGtpizi
 z4qtwKvsNUkAOFXsKzzFCrFp6FYHRWi5RFa1J56cuPfkpYnyDwPdSfZ
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Yiting Deng <yiting.deng@amlogic.com>

Add documentation describing the Amlogic A113L2 and A113X2 rtc controller.

Signed-off-by: Yiting Deng <yiting.deng@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../bindings/rtc/amlogic,amlogic-rtc.yaml          | 66 ++++++++++++++++++++++
 1 file changed, 66 insertions(+)

diff --git a/Documentation/devicetree/bindings/rtc/amlogic,amlogic-rtc.yaml b/Documentation/devicetree/bindings/rtc/amlogic,amlogic-rtc.yaml
new file mode 100644
index 000000000000..fa3d7838022e
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
+      - const: rtc_osc
+      - const: rtc_sys_clk
+
+  interrupts:
+    maxItems: 1
+
+required:
+  - compatible
+  - interrupts
+  - reg
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
+        rtc: rtc@8e600 {
+            compatible = "amlogic,a4-rtc";
+            interrupts = <GIC_SPI 131 IRQ_TYPE_EDGE_RISING>;
+            reg = <0x0 0x8e600 0x0 0x38>;
+            clocks = <&xtal_32k>, <&clkc_periphs 1>;
+            clock-names = "rtc_osc", "rtc_sys_clk";
+        };
+    };

-- 
2.37.1

