From: Hsiao Chien Sung <shawn.sung@mediatek.com>
Date: Sun, 16 Jun 2024 16:29:22 +0800
Subject: [PATCH 12/13] drm/mediatek: Support DRM plane alpha in OVL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240616-mediatek-drm-next-v1-12-7e8f9cf785d8@mediatek.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718526553; l=991;
 i=shawn.sung@mediatek.com; s=20240616; h=from:subject:message-id;
 bh=5BJt05q2olOJLyH/qGdDD53kmjnnoM3hvSVC/ZouM1A=;
 b=jCZ7lXGpv+AGtyowVT4z9RF57ghEL/4IapUmjqVDC/g1vyfBCShi0WXvzHVqwsGRGhY5JtcuO
 otzo4pze4POBtP+gxqYbkHSwA7//1+jksNg8PKDBFkHGUP+A3bEX0p9
X-Developer-Key: i=shawn.sung@mediatek.com; a=ed25519;
 pk=lq1w8BuWDINX+4JHjGHhhbAU5ICP+cL9VCj7wn+cEDA=
X-Endpoint-Received: by B4 Relay for shawn.sung@mediatek.com/20240616 with auth_id=172
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Set the plane alpha according to DRM plane property.

Signed-off-by: Hsiao Chien Sung <shawn.sung@mediatek.com>
Reviewed-by: CK Hu <ck.hu@mediatek.com>
---
 drivers/gpu/drm/mediatek/mtk_disp_ovl.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/mediatek/mtk_disp_ovl.c b/drivers/gpu/drm/mediatek/mtk_disp_ovl.c
index 33b58da15ba4..f358dbfed5e3 100644
--- a/drivers/gpu/drm/mediatek/mtk_disp_ovl.c
+++ b/drivers/gpu/drm/mediatek/mtk_disp_ovl.c
@@ -450,8 +450,10 @@ void mtk_ovl_layer_config(struct device *dev, unsigned int idx,
 	}
 
 	con = ovl_fmt_convert(ovl, fmt);
-	if (state->base.fb && state->base.fb->format->has_alpha)
-		con |= OVL_CON_AEN | OVL_CON_ALPHA;
+	if (state->base.fb) {
+		con |= OVL_CON_AEN;
+		con |= state->base.alpha & OVL_CON_ALPHA;
+	}
 
 	/* CONST_BLD must be enabled for XRGB formats although the alpha channel
 	 * can be ignored, or OVL will still read the value from memory.

-- 
Git-146)

