From: Vincent Choiniere <choiniere.vincent@hydroquebec.com>
Date: Thu, 12 Nov 2026 13:45:56 -0500
Subject: [PATCH net v4] ice: fix Tx hang dump using stale tx_buf[0].skb
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-ice-tx-hang-dump-v4-1-9125f687669b@hydroquebec.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XPS27DIBAG4KtErEvFgE3irHKPKAtghphKxgnYV
 qLIdy92F61UZzmv79e8WKYUKLPj7sUSTSGHPpai+tgx15p4JR6w1EwKqUGA5sERHx58mXEcuxu
 nStuKsDoo1Kyc3RL58FjJM4s0sMtPM4/2i9ywYMtaG/LQp+caPMG6/D5jAg5coRe+bvaNqeHUP
 jH195EsuU/Xd2vIJP8wcouRhSEJSpOXrka3zahfBsR+g1GFOXgpQTQIxuB/Zi6ONZm4TSa6dnm
 6MyGyef4GdQx+uXIBAAA=
X-Change-ID: 20261016-ice-tx-hang-dump-e46b4ed483d6
To: Tony Nguyen <anthony.l.nguyen@intel.com>, 
 Przemek Kitszel <przemyslaw.kitszel@intel.com>, 
 intel-wired-lan@lists.osuosl.org
Cc: Aleksandr Loktionov <aleksandr.loktionov@intel.com>, 
 Michal Kubiak <michal.kubiak@intel.com>, 
 Wojciech Drewek <wojciech.drewek@intel.com>, 
 Mateusz Polchlopek <mateusz.polchlopek@intel.com>, 
 Paul Menzel <pmenzel@molgen.mpg.de>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 Vincent Choiniere <choiniere.vincent@hydroquebec.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794509155; l=18204;
 i=choiniere.vincent@hydroquebec.com; s=20261016; h=from:subject:message-id;
 bh=g6IwZkTyRnjwRh6+ILNEBc+G9HEKzOlDA0Y4fToAutU=;
 b=A3Mv/Y/mBLOWtu7/ZX/TorT81UUgSssH26ZNwXLLNX/5EYDhYzgmqOBIJhRknrEa/54u381lU
 WWPXYIerUsSCJRKe1PKXtkx+c+vPF1G6+yUwag76SqmyY02vfeDRgwF
X-Developer-Key: i=choiniere.vincent@hydroquebec.com; a=ed25519;
 pk=MctQE067DucsZOaNqb+sjY7aQ+urhztuURanagEW3+8=
X-Endpoint-Received: by B4 Relay for choiniere.vincent@hydroquebec.com/20261016 with auth_id=1210
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ice_tx_hang_reporter_dump() always reads tx_ring->tx_buf[0].skb,
regardless of next_to_clean. The Tx cleanup path frees the skb and
marks the buffer empty without clearing the skb pointer, so slot 0 can
hold a stale pointer. A NULL check alone does not cover this, and
devlink_fmsg_dump_skb() can fault on the freed skb.

Using tx_buf[next_to_clean] alone does not fix the lifetime issues.
The dump runs from the service task without synchronization with Tx
cleanup or ring replacement:

- ice_clean_tx_irq() can free the skb at next_to_clean while the
  report is being prepared. It calls napi_consume_skb() before
  marking the buffer empty.
- The ring saved by ice_tx_timeout() can be replaced or freed before
  the service task runs. ethtool -G replaces the ring contents and
  frees tx_buf and desc, while ethtool -L can free whole rings.

Record the queue index, next_to_clean and next_to_use at timeout time.
Before reporting, take RTNL and check that the timeout was on the PF
VSI, that the VSI is up and that the timed-out queue still maps to the
saved ring. A freed ring can be reused for another queue, so a pointer
match alone is not enough. Copy the descriptors and IRQ name while the
ring storage is protected against replacement. If the check fails or
the copy cannot be made, report only the values recorded at timeout
time.

