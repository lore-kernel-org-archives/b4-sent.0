From: Cunhao Lu <1579567540@qq.com>
Date: Wed, 04 Nov 2026 16:56:04 +0800
Subject: [PATCH v4 2/2] pmdomain: rockchip: Add RK3572 power domains
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-add-board-ok3572-c-pmdomain-v4-2-15cf8b5a6e59@qq.com>
References: <20261104-add-board-ok3572-c-pmdomain-v4-0-15cf8b5a6e59@qq.com>
In-Reply-To: <20261104-add-board-ok3572-c-pmdomain-v4-0-15cf8b5a6e59@qq.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Elaine Zhang <zhangqing@rock-chips.com>, Ulf Hansson <ulfh@kernel.org>
Cc: Cunhao Lu <1579567540@qq.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793782666; l=17497;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=JQfhBj6q1J531L6LkQoVBaYdKqvOifvcCmE5MpH1qjA=;
 b=UzJGwqq6KqciKTwbQG5sx+TXXPBGcm5kwqqFSTS3NLUUffdgTcdLNdV/hTAIcvGyx2RIOLrFu
 lkNGLOSSxZ4DNbgm710eRJMzXq640VXRWHSmivjxPOPz2vOKd8KwdFf
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the RK3572 PMU register layout and all 14 power domains, including
bus idle requests, memory power controls and firmware shift-ready checks.
Control the NPU voltage domain around power transitions. Keep boot-enabled
IMG, VOP, VOP_PRE and VO domains powered until genpd releases startup
protection after their consumers have probed.

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
Changes in v4:
- Drop generic pending-state tracking and power-off recovery; reuse the
  separate power-on rollback fix for firmware readiness errors.
- Support all 14 domains, including NPU voltage-domain control and
  cleanup after failed transitions.
- Retain boot-enabled IMG, VOP, VOP_PRE and VO domains until sync_state.
- Use firmware shift-ready naming for the GRF status.
- Build ungate write masks with unsigned arithmetic.

Changes in v3:
- Track incomplete shutdowns to preserve QoS and complete firmware updates.
- Preserve pending memory resets across shutdown and cancel unfinished
  power-on requests.
- Attempt to restore the domain after power-off errors, while preserving
  the original error returned to genpd.

Changes in v2:
- Record low-level power-on and restoration stages before hardware
  operations, so a retry cannot skip unfinished low-level work.
- Retain pending memory resets even if memory is off on retry, and
  avoid repeating completed resets during restoration.
- Preserve QoS snapshots across failed power-on and shutdown; clear
  progress after successful power-on or shutdown.

---

References:

Finley Xiao: RK3572 power-domain support
https://github.com/rockchip-linux/kernel/commit/ac06def92d0abb61f5262b9c099831802cd90ef2

Finley Xiao: IMG startup protection
https://github.com/rockchip-linux/kernel/commit/71cc8905484f2a3a9fae4562fbd5f2d1fa31fa4c

Finley Xiao: delayed release of startup protection
https://github.com/rockchip-linux/kernel/commit/c7709ff2668a4ce3813f4df838743af562568150

---

FAQ:

Q: Can a failed power-off still overwrite saved QoS or leave the NIU idle?

A: A shutdown retry while the domain still reads ON saves QoS again and
   can replace the earlier snapshot with unrestored values. After failed
   power-off, genpd retains its ON state and normally skips the driver's
   power-on callback on resume, so the NIU can remain idle. These failures
   predate this series. Changing the driver's early-return condition alone
   cannot repair a callback that genpd does not invoke; shared shutdown
   recovery needs a separate design.

Q: Can a delayed power-off still miss the firmware notification?

A: If polling times out before the OFF SMC and hardware completes the
   request later, a retry can observe OFF and return without notifying
   firmware. Rollback can also time out before its OFF notification.
   The shared path has no record of this unfinished notification. Handling
   it requires completion tracking independent of the sampled power state;
   the RK3572 support patch does not provide that shared recovery mechanism.

Q: What remains after a low-level power-on or memory-reset timeout?

A: A PMU ON request can still complete after its polling timeout, and an
   interrupted memory reset can leave the memory force-off bit set. A
   retry that observes the domain ON returns before idle exit, firmware
   readiness polling and QoS restore. genpd records OFF after failed
   power-on and normally does not issue the direct OFF callback assumed
   in the v2 review. Removing the pending-state fields removes that
   bookkeeping failure, but does not fix these underlying failures.
   Recovery needs to account for unfinished requests and memory resets;
   a sampled power-state bit does not establish their completion. The
   shared low-level error handling is retained pending that recovery work.

