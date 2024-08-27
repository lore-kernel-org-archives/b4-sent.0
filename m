From: "Jason-JH.Lin" <jason-jh.lin@mediatek.com>
Date: Tue, 27 Aug 2024 22:55:20 +0800
Subject: [PATCH v3 2/2] drm/mediatek: change config_lock from spin_lock to
 spin_lock_irqsave
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-drm-fixup-0819-v3-2-4761005211ec@mediatek.com>
References: <20240827-drm-fixup-0819-v3-0-4761005211ec@mediatek.com>
In-Reply-To: <20240827-drm-fixup-0819-v3-0-4761005211ec@mediatek.com>
To: Chun-Kuang Hu <chunkuang.hu@kernel.org>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: Philipp Zabel <p.zabel@pengutronix.de>, 
 David Airlie <airlied@gmail.com>, Daniel Vetter <daniel@ffwll.ch>, 
 Singo Chang <singo.chang@mediatek.com>, Nancy Lin <nancy.lin@mediatek.com>, 
 "Jason-JH.Lin" <jason-jh.lin@mediatek.com>, 
 Project_Global_Chrome_Upstream_Group@mediatek.com, 
 dri-devel@lists.freedesktop.org, linux-mediatek@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724770559; l=3389;
 i=jason-jh.lin@mediatek.com; s=20240718; h=from:subject:message-id;
 bh=qmIEDrv7vEydnkYLajQteZQg7GKHc0xz1SItk+ixJMg=;
 b=BMUDPPx43HxuqLgPxE38r9SfCUMKzAyjGAJfDPSQ8Fp8MAR5/tJSt8tP35PMgK/0E70FFaATs
 XMmR4p7wiooD3Dn/qzlUeXxxFLuDK7Kd7rIrAvazmTQhyF3ZtSK5qKg
X-Developer-Key: i=jason-jh.lin@mediatek.com; a=ed25519;
 pk=7Hn+BnFBlPrluT5ks5tKVWb3f7O/bMBs6qEemVJwqOo=
X-Endpoint-Received: by B4 Relay for jason-jh.lin@mediatek.com/20240718 with auth_id=187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Operations within spin_locks are limited to fast memory access and
confirmation of minimum lock duration.

Although using spin_lock with config_lock seems to ensure shorter hold
times, it is safer to use spin_lock_irqsave due to potential deadlocks
and nested interrupt scenarios in interrupt contexts.

So change config_lock from spin_lock to spin_lock_irqsave.

Fixes: 7f82d9c43879 ("drm/mediatek: Clear pending flag when cmdq packet is done")
Signed-off-by: Jason-JH.Lin <jason-jh.lin@mediatek.com>
---
 drivers/gpu/drm/mediatek/mtk_crtc.c | 23 +++++++++++++----------
 1 file changed, 13 insertions(+), 10 deletions(-)

diff --git a/drivers/gpu/drm/mediatek/mtk_crtc.c b/drivers/gpu/drm/mediatek/mtk_crtc.c
index b752c0b46383..d7f0926f896d 100644
--- a/drivers/gpu/drm/mediatek/mtk_crtc.c
+++ b/drivers/gpu/drm/mediatek/mtk_crtc.c
@@ -108,14 +108,16 @@ static void mtk_crtc_finish_page_flip(struct mtk_crtc *mtk_crtc)
 
 static void mtk_drm_finish_page_flip(struct mtk_crtc *mtk_crtc)
 {
+	unsigned long flags;
+
 	drm_crtc_handle_vblank(&mtk_crtc->base);
 
-	spin_lock(&mtk_crtc->config_lock);
+	spin_lock_irqsave(&mtk_crtc->config_lock, flags);
 	if (!mtk_crtc->config_updating && mtk_crtc->pending_needs_vblank) {
 		mtk_crtc_finish_page_flip(mtk_crtc);
 		mtk_crtc->pending_needs_vblank = false;
 	}
-	spin_unlock(&mtk_crtc->config_lock);
+	spin_unlock_irqrestore(&mtk_crtc->config_lock, flags);
 }
 
 #if IS_REACHABLE(CONFIG_MTK_CMDQ)
@@ -313,16 +315,16 @@ static void ddp_cmdq_cb(struct mbox_client *cl, void *mssg)
 	struct mtk_crtc *mtk_crtc = container_of(cmdq_cl, struct mtk_crtc, cmdq_client);
 	struct mtk_crtc_state *state;
 	unsigned int i;
+	unsigned long flags;
 
 	if (data->sta < 0)
 		return;
 
 	state = to_mtk_crtc_state(mtk_crtc->base.state);
 
-	spin_lock(&mtk_crtc->config_lock);
-
+	spin_lock_irqsave(&mtk_crtc->config_lock, flags);
 	if (mtk_crtc->config_updating) {
-		spin_unlock(&mtk_crtc->config_lock);
+		spin_unlock_irqrestore(&mtk_crtc->config_lock, flags);
 		goto ddp_cmdq_cb_out;
 	}
 
@@ -352,7 +354,7 @@ static void ddp_cmdq_cb(struct mbox_client *cl, void *mssg)
 		mtk_crtc->pending_async_planes = false;
 	}
 
-	spin_unlock(&mtk_crtc->config_lock);
+	spin_unlock_irqrestore(&mtk_crtc->config_lock, flags);
 
 ddp_cmdq_cb_out:
 
@@ -585,12 +587,13 @@ static void mtk_crtc_update_config(struct mtk_crtc *mtk_crtc, bool needs_vblank)
 	struct mtk_drm_private *priv = crtc->dev->dev_private;
 	unsigned int pending_planes = 0, pending_async_planes = 0;
 	int i;
+	unsigned long flags;
 
 	mutex_lock(&mtk_crtc->hw_lock);
 
-	spin_lock(&mtk_crtc->config_lock);
+	spin_lock_irqsave(&mtk_crtc->config_lock, flags);
 	mtk_crtc->config_updating = true;
-	spin_unlock(&mtk_crtc->config_lock);
+	spin_unlock_irqrestore(&mtk_crtc->config_lock, flags);
 
 	if (needs_vblank)
 		mtk_crtc->pending_needs_vblank = true;
@@ -645,9 +648,9 @@ static void mtk_crtc_update_config(struct mtk_crtc *mtk_crtc, bool needs_vblank)
 		mbox_client_txdone(mtk_crtc->cmdq_client.chan, 0);
 	}
 #endif
-	spin_lock(&mtk_crtc->config_lock);
+	spin_lock_irqsave(&mtk_crtc->config_lock, flags);
 	mtk_crtc->config_updating = false;
-	spin_unlock(&mtk_crtc->config_lock);
+	spin_unlock_irqrestore(&mtk_crtc->config_lock, flags);
 
 	mutex_unlock(&mtk_crtc->hw_lock);
 }

-- 
2.43.0

