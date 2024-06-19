From: Hsiao Chien Sung <shawn.sung@mediatek.com>
Date: Thu, 20 Jun 2024 01:27:08 +0800
Subject: [PATCH 3/5] drm/mediatek: Support "Pre-multiplied" blending in OVL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240620-blend-v1-3-72670072ca20@mediatek.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718818030; l=3803;
 i=shawn.sung@mediatek.com; s=20240616; h=from:subject:message-id;
 bh=DavUw+j//lvUyWdRkM3M0/+G2/7MZYehRHdjvtF7ATk=;
 b=LWKW/d54b/ZZpO3h6Oc9lmFwK+Sj/dMDs9p4n5yrceZyxoQXxu7Vmqo5SS9TRU4A8O/+iB/O8
 hkVn5RoFM4qCwDoqN+s79jfBYu++QIQQR9Lz5012yQOSsvofVtspTlb
X-Developer-Key: i=shawn.sung@mediatek.com; a=ed25519;
 pk=lq1w8BuWDINX+4JHjGHhhbAU5ICP+cL9VCj7wn+cEDA=
X-Endpoint-Received: by B4 Relay for shawn.sung@mediatek.com/20240616 with auth_id=172
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support "Pre-multiplied" alpha blending mode on in OVL.
Before this patch, only the "coverage" mode is supported.

Signed-off-by: Hsiao Chien Sung <shawn.sung@mediatek.com>
---
 drivers/gpu/drm/mediatek/mtk_disp_ovl.c | 32 +++++++++++++++++++++++++-------
 1 file changed, 25 insertions(+), 7 deletions(-)

diff --git a/drivers/gpu/drm/mediatek/mtk_disp_ovl.c b/drivers/gpu/drm/mediatek/mtk_disp_ovl.c
index ad9228fc4dd9..8e9aae36a289 100644
--- a/drivers/gpu/drm/mediatek/mtk_disp_ovl.c
+++ b/drivers/gpu/drm/mediatek/mtk_disp_ovl.c
@@ -52,8 +52,12 @@
 #define GMC_THRESHOLD_HIGH	((1 << GMC_THRESHOLD_BITS) / 4)
 #define GMC_THRESHOLD_LOW	((1 << GMC_THRESHOLD_BITS) / 8)
 
+#define OVL_CON_CLRFMT_MAN	BIT(23)
 #define OVL_CON_BYTE_SWAP	BIT(24)
-#define OVL_CON_MTX_YUV_TO_RGB	(6 << 16)
+
+/* OVL_CON_RGB_SWAP works only if OVL_CON_CLRFMT_MAN is enabled */
+#define OVL_CON_RGB_SWAP	BIT(25)
+
 #define OVL_CON_CLRFMT_RGB	(1 << 12)
 #define OVL_CON_CLRFMT_ARGB8888	(2 << 12)
 #define OVL_CON_CLRFMT_RGBA8888	(3 << 12)
@@ -61,6 +65,11 @@
 #define OVL_CON_CLRFMT_BGRA8888	(OVL_CON_CLRFMT_ARGB8888 | OVL_CON_BYTE_SWAP)
 #define OVL_CON_CLRFMT_UYVY	(4 << 12)
 #define OVL_CON_CLRFMT_YUYV	(5 << 12)
+#define OVL_CON_MTX_YUV_TO_RGB	(6 << 16)
+#define OVL_CON_CLRFMT_PARGB8888 ((3 << 12) | OVL_CON_CLRFMT_MAN)
+#define OVL_CON_CLRFMT_PABGR8888 (OVL_CON_CLRFMT_PARGB8888 | OVL_CON_RGB_SWAP)
+#define OVL_CON_CLRFMT_PBGRA8888 (OVL_CON_CLRFMT_PARGB8888 | OVL_CON_BYTE_SWAP)
+#define OVL_CON_CLRFMT_PRGBA8888 (OVL_CON_CLRFMT_PABGR8888 | OVL_CON_BYTE_SWAP)
 #define OVL_CON_CLRFMT_RGB565(ovl)	((ovl)->data->fmt_rgb565_is_0 ? \
 					0 : OVL_CON_CLRFMT_RGB)
 #define OVL_CON_CLRFMT_RGB888(ovl)	((ovl)->data->fmt_rgb565_is_0 ? \
@@ -382,7 +391,8 @@ void mtk_ovl_layer_off(struct device *dev, unsigned int idx,
 		      DISP_REG_OVL_RDMA_CTRL(idx));
 }
 
-static unsigned int ovl_fmt_convert(struct mtk_disp_ovl *ovl, unsigned int fmt)
+static unsigned int ovl_fmt_convert(struct mtk_disp_ovl *ovl, unsigned int fmt,
+				    unsigned int blend_mode)
 {
 	/* The return value in switch "MEM_MODE_INPUT_FORMAT_XXX"
 	 * is defined in mediatek HW data sheet.
@@ -403,22 +413,30 @@ static unsigned int ovl_fmt_convert(struct mtk_disp_ovl *ovl, unsigned int fmt)
 	case DRM_FORMAT_RGBA8888:
 	case DRM_FORMAT_RGBX1010102:
 	case DRM_FORMAT_RGBA1010102:
-		return OVL_CON_CLRFMT_RGBA8888;
+		return blend_mode == DRM_MODE_BLEND_COVERAGE ?
+		       OVL_CON_CLRFMT_RGBA8888 :
+		       OVL_CON_CLRFMT_PRGBA8888;
 	case DRM_FORMAT_BGRX8888:
 	case DRM_FORMAT_BGRA8888:
 	case DRM_FORMAT_BGRX1010102:
 	case DRM_FORMAT_BGRA1010102:
-		return OVL_CON_CLRFMT_BGRA8888;
+		return blend_mode == DRM_MODE_BLEND_COVERAGE ?
+		       OVL_CON_CLRFMT_BGRA8888 :
+		       OVL_CON_CLRFMT_PBGRA8888;
 	case DRM_FORMAT_XRGB8888:
 	case DRM_FORMAT_ARGB8888:
 	case DRM_FORMAT_XRGB2101010:
 	case DRM_FORMAT_ARGB2101010:
-		return OVL_CON_CLRFMT_ARGB8888;
+		return blend_mode == DRM_MODE_BLEND_COVERAGE ?
+		       OVL_CON_CLRFMT_ARGB8888 :
+		       OVL_CON_CLRFMT_PARGB8888;
 	case DRM_FORMAT_XBGR8888:
 	case DRM_FORMAT_ABGR8888:
 	case DRM_FORMAT_XBGR2101010:
 	case DRM_FORMAT_ABGR2101010:
-		return OVL_CON_CLRFMT_ABGR8888;
+		return blend_mode == DRM_MODE_BLEND_COVERAGE ?
+		       OVL_CON_CLRFMT_ABGR8888 :
+		       OVL_CON_CLRFMT_PABGR8888;
 	case DRM_FORMAT_UYVY:
 		return OVL_CON_CLRFMT_UYVY | OVL_CON_MTX_YUV_TO_RGB;
 	case DRM_FORMAT_YUYV:
@@ -458,7 +476,7 @@ void mtk_ovl_layer_config(struct device *dev, unsigned int idx,
 		return;
 	}
 
-	con = ovl_fmt_convert(ovl, fmt);
+	con = ovl_fmt_convert(ovl, fmt, blend_mode);
 	if (state->base.fb) {
 		con |= OVL_CON_AEN;
 		con |= state->base.alpha & OVL_CON_ALPHA;

-- 
Git-146)

