From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Thu, 12 Mar 2026 09:55:27 +0100
Subject: [PATCH v11 1/4] net: stmmac: platform: read channels irq
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260312-dwmac_multi_irq-v11-1-09621ccb040b@oss.nxp.com>
References: <20260312-dwmac_multi_irq-v11-0-09621ccb040b@oss.nxp.com>
In-Reply-To: <20260312-dwmac_multi_irq-v11-0-09621ccb040b@oss.nxp.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Chester Lin <chester62515@gmail.com>, Matthias Brugger <mbrugger@suse.com>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>, 
 NXP S32 Linux Team <s32@nxp.com>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Frank Li <Frank.Li@nxp.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, devicetree@vger.kernel.org, rmk+kernel@armlinux.org.uk, 
 vladimir.oltean@nxp.com, boon.khai.ng@altera.com, 
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773305743; l=2728;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=GNNHDYswRD5lJmmr4Meo4HJ1mFsNFRWc8kw+/KjFGLw=;
 b=vM9eg2WElPEFN7nCT4YplvEfunkAtCfZB1JEr1Ot3Q0f2/PQiS96QQwhd/h9M/I9TEEdd3NTi
 vAfYC0ZBBQZCsQtyVGSo8Zr0seWU7ERMisGLi2SqLZll9EBPPSGcK/v
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Read IRQ resources for all rx/tx channels, to allow Multi-IRQ mode
for platform glue drivers.

Reviewed-by: Matthias Brugger <mbrugger@suse.com>
Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 .../net/ethernet/stmicro/stmmac/stmmac_platform.c  | 57 +++++++++++++++++++++-
 1 file changed, 56 insertions(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_platform.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_platform.c
index 5c9fd91a1db9..542cd629df11 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_platform.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_platform.c
@@ -697,9 +697,47 @@ struct clk *stmmac_pltfr_find_clk(struct plat_stmmacenet_data *plat_dat,
 }
 EXPORT_SYMBOL_GPL(stmmac_pltfr_find_clk);
 
+/**
+ * stmmac_pltfr_get_irq_array - Read per-channel IRQs from platform device
+ * @pdev: platform device
+ * @fmt: IRQ name format string (e.g., "tx-queue-%d")
+ * @irqs: array to store IRQ numbers
+ * @num: maximum number of IRQs to read
+ *
+ * Return: 0 on success, -EPROBE_DEFER if IRQ is deferred, -EINVAL on error.
+ * Missing IRQs are set to 0 and iteration stops at first missing IRQ.
+ */
+static int stmmac_pltfr_get_irq_array(struct platform_device *pdev,
+				      const char *fmt, int *irqs, size_t num)
+{
+	char name[16];
+	int i;
+
+	for (i = 0; i < num; i++) {
+		if (snprintf(name, sizeof(name), fmt, i) >= sizeof(name))
+			return -EINVAL;
+
+		irqs[i] = platform_get_irq_byname_optional(pdev, name);
+		if (irqs[i] == -EPROBE_DEFER)
+			return -EPROBE_DEFER;
+
+		if (irqs[i] <= 0) {
+			dev_dbg(&pdev->dev, "IRQ %s not found\n", name);
+
+			/* Stop silently on first unset irq */
+			irqs[i] = 0;
+			break;
+		}
+	}
+
+	return 0;
+}
+
 int stmmac_get_platform_resources(struct platform_device *pdev,
 				  struct stmmac_resources *stmmac_res)
 {
+	int ret;
+
 	memset(stmmac_res, 0, sizeof(*stmmac_res));
 
 	/* Get IRQ information early to have an ability to ask for deferred
@@ -735,7 +773,24 @@ int stmmac_get_platform_resources(struct platform_device *pdev,
 
 	stmmac_res->addr = devm_platform_ioremap_resource(pdev, 0);
 
-	return PTR_ERR_OR_ZERO(stmmac_res->addr);
+	if (IS_ERR(stmmac_res->addr))
+		return PTR_ERR(stmmac_res->addr);
+
+	/* TX channels irq */
+	ret = stmmac_pltfr_get_irq_array(pdev, "tx-queue-%d",
+					 stmmac_res->tx_irq,
+					 MTL_MAX_TX_QUEUES);
+	if (ret)
+		return ret;
+
+	/* RX channels irq */
+	ret = stmmac_pltfr_get_irq_array(pdev, "rx-queue-%d",
+					 stmmac_res->rx_irq,
+					 MTL_MAX_RX_QUEUES);
+	if (ret)
+		return ret;
+
+	return 0;
 }
 EXPORT_SYMBOL_GPL(stmmac_get_platform_resources);
 

-- 
2.47.0

