From: "David R. Hedges" <linuxdev844@thelittleman.net>
Date: Tue, 03 Nov 2026 14:02:49 -0600
Subject: [PATCH 3/5] drm/nouveau/dp: restart lost links with a modeset on
 GSP-RM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-nouveau-dp-relink-v1-3-7ee88c7f1e8a@thelittleman.net>
References: <20261103-nouveau-dp-relink-v1-0-7ee88c7f1e8a@thelittleman.net>
In-Reply-To: <20261103-nouveau-dp-relink-v1-0-7ee88c7f1e8a@thelittleman.net>
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jani Nikula <jani.nikula@intel.com>, Ben Skeggs <bskeggs@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Danilo Krummrich <me@dakr.org>, 
 "David R. Hedges" <linuxdev844@thelittleman.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793736171; l=8557;
 i=linuxdev844@thelittleman.net; s=20261103; h=from:subject:message-id;
 bh=tDTlFqdOxIVeMxCktaljDJWmMHEtMCKr2HYUZsjuEfA=;
 b=aeGAuk118jnkuC9YHx5mw0AV28kKFXbz3dAMowBUAKb7wFM0M4LZvLGOLky4gWPl5zrMPR2oD
 OtYN+jj61VFCRIBRn7IGC3yDSvZpdzG1rPCLbEOKCDB20lsuFOefNmg
X-Developer-Key: i=linuxdev844@thelittleman.net; a=ed25519;
 pk=Cynzuei/w0GLdh3LuNJdvH7aaszLrHSxY5UyujS7l+g=
X-Endpoint-Received: by B4 Relay for linuxdev844@thelittleman.net/20261103 with auth_id=1397
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a sink reports through IRQ_HPD that its link has lost lock,
nouveau_dp_link_check() retrains the link in place while the stream
keeps running.  Without GSP-RM, nvkm_dp_train() has a path for that
which leaves the source configuration alone.  On GSP-RM,
r535_dp_train() ignores its retrain argument and issues the same
NV0073_CTRL_CMD_DP_CTRL as for a new link.  NVIDIA's own DisplayPort
library never retrains an active link like that: it puts the SOR into
flush mode, retrains, configures the stream again and takes the SOR
out of flush mode, and warns that skipping part of that sequence can
hang the display engine.

That holds on a GA102 with GSP-RM 570.144.  After an experimental
patch retrained an active 4 x HBR2 link in place, the picture came
back with horizontal artefacts, and the next modeset, a refresh rate
change, never completed: "core notifier timeout", after which GSP
stopped answering RPCs.

nouveau doesn't implement flush mode, so on GSP-RM restart the pipe
with a full modeset of the CRTC driving the connector instead, using
drm_atomic_helper_reset_crtc().  That trains the link, configures the
stream and attaches the SOR in the same order as any other modeset,
which is also how i915 retrains a link.  The HPD worker does this after
dropping mode_config.mutex, so that probing isn't held up while it
runs.  If the sink now advertises less than the mode needs, the
modeset fails atomic check, and the connector's link-status is set to
BAD, as when a DPMS on finds the same.

The link check is only reached once the connector's DP encoder has
been cached, which on nv50+ it currently never is, so this has no
effect until the next patch.

Link: https://gitlab.freedesktop.org/drm/nouveau/-/work_items/515
Signed-off-by: David R. Hedges <linuxdev844@thelittleman.net>
---
 drivers/gpu/drm/nouveau/nouveau_display.c | 65 ++++++++++++++++++++++++++++++-
 drivers/gpu/drm/nouveau/nouveau_dp.c      | 21 ++++++++--
 drivers/gpu/drm/nouveau/nouveau_encoder.h |  2 +-
 3 files changed, 82 insertions(+), 6 deletions(-)

diff --git a/drivers/gpu/drm/nouveau/nouveau_display.c b/drivers/gpu/drm/nouveau/nouveau_display.c
index 4398cf0fc541..c5e914602baf 100644
--- a/drivers/gpu/drm/nouveau/nouveau_display.c
+++ b/drivers/gpu/drm/nouveau/nouveau_display.c
@@ -418,6 +418,53 @@ nouveau_display_hpd_resume(struct nouveau_drm *drm)
 	schedule_work(&drm->hpd_work);
 }
 
