From: Larisa Grigore <larisa.grigore@oss.nxp.com>
Subject: [PATCH v11 00/14] Add S32N79RDB UFS support
Date: Sat, 14 Nov 2026 12:55:32 +0100
Message-Id: <20261114-b4-ufs-s32n7-v11-0-dc36e11919d5@oss.nxp.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADdM+GoC/yWMQQqDMBAAvyJ77oIbNSl+pXhI7KrrIS1ZFUH8e
 1M9zsDMAcpJWKEtDki8iconZiB6FNBPPo6M8s4CTGksEdUYalwHRa1MdBiezlamsey9g5x8Ew+
 yX79Xd7OuYeZ++T/gPH+mTF1pcQAAAA==
X-Change-ID: 20261114-b4-ufs-s32n7-b8763256eaa7
To: "Martin K. Petersen" <mkp@kernel.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, Bart Van Assche <bvanassche@acm.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Rob Herring <robh@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>
Cc: devicetree@vger.kernel.org, Ajay Neeli <ajay.neeli@amd.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, linux-arm-msm@vger.kernel.org, 
 Peter Wang <peter.wang@mediatek.com>, linux-kernel@vger.kernel.org, 
 NXP S32 Linux Team <s32@nxp.com>, Asutosh Das <quic_asutoshd@quicinc.com>, 
 linux-arm-kernel@lists.infradead.org, Stanley Jhu <stanleyjhu@google.com>, 
 Frank Li <Frank.Li@nxp.com>, imx@lists.linux.dev, 
 linux-scsi@vger.kernel.org, Bean Huo <beanhuo@micron.com>, 
 linux-mediatek@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 Pedro Sousa <pedrom.sousa@synopsys.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, eballetb@redhat.com, 
 Peter Griffin <peter.griffin@linaro.org>, echanude@redhat.com, 
 Chaotian Jing <chaotian.jing@mediatek.com>, 
 Yoshihiro Shimoda <yoshihiro.shimoda.uh@renesas.com>, 
 Sai Krishna Potthuri <sai.krishna.potthuri@amd.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, linux-rockchip@lists.infradead.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, clizzi@redhat.com, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Heiko Stuebner <heiko@sntech.de>, Matthias Brugger <matthias.bgg@gmail.com>, 
 Chunyan Zhang <zhang.lyra@gmail.com>, Can Guo <can.guo@oss.qualcomm.com>, 
 Orson Zhai <orsonzhai@gmail.com>, aruizrui@redhat.com, 
 linux-renesas-soc@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794657368; l=16666;
 i=larisa.grigore@oss.nxp.com; s=20261114; h=from:subject:message-id;
 bh=Z2ebGh0OO+u6N438XmaUV9uV7rHt73kB6jypnvtGAAk=;
 b=FVby0cBFzH73DWJzbfFCHut2lJ/4tHOdL+sKwVHHSXgc/kP+umI1OYjqu9NrAD3211rRTNUKb
 GSgobxMA08FA+hZnpQ5QtcGxdy21cmxqYATAUaJcoKgRgwxcoLjzmfI
X-Developer-Key: i=larisa.grigore@oss.nxp.com; a=ed25519;
 pk=Jpt52sb6ETKTtvWjUzhz5Sv5FjB9AEg9QKCcbpWFx3w=
X-Endpoint-Received: by B4 Relay for larisa.grigore@oss.nxp.com/20261114 with auth_id=1522
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the UFS host controller found on the NXP S32N79
platform. The controller is based on the Synopsys DesignWare (DWC) UFS host
architecture and requires S32N79-specific M-PHY initialization/calibration
sequence. It is compliant with JESD-223D "Universal Flash Storage Host
Controller Interface" v3.0, and supports up to HS-Gear 4 speed grade. It is
compatible with UFS 2.1, 3.0 and 3.1 devices. The MIPI UniPro is compliant with
"MIPI Alliance Specification for Unified Protocol", v1.8. The MIPI M-PHY is
compliant to version 4.1.

In order to keep the S32N79 platform driver small and avoid duplicating common
DWC code across platform glue drivers, the series also refactors and exports a
few reusable DWC helpers. In particular, M-PHY CREG (CBCREG*) register access
helpers and the shared M-PHY CR bitfield definitions are moved from the
existing AMD Versal2 glue driver into the common ufshcd-dwc layer, and are then
used by the platform drivers. The series also introduces a generic Hibern8
TX-FSM polling helper so that multiple platforms can reuse the same pre-link
checks.

