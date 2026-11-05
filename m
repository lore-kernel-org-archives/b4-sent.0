From: Jack Wu <jackbb_wu@compal.com>
Subject: [PATCH v11 0/6] net: wwan: t9xx: Add MediaTek T9XX WWAN driver
Date: Thu, 05 Nov 2026 15:56:26 +0800
Message-Id: <20261105-t9xx_driver_v1-v11-0-2084aa512864@compal.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKs27GoC/3XS20oDMRAG4FcpuXZlMjmOV76HSMnRrmhbdutSK
 X13sxXclVEIhIR8fyaHixjL0JdRPGwuYihTP/aHfRtIebcRaRf2L6Xrc5sQCGjBIHUnOp+3eei
 nMmwn2UmndfWhOqdINHQcSu3Pt8Sn5+/x+BFfSzrNKfOKXT+eDsPnbctJzuv+DW8NuphjLZhAF
 uMe0+H9GN7uWyfm9AkXbyUwj80na0LOFVVUlXm18qiZV807VSuoaiFpz7xevANev24++ARA2QA
 lw7xZeVTMm/n86EKNRCnFyLxdvJeSeds8JrJUQzYuWebdyqNn3s37V98O73T2PjDvF0+S359v3
 iDYhMXGEoB5WnnF34+aV6h9JDSWDK9fwk+AhD8KaH8COp0h56KsVPX3C1yv1y/OonYCAgMAAA=
 =
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793865391; l=63960;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=lOcidNBlaPbqMydtlZKOWV4sfckqCJYe3NZv2F6Q13Q=;
 b=OgUeBFztePcNIwiNMHgCHc2f9VVQwB6VQKN9VH/uNxHgGCWoXv3wJmpksDxlLQ2OtrcwXBKEr
 QP/LZeW6KYxAGAj90Adzgd3pfikngG1ml21/OjdWa2KLx/OQdAEbozm
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
CONFIG_MTK_T9XX config option, which depends on
CONFIG_WWAN.

This submission covers the control plane only
(patches 1-6). The data plane will follow in a
separate series once the control plane is accepted.

Statistics are intentionally left out of this series.

---
Changes in v11:
- Patch 1 (Add PCIe core):
  - Trimmed mtk_dev.h to <linux/bits.h>, <linux/types.h> and a forward
    declaration of struct device; seven unused includes dropped
    (Loic Poulain)
  - Replaced the SET_HW_BITS() statement-expression macro with a static
    inline helper, used for the reverse event mapping too (Loic Poulain)
  - Removed mtk_pci_ack_dev_state(), which has no caller in the series
    (Sashiko)
  - mtk_pci_probe() saves and stores the PCI state before
    pci_set_master(), so the restore in remove() no longer re-enables bus
    mastering; remove()'s pci_clear_master() is gone (Sashiko)
  - Added .shutdown, which runs the remove() teardown and reset; without
    it a kexec reboot left the firmware running with its one-shot boot
    notification already consumed (Sashiko)
  - Comments: irq_cb_lock covers irq_cb_list[] and the irq_cb_data[]
    store; a device misreporting its BAR sizes is out of scope rather
    than impossible (Sashiko)
  - Still no pci_resource_len() checks: the kernel assumes a device
    behaves to its specification, and the BAR sizes of the two bound
    products are fixed in hardware (Sashiko)
  - The probe error path disables the ATR tables it enabled; removed a
    leftover probe-time pci_restore_state(), an unused include and a
    duplicate mdev->dev store; file-local helpers are static
  - remove(): warn if the ACPI reset fails with the link already down,
    sleep only after a doorbell that was actually sent, and poll up to 1 s
    for the device before restoring its config space
  - Clear MHCCIF level 1 before reading level 2, so an event raised while
    the work runs is not lost
  - pci_driver.name is KBUILD_MODNAME; .class and .class_mask are named in
    the ID table; parameter and registration errors return
    -EINVAL/-EBUSY/-ENOENT instead of -EFAULT
  - Commit message and kernel-doc: the doorbell fallback also covers a
    failing MRST._RST, every shutdown resets the modem, and the MHCCIF
    callback registration states its context rules
