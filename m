From: Alexandre MINETTE <contact@alex-min.fr>
Date: Thu, 11 Jun 2026 08:07:46 +0200
Subject: [PATCH 1/2] drm/msm/mdp4: keep the bus clock enabled while a CRTC
 is active
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260611-mainline-fix-mdp4-blue-screen-sending-v1-v1-1-22925600e4f2@alex-min.fr>
References: <20260611-mainline-fix-mdp4-blue-screen-sending-v1-v1-0-22925600e4f2@alex-min.fr>
In-Reply-To: <20260611-mainline-fix-mdp4-blue-screen-sending-v1-v1-0-22925600e4f2@alex-min.fr>
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Alexandre MINETTE <contact@alex-min.fr>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781158087; l=4146;
 i=contact@alex-min.fr; s=20260421; h=from:subject:message-id;
 bh=ACm6LaIl/jyuS325Hv9bN+g+5H+Dcl4SC+eD28CoCEU=;
 b=O6NrUIlgFenxGp9OOWJzkRKkFIKgz+wlKqgIXH32ktejtvQPBVJcNJ+FOWQfWSaa54UAs4AVU
 H2/pqqJzCR1DNklPeM/2xWcUC91xOF6ymG3DW5C+ZoKrWOOUNiT3wSI
X-Developer-Key: i=contact@alex-min.fr; a=ed25519;
 pk=KOCaxY4v16ptaT0uk1FRkuaDF2n1JhmnYwLiqWD76M4=
X-Endpoint-Received: by B4 Relay for contact@alex-min.fr/20260421 with auth_id=743
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MDP4 scanout continues to fetch framebuffer data while the CRTC is
active. Keep the AXI/bus clock enabled for the lifetime of each active
CRTC so that temporary MDP4 disable paths do not gate the bus clock
while scanout is still running.

This avoids display corruption seen on the Samsung Galaxy S4 when the
display pipeline is active.

Signed-off-by: Alexandre MINETTE <contact@alex-min.fr>
---
 drivers/gpu/drm/msm/disp/mdp4/mdp4_crtc.c |  2 ++
 drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.c  | 42 +++++++++++++++++++++++++++++++
 drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.h  |  6 +++++
 3 files changed, 50 insertions(+)

diff --git a/drivers/gpu/drm/msm/disp/mdp4/mdp4_crtc.c b/drivers/gpu/drm/msm/disp/mdp4/mdp4_crtc.c
index e8066f9fd534..9e53c9d956ca 100644
--- a/drivers/gpu/drm/msm/disp/mdp4/mdp4_crtc.c
+++ b/drivers/gpu/drm/msm/disp/mdp4/mdp4_crtc.c
@@ -271,6 +271,7 @@ static void mdp4_crtc_atomic_disable(struct drm_crtc *crtc,
 
 	mdp_irq_unregister(&mdp4_kms->base, &mdp4_crtc->err);
 	mdp4_disable(mdp4_kms);
+	mdp4_crtc_bus_put(mdp4_kms);
 
 	if (crtc->state->event && !crtc->state->active) {
 		WARN_ON(mdp4_crtc->event);
@@ -295,6 +296,7 @@ static void mdp4_crtc_atomic_enable(struct drm_crtc *crtc,
 		return;
 
 	mdp4_enable(mdp4_kms);
+	mdp4_crtc_bus_get(mdp4_kms);
 
 	/* Restore vblank irq handling after power is enabled */
 	drm_crtc_vblank_on(crtc);
diff --git a/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.c b/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.c
index 809ca191e9de..4c60b49fb784 100644
--- a/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.c
+++ b/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.c
@@ -118,6 +118,39 @@ static long mdp4_round_pixclk(struct msm_kms *kms, unsigned long rate,
 	}
 }
 
+void mdp4_crtc_bus_get(struct mdp4_kms *mdp4_kms)
+{
+	int ret = 0;
+
+	mutex_lock(&mdp4_kms->clock_lock);
+
+	if (!mdp4_kms->crtc_bus_count)
+		ret = clk_prepare_enable(mdp4_kms->axi_clk);
+
+	if (!ret)
+		mdp4_kms->crtc_bus_count++;
+
+	mutex_unlock(&mdp4_kms->clock_lock);
+
+	WARN_ON(ret);
+}
+
+void mdp4_crtc_bus_put(struct mdp4_kms *mdp4_kms)
+{
+	mutex_lock(&mdp4_kms->clock_lock);
+	if (!mdp4_kms->crtc_bus_count)
+		goto unlock;
+
+	mdp4_kms->crtc_bus_count--;
+	if (mdp4_kms->crtc_bus_count)
+		goto unlock;
+
+	clk_disable_unprepare(mdp4_kms->axi_clk);
+
+unlock:
+	mutex_unlock(&mdp4_kms->clock_lock);
+}
+
 static void mdp4_destroy(struct msm_kms *kms)
 {
 	struct mdp4_kms *mdp4_kms = to_mdp4_kms(to_mdp_kms(kms));
@@ -137,6 +170,13 @@ static void mdp4_destroy(struct msm_kms *kms)
 	if (mdp4_kms->rpm_enabled)
 		pm_runtime_disable(dev);
 
+	mutex_lock(&mdp4_kms->clock_lock);
+	if (mdp4_kms->crtc_bus_count) {
+		clk_disable_unprepare(mdp4_kms->axi_clk);
+		mdp4_kms->crtc_bus_count = 0;
+	}
+	mutex_unlock(&mdp4_kms->clock_lock);
+
 	mdp_kms_destroy(&mdp4_kms->base);
 }
 
@@ -514,6 +554,8 @@ static int mdp4_probe(struct platform_device *pdev)
 	if (!mdp4_kms)
 		return -ENOMEM;
 
+	mutex_init(&mdp4_kms->clock_lock);
+
 	mdp4_kms->mmio = msm_ioremap(pdev, NULL);
 	if (IS_ERR(mdp4_kms->mmio))
 		return PTR_ERR(mdp4_kms->mmio);
diff --git a/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.h b/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.h
index 06458d4ee48c..86391d9bc55f 100644
--- a/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.h
+++ b/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.h
@@ -7,6 +7,8 @@
 #ifndef __MDP4_KMS_H__
 #define __MDP4_KMS_H__
 
+#include <linux/mutex.h>
+
 #include <drm/drm_panel.h>
 
 #include "msm_drv.h"
@@ -31,6 +33,8 @@ struct mdp4_kms {
 	struct clk *pclk;
 	struct clk *lut_clk;
 	struct clk *axi_clk;
+	struct mutex clock_lock;
+	unsigned int crtc_bus_count;
 
 	struct mdp_irq error_handler;
 
@@ -148,6 +152,8 @@ static inline uint32_t mixercfg(uint32_t mixer_cfg, int mixer,
 
 int mdp4_disable(struct mdp4_kms *mdp4_kms);
 int mdp4_enable(struct mdp4_kms *mdp4_kms);
+void mdp4_crtc_bus_get(struct mdp4_kms *mdp4_kms);
+void mdp4_crtc_bus_put(struct mdp4_kms *mdp4_kms);
 
 void mdp4_set_irqmask(struct mdp_kms *mdp_kms, uint32_t irqmask,
 		uint32_t old_irqmask);

-- 
2.43.0

