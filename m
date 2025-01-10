From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 10 Jan 2025 19:47:10 +0800
Subject: [PATCH 1/2] clk: Add initialize the rate boundaries of the clk
 provider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250110-limit-rate-range-of-clk-v1-1-dd618adc4aa8@amlogic.com>
References: <20250110-limit-rate-range-of-clk-v1-0-dd618adc4aa8@amlogic.com>
In-Reply-To: <20250110-limit-rate-range-of-clk-v1-0-dd618adc4aa8@amlogic.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-amlogic@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736509666; l=1896;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=NLbcI+Nns/2o6n4G9nqU4NOW+TQbJwF6LoFvcGM+2I4=;
 b=/HIhXIBeMDoFfKkG+m2ONfOOFLZiafM1eyQll49aSyxL2rXP4aEC5eWqUqKBgLD+IC9SM+MwL
 MB/kqgbTb4DCcVAFh9ZPihXtnYXLBLiD4tVb9iZtoh0zjY6mcTxVxc9
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The rate boundaries output by different clk providers vary due to
hardware limitations.

When registering the clk, limit the rate boundaries of the clk provider
to prevent setting the rate of the clk provider beyond the design
specifications and causing abnormal conditions.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/clk.c            | 4 ++--
 include/linux/clk-provider.h | 4 ++++
 2 files changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index 9b45fa005030..36e4b4f16f1d 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -4359,8 +4359,8 @@ __clk_register(struct device *dev, struct device_node *np, struct clk_hw *hw)
 	core->hw = hw;
 	core->flags = init->flags;
 	core->num_parents = init->num_parents;
-	core->min_rate = 0;
-	core->max_rate = ULONG_MAX;
+	core->min_rate = init->min_rate ? init->min_rate : 0;
+	core->max_rate = init->max_rate ? init->max_rate : ULONG_MAX;
 
 	ret = clk_core_populate_parent_map(core, init);
 	if (ret)
diff --git a/include/linux/clk-provider.h b/include/linux/clk-provider.h
index 2e6e603b7493..46cfc342819e 100644
--- a/include/linux/clk-provider.h
+++ b/include/linux/clk-provider.h
@@ -294,6 +294,8 @@ struct clk_parent_data {
  * @parent_hws: array of pointers to all possible parents (when all parents
  *              are internal to the clk controller)
  * @num_parents: number of possible parents
+ * @min_rate: min rate provided by the clk provider
+ * @max_rate: max rate provided by the clk provider
  * @flags: framework-level hints and quirks
  */
 struct clk_init_data {
@@ -304,6 +306,8 @@ struct clk_init_data {
 	const struct clk_parent_data	*parent_data;
 	const struct clk_hw		**parent_hws;
 	u8			num_parents;
+	unsigned long		min_rate;
+	unsigned long		max_rate;
 	unsigned long		flags;
 };
 

-- 
2.42.0

