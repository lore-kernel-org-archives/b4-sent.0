From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 03 Nov 2026 20:49:55 -0600
Subject: [PATCH v4 14/25] dmaengine: sdxi: Add unit tests for descriptor
 ring reservations
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-sdxi-base-v4-14-3668ccc7aab8@amd.com>
References: <20261103-sdxi-base-v4-0-3668ccc7aab8@amd.com>
In-Reply-To: <20261103-sdxi-base-v4-0-3668ccc7aab8@amd.com>
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: Bjorn Helgaas <bhelgaas@google.com>, 
 David Rientjes <rientjes@google.com>, John.Kariuki@amd.com, 
 Jonathan Cameron <jic23@kernel.org>, Kinsey Ho <kinseyho@google.com>, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 PradeepVineshReddy.Kodamati@amd.com, Shivank Garg <shivankg@amd.com>, 
 Stephen Bates <Stephen.Bates@amd.com>, Tycho Andersen <tycho@kernel.org>, 
 Wei Huang <wei.huang2@amd.com>, Wei Xu <weixugc@google.com>, 
 dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793760600; l=6959;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=aKi4Ay4MoaaY5cf3ziwzqNP5NjJiIfhtNK1EskqUWzk=;
 b=k5kVxI7V5fAJrf8LM7B0y8xNArZD18+smrSlG93ovsDSA0VLriOzibjXjcat6psavSME3KbZw
 C1LPsu33jzuBExFWSKN0fUSp86lxXJBMQPzIygHlbweRxoWavRbv5lW
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add hardware-independent KUnit tests for full-ring and single-slot
reservations, invalid counts, inconsistent indices, insufficient space,
and bounded reservations and descriptor access after ring wrap.

Include the SDXI KUnit configuration and test build support. Run with:

  tools/testing/kunit/kunit.py run \
    --kunitconfig=drivers/dma/sdxi/.kunitconfig

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/.kunitconfig |   4 ++
 drivers/dma/sdxi/Kconfig      |  10 +++
 drivers/dma/sdxi/Makefile     |   3 +
 drivers/dma/sdxi/ring_kunit.c | 147 ++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 164 insertions(+)

diff --git a/drivers/dma/sdxi/.kunitconfig b/drivers/dma/sdxi/.kunitconfig
new file mode 100644
index 000000000000..16a1ae04b156
--- /dev/null
+++ b/drivers/dma/sdxi/.kunitconfig
@@ -0,0 +1,4 @@
+CONFIG_KUNIT=y
+CONFIG_DMADEVICES=y
+CONFIG_SDXI_CORE=y
+CONFIG_SDXI_KUNIT_TEST=y
diff --git a/drivers/dma/sdxi/Kconfig b/drivers/dma/sdxi/Kconfig
index b91b44231a04..7217375c9216 100644
--- a/drivers/dma/sdxi/Kconfig
+++ b/drivers/dma/sdxi/Kconfig
@@ -26,3 +26,13 @@ config SDXI_PCI
 
 	  To compile this driver as a module, choose M here: the module
 	  will be named "sdxi-pci".
+
+config SDXI_KUNIT_TEST
+	tristate "SDXI unit tests" if !KUNIT_ALL_TESTS
+	depends on SDXI_CORE && KUNIT
+	default KUNIT_ALL_TESTS
+	help
+	  KUnit tests for parts of the SDXI driver. Does not require
+	  SDXI hardware.
+
+	  If unsure, say N.
diff --git a/drivers/dma/sdxi/Makefile b/drivers/dma/sdxi/Makefile
index bfcb443f1e64..00e3f1cb0808 100644
--- a/drivers/dma/sdxi/Makefile
+++ b/drivers/dma/sdxi/Makefile
@@ -7,3 +7,6 @@ sdxi-core-y := \
 
 obj-$(CONFIG_SDXI_PCI) += sdxi-pci.o
 sdxi-pci-y := pci.o
