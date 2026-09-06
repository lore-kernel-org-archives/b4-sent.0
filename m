From: Miles Krause <mileskrause5200@gmail.com>
Date: Sun, 06 Sep 2026 15:43:48 -0400
Subject: [PATCH] drm/meson: fix device_node leak in
 meson_encoder_dsi_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-meson-dsi-of-node-leak-v1-1-9d183560279d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAHPCnWoC/x3MTQqAIBBA4avErBswsR+7SrSQnGqoNByIILp70
 vJbvPeAUGIS6IsHEl0sHENGVRYwrS4shOyzQSvdKKsaPEhiQC+MccYQPeFObsPWmM5a7+q20pD
 jM9HM9z8exvf9AD146hxoAAAA
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Nicolas Belin <nbelin@baylibre.com>, 
 Jagan Teki <jagan@amarulasolutions.com>
Cc: dri-devel@lists.freedesktop.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Miles Krause <mileskrause5200@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788723828; l=1903;
 i=mileskrause5200@gmail.com; s=20260906; h=from:subject:message-id;
 bh=MzPOZoQJIZouNhopaY53pEz59ebt1korUstt2TswX5s=;
 b=n7TDRXCuDuGLEEk4/VPeuku3N6NRmryW5wydClhaAsHiByeSusM+Nz8hYgNrxmDeRC7QSYUTm
 N24E5yCU0OhCuzbiwy8lCyAhHI/GXTrgxQ923wq10hBuHkzwXY3Jr/P
X-Developer-Key: i=mileskrause5200@gmail.com; a=ed25519;
 pk=zcIfq4TGtPwMRJUW6WsbE2zLHvOMwk6ZyT/CGd6XzyI=
X-Endpoint-Received: by B4 Relay for mileskrause5200@gmail.com/20260906 with auth_id=1010
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

meson_encoder_dsi_probe() looks up the DSI transceiver's device node
with of_graph_get_remote_node() and hands it to
of_drm_find_and_get_bridge(), but never drops the reference that the
lookup returned.

of_graph_get_remote_node() returns the node with its refcount
incremented, and of_drm_find_and_get_bridge() takes its own reference
on the bridge it finds, so 'remote' is leaked on every path once the
lookup succeeds: on the -EPROBE_DEFER return taken when no bridge is
found, and on a fully successful probe alike.

The two sibling encoders in this driver already handle this correctly.
meson_encoder_cvbs_probe() calls of_node_put(remote) immediately after
of_drm_find_and_get_bridge(), and meson_encoder_hdmi_probe() releases
the node both on its error path and after of_find_device_by_node().

Release the reference in the same place meson_encoder_cvbs_probe()
does, which covers both the error and the success path.

Fixes: 42dcf15f901c ("drm/meson: add DSI encoder")
Signed-off-by: Miles Krause <mileskrause5200@gmail.com>
---
 drivers/gpu/drm/meson/meson_encoder_dsi.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/meson/meson_encoder_dsi.c b/drivers/gpu/drm/meson/meson_encoder_dsi.c
index 3e422b612f74..3fe604496294 100644
--- a/drivers/gpu/drm/meson/meson_encoder_dsi.c
+++ b/drivers/gpu/drm/meson/meson_encoder_dsi.c
@@ -120,6 +120,7 @@ int meson_encoder_dsi_probe(struct meson_drm *priv)
 	}
 
 	meson_encoder_dsi->bridge.next_bridge = of_drm_find_and_get_bridge(remote);
+	of_node_put(remote);
 	if (!meson_encoder_dsi->bridge.next_bridge)
 		return dev_err_probe(priv->dev, -EPROBE_DEFER,
 				     "Failed to find DSI transceiver bridge\n");

---
base-commit: 88405f0ad1d5c680afe3ea0ce9345fa9e1deaac8
change-id: 20260906-meson-dsi-of-node-leak-744899da5712

Best regards,
-- 
Miles Krause <mileskrause5200@gmail.com>

