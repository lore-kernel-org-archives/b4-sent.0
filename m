From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Sat, 19 Sep 2026 08:54:29 +0200
Subject: [PATCH RFC v3 01/12] dt-bindings: phy: Add NXP S32G SerDes
 subsystem
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260919-s32g_serdes-v3-1-9d68868c1e89@oss.nxp.com>
References: <20260919-s32g_serdes-v3-0-9d68868c1e89@oss.nxp.com>
In-Reply-To: <20260919-s32g_serdes-v3-0-9d68868c1e89@oss.nxp.com>
To: Ciprian Marian Costea <ciprianmarian.costea@oss.nxp.com>, 
 NXP S32 Linux Team <s32@nxp.com>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@nxp.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Geert Uytterhoeven <geert+renesas@glider.be>, 
 Magnus Damm <magnus.damm@gmail.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Bogdan Hamciuc <bogdan.hamciuc@nxp.com>, 
 Ionut Vicovan <ionut.vicovan@nxp.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Clark Wang <xiaoning.wang@nxp.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Chester Lin <chester62515@gmail.com>, Matthias Brugger <mbrugger@suse.com>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>, 
 Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Richard Cochran <richardcochran@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-renesas-soc@vger.kernel.org, 
 imx@lists.linux.dev, linux-pci@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789800879; l=10647;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=jWc5rUFrCSvy3cyhVKnTv3ExtsHxUm+n1VLVLDsYybw=;
 b=SFCifXNfc9pfu2YbrTq99I+sUT4yNBnNVyHoAKO09bNUJ4rFkMCxzQHi9bBblxFHSHAP37/im
 cGtZaRxeknpCKYT82Hdr/dHf1X+m+HHxfY+uaTyfEfD9HF+U0vH3RtH
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The S32G SerDes subsystem multiplexes two lanes between a PCIe PHY and
two DesignWare XPCS instances. Describe it with one node per SerDes and
one child node per lane.

Compared to the previous revision, the vendor nxp,sys-mode property is
removed: the SS_RW_REG_0[SUBSYS_MODE] value is fully derivable from the
child-node lane mux and the XPCS instance routing (nxp,xpcs-instance).
Each working mode described here has a unique lane mux, so the mode is
a pure function of the child nodes. The reference-clock rate is
validated against the derived mode; it is not used to select it.

The 3.125 Gbit/s working modes are deliberately not described yet.
Distinguishing them from the 1.25 Gbit/s dual-XPCS mode requires a
per-lane 2500BASE-X capability that this binding does not express, and
the reference clock does not distinguish them either - both accept 100
or 125 MHz. They are added by the 2500BASE-X follow-up.

Only the PCIe lane child gets '#phy-cells'. An XPCS lane is not a
generic PHY provider; the Ethernet controller references it through the
standard pcs-handle property instead.

S32G2 and S32G3 use distinct compatibles without fallback because the
full reference-manual mode tables differ per SoC and per SerDes
instance.

Co-developed-by: Vincent Guittot <vincent.guittot@linaro.org>
Signed-off-by: Vincent Guittot <vincent.guittot@linaro.org>
Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 .../devicetree/bindings/phy/nxp,s32g-serdes.yaml   | 258 +++++++++++++++++++++
 1 file changed, 258 insertions(+)

