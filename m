From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 27 Apr 2023 03:34:17 +0800
Subject: [PATCH v3 2/2] clk: tests: Add missing test cases for mux
 determine_rate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230421-clk-v3-2-9ff79e7e7fed@outlook.com>
References: <20230421-clk-v3-0-9ff79e7e7fed@outlook.com>
In-Reply-To: <20230421-clk-v3-0-9ff79e7e7fed@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1682537658; l=5403;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=ukorzXXoz+p+cK/h39SCI45QuctGTK8HaAHvB2BLCPA=;
 b=6p+VF7zVTR+fhfTHdnuIoe2hf+VoUFHmMHisF+4IK1eRKaodzSANNDsUSQY+kTsu9fyva1loQ
 OtvgowCOTkdBy3JMtQTG3eA1Xl6373lZVPcdn/NHyKh/1DsvQo8Ra4g
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add lots of test cases for mux determine_rate to cover more possible
cases, the original test case is renamed for the change.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/clk_test.c | 131 ++++++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 129 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/clk_test.c b/drivers/clk/clk_test.c
index f9a5c2964c65d..4f7f9a964637a 100644
--- a/drivers/clk/clk_test.c
+++ b/drivers/clk/clk_test.c
@@ -2194,7 +2194,47 @@ static void clk_leaf_mux_set_rate_parent_test_exit(struct kunit *test)
  * parent, the rate request structure returned by __clk_determine_rate
  * is sane and will be what we expect.
  */
-static void clk_leaf_mux_set_rate_parent_determine_rate(struct kunit *test)
+static void clk_leaf_mux_set_rate_parent_determine_rate_case1(struct kunit *test)
+{
+	struct clk_leaf_mux_ctx *ctx = test->priv;
+	struct clk_hw *hw = &ctx->hw;
+	struct clk *clk = clk_hw_get_clk(hw, NULL);
+	struct clk_rate_request req;
+	unsigned long rate;
+	int ret;
+
+	rate = clk_get_rate(clk);
+	KUNIT_ASSERT_EQ(test, rate, DUMMY_CLOCK_RATE_1);
+
+	clk_hw_init_rate_request(hw, &req, 0);
+
+	ret = __clk_determine_rate(hw, &req);
+	KUNIT_ASSERT_EQ(test, ret, -EINVAL);
+
+	clk_put(clk);
+}
+
+static void clk_leaf_mux_set_rate_parent_determine_rate_case2(struct kunit *test)
+{
+	struct clk_leaf_mux_ctx *ctx = test->priv;
+	struct clk_hw *hw = &ctx->hw;
+	struct clk *clk = clk_hw_get_clk(hw, NULL);
+	struct clk_rate_request req;
+	unsigned long rate;
+	int ret;
+
+	rate = clk_get_rate(clk);
+	KUNIT_ASSERT_EQ(test, rate, DUMMY_CLOCK_RATE_1);
+
+	clk_hw_init_rate_request(hw, &req, DUMMY_CLOCK_INIT_RATE);
+
+	ret = __clk_determine_rate(hw, &req);
+	KUNIT_ASSERT_EQ(test, ret, -EINVAL);
+
+	clk_put(clk);
+}
+
+static void clk_leaf_mux_set_rate_parent_determine_rate_case3(struct kunit *test)
 {
 	struct clk_leaf_mux_ctx *ctx = test->priv;
 	struct clk_hw *hw = &ctx->hw;
@@ -2218,8 +2258,95 @@ static void clk_leaf_mux_set_rate_parent_determine_rate(struct kunit *test)
 	clk_put(clk);
 }
 
