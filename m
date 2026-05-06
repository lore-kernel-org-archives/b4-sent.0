From: Rohan Joshi <rohan1sj@cadence.com>
Date: Wed, 06 May 2026 14:34:47 +0530
Subject: [PATCH v2 2/2] mmc: sdhci-cadence: add CQE support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260506-cdns_sdhci_cqe-support-v2-2-754fe4de8b65@cadence.com>
References: <20260506-cdns_sdhci_cqe-support-v2-0-754fe4de8b65@cadence.com>
In-Reply-To: <20260506-cdns_sdhci_cqe-support-v2-0-754fe4de8b65@cadence.com>
To: Ulf Hansson <ulfh@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Masahiro Yamada <yamada.masahiro@socionext.com>, 
 Adrian Hunter <adrian.hunter@intel.com>
Cc: linux-mmc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, mparab@cadence.com, pawell@cadence.com, 
 sjakhade@cadence.com, mpillai@cadence.com, rohan1sj@cadence.com
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778058299; l=2938;
 i=rohan1sj@cadence.com; s=20260406; h=from:subject:message-id;
 bh=eE87dnPJ2d6imQCE9+pL8jia/mRxfjYC8/OHMviUC94=;
 b=hNsboodWZoL6e9MwECUReMdw7cdWnM+8PutK9IQrFH6/y/9/DrH9i7T6dj0XUcl5GxUQipuEh
 rkntK4kDQ1MD0Pty3q6N/3vMByIrsT+1J3GfhvlgnahkiNG1w8R8oAC
X-Developer-Key: i=rohan1sj@cadence.com; a=ed25519;
 pk=YuwylizMVlVj8I4+VPMZ6xrFR2wyqJAWZyj90OVZgD0=
X-Endpoint-Received: by B4 Relay for rohan1sj@cadence.com/20260406 with auth_id=723
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add CQE (Command Queuing Engine) support for all platforms
which use sdhci_cdns_ops. Read additional host capability
register to detect CQE presence

Signed-off-by: Rohan Joshi <rohan1sj@cadence.com>
---
 drivers/mmc/host/Kconfig         |  1 +
 drivers/mmc/host/sdhci-cadence.c | 13 ++++---------
 2 files changed, 5 insertions(+), 9 deletions(-)

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
index 14b12272dae9..1aba8c89821b 100644
--- a/drivers/mmc/host/sdhci-cadence.c
+++ b/drivers/mmc/host/sdhci-cadence.c
@@ -40,7 +40,7 @@
 
 /* Host capabilities not covered by the standard capability registers (SRS16-SRS18) */
 #define SDHCI_CDNS_HRS30		0x78	/* Host capabilities */
-#define   SDHCI_CDNS_HRS30_CQE_SUPPORTED	BIT(0)
+#define SDHCI_CDNS_HRS30_CQE_SUPPORTED	BIT(0)
 
 /* Read block gap */
 #define SDHCI_CDNS_HRS37		0x94	/* interface mode select */
@@ -94,7 +94,7 @@ struct sdhci_cdns_priv {
 	void __iomem *ctl_addr;	/* write control */
 	spinlock_t wrlock;	/* write lock */
 	bool enhanced_strobe;
-	bool cqe_support;   /* Command Queuing Engine support */
+	bool cqe_support;	/* Command Queuing Engine support */
 	void (*priv_writel)(struct sdhci_cdns_priv *priv, u32 val, void __iomem *reg);
 	struct reset_control *rst_hw;
 	unsigned int nr_phy_params;
@@ -417,16 +417,14 @@ static int sdhci_cdns_cqe_add_host(struct sdhci_host *host, struct platform_devi
 	bool dma64;
 	int ret;
 
-	/* setup SDHCI host first */
 	ret = sdhci_setup_host(host);
-
 	if (ret)
 		return ret;
 
-	/* Init CQE */
 	cq_host = cqhci_pltfm_init(pdev);
 	if (IS_ERR(cq_host)) {
 		ret = PTR_ERR(cq_host);
+		dev_err_probe(&pdev->dev, ret, "cqhci platform init failed\n");
 		goto cleanup;
 	}
 
@@ -438,10 +436,9 @@ static int sdhci_cdns_cqe_add_host(struct sdhci_host *host, struct platform_devi
 
 	host->mmc->caps2 |= MMC_CAP2_CQE | MMC_CAP2_CQE_DCMD;
 
-	/* Finally initialize CQHCI */
 	ret = cqhci_init(cq_host, host->mmc, dma64);
 	if (ret) {
-		dev_err(mmc_dev(host->mmc), "Failed to initialize CQHCI: %d\n", ret);
+		dev_err_probe(&pdev->dev, ret, "cqhci init failed\n");
 		goto cleanup;
 	}
 
@@ -450,11 +447,9 @@ static int sdhci_cdns_cqe_add_host(struct sdhci_host *host, struct platform_devi
 	if (ret)
 		goto cleanup;
 
-	dev_info(mmc_dev(host->mmc), "CQE init: success\n");
 	return 0;
 
 cleanup:
-	dev_err(mmc_dev(host->mmc), "CQE init: failed for %s\n", mmc_hostname(host->mmc));
 	sdhci_cleanup_host(host);
 	return ret;
 }

-- 
2.34.1

