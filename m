From: Alireza Asgari <alireza@asgari.net>
Date: Sun, 15 Nov 2026 22:34:43 +0000
Subject: [PATCH RFC nf-next 3/9] memcg: add KUnit coverage for memory.high
 accounting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-b4-nfqueue-memory-accounting-v1-3-b9cc30819997@asgari.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794782082; l=7275;
 i=alireza@asgari.net; s=alireza-kernel; h=from:subject:message-id;
 bh=Z6QbxMTafWb669wa4rTvonBSA708LhbpJBhhLrjki24=;
 b=CTVYi/Mx/6tdBxGj1tMEaVxZ4E6RcSaznHu6ApJh54WF1KH1hRJxcddFgzH1qWKDbzNfOcV30
 v0PQd775resDas0IBE0A8BwvOYL7y6bK7g1wh1mSmjVRgTtqEV3pkrZ
X-Developer-Key: i=alireza@asgari.net; a=ed25519;
 pk=wuQ0/M69FqoVnrCMUJ13EQCwrCwVjCrtz75k15vW8tw=
X-Endpoint-Received: by B4 Relay for alireza@asgari.net/alireza-kernel with auth_id=1055
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Exercise deferred page-debt saturation and the bounded delay arithmetic
without requiring very large memory allocations.

The debt test calls the real charge path using an isolated page-counter
fixture, small GFP_NOWAIT charges, and seeded debt values. It restores
task state and fixture counters before checking results. The arithmetic
cases call the internal helpers directly, including one-page debt and
large numerators whose scaled product would overflow u64.

Keep this coverage independent of the capacity-reservation interface so
the generic MM fixes can be reviewed and tested separately. The tests
require built-in KUnit and memcg support on either word size.

Signed-off-by: Alireza Asgari <alireza@asgari.net>
---
 mm/Kconfig                |  10 +++
 mm/memcontrol.c           |   4 ++
 mm/memcontrol_high_test.c | 162 ++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 176 insertions(+)

diff --git a/mm/Kconfig b/mm/Kconfig
index afff1b25b543..dd763d3d0e36 100644
--- a/mm/Kconfig
+++ b/mm/Kconfig
@@ -1531,6 +1531,16 @@ config PTDUMP
 	bool
 
 
+config MEMCG_HIGH_KUNIT_TEST
+	bool "Memory cgroup high limit tests" if !KUNIT_ALL_TESTS
+	depends on MEMCG && KUNIT=y
+	default KUNIT_ALL_TESTS
+	help
+	  Test deferred memory.high debt saturation through the real charging
+	  path with isolated counters and small charges. Delay tests cover
+	  fixed-point rounding and arithmetic bounds on 32-bit and 64-bit
+	  kernels. Say N unless developing memory cgroup high limit handling.
+
 source "mm/damon/Kconfig"
 
 endmenu
diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 665ce8dfb9ec..446b60ca6aef 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -6532,3 +6532,7 @@ void mem_cgroup_show_protected_memory(struct mem_cgroup *memcg)
 		K(atomic_long_read(&memcg->memory.children_min_usage)),
 		K(atomic_long_read(&memcg->memory.children_low_usage)));
 }
