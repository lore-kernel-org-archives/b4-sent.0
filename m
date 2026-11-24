From: Sai Sree Kartheek Adivi <s-adivi@ti.com>
Subject: [PATCH v13 00/20] dmaengine: ti: Add support for BCDMA v2 and
 PKTDMA v2
Date: Tue, 24 Nov 2026 17:15:02 +0530
Message-Id: <20261124-dma-upstream-v13-v13-0-bd4251fdc6d4@ti.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL94BWsC/yWMyQqDQBAFf0X6nIbMTBbIr4iHWZ5JB1yYVhHEf
 89ojlVQtZEiC5Re1UYZi6gMfQHjLhXFj+/fYElFkL3ahzH2xqnzPI86ZfiOF+M4xSfuMXiE4Kh
 kY0Yr6/msmz/rHL6I0/Ghff8BMOWYdnUAAAA=
X-Change-ID: 20261124-dma-upstream-v13-dc7e5cbaebb3
To: Vignesh Raghavendra <vigneshr@ti.com>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>, Peter Ujfalusi <peter.ujfalusi@ti.com>, 
 Nishanth Menon <nm@ti.com>, Santosh Shilimkar <ssantosh@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 sebin.francis@ti.com, Sai Sree Kartheek Adivi <s-adivi@ti.com>, 
 Frank Li <Frank.Li@nxp.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795520723; l=13523;
 i=s-adivi@ti.com; s=20261124; h=from:subject:message-id;
 bh=iFhIzxAr+gUUwU2I2PBUuKuVS1d+KKY2AE2XqozO4+Q=;
 b=lgKY7DF0J0trH/Z1Uz8tLCVBOVuFjkhCAPKK/z1HdDNRyqSwd3OjWV9cpZqHK2lgsNGTkgpUw
 zDRqXb2BEELCrN3faH6bfqjAci8xaqsq1SFBrTth+N8IyX89dioXsgt
X-Developer-Key: i=s-adivi@ti.com; a=ed25519;
 pk=EtOwVxmXDuYMgw3DqFtPDBpf8ZvbO89w1fJm4w5yPI8=
X-Endpoint-Received: by B4 Relay for s-adivi@ti.com/20261124 with auth_id=1627
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the BCDMA_V2 and PKTDMA_V2 which is
introduced in AM62L.

The key differences between the existing DMA and DMA V2 are:
- Absence of TISCI: Instead of configuring via TISCI calls, direct
  register writes are required.
- Autopair: There is no longer a need for PSIL pair and instead AUTOPAIR
  bit needs to set in the RT_CTL register.
- Static channel mapping: Each channel is mapped to a single peripheral.
- Direct IRQs: There is no INT-A and interrupt lines from DMA are
  directly connected to GIC.
- Remote side configuration handled by DMA. So no need to write to PEER
  registers to START / STOP / PAUSE / TEARDOWN.
- Unified Channel Space: Tx and Rx channels share a single register
  space. Each channel index is specifically fixed in hardware as either
  Tx or Rx in an interleaved manner.

Full tree with device tree patches can be reviewed at:
https://github.com/sskartheekadivi/linux/tree/dma-upstream-v13

Changes from v12 to v13:
- Rebase to next-20261123. No functional changes.
- [10/20], [17/20], [18/20]: Use the new devm_kzalloc_obj()/_objs()
  helpers instead of devm_kcalloc()/devm_kzalloc(), following the
  treewide conversion that happened after v12. Reviewed-by tags carried
  over. The only change is the API conversions.
link to v12:
https://lore.kernel.org/all/20261007102936.2402427-1-s-adivi@ti.com/

Changes from v11 to v12:
- [11/20]: Split into a pure #include move with no functional change,
  and a new patch [12/20] for the module-pinning logic, since the
  commit message claimed "No functional changes intended" while also
  adding try_module_get()/xudma_dev_put().
- [12/20] (new): Pin the owning module in of_xudma_dev_get() via
  try_module_get(); add xudma_dev_put(), called from
  k3_udma_glue_release_tx_chn()/release_rx_chn().
- [13/20]: Use readl_poll_timeout_atomic() in the non-TISCI branch of
  k3_ringacc_ring_reset_sci(), since it can run under uc->vc.lock
  (including from hardirq context) via K3 UDMA V2's autopair-timeout
  cleanup.
