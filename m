From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:23:30 +0000
Subject: [PATCH v2 2/2] pmdomain: rockchip: report domain errors once, with
 dev_err_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-pmdomain-rockchip-v2-2-5cd942a23df7@gmail.com>
References: <20261112-pmdomain-rockchip-v2-0-5cd942a23df7@gmail.com>
In-Reply-To: <20261112-pmdomain-rockchip-v2-0-5cd942a23df7@gmail.com>
To: Ulf Hansson <ulfh@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Kevin Hilman <khilman@linaro.org>, Caesar Wang <wxt@rock-chips.com>, 
 Elaine Zhang <zhangqing@rock-chips.com>
Cc: linux-pm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Yao Zi <me@ziyao.cc>, Igor Pecovnik <igor@armbian.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794471809; l=7366;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=NjDgN0qxUNb8P6mWj/gQ4TDMTDd100w9vcSH2E4Nnws=;
 b=uCNgNWReaauPLf0MyoPtleQYM2BzI10ZFEpvl6R03KZd4/DcFIva5RZJU8iUeSG0tN/b2CUrr
 dHYBRH+bmoAAaOSJG2J8OpsPMJGNdyxyhJOehfNBhVULRcqM4WsYcC/
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a power domain clock is not available yet,
rockchip_pm_add_one_domain() returns -EPROBE_DEFER, and both it and its
callers rockchip_pm_domain_probe() and rockchip_pm_add_subdomain() print
that with dev_err():

  rockchip-pm-domain ...: power-domain: failed to get clk at index 1: -517
  rockchip-pm-domain ...: failed to handle node power-domain: -517

once per probe attempt, and the second line twice for a nested domain.
On an RK3588 board whose NPU domain clock appears late this is more than
20 error lines before the domain finally probes, and the reason of the
deferral is not recorded. Other failures are reported twice (once where
they happen and once by the callers), or only by the callers, which name
the node but not what failed: a missing pm_qos phandle and a pm_qos node
without a regmap print nothing in rockchip_pm_add_one_domain(), and a
failed clk_bulk_prepare() only has the message of the clk core, which
names neither the device nor the domain.

Report every error once, where it happens, with dev_err_probe(), and
drop the "failed to handle (subdomain) node" messages from the callers.
A deferral is then quiet and keeps its specific reason in
/sys/kernel/debug/devices_deferred, such as "failed to get clk at index
1", and -ENOMEM, which the callers used to print, is quiet as well. The
return values are unchanged, except that a failed
syscon_node_to_regmap() for a pm_qos node now returns its own error
instead of -ENODEV: it can be -EPROBE_DEFER (a syscon regmap that is
not registered yet, or a syscon clock or hwlock that is not available
yet), which must not turn into a probe failure.

Fixes: 7c696693a4f5 ("soc: rockchip: power-domain: Add power domain driver")
Fixes: 6be05b5ec161 ("soc: rockchip: power-domain: add support for sub-power domains")
Suggested-by: Sebastian Reichel <sebastian.reichel@collabora.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/pmdomain/rockchip/pm-domains.c | 98 +++++++++++++++-------------------
 1 file changed, 43 insertions(+), 55 deletions(-)

diff --git a/drivers/pmdomain/rockchip/pm-domains.c b/drivers/pmdomain/rockchip/pm-domains.c
index 00c7e78f89b5..be077fb52f40 100644
--- a/drivers/pmdomain/rockchip/pm-domains.c
+++ b/drivers/pmdomain/rockchip/pm-domains.c
@@ -804,28 +804,22 @@ static int rockchip_pm_add_one_domain(struct rockchip_pmu *pmu,
 	int error;
 
 	error = of_property_read_u32(node, "reg", &id);
-	if (error) {
-		dev_err(pmu->dev,
-			"%pOFn: failed to retrieve domain id (reg): %d\n",
-			node, error);
-		return -EINVAL;
-	}
+	if (error)
+		return dev_err_probe(pmu->dev, -EINVAL,
+				     "%pOFn: failed to retrieve domain id (reg)\n",
+				     node);
 
-	if (id >= pmu->info->num_domains) {
-		dev_err(pmu->dev, "%pOFn: invalid domain id %d\n",
-			node, id);
-		return -EINVAL;
-	}
+	if (id >= pmu->info->num_domains)
+		return dev_err_probe(pmu->dev, -EINVAL,
+				     "%pOFn: invalid domain id %d\n", node, id);
 	/* RK3588 has domains with two parents (RKVDEC0/RKVDEC1) */
 	if (pmu->genpd_data.domains[id])
 		return 0;
 
 	pd_info = &pmu->info->domain_info[id];
-	if (!pd_info->pwr_mask && !pd_info->req_mask) {
-		dev_err(pmu->dev, "%pOFn: undefined domain id %d\n",
-			node, id);
-		return -EINVAL;
-	}
+	if (!pd_info->pwr_mask && !pd_info->req_mask)
+		return dev_err_probe(pmu->dev, -EINVAL,
+				     "%pOFn: undefined domain id %d\n", node, id);
 
 	pd = devm_kzalloc_obj(pmu->dev, *pd);
 	if (!pd)
@@ -849,17 +843,20 @@ static int rockchip_pm_add_one_domain(struct rockchip_pmu *pmu,
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
@@ -884,13 +881,18 @@ static int rockchip_pm_add_one_domain(struct rockchip_pmu *pmu,
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
@@ -1038,39 +1040,31 @@ static int rockchip_pm_add_subdomain(struct rockchip_pmu *pmu,
 		u32 idx;
 
 		error = of_property_read_u32(parent, "reg", &idx);
-		if (error) {
-			dev_err(pmu->dev,
-				"%pOFn: failed to retrieve domain id (reg): %d\n",
-				parent, error);
-			return error;
-		}
+		if (error)
+			return dev_err_probe(pmu->dev, error,
+					     "%pOFn: failed to retrieve domain id (reg)\n",
+					     parent);
 		parent_domain = pmu->genpd_data.domains[idx];
 
 		error = rockchip_pm_add_one_domain(pmu, np);
-		if (error) {
-			dev_err(pmu->dev, "failed to handle node %pOFn: %d\n",
-				np, error);
+		if (error)
 			return error;
-		}
 
 		error = of_property_read_u32(np, "reg", &idx);
-		if (error) {
-			dev_err(pmu->dev,
-				"%pOFn: failed to retrieve domain id (reg): %d\n",
-				np, error);
-			return error;
-		}
+		if (error)
+			return dev_err_probe(pmu->dev, error,
+					     "%pOFn: failed to retrieve domain id (reg)\n",
+					     np);
 		child_domain = pmu->genpd_data.domains[idx];
 
 		error = pm_genpd_add_subdomain(parent_domain, child_domain);
-		if (error) {
-			dev_err(pmu->dev, "%s failed to add subdomain %s: %d\n",
-				parent_domain->name, child_domain->name, error);
-			return error;
-		} else {
-			dev_dbg(pmu->dev, "%s add subdomain: %s\n",
-				parent_domain->name, child_domain->name);
-		}
+		if (error)
+			return dev_err_probe(pmu->dev, error,
+					     "%s failed to add subdomain %s\n",
+					     parent_domain->name, child_domain->name);
+
+		dev_dbg(pmu->dev, "%s add subdomain: %s\n",
+			parent_domain->name, child_domain->name);
 
 		error = rockchip_pm_add_subdomain(pmu, np);
 		if (error)
@@ -1141,18 +1135,12 @@ static int rockchip_pm_domain_probe(struct platform_device *pdev)
 
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

