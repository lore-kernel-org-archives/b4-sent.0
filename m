From: Yang Xiwen <forbidden405@outlook.com>
Date: Wed, 06 Mar 2024 00:22:23 +0800
Subject: [PATCH v2 1/2] clk: set initial best mux parent to current parent
 when determining rate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240306-mux-v2-1-92a5fa461fd2@outlook.com>
References: <20240306-mux-v2-0-92a5fa461fd2@outlook.com>
In-Reply-To: <20240306-mux-v2-0-92a5fa461fd2@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: Maxime Ripard <mripard@kernel.org>, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709655743; l=1261;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=qRdSqORY6NMYE6mBkGdQAfI34M7sak4eBKjAJcYC8Bc=;
 b=2/KcJ3havJchmRp7Q0ZuGjPGMzYhLc2hdls8eymEBdHAOmEhBuKe1/LHXVOTT93oVuY6vlvlw
 TNsRHeihtsgAYYDoUzNaYnSz04AOlbU4XGb4vCwAGRXc8BH34n21Ihv
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Originally, the initial clock rate is hardcoded to 0, this can lead to
some problem when setting a very small rate with CLK_MUX_ROUND_CLOSEST.

For example, if the lowest possible rate provided by the mux is 1000Hz,
setting a rate below 500Hz will fail, because no clock can provide a
better rate than the non-existant 0Hz. But it should succeed with 1000Hz
being set.

Setting the initial best parent to current parent could solve this bug.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/clk.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index 2253c154a824..5fa92227b355 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -639,9 +639,9 @@ int clk_mux_determine_rate_flags(struct clk_hw *hw,
 				 struct clk_rate_request *req,
 				 unsigned long flags)
 {
-	struct clk_core *core = hw->core, *parent, *best_parent = NULL;
+	struct clk_core *core = hw->core, *parent, *best_parent = core->parent;
 	int i, num_parents, ret;
-	unsigned long best = 0;
+	unsigned long best = clk_core_get_rate_nolock(core);
 
 	/* if NO_REPARENT flag set, pass through to current parent */
 	if (core->flags & CLK_SET_RATE_NO_REPARENT)

-- 
2.43.0

