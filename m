From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: peter.wang@mediatek.com, stanley.chu@mediatek.com, 
 martin.petersen@oracle.com, James.Bottomley@HansenPartnership.com
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 louisalexis.eyraud@collabora.com, linux-scsi@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH v2 1/3] scsi: ufs: mediatek: skip PA_TXHSADAPTTYPE on
 pre-UniPro-1.8 hosts
Date: Thu, 26 Nov 2026 03:10:09 +0000
Message-Id: <20261126031008.27506-2-iasnezhkov@gmail.com>
In-Reply-To: <20261126031008.27506-1-iasnezhkov@gmail.com>
References: <20261126031008.27506-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795662608; l=2543;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=YrBMBmuL5NKxL84xOFnaZv26ZBNhisc42ddVi587G/A=;
 b=Z6ARB/7QAgKI8p7XSX+o58Vfecfx+i8gOurM6LZ6lQucWkUyedj8N25BSDpFp+JUSqREl0RxC
 vywAruoAct0Ak0AKKdKfz3tVkaWOOu/jxXinlpWEMpaC5SGer+CIOnV
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ufs_mtk_pre_pwr_change() calls ufshcd_dme_configure_adapt() on every
power mode change, which writes PA_TXHSADAPTTYPE (0x15d4) even when
passing PA_NO_ADAPT. PA_TXHSADAPTTYPE was introduced in UniPro 1.8, and
ufs_mtk_get_controller_version() sets host->hw_ver.major = 3 only when
PA_LOCALVERINFO >= UFS_UNIPRO_VER_1_8 (leaving older hosts at major = 2).

On pre-UniPro-1.8 MediaTek hosts such as MT6789 (UFS 2.2, HS-G3 rate B),
the DME write fails on every gear change with
"dme-set: attr-id 0x15d4 val 0x3 failed 0 retries". While mainline
ufshcd_change_power_mode() ignores the PRE_CHANGE return value after
commit d3eba21c7170 ("scsi: ufs: core: Introduce a new ufshcd vops
negotiate_pwr_mode()"), older stable kernels still discard the
negotiated parameters on PRE_CHANGE failure, and mainline still emits
spurious DME-SET errors on every power-mode transition.

Return early from ufs_mtk_pre_pwr_change() when host->hw_ver.major < 3
so pre-UniPro-1.8 hosts do not write PA_TXHSADAPTTYPE, and simplify the
remaining major >= 3 branch.

Fixes: 7212d624f863 ("scsi: ufs: host: mediatek: Fix PWM mode switch issue")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
Changes since v1:
- Corrected Fixes tag from e1e25d1b8996 to 7212d624f863.
- Updated commit description for mainline post-d3eba21c7170 behavior.
- Found on hardware and drafted with an AI coding assistant.

 drivers/ufs/host/ufs-mediatek.c | 19 ++++++++-----------
 1 file changed, 8 insertions(+), 11 deletions(-)

diff --git a/drivers/ufs/host/ufs-mediatek.c b/drivers/ufs/host/ufs-mediatek.c
index 7691349..38d05ac 100644
--- a/drivers/ufs/host/ufs-mediatek.c
+++ b/drivers/ufs/host/ufs-mediatek.c
@@ -1468,21 +1468,18 @@ static int ufs_mtk_pre_pwr_change(struct ufs_hba *hba,
 		return ret;
 	}
 
+	if (host->hw_ver.major < 3)
+		return ret;
+
 	if (dev_req_params->pwr_rx == FAST_MODE ||
 	    dev_req_params->pwr_rx == FASTAUTO_MODE) {
-		if (host->hw_ver.major >= 3) {
-			ret = ufshcd_dme_configure_adapt(hba,
-						   dev_req_params->gear_tx,
-						   PA_INITIAL_ADAPT);
-		} else {
-			ret = ufshcd_dme_configure_adapt(hba,
-				   dev_req_params->gear_tx,
-				   PA_NO_ADAPT);
-		}
+		ret = ufshcd_dme_configure_adapt(hba,
+						 dev_req_params->gear_tx,
+						 PA_INITIAL_ADAPT);
 	} else {
 		ret = ufshcd_dme_configure_adapt(hba,
-			   dev_req_params->gear_tx,
-			   PA_NO_ADAPT);
+						 dev_req_params->gear_tx,
+						 PA_NO_ADAPT);
 	}
 
 	return ret;
-- 
2.54.0 (Apple Git-157)

