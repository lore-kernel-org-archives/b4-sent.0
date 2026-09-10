From: Ricardo Pardini <ricardo@pardini.net>
Date: Thu, 10 Sep 2026 22:07:51 +0200
Subject: [PATCH v5 1/7] dt-bindings: net: add Realtek RTL8125 PCIe Ethernet
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260910-rk3588-dts-rtl-eth-describe-dt-alias-v5-1-c1b9e5f10cd6@pardini.net>
References: <20260910-rk3588-dts-rtl-eth-describe-dt-alias-v5-0-c1b9e5f10cd6@pardini.net>
In-Reply-To: <20260910-rk3588-dts-rtl-eth-describe-dt-alias-v5-0-c1b9e5f10cd6@pardini.net>
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
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2688; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=UYU35l2Y2GghYNHCV52xHFRYzHVpr2XQI3dZsBGSAww=;
 b=owGbwMvMwMFoHWf/eN7xty8ZT6slMWQt5lOWM3t2ZK3S1tNpTK9OCSe3XHS5U1wTZPzuS818+
 a+61Va8nYz+LAyMHAyWYoosaySUeb6tf3XqjkfHZJhBrEwgU6RFGhiAgIWBLzcxr9RIx0jPVNtQ
 z9BIx0DHmIGLUwCmWluP/X9B3hG25g/5JxiX1P4+8lTgW6R29I4khja+hl+9bGcs9mbklnzJaT0
 9+0rbq1N7zTK5QrgVFSf8Niit/BK0vCbWWFrn+ZrvyYJMSUn16946pt24wxQ77dGiSSUML4VevH
 kjt8H6UYB3wxYP/RL9BTeenuqP6Hlr7DCr4ICes6jR7ZwgqYnRr+5xG5rbzXIyMKq886HnVvFZT
 ZWtftEKG4R4Vdf/nO3p2HVujtTib3Y7fmY+++xT8N31vDOzh47KjmDv0izD5Tw79D85PFV7dnFL
 I+PFDyWrLd0+9t7xTo6+NWvB1IjpsenX2FsvH4pJemL43nJtUpSxXMXlus6yaPt9ccvMF4gcZZe
 /7LT6OQA=
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a binding for fixed/soldered Realtek RTL8125 PCIe Ethernet
controller. As a PCIe device, its "pci10ec,8125" compatible is the
Open Firmware spelling auto-derived from its PCI-SIG vendor/device IDs
and is already covered by the generic dtschema pci-device.yaml. The
compatible itself therefore needs no binding to be valid.

A dedicated binding is needed because board DTs describe these
soldered function nodes in order to attach ethernet-controller
properties to them: a placeholder local-mac-address that the bootloader
fills in today, and potentially nvmem-cells, phy-handle, etc. in the
future. This binding references ethernet-controller.yaml so those
properties are validated on the RTL8125 PCI function nodes.

Suggested-by: Sebastian Reichel <sebastian.reichel@collabora.com>
Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 .../devicetree/bindings/net/realtek,rtl8125.yaml   | 43 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 44 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/realtek,rtl8125.yaml b/Documentation/devicetree/bindings/net/realtek,rtl8125.yaml
new file mode 100644
index 0000000000000..eee13fbc1e6a6
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/realtek,rtl8125.yaml
@@ -0,0 +1,43 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/net/realtek,rtl8125.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Realtek RTL8125 2.5 Gigabit PCIe Ethernet Controller
+
+maintainers:
+  - Heiner Kallweit <hkallweit1@gmail.com>
+
+description:
+  The Realtek RTL8125 is a 2.5GBASE-T Ethernet controller with a PCIe host
+  interface.
+
+allOf:
+  - $ref: ethernet-controller.yaml#
+
+properties:
+  compatible:
+    const: pci10ec,8125
+
+  reg:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+
+unevaluatedProperties: false
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
index 6215fcb077705..f74c559a3fd06 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -134,6 +134,7 @@ M:	Heiner Kallweit <hkallweit1@gmail.com>
 M:	nic_swsd@realtek.com
 L:	netdev@vger.kernel.org
 S:	Maintained
+F:	Documentation/devicetree/bindings/net/realtek,rtl8125.yaml
 F:	drivers/net/ethernet/realtek/r8169*
 
 8250/16?50 (AND CLONE UARTS) SERIAL DRIVER

-- 
2.55.0