- Patch 2 (Add control plane transaction layer framework):
  - Removed the unused mtk_ctrl_trans.ctrl_blk back-pointer
- Patch 3 (Add control DMA interface):
  - mtk_cldma_rx_done_work(): the buffer-reload and DMA-mapping-error
    exits go through the need_restart handling, so a queue waiting for a
    restart is not left stalled (Sashiko)
  - Removed the BD (multi-descriptor) CLDMA path, its DMA pool and the
    frag_size fields: every queue has MTU == frag_size, so it never ran
  - Removed dead code: 30 unread register-table fields, a duplicate
    queue-count macro, an MTU self-compare, a single-pass do/while, a stub
    dev_start(), the rx_done() -EAGAIN retry loop and its force_recv
  - rearm_lock, introduced here, serialises the instance reset and re-arm
    against RX resume/restart and TX kicks; a re-armed TX queue starts at
    the first descriptor the device still owns
  - A re-arm that leaves a started TX queue stopped is no longer a failed
    recovery; a failed TX start with a dead link fails its requests at
    once; a DISABLE flush no longer fails an ENABLE queued behind it
  - The RX worker re-queues itself when a refill fails; the RX cursor high
    word is re-read and an all-ones half treated as link loss
  - const register and queue tables; trans->available is a bool under
    submit_lock; queue numbers print with %u; static_assert() that struct
    trb still fits in skb->cb
- Patch 4 (Add control port):
  - mtk_port_status_update(): reject a port-enumeration message shorter
    than its header; the only length check came after three header reads
    (Sashiko)
  - Stamp the TX sequence number when the trb thread hands the packet to
    CLDMA and advance it only on success, so a packet that fails after it
    was queued takes no number instead of leaving a gap (Sashiko)
  - mtk_port_check_rx_seq(): skip the check only while rx_seq holds a
    reset sentinel, warn rate-limited and always deliver; a stored 0
    disabled the check, and a gap dropped a valid packet (Sashiko)
  - Port state transitions use test_and_set_bit()/test_and_clear_bit()
    (Sashiko)
  - Commit message: the port-state, RX dispatch and TRB kref paths only
    become live with the FSM patch, together with the teardown order they
    rely on (Sashiko)
  - Comments: tx_seq has a single writer, at hardware hand-off; a receive
    callback and its argument must stay valid until the receive path is
    drained, because close alone does not wait (Sashiko)
  - The raw port pointers in trb->priv and rxq->arg are safe, and a failed
    channel disable is only logged: the queues and trb services are torn
    down before the ports are freed (Sashiko)
  - Removed dead code: the cdev RX buffering fields, trb->hdr_added, the
    port counter, a duplicated completion callback and two macros that hid
    a continue
  - The blocking write waits with wait_event_interruptible() and its
    result follows the TRB outcome; the PORT_S_FLUSH exit that reported a
    full write is gone
  - RX dispatch drops a packet whose channel peer does not match the
    receiving CLDMA instance; mtk_port_strip_header() uses pskb_may_pull()
    and does the pull; RX warnings are rate-limited
  - The internal receive callback is published with release/acquire
    ordering; control skbs are sized for their payload, not the queue MTU
  - Comments: a port must outlive the trbs and RX queues holding its
    pointer; PORT_S_FLUSH has one setter; status bits are state, not locks