- [17/20]: Add of_dma_controller_free() and
  cancel_work_sync(&ud->purge_work) to udma_v2_remove(); add
  udma_teardown_rx_flush() and call it there to unmap the rx_flush
  buffers. Only compute rflow->reg_rt in udma_v2_probe() when
  ud->rflow_rt is mapped. Revert channel coherency on the
  err_ringcfg path in udma_v2_alloc_tx_resources()/
  udma_v2_alloc_rx_resources(), matching the bchan allocator.
- [1/20]: Reword commit message - the fix is currently a no-op since
  every existing struct field is already assigned; it hardens
  against a base_rt field added later by [13/20].
link to v11:
https://lore.kernel.org/all/20261001084105.1692228-1-s-adivi@ti.com/

Changes from v10 to v11:
- [5/19], [8/19]: Restore seq_puts() for plain strings in
  udma_dbg_summary_show_chan(), reverting an accidental change to
  seq_printf().
- [10/19]: Fail bcdma/pktdma_setup_resources() with -EINVAL instead of
  skipping SCI resource setup when the sci_resources hook is NULL on
  K3_UDMA_V1.
- [11/19]: Pin the owning module in of_xudma_dev_get() via
  try_module_get(); add xudma_dev_put(), called from
  k3_udma_glue_release_tx_chn()/release_rx_chn().
- [12/19]: Fix k3_ringacc_ring_free_sci() to actually wait for SIZE to
  clear before programming the new count, and bail on timeout; require
  TI_SCI_INTA_MSI_DOMAIN for a DT-probed ringacc with ti,sci.
- [15/19]: Take ep_map_mutex around the ep_config memcpy in
  psil_set_new_ep_config(); log by channel ID when the lookup is
  channel-ID based.
- [16/19]: Add TI_SCI_INTA_IRQCHIP dependency, allow COMPILE_TEST, set
  ddev.owner, add udma_v2_remove(); move udma_reset_rings() before IRQ
  request; free uc->desc on a start timeout instead of leaking it;
  simplify udma_v2_ring_irq_handler() to avoid double-completing a
  descriptor.
- [17/19]: Use uc->tchan->tflow_id / uc->rflow->id instead of
  mapped_channel_id for the per-flow ring IRQ lookup, matching the
  glue layer.
- [18/19]: Fix inverted epib/psdata_size checks in the no-TISCI RX
  config path of k3_udma_glue_cfg_rx_chn().
- Fix issues reported by Sashiko introduced by this series.
- Pick up Reviewed-by tags from v10 (14/19, 15/19, 16/19, 19/19).
link to v10:
https://lore.kernel.org/all/20260928025749.1055383-1-s-adivi@ti.com/

Changes from v9 to v10:
- [12/19]: Clear the ring size before the base address registers and
  disable the ring's interrupts (INT_ENABLE_CLR) on free, mirroring
  the enable done on config.
- [15/19]: Validate dma-cells count before indexing dma_spec.args[] in
  the pktdma/bcdma paths; fix thread ID used in the error log.
- [16/19]: Check devm_kasprintf() return value in probe; clear
  uc->chan in all three put functions to avoid a dangling alias;
  return IRQ_HANDLED instead of IRQ_NONE when a TR interrupt was
  actually serviced; fix -ENOENT return from an irqreturn_t function;
  drop a duplicate UDMA_CHAN_RT_CTL_REG write.
- [17/19]: Drop the unused pktdma_v2_driver forward declaration and
  its filter check; pass bool instead of the DMA_TYPE_PKTDMA enum to
  psil_get_ep_config_by_id().
- [18/19]: Apply tx_pause_on_err/tx_supr_tdpkt in the no-TISCI TX
  config path and rx_error_handling in the no-TISCI RX flow path;
  flush the peer before TDOWN in TX teardown, matching RX.
- Fix issues reported by Sashiko which are introduced by this series
  https://sashiko.dev/#/patchset/20260922064902.2719979-1-s-adivi@ti.com
  (12/19, 15/19, 16/19, 17/19, 18/19)
link to v9:
https://lore.kernel.org/all/20260922064902.2719979-1-s-adivi@ti.com/ 

Changes from v8 to v9:
- [01/19]: Add Fixes tag (Frank Li).
- [05/19]: Drop redundant "default n" on TI_K3_UDMA_COMMON (Vignesh).
- [12/19]: Poll for SIZE to clear instead of an unverified comment,
  rename ring2 to fwd_ring, take an explicit status mask in
  k3_ringacc_ring_clear_irq() (Vignesh).