diff --git a/Documentation/devicetree/bindings/phy/nxp,s32g-serdes.yaml b/Documentation/devicetree/bindings/phy/nxp,s32g-serdes.yaml
new file mode 100644
index 000000000000..6343d01bfde4
--- /dev/null
+++ b/Documentation/devicetree/bindings/phy/nxp,s32g-serdes.yaml
@@ -0,0 +1,258 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/phy/nxp,s32g-serdes.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: NXP S32G2xxx/S32G3xxx SerDes PHY subsystem
+
+maintainers:
+  - Ghennadi Procopciuc <ghennadi.procopciuc@nxp.com>
+  - Jan Petrous <jan.petrous@oss.nxp.com>
+
+description: |
+  The SerDes subsystem multiplexes two SerDes lanes between one PCIe
+  controller PHY and two Synopsys DesignWare XPCS (Ethernet PCS) instances,
+  behind a shared 2-lane combo PHY. The active routing is selected by the
+  SS_RW_REG_0[SUBSYS_MODE] field.
+
+  Reference-manual working modes described by this binding:
+
+  Mode  Lane0   Lane1   PHY refclk (MHz)  Description
+  ------------------------------------------------------------
+  0     PCIe    PCIe    100               PCIe x2
+  1     PCIe    XPCS0   100               PCIe x1 + SGMII
+  2     PCIe    XPCS1   100               PCIe x1 + SGMII
+  3     XPCS0   XPCS1   100 or 125        dual SGMII, 1.25 Gbit/s
+
+  Which Ethernet MAC an XPCS instance feeds is fixed by the SoC integration
+  and differs per SoC and per SerDes instance - on S32G3 SerDes_0, XPCS0
+  feeds GMAC0 and XPCS1 feeds PFE_MAC2, while on SerDes_1 the same two
+  instances feed PFE_MAC0 and PFE_MAC1. That mapping is a property of the
+  SoC, not of this binding, and is resolved by the driver.
+
+  The 3.125 Gbit/s working modes are not described here yet. Distinguishing
+  them from mode 3 requires a per-lane 2500BASE-X capability, which this
+  binding does not express; the reference clock does not distinguish them
+  either, as both accept 100 or 125 MHz. They are added by a follow-up.
+
+  SUBSYS_MODE is not encoded in the devicetree. It is derived at probe from
+  information already present in standard form:
+    - the lane mux, from the per-lane child nodes below;
+    - the XPCS instance a lane feeds, from nxp,xpcs-instance (this is what
+      distinguishes modes 1 and 2).
+  Each mode above has a unique lane mux, so the mode is a pure function of
+  the child nodes. The reference-clock rate is validated against the
+  derived mode; it is never used to select it.
+
+  Both lanes must always be described, even a lane the board does not wire
+  out to a connector. The lane mux is a property of the hardware
+  SUBSYS_MODE, not of the board routing: in mode 1, for example, the
+  subsystem internally routes lane 1 to XPCS0 whether or not the board
+  connects that lane to anything. The child nodes describe that fixed
+  hardware mux, so both must be present; omitting a lane leaves the mode
+  underivable and the probe fails with -EINVAL. Which of those lanes is
+  actually used by a given board is expressed elsewhere (the consumer's
+  phys / pcs-handle reference), not by leaving the lane out here.
+
+  The full reference-manual mode tables differ per SoC, which is why S32G2
+  and S32G3 use distinct compatibles without a fallback between them.
+
+  They also differ between the two SerDes instances of one SoC, so each
+  instance additionally carries a compatible naming it, with the per-SoC
+  string as fallback:
+
+    serdes0: compatible = "nxp,s32g3-serdes0", "nxp,s32g3-serdes";
+    serdes1: compatible = "nxp,s32g3-serdes1", "nxp,s32g3-serdes";
+
+  For the modes described here the two instances behave identically and a
+  driver need only match the fallback. They diverge outside this scope:
+  on S32G3 the 3.125 Gbit/s dual-XPCS mode 4 exists on SerDes_1 only, and
+  on S32G2 only SerDes_1 reaches 3.125 Gbit/s at all. Recording the
+  instance now means the follow-up that adds those modes is purely
+  additive - it matches the specific strings and needs no devicetree
+  change.
+
+  The same mechanism covers SoCs whose instances differ in kind rather
+  than in degree: on S32R47 one SerDes has no PCIe controller at all, so
+  its compatible must be distinguishable in order to reject a PCIe lane
+  child in schema rather than at probe time.
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
+  '#address-cells':
+    const: 1
+
+  '#size-cells':
+    const: 0
+
+patternProperties:
+  '^phy@[01]$':
+    description: One SerDes lane. The unit address is the physical lane index.
+    type: object
+    additionalProperties: false
+
+    properties:
+      reg:
+        description: Physical lane index.
+        maximum: 1
+
+      compatible:
+        enum:
+          - nxp,s32g-serdes-pcie-phy
+          - nxp,s32g-serdes-xpcs
+
+      '#phy-cells':
+        const: 0
+
+      nxp,xpcs-instance:
+        $ref: /schemas/types.yaml#/definitions/uint32
+        enum: [0, 1]
+        description:
+          DesignWare XPCS instance this lane is routed to. Required for, and
+          only valid on, XPCS lanes. Distinguishes modes 1 and 2; for the
+          dual-XPCS mode the instance equals the lane index.
+
+    required:
+      - reg
+      - compatible
+
+    allOf:
+      - if:
+          properties:
+            compatible:
+              const: nxp,s32g-serdes-xpcs
+          required:
+            - compatible
+        then:
+          # An XPCS lane is not a generic PHY provider. It is referenced by
+          # the Ethernet controller through pcs-handle, not through phys.
+          required:
+            - nxp,xpcs-instance
+          properties:
+            '#phy-cells': false
+        else:
+          required:
+            - '#phy-cells'
+          properties:
+            nxp,xpcs-instance: false
+
+required:
+  - compatible
+  - reg
+  - reg-names
+  - clocks
+  - clock-names
+  - resets
+  - reset-names
+  - '#address-cells'
+  - '#size-cells'
+
+additionalProperties: false
+
+examples:
+  # PCIe x1 on lane 0 + 1G SGMII on lane 1 via XPCS0 (derived mode 1).
+  - |
+    serdes@40480000 {
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
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        phy@0 {
+            reg = <0>;
+            compatible = "nxp,s32g-serdes-pcie-phy";
+            #phy-cells = <0>;
+        };
+
+        phy@1 {
+            reg = <1>;
+            compatible = "nxp,s32g-serdes-xpcs";
+            nxp,xpcs-instance = <0>;
+        };
+    };
+
+  # Dual 1G SGMII (derived mode 3).
+  - |
+    serdes@44180000 {
+        compatible = "nxp,s32g3-serdes1", "nxp,s32g3-serdes";
+        reg = <0x44180000 0x108>,
+              <0x44183008 0x10>,
+              <0x44182000 0x800>,
+              <0x44182800 0x800>;
+        reg-names = "ss-pcie", "pcie-phy", "xpcs0", "xpcs1";
+        clocks = <&clks 1>, <&clks 2>, <&clks 3>, <&clks 4>;
+        clock-names = "axi", "aux", "apb", "ref";
+        resets = <&scmi_reset 11>, <&scmi_reset 10>;
+        reset-names = "serdes", "pcie";
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        phy@0 {
+            reg = <0>;
+            compatible = "nxp,s32g-serdes-xpcs";
+            nxp,xpcs-instance = <0>;
+        };
+
+        phy@1 {
+            reg = <1>;
+            compatible = "nxp,s32g-serdes-xpcs";
+            nxp,xpcs-instance = <1>;
+        };
+    };

-- 
2.55.0

