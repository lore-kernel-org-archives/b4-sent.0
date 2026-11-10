From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:11:30 +0000
Subject: [PATCH 3/3] pmdomain: rockchip: do not report probe deferral of a
 domain as an error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-pmdomain-rockchip-v1-3-6b9fa6ebaa86@gmail.com>
References: <20261110-pmdomain-rockchip-v1-0-6b9fa6ebaa86@gmail.com>
In-Reply-To: <20261110-pmdomain-rockchip-v1-0-6b9fa6ebaa86@gmail.com>
To: Ulf Hansson <ulfh@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Kevin Hilman <khilman@linaro.org>, Caesar Wang <wxt@rock-chips.com>, 
 Elaine Zhang <zhangqing@rock-chips.com>
Cc: linux-pm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294687; l=2616;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=qCJHjn4ARWllWuHF/3iUyLeU1dBEpnl7ug6sZBC3HTs=;
 b=8X1ybrV4e6PsuLq/Pxx6EQ2FHsA73qXCewhBYjwkiMJXLmo6XYpqrrBDeFmWuCs7wg1xr8Atc
 qjKCZLA33M7DM0Pe0fSNxZsscSShW/5/Z1vnho6mDSZn6ki5VYFy+KC
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a power domain clock is not available yet,
rockchip_pm_add_one_domain() records the reason with dev_err_probe() and
returns -EPROBE_DEFER, but its callers rockchip_pm_domain_probe() and
rockchip_pm_add_subdomain() still print it with dev_err():

  rockchip-pm-domain ...: failed to handle node power-domain: -517

once per probe attempt, and twice for a nested domain. On an RK3588
board whose NPU domain clock appears late this is more than 20 error
lines before the domain finally probes.

Only rockchip_pm_add_one_domain() can return -EPROBE_DEFER here, and it
already records the deferral reason, so skip the message in the callers
for -EPROBE_DEFER and keep it for real errors. dev_err_probe() is not
used in the callers because it would replace the reason recorded for
/sys/kernel/debug/devices_deferred ("failed to get clk at index 1") with
the less specific "failed to handle node power-domain".

Fixes: 7c696693a4f5 ("soc: rockchip: power-domain: Add power domain driver")
Fixes: 6be05b5ec161 ("soc: rockchip: power-domain: add support for sub-power domains")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/pmdomain/rockchip/pm-domains.c | 15 +++++++++------
 1 file changed, 9 insertions(+), 6 deletions(-)

diff --git a/drivers/pmdomain/rockchip/pm-domains.c b/drivers/pmdomain/rockchip/pm-domains.c
index d7df19e10000..70ebe5696b39 100644
--- a/drivers/pmdomain/rockchip/pm-domains.c
+++ b/drivers/pmdomain/rockchip/pm-domains.c
@@ -1050,8 +1050,9 @@ static int rockchip_pm_add_subdomain(struct rockchip_pmu *pmu,
 
 		error = rockchip_pm_add_one_domain(pmu, np);
 		if (error) {
-			dev_err(pmu->dev, "failed to handle node %pOFn: %d\n",
-				np, error);
+			if (error != -EPROBE_DEFER)
+				dev_err(pmu->dev, "failed to handle node %pOFn: %d\n",
+					np, error);
 			return error;
 		}
 
@@ -1144,15 +1145,17 @@ static int rockchip_pm_domain_probe(struct platform_device *pdev)
 	for_each_available_child_of_node_scoped(np, node) {
 		error = rockchip_pm_add_one_domain(pmu, node);
 		if (error) {
-			dev_err(dev, "failed to handle node %pOFn: %d\n",
-				node, error);
+			if (error != -EPROBE_DEFER)
+				dev_err(dev, "failed to handle node %pOFn: %d\n",
+					node, error);
 			goto err_out;
 		}
 
 		error = rockchip_pm_add_subdomain(pmu, node);
 		if (error < 0) {
-			dev_err(dev, "failed to handle subdomain node %pOFn: %d\n",
-				node, error);
+			if (error != -EPROBE_DEFER)
+				dev_err(dev, "failed to handle subdomain node %pOFn: %d\n",
+					node, error);
 			goto err_out;
 		}
 	}

-- 
2.55.0

