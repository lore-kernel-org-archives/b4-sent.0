From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Subject: [PATCH RFC v4 00/15] Add support for the NXP S32G SerDes subsystem
Date: Wed, 25 Nov 2026 10:33:42 +0100
Message-Id: <20261125-s32g_serdes-v4-0-3bfe0589be8d@oss.nxp.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAHarBmsC/1WNwQqDMBBEf0X23EiMRTc9CYV+QK9FSjFbzaGJZ
 ItYJP/eRXopexhmhnm7AVPyxHAqNki0ePYxiDkeChimRxhJeScejDaNthUqrs14l5EjVi3qVs6
 RKMhiTvT06067wfVyhl7CyfM7ps/+Yan36gezf7ClVlpZ1yA2OFSEtovMZVjncogv6HPOX1+Fb
 yCtAAAA
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
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>, 
 Alexandru-Catalin Ionita <alexandru-catalin.ionita@nxp.com>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@nxp.com>, 
 Ionut Vicovan <Ionut.Vicovan@nxp.com>, 
 Bogdan Roman <bogdan-gabriel.roman@nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795599274; l=19045;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=0aUsGnaAZ3M1x+3YY88bRXS5e/zwDyUxtend83v9Zog=;
 b=MxXI7F1308RktpgUd288QUjT2F68D8RzNw5JuHIlPI4RPlFy4gaSFQ7XINB9oX91gWc/a5bQB
 ubx+M3IuDfiAWKRaPjMYprbJyAAxQk4R4I1eFLwr3AhihY+gsJ+MjU5
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series continues the S32G SerDes/XPCS upstreaming started by
Vincent Guittot [v2], which I posted as RFC v3 [v3]. The patches
originating from his series keep his authorship, with Co-developed-by
and his Signed-off-by.

The S32G SoC family has two SerDes subsystems. Each one is built from a
DesignWare PCIe controller, two DesignWare XPCS instances and a shared
two-lane combo PHY (PMA). The lanes are multiplexed between the PCIe
controller and the XPCS instances, so a SerDes instance runs PCIe only,
SGMII only, or both, depending on its working mode.

The series adds:
 - the device tree bindings (patches 1-3);
 - S32G support in pcs-xpcs and the S32G XPCS glue (patches 4-8);
 - the SerDes subsystem PHY driver, which owns the shared PMA and
   sequences the bring-up (patch 9);
 - SGMII support in the dwmac-s32 MAC glue (patch 10);
 - the S32G2 and S32G3 device tree nodes and two routing variants for
   the S32G3-VNP-RDB3 board (patches 12-15).

In the PCIe+SGMII modes the XPCS shares the PMA with the PCIe lane, so
the reset and bring-up ordering is driven by the SerDes PHY driver, and
the XPCS is not a self-contained PCS platform device. The glue exposes
each XPCS instance to pcs-xpcs as an MDIO bus over its indirect MMIO
window. The SerDes node is a four-cell PHY provider, <lane type
instance max-speed>: a PCIe root port references its lanes, a MAC
references its lane, the XPCS instance it is wired to and the highest
speed the lane is wired for, and gets its PCS from the SerDes through
pcs-handle. The mode follows from these references.

The S32G XPCS reports the generic DesignWare PCS ID; what is specific
to S32G is the PMA integration. Following the v3 discussion with Coia
[id], the series has no synthetic PCS ID. Patch 5 lets a glue driver
declare the PCS and PMA IDs through struct dw_xpcs_info, and lets a
pcs-xpcs entry name a PMA ID. The S32G glue declares the DesignWare PCS
ID together with NXP_S32G_XPCS_PMA_ID, which selects the S32G entry of
patch 6. The PCS ID is declared rather than read because the glue
creates the PCS before the SerDes clocks run, so the ID registers
cannot be read at that point. The alternative is to create the PCS
after the SerDes bring-up and declare only the PMA ID; I would welcome
an opinion on which is preferred.

Scope: the 1.25 Gbit/s working modes only, i.e. SGMII up to 1G. The
S32G GMAC is limited to 1G, so nothing in tree can use the 3.125 Gbit/s
modes yet. 2500BASE-X support will follow with its first user: the S32G
PFE Ethernet driver or the S32R47 integration. It builds on patch 5:
the glue also declares the PMA reference clock rate, which the 2.5G
PLL switch needs.

