From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 08:42:06 +0000
Subject: [PATCH v3 2/3] pmdomain: rockchip: don't report probe deferral as
 an error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-pmdomain-rockchip-v3-2-b7039ca30b87@gmail.com>
References: <20261113-pmdomain-rockchip-v3-0-b7039ca30b87@gmail.com>
In-Reply-To: <20261113-pmdomain-rockchip-v3-0-b7039ca30b87@gmail.com>
To: Ulf Hansson <ulfh@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Kevin Hilman <khilman@linaro.org>, Caesar Wang <wxt@rock-chips.com>, 
 Elaine Zhang <zhangqing@rock-chips.com>
Cc: linux-pm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Yao Zi <me@ziyao.cc>, Igor Pecovnik <igor@armbian.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794559325; l=3789;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=eOrDJPTLfEW1xbio4U0pPlpSLvwzZMxXL5lZvNK4rA8=;
 b=AvrffsDE4+u4FUgmu9CMr1tECJc0bIbqCoCD2K9p6N1N1bi/AXG7SFl4ybD9NpWPQemr2V/0g
 HchCHMTmjCcBFjqy5Qwe7WxEjYDrjH/Imgb2c6N7PQvDg62lUbS3/3R
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A domain clock that is not available yet is printed as an error by
rockchip_pm_add_one_domain() and again by its callers, on every probe
attempt. A pm_qos syscon that defers turns into -ENODEV and fails the
probe.

Use dev_err_probe() where the errors happen, keep the syscon error code,
and drop the callers' messages.

Yao Zi sent a patch for the clock message earlier [1] and agreed to drop
it for this one.

Link: https://lore.kernel.org/r/20261105001257.1368266-3-me@ziyao.cc [1]
Fixes: 7c696693a4f5 ("soc: rockchip: power-domain: Add power domain driver")
Fixes: 6be05b5ec161 ("soc: rockchip: power-domain: add support for sub-power domains")
Fixes: 074c6a422d86 ("soc: rockchip: power-domain: support qos save and restore")
Suggested-by: Sebastian Reichel <sebastian.reichel@collabora.com>
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/pmdomain/rockchip/pm-domains.c | 37 +++++++++++++++++-----------------
 1 file changed, 18 insertions(+), 19 deletions(-)

diff --git a/drivers/pmdomain/rockchip/pm-domains.c b/drivers/pmdomain/rockchip/pm-domains.c
index df3f43d0c01b..a0b47d8c4b2a 100644
--- a/drivers/pmdomain/rockchip/pm-domains.c
+++ b/drivers/pmdomain/rockchip/pm-domains.c
@@ -849,17 +849,20 @@ static int rockchip_pm_add_one_domain(struct rockchip_pmu *pmu,
 	for (i = 0; i < pd->num_clks; i++) {
 		pd->clks[i].clk = of_clk_get(node, i);
 		if (IS_ERR(pd->clks[i].clk)) {
-			error = PTR_ERR(pd->clks[i].clk);
-			dev_err(pmu->dev,
-				"%pOFn: failed to get clk at index %d: %d\n",
-				node, i, error);
+			error = dev_err_probe(pmu->dev,
+					      PTR_ERR(pd->clks[i].clk),
+					      "%pOFn: failed to get clk at index %d\n",
+					      node, i);
 			goto err_put_clocks;
 		}
 	}
 
 	error = clk_bulk_prepare(pd->num_clks, pd->clks);
-	if (error)
+	if (error) {
+		dev_err_probe(pmu->dev, error,
+			      "%pOFn: failed to prepare clocks\n", node);
 		goto err_put_clocks;
+	}
 
 	pd->num_qos = of_count_phandle_with_args(node, "pm_qos",
 						 NULL);
@@ -884,13 +887,18 @@ static int rockchip_pm_add_one_domain(struct rockchip_pmu *pmu,
 		for (j = 0; j < pd->num_qos; j++) {
 			qos_node = of_parse_phandle(node, "pm_qos", j);
 			if (!qos_node) {
-				error = -ENODEV;
+				error = dev_err_probe(pmu->dev, -ENODEV,
+						      "%pOFn: failed to get pm_qos %d\n",
+						      node, j);
 				goto err_unprepare_clocks;
 			}
 			pd->qos_regmap[j] = syscon_node_to_regmap(qos_node);
 			of_node_put(qos_node);
 			if (IS_ERR(pd->qos_regmap[j])) {
-				error = -ENODEV;
+				error = dev_err_probe(pmu->dev,
+						      PTR_ERR(pd->qos_regmap[j]),
+						      "%pOFn: failed to get pm_qos %d regmap\n",
+						      node, j);
 				goto err_unprepare_clocks;
 			}
 		}
@@ -1034,11 +1042,8 @@ static int rockchip_pm_add_subdomain(struct rockchip_pmu *pmu,
 		parent_domain = pmu->genpd_data.domains[idx];
 
 		error = rockchip_pm_add_one_domain(pmu, np);
-		if (error) {
-			dev_err(pmu->dev, "failed to handle node %pOFn: %d\n",
-				np, error);
+		if (error)
 			return error;
-		}
 
 		error = of_property_read_u32(np, "reg", &idx);
 		if (error) {
@@ -1128,18 +1133,12 @@ static int rockchip_pm_domain_probe(struct platform_device *pdev)
 
 	for_each_available_child_of_node_scoped(np, node) {
 		error = rockchip_pm_add_one_domain(pmu, node);
-		if (error) {
-			dev_err(dev, "failed to handle node %pOFn: %d\n",
-				node, error);
+		if (error)
 			goto err_out;
-		}
 
 		error = rockchip_pm_add_subdomain(pmu, node);
-		if (error < 0) {
-			dev_err(dev, "failed to handle subdomain node %pOFn: %d\n",
-				node, error);
+		if (error < 0)
 			goto err_out;
-		}
 	}
 
 	if (error) {

-- 
2.55.0

