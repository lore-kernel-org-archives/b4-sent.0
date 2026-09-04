From: Johan Jonker <jbx6244@gmail.com>
Date: Fri, 04 Sep 2026 12:17:19 +0200
Subject: [PATCH v3] drm/rockchip: rk3066_hdmi: convert to
 devm_drm_bridge_alloc() API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260904-drm-v3-1-5b36532a3b72@gmail.com>
X-B4-Tracking: v=1; b=H4sIAK6ammoC/x2MSwqFMAwAryJZv0Kx/q/ycBHbqFlYJRERxLtbX
 Q4zzAVKwqTQZRcIHay8xgTul4GfMU5kOCSG3OaVbW1hgiymDXXjSu8chgpSOaCSGQSjn992Qd1
 JXrEJjXx++39/3w/ouI4PbgAAAA==
To: Sandy Huang <hjc@rock-chips.com>, 
 =?utf-8?q?Heiko_St=C3=BCbner?= <heiko@sntech.de>, 
 Andy Yan <andy.yan@rock-chips.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?H=C3=BCseyin_BIYIK?= <boogiepop@gmx.com>, 
 Johan Jonker <jbx6244@gmail.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788517040; l=1613;
 i=jbx6244@gmail.com; s=20260824; h=from:subject:message-id;
 bh=qWT53GXoOigdQ+erxp3d408shOqYOF+aDMQefkq/Jcs=;
 b=IGdDcQbuWqvrHDkGDHwvL4L5TmWy9kQdIO4Ze6skcvw1cYPzJMVH8k/kHGr0/8asjWG9BamhJ
 SAP9yAsgbn2AWzCty0wEJWmCHyyJubNkEO7HMxCWnoIbvNrG3T8Lzmh
X-Developer-Key: i=jbx6244@gmail.com; a=ed25519;
 pk=MK5Flx1ndjAF0uwXdNm8VvvoghD4KWCNd2hQE8QGyl0=
X-Endpoint-Received: by B4 Relay for jbx6244@gmail.com/20260824 with auth_id=971
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hüseyin BIYIK <boogiepop@gmx.com>

The function devm_drm_bridge_alloc() is the new API for allocating DRM bridges.
This conversion was missed during the initial conversion of all bridges to
the new API.

Signed-off-by: Hüseyin BIYIK <boogiepop@gmx.com>
Signed-off-by: Johan Jonker <jbx6244@gmail.com>
---

Changed V3:
rebase
remove driver_private
---
 drivers/gpu/drm/rockchip/rk3066_hdmi.c | 9 ++++-----
 1 file changed, 4 insertions(+), 5 deletions(-)

diff --git a/drivers/gpu/drm/rockchip/rk3066_hdmi.c b/drivers/gpu/drm/rockchip/rk3066_hdmi.c
index f28d6a883e09..05dbbcc6f7b0 100644
--- a/drivers/gpu/drm/rockchip/rk3066_hdmi.c
+++ b/drivers/gpu/drm/rockchip/rk3066_hdmi.c
@@ -702,8 +702,6 @@ rk3066_hdmi_register(struct drm_device *drm, struct rk3066_hdmi *hdmi)
 	drm_encoder_init(drm, encoder, &rk3066_hdmi_encoder_funcs,
 			 DRM_MODE_ENCODER_TMDS, NULL);
 
-	hdmi->bridge.driver_private = hdmi;
-	hdmi->bridge.funcs = &rk3066_hdmi_bridge_funcs;
 	hdmi->bridge.ops = DRM_BRIDGE_OP_DETECT |
 			   DRM_BRIDGE_OP_EDID |
 			   DRM_BRIDGE_OP_HDMI |
@@ -747,9 +745,10 @@ static int rk3066_hdmi_bind(struct device *dev, struct device *master,
 	int irq;
 	int ret;
 
-	hdmi = devm_kzalloc(dev, sizeof(*hdmi), GFP_KERNEL);
-	if (!hdmi)
-		return -ENOMEM;
+	hdmi = devm_drm_bridge_alloc(dev, struct rk3066_hdmi, bridge,
+				     &rk3066_hdmi_bridge_funcs);
+	if (IS_ERR(hdmi))
+		return PTR_ERR(hdmi);
 
 	hdmi->dev = dev;
 	hdmi->drm_dev = drm;

---
base-commit: 9d80aa4617b32f5054c5aa471d06b66704854935
change-id: 20260904-drm-9d7835c33ad6

Best regards,
-- 
Johan Jonker <jbx6244@gmail.com>

