From: Jack Wu <jackbb_wu@compal.com>
Subject: [PATCH v8 0/6] net: wwan: t9xx: Add MediaTek T9XX WWAN driver
Date: Mon, 14 Sep 2026 18:31:51 +0800
Message-Id: <20260914-t9xx_driver_v1-v8-0-5206c2e6bea0@compal.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABfNp2oC/3XP20rEMBAG4FdZcm0l54NXvofIkkwybkS3S1pLZ
 em7m6wXXQlCIAzM98/MlUyp5DSRp8OVlLTkKY/nWtiHA4GTP7+lIcdaE065poq7YXbreowlL6k
 cFzYwIyVaj8YIRyq6lIR5vQW+vP7W01d4TzC3lNZxytM8lu/bxIW1vn/D66NDiAETB8qSMs8wf
 l78x2P9SEtf+O41o53n1YNWPkbkIgjsvLjzXHZeVG8EIhWoKUjbebl7Q/v9ZfXeAqUuKupAdV7
 deS46r9r93HgMzgGE0Hm9e8tY53X1HJx26KMyoDtv7jy3nTdtPtp6vJHRWv/Hb9v2AypGtNw/A
 gAA
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
 Shuah Khan <skhan@linuxfoundation.org>, Robert Yu <robert_yu@compal.com>, 
 Jeff Chang <Jeff_Chang@compal.com>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-doc@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789381913; l=36235;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=faP0AukpCAW6uC2xZYm4+eflfKtrVxeeZ8XriFtbQ+k=;
 b=f36Yu1ILViqV9JOim7HYTW9lhXZ1IRob9X54ZfXRGZGT7uQKqZ41re95CEDNSQTMIPDjXrICK
 HTj1v2JPr3VBNsweR+o0fjQ3oxf280Z+3JLgHLRMlvNU1/DZA+aEKyM
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

* Device lifecycle management - Contains the logic that
   keeps the device working. It includes:

   * FSM (Finite State Machine) - Drives the T9xx
     device lifecycle (boot handshake, error recovery,
     removal), and notifies each module when the state
     changes.

The compilation of the T9XX driver is enabled by the
CONFIG_MTK_T9XX and CONFIG_MTK_T9XX_PCI config option
which depends on CONFIG_WWAN.

This submission covers the control plane only
(patches 1-6). The data plane will follow in a
separate series once the control plane is accepted.

---
Changes in v8:
- Patch 1 (Add PCIe core):
  - Commit message: reworded the MHCCIF bullet (the driver masks all
    channels at init and does not clear pending status) and added a
    paragraph on the ACPI reset performed on removal
  - Added irq_cb_lock around IRQ callback register/unregister;
    unregister now masks the vector and calls synchronize_irq() before
    clearing the slot, so no callback runs after it returns
  - mtk_pci_pldr() evaluates MRST._RST on the device's own ACPI node
    instead of PXP._OFF/_ON on the upstream bridge: the bridge power
    resource is shared and its 500 ms off/on induced a link down/up
    that a hotplug-capable port reports as a remove/add
  - Removed mtk_pci_fldr(), enum mtk_reset_type, mtk_pci_dev_reset()
    and mtk_pci_reset(): dead here, they belong with the devlink
    firmware-update series that will use them
  - MHCCIF interrupts are now acked before dispatch, not after;
    mtk_mhccif_init() masks every channel but deliberately does not
    ack, as the status is one-shot latched by the device
  - Removed the write-only bar[] array and MTK_PCI_BAR_NUM
  - Switched to pcim_iomap_region(), replacing the deprecated
    pcim_iomap_regions()/pcim_iomap_table() pair
  - Dropped the BIT(30) exemption from the all-ones MMIO check; a
    stray bit is now logged with dev_err_ratelimited() and cleared
  - probe() masks all MHCCIF channels unconditionally; removed the
    dead configuration plumbing that used to select the mask
  - Check pci_save_state() and return -ENOMEM instead of -EFAULT
  - Reordered remove(): dev_exit, mask all 32 channels, mhccif_exit,
    free_irq, clear bus master, PLDR reset last
  - Removed the unused enum mtk_atr_type and the .type field
