From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Fri, 27 Nov 2026 15:27:06 +0100
Subject: [PATCH v3] drm/msm/dp: clear AUX_TRANS_CTRL on reset and enable
 HPD_REFTIMER
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-drm-msm-dp-aux-resume-v3-1-2db151decaab@gmail.com>
X-B4-Tracking: v=1; b=H4sIADmTCWsC/4XNwQ6DIAyA4VcxnNcFqsLYae+x7ACCSjKmgUlcj
 O8+9ORlWXr6m/TrQqINzkZyLRYSbHLRDa8c5akgTa9enQVnchOkyBnDGkzw4KMHM4KaZgg2Tt6
 CvMhWo5bC8Jrk2zHY1s27e3/k7l18D+Gzv0ls2/4TE4M8oq1VRbVUnN06r9zz3AyebGLCo8J/K
 ZiVssSqQqq5EPSorOv6BYK0QgwAAQAA
X-Change-ID: 20261125-drm-msm-dp-aux-resume-989fb2b97d65
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Stephen Boyd <swboyd@chromium.org>, Vara Reddy <quic_varar@quicinc.com>, 
 Guenter Roeck <groeck@chromium.org>, Tanmay Shah <tanmay@codeaurora.org>
Cc: Chandan Uddaraju <chandanu@codeaurora.org>, 
 linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, Kuogee Hsieh <quic_khsieh@quicinc.com>, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795789625; l=5862;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=sRsGGoT4oc+ruJceG2OpF//eZLcBXDogIygLd/WOPls=;
 b=QSL/XC4Fic9RnpIvrlxQ1tx4uuaRTwphqscP7yWjbJhesa0eBK73i6suw88rAqY3Kfqo3yPtS
 ydZgXAMInXIC8/gbHPCLKOEbOo23KXN10e57aEe4DzqbdlOVIUdt72b
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On boards using an external HPD bridge (such as Microsoft Surface Pro X /
SC8180X), internal HPD_CTRL is never enabled via msm_dp_aux_hpd_enable().
Across runtime PM or s2idle suspend/resume power collapse, several AUX
controller issues prevent reliable link re-training:

1. msm_dp_aux_reset() does not clear REG_DP_AUX_TRANS_CTRL before
   pulsing DP_AUX_CTRL_RESET, which can leave a stale transaction bit
   latched across reset.
2. msm_dp_aux_enable() relies on msm_dp_aux_hpd_enable() to set
   DP_DP_HPD_REFTIMER_ENABLE; when internal HPD is unused, AUX timeouts
   can stall after power collapse because the 1us reference timer is off.
   Move DP_DP_HPD_REFTIMER_ENABLE teardown symmetrically from
   msm_dp_aux_hpd_disable() to msm_dp_aux_disable() so disabling HPD
   polling during suspend does not stop the timer while AUX is active.
3. msm_dp_aux_transfer() gates msm_dp_aux_reset() on
   msm_dp_aux_is_link_connected(), which reads internal HPD status and
   always returns 0 when internal HPD_CTRL is disabled, and also skips
   resetting AUX on hardware DP_AUX_ERR_TOUT timeouts.

Clear REG_DP_AUX_TRANS_CTRL in msm_dp_aux_reset(), manage
DP_DP_HPD_REFTIMER_ENABLE across msm_dp_aux_enable()/disable(), and
reset AUX on both transfer errors and DP_AUX_ERR_TOUT timeouts when the
link is connected or transfers are enabled with internal HPD disabled.

Tested on Microsoft Surface Pro X SQ2 (SC8180X) across s2idle suspend
and resume.

Fixes: c943b4948b58 ("drm/msm/dp: add displayPort driver support")
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
Ensure AUX reset clears REG_DP_AUX_TRANS_CTRL and msm_dp_aux_enable()
enables the 1us HPD reference timer even when internal HPD is unused.
---
Changes in v3:
- Check aux->is_edp before DP_DP_HPD_CTRL_HPD_EN in msm_dp_aux_should_reset()
  so eDP boards without internal HPD wired still reset AUX on errors.
- Route hardware DP_AUX_ERR_TOUT timeouts through the ret < 0 retry and
  phy_calibrate() path alongside msm_dp_aux_reset().
- Link to v2: https://lore.kernel.org/r/20261126-drm-msm-dp-aux-resume-v2-1-3324420b6770@gmail.com

Changes in v2:
- Move DP_DP_HPD_REFTIMER_ENABLE teardown from msm_dp_aux_hpd_disable() to
  msm_dp_aux_disable() so HPD teardown during suspend does not disable the
  1us timer while AUX transfers are still active.
- Reset the AUX controller on both transfer failures and DP_AUX_ERR_TOUT
  timeouts, falling back to aux->is_edp || aux->enable_xfers when internal
  HPD_CTRL is disabled.
- Link to v1: https://lore.kernel.org/r/20261125-drm-msm-dp-aux-resume-v1-1-17f5a40b9a61@gmail.com
---
 drivers/gpu/drm/msm/dp/dp_aux.c | 36 ++++++++++++++++++++++++++++--------
 1 file changed, 28 insertions(+), 8 deletions(-)

