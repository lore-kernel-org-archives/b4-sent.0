From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Wed, 11 Nov 2026 11:11:00 +0100
Subject: [PATCH 5/6] memory: tegra114-emc: Program pad auto-calibration per
 channel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-upstream-emc-t114-v1-5-54d9e1bceb6a@tsv-stahl-riesa.de>
References: <20261111-upstream-emc-t114-v1-0-54d9e1bceb6a@tsv-stahl-riesa.de>
In-Reply-To: <20261111-upstream-emc-t114-v1-0-54d9e1bceb6a@tsv-stahl-riesa.de>
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, 
 Mikko Perttunen <mperttunen@nvidia.com>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-tegra@vger.kernel.org, 
 Thierry Reding <thierry.reding@gmail.com>, devicetree@vger.kernel.org, 
 Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794391862; l=3713;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=K2SPmhgJ6C3ZE/fZgTA83RQZgcOScMG8/6jryEAwAiU=;
 b=cKfBOE8LlyrABtcd1DYsV04cH0l8FZKu6uC6HlyXjBQ3Cyyclj2nZwnk1qrbIIadsie7Or/W8
 k87Gil9yIzzARwh48prVIkb0Y0CoZLIfN6MMpps/E5gnMr0i9hCuMZT
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The timing tables carry a value for EMC_AUTO_CAL_CONFIG, but the driver
cannot apply it through the broadcast registers: channel 0 runs the
calibration and channel 1 takes over its results as a slave
(AUTO_CAL_SLAVE_MODE, bit 27), as the values the bootloader leaves show
(0x20f10f0f and 0x28f10f0f on a Tegra Note 7, P1640). The downstream
driver (tegra11_emc.c, rel-tegranote-r8) programs this register per
channel for the same reason.

Map the channel registers when the device tree describes them and write
the table value to channel 0 and the same value with the slave bit to
channel 1. As in the downstream driver, this happens directly on every
rate change, with the AUTO_CAL_START bit from the table. It does not
need the CCFIFO: the Tegra 4 TRM lists EMC_AUTO_CAL_CONFIG among the
shadow registers that are programmed for the new frequency before the
clock change. With an older device tree the register stays as the
bootloader set it.

Tested on a Tegra Note 7 (P1640) together with the previous patches:
the channels read 0x20f10000 and 0x28f10000 after rate changes and
EMC_AUTO_CAL_STATUS keeps changing. Before, two out of two rate changes
from pll_p at 408 MHz to pll_c at 624 MHz ended in a kernel panic; with
this series, about an hour of memory testing that switched between 408
and 624 MHz ran without errors. That points at the calibration but does
not prove it, as the old runs also had the wrong bus width.

Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 drivers/memory/tegra/tegra114-emc.c | 25 +++++++++++++++++++++++++
 1 file changed, 25 insertions(+)

diff --git a/drivers/memory/tegra/tegra114-emc.c b/drivers/memory/tegra/tegra114-emc.c
index 9de3f2e728ea..d5c3142a0671 100644
--- a/drivers/memory/tegra/tegra114-emc.c
+++ b/drivers/memory/tegra/tegra114-emc.c
@@ -142,6 +142,7 @@
 
 #define EMC_AUTO_CAL_CONFIG			0x2a4
 #define EMC_AUTO_CAL_CONFIG_AUTO_CAL_START	BIT(31)
+#define EMC_AUTO_CAL_CONFIG_SLAVE_MODE		BIT(27)
 #define EMC_AUTO_CAL_INTERVAL			0x2a8
 #define EMC_AUTO_CAL_STATUS			0x2ac
 #define EMC_AUTO_CAL_STATUS_ACTIVE		BIT(31)
@@ -393,6 +394,7 @@ struct tegra_emc {
 	struct device *dev;
 	struct tegra_mc *mc;
 	void __iomem *regs;
+	void __iomem *ch_regs[2];
 	unsigned int irq;
 	struct clk *clk;
 
@@ -609,6 +611,19 @@ static int tegra114_emc_prepare_timing_change(struct tegra_emc *emc,
 		emc_ccfifo_writel(emc, timing->emc_auto_cal_config3,
 				  EMC_AUTO_CAL_CONFIG3);
 
+	/*
+	 * Channel 0 runs the pad calibration and channel 1 takes over its
+	 * results, so the two channels need different values. Without the
+	 * channel registers in the DT, keep what the bootloader set up.
+	 */
+	if (emc->ch_regs[0]) {
+		writel(timing->emc_auto_cal_config,
+		       emc->ch_regs[0] + EMC_AUTO_CAL_CONFIG);
+		writel(timing->emc_auto_cal_config |
+		       EMC_AUTO_CAL_CONFIG_SLAVE_MODE,
+		       emc->ch_regs[1] + EMC_AUTO_CAL_CONFIG);
+	}
+
 	/* DDR3: predict MRS long wait count */
 	if (emc->dram_type == DRAM_TYPE_DDR3 &&
 	    dll_change == DLL_CHANGE_ON) {
@@ -1253,6 +1268,16 @@ static int tegra114_emc_probe(struct platform_device *pdev)
 	if (IS_ERR(emc->regs))
 		return PTR_ERR(emc->regs);
 
+	/* Older device trees only describe the broadcast registers */
+	if (platform_get_resource(pdev, IORESOURCE_MEM, 2)) {
+		for (unsigned int i = 0; i < ARRAY_SIZE(emc->ch_regs); i++) {
+			emc->ch_regs[i] =
+				devm_platform_ioremap_resource(pdev, i + 1);
+			if (IS_ERR(emc->ch_regs[i]))
+				return PTR_ERR(emc->ch_regs[i]);
+		}
+	}
+
 	emc->mc = devm_tegra_memory_controller_get(dev);
 	if (IS_ERR(emc->mc))
 		return PTR_ERR(emc->mc);

-- 
2.56.0

