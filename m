From: Yang Xiwen <forbidden405@outlook.com>
Date: Tue, 20 Feb 2024 03:59:51 +0800
Subject: [PATCH RESEND] clk: set initial best mux parent to current parent
 when determining rate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240220-mux-v1-1-3ee0807ec219@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708372793; l=1451;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=fggch9mxMQ8SzPlFXnQcVvzDJCD3ro+vLZXoDYu1RGE=;
 b=K0K7C5//41mDeCsJpdfDjHd3GisENzOiqi+JFzD56RKu1hD13WdtTBCyC9JVc/ZoWoU2bXhfi
 hvk+d/xORxzDWdGIgmJtDjbupDM9vfr5aPKfaG5zFF1x6olZjKdqkcI
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Originally, the initial clock rate is hardcoded to 0, this can lead to
some problem when setting a very small rate with CLK_MUX_ROUND_NEAREST.

For example, if the lowest possible rate privided by the mux is 1000Hz,
setting a rate below 500Hz will fail, because no clock can provide a
better rate than the non-existant 0. But it should succeed with 1000Hz
being set.

Setting the initial best parent to current parent could solve this bug
very well.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
This is actually a v2 of [1], but seems too simple to have a unittest.
It's tested in a mmc host driver.

[1]: https://lore.kernel.org/linux-clk/20230421-clk-v3-1-9ff79e7e7fed@outlook.com/
---
 drivers/clk/clk.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index 2253c154a824..d98cebd7ff03 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -649,6 +649,10 @@ int clk_mux_determine_rate_flags(struct clk_hw *hw,
 
 	/* find the parent that can provide the fastest rate <= rate */
 	num_parents = core->num_parents;
+	if (core->parent) {
+		best_parent = core->parent;
+		best = clk_core_get_rate_nolock(best_parent);
+	}
 	for (i = 0; i < num_parents; i++) {
 		unsigned long parent_rate;
 

---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240215-mux-6db8b3714590

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

