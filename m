From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:18:53 +0000
Subject: [PATCH 5/8] drm/rockchip: vop2: Report POST_BUF_EMPTY at most once
 per frame
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-vop2-fixes-v1-5-d336e9dd90d3@gmail.com>
References: <20261110-vop2-fixes-v1-0-d336e9dd90d3@gmail.com>
In-Reply-To: <20261110-vop2-fixes-v1-0-d336e9dd90d3@gmail.com>
To: Sandy Huang <hjc@rock-chips.com>, 
 =?utf-8?q?Heiko_St=C3=BCbner?= <heiko@sntech.de>, 
 Andy Yan <andyshrk@163.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sascha Hauer <s.hauer@pengutronix.de>
Cc: dri-devel@lists.freedesktop.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295129; l=6832;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=+tkjwCkgUpSm5bDKcbgtDSlyT6K0gvv9mrt7/xcFUtg=;
 b=goO2Sk/a5wy8w43IPzdwu3qAeffjt9xkbsl/NDU57bCSowmq8MAIlGz236xyFJ50Ut4Vz8p6a
 nFwMx7BX110BNMwy/swbdy85qUWjiSWjc4YCVhPv+zlZw07TsS9xv0s
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

POST_BUF_EMPTY is raised for every line on which the post processing
stage of a video port finds no data. The interrupt handler only
rate-limits the error message and leaves the interrupt enabled, so an
underflowing video port keeps the CPU in the interrupt handler 50000 to
300000 times per second, for as long as the configuration that causes
the underflow stays in place (e.g. 120000 interrupts per second for
3840x2160@120 with two full screen layers on one AXI port).

Mask POST_BUF_EMPTY when it fires and unmask it at the next frame start.
The frame start (FS) interrupt is enabled for that frame even when
vblank reporting is off, and disabled again once POST_BUF_EMPTY is
re-armed. A new per video port lock serialises the interrupt enable
bookkeeping between the interrupt handler and the vblank callbacks.
The error is still reported, now at most once per frame and video port.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/rockchip/rockchip_drm_vop2.c | 63 ++++++++++++++++++++++++++--
 drivers/gpu/drm/rockchip/rockchip_drm_vop2.h | 10 +++++
 2 files changed, 70 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
index 9aeb90c6aa4b..3323e50224c5 100644
--- a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
+++ b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.c
@@ -841,6 +841,48 @@ static void vop2_crtc_disable_irq(struct vop2_video_port *vp, u32 irq)
 	vop2_writel(vop2, RK3568_VP_INT_EN(vp->id), irq << 16);
 }
 
