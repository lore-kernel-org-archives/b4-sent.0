From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Subject: [PATCH RFC v3 00/12] Add support for the NXP S32G SerDes subsystem
Date: Sat, 19 Sep 2026 08:54:28 +0200
Message-Id: <20260919-s32g_serdes-v3-0-9d68868c1e89@oss.nxp.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKQxrmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHUUlJIzE
 vPSU3UzU4B8JSMDIzMDS0ML3WJjo/R4oKaU1GJdcwsDcyBMSQXSSkAdBUWpaZkVYNOilYLcnJV
 ia2sBuam+6GIAAAA=
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
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>, 
 Alexandru-Catalin Ionita <alexandru-catalin.ionita@nxp.com>, 
 Ionut Vicovan <Ionut.Vicovan@nxp.com>, 
 Bogdan Roman <bogdan-gabriel.roman@nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789800879; l=6250;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=B0bGHXVmsabhCJwTaoYe1xZvYfRlznf5vkJN3+gI+kI=;
 b=1yvMr9hjZ/knlaYPjq/Du80xtRHyTiYfNcQvgHSiDW0xchVS+JYmlGZx3hOKvZleunJQVmoZu
 Zj9MGuRWAYsCYyMJUnOdjhiwwp4WjxVMRAWsS+eW3V1rfYL7P9+lbC1
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series continues the S32G SerDes/XPCS upstreaming started by Vincent
Guittot. The effort has moved in-house at NXP and I am carrying it
forward from his v2 [v2] below, rather than restarting from scratch.
Authorship of the patches originating from his series is preserved
through Co-developed-by and his Signed-off-by; the rest builds on top.
Thanks to Vincent for the v1 -> v2 groundwork.

The S32G SoC family integrates two SerDes subsystems. Each one is built
from a DesignWare PCIe controller, two DesignWare Ethernet XPCS
instances and a shared two-lane combo PHY (PMA). The two lanes are
multiplexed between the PCIe controller and the XPCS instances, so a
given SerDes instance can run PCIe only, SGMII only, or a combination of
both, depending on the selected subsystem working mode.

This series adds the device tree bindings, the SerDes subsystem PHY
driver that owns the shared PMA and sequences the bring-up, a
transport-agnostic XPCS PCS core shared with i.MX, the S32G XPCS glue,
the SGMII support in the dwmac-s32 MAC glue, and the device tree nodes
for S32G2 and S32G3 including two routing variants for the
S32G3-VNP-RDB3 board.

The lane multiplexing is the reason the XPCS is not a self-contained PCS
platform device: in the mixed PCIe+SGMII modes both XPCS instances share
the PMA with the PCIe lane, so the reset and bring-up ordering has to be
driven by the SerDes PHY driver, which owns the shared resources. The
MAC obtains its phylink PCS from the SerDes subsystem through the
standard pcs-handle property.

Only the 1.25 Gbit/s (1000BASE-X / SGMII) working modes are wired up
here. The 2500BASE-X register paths are present in the PCS but are not
enabled, as there is no in-tree consumer yet; they are added by a
follow-up series together with the per-lane capability the binding would
need to describe them.

Tested on an S32G3-VNP-RDB3 board, in SerDes mode 1 (SGMII alongside two
active PCIe root complexes) and in SerDes mode 3.

Compared to v2 this series is rebased onto current mainline master
(see base-commit at the end of this cover letter) instead of the tree
the previous revision was generated against.

Changes since v2:
- Restructured the series: the single "serdes subsystem" driver has been
  split into the SerDes PHY driver (drivers/phy/freescale) and the PCS
  side (drivers/net/pcs), and the PCS side is further split into a
  transport-agnostic XPCS core shared with i.MX plus the S32G-specific
  glue. The core operates on regmaps supplied by the platform glue, so
  the S32G indirect memory-mapped transport and the i.MX Clause 45 MDIO
  transport can share it.
- Binding: dropped the vendor nxp,sys-mode property. The
  SS_RW_REG_0[SUBSYS_MODE] value is now derived from the lane child
  nodes and the nxp,xpcs-instance routing, since each described working
  mode has a unique lane mux. The reference-clock rate is validated
  against the derived mode instead of selecting it.