- Patch 5 (Add FSM thread):
  - mtk_cldma_dev_exit(): call dma_pool_destroy() unconditionally; a pool
    with blocks outstanding keeps its pages anyway, so the special case
    only leaked the struct dma_pool (Sashiko)
  - mtk_cldma_rearm_queues(): never restart a queue that is being
    stopped, and do nothing once the instance is quiesced; the quiesce
    uses drain_workqueue() (Sashiko)
  - mtk_fsm_startup_act(): on a handshake error unmask only that
    handshake's channel, and re-check the event gate after unmasking so a
    callback racing removal cannot undo its masking (Sashiko)
  - A MUST_SUPPORT feature carries no host data, so HS3 still echoes it
    back with data_len 0; a comment there says why no per-feature handler
    table is needed (Sashiko)
  - Removed the per-transition KOBJ_CHANGE uevent (non KEY=VALUE payload,
    no consumer) and mtk_utility.h with it
  - Removed dead code: the pre-transition notifier list and its register
    parameter, the event mdev and len fields, an impossible hs_id check,
    an unreachable DEV_ADD state and mtk_fsm_start()
  - mtk_fsm_evt_submit() returns 0 or a negative errno instead of private
    codes, always allocates with GFP_ATOMIC, and probe passes its error on
  - QUEUE_ERROR is no longer re-unmasked from the ISR; txq/rxq_free()
    clear the latched error and flush err_work after the final mask; a TX
    stop failing with -ENODEV counts as stopped
  - One HS2 handler for both peers, its duplicate guard claimed by
    cmpxchg(); mtk_fsm_exit() reuses mtk_fsm_stop(); the MHCCIF callbacks
    unmask through a gate-aware helper
  - pcie/mtk_trans_ctrl.h no longer includes mtk_port.h
- Patch 6 (Add AT & MBIM WWAN ports):
  - mtk_port_common_write(): in blocking mode wait on the port's trb wait
    queue for HIF queue space instead of bypassing the depth check; v10
    had left the blocking path with no bound (Sashiko)
  - mtk_port_enable_by_type() walks the port table in place and clears
    port->enable before enabling; the blocking TX wait returns
    -ERESTARTSYS; the tx_mtu guard rejects a header-only MTU
- Link to v10: https://patch.msgid.link/20261014-t9xx_driver_v1-v10-0-4d0dde3613f5@compal.com

Changes in v10:
- Patch 1 (Add PCIe core):
  - Kconfig: depends on PCI && ACPI -> PCI_MSI && ACPI; the driver only
    ever requests MSI-X, so a CONFIG_PCI_MSI=n build linked but could
    never probe
  - t9xx_pci_table[] uses PCI_VENDOR_ID_MEDIATEK in place of the
    private MTK_PCI_VENDOR_ID define, matching t7xx
  - Dropped CEI_PCI_VENDOR_ID, which named the wrong company; the
    second entry is a bare 0x03f0 with an /* HP RMM-G4 */ comment and
    the commit message now names both bound products
  - ATR inbound WIN0 source address: pci_resource_start() ->
    pci_bus_address(); the endpoint matches a PCI bus address, not a
    CPU physical address
  - mtk_pci_bar_init() comment: the MSI-X window reaches 0x3103, not
    0x3080, and the fixed offsets are guaranteed by the only two
    devices this driver binds, whose BAR sizes are fixed by hardware
  - mtk_pci_unregister_irq() publishes the NULL callback under
    irq_cb_lock before synchronize_irq() and clears irq_cb_data only
    afterwards, so a live callback cannot be paired with NULL data
  - mtk_pci_free_irq() sets priv->irq_cnt = 0 after
    pci_free_irq_vectors(), so mtk_pci_get_virq_id() stops handing out
    virqs for vectors that no longer exist
  - mtk_pci_remove() frees the IRQ vectors before mtk_mhccif_exit(),
    the order the probe error path already used, so the unmask at the
    tail of mtk_mhccif_isr_work() cannot re-open the source
  - mtk_pci_remove() calls pci_restore_state() and pci_clear_master()
    after pci_load_and_free_saved_state(): the reset leaves the device
    at power-on defaults and the state was saved after pci_set_master()
  - mtk_pci_remove() sleeps after the MHCCIF reset doorbell, which
    unlike MRST._RST returns before the device has reset, so the config
    restore needs it to settle first
  - Commit message: MRST._RST is a platform-level reset that does not
    depend on firmware state, and the MHCCIF doorbell is a best-effort
    fallback that cannot recover stopped firmware
  - The three ACPI capability checks in mtk_pci_pldr_setup() are
    dev_dbg() rather than dev_err(): probe does not require MRST._RST,
    and without it only removal is degraded
  - Removed mtk_pci_clear_ext_evt() and its prototype; Patch 5 removed
    both callers, leaving no user in this series
  - Declined a read-back after the MHCCIF mask write: the posted write
    is followed by synchronize_irq(), which orders it
  - Deferred .shutdown to the follow-up series, where it lands together
    with dev_pm_ops