- Patch 2 (Add control plane transaction layer):
  - Converted the remaining EXPORT_SYMBOL() to EXPORT_SYMBOL_GPL()
    (mtk_ctrl_init/exit here, mtk_port_trb_free in Patch 4,
    mtk_fsm_start/evt_submit/init/exit in Patch 5) and deleted the
    unused mtk_fsm_notifier_register/unregister exports
- Patch 3 (Add control DMA interface):
  - Clamp the RX length reported by the GPD against data_allow_len and
    drop the packet with -EPROTO instead of trusting the device
  - Publish txq[]/rxq[] with smp_store_release(); the readers added in
    Patch 5 pair with smp_load_acquire()
  - mtk_cldma_stop_queue() returns -ENODEV on an all-ones read,
    escalates to cldma_drv_reset() on timeout and only leaks the ring
    if the queue still refuses to stop
  - Added NULL checks to all six radix_tree_lookup() call sites
  - mtk_cldma_rxq_free() splits ownership three ways (host-owned,
    device-owned, in-flight) instead of unmapping everything
  - New mtk_cldma_hw_recovery(); mtk_cldma_start_xfer() rewritten to
    run entirely under ring_lock so a resume cannot race a submit
  - Populate the control-queue entries of the queue info table here
    instead of in Patch 4, keeping each commit self-consistent
  - srv_cfg is const int (*)[HW_QUE_NUM] instead of int **, dropping
    the type-punning cast
  - Use skb_queue_len_lockless() where the list lock is not held
  - Hold the skb_list lock across every list read; the one place it
    must be dropped (sleeping submit) is documented
  - Check mtk_cldma_trb_process() return and add
    mtk_cldma_txq_flush() to complete pending requests on error
  - Initialise submit_lock and trans->available in
    mtk_trans_ctrl_init(), with a NULL srv guard
  - mtk_pcie_hif_exit() order: cldma_exit, then trb_srv_exit, then
    remove the radix tree
  - Evaluate CHECK_TX_FULL under submit_lock
  - Removed dead code found while auditing the above
  - Reject a non-linear skb with -EINVAL instead of WARN_ON_ONCE()
  - Commit message: probe only registers the transport plane; the
    CLDMA instances and the TRB service thread are started by the
    later "Add FSM thread" patch
  - A stop timeout in mtk_cldma_txq_free()/rxq_free() resets the whole
    IP, so the new mtk_cldma_rearm_queues() re-arms every queue still
    published on that instance, not just the one being freed
  - The RX re-arm is handed to mtk_cldma_rx_done_work() through a
    need_restart flag; it owns free_idx, which the re-arm used to read
    without synchronisation
  - mtk_cldma_submit_tx() rejects a NULL dev, closing the window
    between mtk_cldma_exit() clearing trans->dev and the TRB service
    thread being stopped
- Patch 5 (Add FSM thread):
  - New mtk_fsm_hif_err_record(): a transport init failure is sticky,
    so the STARTUP handler refuses the BOOTUP->READY promotion instead
    of reaching READY on a dead transport; DEV_ADD clears it
  - A feature the device reports as NOT_EXIST/NOT_SUPPORT now fails
    the handshake with -EPROTO when the host marks it MUST_SUPPORT
  - Both ctrl-msg handlers consume the skb on every path and return 0;
    the caller no longer frees behind the handler's back
  - The duplicate-HS2 and invalid-id paths no longer touch rt_data, so
    an epilogue cannot free data owned by a queued STARTUP event
  - mtk_fsm_idle_evt_handler() returns an error on a failed submit and
    unmasks its handshake channels only on success;
    mtk_fsm_early_bootup_handler() latches last_dev_state only after
    the handler chain succeeded, so a failure is retried
  - Re-arm BOOT_FLOW_SYNC in mtk_fsm_early_bootup_handler(): the
    channel was masked on entry and never unmasked, so a device still
    booting when the driver binds never delivered its DEV_STAGE_IDLE
    notification and the FSM stayed at FSM_STATE_ON with no ports
  - The in-flight runtime-data skb is owned by the STARTUP event it
    was submitted with and freed when that event completes; rt_data is
    demoted to a duplicate-HS2 guard and rt_data_len removed
  - mtk_fsm_init() unwinds through explicit labels and no longer leaks
    the kthread on any error path
  - mtk_fsm_exit() calls mtk_fsm_ctrl_ch_stop(), releasing the control
    ports while the port table they reference is still alive
  - Added the 0x0900 entry to cldma_drv_info_tbl[]; the primary
    MediaTek PCI ID no longer fails CLDMA dev_init with -EIO
  - QUEUE_ERROR is now cleared, re-unmasked and handled by a new
    err_work that stops the errored queues and completes their pending
    requests with -EPIPE, instead of being logged against a masked
    interrupt that is never re-armed
  - mtk_cldma_dev_exit() masks the L1 interrupt and calls
    synchronize_irq() before unregistering the callback
  - mtk_cldma_dev_exit() quiesces the IP (interrupt output disabled,
    cldma_drv_reset()) before releasing descriptor memory, and leaks
    the DMA pools as well if a ring was already leaked
  - New mtk_fsm_stop(), called by mtk_pci_dev_exit() after a possibly
    failed DEV_RM and before mtk_trans_ctrl_exit(), so the FSM thread
    cannot run on a dismantled transport plane; mtk_pcie_hif_exit() is
    idempotent, mtk_cldma_exit() latches trans->dev, and the FSM
    kthread is held with get_task_struct() so a thread that died
    abnormally cannot be stopped through a freed task_struct
  - mtk_cldma_txq_free()/rxq_free() flush err_work as well: it may
    already hold the queue they are about to free
  - err_work no longer completes and unmaps the requests of a queue
    that failed to stop; the device may still be reading them
  - The rt_data duplicate-HS2 guard is accessed with READ_ONCE() and
    WRITE_ONCE(), the rx path and the FSM kthread being concurrent
