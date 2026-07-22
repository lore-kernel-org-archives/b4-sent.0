From: Rohan Joshi <rohan1sj@cadence.com>
Date: Wed, 22 Jul 2026 16:18:38 +0530
Subject: [PATCH v3 2/2] mmc: sdhci-cadence: add CQE support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-cdns_sdhci_cqe-support-v3-2-4412856a4488@cadence.com>
References: <20260722-cdns_sdhci_cqe-support-v3-0-4412856a4488@cadence.com>
In-Reply-To: <20260722-cdns_sdhci_cqe-support-v3-0-4412856a4488@cadence.com>
To: Ulf Hansson <ulfh@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Masahiro Yamada <yamada.masahiro@socionext.com>, 
 Adrian Hunter <adrian.hunter@intel.com>
Cc: linux-mmc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, mparab@cadence.com, pawell@cadence.com, 
 sjakhade@cadence.com, mpillai@cadence.com, rohan1sj@cadence.com, 
 razb@mobileye.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784717318; l=6985;
 i=rohan1sj@cadence.com; s=20260406; h=from:subject:message-id;
 bh=TIvygmbfzIhclAgw5h0kIZYKRTzFSS/RgesIZ50ewws=;
 b=Hbrc57Oqvqq2J69S2feO/h2isGE5iRwNWgqwn4QLaDOQsRmu3wmyKMkjEHQYaIMsgjkSMCWrS
 I0Isuj3K5pUCswTZMhbelchfKXF9VqMCZr8bD6dFWScpwWX3W5tQl9U
X-Developer-Key: i=rohan1sj@cadence.com; a=ed25519;
 pk=YuwylizMVlVj8I4+VPMZ6xrFR2wyqJAWZyj90OVZgD0=
X-Endpoint-Received: by B4 Relay for rohan1sj@cadence.com/20260406 with auth_id=723
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Cadence host controller has optional CQE (Command Queue Engine).
The presence of CQE is determined by an additional host capability
register. The same information is used to identify and support all
platforms that contain Command Queue Engine

Signed-off-by: Rohan Joshi <rohan1sj@cadence.com>
---
 drivers/mmc/host/Kconfig         |   1 +
 drivers/mmc/host/sdhci-cadence.c | 124 +++++++++++++++++++++++++++++++++++++--
 2 files changed, 121 insertions(+), 4 deletions(-)

diff --git a/drivers/mmc/host/Kconfig b/drivers/mmc/host/Kconfig
index 4f060d3e5636..2cc8133e8ef3 100644
--- a/drivers/mmc/host/Kconfig
+++ b/drivers/mmc/host/Kconfig
@@ -293,6 +293,7 @@ config MMC_SDHCI_CADENCE
 	depends on MMC_SDHCI_PLTFM
 	depends on OF
 	select MMC_SDHCI_IO_ACCESSORS
+	select MMC_CQHCI
 	help
 	  This selects the Cadence SD/SDIO/eMMC driver.
 
diff --git a/drivers/mmc/host/sdhci-cadence.c b/drivers/mmc/host/sdhci-cadence.c
index 435603c8c00b..f1ae7743ef5f 100644
--- a/drivers/mmc/host/sdhci-cadence.c
+++ b/drivers/mmc/host/sdhci-cadence.c
@@ -15,6 +15,8 @@
 #include <linux/reset.h>
 
 #include "sdhci-pltfm.h"
+#include "sdhci-cqhci.h"
+#include "cqhci.h"
 
 /* HRS - Host Register Set (specific to Cadence) */
 #define SDHCI_CDNS_HRS04		0x10		/* PHY access port */
@@ -36,6 +38,10 @@
 #define   SDHCI_CDNS_HRS06_MODE_MMC_HS400	0x5
 #define   SDHCI_CDNS_HRS06_MODE_MMC_HS400ES	0x6
 
