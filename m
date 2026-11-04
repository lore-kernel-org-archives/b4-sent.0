From: Joseph Telaak <joseph@telaak.dev>
Date: Wed, 04 Nov 2026 02:21:52 -0500
Subject: [PATCH 1/2] dt-bindings: phy: Add Siflower SF19A2890 USB 2.0 PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-sf19a2890-usb-phy-v1-1-db0cad937614@telaak.dev>
References: <20261104-sf19a2890-usb-phy-v1-0-db0cad937614@telaak.dev>
In-Reply-To: <20261104-sf19a2890-usb-phy-v1-0-db0cad937614@telaak.dev>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: Chuanhong Guo <gch981213@gmail.com>, linux-mips@vger.kernel.org, 
 linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793776918; l=1906;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=L78MlUOk5gZfeSsbnMT/Q+d7GI1xujs8BnbBhuQJ4ak=;
 b=S0+qrfCc4jlcI0wF2PTmgXo3vKl2FLJ74NXUncXO4hPQN5uK0b3lEfp0yIN8I2GUR1VxfazEG
 hM7pafvztlZDtw85hEqat821BHMmMtIwsXdoIApjgwDO8UvQkw91GhT
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The USB 2.0 PHY of the Siflower SF19A2890 serves its DWC2 controller.
It takes a reference clock and two resets, power-on and PHY, from the
USB block's clock and reset manager.

Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 .../bindings/phy/siflower,sf19a2890-usb-phy.yaml   | 58 ++++++++++++++++++++++
 1 file changed, 58 insertions(+)

diff --git a/Documentation/devicetree/bindings/phy/siflower,sf19a2890-usb-phy.yaml b/Documentation/devicetree/bindings/phy/siflower,sf19a2890-usb-phy.yaml
new file mode 100644
index 000000000..77b8e35d8
--- /dev/null
+++ b/Documentation/devicetree/bindings/phy/siflower,sf19a2890-usb-phy.yaml
@@ -0,0 +1,58 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/phy/siflower,sf19a2890-usb-phy.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Siflower SF19A2890 USB 2.0 PHY
+
+maintainers:
+  - Joseph Telaak <joseph@telaak.dev>
+
+description:
+  The USB 2.0 PHY of the Siflower SF19A2890, used by its DWC2 controller.
+
+properties:
+  compatible:
+    const: siflower,sf19a2890-usb-phy
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    maxItems: 1
+    description: PHY reference clock
+
+  resets:
+    items:
+      - description: power-on reset
+      - description: PHY reset
+
+  reset-names:
+    items:
+      - const: por
+      - const: phy
+
+  "#phy-cells":
+    const: 0
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - resets
+  - reset-names
+  - "#phy-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    usb-phy@19e0c040 {
+        compatible = "siflower,sf19a2890-usb-phy";
+        reg = <0x19e0c040 0x60>;
+        clocks = <&usb_crm 2>;
+        resets = <&usb_crm 1>, <&usb_crm 2>;
+        reset-names = "por", "phy";
+        #phy-cells = <0>;
+    };

-- 
Git-155)

