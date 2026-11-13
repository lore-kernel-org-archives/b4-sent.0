From: Hugo Sales <hugo@hsal.es>
Date: Fri, 13 Nov 2026 20:24:51 +0000
Subject: [PATCH v2 4/5] drm/amd/display: Commit panel_power_savings writes
 from the kernel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-abm-sysfs-commit-v2-4-5808d17a7e89@hsal.es>
References: <20261113-abm-sysfs-commit-v2-0-5808d17a7e89@hsal.es>
In-Reply-To: <20261113-abm-sysfs-commit-v2-0-5808d17a7e89@hsal.es>
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>
Cc: Mario Limonciello <mario.limonciello@amd.com>, Ray Wu <ray.wu@amd.com>, 
 Alex Hung <alex.hung@amd.com>, 
 Bhawanpreet Lakha <bhawanpreet.lakha@amd.com>, 
 Ivan Lipski <ivan.lipski@amd.com>, Chenyu Chen <chen-yu.chen@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hugo Sales <hugo@hsal.es>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=7559; i=hugo@hsal.es;
 h=from:subject:message-id; bh=7BV3bjHKcfB15nKno9lb5giuMjusjwXHYGyG+Z7talI=;
 b=owJ4nJvAy8zAJVbLU7f+5A3TBYyn1ZIYsr4XCXi/zP07I+G3x/ov/wWu7DH8ef80+7/yG5s/L
 GNM+On/Kpq9o5SFQYyLQVZMkUX3hicDy8TJM3OKni+BmcPKBDKEgYtTACaSIsPI0Ld1f0XLZf9T
 q2rX/T9/eH+P8KkFu5x3Po6WW2Lk6n2g9BvDP9MosXD7nHIz07m6ryMUutYbHeAqvFCcEOA54Vn
 2pJo7LACNkU6c
X-Developer-Key: i=hugo@hsal.es; a=openpgp;
 fpr=193D095149CF7E8737B39064D912B0DB205A91C1
X-Endpoint-Received: by B4 Relay for hugo@hsal.es/default with auth_id=1417
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panel_power_savings_store() currently writes the level into
connector->state and sends a hotplug uevent, and the hardware only gets it
on a later atomic commit that includes the connector. Hyprland adds the
connector to a commit only on a modeset or when a connector property it
sets changes, so it never applies the level

Programs that write the sysfs file, such as power-profiles-daemon, aren't
the DRM master and can't commit themselves, so they depend on the master
taking the uevent as a cue to commit the connector, but nothing documents
they should. A master that wants to control ABM sets the 'adaptive
backlight modulation' property, and from then on writes return -EBUSY. The
file has to work without the master's help, like the backlight device,
whose writes reach DC without a commit

Commit the level from the store instead, with a duplicated connector state
and no modeset. The write returns once the commit is done, or with the
commit's error, so no uevent is needed. A connector that is off gets the
level when it is next enabled. A write of the level the connector already
has, or one the DRM master forbids, returns without a commit and without
waking a runtime-suspended GPU

Document the new behaviour in the kernel-doc

Signed-off-by: Hugo Sales <hugo@hsal.es>
---
This needs "drm/amd/display: Don't force a modeset when the ABM level
changes". Without it, atomic check sees the changed level, asks for a
modeset and the commit fails with -EINVAL

A failed write used to leave the level stored and send the uevent anyway.
Now the level only changes through the commit, so the store reports the
error. power-profiles-daemon logs a failed write and tries again on the
next profile, AC or battery change, because it compares against the value
it reads back. It ignores the hotplug uevent. Compositors used it only as
a cue to commit the connector, which the store now does itself

The commit is blocking, so a write can hold the CRTC locks for up to a
frame while a compositor commit waits. The other way round, while the
store's commit is pending, a nonblocking commit from the compositor on the
same CRTC fails with -EBUSY, as it would behind any pending commit

The store takes a runtime PM reference around the commit, like the
atomic ioctl path. Its locks are interruptible, and a write a signal
interrupts returns -ERESTARTSYS so that it restarts
---
 .../amd/display/amdgpu_dm/amdgpu_dm_backlight.c    | 118 +++++++++++++++++++--
 1 file changed, 107 insertions(+), 11 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c
index 27546febf90d3..8487ac0661396 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c
@@ -40,7 +40,10 @@
 
 #include <linux/backlight.h>
 #include <linux/minmax.h>
+#include <linux/pm_runtime.h>
 #include <linux/power_supply.h>
+#include <drm/drm_atomic.h>
+#include <drm/drm_drv.h>
 #include <drm/drm_edid.h>
 #include <drm/drm_utils.h>
 
@@ -691,6 +694,18 @@ EXPORT_IF_KUNIT(amdgpu_dm_setup_backlight_device);
  *
  * Modifying this value can have implications on color accuracy, so tread
  * carefully.
