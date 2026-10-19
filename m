From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Mon, 19 Oct 2026 17:15:48 -0500
Subject: [PATCH v15 03/11] scsi: ibmvfc: fix potential NULL pointer
 dereference on failed queue allocation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-ibmvfc-fpin-support-v15-3-a858726e178a@linux.ibm.com>
References: <20261019-ibmvfc-fpin-support-v15-0-a858726e178a@linux.ibm.com>
In-Reply-To: <20261019-ibmvfc-fpin-support-v15-0-a858726e178a@linux.ibm.com>
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <mkp@kernel.org>, 
 Tyrel Datwyler <tyreld@linux.ibm.com>
Cc: linux-scsi@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792448148; l=9575;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=lPVevl98wvBvJlO2bgCaSUYb0mdSUey0akY63gmEKEo=;
 b=VIfgw9+tqUG2LHNxUmiPFAkLB/pUDdhwMo2jBOzS1Uf6QUynSIaijzJ1xlc4MsOzdcEqFSxhp
 RIR7i0P4igsCdUmFptxzaHOx/0cX61IXXjMp74YidObC+QUgOfNWFRZ
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Tyrel Datwyler <tyreld@linux.ibm.com>

Guard ibmvfc_deregister_channel() against calling H_FREE_SUB_CRQ on a
queue that was never registered and against memsetting a buffer that was
never allocated.

Add an scrq->cookie guard around the H_FREE_SUB_CRQ hypercall so it is
only issued when the cookie is non-zero; clear scrq->cookie to zero on
success to prevent double-free if the function is called again during
reset or teardown. Add scrq->cookie = 0 in the ibmvfc_register_channel()
irq_failed: cleanup path for the same reason. Guard the memset() of the
queue message buffer behind a check of scrq->msgs.handle to prevent a
NULL dereference when the function is called on a queue that was never
allocated, such as async_sub_crq when multi-queue is disabled or
initialization failed before ibmvfc_alloc_queue() was reached. Update the
error message to include channels->protocol so failures can be
distinguished across SCSI, NVMe, and async sub-CRQ channels.

Expose ibmvfc_deregister_channel() via VISIBLE_IF_KUNIT and
EXPORT_SYMBOL_IF_KUNIT and add a kernel-doc header to support KUnit
testing.

Add ibmvfc_get_first_vhost() to retrieve the first registered ibmvfc
adapter with a reference held; expose it via VISIBLE_IF_KUNIT and
EXPORT_SYMBOL_IF_KUNIT for use by KUnit tests.

Add SCSI_IBMVFC_KUNIT_TEST Kconfig entry and Makefile line, and create
ibmvfc_kunit.c with an ibmvfc-channel-test suite containing
ibmvfc_deregister_channel_guard_test(). The test verifies that calling
ibmvfc_deregister_channel() on a queue with cookie == 0 and
msgs.handle == NULL issues no hypercall, performs no memset, and leaves
the queue state unchanged.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
Signed-off-by: Tyrel Datwyler <tyreld@linux.ibm.com>
---
 drivers/scsi/Kconfig                 | 10 ++++++
 drivers/scsi/ibmvscsi/Makefile       |  1 +
 drivers/scsi/ibmvscsi/ibmvfc-core.c  | 64 +++++++++++++++++++++++++++++++-----
 drivers/scsi/ibmvscsi/ibmvfc.h       |  8 +++++
 drivers/scsi/ibmvscsi/ibmvfc_kunit.c | 63 +++++++++++++++++++++++++++++++++++
 5 files changed, 137 insertions(+), 9 deletions(-)

diff --git a/drivers/scsi/Kconfig b/drivers/scsi/Kconfig
index 4a2af0f702e1..f47789b1102d 100644
--- a/drivers/scsi/Kconfig
+++ b/drivers/scsi/Kconfig
@@ -759,6 +759,16 @@ config SCSI_IBMVFC
 	  To compile this driver as a module, choose M here: the
 	  module will be called ibmvfc.
 
+config SCSI_IBMVFC_KUNIT_TEST
+	tristate "KUnit tests for the IBM POWER Virtual FC Client" if !KUNIT_ALL_TESTS
+	depends on SCSI_IBMVFC && KUNIT
+	default KUNIT_ALL_TESTS
+	help
+	  Compile IBM POWER Virtual FC client KUnit tests. These tests
+	  cover the sub-CRQ channel deregistration guard path.
+	  To compile this driver as a module, choose M here: the module
+	  will be called ibmvfc_kunit.
+
 config SCSI_IBMVFC_TRACE
 	bool "enable driver internal trace"
 	depends on SCSI_IBMVFC
