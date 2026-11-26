From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: peter.wang@mediatek.com, stanley.chu@mediatek.com, 
 martin.petersen@oracle.com, James.Bottomley@HansenPartnership.com
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 louisalexis.eyraud@collabora.com, linux-scsi@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH v2 2/3] scsi: ufs: mediatek: allow clock scaling when
 ufs_fde is absent
Date: Thu, 26 Nov 2026 03:10:10 +0000
Message-Id: <20261126031008.27506-3-iasnezhkov@gmail.com>
In-Reply-To: <20261126031008.27506-1-iasnezhkov@gmail.com>
References: <20261126031008.27506-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795662608; l=1692;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=JrSCC6bqmjDSayjLVPuM/lqnbwzNiJ316tX4mC55cw0=;
 b=WlJ6RSWIlNpmwPCJm9rOCp74Wf4sAwQyre/FuX8xHvV2Wb1+gnofB6HT01qI3BxFab/QSk/hk
 T5xVyGu9vKxASqXffTcrtdDdaR1GyjXEyN/3ew8a14trS8Y3MznGiAW
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ufs_mtk_is_clk_scale_ready() enables UFSHCD_CAP_CLK_SCALING whenever
ufs_sel, ufs_sel_max_src, and ufs_sel_min_src are present, treating the
FDE (AES) clock as optional. However, _ufs_mtk_clk_scale() bails out
early on !fde_clki, so on SoCs without a ufs_fde clock (such as MT6789)
ufshcd believes scaling succeeded and updates clki->curr_freq while the
ufs_sel mux never switches parents.

Only require clki (ufs_sel) in _ufs_mtk_clk_scale(), and gate
clk_fde_scale on fde_clki being non-NULL alongside its min/max parents.

Fixes: 5e5976f5242d ("scsi: ufs: host: mediatek: Support FDE (AES) clock scaling")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
Changes since v1:
- Moved AI coding assistant note below ---.
- Found on hardware and drafted with an AI coding assistant.

 drivers/ufs/host/ufs-mediatek.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/ufs/host/ufs-mediatek.c b/drivers/ufs/host/ufs-mediatek.c
index 38d05ac..09b7993 100644
--- a/drivers/ufs/host/ufs-mediatek.c
+++ b/drivers/ufs/host/ufs-mediatek.c
@@ -2059,7 +2059,7 @@ static void _ufs_mtk_clk_scale(struct ufs_hba *hba, bool scale_up)
 	if (!hba->clk_scaling.is_initialized)
 		return;
 
-	if (!clki || !fde_clki)
+	if (!clki)
 		return;
 
 	reg = host->mclk.reg_vcore;
@@ -2067,7 +2067,7 @@ static void _ufs_mtk_clk_scale(struct ufs_hba *hba, bool scale_up)
 	if (reg && volt != 0)
 		clk_bind_vcore = true;
 
-	if (mclk->ufs_fde_max_clki && mclk->ufs_fde_min_clki)
+	if (fde_clki && mclk->ufs_fde_max_clki && mclk->ufs_fde_min_clki)
 		clk_fde_scale = true;
 
 	ret = clk_prepare_enable(clki->clk);
-- 
2.54.0 (Apple Git-157)

