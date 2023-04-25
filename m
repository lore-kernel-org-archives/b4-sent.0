From: Yang Xiwen <forbidden405@outlook.com>
Date: Tue, 25 Apr 2023 15:46:39 +0800
Subject: [PATCH v2 1/2] clk: use ULONG_MAX as the initial value for the
 iteration in clk_mux_determine_rate_flags()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230421-clk-v2-1-74c6cc2214d1@outlook.com>
References: <20230421-clk-v2-0-74c6cc2214d1@outlook.com>
In-Reply-To: <20230421-clk-v2-0-74c6cc2214d1@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1682408804; l=1301;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=RtgdZyRNyL73Uk7aVZnLxu+b/Md7l1lfROZ/ueMsp+s=;
 b=awpu1dTnuZNRuDSJV4+H8qKX39whCHYqk53e5OCPtlAUqeIpYXfNYqPv0SypQYFzbZO/jG8bk
 RjNzFGo8ueOCDeKFIkfFr4iaoFitMCcPL38Cd/k5tI6NqhpryiJ3zFY
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, clk_mux_determine_rate_flags() use 0 as the initial value for
selecting the best matching parent. However, this will choose a
non-existant rate(0) if the requested rate is closer to 0 than the
minimum rate the parents have.

Fix that by initializing the initial value to ULONG_MAX and treat it as a
magic number.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/clk.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index ae07685c7588b..ab8a2acfac8f3 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -541,6 +541,9 @@ EXPORT_SYMBOL_GPL(__clk_is_enabled);
 static bool mux_is_better_rate(unsigned long rate, unsigned long now,
 			   unsigned long best, unsigned long flags)
 {
+	if (best == ULONG_MAX)
+		return true;
+
 	if (flags & CLK_MUX_ROUND_CLOSEST)
 		return abs(now - rate) < abs(best - rate);
 
@@ -600,7 +603,7 @@ int clk_mux_determine_rate_flags(struct clk_hw *hw,
 {
 	struct clk_core *core = hw->core, *parent, *best_parent = NULL;
 	int i, num_parents, ret;
-	unsigned long best = 0;
+	unsigned long best = ULONG_MAX;
 
 	/* if NO_REPARENT flag set, pass through to current parent */
 	if (core->flags & CLK_SET_RATE_NO_REPARENT) {

-- 
2.39.2