- Patch 6 (Add AT & MBIM WWAN ports):
  - Commit message: note the copy path now uses skb_copy_bits()
  - Removed union user_buf and mtk_port_copy_data_from(); the
    kernel-buffer branch had no user
  - Removed mtk_port_common_write_frag_skb() and the dead
    scatter-gather gate it was reached through
  - Fixed a heap overread: the TX path copied from a paged skb as if
    it were linear; use skb_copy_bits()
  - mtk_port_send_data() takes explicit blocking/force_send arguments,
    no longer mutates the caller's flags, and is all-or-nothing
  - The AT and MBIM TX callbacks are thin wrappers over a shared
    mtk_port_wwan_tx()
  - A port DISABLE is inserted ahead of pending ENABLEs (Patch 3) and
    mtk_port_internal_enable() unwinds on failure (Patch 4), so a
    close cannot be starved by a queued enable
  - Declined the reordering suggested in review, with a comment
    explaining the ordering constraint; w_port is read inside w_lock
  - wwan_port_rx() is called only when PORT_S_OPEN is set; otherwise
    the packet is dropped with -ENXIO and dev_dbg_ratelimited()
- Link to v7: https://patch.msgid.link/20260828-t9xx_driver_v1-v7-0-bf8f6074d88a@compal.com

Changes in v7:
- Cover letter: renamed "Core logic" to "Device lifecycle management".
  The FSM is T9xx-specific (same model as the in-tree t7xx driver) and
  stays in the driver rather than the WWAN framework.
- Patch 1 (Add PCIe core):
  - Removed RGU wording from commit message, no RGU code in the series
  - Removed `select NET_DEVLINK` from Kconfig, no devlink consumer
  - Reordered ATR setup: program TRSL_ADDR/TRSL_PARAM before enabling
    ATR in SRC_ADDR_LSB, with a readback, matching t7xx
  - Adopted the t7xx IRQ model: require exactly MTK_IRQ_CNT_MAX MSI-X
    vectors with one handler per vector; removed the merged-IRQ mode
    and scoped dispatch to each vector's own status bits
  - Fixed IRQ callback publish ordering: WRITE_ONCE + smp_wmb on
    register, READ_ONCE + smp_rmb in the interrupt handler
  - Added hw_bits == 0 guard in mtk_pci_send_ext_evt() to reject
    unmapped event channels
  - MHCCIF callbacks stay under spin_lock_bh by design; added a comment
    documenting the must-not-sleep callback contract
  - Added a drain loop in mtk_mhccif_exit() to free any remaining
    callback nodes
  - Moved cancel_work_sync(&priv->mhccif_work) before mtk_pci_pldr()
    in remove, preventing worker MMIO during the power cycle
  - Squashed the MAINTAINERS entry into this patch (was Patch 7); the
    series is now 6 patches
