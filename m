From: Alireza Asgari <alireza@asgari.net>
Date: Sun, 15 Nov 2026 22:34:45 +0000
Subject: [PATCH RFC nf-next 5/9] memcg: test capacity reservation rollback
 and refunds
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-b4-nfqueue-memory-accounting-v1-5-b9cc30819997@asgari.net>
References: <20261115-b4-nfqueue-memory-accounting-v1-0-b9cc30819997@asgari.net>
In-Reply-To: <20261115-b4-nfqueue-memory-accounting-v1-0-b9cc30819997@asgari.net>
To: netfilter-devel@vger.kernel.org, linux-mm@kvack.org
Cc: Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, 
 Pablo Neira Ayuso <pablo@netfilter.org>, Florian Westphal <fw@strlen.de>, 
 Phil Sutter <phil@nwl.cc>, Shuah Khan <shuah@kernel.org>, 
 Tejun Heo <tj@kernel.org>, Vladimir Davydov <vdavydov.dev@gmail.com>, 
 Chris Down <chris@chrisdown.name>, 
 Zhang Jiao <zhangjiao2@cmss.chinamobile.com>, Song Hu <husong@kylinos.cn>, 
 cgroups@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Alireza Asgari <alireza@asgari.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794782082; l=12013;
 i=alireza@asgari.net; s=alireza-kernel; h=from:subject:message-id;
 bh=JloqzugReTrQDTmQ8+3w3kkQBiN+qr4RbrFYTkj8puY=;
 b=gg11vMfGHX0ZXN6TpMvg36yRN9ncGpEk8plCsVJP9PFk5Y2as5paAhWF0bnq91G+PynzVjsEA
 Y1JGes7kSe5CdUilOWpBrOq7AGkkAT/+kmim7jw6bR3Seu7vVVS31XK
X-Developer-Key: i=alireza@asgari.net; a=ed25519;
 pk=wuQ0/M69FqoVnrCMUJ13EQCwrCwVjCrtz75k15vW8tw=
X-Endpoint-Received: by B4 Relay for alireza@asgari.net/alireza-kernel with auth_id=1055
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add reservation-specific KUnit coverage for partial-growth rollback,
reparented-root growth, range and architecture checks, and root refunds.

Transaction cases inject charge results through KUnit static stubs.
The root-refund case uses temporary real root page-counter charges while
other CPUs are stopped, and restores the counters even if the expected
refund is absent. It models charges inherited after reparenting; the
network selftest separately exercises real cgroup removal.

Keep these tests separate from the generic memory.high suite and make
all redirection conditional on the reservation KUnit option.

Signed-off-by: Alireza Asgari <alireza@asgari.net>
---
 mm/Kconfig                       |  11 ++
 mm/memcontrol.c                  |  16 +++
 mm/memcontrol_reservation_test.c | 232 +++++++++++++++++++++++++++++++++++++++
 3 files changed, 259 insertions(+)

diff --git a/mm/Kconfig b/mm/Kconfig
index dd763d3d0e36..39db388f193f 100644
--- a/mm/Kconfig
+++ b/mm/Kconfig
@@ -1541,6 +1541,17 @@ config MEMCG_HIGH_KUNIT_TEST
 	  fixed-point rounding and arithmetic bounds on 32-bit and 64-bit
 	  kernels. Say N unless developing memory cgroup high limit handling.
 
+config MEMCG_RESERVATION_KUNIT_TEST
+	bool "Memory cgroup capacity reservation tests" if !KUNIT_ALL_TESTS
+	depends on MEMCG && KUNIT=y
+	default KUNIT_ALL_TESTS
+	help
+	  Test capacity reservation transactions, including partial growth
+	  failure, architecture support, and uncharged growth after reparenting
+	  to root. Transaction tests inject charge results. The root refund test
+	  checks real counters with a temporary eight-page charge while other
+	  CPUs are stopped. Say N unless developing this interface.
+
 source "mm/damon/Kconfig"
 
 endmenu
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 0227d9b411f5..d49ce5a92c1f 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -73,6 +73,10 @@
 
 #include <linux/uaccess.h>
 
+#if IS_ENABLED(CONFIG_MEMCG_RESERVATION_KUNIT_TEST)
+#include <kunit/static_stub.h>
+#endif
+
 #define CREATE_TRACE_POINTS
 #include <trace/events/memcg.h>
 #undef CREATE_TRACE_POINTS