Device tree binding documentation for the S32N79 UFS controller is included.
The SoC and board DTS updates that instantiate and enable the controller are
no longer part of this series and will be posted separately.

Changes in v11:

ufs: dwc: Move shared M-PHY CR bitfield macros to ufshcd-dwc.h:
- New patch. Move the FAST_FLAGS, FW_CALIB_CCFG, RX_OVRD_IN_1 and RX_PCS_OUT
  bitfield macros from the AMD Versal2 driver to ufshcd-dwc.h, so the S32N7
  driver can use them instead of raw values.

ufs: pltfrm: Add a flags argument to ufshcd_pltfrm_init():
- New patch. Let glue drivers request optional behavior from the common
  platform code. All existing callers pass 0, no functional change.

ufs: pltfrm: Add a flag to manage fixed rate clocks:
- New patch. Add UFSHCD_PLTFRM_FIXED_RATE_CLKS. When it is set and neither
  freq-table-hz nor operating-points-v2 is present, register the clocks
  listed in clock-names with a 0 Hz min/max rate, so the UFS core enables
  and gates them without scaling. This replaces the dummy single 0 Hz
  operating-points-v2 table used in v10.

dt-bindings: ufs: Add NXP S32N79 UFS host controller:
- Dropped operating-points-v2 from the required properties and the OPP
  table from the example, the fixed rate core clock is now handled by
  UFSHCD_PLTFRM_FIXED_RATE_CLKS.
- Reworded the commit message accordingly.

ufs: s32n7: Add NXP S32N79 UFS host controller driver:
- Pass UFSHCD_PLTFRM_FIXED_RATE_CLKS to ufshcd_pltfrm_init() so the UFS
  core manages the fixed rate "core" clock without an OPP table.
- Also clear the DWC BUSTHRTL clock gating enable (CGE) after each HCE
  enable, as clock gating is not supported on this platform. Added the
  DWC_UFS_BUSTHRTL_CGE definition to ufshci-dwc.h.
- Moved the local N_DeviceID programming from the link startup POST_CHANGE
  to the PRE_CHANGE hook, before DME_LINKSTARTUP, as in the recommended
  sequence. Kept the local-only CPort 0 setup instead of
  ufshcd_dwc_connection_setup(), which programs different settings (it
  clears the host N_DeviceID_valid and sets the device T_PeerDeviceID
  to 1). This additional context is provided here rather than in the commit
  message, as it explains why the suggested alternative was not used rather
  than the change itself.
- Defined the CBREFCLKCTRL2 ref_clk_en_unipro and ref_clk_en_app override
  enable bits in ufshcd-dwc.h, next to the existing ref_clk_gating_support
  one.
- Embedded the variant ops in struct s32n7_soc_data and recovered the SoC data
  in init() with container_of_const(), so device_get_match_data() is only
  called once, in probe().
- Documented why SCM_STATUS is first written back to its reset value: each
  M-PHY start-up sequence must start with the PHY in reset, and the PHY may
  still be running on the host reset / error recovery paths.
- Replaced the raw M-PHY values with the shared bitfield macros, including
  the CBREFCLKCTRL2 override enable bits.
- Updated the commit message for the CGE and fixed rate clock changes.
- Dropped the Reviewed-by tag of Frank Li.

- Link to v10: https://lore.kernel.org/all/20261103133215.1385823-1-larisa.grigore@oss.nxp.com/

Changes in v10:

All patches:
- Dropped the "scsi:" subject prefix.

ufs: core: Return a negative errno from WLUN suspend/resume:
- New patch. __ufshcd_wl_suspend() and __ufshcd_wl_resume() may return a
  positive result code, e.g. from ufshcd_link_startup(). The runtime PM core
  treats it as a failure, but rpm_get_suppliers() only checks for a negative
  value, so the LUs consuming the WLUN are reported as resumed while the host
  is in the error state. Convert positive values to -EIO at the WLUN PM
  callback boundary, as ufshcd_init() already does. This replaces the
  Fixes: rationale previously carried by the dwc link_is_up() patch and
  covers every source of positive values, not only the DWC glue.

ufs: dwc: Return a negative error if the link is down:
- Dropped the Fixes: tag. The PM-boundary issue is now fixed in the core;
  this patch is a cleanup so the helper returns an errno before it is
  exported.

