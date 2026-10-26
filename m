From: Xi Zhang <xz.ca.cn@gmail.com>
Date: Mon, 26 Oct 2026 16:16:55 -0300
Subject: [PATCH 7/8] drm/msm: force mode_changed on color_mgmt_changed, not
 just ctm
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-msm-dpu-res-clean-v1-7-f46130a8a717@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793042236; l=1219;
 i=xz.ca.cn@gmail.com; s=20261026; h=from:subject:message-id;
 bh=Wo3tEP0RL/iVZrlVbjqizqGErC2YhsS/kVeKWgJ1UBY=;
 b=Ka8elEcmKvRmXT6MxV7shh8QtW1BUM34m8jO69Pppxv34hT1WkBIwW/du7byZGl5q+mivl9sR
 dI2mCiPGOpqDqqYH8xMs8i3CNw8qaTypCBy8azN6b6SYsV6VTBNx13P
X-Developer-Key: i=xz.ca.cn@gmail.com; a=ed25519;
 pk=aRUll5L3eJbwG8Y4BO9uySKGzm+Uy+Ccei9prnRVZRs=
X-Endpoint-Received: by B4 Relay for xz.ca.cn@gmail.com/20261026 with auth_id=1328
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dpu_crtc_atomic_check calls dpu_crtc_assign_resources when
color_mgmt_changed is set, which is unsafe outside of full modeset.

Set allow_modeset and mode_changed when color_mgmt_changed is set,
not just when ctm is changed.

Also would fix
commit 42f62cd79578 ("drm/msm/dpu: try reserving the DSPP-less LM first")
which was reverted.

Closes: https://gitlab.freedesktop.org/drm/msm/-/work_items/102

Signed-off-by: Xi Zhang <xz.ca.cn@gmail.com>
---
 drivers/gpu/drm/msm/msm_atomic.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/msm/msm_atomic.c b/drivers/gpu/drm/msm/msm_atomic.c
index a8babf1dbe0d..6f0f30b0728a 100644
--- a/drivers/gpu/drm/msm/msm_atomic.c
+++ b/drivers/gpu/drm/msm/msm_atomic.c
@@ -195,8 +195,7 @@ int msm_atomic_check(struct drm_device *dev, struct drm_atomic_commit *state)
 	 */
 	for_each_oldnew_crtc_in_state(state, crtc, old_crtc_state,
 				      new_crtc_state, i) {
-		if ((old_crtc_state->ctm && !new_crtc_state->ctm) ||
-		    (!old_crtc_state->ctm && new_crtc_state->ctm)) {
+		if (new_crtc_state->color_mgmt_changed) {
 			new_crtc_state->mode_changed = true;
 			state->allow_modeset = true;
 		}

-- 
2.55.0

