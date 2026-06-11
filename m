From: Alexandre MINETTE <contact@alex-min.fr>
Date: Thu, 11 Jun 2026 08:07:47 +0200
Subject: [PATCH 2/2] drm/msm/mdp4: keep inherited display clocks enabled
 until modeset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260611-mainline-fix-mdp4-blue-screen-sending-v1-v1-2-22925600e4f2@alex-min.fr>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781158087; l=5355;
 i=contact@alex-min.fr; s=20260421; h=from:subject:message-id;
 bh=bRl6/0Ew6JY9Fp5O3asZLYPvgCZok6zy103T4pX0/Lo=;
 b=N6BN8t/pvr/mk8k9OqSwa+SamY44EgWxbcKuRlCORo73qZPDSRrVALCiktAauT8vcvXJIXhbn
 FC+BsZ/5NhSDqG2snx7vVR0mS6keV3KDb/GBnnp0ZXwU8T3dyQRgzyn
X-Developer-Key: i=contact@alex-min.fr; a=ed25519;
 pk=KOCaxY4v16ptaT0uk1FRkuaDF2n1JhmnYwLiqWD76M4=
X-Endpoint-Received: by B4 Relay for contact@alex-min.fr/20260421 with auth_id=743
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some devices boot with the MDP4 display pipeline already enabled by
firmware. On the Samsung Galaxy S4, disabling clocks used by that
inherited pipeline before DRM takes over can leave the panel showing a
blue screen.

Keep the required display clocks prepared when an inherited
DSI/LCDC/DTV enable state is detected, and drop the extra clock
references on the first DRM CRTC enable. At that point the driver owns
the display pipeline.

Signed-off-by: Alexandre MINETTE <contact@alex-min.fr>
---
 drivers/gpu/drm/msm/disp/mdp4/mdp4_crtc.c |  1 +
 drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.c  | 66 ++++++++++++++++++++++++++++++-
 drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.h  |  2 +
 3 files changed, 68 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/msm/disp/mdp4/mdp4_crtc.c b/drivers/gpu/drm/msm/disp/mdp4/mdp4_crtc.c
index 9e53c9d956ca..0aeefd48be1f 100644
--- a/drivers/gpu/drm/msm/disp/mdp4/mdp4_crtc.c
+++ b/drivers/gpu/drm/msm/disp/mdp4/mdp4_crtc.c
@@ -297,6 +297,7 @@ static void mdp4_crtc_atomic_enable(struct drm_crtc *crtc,
 
 	mdp4_enable(mdp4_kms);
 	mdp4_crtc_bus_get(mdp4_kms);
+	mdp4_inherited_display_clocks_put(mdp4_kms);
 
 	/* Restore vblank irq handling after power is enabled */
 	drm_crtc_vblank_on(crtc);
diff --git a/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.c b/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.c
index 4c60b49fb784..1264ce7e8459 100644
--- a/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.c
+++ b/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.c
@@ -151,6 +151,58 @@ void mdp4_crtc_bus_put(struct mdp4_kms *mdp4_kms)
 	mutex_unlock(&mdp4_kms->clock_lock);
 }
 
