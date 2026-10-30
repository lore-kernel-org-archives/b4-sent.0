From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Sat, 31 Oct 2026 03:28:50 +0530
Subject: [PATCH] drm/amd/display: use atomic commit for panel power savings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-abm-sysfs-atomic-v1-1-a99068f3b49c@zohomail.in>
X-B4-Tracking: v=1; b=H4sIABkT5WoC/yXMQQqDMBBA0avIrDuQRGLRq5QuYpzoFNSSUVEkd
 ze2y7f4/wShyCTQFCdE2lh4njL0owA/uKkn5C4bjDKVVqVG144ohwRBt8wje/TP2iobqtIZgpx
 9IwXef8vX+29Z2w/55f5AShdvtFx9dAAAAA==
X-Change-ID: 20261031-abm-sysfs-atomic-c79505f63a2e
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Hamza Mahfooz <hamzamahfooz@linux.microsoft.com>, 
 Mario Limonciello <mario.limonciello@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, David Weber <weber.aulendorf@gmail.com>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793397663; l=12858;
 i=shivamkalra98@zohomail.in; s=20260402; h=from:subject:message-id;
 bh=jACiQwIUkVzip4GOIHF0xLWEFouP+BbAsfe/i/JrkeI=;
 b=YlU+jkoRUFl1QWKkiZLwFHxNq1W9Ny88KCYR5dgFIH8NS6DbxvdxRYD/BlEIStZhf2QMJGRQq
 EpagiSbvMY5Dw/8IstrIPbInl7iuj2RhIwY4W8T+xGrFvkc+hZBiAKi
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=U8kQSxcte8P8iZ6zB7phIj+Yl+i/5ntifBGuclgypx8=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260402 with auth_id=716
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panel_power_savings_store() mutates connector->state directly and sends a
hotplug event. This bypasses atomic commit handling, so the new ABM level
is only applied when userspace happens to perform another modeset, and it
races with concurrent commits.

Build an atomic state, set the level on the connector state and commit it.
If the connector is not attached to a CRTC, keep the level in the current
state so the next modeset picks it up, as before.

A previous attempt to avoid the modeset by calling into DMUB directly was
reverted because it broke the abm_gradual IGT test (8d20a066fa9b,
95aaa207e9ef). This version instead uses the normal atomic stream update
path.

Expose the atomic state update helper for KUnit and extend the tests to
cover the atomic update and the inactive sysfs path.

Fixes: 63d0b87213a0 ("drm/amd/display: add panel_power_savings sysfs entry to eDP connectors")
Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
Note: This patch works standalone (applying ABM changes via a modeset), and
pairs cleanly with David Weber's unmerged series [1] ("drm/amd/display: Skip
connector updates without a stream" and "drm/amd/display: Avoid modeset for
ABM changes") to allow non-modeset ABM updates via the stream update path.

[1] https://lore.kernel.org/amd-gfx/20260813112634.11455-1-weber.aulendorf@gmail.com/

Testing:
- KUnit: the amdgpu_dm_backlight suite passes on amd-staging-drm-next
  (75/75 tests passed), covering the new atomic update and inactive sysfs
  tests.
- Hardware: tested on a 7.1.13-based kernel backport alongside [1]. Before
  the patch, the store called drm_kms_helper_hotplug_event(), produced two
  HOTPLUG=1 uevents (triggering 36 GetConnector probes / 20.8 ms stall in
  Xorg), and the backlight PWM sweep stayed flat at 6998 for levels 0..4.
  With the patch, ftrace shows panel_power_savings_store() ->
  drm_atomic_commit() -> amdgpu_dm_atomic_commit_tail() ->
  dc_update_planes_and_stream() -> dmub_abm_set_level_ex(), with no hotplug
  event or connector reprobe. The PWM sweep tracks the requested level
  (11130, 8304, 5782, 3815 and 2782 target for levels 0..4; 75% target
  reduction at level 4, 73.8% measured).
