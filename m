From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 16:38:52 +0000
Subject: [PATCH 6/9] soc: rockchip: grf: Restore the RK3588 PHP StreamIDs
 after system suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-mmu600-php-v1-6-231196049a3b@gmail.com>
References: <20261113-mmu600-php-v1-0-231196049a3b@gmail.com>
In-Reply-To: <20261113-mmu600-php-v1-0-231196049a3b@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 David Wu <david.wu@rock-chips.com>, Damien Le Moal <dlemoal@kernel.org>, 
 Niklas Cassel <cassel@kernel.org>, Serge Semin <fancer.lancer@gmail.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-ide@vger.kernel.org, 
 Pranjal Shrivastava <praan@google.com>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, iommu@lists.linux.dev, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794587927; l=4304;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=8DHxrdJD0UZC+IKdgFQ4M91V4d4tnm4LzFVvQpurqQ8=;
 b=GzdbBcBqkmweKHxzPMHYCQmzb/0EhrQfQeUy7omA/fOWzOpjrySHDiBSJZ5bKGW+RMYdB5mh4
 sVBH3JfCdxsDg4tUJW2JgSC3e8R+FVlidea/9CWZhPjofvxhrNIe8D/
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PHP GRF is in PD_PHP, which firmware may power off in system
suspend. The SMMU aborts a master whose StreamID was lost.

Write the StreamIDs again from a syscore resume op, before devices
resume. Register it only when the node has a clock, as the access hangs
without it.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/soc/rockchip/grf.c | 70 ++++++++++++++++++++++++++++++++++++++++++++--
 1 file changed, 68 insertions(+), 2 deletions(-)

diff --git a/drivers/soc/rockchip/grf.c b/drivers/soc/rockchip/grf.c
index 3f0f82a2119f..8f318ebc14e9 100644
--- a/drivers/soc/rockchip/grf.c
+++ b/drivers/soc/rockchip/grf.c
@@ -11,6 +11,8 @@
 #include <linux/of.h>
 #include <linux/platform_device.h>
 #include <linux/regmap.h>
+#include <linux/slab.h>
+#include <linux/syscore_ops.h>
 
 
 struct rockchip_grf_value {
@@ -22,6 +24,14 @@ struct rockchip_grf_value {
 struct rockchip_grf_info {
 	const struct rockchip_grf_value *values;
 	int num_values;
+	/* Rewrite the values on resume; such tables must not be __initconst */
+	bool restore_on_resume;
+};
+
+struct rockchip_grf_restore {
+	struct syscore syscore;
+	struct regmap *grf;
+	const struct rockchip_grf_info *info;
 };
 
 #define RK3036_GRF_SOC_CON0		0x140
@@ -182,7 +192,7 @@ static const struct rockchip_grf_info rk3588_sysgrf __initconst = {
 #define RK3588_PHP_GRF_USB3OTG2_SID_AR	0x00c4
 #define RK3588_PHP_GRF_USB3OTG2_SID_AW	0x00cc
 
-static const struct rockchip_grf_value rk3588_defaults_php_grf[] __initconst = {
+static const struct rockchip_grf_value rk3588_defaults_php_grf[] = {
 	{ "gmac0 write streamid", RK3588_PHP_GRF_GMAC0_SID_AW, 1 },
 	{ "gmac0 read streamid", RK3588_PHP_GRF_GMAC0_SID_AR, 1 },
 	{ "gmac1 write streamid", RK3588_PHP_GRF_GMAC1_SID_AW, 2 },
@@ -197,9 +207,10 @@ static const struct rockchip_grf_value rk3588_defaults_php_grf[] __initconst = {
 	{ "usb3otg2 read streamid", RK3588_PHP_GRF_USB3OTG2_SID_AR, 6 },
 };
 
-static const struct rockchip_grf_info rk3588_phpgrf __initconst = {
+static const struct rockchip_grf_info rk3588_phpgrf = {
 	.values = rk3588_defaults_php_grf,
 	.num_values = ARRAY_SIZE(rk3588_defaults_php_grf),
+	.restore_on_resume = true,
 };
 
 static const struct of_device_id rockchip_grf_dt_match[] __initconst = {
@@ -246,6 +257,59 @@ static const struct of_device_id rockchip_grf_dt_match[] __initconst = {
 	{ /* sentinel */ },
 };
 
+/* Syscore op: runs before the SMMU and its masters resume */
+static void rockchip_grf_resume(void *data)
+{
+	struct rockchip_grf_restore *restore = data;
+	const struct rockchip_grf_info *info = restore->info;
+	unsigned int cur;
+	int i, lost = 0;
+
+	for (i = 0; i < info->num_values; i++) {
+		const struct rockchip_grf_value *val = &info->values[i];
+
+		if (!regmap_read(restore->grf, val->reg, &cur) && cur == val->val)
+			continue;
+
+		lost++;
+		if (regmap_write(restore->grf, val->reg, val->val))
+			pr_err("%s: restoring %s in %#6x failed\n", __func__,
+			       val->desc, val->reg);
+	}
+
+	if (lost)
+		pr_info("%s: restored %d of %d values lost in suspend\n",
+			__func__, lost, info->num_values);
+}
+
+static const struct syscore_ops rockchip_grf_syscore_ops = {
+	.resume = rockchip_grf_resume,
+};
+
+static void __init rockchip_grf_register_restore(struct device_node *np,
+						 struct regmap *grf,
+						 const struct rockchip_grf_info *info)
+{
+	struct rockchip_grf_restore *restore;
+
+	if (!IS_ENABLED(CONFIG_PM_SLEEP) || !info->restore_on_resume)
+		return;
+
+	/* Without its bus clock the GRF is not accessible in syscore resume */
+	if (!of_property_present(np, "clocks"))
+		return;
+
+	restore = kzalloc_obj(*restore);
+	if (!restore)
+		return;
+
+	restore->grf = grf;
+	restore->info = info;
+	restore->syscore.ops = &rockchip_grf_syscore_ops;
+	restore->syscore.data = restore;
+	register_syscore(&restore->syscore);
+}
+
 static int __init rockchip_grf_init(void)
 {
 	const struct rockchip_grf_info *grf_info;
@@ -282,6 +346,8 @@ static int __init rockchip_grf_init(void)
 				pr_err("%s: write to %#6x failed with %d\n",
 					__func__, val->reg, ret);
 		}
+
+		rockchip_grf_register_restore(np, grf, grf_info);
 	}
 
 	return 0;

-- 
2.55.0

