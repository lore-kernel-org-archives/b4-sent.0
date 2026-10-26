From: Xi Zhang <xz.ca.cn@gmail.com>
Date: Mon, 26 Oct 2026 16:16:49 -0300
Subject: [PATCH 1/8] drm/msm/dpu: reset unassigned resource slots to NULL
 on topology update
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-msm-dpu-res-clean-v1-1-f46130a8a717@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793042236; l=2413;
 i=xz.ca.cn@gmail.com; s=20261026; h=from:subject:message-id;
 bh=XV5yIGRicisWHnZm/blBrd+eV6OtBhD/12tGnVobzAE=;
 b=s55jsSFGNJ3ReHkx8AMVQSTN6+WwH+fE1jNAXjs8ys3POrRiBNFM/SLkbQeL00+tsbmzalW/j
 5tLQIjH2UBwCk5ifphW1VkW+DEOnolU72y5xsm2yA+GtfW2h7Q/JDm9
X-Developer-Key: i=xz.ca.cn@gmail.com; a=ed25519;
 pk=aRUll5L3eJbwG8Y4BO9uySKGzm+Uy+Ccei9prnRVZRs=
X-Endpoint-Received: by B4 Relay for xz.ca.cn@gmail.com/20261026 with auth_id=1328
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While this is not currently the case, it may be possible that topology
for cwb and dsc resource requirements change between mode set in the
future.

e.g. when dsc support is added to DisplayPort, dsc may be optionally
enabled and disabled between different modes due to
bandwidth requirements.

Set unassigned resource slots to NULL on topology update to avoid
issues in the future. It's good practice to do so anyway.

Signed-off-by: Xi Zhang <xz.ca.cn@gmail.com>
---
 drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c | 22 +++++++++++++++-------
 1 file changed, 15 insertions(+), 7 deletions(-)

diff --git a/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c b/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
index 0a6be69a3e83..8d2b4d2726f2 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
+++ b/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
@@ -1205,9 +1205,13 @@ static void dpu_encoder_virt_atomic_mode_set(struct drm_encoder *drm_enc,
 						       ARRAY_SIZE(hw_pp));
 	}
 
-	for (i = 0; i < num_cwb; i++) {
-		dpu_enc->hw_cwb[i] = to_dpu_hw_cwb(hw_cwb[i]);
-		cwb_mask |= BIT(dpu_enc->hw_cwb[i]->idx - CWB_0);
+	for (i = 0; i < ARRAY_SIZE(dpu_enc->hw_cwb); i++) {
+		if (i < num_cwb) {
+			dpu_enc->hw_cwb[i] = to_dpu_hw_cwb(hw_cwb[i]);
+			cwb_mask |= BIT(dpu_enc->hw_cwb[i]->idx - CWB_0);
+		} else {
+			dpu_enc->hw_cwb[i] = NULL;
+		}
 	}
 
 	dpu_enc->cwb_mask = cwb_mask;
@@ -1215,16 +1219,20 @@ static void dpu_encoder_virt_atomic_mode_set(struct drm_encoder *drm_enc,
 	num_ctl = dpu_rm_get_assigned_resources(&dpu_kms->rm, global_state,
 		drm_enc->crtc, DPU_HW_BLK_CTL, hw_ctl, ARRAY_SIZE(hw_ctl));
 
-	for (i = 0; i < MAX_CHANNELS_PER_ENC; i++)
+	for (i = 0; i < ARRAY_SIZE(dpu_enc->hw_pp); i++)
 		dpu_enc->hw_pp[i] = i < num_pp ? to_dpu_hw_pingpong(hw_pp[i])
 						: NULL;
 
 	num_dsc = dpu_rm_get_assigned_resources(&dpu_kms->rm, global_state,
 						drm_enc->crtc, DPU_HW_BLK_DSC,
 						hw_dsc, ARRAY_SIZE(hw_dsc));
-	for (i = 0; i < num_dsc; i++) {
-		dpu_enc->hw_dsc[i] = to_dpu_hw_dsc(hw_dsc[i]);
-		dsc_mask |= BIT(dpu_enc->hw_dsc[i]->idx - DSC_0);
+	for (i = 0; i < ARRAY_SIZE(dpu_enc->hw_dsc); i++) {
+		if (i < num_dsc) {
+			dpu_enc->hw_dsc[i] = to_dpu_hw_dsc(hw_dsc[i]);
+			dsc_mask |= BIT(dpu_enc->hw_dsc[i]->idx - DSC_0);
+		} else {
+			dpu_enc->hw_dsc[i] = NULL;
+		}
 	}
 
 	dpu_enc->dsc_mask = dsc_mask;

-- 
2.55.0

