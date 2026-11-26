From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: peter.wang@mediatek.com, stanley.chu@mediatek.com, 
 martin.petersen@oracle.com, James.Bottomley@HansenPartnership.com
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 louisalexis.eyraud@collabora.com, linux-scsi@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH v2 0/3] scsi: ufs: mediatek: pre-UniPro-1.8 adapt and clock
 scaling fixes
Date: Thu, 26 Nov 2026 03:10:08 +0000
Message-Id: <20261126031008.27506-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795662608; l=1580;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=BP06CLJVlJGdEHSpJcnNEfsWqrVwVf9F4B3gDHXexkk=;
 b=SOfVrfsX0so2wDlCf+TkdENLwrZyjD50wLxT6xdQB9Ovl06EZ84fiR2Y41EcTjnkOn218D1FZ
 iQSybmFGuTCCrcJ4DRGcFE34imQJlfBhGdO0Ba4PepOGZVehCGmH9n6
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes three bugs in the MediaTek UFS host driver observed on
MT6789 (UFS 2.2, pre-UniPro-1.8, HS-G3 rate B, no ufs_fde clock):

1. Skip ufshcd_dme_configure_adapt() when host->hw_ver.major < 3 so
   pre-UniPro-1.8 hosts do not fail DME-SET on PA_TXHSADAPTTYPE (0x15d4)
   on every power-mode change.
2. Allow _ufs_mtk_clk_scale() to switch ufs_sel when the optional
   ufs_fde clock is absent, matching ufs_mtk_is_clk_scale_ready().
3. Round clki->max_freq and clki->min_freq with clk_round_rate() during
   ufs_mtk_init_clocks() so PLL-derived clocks whose rounded rate
   differs from the nominal DT frequency can scale back up in
   ufshcd_devfreq_target().

Changes since v1:
- Patch 1: corrected Fixes tag to 7212d624f863 ("scsi: ufs: host:
  mediatek: Fix PWM mode switch issue") and clarified mainline behavior
  after d3eba21c7170 vs older stable kernels.
- Patch 3: use IS_ERR_OR_NULL(clki->clk) and cast max_rounded to u64
  before comparing with U32_MAX to avoid 32-bit -Wtype-limits warnings.
- Moved AI assistant disclosure out of commit logs (below --- and in
  this cover letter).

Found on hardware and drafted with an AI coding assistant.

Ilia Snezhkov (3):
  scsi: ufs: mediatek: skip PA_TXHSADAPTTYPE on pre-UniPro-1.8 hosts
  scsi: ufs: mediatek: allow clock scaling when ufs_fde is absent
  scsi: ufs: mediatek: round scalable clock bounds to clk_round_rate()

 drivers/ufs/host/ufs-mediatek.c | 58 +++++++++++++++++++++++++--------
 1 file changed, 45 insertions(+), 13 deletions(-)

-- 
2.54.0 (Apple Git-157)