- [13/19], [14/19]: Both carry an extra fix beyond what Krzysztof
  reviewed in v7 (minItems on interrupt-names had to come back). should
  have said so in v8's changelog, sorry about that. Krzysztof re-tagged
  13/19 in v8; 14/19 has no tag since it hasn't been re-reviewed.
- Fix issues reported by Sashiko which are introduced by this series
  https://sashiko.dev/#/patchset/20260810151423.1948224-1-s-adivi@ti.com
  (09/19, 12/19, 15/19, 16/19, 17/19, 18/19)
link to v8:
https://lore.kernel.org/all/20260810151423.1948224-1-s-adivi@ti.com/

Changes from v7 to v8:
- Fix issues reported by Sashiko which are introduced by this series
  https://sashiko.dev/#/patchset/20260724102115.2854-1-s-adivi@ti.com
- Remove minItems for interrupts entry in both BCDMA and PKTDMA
  dt-bindings
- Update interrupt-names pattern for pktdma from tflow-<n>/rflow-<n> to
  tx-<n>/rx-<n>.
link to v7:
https://lore.kernel.org/all/20260724102115.2854-1-s-adivi@ti.com/

Changes from v6 to v7:
- Rebase to next-20260721
- [03/19]: Add missing includes
- Fix incorrect register bits used when configuring rx flows.
  Add correct UDMA_CHAN_CFG_FILT_EINFO/PSWORDS and
  UDMA_FLOWRT_RFA_RX_EINFO/PSINFO_PRESENT bit definitions.
- Update AM62L BCDMA and PKTDMA dt bindings to remove address cells,
  redefine dma-cells semantics (mapped channel id for bcdma, hardware
  flow id for pktdma) and fully enumerate interrupts/interrupt-names
  with restricted naming patterns.
- Add fifo select register write support for XYMF channels in the BCDMA
  v2 driver. Update udma_v2_filter_param to use channel id instead of
  remote thread id and resolve it via psil_get_ep_config_by_id().
- Switch channel resource bitmap allocation to devm_bitmap_zalloc() and
  ring IRQ registration to request_irq()+IRQF_SHARED (channels can now
  share a PSI-L/IRQ line); fix the ring IRQ handler to return IRQ_NONE
  for spurious/foreign interrupts instead of unconditionally claiming
  them.
link to v6:
https://lore.kernel.org/all/20260428085202.1724548-1-s-adivi@ti.com/

Changes from v5 to v6:
- Switch from interrupt-map to interrupts and interrupt-names in the
  dt-bindings.
- Reverse the if DMA version checks to check for v1 and else v2.
- Add new patch [01/19] before refactoring to fix sporadic crash
  observed on AM62x.
link to v5:
https://lore.kernel.org/all/20260218095243.2832115-1-s-adivi@ti.com/

Changes from v4 to v5:
- Introduce a new version variable in udma_match_data to differentiate
  between K3 UDMA V1 and K3 UDMA V2. This simplifies the approach for
  adding any future possible variants avoiding complex if conditions.
- Fix both K3 BCDMA V2 and PKTDMA V2 dt bindings as per the comments
  from previous versions.
- Fix minor nitpicks like following the reverse christmas tree order for
  variable declarations.
- Remove the patch [v4 19/19] that switches to synchronous descriptor
  freeing. With this patch, dma_free_coherent gets called in irq
  context and hence a WARN().
link to v4:
https://lore.kernel.org/all/20260130110159.359501-1-s-adivi@ti.com/

Changes from v3 to v4:
- Rename the dt-binding files to add "ti," prefix.
- Update cell description in dt-bindings and add client examples.
- Update k3_ring_intr_regs reg names
- Rename soc specific data to bcdma_v2_data and pktdma_v2_data to
  bcdma_v2_am62l_data and pktdma_v2_am62l_data.
- Add a new patch [18/19] to fix a null pointer dereference issue when
  trying to reserve a channel id that is out of bounds in
  udma_reserve_##res macro. Also fix logging issues in this macro.
- Add a new patch [19/19] to switch to synchronous descriptor freeing to
  avoid running out of memory during stress tests.
- Fix checkpatch warnings.
link to v3:
https://lore.kernel.org/linux-arm-kernel/20250623053716.1493974-1-s-adivi@ti.com

