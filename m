From: Cunhao Lu <1579567540@qq.com>
Date: Thu, 22 Oct 2026 00:11:21 +0800
Subject: [PATCH 24/27] mmc: dw_mmc-rockchip: Keep RK3572 NVM domain powered
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-add-board-ok3572-c-v1-24-0b0fd85a31ee@qq.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792599138; l=2194;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=3PU9hSe/SMk7DBdg0xf4xauSWrjq1Nz1yuJVCXM3AuM=;
 b=F8VlQQXXXNczwtESOy5RD1fLR2o2T1P1xaFISpXna6qy9gK+Nv97fAEV0tPYcJpVPqhMJ72/i
 Vvc390n0/atAb9P5zCJiO6A21b9yqanXUk0GsKPdEjNs1+rSq2/UdJr
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Power cycling the RK3572 NVM domain causes repeated SD recovery. Keep it
powered during runtime suspend without disabling controller runtime PM.

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
 drivers/mmc/host/dw_mmc-rockchip.c | 24 ++++++++++++++++++++++++
 1 file changed, 24 insertions(+)

diff --git a/drivers/mmc/host/dw_mmc-rockchip.c b/drivers/mmc/host/dw_mmc-rockchip.c
index 75c82ff20f177..8bc55d4b996c6 100644
--- a/drivers/mmc/host/dw_mmc-rockchip.c
+++ b/drivers/mmc/host/dw_mmc-rockchip.c
@@ -10,6 +10,7 @@
 #include <linux/mmc/host.h>
 #include <linux/of_address.h>
 #include <linux/mmc/slot-gpio.h>
+#include <linux/pm_domain.h>
 #include <linux/pm_runtime.h>
 #include <linux/slab.h>
 
@@ -528,6 +529,19 @@ static int dw_mci_rockchip_init(struct dw_mci *host)
 	return 0;
 }
 
+static int dw_mci_rk3572_init(struct dw_mci *host)
+{
+	int ret;
+
+	/* Power cycling the NVM domain disrupts SDMMC recovery. */
+	ret = dev_pm_genpd_rpm_always_on(host->dev, true);
+	if (ret && ret != -EOPNOTSUPP)
+		dev_warn(host->dev, "failed to keep power domain on: %pe\n",
+			 ERR_PTR(ret));
+
+	return dw_mci_rockchip_init(host);
+}
+
 static const struct dw_mci_drv_data rk2928_drv_data = {
 	.init			= dw_mci_rockchip_init,
 	.parse_dt		= dw_mci_rk2928_parse_dt,
@@ -541,6 +555,14 @@ static const struct dw_mci_drv_data rk3288_drv_data = {
 	.init			= dw_mci_rockchip_init,
 };
 
+static const struct dw_mci_drv_data rk3572_drv_data = {
+	.common_caps		= MMC_CAP_CMD23,
+	.set_ios		= dw_mci_rk3288_set_ios,
+	.execute_tuning		= dw_mci_rk3288_execute_tuning,
+	.parse_dt		= dw_mci_rk3576_parse_dt,
+	.init			= dw_mci_rk3572_init,
+};
+
 static const struct dw_mci_drv_data rk3576_drv_data = {
 	.common_caps		= MMC_CAP_CMD23,
 	.set_ios		= dw_mci_rk3288_set_ios,
@@ -554,6 +576,8 @@ static const struct of_device_id dw_mci_rockchip_match[] = {
 		.data = &rk2928_drv_data },
 	{ .compatible = "rockchip,rk3288-dw-mshc",
 		.data = &rk3288_drv_data },
+	{ .compatible = "rockchip,rk3572-dw-mshc",
+		.data = &rk3572_drv_data },
 	{ .compatible = "rockchip,rk3576-dw-mshc",
 		.data = &rk3576_drv_data },
 	{},

-- 
2.34.1

