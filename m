From: Rohan G Thomas <rohan.g.thomas@altera.com>
Date: Wed, 29 Oct 2025 16:06:16 +0800
Subject: [PATCH net-next 4/4] net: stmmac: socfpga: Add hardware supported
 cross-timestamp
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251029-agilex5_ext-v1-4-1931132d77d6@altera.com>
References: <20251029-agilex5_ext-v1-0-1931132d77d6@altera.com>
In-Reply-To: <20251029-agilex5_ext-v1-0-1931132d77d6@altera.com>
To: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Richard Cochran <richardcochran@gmail.com>, 
 Steffen Trumtrar <s.trumtrar@pengutronix.de>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761725182; l=7260;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=tUV/L7I6pOGEG38MdWI+75TwNmBVsKyEDIuFz1TUCgU=;
 b=/smYeDjK8rwqYcgfEOpvuMUFqL6IEZpzQmRyCLPGablCq+W4zvn+KYPaTwBit++QgjOUr83wd
 rfffrHawDlaCV0cK2KiOjCLsdGsKnFSX58w84U23PMwor8COayGh/+U
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=5yZXkXswhfUILKAQwoIn7m6uSblwgV5oppxqde4g4TY=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250815 with auth_id=494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Cross timestamping is supported on Agilex5 platform with Synchronized
Multidrop Timestamp Gathering(SMTG) IP. The hardware cross-timestamp
result is made available the applications through the ioctl call
PTP_SYS_OFFSET_PRECISE, which inturn calls stmmac_getcrosststamp().

Device time is stored in the MAC Auxiliary register. The 64-bit System
time (ARM_ARCH_COUNTER) is stored in SMTG IP. SMTG IP is an MDIO device
with 0xC - 0xF MDIO register space holds 64-bit system time.

This commit is similar to following commit for Intel platforms:
Commit 341f67e424e5 ("net: stmmac: Add hardware supported cross-timestamp")

Signed-off-by: Rohan G Thomas <rohan.g.thomas@altera.com>
---
 .../net/ethernet/stmicro/stmmac/dwmac-socfpga.c    | 125 +++++++++++++++++++++
 drivers/net/ethernet/stmicro/stmmac/dwxgmac2.h     |   5 +
 2 files changed, 130 insertions(+)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-socfpga.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-socfpga.c
index 37fcf272a46920d1d97a4b651a469767609373b4..d36c9b77003ef4ad3ac598929fee3f7a8b94b9bc 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-socfpga.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-socfpga.c
@@ -5,6 +5,7 @@
  */
 
 #include <linux/mfd/altera-sysmgr.h>
+#include <linux/clocksource_ids.h>
 #include <linux/of.h>
 #include <linux/of_address.h>
 #include <linux/of_net.h>
@@ -15,8 +16,10 @@
 #include <linux/reset.h>
 #include <linux/stmmac.h>
 
+#include "dwxgmac2.h"
 #include "stmmac.h"
 #include "stmmac_platform.h"
+#include "stmmac_ptp.h"
 
 #define SYSMGR_EMACGRP_CTRL_PHYSEL_ENUM_GMII_MII 0x0
 #define SYSMGR_EMACGRP_CTRL_PHYSEL_ENUM_RGMII 0x1
@@ -41,6 +44,13 @@
 #define SGMII_ADAPTER_ENABLE		0x0000
 #define SGMII_ADAPTER_DISABLE		0x0001
 
+#define SMTG_MDIO_ADDR		0x15
+#define SMTG_TSC_WORD0		0xC
+#define SMTG_TSC_WORD1		0xD
+#define SMTG_TSC_WORD2		0xE
+#define SMTG_TSC_WORD3		0xF
+#define SMTG_TSC_SHIFT		16
+
 struct socfpga_dwmac;
 struct socfpga_dwmac_ops {
 	int (*set_phy_mode)(struct socfpga_dwmac *dwmac_priv);
@@ -269,6 +279,117 @@ static int socfpga_set_phy_mode_common(int phymode, u32 *val)
 	return 0;
 }
 
