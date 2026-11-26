From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 10:01:26 +0000
Subject: [PATCH 3/3] pmdomain: rockchip: report domain errors where they
 happen
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-pmdomain-rockchip-cleanup-v1-3-a19f5ea7d555@gmail.com>
References: <20261126-pmdomain-rockchip-cleanup-v1-0-a19f5ea7d555@gmail.com>
In-Reply-To: <20261126-pmdomain-rockchip-cleanup-v1-0-a19f5ea7d555@gmail.com>
To: Ulf Hansson <ulfh@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>
Cc: linux-pm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Yao Zi <me@ziyao.cc>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795687283; l=3430;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=3AtAbt0gF5z4t2/yujfDXZ8Drlb6obYk/ZkMiiGPe04=;
 b=j+aLrJix27Oqfi1XC8nUFAK/8l0MqREaHGMArIJ+AoRbOnYDN/6wIpgqSGW7t7ylhckA+sm7l
 ipCOyxDq/MlB4wbav21x1xx2dYDoIlwQTlTtDuW8lyrdmaFRAmyIEdS
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Print the clock prepare and pm_qos failures with dev_err_probe() and
drop the callers' "failed to handle node" messages. Each error is now
reported once, and -ENOMEM stays quiet.

Suggested-by: Sebastian Reichel <sebastian.reichel@collabora.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/pmdomain/rockchip/pm-domains.c | 40 +++++++++++++++-------------------
 1 file changed, 17 insertions(+), 23 deletions(-)

diff --git a/drivers/pmdomain/rockchip/pm-domains.c b/drivers/pmdomain/rockchip/pm-domains.c
index 9d5a79c6d4f9..c3df32934120 100644
--- a/drivers/pmdomain/rockchip/pm-domains.c
+++ b/drivers/pmdomain/rockchip/pm-domains.c
@@ -881,17 +881,19 @@ static int rockchip_pm_add_one_domain(struct rockchip_pmu *pmu,
 	for (i = 0; i < pd->num_clks; i++) {
 		pd->clks[i].clk = of_clk_get(node, i);
 		if (IS_ERR(pd->clks[i].clk)) {
-			error = PTR_ERR(pd->clks[i].clk);
-			dev_err_probe(pmu->dev, error,
-				      "%pOFn: failed to get clk at index %d: %d\n",
-				      node, i, error);
+			error = dev_err_probe(pmu->dev, PTR_ERR(pd->clks[i].clk),
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
@@ -916,13 +918,18 @@ static int rockchip_pm_add_one_domain(struct rockchip_pmu *pmu,
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
-				error = PTR_ERR(pd->qos_regmap[j]);
+				error = dev_err_probe(pmu->dev,
+						      PTR_ERR(pd->qos_regmap[j]),
+						      "%pOFn: failed to get pm_qos %d regmap\n",
+						      node, j);
 				goto err_unprepare_clocks;
 			}
 		}
@@ -1074,13 +1081,8 @@ static int rockchip_pm_add_subdomain(struct rockchip_pmu *pmu,
 
 		error = rockchip_pm_add_one_domain(pmu, np,
 						   to_rockchip_pd(parent_domain));
-		if (error) {
-			if (error != -EPROBE_DEFER)
-				dev_err(pmu->dev,
-					"failed to handle node %pOFn: %d\n",
-					np, error);
+		if (error)
 			return error;
-		}
 
 		error = of_property_read_u32(np, "reg", &idx);
 		if (error)
@@ -1162,20 +1164,12 @@ static int rockchip_pm_domain_probe(struct platform_device *pdev)
 
 	for_each_available_child_of_node_scoped(np, node) {
 		error = rockchip_pm_add_one_domain(pmu, node, NULL);
-		if (error) {
-			if (error != -EPROBE_DEFER)
-				dev_err(dev, "failed to handle node %pOFn: %d\n",
-					node, error);
+		if (error)
 			goto err_out;
-		}
 
 		error = rockchip_pm_add_subdomain(pmu, node);
-		if (error < 0) {
-			if (error != -EPROBE_DEFER)
-				dev_err(dev, "failed to handle subdomain node %pOFn: %d\n",
-					node, error);
+		if (error < 0)
 			goto err_out;
-		}
 
 		/* A domain left on is not fatal; carry on with the others. */
 		rockchip_pm_power_off_subtree(pmu, node);

-- 
2.55.0