As before this patch, a successful snapshot shows the ring when the
report is generated. A reset of the same queue after the timeout, for
example by ethtool -G or an MTU change, is not detected.

Tx cleanup can still run while the ring state is copied, so do not
dereference the skb. Retain only its pointer value in the dump and
remove the skb contents.

Release RTNL before calling devlink_health_report(), which takes the
devlink instance lock. Build the dump from the copied data and free
the descriptor copy after reporting.

This leaves devlink_fmsg_dump_skb() without users; its removal is left
to a net-next follow-up.

Observed on an E810 PF passed through to a KVM guest with Ubuntu
kernel 7.0.0-14 (PREEMPT_RT and a local scheduler patch): a delayed
queue IRQ led to a Tx timeout and a page fault in
devlink_fmsg_dump_skb():

 BUG: unable to handle page fault for address: 0000000004cd0c11
 Workqueue: ice ice_service_task [ice]
 RIP: devlink_fmsg_dump_skb+0x2d8/0x5d0
 Call Trace:
  ice_tx_hang_reporter_dump+0x1ce/0x210 [ice]
  devlink_health_do_dump+0xcc/0x190
  devlink_health_report+0x1d7/0x260
  ice_report_tx_hang+0x7d/0xa0 [ice]

Fixes: 2a82874a3b7b ("ice: add Tx hang devlink health reporter")
Link: https://lore.kernel.org/all/20260327072332.130320-1-aleksandr.loktionov@intel.com/
Cc: stable@vger.kernel.org
Reviewed-by: Przemek Kitszel <przemyslaw.kitszel@intel.com>
Signed-off-by: Vincent Choiniere <choiniere.vincent@hydroquebec.com>
---
Changes in v4:
- Use the saved ring only if the timeout was on the PF VSI and the
  timed-out queue still maps to it. A pointer match alone accepted a
  freed ring reused for another queue (Sashiko).
- Read the saved ring pointer before taking RTNL, alongside the
  timeout-time values, as before this patch. This avoids rereading
  the pointer after the RTNL wait, but does not make the event
  snapshot atomic (Sashiko).
- Clarify that a successful snapshot shows the ring at report time,
  as before, and that a reset of the same queue is not detected.
  v3 implied that ring replacement was detected (Sashiko).
- Carry Przemek's Reviewed-by; the only code changes are the VSI/queue
  check and the saved pointer read above.
- Leave removal of the unused devlink_fmsg_dump_skb() export to a
  net-next follow-up, and say so in the commit message (Sashiko).
- Document the pre-existing reload deadlock separately under
  Limitations.
- Run hardware tests of v4; see "Testing of v4". The v2 stress
  campaign was not repeated.

Changes in v3:
- Glue the kvfree() of the descriptor copy to the preceding if as an
  else (Przemek).
- Reword the ice_tx_hang_snapshot() kernel-doc: it said the rings are
  only replaced or freed under RTNL or from the service task, which does
  not hold for driver removal and devlink reload (Sashiko). No code
  change for this.
- Carry Przemek's Reviewed-by; the only code change is the else above.
- Move the AI-assistance attribution from the commit trailers to
  the notes below.

Changes in v2:
- Validate the saved ring under RTNL before dereferencing it from
  the service task, and restrict snapshots to the PF VSI while it
  is up (Sashiko).
- Check next_to_clean against count before indexing tx_buf, and
  copy the descriptors and IRQ name while ring replacement is
  excluded (Sashiko).
- Stop dereferencing the skb and remove its contents from the dump.
  Keep only its pointer value (Sashiko).
- Release RTNL before reporting to preserve the devlink instance
  lock ordering.
- Record the queue index and ring indices at timeout time as a
  fallback when a snapshot cannot be made.
- Drop Paul's Reviewed-by because the patch changed substantially.

v3:
https://lore.kernel.org/all/20261107-ice-tx-hang-dump-v3-1-8f22109d1aad@hydroquebec.com/

