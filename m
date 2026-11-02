From: Dave Marquardt <davemarq@linux.ibm.com>
Subject: [PATCH v17 00/13] scsi: ibmvfc: make ibmvfc support FPIN messages
Date: Mon, 02 Nov 2026 15:38:40 -0600
Message-Id: <20261102-ibmvfc-fpin-support-v17-0-9ee5f195ac91@linux.ibm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XRS07EMAwG4KuMsiaV805ZcQ/EIkkTGjTTVulDM
 xr17iQDQgXapS378y/5jkafoh/R8+mOkl/iGPsuF0Q9nZBrTffucWxyA1GgEmoqcLSXJTgchtj
 hcR6GPk3Ye2t4A9pyKlDeHJIP8fpgX9++6nG2H95NhSoTIfUXPLXJm186cF4DVJxwxgETPN2SP
 zcv59jN1ypfrlx/KettHKc+3R6xF0LLnW+DwW7CPIQBC2ZYCEE1Stk/aIm5EPYjEQB1ILEsWU2
 kscHw4NyuxDcSEQcSz5IBC5JZ3WgqdiWxleoDSRRJC62o9ERpsyvJjUTlgSSLlJ9gjBTKN/8yr
 ev6CTdT0m42AgAA
X-Change-ID: 20260925-ibmvfc-fpin-support-eeba4d08b425
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <mkp@kernel.org>, 
 Tyrel Datwyler <tyreld@linux.ibm.com>
Cc: linux-scsi@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793655530; l=18203;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=j6wjE7cD3PL+88vXCOHbLuWhinJSbxx2+DhNCzU2P+U=;
 b=/rG9r8jDY5OqVqZ5/t74isNMV8wWEZ9cIz4ppRTFAFC1ztw+aH+t1oejBL77MPwaTeOZ+YT6B
 WUvuah/3eweAusrnQEO0C8UuZdxWbqa09VmL3A1obxlT1sj0tjvi7Ao
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds FPIN (fabric performance impact notification)
support to the ibmvfc (IBM Virtual Fibre Channel) driver. This comes
in three flavors:

- basic, to recognize existing FPIN messages from the virtual I/O
  server (VIOS) (patch 6)
- full, supporting additional FPIN information and using its own
  asynchronous sub-queue and interrupt (patches 8-12)
- extended, supporting FC-LS-5 (patch 13)

Full and extended FPIN support requires a new asynchronous sub-queue
with its own interrupt. The asynchronous sub-queue support requires
ibmvfc to also support a new IBMVFC_NOOP command, which the driver
recognizes and ignores (patch 7).

The asynchronous sub-queue work is split across five patches: patch 8
defines the necessary data structures, patch 9 extends the async event
handlers to accept events from the new queue, patch 10 adds the
interrupt and drain routines for the queue, patch 11 extends channel
registration to accommodate the new queue, and patch 12 registers the
queue during channel initialization, advertises support to VIOS during
NPIV login, and routes events from the queue to the handlers. Patches
1-5 fix IRQ cleanup and error handling bugs exposed during that work.
Patch 13 adds extended FPIN handling on top of the new queue.

All three modes convert an incoming FPIN message from VIOS to an FC
extended link service message, in some cases using default values for
information not provided by the VIOS FPIN message but expected in the
FC ELS message. This FC ELS message is passed to fc_host_fpin_rcv for
updating statistics and sending the information upstream by netlink
multicast, where it may be read by listeners including the DM
multipath daemon "multipathd."

Signed-off-by: Tyrel Datwyler <tyreld@linux.ibm.com>
Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>

---
Changes in v17:
- new patch 4 (fix stale rc and IRQ mapping leak in
  ibmvfc_register_channel()): set rc = -EINVAL in the default: case of
  the protocol switch to prevent a stale h_reg_sub_crq() return value
  (0 or H_CLOSED) being returned to the caller after the sub-CRQ is
  freed; introduce irq_mapping_failed: label to dispose the IRQ mapping
  and clear scrq->irq before falling through to irq_failed, fixing a
  leak when irq_create_mapping() succeeds but a later step fails
- patch 5 (fix resource leaks on partial queue allocation failure):
  add ibmvfc_free_event_pool() calls on the get_zeroed_page() and
  dma_mapping_error() failure paths in ibmvfc_alloc_queue() to fix
  an event pool leak when ibmvfc_init_event_pool() succeeds but a
  later step fails; rename patch subject to reflect broader scope
