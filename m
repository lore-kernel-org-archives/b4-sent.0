From: Hugo Sales <hugo@hsal.es>
Date: Fri, 13 Nov 2026 20:24:52 +0000
Subject: [PATCH v2 5/5] drm/amd/display: Test panel_power_savings commits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-abm-sysfs-commit-v2-5-5808d17a7e89@hsal.es>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=12931; i=hugo@hsal.es;
 h=from:subject:message-id; bh=YpTAGTLXAp7SFOAVq0iSaKIiV7GZ186E+ZpVnsVE+Wk=;
 b=owJ4nJvAy8zAJVbLU7f+5A3TBYyn1ZIYsr4XCVh4/0jSzFGx+3p9qt/FXQsmNH2QTI14XLj95
 6HlCjelix51lLIwiHExyIopsuje8GRgmTh5Zk7R8yUwc1iZQIYwcHEKwERKoxn+md55qlZWl7lo
 zdEAnWn185OP9G65kTetPrK2Zc76LQL1vgz/E+22cJ+MYw6+5PFnQ0LxyoPTuXK8pXzW+KsGZs0
 La87jAABTLUu6
X-Developer-Key: i=hugo@hsal.es; a=openpgp;
 fpr=193D095149CF7E8737B39064D912B0DB205A91C1
X-Endpoint-Received: by B4 Relay for hugo@hsal.es/default with auth_id=1417
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add KUnit cases for a panel_power_savings write to a connector bound to a
CRTC. With the CRTC on or off, the store commits a connector state that
carries the level. When atomic check rejects the commit, the write returns
the error and the connector keeps its old level. A write of the current
level succeeds without a commit. The existing store tests also check that a
write replaces the connector state, and that a forbidden write keeps the
state and level. A forbidden write and a write of the current level leave a
runtime-suspended GPU suspended. For the new cases, the pipe helper can
route the connector to the CRTC, set whether the CRTC is active and take
CRTC helper funcs

The store checks the forbidden flag and the level again on the duplicated
connector state. Those checks only fire when a commit changes the level
between the first check and the commit's locks, which these tests can't
set up

Signed-off-by: Hugo Sales <hugo@hsal.es>
---
 .../amdgpu_dm/tests/amdgpu_dm_backlight_test.c     | 195 ++++++++++++++++++++-
 1 file changed, 188 insertions(+), 7 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_backlight_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_backlight_test.c
index 5133c8f251f53..2484788946d54 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_backlight_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_backlight_test.c
@@ -10,6 +10,7 @@
 #include <linux/pm_runtime.h>
 
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_uapi.h>
 #include <drm/drm_connector.h>
 #include <drm/drm_kunit_helpers.h>
 #include <drm/drm_managed.h>
@@ -564,16 +565,43 @@ static const struct drm_connector_helper_funcs dm_test_pps_connector_helper_func
 	.get_modes = dm_test_pps_get_modes,
 };
 
+static int dm_test_pps_crtc_atomic_check_fail(struct drm_crtc *crtc,
+					      struct drm_atomic_commit *state)
+{
+	return -ENOSPC;
+}
+
+static const struct drm_crtc_helper_funcs dm_test_pps_crtc_helper_funcs_fail = {
+	.atomic_check = dm_test_pps_crtc_atomic_check_fail,
+};
+
+/* The generic helpers accept a commit that allows a modeset it doesn't need */
+static int dm_test_pps_crtc_atomic_check_no_modeset(struct drm_crtc *crtc,
+						    struct drm_atomic_commit *state)
+{
+	return state->allow_modeset ? -EINVAL : 0;
+}
+
+static const struct drm_crtc_helper_funcs dm_test_pps_crtc_helper_funcs_no_modeset = {
+	.atomic_check = dm_test_pps_crtc_atomic_check_no_modeset,
+};
+
 /*
  * Build a primary plane, a CRTC, an encoder and an eDP connector that the
- * store can commit to. The KUnit device uses the generic atomic helpers, so a
- * commit runs drm_atomic_helper_check() and drm_atomic_helper_commit() rather
- * than the DM implementations
+ * store can commit to. With @bound, the connector's current state is routed
+ * to the CRTC, which is enabled and has @active as its active state. The KUnit
+ * device uses the generic atomic helpers, so a commit runs
+ * drm_atomic_helper_check() and drm_atomic_helper_commit() rather than the DM
+ * implementations. A NULL @crtc_helper_funcs gives the KUnit helper's defaults
  */
 static struct drm_connector *
