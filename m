From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Wed, 25 Nov 2026 10:33:43 +0100
Subject: [PATCH RFC v4 01/15] dt-bindings: phy: Add NXP S32G SerDes
 subsystem
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-s32g_serdes-v4-1-3bfe0589be8d@oss.nxp.com>
References: <20261125-s32g_serdes-v4-0-3bfe0589be8d@oss.nxp.com>
In-Reply-To: <20261125-s32g_serdes-v4-0-3bfe0589be8d@oss.nxp.com>
To: Vincent Guittot <vincent.guittot@linaro.org>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>, 
 Ciprian Marian Costea <ciprianmarian.costea@oss.nxp.com>, 
 NXP S32 Linux Team <s32@nxp.com>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Bogdan Hamciuc <bogdan.hamciuc@nxp.com>, 
 Ionut Vicovan <ionut.vicovan@nxp.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Chester Lin <chester62515@gmail.com>, Matthias Brugger <mbrugger@suse.com>, 
 Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Richard Cochran <richardcochran@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, 
 linux-pci@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795599274; l=6931;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=pFftY5ppzmA4Tf+cdOjE2ihm8f1VwzEk/60Lo7i4qIc=;
 b=3bbfmg5c+OccNyS5LG7aiWzBtkz3ffrgYWf1bz6LgNqobSpPjIII0BxLOhGI4WGU8p53GT5j2
 qgJ69HhmkMqBBh/mo0uRkTkydQRVj6DUsFHSHSpqfMVkDzSq1f8AbqX
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The S32G SerDes subsystem multiplexes two lanes between a PCIe PHY and
two DesignWare XPCS instances. Describe it with one node per SerDes,
which is a four-cell PHY provider: <lane type instance max-speed>.

There is no mode property. SS_RW_REG_0[SUBSYS_MODE] follows from the
phys references of the consumers: a PCIe root port references its
lanes with PHY_TYPE_PCIE, an Ethernet controller references its lane
with PHY_TYPE_SGMII, the XPCS instance it is wired to and the highest
speed the lane is wired for, and takes the PCS from the SerDes node
through pcs-handle. Each mode described here has a unique lane mux. A
lane that no consumer references takes the function it has in the
first matching mode.

The XPCS instance is a cell rather than derived from the MAC: the mux
is programmed at SerDes probe, before any MAC exists, and "XPCS0 alone
on lane 1" (mode 1 with the PCIe lane idle) and "XPCS1 alone on lane 1"
(mode 2) are different routings of the same pins. The cell layout is
final.

The speed is a cell for the same reason. The 3.125 Gbit/s
configurations select other SUBSYS_MODE values, reference clocks and
PCIe speeds, all decided at SerDes probe, and the MAC's phy-mode does
not tell: an in-band SGMII link to a 2.5G PHY is "sgmii" and moves to
2500BASE-X at runtime. Only the 1.25 Gbit/s modes are described, so
1000 is the only accepted speed; 2500 comes with the 3.125 Gbit/s
modes without a change of #phy-cells.

The mode tables differ per SoC and per SerDes instance, so S32G2 and
S32G3 have no common fallback, and each instance has its own compatible
with the per-SoC one as fallback.

Co-developed-by: Vincent Guittot <vincent.guittot@linaro.org>
Signed-off-by: Vincent Guittot <vincent.guittot@linaro.org>
Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 .../devicetree/bindings/phy/nxp,s32g-serdes.yaml   | 137 +++++++++++++++++++++
 1 file changed, 137 insertions(+)

