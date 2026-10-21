From: Cunhao Lu <1579567540@qq.com>
Date: Thu, 22 Oct 2026 00:11:07 +0800
Subject: [PATCH 10/27] pmdomain: rockchip: Add RK3572 boot peripheral
 domains
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-add-board-ok3572-c-v1-10-0b0fd85a31ee@qq.com>
References: <20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com>
In-Reply-To: <20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com>
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Elaine Zhang <zhangqing@rock-chips.com>, Lee Jones <lee@kernel.org>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Richard Cochran <richardcochran@gmail.com>, Ulf Hansson <ulfh@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Jisheng Zhang <jszhang@kernel.org>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 David Wu <david.wu@rock-chips.com>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, 
 Shawn Lin <shawn.lin@rock-chips.com>
Cc: Cunhao Lu <1579567540@qq.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 mfd@lists.linux.dev, linux-gpio@vger.kernel.org, netdev@vger.kernel.org, 
 linux-pm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-serial@vger.kernel.org, linux-mmc@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, linux-phy@lists.infradead.org, 
 linux-usb@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792599138; l=9125;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=OcoLzubR+q6LA4Mp8RFJ2dcJWa6HZEI/3F0zWmoWW+Y=;
 b=31DndXn+l9vraEjbkUVK1hHT383BRrksW+mizMDtg7mJ97WqryA318Mlr8GICWwn4BqGXTRsO
 QsCzMX2gm5GBpGf0KSFuezb2rS5FvA6AX4uXHuMboLk7fKU4sye0DUz
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the NVM0, NVM1, PHP, and VOP power domains. Wait for the GRF firewall
before restoring consumers and retry power-on failures without cycling
the domain again.

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
 drivers/pmdomain/rockchip/pm-domains.c | 141 ++++++++++++++++++++++++++++++---
 1 file changed, 131 insertions(+), 10 deletions(-)

diff --git a/drivers/pmdomain/rockchip/pm-domains.c b/drivers/pmdomain/rockchip/pm-domains.c
index e193f978d5f3..86a6ffd43254 100644
--- a/drivers/pmdomain/rockchip/pm-domains.c
+++ b/drivers/pmdomain/rockchip/pm-domains.c
@@ -39,6 +39,7 @@
 #include <dt-bindings/power/rockchip,rk3528-power.h>
 #include <dt-bindings/power/rockchip,rk3562-power.h>
 #include <dt-bindings/power/rk3568-power.h>
+#include <dt-bindings/power/rockchip,rk3572-power-controller.h>
 #include <dt-bindings/power/rockchip,rk3576-power.h>
 #include <dt-bindings/power/rk3588-power.h>
 