+/*
+ * POST_BUF_EMPTY is raised for every line the post processing stage finds
+ * no data for, so an underflowing video port can raise it 100000 times per
+ * second. Report it at most once per frame: mask it when it fires and
+ * unmask it at the next frame start, using the FS interrupt even when
+ * vblank reporting is off.
+ */
+static void vop2_crtc_enable_post_buf_empty_irq(struct vop2_video_port *vp)
+{
+	unsigned long flags;
+
+	spin_lock_irqsave(&vp->irq_lock, flags);
+	vp->post_buf_empty_masked = false;
+	vop2_crtc_enable_irq(vp, VP_INT_POST_BUF_EMPTY);
+	spin_unlock_irqrestore(&vp->irq_lock, flags);
+}
+
+static void vop2_crtc_handle_post_buf_empty(struct vop2_video_port *vp)
+{
+	struct vop2 *vop2 = vp->vop2;
+
+	spin_lock(&vp->irq_lock);
+	vop2_crtc_disable_irq(vp, VP_INT_POST_BUF_EMPTY);
+	vp->post_buf_empty_masked = true;
+	/* don't clear a pending FS, it may carry a vblank event */
+	vop2_writel(vop2, RK3568_VP_INT_EN(vp->id),
+		    VP_INT_FS_FIELD << 16 | VP_INT_FS_FIELD);
+	spin_unlock(&vp->irq_lock);
+}
+
+static void vop2_crtc_rearm_post_buf_empty(struct vop2_video_port *vp)
+{
+	spin_lock(&vp->irq_lock);
+	if (vp->post_buf_empty_masked) {
+		vp->post_buf_empty_masked = false;
+		vop2_crtc_enable_irq(vp, VP_INT_POST_BUF_EMPTY);
+		if (!vp->vblank_enabled)
+			vop2_crtc_disable_irq(vp, VP_INT_FS_FIELD);
+	}
+	spin_unlock(&vp->irq_lock);
+}
+
 static int vop2_core_clks_prepare_enable(struct vop2 *vop2)
 {
 	int ret;
@@ -1668,8 +1710,12 @@ static const struct drm_plane_funcs vop2_plane_funcs = {
 static int vop2_crtc_enable_vblank(struct drm_crtc *crtc)
 {
 	struct vop2_video_port *vp = to_vop2_video_port(crtc);
+	unsigned long flags;
 
+	spin_lock_irqsave(&vp->irq_lock, flags);
+	vp->vblank_enabled = true;
 	vop2_crtc_enable_irq(vp, VP_INT_FS_FIELD);
+	spin_unlock_irqrestore(&vp->irq_lock, flags);
 
 	return 0;
 }
@@ -1677,8 +1723,13 @@ static int vop2_crtc_enable_vblank(struct drm_crtc *crtc)
 static void vop2_crtc_disable_vblank(struct drm_crtc *crtc)
 {
 	struct vop2_video_port *vp = to_vop2_video_port(crtc);
+	unsigned long flags;
 
-	vop2_crtc_disable_irq(vp, VP_INT_FS_FIELD);
+	spin_lock_irqsave(&vp->irq_lock, flags);
+	vp->vblank_enabled = false;
+	if (!vp->post_buf_empty_masked)
+		vop2_crtc_disable_irq(vp, VP_INT_FS_FIELD);
+	spin_unlock_irqrestore(&vp->irq_lock, flags);
 }
 
 static enum drm_mode_status vop2_crtc_mode_valid(struct drm_crtc *crtc,
@@ -1977,7 +2028,7 @@ static void vop2_crtc_atomic_enable(struct drm_crtc *crtc,
 
 	vcstate->yuv_overlay = is_yuv_output(vcstate->bus_format);
 
-	vop2_crtc_enable_irq(vp, VP_INT_POST_BUF_EMPTY);
+	vop2_crtc_enable_post_buf_empty_irq(vp);
 
 	polflags = 0;
 	if (vcstate->bus_flags & DRM_BUS_FLAG_PIXDATA_DRIVE_NEGEDGE)
@@ -2535,6 +2586,7 @@ static irqreturn_t rk3576_vp_isr(int irq, void *data)
 	}
 
 	if (irqs & VP_INT_FS_FIELD) {
+		vop2_crtc_rearm_post_buf_empty(vp);
 		drm_crtc_handle_vblank(crtc);
 		spin_lock(&crtc->dev->event_lock);
 		if (vp->event) {
@@ -2552,6 +2604,7 @@ static irqreturn_t rk3576_vp_isr(int irq, void *data)
 	}
 
 	if (irqs & VP_INT_POST_BUF_EMPTY) {
+		vop2_crtc_handle_post_buf_empty(vp);
 		drm_err_ratelimited(vop2->drm, "POST_BUF_EMPTY irq err at vp%d\n", vp->id);
 		ret = IRQ_HANDLED;
 	}
@@ -2591,6 +2644,7 @@ static irqreturn_t vop2_isr(int irq, void *data)
 			}
 
 			if (irqs & VP_INT_FS_FIELD) {
+				vop2_crtc_rearm_post_buf_empty(vp);
 				drm_crtc_handle_vblank(crtc);
 				spin_lock(&crtc->dev->event_lock);
 				if (vp->event) {
@@ -2608,6 +2662,7 @@ static irqreturn_t vop2_isr(int irq, void *data)
 			}
 
 			if (irqs & VP_INT_POST_BUF_EMPTY) {
+				vop2_crtc_handle_post_buf_empty(vp);
 				drm_err_ratelimited(vop2->drm,
 						    "POST_BUF_EMPTY irq err at vp%d\n",
 						    vp->id);
@@ -2984,7 +3039,7 @@ static int vop2_bind(struct device *dev, struct device *master, void *data)
 	struct vop2 *vop2;
 	struct resource *res;
 	size_t alloc_size;
-	int ret;
+	int ret, i;
 
 	vop2_data = of_device_get_match_data(dev);
 	if (!vop2_data)
@@ -3102,6 +3157,8 @@ static int vop2_bind(struct device *dev, struct device *master, void *data)
 	mutex_init(&vop2->vop2_lock);
 	mutex_init(&vop2->ovl_lock);
 	spin_lock_init(&vop2->axi_lock);
+	for (i = 0; i < ARRAY_SIZE(vop2->vps); i++)
+		spin_lock_init(&vop2->vps[i].irq_lock);
 
 	ret = devm_request_irq(dev, vop2->irq, vop2_isr, IRQF_SHARED, dev_name(dev), vop2);
 	if (ret)
diff --git a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.h b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.h
index f1e35967e67f..7de32bef8d7b 100644
--- a/drivers/gpu/drm/rockchip/rockchip_drm_vop2.h
+++ b/drivers/gpu/drm/rockchip/rockchip_drm_vop2.h
@@ -272,6 +272,16 @@ struct vop2_video_port {
 	struct drm_pending_vblank_event *event;
 
 	unsigned int nlayers;
+
+	/** @irq_lock: protects @vblank_enabled and @post_buf_empty_masked */
+	spinlock_t irq_lock;
+	/** @vblank_enabled: the FS interrupt is enabled for vblank reporting */
+	bool vblank_enabled;
+	/**
+	 * @post_buf_empty_masked: POST_BUF_EMPTY is masked until the next
+	 * frame start
+	 */
+	bool post_buf_empty_masked;
 };
 
 /**

-- 
2.55.0

