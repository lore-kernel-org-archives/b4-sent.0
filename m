From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Tue, 02 Jun 2026 20:18:48 +0200
Subject: [PATCH v2] drm/msm/dp: add missing drm_edid_connector_update()
 before add_modes on cached EDID
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260602-drm_plug_flaky_edid-v2-1-1269fb942299@oldschoolsolutions.biz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32OQQ6CMBREr0K6tqYtSsWV9zCEYPsLP1ZK+oGIh
 LtbOYDLN8m8mZURRARi12xlEWYkDH0CdciY6Zq+BY42MVNCFeKcS27jqx781NbON8+lBouWG6P
 1KXeFK0XJUnOI4PC9W+9V4g5pDHHZR2b5S//7ZsklV1pcjCysgVLfgrdkuhA8BT+N6SMdH/hh1
 bZtX6MI4UHDAAAA
X-Change-ID: 20260531-drm_plug_flaky_edid-cc7743f6f909
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Douglas Anderson <dianders@chromium.org>, 
 Jani Nikula <jani.nikula@intel.com>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 dmitry.baryshkov@oss.qualcomm.com, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780424350; l=2429;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=YZ7y8qgyyn7uIzSkFbhV3TyNem0jp5eLRvTq7Rc2SfA=;
 b=AfO11WxiGoEU81lVanf8WCGXKyt3VIimcAxGbFc3/GiVujnFc/fY13KIy0UpHPnTk5HvjjVZ2
 T3o35pm+MRoD28BWQjMjEuea2YGRd0uu+Cq+WIQJWWJBdt5W1k/xByk
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After the refactor to struct drm_edid, the fast path in
msm_dp_panel_get_modes() that already held a cached EDID called
drm_edid_connector_add_modes() directly without first calling
drm_edid_connector_update().

The new API requires the update step to associate the EDID with the
connector. Add the missing call. This restores correct behaviour for
the cached-EDID path.

Fixes: 5bea90ad9743 ("drm/msm/dp: switch to struct drm_edid")

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
Hi there,

thank you for the feedback on V1. I dug a little deeper and heeded Janis'
and Dmitry's request to print the "garbage" EDID, and to my surprise it 
was the genuine valid EDID for the display. The code is documented in [1].

That changed the picture a bit - "right" EDID but not tied to the connector.
The retry code does the drm_edid_connector_update() before 
drm_edid_connector_add_modes(), so I only added that missing piece in 
msm_dp_panel_get_modes(). This proves to be sufficient to get a stable
link with the desired resolution. Therefore I dropped the entire re-read 
and retry logic, because it is of course an ugly hack.
I have tested this with my complete collection of adapters and hubs, and
all work well.

[1]: https://github.com/jglathe/linux_ms_dev_kit/tree/jg/flaky_edid_retry

with best regards,

Jens
---
Changes in v2:
- Dropped the retry + re-read logic
- Just add the missing drm_edid_connector_update() in the cached EDID path
- Link to v1: https://lore.kernel.org/r/20260531-drm_plug_flaky_edid-v1-1-2708c16dce97@oldschoolsolutions.biz
---
 drivers/gpu/drm/msm/dp/dp_panel.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/msm/dp/dp_panel.c b/drivers/gpu/drm/msm/dp/dp_panel.c
index 6bb021820d7c5..5b4954e7cb748 100644
--- a/drivers/gpu/drm/msm/dp/dp_panel.c
+++ b/drivers/gpu/drm/msm/dp/dp_panel.c
@@ -332,8 +332,10 @@ int msm_dp_panel_get_modes(struct msm_dp_panel *msm_dp_panel,
 		return -EINVAL;
 	}
 
-	if (msm_dp_panel->drm_edid)
+	if (msm_dp_panel->drm_edid) {
+		drm_edid_connector_update(connector, msm_dp_panel->drm_edid);
 		return drm_edid_connector_add_modes(connector);
+	}
 
 	return 0;
 }

---
base-commit: 7da7f07112610a520567421dd2ffcb51beaefbcc
change-id: 20260531-drm_plug_flaky_edid-cc7743f6f909

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