+/* Restart the pipe driving @connector with a full modeset, so that its link is
+ * trained again along with everything else.
+ */
+static void
+nouveau_display_relink(struct drm_connector *connector)
+{
+	struct drm_device *dev = connector->dev;
+	struct drm_modeset_acquire_ctx ctx;
+	struct drm_crtc *crtc;
+	int ret;
+
+	drm_modeset_acquire_init(&ctx, 0);
+retry:
+	ret = drm_modeset_lock(&dev->mode_config.connection_mutex, &ctx);
+	if (ret)
+		goto out;
+
+	crtc = connector->state->crtc;
+	if (!crtc)
+		goto out;
+
+	ret = drm_modeset_lock(&crtc->mutex, &ctx);
+	if (ret)
+		goto out;
+
+	if (crtc->state->active) {
+		drm_dbg_kms(dev, "[CONNECTOR:%d:%s] restarting link\n",
+			    connector->base.id, connector->name);
+		ret = drm_atomic_helper_reset_crtc(crtc, &ctx);
+	}
+out:
+	if (ret == -EDEADLK) {
+		drm_modeset_backoff(&ctx);
+		goto retry;
+	}
+
+	drm_modeset_drop_locks(&ctx);
+	drm_modeset_acquire_fini(&ctx);
+
+	/* The sink may now advertise less than the mode needs. */
+	if (ret == -EINVAL)
+		schedule_work(&nouveau_connector(connector)->link_bad_work);
+	else if (ret)
+		NV_ERROR(nouveau_drm(dev), "%s: failed to restart link: %d\n",
+			 connector->name, ret);
+}
+
 static void
 nouveau_display_hpd_work(struct work_struct *work)
 {
@@ -425,7 +472,7 @@ nouveau_display_hpd_work(struct work_struct *work)
 	struct drm_device *dev = drm->dev;
 	struct drm_connector *connector;
 	struct drm_connector_list_iter conn_iter;
-	u32 pending;
+	u32 pending, relink = 0;
 	int changed = 0;
 	struct drm_connector *first_changed_connector = NULL;
 
@@ -447,6 +494,7 @@ nouveau_display_hpd_work(struct work_struct *work)
 		struct nouveau_connector *nv_connector = nouveau_connector(connector);
 		enum drm_connector_status old_status = connector->status;
 		u64 bits, old_epoch_counter = connector->epoch_counter;
+		bool modeset = false;
 
 		if (!(pending & drm_connector_mask(connector)))
 			continue;
@@ -468,11 +516,14 @@ nouveau_display_hpd_work(struct work_struct *work)
 		 */
 		if ((bits & NVIF_CONN_EVENT_V0_IRQ) &&
 		    !(bits & (NVIF_CONN_EVENT_V0_PLUG | NVIF_CONN_EVENT_V0_UNPLUG))) {
-			if (nouveau_dp_link_check(nv_connector))
+			if (nouveau_dp_link_check(nv_connector, &modeset))
 				continue;
 		}
 
 		connector->status = drm_helper_probe_detect(connector, NULL, false);
+		if (modeset && connector->status == connector_status_connected)
+			relink |= drm_connector_mask(connector);
+
 		if (old_epoch_counter == connector->epoch_counter)
 			continue;
 
@@ -492,6 +543,16 @@ nouveau_display_hpd_work(struct work_struct *work)
 	drm_connector_list_iter_end(&conn_iter);
 	mutex_unlock(&dev->mode_config.mutex);
 
+	/* A restart is a full modeset, so don't hold up probing while it runs. */
+	if (relink) {
+		drm_connector_list_iter_begin(dev, &conn_iter);
+		nouveau_for_each_non_mst_connector_iter(connector, &conn_iter) {
+			if (relink & drm_connector_mask(connector))
+				nouveau_display_relink(connector);
+		}
+		drm_connector_list_iter_end(&conn_iter);
+	}
+
 	if (changed == 1)
 		drm_kms_helper_connector_hotplug_event(first_changed_connector);
 	else if (changed > 0)
diff --git a/drivers/gpu/drm/nouveau/nouveau_dp.c b/drivers/gpu/drm/nouveau/nouveau_dp.c
index 9bc24f3914bd..99eeb66cc6a8 100644
--- a/drivers/gpu/drm/nouveau/nouveau_dp.c
+++ b/drivers/gpu/drm/nouveau/nouveau_dp.c
@@ -31,6 +31,8 @@
 
 #include <nvif/if0011.h>
 
+#include <subdev/gsp.h>
+
 MODULE_PARM_DESC(mst, "Enable DisplayPort multi-stream (default: enabled)");
 static int nouveau_mst = 1;
 module_param_named(mst, nouveau_mst, int, 0400);
@@ -452,7 +454,7 @@ nouveau_dp_train(struct nouveau_encoder *outp, bool mst, u32 khz, u8 bpc)
 }
 
 static bool