- Patch 2 (Add control plane transaction layer):
  - Commit message and Kconfig help text now name both modules
    (mtk_t9xx and mtk_t9xx_pcie)
  - Reworded mtk_ctrl_exit() kernel-doc: the allocation itself is
    devres-managed and freed on driver detach
- Patch 3 (Add control DMA interface):
  - RX re-map failure now keeps the buffer in its slot instead of
    freeing it and advancing free_idx, preventing a permanent ring
    stall from a stale GPD DMA address
  - mtk_cldma_stop_queue() returns -ETIMEDOUT on poll timeout; alloc
    paths abort on failure, free paths warn and proceed
  - Added READ_ONCE() for the free_idx and tx_started reads in
    mtk_cldma_start_xfer()
  - mtk_cldma_get_tx_start_addr() reads ADDRL+ADDRH as u64, so a >4GB
    DMA address is not mistaken for "queue not started"
  - mtk_cldma_open() decrements usr_cnt on failure. Beyond the emailed
    reply: mtk_pcie_hif_init() re-zeroes usr_cnt and ENABLE/DISABLE no
    longer gate on TX budget, so a channel reopens after devlink reload
  - mtk_cldma_close() completes the TRB with -EPIPE when drv_info is
    already gone, instead of stalling the submitter until timeout
  - mtk_cldma_txbuf_set() returns -ENOMEM instead of -EAGAIN on
    dma_map failure (no infinite retry); dev_err_ratelimited
  - Added the 0x0900 (MTK reference) entry to mtk_ctrl_info_tbl[];
    both PCI IDs are now present in all dispatch tables
  - Documented the single-consumer assumption of
    mtk_ctrl_trb_handler() in a comment
  - Added a submit_lock mutex closing the submit vs. hif_exit race on
    trans->available; hif_cmd_func() now checks available
  - Kept the empty queue table: queue_info entries are populated by
    the next patch "Add control port"
  - Commit message notes TX/RX paths are wired up by later patches
  - hif_exit has no caller at this commit, but ops->init is not called
    either, so nothing is allocated to leak; patch 5 wires up both
  - The trb_handler default case completes the TRB with -EINVAL
    instead of silently leaking the SKB
  - Documented the non-BD skb_headlen() == skb->len invariant
  - trb_open_priv overlay size is safe by construction
  - Removed the unused CLDMA4 support here at the source, instead of
    introducing it and deleting it again in Patch 5
  - Fixed an skb leak in the mtk_cldma_rxq_free() BD path: the parent
    skb was never freed after detaching frag_list
  - Replaced the free_idx/wr_idx boundary check added in v5 with a
    per-queue ring_lock following drivers/net/wwan/t7xx: the check
    raced with submit_tx and could stall TX forever; the lock also
    closes the submit/reclaim race the check was originally added for
  - Removed the write-only queues_cnt and tx_req.data_vm_addr fields
- Patch 5 (Add FSM thread):
  - Commit message: five FSM states (not seven); now describes the
    HS1/HS2/HS3 handshake and CLDMA bring-up/teardown in detail
  - Check ops->init() return in FSM_STATE_ON; NULL guard for srv in
    trb_srv_exit(); check mtk_cldma_dev_init() return in the listener
  - Kept the HS2 feature parser as is: the protocol requires dense
    ascending order and the ft_id check catches violations
  - Reject data_len == 0 before calling the query_rtft handler
  - Drop duplicate HS2 messages when hs_info->rt_data is already set
  - Added a notifier_lock mutex protecting FSM notifier list walks
  - Reordered HS2 handling: parse HS2, send HS3, and only then switch
    state, so FSM_STATE_READY implies HS3 was delivered
  - Unmask the HS channels on handshake error so the modem can retry
  - Moved wake_up_process() under evtq_lock with a fsm_handler NULL
    check; exit sets GATECLOSED and clears fsm_handler under the lock
  - mtk_fsm_hs_info_init() propagates event-registration failures and
    unwinds on error
  - The CLDMA ISR logs, clears and re-unmasks QUEUE_ERROR bits
  - CLDMA dev_exit unregisters the IRQ callback before mask +
    synchronize_irq, preventing ISR re-arm after teardown
  - Reordered FSM_STATE_OFF teardown: stop the TRB threads before
    freeing CLDMA, with the per-hif teardown moved into
    mtk_cldma_exit(); fixes a silently skipped teardown that broke the
    next reset cycle and leaked the CLDMA resources
  - mtk_trans_ctrl_exit() falls back to hif_exit when the
    FSM_STATE_OFF teardown never ran (guarded by trans->available)
  - mtk_pci_dev_start() propagates evt_submit/fsm_start errors
  - Restored TASK_INTERRUPTIBLE for the FSM event kthread: the v2 flip
    to TASK_UNINTERRUPTIBLE was not requested by review, and an idle
    D-state kthread blocks suspend and trips the hung-task detector