ufs: unipro: Add TX/RX FSM state attributes:
- Fixed the commit message: AMD Versal2 has no header with these
  definitions, only users in the .c file.

ufs: core: Add common Hibern8 TX FSM polling helper:
- Changed the subject prefix from "ufs: host:" to "ufs: core:".
- Fixed the helper name in the commit message.
- Renamed the internal per-lane poller from ufshcd_poll_tx_hibern8_lanes()
  to ufshcd_tx_lanes_in_hibern8().
- Log the TX_FSM_STATE of each lane that did not reach Hibern8 on timeout.
- Moved the prototype to the non-extern declarations and dropped "extern".
- Report a positive UIC result from DME_GET as -EIO, so the helper really
  returns a negative errno as documented.
- Fixed checkpatch --strict alignment checks.
- Dropped the Reviewed-by tags of Frank Li and Stanley Jhu, as the patch
  changed significantly.

ufs: dwc: Move Versal2 M-PHY CREG access helpers into ufshcd-dwc:
- Reworded the commit message and explained the static array race.
- Use the "name() - description" kernel-doc style like the rest of the
  file.

dt-bindings: ufs: Add NXP S32N79 UFS host controller:
- Restricted lanes-per-direction to 2, matching the driver.
- Explained in the commit message why clock-names and the single 0 Hz
  operating-points-v2 entry are required.

ufs: s32n7: Add NXP S32N79 UFS host controller driver:
- Changed the subject prefix to "ufs: s32n7:".
- Added <linux/bitfield.h> and <linux/bits.h>.
- Reject lanes-per-direction other than 2.
- Dropped redundant error messages and the remove() wrapper.
- Used u32 for the ufshcd_dme_get() result, aligned register offset style,
  clarified the SCM_STATUS comments.
- Documented the PERFORM_LINK_STARTUP_ONCE quirk and spm_lvl in the commit
  message, and updated the HS rate-select bullet.
- Documented in the commit message that the DWC BUSTHRTL power gating is
  disabled because it is not supported on this platform.

Changes in v9:

ufs: unipro: Move Tx/Rx FSM state definitions to unipro.h:
- Prefixed the RX_STATE_* and TX_STATE_* enum constants with UFS_ to avoid
  polluting the global namespace, and updated the existing users
  (AMD Versal2, HiSilicon, Qualcomm).

ufs: host: Add common Hibern8 TX FSM polling helper:
- Use the renamed UFS_TX_STATE_HIBERN8 constant.

dt-bindings: ufs: Add NXP S32N79 UFS host controller:
- Added Reviewed-by: Frank Li.

MAINTAINERS: Add NXP S32N7 UFS host controller entry:
- Added the imx@lists.linux.dev mailing list.

arm64: dts: freescale: s32n79: Add UFS host controller:
arm64: dts: freescale: s32n79-rdb: Enable UFS:
- Dropped from this series, as requested; they will be sent separately.

Changes in v8:

ufs: host: Add common Hibern8 TX FSM polling helper:
- Added Reviewed-by: Stanley Jhu.

scsi: ufs: Add NXP S32N79 UFS host controller driver:
- Let the UFS core manage the core reference clock: declare it in DT via
  clock-names/operating-points-v2 so the core adds it to hba->clk_list_head
  and gates it across system suspend and runtime idle. Dropped the manual
  devm_clk_get_enabled() and the struct s32n7_ufs core_clk member, and now
  read the clock rate from the core clock list.
- Dropped the ufs_s32n7_calculate_us_tick() wrapper and inlined the division.
- Dropped the unused struct s32n7_ufs hba member.

dt-bindings: ufs: Add NXP S32N79 UFS host controller:
- Added the required clock-names and operating-points-v2 properties.
- Dropped the Reviewed-by and Acked-by tags.

arm64: dts: freescale: s32n79: Add UFS host controller:
- Added clock-names = "core" and an operating-points-v2 table with
  opp-hz = <0> (fixed-rate clock) so the UFS core manages (and gates) the
  core reference clock.

Changes in v7:

scsi: ufs: Add NXP S32N79 UFS host controller driver:
- Wrapped .prepare/.complete in pm_sleep_ptr() instead of pm_ptr().
- Fixed code alignment issues.

Changes in v6:

