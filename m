From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:11:28 +0000
Subject: [PATCH 1/3] pmdomain: rockchip: put only the clocks that were got
 on error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-pmdomain-rockchip-v1-1-6b9fa6ebaa86@gmail.com>
References: <20261110-pmdomain-rockchip-v1-0-6b9fa6ebaa86@gmail.com>
In-Reply-To: <20261110-pmdomain-rockchip-v1-0-6b9fa6ebaa86@gmail.com>
To: Ulf Hansson <ulfh@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Kevin Hilman <khilman@linaro.org>, Caesar Wang <wxt@rock-chips.com>, 
 Elaine Zhang <zhangqing@rock-chips.com>
Cc: linux-pm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Pecovnik <igor@armbian.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294687; l=2026;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=AWNB6l2jcN6MKFzvoLZq759tpOEfOEsNFO9JurbdzAQ=;
 b=QHMOwsrRbvV+Aiyiv88LewtSOVi1XCHYN77Ad7CvvDlcYGBdCa3/ygAp6IkD7/C+5oDlFjjQP
 0VE1cTPmxj8DkLfICTZ3ADwT0hxogSj8xwSNuZv7TaJmgf4qpSfzCAv
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Igor Pecovnik <igor@armbian.com>

When of_clk_get() fails for clock i of a power domain,
rockchip_pm_add_one_domain() jumps to err_put_clocks, which calls
clk_bulk_put() on all pd->num_clks entries. That includes the
ERR_PTR() just stored in pd->clks[i] (clk_put() warns on it) and
the NULL entries after it (harmless, clk_put(NULL) is a no-op).

This is hit when a domain clock is not available yet and the probe is
deferred: the first deferral triggers the WARN_ON_ONCE() in __clk_put(),
and the failure is reported with dev_err() instead of being recorded as
the deferral reason shown in devices_deferred.

Put only the i clocks that were obtained, and report the failure with
dev_err_probe().

Fixes: d8b384777066 ("pmdomain: rockchip: fix clock leak on domain probe failure")
Cc: stable@vger.kernel.org
Link: https://github.com/armbian/build/commit/814ab46114eb18832e18d1f94f2d279680a308d7
Signed-off-by: Igor Pecovnik <igor@armbian.com>
[arun: rewrote the commit message for upstream]
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/pmdomain/rockchip/pm-domains.c | 12 +++++++-----
 1 file changed, 7 insertions(+), 5 deletions(-)

diff --git a/drivers/pmdomain/rockchip/pm-domains.c b/drivers/pmdomain/rockchip/pm-domains.c
index 6eca21e0bb12..3b39b231ca0e 100644
--- a/drivers/pmdomain/rockchip/pm-domains.c
+++ b/drivers/pmdomain/rockchip/pm-domains.c
@@ -849,11 +849,13 @@ static int rockchip_pm_add_one_domain(struct rockchip_pmu *pmu,
 	for (i = 0; i < pd->num_clks; i++) {
 		pd->clks[i].clk = of_clk_get(node, i);
 		if (IS_ERR(pd->clks[i].clk)) {
-			error = PTR_ERR(pd->clks[i].clk);
-			dev_err(pmu->dev,
-				"%pOFn: failed to get clk at index %d: %d\n",
-				node, i, error);
-			goto err_put_clocks;
+			error = dev_err_probe(pmu->dev,
+					      PTR_ERR(pd->clks[i].clk),
+					      "%pOFn: failed to get clk at index %d\n",
+					      node, i);
+			/* Only the clocks before index i were got */
+			clk_bulk_put(i, pd->clks);
+			return error;
 		}
 	}
 

-- 
2.55.0

