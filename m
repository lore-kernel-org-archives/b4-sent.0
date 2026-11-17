From: Mattathias Pinchover <mattathias.pinchover@uber.com>
Date: Tue, 17 Nov 2026 23:22:17 +0000
Subject: [PATCH v2 3/6] mm/damon/tests/core-kunit: test
 sz_ops_filter_passed_last
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-damon-sz-ops-b4-v2-3-439888fa04ac@uber.com>
References: <20261117-damon-sz-ops-b4-v2-0-439888fa04ac@uber.com>
In-Reply-To: <20261117-damon-sz-ops-b4-v2-0-439888fa04ac@uber.com>
To: SJ Park <sj@kernel.org>, Andrew Morton <akpm@linux-foundation.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: damon@lists.linux.dev, linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, 
 Mattathias Pinchover <mattathias.pinchover@uber.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794957787; l=4205;
 i=mattathias.pinchover@uber.com; s=20261113; h=from:subject:message-id;
 bh=h2bZi8GyX472sluoP+mJ0igMgXjinQcbkxTFNqsCnXE=;
 b=ZS34BMhhNNrcONv8s6qnYwqh4wj0bpUA4Em2mETWCFRNJ9ey1QcEsZRaNUI6Xf1MD07QoprXJ
 hdZUjXRi/lUDfzAinICPHfg3X+BebVvswtcnycZHNUYnIZwF37EYvLh
X-Developer-Key: i=mattathias.pinchover@uber.com; a=ed25519;
 pk=6Bh6OEwWiU6dpON0CVcoipq8fXtEgvhsM1Tmm9CTmtY=
X-Endpoint-Received: by B4 Relay for mattathias.pinchover@uber.com/20261113 with auth_id=1515
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a kunit test for the sz_ops_filter_passed_last DAMOS
stat.  The test runs kdamond_apply_schemes() for multiple apply intervals
with a stub apply_scheme() operation that reports a given ops
filter-passed size, and checks that the stat is set to the value of the
last apply interval rather than the accumulated value, and that it is
kept unchanged until the next apply interval is completed.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Mattathias Pinchover <mattathias.pinchover@uber.com>
---
 mm/damon/tests/core-kunit.h | 93 +++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 93 insertions(+)

diff --git a/mm/damon/tests/core-kunit.h b/mm/damon/tests/core-kunit.h
index a5ca4bfe2f0d..d256e6b7de73 100644
--- a/mm/damon/tests/core-kunit.h
+++ b/mm/damon/tests/core-kunit.h
@@ -2541,6 +2541,98 @@ static void damon_test_last_region_quota_reset(struct kunit *test)
 	damon_destroy_ctx(ctx);
 }
 
+/* bytes that damos_test_apply_scheme_passed_stub() reports per region */
+static unsigned long damos_test_sz_passed;
+
+static unsigned long damos_test_apply_scheme_passed_stub(struct damon_ctx *c,
+		struct damon_target *t, struct damon_region *r,
+		struct damos *s, unsigned long *sz_filter_passed)
+{
+	*sz_filter_passed = damos_test_sz_passed;
+	return 0;
+}
+
+/* run one apply interval and return the last apply interval's passed bytes */
+static unsigned long damos_test_apply_interval(struct damon_ctx *c,
+		struct damos *s)
+{
+	c->passed_sample_intervals = s->next_apply_sis;
+	kdamond_apply_schemes(c);
+	return s->stat.sz_ops_filter_passed_last;
+}
+
+static void damos_test_sz_ops_filter_passed_last(struct kunit *test)
+{
+	struct damos_access_pattern pattern = {
+		.min_sz_region = 0,
+		.max_sz_region = ULONG_MAX,
+		.min_nr_accesses = 0,
+		.max_nr_accesses = UINT_MAX,
+		.min_age_region = 0,
+		.max_age_region = UINT_MAX,
+	};
+	struct damos_watermarks wmarks = {};
+	struct damos_quota quota = {};
+	struct damon_ctx *c;
+	struct damon_target *t;
+	struct damon_region *r;
+	struct damos *s;
+
+	c = damon_new_ctx();
+	if (!c)
+		kunit_skip(test, "ctx alloc fail");
+	c->ops.apply_scheme = damos_test_apply_scheme_passed_stub;
+
+	s = damon_new_scheme(&pattern, DAMOS_STAT, 0, &quota, &wmarks,
+			NUMA_NO_NODE);
+	if (!s) {
+		damon_destroy_ctx(c);
+		kunit_skip(test, "scheme alloc fail");
+	}
+	damos_set_filters_default_reject(s);
+	damon_add_scheme(c, s);
+
+	t = damon_new_target();
+	if (!t) {
+		damon_destroy_ctx(c);
+		kunit_skip(test, "target alloc fail");
+	}
+	damon_add_target(c, t);
+
+	r = damon_new_region(0, DAMON_MIN_REGION_SZ);
+	if (!r) {
+		damon_destroy_ctx(c);
+		kunit_skip(test, "region alloc fail");
+	}
+	damon_add_region(r, t);
+
+	KUNIT_EXPECT_EQ(test, s->stat.sz_ops_filter_passed_last, 0);
+
+	/* each value is for the last apply interval only, not cumulative */
+	damos_test_sz_passed = 1000;
+	KUNIT_EXPECT_EQ(test, damos_test_apply_interval(c, s), 1000);
+	KUNIT_EXPECT_EQ(test, damos_test_apply_interval(c, s), 1000);
+	KUNIT_EXPECT_EQ(test, s->stat.sz_ops_filter_passed, 2000);
+
+	damos_test_sz_passed = 300;
+	KUNIT_EXPECT_EQ(test, damos_test_apply_interval(c, s), 300);
+	KUNIT_EXPECT_EQ(test, s->stat.sz_ops_filter_passed, 2300);
+
+	damos_test_sz_passed = 0;
+	KUNIT_EXPECT_EQ(test, damos_test_apply_interval(c, s), 0);
+	KUNIT_EXPECT_EQ(test, s->stat.sz_ops_filter_passed, 2300);
+
+	/* not yet the time to apply, so the last value should be kept */
+	damos_test_sz_passed = 500;
+	damos_test_apply_interval(c, s);
+	c->passed_sample_intervals = s->next_apply_sis - 1;
+	kdamond_apply_schemes(c);
+	KUNIT_EXPECT_EQ(test, s->stat.sz_ops_filter_passed_last,
+			500);
+
+	damon_destroy_ctx(c);
+}
+
 static struct kunit_case damon_test_cases[] = {
 	KUNIT_CASE(damon_test_target),
 	KUNIT_CASE(damon_test_regions),
@@ -2585,6 +2677,7 @@ static struct kunit_case damon_test_cases[] = {
 	KUNIT_CASE(damon_test_rand),
 	KUNIT_CASE(damos_test_esz_goal_temporal),
 	KUNIT_CASE(damon_test_last_region_quota_reset),
+	KUNIT_CASE(damos_test_sz_ops_filter_passed_last),
 	{},
 };
 

-- 
2.54.0-uber3