Q: Can failed rollback still leave hardware ON while genpd records OFF?

A: If rollback cannot idle or power off the domain, the original error is
   returned and transition clocks are released. The power-on wrapper also
   drops the supply reference where configured, and genpd may undo parent
   power-on while the child remains powered. The new firmware wait can
   reach this failure path too. NPU VD is retained while the domain reads
   ON, but this does not protect its external supply or parent.
   RK3572's domain table does not set need_regulator; the supply-reference
   case applies to domains configured to use that shared path. Persistent
   fault isolation and safe retry require a shared resource-lifetime and
   genpd recovery policy, which this series does not implement.

Link: https://sashiko.dev/#/patchset/20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com?part=10
Link: https://sashiko.dev/#/patchset/20261023-add-board-ok3572-c-pmdomain-v2-0-79ddd42e92c1@qq.com?part=2
Link: https://sashiko.dev/#/patchset/20261026-add-board-ok3572-c-pmdomain-v3-0-70d614d3d921@qq.com?part=2
---
 drivers/pmdomain/rockchip/pm-domains.c | 168 ++++++++++++++++++++++++++++++---
 1 file changed, 157 insertions(+), 11 deletions(-)

diff --git a/drivers/pmdomain/rockchip/pm-domains.c b/drivers/pmdomain/rockchip/pm-domains.c
index 170f140601d0..32f6fed1ffcc 100644
--- a/drivers/pmdomain/rockchip/pm-domains.c
+++ b/drivers/pmdomain/rockchip/pm-domains.c
@@ -39,6 +39,7 @@
 #include <dt-bindings/power/rockchip,rk3528-power.h>
 #include <dt-bindings/power/rockchip,rk3562-power.h>
 #include <dt-bindings/power/rk3568-power.h>
+#include <dt-bindings/power/rockchip,rk3572-power-controller.h>
 #include <dt-bindings/power/rockchip,rk3576-power.h>
 #include <dt-bindings/power/rk3588-power.h>
 
