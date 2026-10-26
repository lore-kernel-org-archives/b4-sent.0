From: Xi Zhang <xz.ca.cn@gmail.com>
Date: Mon, 26 Oct 2026 16:16:51 -0300
Subject: [PATCH 3/8] drm/msm/dpu: use common helper cleanup function in cmd
 mode disable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-msm-dpu-res-clean-v1-3-f46130a8a717@gmail.com>
References: <20261026-msm-dpu-res-clean-v1-0-f46130a8a717@gmail.com>
In-Reply-To: <20261026-msm-dpu-res-clean-v1-0-f46130a8a717@gmail.com>
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Xi Zhang <xz.ca.cn@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793042236; l=2525;
 i=xz.ca.cn@gmail.com; s=20261026; h=from:subject:message-id;
 bh=gZ1zC6u8j/CKI/qwlb5BfuiGxnpobk+GG3KE6oTYs3E=;
 b=djxSX4RkzGCjSlbrGlDEDQTemoOHmmwWVv3U6EqgJqc3gjSxfRZHYmyKyI7l0tIR3a4tgvWE1
 KaOqgDsEm/lCj2DQejbY1fYbGErlUkz9xTZzHmPKFYvGiYzrUtBbytL
X-Developer-Key: i=xz.ca.cn@gmail.com; a=ed25519;
 pk=aRUll5L3eJbwG8Y4BO9uySKGzm+Uy+Ccei9prnRVZRs=
X-Endpoint-Received: by B4 Relay for xz.ca.cn@gmail.com/20261026 with auth_id=1328
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cmd mode encoder previously did not clean up dsc, or LMs during
disable.

Change to use the common dpu_encoder_helper_phys_cleanup function
for cmd mode disable.

Also do not set intf_cfg.mode_3d during disable:
dpu_encoder_helper_get_3d_blend_mode accesses drm_encoder->crtc->state
directly so intf_cfg.mode_3d weren't set to expected value for disable.
intf_cfg.mode_3d is also ignored by ctl->ops.reset_intf_cfg.

Signed-off-by: Xi Zhang <xz.ca.cn@gmail.com>
---
 drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c          |  4 ++--
 drivers/gpu/drm/msm/disp/dpu1/dpu_encoder_phys_cmd.c | 10 +---------
 2 files changed, 3 insertions(+), 11 deletions(-)

diff --git a/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c b/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
index 09afc0681248..0ab151369c99 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
+++ b/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
@@ -2332,8 +2332,8 @@ void dpu_encoder_helper_phys_cleanup(struct dpu_encoder_phys *phys_enc)
 		dpu_enc->dsc = NULL;
 	}
 
-	intf_cfg.stream_sel = 0; /* Don't care value for video mode */
-	intf_cfg.mode_3d = dpu_encoder_helper_get_3d_blend_mode(phys_enc);
+	intf_cfg.stream_sel = 0; /* Ignored by reset_intf_cfg */
+	intf_cfg.mode_3d = 0; /* Ignored by reset_intf_cfg */
 	intf_cfg.dsc = dpu_encoder_helper_get_dsc(phys_enc);
 	intf_cfg.cwb = dpu_enc->cwb_mask;
 
diff --git a/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder_phys_cmd.c b/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder_phys_cmd.c
index 45079ee59cf6..111f9dd5e053 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder_phys_cmd.c
+++ b/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder_phys_cmd.c
@@ -538,7 +538,6 @@ static void dpu_encoder_phys_cmd_disable(struct dpu_encoder_phys *phys_enc)
 {
 	struct dpu_encoder_phys_cmd *cmd_enc =
 		to_dpu_encoder_phys_cmd(phys_enc);
-	struct dpu_hw_ctl *ctl;
 
 	if (phys_enc->enable_state == DPU_ENC_DISABLED) {
 		DPU_ERROR_CMDENC(cmd_enc, "already disabled\n");
@@ -566,14 +565,7 @@ static void dpu_encoder_phys_cmd_disable(struct dpu_encoder_phys *phys_enc)
 			phys_enc->hw_pp->ops.disable_tearcheck(phys_enc->hw_pp);
 	}
 
-	if (phys_enc->hw_intf->ops.bind_pingpong_blk) {
-		phys_enc->hw_intf->ops.bind_pingpong_blk(
-				phys_enc->hw_intf,
-				PINGPONG_NONE);
-
-		ctl = phys_enc->hw_ctl;
-		ctl->ops.update_pending_flush_intf(ctl, phys_enc->hw_intf->idx);
-	}
+	dpu_encoder_helper_phys_cleanup(phys_enc);
 
 	phys_enc->enable_state = DPU_ENC_DISABLED;
 }

-- 
2.55.0

