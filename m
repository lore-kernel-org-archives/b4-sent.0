From: Xi Zhang <xz.ca.cn@gmail.com>
Date: Mon, 26 Oct 2026 17:25:45 -0300
Subject: [PATCH v2 4/6] drm/msm/dpu: Match setup_dither cleanup to the way
 it was set up
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-msm-dpu-res-clean-v2-4-3d864435186e@gmail.com>
References: <20261026-msm-dpu-res-clean-v2-0-3d864435186e@gmail.com>
In-Reply-To: <20261026-msm-dpu-res-clean-v2-0-3d864435186e@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793046364; l=1544;
 i=xz.ca.cn@gmail.com; s=20261026; h=from:subject:message-id;
 bh=i8W21Uwim0c1+zeph5hx6bDBWdsis2GxB2oH6BEEkww=;
 b=euKQ8P4qZyAu2dx4tItsfmlM/IJot2mVulrG4mVSxuASX2xKy1XyWLOa7VkLDFzhCk8fR2qdD
 /MbwySbCj91Dkv0VseguSPHw0//cMrQ+k0rXv8jzl8mWfiN89+ytO69
X-Developer-Key: i=xz.ca.cn@gmail.com; a=ed25519;
 pk=aRUll5L3eJbwG8Y4BO9uySKGzm+Uy+Ccei9prnRVZRs=
X-Endpoint-Received: by B4 Relay for xz.ca.cn@gmail.com/20261026 with auth_id=1328
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Cleanup hw_pp->ops.setup_dither with NULL for all PINGPONGs,
matching the way it was setup during enable.

Signed-off-by: Xi Zhang <xz.ca.cn@gmail.com>
---
 drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c b/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
index d967deb34c77..acea64ebd24e 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
+++ b/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
@@ -1320,7 +1320,7 @@ static void _dpu_encoder_virt_enable_helper(struct drm_encoder *drm_enc)
 	if (dpu_enc->disp_info.intf_type == INTF_DSI &&
 			!WARN_ON(dpu_enc->num_phys_encs == 0)) {
 		unsigned bpc = dpu_enc->connector->display_info.bpc;
-		for (i = 0; i < MAX_CHANNELS_PER_ENC; i++) {
+		for (i = 0; i < ARRAY_SIZE(dpu_enc->hw_pp); i++) {
 			if (!dpu_enc->hw_pp[i])
 				continue;
 			_dpu_encoder_setup_dither(dpu_enc->hw_pp[i], bpc);
@@ -2306,8 +2306,10 @@ void dpu_encoder_helper_phys_cleanup(struct dpu_encoder_phys *phys_enc)
 		}
 	}
 
-	if (phys_enc->hw_pp && phys_enc->hw_pp->ops.setup_dither)
-		phys_enc->hw_pp->ops.setup_dither(phys_enc->hw_pp, NULL);
+	if (dpu_enc->disp_info.intf_type == INTF_DSI)
+		for (i = 0; i < ARRAY_SIZE(dpu_enc->hw_pp); i++)
+			if (dpu_enc->hw_pp[i] && dpu_enc->hw_pp[i]->ops.setup_dither)
+				dpu_enc->hw_pp[i]->ops.setup_dither(dpu_enc->hw_pp[i], NULL);
 
 	if (dpu_enc->cwb_mask)
 		dpu_encoder_helper_phys_setup_cwb(phys_enc, false);

-- 
2.55.0