- Binding: S32G2 and S32G3 now use distinct compatibles without
  fallback, because the reference-manual mode tables differ per SoC and
  per SerDes instance.
- Binding: only the PCIe lane child carries '#phy-cells'; an XPCS lane
  is referenced by the MAC through pcs-handle rather than as a generic
  PHY provider.
- Documented pcs-handle for nxp,s32-dwmac and fixed the SerDes PHY
  phandle in the nxp,s32g-pcie example.
- Added SGMII support to the dwmac-s32 glue (pcs_init / select_pcs) and
  fixed the PHY interface selector to handle SGMII, RGMII, RMII and MII.
- Converted the vendor driver busy-waits to read_poll_timeout().
- Added the S32G2/S32G3 SerDes, PCIe and SCMI reset controller DT nodes
  and the S32G3-RDB3 SerDes routing overlays.

Link: https://lore.kernel.org/all/20260203161917.1666696-1-vincent.guittot@linaro.org/ [v2]

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
Clark Wang (1):
      net: pcs: add NXP SerDes XPCS shared core

Jan Petrous (OSS) (8):
      dt-bindings: phy: Add NXP S32G SerDes subsystem
      dt-bindings: net: nxp,s32-dwmac: Document pcs-handle
      dt-bindings: PCI: nxp,s32g-pcie: Fix SerDes PHY phandle in example
      net: stmmac: dwmac-s32: Add SGMII support
      arm64: dts: s32g: Add SCMI reset controller
      arm64: dts: s32g: Add SerDes controller nodes
      arm64: dts: s32g: Add PCIe controller nodes
      arm64: dts: s32g: Add S32G3-RDB3 SerDes routing variants

Vincent Guittot (3):
      net: pcs: Add NXP S32G XPCS driver
      phy: freescale: s32g: Add SerDes subsystem PHY
      MAINTAINERS: Add NXP S32G SerDes and SerDes xPCS core entries

 .../devicetree/bindings/net/nxp,s32-dwmac.yaml     |   11 +-
 .../devicetree/bindings/pci/nxp,s32g-pcie.yaml     |    3 +-
 .../devicetree/bindings/phy/nxp,s32g-serdes.yaml   |  258 +++++
 MAINTAINERS                                        |   23 +
 arch/arm64/boot/dts/freescale/Makefile             |    6 +
 arch/arm64/boot/dts/freescale/s32g2.dtsi           |  118 +++
 arch/arm64/boot/dts/freescale/s32g3.dtsi           |  118 +++
 .../dts/freescale/s32g399a-rdb3-serdes-mode1.dtso  |  111 ++
 .../dts/freescale/s32g399a-rdb3-serdes-mode3.dtso  |   60 ++
 drivers/net/ethernet/stmicro/stmmac/Kconfig        |    6 +
 drivers/net/ethernet/stmicro/stmmac/dwmac-s32.c    |   74 +-
 drivers/net/pcs/Kconfig                            |   25 +
 drivers/net/pcs/Makefile                           |    2 +
 drivers/net/pcs/pcs-nxp-s32g-xpcs.c                |  947 ++++++++++++++++++
 drivers/net/pcs/pcs-nxp-serdes-xpcs.c              |  853 ++++++++++++++++
 drivers/phy/freescale/Kconfig                      |    9 +
 drivers/phy/freescale/Makefile                     |    1 +
 drivers/phy/freescale/phy-nxp-s32g-serdes.c        | 1057 ++++++++++++++++++++
 include/linux/pcs/pcs-nxp-s32g-xpcs.h              |   48 +
 include/linux/pcs/pcs-nxp-serdes-xpcs.h            |  100 ++
 include/linux/phy/nxp-s32g-serdes.h                |   25 +
 21 files changed, 3850 insertions(+), 5 deletions(-)
---
base-commit: 5dd1818b15d98d4a20806cd00b1b40320b06004f
change-id: 20260918-s32g_serdes-7807070de807

Best regards,
-- 
Jan Petrous (OSS) <jan.petrous@oss.nxp.com>

