From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 27 Apr 2023 03:34:16 +0800
Subject: [PATCH v3 1/2] clk: use ULONG_MAX as the initial value for the
 iteration in clk_mux_determine_rate_flags()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230421-clk-v3-1-9ff79e7e7fed@outlook.com>
References: <20230421-clk-v3-0-9ff79e7e7fed@outlook.com>
In-Reply-To: <20230421-clk-v3-0-9ff79e7e7fed@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1682537658; l=1478;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=Iu0E0q+m/ABmoRJdE8XwPzuxx9jb5jEc73TdhQk/cwU=;
 b=lp6Wlz34BkiBEGirNzXxZ4uIqmEe8WkQ7rtxd06Gw/mE8ROkS5KmsbZezY6429bqJEzGkcBS3
 0v4ZInnmIhqDGo+5HmSxUMr3njgcI+rASch/8W1a6GgkcCvu7XT62Qh
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
 drivers/clk/clk.c | 13 ++++++++++++-
 1 file changed, 12 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index ae07685c7588b..6184d4aa88193 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -541,6 +541,17 @@ EXPORT_SYMBOL_GPL(__clk_is_enabled);
 static bool mux_is_better_rate(unsigned long rate, unsigned long now,
 			   unsigned long best, unsigned long flags)
 {
+	if (rate == ULONG_MAX) {
+		// select the highest clock rate
+		if (best == ULONG_MAX)
+			return true;
+		else
+			return now > best;
+	}
+
+	if (best == ULONG_MAX && now <= rate)
+		return true;
+
 	if (flags & CLK_MUX_ROUND_CLOSEST)
 		return abs(now - rate) < abs(best - rate);
 
@@ -600,7 +611,7 @@ int clk_mux_determine_rate_flags(struct clk_hw *hw,
 {
 	struct clk_core *core = hw->core, *parent, *best_parent = NULL;
 	int i, num_parents, ret;
-	unsigned long best = 0;
+	unsigned long best = ULONG_MAX;
 
 	/* if NO_REPARENT flag set, pass through to current parent */
 	if (core->flags & CLK_SET_RATE_NO_REPARENT) {

-- 
2.39.2