@@ -3264,6 +3268,10 @@ static int mem_cgroup_reservation_charge(struct obj_cgroup *objcg,
 	struct mem_cgroup *memcg;
 	int ret = 0;
 
+#if IS_ENABLED(CONFIG_MEMCG_RESERVATION_KUNIT_TEST)
+	KUNIT_STATIC_STUB_REDIRECT(mem_cgroup_reservation_charge, objcg, pages,
+				   charged);
+#endif
 	memcg = get_mem_cgroup_from_objcg(objcg);
 	*charged = false;
 	/* Reparenting to root removes the limit, not previously held charges. */
@@ -3291,6 +3299,10 @@ static void mem_cgroup_reservation_uncharge_batch(struct mem_cgroup *memcg,
 
 static void mem_cgroup_reservation_uncharge(struct obj_cgroup *objcg, u64 pages)
 {
+#if IS_ENABLED(CONFIG_MEMCG_RESERVATION_KUNIT_TEST)
+	KUNIT_STATIC_STUB_REDIRECT(mem_cgroup_reservation_uncharge, objcg,
+				   pages);
+#endif
 	while (pages) {
 		unsigned int batch = min_t(u64, pages, MEMCG_RESERVATION_BATCH);
 		struct mem_cgroup *memcg;
@@ -6699,3 +6711,7 @@ void mem_cgroup_show_protected_memory(struct mem_cgroup *memcg)
 #if IS_ENABLED(CONFIG_MEMCG_HIGH_KUNIT_TEST)
 #include "memcontrol_high_test.c"
 #endif
+
+#if IS_ENABLED(CONFIG_MEMCG_RESERVATION_KUNIT_TEST)
+#include "memcontrol_reservation_test.c"
+#endif
diff --git a/mm/memcontrol_reservation_test.c b/mm/memcontrol_reservation_test.c
new file mode 100644
index 000000000000..5ce4f05431b3
--- /dev/null
+++ b/mm/memcontrol_reservation_test.c
@@ -0,0 +1,232 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+
+#include <kunit/test.h>
+#include <linux/stop_machine.h>
+
+struct memcg_reservation_test {
+	struct obj_cgroup owner;
+	struct mem_cgroup_reservation res;
+	u64 refunds;
+	unsigned int calls;
+	unsigned int fail_call;
+	bool uncharged;
+};
+
+static int memcg_reservation_test_charge(struct obj_cgroup *objcg,
+					 unsigned int pages, bool *charged)
+{
+	struct memcg_reservation_test *ctx = kunit_get_current_test()->priv;
+
+	*charged = !ctx->uncharged;
+	if (++ctx->calls == ctx->fail_call)
+		return -ENOMEM;
+	return 0;
+}
+
+static void memcg_reservation_test_uncharge(struct obj_cgroup *objcg, u64 pages)
+{
+	struct memcg_reservation_test *ctx = kunit_get_current_test()->priv;
+
+	ctx->refunds += pages;
+}
+
+static int memcg_reservation_test_init(struct kunit *test)
+{
+	struct memcg_reservation_test *ctx;
+
+	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
+	if (!ctx)
+		return -ENOMEM;
+	/* Transaction cases stub accounting; the root refund case calls the batch. */
+	ctx->owner.is_root = true;
+	ctx->res.objcg = &ctx->owner;
+	test->priv = ctx;
+	kunit_activate_static_stub(test, mem_cgroup_reservation_charge,
+				   memcg_reservation_test_charge);
+	kunit_activate_static_stub(test, mem_cgroup_reservation_uncharge,
+				   memcg_reservation_test_uncharge);
+	return 0;
+}
+
+static void memcg_reservation_test_rollback(struct kunit *test)
+{
+	struct memcg_reservation_test *ctx = test->priv;
+	u64 original = 7;
+
+	if (!IS_ENABLED(CONFIG_64BIT)) {
+		kunit_skip(test,
+			   "Charged reservations require 64-bit counters");
+		return;
+	}
+	KUNIT_ASSERT_EQ(test,
+			mem_cgroup_reservation_resize(&ctx->res, original), 0);
+	ctx->calls = 0;
+	ctx->fail_call = 2;
+	KUNIT_EXPECT_EQ(test,
+			mem_cgroup_reservation_resize(
+				&ctx->res,
+				original + MEMCG_RESERVATION_BATCH + 1),
+			-ENOMEM);
+	KUNIT_EXPECT_EQ(test, ctx->res.pages, original);
+	KUNIT_EXPECT_EQ(test, ctx->res.charged_pages, original);
+	KUNIT_EXPECT_EQ(test, ctx->refunds, (u64)MEMCG_RESERVATION_BATCH);
+	KUNIT_EXPECT_EQ(test, ctx->calls, 2U);
+	mem_cgroup_reservation_destroy(&ctx->res);
+	KUNIT_EXPECT_EQ(test, ctx->refunds, MEMCG_RESERVATION_BATCH + original);
+	KUNIT_EXPECT_PTR_EQ(test, ctx->res.objcg, NULL);
+}
+
+static void memcg_reservation_test_root_growth(struct kunit *test)
+{
+	struct memcg_reservation_test *ctx = test->priv;
+
+	if (!IS_ENABLED(CONFIG_64BIT)) {
+		kunit_skip(test,
+			   "Charged reservations require 64-bit counters");
+		return;
+	}
+	KUNIT_ASSERT_EQ(test, mem_cgroup_reservation_resize(&ctx->res, 8), 0);
+	/* Simulate the charge helper observing reparenting to root. */
+	ctx->uncharged = true;
+	KUNIT_ASSERT_EQ(test, mem_cgroup_reservation_resize(&ctx->res, 16), 0);
+	KUNIT_EXPECT_EQ(test, ctx->res.charged_pages, 8ULL);
+	KUNIT_ASSERT_EQ(test, mem_cgroup_reservation_resize(&ctx->res, 10), 0);
+	KUNIT_EXPECT_EQ(test, ctx->refunds, 0ULL);
+	KUNIT_ASSERT_EQ(test, mem_cgroup_reservation_resize(&ctx->res, 3), 0);
+	KUNIT_EXPECT_EQ(test, ctx->res.charged_pages, 3ULL);
+	KUNIT_EXPECT_EQ(test, ctx->refunds, 5ULL);
+	mem_cgroup_reservation_destroy(&ctx->res);
+	KUNIT_EXPECT_EQ(test, ctx->refunds, 8ULL);
+	KUNIT_EXPECT_EQ(test, ctx->res.pages, 0ULL);
+	KUNIT_EXPECT_EQ(test, ctx->res.charged_pages, 0ULL);
+}
+
+static void memcg_reservation_test_range(struct kunit *test)
+{
+	struct memcg_reservation_test *ctx = test->priv;
+
+	KUNIT_EXPECT_EQ(test,
+			mem_cgroup_reservation_resize(
+				&ctx->res, (u64)PAGE_COUNTER_MAX + 1),
+			-E2BIG);
+	KUNIT_EXPECT_EQ(test, ctx->calls, 0U);
+	KUNIT_EXPECT_EQ(test, ctx->res.pages, 0ULL);
+	mem_cgroup_reservation_destroy(&ctx->res);
+	/* Disabled/root ownership still records the logical reservation. */
+	KUNIT_EXPECT_EQ(test, mem_cgroup_reservation_resize(&ctx->res, 9), 0);
+	KUNIT_EXPECT_EQ(test, ctx->res.pages, 9ULL);
+	KUNIT_EXPECT_EQ(test, ctx->res.charged_pages, 0ULL);
+	mem_cgroup_reservation_destroy(&ctx->res);
+}
+
+static void memcg_reservation_test_arch_support(struct kunit *test)
+{
+	struct memcg_reservation_test *ctx = test->priv;
+	bool supported = IS_ENABLED(CONFIG_64BIT);
+
+	KUNIT_ASSERT_EQ(test, mem_cgroup_reservation_resize(&ctx->res, 0), 0);
+	KUNIT_EXPECT_EQ(test, ctx->calls, 0U);
+	KUNIT_EXPECT_EQ(test, mem_cgroup_reservation_resize(&ctx->res, 9),
+			supported ? 0 : -EOPNOTSUPP);
+	KUNIT_EXPECT_EQ(test, ctx->calls, supported ? 1U : 0U);
+	KUNIT_EXPECT_EQ(test, ctx->res.pages, supported ? 9ULL : 0ULL);
+	KUNIT_EXPECT_EQ(test, ctx->res.charged_pages, supported ? 9ULL : 0ULL);
+	KUNIT_EXPECT_EQ(test, ctx->refunds, 0ULL);
+	mem_cgroup_reservation_destroy(&ctx->res);
+	KUNIT_EXPECT_EQ(test, ctx->refunds, supported ? 9ULL : 0ULL);
+	KUNIT_EXPECT_PTR_EQ(test, ctx->res.objcg, NULL);
+
+	/* An uncharged reservation remains usable on either architecture. */
+	KUNIT_ASSERT_EQ(test, mem_cgroup_reservation_resize(&ctx->res, 9), 0);
+	KUNIT_EXPECT_EQ(test, ctx->res.pages, 9ULL);
+	KUNIT_EXPECT_EQ(test, ctx->res.charged_pages, 0ULL);
+	KUNIT_EXPECT_EQ(test, ctx->calls, supported ? 1U : 0U);
+	mem_cgroup_reservation_destroy(&ctx->res);
+	KUNIT_EXPECT_EQ(test, ctx->refunds, supported ? 9ULL : 0ULL);
+}
+
+struct memcg_reservation_root_refund {
+	unsigned long memory_before, memory_shrunk, memory_after;
+	unsigned long memsw_before, memsw_shrunk, memsw_after;
+	bool memsw;
+};
+
+static void memcg_reservation_test_restore_counter(struct page_counter *counter,
+						   unsigned long before)
+{
+	unsigned long after = page_counter_read(counter);
+
+	if (after > before)
+		page_counter_uncharge(counter, after - before);
+	else if (after < before)
+		page_counter_charge(counter, before - after);
+}
+
+static int memcg_reservation_test_root_refund_stopped(void *data)
+{
+	struct memcg_reservation_root_refund *result = data;
+	struct mem_cgroup *memcg = root_mem_cgroup;
+
+	/* Model charged capacity inherited from a removed child. */
+	result->memory_before = page_counter_read(&memcg->memory);
+	result->memsw_before = page_counter_read(&memcg->memsw);
+	page_counter_charge(&memcg->memory, 8);
+	if (result->memsw)
+		page_counter_charge(&memcg->memsw, 8);
+	account_kmem_nmi_safe(memcg, 8);
+	memcg1_account_kmem(memcg, 8);
+
+	mem_cgroup_reservation_uncharge_batch(memcg, 3);
+	result->memory_shrunk = page_counter_read(&memcg->memory);
+	result->memsw_shrunk = page_counter_read(&memcg->memsw);
+	mem_cgroup_reservation_uncharge_batch(memcg, 5);
+	result->memory_after = page_counter_read(&memcg->memory);
+	result->memsw_after = page_counter_read(&memcg->memsw);
+
+	/* Leave no counter imbalance behind if the refund regression returns. */
+	memcg_reservation_test_restore_counter(&memcg->memory,
+					       result->memory_before);
+	if (result->memsw)
+		memcg_reservation_test_restore_counter(&memcg->memsw,
+						       result->memsw_before);
+	return 0;
+}
+
+static void memcg_reservation_test_root_refund(struct kunit *test)
+{
+	struct memcg_reservation_root_refund result = {
+		.memsw = do_memsw_account(),
+	};
+
+	if (mem_cgroup_disabled() || mem_cgroup_kmem_disabled()) {
+		kunit_skip(test, "Memory cgroup accounting is disabled");
+		return;
+	}
+	/* Exclude background charges while checking the actual root counters. */
+	KUNIT_ASSERT_EQ(test,
+			stop_machine(memcg_reservation_test_root_refund_stopped,
+				     &result, NULL),
+			0);
+	KUNIT_EXPECT_EQ(test, result.memory_shrunk, result.memory_before + 5);
+	KUNIT_EXPECT_EQ(test, result.memory_after, result.memory_before);
+	KUNIT_EXPECT_EQ(test, result.memsw_shrunk,
+			result.memsw_before + (result.memsw ? 5 : 0));
+	KUNIT_EXPECT_EQ(test, result.memsw_after, result.memsw_before);
+}
+
+static struct kunit_case memcg_reservation_test_cases[] = {
+	KUNIT_CASE(memcg_reservation_test_rollback),
+	KUNIT_CASE(memcg_reservation_test_root_growth),
+	KUNIT_CASE(memcg_reservation_test_range),
+	KUNIT_CASE(memcg_reservation_test_arch_support),
+	KUNIT_CASE(memcg_reservation_test_root_refund),
+	{}
+};
+
+static struct kunit_suite memcg_reservation_test_suite = {
+	.name = "memcg_reservation",
+	.init = memcg_reservation_test_init,
+	.test_cases = memcg_reservation_test_cases,
+};
+
+kunit_test_suite(memcg_reservation_test_suite);

-- 
2.34.1

