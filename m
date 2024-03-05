From: Yang Xiwen <forbidden405@outlook.com>
Date: Wed, 06 Mar 2024 00:22:24 +0800
Subject: [PATCH v2 2/2] clk: test: use __clk_mux_determine_rate() and
 remove FIXME
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240306-mux-v2-2-92a5fa461fd2@outlook.com>
References: <20240306-mux-v2-0-92a5fa461fd2@outlook.com>
In-Reply-To: <20240306-mux-v2-0-92a5fa461fd2@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: Maxime Ripard <mripard@kernel.org>, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709655743; l=1658;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=V02NfOQOSUmVUo/qMJu9x6OdiFLOhTtTpAJh6FrUtjc=;
 b=s1EiXjZNeM8uWPA80SvuRGX7cXgQ1n/vcR21IzpPY6kl+V0gmKSPZLw7/+kes24ffoPgL/r/v
 P/w30J9+K12Aa4bh0csQONBp7dNdEOrJzCjmKsCyxwN5t3wa+MEl0kG
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Recent clk core fix resolved the bug in the FIXME comment. Now replace
the .determine_rate field back to __clk_mux_determine_rate() and remove
the FIXME comment.

Fixes: aebddfe2dfaf ("clk: test: Add a determine_rate hook")
Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/clk_test.c | 18 +-----------------
 1 file changed, 1 insertion(+), 17 deletions(-)

diff --git a/drivers/clk/clk_test.c b/drivers/clk/clk_test.c
index 39e2b5ff4f51..0c91dc14d942 100644
--- a/drivers/clk/clk_test.c
+++ b/drivers/clk/clk_test.c
@@ -106,23 +106,7 @@ static const struct clk_ops clk_dummy_minimize_rate_ops = {
 };
 
 static const struct clk_ops clk_dummy_single_parent_ops = {
-	/*
-	 * FIXME: Even though we should probably be able to use
-	 * __clk_mux_determine_rate() here, if we use it and call
-	 * clk_round_rate() or clk_set_rate() with a rate lower than
-	 * what all the parents can provide, it will return -EINVAL.
-	 *
-	 * This is due to the fact that it has the undocumented
-	 * behaviour to always pick up the closest rate higher than the
-	 * requested rate. If we get something lower, it thus considers
-	 * that it's not acceptable and will return an error.
-	 *
-	 * It's somewhat inconsistent and creates a weird threshold
-	 * between rates above the parent rate which would be rounded to
-	 * what the parent can provide, but rates below will simply
-	 * return an error.
-	 */
-	.determine_rate = __clk_mux_determine_rate_closest,
+	.determine_rate = __clk_mux_determine_rate,
 	.set_parent = clk_dummy_single_set_parent,
 	.get_parent = clk_dummy_single_get_parent,
 };

-- 
2.43.0

