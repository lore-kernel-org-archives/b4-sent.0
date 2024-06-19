From: Hsiao Chien Sung <shawn.sung@mediatek.com>
Date: Wed, 19 Jun 2024 22:30:51 +0800
Subject: [PATCH v2 10/14] drm/mediatek: Support more 10bit formats in OVL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240619-mediatek-drm-next-v2-10-abf68f46f8d2@mediatek.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718807531; l=3007;
 i=shawn.sung@mediatek.com; s=20240616; h=from:subject:message-id;
 bh=mrSvvVZ/mFrWd71ZaekcuPkD1pvqPrfCwDLvo7/MQM0=;
 b=m1P49byuk48IKl42u3xDxi+FR7/4d7bKlfXD7KFC0FQozyD/EWnb7AIOi/PtZRvjHtNrnifNN
 2BK6KgEjQ5nCr+VyCmA9f5W8XZDoZUsrQMk4yr7XRGVVOTi9CeX6s+0
X-Developer-Key: i=shawn.sung@mediatek.com; a=ed25519;
 pk=lq1w8BuWDINX+4JHjGHhhbAU5ICP+cL9VCj7wn+cEDA=
X-Endpoint-Received: by B4 Relay for shawn.sung@mediatek.com/20240616 with auth_id=172
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support more 10bit formats in OVL.

Reviewed-by: CK Hu <ck.hu@mediatek.com>
Reviewed-by: AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Signed-off-by: Hsiao Chien Sung <shawn.sung@mediatek.com>
---
 drivers/gpu/drm/mediatek/mtk_disp_ovl.c | 32 +++++++++++++++++++++++++++++---
 1 file changed, 29 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/mediatek/mtk_disp_ovl.c b/drivers/gpu/drm/mediatek/mtk_disp_ovl.c
index 3724f77c5b6b..671b1258d9c8 100644
--- a/drivers/gpu/drm/mediatek/mtk_disp_ovl.c
+++ b/drivers/gpu/drm/mediatek/mtk_disp_ovl.c
@@ -74,6 +74,22 @@
 #define	OVL_CON_VIRT_FLIP	BIT(9)
 #define	OVL_CON_HORZ_FLIP	BIT(10)
 
+static inline bool is_10bit_rgb(u32 fmt)
+{
+	switch (fmt) {
+	case DRM_FORMAT_XRGB2101010:
+	case DRM_FORMAT_ARGB2101010:
+	case DRM_FORMAT_RGBX1010102:
+	case DRM_FORMAT_RGBA1010102:
+	case DRM_FORMAT_XBGR2101010:
+	case DRM_FORMAT_ABGR2101010:
+	case DRM_FORMAT_BGRX1010102:
+	case DRM_FORMAT_BGRA1010102:
+		return true;
+	}
+	return false;
+}
+
 static const u32 mt8173_formats[] = {
 	DRM_FORMAT_XRGB8888,
 	DRM_FORMAT_ARGB8888,
@@ -91,12 +107,18 @@ static const u32 mt8173_formats[] = {
 static const u32 mt8195_formats[] = {
 	DRM_FORMAT_XRGB8888,
 	DRM_FORMAT_ARGB8888,
+	DRM_FORMAT_XRGB2101010,
 	DRM_FORMAT_ARGB2101010,
 	DRM_FORMAT_BGRX8888,
 	DRM_FORMAT_BGRA8888,
+	DRM_FORMAT_BGRX1010102,
 	DRM_FORMAT_BGRA1010102,
 	DRM_FORMAT_ABGR8888,
 	DRM_FORMAT_XBGR8888,
+	DRM_FORMAT_XBGR2101010,
+	DRM_FORMAT_ABGR2101010,
+	DRM_FORMAT_RGBX1010102,
+	DRM_FORMAT_RGBA1010102,
 	DRM_FORMAT_RGB888,
 	DRM_FORMAT_BGR888,
 	DRM_FORMAT_RGB565,
@@ -256,9 +278,7 @@ static void mtk_ovl_set_bit_depth(struct device *dev, int idx, u32 format,
 	reg = readl(ovl->regs + DISP_REG_OVL_CLRFMT_EXT);
 	reg &= ~OVL_CON_CLRFMT_BIT_DEPTH_MASK(idx);
 
-	if (format == DRM_FORMAT_RGBA1010102 ||
-	    format == DRM_FORMAT_BGRA1010102 ||
-	    format == DRM_FORMAT_ARGB2101010)
+	if (is_10bit_rgb(format))
 		bit_depth = OVL_CON_CLRFMT_10_BIT;
 
 	reg |= OVL_CON_CLRFMT_BIT_DEPTH(bit_depth, idx);
@@ -371,17 +391,23 @@ static unsigned int ovl_fmt_convert(struct mtk_disp_ovl *ovl, unsigned int fmt)
 		return OVL_CON_CLRFMT_RGB888(ovl) | OVL_CON_BYTE_SWAP;
 	case DRM_FORMAT_RGBX8888:
 	case DRM_FORMAT_RGBA8888:
+	case DRM_FORMAT_RGBX1010102:
+	case DRM_FORMAT_RGBA1010102:
 		return OVL_CON_CLRFMT_RGBA8888;
 	case DRM_FORMAT_BGRX8888:
 	case DRM_FORMAT_BGRA8888:
+	case DRM_FORMAT_BGRX1010102:
 	case DRM_FORMAT_BGRA1010102:
 		return OVL_CON_CLRFMT_BGRA8888;
 	case DRM_FORMAT_XRGB8888:
 	case DRM_FORMAT_ARGB8888:
+	case DRM_FORMAT_XRGB2101010:
 	case DRM_FORMAT_ARGB2101010:
 		return OVL_CON_CLRFMT_ARGB8888;
 	case DRM_FORMAT_XBGR8888:
 	case DRM_FORMAT_ABGR8888:
+	case DRM_FORMAT_XBGR2101010:
+	case DRM_FORMAT_ABGR2101010:
 		return OVL_CON_CLRFMT_ABGR8888;
 	case DRM_FORMAT_UYVY:
 		return OVL_CON_CLRFMT_UYVY | OVL_CON_MTX_YUV_TO_RGB;

-- 
Git-146)

