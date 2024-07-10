From: Hsiao Chien Sung <shawn.sung@mediatek.com>
Date: Wed, 10 Jul 2024 16:37:22 +0800
Subject: [PATCH v2 4/5] drm/mediatek: Support "Pre-multiplied" blending in
 Mixer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240710-alpha-blending-v2-4-d4b505e6980a@mediatek.com>
References: <20240710-alpha-blending-v2-0-d4b505e6980a@mediatek.com>
In-Reply-To: <20240710-alpha-blending-v2-0-d4b505e6980a@mediatek.com>
To: Chun-Kuang Hu <chunkuang.hu@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, David Airlie <airlied@gmail.com>, 
 Daniel Vetter <daniel@ffwll.ch>, Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: dri-devel@lists.freedesktop.org, linux-mediatek@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Hsiao Chien Sung <shawn.sung@mediatek.corp-partner.google.com>, 
 Hsiao Chien Sung <shawn.sung@mediatek.com>
X-Mailer: b4 0.12.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720600641; l=2211;
 i=shawn.sung@mediatek.com; s=20240710; h=from:subject:message-id;
 bh=L3aSZMNI/5e4YMPf4nqEmkejhrP0vtCut0YLE0pQ+qs=;
 b=ar4ZvKNsZZFYYYRhlTblHJLqdhIfL3KbfOwFhbVhs5KkRPAiTvE1rR+Str+/zCYpkhyaY5p02
 Tl997s/5QS1DTNJ2iL/1yJNE2W14+DA0gH+3bn6P9S3mTbkZrknCaQD
X-Developer-Key: i=shawn.sung@mediatek.com; a=ed25519;
 pk=VRlGZ3diQkQtpDd8fCL9/mx+TpZStm08pg8UPaG1NGc=
X-Endpoint-Received: by B4 Relay for shawn.sung@mediatek.com/20240710 with auth_id=184
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support "Pre-multiplied" alpha blending mode in Mixer.
Before this patch, only the coverage mode is supported.

To replace the default setting that is set in mtk_ethdr_config(),
we change mtk_ddp_write_mask() to mtk_ddp_write(), and this change will
also reset the NON_PREMULTI_SOURCE bit that was assigned in
mtk_ethdr_config(). Therefore, we must still set NON_PREMULTI_SOURCE bit
if the blend mode is not DRM_MODE_BLEND_PREMULTI.

Signed-off-by: Hsiao Chien Sung <shawn.sung@mediatek.com>
---
 drivers/gpu/drm/mediatek/mtk_ethdr.c | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/mediatek/mtk_ethdr.c b/drivers/gpu/drm/mediatek/mtk_ethdr.c
index 80ccdad3741b..d1d9cf8b10e1 100644
--- a/drivers/gpu/drm/mediatek/mtk_ethdr.c
+++ b/drivers/gpu/drm/mediatek/mtk_ethdr.c
@@ -36,6 +36,7 @@
 #define MIX_SRC_L0_EN				BIT(0)
 #define MIX_L_SRC_CON(n)		(0x28 + 0x18 * (n))
 #define NON_PREMULTI_SOURCE			(2 << 12)
+#define PREMULTI_SOURCE				(3 << 12)
 #define MIX_L_SRC_SIZE(n)		(0x30 + 0x18 * (n))
 #define MIX_L_SRC_OFFSET(n)		(0x34 + 0x18 * (n))
 #define MIX_FUNC_DCM0			0x120
@@ -176,6 +177,11 @@ void mtk_ethdr_layer_config(struct device *dev, unsigned int idx,
 		alpha_con |= state->base.alpha & MIXER_ALPHA;
 	}
 
+	if (state->base.pixel_blend_mode == DRM_MODE_BLEND_PREMULTI)
+		alpha_con |= PREMULTI_SOURCE;
+	else
+		alpha_con |= NON_PREMULTI_SOURCE;
+
 	if ((state->base.fb && !state->base.fb->format->has_alpha) ||
 	    state->base.pixel_blend_mode == DRM_MODE_BLEND_PIXEL_NONE) {
 		/*
@@ -193,8 +199,7 @@ void mtk_ethdr_layer_config(struct device *dev, unsigned int idx,
 	mtk_ddp_write(cmdq_pkt, pending->height << 16 | align_width, &mixer->cmdq_base,
 		      mixer->regs, MIX_L_SRC_SIZE(idx));
 	mtk_ddp_write(cmdq_pkt, offset, &mixer->cmdq_base, mixer->regs, MIX_L_SRC_OFFSET(idx));
-	mtk_ddp_write_mask(cmdq_pkt, alpha_con, &mixer->cmdq_base, mixer->regs, MIX_L_SRC_CON(idx),
-			   0x1ff);
+	mtk_ddp_write(cmdq_pkt, alpha_con, &mixer->cmdq_base, mixer->regs, MIX_L_SRC_CON(idx));
 	mtk_ddp_write_mask(cmdq_pkt, BIT(idx), &mixer->cmdq_base, mixer->regs, MIX_SRC_CON,
 			   BIT(idx));
 }

-- 
2.43.0

