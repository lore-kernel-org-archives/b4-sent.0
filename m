From: "David R. Hedges" <linuxdev844@thelittleman.net>
Date: Tue, 03 Nov 2026 14:02:51 -0600
Subject: [PATCH 5/5] drm/nouveau/dp: restart an active link when the sink
 reasserts HPD
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-nouveau-dp-relink-v1-5-7ee88c7f1e8a@thelittleman.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793736171; l=6803;
 i=linuxdev844@thelittleman.net; s=20261103; h=from:subject:message-id;
 bh=Wj9O+KZXb+AJG+c61p+ihLDpQLh/2BrNWBgFuU7RiIg=;
 b=XggoV3AxSDbv4q/H13nQdZIi21yV13MlmFAf25rnbaz3E5DM7QnaYtAjDbOVbW/Nx8rvIhgaD
 ifxS9iWRdhDBfdSykeRCEZmGIbWvpLxwmYfs53IoHzQfJCd93s6bRTP
X-Developer-Key: i=linuxdev844@thelittleman.net; a=ed25519;
 pk=Cynzuei/w0GLdh3LuNJdvH7aaszLrHSxY5UyujS7l+g=
X-Endpoint-Received: by B4 Relay for linuxdev844@thelittleman.net/20261103 with auth_id=1397
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a DP sink drops HPD for longer than an IRQ_HPD pulse, it may have
reset its end of the link.  nouveau handles the unplug and plug by
re-running connector detection and sending hotplug events, but if the
same display comes back, userspace sees nothing that needs a modeset
and leaves the CRTC as it was.  Nothing trains the link again, and the
sink is left without a picture.

That's what happens with an IGM L28TN4K on a GA102 (GSP-RM 570.144)
after waking it from DPMS off.  If the link is trained before the
monitor has finished waking up, training succeeds at 4 x HBR2, but
about two seconds later the monitor raises IRQ_HPD and shows "No input
signal", and two seconds after that it drops HPD briefly and reasserts
it.  The link status read on the IRQ_HPD is 77 77 01 03 (DPCD
0x202-0x205: all lanes locked, interlane-aligned, sink in sync), and
DP_SET_POWER still reads D0 once HPD is back, so there's nothing to
check that would show the problem.  Whenever the IRQ_HPD came before
link training instead, the picture came up normally.  The same happens
after replugging the cable and after resuming from S3, and the screen
stays dark until the cable is replugged, often several times.

When a plug or unplug event leaves a DP connector connected while it
still drives an active CRTC, restart the link with a modeset, using
the restart added for lost links on GSP-RM, on any GPU.  NVIDIA's own
DisplayPort library does the equivalent:
ConnectorImpl::notifyLongPulseInternal() calls assessLink(), which
retrains the link, for an SST sink that's still connected.  i915, by
contrast, only retrains on hotplug if the link status says the link is
bad.  With this applied, the monitor above comes back four to five
seconds after being woken, replugged or resumed.  On resume,
nouveau_display_hpd_resume() schedules the HPD worker without any
events, so this doesn't add a restart to the resume modeset.

Switched on with its power button, which it reports only as a plug
event, the same monitor first advertises DPCD 1.1 and HBR, which can't
carry the 3840x2160@60 mode its CRTC still has.  The restart then fails
atomic check, link-status is set to BAD, and userspace, which gets a
hotplug event, picks a mode that fits.  About a second later the
monitor drops and reasserts HPD with its full capabilities, and
userspace goes back to 3840x2160@60.

A sink that dropped HPD every time its link was trained would have the
link restarted for ever, so stop after five restarts that each came
within ten seconds of the one before, until ten seconds have passed
without one.  If userspace has already responded to a hotplug event
with a modeset of its own by the time the HPD worker runs, the link is
restarted a second time, which costs another brief blank but is
otherwise harmless.

Closes: https://gitlab.freedesktop.org/drm/nouveau/-/work_items/515
Signed-off-by: David R. Hedges <linuxdev844@thelittleman.net>
---
 drivers/gpu/drm/nouveau/nouveau_connector.h |  5 +++
 drivers/gpu/drm/nouveau/nouveau_display.c   | 51 ++++++++++++++++++++++++++---
 2 files changed, 52 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/nouveau/nouveau_connector.h b/drivers/gpu/drm/nouveau/nouveau_connector.h
