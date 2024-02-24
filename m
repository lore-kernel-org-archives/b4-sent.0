From: Yang Xiwen <forbidden405@outlook.com>
Date: Sun, 25 Feb 2024 00:56:09 +0800
Subject: [PATCH RFC 1/2] clk: hisilicon: rename hi3519 PLL registration
 function
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240225-pll-v1-1-fad6511479c6@outlook.com>
References: <20240225-pll-v1-0-fad6511479c6@outlook.com>
In-Reply-To: <20240225-pll-v1-0-fad6511479c6@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: David Yang <mmyangfl@gmail.com>, 
 Igor Opaniuk <igor.opaniuk@foundries.io>, 
 Jorge Ramirez-Ortiz Gmail <jorge.ramirez.ortiz@gmail.com>, 
 linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708793775; l=1253;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=RjDdWKwpGyzyVB1dZKcx8ShQs0qG7CAnl7kkoTOnoFc=;
 b=QlwkUL5n+D2xcLQWoH0d8vCOTVanik7rxPAd2tCP7zr67tXHaUwqziZ5IYv4k0T+7Ac0VN/OM
 +Ga6WfGfqWmAaZQ6NxFn6zHRMCAR1RHP2JR+SidKbtQ2MGxW+gmZqd1
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi3559 clock drivers implemented their own PLL driver. Unfortunately
our generic PLL driver will use a same name. So add a prefix "_" to
avoid that.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/hisilicon/clk-hi3559a.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/hisilicon/clk-hi3559a.c b/drivers/clk/hisilicon/clk-hi3559a.c
index ff4ca0edce06..77fa4203a428 100644
--- a/drivers/clk/hisilicon/clk-hi3559a.c
+++ b/drivers/clk/hisilicon/clk-hi3559a.c
@@ -452,7 +452,7 @@ static const struct clk_ops hisi_clk_pll_ops = {
 	.recalc_rate = clk_pll_recalc_rate,
 };
 
-static void hisi_clk_register_pll(struct hi3559av100_pll_clock *clks,
+static void _hisi_clk_register_pll(struct hi3559av100_pll_clock *clks,
 			   int nums, struct hisi_clock_data *data, struct device *dev)
 {
 	void __iomem *base = data->base;
@@ -517,7 +517,7 @@ static struct hisi_clock_data *hi3559av100_clk_register(
 	if (ret)
 		return ERR_PTR(ret);
 
-	hisi_clk_register_pll(hi3559av100_pll_clks,
+	_hisi_clk_register_pll(hi3559av100_pll_clks,
 			      ARRAY_SIZE(hi3559av100_pll_clks), clk_data, &pdev->dev);
 
 	ret = hisi_clk_register_mux(hi3559av100_mux_clks_crg,

-- 
2.43.0

