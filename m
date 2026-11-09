From: Gaurav Suman <gauravsuman007@gmail.com>
Date: Mon, 09 Nov 2026 22:38:25 +0000
Subject: [PATCH 7/8] dt-bindings: media: i2c: Add ON Semiconductor
 LC898123F40
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-sm8150-camera-v1-7-3d2e7b407516@gmail.com>
References: <20261109-sm8150-camera-v1-0-3d2e7b407516@gmail.com>
In-Reply-To: <20261109-sm8150-camera-v1-0-3d2e7b407516@gmail.com>
To: Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Gaurav Suman <gauravsuman007@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-arm-msm@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794263921; l=2002;
 i=gauravsuman007@gmail.com; s=default; h=from:subject:message-id;
 bh=rigIVBWMlVSOi77vfy3OEmUXyFuzk+Zl0xoBupe283Y=;
 b=AcNLWQdV2Cmi4kv8K7vud0KowSrdcDTaYl35bDVKPaCgiM9C1Poe50W+E7i+Ho17AfHNdAOlo
 V3ypeD68riEAQxRTMNIEl+uePxteBWXook54qLua9zf4P08X7oqK1c5
X-Developer-Key: i=gauravsuman007@gmail.com; a=ed25519;
 pk=lnUC0mQfc0KyA0LE73pQ4+QWYVRaCD8Sd3XWxLZO+JY=
X-Endpoint-Received: by B4 Relay for gauravsuman007@gmail.com/default with auth_id=1467
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for the LC898123F40 optical image stabilisation and
autofocus controller, used in the main camera module of the LG G8x
ThinQ.

This was written and tested with the help of an AI coding assistant
(Claude Opus 5.5, Anthropic); I reviewed the change and the results.

Signed-off-by: Gaurav Suman <gauravsuman007@gmail.com>
---
 .../bindings/media/i2c/onnn,lc898123f40.yaml       | 46 ++++++++++++++++++++++
 1 file changed, 46 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/i2c/onnn,lc898123f40.yaml b/Documentation/devicetree/bindings/media/i2c/onnn,lc898123f40.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..ac0ab6a8793547a5a3617b75bcc590a1e01af602
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/i2c/onnn,lc898123f40.yaml
@@ -0,0 +1,46 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/i2c/onnn,lc898123f40.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: ON Semiconductor LC898123F40 OIS and autofocus controller
+
+maintainers:
+  - Gaurav Suman <gauravsuman007@gmail.com>
+
+description:
+  The LC898123F40 is an optical image stabilisation and autofocus
+  controller with built-in flash memory for its firmware, controlled over
+  I2C. It drives the voice coil motors of a camera module. Only the
+  autofocus (lens position) function is described here.
+
+properties:
+  compatible:
+    const: onnn,lc898123f40
+
+  reg:
+    maxItems: 1
+
+  vdd-supply:
+    description: Supply for the controller and the voice coil motors.
+
+required:
+  - compatible
+  - reg
+
+additionalProperties: false
+
+examples:
+  - |
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        camera-lens@3e {
+            compatible = "onnn,lc898123f40";
+            reg = <0x3e>;
+            vdd-supply = <&vreg_2p8>;
+        };
+    };
+...

-- 
2.49.1