v2:
https://lore.kernel.org/netdev/20261026-ice-tx-hang-dump-v2-1-e2136ef2c5dc@hydroquebec.com/

v1:
https://lore.kernel.org/netdev/20261016-ice-tx-hang-dump-v1-1-3df0f5979a51@hydroquebec.com/

AI assistance: Claude (claude-sonnet-5-5) for earlier revisions;
Copilot for the v4 queue validation and pointer-read changes, review
analysis, and commit message and revision notes.

Testing of v4:
- Built all ice objects and linked ice.o on the exact base below with
  x86_64 defconfig, CONFIG_ICE=m, GCC 15.2.0, W=1 and sparse C=2
  (sparse git 84ec065).
  The compiler and sparse reported no warnings or errors.
- checkpatch --strict on the full patch: 0 errors, warnings or checks.
- Runtime tests used a backport, not the exact net tree. The ice module
  was built from upstream v7.0 with the v4 changes to
  ice_tx_hang_snapshot() and ice_report_tx_hang(), plus an unrelated PTP
  lifetime fix, and run on an E810 PF passed through to a KVM guest with
  a PREEMPT_RT 7.0.0-38 kernel, KASAN, PROVE_LOCKING and
  DEBUG_ATOMIC_SLEEP.
- Test-only hooks stop Tx cleaning on one queue of the test PF and delay
  ice_report_tx_hang() or the dump callback. The stall is released at
  the first timeout, so recovery stayed at a PF reset. A racing command
  was started when the hook logged its delay.
- Forced Tx timeout with automatic dump: 3 runs, complete dump.
- ethtool -G tx 64 while ice_report_tx_hang() was delayed: 2 runs, the
  dump showed the replaced ring.
- ethtool -G tx 64 while the dump callback was delayed: 2 runs, the dump
  was built from the copy.
- ethtool -L combined 1 while ice_report_tx_hang() was delayed: 4 runs.
  The channel change is refused while RDMA is active, so irdma was
  unbound from the test PF through sysfs first. The report then
  contained only head, intr, vsi_num, queue, next_to_clean and
  next_to_use, without the ring-derived fields.
- No KASAN, lockdep or sleeping-in-atomic report was seen in these
  runs, and lockdep stayed enabled for the whole boot.
- Reuse of a freed ring by another queue was not reproduced. The
  queue check was compared with ice_vsi_alloc_rings(), where q_index is
  the tx_rings array index. The ethtool -G runs reset the same queue in
  place; as described above, this is not detected and the dump shows the
  ring as it is when the report is generated.
- Other observations during testing, not investigated: the kernel logged
  order-9 allocation failures in irdma during PF recovery, and an
  ip link down/up attempted while a reset was pending produced an RTNL
  assertion warning in ice_dis_vsi() -> ice_vsi_close() on the service
  task reset path.

Testing of earlier revisions:
- Built ice.ko with x86_64 defconfig, CONFIG_ICE=m, GCC 12.2 and W=1.
  Ran sparse with C=2 (sparse git c464045). Neither reported warnings
  in the changed files.
- checkpatch --strict reported only an unknown Fixes commit because
  the local tree is a shallow clone.
- Runtime testing used an E810 PF passed through to a KVM guest with
  Ubuntu kernel 7.0.0-38 (PREEMPT_RT), KASAN, PROVE_LOCKING and
  DEBUG_ATOMIC_SLEEP.
- Forced Tx timeouts by starving one queue's IRQ thread. The watchdog
  fired after five seconds, the PF recovered, and the dump retained
  the v1 fields except for the skb contents.
- Used a test-only kernel patch to insert configurable delays before
  ice_report_tx_hang() or the dump callback. Racing ethtool commands
  were started when the instrumentation logged the delay.
