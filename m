From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Thu, 26 Nov 2026 14:40:40 +0100
Subject: [PATCH v2] drm/msm/dp: clear AUX_TRANS_CTRL on reset and keep
 HPD_REFTIMER active
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-drm-msm-dp-aux-resume-v2-1-120ccb6e0578@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0Jm7RjaCFhX3MOwaOkANRZIBwiGc
 HcLHsD81Uv+/28DpuCI4ZFsEGhx7IY+grwkUHe6bwmdjQwylbkQMkMbPHr2aEfU84qBePaE6q4
 aI40qbJ5B3I6BGreev8/qxzybF9XTcXY0OsfTED6neBFH759jERhTNJm+pUbpXJSt1+59rQcP1
 b7vX21rY1TMAAAA
X-Change-ID: 20261125-drm-msm-dp-aux-resume-989fb2b97d65
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795700441; l=5787;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=s04v/WtSg0tv9DLmYm8Y+6H4r+tdC+2uw407I62fgaE=;
 b=IMT91Cheu9fHm1pgb9cPPpSaIlpsgmg4JNnw+EcW80eAr9j9z3tz5toURXd6ZZ6IOhOHZWnZv
 CUODVQxvgEXBGQ5tNnnYK43Fnsp3olg+vXWQpeOT2hvTB0GseOOz9Ac
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On boards using an external HPD bridge (such as Microsoft Surface Pro X /
SC8180X), internal HPD_CTRL is never enabled via msm_dp_aux_hpd_enable().
Across runtime PM or s2idle suspend/resume power collapse, three AUX
controller details prevent clean timeout recovery and link re-training:

1. msm_dp_aux_reset() does not clear REG_DP_AUX_TRANS_CTRL before
   pulsing DP_AUX_CTRL_RESET, and msm_dp_aux_transfer() skips
   msm_dp_aux_reset() both when internal HPD is disabled
   (msm_dp_aux_is_link_connected() reads 0) and on hardware
   DP_AUX_ERR_TOUT completions.
2. msm_dp_aux_enable() relies on msm_dp_aux_hpd_enable() to set
   DP_DP_HPD_REFTIMER_ENABLE, leaving the 1us timeout reference timer
   off when internal HPD is unused.
3. During suspend, msm_dp_aux_hpd_disable() unconditionally clears
   DP_DP_HPD_REFTIMER_ENABLE before active displays finish AUX power-down
   transactions (such as msm_dp_link_psm_config()).

Clear REG_DP_AUX_TRANS_CTRL in msm_dp_aux_reset(), allow AUX reset on
timeout when internal HPD is disabled or the link is connected, enable
DP_DP_HPD_REFTIMER_ENABLE in msm_dp_aux_enable(), and keep the reference
timer running until both DP_AUX_CTRL_ENABLE and DP_DP_HPD_CTRL_HPD_EN
are cleared.

Tested on Microsoft Surface Pro X SQ2 (SC8180X) across s2idle suspend
and resume.

Fixes: c943b4948b58 ("drm/msm/dp: add displayPort driver support")
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
Changes in v2:
- Allow msm_dp_aux_reset() in msm_dp_aux_transfer() when internal HPD is
  not enabled (external HPD / eDP) and also reset AUX on hardware
  DP_AUX_ERR_TOUT timeouts so stale REG_DP_AUX_TRANS_CTRL state is
  cleared on both timeout paths.
- Keep DP_DP_HPD_REFTIMER_ENABLE enabled across msm_dp_aux_hpd_disable()
  while DP_AUX_CTRL_ENABLE is still active, and clear it in
  msm_dp_aux_disable() once both AUX and HPD are disabled.
- Link to v1: https://patch.msgid.link/20261125-drm-msm-dp-aux-resume-v1-1-17f5a40b9a61@gmail.com
---
 drivers/gpu/drm/msm/dp/dp_aux.c | 41 +++++++++++++++++++++++++++++++++--------
 1 file changed, 33 insertions(+), 8 deletions(-)

diff --git a/drivers/gpu/drm/msm/dp/dp_aux.c b/drivers/gpu/drm/msm/dp/dp_aux.c
index b52393d..fb35cc7 100644
--- a/drivers/gpu/drm/msm/dp/dp_aux.c
+++ b/drivers/gpu/drm/msm/dp/dp_aux.c
@@ -72,10 +72,20 @@ static void msm_dp_aux_clear_hw_interrupts(struct msm_dp_aux_private *aux)
 /*
  * NOTE: resetting AUX controller will also clear any pending HPD related interrupts
  */