+/* Host capabilities not covered by the standard capability registers (SRS16-SRS18) */
+#define SDHCI_CDNS_HRS30		0x78	/* Host capabilities */
+#define SDHCI_CDNS_HRS30_CQE_SUPPORTED	BIT(0)
+
 /* Read block gap */
 #define SDHCI_CDNS_HRS37		0x94	/* interface mode select */
 #define   SDHCI_CDNS_HRS37_MODE_DS		0x0
@@ -88,6 +94,7 @@ struct sdhci_cdns_priv {
 	void __iomem *ctl_addr;	/* write control */
 	spinlock_t wrlock;	/* write lock */
 	bool enhanced_strobe;
+	bool cqe_support;	/* Command Queuing Engine support */
 	void (*priv_writel)(struct sdhci_cdns_priv *priv, u32 val, void __iomem *reg);
 	struct reset_control *rst_hw;
 	unsigned int nr_phy_params;
@@ -385,6 +392,68 @@ static void sdhci_cdns_set_uhs_signaling(struct sdhci_host *host,
 		sdhci_set_uhs_signaling(host, timing);
 }
 
+static u32 sdhci_cdns_cqhci_irq(struct sdhci_host *host, u32 intmask)
+{
+	int cmd_err = 0;
+	int data_err = 0;
+
+	/* return original intmask to be handled by other handlers if it's not a CQE interrupt */
+	if (!sdhci_cqe_irq(host, intmask, &cmd_err, &data_err))
+		return intmask;
+
+	cqhci_irq(host->mmc, intmask, cmd_err, data_err);
+
+	return 0;
+}
+
+static const struct cqhci_host_ops sdhci_cdns_cqhci_ops = {
+	.enable		= sdhci_cqe_enable,
+	.disable	= sdhci_cqe_disable,
+};
+
+static int sdhci_cdns_cqe_add_host(struct sdhci_host *host, struct platform_device *pdev)
+{
+	struct cqhci_host *cq_host;
+	bool dma64;
+	int ret;
+
+	ret = sdhci_setup_host(host);
+	if (ret)
+		return ret;
+
+	cq_host = cqhci_pltfm_init(pdev);
+	if (IS_ERR(cq_host)) {
+		ret = PTR_ERR(cq_host);
+		dev_err_probe(&pdev->dev, ret, "cqhci platform init failed\n");
+		goto cleanup;
+	}
+
+	dma64 = host->flags & SDHCI_USE_64_BIT_DMA;
+	if (dma64)
+		cq_host->caps |= CQHCI_TASK_DESC_SZ_128;
+
+	cq_host->ops = &sdhci_cdns_cqhci_ops;
+
+	host->mmc->caps2 |= MMC_CAP2_CQE | MMC_CAP2_CQE_DCMD;
+
+	ret = cqhci_init(cq_host, host->mmc, dma64);
+	if (ret) {
+		dev_err_probe(&pdev->dev, ret, "cqhci init failed\n");
+		goto cleanup;
+	}
+
+	/* add host to MMC subsystem */
+	ret = __sdhci_add_host(host);
+	if (ret)
+		goto cleanup;
+
+	return 0;
+
+cleanup:
+	sdhci_cleanup_host(host);
+	return ret;
+}
+
 /* Elba control register bits [6:3] are byte-lane enables */
 #define ELBA_BYTE_ENABLE_MASK(x)	((x) << 3)
 
@@ -445,8 +514,9 @@ static const struct sdhci_ops sdhci_elba_ops = {
 	.set_clock = sdhci_set_clock,
 	.get_timeout_clock = sdhci_cdns_get_timeout_clock,
 	.set_bus_width = sdhci_set_bus_width,
-	.reset = sdhci_reset,
+	.reset = sdhci_and_cqhci_reset,
 	.set_uhs_signaling = sdhci_cdns_set_uhs_signaling,
+	.irq = sdhci_cdns_cqhci_irq,
 };
 
 static int elba_drv_init(struct platform_device *pdev)
@@ -474,9 +544,10 @@ static const struct sdhci_ops sdhci_cdns_ops = {
 	.set_clock = sdhci_set_clock,
 	.get_timeout_clock = sdhci_cdns_get_timeout_clock,
 	.set_bus_width = sdhci_set_bus_width,
-	.reset = sdhci_reset,
+	.reset = sdhci_and_cqhci_reset,
 	.platform_execute_tuning = sdhci_cdns_execute_tuning,
 	.set_uhs_signaling = sdhci_cdns_set_uhs_signaling,
+	.irq = sdhci_cdns_cqhci_irq,
 };
 
 static const struct sdhci_cdns_drv_data sdhci_cdns_uniphier_drv_data = {
@@ -553,6 +624,8 @@ static int sdhci_cdns_probe(struct platform_device *pdev)
 	int ret;
 	struct device *dev = &pdev->dev;
 	static const u16 version = SDHCI_SPEC_400 << SDHCI_SPEC_VER_SHIFT;
+	bool cqe_enabled;
+	u32 host_caps;
 
 	clk = devm_clk_get_enabled(dev, NULL);
 	if (IS_ERR(clk))
@@ -608,7 +681,43 @@ static int sdhci_cdns_probe(struct platform_device *pdev)
 			host->mmc_host_ops.card_hw_reset = sdhci_cdns_mmc_hw_reset;
 	}
 
-	return sdhci_add_host(host);
+	host_caps = readl(priv->hrs_addr + SDHCI_CDNS_HRS30);
+
+	/*
+	 * CQE is enabled only when both conditions are met:
+	 *   1. Hardware reports CQE support via HRS30[0].
+	 *   2. DT provides a named "cqhci" register space.
+	 */
+	cqe_enabled = (host_caps & SDHCI_CDNS_HRS30_CQE_SUPPORTED) &&
+		      !!platform_get_resource_byname(pdev, IORESOURCE_MEM, "cqhci");
+
+	if ((host_caps & SDHCI_CDNS_HRS30_CQE_SUPPORTED) && !cqe_enabled)
+		dev_dbg(dev, "CQE supported by hardware but no 'cqhci' register space in DT, disabling\n");
+
+	if (cqe_enabled) {
+		priv->cqe_support = true;
+		ret = sdhci_cdns_cqe_add_host(host, pdev);
+	} else {
+		ret = sdhci_add_host(host);
+	}
+
+	return ret;
+}
+
+static int sdhci_cdns_suspend(struct device *dev)
+{
+	struct sdhci_host *host = dev_get_drvdata(dev);
+	struct sdhci_pltfm_host *pltfm_host = sdhci_priv(host);
+	struct sdhci_cdns_priv *priv = sdhci_pltfm_priv(pltfm_host);
+	int ret;
+
+	if (priv->cqe_support) {
+		ret = cqhci_suspend(host->mmc);
+		if (ret)
+			return ret;
+	}
+
+	return sdhci_pltfm_suspend(dev);
 }
 
 static int sdhci_cdns_resume(struct device *dev)
@@ -630,6 +739,13 @@ static int sdhci_cdns_resume(struct device *dev)
 	if (ret)
 		goto disable_clk;
 
+	/* Resume CQE if enabled */
+	if (priv->cqe_support) {
+		ret = cqhci_resume(host->mmc);
+		if (ret)
+			goto disable_clk;
+	}
+
 	return 0;
 
 disable_clk:
@@ -638,7 +754,7 @@ static int sdhci_cdns_resume(struct device *dev)
 	return ret;
 }
 
-static DEFINE_SIMPLE_DEV_PM_OPS(sdhci_cdns_pm_ops, sdhci_pltfm_suspend, sdhci_cdns_resume);
+static DEFINE_SIMPLE_DEV_PM_OPS(sdhci_cdns_pm_ops, sdhci_cdns_suspend, sdhci_cdns_resume);
 
 static const struct of_device_id sdhci_cdns_match[] = {
 	{

-- 
2.43.0