v3 introduced a transport-agnostic NXP SerDes XPCS core, authored by
Clark Wang, as a common base for S32G and a later i.MX9 xPCS port.
Following the review of v3, v4 drops it in favour of pcs-xpcs. This
does not leave i.MX9 behind: its XPCS is reached over Clause 45 MDIO,
which pcs-xpcs supports as it is. No i.MX9 code was part of v3.
Thanks to Clark for the shared core work.

Merging: the series is meant for the PHY tree, as v2 and v3 were.
Patches 4-8 (pcs-xpcs) and 10 (dwmac-s32) change networking code, and
the build depends on them in order, 8 -> 9 -> 10. I would ask for Acks
from the PCS and stmmac side on those patches, so that they can go
through the PHY tree together with patch 9. The device tree patches
12-15 can go through the NXP SoC tree once the bindings are in.

The series is based on v7.4-rc1. Since v3, Coia Prant's RK3568 XPCS
series [rk3568] went in: pcs-xpcs-plat.c is now its own module
(PCS_XPCS_PLATFORM), and pcs-xpcs restarts SGMII autonegotiation in
xpcs_config_aneg_c37_sgmii() and in xpcs_get_state_c37_sgmii() when
the link is down with AN complete latched. The S32G glue of patch 8
takes the same shape as the RK3568 one, an MDIO bus over the register
window with the PCS created by pcs-xpcs. The series was retested on
the 7.4 merge window state of 2026-10-27, see below; rc1 brought no
change to pcs-xpcs, the SerDes PHY driver or dwmac-s32 after that.

The bring-up register sequences come from the vendor driver and the
reference manual.

