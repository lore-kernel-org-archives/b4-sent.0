From: Yang Xiwen <forbidden405@outlook.com>
Date: Tue, 25 Apr 2023 15:46:40 +0800
Subject: [PATCH v2 2/2] clk: tests: Add missing test case for mux
 determine_rate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230421-clk-v2-2-74c6cc2214d1@outlook.com>
References: <20230421-clk-v2-0-74c6cc2214d1@outlook.com>
In-Reply-To: <20230421-clk-v2-0-74c6cc2214d1@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1682408804; l=1148;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=9OLnZFueJynRZ3/SvtdA921aQdEuKJhzY8cmJ1y5r2Y=;
 b=pdXVz8zXO1kXbFfAdJ/F15BBHF/1kAn2fhFbi8+/zSxB0PPgyE7tRm3SSeQEjMvI/zH4HDqAQ
 /LWxPZfpgvADWcbrp4mevnApifX4nH2eR+d3HP1k0vnov5Tg2gcRW9J
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a missing test case for determine_rate implemented by mux. It tests
the behavior of determine_rate when requesting a rate that none of the
parents could give.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/clk_test.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/clk/clk_test.c b/drivers/clk/clk_test.c
index f9a5c2964c65d..9b1c90de90454 100644
--- a/drivers/clk/clk_test.c
+++ b/drivers/clk/clk_test.c
@@ -2215,6 +2215,15 @@ static void clk_leaf_mux_set_rate_parent_determine_rate(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, req.best_parent_rate, DUMMY_CLOCK_RATE_2);
 	KUNIT_EXPECT_PTR_EQ(test, req.best_parent_hw, &ctx->mux_ctx.hw);
 
+	// Test a non-existant rate which none of the parents could give
+	clk_hw_init_rate_request(hw, &req, DUMMY_CLOCK_INIT_RATE);
+
+	ret = __clk_determine_rate(hw, &req);
+	KUNIT_ASSERT_EQ(test, ret, 0);
+
+	KUNIT_EXPECT_EQ(test, req.rate, DUMMY_CLOCK_RATE_1);
+	KUNIT_EXPECT_EQ(test, req.best_parent_rate, DUMMY_CLOCK_RATE_1);
+	KUNIT_EXPECT_PTR_EQ(test, req.best_parent_hw, &ctx->mux_ctx.hw);
 	clk_put(clk);
 }
 

-- 
2.39.2