diff --git a/drivers/gpu/drm/msm/dp/dp_aux.c b/drivers/gpu/drm/msm/dp/dp_aux.c
index b52393dcc067049529a51a9885990e5da663d802..2513f788fb0900311869de987cd00ace62a76984 100644
--- a/drivers/gpu/drm/msm/dp/dp_aux.c
+++ b/drivers/gpu/drm/msm/dp/dp_aux.c
@@ -76,6 +76,8 @@ static void msm_dp_aux_reset(struct msm_dp_aux_private *aux)
 {
 	u32 aux_ctrl;
 
+	msm_dp_write_aux(aux, REG_DP_AUX_TRANS_CTRL, 0);
+
 	aux_ctrl = msm_dp_read_aux(aux, REG_DP_AUX_CTRL);
 
 	aux_ctrl |= DP_AUX_CTRL_RESET;
@@ -88,7 +90,12 @@ static void msm_dp_aux_reset(struct msm_dp_aux_private *aux)
 
 static void msm_dp_aux_enable(struct msm_dp_aux_private *aux)
 {
-	u32 aux_ctrl;
+	u32 aux_ctrl, reftimer;
+
+	/* Keep the 1us AUX/HPD reference timer running without internal HPD. */
+	reftimer = msm_dp_read_aux(aux, REG_DP_DP_HPD_REFTIMER);
+	reftimer |= DP_DP_HPD_REFTIMER_ENABLE;
+	msm_dp_write_aux(aux, REG_DP_DP_HPD_REFTIMER, reftimer);
 
 	aux_ctrl = msm_dp_read_aux(aux, REG_DP_AUX_CTRL);
 
@@ -101,11 +108,26 @@ static void msm_dp_aux_enable(struct msm_dp_aux_private *aux)
 
 static void msm_dp_aux_disable(struct msm_dp_aux_private *aux)
 {
-	u32 aux_ctrl;
+	u32 aux_ctrl, reftimer;
 
 	aux_ctrl = msm_dp_read_aux(aux, REG_DP_AUX_CTRL);
 	aux_ctrl &= ~DP_AUX_CTRL_ENABLE;
 	msm_dp_write_aux(aux, REG_DP_AUX_CTRL, aux_ctrl);
+
+	reftimer = msm_dp_read_aux(aux, REG_DP_DP_HPD_REFTIMER);
+	reftimer &= ~DP_DP_HPD_REFTIMER_ENABLE;
+	msm_dp_write_aux(aux, REG_DP_DP_HPD_REFTIMER, reftimer);
+}
+
+static bool msm_dp_aux_should_reset(struct msm_dp_aux_private *aux)
+{
+	if (aux->is_edp)
+		return true;
+
+	if (msm_dp_read_aux(aux, REG_DP_DP_HPD_CTRL) & DP_DP_HPD_CTRL_HPD_EN)
+		return msm_dp_aux_is_link_connected(&aux->msm_dp_aux);
+
+	return aux->enable_xfers;
 }
 
 static int msm_dp_aux_wait_for_hpd_connect_state(struct msm_dp_aux_private *aux,
@@ -405,6 +427,9 @@ static ssize_t msm_dp_aux_transfer(struct drm_dp_aux *msm_dp_aux,
 	}
 
 	ret = msm_dp_aux_cmd_fifo_tx(aux, msg);
+	if (ret >= 0 && aux->aux_error_num == DP_AUX_ERR_TOUT)
+		ret = -ETIMEDOUT;
+
 	if (ret < 0) {
 		if (aux->native) {
 			aux->retry_cnt++;
@@ -412,7 +437,7 @@ static ssize_t msm_dp_aux_transfer(struct drm_dp_aux *msm_dp_aux,
 				phy_calibrate(aux->phy);
 		}
 		/* reset aux if link is in connected state */
-		if (msm_dp_aux_is_link_connected(msm_dp_aux))
+		if (msm_dp_aux_should_reset(aux))
 			msm_dp_aux_reset(aux);
 	} else {
 		aux->retry_cnt = 0;
@@ -612,11 +637,6 @@ void msm_dp_aux_hpd_disable(struct drm_dp_aux *msm_dp_aux)
 {
 	struct msm_dp_aux_private *aux =
 		container_of(msm_dp_aux, struct msm_dp_aux_private, msm_dp_aux);
-	u32 reg;
-
-	reg = msm_dp_read_aux(aux, REG_DP_DP_HPD_REFTIMER);
-	reg &= ~DP_DP_HPD_REFTIMER_ENABLE;
-	msm_dp_write_aux(aux, REG_DP_DP_HPD_REFTIMER, reg);
 
 	msm_dp_write_aux(aux, REG_DP_DP_HPD_CTRL, 0);
 }

---
base-commit: 4dce97c6c265544342e716e62fd24bbb232590c5
change-id: 20261125-drm-msm-dp-aux-resume-989fb2b97d65

Best regards,
-- 
Robert Ijtsma <robertijtsma@gmail.com>