+static void get_smtgtime(struct mii_bus *mii, int smtg_addr, u64 *smtg_time)
+{
+	u64 ns;
+
+	ns = mdiobus_read(mii, smtg_addr, SMTG_TSC_WORD3);
+	ns <<= SMTG_TSC_SHIFT;
+	ns |= mdiobus_read(mii, smtg_addr, SMTG_TSC_WORD2);
+	ns <<= SMTG_TSC_SHIFT;
+	ns |= mdiobus_read(mii, smtg_addr, SMTG_TSC_WORD1);
+	ns <<= SMTG_TSC_SHIFT;
+	ns |= mdiobus_read(mii, smtg_addr, SMTG_TSC_WORD0);
+
+	*smtg_time = ns;
+}
+
+static int dwxgmac_cross_ts_isr(struct stmmac_priv *priv)
+{
+	return (readl(priv->ioaddr + XGMAC_INT_STATUS) & XGMAC_INT_TSIS);
+}
+
+static int smtg_crosststamp(ktime_t *device, struct system_counterval_t *system,
+			    void *ctx)
+{
+	struct stmmac_priv *priv = (struct stmmac_priv *)ctx;
+	u32 num_snapshot, gpio_value, acr_value;
+	void __iomem *ptpaddr = priv->ptpaddr;
+	void __iomem *ioaddr = priv->hw->pcsr;
+	unsigned long flags;
+	u64 smtg_time = 0;
+	u64 ptp_time = 0;
+	int i, ret;
+
+	/* Both internal crosstimestamping and external triggered event
+	 * timestamping cannot be run concurrently.
+	 */
+	if (priv->plat->flags & STMMAC_FLAG_EXT_SNAPSHOT_EN)
+		return -EBUSY;
+
+	mutex_lock(&priv->aux_ts_lock);
+	/* Enable Internal snapshot trigger */
+	acr_value = readl(ptpaddr + PTP_ACR);
+	acr_value &= ~PTP_ACR_MASK;
+	switch (priv->plat->int_snapshot_num) {
+	case AUX_SNAPSHOT0:
+		acr_value |= PTP_ACR_ATSEN0;
+		break;
+	case AUX_SNAPSHOT1:
+		acr_value |= PTP_ACR_ATSEN1;
+		break;
+	case AUX_SNAPSHOT2:
+		acr_value |= PTP_ACR_ATSEN2;
+		break;
+	case AUX_SNAPSHOT3:
+		acr_value |= PTP_ACR_ATSEN3;
+		break;
+	default:
+		mutex_unlock(&priv->aux_ts_lock);
+		return -EINVAL;
+	}
+	writel(acr_value, ptpaddr + PTP_ACR);
+
+	/* Clear FIFO */
+	acr_value = readl(ptpaddr + PTP_ACR);
+	acr_value |= PTP_ACR_ATSFC;
+	writel(acr_value, ptpaddr + PTP_ACR);
+	/* Release the mutex */
+	mutex_unlock(&priv->aux_ts_lock);
+
+	/* Trigger Internal snapshot signal. Create a rising edge by just toggle
+	 * the GPO0 to low and back to high.
+	 */
+	gpio_value = readl(ioaddr + XGMAC_GPIO_STATUS);
+	gpio_value &= ~XGMAC_GPIO_GPO0;
+	writel(gpio_value, ioaddr + XGMAC_GPIO_STATUS);
+	gpio_value |= XGMAC_GPIO_GPO0;
+	writel(gpio_value, ioaddr + XGMAC_GPIO_STATUS);
+
+	/* Time sync done Indication - Interrupt method */
+	if (!wait_event_interruptible_timeout(priv->tstamp_busy_wait,
+					      dwxgmac_cross_ts_isr(priv),
+					      HZ / 100)) {
+		priv->plat->flags &= ~STMMAC_FLAG_INT_SNAPSHOT_EN;
+		return -ETIMEDOUT;
+	}
+
+	*system = (struct system_counterval_t) {
+		.cycles = 0,
+		.cs_id = CSID_ARM_ARCH_COUNTER,
+		.use_nsecs = true,
+	};
+
+	num_snapshot = (readl(ioaddr + XGMAC_TIMESTAMP_STATUS) &
+			XGMAC_TIMESTAMP_ATSNS_MASK) >>
+			XGMAC_TIMESTAMP_ATSNS_SHIFT;
+
+	/* Repeat until the timestamps are from the FIFO last segment */
+	for (i = 0; i < num_snapshot; i++) {
+		read_lock_irqsave(&priv->ptp_lock, flags);
+		stmmac_get_ptptime(priv, ptpaddr, &ptp_time);
+		*device = ns_to_ktime(ptp_time);
+		read_unlock_irqrestore(&priv->ptp_lock, flags);
+	}
+
+	get_smtgtime(priv->mii, SMTG_MDIO_ADDR, &smtg_time);
+	system->cycles = smtg_time;
+
+	priv->plat->flags &= ~STMMAC_FLAG_INT_SNAPSHOT_EN;
+
+	return ret;
+}
+
 static int socfpga_gen5_set_phy_mode(struct socfpga_dwmac *dwmac)
 {
 	struct regmap *sys_mgr_base_addr = dwmac->sys_mgr_base_addr;
@@ -489,6 +610,10 @@ static void socfpga_agilex5_setup_plat_dat(struct socfpga_dwmac *dwmac)
 		/* Tx Queues 0 - 5 doesn't support TBS on Agilex5 */
 		break;
 	}
