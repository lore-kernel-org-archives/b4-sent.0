From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Sun, 24 Nov 2024 23:29:24 +0100
Subject: [PATCH 1/5] dt-bindgins: display: Add Apple pre-DCP display
 controller bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241124-adpdrm-v1-1-3191d8e6e49a@gmail.com>
References: <20241124-adpdrm-v1-0-3191d8e6e49a@gmail.com>
In-Reply-To: <20241124-adpdrm-v1-0-3191d8e6e49a@gmail.com>
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, asahi@lists.linux.dev
Cc: linux-arm-kernel@lists.infradead.org, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732487379; l=2711;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=NTNIkjPdOTlJZEDvMknaGPG5ha7ey/9KeGDX3Cvd+fo=;
 b=aEiRFrdmA0I2NmORiFQ0n25DBwKAtSgEjQA1vtAY9JgY15BTKorcuza/Kpb5hFtDSET8waSkN
 UXv3sdP+1LFD5i79mgtG+qRN2dKShhJRlzP0wvWtLVqDSSNrku1HWx5
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for a secondary display controller present on certain
Apple laptops.

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 .../bindings/display/apple,display-pipe.yaml       | 59 ++++++++++++++++++++++
 .../bindings/display/panel/apple,summit.yaml       | 24 +++++++++
 2 files changed, 83 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/apple,display-pipe.yaml b/Documentation/devicetree/bindings/display/apple,display-pipe.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..bd25ddc6e09dd636c0221c854e594113f6011866
--- /dev/null
+++ b/Documentation/devicetree/bindings/display/apple,display-pipe.yaml
@@ -0,0 +1,59 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/display/apple,display-pipe.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Apple pre-DCP display controller.
+
+maintainers:
+  - asahi@lists.linux.dev
+  - Sasha Finkelstein <fnkl.kernel@gmail.com>
+
+description: |
+  A secondary display controller used to drive the "touchbar" on certain
+  Apple laptops.
+
+properties:
+  compatible:
+    items:
+      - enum:
+        - "apple,t8112-display-pipe"
+        - "apple,t8103-display-pipe"
+      - const: "apple,h7-display-pipe"
+
+  reg:
+    minItems: 3
+    maxItems: 3
+
+  reg-names:
+    items:
+      - const: be
+      - const: fe
+      - const: mipi
+
+  power-domains: true
+
+  interrupts:
+    minItems: 2
+    maxItems: 2
+
+  interrupt-names:
+    items:
+      - const: be
+      - const: fe
+
+  iommus: true
+
+  "#address-cells":
+    const: 1
+
+  "#size-cells":
+    const: 0
+
+additionalProperties: true
+
+required:
+  - compatible
+  - reg
+  - interrupts
diff --git a/Documentation/devicetree/bindings/display/panel/apple,summit.yaml b/Documentation/devicetree/bindings/display/panel/apple,summit.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..dc281c1f52c1ed07cc2f7f804dcfd2f3b4239d89
--- /dev/null
+++ b/Documentation/devicetree/bindings/display/panel/apple,summit.yaml
@@ -0,0 +1,24 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/display/panel/apple,summit.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Apple "Summit" display panel.
+
+maintainers:
+  - asahi@lists.linux.dev
+  - Sasha Finkelstein <fnkl.kernel@gmail.com>
+
+properties:
+  compatible:
+    const: apple,summit
+
+  reg:
+    maxItems: 1
+
+additionalProperties: false
+
+required:
+  - compatible
+  - reg

-- 
2.47.0

