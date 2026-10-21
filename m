From: Cunhao Lu <1579567540@qq.com>
Date: Thu, 22 Oct 2026 00:11:17 +0800
Subject: [PATCH 20/27] dt-bindings: usb: rockchip: Add RK3572 DWC3
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-add-board-ok3572-c-v1-20-0b0fd85a31ee@qq.com>
References: <20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com>
In-Reply-To: <20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com>
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Elaine Zhang <zhangqing@rock-chips.com>, Lee Jones <lee@kernel.org>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Richard Cochran <richardcochran@gmail.com>, Ulf Hansson <ulfh@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Jisheng Zhang <jszhang@kernel.org>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 David Wu <david.wu@rock-chips.com>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, 
 Shawn Lin <shawn.lin@rock-chips.com>
Cc: Cunhao Lu <1579567540@qq.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 mfd@lists.linux.dev, linux-gpio@vger.kernel.org, netdev@vger.kernel.org, 
 linux-pm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-serial@vger.kernel.org, linux-mmc@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, linux-phy@lists.infradead.org, 
 linux-usb@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792599138; l=2999;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=iT5BkLeeMmmjRIQeuSIycaI/UXplV+prYKUmY7Ulxps=;
 b=v53jOqW6R2n7fnmg8g19Yw7h4T0AjT02bVfEk5sahYgQzXvZmOvgxh+pYAmDqwo1QrriCFURL
 PtaQ5zJEYipCdDZabXmFfxXkC5DXvBCRrr4RHaHwP9Kab8NEfd0cZhV
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the PHP GRF register used to configure the DWC3 PIPE port before
controller discovery.

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
 .../bindings/usb/rockchip,rk3572-dwc3.yaml         | 100 +++++++++++++++++++++
 1 file changed, 100 insertions(+)

diff --git a/Documentation/devicetree/bindings/usb/rockchip,rk3572-dwc3.yaml b/Documentation/devicetree/bindings/usb/rockchip,rk3572-dwc3.yaml
new file mode 100644
index 000000000000..47ff5e16dce6
--- /dev/null
+++ b/Documentation/devicetree/bindings/usb/rockchip,rk3572-dwc3.yaml
@@ -0,0 +1,100 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/usb/rockchip,rk3572-dwc3.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Rockchip RK3572 DWC3 USB controller
+
+maintainers:
+  - Heiko Stuebner <heiko@sntech.de>
+  - Cunhao Lu <1579567540@qq.com>
+
+allOf:
+  - $ref: snps,dwc3-common.yaml#
+
+properties:
+  compatible:
+    const: rockchip,rk3572-dwc3
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  dma-coherent: true
+
+  clocks:
+    minItems: 3
+    maxItems: 3
+
+  clock-names:
+    items:
+      - const: ref_clk
+      - const: suspend_clk
+      - const: bus_clk
+
+  phys:
+    minItems: 1
+    items:
+      - description: USB2 PHY
+      - description: USB3 PHY
+
+  phy-names:
+    minItems: 1
+    items:
+      - const: usb2-phy
+      - const: usb3-phy
+
+  power-domains:
+    maxItems: 1
+
+  resets:
+    maxItems: 1
+
+  rockchip,grf:
+    $ref: /schemas/types.yaml#/definitions/phandle-array
+    description:
+      PHP GRF and the controller's PIPE configuration register offset.
+    items:
+      - items:
+          - description: PHP GRF phandle
+          - enum: [0x14, 0x34]
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - clocks
+  - clock-names
+  - phys
+  - phy-names
+  - power-domains
+  - resets
+  - rockchip,grf
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/clock/rockchip,rk3572-cru.h>
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+    #include <dt-bindings/phy/phy.h>
+    #include <dt-bindings/power/rockchip,rk3572-power-controller.h>
+    #include <dt-bindings/reset/rockchip,rk3572-cru.h>
+
+    usb@24400000 {
+        compatible = "rockchip,rk3572-dwc3";
+        reg = <0x24400000 0x400000>;
+        interrupts = <GIC_SPI 254 IRQ_TYPE_LEVEL_HIGH>;
+        clocks = <&cru CLK_REF_USB3OTG1>, <&cru CLK_SUSPEND_USB3OTG1>,
+                 <&cru ACLK_USB3OTG1>;
+        clock-names = "ref_clk", "suspend_clk", "bus_clk";
+        phys = <&u2phy1_otg>, <&combphy1 PHY_TYPE_USB3>;
+        phy-names = "usb2-phy", "usb3-phy";
+        power-domains = <&power RK3572_PD_PHP>;
+        resets = <&cru SRST_ARESETN_USB3OTG1>;
+        rockchip,grf = <&php_grf 0x34>;
+        dr_mode = "host";
+    };

-- 
2.34.1

