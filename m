From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: peter.wang@mediatek.com, stanley.chu@mediatek.com, 
 martin.petersen@oracle.com, James.Bottomley@HansenPartnership.com
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 louisalexis.eyraud@collabora.com, linux-scsi@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH v2 3/3] scsi: ufs: mediatek: round scalable clock bounds to
 clk_round_rate()
Date: Thu, 26 Nov 2026 03:10:11 +0000
Message-Id: <20261126031008.27506-4-iasnezhkov@gmail.com>
In-Reply-To: <20261126031008.27506-1-iasnezhkov@gmail.com>
References: <20261126031008.27506-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795662608; l=3051;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=MuIq1TvnjCaHK1YyQad7wOf3RnvQAYoWa7G/0M98I2c=;
 b=oH1rvPdfuZPM6eSf5SJfZh3FEeViLmw03zRzbmT1vwVo0mWByrcy5Fph1kijf2WqWDBGi97Kg
 7979edxEa4/DkIVBKl6GGF3N9wZ8kKBgwzeoTHJEtsX+Chccj7wmQbA
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ufshcd_devfreq_target() determines scale_up via an exact equality check
against clki->max_freq after rounding the target frequency. When a DT
freq-table-hz lists a nominal value that a PLL-derived clock cannot hit
exactly (for example, msdcpll_d2 on MT6789 delivers 191999939 Hz for a
192000000 Hz DT maximum), clk_round_rate() produces a rate that never
equals clki->max_freq, so devfreq scales down once and can never scale
back up.

Round clki->max_freq and clki->min_freq with clk_round_rate() in
ufs_mtk_init_clocks() for ufs_sel (and ufs_fde when present) before
ufshcd_devfreq_init() builds the OPP table from those bounds, keeping
clki->curr_freq synchronized with the rounded bound and skipping the
adjustment if rounding fails, overflows u32, or collapses min >= max.

Fixes: b7dbc686f60b ("scsi: ufs: ufs-mediatek: Support clk-scaling to optimize power consumption")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
Changes since v1:
- Use IS_ERR_OR_NULL(clki->clk) and cast max_rounded to u64 before
  comparing against U32_MAX for 32-bit cleanliness.
- Found on hardware and drafted with an AI coding assistant.

 drivers/ufs/host/ufs-mediatek.c | 35 +++++++++++++++++++++++++++++++++++
 1 file changed, 35 insertions(+)

diff --git a/drivers/ufs/host/ufs-mediatek.c b/drivers/ufs/host/ufs-mediatek.c
index 09b7993..4de72ae 100644
--- a/drivers/ufs/host/ufs-mediatek.c
+++ b/drivers/ufs/host/ufs-mediatek.c
@@ -967,6 +967,37 @@ static u32 ufs_mtk_get_ufs_hci_version(struct ufs_hba *hba)
 	return hba->ufs_version;
 }
 
+static void ufs_mtk_round_clk_freq(struct ufs_hba *hba,
+				   struct ufs_clk_info *clki)
+{
+	long max_rounded, min_rounded;
+
+	if (IS_ERR_OR_NULL(clki->clk) || !clki->max_freq || !clki->min_freq)
+		return;
+
+	max_rounded = clk_round_rate(clki->clk, clki->max_freq);
+	min_rounded = clk_round_rate(clki->clk, clki->min_freq);
+	if (max_rounded <= 0 || min_rounded <= 0 ||
+	    min_rounded >= max_rounded || (u64)max_rounded > U32_MAX)
+		return;
+
+	if (max_rounded != clki->max_freq) {
+		dev_dbg(hba->dev, "%s: max_freq %u rounds to %ld\n",
+			clki->name, clki->max_freq, max_rounded);
+		if (clki->curr_freq == clki->max_freq)
+			clki->curr_freq = max_rounded;
+		clki->max_freq = max_rounded;
+	}
+
+	if (min_rounded != clki->min_freq) {
+		dev_dbg(hba->dev, "%s: min_freq %u rounds to %ld\n",
+			clki->name, clki->min_freq, min_rounded);
+		if (clki->curr_freq == clki->min_freq)
+			clki->curr_freq = min_rounded;
+		clki->min_freq = min_rounded;
+	}
+}
+
 /**
  * ufs_mtk_init_clocks - Init mtk driver private clocks
  *
@@ -1022,6 +1053,10 @@ static void ufs_mtk_init_clocks(struct ufs_hba *hba)
 		return;
 	}
 
+	ufs_mtk_round_clk_freq(hba, host->mclk.ufs_sel_clki);
+	if (host->mclk.ufs_fde_clki)
+		ufs_mtk_round_clk_freq(hba, host->mclk.ufs_fde_clki);
+
 	/*
 	 * Default get vcore if dts have these settings.
 	 * No matter clock scaling support or not. (may disable by customer)
-- 
2.54.0 (Apple Git-157)