- Patch 2 (Add control plane transaction layer framework):
  - Subject gains "framework", and the commit message says
    mtk_ctrl_init() and mtk_ctrl_exit() get their first callers in
    Patch 3; the patch is unreachable at its own commit by construction
  - mtk_ctrl_init() kerneldoc: ctrl_blk is devres managed, so it is
    released at unbind and not by mtk_ctrl_exit()
  - mtk_ctrl_blk::ctrl_hw_priv is void * from the start, instead of a
    PCIe-specific type in a generic header
  - <linux/kref.h> is no longer added here; Patch 4 adds it together
    with struct trb::kref, its first user, so Patch 3 no longer has to
    delete it again
- Patch 3 (Add control DMA interface):
  - BD-mode RX clamps each BD's received length with the host-side
    req->frag_size as well as the device-written data_allow_len, so an
    oversized device value cannot overrun the buffer
  - mtk_cldma_rx_done() retries mtk_cldma_reload_rx_skb() on the next
    pass and re-arms the slot, instead of leaving a slot whose second
    reload failed marked complete
  - mtk_cldma_reload_rx_skb() frees the skb and clears both req->skb
    and req->data_dma_addr on dma_map failure, so the retry does not
    re-map a stale address
  - mtk_cldma_rxq_free() stops the RX queue again after the flush
    unless the stop returned -ETIMEDOUT; rx_done_work can resume or
    restart the engine after it read need_exit
  - mtk_cldma_rearm_queues() clears tx_started instead of starting TX
    from req_pool[free_idx], which can already be complete, and queues
    tx_done_work so a lost XFER_DONE still advances free_idx
  - mtk_cldma_start_xfer() stops the queue and clears tx_started on
    failure, so mtk_cldma_txq_flush() does not run against a queue the
    hardware still owns
  - mtk_cldma_drv_reset() writes only this CLDMA's bit to RST0_SET and
    RST0_CLR instead of read-modify-writing the whole bank, and reads
    each register back to flush the posted write
  - That reverses the answer already sent for the reset sequencing
    question: the read-modify-write on RST0_CLR releases every other
    block held in reset in the same bank
  - mtk_ctrl_srv_exit() calls mtk_ctrl_chs_flush(srv) right after
    kthread_stop() instead of at the thread's tail, so queued TRBs are
    flushed even when the thread never ran
  - DISABLE insertion tracks the last ENABLE and __skb_queue_after()
    it; with no ENABLE present it falls back to __skb_queue_head()
    rather than the tail
  - trans->queue_tbl is an xarray instead of a radix_tree, which
    removes the radix_tree_delete() inside a radix_tree_for_each_slot()
    walk and the missing rcu_read_lock()
  - struct trb::kref moved out of mtk_ctrl_plane.h into Patch 4, where
    mtk_port_trb_init() first takes the reference, rather than taking
    the reference earlier here
  - mtk_ctrl_trb_handler() publishes trb->status with
    smp_store_release(), pairing with the port layer's
    smp_load_acquire() so it cannot be seen before the geometry stores
  - mtk_cldma_open() keeps the usr_cnt increment when the open
    completes -EBUSY, with a comment at the decrement: -EBUSY leaves
    the channel open, so its eventual DISABLE releases the count
