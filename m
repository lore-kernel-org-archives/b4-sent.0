From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 05 Jun 2026 19:02:16 -0500
Subject: [PATCH v3 13/23] dmaengine: sdxi: Add unit tests for descriptor
 ring reservations
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-sdxi-base-v3-13-4d38ca2bdffe@amd.com>
References: <20260605-sdxi-base-v3-0-4d38ca2bdffe@amd.com>
In-Reply-To: <20260605-sdxi-base-v3-0-4d38ca2bdffe@amd.com>
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
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780704140; l=5291;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=AjqlcR1J/MdjgT8HA14M/iwSkOjphEY9WGqJW4+YCzE=;
 b=D0VFz6DmNWL9JA+2QGNBo5wg4j3HDEu7MZMwXhngMRfX1Tsd46uFat+ytjhWOuWlk3/NxUDjb
 UtfW0FaBUrhBLYJphGbugTqK1aY978WWZ00cwFNUKAAINj3m9HFmrHH
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add KUnit tests for the descriptor ring reservation API, covering:

- Valid reservations: full-ring and single-slot after advancing the
  read pointer.

- Error paths: zero or over-capacity count (-EINVAL), inconsistent
  index state (-EIO), and insufficient space (-EBUSY).

A .kunitconfig is included ease of use:

  $ tools/testing/kunit/kunit.py run \
         --kunitconfig=drivers/dma/sdxi/.kunitconfig

No SDXI hardware is required to run these tests.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/.kunitconfig |   4 ++
 drivers/dma/sdxi/Kconfig      |  10 ++++
 drivers/dma/sdxi/Makefile     |   3 ++
 drivers/dma/sdxi/ring_kunit.c | 105 ++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 122 insertions(+)

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
index 000000000000..3bc7073e0c39
--- /dev/null
+++ b/drivers/dma/sdxi/ring_kunit.c
@@ -0,0 +1,105 @@
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
+#include <linux/packing.h>
+#include <linux/string.h>
+
+#include "ring.h"
+
+MODULE_IMPORT_NS("EXPORTED_FOR_KUNIT_TESTING");
+
+static void valid(struct kunit *t)
+{
+	__le64 wi, ri;
+	struct sdxi_ring_state r;
+	struct sdxi_ring_resv resv;
+	struct sdxi_desc *descs, *desc;
+
+
+	descs = kunit_kmalloc_array(t, SZ_1K, sizeof(descs[0]),
+				    GFP_KERNEL | __GFP_ZERO);
+	KUNIT_ASSERT_NOT_NULL(t, descs);
+
+	ri = wi = 0;
+	sdxi_ring_state_init(&r, &ri, &wi, SZ_1K, descs);
+
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve(&r, r.entries, &resv), 0);
+	KUNIT_EXPECT_EQ(t, resv.range.start, 0);
+	KUNIT_EXPECT_EQ(t, resv.range.end, r.entries - 1);
+	KUNIT_EXPECT_EQ(t, le64_to_cpu(wi), r.entries);
+	sdxi_ring_resv_foreach(&resv, desc) {
+		KUNIT_EXPECT_NOT_NULL_MSG(t, sdxi_ring_resv_next(&resv),
+			"unexpected null descriptor for index %llu", resv.iter);
+	}
+
+	ri = cpu_to_le64(1);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve(&r, 1, &resv), 0);
+	KUNIT_EXPECT_EQ(t, le64_to_cpu(wi), r.entries + 1);
+	KUNIT_EXPECT_NOT_NULL(t, sdxi_ring_resv_next(&resv));
+}
+
+static void invalid(struct kunit *t)
+{
+	__le64 wi, ri;
+	struct sdxi_ring_state rs;
+	struct sdxi_ring_resv resv;
+	struct sdxi_desc *descs;
+
+	descs = kunit_kmalloc_array(t, SZ_1K, sizeof(descs[0]),
+				    GFP_KERNEL | __GFP_ZERO);
+	KUNIT_ASSERT_NOT_NULL(t, descs);
+
+	ri = wi = 0;
+	sdxi_ring_state_init(&rs, &ri, &wi, SZ_1K, descs);
+
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve(&rs, 0, &resv), -EINVAL);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve(&rs, rs.entries + 1, &resv), -EINVAL);
+
+	ri = cpu_to_le64(1);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve(&rs, 1, &resv), -EIO);
+
+	ri = 0;
+	wi = cpu_to_le64(rs.entries);
+	sdxi_ring_state_init(&rs, &ri, &wi, SZ_1K, descs);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve(&rs, 1, &resv), -EBUSY);
+
+	ri = cpu_to_le64(rs.entries);
+	wi = cpu_to_le64(rs.entries + 1);
+	sdxi_ring_state_init(&rs, &ri, &wi, SZ_1K, descs);
+	KUNIT_EXPECT_EQ(t, sdxi_ring_try_reserve(&rs, rs.entries, &resv), -EBUSY);
+}
+
+static struct kunit_case testcases[] = {
+	KUNIT_CASE(valid),
+	KUNIT_CASE(invalid),
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
2.54.0

