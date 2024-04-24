From: Xilin Wu <wuxilin123@gmail.com>
Date: Wed, 24 Apr 2024 23:29:08 +0800
Subject: [PATCH 03/10] dt-bindings: display: panel: Add Synaptics TD4328
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240424-ayn-odin2-initial-v1-3-e0aa05c991fd@gmail.com>
References: <20240424-ayn-odin2-initial-v1-0-e0aa05c991fd@gmail.com>
In-Reply-To: <20240424-ayn-odin2-initial-v1-0-e0aa05c991fd@gmail.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Junhao Xie <bigfoot@classfun.cn>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, Sam Ravnborg <sam@ravnborg.org>, 
 David Airlie <airlied@gmail.com>, Daniel Vetter <daniel@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, 
 Tengfei Fan <quic_tengfan@quicinc.com>, 
 Molly Sophia <mollysophia379@gmail.com>, Junhao Xie <bigfoot@classfun.cn>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-arm-msm@vger.kernel.org, Xilin Wu <wuxilin123@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713972563; l=2025;
 i=wuxilin123@gmail.com; s=20240424; h=from:subject:message-id;
 bh=0VK+Kj9m0jq5c+1jyByVu388zTnbuAfKwi30ATqYDLI=;
 b=AweMBhEqEuTCc4enzY9h7GdeI8XUuiwF9MDWxLyD+4cgpmTUAoig7/9l8o0WgxW1VxR4gHORU
 cYNQ8NATvgzA6BG+EfLmVbx9tD6Qq3ybWio/Y940cWK+I6rFS9he+gk
X-Developer-Key: i=wuxilin123@gmail.com; a=ed25519;
 pk=vPnxeJnlD/PfEbyQPZzaay5ezxI/lMrke7qXy31lSM8=
X-Endpoint-Received: by B4 Relay for wuxilin123@gmail.com/20240424 with auth_id=157
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Synaptics TD4328 is a display driver IC used to drive LCD DSI panels.

Signed-off-by: Xilin Wu <wuxilin123@gmail.com>
---
 .../bindings/display/panel/synaptics,td4328.yaml   | 69 ++++++++++++++++++++++
 1 file changed, 69 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/panel/synaptics,td4328.yaml b/Documentation/devicetree/bindings/display/panel/synaptics,td4328.yaml
new file mode 100644
index 000000000000..216f2fb22b88
--- /dev/null
+++ b/Documentation/devicetree/bindings/display/panel/synaptics,td4328.yaml
@@ -0,0 +1,69 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/display/panel/synaptics,td4328.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Synaptics TD4328-based DSI display panels
+
+maintainers:
+  - Xilin Wu <wuxilin123@gmail.com>
+
+description:
+  The Synaptics TD4328 is a generic DSI Panel IC used to control
+  LCD panels.
+
+allOf:
+  - $ref: panel-common.yaml#
+
+properties:
+  compatible:
+    contains:
+      const: syna,td4328
+
+  vdd-supply:
+    description: Digital voltage rail
+
+  vddio-supply:
+    description: Digital I/O voltage rail
+
+  reg: true
+  port: true
+
+required:
+  - compatible
+  - reg
+  - reset-gpios
+  - vdd-supply
+  - vddio-supply
+  - port
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    dsi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        panel@0 {
+            compatible = "syna,td4328";
+            reg = <0>;
+
+            backlight = <&backlight>;
+            reset-gpios = <&tlmm 133 GPIO_ACTIVE_LOW>;
+
+            vdd-supply = <&vdd_lcm_2p8>;
+            vddio-supply = <&vreg_l12b_1p8>;
+
+            port {
+                panel_in_0: endpoint {
+                    remote-endpoint = <&dsi0_out>;
+                };
+            };
+        };
+    };
+
+...

-- 
2.44.0

