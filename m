From: Ricardo Pardini <ricardo@pardini.net>
Date: Fri, 05 Jun 2026 13:49:08 +0200
Subject: [PATCH v3 1/3] dt-bindings: net: add Realtek r8169 family PCIe
 Ethernet
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-rk3588-dts-rtl-eth-describe-dt-alias-v3-1-8a8857b39daf@pardini.net>
References: <20260605-rk3588-dts-rtl-eth-describe-dt-alias-v3-0-8a8857b39daf@pardini.net>
In-Reply-To: <20260605-rk3588-dts-rtl-eth-describe-dt-alias-v3-0-8a8857b39daf@pardini.net>
To: Heiner Kallweit <hkallweit1@gmail.com>, nic_swsd@realtek.com, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Sebastian Reichel <sebastian.reichel@collabora.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2818; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=SwvhGPGzhgbbXrid/Pg1myL4wDhH+eVp/OO6aNuLepE=;
 b=owGbwMvMwMFoHWf/eN7xty8ZT6slMWQpbd/FWGppYr/MysQiwyooP2dW8OqTcdMl65jLxefU5
 +/tbgnrZPRnYWDkYLAUU2RZI6HM8239q1N3PDomwwxiZQKZIi3SwAAELAx8uYl5pUY6Rnqm2oZ6
 hkY6BjrGDFycAjDV7Jnsf7h/aG+smiH5n33aR5fpvm1HGk9JbnOR+ZyvtGbSZr/NEez3vliZRHl
 cy7E6L+Ks8C9P8m7j7wDDBLH8I0EOmvz8TZ9qFmyIWO1xpnP5v56Gy9/WbjZL3K18Yj9nk8zWfa
 E1llPti9cd+c8s3l4XMYdt4qtXHh//e3EfPuldmfhwcdpFR+2Up5vcY2+KavrNsgktveWxITQku
 Nt3m8zNh9z7Fm+qv9j1gfX7Fv8H1eVn8qMjZj2c1Jfgkm35iiHDpjXhQar2FEXm/ZZc8g75vYqn
 Pr5NWHZLat+KSzHRaXK7Qw/6hy8WaDx/TPSaYZU5q96/O533e1JvOrX/nVA+71utW8T1O3VnTnT
 2dJQyAgA=
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a binding for fixed/soldered Realtek PCIe Ethernet controllers
driven by the r8169 driver (RTL8125/8126/8127/8168 and variants).

The "pciVVVV,DDDD" compatibles are the Open Firmware PCI Bus Binding
spelling, auto-derived from PCI-SIG vendor/device IDs, but they still
need a binding when used in a board DT - analogous to "usbVVVV,PPPP"
compatibles documented in their own bindings (e.g. microchip,lan95xx)
so board DTs attaching properties (fixed MAC, nvmem cell, ...) to
these PCI function nodes can be validated.

Suggested-by: Sebastian Reichel <sebastian.reichel@collabora.com>
Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 .../devicetree/bindings/net/realtek,r8169.yaml     | 54 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 55 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/realtek,r8169.yaml b/Documentation/devicetree/bindings/net/realtek,r8169.yaml
new file mode 100644
index 0000000000000..6923211ff4c93
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/realtek,r8169.yaml
@@ -0,0 +1,54 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/net/realtek,r8169.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Realtek r8169 family PCIe Ethernet Controllers
+
+maintainers:
+  - Heiner Kallweit <hkallweit1@gmail.com>
+
+description:
+  PCI function node properties for fixed/soldered Realtek Ethernet
+  controllers driven by the r8169 driver.
+
+allOf:
+  - $ref: ethernet-controller.yaml#
+
+properties:
+  compatible:
+    enum:
+      - pci10ec,8125  # RTL8125 2.5GbE
+      - pci10ec,8126  # RTL8126 5GbE
+      - pci10ec,8127  # RTL8127
+      - pci10ec,8161  # RTL8168 variant
+      - pci10ec,8162  # RTL8168 variant
+      - pci10ec,8168  # RTL8168/8111 GbE
+
+  reg:
+    maxItems: 1
+
+  local-mac-address: true
+  mac-address: true
+  nvmem-cells: true
+  nvmem-cell-names: true
+
+required:
+  - compatible
+  - reg
+
+additionalProperties: false
+
+examples:
+  - |
+    pcie {
+        #address-cells = <3>;
+        #size-cells = <2>;
+
+        ethernet@0,0 {
+            compatible = "pci10ec,8125";
+            reg = <0x10000 0 0 0 0>;
+            local-mac-address = [00 00 00 00 00 00];
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index b539be153f6a4..6341de4fadb6c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -134,6 +134,7 @@ M:	Heiner Kallweit <hkallweit1@gmail.com>
 M:	nic_swsd@realtek.com
 L:	netdev@vger.kernel.org
 S:	Maintained
+F:	Documentation/devicetree/bindings/net/realtek,r8169.yaml
 F:	drivers/net/ethernet/realtek/r8169*
 
 8250/16?50 (AND CLONE UARTS) SERIAL DRIVER

-- 
2.54.0