diff --git a/Documentation/devicetree/bindings/phy/nxp,s32g-serdes.yaml b/Documentation/devicetree/bindings/phy/nxp,s32g-serdes.yaml
new file mode 100644
index 000000000000..a06becfcc4e4
--- /dev/null
+++ b/Documentation/devicetree/bindings/phy/nxp,s32g-serdes.yaml
@@ -0,0 +1,137 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/phy/nxp,s32g-serdes.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: NXP S32G2xxx/S32G3xxx SerDes PHY subsystem
+
+maintainers:
+  - Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>
+  - Ciprian Marian Costea <ciprianmarian.costea@oss.nxp.com>
+  - Jan Petrous <jan.petrous@oss.nxp.com>
+
+description: |
+  The SerDes subsystem multiplexes two lanes between one PCIe controller PHY
+  and two Synopsys DesignWare XPCS (Ethernet PCS) instances, behind a shared
+  2-lane combo PHY. The routing is selected by SS_RW_REG_0[SUBSYS_MODE].
+  The 1.25 Gbit/s modes are:
+
+  Mode  Lane0   Lane1   PHY refclk (MHz)  Description
+  ------------------------------------------------------------
+  0     PCIe    PCIe    100               PCIe x2
+  1     PCIe    XPCS0   100               PCIe x1 + SGMII
+  2     PCIe    XPCS1   100               PCIe x1 + SGMII
+  3     XPCS0   XPCS1   100 or 125        dual SGMII, 1.25 Gbit/s
+
+  The mode is not a property. It follows from the phys references of the
+  consumers: each one names the lane, the PHY type and, for an XPCS lane,
+  the XPCS instance and the highest speed the lane is wired for. Each mode
+  has a unique lane mux. A lane that no consumer references takes the
+  function it has in the first matching mode of the table.
+
+  A PCIe root port references one lane per link width. An Ethernet MAC
+  references its lane with phys and takes its PCS from the same SerDes
+  node through pcs-handle.
+
+  Which MAC an XPCS instance feeds is fixed by the SoC integration. On S32G3
+  SerDes_0, XPCS0 feeds GMAC0 and XPCS1 feeds PFE_MAC2; on SerDes_1 they feed
+  PFE_MAC0 and PFE_MAC1.
+
+  The mode tables differ per SoC and per SerDes instance: on S32G3 the
+  3.125 Gbit/s dual-XPCS mode exists on SerDes_1 only, and on S32G2 only
+  SerDes_1 reaches 3.125 Gbit/s. S32G2 and S32G3 therefore have no common
+  fallback, and each instance has its own compatible, with the per-SoC one
+  as fallback.
+
+properties:
+  compatible:
+    oneOf:
+      - items:
+          - enum:
+              - nxp,s32g2-serdes0
+              - nxp,s32g2-serdes1
+          - const: nxp,s32g2-serdes
+      - items:
+          - enum:
+              - nxp,s32g3-serdes0
+              - nxp,s32g3-serdes1
+          - const: nxp,s32g3-serdes
+
+  reg:
+    maxItems: 4
+
+  reg-names:
+    items:
+      - const: ss-pcie
+      - const: pcie-phy
+      - const: xpcs0
+      - const: xpcs1
+
+  clocks:
+    minItems: 4
+    maxItems: 5
+
+  clock-names:
+    minItems: 4
+    items:
+      - const: axi
+      - const: aux
+      - const: apb
+      - const: ref
+      - const: ext
+    description:
+      The combo PHY reference can be taken from the internal reference
+      clock ("ref") or from the external reference pad ("ext"). A board
+      that routes the external pad lists both; the external reference is
+      then the one used.
+
+  resets:
+    maxItems: 2
+
+  reset-names:
+    items:
+      - const: serdes
+      - const: pcie
+
+  '#phy-cells':
+    const: 4
+    description: |
+      The first cell is the lane, 0 or 1. The second cell is the PHY type,
+      PHY_TYPE_PCIE or PHY_TYPE_SGMII from dt-bindings/phy/phy.h. The third
+      cell is the XPCS instance, 0 or 1, and the fourth the highest
+      Ethernet speed the lane is wired for, in Mbit/s: 1000 for a 1.25
+      Gbit/s lane, 2500 for a 3.125 Gbit/s one. Both are 0 for
+      PHY_TYPE_PCIE.
+
+required:
+  - compatible
+  - reg
+  - reg-names
+  - clocks
+  - clock-names
+  - resets
+  - reset-names
+  - '#phy-cells'
+
+additionalProperties: false
+
+examples:
+  # Consumers select the mode. PCIe x1 on lane 0 plus 1G SGMII on lane 1 via
+  # XPCS0 (mode 1) is, on the PCIe root port and the MAC:
+  #   phys = <&serdes0 0 PHY_TYPE_PCIE 0 0>;
+  #   phys = <&serdes0 1 PHY_TYPE_SGMII 0 1000>; pcs-handle = <&serdes0>;
+  - |
+    serdes0: serdes@40480000 {
+        compatible = "nxp,s32g3-serdes0", "nxp,s32g3-serdes";
+        reg = <0x40480000 0x108>,
+              <0x40483008 0x10>,
+              <0x40482000 0x800>,
+              <0x40482800 0x800>;
+        reg-names = "ss-pcie", "pcie-phy", "xpcs0", "xpcs1";
+        clocks = <&clks 1>, <&clks 2>, <&clks 3>, <&clks 4>;
+        clock-names = "axi", "aux", "apb", "ref";
+        resets = <&scmi_reset 1>, <&scmi_reset 0>;
+        reset-names = "serdes", "pcie";
+        #phy-cells = <4>;
+    };

-- 
2.55.0