- Patch 4 (Add control port):
  - mtk_ctrl_init() drops the err_free_mem label, which freed nothing,
    and clears mdev->ctrl_blk on failure so probe does not leave a
    dangling block behind
  - The cfg pointers are const through mtk_port_layer_cfg and the port
    table helpers, which also removes the (struct mtk_port_cfg *) cast
    on .port_cfg
  - Driver prefix on three globals: mtk_port_mngr_grp_mtx, struct
    mtk_port_ops, and a static mtk_port_ops_tbl[] behind
    mtk_port_get_ops() in place of the exported ports_ops[] table
  - Removed the MTK_TRB_HEADER_ADDED (0xADDED) in-flight sentinel,
    which made a blocking write return 712173 as a byte count; struct
    trb carries explicit bools and that write returns -EBADF
  - mtk_port_trb_done() reads smp_load_acquire(&trb->done), set by
    smp_store_release() in all three completions, instead of inferring
    completion from a status written before the callback ran
  - The queue geometry copy moved from mtk_port_open_trb_complete() to
    mtk_port_ch_enable() after the wait, and runs for -EBUSY too, so
    such an ENABLE publishes tx_mtu like any other
  - Deleted the empty mtk_port_io_init()/mtk_port_io_exit(), so this
    patch no longer rewrites pcie/mtk_pci.c at all; the commit message
    documents the trb kref instead
  - mtk_port_get_by_name() does the lookup and the kref_get() in one
    critical section; mtk_port_search_by_name() is static and gains
    lockdep_assert_held()
  - mtk_port_add_header() calls skb_cow_head() before skb_push() and
    returns the error instead of dropping it
  - The tx_seq rollback samples seq_taken into a local first, with a
    comment that the kref_put()s below it free the skb that trb lives
    in
  - port->tx_seq = 0 / rx_seq = -1 moved from mtk_port_struct_init() to
    the top of mtk_port_ch_enable(), so CCCI sequence numbering
    restarts with each modem session
- Patch 5 (Add FSM thread):
  - mtk_fsm_idle_evt_handler() returns void, so the handshake channels
    are unmasked whether or not the STARTUP submit succeeded; the old
    early return left them masked forever
  - mtk_fsm_hs1_handler() masks the channel before the submit and
    unmasks it again on failure, so it cannot overwrite a re-arm the
    FSM thread just did on its error path
  - Removed both mtk_pci_clear_ext_evt() calls; the ISR already
    acknowledges the MHCCIF event, so the handlers were acking twice
  - mtk_cldma_dev_exit() leaves the CLDMA vector masked after the reset
    so the ISR tail cannot re-open it, and moves the WRITE_ONCE()
    unpublish to the top, where the comment claims it is
  - mtk_cldma_txq_free()/mtk_cldma_rxq_free() mask QUEUE_XFER_DONE and
    QUEUE_ERROR first, clear the latched error bit, flush err_work then
    the worker, and mask XFER_DONE once more after that final flush
  - mtk_cldma_err_work() is split into mtk_cldma_err_tx_one() and
    mtk_cldma_err_rx_one(), so an early exit on the TX side cannot skip
    the RX error carrying the same index
  - mtk_cldma_rxq_restart() does the stop itself and leaves the queue
    stopped on failure, so the restart is the only context that
    programs an RX queue
  - TX submit returns early on -EPIPE instead of falling into the
    flush, which would unmap buffers err_work kept for the device, and
    re-checks is_stopping under ring_lock before publishing a new HWO
  - Added mtk_cldma_drv_quiesce() and exported mtk_cldma_quiesce();
    mtk_pcie_hif_exit() calls it before joining the trb services, which
    the IRQ handler and the workqueue read as well
  - mtk_cldma_exit() comment corrected: not all of its callers hold
    submit_lock
  - The dma_pool_destroy() comment now says it releases the backing
    pages even when blocks are outstanding, so the rings are leaked
    deliberately, bounded by the device instance and reported
  - mtk_fsm_feature_set_match() gained comments on three arms: a
    mandatory feature is fatal only on an outright refusal, and the
    backward-compat arm decides on the device's declaration alone
- Patch 6 (Add AT & MBIM WWAN ports):
  - mtk_port_common_write() caps one write() at MTK_PORT_MAX_TX_PKT
    packets and rejects more with -EMSGSIZE; packets after the first
    carry force_send, which bypasses the HIF depth check
  - force_send starts out as the blocking flag, so a blocking fd no
    longer gets -EAGAIN on its first packet and the blocking worst case
    is one queue depth rather than depth - 1
  - mtk_port_common_write() reports the prefix already on the wire with
    dev_err_ratelimited() when a submit fails mid-message, and samples
    skb->len before the submit, which may free the skb
  - Its comment states why that write is not made atomic: the WWAN
    core already turns a partial write into a whole-write failure, and
    the failed submit cannot be retried once the skb is freed
  - mtk_port_wwan_tx_pause() drops w_lock around
    mtk_pcie_hif_cmd_func(), which takes submit_lock; teardown holds
    submit_lock while calling back into this port under w_lock
  - mtk_port_wwan_open() publishes w_priv.w_port in the same critical
    section that sets PORT_S_OPEN, so mtk_port_wwan_recv() cannot see
    an open port with a NULL w_port and drop a reply
  - mtk_port_get_locked() returns void and only takes the reference;
    the WWAN core owns the port pointer across its .start/.stop pair
