From: Esteban Urrutia <esteuwu@proton.me>
Date: Tue, 11 Aug 2026 01:52:33 -0400
Subject: [PATCH 1/2] dt-bindings: display: panel: Add bindings for Novatek
 NT37703
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-nt37703-bup-v1-1-34ad42b064a3@proton.me>
References: <20260811-nt37703-bup-v1-0-34ad42b064a3@proton.me>
In-Reply-To: <20260811-nt37703-bup-v1-0-34ad42b064a3@proton.me>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786427559; l=2389;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=wVUFKmF2iBpqMPBKlh1CrckDAlUx+1CZ7rLZO14pU3o=;
 b=zDgmu5CjSC8v9Ywt8q27e1eyV15gl8TlNQUo7SIpUh/H++AOEjiAbFwAtsanUoFgC9Dgo7eF/
 LhFoc8AV6LnD2W6ej0bo7Lt1rx1opy3lzfKBgRfHeVcNA0+zfm7sWfV
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for this display driver IC which is used to drive MIPI DSI
panels.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 .../bindings/display/panel/novatek,nt37703.yaml    | 78 ++++++++++++++++++++++
 1 file changed, 78 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/panel/novatek,nt37703.yaml b/Documentation/devicetree/bindings/display/panel/novatek,nt37703.yaml
new file mode 100644
index 000000000000..e1aeed5b978e
--- /dev/null
+++ b/Documentation/devicetree/bindings/display/panel/novatek,nt37703.yaml
@@ -0,0 +1,78 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/display/panel/novatek,nt37703.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Novatek NT37703 display driver IC based panels
+
+maintainers:
+  - Esteban Urrutia <esteuwu@proton.me>
+
+properties:
+  compatible:
+    items:
+      - enum:
+          - motorola,bronco-tianma-v2-nt37703
+      - const: novatek,nt37703
+
+  reg:
+    maxItems: 1
+
+  avdd-supply:
+    description: Analog power supply for panel
+
+  elvdd-supply:
+    description: Positive electroluminiscent (EL) power supply for panel
+
+  elvss-supply:
+    description: Negative electroluminiscent (EL) power supply for panel
+
+  vci-supply:
+    description: Analog power supply for DDIC
+
+  vdd-supply:
+    description: Digital power supply for DDIC
+
+  vddi-supply:
+    description: Digital I/O power supply for DDIC
+
+  reset-gpios:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+  - reset-gpios
+
+allOf:
+  - $ref: panel-common.yaml#
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
+            compatible = "motorola,bronco-tianma-v2-nt37703", "novatek,nt37703";
+            reg = <0>;
+
+            vci-supply = <&vreg_l13c_3p0>;
+            vdd-supply = <&vreg_l1d_1p25>;
+            vddi-supply = <&vreg_l12c_1p8>;
+            reset-gpios = <&tlmm 0 GPIO_ACTIVE_LOW>;
+
+            port {
+                panel_in: endpoint {
+                        remote-endpoint = <&dsi0_out>;
+                };
+            };
+        };
+    };
+
+...

-- 
2.55.0