-setup_panel_power_savings_pipe(struct kunit *test, struct device **device_out)
+setup_panel_power_savings_pipe(struct kunit *test, struct device **device_out,
+			       bool bound, bool active,
+			       const struct drm_crtc_helper_funcs *crtc_helper_funcs)
 {
 	struct amdgpu_dm_connector *aconnector;
+	struct drm_display_mode *mode;
+	struct drm_crtc_state *crtc_state;
 	struct drm_connector *connector;
 	struct drm_encoder *encoder;
 	struct amdgpu_device *adev;
@@ -589,7 +617,7 @@ setup_panel_power_savings_pipe(struct kunit *test, struct device **device_out)
 							NULL, NULL, 0, NULL);
 	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, primary);
 	crtc = drm_kunit_helper_create_crtc(test, &adev->ddev, primary, NULL,
-					    NULL, NULL);
+					    NULL, crtc_helper_funcs);
 	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, crtc);
 
 	encoder = drmm_kzalloc(&adev->ddev, sizeof(*encoder), GFP_KERNEL);
@@ -610,6 +638,21 @@ setup_panel_power_savings_pipe(struct kunit *test, struct device **device_out)
 	drm_mode_config_reset(&adev->ddev);
 	KUNIT_ASSERT_NOT_NULL(test, connector->state);
 
+	if (bound) {
+		/* A connector state bound to a CRTC holds a connector reference */
+		connector->state->crtc = crtc;
+		drm_connector_get(connector);
+		connector->state->best_encoder = encoder;
+		crtc_state = crtc->state;
+		crtc_state->connector_mask = drm_connector_mask(connector);
+		crtc_state->encoder_mask = drm_encoder_mask(encoder);
+		crtc_state->enable = true;
+		crtc_state->active = active;
+		mode = drm_kunit_display_mode_from_cea_vic(test, &adev->ddev, 1);
+		KUNIT_ASSERT_NOT_NULL(test, mode);
+		KUNIT_ASSERT_EQ(test, drm_atomic_set_mode_for_crtc(crtc_state, mode), 0);
+	}
+
 	device = kunit_kzalloc(test, sizeof(*device), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, device);
 	dev_set_drvdata(device, connector);
@@ -618,6 +661,35 @@ setup_panel_power_savings_pipe(struct kunit *test, struct device **device_out)
 	return connector;
 }
 
