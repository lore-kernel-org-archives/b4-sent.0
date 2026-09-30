From: Dave Marquardt <davemarq@linux.ibm.com>
Subject: [PATCH v12 00/11] scsi: ibmvfc: make ibmvfc support FPIN messages
Date: Wed, 30 Sep 2026 13:23:28 -0500
Message-Id: <20260930-ibmvfc-fpin-support-v12-0-53a3fff7d77b@linux.ibm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKBTvWoC/1WNQQ6CMBREr0K69pNSixFX3MO4oOVXvoG2aQvBE
 O5u0ZXLN5l5s7GIgTCyW7GxgAtFcjZDJU4F00NnnwjU54AJLi68ETWQmhajwXiyEGfvXUiAqDr
 Z86uSomZ56QMaWr/a++PHcVYv1OlQHQ0T3ARpCNj92bmUDeelrORZcqggvQOOfTuSndcyP5faT
 WzfPzV/OUq3AAAA
X-Change-ID: 20260925-ibmvfc-fpin-support-eeba4d08b425
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <mkp@kernel.org>
Cc: linux-scsi@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Tyrel Datwyler <tyreld@linux.ibm.com>, 
 Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790792616; l=10797;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=iCsLa/gelRtEc6l0mAiPHb8YaDXPzbWWJBrDaY+kxWA=;
 b=2uPeAO+qN2LcDRsM+G5yBjuTz7JR0m1ZR60a3SgaYL/Rry69p/jHuIpVM7uw4F1cd01wp7L1/
 Pacrtutp3P+Cm3F/sls2mfCmAxZdKxnC70X/l6SB8UjzSOhJdhG3Nhb
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds FPIN (fabric performance impact notification)
support to the ibmvfc (IBM Virtual Fibre Channel) driver. This comes
in three flavors:

- basic, to recognize existing FPIN messages from the virtual I/O
  server (VIOS) (patch 4)
- full, supporting additional FPIN information and using its own
  asynchronous sub-queue and interrupt (patches 6-10)
- extended, supporting FC-LS-5 (patch 11)

Full and extended FPIN support requires a new asynchronous sub-queue
with its own interrupt. The asynchronous sub-queue support requires
ibmvfc to also support a new IBMVFC_NOOP command, which the driver
recognizes and ignores (patch 5).

The asynchronous sub-queue work is split across five patches: patch 6
defines the necessary data structures, patches 7 and 8 add the
interrupt and drain routines for the queue, patch 9 extends channel
registration and deregistration to accommodate the new queue, and
patches 1-3 fix IRQ cleanup and error handling bugs exposed during
that work. Patch 10 wires everything together, registering the async
sub-queue during channel initialization and advertising support to
VIOS during NPIV login.

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

To: "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>
To: "Martin K. Petersen" <mkp@kernel.org>
To: Madhavan Srinivasan <maddy@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>
To: Nicholas Piggin <npiggin@gmail.com>
To: "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>
To: Tyrel Datwyler <tyreld@linux.ibm.com>
Cc: linux-kernel@vger.kernel.org
Cc: linux-scsi@vger.kernel.org
Cc: linuxppc-dev@lists.ozlabs.org

---

Dave Marquardt (9):
  scsi: ibmvfc: fix IRQ leak and guard deregister on channel reg failure
  scsi: ibmvfc: add basic FPIN support
  scsi: ibmvfc: add NOOP command support
  scsi: ibmvfc: add FPIN extended flag and async sub-CRQ queue handle
  scsi: ibmvfc: extend async event handlers for async sub-CRQ events
  scsi: ibmvfc: add interrupt routine for asynchronous sub CRQ
  scsi: ibmvfc: extend channel reg/dereg helpers for async sub-CRQ
  scsi: ibmvfc: register and use asynchronous sub CRQ for events
  scsi: ibmvfc: handle extended FPIN events

Tyrel Datwyler (2):
  scsi: ibmvfc: fix potential clobbering of rc after failed irq setup
  scsi: ibmvfc: fix potential NULL pointer dereference on failed queue
    allocation

 drivers/scsi/Kconfig                 |  10 +
 drivers/scsi/ibmvscsi/Makefile       |   1 +
 drivers/scsi/ibmvscsi/ibmvfc-core.c  | 720 ++++++++++++++++++++++++---
 drivers/scsi/ibmvscsi/ibmvfc.h       |  66 +++
 drivers/scsi/ibmvscsi/ibmvfc_kunit.c | 409 +++++++++++++++
 5 files changed, 1141 insertions(+), 65 deletions(-)
 create mode 100644 drivers/scsi/ibmvscsi/ibmvfc_kunit.c

--
2.55.0

---
Dave Marquardt (9):
      scsi: ibmvfc: fix IRQ leak and guard deregister on channel reg failure
      scsi: ibmvfc: add basic FPIN support
      scsi: ibmvfc: add NOOP command support
      scsi: ibmvfc: add FPIN extended flag and async sub-CRQ queue handle
      scsi: ibmvfc: extend async event handlers for async sub-CRQ events
      scsi: ibmvfc: add interrupt routine for asynchronous sub CRQ
      scsi: ibmvfc: extend channel reg/dereg helpers for async sub-CRQ
      scsi: ibmvfc: register and use asynchronous sub CRQ for events
      scsi: ibmvfc: handle extended FPIN events

Tyrel Datwyler (2):
      scsi: ibmvfc: fix potential clobbering of rc after failed irq setup
      scsi: ibmvfc: fix potential NULL pointer dereference on failed queue allocation

 drivers/scsi/Kconfig                 |  10 +
 drivers/scsi/ibmvscsi/Makefile       |   1 +
 drivers/scsi/ibmvscsi/ibmvfc-core.c  | 718 +++++++++++++++++++++++++++++++----
 drivers/scsi/ibmvscsi/ibmvfc.h       |  66 ++++
 drivers/scsi/ibmvscsi/ibmvfc_kunit.c | 422 ++++++++++++++++++++
 5 files changed, 1152 insertions(+), 65 deletions(-)
---
base-commit: 12e67eb89eb2b9516685c744d3f7de0a2d1bd701
change-id: 20260925-ibmvfc-fpin-support-eeba4d08b425

Best regards,
--  
Dave Marquardt <davemarq@linux.ibm.com>

