From: Dang Huynh <dang.huynh@mainlining.org>
Subject: [PATCH v6 00/12] Rockchip VOP2 support
Date: Sat, 08 Nov 2025 12:37:56 +0700
Message-Id: <20251108-vop2-pt2-v6-0-d04c699262fb@mainlining.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADTXDmkC/2XMTW7DIBCG4atErEvFzPBTuso9oi4Mxgkb2wIXJ
 Yp89+JIFY4sVh+a532yHFIMmX2fniyFEnOcxjr0x4n5WzdeA4993QwFKgEgeZlm5POC3Cg1OLA
 WnNOsns8pDPH+Sl1+6r7FvEzp8SoX2H7/I7pFCnDBve211E6RJXFOMYff+XMMC9sqBZtEpJ3EK
 g2QEkF+oTVHSU1KwJ2kTXpjde+IVLAHKZusbydlleSMp85Bp8EcpGpSC7OTqkroFQ6mQz+Qf5P
 ruv4BK/wA9IkBAAA=
X-Change-ID: 20250114-vop2-pt2-755fb1991bb6
To: u-boot@lists.denx.de
Cc: Anatolij Gustschin <ag.dev.uboot@gmail.com>, 
 Simon Glass <sjg@chromium.org>, Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, Tom Rini <trini@konsulko.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, Alexander Graf <agraf@csgraf.de>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, Ondrej Jirman <megi@xff.cz>, 
 Ion Agorria <ion@agorria.com>, 
 Dario Binacchi <dario.binacchi@amarulasolutions.com>, 
 Dragan Simic <dsimic@manjaro.org>, 
 Patrice Chotard <patrice.chotard@foss.st.com>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, Jonas Karlman <jonas@kwiboo.se>, 
 Nicolas Frattaroli <frattaroli.nicolas@gmail.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>, 
 Piotr Zalewski <pZ010001011111@proton.me>, 
 Dang Huynh <dang.huynh@mainlining.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762580305; l=3255;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=o+iWdlsjjDKGHYbj1Zwg238nKZsLqOcUFA3sjXl34/E=;
 b=tnHPJVmw+v29dfMRlCh4UXGyw76jXFK1xEBniRl/6tpHjd/wePQnYh5UOEzvxHppI1tB+96Tj
 sKOJ8byCeOBCtljqK05pf/CNKwtfHgK/rJHCviY5ARiz1ly3kgkk15+
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds VOP2 support to U-Boot and enable it for PineTab2.

HDMI should work flawlessly but there's still some timings issue with
DW MIPI DSI, perhaps that's something to look into later.

Tested-by: Piotr Zalewski <pZ010001011111@proton.me>
Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
Changes in v6:
- Switch to mainlining.org email
- Link to v5: https://lore.kernel.org/r/20250607-vop2-pt2-v5-0-1d52f7a2cf3c@riseup.net

Changes in v5:
- Add check for invalid win_id value
- Link to v4: https://lore.kernel.org/r/20250505-vop2-pt2-v4-0-3b7c3ab1a617@riseup.net

Changes in v4:
- Remove unnecessary clk_enable() as VOP clocks are enabled by TF-A
- Adjust I2C clock configuration to match 24 MHz clock
- Reorganize VOP node order
- Link to v3: https://lore.kernel.org/r/20250412-vop2-pt2-v3-0-7c796db335e9@riseup.net

Changes in v3:
- Renaming prefix from "rkvop" to "rkvop2" and similar
- Win planes are platform-configurable
- Link to v2: https://lore.kernel.org/r/20250223-vop2-pt2-v2-0-71350e482970@riseup.net

Changes in v2:
- Get display timings from video bridge (requires [1])
- Disable esmart and post before booting to OS
- Enable avdd-0v9 and avdd-1v8 when probing HDMI.
- Link to v1: https://lore.kernel.org/r/20250116-vop2-pt2-v1-0-c9d646b53930@riseup.net

---
Dang Huynh (10):
      video: rockchip: dw-mipi-dsi: Depend on CONFIG_VIDEO_BRIDGE
      video: rockchip: dw-mipi-dsi: Add get_display_timing support
      video: Add BOE TH101MB31IG002-28A MIPI-DSI panel
      video: rockchip: Add VOP2 support
      video: rockchip: vop2: Add video bridge support
      arm: dts: rockchip: rk356x: Prerelocate VOP in U-Boot proper
      configs: quartz64: Enable vidconsole
      video: rockchip: Add HDMI support for RK3568
      configs: pinetab2-rk3566: Enable video and USB keyboard
      clk: rockchip: rk3568: Use assigned VPLL clock when possible

Ondrej Jirman (2):
      video: rockchip: dw_mipi_dsi: Improve pixel clock calculations
      video: rockchip: dw_mipi_dsi: Proceed when external PHY is not defined

 arch/arm/dts/rk356x-u-boot.dtsi                 |   4 +
 arch/arm/include/asm/arch-rockchip/vop_rk3568.h | 280 ++++++++++++
 configs/pinetab2-rk3566_defconfig               |  10 +
 drivers/clk/rockchip/clk_rk3568.c               |   6 +-
 drivers/video/Kconfig                           |  10 +
 drivers/video/Makefile                          |   1 +
 drivers/video/boe-th101mb31ig002-28a.c          | 236 ++++++++++
 drivers/video/rockchip/Kconfig                  |   2 +-
 drivers/video/rockchip/Makefile                 |   4 +-
 drivers/video/rockchip/dw_mipi_dsi_rockchip.c   |  45 +-
 drivers/video/rockchip/rk3568_hdmi.c            |  71 +++
 drivers/video/rockchip/rk3568_vop.c             | 260 +++++++++++
 drivers/video/rockchip/rk_vop2.c                | 557 ++++++++++++++++++++++++
 drivers/video/rockchip/rk_vop2.h                |  76 ++++
 include/configs/quartz64_rk3566.h               |   5 +-
 15 files changed, 1544 insertions(+), 23 deletions(-)
---
base-commit: 928af44314a1a086e946ef3c0901d40bdb3e19a9
change-id: 20250114-vop2-pt2-755fb1991bb6

Best regards,
-- 
Dang Huynh <dang.huynh@mainlining.org>

