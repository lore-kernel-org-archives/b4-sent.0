From: Ackerley Tng <ackerleytng@google.com>
Date: Mon, 20 Jul 2026 17:25:12 -0700
Subject: [PATCH v3 09/13] WIP: tools: testing: Add userspace unit tests for
 HugeTLB subpools
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-hugetlb-alloc-failure-fixes-v3-9-7d2a169aa9ee@google.com>
References: <20260720-hugetlb-alloc-failure-fixes-v3-0-7d2a169aa9ee@google.com>
In-Reply-To: <20260720-hugetlb-alloc-failure-fixes-v3-0-7d2a169aa9ee@google.com>
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Nhat Pham <nphamcs@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Peter Xu <peterx@redhat.com>, 
 Wupeng Ma <mawupeng1@huawei.com>, fvdl@google.com, rientjes@google.com, 
 jthoughton@google.com, Mike Kravetz <mike.kravetz@oracle.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>
Cc: vannapurve@google.com, erdemaktas@google.com, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784602387; l=14766;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=AFhB3BYtnUMT5tXegPxhvbG8FQDY9Ut+0oGZYrpvwok=;
 b=mrCruZP1FMarqd1HWOG5AX+9jUQaU5ylqrHxi315b0QQ25YCYRIDJnh37ncg1zwrkEKn4cXbn
 tf1wcSSWxEXDYUnpi6W9u0d33J+eZV2xvMufZECFIv66dcAVvFWMUei
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a standalone Userspace Unit Testing Suite under
`tools/testing/hugetlb_subpool/` to exercise and stress-test the new
internal `mm/hugetlb_subpool.c` API boundaries.

Reuses the private kernel `struct hugepage_subpool` struct layout
natively by embedding the implementation directly, avoiding
structural definition drift between the implementation and testing
mock environments.

TAG=agy
CONV=5f2e8401-48d5-42c5-ab78-6b2f1aa16aff

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/hugetlb_subpool/.gitignore     |   1 +
 tools/testing/hugetlb_subpool/Makefile       |  18 ++
 tools/testing/hugetlb_subpool/test_subpool.c | 400 +++++++++++++++++++++++++++
 3 files changed, 419 insertions(+)

