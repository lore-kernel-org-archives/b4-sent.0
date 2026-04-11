From: Vasiliy Doylov <nekocwd@mainlining.org>
Date: Sat, 11 Apr 2026 16:13:08 +0300
Subject: [PATCH v5 1/3] media: dt-bindings: Add LC898217XC documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260411-media-i2c-lc898217xc-initial-driver-v5-1-c71ddcf40bad@mainlining.org>
References: <20260411-media-i2c-lc898217xc-initial-driver-v5-0-c71ddcf40bad@mainlining.org>
In-Reply-To: <20260411-media-i2c-lc898217xc-initial-driver-v5-0-c71ddcf40bad@mainlining.org>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, david@ixit.cz
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Vitalii Skorkin <nikroks@mainlining.org>, 
 Antonio Rische <nt8r@protonmail.com>, 
 Vasiliy Doylov <nekocwd@mainlining.org>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2204;
 i=nekocwd@mainlining.org; h=from:subject:message-id;
 bh=s4FrTZ3Fx26kAj8zMlKs4iZ3umFcszpWLs1SXRZOPZs=;
 b=owGbwMvMwCVmXFbadLHr1XTG02pJDJm3PF5wrD+dsuxJwrHOXN5pVp3vJ/WGifmICd7dc91/m
 kTSzKagjlIWBjEuBlkxRZbu94fvPZjHy1qq/okXZg4rE8gQBi5OAZjIRztGhicvMiVOs00WmPd+
 z/t+o6xTIhE2r569D5ObckAqdOkrYV6G/6mm2ydWs4jGWk08o7JiZ/vKU9KtP12fxAucdJ/Ju6m
 3nA0A
X-Developer-Key: i=nekocwd@mainlining.org; a=openpgp;
 fpr=8BEFC3DEE09E0D057527F20D33767582D18AEA97
X-Endpoint-Received: by B4 Relay for nekocwd@mainlining.org/default with auth_id=692
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree bindings documentation for ON Semiconductor
LC898217XC voice coil motor.

Signed-off-by: Vasiliy Doylov <nekocwd@mainlining.org>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
---
 .../bindings/media/i2c/onnn,lc898217xc.yaml        | 59 ++++++++++++++++++++++
 1 file changed, 59 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/i2c/onnn,lc898217xc.yaml b/Documentation/devicetree/bindings/media/i2c/onnn,lc898217xc.yaml
new file mode 100644
index 000000000000..3dd137d4c67c
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/i2c/onnn,lc898217xc.yaml
@@ -0,0 +1,59 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+# Copyright 2025 Vasiliy Doylov <nekocwd@mainlining.org>
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/i2c/onnn,lc898217xc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: ON Semiconductor LC898217XC Voice Coil Motor (VCM) Lens
+
+maintainers:
+  - Vasiliy Doylov <nekocwd@mainlining.org>
+
+description:
+  The LC898217XC is a 11-bit digital-to-analog (DAC) converter.
+  VCM current is controlled with a linear mode driver.The DAC is controlled
+  via a 2-wire (I2C-compatible) serial interface that operates at clock
+  rates up to 1MHz. This chip integrates Advanced Actuator Control (AAC)
+  technology and is intended for driving voice coil lenses in camera modules.
+
+properties:
+  compatible:
+    enum:
+      - onnn,lc898217xc
+
+  reg:
+    maxItems: 1
+
+  vana-supply:
+    description:
+      Definition of the regulator used as motor voltage supply.
+
+  vdd-supply:
+    description:
+      Definition of the regulator used as digital core voltage supply.
+
+required:
+  - compatible
+  - reg
+  - vana-supply
+  - vdd-supply
+
+additionalProperties: false
+
+examples:
+  - |
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        camera-lens@74 {
+            compatible = "onnn,lc898217xc";
+            reg = <0x74>;
+
+            vana-supply = <&mt6358_vaf_reg>;
+            vdd-supply = <&mt6358_vcamio_reg>;
+        };
+    };
+
+...

-- 
2.50.1

