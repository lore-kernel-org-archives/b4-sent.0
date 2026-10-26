From: Xi Zhang <xz.ca.cn@gmail.com>
Date: Mon, 26 Oct 2026 16:16:53 -0300
Subject: [PATCH 5/8] drm/msm/dpu: use cached PINGPONGs from mode set in cwb
 setup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-msm-dpu-res-clean-v1-5-f46130a8a717@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793042236; l=2160;
 i=xz.ca.cn@gmail.com; s=20261026; h=from:subject:message-id;
 bh=Z1k+1OyboIw3FwlS2YQ2mt7AUCLFoNmOxjQChG5wHhQ=;
 b=5WTfGrGDY9HoEPtY+145EtqV+YOoCgU2atdQ0i8iU7JsZE1MEqBQ4meUEIE494qCHpGNhkttD
 946Gcd33reACz0p/fbHprBwGUCfIbHLcjfreDPdoexf9dSQCm1d71oA
X-Developer-Key: i=xz.ca.cn@gmail.com; a=ed25519;
 pk=aRUll5L3eJbwG8Y4BO9uySKGzm+Uy+Ccei9prnRVZRs=
X-Endpoint-Received: by B4 Relay for xz.ca.cn@gmail.com/20261026 with auth_id=1328
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

No functional change intended. Clean up only.

The cached hw_pp should be the same as the ones from
dpu_kms_get_existing_global_state during
dpu_encoder_helper_phys_setup_cwb.

Signed-off-by: Xi Zhang <xz.ca.cn@gmail.com>
---
 drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c | 24 +++---------------------
 1 file changed, 3 insertions(+), 21 deletions(-)

diff --git a/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c b/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
index 7d092398fc99..f1d2482b787b 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
+++ b/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
@@ -2363,11 +2363,6 @@ void dpu_encoder_helper_phys_setup_cwb(struct dpu_encoder_phys *phys_enc,
 	struct dpu_hw_ctl *hw_ctl;
 	struct dpu_hw_cwb_setup_cfg cwb_cfg;
 
-	struct dpu_kms *dpu_kms;
-	struct dpu_global_state *global_state;
-	struct dpu_hw_blk *rt_pp_list[MAX_CHANNELS_PER_ENC];
-	int num_pp;
-
 	if (!phys_enc->hw_wb)
 		return;
 
@@ -2379,33 +2374,20 @@ void dpu_encoder_helper_phys_setup_cwb(struct dpu_encoder_phys *phys_enc,
 		return;
 	}
 
-	dpu_kms = phys_enc->dpu_kms;
-	global_state = dpu_kms_get_existing_global_state(dpu_kms);
-	num_pp = dpu_rm_get_assigned_resources(&dpu_kms->rm, global_state,
-					       phys_enc->parent->crtc,
-					       DPU_HW_BLK_PINGPONG, rt_pp_list,
-					       ARRAY_SIZE(rt_pp_list));
-
-	if (num_pp == 0 || num_pp > MAX_CHANNELS_PER_ENC) {
-		DPU_DEBUG_ENC(dpu_enc, "invalid num_pp %d\n", num_pp);
-		return;
-	}
-
 	/*
 	 * The CWB mux supports using LM or DSPP as tap points. For now,
 	 * always use LM tap point
 	 */
 	cwb_cfg.input = INPUT_MODE_LM_OUT;
 
-	for (int i = 0; i < MAX_CWB_PER_ENC; i++) {
+	for (int i = 0; i < ARRAY_SIZE(dpu_enc->hw_cwb); i++) {
 		hw_cwb = dpu_enc->hw_cwb[i];
 		if (!hw_cwb)
 			continue;
 
 		if (enable) {
-			struct dpu_hw_pingpong *hw_pp =
-					to_dpu_hw_pingpong(rt_pp_list[i]);
-			cwb_cfg.pp_idx = hw_pp->idx;
+			cwb_cfg.pp_idx = i < ARRAY_SIZE(dpu_enc->hw_pp) && dpu_enc->hw_pp[i] ?
+					dpu_enc->hw_pp[i]->idx : PINGPONG_NONE;
 		} else {
 			cwb_cfg.pp_idx = PINGPONG_NONE;
 		}

-- 
2.55.0