@@ -59,6 +60,9 @@ struct rockchip_domain_info {
 	u32 pwr_offset;
 	u32 mem_offset;
 	u32 req_offset;
+	u32 status_offset;
+	u32 firewall_mask;
+	u32 clk_ungate_offset;
 };
 
 struct rockchip_pmu_info {
@@ -72,6 +76,8 @@ struct rockchip_pmu_info {
 	u32 mem_status_offset;
 	u32 repair_status_offset;
 	u32 clk_ungate_offset;
+	u32 firewall_status_offset;
+	bool chain_status_inverted;
 
 	u32 core_pwrcnt_offset;
 	u32 gpu_pwrcnt_offset;
@@ -101,11 +107,13 @@ struct rockchip_pm_domain {
 	struct clk_bulk_data *clks;
 	struct device_node *node;
 	struct regulator *supply;
+	bool power_on_pending;
 };
 
 struct rockchip_pmu {
 	struct device *dev;
 	struct regmap *regmap;
+	struct regmap *grf;
 	const struct rockchip_pmu_info *info;
 	struct mutex mutex; /* mutex lock for pmu */
 	struct genpd_onecell_data genpd_data;
@@ -373,15 +381,16 @@ static bool rockchip_pmu_domain_is_idle(struct rockchip_pm_domain *pd)
 	const struct rockchip_domain_info *pd_info = pd->info;
 	unsigned int val;
 
-	regmap_read(pmu->regmap, pmu->info->idle_offset, &val);
+	regmap_read(pmu->regmap, pmu->info->idle_offset + pd_info->status_offset, &val);
 	return (val & pd_info->idle_mask) == pd_info->idle_mask;
 }
 
-static unsigned int rockchip_pmu_read_ack(struct rockchip_pmu *pmu)
+static unsigned int rockchip_pmu_read_ack(struct rockchip_pm_domain *pd)
 {
+	struct rockchip_pmu *pmu = pd->pmu;
 	unsigned int val;
 
-	regmap_read(pmu->regmap, pmu->info->ack_offset, &val);
+	regmap_read(pmu->regmap, pmu->info->ack_offset + pd->info->status_offset, &val);
 	return val;
 }
 
@@ -400,7 +409,8 @@ static int rockchip_pmu_ungate_clk(struct rockchip_pm_domain *pd, bool ungate)
 
 	val = ungate ? (pd_info->clk_ungate_mask | clk_ungate_w_mask) :
 			clk_ungate_w_mask;
-	regmap_write(pmu->regmap, pmu->info->clk_ungate_offset, val);
+	regmap_write(pmu->regmap, pmu->info->clk_ungate_offset +
+		     pd_info->clk_ungate_offset, val);
 
 	return 0;
 }
@@ -431,7 +441,7 @@ static int rockchip_pmu_set_idle_request(struct rockchip_pm_domain *pd,
 
 	/* Wait util idle_ack = 1 */
 	target_ack = idle ? pd_info->ack_mask : 0;
-	ret = readx_poll_timeout_atomic(rockchip_pmu_read_ack, pmu, val,
+	ret = readx_poll_timeout_atomic(rockchip_pmu_read_ack, pd, val,
 					(val & pd_info->ack_mask) == target_ack,
 					0, 10000);
 	if (ret) {
@@ -543,6 +553,9 @@ static bool rockchip_pmu_domain_is_chain_on(struct rockchip_pm_domain *pd)
 	regmap_read(pmu->regmap,
 		    pmu->info->chain_status_offset + pd->info->mem_offset, &val);
 
+	if (pmu->info->chain_status_inverted)
+		return !(val & pd->info->mem_status_mask);
+
 	/* 1'b1: power on, 1'b0: power off */
 	return val & pd->info->mem_status_mask;
 }
@@ -644,14 +657,29 @@ static int rockchip_do_pmu_set_power_domain(struct rockchip_pm_domain *pd,
 	return 0;
 }
 
+static int rockchip_pmu_wait_firewall(struct rockchip_pm_domain *pd)
+{
+	struct rockchip_pmu *pmu = pd->pmu;
+	u32 mask = pd->info->firewall_mask;
+	u32 val;
+
+	if (!mask)
+		return 0;
+
+	return regmap_read_poll_timeout(pmu->grf, pmu->info->firewall_status_offset,
+				       val, (val & mask) == mask, 0, 10000);
+}
+
 static int rockchip_pd_power(struct rockchip_pm_domain *pd, bool power_on)
 {
 	struct rockchip_pmu *pmu = pd->pmu;
+	bool is_on;
 	int ret;
 
 	guard(mutex)(&pmu->mutex);
 
-	if (rockchip_pmu_domain_is_on(pd) == power_on)
+	is_on = rockchip_pmu_domain_is_on(pd);
+	if (is_on == power_on && !pd->power_on_pending)
 		return 0;
 
 	ret = clk_bulk_enable(pd->num_clks, pd->clks);
@@ -663,7 +691,8 @@ static int rockchip_pd_power(struct rockchip_pm_domain *pd, bool power_on)
 	rockchip_pmu_ungate_clk(pd, true);
 
 	if (!power_on) {
-		rockchip_pmu_save_qos(pd);
+		if (!pd->power_on_pending)
+			rockchip_pmu_save_qos(pd);
 
 		/* if powering down, idle request to NIU first */
 		ret = rockchip_pmu_set_idle_request(pd, true);
@@ -671,18 +700,29 @@ static int rockchip_pd_power(struct rockchip_pm_domain *pd, bool power_on)
 			goto out;
 	}
 
-	ret = rockchip_do_pmu_set_power_domain(pd, power_on);
-	if (ret < 0)
-		goto out;
+	/* A failed firewall wait must not restart powered memory on retry. */
+	if (is_on != power_on) {
+		ret = rockchip_do_pmu_set_power_domain(pd, power_on);
+		if (ret < 0)
+			goto out;
+	}
 
 	if (power_on) {
+		if (pd->info->firewall_mask)
+			pd->power_on_pending = true;
+
 		/* if powering up, leave idle mode */
 		ret = rockchip_pmu_set_idle_request(pd, false);
 		if (ret < 0)
 			goto out;
 
+		ret = rockchip_pmu_wait_firewall(pd);
+		if (ret)
+			goto out;
+
 		rockchip_pmu_restore_qos(pd);
 	}
+	pd->power_on_pending = false;
 
 out:
 	rockchip_pmu_ungate_clk(pd, false);
@@ -1064,6 +1104,11 @@ static int rockchip_pm_domain_probe(struct platform_device *pdev)
 	mutex_init(&pmu->mutex);
 
 	pmu->info = pmu_info;
+	if (pmu_info->firewall_status_offset) {
+		pmu->grf = syscon_regmap_lookup_by_phandle(np, "rockchip,grf");
+		if (IS_ERR(pmu->grf))
+			return dev_err_probe(dev, PTR_ERR(pmu->grf), "failed to get system GRF\n");
+	}
 
 	pmu->genpd_data.domains = pmu->domains;
 	pmu->genpd_data.num_domains = pmu_info->num_domains;
@@ -1313,6 +1358,62 @@ static const struct rockchip_domain_info rk3568_pm_domains[] = {
 	[RK3568_PD_PIPE]	= DOMAIN_RK3568("pipe", BIT(8), BIT(11), false, false),
 };
 
+static const struct rockchip_domain_info rk3572_pm_domains[] = {
+	[RK3572_PD_NVM1] = {
+		.name = "nvm1",
+		.pwr_mask = BIT(4),
+		.pwr_w_mask = BIT(20),
+		.mem_status_mask = BIT(4),
+		.repair_status_mask = BIT(3),
+		.req_mask = BIT(6),
+		.req_w_mask = BIT(22),
+		.idle_mask = BIT(6),
+		.ack_mask = BIT(6),
+		.clk_ungate_mask = BIT(6),
+	},
+	[RK3572_PD_PHP] = {
+		.name = "php",
+		.pwr_mask = BIT(7),
+		.pwr_w_mask = BIT(23),
+		.mem_status_mask = BIT(7),
+		.repair_status_mask = BIT(5),
+		.req_mask = BIT(9),
+		.req_w_mask = BIT(25),
+		.idle_mask = BIT(9),
+		.ack_mask = BIT(9),
+		.clk_ungate_mask = BIT(9),
+		.firewall_mask = BIT(28),
+	},
+	[RK3572_PD_VOP] = {
+		.name = "vop",
+		.pwr_mask = BIT(12),
+		.pwr_w_mask = BIT(28),
+		.mem_status_mask = BIT(12),
+		.repair_status_mask = BIT(10),
+		.req_mask = BIT(14),
+		.req_w_mask = BIT(30),
+		.idle_mask = BIT(14),
+		.ack_mask = BIT(14),
+		.clk_ungate_mask = BIT(14),
+		.firewall_mask = BIT(23),
+	},
+	[RK3572_PD_NVM0] = {
+		.name = "nvm0",
+		.pwr_mask = BIT(15),
+		.pwr_w_mask = BIT(31),
+		.mem_status_mask = BIT(15),
+		.repair_status_mask = BIT(13),
+		.req_mask = BIT(0),
+		.req_w_mask = BIT(16),
+		.idle_mask = BIT(0),
+		.ack_mask = BIT(0),
+		.clk_ungate_mask = BIT(0),
+		.req_offset = 4,
+		.status_offset = 4,
+		.clk_ungate_offset = 4,
+	},
+};
+
 static const struct rockchip_domain_info rk3576_pm_domains[] = {
 	[RK3576_PD_NPU]		= DOMAIN_RK3576("npu",    0x0, BIT(0),  BIT(0), 0,       0x0, 0,       0,       0,       false),
 	[RK3576_PD_NVM]		= DOMAIN_RK3576("nvm",    0x0, BIT(6),  0,      BIT(6),  0x4, BIT(2),  BIT(18), BIT(2),  false),
@@ -1536,6 +1637,23 @@ static const struct rockchip_pmu_info rk3568_pmu = {
 	.domain_info = rk3568_pm_domains,
 };
 
+static const struct rockchip_pmu_info rk3572_pmu = {
+	.pwr_offset = 0x210,
+	.status_offset = 0x230,
+	.chain_status_offset = 0x250,
+	.chain_status_inverted = true,
+	.mem_status_offset = 0x260,
+	.mem_pwr_offset = 0x300,
+	.req_offset = 0x110,
+	.idle_offset = 0x130,
+	.ack_offset = 0x120,
+	.repair_status_offset = 0x570,
+	.clk_ungate_offset = 0x150,
+	.firewall_status_offset = 0x140,
+	.num_domains = ARRAY_SIZE(rk3572_pm_domains),
+	.domain_info = rk3572_pm_domains,
+};
+
 static const struct rockchip_pmu_info rk3576_pmu = {
 	.pwr_offset = 0x210,
 	.status_offset = 0x230,
@@ -1648,6 +1766,9 @@ static const struct of_device_id rockchip_pm_domain_dt_match[] = {
 		.data = (void *)&rk3568_pmu,
 	},
 	{
+		.compatible = "rockchip,rk3572-power-controller",
+		.data = &rk3572_pmu,
+	}, {
 		.compatible = "rockchip,rk3576-power-controller",
 		.data = (void *)&rk3576_pmu,
 	},

-- 
2.34.1