+
+#if IS_ENABLED(CONFIG_MEMCG_HIGH_KUNIT_TEST)
+#include "memcontrol_high_test.c"
+#endif
diff --git a/mm/memcontrol_high_test.c b/mm/memcontrol_high_test.c
new file mode 100644
index 000000000000..bf792d398021
--- /dev/null
+++ b/mm/memcontrol_high_test.c
@@ -0,0 +1,162 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+
+#include <kunit/test.h>
+
+static void memcg_high_test_restore_counter(struct page_counter *counter,
+					    unsigned long before)
+{
+	unsigned long after = page_counter_read(counter);
+
+	if (after > before)
+		page_counter_uncharge(counter, after - before);
+	else if (after < before)
+		page_counter_charge(counter, before - after);
+}
+
+static void memcg_high_test_debt(struct kunit *test)
+{
+	const unsigned int nr_pages = MEMCG_CHARGE_BATCH + 1;
+	const struct {
+		unsigned int before;
+		unsigned int expected;
+	} cases[] = {
+		{ 0, nr_pages },
+		{ UINT_MAX - nr_pages, UINT_MAX },
+		{ UINT_MAX - nr_pages + 1, UINT_MAX },
+		{ UINT_MAX, UINT_MAX },
+	};
+	struct mem_cgroup *memcg;
+	unsigned int i;
+
+	memcg = kunit_kzalloc(test, sizeof(*memcg), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, memcg);
+	page_counter_init(&memcg->memory, NULL, false);
+	page_counter_init(&memcg->memsw, NULL, false);
+	page_counter_init(&memcg->swap, NULL, false);
+	page_counter_set_high(&memcg->memory, 0);
+	page_counter_set_high(&memcg->swap, PAGE_COUNTER_MAX);
+
+	for (i = 0; i < ARRAY_SIZE(cases); i++) {
+		unsigned int saved = current->memcg_nr_pages_over_high;
+		bool notify = test_thread_flag(TIF_NOTIFY_RESUME);
+		unsigned int debt;
+		bool notified;
+		int ret;
+
+		/*
+		 * Exceed the stock batch to use the real counter charge path
+		 * without leaving a reference to this isolated fixture in stock.
+		 * GFP_NOWAIT defers reclaim until return to userspace.
+		 */
+		current->memcg_nr_pages_over_high = cases[i].before;
+		ret = try_charge_memcg(memcg, GFP_NOWAIT, nr_pages);
+		debt = current->memcg_nr_pages_over_high;
+		notified = test_thread_flag(TIF_NOTIFY_RESUME);
+
+		/* Restore the test task before any assertion can abort the case. */
+		current->memcg_nr_pages_over_high = saved;
+		if (!notify)
+			clear_thread_flag(TIF_NOTIFY_RESUME);
+		memcg_high_test_restore_counter(&memcg->memory, 0);
+		if (do_memsw_account())
+			memcg_high_test_restore_counter(&memcg->memsw, 0);
+
+		KUNIT_EXPECT_EQ_MSG(test, ret, 0, "case %u", i);
+		KUNIT_EXPECT_EQ_MSG(test, debt, cases[i].expected, "case %u",
+				    i);
+		KUNIT_EXPECT_TRUE_MSG(test, notified, "case %u", i);
+	}
+}
+
+static void memcg_high_test_overage(struct kunit *test)
+{
+	const unsigned long large_high = 1UL << (BITS_PER_LONG - 3);
+	const struct {
+		unsigned long usage;
+		unsigned long high;
+		u64 expected;
+	} cases[] = {
+		{ 0, 0, 0 },
+		{ 1, 0, 0 },
+		{ 2, 0, 1ULL << 20 },
+		{ 99, 100, 0 },
+		{ 100, 100, 0 },
+		{ 110, 100, 104857 },
+		{ 150, 100, 524288 },
+		{ 299, 100, 2086666 },
+		{ 300, 100, 2ULL << 20 },
+		{ 301, 100, 2ULL << 20 },
+		{ ULONG_MAX, 1, 2ULL << 20 },
+		{ ULONG_MAX, ULONG_MAX - 1, 0 },
+		/* A modest ratio whose scaled numerator exceeds u64 on 64-bit. */
+		{ large_high + large_high / 16, large_high, 1ULL << 16 },
+	};
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(cases); i++)
+		KUNIT_EXPECT_EQ_MSG(
+			test, calculate_overage(cases[i].usage, cases[i].high),
+			cases[i].expected, "case %u", i);
+}
+
+static void memcg_high_test_delay(struct kunit *test)
+{
+	const unsigned long cap = MEMCG_MAX_HIGH_DELAY_JIFFIES;
+	const struct {
+		unsigned int pages;
+		u64 overage;
+		unsigned long expected;
+	} cases[] = {
+		{ 0, 0, 0 },
+		{ 0, U64_MAX, 0 },
+		{ UINT_MAX, 0, 0 },
+		{ 1, 1ULL << 16, (HZ / 4) / 64 },
+		{ 63, 1ULL << 16, (HZ / 4) * 63 / 64 },
+		{ 64, 1ULL << 16, HZ / 4 },
+		{ 65, 1ULL << 16, (HZ / 4) * 65 / 64 },
+		{ UINT_MAX, 1ULL << 16, cap },
+		{ 64, 1ULL << 17, HZ },
+		/* Apply debt scaling before the cap, including sub-batch debt. */
+		{ 1, 1ULL << 18, HZ / 16 },
+		{ 1, 1ULL << 20, HZ },
+		{ 2, 1ULL << 20, cap },
+		{ 1, 2ULL << 20, cap },
+		{ 64, 1ULL << 32, cap },
+		{ UINT_MAX, 1ULL << 32, cap },
+		{ 1, U64_MAX, cap },
+		{ UINT_MAX, U64_MAX, cap },
+	};
+	unsigned long delay;
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(cases); i++)
+		KUNIT_EXPECT_EQ_MSG(test,
+				    calculate_high_delay(cases[i].pages,
+							 cases[i].overage),
+				    cases[i].expected, "case %u", i);
+
+	/* 32 GiB over an 8 MiB high limit, expressed in 4 KiB pages. */
+	KUNIT_EXPECT_EQ(
+		test,
+		calculate_high_delay(64, calculate_overage((1UL << 23) + 2048,
+							   2048)),
+		cap);
+	/* Both memory and swap contributions are bounded before addition. */
+	delay = calculate_high_delay(UINT_MAX, U64_MAX);
+	delay += calculate_high_delay(UINT_MAX, U64_MAX);
+	KUNIT_EXPECT_EQ(test, delay, 2 * cap);
+}
+
+static struct kunit_case memcg_high_test_cases[] = {
+	KUNIT_CASE(memcg_high_test_debt),
+	KUNIT_CASE(memcg_high_test_overage),
+	KUNIT_CASE(memcg_high_test_delay),
+	{}
+};
+
+static struct kunit_suite memcg_high_test_suite = {
+	.name = "memcg_high",
+	.test_cases = memcg_high_test_cases,
+};
+
+kunit_test_suite(memcg_high_test_suite);

-- 
2.34.1