- With v1 and the same instrumentation, shrinking the ring with
  ethtool -G tx 64 while next_to_clean was above 64 triggered a KASAN
  slab-out-of-bounds report. This was also reproduced on a non-RT
  kernel built from net. Racing ethtool -L combined 1 triggered a
  use-after-free followed by a general protection fault.
- With v2, ran 168 forced Tx timeouts, including 149 with concurrent
  ethtool -G (tx 64, 128 or 512) or ethtool -L combined 1, before and
  after the ring state was copied. No KASAN, lockdep or
  sleeping-in-atomic reports were observed. When the saved ring was
  no longer present, the dump contained only the timeout-time values.

Limitations:
- The v4 runs were short: two to four per scenario, not a repeat of the
  168 timeouts run with v2. The same stress testing was not completed
  on a non-RT kernel, where Tx timeouts could not be forced reliably.
- Subfunction VSIs and XDP were not tested. Subfunction VSI rings
  are excluded from the snapshot because ice_sf_dev_remove() frees
  them without RTNL.
- Driver removal and devlink reload still stop the service task only after
  the devlink reporter and the VSIs are torn down, and the service task
  runs the Tx hang report before it checks ICE_SERVICE_DIS. Before this
  patch the same path dereferenced the saved ring with no protection at
  all. The ordering is left to a separate fix.
- DRIVER_REINIT reload can deadlock: it holds the devlink instance
  lock while waiting for the service task to stop, and the service
  task's devlink_health_report() path may need that lock for auto-dump.
  This pre-existing locking issue is left to a separate fix.
- This patch does not synchronize publication and consumption of
  tx_hang_buf between ice_tx_timeout() and the service task. A newer
  timeout may still be dropped or its fields mixed with an older
  event. The ring is only used if it matches the recorded VSI and
  queue.

The original devlink_fmsg_dump_skb() crash was reproduced on Ubuntu
kernel 7.0.0-14 with PREEMPT_RT and a local scheduler patch. The
additional race reproductions above used test-only instrumentation.
The affected reporter code is also present in upstream net at
191aa4154.
---
 drivers/net/ethernet/intel/ice/devlink/health.c | 116 +++++++++++++++++++++---
 drivers/net/ethernet/intel/ice/devlink/health.h |   6 ++
 2 files changed, 108 insertions(+), 14 deletions(-)

