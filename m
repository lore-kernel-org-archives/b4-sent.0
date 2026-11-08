From: Vincent Jardin <vjardin@free.fr>
Subject: [PATCH v3 0/5] lx2160a: change the pad muxes through the RCW
 override
Date: Sun, 08 Nov 2026 11:06:48 +0100
Message-Id: <20261108-for-upstream-lx2160a-rcw-pinmux-v1-v3-0-5a0063f1da9e@free.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALhJ8GoC/5XNyw6CMBCF4VcxXTumF1JaV76HcTHSVprIJVNAD
 OHdLazckszmn8V3FpY8RZ/Y9bQw8lNMsWtzqPOJVTW2Lw/R5WaSSy0EVxA6grFPA3ls4D1LoTk
 CVR/oY9uMM0wClAgWnS1dZTTLUE8+xHkfuT9y1zENHX33zUls30N8Pg4ctUBrVFkWxS2Q95dAb
 MMneRyUGVSIjhvNn9b8geu6/gDLm28EIwEAAA==
To: Dong Aisheng <aisheng.dong@nxp.com>, Fabio Estevam <festevam@gmail.com>, 
 Frank Li <Frank.Li@nxp.com>, Jacky Bai <ping.bai@nxp.com>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 NXP S32 Linux Team <s32@nxp.com>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-arm-kernel@lists.infradead.org, imx@lists.linux.dev, 
 Vladimir Oltean <vladimir.oltean@nxp.com>, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794132412; l=4355;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=8qOvvLzHr2YInpyd/1vxj2b1Dv0S6oVIXe4mSCnnlG0=;
 b=Z6eeEU/IRNtio9zH+RBAjzG+uELIzoQb4b3cn+EU2qY7cBXUySKMbL04CTZMTdU8CZbQ2rQT9
 52Z7tVqd7h6Ay5NUrLoj719O3Zj/jE60Yt1RhzHPmfCq2yG1lQKb50d
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LX2160A muxes its IIC, XSPI, SDHC, UART, IRQ and EVT pads from
fields of the RCW. They are read-only in RCWSR12..14 of DCFG, and are
changed at runtime through the override registers in the DCSR view of
DCFG, which read 0 until written.

Since commit 8a1365c7bbc1 ("arm64: dts: lx2160a: add pinmux and i2c
gpio to support bus recovery"), fsl-lx216x.dtsi drives the override
registers with pinctrl-single for the I2C bus recovery. Its first pin
state clears every other field of the word: a board whose RCW programs
a non-zero pad mux loses those pads at the first I2C probe.

This series reads the fields in effect from RCWSR and writes RCWCR, as
fsl_guts_rcw_rmw() already does for the SerDes protocols:

- patches 1 and 2 describe the pad mux as a child of the DCFG node,
  which gains its DCSR view
- patch 3 exports the RCW override of fsl-guts for any RCWSR
- patch 4 adds the pinctrl driver: one group per RCW field, one
  function per encoding
- patch 5 moves the pad muxes of fsl-lx216x.dtsi under DCFG. Labels
  and pin node names stay, so no board file changes, and the
  pinctrl-single node goes

Patch 4 uses the exports of patch 3, so it cannot be applied alone:
patches 1 to 4 could be for the the pinctrl tree with an Ack of
the soc/fsl maintainer on patch 3,
and patch 5 through the i.MX tree once the driver is in,
since the I2C pin states of fsl-lx216x.dtsi then belong to it.

DTBs built before patch 5 keep their pinctrl-single node and behave as
before. There is no Fixes: tag, since patch 5 depends on a new driver.
I did not believe it should be backported then.

Tested on a Nodebox v3 (LX2160A) whose RCW muxes XSPI1_A_DATA[7:4],
SDHC1 and IIC5 are not set with the defaults, so I could confirm:
 - with pinctrl-single the first I2C probe cleared those fields
 - with this series RCWSR12..14 read after boot exactly what the RCW and
   the board's pin states select
 - all I2C controllers come up with their recovery states and a
   forced bus recovery on IIC1 (multi-master enabled for the test)
   changes only that field

Thanks to Vladimir Oltean for pointing at fsl_guts_rcw_rmw() when I
tried to prime the override registers from the RCW instead:
https://github.com/nxp-qoriq/rcw/pull/8

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Changes in v3:
- dt-bindings, dts: the pad-mux child is bus-addressed like the
  clock-controller child of the LS1028A dcfg: its reg is the RCWSR12
  to RCWSR14 window, under #address-cells, #size-cells and ranges on
  the dcfg node, the override registers stay the DCSR view of the
  parent (Krzysztof Kozlowski)
- cover letter: patch 4 cannot be applied without patch 3 (Linus Walleij)
- Patches 3 and 4 are unchanged
- Link to v2: https://lore.kernel.org/r/20261103-for-upstream-lx2160a-rcw-pinmux-v1-v2-0-3aad0860b984@free.fr

Changes in v2:
- dt-bindings: list, for each function, the groups, so the
  schema refuses the associations the driver refuses (Frank Li)
- Patches 2 to 5 are unchanged
- Link to v1: https://lore.kernel.org/r/20261103-for-upstream-lx2160a-rcw-pinmux-v1-v1-0-0a61a9837744@free.fr

---
Vincent Jardin (5):
      dt-bindings: pinctrl: add the NXP LX2160A RCW pad mux
      dt-bindings: soc: fsl: layerscape-dcfg: add the LX2160A pad-mux child
      soc: fsl: guts: add the RCW override of any RCWSR
      pinctrl: freescale: add the LX2160A RCW pad-mux driver
      arm64: dts: lx2160a: describe the pad muxes as the DCFG RCW override

 .../bindings/pinctrl/fsl,lx2160a-rcw-pinmux.yaml   | 264 +++++++++++++++
 .../bindings/soc/fsl/fsl,layerscape-dcfg.yaml      |  18 +
 MAINTAINERS                                        |   7 +
 arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi      | 377 +++++++++++----------
 drivers/pinctrl/freescale/Kconfig                  |  15 +
 drivers/pinctrl/freescale/Makefile                 |   1 +
 drivers/pinctrl/freescale/pinctrl-lx2160a.c        | 355 +++++++++++++++++++
 drivers/soc/fsl/guts.c                             |  73 ++++
 include/linux/fsl/guts.h                           |   3 +
 9 files changed, 938 insertions(+), 175 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261103-for-upstream-lx2160a-rcw-pinmux-v1-31f9ad97dc86

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