+static void dm_test_pps_expect_no_pm_reference(struct kunit *test,
+					       struct drm_connector *connector)
+{
+#ifdef CONFIG_PM
+	KUNIT_EXPECT_EQ(test, atomic_read(&connector->dev->dev->power.usage_count), 0);
+#endif
+}
+
+static void dm_test_pps_runtime_suspend(struct kunit *test,
+					struct drm_connector *connector)
+{
+#ifdef CONFIG_PM
+	struct device *dev = connector->dev->dev;
+
+	pm_runtime_disable(dev);
+	KUNIT_ASSERT_EQ(test, pm_runtime_set_suspended(dev), 0);
+	pm_runtime_enable(dev);
+#endif
+}
+
+static void dm_test_pps_expect_still_suspended(struct kunit *test,
+					       struct drm_connector *connector)
+{
+#ifdef CONFIG_PM
+	KUNIT_EXPECT_TRUE(test, pm_runtime_suspended(connector->dev->dev));
+#endif
+	dm_test_pps_expect_no_pm_reference(test, connector);
+}
+
 static void dm_test_free_sysfs_buf(void *data)
 {
 	free_page((unsigned long)data);
@@ -678,18 +750,24 @@ static void dm_test_panel_power_savings_show_reports_level(struct kunit *test)
 /**
  * dm_test_panel_power_savings_store_sets_disable - Test zero maps to disable
  * @test: The KUnit test context
+ *
+ * With no CRTC on the connector, the store commits a connector state that
+ * carries the disable sentinel
  */
 static void dm_test_panel_power_savings_store_sets_disable(struct kunit *test)
 {
+	struct drm_connector_state *old_state;
 	struct drm_connector *connector;
 	struct device *device;
 	size_t count = strlen("0");
 
-	connector = setup_panel_power_savings_pipe(test, &device);
+	connector = setup_panel_power_savings_pipe(test, &device, false, false, NULL);
 	to_dm_connector_state(connector->state)->abm_level = 2;
+	old_state = connector->state;
 
 	KUNIT_EXPECT_EQ(test, panel_power_savings_store(device, NULL, "0", count),
 			 (ssize_t)count);
+	KUNIT_EXPECT_PTR_NE(test, connector->state, old_state);
 	KUNIT_EXPECT_EQ(test, to_dm_connector_state(connector->state)->abm_level,
 			ABM_LEVEL_IMMEDIATE_DISABLE);
 }
@@ -697,6 +775,9 @@ static void dm_test_panel_power_savings_store_sets_disable(struct kunit *test)
 /**
  * dm_test_panel_power_savings_store_forbidden - Test forbidden update
  * @test: The KUnit test context
+ *
+ * Once the DRM master owns the level, the store fails without committing and
+ * without waking the runtime-suspended GPU
  */
 static void dm_test_panel_power_savings_store_forbidden(struct kunit *test)
 {
@@ -704,11 +785,16 @@ static void dm_test_panel_power_savings_store_forbidden(struct kunit *test)
 	struct drm_connector *connector;
 	struct device *device;
 
-	connector = setup_panel_power_savings_pipe(test, &device);
+	connector = setup_panel_power_savings_pipe(test, &device, false, false, NULL);
 	dm_state = to_dm_connector_state(connector->state);
 	dm_state->abm_sysfs_forbidden = true;
+	dm_state->abm_level = 2;
+	dm_test_pps_runtime_suspend(test, connector);
 
 	KUNIT_EXPECT_EQ(test, panel_power_savings_store(device, NULL, "1", 1), -EBUSY);
+	KUNIT_EXPECT_PTR_EQ(test, connector->state, &dm_state->base);
+	KUNIT_EXPECT_EQ(test, dm_state->abm_level, 2);
+	dm_test_pps_expect_still_suspended(test, connector);
 }
 
 /**
@@ -757,6 +843,98 @@ static void dm_test_panel_power_savings_store_rejects_out_of_range(struct kunit
 	KUNIT_EXPECT_EQ(test, panel_power_savings_store(device, NULL, "5", 1), -EINVAL);
 }
 
+struct dm_pps_store_crtc_param {
+	const char *name;
+	bool active;
+	const char *buf;
+	int level;
+};
+
+static const struct dm_pps_store_crtc_param dm_pps_store_crtc_params[] = {
+	{ "inactive", false, "3", 3 },
+	{ "active", true, "2", 2 },
+};
+
+KUNIT_ARRAY_PARAM_DESC(dm_pps_store_crtc, dm_pps_store_crtc_params, name);
+
+/**
+ * dm_test_panel_power_savings_store_crtc - Test store with the CRTC on or off
+ * @test: The KUnit test context
+ *
+ * With the connector's CRTC enabled, active or not, the store commits a
+ * connector state that carries the level, without allowing a modeset, and
+ * drops its runtime PM reference
+ */
+static void dm_test_panel_power_savings_store_crtc(struct kunit *test)
+{
+	const struct dm_pps_store_crtc_param *param = test->param_value;
+	struct drm_connector_state *old_state;
+	struct drm_connector *connector;
+	struct device *device;
+
+	connector = setup_panel_power_savings_pipe(test, &device, true, param->active,
+						   &dm_test_pps_crtc_helper_funcs_no_modeset);
+	old_state = connector->state;
+
+	KUNIT_EXPECT_EQ(test, panel_power_savings_store(device, NULL, param->buf, 1), 1);
+	KUNIT_EXPECT_PTR_NE(test, connector->state, old_state);
+	KUNIT_EXPECT_EQ(test, to_dm_connector_state(connector->state)->abm_level,
+			param->level);
+	KUNIT_EXPECT_FALSE(test, drm_atomic_crtc_needs_modeset(connector->state->crtc->state));
+	dm_test_pps_expect_no_pm_reference(test, connector);
+}
+
+/**
+ * dm_test_panel_power_savings_store_commit_fails - Test store when the commit fails
+ * @test: The KUnit test context
+ *
+ * When atomic check rejects the commit, the write returns the error, the
+ * current connector state keeps the old level and the runtime PM reference is
+ * dropped
+ */
+static void dm_test_panel_power_savings_store_commit_fails(struct kunit *test)
+{
+	struct drm_connector_state *old_state;
+	struct drm_connector *connector;
+	struct device *device;
+
+	connector = setup_panel_power_savings_pipe(test, &device, true, true,
+						   &dm_test_pps_crtc_helper_funcs_fail);
+	to_dm_connector_state(connector->state)->abm_level = 1;
+	old_state = connector->state;
+
+	KUNIT_EXPECT_EQ(test, panel_power_savings_store(device, NULL, "4", 1), -ENOSPC);
+	KUNIT_EXPECT_PTR_EQ(test, connector->state, old_state);
+	KUNIT_EXPECT_EQ(test, to_dm_connector_state(connector->state)->abm_level, 1);
+	dm_test_pps_expect_no_pm_reference(test, connector);
+}
+
+/**
+ * dm_test_panel_power_savings_store_same_level - Test store of the current level
+ * @test: The KUnit test context
+ *
+ * Writing the level the connector already has succeeds without a commit, so
+ * the connector keeps its state even though atomic check would fail, and the
+ * runtime-suspended GPU stays suspended
+ */
+static void dm_test_panel_power_savings_store_same_level(struct kunit *test)
+{
+	struct drm_connector_state *old_state;
+	struct drm_connector *connector;
+	struct device *device;
+
+	connector = setup_panel_power_savings_pipe(test, &device, true, true,
+						   &dm_test_pps_crtc_helper_funcs_fail);
+	to_dm_connector_state(connector->state)->abm_level = 2;
+	old_state = connector->state;
+	dm_test_pps_runtime_suspend(test, connector);
+
+	KUNIT_EXPECT_EQ(test, panel_power_savings_store(device, NULL, "2", 1), 1);
+	KUNIT_EXPECT_PTR_EQ(test, connector->state, old_state);
+	KUNIT_EXPECT_EQ(test, to_dm_connector_state(connector->state)->abm_level, 2);
+	dm_test_pps_expect_still_suspended(test, connector);
+}
+
 /* Tests for amdgpu_dm_backlight_get_device_index() */
 
 /**
@@ -2019,6 +2197,9 @@ static struct kunit_case dm_backlight_test_cases[] = {
 	KUNIT_CASE(dm_test_panel_power_savings_store_forbidden),
 	KUNIT_CASE(dm_test_panel_power_savings_store_rejects_invalid_text),
 	KUNIT_CASE(dm_test_panel_power_savings_store_rejects_out_of_range),
+	KUNIT_CASE_PARAM(dm_test_panel_power_savings_store_crtc, dm_pps_store_crtc_gen_params),
+	KUNIT_CASE(dm_test_panel_power_savings_store_commit_fails),
+	KUNIT_CASE(dm_test_panel_power_savings_store_same_level),
 	/* amdgpu_dm_backlight_get_device_index */
 	KUNIT_CASE(dm_test_backlight_device_index_matches_second),
 	KUNIT_CASE(dm_test_backlight_device_index_missing_fallback),

-- 
2.56.0

