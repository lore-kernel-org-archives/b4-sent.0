From: Jack Wu <jackbb_wu@compal.com>
Subject: [PATCH v3 0/7] net: wwan: t9xx: Add MediaTek T9XX WWAN driver
Date: Wed, 24 Jun 2026 18:04:06 +0800
Message-Id: <20260624-t9xx_driver_v1-v3-0-73ff03f60c48@compal.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJarO2oC/3WNWwrCMBREtyL5NpJH21i/3IdIyePGRrQtSQ2V0
 r2b1A8RES4MA3POnVEA7yCgw2ZGHqILru9S4dsN0q3sLoCdSR0xwipSshqP9TQ1xrsIvokUU1E
 Udi+tELxGCRo8WDetwtP53cNDXUGP2ZIXrQtj75/rx0jz7q88HcHKKAtMEwqlOOr+PsjbLgXK9
 sg+fEXJD88Sr6tSGmMZV9x+8cuyvACNvY/m/wAAAA==
X-Change-ID: 20260529-t9xx_driver_v1-1744f8af7739
To: Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Sergey Ryazanov <ryazanov.s.a@gmail.com>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Jack Wu <jackbb_wu@compal.com>, Wen-Zhi Huang <wen-zhi.huang@mediatek.com>, 
 Shi-Wei Yeh <shi-wei.yeh@mediatek.com>, 
 Minano Tseng <Minano.tseng@mediatek.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-doc@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782295454; l=13177;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=wkVjtgalCZbQSoIpv9CwBCZjvSYX3+Cp4uEVA8TMu7k=;
 b=jPZka2HnEi+K+CbV2Jywm3Mrp5Qd3gOkA5PmGzVD32JJuUfAPPdLYsawrAo9Hw8HHi2bSqKlz
 ssBbVetjNJQCqRBRstFy4adm0Ra8tfI7w9HHrdsaeH5TUTYXiEeiPjV
X-Developer-Key: i=jackbb_wu@compal.com; a=ed25519;
 pk=VH1prTWixNl8OEUPPSfII3p46MzJpQN8J3+ecE1tZXg=
X-Endpoint-Received: by B4 Relay for jackbb_wu@compal.com/20260526 with auth_id=793
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

T9XX is the PCIe host device driver for MediaTek's
t900 modem. The driver uses the WWAN framework
infrastructure to create the following control ports
and network interfaces for data transactions.
* /dev/wwan0at0 - Interface that supports AT commands.
* /dev/wwan0mbim0 - Interface conforming to the MBIM
  protocol.
* wwan0-X - Primary network interface for IP traffic.

The main blocks in the T9XX driver are:
* HW layer - Abstracts the hardware bus operations for
   the device, and provides generic interfaces for the
   transaction layer to get the device's information and
   control the device's behavior. It includes:

   * PCIe - Implements probe, removal and interrupt
     handling.
   * MHCCIF (Modem Host Cross-Core Interface) - Provides
     interrupt channels for bidirectional event
     notification such as handshake and port enumeration.

* Transaction layer - Implements data transactions for
   the control plane and the data plane. It includes:

   * DPMAIF (Data Plane Modem AP Interface) - Controls
     the hardware that provides uplink and downlink
     queues for the data path. The data exchange takes
     place using circular buffers to share data buffer
     addresses and metadata to describe the packets.
   * CLDMA (Cross Layer DMA) - Manages the hardware
     used by the port layer to send control messages to
     the device using MediaTek's CCCI (Cross-Core
     Communication Interface) protocol.
   * TX Services - Dispatch packets from the port layer
     to the device.
   * RX Services - Dispatch packets to the port layer
     when receiving packets from the device.

* Port layer - Provides control plane and data plane
   interfaces to userspace. It includes:

   * Control Plane - Provides device node interfaces
     for controlling data transactions.
   * Data Plane - Provides network link interfaces
     wwanX (0, 1, 2...) for IP data transactions.

* Core logic - Contains the core logic to keep the
   device working. It includes:

   * FSM (Finite State Machine) - Monitors the state
     of the device, and notifies each module when the
     state changes.

The compilation of the T9XX driver is enabled by the
CONFIG_MTK_T9XX and CONFIG_MTK_T9XX_PCI config option
which depends on CONFIG_WWAN.