+
+obj-$(CONFIG_SDXI_KUNIT_TEST) += \
+	ring_kunit.o
diff --git a/drivers/dma/sdxi/ring_kunit.c b/drivers/dma/sdxi/ring_kunit.c
new file mode 100644
index 000000000000..7df85fc5549c
--- /dev/null
+++ b/drivers/dma/sdxi/ring_kunit.c
@@ -0,0 +1,147 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * SDXI descriptor ring management tests.
+ *
+ * Copyright Advanced Micro Devices, Inc.
+ */
+#include <kunit/device.h>
+#include <kunit/test-bug.h>
+#include <kunit/test.h>
+#include <linux/container_of.h>
+#include <linux/dma-mapping.h>
+#include <linux/module.h>
+#include <linux/overflow.h>
+#include <linux/packing.h>
+#include <linux/string.h>
+
+#include "ring.h"
+#include "submission.h"
+
+MODULE_IMPORT_NS("EXPORTED_FOR_KUNIT_TESTING");
+
+/* A submission queue backed by plain memory; no device or DMA required. */
+static struct sdxi_sq *alloc_sq(struct kunit *t, u32 count)
+{
+	struct sdxi_sq *sq;
+
+	sq = kunit_kmalloc(t, struct_size(sq, ring, count),
+			   GFP_KERNEL | __GFP_ZERO);
+	if (sq)
+		sq->count = count;
+	return sq;
+}
+
+static void valid(struct kunit *t)
+{
+	struct sdxi_ring_state r;
+	struct sdxi_ring_resv resv;
+	struct sdxi_sq *sq;
+
+	sq = alloc_sq(t, SZ_1K);
+	KUNIT_ASSERT_NOT_NULL(t, sq);
+
+	sdxi_ring_state_init(&r, sq);
+
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve(&r, sq->count, &resv), 0);
+	KUNIT_EXPECT_EQ(t, resv.range.start, 0);
+	KUNIT_EXPECT_EQ(t, resv.range.end, sq->count - 1);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_resv_count(&resv), sq->count);
+	KUNIT_EXPECT_EQ(t, le64_to_cpu(sq->write_index), sq->count);
+
+	/* A ring-sized reservation maps slot i onto ring entry i. */
+	for (unsigned int i = 0; i < sq->count; i++) {
+		KUNIT_EXPECT_EQ(t, sdxi_ring_resv_index(&resv, i), i);
+		KUNIT_EXPECT_PTR_EQ(t, sdxi_ring_desc(&r, i), &sq->ring[i]);
+	}
+
+	sq->cxt_sts.read_index = cpu_to_le64(1);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve(&r, 1, &resv), 0);
+	KUNIT_EXPECT_EQ(t, le64_to_cpu(sq->write_index), sq->count + 1);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_resv_count(&resv), 1);
+
+	/* The index space is unwrapped: index sq->count is entry 0. */
+	KUNIT_EXPECT_EQ(t, sdxi_ring_resv_index(&resv, 0), sq->count);
+	KUNIT_EXPECT_PTR_EQ(t, sdxi_ring_desc(&r, sq->count), &sq->ring[0]);
+}
+
+static void invalid(struct kunit *t)
+{
+	struct sdxi_ring_state rs;
+	struct sdxi_ring_resv resv;
+	struct sdxi_sq *sq;
+
+	sq = alloc_sq(t, SZ_1K);
+	KUNIT_ASSERT_NOT_NULL(t, sq);
+
+	sdxi_ring_state_init(&rs, sq);
+
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve(&rs, 0, &resv), -EINVAL);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve(&rs, sq->count + 1, &resv), -EINVAL);
+
+	sq->cxt_sts.read_index = cpu_to_le64(1);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve(&rs, 1, &resv), -EIO);
+
+	sq->cxt_sts.read_index = 0;
+	sq->write_index = cpu_to_le64(sq->count);
+	sdxi_ring_state_init(&rs, sq);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve(&rs, 1, &resv), -EBUSY);
+
+	sq->cxt_sts.read_index = cpu_to_le64(sq->count);
+	sq->write_index = cpu_to_le64(sq->count + 1);
+	sdxi_ring_state_init(&rs, sq);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve(&rs, sq->count, &resv), -EBUSY);
+}
+
+static void bounded_reservations(struct kunit *t)
+{
+	struct sdxi_ring_state rs;
+	struct sdxi_ring_resv resv;
+	struct sdxi_sq *sq = alloc_sq(t, SZ_1K);
+
+	KUNIT_ASSERT_NOT_NULL(t, sq);
+	sdxi_ring_state_init(&rs, sq);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve_range(&rs, 0, 2, &resv), -EINVAL);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve_range(&rs, 3, 2, &resv), -EINVAL);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve_range(&rs, 2, sq->count + 1, &resv),
+			-EINVAL);
+
+	sq->write_index = cpu_to_le64(sq->count - 2);
+	KUNIT_ASSERT_EQ(t, sdxi_ring_try_reserve_range(&rs, 2, 10, &resv), 0);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_resv_count(&resv), 2);
+	KUNIT_EXPECT_EQ(t, resv.range.start, sq->count - 2);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve_range(&rs, 2, 10, &resv), -EBUSY);
+	sq->cxt_sts.read_index = cpu_to_le64(1);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve_range(&rs, 2, 10, &resv), -EBUSY);
+	sq->cxt_sts.read_index = cpu_to_le64(5);
+	KUNIT_ASSERT_EQ(t, sdxi_ring_try_reserve_range(&rs, 2, 10, &resv), 0);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_resv_count(&resv), 5);
+	KUNIT_EXPECT_PTR_EQ(t, sdxi_slot_desc(sdxi_ring_resv_slot(&resv, 0)),
+			    &sq->ring[0]);
+}
+
+static struct kunit_case testcases[] = {
+	KUNIT_CASE(valid),
+	KUNIT_CASE(invalid),
+	KUNIT_CASE(bounded_reservations),
+	{}
+};
+
+static int setup_device(struct kunit *t)
+{
+	struct device *dev = kunit_device_register(t, "sdxi-mock-device");
+
+	KUNIT_ASSERT_NOT_ERR_OR_NULL(t, dev);
+	t->priv = dev;
+	return 0;
+}
+
+static struct kunit_suite generic_desc_ts = {
+	.name = "SDXI descriptor ring management",
+	.test_cases = testcases,
+	.init = setup_device,
+};
+kunit_test_suite(generic_desc_ts);
+
+MODULE_DESCRIPTION("SDXI descriptor ring tests");
+MODULE_AUTHOR("Nathan Lynch");
+MODULE_LICENSE("GPL");

-- 
2.56.0

