From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Wed, 05 Aug 2026 16:48:25 +0530
Subject: [PATCH 2/3] mm: add KUnit coverage for mappingless swapcache
 folios
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260805-b4-mappingless-swapcache-v1-2-b1d78ba257ca@zohomail.in>
References: <20260805-b4-mappingless-swapcache-v1-0-b1d78ba257ca@zohomail.in>
In-Reply-To: <20260805-b4-mappingless-swapcache-v1-0-b1d78ba257ca@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Zi Yan <ziy@nvidia.com>, Baolin Wang <baolin.wang@linux.alibaba.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Ryan Roberts <ryan.roberts@arm.com>, 
 Dev Jain <dev.jain@arm.com>, Barry Song <baohua@kernel.org>, 
 Lance Yang <lance.yang@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Shuah Khan <shuah@kernel.org>, Nico Pache <nico.pache@linux.dev>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785928706; l=3587;
 i=shivamkalra98@zohomail.in; s=20260402; h=from:subject:message-id;
 bh=3IHZ3BPfu/ApButT5xoLEv/VnC/YC3Wow9MhmnAZMzc=;
 b=kwJo2F0rrfAhLwyUMaWx9mR8UMYCkW+NJtcJ+vkgWEVRteK7dzLUswl4dzXKcjsjnKaY7gy+o
 aZ7xqewrI1jABqzhx/4AhTC7/o5MsARKWLGAI5QWdu0WThzRY5Qn8TP
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=U8kQSxcte8P8iZ6zB7phIj+Yl+i/5ntifBGuclgypx8=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260402 with auth_id=716
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add focused coverage for the folio_check_splittable() eligibility checks.
Verify that an ordinary mappingless folio is rejected, a mappingless
swapcache folio is accepted, and unsupported target orders and split types
remain rejected.

Build the test only when KUnit is built in because
folio_check_splittable() is intentionally not exported.

Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 mm/Kconfig                   | 14 ++++++++++++
 mm/Makefile                  |  1 +
 mm/tests/folio_split_kunit.c | 52 ++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 67 insertions(+)

diff --git a/mm/Kconfig b/mm/Kconfig
index 331daf7fcfab..164dc1438900 100644
--- a/mm/Kconfig
+++ b/mm/Kconfig
@@ -1503,6 +1503,20 @@ config LAZY_MMU_MODE_KUNIT_TEST
 
 	  If unsure, say N.
 
+config FOLIO_SPLIT_KUNIT_TEST
+	bool "KUnit tests for folio splitting" if !KUNIT_ALL_TESTS
+	depends on KUNIT=y
+	depends on TRANSPARENT_HUGEPAGE
+	depends on SWAP
+	default KUNIT_ALL_TESTS
+	help
+	  Enable this option to test folio split eligibility checks. The tests
+	  verify support for mappingless folios in the swap cache and ensure
+	  that unsupported target orders and split types are still rejected.
+	  The tests are built into the kernel and run during KUnit execution.
+
+	  If unsure, say N.
+
 source "mm/damon/Kconfig"
 
 endmenu
diff --git a/mm/Makefile b/mm/Makefile
index ab37ef428d98..f09057b40e1a 100644
--- a/mm/Makefile
+++ b/mm/Makefile
@@ -146,4 +146,5 @@ obj-$(CONFIG_SHRINKER_DEBUG) += shrinker_debug.o
 obj-$(CONFIG_EXECMEM) += execmem.o
 obj-$(CONFIG_TMPFS_QUOTA) += shmem_quota.o
 obj-$(CONFIG_LAZY_MMU_MODE_KUNIT_TEST) += tests/lazy_mmu_mode_kunit.o
+obj-$(CONFIG_FOLIO_SPLIT_KUNIT_TEST) += tests/folio_split_kunit.o
 obj-$(CONFIG_MEM_ALLOC_PROFILING) += alloc_tag.o
diff --git a/mm/tests/folio_split_kunit.c b/mm/tests/folio_split_kunit.c
new file mode 100644
index 000000000000..f91c1a320bbf
--- /dev/null
+++ b/mm/tests/folio_split_kunit.c
@@ -0,0 +1,52 @@
+// SPDX-License-Identifier: GPL-2.0-only
+#include <kunit/test.h>
+#include <linux/errno.h>
+#include <linux/mm.h>
+#include <linux/huge_mm.h>
+#include <linux/module.h>
+#include <linux/pagemap.h>
+
+static void folio_check_splittable_mappingless_swapcache(struct kunit *test)
+{
+	struct folio *folio;
+	int ret;
+
+	folio = folio_alloc(GFP_KERNEL, 2);
+	KUNIT_ASSERT_NOT_NULL(test, folio);
+	folio_lock(folio);
+
+	KUNIT_EXPECT_PTR_EQ(test, folio->mapping, NULL);
+	ret = folio_check_splittable(folio, 0, SPLIT_TYPE_UNIFORM);
+	KUNIT_EXPECT_EQ(test, ret, -EBUSY);
+
+	/* Only the eligibility check is exercised here. */
+	folio_set_swapbacked(folio);
+	folio_set_swapcache(folio);
+
+	ret = folio_check_splittable(folio, 0, SPLIT_TYPE_UNIFORM);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	ret = folio_check_splittable(folio, 1, SPLIT_TYPE_UNIFORM);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+	ret = folio_check_splittable(folio, 0, SPLIT_TYPE_NON_UNIFORM);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	folio_clear_swapcache(folio);
+	folio_clear_swapbacked(folio);
+	folio_unlock(folio);
+	folio_put(folio);
+}
+
+static struct kunit_case folio_split_test_cases[] = {
+	KUNIT_CASE(folio_check_splittable_mappingless_swapcache),
+	{}
+};
+
+static struct kunit_suite folio_split_test_suite = {
+	.name = "folio_split",
+	.test_cases = folio_split_test_cases,
+};
+
+kunit_test_suite(folio_split_test_suite);
+
+MODULE_DESCRIPTION("Tests for folio splitting");
+MODULE_LICENSE("GPL");

-- 
2.43.0