diff --git a/tools/testing/hugetlb_subpool/.gitignore b/tools/testing/hugetlb_subpool/.gitignore
new file mode 100644
index 0000000000000..7348c2c72f1e1
--- /dev/null
+++ b/tools/testing/hugetlb_subpool/.gitignore
@@ -0,0 +1 @@
+test_subpool
diff --git a/tools/testing/hugetlb_subpool/Makefile b/tools/testing/hugetlb_subpool/Makefile
new file mode 100644
index 0000000000000..1bdb7e2635614
--- /dev/null
+++ b/tools/testing/hugetlb_subpool/Makefile
@@ -0,0 +1,18 @@
+# SPDX-License-Identifier: GPL-2.0
+.PHONY: all clean test
+
+CC = gcc
+CFLAGS = -Wall -O2 -I../shared -I. -I../../include -I../../arch/x86/include -pthread
+KERNEL_SUBPOOL_H = ../../../mm/hugetlb_subpool.h
+KERNEL_SUBPOOL_C = ../../../mm/hugetlb_subpool.c
+
+all: test
+
+test_subpool: test_subpool.c $(KERNEL_SUBPOOL_C) $(KERNEL_SUBPOOL_H)
+	$(CC) $(CFLAGS) test_subpool.c -o test_subpool
+
+test: test_subpool
+	./test_subpool
+
+clean:
+	rm -f test_subpool
diff --git a/tools/testing/hugetlb_subpool/test_subpool.c b/tools/testing/hugetlb_subpool/test_subpool.c
new file mode 100644
index 0000000000000..78900274cc264
--- /dev/null
+++ b/tools/testing/hugetlb_subpool/test_subpool.c
@@ -0,0 +1,400 @@
+// SPDX-License-Identifier: GPL-2.0
+#include <assert.h>
+#include <stdlib.h>
+#include <linux/types.h>
+#include <linux/slab.h>
+#include <linux/bug.h>
+
+/* Mocked Userspace implementation for Kernel Subpool allocation dependencies */
+struct hstate {
+	int dummy;
+};
+
+#undef kzalloc_obj
+#undef kzalloc_objs
+#define kzalloc_obj(P, ...) malloc(sizeof(P))
+#define kzalloc_objs(P, COUNT, ...) malloc(sizeof(P) * (COUNT))
+
+#define kfree free
+#define kmalloc malloc
+
+#define huge_page_shift(h) (21 + (0 * ((unsigned long)(h) & 0)))
+#define huge_page_size(h) (1UL << huge_page_shift(h))
+
+static bool hugetlb_acct_memory_called;
+static struct hstate *hugetlb_acct_memory_h;
+static long hugetlb_acct_memory_delta;
+
+static int hugetlb_acct_memory(struct hstate *h, long delta)
+{
+	hugetlb_acct_memory_called = true;
+	hugetlb_acct_memory_h = h;
+	hugetlb_acct_memory_delta = delta;
+	return 0;
+}
+
+static void reset_hugetlb_acct_memory_mock(void)
+{
+	hugetlb_acct_memory_called = false;
+	hugetlb_acct_memory_h = NULL;
+	hugetlb_acct_memory_delta = 0;
+}
+
+static void assert_hugetlb_acct_memory_called(struct hstate *h, long delta)
+{
+	assert(hugetlb_acct_memory_called);
+	assert(hugetlb_acct_memory_h == h);
+	assert(hugetlb_acct_memory_delta == delta);
+
+	reset_hugetlb_acct_memory_mock();
+}
+
+static void assert_hugetlb_acct_memory_not_called(void)
+{
+	assert(!hugetlb_acct_memory_called);
+}
+
+#include "../../../mm/hugetlb_subpool.h"
+#include "../../../mm/hugetlb_subpool.c"
+
+static void test_subpool_new_put_no_min_limit(void)
+{
+	struct hstate h;
+	struct hugepage_subpool *spool;
+
+	spool = hugepage_new_subpool(&h, 10, -1);
+	assert(spool != NULL);
+	assert(spool->max_hpages == 10);
+	assert(spool->min_hpages == -1);
+	assert(spool->rsv_hpages == -1);
+	assert(spool->count == 1);
+	assert_hugetlb_acct_memory_not_called();
+
+	hugepage_put_subpool(spool);
+	assert_hugetlb_acct_memory_not_called();
+}
+
+static void test_subpool_new_put_with_min_limit(void)
+{
+	struct hstate h;
+	struct hugepage_subpool *spool;
+
+	spool = hugepage_new_subpool(&h, 20, 5);
+	assert(spool != NULL);
+	assert(spool->max_hpages == 20);
+	assert(spool->min_hpages == 5);
+	assert(spool->rsv_hpages == 5);
+	assert(spool->count == 1);
+	assert_hugetlb_acct_memory_called(&h, 5);
+
+	hugepage_put_subpool(spool);
+	assert_hugetlb_acct_memory_called(&h, -5);
+}
+
+static void test_subpool_get_pages_below_min(void)
+{
+	struct hstate h;
+	struct hugepage_subpool *spool;
+	long ret;
+
+	/* Let's initialize: min_hpages = 10, used_hpages = 9, rsv_hpages = 1 */
+	spool = hugepage_new_subpool(&h, -1, 10);
+	assert_hugetlb_acct_memory_called(&h, 10);
+
+	ret = hugepage_subpool_get_pages(spool, 9);
+	assert(ret == 0);
+	assert(spool->used_hpages == 9);
+	assert(spool->rsv_hpages == 1);
+
+	/* Invoke Get (Consumes the remaining 1 subpool reserve!) */
+	ret = hugepage_subpool_get_pages(spool, 1);
+	assert(ret == 0); /* Covered by subpool reserve! */
+	assert(spool->used_hpages == 10);
+	assert(spool->rsv_hpages == 0);
+
+	/* Invoke Put (Replenishes the subpool reserve!) */
+	ret = hugepage_subpool_put_pages(spool, 1);
+	assert(ret == 0); /* Kept by subpool reserve! */
+	assert(spool->used_hpages == 9);
+	assert(spool->rsv_hpages == 1);
+
+	/* Cleanup: Return used_hpages to 0 so the subpool frees symmetrically! */
+	hugepage_subpool_put_pages(spool, 9);
+	hugepage_put_subpool(spool);
+	assert_hugetlb_acct_memory_called(&h, -10);
+}
+
+static void test_subpool_get_pages_crossing_min(void)
+{
+	struct hstate h;
+	struct hugepage_subpool *spool;
+	long ret;
+
+	/* Let's initialize: min_hpages = 10, used_hpages = 10, rsv_hpages = 0 */
+	spool = hugepage_new_subpool(&h, -1, 10);
+	assert_hugetlb_acct_memory_called(&h, 10);
+
+	hugepage_subpool_get_pages(spool, 10);
+	assert(spool->used_hpages == 10);
+	assert(spool->rsv_hpages == 0);
+
+	/* Invoke Get (Triggers a request for a Global Buddy/Surplus page!) */
+	ret = hugepage_subpool_get_pages(spool, 1);
+	assert(ret == 1); /* Requires global page! */
+	assert(spool->used_hpages == 11);
+	assert(spool->rsv_hpages == 0);
+
+	/* Invoke Put (Above minimum, so it releases the page to the Global Pool!) */
+	ret = hugepage_subpool_put_pages(spool, 1);
+	assert(ret == 1); /* Dropped to global pool! */
+	assert(spool->used_hpages == 10);
+	assert(spool->rsv_hpages == 0);
+
+	/* Cleanup */
+	hugepage_subpool_put_pages(spool, 10);
+	hugepage_put_subpool(spool);
+	assert_hugetlb_acct_memory_called(&h, -10);
+}
+
+static void test_subpool_get_pages_crossing_min_multi(void)
+{
+	struct hstate h;
+	struct hugepage_subpool *spool;
+	long ret;
+
+	/* Scenario 1: Crossing entirely into surplus territory by a delta > 1 */
+	/* Let's initialize: min_hpages = 10, used_hpages = 8, rsv_hpages = 2 */
+	spool = hugepage_new_subpool(&h, -1, 10);
+	assert_hugetlb_acct_memory_called(&h, 10);
+
+	ret = hugepage_subpool_get_pages(spool, 8);
+	assert(ret == 0);
+	assert(spool->used_hpages == 8);
+	assert(spool->rsv_hpages == 2);
+
+	/* Invoke Get with delta = 5 (Crosses min limit of 10 up to 13) */
+	ret = hugepage_subpool_get_pages(spool, 5);
+	assert(ret == 3); /* (8 + 5) - 10 = 3 global pages required! */
+	assert(spool->used_hpages == 13);
+	assert(spool->rsv_hpages == 0);
+
+	/* Invoke Put with delta = 5 (Drops from 13 down to 8) */
+	ret = hugepage_subpool_put_pages(spool, 5);
+	assert(ret == 3); /* 3 surplus pages released to the global pool! */
+	assert(spool->used_hpages == 8);
+	assert(spool->rsv_hpages == 2); /* 2 subpool reserves perfectly restored! */
+
+	/* Scenario 2: Landing exactly on the min_hpages boundary with delta > 1 */
+	ret = hugepage_subpool_get_pages(spool, 2);
+	assert(ret == 0); /* Perfectly covered by remaining 2 subpool reserves! */
+	assert(spool->used_hpages == 10);
+	assert(spool->rsv_hpages == 0);
+
+	ret = hugepage_subpool_put_pages(spool, 2);
+	assert(ret == 0); /* Swallowed perfectly to replenish the 2 subpool reserves! */
+	assert(spool->used_hpages == 8);
+	assert(spool->rsv_hpages == 2);
+
+	/* Cleanup */
+	hugepage_subpool_put_pages(spool, 8);
+	hugepage_put_subpool(spool);
+	assert_hugetlb_acct_memory_called(&h, -10);
+}
+
+static void test_subpool_get_pages_max_limit(void)
+{
+	struct hstate h;
+	struct hugepage_subpool *spool;
+	long ret;
+
+	spool = hugepage_new_subpool(&h, 5, -1);
+	assert_hugetlb_acct_memory_not_called();
+
+	ret = hugepage_subpool_get_pages(spool, 5);
+	assert(ret == 5);
+	assert(spool->used_hpages == 5);
+	assert(spool->rsv_hpages == -1);
+
+	/* Invoke Get (Should trigger -ENOMEM due to max cap limit exceeded!) */
+	ret = hugepage_subpool_get_pages(spool, 1);
+	assert(ret == -ENOMEM);
+	assert(spool->used_hpages == 5); /* Unchanged */
+
+	/* Cleanup */
+	hugepage_subpool_put_pages(spool, 5);
+	hugepage_put_subpool(spool);
+	assert_hugetlb_acct_memory_not_called();
+}
+
+static void test_subpool_get_pages_no_limits(void)
+{
+	struct hstate h;
+	struct hugepage_subpool *spool;
+	long ret;
+
+	spool = hugepage_new_subpool(&h, -1, -1);
+	assert_hugetlb_acct_memory_not_called();
+
+	hugepage_subpool_get_pages(spool, 5);
+	assert(spool->used_hpages == 5);
+
+	/* Invoke Get (Surplus Global Territory) */
+	ret = hugepage_subpool_get_pages(spool, 2);
+	assert(ret == 2);
+	assert(spool->used_hpages == 7);
+
+	/* Invoke Put */
+	ret = hugepage_subpool_put_pages(spool, 2);
+	assert(ret == 2);
+	assert(spool->used_hpages == 5);
+
+	/* Cleanup */
+	hugepage_subpool_put_pages(spool, 5);
+	hugepage_put_subpool(spool);
+	assert_hugetlb_acct_memory_not_called();
+}
+
+static void test_subpool_free_hpages(void)
+{
+	struct hstate h;
+	struct hugepage_subpool *spool;
+
+	/* Test that free_hpages with NO min_size works perfectly */
+	spool = hugepage_new_subpool(&h, 15, -1);
+	hugepage_subpool_get_pages(spool, 3);
+	assert(hugepage_subpool_free_hpages(spool) == 12);
+	hugepage_subpool_put_pages(spool, 3);
+	hugepage_put_subpool(spool);
+
+	/* Test that free_hpages with a min_size configured is COMPLETELY UNAFFECTED by it */
+	spool = hugepage_new_subpool(&h, 15, 5);
+	assert_hugetlb_acct_memory_called(&h, 5);
+	hugepage_subpool_get_pages(spool, 3);
+	assert(hugepage_subpool_free_hpages(spool) == 12); /* Should still be 15 - 3 = 12! */
+	hugepage_subpool_put_pages(spool, 3);
+	hugepage_put_subpool(spool);
+	assert_hugetlb_acct_memory_called(&h, -5);
+
+	spool = hugepage_new_subpool(&h, -1, -1);
+	hugepage_subpool_get_pages(spool, 3);
+	assert(hugepage_subpool_free_hpages(spool) == -1);
+	hugepage_subpool_put_pages(spool, 3);
+	hugepage_put_subpool(spool);
+
+	/* Test that free_hpages with a min_size configured and NO max size returns -1 */
+	spool = hugepage_new_subpool(&h, -1, 5);
+	assert_hugetlb_acct_memory_called(&h, 5);
+	hugepage_subpool_get_pages(spool, 3);
+	assert(hugepage_subpool_free_hpages(spool) == -1);
+	hugepage_subpool_put_pages(spool, 3);
+	hugepage_put_subpool(spool);
+	assert_hugetlb_acct_memory_called(&h, -5);
+
+	spool = hugepage_new_subpool(&h, 3, -1);
+	hugepage_subpool_get_pages(spool, 3);
+	assert(hugepage_subpool_free_hpages(spool) == 0);
+	hugepage_subpool_put_pages(spool, 3);
+	hugepage_put_subpool(spool);
+}
+
+static void test_subpool_max_hpages(void)
+{
+	struct hstate h;
+	struct hugepage_subpool *spool;
+
+	spool = hugepage_new_subpool(&h, 123, -1);
+	assert(hugepage_subpool_max_hpages(spool) == 123);
+	hugepage_put_subpool(spool);
+
+	/* Test that max_hpages with a min_size configured is COMPLETELY UNAFFECTED by it */
+	spool = hugepage_new_subpool(&h, 123, 5);
+	assert_hugetlb_acct_memory_called(&h, 5);
+	assert(hugepage_subpool_max_hpages(spool) == 123);
+	hugepage_put_subpool(spool);
+	assert_hugetlb_acct_memory_called(&h, -5);
+
+	spool = hugepage_new_subpool(&h, -1, -1);
+	assert(hugepage_subpool_max_hpages(spool) == -1);
+	hugepage_put_subpool(spool);
+
+	spool = hugepage_new_subpool(&h, -1, 5);
+	assert_hugetlb_acct_memory_called(&h, 5);
+	assert(hugepage_subpool_max_hpages(spool) == -1);
+	hugepage_put_subpool(spool);
+	assert_hugetlb_acct_memory_called(&h, -5);
+
+	spool = hugepage_new_subpool(&h, 0, -1);
+	assert(hugepage_subpool_max_hpages(spool) == 0);
+	hugepage_put_subpool(spool);
+}
+
+static void test_subpool_max_size(void)
+{
+	struct hstate h;
+	struct hugepage_subpool *spool;
+
+	spool = hugepage_new_subpool(&h, 10, -1);
+	assert(hugepage_subpool_max_size(spool) == (10ULL << 21));
+	hugepage_put_subpool(spool);
+
+	/* Test that max_size with a min_size configured is COMPLETELY UNAFFECTED by it */
+	spool = hugepage_new_subpool(&h, 10, 5);
+	assert_hugetlb_acct_memory_called(&h, 5);
+	assert(hugepage_subpool_max_size(spool) == (10ULL << 21));
+	hugepage_put_subpool(spool);
+	assert_hugetlb_acct_memory_called(&h, -5);
+
+	spool = hugepage_new_subpool(&h, -1, -1);
+	assert(hugepage_subpool_max_size(spool) == -1ULL);
+	hugepage_put_subpool(spool);
+
+	spool = hugepage_new_subpool(&h, 0, -1);
+	assert(hugepage_subpool_max_size(spool) == 0ULL);
+	hugepage_put_subpool(spool);
+}
+
+static void test_subpool_min_size(void)
+{
+	struct hstate h;
+	struct hugepage_subpool *spool;
+
+	spool = hugepage_new_subpool(&h, -1, 5);
+	assert_hugetlb_acct_memory_called(&h, 5);
+	assert(hugepage_subpool_min_size(spool) == (5ULL << 21));
+	hugepage_put_subpool(spool);
+	assert_hugetlb_acct_memory_called(&h, -5);
+
+	/* Test that min_size with a max_size configured is COMPLETELY UNAFFECTED by it */
+	spool = hugepage_new_subpool(&h, 20, 5);
+	assert_hugetlb_acct_memory_called(&h, 5);
+	assert(hugepage_subpool_min_size(spool) == (5ULL << 21));
+	hugepage_put_subpool(spool);
+	assert_hugetlb_acct_memory_called(&h, -5);
+
+	spool = hugepage_new_subpool(&h, -1, -1);
+	assert(hugepage_subpool_min_size(spool) == -1ULL);
+	hugepage_put_subpool(spool);
+
+	spool = hugepage_new_subpool(&h, -1, 0);
+	assert_hugetlb_acct_memory_called(&h, 0);
+	assert(hugepage_subpool_min_size(spool) == 0ULL);
+	hugepage_put_subpool(spool);
+	assert_hugetlb_acct_memory_called(&h, 0);
+}
+
+int main(void)
+{
+	test_subpool_new_put_no_min_limit();
+	test_subpool_new_put_with_min_limit();
+	test_subpool_get_pages_below_min();
+	test_subpool_get_pages_crossing_min();
+	test_subpool_get_pages_crossing_min_multi();
+	test_subpool_get_pages_max_limit();
+	test_subpool_get_pages_no_limits();
+	test_subpool_free_hpages();
+	test_subpool_max_hpages();
+	test_subpool_max_size();
+	test_subpool_min_size();
+
+	return 0;
+}

-- 
2.55.0.229.g6434b31f56-goog