---
 .../amd/display/amdgpu_dm/amdgpu_dm_backlight.c    | 85 ++++++++++++++++---
 .../amd/display/amdgpu_dm/amdgpu_dm_backlight.h    |  3 +
 .../amdgpu_dm/tests/amdgpu_dm_backlight_test.c     | 95 +++++++++++++++++++++-
 3 files changed, 172 insertions(+), 11 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c
index 27546febf90d..f8d797324319 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c
@@ -712,6 +712,31 @@ ssize_t panel_power_savings_show(struct device *device,
 }
 EXPORT_IF_KUNIT(panel_power_savings_show);
 
+static int
+panel_power_savings_set_level(struct dm_connector_state *dm_conn_state, long val)
+{
+	if (dm_conn_state->abm_sysfs_forbidden)
+		return -EBUSY;
+
+	dm_conn_state->abm_level = val ?: ABM_LEVEL_IMMEDIATE_DISABLE;
+
+	return 0;
+}
+
+STATIC_IFN_KUNIT int
+panel_power_savings_update_state(struct drm_atomic_commit *state,
+				 struct drm_connector *connector, long val)
+{
+	struct drm_connector_state *conn_state;
+
+	conn_state = drm_atomic_get_connector_state(state, connector);
+	if (IS_ERR(conn_state))
+		return PTR_ERR(conn_state);
+
+	return panel_power_savings_set_level(to_dm_connector_state(conn_state), val);
+}
+EXPORT_IF_KUNIT(panel_power_savings_update_state);
+
 STATIC_IFN_KUNIT
 ssize_t panel_power_savings_store(struct device *device,
 				 struct device_attribute *attr,
@@ -719,6 +744,9 @@ ssize_t panel_power_savings_store(struct device *device,
 {
 	struct drm_connector *connector = dev_get_drvdata(device);
 	struct drm_device *dev = connector->dev;
+	struct drm_modeset_acquire_ctx ctx;
+	struct drm_connector_state *conn_state;
+	struct drm_atomic_commit *state;
 	long val;
 	int ret;
 
@@ -730,20 +758,57 @@ ssize_t panel_power_savings_store(struct device *device,
 	if (val < 0 || val > 4)
 		return -EINVAL;
 
-	drm_modeset_lock(&dev->mode_config.connection_mutex, NULL);
-	if (to_dm_connector_state(connector->state)->abm_sysfs_forbidden)
-		ret = -EBUSY;
-	else
-		to_dm_connector_state(connector->state)->abm_level = val ?:
-			ABM_LEVEL_IMMEDIATE_DISABLE;
-	drm_modeset_unlock(&dev->mode_config.connection_mutex);
+	drm_modeset_acquire_init(&ctx, 0);
+	state = drm_atomic_commit_alloc(dev);
+	if (!state) {
+		ret = -ENOMEM;
+		goto out_ctx;
+	}
+	state->acquire_ctx = &ctx;
 
+retry:
+	ret = panel_power_savings_update_state(state, connector, val);
+	if (ret == -EDEADLK)
+		goto backoff;
 	if (ret)
-		return ret;
+		goto out_state;
+
+	conn_state = drm_atomic_get_new_connector_state(state, connector);
+	if (!conn_state) {
+		ret = -EINVAL;
+		goto out_state;
+	}
+
+	/*
+	 * Without a CRTC there is no stream to update and nothing to commit.
+	 * Keep the level in the current state so the next modeset picks it
+	 * up, matching the behavior of the sysfs interface.
+	 */
+	if (!conn_state->crtc) {
+		to_dm_connector_state(connector->state)->abm_level =
+			to_dm_connector_state(conn_state)->abm_level;
+		goto out_state;
+	}
+
+	ret = drm_atomic_commit(state);
+	if (ret == -EDEADLK)
+		goto backoff;
+
+out_state:
+	drm_atomic_commit_put(state);
+out_ctx:
+	drm_modeset_drop_locks(&ctx);
+	drm_modeset_acquire_fini(&ctx);
+
+	return ret ? ret : count;
 
-	drm_kms_helper_hotplug_event(dev);
+backoff:
+	drm_atomic_commit_clear(state);
+	ret = drm_modeset_backoff(&ctx);
+	if (!ret)
+		goto retry;
 
-	return count;
+	goto out_state;
 }
 EXPORT_IF_KUNIT(panel_power_savings_store);
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.h b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.h
index 9ad888d3ae7b..d92ec0789f15 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.h
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.h
@@ -34,6 +34,7 @@ struct device;
 struct device_attribute;
 struct drm_connector;
 struct attribute_group;
+struct drm_atomic_commit;
 
 #define AMDGPU_DM_DEFAULT_MIN_BACKLIGHT 12
 #define AMDGPU_DM_DEFAULT_MAX_BACKLIGHT 255
@@ -65,6 +66,8 @@ ssize_t panel_power_savings_show(struct device *device,
 ssize_t panel_power_savings_store(struct device *device,
 				 struct device_attribute *attr,
 				 const char *buf, size_t count);
+int panel_power_savings_update_state(struct drm_atomic_commit *state,
+				     struct drm_connector *connector, long val);
 int get_brightness_range(const struct amdgpu_dm_backlight_caps *caps,
 			 unsigned int *min, unsigned int *max);
 void convert_custom_brightness(const struct amdgpu_dm_backlight_caps *caps,
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_backlight_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_backlight_test.c
index c6d15fb8ad98..a482261e85d2 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_backlight_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_backlight_test.c
@@ -514,6 +514,37 @@ static void dm_test_register_backlight_device_success(struct kunit *test)
 			adev->dm.backlight_dev[0]), 0);
 }
 
+static struct drm_connector_state *
+dm_test_panel_power_savings_duplicate_state(struct drm_connector *connector)
+{
+	struct dm_connector_state *state;
+
+	state = kmemdup(to_dm_connector_state(connector->state),
+			sizeof(*state), GFP_KERNEL);
+	if (!state)
+		return NULL;
+
+	__drm_atomic_helper_connector_duplicate_state(connector, &state->base);
+
+	return &state->base;
+}
+
+static void
+dm_test_panel_power_savings_destroy_state(struct drm_connector *connector,
+					  struct drm_connector_state *state)
+{
+	__drm_atomic_helper_connector_destroy_state(state);
+	kfree(to_dm_connector_state(state));
+}
+
+static const struct drm_connector_funcs dm_test_panel_power_savings_connector_funcs = {
+	.atomic_duplicate_state = dm_test_panel_power_savings_duplicate_state,
+	.atomic_destroy_state = dm_test_panel_power_savings_destroy_state,
+};
+
+static const struct drm_mode_config_funcs dm_test_panel_power_savings_mode_funcs = {
+};
+
 static struct drm_connector *setup_panel_power_savings_connector(struct kunit *test,
 							 struct device **device_out,
 							 struct dm_connector_state **state_out)
@@ -527,6 +558,7 @@ static struct drm_connector *setup_panel_power_savings_connector(struct kunit *t
 	adev = dm_kunit_alloc_adev(test);
 	ret = drmm_mode_config_init(&adev->ddev);
 	KUNIT_ASSERT_EQ(test, ret, 0);
+	adev->ddev.mode_config.funcs = &dm_test_panel_power_savings_mode_funcs;
 
 	connector = kunit_kzalloc(test, sizeof(*connector), GFP_KERNEL);
 	device = kunit_kzalloc(test, sizeof(*device), GFP_KERNEL);
@@ -536,7 +568,11 @@ static struct drm_connector *setup_panel_power_savings_connector(struct kunit *t
 	KUNIT_ASSERT_NOT_NULL(test, state);
 
 	connector->dev = &adev->ddev;
+	connector->funcs = &dm_test_panel_power_savings_connector_funcs;
+	connector->index = 0;
+	kref_init(&connector->base.refcount);
 	connector->state = &state->base;
+	state->base.connector = connector;
 	dev_set_drvdata(device, connector);
 	*device_out = device;
 	*state_out = state;
@@ -614,10 +650,40 @@ static void dm_test_panel_power_savings_store_sets_disable(struct kunit *test)
 	setup_panel_power_savings_connector(test, &device, &state);
 
 	KUNIT_EXPECT_EQ(test, panel_power_savings_store(device, NULL, "0", count),
-			 (ssize_t)count);
+			(ssize_t)count);
 	KUNIT_EXPECT_EQ(test, state->abm_level, ABM_LEVEL_IMMEDIATE_DISABLE);
 }
 
+static void dm_test_panel_power_savings_update_state_sets_disable(struct kunit *test)
+{
+	struct drm_modeset_acquire_ctx ctx;
+	struct drm_connector_state *conn_state;
+	struct drm_atomic_commit *atomic;
+	struct dm_connector_state *state;
+	struct drm_connector *connector;
+	struct device *device;
+	int ret;
+
+	connector = setup_panel_power_savings_connector(test, &device, &state);
+	atomic = drm_atomic_commit_alloc(connector->dev);
+	KUNIT_ASSERT_NOT_NULL(test, atomic);
+
+	drm_modeset_acquire_init(&ctx, 0);
+	atomic->acquire_ctx = &ctx;
+
+	ret = panel_power_savings_update_state(atomic, connector, 0);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+
+	conn_state = drm_atomic_get_new_connector_state(atomic, connector);
+	KUNIT_ASSERT_NOT_NULL(test, conn_state);
+	KUNIT_EXPECT_EQ(test, to_dm_connector_state(conn_state)->abm_level,
+			ABM_LEVEL_IMMEDIATE_DISABLE);
+
+	drm_atomic_commit_put(atomic);
+	drm_modeset_drop_locks(&ctx);
+	drm_modeset_acquire_fini(&ctx);
+}
+
 /**
  * dm_test_panel_power_savings_store_forbidden - Test forbidden update
  * @test: The KUnit test context
@@ -633,6 +699,31 @@ static void dm_test_panel_power_savings_store_forbidden(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, panel_power_savings_store(device, NULL, "1", 1), -EBUSY);
 }
 
+static void dm_test_panel_power_savings_update_state_forbidden(struct kunit *test)
+{
+	struct drm_modeset_acquire_ctx ctx;
+	struct drm_atomic_commit *atomic;
+	struct dm_connector_state *state;
+	struct drm_connector *connector;
+	struct device *device;
+	int ret;
+
+	connector = setup_panel_power_savings_connector(test, &device, &state);
+	state->abm_sysfs_forbidden = true;
+	atomic = drm_atomic_commit_alloc(connector->dev);
+	KUNIT_ASSERT_NOT_NULL(test, atomic);
+
+	drm_modeset_acquire_init(&ctx, 0);
+	atomic->acquire_ctx = &ctx;
+
+	ret = panel_power_savings_update_state(atomic, connector, 1);
+	KUNIT_EXPECT_EQ(test, ret, -EBUSY);
+
+	drm_atomic_commit_put(atomic);
+	drm_modeset_drop_locks(&ctx);
+	drm_modeset_acquire_fini(&ctx);
+}
+
 /**
  * dm_test_panel_power_savings_store_rejects_invalid_text - Test parse failure
  * @test: The KUnit test context
@@ -1939,6 +2030,8 @@ static struct kunit_case dm_backlight_test_cases[] = {
 	KUNIT_CASE(dm_test_panel_power_savings_show_reports_level),
 	KUNIT_CASE(dm_test_panel_power_savings_store_sets_disable),
 	KUNIT_CASE(dm_test_panel_power_savings_store_forbidden),
+	KUNIT_CASE(dm_test_panel_power_savings_update_state_sets_disable),
+	KUNIT_CASE(dm_test_panel_power_savings_update_state_forbidden),
 	KUNIT_CASE(dm_test_panel_power_savings_store_rejects_invalid_text),
 	KUNIT_CASE(dm_test_panel_power_savings_store_rejects_out_of_range),
 	/* amdgpu_dm_backlight_get_device_index */

---
base-commit: ba496bb837882eb1af58f41572fc289e46c77b8c
change-id: 20261031-abm-sysfs-atomic-c79505f63a2e

Best regards,
--  
Shivam Kalra <shivamkalra98@zohomail.in>

