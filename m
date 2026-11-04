From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 03 Nov 2026 20:49:58 -0600
Subject: [PATCH v4 17/25] dmaengine: sdxi: Add unit tests for completion
 pool ownership
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-sdxi-base-v4-17-3668ccc7aab8@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793760600; l=8791;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=UKgpOPnxXxSWuJws2LmbCd9jOGUCzGSR66fffU0Lkh8=;
 b=3ti8GbL21v0aKqtG7r5c2WMxCq0oj9m6meVHSn8qVMixURCdGrM6NUkJzKiK3UFPkyLzs1MQL
 ThDGJXOPTD7CEysRpnVptq0ap2UijQJYwaaJMsaQNvr0RJ3yp6R6i/H
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add hardware-independent KUnit coverage for completion-pool exhaustion
across a bitmap word boundary, arbitrary release and reuse, reinitialization
of reused status blocks. Verify that a claimed block remains unavailable
until explicitly released, including after a simulated late device completion.
Also cover release of an unpublished claim.

Provide test allocation helpers and KUnit-only exports so the tests exercise
the production claim and release paths without a coherent-DMA device.

Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/Makefile           |   1 +
 drivers/dma/sdxi/completion.c       |  37 ++++++++++
 drivers/dma/sdxi/completion.h       |   4 ++
 drivers/dma/sdxi/completion_kunit.c | 131 ++++++++++++++++++++++++++++++++++++
 4 files changed, 173 insertions(+)

diff --git a/drivers/dma/sdxi/Makefile b/drivers/dma/sdxi/Makefile
index eacad504a816..d12eebe03870 100644
--- a/drivers/dma/sdxi/Makefile
+++ b/drivers/dma/sdxi/Makefile
@@ -10,4 +10,5 @@ obj-$(CONFIG_SDXI_PCI) += sdxi-pci.o
 sdxi-pci-y := pci.o
 
 obj-$(CONFIG_SDXI_KUNIT_TEST) += \
+	completion_kunit.o    \
 	ring_kunit.o
diff --git a/drivers/dma/sdxi/completion.c b/drivers/dma/sdxi/completion.c
index c07a0fc101c8..dacd1cac6303 100644
--- a/drivers/dma/sdxi/completion.c
+++ b/drivers/dma/sdxi/completion.c
@@ -4,6 +4,7 @@
  *
  * Copyright Advanced Micro Devices, Inc.
  */
+#include <kunit/visibility.h>
 #include <linux/bitfield.h>
 #include <linux/bitmap.h>
 #include <linux/dma-mapping.h>
@@ -90,6 +91,7 @@ bool sdxi_cst_pool_get(struct sdxi_cst_pool *pool, struct sdxi_completion *comp)
 	sdxi_cst_blk_init(comp->cst_blk);
 	return true;
 }
+EXPORT_SYMBOL_IF_KUNIT(sdxi_cst_pool_get);
 
 int sdxi_cst_pool_get_wait(struct sdxi_cst_pool *pool,
 			 struct sdxi_completion *comp)
@@ -116,7 +118,42 @@ void sdxi_cst_pool_put(struct sdxi_cst_pool *pool, struct sdxi_cst_blk *cst)
 	spin_unlock_irqrestore(&pool->lock, flags);
 	wake_up_all(&pool->wait);
 }
+EXPORT_SYMBOL_IF_KUNIT(sdxi_cst_pool_put);
 
