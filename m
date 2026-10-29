From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Thu, 29 Oct 2026 18:12:30 +0800
Subject: [PATCH v5 1/2] dt-bindings: display: bridge: Add ITE IT6162 MIPI
 DSI to HDMI bridge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-upstream-6162-v5-1-8369f9e5afe6@ite.com.tw>
References: <20261029-upstream-6162-v5-0-8369f9e5afe6@ite.com.tw>
In-Reply-To: <20261029-upstream-6162-v5-0-8369f9e5afe6@ite.com.tw>
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Luca Ceresoli <luca.ceresoli@bootlin.com>
Cc: Pet.Weng@ite.com.tw, Kenneth.Hung@ite.com.tw, 
 Hermes Wu <Hermes.Wu@ite.com.tw>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793268764; l=6481;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=QF0B/yza7N4OwyzuyvztL9A4gDCKr/fyYHljCYyQq8k=;
 b=S/rF04RECIxFE+wTACSGSXgxYdCgEPQ4UjOGZ3pWSwAXZxjrBB3BHNO/lTUS0He0m7MWUFRSP
 JaovkY9DEUxD8QoMU352AKRE3V2k0j87TsbNRIG5onJW875db8l7vvt
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

Assisted-by: Claude Opus 5.5
Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 .../bindings/display/bridge/ite,it6162.yaml        | 205 +++++++++++++++++++++
 1 file changed, 205 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/bridge/ite,it6162.yaml b/Documentation/devicetree/bindings/display/bridge/ite,it6162.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..50a6e1e8a4c6a6b62f98b7755ca0c103df3a2960
--- /dev/null
+++ b/Documentation/devicetree/bindings/display/bridge/ite,it6162.yaml
@@ -0,0 +1,205 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/display/bridge/ite,it6162.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: ITE IT6162 MIPI DSI to HDMI 2.0 Bridge
+
+maintainers:
+  - Hermes Wu <Hermes.Wu@ite.com.tw>
+
+description: |
+  The ITE IT6162 is a high-performance, low-power HDMI bridge that converts
+  2 MIPI DSI signals to 1 HDMI 2.0 output. It supports dual MIPI D-PHY 2.0
+  links up to 10 Gbps each (20 Gbps total), compatible with DSI-2 v2.0.
+
+  The HDMI transmitter supports resolutions up to 4Kx2K@60Hz and is compliant
+  with HDMI 2.0 specifications.
+
+  For audio, it supports up to 8-channel LPCM via I2S (multi-line or TDM mode),
+  with optional S/PDIF or DSD (for SACD). Audio sampling rates up to 192 kHz
+  are supported.
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
+    description: Core voltage supply
+
+  ovdd-supply:
+    description: I/O voltage supply
+
+  ovdd1833-supply:
+    description: Flexible I/O voltage supply (1.8V domain)
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
+
+            properties:
+              data-lanes:
+                description: array of physical DSI data lane indexes.
+                oneOf:
+                  - minItems: 1
+                    items:
+                      - const: 1
+                      - const: 2
+                      - const: 3
+                      - const: 4
+                  - items:
+                      - const: 4
+                      - const: 3
+                      - const: 2
+                      - const: 1
+
+            required:
+              - data-lanes
+
+      port@1:
+        $ref: /schemas/graph.yaml#/$defs/port-base
+        unevaluatedProperties: false
+        description:
+          Input port for MIPI DSI-1, the preferred port for a single MIPI DSI
+          input.
+
+        properties:
+          endpoint:
+            $ref: /schemas/media/video-interfaces.yaml#
+            unevaluatedProperties: false
+
+            properties:
+              data-lanes:
+                description: array of physical DSI data lane indexes.
+                oneOf:
+                  - minItems: 1
+                    items:
+                      - const: 1
+                      - const: 2
+                      - const: 3
+                      - const: 4
+                  - items:
+                      - const: 4
+                      - const: 3
+                      - const: 2
+                      - const: 1
+
+            required:
+              - data-lanes
+
+      port@2:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Audio input port
+
+      port@3:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: HDMI output port
+
+    required:
+      - port@1
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - reset-gpios
+  - ivdd-supply
+  - ovdd-supply
+  - ovdd1833-supply
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
+
+            #sound-dai-cells = <0>;
+
+            interrupt-parent = <&pio>;
+            interrupts = <128 IRQ_TYPE_LEVEL_LOW>;
+
+            pinctrl-names = "default";
+            pinctrl-0 = <&it6162_pins>;
+
+            reset-gpios = <&pio 127 GPIO_ACTIVE_LOW>;
+
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
+
+                    it6162_dsi0: endpoint {
+                        data-lanes = <1 2 3 4>;
+                        remote-endpoint = <&dsi_0_out>;
+                    };
+                };
+
+                port@1 {
+                    reg = <1>;
+
+                    it6162_dsi1: endpoint {
+                        data-lanes = <1 2 3 4>;
+                        remote-endpoint = <&dsi_1_out>;
+                    };
+                };
+
+                port@2 {
+                    reg = <2>;
+
+                    it6162_audio_in: endpoint {
+                        remote-endpoint = <&i2s0_out>;
+                    };
+                };
+
+                port@3 {
+                    reg = <3>;
+
+                    it6162_hdmi_out: endpoint {
+                        remote-endpoint = <&hdmi_connector_in>;
+                    };
+                };
+            };
+        };
+    };

-- 
2.34.1

