From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: chunkuang.hu@kernel.org, p.zabel@pengutronix.de
Cc: airlied@gmail.com, simona@ffwll.ch, matthias.bgg@gmail.com, 
 angelogioacchino.delregno@collabora.com, dri-devel@lists.freedesktop.org, 
 linux-mediatek@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH] drm/mediatek: dsi: return tx_len for write transfers in
 mtk_dsi_host_transfer()
Date: Thu, 26 Nov 2026 00:33:11 +0000
Message-Id: <20261126003311.49008-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795653191; l=1225;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=d9GTUwGLxs30Q2Foqvf23WnszilxicEoDpegYZ+sWi4=;
 b=/fZZBXK5jnT5BP/TtqUfZI5IQwPDnaE4fgeIwJ9Z81lnWz9ZALqBGiVUqXmoMC5TSkjDvWuQq
 N7m4jW48yBhAzS3lOhi2PIxBquPw7E7OhOKlcgfZqaWuypo5wDlZ/VF
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Per struct mipi_dsi_host_ops .transfer() documentation in
include/drm/drm_mipi_dsi.h, on success .transfer() must return the
number of bytes transmitted for write packets or the number of bytes
received for read packets.

mtk_dsi_host_transfer() currently sets recv_cnt = 0 for non-read
messages, returning 0 instead of msg->tx_len. Callers checking for short
writes against msg->tx_len observe a spurious 0-byte transfer.

Return msg->tx_len on successful write transfers.

Found and drafted with an AI coding assistant.

Fixes: 21898816831f ("drm/mediatek: add dsi transfer function")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 drivers/gpu/drm/mediatek/mtk_dsi.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/mediatek/mtk_dsi.c b/drivers/gpu/drm/mediatek/mtk_dsi.c
index f82506e..e2179b4 100644
--- a/drivers/gpu/drm/mediatek/mtk_dsi.c
+++ b/drivers/gpu/drm/mediatek/mtk_dsi.c
@@ -1156,7 +1156,7 @@ static ssize_t mtk_dsi_host_transfer(struct mipi_dsi_host *host,
 		goto restore_dsi_mode;
 
 	if (!MTK_DSI_HOST_IS_READ(msg->type)) {
-		recv_cnt = 0;
+		recv_cnt = msg->tx_len;
 		goto restore_dsi_mode;
 	}
 
-- 
2.54.0 (Apple Git-157)