+static bool msm_dp_aux_can_reset(struct msm_dp_aux_private *aux)
+{
+	if (!(msm_dp_read_aux(aux, REG_DP_DP_HPD_CTRL) & DP_DP_HPD_CTRL_HPD_EN))
+		return true;
+
+	return msm_dp_aux_is_link_connected(&aux->msm_dp_aux);
+}
+
 static void msm_dp_aux_reset(struct msm_dp_aux_private *aux)
 {
 	u32 aux_ctrl;
 
+	msm_dp_write_aux(aux, REG_DP_AUX_TRANS_CTRL, 0);
+
 	aux_ctrl = msm_dp_read_aux(aux, REG_DP_AUX_CTRL);
 
 	aux_ctrl |= DP_AUX_CTRL_RESET;
@@ -88,7 +98,12 @@ static void msm_dp_aux_reset(struct msm_dp_aux_private *aux)
 
 static void msm_dp_aux_enable(struct msm_dp_aux_private *aux)
 {
-	u32 aux_ctrl;
+	u32 aux_ctrl, reftimer;
+
+	/* Keep the 1us AUX/HPD reference timer running without internal HPD */
+	reftimer = msm_dp_read_aux(aux, REG_DP_DP_HPD_REFTIMER);
+	reftimer |= DP_DP_HPD_REFTIMER_ENABLE;
+	msm_dp_write_aux(aux, REG_DP_DP_HPD_REFTIMER, reftimer);
 
 	aux_ctrl = msm_dp_read_aux(aux, REG_DP_AUX_CTRL);
 
@@ -101,11 +116,17 @@ static void msm_dp_aux_enable(struct msm_dp_aux_private *aux)
 
 static void msm_dp_aux_disable(struct msm_dp_aux_private *aux)
 {
-	u32 aux_ctrl;
+	u32 aux_ctrl, reftimer;
 
 	aux_ctrl = msm_dp_read_aux(aux, REG_DP_AUX_CTRL);
 	aux_ctrl &= ~DP_AUX_CTRL_ENABLE;
 	msm_dp_write_aux(aux, REG_DP_AUX_CTRL, aux_ctrl);
+
+	if (!(msm_dp_read_aux(aux, REG_DP_DP_HPD_CTRL) & DP_DP_HPD_CTRL_HPD_EN)) {
+		reftimer = msm_dp_read_aux(aux, REG_DP_DP_HPD_REFTIMER);
+		reftimer &= ~DP_DP_HPD_REFTIMER_ENABLE;
+		msm_dp_write_aux(aux, REG_DP_DP_HPD_REFTIMER, reftimer);
+	}
 }
 
 static int msm_dp_aux_wait_for_hpd_connect_state(struct msm_dp_aux_private *aux,
@@ -411,8 +432,8 @@ static ssize_t msm_dp_aux_transfer(struct drm_dp_aux *msm_dp_aux,
 			if (!(aux->retry_cnt % MAX_AUX_RETRIES))
 				phy_calibrate(aux->phy);
 		}
-		/* reset aux if link is in connected state */
-		if (msm_dp_aux_is_link_connected(msm_dp_aux))
+		/* reset aux if internal HPD is unused or link is connected */
+		if (msm_dp_aux_can_reset(aux))
 			msm_dp_aux_reset(aux);
 	} else {
 		aux->retry_cnt = 0;
@@ -432,6 +453,8 @@ static ssize_t msm_dp_aux_transfer(struct drm_dp_aux *msm_dp_aux,
 			msg->reply = aux->native ? DP_AUX_NATIVE_REPLY_NACK : DP_AUX_I2C_REPLY_NACK;
 			break;
 		case DP_AUX_ERR_TOUT:
+			if (msm_dp_aux_can_reset(aux))
+				msm_dp_aux_reset(aux);
 			ret = -ETIMEDOUT;
 			break;
 		}
@@ -614,11 +637,13 @@ void msm_dp_aux_hpd_disable(struct drm_dp_aux *msm_dp_aux)
 		container_of(msm_dp_aux, struct msm_dp_aux_private, msm_dp_aux);
 	u32 reg;
 
-	reg = msm_dp_read_aux(aux, REG_DP_DP_HPD_REFTIMER);
-	reg &= ~DP_DP_HPD_REFTIMER_ENABLE;
-	msm_dp_write_aux(aux, REG_DP_DP_HPD_REFTIMER, reg);
-
 	msm_dp_write_aux(aux, REG_DP_DP_HPD_CTRL, 0);
+
+	if (!(msm_dp_read_aux(aux, REG_DP_AUX_CTRL) & DP_AUX_CTRL_ENABLE)) {
+		reg = msm_dp_read_aux(aux, REG_DP_DP_HPD_REFTIMER);
+		reg &= ~DP_DP_HPD_REFTIMER_ENABLE;
+		msm_dp_write_aux(aux, REG_DP_DP_HPD_REFTIMER, reg);
+	}
 }
 
 void msm_dp_aux_hpd_intr_enable(struct drm_dp_aux *msm_dp_aux)

---
base-commit: 4843f6873f7c4835e62f2c73ba0fd538e57a2f22
change-id: 20261125-drm-msm-dp-aux-resume-989fb2b97d65

Best regards,
--  
Robert Ijtsma <robertijtsma@gmail.com>