- Patch 6 (Add AT & MBIM WWAN ports):
  - Check and log mtk_port_enable_by_type() failure in the FSM state
    handler
  - A short WWAN write now returns -EIO; consume_skb() on success
  - The wwan_enable failure path calls mtk_port_ch_disable() to undo
    usr_cnt and partial resources
  - Publish the wwan_port pointer only after IS_ERR validation, so the
    RX path never sees an ERR_PTR
  - Pass wwan_port_caps (frag_len = negotiated tx_mtu, CCCI header
    headroom) to wwan_create_port(); a tx_mtu == 0 guard prevents
    userspace write() from spinning forever on frag_len == 0
  - Set PORT_S_WR/PORT_S_ENABLE before wwan_create_port() and clear
    both bits on failure
- Link to v6: https://patch.msgid.link/20260811-t9xx_driver_v1-v6-0-2c969fad57c6@compal.com

Changes in v6:
- Patch 3 (Add control DMA interface):
  - Move extern declarations for mtk_cldma_regs_m9xx and
    cldma_drv_ops_m9xx from Patch 5 to Patch 3 where the
    symbols are first defined, fixing sparse W=1 C=1 warnings
  - Fix RX done recycle path: skip buffer recycle in BD mode
    (nr_bds > 0) to prevent BDP flag mismatch causing HW to
    misinterpret data buffer address as BD chain pointer
    [sashiko]
  - Fix RX done recycle path: on dma_map_single failure,
    free skb and advance free_idx instead of goto out, to
    prevent ring stall [sashiko]
- Patch 4 (Add control port):
  - Replace wake_up_interruptible_all() with wake_up_all()
    for trb_wq and rx_wq in open/close/tx completion
    callbacks and common_close, fixing mismatch with
    wait_event_timeout (TASK_UNINTERRUPTIBLE) waiters in
    ch_enable/ch_disable that caused spurious timeouts
    [sashiko]
- Link to v5: https://patch.msgid.link/20260723-t9xx_driver_v1-v5-0-b27afb99ccbb@compal.com

Changes in v5:
- Patch 1 (Add PCIe core):
  - Remove LE32_TO_U32(cpu_to_le32()) no-op endianness
    roundtrip, return hw_bits directly
  - Use "%s" format string in pci_request_irq() to prevent
    format string injection
  - Return PCI_ERS_RESULT_DISCONNECT from AER error_detected,
    driver does not support AER recovery
- Patch 2 (Add control plane transaction layer):
  - Rewrite commit message to accurately describe skeleton
    content
- Patch 3 (Add control DMA interface):
  - Replace rmb() with dma_rmb() after HWO check in TX/RX
    done paths for correct DMA descriptor ordering
  - Add ring boundary check in TX done to prevent crossing
    into submit territory
  - Fix RX stall on reload failure: recycle old buffer with
    skb_trim() + dma_map_single() instead of losing descriptor
  - Convert devm_kcalloc to kcalloc for req_pool and
    bd_dsc_pool, matching existing kfree in teardown
  - Set bd_dsc->skb = NULL after dev_kfree_skb_any() in
    reload error path to prevent use-after-free
  - Use skb_headlen(skb) instead of skb->len for linear
    segment size in txbuf_set non-BD path
  - Use WRITE_ONCE() for wr_idx update in submit_tx
- Patch 4 (Add control port):
  - Fix direct mtk_port_release() calls to use kref_put()
    in mtk_port_free_or_backup and stale_list_grp_cleanup
  - Add ida_free() before kfree(s_list) in stale list
    cleanup to prevent IDA leak
  - Remove double-free of skb in mtk_port_internal_recv()
    drop_data path, caller owns the skb
  - Add port_cnt bounds check against data_len in
    mtk_port_status_update() to prevent OOB read
  - Replace wait_event_interruptible_timeout with
    wait_event_timeout in ch_enable/ch_disable to prevent
    busy-spin on pending signals