scsi: ufs: dwc: Return a negative error if the link is down:
- Translate a positive UIC command result from ufshcd_dme_get() into -EIO.
- Declare dme_result as u32 to match the ufshcd_dme_get() parameter type.

scsi: ufs: dwc: Sort CBCRCTRL and CBREFCLKCTRL2 by offset:
- Added Reviewed-by: Frank Li.

scsi: ufs: Add NXP S32N79 UFS host controller driver:
- Added Reviewed-by: Frank Li.

Changes in v5:

scsi: ufs: dwc: Sort CBCRCTRL and CBREFCLKCTRL2 by offset:
- New patch. Split the macro reorder into its own cleanup.

ufs: host: Add common Hibern8 TX FSM polling helper:
- Return the real poller error on timeout, not a forced -ETIMEDOUT.

dt-bindings: ufs: Add NXP S32N79 UFS host controller:
- Dropped the jedec,ufs-2.0 fallback.
- Removed the select: block and the clocks description.

scsi: ufs: Add NXP S32N79 UFS host controller driver:
- Documented the timeout values as driver-defined bounds.
- Wrapped .prepare/.complete in pm_ptr().

arm64: dts: freescale: s32n79: Add UFS host controller:
- Dropped the jedec,ufs-2.0 fallback.

Changes in v4:

scsi: ufs: dwc: Return a negative error if the link is down:
- New patch. ufshcd_dwc_link_is_up() now returns a negative errno on failure
  instead of a positive value.

ufs: unipro: Move Tx/Rx FSM state definitions to unipro.h
- Added Reviewed-by: Frank Li.

ufs: host: Add common Hibern8 TX FSM polling helper:
- Refactored ufshcd_dme_check_tx_hibern8() to use read_poll_timeout().

scsi: ufs: Move Versal2 M-PHY CREG access helpers into ufshcd-dwc:
- Added Reviewed-by: Frank Li.

dt-bindings: ufs: Add NXP S32N79 UFS host controller:
- Added Reviewed-by: Frank Li.

Changes in v3:

ufs: host: Add common Hibern8 TX FSM polling helper:
- Use -EAGAIN while polling and only normalize to -ETIMEDOUT on timeout, so
  real attribute-read errors are returned instead of masked.
- Drop the stray delay.h include in ufshcd-pltfrm.c; the helper lives in
  ufshcd.c.
- Drop the now-redundant dev_err() after the check in the HiSilicon driver.

scsi: ufs: Add NXP S32N79 UFS host controller driver:
- Use devm_clk_get_enabled() to enable the core reference clock.
- Rename the family-level identifiers from the s32n_ prefix to s32n7_
  (structs and functions), keeping the s32n79_ prefix only for the
  chip-specific data.

Changes in v2:

ufs: unipro: Move Tx/Rx FSM state definitions to unipro.h:
- Improved the enum comments. They now cite the MIPI M-PHY v6.0 tables.

ufs: unipro: Add TX/RX FSM state attributes:
- Added Reviewed-by: Frank Li.

ufs: host: Add common Hibern8 TX FSM polling helper:
- Moved the helper into the UFS core (ufshcd.c).
- Split out an inner per-lane poller, ufshcd_poll_tx_hibern8_lanes().
- Expanded the commit message to document the -ETIMEDOUT normalization done
  when converting the qcom/hisi checks to the helper. No code behaviour change.

scsi: ufs: Move Versal2 M-PHY CREG access helpers into ufshcd-dwc:
- Made the DME attribute arrays const. They are now initialized inline instead
  of by later field assignments.

scsi: ufs: dwc: Export common clock divider and link status helpers:
- Added Reviewed-by: Frank Li.

dt-bindings: ufs: Add NXP S32N79 UFS host controller:
- Renamed the patch subject and simplified the commit message.
- Renamed the binding file to nxp,s32n79-ufshc.yaml so it matches the
  nxp,s32n79-ufshc compatible string.
- Removed the nxp,mphy-boot-mode property.
- Made reg-names and clocks required.
- Removed the conditional if/then/else schema.
- Removed clock-names.
- Changed the compatible from jedec,ufs-3.0 to jedec,ufs-2.0.
- Updated the example clocks to <&clks 0x92>.

scsi: ufs: Add NXP S32N79 UFS host controller driver:
- Removed the nxp,mphy-boot-mode handling and the mphy_boot_mode enum. The
  M-PHY firmware always runs from ROM now.
