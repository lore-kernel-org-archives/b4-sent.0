From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 10:01:19 +0000
Subject: [PATCH v4] pmdomain: rockchip: remove subdomain links before the
 domains on error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-pmdomain-rockchip-v4-1-c793cbec970a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NyQ6CMBSF4VcxXVvTgdGV72FcdISqUNJioyG8u
 y1u0BCXJ/nvdyfglTPKg+NuAk4F443t48j2OyBa1jcKGhk3IIgUGGMEh07ajpkeOituojUDpFl
 dMqJKLXUO4t3glDbPxTxfPts/+FWJMUGpaI0frXstTwNO3T8/YIhgwWvNCsUZq4pTE4P7QdgOJ
 D+QtUC2BBKFXMg6I4xQqctfga4FuiXQKPAS0Vowinj1Jczz/AZU6LbgSAEAAA==
X-Change-ID: 20261110-pmdomain-rockchip-3497a2e7fdf5
To: Ulf Hansson <ulfh@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Kevin Hilman <khilman@linaro.org>, Caesar Wang <wxt@rock-chips.com>, 
 Elaine Zhang <zhangqing@rock-chips.com>
Cc: linux-pm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Yao Zi <me@ziyao.cc>, Igor Pecovnik <igor@armbian.com>, 
 stable@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795687278; l=3318;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=uck8uxhwuf0y7xOwjlHVWqB3IaYYgJtnjsA3v9+m38k=;
 b=sRUvDBPRpSUbm6kCsepTLQEUjX7F+fdk2Qa4Tux6yLrT9dKMKjvPTx94+soL/DDWuCHWOxAnQ
 570nDuozAeOCmeA3ljSrNpMaWT3yMRspv7kTsM6Xwuj1oruD9RhePPd
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When probe fails after some domains were registered, the cleanup calls
pm_genpd_remove() in domain id order. That fails with -EBUSY for every
domain that is still a parent. Reversing the order does not help: on
RK3588 RKVDEC0/1 have a parent with a lower and one with a higher id.
devm then frees those domains while they are still on gpd_list.

Remove the parent/child links first, depth first over the DT nodes.

Fixes: 79d12b7a7f22 ("soc: rockchip: power-domain: use pm_genpd_remove in error cleanup")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested as v1 (same code) on an Orange Pi 5 (RK3588S), v7.3 based
kernel, with a test device tree that makes the PD_FEC clock appear late:
no freed domain left on gpd_list, and the controller binds later with
all 26 domains. The rebase is build-tested only.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.
---
Changes in v4:
- Rebased on the pmdomain fixes branch
- Fix only; the pm_qos error code and dev_err_probe() changes go to next
  separately
- Dropped "don't report probe deferral as an error": Yao Zi's patch in
  next covers part of it, the cleanup series the rest
- Link to v3: https://patch.msgid.link/20261113-pmdomain-rockchip-v3-0-b7039ca30b87@gmail.com
---
 drivers/pmdomain/rockchip/pm-domains.c | 33 +++++++++++++++++++++++++++++++++
 1 file changed, 33 insertions(+)

diff --git a/drivers/pmdomain/rockchip/pm-domains.c b/drivers/pmdomain/rockchip/pm-domains.c
index 563614a7bf66..81a9163b43cc 100644
--- a/drivers/pmdomain/rockchip/pm-domains.c
+++ b/drivers/pmdomain/rockchip/pm-domains.c
@@ -993,12 +993,45 @@ static void rockchip_pm_remove_one_domain(struct rockchip_pm_domain *pd)
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
+/* Remove the links depth first, so each child has no subdomains left. */
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
 
+	/* pm_genpd_remove() refuses a domain that still has subdomains */
+	for_each_available_child_of_node_scoped(pmu->dev->of_node, np)
+		rockchip_pm_remove_subdomains(pmu, np);
+
 	for (i = 0; i < pmu->genpd_data.num_domains; i++) {
 		genpd = pmu->genpd_data.domains[i];
 		if (genpd) {

---
base-commit: faa6cd23f6269990b09ec63849239aae5cdb238b
change-id: 20261110-pmdomain-rockchip-3497a2e7fdf5

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