index 3109278d36ea..914e86ad2df2 100644
--- a/drivers/gpu/drm/nouveau/nouveau_connector.h
+++ b/drivers/gpu/drm/nouveau/nouveau_connector.h
@@ -135,6 +135,11 @@ struct nouveau_connector {
 	struct nvif_event irq;
 	struct work_struct irq_work;
 	struct work_struct link_bad_work;
+	/* Recent link restarts, see nouveau_display_relink() */
+	struct {
+		unsigned long last;
+		unsigned int count;
+	} relink;
 
 	struct drm_dp_aux aux;
 
diff --git a/drivers/gpu/drm/nouveau/nouveau_display.c b/drivers/gpu/drm/nouveau/nouveau_display.c
index c5e914602baf..a52db6129962 100644
--- a/drivers/gpu/drm/nouveau/nouveau_display.c
+++ b/drivers/gpu/drm/nouveau/nouveau_display.c
@@ -418,6 +418,33 @@ nouveau_display_hpd_resume(struct nouveau_drm *drm)
 	schedule_work(&drm->hpd_work);
 }
 
+/* A sink that responds to link training by dropping HPD would otherwise have
+ * its link restarted for ever.  Stop after a few restarts that each came soon
+ * after the one before, until things have been quiet for a while.
+ */
+#define NOUVEAU_RELINK_MAX	5
+#define NOUVEAU_RELINK_QUIET	(10 * HZ)
+
+static bool
+nouveau_display_relink_allowed(struct drm_connector *connector)
+{
+	struct nouveau_connector *nv_connector = nouveau_connector(connector);
+	unsigned long now = jiffies;
+
+	if (time_after(now, nv_connector->relink.last + NOUVEAU_RELINK_QUIET))
+		nv_connector->relink.count = 0;
+	nv_connector->relink.last = now;
+
+	if (nv_connector->relink.count++ < NOUVEAU_RELINK_MAX)
+		return true;
+
+	if (nv_connector->relink.count == NOUVEAU_RELINK_MAX + 1)
+		NV_WARN(nouveau_drm(connector->dev),
+			"%s: link restarted %d times in quick succession, giving up\n",
+			connector->name, NOUVEAU_RELINK_MAX);
+	return false;
+}
+
 /* Restart the pipe driving @connector with a full modeset, so that its link is
  * trained again along with everything else.
  */
@@ -427,6 +454,7 @@ nouveau_display_relink(struct drm_connector *connector)
 	struct drm_device *dev = connector->dev;
 	struct drm_modeset_acquire_ctx ctx;
 	struct drm_crtc *crtc;
+	bool counted = false;
 	int ret;
 
 	drm_modeset_acquire_init(&ctx, 0);
@@ -443,11 +471,18 @@ nouveau_display_relink(struct drm_connector *connector)
 	if (ret)
 		goto out;
 
-	if (crtc->state->active) {
-		drm_dbg_kms(dev, "[CONNECTOR:%d:%s] restarting link\n",
-			    connector->base.id, connector->name);
-		ret = drm_atomic_helper_reset_crtc(crtc, &ctx);
+	if (!crtc->state->active)
+		goto out;
+
+	if (!counted) {
+		if (!nouveau_display_relink_allowed(connector))
+			goto out;
+		counted = true;
 	}
+
+	drm_dbg_kms(dev, "[CONNECTOR:%d:%s] restarting link\n",
+		    connector->base.id, connector->name);
+	ret = drm_atomic_helper_reset_crtc(crtc, &ctx);
 out:
 	if (ret == -EDEADLK) {
 		drm_modeset_backoff(&ctx);
@@ -510,6 +545,14 @@ nouveau_display_hpd_work(struct work_struct *work)
 			    !!(bits & NVIF_CONN_EVENT_V0_UNPLUG),
 			    !!(bits & NVIF_CONN_EVENT_V0_IRQ));
 
+		/* If a DP sink dropped HPD while we were driving it, it may have
+		 * reset its end of the link whatever its link status says, and
+		 * userspace won't modeset again if nothing else has changed.
+		 */
+		if (nv_connector->dp_encoder &&
+		    (bits & (NVIF_CONN_EVENT_V0_PLUG | NVIF_CONN_EVENT_V0_UNPLUG)))
+			modeset = true;
+
 		/* A plug or unplug event pending alongside the IRQ, such as a
 		 * sink count change reported by nouveau_dp_irq(), still needs
 		 * connector detection.

-- 
2.55.0