+
+	/* Hw supported cross-timestamp */
+	plat_dat->int_snapshot_num = AUX_SNAPSHOT0;
+	plat_dat->crosststamp = smtg_crosststamp;
 }
 
 static int socfpga_dwmac_probe(struct platform_device *pdev)
diff --git a/drivers/net/ethernet/stmicro/stmmac/dwxgmac2.h b/drivers/net/ethernet/stmicro/stmmac/dwxgmac2.h
index 0d408ee17f337851502cbcba8e82d2b839b9db02..e48cfa05000c07ed9194de786efa530a61a9dbfa 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwxgmac2.h
+++ b/drivers/net/ethernet/stmicro/stmmac/dwxgmac2.h
@@ -79,6 +79,7 @@
 #define XGMAC_PSRQ(x)			GENMASK((x) * 8 + 7, (x) * 8)
 #define XGMAC_PSRQ_SHIFT(x)		((x) * 8)
 #define XGMAC_INT_STATUS		0x000000b0
+#define XGMAC_INT_TSIS			BIT(12)
 #define XGMAC_LPIIS			BIT(5)
 #define XGMAC_PMTIS			BIT(4)
 #define XGMAC_INT_EN			0x000000b4
@@ -173,6 +174,8 @@
 #define XGMAC_MDIO_ADDR			0x00000200
 #define XGMAC_MDIO_DATA			0x00000204
 #define XGMAC_MDIO_C22P			0x00000220
+#define XGMAC_GPIO_STATUS		0x0000027c
+#define XGMAC_GPIO_GPO0			BIT(16)
 #define XGMAC_ADDRx_HIGH(x)		(0x00000300 + (x) * 0x8)
 #define XGMAC_ADDR_MAX			32
 #define XGMAC_AE			BIT(31)
@@ -220,6 +223,8 @@
 #define XGMAC_OB			BIT(0)
 #define XGMAC_RSS_DATA			0x00000c8c
 #define XGMAC_TIMESTAMP_STATUS		0x00000d20
+#define XGMAC_TIMESTAMP_ATSNS_MASK	GENMASK(29, 25)
+#define XGMAC_TIMESTAMP_ATSNS_SHIFT	25
 #define XGMAC_TXTSC			BIT(15)
 #define XGMAC_TXTIMESTAMP_NSEC		0x00000d30
 #define XGMAC_TXTSSTSLO			GENMASK(30, 0)

-- 
2.43.7