- Added a struct s32n_soc_data for SoC match data.
- Moved the calibration writes out to static const tables.
- Renamed struct phy_reg_cfg to s32n_phy_reg.
- Moved the rate-select sequence out of link_startup_post_change() into a new
  pwr_change_notify() pre-change path.
- Used devm_clk_get(dev, NULL) and dropped the redundant core_clk NULL check.
- Switched to *_PM_OPS() macros and pm_ptr() for the PM ops.
- Clarified the Hibern8 poll timeout comment.
- Enabled Auto-Hibern8 instead of setting UFSHCD_QUIRK_BROKEN_AUTO_HIBERN8.
- Reworked and improved the M-PHY initialization sequence.

arm64: dts: freescale: s32n79: Add UFS host controller:
- Changed the compatible from jedec,ufs-3.0 to jedec,ufs-2.0.
- Removed clock-names.

arm64: dts: freescale: s32n79-rdb: Enable UFS:
- Removed the nxp,mphy-boot-mode property.

Signed-off-by: Larisa Grigore <larisa.grigore@oss.nxp.com>
---
Larisa Grigore (14):
      ufs: core: Return a negative errno from WLUN suspend/resume
      ufs: dwc: Return a negative error if the link is down
      ufs: unipro: Move Tx/Rx FSM state definitions to unipro.h
      ufs: unipro: Add TX/RX FSM state attributes
      ufs: core: Add common Hibern8 TX FSM polling helper
      ufs: dwc: Move Versal2 M-PHY CREG access helpers into ufshcd-dwc
      ufs: dwc: Export common clock divider and link status helpers
      ufs: dwc: Sort CBCRCTRL and CBREFCLKCTRL2 by offset
      ufs: dwc: Move shared M-PHY CR bitfield macros to ufshcd-dwc.h
      ufs: pltfrm: Add a flags argument to ufshcd_pltfrm_init()
      ufs: pltfrm: Add a flag to manage fixed rate clocks
      dt-bindings: ufs: Add NXP S32N79 UFS host controller
      ufs: s32n7: Add NXP S32N79 UFS host controller driver
      MAINTAINERS: Add NXP S32N7 UFS host controller entry

 .../devicetree/bindings/ufs/nxp,s32n79-ufshc.yaml  |  58 +++
 MAINTAINERS                                        |   9 +
 drivers/ufs/core/ufshcd.c                          | 101 +++-
 drivers/ufs/host/Kconfig                           |  12 +
 drivers/ufs/host/Makefile                          |   1 +
 drivers/ufs/host/cdns-pltfrm.c                     |   2 +-
 drivers/ufs/host/tc-dwc-g210-pltfrm.c              |   2 +-
 drivers/ufs/host/ufs-amd-versal2.c                 | 106 +---
 drivers/ufs/host/ufs-exynos.c                      |   2 +-
 drivers/ufs/host/ufs-hisi.c                        |  50 +-
 drivers/ufs/host/ufs-hisi.h                        |   6 -
 drivers/ufs/host/ufs-mediatek.c                    |   2 +-
 drivers/ufs/host/ufs-nxp-s32n7.c                   | 546 +++++++++++++++++++++
 drivers/ufs/host/ufs-qcom.c                        |  44 +-
 drivers/ufs/host/ufs-qcom.h                        |   2 -
 drivers/ufs/host/ufs-renesas.c                     |   2 +-
 drivers/ufs/host/ufs-rockchip.c                    |   2 +-
 drivers/ufs/host/ufs-sprd.c                        |   2 +-
 drivers/ufs/host/ufshcd-dwc.c                      |  86 +++-
 drivers/ufs/host/ufshcd-dwc.h                      |  50 +-
 drivers/ufs/host/ufshcd-pltfrm.c                   |  61 ++-
 drivers/ufs/host/ufshcd-pltfrm.h                   |  12 +-
 drivers/ufs/host/ufshci-dwc.h                      |   8 +
 include/ufs/ufshcd.h                               |   2 +
 include/ufs/unipro.h                               |  22 +
 25 files changed, 949 insertions(+), 241 deletions(-)
---
base-commit: 7e1392a42ea288d70a266f6553fe06f57f8647ea
change-id: 20261114-b4-ufs-s32n7-b8763256eaa7

Best regards,
--  
Larisa Grigore <larisa.grigore@oss.nxp.com>

