From: Ben Grisdale <bengris32@protonmail.ch>
Date: Thu, 05 Nov 2026 14:35:22 +0000
Subject: [PATCH RESEND] drm/mediatek: dsi: Fix handling of long packet
 reads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-mtk-dsi-long-read-v1-1-0b6d9b67c011@protonmail.ch>
To: Chun-Kuang Hu <chunkuang.hu@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 CK Hu <ck.hu@mediatek.com>, shaoming chen <shaoming.chen@mediatek.com>
Cc: dri-devel@lists.freedesktop.org, linux-mediatek@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 stable@vger.kernel.org, Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793889321; l=1763;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=VXV9DuiW9rx/vH2b4BfioyjlslOvRRPzghK8kVYZ1/0=;
 b=XjMPJTyBrxC8GcQXU4Xc888DUrmAcQ8CQFMmTuLs1KLt6phlxiKfEhGbE+pGWUgA6C+EVwIob
 yH8TFU7VXmwAcVXJ0pyd2yVg0U+p3LsAvEeE3lNBv338z8Tpq74YB/P
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mtk_dsi_host_transfer() decides where the payload starts in the
received data based on the byte count returned by mtk_dsi_recv_cnt(),
treating anything longer than 2 bytes as a long packet.

This breaks long read responses with a 1 or 2 byte payload: they are
treated as short packets, so the word count from the packet header is
copied into rx_buf instead of the payload.

Fix this by checking the packet's data type instead of inferring it
from the length.

Fixes: 21898816831f ("drm/mediatek: add dsi transfer function")
Cc: stable@vger.kernel.org
Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
 drivers/gpu/drm/mediatek/mtk_dsi.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/mediatek/mtk_dsi.c b/drivers/gpu/drm/mediatek/mtk_dsi.c
index f82506e10fd5..de4414b51abb 100644
--- a/drivers/gpu/drm/mediatek/mtk_dsi.c
+++ b/drivers/gpu/drm/mediatek/mtk_dsi.c
@@ -165,6 +165,10 @@
 	(type == MIPI_DSI_GENERIC_READ_REQUEST_2_PARAM) || \
 	(type == MIPI_DSI_DCS_READ))
 
+#define MTK_DSI_IS_LONG_RESP(type) \
+	(((type) == MIPI_DSI_RX_GENERIC_LONG_READ_RESPONSE) || \
+	((type) == MIPI_DSI_RX_DCS_LONG_READ_RESPONSE))
+
 struct mtk_phy_timing {
 	u32 lpx;
 	u32 da_hs_prepare;
@@ -1171,7 +1175,7 @@ static ssize_t mtk_dsi_host_transfer(struct mipi_dsi_host *host,
 
 	recv_cnt = mtk_dsi_recv_cnt(read_data[0], read_data);
 
-	if (recv_cnt > 2)
+	if (MTK_DSI_IS_LONG_RESP(read_data[0]))
 		src_addr = &read_data[4];
 	else
 		src_addr = &read_data[1];

---
base-commit: 2efb7a11f1aa4d2dc285fe2680cca22cb9f72f64
change-id: 20261019-mtk-dsi-long-read-45bc8e49d08b

Best regards,
--
Ben Grisdale <bengris32@protonmail.ch>
-- 
Ben Grisdale <bengris32@protonmail.ch>