+#if IS_ENABLED(CONFIG_SDXI_KUNIT_TEST)
+/* Exercise allocation without requiring a device capable of coherent DMA. */
+struct sdxi_cst_pool *sdxi_cst_pool_test_create(unsigned int count)
+{
+	struct sdxi_cst_pool *pool;
+
+	pool = kzalloc_obj(*pool, GFP_KERNEL);
+	if (!pool)
+		return NULL;
+	pool->allocated = bitmap_zalloc(count, GFP_KERNEL);
+	if (!pool->allocated) {
+		kfree(pool);
+		return NULL;
+	}
+	pool->blocks = kcalloc(count, sizeof(*pool->blocks), GFP_KERNEL);
+	if (!pool->blocks) {
+		bitmap_free(pool->allocated);
+		kfree(pool);
+		return NULL;
+	}
+	pool->dma = 0x1000;
+	sdxi_cst_pool_init(pool, count);
+	return pool;
+}
+EXPORT_SYMBOL_IF_KUNIT(sdxi_cst_pool_test_create);
+
+void sdxi_cst_pool_test_destroy(struct sdxi_cst_pool *pool)
+{
+	kfree(pool->blocks);
+	bitmap_free(pool->allocated);
+	kfree(pool);
+}
+EXPORT_SYMBOL_IF_KUNIT(sdxi_cst_pool_test_destroy);
+#endif
 
 enum sdxi_completion_state sdxi_cst_blk_check(const struct sdxi_cst_blk *cst)
 {
diff --git a/drivers/dma/sdxi/completion.h b/drivers/dma/sdxi/completion.h
index f91f44b9b516..18c89701d1d6 100644
--- a/drivers/dma/sdxi/completion.h
+++ b/drivers/dma/sdxi/completion.h
@@ -34,6 +34,10 @@ int sdxi_cst_pool_get_wait(struct sdxi_cst_pool *pool,
 /* Release only after consumption, unpublished rollback, or hardware quiescence. */
 void sdxi_cst_pool_put(struct sdxi_cst_pool *pool, struct sdxi_cst_blk *cst);
 
+#if IS_ENABLED(CONFIG_SDXI_KUNIT_TEST)
+struct sdxi_cst_pool *sdxi_cst_pool_test_create(unsigned int count);
+void sdxi_cst_pool_test_destroy(struct sdxi_cst_pool *pool);
+#endif
 
 static inline void sdxi_cst_blk_init(struct sdxi_cst_blk *cst)
 {
diff --git a/drivers/dma/sdxi/completion_kunit.c b/drivers/dma/sdxi/completion_kunit.c
new file mode 100644
index 000000000000..326e3d84da0d
--- /dev/null
+++ b/drivers/dma/sdxi/completion_kunit.c
@@ -0,0 +1,131 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/* Copyright Advanced Micro Devices, Inc. */
+#include <kunit/test.h>
+#include <linux/module.h>
+
+#include "completion.h"
+
+MODULE_IMPORT_NS("EXPORTED_FOR_KUNIT_TESTING");
+
+static void destroy_pool(void *pool)
+{
+	sdxi_cst_pool_test_destroy(pool);
+}
+
+static struct sdxi_cst_pool *alloc_pool(struct kunit *test, unsigned int count)
+{
+	struct sdxi_cst_pool *pool = sdxi_cst_pool_test_create(count);
+
+	if (!pool || kunit_add_action_or_reset(test, destroy_pool, pool))
+		return NULL;
+	return pool;
+}
+
+static void exhaustion(struct kunit *test)
+{
+	/* Cross a bitmap word boundary without filling the final word. */
+	const unsigned int count = BITS_PER_LONG + 3;
+	struct sdxi_completion *held, extra = {};
+	struct sdxi_cst_pool *pool;
+
+	pool = alloc_pool(test, count);
+	KUNIT_ASSERT_NOT_NULL(test, pool);
+	held = kunit_kcalloc(test, count, sizeof(*held), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, held);
+	for (unsigned int i = 0; i < count; i++) {
+		KUNIT_ASSERT_TRUE(test, sdxi_cst_pool_get(pool, &held[i]));
+		KUNIT_EXPECT_EQ(test, held[i].cst_blk_dma % 32, 0);
+		KUNIT_EXPECT_EQ(test, le64_to_cpu(held[i].cst_blk->signal),
+				(u64)SDXI_CST_BLK_SIGNAL_INIT);
+		for (unsigned int j = 0; j < i; j++) {
+			KUNIT_EXPECT_PTR_NE(test, held[i].cst_blk, held[j].cst_blk);
+			KUNIT_EXPECT_NE(test, held[i].cst_blk_dma, held[j].cst_blk_dma);
+		}
+	}
+	KUNIT_EXPECT_FALSE(test, sdxi_cst_pool_get(pool, &extra));
+	KUNIT_EXPECT_PTR_EQ(test, extra.cst_blk, NULL);
+	for (unsigned int i = 0; i < count; i++)
+		sdxi_cst_pool_put(pool, held[i].cst_blk);
+}
+
+static void arbitrary_release(struct kunit *test)
+{
+	struct sdxi_completion held[5], comp;
+	struct sdxi_cst_pool *pool;
+	const unsigned int order[] = { 3, 1, 4, 0, 2 };
+
+	pool = alloc_pool(test, ARRAY_SIZE(held));
+	KUNIT_ASSERT_NOT_NULL(test, pool);
+	for (unsigned int i = 0; i < ARRAY_SIZE(held); i++)
+		KUNIT_ASSERT_TRUE(test, sdxi_cst_pool_get(pool, &held[i]));
+
+	/* A released block is reusable while all other owners retain theirs. */
+	for (unsigned int i = 0; i < ARRAY_SIZE(order); i++) {
+		unsigned int index = order[i];
+
+		sdxi_cst_pool_put(pool, held[index].cst_blk);
+		KUNIT_ASSERT_TRUE(test, sdxi_cst_pool_get(pool, &comp));
+		KUNIT_EXPECT_PTR_EQ(test, comp.cst_blk, held[index].cst_blk);
+		KUNIT_EXPECT_EQ(test, comp.cst_blk_dma, held[index].cst_blk_dma);
+		KUNIT_EXPECT_FALSE(test, sdxi_cst_pool_get(pool, &comp));
+	}
+	for (unsigned int i = 0; i < ARRAY_SIZE(held); i++)
+		sdxi_cst_pool_put(pool, held[i].cst_blk);
+}
+
+static void reuse_initializes_status(struct kunit *test)
+{
+	const struct sdxi_cst_blk initial = {
+		.signal = cpu_to_le64(SDXI_CST_BLK_SIGNAL_INIT),
+	};
+	struct sdxi_completion first, second;
+	struct sdxi_cst_pool *pool;
+
+	pool = alloc_pool(test, 1);
+	KUNIT_ASSERT_NOT_NULL(test, pool);
+	KUNIT_ASSERT_TRUE(test, sdxi_cst_pool_get(pool, &first));
+	memset(first.cst_blk, 0xff, sizeof(*first.cst_blk));
+	first.cst_blk->signal = cpu_to_le64(SDXI_CST_BLK_SIGNAL_TERMINAL);
+	sdxi_cst_pool_put(pool, first.cst_blk);
+	KUNIT_ASSERT_TRUE(test, sdxi_cst_pool_get(pool, &second));
+	KUNIT_EXPECT_PTR_EQ(test, first.cst_blk, second.cst_blk);
+	KUNIT_EXPECT_MEMEQ(test, second.cst_blk, &initial, sizeof(initial));
+	sdxi_cst_pool_put(pool, second.cst_blk);
+}
+
+static void retained_completion(struct kunit *test)
+{
+	struct sdxi_completion timed_out, other;
+	struct sdxi_cst_pool *pool;
+
+	pool = alloc_pool(test, 1);
+	KUNIT_ASSERT_NOT_NULL(test, pool);
+	KUNIT_ASSERT_TRUE(test, sdxi_cst_pool_get(pool, &timed_out));
+	KUNIT_EXPECT_FALSE(test, sdxi_cst_pool_get(pool, &other));
+	/* Even a late completion remains allocated until its owner releases it. */
+	timed_out.cst_blk->signal = cpu_to_le64(SDXI_CST_BLK_SIGNAL_TERMINAL);
+	KUNIT_EXPECT_FALSE(test, sdxi_cst_pool_get(pool, &other));
+	sdxi_cst_pool_put(pool, timed_out.cst_blk);
+	KUNIT_ASSERT_TRUE(test, sdxi_cst_pool_get(pool, &other));
+	/* A never-published claim can be returned without a terminal signal. */
+	sdxi_cst_pool_put(pool, other.cst_blk);
+	KUNIT_ASSERT_TRUE(test, sdxi_cst_pool_get(pool, &other));
+	sdxi_cst_pool_put(pool, other.cst_blk);
+}
+
+static struct kunit_case completion_testcases[] = {
+	KUNIT_CASE(exhaustion),
+	KUNIT_CASE(arbitrary_release),
+	KUNIT_CASE(reuse_initializes_status),
+	KUNIT_CASE(retained_completion),
+	{}
+};
+
+static struct kunit_suite completion_tests = {
+	.name = "SDXI completion pool",
+	.test_cases = completion_testcases,
+};
+kunit_test_suite(completion_tests);
+
+MODULE_DESCRIPTION("SDXI completion pool tests");
+MODULE_LICENSE("GPL");

-- 
2.56.0