This v2 submission covers the control plane only
(patches 1-6). The data plane will follow in a
separate series once the control plane is accepted.

---
Changes in v3:
- Address sashiko AI code review comments and fix sparse warnings
- Patch 1 (Add PCIe core):
  - Move extern declaration of mtk_dev_cfg_0900 from mtk_pci.c to mtk_pci.h to fix sparse warning
  - Remove mtk_pci_bar_exit(): pcim_iounmap_region() was called with bitmask instead of BAR index, and pcim_iomap_regions() is devres-managed so manual unmap is redundant [sashiko]
  - Remove pci_disable_device() from probe error path and remove path: pcim_enable_device() registers devres cleanup, manual disable causes enable_cnt underflow [sashiko]
- Patch 3 (Add control DMA interface):
  - Add #include "mtk_cldma.h" in mtk_cldma_drv_m9xx.c to fix sparse undeclared symbol warnings for mtk_cldma_regs_m9xx and cldma_drv_ops_m9xx
  - Move extern declaration of mtk_ctrl_info_m9xx from mtk_trans_ctrl.c to mtk_trans_ctrl.h to fix sparse undeclared symbol warning
  - Replace kcalloc + radix_tree_gang_lookup with radix_tree_for_each_slot() in mtk_ctrl_remove_radix_tree() to eliminate allocation in teardown path [sashiko]
  - Add missing mtk_pci_dev_exit() call in mtk_pci_remove() to properly clean up FSM and trans_ctrl resources before device removal [sashiko]
- Patch 4 (Add control port):
  - Replace kcalloc + radix_tree_gang_lookup with radix_tree_for_each_slot() and single-entry gang_lookup in mtk_port_tbl_destroy() to eliminate allocation failure in teardown path [sashiko]
  - Add port = NULL after mtk_port_put_locked() in mtk_port_internal_open() error path to prevent returning un-refcounted pointer [sashiko]
  - Restore skb_unlink + trb_complete for non-EAGAIN errors in mtk_ctrl_trb_handler() TX path to prevent infinite retry loop [sashiko]
- Patch 5 (Add FSM thread):
  - Check mtk_pci_register_irq() return value in mtk_cldma_dev_init() and add err_destroy_wq error label to fix unreachable dead code [sashiko]
  - Propagate specific error codes (ENOMEM/EIO/EINVAL) from mtk_cldma_dev_init() error paths instead of generic -EIO [sashiko]
  - Free head SKB after detaching frag_list in mtk_cldma_rxq_free() scatter-gather mode to fix memory leak [sashiko]
- Patch 6 (Add AT & MBIM WWAN ports):
  - Remove unused write_lock mutex from struct mtk_port and its mutex_init call [sashiko]
- Link to v2: https://patch.msgid.link/20260610-t9xx_driver_v1-v2-0-c65addf23b3f@compal.com

Changes in v2:
- Split series into control plane (this v2) and data plane (follow-up)
- Patch 1 (Add PCIe core):
  - Rename BAR_NUM to MTK_PCI_BAR_NUM for driver prefix consistency
  - Replace magic numbers in mtk_pci_setup_atr() with named defines
  - Remove redundant ATR register comments, use blank line separators
  - Add kernel-doc comments to all non-static functions
  - Convert 4 MMIO wrapper functions to static inline in header [sashiko]
  - Remove unnecessary unlikely() from IRQ validation paths
  - Add irq_cnt == 0 and irq_id < 0 guards in mtk_pci_get_virq_id() [sashiko]
  - Initialize hw_bits at declaration for consistency
  - Merge same-type variable declarations into single lines
  - Add #else/#endif comments for CONFIG_ACPI blocks
  - Add newlines in mtk_pci_pldr() for readability
  - Move return into default case in mtk_pci_dev_reset()
  - Simplify mtk_mhccif_init() error path to use direct returns
  - Change -EFAULT to -ENOLINK for PCIe link check failure
  - Rename goto label "out" to "log_err" in mtk_pci_probe()
  - Wrap long lines to stay within 80 columns
  - Fix IRQ vector leak: add pci_free_irq_vectors() on error path [sashiko]
  - Fix mtk_pci_remove() ordering: free IRQ before cancel_work_sync [sashiko]
  - Fix mtk_pci_pldr() ACPI buffer leak: free first result before second call [sashiko]
  - Replace msleep(500) with MTK_PLDR_POWER_OFF_DELAY_MS define
  - Remove unused EXT_EVT_H2D_DRM_DISABLE_AP and related register define [sashiko]
  - Increase MTK_IRQ_NAME_LEN from 20 to 32 to fix W=1 format-truncation warning [sashiko]
