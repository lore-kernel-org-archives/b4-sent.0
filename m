From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 10:01:25 +0000
Subject: [PATCH 2/3] pmdomain: rockchip: use dev_err_probe() in the probe
 path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-pmdomain-rockchip-cleanup-v1-2-a19f5ea7d555@gmail.com>
References: <20261126-pmdomain-rockchip-cleanup-v1-0-a19f5ea7d555@gmail.com>
In-Reply-To: <20261126-pmdomain-rockchip-cleanup-v1-0-a19f5ea7d555@gmail.com>
To: Ulf Hansson <ulfh@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>
Cc: linux-pm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Yao Zi <me@ziyao.cc>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795687283; l=4842;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=EuQMv/4YZ9MKBCAwmy2pWeQx5JPLsPHE+V7fKlPqOcE=;
 b=PkWY7V9lN6YIaE5jS+PW/vU+Ml5zf9WOW6JDrNkQEWpdrHtdPrqAE7zHSQl56yI17wpz0+JnB
 F02kVG33IuUCwYpNho0/o2KlnExh/zWPiELveBTgGBoa4qa7KkpzuQ2
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert the dev_err() and return pairs in the probe path to
dev_err_probe(). The return values do not change.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/pmdomain/rockchip/pm-domains.c | 82 ++++++++++++++--------------------
 1 file changed, 33 insertions(+), 49 deletions(-)

diff --git a/drivers/pmdomain/rockchip/pm-domains.c b/drivers/pmdomain/rockchip/pm-domains.c
index b52bdf0e8a19..9d5a79c6d4f9 100644
--- a/drivers/pmdomain/rockchip/pm-domains.c
+++ b/drivers/pmdomain/rockchip/pm-domains.c
@@ -842,28 +842,22 @@ static int rockchip_pm_add_one_domain(struct rockchip_pmu *pmu,
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
@@ -1072,12 +1066,10 @@ static int rockchip_pm_add_subdomain(struct rockchip_pmu *pmu,
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
 
 		error = rockchip_pm_add_one_domain(pmu, np,
@@ -1091,23 +1083,20 @@ static int rockchip_pm_add_subdomain(struct rockchip_pmu *pmu,
 		}
 
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
@@ -1126,10 +1115,8 @@ static int rockchip_pm_domain_probe(struct platform_device *pdev)
 	const struct rockchip_pmu_info *pmu_info;
 	int error;
 
-	if (!np) {
-		dev_err(dev, "device tree node not found\n");
-		return -ENODEV;
-	}
+	if (!np)
+		return dev_err_probe(dev, -ENODEV, "device tree node not found\n");
 
 	pmu_info = device_get_match_data(dev);
 
@@ -1146,16 +1133,13 @@ static int rockchip_pm_domain_probe(struct platform_device *pdev)
 	pmu->genpd_data.num_domains = pmu_info->num_domains;
 
 	parent = dev->parent;
-	if (!parent) {
-		dev_err(dev, "no parent for syscon devices\n");
-		return -ENODEV;
-	}
+	if (!parent)
+		return dev_err_probe(dev, -ENODEV, "no parent for syscon devices\n");
 
 	pmu->regmap = syscon_node_to_regmap(parent->of_node);
-	if (IS_ERR(pmu->regmap)) {
-		dev_err(dev, "no regmap available\n");
-		return PTR_ERR(pmu->regmap);
-	}
+	if (IS_ERR(pmu->regmap))
+		return dev_err_probe(dev, PTR_ERR(pmu->regmap),
+				     "no regmap available\n");
 
 	/*
 	 * Configure power up and down transition delays for CORE
@@ -1204,7 +1188,7 @@ static int rockchip_pm_domain_probe(struct platform_device *pdev)
 
 	error = of_genpd_add_provider_onecell(np, &pmu->genpd_data);
 	if (error) {
-		dev_err(dev, "failed to add provider: %d\n", error);
+		dev_err_probe(dev, error, "failed to add provider\n");
 		goto err_out;
 	}
 

-- 
2.55.0

