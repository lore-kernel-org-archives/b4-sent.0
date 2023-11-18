From: Yang Xiwen <forbidden405@outlook.com>
Date: Sun, 19 Nov 2023 06:10:06 +0800
Subject: [PATCH v2 2/4] clk: get correct ops for clk_enable() and
 clk_disable()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231111-enable_count-v2-2-20e3728600b5@outlook.com>
References: <20231111-enable_count-v2-0-20e3728600b5@outlook.com>
In-Reply-To: <20231111-enable_count-v2-0-20e3728600b5@outlook.com>
To: Simon Glass <sjg@chromium.org>, Lukasz Majewski <lukma@denx.de>, 
 Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700345405; l=1139;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=AnAh3PLkdIwcY96zMqQqGxKzLY2UH8ifWEJiVBEhqyc=;
 b=ztblI32rvGm1l+7dyNgBHQg8ICrsYggmpijyGzHVF3fQl4jEdcbGzYKIxIrIkaKIa8qazK6ZJ
 I/nCVxrOTN/CUA4bydtRVhWPawSRlp7xNiP/qHSeOEyTZtiZ/c7CHxd
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

assign clk_dev_ops(clkp->dev) to ops to ensure correct clk operations
are called on clocks.

This fixes the incorrect enable_count issue as described in [1].

[1]: https://lore.kernel.org/all/SEZPR06MB695927A6DEEEF8489A06897396A7A@SEZPR06MB6959.apcprd06.prod.outlook.com/

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/clk-uclass.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/clk/clk-uclass.c b/drivers/clk/clk-uclass.c
index 3b5e3f9c86..3e9d68feb3 100644
--- a/drivers/clk/clk-uclass.c
+++ b/drivers/clk/clk-uclass.c
@@ -640,6 +640,7 @@ int clk_enable(struct clk *clk)
 	if (CONFIG_IS_ENABLED(CLK_CCF)) {
 		/* Take id 0 as a non-valid clk, such as dummy */
 		if (clk->id && !clk_get_by_id(clk->id, &clkp)) {
+			ops = clk_dev_ops(clkp->dev);
 			if (clkp->enable_count) {
 				clkp->enable_count++;
 				return 0;
@@ -699,6 +700,7 @@ int clk_disable(struct clk *clk)
 
 	if (CONFIG_IS_ENABLED(CLK_CCF)) {
 		if (clk->id && !clk_get_by_id(clk->id, &clkp)) {
+			ops = clk_dev_ops(clkp->dev);
 			if (clkp->flags & CLK_IS_CRITICAL)
 				return 0;
 

-- 
2.39.2

