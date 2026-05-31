From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sun, 31 May 2026 23:16:51 +0200
Subject: [PATCH] drm/msm/dp: add EDID re-read retry in
 msm_dp_panel_get_modes()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260531-drm_plug_flaky_edid-v1-1-2708c16dce97@oldschoolsolutions.biz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MTQqAIBBA4avErBNM+6GuEiGiYw2VhVIU0d2Tl
 t/ivQciBsIIXfZAwJMibT6hyDMwk/YjMrLJILioeSULZsOq9uUYlVv0fCu0ZJkxTVNKV7uWt5D
 KPaCj67/2w/t+pFTkKmUAAAA=
X-Change-ID: 20260531-drm_plug_flaky_edid-cc7743f6f909
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780262215; l=2645;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=LLV/YX7XX1GqZAGEgoltmCK2iL/5xctBrdp5zxAObKo=;
 b=GLYLpyJ3FvnDVIbCdCUxHGXOTUaswQADP+GHzOeIi2qhcCoAlZ0jzcODmoI9JDRZtetZK6chQ
 gVkQC5yQIGPDzai1VWFPfxL0t+lcFo2vpqclOYDlQGoYhwoCzMPgEqp
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

drm_edid_read_ddc() can return a structurally valid EDID from which
drm_edid_connector_add_modes() still returns zero modes. This triggers
the error:

  [drm:msm_dp_bridge_get_modes [msm]] *ERROR* failed to get DP sink
   modes, rc=0

even though the link is ready. Since the EDID is only read once, this
error persists and the display comes up with 640x480 resolution.

Add a retry of drm_edid_read_ddc() inside get_modes() when the initial
read produces no usable modes. The bad EDID is freed before retrying
and container_of ensures access to the DDC channel. This directly
addresses the observed "valid but empty/garbage" EDID case on
flaky DP plugs and adapters.

I tested this on a few of my "flaky" type-c to HDMI adapters and hubs,
getting no "retry failed" messages and the desired resolution. Without
the patch most plugs would result in 640x480 external display.

Fixes: [5bea90ad9743d2] "drm/msm/dp: switch to struct drm_edid"

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 drivers/gpu/drm/msm/dp/dp_panel.c | 28 ++++++++++++++++++++++++++++
 1 file changed, 28 insertions(+)

diff --git a/drivers/gpu/drm/msm/dp/dp_panel.c b/drivers/gpu/drm/msm/dp/dp_panel.c
index 6bb021820d7c5..4f27c8129b0ef 100644
--- a/drivers/gpu/drm/msm/dp/dp_panel.c
+++ b/drivers/gpu/drm/msm/dp/dp_panel.c
@@ -327,11 +327,39 @@ u32 msm_dp_panel_get_mode_bpp(struct msm_dp_panel *msm_dp_panel,
 int msm_dp_panel_get_modes(struct msm_dp_panel *msm_dp_panel,
 	struct drm_connector *connector)
 {
+	int modes;
+	int retry;
+	struct msm_dp_panel_private *panel;
+
 	if (!msm_dp_panel) {
 		DRM_ERROR("invalid input\n");
 		return -EINVAL;
 	}
 
+	panel = container_of(msm_dp_panel, struct msm_dp_panel_private, msm_dp_panel);
+
+	if (msm_dp_panel->drm_edid) {
+		modes = drm_edid_connector_add_modes(connector);
+		if (modes > 0)
+			return modes;
+
+		drm_edid_free(msm_dp_panel->drm_edid);
+		msm_dp_panel->drm_edid = NULL;
+	}
+
+	for (retry = 0; retry < 5; retry++) {
+		usleep_range(20000, 25000);
+		msm_dp_panel->drm_edid =
+			drm_edid_read_ddc(connector, &panel->aux->ddc);
+		if (msm_dp_panel->drm_edid)
+			break;
+
+		drm_dbg_dp(connector->dev,
+			   "get_modes re-read attempt %d/5 failed\n",
+			   retry + 1);
+	}
+
+	drm_edid_connector_update(connector, msm_dp_panel->drm_edid);
 	if (msm_dp_panel->drm_edid)
 		return drm_edid_connector_add_modes(connector);
 

---
base-commit: 7da7f07112610a520567421dd2ffcb51beaefbcc
change-id: 20260531-drm_plug_flaky_edid-cc7743f6f909

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

