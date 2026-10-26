From: Xi Zhang <xz.ca.cn@gmail.com>
Date: Mon, 26 Oct 2026 16:16:54 -0300
Subject: [PATCH 6/8] drm/msm/dpu: workaround res re-assignment issues by
 pairing enc/crtc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-msm-dpu-res-clean-v1-6-f46130a8a717@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793042236; l=1740;
 i=xz.ca.cn@gmail.com; s=20261026; h=from:subject:message-id;
 bh=3eiBb0uy0PBNKjp2IH6yVXShmpVfE6rEzfXROTQjPv0=;
 b=ycxSfaEHnf/r9SC/zlyhmgTTleLJJJn92cKvzii6Bit0CyIas1C355iPIhMAqv0NA6PlhVHZC
 dulUR+CXhM7DEBZrrlKO277amomkcrzgmo04Y0S7FeLxt7KmbuRk4vy
X-Developer-Key: i=xz.ca.cn@gmail.com; a=ed25519;
 pk=aRUll5L3eJbwG8Y4BO9uySKGzm+Uy+Ccei9prnRVZRs=
X-Endpoint-Received: by B4 Relay for xz.ca.cn@gmail.com/20261026 with auth_id=1328
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Consider the scenario with 4 crtcs, 3 encoders/displays are
connected. DPU resources is nearly maxed-out, and mode set is
performed on a display which has acquired many dpu resources.
A new crtc is selected by kernel drm for the mode set,
and during atomic_check, the previous crtc won't have a chance
to release its old resources from global_state before the new
crtc tries to allocate new ones. Leading to atomic_check failure.

By having the same crtc for encoder when possible, during
atomic_check each individual crtc will always be able to release
old resources before allocating new ones.

Signed-off-by: Xi Zhang <xz.ca.cn@gmail.com>
---
 drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c | 15 ++++++++++++---
 1 file changed, 12 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c b/drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c
index da3556eb6ecc..13099d6e3ac9 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c
+++ b/drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c
@@ -879,9 +879,18 @@ static int _dpu_kms_drm_obj_init(struct dpu_kms *dpu_kms)
 		}
 	}
 
-	/* All CRTCs are compatible with all encoders */
-	drm_for_each_encoder(encoder, dev)
-		encoder->possible_crtcs = (1 << dev->mode_config.num_crtc) - 1;
+	/* All CRTCs are compatible with all encoders.
+	 * Nevertheless, if enough CRTCs are available, pair up crtc/encoder
+	 * for better resource re-assignments during atomic_check
+	 * from userspace mode set.
+	 */
+	i = 0;
+	drm_for_each_encoder(encoder, dev) {
+		if (dev->mode_config.num_crtc >= num_encoders)
+			encoder->possible_crtcs = 1 << i++;
+		else
+			encoder->possible_crtcs = (1 << dev->mode_config.num_crtc) - 1;
+	}
 
 	return 0;
 }

-- 
2.55.0