Changes from v2 to v3:
- Fix checkpatch errors & spellings.
link to v2:
https://lore.kernel.org/linux-arm-kernel/20250612071521.3116831-1-s-adivi@ti.com

Changes from v1 to v2:
- Split refactoring of k3-udma driver into multiple commits
- Fix bcdma v2 and pktdma v2 dt-binding examples
- Fix compatibles in k3-udma-v2.c
- move udma_is_desc_really_done to k3-udma-common.c as the difference
  between k3-udma and k3-udma-v2 implementation is minor.
- remove udma_ prefix to function pointers in udma_dev
- reorder the commits to first refactor the existing code completely and
  then introduce k3-udma-v2 related commits.
- remove redundant includes in k3-udma-common.c
- remove ti_sci_ dependency for k3_ringacc in Kconfig
- refactor setup_resources functions to remove ti_sci_ code from common
  logic.
link to v1:
https://lore.kernel.org/linux-arm-kernel/20250428072032.946008-1-s-adivi@ti.com

Signed-off-by: Sai Sree Kartheek Adivi <s-adivi@ti.com>
---
Sai Sree Kartheek Adivi (19):
      dmaengine: ti: k3-udma: move macros to header file
      dmaengine: ti: k3-udma: move structs and enums to header file
      dmaengine: ti: k3-udma: move static inline helper functions to header file
      dmaengine: ti: k3-udma: move descriptor management to k3-udma-common.c
      dmaengine: ti: k3-udma: move ring management functions to k3-udma-common.c
      dmaengine: ti: k3-udma: Add variant-specific function pointers to udma_dev
      dmaengine: ti: k3-udma: move udma utility functions to k3-udma-common.c
      dmaengine: ti: k3-udma: move resource management functions to k3-udma-common.c
      dmaengine: ti: k3-udma: refactor resource setup functions
      dmaengine: ti: k3-udma: move inclusion of k3-udma-private.c to k3-udma-common.c
      dmaengine: ti: k3-udma: pin owning module while glue clients hold a udma_dev
      drivers: soc: ti: k3-ringacc: handle absence of tisci
      dt-bindings: dma: ti: Add K3 BCDMA V2
      dt-bindings: dma: ti: Add K3 PKTDMA V2
      dmaengine: ti: k3-psil-am62l: Add AM62Lx PSIL and PDMA data
      dmaengine: ti: k3-udma-v2: New driver for K3 BCDMA_V2
      dmaengine: ti: k3-udma-v2: Add support for PKTDMA V2
      dmaengine: ti: k3-udma-v2: Update glue layer to support PKTDMA V2
      dmaengine: ti: k3-udma: Validate resource ID and fix logging in reservation

Vignesh Raghavendra (1):
      dmaengine: ti: k3-udma: Fix sporadic crash on AM62x

 .../bindings/dma/ti/ti,am62l-dmss-bcdma.yaml       |  211 ++
 .../bindings/dma/ti/ti,am62l-dmss-pktdma.yaml      |  189 ++
 drivers/dma/ti/Kconfig                             |   21 +-
 drivers/dma/ti/Makefile                            |    5 +-
 drivers/dma/ti/k3-psil-am62l.c                     |  169 ++
 drivers/dma/ti/k3-psil-priv.h                      |    5 +
 drivers/dma/ti/k3-psil.c                           |  106 +-
 drivers/dma/ti/k3-udma-common.c                    | 2643 +++++++++++++++++
 drivers/dma/ti/k3-udma-glue.c                      |  218 +-
 drivers/dma/ti/k3-udma-private.c                   |   53 +-
 drivers/dma/ti/k3-udma-v2.c                        | 1587 ++++++++++
 drivers/dma/ti/k3-udma.c                           | 3137 +-------------------
 drivers/dma/ti/k3-udma.h                           |  572 ++++
 drivers/soc/ti/k3-ringacc.c                        |  209 +-
 include/linux/dma/k3-psil.h                        |    3 +
 include/linux/soc/ti/k3-ringacc.h                  |   21 +
 16 files changed, 6085 insertions(+), 3064 deletions(-)
---
base-commit: 3191063649dbf7c0d0b768e1f3655e4c5fc6edb5
change-id: 20261124-dma-upstream-v13-dc7e5cbaebb3

Best regards,
--  
Sai Sree Kartheek Adivi <s-adivi@ti.com>

