From: Cunhao Lu <1579567540@qq.com>
Date: Mon, 23 Nov 2026 17:59:03 +0800
Subject: [PATCH v7 4/5] clk: rockchip: Return errors from
 rockchip_clk_of_add_provider()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-add-board-ok3572-c-clk-v7-4-16f6860191a9@qq.com>
References: <20261123-add-board-ok3572-c-clk-v7-0-16f6860191a9@qq.com>
In-Reply-To: <20261123-add-board-ok3572-c-clk-v7-0-16f6860191a9@qq.com>
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Elaine Zhang <zhangqing@rock-chips.com>
Cc: Cunhao Lu <1579567540@qq.com>, Jonas Karlman <jonas@kwiboo.se>, 
 linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795427940; l=2105;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=KzKhwQsNNbIws0UUJ9FPBVs8oMjRaBZLFgFz/fZdYoI=;
 b=HFB7NnDB8rPefSg8tt8zKk/NjvwmZqMsFFY3rd8vjxVT35SJbPvWEKCrjSWqXC3wDoHA/evN1
 ww9SYQ9+g54AvPkJL0DqtcqYOvI585gggM2QGBUGtECUkSHcdlp+uPI
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rockchip_clk_of_add_provider() discards the OF registration status
after logging an error. Return the status so a caller can release its
lookup data if the OF provider fails to register.

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
 drivers/clk/rockchip/clk.c | 14 +++++++++-----
 drivers/clk/rockchip/clk.h |  4 ++--
 2 files changed, 11 insertions(+), 7 deletions(-)

diff --git a/drivers/clk/rockchip/clk.c b/drivers/clk/rockchip/clk.c
index 2053e0d67a1b..7c52406d4925 100644
--- a/drivers/clk/rockchip/clk.c
+++ b/drivers/clk/rockchip/clk.c
@@ -420,12 +420,16 @@ void rockchip_clk_finalize(struct rockchip_clk_provider *ctx)
 }
 EXPORT_SYMBOL_GPL(rockchip_clk_finalize);
 
-void rockchip_clk_of_add_provider(struct device_node *np,
-				  struct rockchip_clk_provider *ctx)
+int rockchip_clk_of_add_provider(struct device_node *np,
+				 struct rockchip_clk_provider *ctx)
 {
-	if (of_clk_add_provider(np, of_clk_src_onecell_get,
-				&ctx->clk_data))
-		pr_err("%s: could not register clk provider\n", __func__);
+	int ret;
+
+	ret = of_clk_add_provider(np, of_clk_src_onecell_get, &ctx->clk_data);
+	if (ret)
+		pr_err("%pOF: could not register clk provider: %d\n", np, ret);
+
+	return ret;
 }
 EXPORT_SYMBOL_GPL(rockchip_clk_of_add_provider);
 
diff --git a/drivers/clk/rockchip/clk.h b/drivers/clk/rockchip/clk.h
index d84e42533266..a1d4fd3b1248 100644
--- a/drivers/clk/rockchip/clk.h
+++ b/drivers/clk/rockchip/clk.h
@@ -1374,8 +1374,8 @@ struct rockchip_clk_provider *rockchip_clk_init(struct device_node *np,
 struct rockchip_clk_provider *rockchip_clk_init_early(struct device_node *np,
 			void __iomem *base, unsigned long nr_clks);
 void rockchip_clk_finalize(struct rockchip_clk_provider *ctx);
-void rockchip_clk_of_add_provider(struct device_node *np,
-				struct rockchip_clk_provider *ctx);
+int rockchip_clk_of_add_provider(struct device_node *np,
+				 struct rockchip_clk_provider *ctx);
 int rockchip_clk_add_grf(struct rockchip_clk_provider *ctx,
 			 struct regmap *grf,
 			 enum rockchip_grf_type type);

-- 
2.34.1