Tested on an S32G399A-RDB3 board, on the merge window base above,
with the 15 patches as posted. The XPCS1 runs use the PFE
Ethernet MACs, whose driver is not upstream yet.

 - SerDes_1 in mode 3 (dual SGMII, 125 MHz): XPCS0 as a 1G fixed link
   to the on-board SJA1110, XPCS1 with in-band SGMII to an AQR113C. 30
   partner speed changes between 100M and 1G without a stale speed,
   which is the path where pcs-xpcs restarts AN, with the link timer
   that the PMA hook sets, 935/941 and 942/941 Mbit/s on the two lanes,
   94.2 Mbit/s at 100M with no UDP loss, link down/up and driver reload
   cycles, no kernel errors. The receive path works on both lanes,
   which shows that the S32G entry, and with it the no-soft-reset
   quirk, is selected through the declared IDs.

 - SerDes_1 in mode 2 (PCIe x1 + SGMII, 100 MHz, internal and external
   reference) together with SerDes_0 in mode 3 (GMAC0 over XPCS0 at 1G):
   an Intel 82574L in the PCIe slot (Gen 1 x1, the card's maximum) at
   901/941 Mbit/s with its BARs in the 64-bit prefetchable window, the
   shared-lane XPCS1 at 935/941, GMAC0 at 935/941, NIC and XPCS1 at the
   same time 898 + 935, 10/10 XPCS1 link down/up under PCIe traffic with
   the NIC never below 893 Mbit/s, 10/10 GMAC0 down/up, no AER events.
   The same figures on the external reference (NIC 902/941). The fixed
   linux,pci-domain puts the slot in domain 1, so its NIC is named
   enP1p1s0.

 - The mode 1 variant of patch 15: SerDes_0 with PCIe_0 on lane 0, on
   the internal 100 MHz reference, and GMAC0 over XPCS0 on lane 1, with
   no phy-handle left on GMAC0. An NVMe SSD in the M.2 M-key slot trains
   at Gen 3 x1 and reads at 511 MB/s, with the data read back intact
   and no AER events. SerDes_1 derives PCIe x2 from its single PCIe
   reference. The mode 3 variant brings up SerDes_0 with GMAC0 on a
   fixed 1G SGMII link to the SJA1110. No GMAC0 traffic with the
   variants: the plain RDB3 DT has no SJA1110 firmware loader.

 - On v7.4-rc1 itself, with PHY_S32G_SERDES=m and PCIe_0 bound to a
   SerDes_0 lane, the PCIe controller defers until the module is loaded,
   and rmmod of the module then fails with "in use".

 - The two pcs-xpcs quirks of patch 4 were verified earlier by removing
   them (see the patch 4 note below).

 - With the 2.5G follow-up on top, SerDes_1 mode 3 also passed the
   100M/1G/2.5G partner speed cycle at 2.35/2.32 Gbit/s on the 2.5G
   lane, with the same 1G and 100M figures as above.

Not covered: suspend/resume, GMAC0 at 10M and 100M.

Changes in v4:

- Drop the NXP SerDes XPCS shared core (v3 patch 4) and use pcs-xpcs.
  The S32G support becomes a pcs-xpcs entry and a platform glue which
  owns the PMA/PLL bring-up. The review comments on v3 patch 4 no
  longer apply.

- Drop 2.5G support: no in-tree MAC can use it, and the binding only
  describes the 1.25 Gbit/s modes.

- Patch 1: the lanes are argument cells of the SerDes node,
  <lane type instance max-speed>, instead of child nodes (Rob, v2;
  Frank, v3). The XPCS instance is the third cell: the mux is
  programmed before any MAC probes, and modes 1 and 2 differ only by
  it. The cell layout is final. The fourth cell is the highest speed
  the lane is wired for; this series takes 1000 only, and 2500 comes
  with the 3.125 Gbit/s modes, which select other SUBSYS_MODE values,
  reference clocks and PCIe speeds, again at SerDes probe. The driver
  walks the tree for the references at probe. nxp,xpcs-instance vendor
  property is gone.
  Patches 2, 3, 9, 10, 13 and 15 follow: a MAC carries phys and
  pcs-handle to the SerDes node, a PCIe root port one phys entry per
  lane, and the SerDes driver provides one PHY per XPCS instance next
  to the PCIe one.

- Patch 2: phy-mode "sgmii" requires phys and pcs-handle, and each of
  them requires the other.

- Patch 3 (v3 patch 3): the example fix is dropped (Frank). What is
  left allows two phys entries on the root port, one per lane, and
  updates the example to the cells form.

- New patch 4: quirks mask in struct dw_xpcs_desc (no soft reset, no
  EEE). Both were checked on RDB3 by removing them. Without the first,
  the generic BMCR soft reset of xpcs_pre_config() leaves the XPCS stuck
  in reset on the in-band lane (BMCR_RESET never self-clears and every
  register then reads 0x8000) and the receive path dead on the lanes
  where it does complete; the working reset is VR_RST inside the vendor
  bring-up, which the SerDes PHY driver owns. VR_MII_EEE_MCTRL0/1 read
  zero and ignore writes, so the second quirk keeps the driver from
  touching registers the integration does not have.

- New patch 5: a glue driver can declare the PCS and PMA IDs through
  struct dw_xpcs_info with xpcs_create_pcs_mdiodev_info(); with both
  declared, no ID register is read. A dw_xpcs_desc entry can name a
  PMA ID, and such an entry takes precedence over one for the same PCS
  ID that matches any PMA. No functional change for existing users.
  This replaces the synthetic PCS ID discussed in the v3 thread [id],
  which Coia asked to avoid; the value proposed then, 0x30, is also
  used by the Qualcomm Nord RFC.

- New patch 6: S32G entry in pcs-xpcs, for the DesignWare PCS ID with
  NXP_S32G_XPCS_PMA_ID. SGMII only, with the PMA hook in
  pcs-xpcs-s32g.c. The hook sets the SGMII link timer to the 1.6 ms
  that phylink_get_link_timer_ns() gives for SGMII, converted with the
  reference manual formula, then sets CL37_TMR_OVR_RIDE, and restarts AN
  when it is enabled, so that the negotiation runs with the new timer.
  v3 wrote 0x7a1, the vendor 2500BASE-X value. The hook does not touch
  the PLLs and does not flush the PCS: the lane is on MPLLA from the
  SerDes bring-up, and the 1G sequence of the reference manual has no
  such steps. The quirks stay on the entry: Coia suggested glue-set
  flags, and they would move there without further change if that is
  preferred.

- New patch 7: with in-band SGMII, report the link down until AN
  completes, as the S32G XPCS keeps the previous SGMII link word until
  then. The v3 XPCS driver did the same. The gate also ran ungated on
  RDB3 with the same result; it stays behind the quirk only because it
  has been seen on S32G alone. It is independent of the AN restart that
  pcs-xpcs now does in the same function: that one acts once the link is
  down and AN complete is latched, this one keeps a stale link word from
  being reported before AN has completed.

- Patch 8 (v3 patch 5):
  - PCS_NXP_S32G_XPCS is a hidden symbol, selected by the SerDes PHY
    driver, in the "if PCS_XPCS" block that the RK3568 series added.
  - DW_VR_RST and DW_PSEQ_ST* come from pcs-xpcs.h.
  - The regmap is replaced by a mutex protected indirect accessor.
    Each XPCS instance is an mii_bus, and the PCS comes from
    xpcs_create_pcs_mdiodev_info() with the IDs of patch 5 declared.
    The glue does not emulate the MDIO ID registers; the hardware
    reports the generic DesignWare XPCS ID 0x7996ced0 (checked on
    RDB3).
  - Use MII_BMCR/BMCR_* and DW_VR_MII_DIG_CTRL1 instead of private
    defines (Andrew).
  - The exported bring-up steps have kernel-doc; the indirect window
    accessors use guard(mutex); the BMCR writes before VR_RST are gone,
    as the XPCS state is set after the reset.

- Patch 9:
  - PHY_S32G_SERDES depends on NETDEVICES, which its PCS select needs.
  - The PCIe PHY provider is registered on the SerDes device.
  - Return -EBUSY from set_mode while the PHY is powered on.
  - Drop the redundant reference clock check. Print the selected mode
    once at probe instead of on every resume.
  - Set .owner on the PCIe PHY ops, so a bound PCIe controller pins the
    module.
  - Use the reference manual field names and named delays in the PCIe
    PHY register path; drop the unused max_speed.

- Patch 10:
  - Select PHY_S32G_SERDES instead of "depends on PHY_S32G_SERDES ||
    PHY_S32G_SERDES=n". PHY_S32G_SERDES (patch 9) now selects
    PCS_XPCS and PCS_NXP_S32G_XPCS instead of depending on them
    (Maxime).
  - Store the PCS in priv->hw->phylink_pcs (Maxime).
  - Do not add RMII and MII to the interface selector (Maxime).
  - Keep the MAC transmit clock at 125 MHz with SGMII. The generic
    stmmac_set_clk_tx_rate() set 25 MHz / 2.5 MHz at 100M / 10M.
  - Look up the PCS for SGMII only; an SGMII MAC without pcs-handle
    fails to probe.
  - Compute the interface selector once at probe, so an unsupported
    phy-mode fails the probe.
  - Disable EEE with SGMII: the S32G XPCS has no EEE, but stmmac
    assumes LPI works through any external PCS.

- Patch 11: drop the shared core entry, add pcs-xpcs-s32g.c. The entry
  and the binding name the same maintainers.

- Patch 13: keep the S32G3 SoC nodes sorted by unit address.

- Patch 14: fixed linux,pci-domain on both PCIe controllers.

- Patch 15: the routing variants are full .dts files that include the
  board DT, not overlays, as they drop the phy-handle of GMAC0 and
  /delete-property/ has no effect in an overlay.

- sashiko-bot review of v3:
  - Patch 2: pcs-handle only adds maxItems: 1 to the inherited type.
  - Patch 14: mark the window above 4 GiB as 64-bit prefetchable
    (0x43000000), as the other DesignWare hosts do. A non-prefetchable
    window above 4 GiB cannot be used behind the root port.
  - Patch 9:
    - Register the PCIe PHY provider at the end of probe, after the
      clocks are up.
    - Return -ENODEV for an XPCS instance which was not set up, instead
      of deferring forever.
    - Track the clock state, so that suspend and unbind do not disable
      the clocks again after a failed resume.
    - Set suppress_bind_attrs.
    - The "sleep in atomic context" report is a false positive: noirq
      callbacks run in process context.

- Commit messages and code comments are shortened throughout. Patch
  12 has no other change.

Link: https://lore.kernel.org/all/20260203161917.1666696-1-vincent.guittot@linaro.org/ [v2]
Link: https://lore.kernel.org/all/20260919-s32g_serdes-v3-0-9d68868c1e89@oss.nxp.com/ [v3]
Link: https://lore.kernel.org/all/20261017054406.1828061-1-coiaprant@gmail.com/ [rk3568]
Link: https://lore.kernel.org/all/as95JpawMfSSk+Pa@lsv051416.swis.nl-cdc01.nxp.com/ [id]

To: Vincent Guittot <vincent.guittot@linaro.org>
To: Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>
To: Ciprian Marian Costea <ciprianmarian.costea@oss.nxp.com>
To: NXP S32 Linux Team <s32@nxp.com>
To: Vinod Koul <vkoul@kernel.org>
To: Neil Armstrong <neil.armstrong@linaro.org>
To: Manivannan Sadhasivam <mani@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Andrew Lunn <andrew+netdev@lunn.ch>
To: David S. Miller <davem@davemloft.net>
To: Eric Dumazet <edumazet@kernel.org>
To: Jakub Kicinski <kuba@kernel.org>
To: Paolo Abeni <pabeni@redhat.com>
To: Bjorn Helgaas <bhelgaas@google.com>
To: Lorenzo Pieralisi <lpieralisi@kernel.org>
To: Krzysztof Wilczyński <kwilczynski@kernel.org>
To: Bogdan Hamciuc <bogdan.hamciuc@nxp.com>
To: Ionut Vicovan <ionut.vicovan@nxp.com>
To: Andrew Lunn <andrew@lunn.ch>
To: Heiner Kallweit <hkallweit1@gmail.com>
To: Russell King <linux@armlinux.org.uk>
To: Philipp Zabel <p.zabel@pengutronix.de>
To: Maxime Chevallier <maxime.chevallier@bootlin.com>
To: Maxime Coquelin <mcoquelin.stm32@gmail.com>
To: Alexandre Torgue <alexandre.torgue@foss.st.com>
To: Chester Lin <chester62515@gmail.com>
To: Matthias Brugger <mbrugger@suse.com>
To: Frank Li <Frank.Li@nxp.com>
To: Sascha Hauer <s.hauer@pengutronix.de>
To: Pengutronix Kernel Team <kernel@pengutronix.de>
To: Fabio Estevam <festevam@gmail.com>
To: Richard Cochran <richardcochran@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-phy@lists.infradead.org
Cc: netdev@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: imx@lists.linux.dev
Cc: linux-pci@vger.kernel.org
Cc: linux-stm32@st-md-mailman.stormreply.com

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
Jan Petrous (OSS) (12):
      dt-bindings: phy: Add NXP S32G SerDes subsystem
      dt-bindings: net: nxp,s32-dwmac: Document pcs-handle
      dt-bindings: PCI: nxp,s32g-pcie: One PHY per lane
      net: pcs: xpcs: allow a PCS to opt out of soft reset and EEE
      net: pcs: xpcs: let a glue driver declare the PCS and PMA IDs
      net: pcs: xpcs: add NXP S32G SerDes XPCS support
      net: pcs: xpcs: wait for SGMII AN to complete in-band
      net: stmmac: s32: Add SGMII support
      arm64: dts: s32g: Add SCMI reset controller
      arm64: dts: s32g: Add SerDes controller nodes
      arm64: dts: s32g: Add PCIe controller nodes
      arm64: dts: s32g: Add S32G3-RDB3 SerDes routing variants

Vincent Guittot (3):
      net: pcs: Add NXP S32G XPCS glue
      phy: freescale: s32g: Add SerDes subsystem PHY
      MAINTAINERS: Add NXP S32G SerDes entry

 .../devicetree/bindings/net/nxp,s32-dwmac.yaml     |   30 +-
 .../devicetree/bindings/pci/nxp,s32g-pcie.yaml     |    6 +-
 .../devicetree/bindings/phy/nxp,s32g-serdes.yaml   |  137 +++
 MAINTAINERS                                        |   16 +
 arch/arm64/boot/dts/freescale/Makefile             |    2 +
 arch/arm64/boot/dts/freescale/s32g2.dtsi           |  116 ++
 arch/arm64/boot/dts/freescale/s32g3.dtsi           |  116 ++
 .../dts/freescale/s32g399a-rdb3-serdes-mode1.dts   |   65 ++
 .../dts/freescale/s32g399a-rdb3-serdes-mode3.dts   |   40 +
 drivers/net/ethernet/stmicro/stmmac/Kconfig        |    1 +
 drivers/net/ethernet/stmicro/stmmac/dwmac-s32.c    |   81 +-
 drivers/net/pcs/Kconfig                            |    7 +
 drivers/net/pcs/Makefile                           |    4 +-
 drivers/net/pcs/pcs-nxp-s32g-xpcs.c                |  569 ++++++++++
 drivers/net/pcs/pcs-xpcs-s32g.c                    |   48 +
 drivers/net/pcs/pcs-xpcs.c                         |  149 ++-
 drivers/net/pcs/pcs-xpcs.h                         |    5 +
 drivers/phy/freescale/Kconfig                      |   13 +
 drivers/phy/freescale/Makefile                     |    1 +
 drivers/phy/freescale/phy-nxp-s32g-serdes.c        | 1132 ++++++++++++++++++++
 include/linux/pcs/pcs-nxp-s32g-xpcs.h              |   41 +
 include/linux/pcs/pcs-xpcs.h                       |    4 +
 include/linux/phy/nxp-s32g-serdes.h                |   25 +
 23 files changed, 2578 insertions(+), 30 deletions(-)
---
base-commit: 4dce97c6c265544342e716e62fd24bbb232590c5
change-id: 20260918-s32g_serdes-7807070de807

Best regards,
-- 
Jan Petrous (OSS) <jan.petrous@oss.nxp.com>