diff --git a/drivers/net/ethernet/intel/ice/devlink/health.c b/drivers/net/ethernet/intel/ice/devlink/health.c
index 8e9a8a8178..3909e55b96 100644
--- a/drivers/net/ethernet/intel/ice/devlink/health.c
+++ b/drivers/net/ethernet/intel/ice/devlink/health.c
@@ -382,7 +382,13 @@ struct ice_tx_hang_event {
 	u16 queue;
 	u16 next_to_clean;
 	u16 next_to_use;
-	struct ice_tx_ring *tx_ring;
+	/* the fields below are only valid if @desc is set */
+	char irq_name[ICE_INT_NAME_STR_LEN];
+	void *desc_ptr;
+	dma_addr_t dma;
+	void *desc;
+	u32 desc_size;
+	void *skb_ptr;	/* pointer value only, never dereferenced */
 };
 
 static int ice_tx_hang_reporter_dump(struct devlink_health_reporter *reporter,
@@ -390,12 +396,10 @@ static int ice_tx_hang_reporter_dump(struct devlink_health_reporter *reporter,
 				     struct netlink_ext_ack *extack)
 {
 	struct ice_tx_hang_event *event = priv_ctx;
-	struct sk_buff *skb;
 
 	if (!event)
 		return 0;
 
-	skb = event->tx_ring->tx_buf->skb;
 	devlink_fmsg_obj_nest_start(fmsg);
 	ICE_DEVLINK_FMSG_PUT_FIELD(fmsg, event, head);
 	ICE_DEVLINK_FMSG_PUT_FIELD(fmsg, event, intr);
@@ -403,13 +407,14 @@ static int ice_tx_hang_reporter_dump(struct devlink_health_reporter *reporter,
 	ICE_DEVLINK_FMSG_PUT_FIELD(fmsg, event, queue);
 	ICE_DEVLINK_FMSG_PUT_FIELD(fmsg, event, next_to_clean);
 	ICE_DEVLINK_FMSG_PUT_FIELD(fmsg, event, next_to_use);
-	devlink_fmsg_put(fmsg, "irq-mapping", event->tx_ring->q_vector->name);
-	ice_fmsg_put_ptr(fmsg, "desc-ptr", event->tx_ring->desc);
-	ice_fmsg_put_ptr(fmsg, "dma-ptr", (void *)(long)event->tx_ring->dma);
-	ice_fmsg_put_ptr(fmsg, "skb-ptr", skb);
-	devlink_fmsg_binary_pair_put(fmsg, "desc", event->tx_ring->desc,
-				     event->tx_ring->count * sizeof(struct ice_tx_desc));
-	devlink_fmsg_dump_skb(fmsg, skb);
+	if (event->desc) {
+		devlink_fmsg_put(fmsg, "irq-mapping", event->irq_name);
+		ice_fmsg_put_ptr(fmsg, "desc-ptr", event->desc_ptr);
+		ice_fmsg_put_ptr(fmsg, "dma-ptr", (void *)(long)event->dma);
+		ice_fmsg_put_ptr(fmsg, "skb-ptr", event->skb_ptr);
+		devlink_fmsg_binary_pair_put(fmsg, "desc", event->desc,
+					     event->desc_size);
+	}
 	devlink_fmsg_obj_nest_end(fmsg);
 
 	return 0;
@@ -424,6 +429,78 @@ void ice_prep_tx_hang_report(struct ice_pf *pf, struct ice_tx_ring *tx_ring,
 	buf->vsi_num = vsi_num;
 	buf->head = head;
 	buf->intr = intr;
+	buf->queue = tx_ring->q_index;
+	buf->next_to_clean = tx_ring->next_to_clean;
+	buf->next_to_use = tx_ring->next_to_use;
+}
+
+/**
+ * ice_tx_hang_snapshot - copy the timed-out queue's ring at report time
+ * @pf: PF on which the Tx hang was detected
+ * @tx_ring: ring saved by ice_tx_timeout(), possibly stale
+ * @ev: event to fill in
+ *
+ * The saved ring may have been freed or replaced since the timeout (e.g. by
+ * ethtool -G or -L), and a freed ring may be reused for another queue. Use it
+ * only if the timeout was on the PF VSI, that VSI is up and the timed-out
+ * queue still maps to it. Those paths, and the reset paths, replace or free
+ * the rings under RTNL or from the service task itself, so with RTNL held the
+ * accesses below are to live memory for them. The ring may still have been
+ * reset in place since the timeout (e.g. by ethtool -G or an MTU change); as
+ * before, its state is read when the report is generated. Driver removal and
+ * devlink reload tear the VSIs down before the service task is stopped and are
+ * not covered here. ice_clean_tx_irq() may still run and free the skb at
+ * next_to_clean at any time, so only the pointer value is recorded and the skb
+ * itself is never dereferenced.
+ */
+static void ice_tx_hang_snapshot(struct ice_pf *pf, struct ice_tx_ring *tx_ring,
+				 struct ice_tx_hang_event *ev)
+{
+	struct ice_vsi *vsi = ice_get_main_vsi(pf);
+	struct ice_q_vector *q_vector;
+	struct ice_tx_buf *tx_buf;
+	u16 ntc, ntu;
+	void *desc;
+	u32 size;
+
+	ASSERT_RTNL();
+
+	if (!tx_ring || !vsi || !vsi->tx_rings ||
+	    test_bit(ICE_VSI_DOWN, vsi->state))
+		return;
+
+	if (ev->vsi_num != vsi->vsi_num || ev->queue >= vsi->num_txq ||
+	    vsi->tx_rings[ev->queue] != tx_ring)
+		return;
+
+	q_vector = tx_ring->q_vector;
+	if (!q_vector || !tx_ring->desc || !tx_ring->tx_buf || !tx_ring->count)
+		return;
+
+	size = tx_ring->count * sizeof(struct ice_tx_desc);
+	desc = kvmalloc(size, GFP_KERNEL);
+	if (!desc)
+		return;
+
+	ntc = READ_ONCE(tx_ring->next_to_clean);
+	ntu = READ_ONCE(tx_ring->next_to_use);
+
+	if (ntc < tx_ring->count) {
+		tx_buf = &tx_ring->tx_buf[ntc];
+		if (tx_buf->type == ICE_TX_BUF_SKB)
+			ev->skb_ptr = READ_ONCE(tx_buf->skb);
+
+		memcpy(desc, tx_ring->desc, size);
+		ev->next_to_clean = ntc;
+		ev->next_to_use = ntu;
+		strscpy(ev->irq_name, q_vector->name);
+		ev->desc_ptr = tx_ring->desc;
+		ev->dma = tx_ring->dma;
+		ev->desc_size = size;
+		ev->desc = desc;
+	} else {
+		kvfree(desc);
+	}
 }
 
 void ice_report_tx_hang(struct ice_pf *pf)
@@ -435,13 +512,24 @@ void ice_report_tx_hang(struct ice_pf *pf)
 		.head = buf->head,
 		.intr = buf->intr,
 		.vsi_num = buf->vsi_num,
-		.queue = tx_ring->q_index,
-		.next_to_clean = tx_ring->next_to_clean,
-		.next_to_use = tx_ring->next_to_use,
-		.tx_ring = tx_ring,
+		.queue = buf->queue,
+		.next_to_clean = buf->next_to_clean,
+		.next_to_use = buf->next_to_use,
 	};
 
+	if (!pf->health_reporters.tx_hang)
+		return;
+
+	rtnl_lock();
+	ice_tx_hang_snapshot(pf, tx_ring, &ev);
+	rtnl_unlock();
+
+	/* devlink_health_report() takes the devlink instance lock, which nests
+	 * outside RTNL, so only report once RTNL has been released.
+	 */
 	ice_devlink_health_report(pf->health_reporters.tx_hang, "Tx hang", &ev);
+
+	kvfree(ev.desc);
 }
 
 static struct devlink_health_reporter *
diff --git a/drivers/net/ethernet/intel/ice/devlink/health.h b/drivers/net/ethernet/intel/ice/devlink/health.h
index 5edfc4d2ad..508e4115db 100644
--- a/drivers/net/ethernet/intel/ice/devlink/health.h
+++ b/drivers/net/ethernet/intel/ice/devlink/health.h
@@ -37,6 +37,9 @@ enum ice_mdd_src {
  * @head: descriptor head
  * @intr: interrupt register value
  * @vsi_num: VSI owning the queue that the hang occurred on
+ * @queue: index of the queue that the hang occurred on
+ * @next_to_clean: next_to_clean of the ring when the hang was detected
+ * @next_to_use: next_to_use of the ring when the hang was detected
  * @fw_status: buffer for last received FW Status event
  * @port_status: buffer for last received Port Status event
  */
@@ -50,6 +53,9 @@ struct ice_health {
 		u32 head;
 		u32 intr;
 		u16 vsi_num;
+		u16 queue;
+		u16 next_to_clean;
+		u16 next_to_use;
 	);
 	struct ice_aqc_health_status_elem fw_status;
 	struct ice_aqc_health_status_elem port_status;

---
base-commit: 7076f684d5132e6a6145e1da2fa74771ecd052e5
change-id: 20261016-ice-tx-hang-dump-e46b4ed483d6

Best regards,
--  
Vincent Choiniere <choiniere.vincent@hydroquebec.com>