- Patch 2 (Add control plane transaction layer):
  - Add kernel-doc comments to mtk_ctrl_init() and mtk_ctrl_exit()
  - Change mtk_ctrl_exit() return type from int to void
  - Set mdev->ctrl_blk to NULL after freeing in mtk_ctrl_exit() [sashiko]
  - Change ctrl_blk from void* to typed struct mtk_ctrl_blk* [sashiko]
  - Remove redundant "depends on MTK_T9XX" from MTK_T9XX_PCI Kconfig [sashiko]
  - Use mtk_dev_free() instead of devm_kfree() in mtk_pci_probe() error path [sashiko]
- Patch 3 (Add control DMA interface):
  - Add @ops kernel-doc parameter for mtk_ctrl_init()
  - Rename 'err' to 'ret' consistently throughout the patch
  - Reorder variable declarations to follow reverse Christmas tree style
  - Change mtk_cldma_txq_free() return type from int to void
  - Change mtk_cldma_rxq_free() return type from int to void
  - Change mtk_cldma_exit() return type from int to void
  - Remove unnecessary zero-initialization of ret in mtk_cldma_start_xfer()
  - Remove unnecessary zero-initialization of ret in mtk_cldma_tx()
  - Use direct return instead of goto out in mtk_cldma_submit_tx() error paths
  - Move software state before HWO flag in mtk_cldma_submit_tx()
  - Squash variable declarations in mtk_cldma_check_intr_status()
  - Remove unlikely() from validation paths in mtk_cldma_check_ch_cfg()
  - Clamp data_recv_len with min_t to prevent skb_over_panic in mtk_cldma_rx_skb_adjust() [sashiko]
  - Use READ_ONCE() for HWO flag polling in mtk_cldma_check_rx_req() [sashiko]
  - Fix mtk_cldma_rx_done_work() to always unmask interrupt on error path [sashiko]
  - Add DMA address guard in mtk_cldma_txq_free() teardown loop [sashiko]
  - Add IS_ERR() check for kthread_run() in mtk_ctrl_trb_srv_init() [sashiko]
  - Fix queue_info memory leak on validation failure in mtk_pcie_hif_init() [sashiko]
  - Handle non-EAGAIN errors in mtk_ctrl_trb_handler() TX path [sashiko]
  - Fix 'err' typo to 'ret' in mtk_cldma_txbuf_set() error message
  - Remove unused variable mdev in mtk_cldma_rx_check_again() [sashiko]
  - Remove unused variables trans and ctrl_blk in mtk_cldma_txq_free() and mtk_cldma_rxq_free() [sashiko]
- Patch 4 (Add control port):
  - Add @cfg kernel-doc parameter for mtk_ctrl_init()
  - Update mtk_ctrl_init() return description to cover additional error codes
  - Fix double list_del in mtk_port_stale_list_grp_cleanup() [sashiko]
  - Fix direct mtk_port_trb_free() call to use kref_put() in mtk_port_ch_enable() error path [sashiko]
  - Fix direct mtk_port_trb_free() call to use kref_put() in mtk_port_ch_disable() error path [sashiko]
  - Add mtk_port_tbl_destroy() in mtk_port_mngr_init() error path to prevent port memory leak [sashiko]
  - Change port_ops exit/reset/enable/disable callbacks from int to void
  - Move -EIO dispatch comment to where the code was introduced
