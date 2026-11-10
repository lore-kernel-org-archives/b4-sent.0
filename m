From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:11:29 +0000
Subject: [PATCH 2/3] pmdomain: rockchip: remove subdomain links before the
 domains on error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-pmdomain-rockchip-v1-2-6b9fa6ebaa86@gmail.com>
References: <20261110-pmdomain-rockchip-v1-0-6b9fa6ebaa86@gmail.com>
In-Reply-To: <20261110-pmdomain-rockchip-v1-0-6b9fa6ebaa86@gmail.com>
To: Ulf Hansson <ulfh@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Kevin Hilman <khilman@linaro.org>, Caesar Wang <wxt@rock-chips.com>, 
 Elaine Zhang <zhangqing@rock-chips.com>
Cc: linux-pm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294687; l=4093;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=dHO39ZDWV/KiynPjCX8DIPyBCclsXy+H+T79g0o69nI=;
 b=FFzN4q78FMlY70uZGAMhsLAd44pNMH5/Fp7RNwf+nYNlyKGSPKSu/By7MPSUvIquosiNFfIVv
 eLAwEl1GuJqCDwK9Y6vYCfyPUevloLjeK0yPkHt6uxEvUgGCTNxZn24
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When rockchip_pm_domain_probe() fails after some domains were
registered, for example because a clock of a nested domain is not
available yet and returns -EPROBE_DEFER, rockchip_pm_domain_cleanup()
calls pm_genpd_remove() for every registered domain in domain id order.

pm_genpd_remove() refuses a domain that is still the parent of another
domain and returns -EBUSY. The cleanup walks parents before their
children in id order, and on RK3588 RKVDEC0/RKVDEC1 (ids 14 and 15) are
also children of VDPU (id 21), so no ordering of the domain array lets
every removal succeed. Each refused parent only gets the "state may be
inconsistent" message, and on return devm frees its struct
rockchip_pm_domain, the embedded generic_pm_domain included, while it
is still linked on the global gpd_list. The next registration, the
unused domain power off at late_initcall and the genpd debugfs files
then walk freed memory.

Remove the parent/child links first, walking the power domain nodes
depth first in the same way rockchip_pm_add_subdomain() added them, so
that each child no longer has subdomains of its own when its link is
removed. With no links left, and no provider or devices attached in the
probe error path, pm_genpd_remove() succeeds for every domain before
devm frees it. pm_genpd_remove_subdomain() also drops the parent's
subdomain count, which removing the child with pm_genpd_remove() alone
does not.

Fixes: 79d12b7a7f22 ("soc: rockchip: power-domain: use pm_genpd_remove in error cleanup")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/pmdomain/rockchip/pm-domains.c | 46 ++++++++++++++++++++++++++++++++++
 1 file changed, 46 insertions(+)

diff --git a/drivers/pmdomain/rockchip/pm-domains.c b/drivers/pmdomain/rockchip/pm-domains.c
index 3b39b231ca0e..d7df19e10000 100644
--- a/drivers/pmdomain/rockchip/pm-domains.c
+++ b/drivers/pmdomain/rockchip/pm-domains.c
@@ -957,12 +957,58 @@ static void rockchip_pm_remove_one_domain(struct rockchip_pm_domain *pd)
 	/* devm will free our memory */
 }
 
+static struct generic_pm_domain *
+rockchip_pm_node_to_genpd(struct rockchip_pmu *pmu, struct device_node *node)
+{
+	u32 id;
+
+	if (of_property_read_u32(node, "reg", &id) ||
+	    id >= pmu->genpd_data.num_domains)
+		return NULL;
+
+	return pmu->genpd_data.domains[id];
+}
+
+/*
+ * Undo the pm_genpd_add_subdomain() calls of rockchip_pm_add_subdomain().
+ * Links are only ever added between a DT node and its children, so walking
+ * the tree depth first and removing the links of the children before the
+ * link to their parent always finds the subdomain without subdomains of its
+ * own, as pm_genpd_remove_subdomain() requires. This also covers domains with
+ * more than one parent (RKVDEC0/RKVDEC1 on RK3588), which a walk in domain id
+ * or registration order does not.
+ */
+static void rockchip_pm_remove_subdomains(struct rockchip_pmu *pmu,
+					  struct device_node *parent)
+{
+	struct generic_pm_domain *parent_domain, *child_domain;
+
+	parent_domain = rockchip_pm_node_to_genpd(pmu, parent);
+
+	for_each_child_of_node_scoped(parent, np) {
+		rockchip_pm_remove_subdomains(pmu, np);
+
+		child_domain = rockchip_pm_node_to_genpd(pmu, np);
+		if (parent_domain && child_domain)
+			pm_genpd_remove_subdomain(parent_domain, child_domain);
+	}
+}
+
 static void rockchip_pm_domain_cleanup(struct rockchip_pmu *pmu)
 {
 	struct generic_pm_domain *genpd;
 	struct rockchip_pm_domain *pd;
 	int i;
 
+	/*
+	 * pm_genpd_remove() refuses a domain that still has subdomains, and
+	 * devm frees the domains on return whether or not they were removed,
+	 * which would leave freed memory on the global genpd list. Remove all
+	 * parent/child links first, so every domain can be removed.
+	 */
+	for_each_available_child_of_node_scoped(pmu->dev->of_node, np)
+		rockchip_pm_remove_subdomains(pmu, np);
+
 	for (i = 0; i < pmu->genpd_data.num_domains; i++) {
 		genpd = pmu->genpd_data.domains[i];
 		if (genpd) {

-- 
2.55.0

