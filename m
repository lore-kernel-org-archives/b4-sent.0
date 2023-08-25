From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Fri, 25 Aug 2023 11:43:25 +0300
Subject: [PATCH v2 1/2] dt-bindings: rtc: Add ST M48T86
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230823-m48t86_device_tree-v2-1-21ff275f949d@maquefel.me>
References: <20230823-m48t86_device_tree-v2-0-21ff275f949d@maquefel.me>
In-Reply-To: <20230823-m48t86_device_tree-v2-0-21ff275f949d@maquefel.me>
To: Alessandro Zummo <a.zummo@towertech.it>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nikita Shubin <nikita.shubin@maquefel.me>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1692953023; l=1415;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=MnFLUVNbKTyfZ50U0UaB3bgdv9grXe+OsjVQV5/9QnA=;
 b=LVnK3jIdYHtYhQ3q83ARey1BgIv2Hx+r3atUv8MPpTSm8UfB/QWN+DKaalJjZLk4kAUWxvNk6uJq
 sQOt5Nr3BYuZXkJKNVQQFlKwAaeGH12su8puRDMKqPxfQOvaJM2n
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add YAML bindings for ST M48T86 / Dallas DS12887 RTC.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Link: https://lore.kernel.org/lkml/61b9e036-7864-65c6-d43b-463fff896ddc@linaro.org/
Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 .../devicetree/bindings/rtc/st,m48t86.yaml         | 38 ++++++++++++++++++++++
 1 file changed, 38 insertions(+)

diff --git a/Documentation/devicetree/bindings/rtc/st,m48t86.yaml b/Documentation/devicetree/bindings/rtc/st,m48t86.yaml
new file mode 100644
index 000000000000..e3e12fa23380
--- /dev/null
+++ b/Documentation/devicetree/bindings/rtc/st,m48t86.yaml
@@ -0,0 +1,38 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/rtc/st,m48t86.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: ST M48T86 / Dallas DS12887 RTC with SRAM
+
+maintainers:
+  - Alexandre Belloni <alexandre.belloni@bootlin.com>
+
+allOf:
+  - $ref: rtc.yaml
+
+properties:
+  compatible:
+    enum:
+      - st,m48t86
+
+  reg:
+    items:
+      - description: index register
+      - description: data register
+
+required:
+  - compatible
+  - reg
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    rtc@10800000 {
+      compatible = "st,m48t86";
+      reg = <0x10800000 0x1>, <0x11700000 0x1>;
+    };
+
+...

-- 
2.39.2