+static void clk_leaf_mux_set_rate_parent_determine_rate_case4(struct kunit *test)
+{
+	struct clk_leaf_mux_ctx *ctx = test->priv;
+	struct clk_hw *hw = &ctx->hw;
+	struct clk *clk = clk_hw_get_clk(hw, NULL);
+	struct clk_rate_request req;
+	unsigned long rate;
+	int ret;
+
+	rate = clk_get_rate(clk);
+	KUNIT_ASSERT_EQ(test, rate, DUMMY_CLOCK_RATE_1);
+
+	clk_hw_init_rate_request(hw, &req, (DUMMY_CLOCK_RATE_1 + DUMMY_CLOCK_RATE_2) / 2);
+
+	ret = __clk_determine_rate(hw, &req);
+	KUNIT_ASSERT_EQ(test, ret, 0);
+
+	KUNIT_EXPECT_EQ(test, req.rate, DUMMY_CLOCK_RATE_1);
+	KUNIT_EXPECT_EQ(test, req.best_parent_rate, DUMMY_CLOCK_RATE_1);
+	KUNIT_EXPECT_PTR_EQ(test, req.best_parent_hw, &ctx->mux_ctx.hw);
+
+	clk_put(clk);
+}
+
+static void clk_leaf_mux_set_rate_parent_determine_rate_case5(struct kunit *test)
+{
+	struct clk_leaf_mux_ctx *ctx = test->priv;
+	struct clk_hw *hw = &ctx->hw;
+	struct clk *clk = clk_hw_get_clk(hw, NULL);
+	struct clk_rate_request req;
+	unsigned long rate;
+	int ret;
+
+	rate = clk_get_rate(clk);
+	KUNIT_ASSERT_EQ(test, rate, DUMMY_CLOCK_RATE_1);
+
+	clk_hw_init_rate_request(hw, &req, DUMMY_CLOCK_RATE_2 + 100000);
+
+	ret = __clk_determine_rate(hw, &req);
+	KUNIT_ASSERT_EQ(test, ret, 0);
+
+	KUNIT_EXPECT_EQ(test, req.rate, DUMMY_CLOCK_RATE_2);
+	KUNIT_EXPECT_EQ(test, req.best_parent_rate, DUMMY_CLOCK_RATE_2);
+	KUNIT_EXPECT_PTR_EQ(test, req.best_parent_hw, &ctx->mux_ctx.hw);
+
+	clk_put(clk);
+}
+
+static void clk_leaf_mux_set_rate_parent_determine_rate_case6(struct kunit *test)
+{
+	struct clk_leaf_mux_ctx *ctx = test->priv;
+	struct clk_hw *hw = &ctx->hw;
+	struct clk *clk = clk_hw_get_clk(hw, NULL);
+	struct clk_rate_request req;
+	unsigned long rate;
+	int ret;
+
+	rate = clk_get_rate(clk);
+	KUNIT_ASSERT_EQ(test, rate, DUMMY_CLOCK_RATE_1);
+
+	clk_hw_init_rate_request(hw, &req, ULONG_MAX);
+
+	ret = __clk_determine_rate(hw, &req);
+	KUNIT_ASSERT_EQ(test, ret, 0);
+
+	KUNIT_EXPECT_EQ(test, req.rate, DUMMY_CLOCK_RATE_2);
+	KUNIT_EXPECT_EQ(test, req.best_parent_rate, DUMMY_CLOCK_RATE_2);
+	KUNIT_EXPECT_PTR_EQ(test, req.best_parent_hw, &ctx->mux_ctx.hw);
+
+	clk_put(clk);
+}
+
+/* We test 6 cases here:
+ * 1. The requested rate is 0;
+ * 2. The requested rate is not 0 but lower than any rate that parents could offer;
+ * 3. The requested rate is exactly one of the parents' clock rate;
+ * 4. The requested rate is between the lowest clock rate and the highest clock rate that the parents could offer;
+ * 5. The requested rate is larger than all rates that parents could offer;
+ * 6. The requested rate is ULONG_MAX.
+ *
+ * Hopefully they covered all cases.
+ */
 static struct kunit_case clk_leaf_mux_set_rate_parent_test_cases[] = {
-	KUNIT_CASE(clk_leaf_mux_set_rate_parent_determine_rate),
+	KUNIT_CASE(clk_leaf_mux_set_rate_parent_determine_rate_case1),
+	KUNIT_CASE(clk_leaf_mux_set_rate_parent_determine_rate_case2),
+	KUNIT_CASE(clk_leaf_mux_set_rate_parent_determine_rate_case3),
+	KUNIT_CASE(clk_leaf_mux_set_rate_parent_determine_rate_case4),
+	KUNIT_CASE(clk_leaf_mux_set_rate_parent_determine_rate_case5),
+	KUNIT_CASE(clk_leaf_mux_set_rate_parent_determine_rate_case6),
 	{}
 };
 

-- 
2.39.2

