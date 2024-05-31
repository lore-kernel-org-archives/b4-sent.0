From: Sam Ravnborg <sam@ravnborg.org>
Date: Fri, 31 May 2024 22:37:45 +0200
Subject: [PATCH 1/2] drm/mediatek: Drop chain_mode_fixup call in
 mode_valid()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240531-bridge_chain_mode-v1-1-8b49e36c5dd3@ravnborg.org>
References: <20240531-bridge_chain_mode-v1-0-8b49e36c5dd3@ravnborg.org>
In-Reply-To: <20240531-bridge_chain_mode-v1-0-8b49e36c5dd3@ravnborg.org>
To: dri-devel@lists.freedesktop.org, 
 Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>
Cc: Sam Ravnborg <sam@ravnborg.org>, Maxime Ripard <mripard@kernel.org>, 
 Laurent Pinchart <laurent.pinchart+renesas@ideasonboard.com>, 
 Chun-Kuang Hu <chunkuang.hu@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 Dafna Hirschfeld <dafna.hirschfeld@collabora.com>, 
 linux-mediatek@lists.infradead.org, linux-arm-kernel@lists.infradead.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717187864; l=2519;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=g2zVbjZcqkh2hiGY7iFzlHZfu3znz4lPoZjniC5HZeQ=;
 b=w1EiPCAd7or7aUVHQp8xtVRJNOSZi3rzqoyygcHYSDL0tXhq+4GnhDrFo1QaJLFVumuIe3eIJ3h4
 mLJiwpcJBf0dYmx6OK/rqorlTGUd/cXH7dmKWbVIQxReLwBc+/tZ
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The mode_valid implementation had a call to
drm_bridge_chain_mode_fixup() which would be wrong as the mode_valid is
not allowed to change anything - only to validate the mode.

As the next bridge is often/always a connector the call had no effect
anyway. So drop it.

From the git history I could see this call was included in the original
version of the driver so there was no help there to find out why it was
added in the first place. But a lot has changed since the initial driver
were added and is seems safe to remove the call now.

v4:
  - Link to v3: https://lore.kernel.org/dri-devel/20220717174454.46616-4-sam@ravnborg.org/
  - Rebase, and added acks/rb
v3:
  - Link to v2: https://lore.kernel.org/dri-devel/20211020181901.2114645-6-sam@ravnborg.org/
v2:
  - Link to v1: https://lore.kernel.org/dri-devel/20210722062246.2512666-6-sam@ravnborg.org/

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Reviewed-by: Maxime Ripard <mripard@kernel.org>
Reviewed-by: Laurent Pinchart <laurent.pinchart+renesas@ideasonboard.com>
Acked-by: Chun-Kuang Hu <chunkuang.hu@kernel.org>
Cc: Chun-Kuang Hu <chunkuang.hu@kernel.org>
Cc: Philipp Zabel <p.zabel@pengutronix.de>
Cc: Matthias Brugger <matthias.bgg@gmail.com>
Cc: Dafna Hirschfeld <dafna.hirschfeld@collabora.com>
Cc: linux-mediatek@lists.infradead.org
Cc: linux-arm-kernel@lists.infradead.org
---
 drivers/gpu/drm/mediatek/mtk_hdmi.c | 11 -----------
 1 file changed, 11 deletions(-)

diff --git a/drivers/gpu/drm/mediatek/mtk_hdmi.c b/drivers/gpu/drm/mediatek/mtk_hdmi.c
index 6e1cca97a654..0a90fe448d14 100644
--- a/drivers/gpu/drm/mediatek/mtk_hdmi.c
+++ b/drivers/gpu/drm/mediatek/mtk_hdmi.c
@@ -1208,22 +1208,11 @@ mtk_hdmi_bridge_mode_valid(struct drm_bridge *bridge,
 			   const struct drm_display_mode *mode)
 {
 	struct mtk_hdmi *hdmi = hdmi_ctx_from_bridge(bridge);
-	struct drm_bridge *next_bridge;
 
 	dev_dbg(hdmi->dev, "xres=%d, yres=%d, refresh=%d, intl=%d clock=%d\n",
 		mode->hdisplay, mode->vdisplay, drm_mode_vrefresh(mode),
 		!!(mode->flags & DRM_MODE_FLAG_INTERLACE), mode->clock * 1000);
 
-	next_bridge = drm_bridge_get_next_bridge(&hdmi->bridge);
-	if (next_bridge) {
-		struct drm_display_mode adjusted_mode;
-
-		drm_mode_init(&adjusted_mode, mode);
-		if (!drm_bridge_chain_mode_fixup(next_bridge, mode,
-						 &adjusted_mode))
-			return MODE_BAD;
-	}
-
 	if (hdmi->conf) {
 		if (hdmi->conf->cea_modes_only && !drm_match_cea_mode(mode))
 			return MODE_BAD;

-- 
2.34.1

