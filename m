From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 01 Feb 2024 22:05:42 +0800
Subject: [PATCH v2 1/3] mmc: hi6220-dwmmc: handle clocks and resets if
 CONFIG_CLK and CONFIG_DM_RESET enabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240201-mmc-v2-1-9f09dc1335fd@outlook.com>
References: <20240201-mmc-v2-0-9f09dc1335fd@outlook.com>
In-Reply-To: <20240201-mmc-v2-0-9f09dc1335fd@outlook.com>
To: Peng Fan <peng.fan@nxp.com>, Jaehoon Chung <jh80.chung@samsung.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706796342; l=3767;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=ikTybhaviPLpwL/4MV5qP49z5jgH5zt1fBMlk3sX/pU=;
 b=yPuKAhZKzlcNFci8EC4sF7TAU0l+VUy+KT/vf0nDENz18N8Ycc3VTATKP+VRjAqx6owxvvHXN
 eTKMxTZrecXDd0Thp0SW40PfaL9u/kzYnQSBPxjTHlZrJZzMhWKWcSm
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This can avoid hardcoding a clock rate in driver. Also can enable the
clocks and deassert the resets if the pre-bootloader does not do this
for us.

Currently only enabled for Hi3798MV200.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/mmc/hi6220_dw_mmc.c | 61 ++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 60 insertions(+), 1 deletion(-)

diff --git a/drivers/mmc/hi6220_dw_mmc.c b/drivers/mmc/hi6220_dw_mmc.c
index 71962cd47e..a4b8072976 100644
--- a/drivers/mmc/hi6220_dw_mmc.c
+++ b/drivers/mmc/hi6220_dw_mmc.c
@@ -5,15 +5,24 @@
  */
 
 #include <common.h>
+#include <clk.h>
 #include <dm.h>
 #include <dwmmc.h>
 #include <errno.h>
 #include <fdtdec.h>
 #include <malloc.h>
+#include <reset.h>
 #include <asm/global_data.h>
+#include <dm/device_compat.h>
 
 DECLARE_GLOBAL_DATA_PTR;
 
+enum hi6220_dwmmc_clk_type {
+	HI6220_DWMMC_CLK_BIU,
+	HI6220_DWMMC_CLK_CIU,
+	HI6220_DWMMC_CLK_CNT,
+};
+
 struct hi6220_dwmmc_plat {
 	struct mmc_config cfg;
 	struct mmc mmc;
@@ -21,6 +30,8 @@ struct hi6220_dwmmc_plat {
 
 struct hi6220_dwmmc_priv_data {
 	struct dwmci_host host;
+	struct clk *clks[HI6220_DWMMC_CLK_CNT];
+	struct reset_ctl_bulk rsts;
 };
 
 struct hisi_mmc_data {
@@ -32,7 +43,29 @@ static int hi6220_dwmmc_of_to_plat(struct udevice *dev)
 {
 	struct hi6220_dwmmc_priv_data *priv = dev_get_priv(dev);
 	struct dwmci_host *host = &priv->host;
+	int ret;
 
+	if (CONFIG_IS_ENABLED(CLK) && CONFIG_IS_ENABLED(DM_RESET)) {
+		priv->clks[HI6220_DWMMC_CLK_BIU] = devm_clk_get(dev, "biu");
+		if (IS_ERR(priv->clks[HI6220_DWMMC_CLK_BIU])) {
+			ret = PTR_ERR(priv->clks[HI6220_DWMMC_CLK_BIU]);
+			dev_err(dev, "Failed to get BIU clock(ret = %d).\n", ret);
+			return log_msg_ret("clk", ret);
+		}
+
+		priv->clks[HI6220_DWMMC_CLK_CIU] = devm_clk_get(dev, "ciu");
+		if (IS_ERR(priv->clks[HI6220_DWMMC_CLK_CIU])) {
+			ret = PTR_ERR(priv->clks[HI6220_DWMMC_CLK_CIU]);
+			dev_err(dev, "Failed to get CIU clock(ret = %d).\n", ret);
+			return log_msg_ret("clk", ret);
+		}
+
+		ret = reset_get_bulk(dev, &priv->rsts);
+		if (ret) {
+			dev_err(dev, "Failed to get resets(ret = %d)", ret);
+			return log_msg_ret("rst", ret);
+		}
+	}
 	host->name = dev->name;
 	host->ioaddr = dev_read_addr_ptr(dev);
 	host->buswidth = fdtdec_get_int(gd->fdt_blob, dev_of_offset(dev),
@@ -56,11 +89,37 @@ static int hi6220_dwmmc_probe(struct udevice *dev)
 	struct hi6220_dwmmc_priv_data *priv = dev_get_priv(dev);
 	struct dwmci_host *host = &priv->host;
 	struct hisi_mmc_data *mmc_data;
+	int ret;
 
 	mmc_data = (struct hisi_mmc_data *)dev_get_driver_data(dev);
 
-	/* Use default bus speed due to absence of clk driver */
 	host->bus_hz = mmc_data->clock;
+	if (CONFIG_IS_ENABLED(CLK) && CONFIG_IS_ENABLED(DM_RESET)) {
+		ret = clk_prepare_enable(priv->clks[HI6220_DWMMC_CLK_BIU]);
+		if (ret) {
+			dev_err(dev, "Failed to enable biu clock(ret = %d).\n", ret);
+			return log_msg_ret("clk", ret);
+		}
+
+		ret = clk_prepare_enable(priv->clks[HI6220_DWMMC_CLK_CIU]);
+		if (ret) {
+			dev_err(dev, "Failed to enable ciu clock(ret = %d).\n", ret);
+			return log_msg_ret("clk", ret);
+		}
+
+		ret = reset_deassert_bulk(&priv->rsts);
+		if (ret) {
+			dev_err(dev, "Failed to deassert resets(ret = %d).\n", ret);
+			return log_msg_ret("rst", ret);
+		}
+
+		host->bus_hz = clk_get_rate(priv->clks[HI6220_DWMMC_CLK_CIU]);
+		if (host->bus_hz <= 0) {
+			dev_err(dev, "Failed to get ciu clock rate(ret = %d).\n", ret);
+			return log_msg_ret("clk", ret);
+		}
+	}
+	dev_dbg(dev, "bus clock rate: %d.\n", host->bus_hz);
 
 	dwmci_setup_cfg(&plat->cfg, host, host->bus_hz, 400000);
 	host->mmc = &plat->mmc;

-- 
2.43.0