- Link to v9: https://patch.msgid.link/20260930-t9xx_driver_v1-v9-0-3248b9256956@compal.com

Changes in v9:
- Patch 1 (Add PCIe core):
  - Dropped the priv->irq_type term from the mask/unmask/clear IRQ
    guards; the field was write-only and made the probe-failure path
    log a false "input irq_id=28" error
  - mtk_pci_pldr() no longer requests an ACPI_ALLOCATE_BUFFER output
    buffer from acpi_evaluate_object(): nothing read it and the
    failure branch leaked it
  - mtk_mhccif_exit() masks the MHCCIF source again after
    cancel_work_sync(), so a work item already past the unregister
    cannot leave remove() with an unmasked source and no callback
  - pcim_enable_device() -> pci_enable_device(), with explicit
    pci_clear_master()/pci_disable_device() in remove(): the devres
    action touched config space after the ACPI reset
  - The AER handler prints pci_channel_state_t with %u
  - Deleted struct mtk_dev_ops and the mtk_dev_* inline wrappers;
    every caller uses the mtk_pci_* implementation directly, and
    mtk_dev_get_dev_cfg()/mtk_pci_get_dev_cfg() are gone (no callers)
  - Single module: mtk_dev.c, pcie/Makefile and CONFIG_MTK_T9XX_PCI
    are gone, driver init/exit live in pcie/mtk_pci.c, and every
    EXPORT_SYMBOL_GPL is removed with the module boundary
  - Removed the PCI dispatch-by-hw_ver table; there is one
    implementation and it is called directly
  - Declined a BAR length sanity check: the driver binds two fixed PCI
    IDs and pcim_iomap_region() already fails probe for the
    generically detectable cases
  - Declined reordering the probe unwind to match remove(): probe
    unwinds in reverse acquisition order, remove() deviates
    deliberately and the reason is commented at the call site
  - No delay added after the reset: MRST._RST is an ACPI method, so
    acpi_evaluate_object() returns when the AML has finished, and it
    is the last device access in remove()
  - Removed the PCIe PM registers and the MHCCIF PM/DPMAIF/CLDMA
    channel bits; nothing in this series reads them
  - Removed the unused IRQ sources, MTK_USER_MIN/DATA, DEV_EVT_*_MAX,
    ATR_DST_AXIM_1-3 and the <linux/debugfs.h> include
- Patch 2 (Add control plane transaction layer):
  - Deleted struct mtk_ctrl_hif_ops and ctrl_blk->ops with the rest of
    the single-implementation dispatch layers; mtk_ctrl_blk now holds
    only mdev and trans
- Patch 3 (Add control DMA interface):
  - Deleted struct cldma_drv_ops, drv_info->drv_ops,
    cldma_drv_info_tbl[] and mtk_cldma_drv_m9xx.c/.h; the register
    table stays as data and is assigned directly in dev_init()
  - Deleted pcie/mtk_ctrl_cfg_m9xx.c: the queue, service and port
    tables are file-scope statics in pcie/mtk_trans_ctrl.c and the
    hw_ver lookup is gone
  - REG_CLDMA_INT_WF_MASK is no longer introduced here; it had no
    reader and Patch 5 used to remove it again
  - Removed CLDMA_GPD_FLAG_BPS, enum mtk_ip_busy_src, DIR_MAX, unused
    mtk_intr_type members, six reg_* fields and the *_done_cnt counters
  - mtk_cldma_txq_alloc()/rxq_alloc() take the queue_info the caller
    already resolved, dropping a repeated lookup that cannot fail
