From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 07 Mar 2024 10:03:50 +0800
Subject: [PATCH v3] clk: set initial best mux parent to current parent with
 CLK_MUX_ROUND_CLOSEST
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240307-mux-v3-1-0885fc1ab2c9@outlook.com>
X-B4-Tracking: v=1; b=H4sIAIUg6WUC/1WM0Q6CIBhGX8Vx3d/gBy276j1aFyCQrJQGymzOd
 w/tonl5vn3nzCSa4Ewkl2ImwSQXne8z8ENBmlb2DwNOZyZIUVBkJXTjBJVWZ8VPTJQ1Jfn5Dsa
 6aavc7plbFwcfPls0sXXd+4kBA6MUWiU506K++nF4ef88Nr4jayHh3+K0+lkIFGqUpZWiYlbj3
 lqW5QsHS1sRzgAAAA==
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: Maxime Ripard <mripard@kernel.org>, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709777030; l=1992;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=+mzOqRRpetTLywKtq+naXweDz2ih9wEm/mCbtZc7rOw=;
 b=q+iZF6EtDER3d5gAVZq04xD7GVCQQOVDTZPRm4F+aCBXhuLGOt+Y78TQ2fuynzckogHnLL6vD
 XzZ5kgSoK0xCpTlzgt55ANodTR7HaH4eNJg3XL7hLANVkNYw5P2M0Cp
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
This is actually a v2 of [1]. It's tested in a mmc host driver.

[1]: https://lore.kernel.org/linux-clk/20230421-clk-v3-1-9ff79e7e7fed@outlook.com/
---
Changes in v3:
- remove the fix for clk_test.c
- limit the fix to CLK_MUX_ROUND_CLOSEST
- Link to v2: https://lore.kernel.org/r/20240306-mux-v2-0-92a5fa461fd2@outlook.com

Changes in v2:
- cover letter: remove statements about unittest
- add fix for clk_test.c
- s/privide/provide
- Cc Maxime
All suggested by Stephan Boyd
- Link to v1: https://lore.kernel.org/r/20240215-mux-v1-1-ebb2fba31d49@outlook.com
---
 drivers/clk/clk.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index 2253c154a824..74dd61f7269f 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -647,6 +647,12 @@ int clk_mux_determine_rate_flags(struct clk_hw *hw,
 	if (core->flags & CLK_SET_RATE_NO_REPARENT)
 		return clk_core_determine_rate_no_reparent(hw, req);
 
+	/* if MUX_ROUND_CLOSEST is set, set the initial best parent to current parent */
+	if (flags & CLK_MUX_ROUND_CLOSEST) {
+		best_parent = core->parent;
+		best = clk_core_get_rate_nolock(core);
+	}
+
 	/* find the parent that can provide the fastest rate <= rate */
 	num_parents = core->num_parents;
 	for (i = 0; i < num_parents; i++) {

---
base-commit: 90d35da658da8cff0d4ecbb5113f5fac9d00eb72
change-id: 20240215-mux-6db8b3714590

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