- Patch 5 (Add FSM thread):
  - Validate rtft data_len before passing to query_rtft
    callback to prevent OOB access
  - Zero-initialize HS3 skb data with memset() to prevent
    heap infoleak
  - Set hs_info->rt_data = NULL after dev_kfree_skb() in
    SAP/MD ctrl msg handlers to prevent use-after-free
  - Move wake_up_process() inside spinlock in evt_submit,
    clear fsm_handler under lock in exit to fix race
  - Replace kcalloc + radix_tree_gang_lookup with
    radix_tree_for_each_slot() in mtk_port_disable()
  - Add rt_data cleanup loop in FSM teardown path
- Patch 7 (Add maintainers entry):
  - Add Robert Yu and Jeff Chang as maintainers
- Link to v4: https://patch.msgid.link/20260709-t9xx_driver_v1-v4-0-a8c009d509c5@compal.com

Changes in v4:
- Patch 1 (Add PCIe core):
  - Add ACPI dependency to Kconfig (depends on PCI && ACPI)
    and remove #ifdef CONFIG_ACPI / #else guards from
    mtk_pci_fldr() and mtk_pci_pldr()
  - Remove unnecessary parentheses in (mdev)->dev across
    all dev_err/dev_warn calls
  - Remove devm_kfree() calls from mtk_pci_probe() error
    path and mtk_pci_remove(), devres handles cleanup
  - Remove mtk_dev_alloc()/mtk_dev_free() wrappers, use
    devm_kzalloc() directly in mtk_pci_probe()
  - Convert ext_evt callbacks from devm_kzalloc/devm_kfree
    to kzalloc/kfree for runtime-managed resources
- Patch 2 (Add control plane transaction layer):
  - Remove mtk_dev_alloc()/mtk_dev_free() declarations and
    implementations from mtk_dev.h and mtk_dev.c
  - Remove empty module_init/module_exit stubs, defer to
    Patch 4 where they have actual content
  - Remove devm_kfree() and unused ctrl_blk variable in
    mtk_ctrl_exit(), devres handles cleanup
- Patch 3 (Add control DMA interface):
  - Remove inline keyword from mtk_cldma_clr_bd_dsc() in
    .c file, let compiler decide inlining
  - Replace dev_warn() with dev_warn_ratelimited() for SKB
    alloc/map failure messages in data path
  - Replace open-coded do/while polling loop with
    read_poll_timeout() from <linux/iopoll.h> in
    mtk_cldma_stop_queue()
  - Remove ctrl_port_chl_mtu module_param, MODULE_PARM_DESC,
    and mtk_ctrl_queue_info_update() with associated macros
  - Remove unnecessary parentheses in (mdev)->dev across
    mtk_cldma.c and mtk_trans_ctrl.c
  - Convert CLDMA txq/rxq/cd from devm_kzalloc/devm_kfree
    to kzalloc/kfree for runtime-managed resources
  - Convert trb_srv/srv_que from devm_kzalloc/devm_kfree
    to kzalloc/kfree for runtime-managed resources
  - Remove devm_kfree() and unused variables from
    mtk_cldma_exit() and mtk_trans_ctrl_exit(), devres
    handles cleanup for device-lifetime resources
  - Remove unnecessary NULL checks before kfree() for
    bd_dsc_pool in txq_free/rxq_free
- Patch 4 (Add control port):
  - Add module_init/module_exit with mtk_port_io_init/exit
    content, moved from Patch 2
  - Remove unnecessary parentheses in (mdev)->dev in
    mtk_port.c
  - Remove devm_kfree() from mtk_port_mngr_init() error
    path and mtk_port_mngr_exit(), devres handles cleanup
  - Simplify mtk_trans_ctrl_init() error path: replace goto
    err_free_trans with direct return -ENOMEM
