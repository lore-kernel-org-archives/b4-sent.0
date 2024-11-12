From: Chuan Liu <chuan.liu@amlogic.com>
Date: Tue, 12 Nov 2024 20:57:13 +0800
Subject: [PATCH v2] clk: meson: Fix the determine rate error in
 clk_regmap_divider_ro_ops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241112-fix_childclk_of_roclk_has_been_tampered_with-v2-1-64f8009cdf2a@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAKhQM2cC/52NQQ6DIBBFr2JYl0aooU1XvUdjCAyDTKpiwNg2x
 rsXPUL/at4k/7+VZUyEmd2rlSVcKFMcC8hTxSCYsUNOrjCTtWxECff00RCod9C/dPQ6xf0IJmu
 LOOrZDBMmdPpNc+BKOAug5OXaKFYmp4Slf+iebeFAeY7pe9gXsX//FC2Cl8YNhFXeO7D1wwx97
 AjOEAfWbtv2A6RiwUTqAAAA
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jian Hu <jian.hu@amlogic.com>, Dmitry Rokosov <ddrokosov@sberdevices.ru>, 
 Yu Tu <yu.tu@amlogic.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731416235; l=3076;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=8AI+tmYmNulgS0Oos4nPr/9f/YnCkFdoNAlNOvZiX+k=;
 b=WNYt8589v61xwco+HqIDwnC1iODrOIA0rq+V7GBT46G5LTeEwTBownMkgl0abQ1O51r4LdNy9
 gE/wSujgJ5GCiKjMCC4QQU+iisFAWMUD223v2rIPbgsygenS6PSUYTV
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The rate determined by calling clk_regmap_divider_ro_ops with
clk_regmap_div_determine_rate is not RO, which will result in the
unexpected modification of the frequency of its children when setting
the rate of a clock that references clk_regmap_divider_ro_ops.

Fiexs: ea11dda9e091 ("clk: meson: add regmap clocks")
Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Background: During the execution of clk_set_rate(), the function 
clk_core_round_rate_nolock() is called to calculate the matching rate
and save it to 'core->new_rate'. At the same time, it recalculates and
updates its 'child->newrate'. Finally, clk_change_rate() is called to
set all 'new_rates'.
---
Changes in v2:
- Remove the CLK_DIVIDER_READ_ONLY judgment logic in
clk_regmap_div_determine_rate().
- Add clk_regmap_div_ro_determine_rate().
- Link to v1: https://lore.kernel.org/r/20241111-fix_childclk_of_roclk_has_been_tampered_with-v1-1-f8c1b6ffdcb0@amlogic.com
---
 drivers/clk/meson/clk-regmap.c | 36 ++++++++++++++++++++----------------
 1 file changed, 20 insertions(+), 16 deletions(-)

diff --git a/drivers/clk/meson/clk-regmap.c b/drivers/clk/meson/clk-regmap.c
index 07f7e441b916..edf65ca92c7a 100644
--- a/drivers/clk/meson/clk-regmap.c
+++ b/drivers/clk/meson/clk-regmap.c
@@ -80,21 +80,6 @@ static int clk_regmap_div_determine_rate(struct clk_hw *hw,
 {
 	struct clk_regmap *clk = to_clk_regmap(hw);
 	struct clk_regmap_div_data *div = clk_get_regmap_div_data(clk);
-	unsigned int val;
-	int ret;
-
-	/* if read only, just return current value */
-	if (div->flags & CLK_DIVIDER_READ_ONLY) {
-		ret = regmap_read(clk->map, div->offset, &val);
-		if (ret)
-			return ret;
-
-		val >>= div->shift;
-		val &= clk_div_mask(div->width);
-
-		return divider_ro_determine_rate(hw, req, div->table,
-						 div->width, div->flags, val);
-	}
 
 	return divider_determine_rate(hw, req, div->table, div->width,
 				      div->flags);
@@ -127,9 +112,28 @@ const struct clk_ops clk_regmap_divider_ops = {
 };
 EXPORT_SYMBOL_NS_GPL(clk_regmap_divider_ops, CLK_MESON);
 
+static int clk_regmap_div_ro_determine_rate(struct clk_hw *hw,
+					    struct clk_rate_request *req)
+{
+	struct clk_regmap *clk = to_clk_regmap(hw);
+	struct clk_regmap_div_data *div = clk_get_regmap_div_data(clk);
+	unsigned int val;
+	int ret;
+
+	ret = regmap_read(clk->map, div->offset, &val);
+	if (ret)
+		return ret;
+
+	val >>= div->shift;
+	val &= clk_div_mask(div->width);
+
+	return divider_ro_determine_rate(hw, req, div->table, div->width,
+					 div->flags, val);
+}
+
 const struct clk_ops clk_regmap_divider_ro_ops = {
 	.recalc_rate = clk_regmap_div_recalc_rate,
-	.determine_rate = clk_regmap_div_determine_rate,
+	.determine_rate = clk_regmap_div_ro_determine_rate,
 };
 EXPORT_SYMBOL_NS_GPL(clk_regmap_divider_ro_ops, CLK_MESON);
 

---
base-commit: 664988eb47dd2d6ae1d9e4188ec91832562f8f26
change-id: 20241111-fix_childclk_of_roclk_has_been_tampered_with-61dbcc623746

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

