From: Hsiao Chien Sung <shawn.sung@mediatek.com>
Date: Sun, 16 Jun 2024 16:29:19 +0800
Subject: [PATCH 09/13] drm/mediatek: Fix XRGB setting error in OVL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240616-mediatek-drm-next-v1-9-7e8f9cf785d8@mediatek.com>
References: <20240616-mediatek-drm-next-v1-0-7e8f9cf785d8@mediatek.com>
In-Reply-To: <20240616-mediatek-drm-next-v1-0-7e8f9cf785d8@mediatek.com>
To: Chun-Kuang Hu <chunkuang.hu@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, David Airlie <airlied@gmail.com>, 
 Daniel Vetter <daniel@ffwll.ch>, Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 CK Hu <ck.hu@mediatek.com>, Bibby Hsieh <bibby.hsieh@mediatek.com>, 
 Daniel Kurtz <djkurtz@chromium.org>, YT Shen <yt.shen@mediatek.com>, 
 Mao Huang <littlecvr@chromium.org>, "Nancy.Lin" <nancy.lin@mediatek.com>
Cc: dri-devel@lists.freedesktop.org, linux-mediatek@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Hsiao Chien Sung <shawn.sung@mediatek.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718526553; l=2836;
 i=shawn.sung@mediatek.com; s=20240616; h=from:subject:message-id;
 bh=vVW9D7krUv/QeI7mKMXg4dCoJYZZZHxYjH8XtvTllws=;
 b=QoL51j2R0DiY+OHpy49e3QAW6LGgdoVCPECx4xnWLYMZrD3YfeTfIC47sGwymgVf4ZbeyXm38
 Fq2J9Sfl+eXBwiwskTMoIlnl52iizChvE30QSBSkFtxhw2+0cG/HEO3
X-Developer-Key: i=shawn.sung@mediatek.com; a=ed25519;
 pk=lq1w8BuWDINX+4JHjGHhhbAU5ICP+cL9VCj7wn+cEDA=
X-Endpoint-Received: by B4 Relay for shawn.sung@mediatek.com/20240616 with auth_id=172
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CONST_BLD must be enabled for XRGB formats although the alpha channel
can be ignored, or OVL will still read the value from memory.
This error only affects CRC generation.

Fixes: 119f5173628a ("drm/mediatek: Add DRM Driver for Mediatek SoC MT8173.")
Signed-off-by: Hsiao Chien Sung <shawn.sung@mediatek.com>
---
 drivers/gpu/drm/mediatek/mtk_disp_ovl.c | 14 ++++++++++++--
 1 file changed, 12 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/mediatek/mtk_disp_ovl.c b/drivers/gpu/drm/mediatek/mtk_disp_ovl.c
index 738244a6164e..615b75919d1b 100644
--- a/drivers/gpu/drm/mediatek/mtk_disp_ovl.c
+++ b/drivers/gpu/drm/mediatek/mtk_disp_ovl.c
@@ -38,6 +38,7 @@
 #define DISP_REG_OVL_PITCH_MSB(n)		(0x0040 + 0x20 * (n))
 #define OVL_PITCH_MSB_2ND_SUBBUF			BIT(16)
 #define DISP_REG_OVL_PITCH(n)			(0x0044 + 0x20 * (n))
+#define OVL_CONST_BLEND					BIT(28)
 #define DISP_REG_OVL_RDMA_CTRL(n)		(0x00c0 + 0x20 * (n))
 #define DISP_REG_OVL_RDMA_GMC(n)		(0x00c8 + 0x20 * (n))
 #define DISP_REG_OVL_ADDR_MT2701		0x0040
@@ -428,6 +429,7 @@ void mtk_ovl_layer_config(struct device *dev, unsigned int idx,
 	unsigned int fmt = pending->format;
 	unsigned int offset = (pending->y << 16) | pending->x;
 	unsigned int src_size = (pending->height << 16) | pending->width;
+	unsigned int ignore_pixel_alpha = 0;
 	unsigned int con;
 	bool is_afbc = pending->modifier != DRM_FORMAT_MOD_LINEAR;
 	union overlay_pitch {
@@ -449,6 +451,14 @@ void mtk_ovl_layer_config(struct device *dev, unsigned int idx,
 	if (state->base.fb && state->base.fb->format->has_alpha)
 		con |= OVL_CON_AEN | OVL_CON_ALPHA;
 
+	/* CONST_BLD must be enabled for XRGB formats although the alpha channel
+	 * can be ignored, or OVL will still read the value from memory.
+	 * For RGB888 related formats, whether CONST_BLD is enabled or not won't
+	 * affect the result. Therefore we use !has_alpha as the condition.
+	 */
+	if (state->base.fb && !state->base.fb->format->has_alpha)
+		ignore_pixel_alpha = OVL_CONST_BLEND;
+
 	if (pending->rotation & DRM_MODE_REFLECT_Y) {
 		con |= OVL_CON_VIRT_FLIP;
 		addr += (pending->height - 1) * pending->pitch;
@@ -464,8 +474,8 @@ void mtk_ovl_layer_config(struct device *dev, unsigned int idx,
 
 	mtk_ddp_write_relaxed(cmdq_pkt, con, &ovl->cmdq_reg, ovl->regs,
 			      DISP_REG_OVL_CON(idx));
-	mtk_ddp_write_relaxed(cmdq_pkt, overlay_pitch.split_pitch.lsb, &ovl->cmdq_reg, ovl->regs,
-			      DISP_REG_OVL_PITCH(idx));
+	mtk_ddp_write_relaxed(cmdq_pkt, overlay_pitch.split_pitch.lsb | ignore_pixel_alpha,
+			      &ovl->cmdq_reg, ovl->regs, DISP_REG_OVL_PITCH(idx));
 	mtk_ddp_write_relaxed(cmdq_pkt, src_size, &ovl->cmdq_reg, ovl->regs,
 			      DISP_REG_OVL_SRC_SIZE(idx));
 	mtk_ddp_write_relaxed(cmdq_pkt, offset, &ovl->cmdq_reg, ovl->regs,

-- 
Git-146)

