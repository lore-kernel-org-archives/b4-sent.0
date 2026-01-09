From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 09 Jan 2026 11:24:22 +0800
Subject: [PATCH] clk: Ensure correct consumer's rate boundaries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260109-fix_error_setting_clk_rate_range-v1-1-bae0b40e870f@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAOV0YGkC/x2NSwqAMAxEryJZK9Qu/F1FpBSbalCqpEUE6d2Nb
 gYezJt5ICITRhiKBxgvinQEgbosYF5tWLAiJwxa6UbVqq083QaZDzYRU6KwmHnfDNuEEl/f9bp
 ztmmt7xXIzMkozn8xTjm/P+F7THIAAAA=
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767929092; l=1489;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=iAO6kZohGujkhzhp+PGjVKzMDmm3KwoHd3yOlenUwTg=;
 b=dklgwC075h3YRM54I0zr7DtZkIYv/Y+AVjOdXmt8hcpOeuKhFpjJQhRjBkBonddOkbY+MvAUQ
 lPhkBifsCffA4npjw9eyRfrtfzMFRjZzkyO92BFAvLM9bUg37MjVLPD
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If we were to have two users of the same clock, doing something like:

clk_set_rate_range(user1, 1000, 2000);
clk_set_rate_range(user2, 3000, 4000);

Even when user2's call returns -EINVAL, the min_rate and max_rate of
user2 are still incorrectly updated. This causes subsequent calls by
user1 to fail when setting the clock rate, as clk_core_get_boundaries()
returns corrupted boundaries (min_rate = 3000, max_rate = 2000).

To prevent this, clk_core_check_boundaries() now rollback to the old
boundaries when the check fails.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/clk.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index 85d2f2481acf..0dfb16bf3f31 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -2710,13 +2710,17 @@ static int clk_set_rate_range_nolock(struct clk *clk,
 	 */
 	rate = clamp(rate, min, max);
 	ret = clk_core_set_rate_nolock(clk->core, rate);
+
+out:
 	if (ret) {
-		/* rollback the changes */
+		/*
+		 * Rollback the consumer’s old boundaries if check_boundaries or
+		 * set_rate fails.
+		 */
 		clk->min_rate = old_min;
 		clk->max_rate = old_max;
 	}
 
-out:
 	if (clk->exclusive_count)
 		clk_core_rate_protect(clk->core);
 

---
base-commit: 7f98ab9da046865d57c102fd3ca9669a29845f67
change-id: 20260107-fix_error_setting_clk_rate_range-d928da67af90

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