- Patch 4 (Add control port):
  - Deleted the stale-list and device-id-IDA machinery instead of
    hardening it: nothing here can reach the stale list and dev_id was
    only handed back to ida_free(), so both reported call sites are gone
  - mtk_port_tbl_destroy() uses the file's own radix-tree accessor
    (rcu_dereference_raw()); radix_tree_deref_slot() splats under
    CONFIG_PROVE_RCU in this lock-free teardown
  - Added port_mngr->port_tbl_mtx around the radix insert/delete and
    the port_cnt update, and struct mtk_port gained a rcu_head so
    mtk_port_release() frees with kfree_rcu()
  - Removed PORT_F_ALLOW_DROP (set, never read) and PORT_F_FORCE_SEND
    (read, never set, so the term was provably zero)
  - mtk_port_internal_disable() logs a failed mtk_port_ch_disable()
    with dev_warn(); teardown still continues and PORT_S_ENABLE is
    still cleared, or the port could never re-enable
  - clear_bit(PORT_S_WR) in mtk_port_internal_disable() is followed by
    wake_up_all(): the blocking writer loops back on timeout and
    otherwise only noticed one trb timeout later
  - mtk_ctrl_init() takes a struct mtk_port_layer_cfg * directly, the
    struct mtk_ctrl_cfg wrapper is gone, and mtk_port.c calls
    mtk_pcie_hif_submit_skb() instead of dispatching through ops
  - Removed the Q_MTU_*/Q_FRAG_* sizes no queue uses, MTK_PEER_ID_SAP
    and _MD, and PORT_S_DFLT/PORT_S_RD/PORT_S_STOP
- Patch 5 (Add FSM thread):
  - mtk_pcie_hif_exit() stops the TRB service kthreads before
    mtk_cldma_exit() frees the rings they walk; the two wake_up()
    sites skip a NULL trb_srv so the reorder cannot oops instead
  - One owner per direction on error: err_work sets txq->is_stopping
    under ring_lock and mtk_cldma_start_xfer() rechecks it there, and
    the RX side hands the queue to rx_done_work through need_restart
  - mtk_cldma_rx_done_work() consumes need_restart before honouring
    -ENXIO, so a queue left with no start address after a reset is
    restarted instead of skipped
  - The RX length is clamped against req->mtu (host state) instead of
    the GPD's data_allow_len, and an oversized frame is dropped with
    -EPROTO
  - fsm->hif_err became a per-producer array and the recorder stores
    unconditionally, so a successful handshake retry clears its own
    slot instead of refusing FSM_STATE_READY forever
  - The invalid dev_stage path of mtk_fsm_early_bootup_handler() uses
    goto exit, re-arming the boot-flow channel that was masked on
    entry
  - Both CLDMA dma_pools are created with align 16; with align 4 the
    24-byte descriptors were only 8-byte aligned every other block
  - cldma_drv_info[] is published with smp_store_release() and read
    with smp_load_acquire(); the removal sites and the txq/rxq slots
    use WRITE_ONCE(), completing the pairing already used elsewhere
  - struct runtime_feature_entry is __packed: offset advances by a
    device-supplied length, so a later entry's data_len can land
    unaligned. The layout is unchanged
  - Removed MTK_UEVENT_MINIDUMP and MTK_UEVENT_LOWPOWER, declared with
    no emitter anywhere in the series
  - Commit message rewritten to cover the CLDMA scope: the ISR, the
    QUEUE_ERROR worker and its -EPIPE completion policy, the
    ring_leaked rule, the teardown changes and the FSM uevent payload
  - Kept the uevent rather than reporting state through the wwan
    framework: wwan exposes ports and netdevs, neither carries a
    driver state machine, and adding one is a core change
  - Declined splitting the CLDMA work into its own patch: the ISR is
    registered by dev_init(), which only the FSM listener added here
    calls, so either split order leaves a non-functional commit
  - mtk_fsm.c calls mtk_pci_* directly and its six EXPORT_SYMBOL_GPL
    are removed
  - Removed FEATURE_TYPE_MUST/OPTIONAL, FSM_PRIO_0, MTK_UEVENT_UNDEF
    and _MAX, DEV_CFG_NORMAL, QUERY_RTFT_ID_MAX and the TAG define