-nouveau_dp_link_check_locked(struct nouveau_encoder *outp)
+nouveau_dp_link_check_locked(struct nouveau_encoder *outp, bool *modeset)
 {
 	u8 link_status[DP_LINK_STATUS_SIZE];
 
@@ -465,11 +467,24 @@ nouveau_dp_link_check_locked(struct nouveau_encoder *outp)
 	if (drm_dp_channel_eq_ok(link_status, outp->dp.lt.nr))
 		return true;
 
+	/* NVIDIA's own DisplayPort library only retrains an active link with
+	 * the SOR in flush mode, which we don't implement, and retraining it
+	 * without that on GSP-RM can hang the display engine.  Leave the link
+	 * to be restarted with a modeset instead.
+	 */
+	if (nvkm_gsp_rm(nvxx_device(nouveau_drm(outp->base.base.dev))->gsp)) {
+		*modeset = true;
+		return false;
+	}
+
 	return nouveau_dp_train_link(outp, true);
 }
 
+/* Returns false if the link has been lost, setting *modeset if it has to be
+ * restarted with a modeset rather than having been retrained here.
+ */
 bool
-nouveau_dp_link_check(struct nouveau_connector *nv_connector)
+nouveau_dp_link_check(struct nouveau_connector *nv_connector, bool *modeset)
 {
 	struct nouveau_encoder *outp = nv_connector->dp_encoder;
 	bool link_ok = true;
@@ -477,7 +492,7 @@ nouveau_dp_link_check(struct nouveau_connector *nv_connector)
 	if (outp) {
 		mutex_lock(&outp->dp.hpd_irq_lock);
 		if (outp->dp.lt.nr)
-			link_ok = nouveau_dp_link_check_locked(outp);
+			link_ok = nouveau_dp_link_check_locked(outp, modeset);
 		mutex_unlock(&outp->dp.hpd_irq_lock);
 	}
 
diff --git a/drivers/gpu/drm/nouveau/nouveau_encoder.h b/drivers/gpu/drm/nouveau/nouveau_encoder.h
index 9366678e7d05..1639b7e41c1d 100644
--- a/drivers/gpu/drm/nouveau/nouveau_encoder.h
+++ b/drivers/gpu/drm/nouveau/nouveau_encoder.h
@@ -158,7 +158,7 @@ enum nouveau_dp_status {
 int nouveau_dp_detect(struct nouveau_connector *, struct nouveau_encoder *);
 int nouveau_dp_train(struct nouveau_encoder *outp, bool mst, u32 khz, u8 bpc);
 void nouveau_dp_power_down(struct nouveau_encoder *);
-bool nouveau_dp_link_check(struct nouveau_connector *);
+bool nouveau_dp_link_check(struct nouveau_connector *nv_connector, bool *modeset);
 void nouveau_dp_irq(struct work_struct *);
 enum drm_mode_status nv50_dp_mode_valid(struct nouveau_encoder *,
 					const struct drm_display_mode *,

-- 
2.55.0

