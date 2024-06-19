From: Hsiao Chien Sung <shawn.sung@mediatek.com>
Date: Wed, 19 Jun 2024 22:30:54 +0800
Subject: [PATCH v2 13/14] drm/mediatek: Support DRM plane alpha in Mixer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240619-mediatek-drm-next-v2-13-abf68f46f8d2@mediatek.com>
References: <20240619-mediatek-drm-next-v2-0-abf68f46f8d2@mediatek.com>
In-Reply-To: <20240619-mediatek-drm-next-v2-0-abf68f46f8d2@mediatek.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718807531; l=984;
 i=shawn.sung@mediatek.com; s=20240616; h=from:subject:message-id;
 bh=wRuukHEj6ar3MzrXsZ6wMBC1YWkwtR1Cd5NiPWkH4fQ=;
 b=mXffXrDFXrHd8s/MoUIUUbt/P7yp7KbzAnh4zOUemxlxHfiBroL5wHk35yF0/DMHdRIAWLfR2
 d4oOEUBWMpeA2jzbQDTSaw/jhwFjI+xMSQDX1+voFSDc/N3erHWWKGS
X-Developer-Key: i=shawn.sung@mediatek.com; a=ed25519;
 pk=lq1w8BuWDINX+4JHjGHhhbAU5ICP+cL9VCj7wn+cEDA=
X-Endpoint-Received: by B4 Relay for shawn.sung@mediatek.com/20240616 with auth_id=172
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Set the plane alpha according to DRM plane property.

Reviewed-by: CK Hu <ck.hu@mediatek.com>
Reviewed-by: AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Signed-off-by: Hsiao Chien Sung <shawn.sung@mediatek.com>
---
 drivers/gpu/drm/mediatek/mtk_ethdr.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/mediatek/mtk_ethdr.c b/drivers/gpu/drm/mediatek/mtk_ethdr.c
index bf5826b7e776..36021cb8df62 100644
--- a/drivers/gpu/drm/mediatek/mtk_ethdr.c
+++ b/drivers/gpu/drm/mediatek/mtk_ethdr.c
@@ -170,8 +170,10 @@ void mtk_ethdr_layer_config(struct device *dev, unsigned int idx,
 		return;
 	}
 
-	if (state->base.fb && state->base.fb->format->has_alpha)
-		alpha_con = MIXER_ALPHA_AEN | MIXER_ALPHA;
+	if (state->base.fb) {
+		alpha_con |= MIXER_ALPHA_AEN;
+		alpha_con |= state->base.alpha & MIXER_ALPHA;
+	}
 
 	if (state->base.fb && !state->base.fb->format->has_alpha) {
 		/*

-- 
Git-146)