+static bool mdp4_has_inherited_display_state(struct mdp4_kms *mdp4_kms)
+{
+	return mdp4_read(mdp4_kms, REG_MDP4_DSI_ENABLE) ||
+	       mdp4_read(mdp4_kms, REG_MDP4_LCDC_ENABLE) ||
+	       mdp4_read(mdp4_kms, REG_MDP4_DTV_ENABLE);
+}
+
+/*
+ * If firmware left MDP4 scanout enabled, preserve the core/LUT clocks until
+ * the first DRM CRTC enable takes ownership of the display pipeline.
+ */
+static void mdp4_inherited_display_clocks_get(struct mdp4_kms *mdp4_kms)
+{
+	bool inherited_display;
+
+	mutex_lock(&mdp4_kms->clock_lock);
+
+	clk_prepare_enable(mdp4_kms->clk);
+	clk_prepare_enable(mdp4_kms->pclk);
+	clk_prepare_enable(mdp4_kms->lut_clk);
+	clk_prepare_enable(mdp4_kms->axi_clk);
+
+	inherited_display = mdp4_has_inherited_display_state(mdp4_kms);
+
+	if (inherited_display) {
+		clk_prepare_enable(mdp4_kms->clk);
+		clk_prepare_enable(mdp4_kms->lut_clk);
+		mdp4_kms->inherited_display_clocks_held = true;
+	}
+
+	clk_disable_unprepare(mdp4_kms->clk);
+	clk_disable_unprepare(mdp4_kms->pclk);
+	clk_disable_unprepare(mdp4_kms->lut_clk);
+	clk_disable_unprepare(mdp4_kms->axi_clk);
+
+	mutex_unlock(&mdp4_kms->clock_lock);
+}
+
+void mdp4_inherited_display_clocks_put(struct mdp4_kms *mdp4_kms)
+{
+	mutex_lock(&mdp4_kms->clock_lock);
+	if (!mdp4_kms->inherited_display_clocks_held)
+		goto unlock;
+
+	clk_disable_unprepare(mdp4_kms->clk);
+	clk_disable_unprepare(mdp4_kms->lut_clk);
+	mdp4_kms->inherited_display_clocks_held = false;
+
+unlock:
+	mutex_unlock(&mdp4_kms->clock_lock);
+}
+
 static void mdp4_destroy(struct msm_kms *kms)
 {
 	struct mdp4_kms *mdp4_kms = to_mdp4_kms(to_mdp_kms(kms));
@@ -171,6 +223,11 @@ static void mdp4_destroy(struct msm_kms *kms)
 		pm_runtime_disable(dev);
 
 	mutex_lock(&mdp4_kms->clock_lock);
+	if (mdp4_kms->inherited_display_clocks_held) {
+		clk_disable_unprepare(mdp4_kms->clk);
+		clk_disable_unprepare(mdp4_kms->lut_clk);
+		mdp4_kms->inherited_display_clocks_held = false;
+	}
 	if (mdp4_kms->crtc_bus_count) {
 		clk_disable_unprepare(mdp4_kms->axi_clk);
 		mdp4_kms->crtc_bus_count = 0;
@@ -549,6 +606,7 @@ static int mdp4_probe(struct platform_device *pdev)
 	struct device *dev = &pdev->dev;
 	struct mdp4_kms *mdp4_kms;
 	int irq;
+	int ret;
 
 	mdp4_kms = devm_kzalloc(dev, sizeof(*mdp4_kms), GFP_KERNEL);
 	if (!mdp4_kms)
@@ -594,7 +652,13 @@ static int mdp4_probe(struct platform_device *pdev)
 	if (IS_ERR(mdp4_kms->lut_clk))
 		return dev_err_probe(dev, PTR_ERR(mdp4_kms->lut_clk), "failed to get lut_clk\n");
 
-	return msm_drv_probe(&pdev->dev, mdp4_kms_init, &mdp4_kms->base.base);
+	mdp4_inherited_display_clocks_get(mdp4_kms);
+
+	ret = msm_drv_probe(&pdev->dev, mdp4_kms_init, &mdp4_kms->base.base);
+	if (ret)
+		mdp4_inherited_display_clocks_put(mdp4_kms);
+
+	return ret;
 }
 
 static void mdp4_remove(struct platform_device *pdev)
diff --git a/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.h b/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.h
index 86391d9bc55f..289b5b476d99 100644
--- a/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.h
+++ b/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.h
@@ -34,6 +34,7 @@ struct mdp4_kms {
 	struct clk *lut_clk;
 	struct clk *axi_clk;
 	struct mutex clock_lock;
+	bool inherited_display_clocks_held;
 	unsigned int crtc_bus_count;
 
 	struct mdp_irq error_handler;
@@ -152,6 +153,7 @@ static inline uint32_t mixercfg(uint32_t mixer_cfg, int mixer,
 
 int mdp4_disable(struct mdp4_kms *mdp4_kms);
 int mdp4_enable(struct mdp4_kms *mdp4_kms);
+void mdp4_inherited_display_clocks_put(struct mdp4_kms *mdp4_kms);
 void mdp4_crtc_bus_get(struct mdp4_kms *mdp4_kms);
 void mdp4_crtc_bus_put(struct mdp4_kms *mdp4_kms);
 

-- 
2.43.0