@@ -49,25 +50,34 @@ struct rockchip_domain_info {
 	int req_mask;
 	int idle_mask;
 	int ack_mask;
+	bool vd_en;
 	bool active_wakeup;
+	bool keepon_startup;
 	bool need_regulator;
 	int pwr_w_mask;
 	int req_w_mask;
 	int clk_ungate_mask;
 	int mem_status_mask;
 	int repair_status_mask;
+	u32 fw_mask;
 	u32 pwr_offset;
 	u32 mem_offset;
 	u32 req_offset;
+	u32 status_offset;
+	u32 clk_ungate_offset;
 };
 
 struct rockchip_pmu_info {
+	bool chain_status_inverted;
+
+	u32 vd_offset;
 	u32 pwr_offset;
 	u32 status_offset;
 	u32 req_offset;
 	u32 idle_offset;
 	u32 ack_offset;
 	u32 mem_pwr_offset;
+	u32 fw_status_offset;
 	u32 chain_status_offset;
 	u32 mem_status_offset;
 	u32 repair_status_offset;
@@ -105,6 +115,7 @@ struct rockchip_pm_domain {
 
 struct rockchip_pmu {
 	struct device *dev;
+	struct regmap *grf;
 	struct regmap *regmap;
 	const struct rockchip_pmu_info *info;
 	struct mutex mutex; /* mutex lock for pmu */
@@ -258,6 +269,35 @@ struct rockchip_pmu {
 #define DOMAIN_RK3568(name, pwr, req, wakeup, regulator)		\
 	DOMAIN_M_R(name, pwr, pwr, req, req, req, wakeup, regulator)
 
+#define DOMAIN_RK3572_FLAGS(_name, p_offset, pwr, status, repair, r_offset, req, vd, fw, keepon) \
+{							\
+	.name = _name,					\
+	.pwr_offset = p_offset,				\
+	.pwr_mask = (pwr),				\
+	.pwr_w_mask = (pwr) << 16,			\
+	.status_mask = (status),				\
+	.mem_offset = p_offset,				\
+	.mem_status_mask = (pwr),				\
+	.repair_status_mask = (repair),			\
+	.req_offset = r_offset,				\
+	.req_mask = (req),				\
+	.req_w_mask = (req) << 16,			\
+	.status_offset = r_offset,			\
+	.idle_mask = (req),				\
+	.ack_mask = (req),				\
+	.clk_ungate_offset = r_offset,			\
+	.clk_ungate_mask = (req),				\
+	.vd_en = vd,					\
+	.fw_mask = (fw),					\
+	.keepon_startup = keepon,				\
+}
+
+#define DOMAIN_RK3572(name, p_offset, pwr, status, repair, r_offset, req, vd, fw) \
+	DOMAIN_RK3572_FLAGS(name, p_offset, pwr, status, repair, r_offset, req, vd, fw, false)
+
+#define DOMAIN_RK3572_P(name, p_offset, pwr, status, repair, r_offset, req, vd, fw) \
+	DOMAIN_RK3572_FLAGS(name, p_offset, pwr, status, repair, r_offset, req, vd, fw, true)
+
 #define DOMAIN_RK3576(name, p_offset, pwr, status, r_status, r_offset, req, idle, g_mask, wakeup)	\
 	DOMAIN_M_O_R_G(name, p_offset, pwr, status, 0, r_status, r_status, r_offset, req, idle, idle, g_mask, wakeup)
 
@@ -373,15 +413,16 @@ static bool rockchip_pmu_domain_is_idle(struct rockchip_pm_domain *pd)
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
 
@@ -390,7 +431,7 @@ static int rockchip_pmu_ungate_clk(struct rockchip_pm_domain *pd, bool ungate)
 	const struct rockchip_domain_info *pd_info = pd->info;
 	struct rockchip_pmu *pmu = pd->pmu;
 	unsigned int val;
-	int clk_ungate_w_mask = pd_info->clk_ungate_mask << 16;
+	u32 clk_ungate_w_mask = (u32)pd_info->clk_ungate_mask << 16;
 
 	if (!pd_info->clk_ungate_mask)
 		return 0;
@@ -400,7 +441,8 @@ static int rockchip_pmu_ungate_clk(struct rockchip_pm_domain *pd, bool ungate)
 
 	val = ungate ? (pd_info->clk_ungate_mask | clk_ungate_w_mask) :
 			clk_ungate_w_mask;
-	regmap_write(pmu->regmap, pmu->info->clk_ungate_offset, val);
+	regmap_write(pmu->regmap,
+		     pmu->info->clk_ungate_offset + pd_info->clk_ungate_offset, val);
 
 	return 0;
 }
@@ -429,9 +471,8 @@ static int rockchip_pmu_set_idle_request(struct rockchip_pm_domain *pd,
 
 	wmb();
 
-	/* Wait util idle_ack = 1 */
 	target_ack = idle ? pd_info->ack_mask : 0;
-	ret = readx_poll_timeout_atomic(rockchip_pmu_read_ack, pmu, val,
+	ret = readx_poll_timeout_atomic(rockchip_pmu_read_ack, pd, val,
 					(val & pd_info->ack_mask) == target_ack,
 					0, 10000);
 	if (ret) {
@@ -543,6 +584,9 @@ static bool rockchip_pmu_domain_is_chain_on(struct rockchip_pm_domain *pd)
 	regmap_read(pmu->regmap,
 		    pmu->info->chain_status_offset + pd->info->mem_offset, &val);
 
+	if (pmu->info->chain_status_inverted)
+		return !(val & pd->info->mem_status_mask);
+
 	/* 1'b1: power on, 1'b0: power off */
 	return val & pd->info->mem_status_mask;
 }
@@ -667,9 +711,37 @@ static void rockchip_pd_power_on_rollback(struct rockchip_pm_domain *pd)
 			pd->genpd.name, ret);
 }
 
+static void rockchip_pmu_vd_on(struct rockchip_pm_domain *pd, bool on)
+{
+	const struct rockchip_domain_info *pd_info = pd->info;
+	struct rockchip_pmu *pmu = pd->pmu;
+	unsigned int val;
+
+	if (!pd_info->vd_en)
+		return;
+
+	val = on ? pd_info->pwr_w_mask : pd_info->pwr_mask | pd_info->pwr_w_mask;
+	regmap_write(pmu->regmap, pmu->info->vd_offset + pd_info->pwr_offset, val);
+}
+
+static int rockchip_pmu_wait_fw_shift_ready(struct rockchip_pm_domain *pd)
+{
+	struct rockchip_pmu *pmu = pd->pmu;
+	u32 mask = pd->info->fw_mask;
+	unsigned int val;
+
+	if (!mask)
+		return 0;
+
+	return regmap_read_poll_timeout(pmu->grf, pmu->info->fw_status_offset,
+				       val, (val & mask) == mask, 0, 10000);
+}
+
 static int rockchip_pd_power(struct rockchip_pm_domain *pd, bool power_on)
 {
 	struct rockchip_pmu *pmu = pd->pmu;
+	bool vd_was_on = false;
+	unsigned int val;
 	int ret;
 
 	guard(mutex)(&pmu->mutex);
@@ -677,9 +749,21 @@ static int rockchip_pd_power(struct rockchip_pm_domain *pd, bool power_on)
 	if (rockchip_pmu_domain_is_on(pd) == power_on)
 		return 0;
 
+	if (power_on && pd->info->vd_en) {
+		ret = regmap_read(pmu->regmap,
+				  pmu->info->vd_offset + pd->info->pwr_offset, &val);
+		if (ret)
+			return ret;
+		vd_was_on = !(val & pd->info->pwr_mask);
+		rockchip_pmu_vd_on(pd, true);
+	}
+
 	ret = clk_bulk_enable(pd->num_clks, pd->clks);
 	if (ret < 0) {
 		dev_err(pmu->dev, "failed to enable clocks\n");
+		/* Preserve a VD request retained by an earlier failed attempt. */
+		if (power_on && !vd_was_on)
+			rockchip_pmu_vd_on(pd, false);
 		return ret;
 	}
 
@@ -694,6 +778,7 @@ static int rockchip_pd_power(struct rockchip_pm_domain *pd, bool power_on)
 			goto out;
 	}
 
+	/* A timed-out power-on request may still complete, so keep VD on. */
 	ret = rockchip_do_pmu_set_power_domain(pd, power_on);
 	if (ret < 0)
 		goto out;
@@ -701,13 +786,26 @@ static int rockchip_pd_power(struct rockchip_pm_domain *pd, bool power_on)
 	if (power_on) {
 		/* if powering up, leave idle mode */
 		ret = rockchip_pmu_set_idle_request(pd, false);
-		if (ret < 0) {
-			rockchip_pd_power_on_rollback(pd);
-			goto out;
+		if (ret < 0)
+			goto rollback;
+
+		ret = rockchip_pmu_wait_fw_shift_ready(pd);
+		if (ret) {
+			dev_err(pmu->dev, "failed to get firmware ready for domain '%s': %d\n",
+				pd->genpd.name, ret);
+			goto rollback;
 		}
 
 		rockchip_pmu_restore_qos(pd);
+	} else {
+		rockchip_pmu_vd_on(pd, false);
 	}
+	goto out;
+
+rollback:
+	rockchip_pd_power_on_rollback(pd);
+	if (pd->info->vd_en && !rockchip_pmu_domain_is_on(pd))
+		rockchip_pmu_vd_on(pd, false);
 
 out:
 	rockchip_pmu_ungate_clk(pd, false);
@@ -943,7 +1041,9 @@ static int rockchip_pm_add_one_domain(struct rockchip_pmu *pmu,
 	pd->genpd.power_on = rockchip_pd_power_on;
 	pd->genpd.attach_dev = rockchip_pd_attach_dev;
 	pd->genpd.detach_dev = rockchip_pd_detach_dev;
-	pd->genpd.flags = GENPD_FLAG_PM_CLK | GENPD_FLAG_NO_STAY_ON;
+	pd->genpd.flags = GENPD_FLAG_PM_CLK;
+	if (!pd_info->keepon_startup)
+		pd->genpd.flags |= GENPD_FLAG_NO_STAY_ON;
 	if (pd_info->active_wakeup)
 		pd->genpd.flags |= GENPD_FLAG_ACTIVE_WAKEUP;
 	pm_genpd_init(&pd->genpd, NULL,
@@ -1089,6 +1189,12 @@ static int rockchip_pm_domain_probe(struct platform_device *pdev)
 	mutex_init(&pmu->mutex);
 
 	pmu->info = pmu_info;
+	if (pmu_info->fw_status_offset) {
+		pmu->grf = syscon_regmap_lookup_by_phandle(np, "rockchip,grf");
+		if (IS_ERR(pmu->grf))
+			return dev_err_probe(dev, PTR_ERR(pmu->grf),
+					     "failed to get system GRF\n");
+	}
 
 	pmu->genpd_data.domains = pmu->domains;
 	pmu->genpd_data.num_domains = pmu_info->num_domains;
@@ -1338,6 +1444,23 @@ static const struct rockchip_domain_info rk3568_pm_domains[] = {
 	[RK3568_PD_PIPE]	= DOMAIN_RK3568("pipe", BIT(8), BIT(11), false, false),
 };
 
+static const struct rockchip_domain_info rk3572_pm_domains[] = {
+	[RK3572_PD_NVM1]	= DOMAIN_RK3572("nvm1",      0x0, BIT(4),  0,      BIT(3),  0x0, BIT(6),  false, 0),
+	[RK3572_PD_DSMC]	= DOMAIN_RK3572("dsmc",      0x0, BIT(5),  BIT(5), 0,       0x0, BIT(7),  false, 0),
+	[RK3572_PD_AUDIO]	= DOMAIN_RK3572("audio",     0x0, BIT(6),  0,      BIT(4),  0x0, BIT(8),  false, 0),
+	[RK3572_PD_PHP]		= DOMAIN_RK3572("php",       0x0, BIT(7),  0,      BIT(5),  0x0, BIT(9),  false, BIT(28)),
+	[RK3572_PD_VDEC]	= DOMAIN_RK3572("vdec",      0x0, BIT(8),  0,      BIT(6),  0x0, BIT(10), false, 0),
+	[RK3572_PD_IMG]		= DOMAIN_RK3572_P("img",     0x0, BIT(9),  0,      BIT(7),  0x0, BIT(11), false, 0),
+	[RK3572_PD_VI]		= DOMAIN_RK3572("vi",        0x0, BIT(10), 0,      BIT(8),  0x0, BIT(12), false, 0),
+	[RK3572_PD_VENC]	= DOMAIN_RK3572("venc",      0x0, BIT(11), 0,      BIT(9),  0x0, BIT(13), false, 0),
+	[RK3572_PD_VOP]		= DOMAIN_RK3572_P("vop",     0x0, BIT(12), 0,      BIT(10), 0x0, BIT(14), false, BIT(23)),
+	[RK3572_PD_VOP_PRE]	= DOMAIN_RK3572_P("vop_pre", 0x0, BIT(13), 0,      BIT(11), 0x0, 0,       false, 0),
+	[RK3572_PD_VO]		= DOMAIN_RK3572_P("vo",      0x0, BIT(14), 0,      BIT(12), 0x0, BIT(15), false, 0),
+	[RK3572_PD_NVM0]	= DOMAIN_RK3572("nvm0",      0x0, BIT(15), 0,      BIT(13), 0x4, BIT(0),  false, 0),
+	[RK3572_PD_NPU]		= DOMAIN_RK3572("npu",       0x4, BIT(1),  0,      BIT(14), 0x4, BIT(2),  true,  BIT(27)),
+	[RK3572_PD_GPU]		= DOMAIN_RK3572("gpu",       0x4, BIT(2),  0,      BIT(15), 0x4, BIT(3),  false, BIT(29)),
+};
+
 static const struct rockchip_domain_info rk3576_pm_domains[] = {
 	[RK3576_PD_NPU]		= DOMAIN_RK3576("npu",    0x0, BIT(0),  BIT(0), 0,       0x0, 0,       0,       0,       false),
 	[RK3576_PD_NVM]		= DOMAIN_RK3576("nvm",    0x0, BIT(6),  0,      BIT(6),  0x4, BIT(2),  BIT(18), BIT(2),  false),
@@ -1561,6 +1684,25 @@ static const struct rockchip_pmu_info rk3568_pmu = {
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
+	.vd_offset = 0x220,
+	.fw_status_offset = 0x140,
+
+	.num_domains = ARRAY_SIZE(rk3572_pm_domains),
+	.domain_info = rk3572_pm_domains,
+};
+
 static const struct rockchip_pmu_info rk3576_pmu = {
 	.pwr_offset = 0x210,
 	.status_offset = 0x230,
@@ -1672,6 +1814,10 @@ static const struct of_device_id rockchip_pm_domain_dt_match[] = {
 		.compatible = "rockchip,rk3568-power-controller",
 		.data = (void *)&rk3568_pmu,
 	},
+	{
+		.compatible = "rockchip,rk3572-power-controller",
+		.data = (void *)&rk3572_pmu,
+	},
 	{
 		.compatible = "rockchip,rk3576-power-controller",
 		.data = (void *)&rk3576_pmu,

-- 
2.34.1

