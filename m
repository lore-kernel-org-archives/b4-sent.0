From: Ben Zong-You Xie <ben717@andestech.com>
Date: Wed, 04 Feb 2026 19:30:41 +0800
Subject: [PATCH v4 1/3] dt-bindings: pwm: add support for AE350 PWM
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260204-andes-pwm-v4-1-67016bb13555@andestech.com>
References: <20260204-andes-pwm-v4-0-67016bb13555@andestech.com>
In-Reply-To: <20260204-andes-pwm-v4-0-67016bb13555@andestech.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ben Zong-You Xie <ben717@andestech.com>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770204641; l=2571;
 i=ben717@andestech.com; s=20260120; h=from:subject:message-id;
 bh=0bXlagODlL9Rn/hEL7/r3/Td8Wjq5W+Ods2FEtVZSXo=;
 b=ihvP0/54bNkepk8SWKpujW3hSXcb7C9ZTAkQFRKr54SXr1qrfkrJVAOG+KvNCh5PkmvUhckig
 h2pi6jRcFsdCsrZDfcs4m0ccoOQuVEuAGoAJvv7OknVw+Hrr9weDR5V
X-Developer-Key: i=ben717@andestech.com; a=ed25519;
 pk=nb8L7zQKGJpYk0yvrYKjViOZ34A36g1ZIsCmCsP518s=
X-Endpoint-Received: by B4 Relay for ben717@andestech.com/20260120 with auth_id=610
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ATCPIT100 is a set of compact multi-function timers, which can be
used as pulse width modulators (PWM) as well as simple timers.
ATCPIT100 supports up to 4 PIT channels, and each PIT channel may be
configured as a simple timer or PWM, or a combination of the timer and
the PWM. This IP block is a core component of the Andes AE350 platform,
which serves as a reference architecture for SoC designs. The QiLai SoC
also integrates this controller.

The binding introduces the following compatible strings:
- "andestech,qilai-pwm": For the implementation integrated into the
  Andes QiLai SoC.
- "andestech,ae350-pwm": As a fallback compatible string representing
  the base IP design used across the AE350 platform architecture.

Signed-off-by: Ben Zong-You Xie <ben717@andestech.com>
---
 .../bindings/pwm/andestech,ae350-pwm.yaml          | 61 ++++++++++++++++++++++
 1 file changed, 61 insertions(+)

diff --git a/Documentation/devicetree/bindings/pwm/andestech,ae350-pwm.yaml b/Documentation/devicetree/bindings/pwm/andestech,ae350-pwm.yaml
new file mode 100644
index 000000000000..287f3c62965f
--- /dev/null
+++ b/Documentation/devicetree/bindings/pwm/andestech,ae350-pwm.yaml
@@ -0,0 +1,61 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pwm/andestech,ae350-pwm.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Andes PWM controller on AE350 platform
+
+description:
+  This controller has 4 channels and two clock sources. Each channel can
+  switch the clock source by programming the corresponding register.
+
+maintainers:
+  - Ben Zong-You Xie <ben717@andestech.com>
+
+allOf:
+  - $ref: pwm.yaml#
+
+properties:
+  compatible:
+    oneOf:
+      - items:
+          - enum:
+              - andestech,qilai-pwm
+          - const: andestech,ae350-pwm
+      - const: andestech,ae350-pwm
+
+  reg:
+    maxItems: 1
+
+  "#pwm-cells":
+    const: 3
+
+  clocks:
+    items:
+      - description: APB bus clock
+      - description: External clock
+
+  clock-names:
+    items:
+      - const: pclk
+      - const: extclk
+
+required:
+  - compatible
+  - reg
+  - "#pwm-cells"
+  - clocks
+  - clock-names
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    pwm@f0400000 {
+        compatible = "andestech,ae350-pwm";
+        reg = <0xf0400000 0x100000>;
+        #pwm-cells = <3>;
+        clocks = <&pclk>, <&extclk>;
+        clock-names = "pclk", "extclk";
+    };

-- 
2.34.1