diff --git a/drivers/scsi/ibmvscsi/Makefile b/drivers/scsi/ibmvscsi/Makefile
index 9408c7f4cdee..a227bc633f3a 100644
--- a/drivers/scsi/ibmvscsi/Makefile
+++ b/drivers/scsi/ibmvscsi/Makefile
@@ -3,3 +3,4 @@ ibmvfc-objs := ibmvfc-core.o ibmvfc-nvme.o
 
 obj-$(CONFIG_SCSI_IBMVSCSI)	+= ibmvscsi.o
 obj-$(CONFIG_SCSI_IBMVFC)	+= ibmvfc.o
+obj-$(CONFIG_SCSI_IBMVFC_KUNIT_TEST)	+= ibmvfc_kunit.o
diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index 145d559041f1..0fe6b6f4260b 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -6449,12 +6449,24 @@ static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
 	do {
 		hcall_rc = plpar_hcall_norets(H_FREE_SUB_CRQ, vdev->unit_address, scrq->cookie);
 	} while (hcall_rc == H_BUSY || H_IS_LONG_BUSY(hcall_rc));
+	scrq->cookie = 0;
 reg_failed:
 	LEAVE;
 	return rc;
 }
 
-static void ibmvfc_deregister_channel(struct ibmvfc_host *vhost,
+/**
+ * ibmvfc_deregister_channel - Deregister a sub-CRQ channel with the hypervisor
+ * @vhost:	ibmvfc host struct
+ * @channels:	ibmvfc channels struct containing the sub-CRQ array
+ * @index:	index into the sub-CRQ array
+ *
+ * Frees the IRQ, disposes of the IRQ mapping, and calls H_FREE_SUB_CRQ to
+ * release the sub-CRQ with the hypervisor. On success the queue message
+ * buffer is zeroed and the current index is reset. If H_FREE_SUB_CRQ fails,
+ * an error is logged but the channel resources are cleaned up regardless.
+ */
+VISIBLE_IF_KUNIT void ibmvfc_deregister_channel(struct ibmvfc_host *vhost,
 				      struct ibmvfc_channels *channels,
 				      int index)
 {
@@ -6471,20 +6483,28 @@ static void ibmvfc_deregister_channel(struct ibmvfc_host *vhost,
 		scrq->irq = 0;
 	}
 
-	do {
-		rc = plpar_hcall_norets(H_FREE_SUB_CRQ, vdev->unit_address,
-					scrq->cookie);
-	} while (rc == H_BUSY || H_IS_LONG_BUSY(rc));
+	if (scrq->cookie) {
+		do {
+			rc = plpar_hcall_norets(H_FREE_SUB_CRQ, vdev->unit_address,
+						scrq->cookie);
+		} while (rc == H_BUSY || H_IS_LONG_BUSY(rc));
 
-	if (rc)
-		dev_err(dev, "Failed to free sub-crq[%d]: rc=%ld\n", index, rc);
+		if (rc)
+			dev_err(dev, "Failed to free protocol (%d) sub-crq[%d]: rc=%ld\n",
+				channels->protocol, index, rc);
+		else
+			scrq->cookie = 0;
+	}
 
 	/* Clean out the queue */
-	memset(scrq->msgs.crq, 0, PAGE_SIZE);
-	scrq->cur = 0;
+	if (scrq->msgs.handle) {
+		memset(scrq->msgs.crq, 0, PAGE_SIZE);
+		scrq->cur = 0;
+	}
 
 	LEAVE;
 }
+EXPORT_SYMBOL_IF_KUNIT(ibmvfc_deregister_channel);
 
 static void ibmvfc_reg_sub_crqs(struct ibmvfc_host *vhost,
 				struct ibmvfc_channels *channels)
@@ -7118,5 +7138,31 @@ static void __exit ibmvfc_module_exit(void)
 	fc_release_transport(ibmvfc_transport_template);
 }
 
