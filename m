From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Mon, 23 Feb 2026 17:20:46 +0800
Subject: [PATCH 2/3] dt-bindings: display: bridge: Add ITE IT6162 MIPI DSI
 to HDMI bridge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260223-upstream-6162-v1-2-ebcc66ccb1fe@ite.com.tw>
References: <20260223-upstream-6162-v1-0-ebcc66ccb1fe@ite.com.tw>
In-Reply-To: <20260223-upstream-6162-v1-0-ebcc66ccb1fe@ite.com.tw>
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Pet.Weng@ite.com.tw, Kenneth.Hung@ite.com.tw, 
 Hermes Wu <Hermes.Wu@ite.com.tw>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771838463; l=5183;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=RPki/TN57hKw8ecs2LV5OUWeAKQeKfXxTdHdAtzApJ4=;
 b=7IXPvkB5T7jqQQCrgwtKpK+vykkelp8Dik/v6Kk+cxfaParm2cgHbaReanvEYtvvuMEfYD+Rt
 UShJGWvi02wB40A0pSuhBjP25c/t/SA7gIel9WXrR33PMBlkI8BixcS
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree binding documentation for the ITE IT6162 MIPI DSI to
HDMI 2.0 bridge chip. The IT6162 is an I2C-controlled bridge that
supports the following configurations:

  - Single MIPI DSI input: up to 4K @ 30Hz
  - Dual MIPI DSI input (combined): up to 4K @ 60Hz

The chip also supports up to 8-channel audio output via 4 I2S data
channels.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 .../bindings/display/bridge/ite,it6162.yaml        | 156 +++++++++++++++++++++
 1 file changed, 156 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/bridge/ite,it6162.yaml b/Documentation/devicetree/bindings/display/bridge/ite,it6162.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..31f809a83c305447a152e14b20cb39ef1f816911
--- /dev/null
+++ b/Documentation/devicetree/bindings/display/bridge/ite,it6162.yaml
@@ -0,0 +1,156 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/display/bridge/ite,it6162.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: ITE IT6162 MIPI DSI to HDMI2.0 Bridge
+
+maintainers:
+  - Hermes Wu <Hermes.Wu@ite.com.tw>
+
+description: |
+  The ITE IT6162 is a high-performance, low-power HDMI bridge that converts
+  2 MIPI DSI signal to 1 HDMI2.0. It supports 2 MIPI D-PHY 2.0 up to 10Gbps
+  each DSI port (20Gbps total), compatible with DSI-2 v2.0.
+
+  The HDMI transmitter side supports up to 4Kx2K@60Hz resolutions, and is
+  compliant with HDMI2.0.
+
+  For audio, the IT61620 supports up to 8-channel LPCM via I2S (multi-line or
+  TDM mode), with optional S/PDIF or DSD (for SACD). It supports audio
+  sampling rates up to 192kHz.
+
+allOf:
+  - $ref: /schemas/sound/dai-common.yaml#
+
+properties:
+  compatible:
+    const: ite,it6162
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  reset-gpios:
+    maxItems: 1
+
+  ivdd-supply:
+    description: core voltage
+
+  ovdd-supply:
+    description: I/O voltage
+
+  ovdd1833-supply:
+    description: flexible I/O voltage
+
+  "#sound-dai-cells":
+    const: 0
+
+  ports:
+    $ref: /schemas/graph.yaml#/properties/ports
+
+    properties:
+      port@0:
+        $ref: /schemas/graph.yaml#/$defs/port-base
+        unevaluatedProperties: false
+        description: Input port for MIPI DSI-0
+
+        properties:
+          endpoint:
+            $ref: /schemas/media/video-interfaces.yaml#
+            unevaluatedProperties: false
+            required:
+              - data-lanes
+
+      port@1:
+        $ref: /schemas/graph.yaml#/$defs/port-base
+        unevaluatedProperties: false
+        description: Input port for MIPI DSI-1
+
+        properties:
+          endpoint:
+            $ref: /schemas/media/video-interfaces.yaml#
+            unevaluatedProperties: false
+            required:
+              - data-lanes
+
+      port@2:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Audio input port (I2S)
+
+      port@3:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Output port for HDMI output
+
+    required:
+      - port@1
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - ports
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        bridge@58 {
+            compatible = "ite,it6162";
+            reg = <0x58>;
+            #sound-dai-cells = <0>;
+            interrupt-parent = <&pio>;
+            interrupts = <128 IRQ_TYPE_LEVEL_LOW>;
+            pinctrl-names = "default";
+            pinctrl-0 = <&it6162_pins>;
+            reset-gpios = <&pio 127 GPIO_ACTIVE_LOW>;
+            ivdd-supply = <&pp1000_hdmi_x>;
+            ovdd-supply = <&pp3300_vio28_x>;
+            ovdd1833-supply = <&pp1800_vcamio_x>;
+
+            ports {
+                #address-cells = <1>;
+                #size-cells = <0>;
+
+                port@0 {
+                    reg = <0>;
+                    it6162_dsi0: endpoint {
+                        data-lanes = <0 1 2 3>;
+                        remote-endpoint = <&dsi_0_out>;
+                    };
+                };
+
+                port@1 {
+                    reg = <1>;
+                    it6162_dsi1: endpoint {
+                        data-lanes = <0 1 2 3>;
+                        remote-endpoint = <&dsi_1_out>;
+                    };
+                };
+
+                port@2 {
+                    reg = <2>;
+                    it6162_audio_in: endpoint {
+                        remote-endpoint = <&i2s0_out>;
+                    };
+                };
+
+                port@3 {
+                    reg = <3>;
+                    it6162_hdmi_out: endpoint {
+                        remote-endpoint = <&hdmi_connector_in>;
+                    };
+                };
+            };
+        };
+    };

-- 
2.34.1

