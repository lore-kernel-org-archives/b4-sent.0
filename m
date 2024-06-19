From: Hsiao Chien Sung <shawn.sung@mediatek.com>
Date: Thu, 20 Jun 2024 01:27:09 +0800
Subject: [PATCH 4/5] drm/mediatek: Support "Pre-multiplied" blending in
 Mixer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240620-blend-v1-4-72670072ca20@mediatek.com>
References: <20240620-blend-v1-0-72670072ca20@mediatek.com>
In-Reply-To: <20240620-blend-v1-0-72670072ca20@mediatek.com>
To: Chun-Kuang Hu <chunkuang.hu@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, David Airlie <airlied@gmail.com>, 
 Daniel Vetter <daniel@ffwll.ch>, Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: dri-devel@lists.freedesktop.org, linux-mediatek@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Hsiao Chien Sung <shawn.sung@mediatek.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718818030; l=936;
 i=shawn.sung@mediatek.com; s=20240616; h=from:subject:message-id;
 bh=3bQjcoj+V0e9su0dM39EChvPukc7zStbrzEBWWh/Frw=;
 b=tmGg6oENStsgX78tH+bSHouFVDAfE2H7VBaEIK/gPa76rctdyJWSPy0rnc5TkdUO5Jnni8zSK
 fbpepZ4ykebB0sXZivN86VVGHO6snBnajwCVvviUw2iYjuEzcz//B+b
X-Developer-Key: i=shawn.sung@mediatek.com; a=ed25519;
 pk=lq1w8BuWDINX+4JHjGHhhbAU5ICP+cL9VCj7wn+cEDA=
X-Endpoint-Received: by B4 Relay for shawn.sung@mediatek.com/20240616 with auth_id=172
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support "Pre-multiplied" alpha blending mode in Mixer.
Before this patch, only the coverage mode is supported.

Signed-off-by: Hsiao Chien Sung <shawn.sung@mediatek.com>
---
 drivers/gpu/drm/mediatek/mtk_ethdr.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/mediatek/mtk_ethdr.c b/drivers/gpu/drm/mediatek/mtk_ethdr.c
index 48b714994492..bc43d0d760c1 100644
--- a/drivers/gpu/drm/mediatek/mtk_ethdr.c
+++ b/drivers/gpu/drm/mediatek/mtk_ethdr.c
@@ -177,7 +177,8 @@ void mtk_ethdr_layer_config(struct device *dev, unsigned int idx,
 		alpha_con |= state->base.alpha & MIXER_ALPHA;
 	}
 
-	if (state->base.pixel_blend_mode == DRM_MODE_BLEND_PIXEL_NONE)
+	if (state->base.pixel_blend_mode == DRM_MODE_BLEND_PIXEL_NONE ||
+	    state->base.pixel_blend_mode == DRM_MODE_BLEND_PREMULTI)
 		alpha_con |= PREMULTI_SOURCE;
 	else
 		alpha_con |= NON_PREMULTI_SOURCE;

-- 
Git-146)