- Patch 5 (Add FSM thread):
  - Add bounds check for rtft_entry in mtk_fsm_parse_hs2_msg() [sashiko]
  - Add skb length validation before accessing ctrl_msg_header in mtk_fsm_sap_ctrl_msg_handler() [sashiko]
  - Fix skb leak on CTRL_MSG_HS2 mismatch return in mtk_fsm_sap_ctrl_msg_handler() [sashiko]
  - Add skb length validation before accessing ctrl_msg_header in mtk_fsm_md_ctrl_msg_handler() [sashiko]
  - Replace devm_kzalloc/devm_kfree with kzalloc/kfree for FSM events [sashiko]
  - Fix mtk_fsm_evt_submit() to return -ETIMEDOUT on blocking event timeout [sashiko]
  - Change FSM kthread from TASK_INTERRUPTIBLE to TASK_UNINTERRUPTIBLE [sashiko]
  - Remove unused variable hw_id in mtk_cldma_dev_exit() [sashiko]
- Patch 6 (Add AT & MBIM WWAN ports):
  - Use imperative mode in commit message
  - Remove unnecessary zero-initialization of ret in mtk_port_copy_data_from()
  - Change copy_from_user() error code from -EFAULT to -EINVAL in mtk_port_copy_data_from()
  - Return -EINVAL for zero-length write in mtk_port_common_write()
  - Change mtk_port_wwan_exit/enable/disable() return type from int to void
  - Fix packet_size to account for CCCI header reservation in mtk_port_common_write() [sashiko]
  - Fix WWAN tx callbacks to consume skb and return 0 per wwan_port_ops contract [sashiko]
  - Fix wwan_create_port() error path: clear ERR_PTR to NULL and call mtk_port_ch_disable() [sashiko]
- Patch 7 (Add maintainers entry): new patch
- Link to v1: https://patch.msgid.link/20260529-t9xx_driver_v1-v1-0-bdbfe2c01e57@compal.com

---
Jack Wu (7):
      net: wwan: t9xx: Add PCIe core
      net: wwan: t9xx: Add control plane transaction layer
      net: wwan: t9xx: Add control DMA interface
      net: wwan: t9xx: Add control port
      net: wwan: t9xx: Add FSM thread
      net: wwan: t9xx: Add AT & MBIM WWAN ports
      net: wwan: t9xx: Add maintainers entry

 MAINTAINERS                                     |    9 +
 drivers/net/wwan/Kconfig                        |   17 +
 drivers/net/wwan/Makefile                       |    1 +
 drivers/net/wwan/t9xx/Makefile                  |   14 +
 drivers/net/wwan/t9xx/mtk_ctrl_plane.c          |  111 ++
 drivers/net/wwan/t9xx/mtk_ctrl_plane.h          |   88 ++
 drivers/net/wwan/t9xx/mtk_dev.c                 |   55 +
 drivers/net/wwan/t9xx/mtk_dev.h                 |  114 ++
 drivers/net/wwan/t9xx/mtk_fsm.c                 |  948 +++++++++++++++
 drivers/net/wwan/t9xx/mtk_fsm.h                 |  140 +++
 drivers/net/wwan/t9xx/mtk_port.c                |  968 +++++++++++++++
 drivers/net/wwan/t9xx/mtk_port.h                |  174 +++
 drivers/net/wwan/t9xx/mtk_port_io.c             |  573 +++++++++
 drivers/net/wwan/t9xx/mtk_port_io.h             |   41 +
 drivers/net/wwan/t9xx/mtk_utility.h             |   33 +
 drivers/net/wwan/t9xx/pcie/Makefile             |   15 +
 drivers/net/wwan/t9xx/pcie/mtk_cldma.c          | 1420 +++++++++++++++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_cldma.h          |  173 +++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.c      |  371 ++++++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.h      |  174 +++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.c |  178 +++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.h |  101 ++
 drivers/net/wwan/t9xx/pcie/mtk_ctrl_cfg_m9xx.c  |   55 +
 drivers/net/wwan/t9xx/pcie/mtk_pci.c            | 1102 ++++++++++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_pci.h            |  234 ++++
 drivers/net/wwan/t9xx/pcie/mtk_pci_drv_m9xx.c   |   69 ++
 drivers/net/wwan/t9xx/pcie/mtk_pci_reg.h        |   71 ++
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c     |  603 ++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h     |  107 ++
 29 files changed, 7959 insertions(+)
---
base-commit: eb3f4b7426cfd2b79d65b7d37155480b32259a11
change-id: 20260529-t9xx_driver_v1-1744f8af7739

Best regards,
--  
Jack Wu <jackbb_wu@compal.com>

