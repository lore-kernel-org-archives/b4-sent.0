From: Ricardo Pardini <ricardo@pardini.net>
Date: Mon, 09 Nov 2026 02:53:47 +0100
Subject: [PATCH net-next] dt-bindings: net: add Realtek RTL8125 PCIe
 Ethernet
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-dt-bindings-net-realtek-rtl8125-v1-1-cff4b8a8be66@pardini.net>
X-B4-Tracking: v=1; b=H4sIAKon8WoC/yWNQQ6CQAxFr0K6tgkdIoJXMS5gpmCVVDNTDQnh7
 gy4fPn57y2QOAonuBYLRP5JkrdmoFMB/tHpyCghM7jS1URlg8GwFw2iY0Jlw8jdZPzCaFND7ox
 tS87Vni5VNUC2fCIPMh+FG+wH5dng/l/St3+ytz0A67oBqUu5Do0AAAA=
X-Change-ID: 20261108-dt-bindings-net-realtek-rtl8125-991226c1733f
To: Heiner Kallweit <hkallweit1@gmail.com>, nic_swsd@realtek.com, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Sebastian Reichel <sebastian.reichel@collabora.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4350; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=7nlD6uY1u4F0mRBPPEUBKpIYrlmDUFHO6at2lmifh/s=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBq8SeuO6zb9eCJ6q8FtHOjt+bOOtHzf7xobZ4Yv
 OGicDy6heCJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCavEnrgAKCRA7Xj/jnsft
 6XLNB/9Bw77ejpGM8LhzEykrl+tF+nUiOG35uGPYS4dZ8xPFx7G7xNQ2S0r2IIG3rj5RMbgcw5V
 vQvGZ9yBx/Ua1WVRrmQR4kEHWEr9xR6JdnUMZ6h6NLqof5GwES+wDjiodYS0M49rYgeiLDfjX9J
 tC5HcEYbyzBvBvVsv4bFdmHLACkeSC3mKh2DcLrcuH+/N1+ny7mvxjbn/YbZ9AlqWUdqj3v9Xlu
 40lySG5btGdRNqZJyA8H4AP+m6R4U8eE/1mTUNSWt75dtCMtHgcY1lyr2Mrnu1Hen6dHaY0lSpL
 +6G+94wjy2dCIb1FeEcGETp6gTlsRo8FLwo3LXxOcb1fVe9S
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
Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
---
Add a DT binding for the Realtek RTL8125 2.5GbE PCIe Ethernet
controller, so that board DTs describing soldered RTL8125 PCI function
nodes get their ethernet-controller properties (local-mac-address,
nvmem-cells, ...) validated.

This was previously patch 1/7 of the series "describe RTL8125 PCIe
NICs on Rockchip boards (and add DT binding)", up to v5 [1]. Per
Heiko's review [2] it is now sent on its own via net-next; the board
DT patches continue separately in that series (v6+). There is no
build-time dependency between the two: "pci10ec,8125" is already
covered by dtschema's pci-device.yaml, so the board DTs validate
without this binding.

The need for the binding (and for the compatible at all, since the
kernel binds these nodes by their reg) was discussed with Heiner in
v3 [3] and v4 [4]; the outcome, per Krzysztof, is reflected in the
commit message.

The patch is unchanged since v5 1/7, apart from the rebase onto
net-next; Rob's Reviewed-by from v5 [5] is carried over.

[1] https://patch.msgid.link/20260910-rk3588-dts-rtl-eth-describe-dt-alias-v5-0-c1b9e5f10cd6@pardini.net
[2] https://lore.kernel.org/all/1971659.CQOukoFCf9@phil/
[3] https://lore.kernel.org/all/b7cc8eba-ff6e-417d-8e74-b3bb24e08a26@gmail.com/T/#u
[4] https://lore.kernel.org/all/876a38f8-75ea-4b32-bb65-216cb3adb436@gmail.com/T/#u
[5] https://lore.kernel.org/all/178976078089.1640411.4176382061491076376.robh@kernel.org/
---
 .../devicetree/bindings/net/realtek,rtl8125.yaml   | 43 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 44 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/realtek,rtl8125.yaml b/Documentation/devicetree/bindings/net/realtek,rtl8125.yaml
new file mode 100644
index 000000000000..eee13fbc1e6a
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
index fe23913b1e43..afe9bff92936 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -134,6 +134,7 @@ M:	Heiner Kallweit <hkallweit1@gmail.com>
 M:	nic_swsd@realtek.com
 L:	netdev@vger.kernel.org
 S:	Maintained
+F:	Documentation/devicetree/bindings/net/realtek,rtl8125.yaml
 F:	drivers/net/ethernet/realtek/r8169*
 
 8250/16?50 (AND CLONE UARTS) SERIAL DRIVER

---
base-commit: fa5196392691051963726787944db872420dfa75
change-id: 20261108-dt-bindings-net-realtek-rtl8125-991226c1733f

Best regards,
--  
Ricardo Pardini <ricardo@pardini.net>