- Patch 6 (Add AT & MBIM WWAN ports):
  - Dropped .tx_poll: it poll_wait()ed on a waitqueue inside struct
    mtk_port, which wwan_remove_port() releases while the fd stays
    open, and wake_up_pollfree() is not available to modules
  - TX back-pressure now reaches poll() through wwan_port_txon() and
    wwan_port_txoff() on the core's waitqueue, whose lifetime the open
    file pins; this also removes the errno/queue-full poll confusion
  - mtk_port_common_write() builds every CCCI packet onto a local
    queue before submitting any, so an allocation or copy failure can
    no longer truncate a message whose first packets are on the wire
  - caps.frag_len is tx_mtu minus the CCCI header, so one core
    fragment is exactly one CCCI packet instead of a full packet plus
    a 16-byte runt
  - w_lock now covers PORT_S_OPEN on the wwan ops: a receive that saw
    the port open completes wwan_port_rx() before stop() returns and
    the core purges its rx queue
  - clear_bit(PORT_S_WR) in mtk_port_wwan_disable() is followed by
    wake_up_all(), and a failed mtk_port_ch_disable() is logged with
    dev_warn() as in Patch 4
  - Commit message corrected: init() only prepares the port object,
    wwan_create_port() is in enable(), which FSM_STATE_READY reaches
    through the new mtk_port_enable_by_type(PORT_TBL_MD) hook
  - w_port is still published after PORT_S_ENABLE/PORT_S_WR: it is
    wwan_create_port()'s return value and the node becomes openable
    inside that call, so a comment now records the -ENXIO window
  - The AT/MBIM port and queue rows are added directly to the
    file-scope tables in pcie/mtk_trans_ctrl.c, and mtk_port_io.c
    calls mtk_pcie_hif_cmd_func() directly
- Link to v8: https://patch.msgid.link/20260914-t9xx_driver_v1-v8-0-5206c2e6bea0@compal.com

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
      net: wwan: t9xx: Add control plane transaction layer framework
      net: wwan: t9xx: Add control DMA interface
      net: wwan: t9xx: Add control port
      net: wwan: t9xx: Add FSM thread
      net: wwan: t9xx: Add AT & MBIM WWAN ports

 MAINTAINERS                                 |   11 +
 drivers/net/wwan/Kconfig                    |   11 +
 drivers/net/wwan/Makefile                   |    1 +
 drivers/net/wwan/t9xx/Makefile              |   16 +
 drivers/net/wwan/t9xx/mtk_ctrl_plane.c      |  111 ++
 drivers/net/wwan/t9xx/mtk_ctrl_plane.h      |   82 ++
 drivers/net/wwan/t9xx/mtk_dev.h             |   43 +
 drivers/net/wwan/t9xx/mtk_fsm.c             | 1085 +++++++++++++++++
 drivers/net/wwan/t9xx/mtk_fsm.h             |  153 +++
 drivers/net/wwan/t9xx/mtk_port.c            |  762 ++++++++++++
 drivers/net/wwan/t9xx/mtk_port.h            |  149 +++
 drivers/net/wwan/t9xx/mtk_port_io.c         |  642 ++++++++++
 drivers/net/wwan/t9xx/mtk_port_io.h         |   33 +
 drivers/net/wwan/t9xx/pcie/mtk_cldma.c      | 1689 +++++++++++++++++++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_cldma.h      |  128 ++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.c  |  505 ++++++++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.h  |  118 ++
 drivers/net/wwan/t9xx/pcie/mtk_pci.c        | 1106 ++++++++++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_pci.h        |  139 +++
 drivers/net/wwan/t9xx/pcie/mtk_pci_reg.h    |   35 +
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c |  673 +++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h |   88 ++
 22 files changed, 7580 insertions(+)
---
base-commit: eb3f4b7426cfd2b79d65b7d37155480b32259a11
change-id: 20260529-t9xx_driver_v1-1744f8af7739

Best regards,
--  
Jack Wu <jackbb_wu@compal.com>