- patch 6 (add basic FPIN support): allocate fpin_workq after
  ibmvfc_alloc_mem() in ibmvfc_probe() to prevent double-free of
  resources that ibmvfc_alloc_mem() already unwound on failure; deliver
  LINK_CONGESTED and CONGESTION_CLEARED events whose identifiers are all
  zero as host-scope FPIN events, and silently drop other statuses with
  no identifiers; set detecting_wwpn in the FPIN descriptors from
  fc_host_port_name() instead of leaving it zero; add KUnit cases for the
  host-scope and dropped zero-identifier events
- patch 9 (extend async event handlers for async sub-CRQ events): add
  assoc_id parameter to ibmvfc_find_target() and match on tgt->assoc_id
  when nonzero; when an async sub-CRQ event has IBMVFC_ASYNC_ID_IS_ASSOC_ID
  set, extract assoc_id from subq->id.assoc_id and pass it to the target
  lookup so NVMe targets sharing a wwpn are distinguished by association ID;
  propagate assoc_id into the ELS LOGO/PRLO/PLOGI target loops in
  ibmvfc_handle_async() for the same reason; when no target is found for
  a LINK_CONGESTED or CONGESTION_CLEARED event, fall back to a
  host-scope descriptor as for basic FPIN; set detecting_wwpn in the
  full FPIN descriptors; use a severity of 0 for PORT_CLEARED and
  CONGESTION_CLEARED events
- patch 10 (add interrupt routine for asynchronous sub CRQ): collect
  async sub-CRQ events into a deferred list while holding host_lock and
  q_lock and dispatch them after releasing both, re-taking host_lock
  around each ibmvfc_handle_async() call, avoiding a potential lockdep
  recursive locking warning from ibmvfc_handle_async() calling
  ibmvfc_purge_requests() which acquires q_lock instances of the same
  lockdep class
- patch 11 (extend channel registration for async sub-CRQ): rename the
  patch and correct its commit message, which said
  ibmvfc_deregister_channel() was changed when only
  ibmvfc_register_channel() is
- patch 12 (register and use asynchronous sub CRQ): move
  mq_enabled/do_enquiry flag clearing out of ibmvfc_reg_sub_crqs() and
  into each caller; in ibmvfc_reenable_crq_queue() and
  ibmvfc_reset_crq(), deregister all channel sets and clear mq_enabled
  and do_enquiry if any ibmvfc_reg_sub_crqs() call fails, preventing
  leaked hypervisor sub-CRQ registrations; set async_sub_crq_handle
  unconditionally in ibmvfc_channel_setup() so the handle is sent to
  VIOS even on the CANCEL_CHANNELS path
- patch 13 (handle extended FPIN events): pass detecting_wwpn through
  ibmvfc_ext_fpin_to_desc(); correct the @severity kernel-doc to say
  severity is only carried by the congestion descriptor
  (LINK_CONGESTED and CONGESTION_CLEARED); drop the redundant
  IBMVFC_FPIN_EVENT_TYPE_VALID test in ibmvfc_ext_fpin_to_desc(); remove
  volatile from the valid field of struct ibmvfc_async_subq_fpin; move
  the static_assert() checks to file scope
- Link to v16: https://lore.kernel.org/r/20261026-ibmvfc-fpin-support-v16-0-a900aa657ed5@linux.ibm.com

Changes in v16:
- new patch 4: fix unguarded dma_unmap_single() in ibmvfc_free_queue();
  guard dma_unmap_single() and free_page() together under the msgs.handle
  check to prevent calling dma_unmap_single() with address 0 on a
  partially initialized queue
- patch 5 (add basic FPIN support): restore per-adapter fpin_workq instead
  of schedule_work(); destroy it after ibmvfc_release_crq_queue() in
  ibmvfc_remove() to ensure in-flight work items drain before tgt_pool is
  freed and to close the original race where queue_work() could be called
  on a destroyed workqueue pointer; fix probe error unwind to call
  destroy_workqueue() before ibmvfc_free_mem()
- patch 10 (extend channel reg/dereg helpers): initialize scrq->hwq_id
  before request_irq() so error logging in ibmvfc_toggle_scrq_irq() shows
  the correct index if an early interrupt triggers before hwq_id was set
