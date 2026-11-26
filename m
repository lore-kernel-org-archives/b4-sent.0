From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 10:01:24 +0000
Subject: [PATCH 1/3] pmdomain: rockchip: keep the pm_qos regmap error code
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-pmdomain-rockchip-cleanup-v1-1-a19f5ea7d555@gmail.com>
References: <20261126-pmdomain-rockchip-cleanup-v1-0-a19f5ea7d555@gmail.com>
In-Reply-To: <20261126-pmdomain-rockchip-cleanup-v1-0-a19f5ea7d555@gmail.com>
To: Ulf Hansson <ulfh@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>
Cc: linux-pm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Yao Zi <me@ziyao.cc>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795687283; l=840;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Rr7b7wy7/bWnsPzKpwANzWHGgxRsCm6m0gcZ7iKlZsE=;
 b=Cn5i63RwUAn/ITud+BGQ8dl7zKq5hhKeQ415dPtLhT1AnXObQwTI1NA5Nf6/vtRvnvgcabsJS
 eOygr7BCQyxD8KrZe0fNeKxOdjjI7xBJGfTvckf0T4OC/3+21jCH/JW
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

syscon_node_to_regmap() can return -EPROBE_DEFER. Turning that into
-ENODEV fails the probe instead of deferring it.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/pmdomain/rockchip/pm-domains.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/pmdomain/rockchip/pm-domains.c b/drivers/pmdomain/rockchip/pm-domains.c
index 17a6334b0b9f..b52bdf0e8a19 100644
--- a/drivers/pmdomain/rockchip/pm-domains.c
+++ b/drivers/pmdomain/rockchip/pm-domains.c
@@ -928,7 +928,7 @@ static int rockchip_pm_add_one_domain(struct rockchip_pmu *pmu,
 			pd->qos_regmap[j] = syscon_node_to_regmap(qos_node);
 			of_node_put(qos_node);
 			if (IS_ERR(pd->qos_regmap[j])) {
-				error = -ENODEV;
+				error = PTR_ERR(pd->qos_regmap[j]);
 				goto err_unprepare_clocks;
 			}
 		}

-- 
2.55.0

