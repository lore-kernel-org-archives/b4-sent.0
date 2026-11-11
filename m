From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Wed, 11 Nov 2026 11:10:58 +0100
Subject: [PATCH 3/6] memory: tegra114-emc: Always restore the
 auto-calibration interval
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-upstream-emc-t114-v1-3-54d9e1bceb6a@tsv-stahl-riesa.de>
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
 stable@vger.kernel.org, Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794391862; l=2143;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=TAnBAqYy7A55BHTS5zRoiWh6peV/YQug5wzY/XpzP7U=;
 b=3bGYVrsXMzw14FnvFfHSX/wK6/A6Ih2qMJmxlqJ4s8ey7rwdjmEj/OqYyDMe94ALBtxWVK5Bx
 Ms/t3MLnUf3BWPIanBMyhLDk5EHYXlPtz9oZ85nCA6+QS7HtVc2V7ub
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tegra114_emc_prepare_timing_change() disables pad auto-calibration for
every clock change by writing 0 to EMC_AUTO_CAL_INTERVAL. The interval
is only written back if EMC_CTT_TERM_CTRL differs between the old and
the new timing, which is not the case with the usual tables, so after
the first rate change auto-calibration stays off for good. Read back on
a Tegra Note 7 (P1640) after a few rate changes, EMC_AUTO_CAL_INTERVAL
is 0 and EMC_AUTO_CAL_STATUS no longer changes.

The Tegra124 driver this code is based on writes the interval back
unconditionally for DDR3 as part of its BGBIAS handling, which was left
out for Tegra114. The downstream Tegra114 driver (tegra11_emc.c,
rel-tegranote-r8) also restores it after every clock change.

Restore the interval unconditionally.

Fixes: dce208b5405f ("memory: tegra: Add Tegra114 EMC driver")
Cc: stable@vger.kernel.org
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 drivers/memory/tegra/tegra114-emc.c | 8 +++-----
 1 file changed, 3 insertions(+), 5 deletions(-)

diff --git a/drivers/memory/tegra/tegra114-emc.c b/drivers/memory/tegra/tegra114-emc.c
index 6ec1bb2c3ed0..9de3f2e728ea 100644
--- a/drivers/memory/tegra/tegra114-emc.c
+++ b/drivers/memory/tegra/tegra114-emc.c
@@ -706,7 +706,6 @@ static void tegra114_emc_complete_timing_change(struct tegra_emc *emc,
 						unsigned long rate)
 {
 	struct emc_timing *timing = tegra114_emc_find_timing(emc, rate);
-	struct emc_timing *last = &emc->last_timing;
 
 	if (!timing)
 		return;
@@ -714,10 +713,9 @@ static void tegra114_emc_complete_timing_change(struct tegra_emc *emc,
 	/* Wait until the state machine has settled */
 	emc_seq_wait_clkchange(emc);
 
-	/* Restore AUTO_CAL */
-	if (timing->emc_ctt_term_ctrl != last->emc_ctt_term_ctrl)
-		writel(timing->emc_auto_cal_interval,
-		       emc->regs + EMC_AUTO_CAL_INTERVAL);
+	/* Restore AUTO_CAL, it was disabled for the clock change */
+	writel(timing->emc_auto_cal_interval,
+	       emc->regs + EMC_AUTO_CAL_INTERVAL);
 
 	/* Restore dynamic self-refresh */
 	if (timing->emc_cfg & EMC_CFG_PWR_MASK)

-- 
2.56.0

