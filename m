From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Fri, 03 Apr 2026 17:30:26 +0530
Subject: [PATCH] drm/mediatek: mtk_dpi: Open-code drm_simple_encoder_init()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-drm-mediatek-opencode-encoder-init-v1-1-7be86241b876@zohomail.in>
X-B4-Tracking: v=1; b=H4sIANmrz2kC/yXNwQrCMBCE4Vcpe3YhNiEHX0U81GSiqzQpmyhC6
 bsb7Wn4Lv+sVKGCSqdhJcVbqpTccTwMFO5TvoEldtNoRm+csRx15hlRpoYnlwU5lAjeR1myNLb
 eWg8XXEqWemhRJPn8T86X3fV1fSC0X5m27Qu6nSeShgAAAA==
X-Change-ID: 20260403-drm-mediatek-opencode-encoder-init-36336e4c4ff3
To: Chun-Kuang Hu <chunkuang.hu@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: Thomas Zimmermann <tzimmermann@suse.de>, 
 dri-devel@lists.freedesktop.org, linux-mediatek@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775217629; l=2101;
 i=shivamkalra98@zohomail.in; s=20260402; h=from:subject:message-id;
 bh=9DjXSfOgfUU5yg/kiJD0QlllCcJ+4tIybh7zqyvb0Gs=;
 b=CrHLxQL+7xEDYiixoSol8OG9gkFNY9o81VC5AbB67EE257gn+LlkpL+BZzcJKQZPavGvGk+Bf
 t59unbL8axaCODm0YSBCBgdyugg5VYLhB8fx3mf9gsqeuXShXgfhmcW
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=U8kQSxcte8P8iZ6zB7phIj+Yl+i/5ntifBGuclgypx8=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260402 with auth_id=716
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The helper drm_simple_encoder_init() is a trivial wrapper around
drm_encoder_init() that only provides a static drm_encoder_funcs with
.destroy set to drm_encoder_cleanup(). Open-code the initialization
with a driver-specific instance of drm_encoder_funcs and remove the
dependency on drm_simple_kms_helper.

Suggested-by: Thomas Zimmermann <tzimmermann@suse.de>
Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
Addresses the "Open-code drm_simple_encoder_init()" task from
Documentation/gpu/todo.rst.
---
 drivers/gpu/drm/mediatek/mtk_dpi.c | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/mediatek/mtk_dpi.c b/drivers/gpu/drm/mediatek/mtk_dpi.c
index 53360b5d12ba..5b83ca6aecb2 100644
--- a/drivers/gpu/drm/mediatek/mtk_dpi.c
+++ b/drivers/gpu/drm/mediatek/mtk_dpi.c
@@ -25,8 +25,8 @@
 #include <drm/drm_bridge_connector.h>
 #include <drm/drm_crtc.h>
 #include <drm/drm_edid.h>
+#include <drm/drm_encoder.h>
 #include <drm/drm_of.h>
-#include <drm/drm_simple_kms_helper.h>
 
 #include "mtk_ddp_comp.h"
 #include "mtk_disp_drv.h"
@@ -993,6 +993,10 @@ static const struct drm_bridge_funcs mtk_dpi_bridge_funcs = {
 	.debugfs_init = mtk_dpi_debugfs_init,
 };
 
+static const struct drm_encoder_funcs mtk_dpi_encoder_funcs = {
+	.destroy = drm_encoder_cleanup,
+};
+
 void mtk_dpi_start(struct device *dev)
 {
 	struct mtk_dpi *dpi = dev_get_drvdata(dev);
@@ -1026,8 +1030,8 @@ static int mtk_dpi_bind(struct device *dev, struct device *master, void *data)
 	int ret;
 
 	dpi->mmsys_dev = priv->mmsys_dev;
-	ret = drm_simple_encoder_init(drm_dev, &dpi->encoder,
-				      DRM_MODE_ENCODER_TMDS);
+	ret = drm_encoder_init(drm_dev, &dpi->encoder, &mtk_dpi_encoder_funcs,
+			       DRM_MODE_ENCODER_TMDS, NULL);
 	if (ret) {
 		dev_err(dev, "Failed to initialize decoder: %d\n", ret);
 		return ret;

---
base-commit: 4b9c36c83b34f710da9573291404f6a2246251c1
change-id: 20260403-drm-mediatek-opencode-encoder-init-36336e4c4ff3

Best regards,
--  
Shivam Kalra <shivamkalra98@zohomail.in>