- Patch 5 (Add FSM thread):
  - Remove unnecessary parentheses in (mdev)->dev across
    mtk_fsm.c and mtk_ctrl_plane.c
  - Convert FSM notifiers from devm_kzalloc/devm_kfree to
    kzalloc/kfree for runtime-managed resources
  - Convert CLDMA drv_info from devm_kzalloc/devm_kfree to
    kzalloc/kfree for runtime-managed resources
  - Remove devm_kfree() from mtk_fsm_init()/mtk_fsm_exit()
    and mtk_ctrl_init()/mtk_ctrl_exit(), devres handles
    cleanup for device-lifetime resources
- Link to v3: https://patch.msgid.link/20260624-t9xx_driver_v1-v3-0-73ff03f60c48@compal.com

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

To: Loic Poulain <loic.poulain@oss.qualcomm.com>
To: Sergey Ryazanov <ryazanov.s.a@gmail.com>
To: Johannes Berg <johannes@sipsolutions.net>
To: Andrew Lunn <andrew+netdev@lunn.ch>
To: "David S. Miller" <davem@davemloft.net>
To: Eric Dumazet <edumazet@google.com>
To: Jakub Kicinski <kuba@kernel.org>
To: Paolo Abeni <pabeni@redhat.com>
To: Jack Wu <jackbb_wu@compal.com>
To: Robert Yu <robert_yu@compal.com>
To: Jeff Chang <Jeff_Chang@compal.com>
To: Wen-Zhi Huang <wen-zhi.huang@mediatek.com>
To: Shi-Wei Yeh <shi-wei.yeh@mediatek.com>
To: Minano Tseng <Minano.tseng@mediatek.com>
To: Matthias Brugger <matthias.bgg@gmail.com>
To: AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-kernel@vger.kernel.org
Cc: netdev@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-mediatek@lists.infradead.org

---
Jack Wu (6):
      net: wwan: t9xx: Add PCIe core
      net: wwan: t9xx: Add control plane transaction layer
      net: wwan: t9xx: Add control DMA interface
      net: wwan: t9xx: Add control port
      net: wwan: t9xx: Add FSM thread
      net: wwan: t9xx: Add AT & MBIM WWAN ports

 MAINTAINERS                                     |   11 +
 drivers/net/wwan/Kconfig                        |   16 +
 drivers/net/wwan/Makefile                       |    1 +
 drivers/net/wwan/t9xx/Makefile                  |   14 +
 drivers/net/wwan/t9xx/mtk_ctrl_plane.c          |  114 ++
 drivers/net/wwan/t9xx/mtk_ctrl_plane.h          |  100 ++
 drivers/net/wwan/t9xx/mtk_dev.c                 |   33 +
 drivers/net/wwan/t9xx/mtk_dev.h                 |  111 ++
 drivers/net/wwan/t9xx/mtk_fsm.c                 | 1174 ++++++++++++++
 drivers/net/wwan/t9xx/mtk_fsm.h                 |  149 ++
 drivers/net/wwan/t9xx/mtk_port.c                |  969 ++++++++++++
 drivers/net/wwan/t9xx/mtk_port.h                |  161 ++
 drivers/net/wwan/t9xx/mtk_port_io.c             |  522 +++++++
 drivers/net/wwan/t9xx/mtk_port_io.h             |   36 +
 drivers/net/wwan/t9xx/mtk_utility.h             |   33 +
 drivers/net/wwan/t9xx/pcie/Makefile             |   15 +
 drivers/net/wwan/t9xx/pcie/mtk_cldma.c          | 1865 +++++++++++++++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_cldma.h          |  181 +++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.c      |  380 +++++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.h      |  181 +++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.c |  178 +++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.h |  101 ++
 drivers/net/wwan/t9xx/pcie/mtk_ctrl_cfg_m9xx.c  |   55 +
 drivers/net/wwan/t9xx/pcie/mtk_pci.c            | 1087 +++++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_pci.h            |  180 +++
 drivers/net/wwan/t9xx/pcie/mtk_pci_drv_m9xx.c   |   65 +
 drivers/net/wwan/t9xx/pcie/mtk_pci_reg.h        |   69 +
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c     |  667 ++++++++
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h     |  103 ++
 29 files changed, 8571 insertions(+)
---
base-commit: eb3f4b7426cfd2b79d65b7d37155480b32259a11
change-id: 20260529-t9xx_driver_v1-1744f8af7739

Best regards,
--  
Jack Wu <jackbb_wu@compal.com>