- patch 11 (register and use asynchronous sub CRQ): clamp
  scsi->active_queues and nvme->active_queues to max_queues in
  ibmvfc_channel_setup_done() to prevent out-of-bounds scrqs[] access on
  a malformed hypervisor response; take host_lock around bitfield writes
  to mq_enabled, do_enquiry, and nvme_enabled in ibmvfc_reg_sub_crqs()
  and ibmvfc_init_sub_crqs() to prevent lost updates from concurrent
  read-modify-write on the packed bitfield word; remove mq_enabled guard
  from ibmvfc_dereg_sub_crqs() to prevent previously registered channel
  sets being skipped on teardown after a registration failure; change
  ibmvfc_reg_sub_crqs() to return int and check its return value in
  ibmvfc_init_sub_crqs() so each channel set failure triggers correct
  per-set cleanup
- Link to v15: https://patch.msgid.link/20261019-ibmvfc-fpin-support-v15-0-a858726e178a@linux.ibm.com

Changes in v15:
- patch 4 (add basic FPIN support): restore per-adapter fpin_workq instead
  of schedule_work(); destroy it after ibmvfc_release_crq_queue() in
  ibmvfc_remove() to ensure in-flight work items drain before tgt_pool is
  freed and to close the original race where queue_work() could be called
  on a destroyed workqueue pointer
- patch 9 (extend channel reg/dereg helpers): initialize scrq->hwq_id
  before request_irq() so error logging in ibmvfc_toggle_scrq_irq() shows
  the correct index if an early interrupt triggers before hwq_id was set
- patch 10 (register and use asynchronous sub CRQ): clamp scsi->active_queues
  and nvme->active_queues to max_queues in ibmvfc_channel_setup_done() to
  prevent out-of-bounds scrqs[] access on a malformed hypervisor response;
  take host_lock around bitfield writes to mq_enabled, do_enquiry, and
  nvme_enabled in ibmvfc_reg_sub_crqs() and ibmvfc_init_sub_crqs() to
  prevent lost updates from concurrent read-modify-write on the packed
  bitfield word
- Link to v14: https://patch.msgid.link/20261015-ibmvfc-fpin-support-v14-0-a0b063b8d825@linux.ibm.com

Changes in v14:
- Fix double-free of sub-CRQ at the hypervisor level: guard
  H_FREE_SUB_CRQ in ibmvfc_deregister_channel() on scrq->cookie != 0
  and clear cookie to zero on success; also clear cookie in the
  ibmvfc_register_channel() irq_failed: rollback path (patch 3)
- Add SCSI_IBMVFC_KUNIT_TEST Kconfig entry, Makefile line, and
  ibmvfc_kunit.c with ibmvfc_deregister_channel_guard_test() verifying
  the cookie and msgs.handle guard paths (patch 3)
- Fix wild pointer dereference in ibmvfc_handle_scrq(): change signature
  to accept struct ibmvfc_queue *scrq and use &scrq->evt_pool for event
  validation instead of &evt->queue->evt_pool (patch 5)
- Fix NULL pointer dereference in ibmvfc_channel_setup_done() when
  mq_enabled=0: compute async->active_queues from the VIOS response
  guarded by async->scrqs != NULL; guard async->scrqs[0].cookie access
  in ibmvfc_channel_setup() with a NULL check (patch 10)
- Fix host state machine stall on ibmvfc_reg_sub_crqs() failure: clear
  vhost->mq_enabled in addition to do_enquiry so ibmvfc_npiv_login_done()
  takes the non-channel fallback path and wakes the work queue (patch 10)
- Link to v13: https://patch.msgid.link/20261007-ibmvfc-fpin-support-v13-0-b816abfa4fcc@linux.ibm.com

Changes in v13:
- Updated to 7.4/scsi-staging base
- Extend ibmvfc_common_fpin_to_desc() with a severity parameter;
  ibmvfc_ext_fpin_to_desc() now honours IBMVFC_FPIN_SEVERITY_VALID
  and propagates the severity from the VIOS rather than always
  defaulting to FPIN_CONGN_SEVERITY_WARNING (patch 11)
- Handle scsi_host_get() failure in ibmvfc_get_first_vhost() (patch 4)
- Add kernel-doc comment to ibmvfc_get_first_vhost() (patch 4)
- Use list_for_each_entry to find an online FCP/NVMe target rport in
  KUnit tests rather than taking the first list entry unconditionally
  (patches 4, 7, 11)
- Link to v12: https://patch.msgid.link/20260930-ibmvfc-fpin-support-v12-0-53a3fff7d77b@linux.ibm.com

