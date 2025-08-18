From: Michael Riesch <michael.riesch@collabora.com>
Date: Tue, 19 Aug 2025 01:00:37 +0200
Subject: [PATCH v2 3/7] dt-bindings: phy: rockchip-inno-csi-dphy: add
 rk3588 variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250616-rk3588-csi-dphy-v2-3-7a94f079b712@collabora.com>
References: <20250616-rk3588-csi-dphy-v2-0-7a94f079b712@collabora.com>
In-Reply-To: <20250616-rk3588-csi-dphy-v2-0-7a94f079b712@collabora.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Vinod Koul <vkoul@kernel.org>, Kishon Vijay Abraham I <kishon@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Jagan Teki <jagan@amarulasolutions.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Diederik de Haas <didi.debian@cknow.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Heiko Stuebner <heiko@sntech.de>, 
 Collabora Kernel Team <kernel@collabora.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-phy@lists.infradead.org, 
 Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755558041; l=2827;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=PMDzlrQeY+NRmFqopM/ChR6/5pYbe3wSrubFJu+0sMU=;
 b=AEtLzU240l3giMFwyKl21EH9Gejgiu6qeYmvs3lvFhzWFKQ1tm7t0mCqCxz29QeDKQCU7vmKM
 w70rtAqj0rKAfrDEtilu6hzdb8YHSeHoMX79gE1BCU3lqkrWLYpYDVC
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Rockchip RK3588 variant of the CSI-2 DPHY features two reset lines.
Add the variant and allow for the additional reset.

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 .../bindings/phy/rockchip-inno-csi-dphy.yaml       | 60 ++++++++++++++++++++--
 1 file changed, 56 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/phy/rockchip-inno-csi-dphy.yaml b/Documentation/devicetree/bindings/phy/rockchip-inno-csi-dphy.yaml
index 42da616ae2e3..10197cc9dc47 100644
--- a/Documentation/devicetree/bindings/phy/rockchip-inno-csi-dphy.yaml
+++ b/Documentation/devicetree/bindings/phy/rockchip-inno-csi-dphy.yaml
@@ -21,6 +21,7 @@ properties:
       - rockchip,rk3326-csi-dphy
       - rockchip,rk3368-csi-dphy
       - rockchip,rk3568-csi-dphy
+      - rockchip,rk3588-csi-dphy
 
   reg:
     maxItems: 1
@@ -39,18 +40,50 @@ properties:
     maxItems: 1
 
   resets:
-    items:
-      - description: exclusive PHY reset line
+    minItems: 1
+    maxItems: 2
 
   reset-names:
-    items:
-      - const: apb
+    minItems: 1
+    maxItems: 2
 
   rockchip,grf:
     $ref: /schemas/types.yaml#/definitions/phandle
     description:
       Some additional phy settings are access through GRF regs.
 
+allOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - rockchip,px30-csi-dphy
+              - rockchip,rk1808-csi-dphy
+              - rockchip,rk3326-csi-dphy
+              - rockchip,rk3368-csi-dphy
+              - rockchip,rk3568-csi-dphy
+    then:
+      properties:
+        resets:
+          items:
+            - description: exclusive PHY reset line
+
+        reset-names:
+          items:
+            - const: apb
+    else:
+      properties:
+        resets:
+          items:
+            - description: APB reset line
+            - description: PHY reset line
+
+        reset-names:
+          items:
+            - const: apb
+            - const: phy
+
 required:
   - compatible
   - reg
@@ -77,3 +110,22 @@ examples:
         reset-names = "apb";
         rockchip,grf = <&grf>;
     };
+  - |
+    #include <dt-bindings/clock/rockchip,rk3588-cru.h>
+    #include <dt-bindings/reset/rockchip,rk3588-cru.h>
+
+    soc {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        phy@fedc0000 {
+            compatible = "rockchip,rk3588-csi-dphy";
+            reg = <0x0 0xfedc0000 0x0 0x8000>;
+            clocks = <&cru PCLK_CSIPHY0>;
+            clock-names = "pclk";
+            #phy-cells = <0>;
+            resets = <&cru SRST_P_CSIPHY0>, <&cru SRST_CSIPHY0>;
+            reset-names = "apb", "phy";
+            rockchip,grf = <&csidphy0_grf>;
+        };
+    };

-- 
2.39.5