+ *
+ * A write commits the new level before it returns, without a modeset. The
+ * commit waits for any commit already pending on the connector's CRTC, and
+ * while it is pending, a nonblocking commit from the DRM master on that CRTC
+ * fails with -EBUSY. If the connector or its CRTC is off, the driver stores
+ * the level and applies it when the connector is next enabled
+ *
+ * If the commit fails, the write returns its error and the level stays as it
+ * was. While the CRTC needs a modeset, as after a DSC override in debugfs,
+ * writes fail with -EINVAL until a commit that allows a modeset clears that
+ * state. Writes fail with -EBUSY once the DRM master has set the connector's
+ * 'adaptive backlight modulation' property to a value other than 'sysfs'
  */
 
 STATIC_IFN_KUNIT
@@ -712,13 +727,100 @@ ssize_t panel_power_savings_show(struct device *device,
 }
 EXPORT_IF_KUNIT(panel_power_savings_show);
 
+static int panel_power_savings_apply(struct drm_connector *connector,
+				     unsigned int level)
+{
+	struct drm_connector_state *conn_state;
+	struct dm_connector_state *dm_state;
+	struct drm_device *dev = connector->dev;
+	struct drm_modeset_acquire_ctx ctx;
+	struct drm_atomic_commit *state;
+	bool forbidden, unchanged;
+	int ret, idx;
+
+	level = level ?: ABM_LEVEL_IMMEDIATE_DISABLE;
+
+	if (!drm_dev_enter(dev, &idx))
+		return -ENODEV;
+
+	/*
+	 * Don't wake the GPU for a write that changes nothing. The duplicated
+	 * state below is checked again. This check only spares the runtime resume
+	 */
+	ret = drm_modeset_lock_single_interruptible(&dev->mode_config.connection_mutex);
+	if (ret)
+		goto dev_exit;
+	dm_state = to_dm_connector_state(connector->state);
+	forbidden = dm_state->abm_sysfs_forbidden;
+	unchanged = dm_state->abm_level == level;
+	drm_modeset_unlock(&dev->mode_config.connection_mutex);
+
+	if (forbidden || unchanged) {
+		ret = forbidden ? -EBUSY : 0;
+		goto dev_exit;
+	}
+
+	ret = pm_runtime_resume_and_get(dev->dev);
+	if (ret < 0)
+		goto dev_exit;
+
+	state = drm_atomic_commit_alloc(dev);
+	if (!state) {
+		ret = -ENOMEM;
+		goto pm_put;
+	}
+
+	/* Kernel commits allow a modeset by default, which a level change doesn't need */
+	state->allow_modeset = false;
+
+	drm_modeset_acquire_init(&ctx, DRM_MODESET_ACQUIRE_INTERRUPTIBLE);
+	state->acquire_ctx = &ctx;
+retry:
+	conn_state = drm_atomic_get_connector_state(state, connector);
+	if (IS_ERR(conn_state)) {
+		ret = PTR_ERR(conn_state);
+		goto out;
+	}
+
+	dm_state = to_dm_connector_state(conn_state);
+	if (dm_state->abm_sysfs_forbidden) {
+		ret = -EBUSY;
+		goto out;
+	}
+
+	if (dm_state->abm_level == level) {
+		ret = 0;
+		goto out;
+	}
+
+	dm_state->abm_level = level;
+
+	ret = drm_atomic_commit(state);
+out:
+	if (ret == -EDEADLK) {
+		drm_atomic_commit_clear(state);
+		ret = drm_modeset_backoff(&ctx);
+		if (!ret)
+			goto retry;
+	}
+
+	drm_atomic_commit_put(state);
+	drm_modeset_drop_locks(&ctx);
+	drm_modeset_acquire_fini(&ctx);
+pm_put:
+	pm_runtime_put_autosuspend(dev->dev);
+dev_exit:
+	drm_dev_exit(idx);
+
+	return ret;
+}
+
 STATIC_IFN_KUNIT
 ssize_t panel_power_savings_store(struct device *device,
 				 struct device_attribute *attr,
 				 const char *buf, size_t count)
 {
 	struct drm_connector *connector = dev_get_drvdata(device);
-	struct drm_device *dev = connector->dev;
 	long val;
 	int ret;
 
@@ -730,19 +832,13 @@ ssize_t panel_power_savings_store(struct device *device,
 	if (val < 0 || val > 4)
 		return -EINVAL;
 
-	drm_modeset_lock(&dev->mode_config.connection_mutex, NULL);
-	if (to_dm_connector_state(connector->state)->abm_sysfs_forbidden)
-		ret = -EBUSY;
-	else
-		to_dm_connector_state(connector->state)->abm_level = val ?:
-			ABM_LEVEL_IMMEDIATE_DISABLE;
-	drm_modeset_unlock(&dev->mode_config.connection_mutex);
-
+	ret = panel_power_savings_apply(connector, val);
+	/* The modeset locks return -EINTR, which write(2) would not restart */
+	if (ret == -EINTR)
+		return -ERESTARTSYS;
 	if (ret)
 		return ret;
 
-	drm_kms_helper_hotplug_event(dev);
-
 	return count;
 }
 EXPORT_IF_KUNIT(panel_power_savings_store);

-- 
2.56.0