Changes in v12:
- Wrap ibmvfc_handle_async() invocations in KUnit tests with host_lock to
  prevent races with workqueue destruction on concurrent device removal
  (patches 4, 7, 11)
- Add missing scsi_host_put() in success exit path of ibmvfc_async_fpin_test()
  (patch 4)
- Pass resolved tgt->wwpn into ibmvfc_full_fpin_to_desc() instead of subq->wwpn
  so FPIN descriptors are correctly populated when subq->wwpn is 0 (patch 7)
- Fix kernel-doc comments in ibmvfc_register_channel() and
  ibmvfc_deregister_channel() that incorrectly directed passing a negative index
  (patch 9)
- Fix double registration of scsi_scrqs in ibmvfc_reenable_crq_queue() by
  registering async_scrqs instead (patch 10)
- Link to v11: https://lore.kernel.org/linux-scsi/20260925044900.414340-1-tyreld@linux.ibm.com/

Changes in v11:
- Split the IRQ cleanup and NULL-pointer fixes out of the "register and
  use" patch into two dedicated bug-fix patches (patches 1-2 and 1-3),
  making the series 11 patches instead of 9
- Replaced the single ibmvfc_queue async_sub_crq field in ibmvfc_host with
  an ibmvfc_channels async_scrqs field, reusing the existing channel
  infrastructure for allocation, registration, and teardown (patches 6, 9, 10)
- Added IBMVFC_PROTO_ASYNC to enum ibmvfc_protocol; ibmvfc_register_channel()
  and ibmvfc_deregister_channel() now dispatch on protocol rather than a
  negative-index sentinel (patch 9)
- Added IBMVFC_ASYNC_SUB_CRQ_FMT format enum value and corresponding
  async_scrq pointer in union ibmvfc_msgs (patch 6)
- ibmvfc_alloc_channels() selects IBMVFC_ASYNC_SUB_CRQ_FMT for async
  protocol channels so queues are sized for ibmvfc_async_sub_crq entries
  (patch 10)
- Link to v10: https://lore.kernel.org/linux-scsi/20260911021910.1038128-1-tyreld@linux.ibm.com/

Changes in v10:
- Fix ibmvfc_find_target() to use logical and (&&) instead of logical or (||)
  when checking whether fc and nvme remote ports are NULL (patch 4)
- Fix build issues due to missing & operator when referencing the host lock
  during irqsave/restore calls (patch 4, patch 7, patch 8, patch 11)
- Fix kunit build issues caused by inclusion of code meant for later patches
  (patch 4, patch 7, patch 11)
- Link to v9: https://lore.kernel.org/linux-scsi/20260911021910.1038128-1-tyreld@linux.ibm.com/

Changes in v9:
- Fix ibmvfc_find_target() to check for either a valid rport or nvme_remote_port
  so nvme targets are not silently dropped (patch 4)
- Restore xxx_host_remove() ordering and destroy async work queue prior to these
  calls. Check that the host is not offline prior to enqueuing new async work
  (patch 4)
- Link to v8: https://lore.kernel.org/linux-scsi/20260909-ibmvfc-fpin-support-v8-0-b27183b055af@linux.ibm.com

Changes in v8:
- Split patch 6 into two patches: extend channel registration/deregistration
  for async subq (patch 9), and clear sub-CRQ IRQ on registration failure
  and guard teardown (patch 1)
- Fixed NULL dereference in ibmvfc_deregister_channel() when called on
  an unallocated queue: guard memset() behind scrq->msgs.handle check
- Fixed variable-shadowing bug in ibmvfc_register_channel() error path
  where H_FREE_SUB_CRQ hcall result clobbered the return code
- Deregister and re-register async sub-CRQ in ibmvfc_reenable_crq_queue()
  and ibmvfc_reset_crq() alongside SCSI channel queues
- Link to v7: https://patch.msgid.link/20260831-ibmvfc-fpin-support-v7-0-77d0b9809080@linux.ibm.com

Changes in v7:
- Removed CRQ valid bit clearing to callers of ibmvfc_handle_async in
  all cases
- Added validity checks that IBMVFC_ASYNC_ID_IS_ASSOC_ID is clear
  before using node_name
- Fixed error path cleanup in ibmvfc_init_sub_crqs
- Deregister and reregister async sub-CRQ in CRQ reset and reenable
  code.