+#if IS_ENABLED(CONFIG_KUNIT)
+/**
+ * ibmvfc_get_first_vhost - Get the first ibmvfc host from the global list
+ *
+ * Grabs the driver spinlock and retrieves the first host adapter from the
+ * driver list. If found, increments its reference count via scsi_host_get().
+ *
+ * Return value:
+ *	struct ibmvfc_host * with reference held on success, NULL otherwise
+ **/
+VISIBLE_IF_KUNIT struct ibmvfc_host *ibmvfc_get_first_vhost(void)
+{
+	struct ibmvfc_host *vhost = NULL;
+
+	spin_lock(&ibmvfc_driver_lock);
+	if (!list_empty(&ibmvfc_head))
+		vhost = list_first_entry(&ibmvfc_head, struct ibmvfc_host, queue);
+	if (vhost)
+		if (!scsi_host_get(vhost->host))
+			vhost = NULL;
+	spin_unlock(&ibmvfc_driver_lock);
+	return vhost;
+}
+EXPORT_SYMBOL_IF_KUNIT(ibmvfc_get_first_vhost);
+#endif
+
 module_init(ibmvfc_module_init);
 module_exit(ibmvfc_module_exit);
diff --git a/drivers/scsi/ibmvscsi/ibmvfc.h b/drivers/scsi/ibmvscsi/ibmvfc.h
index ca80ceffe53a..421ce8bc3ea3 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.h
+++ b/drivers/scsi/ibmvscsi/ibmvfc.h
@@ -1088,4 +1088,12 @@ static inline struct ibmvfc_host *ibmvfc_channels_to_vhost(struct ibmvfc_channel
 #define ibmvfc_remove_trace_file(kobj, attr) do { } while (0)
 #endif
 
+#if IS_ENABLED(CONFIG_KUNIT)
+#include <kunit/visibility.h>
+VISIBLE_IF_KUNIT void ibmvfc_deregister_channel(struct ibmvfc_host *vhost,
+						struct ibmvfc_channels *channels,
+						int index);
+VISIBLE_IF_KUNIT struct ibmvfc_host *ibmvfc_get_first_vhost(void);
+#endif
+
 #endif
diff --git a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
new file mode 100644
index 000000000000..24799aa2368a
--- /dev/null
+++ b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
@@ -0,0 +1,63 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+#include <kunit/test.h>
+#include <kunit/visibility.h>
+#include <scsi/scsi_device.h>
+#include <scsi/scsi_transport_fc.h>
+#include "ibmvfc.h"
+
+MODULE_IMPORT_NS("EXPORTED_FOR_KUNIT_TESTING");
+
+/**
+ * ibmvfc_deregister_channel_guard_test - unit test for ibmvfc_deregister_channel()
+ *   guard conditions
+ * @test: pointer to kunit structure
+ *
+ * Tests that ibmvfc_deregister_channel() safely handles a queue that was
+ * never registered with the hypervisor (cookie == 0, msgs.handle == NULL):
+ * - no H_FREE_SUB_CRQ hypercall is issued
+ * - no memset is attempted on a NULL buffer
+ * - cookie and cur remain zero after the call
+ *
+ * Return: void
+ */
+static void ibmvfc_deregister_channel_guard_test(struct kunit *test)
+{
+	struct ibmvfc_channels channels = {};
+	struct ibmvfc_queue scrq = {};
+	struct ibmvfc_host *vhost;
+
+	vhost = ibmvfc_get_first_vhost();
+	if (!vhost)
+		kunit_skip(test, "No ibmvfc devices available");
+
+	/*
+	 * Embed the synthetic queue in a channels struct with one entry.
+	 * cookie == 0 and msgs.handle == NULL: ibmvfc_deregister_channel()
+	 * must skip both the H_FREE_SUB_CRQ hypercall and the memset.
+	 */
+	channels.scrqs = &scrq;
+	channels.max_queues = 1;
+
+	ibmvfc_deregister_channel(vhost, &channels, 0);
+
+	KUNIT_EXPECT_EQ(test, scrq.cookie, 0UL);
+	KUNIT_EXPECT_EQ(test, scrq.cur, 0);
+	KUNIT_EXPECT_NULL(test, scrq.msgs.handle);
+
+	scsi_host_put(vhost->host);
+}
+
+static struct kunit_case ibmvfc_channel_test_cases[] = {
+	KUNIT_CASE(ibmvfc_deregister_channel_guard_test),
+	{},
+};
+
+static struct kunit_suite ibmvfc_channel_test_suite = {
+	.name = "ibmvfc-channel-test",
+	.test_cases = ibmvfc_channel_test_cases,
+};
+kunit_test_init_section_suite(ibmvfc_channel_test_suite);
+
+MODULE_LICENSE("GPL");
+MODULE_AUTHOR("Dave Marquardt <davemarq@linux.ibm.com>");
+MODULE_DESCRIPTION("Test module for IBM Virtual Fibre Channel Driver");

-- 
2.56.0