- Moved work queue destruction after sub CRQs teardown in ibmvfc_remove
- Modified async event handling code to use a tagged union rather than
  void *.
- Use WQ_UNBOUND rather than WQ_PERCPU for fpin workqueue, as FPIN
  events should be rare. Hold q_lock only in
  ibmvfc_drain_async_subq(), like ibmvfc_drain_sub_crq().
- Hardened KUnit tests to use host_lock and kref.
- Link to v6: https://patch.msgid.link/20260817-ibmvfc-fpin-support-v6-0-62a2d525e70d@linux.ibm.com

Changes in v6:
- Use alloc_workqueue rather than devm_alloc_workqueue, and add
  explicit destroy_workqueue calls
- Moved ibmvfc_find_target into patch 4
- Link to v5: https://patch.msgid.link/20260806-ibmvfc-fpin-support-v5-0-13fd6f8a8f8b@linux.ibm.com

Changes in v5:
- Incorporate changes for NVME-over-FC.
- Removed now redundant fabric login patch.
- Link to v4: https://patch.msgid.link/20260710-ibmvfc-fpin-support-v4-0-ef031ac19520@linux.ibm.com

Changes in v4:
- Refactored channel registration
- Check whether async work queue is allocated before using or freeing
- Fixed work queue allocation/destruction
- Skip basic KUnit test when there are no ibmvfc devices available
- Fix target not found condition in ibmvfc_process_async_work
- Link to v3: https://patch.msgid.link/20260702-ibmvfc-fpin-support-v3-0-d95b9747cf88@linux.ibm.com

Changes in v3:
- Fixed latent bug, exposed by VFC_NOOP, related to dataless CRQs and events
- Fixed FPIN TLV descriptor length calculations
- Use safe list walker to walk targets in ibmvfc_process_async_work
- Added write memory barriers after clearing CRQ valid field
- Use per-vhost work queue for FPIN work
- Link to v2: https://patch.msgid.link/20260608-ibmvfc-fpin-support-v2-0-d41f540fba5c@linux.ibm.com

Highlights of changes in v2:
- Refactored mostly common FPIN conversion routines and async event
  processing into single routines with wrappers for differences.
- Moved FPIN processing to a work queue to avoid conflicts with
  fc_host_fpin_rcv and memory allocation
- Set descriptor sizes correctly
- Use target WWPN for basic FPIN descriptor
- Split patch 4 into 3 patches, for definition, allocation, and use of
  the asynchronous sub-queue for events
- Link to v1: https://patch.msgid.link/20260408-ibmvfc-fpin-support-v1-0-52b06c464e03@linux.ibm.com

---
Dave Marquardt (11):
      scsi: ibmvfc: fix IRQ leak and guard deregister on channel reg failure
      scsi: ibmvfc: fix stale rc and IRQ mapping leak in ibmvfc_register_channel()
      scsi: ibmvfc: fix resource leaks on partial queue allocation failure
      scsi: ibmvfc: add basic FPIN support
      scsi: ibmvfc: add NOOP command support
      scsi: ibmvfc: add FPIN extended flag and async sub-CRQ queue handle
      scsi: ibmvfc: extend async event handlers for async sub-CRQ events
      scsi: ibmvfc: add interrupt routine for asynchronous sub CRQ
      scsi: ibmvfc: extend channel registration for async sub-CRQ
      scsi: ibmvfc: register and use asynchronous sub CRQ for events
      scsi: ibmvfc: handle extended FPIN events

Tyrel Datwyler (2):
      scsi: ibmvfc: fix potential clobbering of rc after failed irq setup
      scsi: ibmvfc: fix potential NULL pointer dereference on failed queue allocation

 drivers/scsi/Kconfig                 |   10 +
 drivers/scsi/ibmvscsi/Makefile       |    1 +
 drivers/scsi/ibmvscsi/ibmvfc-core.c  | 1009 ++++++++++++++++++++++++++++++----
 drivers/scsi/ibmvscsi/ibmvfc.h       |   69 +++
 drivers/scsi/ibmvscsi/ibmvfc_kunit.c |  584 ++++++++++++++++++++
 5 files changed, 1575 insertions(+), 98 deletions(-)
---
base-commit: c3cff7fac01638ab58e85fe7df41a04fa25c5bae
change-id: 20260925-ibmvfc-fpin-support-eeba4d08b425

Best regards,
-- 
Dave Marquardt <davemarq@linux.ibm.com>

