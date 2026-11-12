From: Dave Airlie <airlied@redhat.com>
Date: Thu, 12 Nov 2026 11:43:47 +1000
Subject: [PATCH 12/19] drm/amd/display: Migrate amdgpu_dm KUnit tests off
 struct dc internals
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261112-amdgpu-dc-cleanup-v1-12-0fae41718ad2@redhat.com>
References: <20261112-amdgpu-dc-cleanup-v1-0-0fae41718ad2@redhat.com>
In-Reply-To: <20261112-amdgpu-dc-cleanup-v1-0-0fae41718ad2@redhat.com>
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Austin Zheng <austin.zheng@amd.com>, 
 Jun Lei <jun.lei@amd.com>, Kenneth Feng <kenneth.feng@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=144439; i=airlied@redhat.com;
 h=from:subject:message-id; bh=NgxHCOqbvhBBnObMydLZyk58BDA1O3i5Kw28vcLV00o=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq9RnQSDl+Im9RIkE/VGXYX0dwnBrpQywrtqJV1
 15JdI2l4g+JAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavUZ0AAKCRAMdPNZecSG
 vvmpD/wNrw7/r5CPJ5GtbIkRTpGMOZL8fjgEd+ja3RKgb3Lz5SjjGUhwpgcXPR5PuvNAeEqgPqP
 kaCjZeNWhgcf9T1H85M9Ep9BaNBu6gxoPNe58S2KFvp0xuSfjkWjtDPMBd9z442ic6orFnd31i5
 GdUvjrb42uymbW8eEPMPHac34Oc12jNsaerNGOjdXQiy34kTRda/IT9xLE2MGrFqUbajrTq0uwZ
 /Bxx8YwKrEIsESWFsZ6HQI8n0rzqMXC5EzfzntF0GAihVT22LswTwH26L64qunDqphTWCpOzhM7
 7977ULDJTN3NhCOfQsvkfdC9jfVXCDVwVjV9KfCSttnG4q07EDbMUI5CefmXwawFiE9aQDY9Reg
 o+8UmZrYUrIQTMDkVDgwu+jrMKvqRhgnS72/EA1JjeD5thk5Nd8KMOqB/GqeQH1vbVZ40hngAgG
 KqkFcwMw31rdtoqq61MqdUOgtnyy1/FN1LOy1ztnmnOq2UOfn+i7QaD3oTSHW2P7EMiu3MiUIAd
 5voxN0NqLQwhYi8e9rO8J/XOm5WWy7XFlZLp6pOiNSHJZM9wuBe+MGvEOeFWLmbdO170wLoiWQ9
 A2o7TTiW5C+xsOP3pE6SnYYs7m9UEpSb9g5MWrXjfhGw8PT9tf/qwEvGSgWFeO6jQoG7IJM0xZM
 zAfxbcZ5XThZK8w==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The amdgpu_dm KUnit tests constructed fake struct dc instances with
kunit_kzalloc(sizeof(*dc)) and populated members directly. Add a
KUnit-gated test double API in DC (dc/inc/dc_test.h implemented in
dc/core/dc_test.c) that allocates the fake and exposes setters and
mutable views for the members tests need:

- dc_test_create/destroy for the fake instance
- setters for ctx, current_state, link_srv, res_pool, clk_mgr,
  fbc_compressor, links[], link_count, idle_optimizations_allowed
- mutable views for caps, config, debug, hwss and cap_funcs

Rework dm_kunit_alloc_dc* helpers on top of it and convert all test
files to the API plus the public accessors (dc_get_ctx,
dc_get_current_state, dc_get_res_pool, dc_get_clk_mgr, ...), which
are exported for the test modules with EXPORT_IF_KUNIT.

No test logic changes; only how the fakes are built.

Part of making struct dc private to DC.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 .../display/amdgpu_dm/tests/amdgpu_dm_audio_test.c |  41 ++---
 .../amdgpu_dm/tests/amdgpu_dm_backlight_test.c     |  71 ++++----
 .../display/amdgpu_dm/tests/amdgpu_dm_color_test.c |  21 +--
 .../amdgpu_dm/tests/amdgpu_dm_colorop_test.c       |   8 +-
 .../amdgpu_dm/tests/amdgpu_dm_connector_test.c     |  62 ++++---
 .../display/amdgpu_dm/tests/amdgpu_dm_crc_test.c   |   5 +-
 .../display/amdgpu_dm/tests/amdgpu_dm_crtc_test.c  |  59 ++++---
 .../display/amdgpu_dm/tests/amdgpu_dm_dmub_test.c  |  74 ++++----
 .../amdgpu_dm/tests/amdgpu_dm_freesync_test.c      |   3 +-
 .../display/amdgpu_dm/tests/amdgpu_dm_hdcp_test.c  |  23 ++-
 .../amdgpu_dm/tests/amdgpu_dm_helpers_test.c       |  70 ++++----
 .../display/amdgpu_dm/tests/amdgpu_dm_irq_test.c   | 195 ++++++++++-----------
 .../display/amdgpu_dm/tests/amdgpu_dm_ism_test.c   |  31 ++--
 .../amdgpu_dm/tests/amdgpu_dm_kunit_helpers.c      |  26 ++-
 .../amdgpu_dm/tests/amdgpu_dm_kunit_test_helpers.h |   1 +
 .../amdgpu_dm/tests/amdgpu_dm_mst_types_test.c     |  81 ++++-----
 .../display/amdgpu_dm/tests/amdgpu_dm_plane_test.c |  73 ++++----
 .../display/amdgpu_dm/tests/amdgpu_dm_psr_test.c   |  21 +--
 .../amd/display/amdgpu_dm/tests/amdgpu_dm_test.c   |  53 +++---
 .../display/amdgpu_dm/tests/amdgpu_dm_wb_test.c    |   6 +-
 drivers/gpu/drm/amd/display/dc/Makefile            |   4 +
 drivers/gpu/drm/amd/display/dc/core/dc_accessors.c |   7 +
 drivers/gpu/drm/amd/display/dc/core/dc_test.c      | 135 ++++++++++++++
 drivers/gpu/drm/amd/display/dc/inc/dc_test.h       |  81 +++++++++
 24 files changed, 689 insertions(+), 462 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_audio_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_audio_test.c
index 281dac959dca..6d8651047ff7 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_audio_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_audio_test.c
@@ -18,6 +18,7 @@
 #include <drm/drm_probe_helper.h>
 
 #include "dc.h"
+#include "dc_test.h"
 #include "dc/inc/core_types.h"
 #include "dc/inc/hw/audio.h"
 #include "amdgpu.h"
@@ -103,7 +104,7 @@ static void dm_test_audio_init_enabled_success(struct kunit *test)
 	int saved_audio = amdgpu_dm_audio_get_param();
 
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	res_pool = kunit_kzalloc(test, sizeof(*res_pool), GFP_KERNEL);
 	audio0 = kunit_kzalloc(test, sizeof(*audio0), GFP_KERNEL);
 	audio1 = kunit_kzalloc(test, sizeof(*audio1), GFP_KERNEL);
@@ -121,7 +122,7 @@ static void dm_test_audio_init_enabled_success(struct kunit *test)
 	res_pool->audio_count = 2;
 	res_pool->audios[0] = audio0;
 	res_pool->audios[1] = audio1;
-	dc->res_pool = res_pool;
+	dc_test_set_res_pool(dc, res_pool);
 	adev->dm.dc = dc;
 	adev->dev = dev;
 
@@ -810,16 +811,16 @@ static void dm_test_commit_audio_notifies_added_connector(struct kunit *test)
 
 	adev->dm.dc = kunit_kzalloc(test, sizeof(*adev->dm.dc), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, adev->dm.dc);
-	adev->dm.dc->current_state = kunit_kzalloc(test,
-							 sizeof(*adev->dm.dc->current_state),
-							 GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, adev->dm.dc->current_state);
+	dc_test_set_current_state(adev->dm.dc, kunit_kzalloc(test,
+							 sizeof(*dc_get_current_state(adev->dm.dc)),
+							 GFP_KERNEL));
+	KUNIT_ASSERT_NOT_NULL(test, dc_get_current_state(adev->dm.dc));
 	stream->ctx = kunit_kzalloc(test, sizeof(*stream->ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, stream->ctx);
 	stream->ctx->dc = adev->dm.dc;
-	adev->dm.dc->current_state->stream_count = 1;
-	adev->dm.dc->current_state->streams[0] = stream;
-	adev->dm.dc->current_state->stream_status[0].audio_inst = 8;
+	dc_get_current_state(adev->dm.dc)->stream_count = 1;
+	dc_get_current_state(adev->dm.dc)->streams[0] = stream;
+	dc_get_current_state(adev->dm.dc)->stream_status[0].audio_inst = 8;
 
 	mutex_init(&adev->dm.audio_lock);
 	dm_test_audio_setup_notify_component(test, adev);
@@ -968,10 +969,10 @@ static void dm_test_commit_audio_skips_without_stream_status(struct kunit *test)
 
 	adev->dm.dc = kunit_kzalloc(test, sizeof(*adev->dm.dc), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, adev->dm.dc);
-	adev->dm.dc->current_state = kunit_kzalloc(test,
-							 sizeof(*adev->dm.dc->current_state),
-							 GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, adev->dm.dc->current_state);
+	dc_test_set_current_state(adev->dm.dc, kunit_kzalloc(test,
+							 sizeof(*dc_get_current_state(adev->dm.dc)),
+							 GFP_KERNEL));
+	KUNIT_ASSERT_NOT_NULL(test, dc_get_current_state(adev->dm.dc));
 	stream->ctx = kunit_kzalloc(test, sizeof(*stream->ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, stream->ctx);
 	stream->ctx->dc = adev->dm.dc;
@@ -1173,16 +1174,16 @@ static void dm_test_commit_audio_skips_writeback_addition(struct kunit *test)
 
 	adev->dm.dc = kunit_kzalloc(test, sizeof(*adev->dm.dc), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, adev->dm.dc);
-	adev->dm.dc->current_state = kunit_kzalloc(test,
-							 sizeof(*adev->dm.dc->current_state),
-							 GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, adev->dm.dc->current_state);
+	dc_test_set_current_state(adev->dm.dc, kunit_kzalloc(test,
+							 sizeof(*dc_get_current_state(adev->dm.dc)),
+							 GFP_KERNEL));
+	KUNIT_ASSERT_NOT_NULL(test, dc_get_current_state(adev->dm.dc));
 	stream->ctx = kunit_kzalloc(test, sizeof(*stream->ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, stream->ctx);
 	stream->ctx->dc = adev->dm.dc;
-	adev->dm.dc->current_state->stream_count = 1;
-	adev->dm.dc->current_state->streams[0] = stream;
-	adev->dm.dc->current_state->stream_status[0].audio_inst = 14;
+	dc_get_current_state(adev->dm.dc)->stream_count = 1;
+	dc_get_current_state(adev->dm.dc)->streams[0] = stream;
+	dc_get_current_state(adev->dm.dc)->stream_status[0].audio_inst = 14;
 
 	mutex_init(&adev->dm.audio_lock);
 	dm_test_audio_setup_notify_component(test, adev);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_backlight_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_backlight_test.c
index a60c0fbf519d..377b92d84b98 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_backlight_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_backlight_test.c
@@ -14,6 +14,7 @@
 #include <drm/drm_property.h>
 
 #include "dc.h"
+#include "dc_test.h"
 #include "dc_dmub_srv.h"
 #include "amdgpu.h"
 #include "amdgpu_display.h"
@@ -72,8 +73,8 @@ static void dm_test_find_stream_with_link_returns_match(struct kunit *test)
 	struct dc_link *target_link = dm_kunit_alloc_link(test);
 	struct dc_stream_state *stream;
 
-	dm_kunit_add_stream_to_state(test, dm->dc->current_state, 0, other_link);
-	dm_kunit_add_stream_to_state(test, dm->dc->current_state, 1, target_link);
+	dm_kunit_add_stream_to_state(test, dc_get_current_state(dm->dc), 0, other_link);
+	dm_kunit_add_stream_to_state(test, dc_get_current_state(dm->dc), 1, target_link);
 	stream = dm_find_stream_with_link(dm, target_link);
 
 	KUNIT_ASSERT_NOT_NULL(test, stream);
@@ -90,7 +91,7 @@ static void dm_test_find_stream_with_link_missing(struct kunit *test)
 	struct dc_link *stream_link = dm_kunit_alloc_link(test);
 	struct dc_link *missing_link = dm_kunit_alloc_link(test);
 
-	dm_kunit_add_stream_to_state(test, dm->dc->current_state, 0, stream_link);
+	dm_kunit_add_stream_to_state(test, dc_get_current_state(dm->dc), 0, stream_link);
 
 	KUNIT_EXPECT_NULL(test, dm_find_stream_with_link(dm, missing_link));
 }
@@ -182,7 +183,7 @@ static void dm_test_backlight_set_level_aux_programs_power_module(struct kunit *
 	dm->backlight_caps[1].min_input_signal = AMDGPU_DM_DEFAULT_MIN_BACKLIGHT;
 	dm->backlight_caps[1].max_input_signal = AMDGPU_DM_DEFAULT_MAX_BACKLIGHT;
 	dm->backlight_link[1] = link;
-	dm_kunit_add_stream_to_state(test, dm->dc->current_state, 0, link);
+	dm_kunit_add_stream_to_state(test, dc_get_current_state(dm->dc), 0, link);
 
 	amdgpu_dm_backlight_set_level(dm, 1, 2000);
 
@@ -227,7 +228,7 @@ static void dm_test_backlight_set_level_pwm_programs_power_module(struct kunit *
 	dm->backlight_caps[1].max_input_signal = AMDGPU_DM_DEFAULT_MAX_BACKLIGHT;
 	memcpy(dm->backlight_caps[1].luminance_data, curve, sizeof(curve));
 	dm->backlight_link[1] = link;
-	dm_kunit_add_stream_to_state(test, dm->dc->current_state, 0, link);
+	dm_kunit_add_stream_to_state(test, dc_get_current_state(dm->dc), 0, link);
 
 	amdgpu_dm_set_dc_debug_mask(saved_mask & ~DC_DISABLE_CUSTOM_BRIGHTNESS_CURVE);
 	for (i = 0; i < ARRAY_SIZE(cases); i++) {
@@ -266,23 +267,23 @@ static void dm_test_backlight_set_level_reallows_idle(struct kunit *test)
 	mutex_init(&dm->dc_lock);
 	dm->power_module = NULL;
 
-	/* dm_kunit_alloc_dm() leaves dc->ctx NULL; the idle path dereferences it. */
+	/* dm_kunit_alloc_dm() leaves dc_get_ctx(dc) NULL; the idle path dereferences it. */
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx);
-	dm->dc->ctx = ctx;
+	dc_test_set_ctx(dm->dc, ctx);
 
 	logger = kunit_kzalloc(test, sizeof(*logger), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, logger);
 	logger->dev = &adev->ddev;
-	dm->dc->ctx->logger = logger;
+	dc_get_ctx(dm->dc)->logger = logger;
 
 	dmub_srv = kunit_kzalloc(test, sizeof(*dmub_srv), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, dmub_srv);
 	dmub_srv->idle_allowed = true;
-	dm->dc->ctx->dmub_srv = dmub_srv;
-	dm->dc->caps.ips_support = true;
+	dc_get_ctx(dm->dc)->dmub_srv = dmub_srv;
+	dc_test_caps(dm->dc)->ips_support = true;
 	/* Keep dc_allow_idle_optimizations() a safe early return. */
-	dm->dc->debug.disable_idle_power_optimizations = true;
+	dc_test_debug_options(dm->dc)->disable_idle_power_optimizations = true;
 
 	dm->backlight_caps[1].caps_valid = true;
 	dm->backlight_caps[1].aux_support = true;
@@ -291,7 +292,7 @@ static void dm_test_backlight_set_level_reallows_idle(struct kunit *test)
 	dm->backlight_caps[1].min_input_signal = AMDGPU_DM_DEFAULT_MIN_BACKLIGHT;
 	dm->backlight_caps[1].max_input_signal = AMDGPU_DM_DEFAULT_MAX_BACKLIGHT;
 	dm->backlight_link[1] = link;
-	dm_kunit_add_stream_to_state(test, dm->dc->current_state, 0, link);
+	dm_kunit_add_stream_to_state(test, dc_get_current_state(dm->dc), 0, link);
 
 	amdgpu_dm_backlight_set_level(dm, 1, 2000);
 
@@ -319,24 +320,25 @@ static void dm_test_backlight_update_status_no_stream(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, dm->brightness[1], 3456U);
 }
 
-static void setup_test_link_service(struct kunit *test, struct dc_link *link)
+static struct link_service *setup_test_link_service(struct kunit *test, struct dc_link *link)
 {
 	struct link_service *link_srv;
 	struct dc_context *ctx;
 	struct dc *dc;
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
 	KUNIT_ASSERT_NOT_NULL(test, ctx);
 	KUNIT_ASSERT_NOT_NULL(test, link_srv);
 
-	dc->ctx = ctx;
-	dc->link_srv = link_srv;
+	dc_test_set_ctx(dc, ctx);
+	dc_test_install_link_service(dc, link_srv);
 	ctx->dc = dc;
 	link->dc = dc;
 	link->ctx = ctx;
+
+	return link_srv;
 }
 
 static int dm_test_get_backlight_level_mid(const struct dc_link *link)
@@ -382,9 +384,10 @@ static void dm_test_backlight_get_level_pwm_success(struct kunit *test)
 	struct amdgpu_display_manager *dm = dm_kunit_alloc_dm(test);
 	struct dc_link *link = dm_kunit_alloc_link(test);
 	u32 hw_level = dm_test_get_backlight_level_mid(link);
+	struct link_service *link_srv;
 
-	setup_test_link_service(test, link);
-	link->dc->link_srv->edp_get_backlight_level = dm_test_get_backlight_level_mid;
+	link_srv = setup_test_link_service(test, link);
+	link_srv->edp_get_backlight_level = dm_test_get_backlight_level_mid;
 	dm->backlight_link[0] = link;
 
 	KUNIT_EXPECT_EQ(test, amdgpu_dm_backlight_get_level(dm, 0),
@@ -399,9 +402,10 @@ static void dm_test_backlight_get_level_pwm_error(struct kunit *test)
 {
 	struct amdgpu_display_manager *dm = dm_kunit_alloc_dm(test);
 	struct dc_link *link = dm_kunit_alloc_link(test);
+	struct link_service *link_srv;
 
-	setup_test_link_service(test, link);
-	link->dc->link_srv->edp_get_backlight_level = dm_test_get_backlight_level_error;
+	link_srv = setup_test_link_service(test, link);
+	link_srv->edp_get_backlight_level = dm_test_get_backlight_level_error;
 	dm->brightness[0] = 4321;
 	dm->backlight_link[0] = link;
 
@@ -417,9 +421,10 @@ static void dm_test_backlight_get_level_aux_success(struct kunit *test)
 	struct amdgpu_display_manager *dm = dm_kunit_alloc_dm(test);
 	struct dc_link *link = dm_kunit_alloc_link(test);
 	struct amdgpu_dm_backlight_caps *caps = &dm->backlight_caps[0];
+	struct link_service *link_srv;
 
-	setup_test_link_service(test, link);
-	link->dc->link_srv->edp_get_backlight_level_nits = dm_test_get_backlight_level_nits;
+	link_srv = setup_test_link_service(test, link);
+	link_srv->edp_get_backlight_level_nits = dm_test_get_backlight_level_nits;
 	dm->backlight_link[0] = link;
 	caps->caps_valid = true;
 	caps->aux_support = true;
@@ -439,9 +444,10 @@ static void dm_test_backlight_get_level_aux_error(struct kunit *test)
 	struct amdgpu_display_manager *dm = dm_kunit_alloc_dm(test);
 	struct dc_link *link = dm_kunit_alloc_link(test);
 	struct amdgpu_dm_backlight_caps *caps = &dm->backlight_caps[0];
+	struct link_service *link_srv;
 
-	setup_test_link_service(test, link);
-	link->dc->link_srv->edp_get_backlight_level_nits = dm_test_get_backlight_level_nits_fail;
+	link_srv = setup_test_link_service(test, link);
+	link_srv->edp_get_backlight_level_nits = dm_test_get_backlight_level_nits_fail;
 	dm->brightness[0] = 6789;
 	dm->backlight_link[0] = link;
 	caps->caps_valid = true;
@@ -459,9 +465,10 @@ static void dm_test_backlight_get_brightness_uses_device_index(struct kunit *tes
 	struct amdgpu_display_manager *dm = dm_kunit_alloc_dm(test);
 	struct dc_link *link = dm_kunit_alloc_link(test);
 	struct backlight_device *bd;
+	struct link_service *link_srv;
 
-	setup_test_link_service(test, link);
-	link->dc->link_srv->edp_get_backlight_level = dm_test_get_backlight_level_error;
+	link_srv = setup_test_link_service(test, link);
+	link_srv->edp_get_backlight_level = dm_test_get_backlight_level_error;
 	bd = kunit_kzalloc(test, sizeof(*bd), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, bd);
 	dev_set_drvdata(&bd->dev, dm);
@@ -506,9 +513,10 @@ static void dm_test_register_backlight_device_success(struct kunit *test)
 	struct dc_link *link = dm_kunit_alloc_link(test);
 	struct drm_minor *primary;
 	unsigned int max;
+	struct link_service *link_srv;
 
-	setup_test_link_service(test, link);
-	link->dc->link_srv->edp_get_backlight_level = dm_test_get_backlight_level_error;
+	link_srv = setup_test_link_service(test, link);
+	link_srv->edp_get_backlight_level = dm_test_get_backlight_level_error;
 	primary = kunit_kzalloc(test, sizeof(*primary), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, primary);
 	adev->ddev.primary = primary;
@@ -555,10 +563,11 @@ static void dm_test_register_backlight_device_custom_curve_readback(struct kunit
 	struct backlight_device *bd;
 	struct drm_minor *primary;
 	int ret;
+	struct link_service *link_srv;
 
 	amdgpu_dm_set_dc_debug_mask(saved_mask & ~DC_DISABLE_CUSTOM_BRIGHTNESS_CURVE);
-	setup_test_link_service(test, link);
-	link->dc->link_srv->edp_get_backlight_level = dm_test_get_backlight_level_mid;
+	link_srv = setup_test_link_service(test, link);
+	link_srv->edp_get_backlight_level = dm_test_get_backlight_level_mid;
 	primary = kunit_kzalloc(test, sizeof(*primary), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, primary);
 	adev->ddev.primary = primary;
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_color_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_color_test.c
index 7ad8c56cbcf3..56a47809f302 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_color_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_color_test.c
@@ -13,6 +13,7 @@
 #include <uapi/drm/drm_mode.h>
 
 #include "dc.h"
+#include "dc_test.h"
 #include "amdgpu.h"
 #include "amdgpu_mode.h"
 #include "amdgpu_dm.h"
@@ -1759,7 +1760,7 @@ dm_test_verify_lut3d_alloc_adev(struct kunit *test, bool has_3dlut)
 
 	adev->dm.dc = kunit_kzalloc(test, sizeof(*adev->dm.dc), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, adev->dm.dc);
-	adev->dm.dc->caps.color.dpp.hw_3d_lut = has_3dlut;
+	dc_test_caps(adev->dm.dc)->color.dpp.hw_3d_lut = has_3dlut;
 
 	return adev;
 }
@@ -2201,7 +2202,7 @@ static void dm_test_update_plane_color_mgmt_bad_lut3d(struct kunit *test)
 {
 	struct dm_test_color_update_fixture f = dm_test_color_update_setup(test);
 
-	f.adev->dm.dc->caps.color.dpp.hw_3d_lut = true;
+	dc_test_caps(f.adev->dm.dc)->color.dpp.hw_3d_lut = true;
 	f.dm_plane_state->lut3d = dm_test_make_lut_blob(test, 128);
 
 	KUNIT_EXPECT_EQ(test,
@@ -2385,7 +2386,7 @@ static void dm_test_update_plane_color_mgmt_legacy_luts(struct kunit *test)
 	struct drm_plane_state *plane_state = &f.dm_plane_state->base;
 	int ret;
 
-	f.adev->dm.dc->caps.color.dpp.hw_3d_lut = true;
+	dc_test_caps(f.adev->dm.dc)->color.dpp.hw_3d_lut = true;
 	f.dm_plane_state->shaper_lut =
 		dm_test_make_lut_blob(test, MAX_COLOR_LUT_ENTRIES);
 	f.dm_plane_state->lut3d = dm_test_make_lut_blob(test, lut3d_entries);
@@ -2537,7 +2538,7 @@ static void dm_test_update_plane_color_mgmt_colorop_bypass_pipeline(struct kunit
 	};
 	struct dm_test_color_update_fixture f = dm_test_color_update_setup(test);
 
-	f.adev->dm.dc->caps.color.dpp.hw_3d_lut = true;
+	dc_test_caps(f.adev->dm.dc)->color.dpp.hw_3d_lut = true;
 	f.dm_plane_state->base.color_pipeline =
 		dm_test_colorop_pipeline_setup(test, &f, types, curves, bypass, ARRAY_SIZE(types));
 
@@ -2635,7 +2636,7 @@ static void dm_test_update_plane_color_mgmt_colorop_truncated(struct kunit *test
 	struct dm_crtc_state *crtc_state = f.crtc_state;
 	int count, ret;
 
-	f.adev->dm.dc->caps.color.dpp.hw_3d_lut = true;
+	dc_test_caps(f.adev->dm.dc)->color.dpp.hw_3d_lut = true;
 
 	for (count = 3; count <= ARRAY_SIZE(types); count++) {
 		f.dm_plane_state->base.color_pipeline =
@@ -2681,11 +2682,11 @@ static void dm_test_update_plane_color_mgmt_colorop_no_3dlut_hw(struct kunit *te
 	};
 	struct dm_test_color_update_fixture f = dm_test_color_update_setup(test);
 
-	f.adev->dm.dc->caps.color.dpp.hw_3d_lut = true;
+	dc_test_caps(f.adev->dm.dc)->color.dpp.hw_3d_lut = true;
 	f.dm_plane_state->base.color_pipeline =
 		dm_test_colorop_pipeline_setup(test, &f, types, curves, bypass,
 					       ARRAY_SIZE(types));
-	f.adev->dm.dc->caps.color.dpp.hw_3d_lut = false;
+	dc_test_caps(f.adev->dm.dc)->color.dpp.hw_3d_lut = false;
 
 	KUNIT_EXPECT_EQ(test,
 		amdgpu_dm_update_plane_color_mgmt(f.crtc_state, &f.dm_plane_state->base,
@@ -2729,7 +2730,7 @@ static void dm_test_update_plane_color_mgmt_colorop_shaper(struct kunit *test)
 	struct drm_property_blob *blob;
 	int ret;
 
-	f.adev->dm.dc->caps.color.dpp.hw_3d_lut = true;
+	dc_test_caps(f.adev->dm.dc)->color.dpp.hw_3d_lut = true;
 	f.dm_plane_state->base.color_pipeline =
 		dm_test_colorop_pipeline_setup(test, &f, types, curves, bypass,
 					       ARRAY_SIZE(types));
@@ -2784,7 +2785,7 @@ static void dm_test_update_plane_color_mgmt_colorop_3dlut(struct kunit *test)
 	struct drm_property_blob *blob;
 	int ret;
 
-	f.adev->dm.dc->caps.color.dpp.hw_3d_lut = true;
+	dc_test_caps(f.adev->dm.dc)->color.dpp.hw_3d_lut = true;
 	f.dm_plane_state->base.color_pipeline =
 		dm_test_colorop_pipeline_setup(test, &f, types, curves, bypass,
 					       ARRAY_SIZE(types));
@@ -2839,7 +2840,7 @@ static void dm_test_update_plane_color_mgmt_colorop_3dlut_no_data(struct kunit *
 	struct drm_plane_state *plane_state = &f.dm_plane_state->base;
 	int ret;
 
-	f.adev->dm.dc->caps.color.dpp.hw_3d_lut = true;
+	dc_test_caps(f.adev->dm.dc)->color.dpp.hw_3d_lut = true;
 	f.dm_plane_state->base.color_pipeline =
 		dm_test_colorop_pipeline_setup(test, &f, types, curves, bypass,
 					       ARRAY_SIZE(types));
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_colorop_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_colorop_test.c
index 27cd4b8500e8..de49c54e988e 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_colorop_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_colorop_test.c
@@ -10,6 +10,7 @@
 #include <drm/drm_kunit_helpers.h>
 
 #include "dc.h"
+#include "dc_test.h"
 #include "amdgpu.h"
 #include "amdgpu_dm_colorop.h"
 #include "amdgpu_dm_kunit_test_helpers.h"
@@ -231,11 +232,10 @@ static void dm_test_initialize_default_pipeline_caps(struct kunit *test,
 	adev = dm_kunit_alloc_adev(test);
 	drm = &adev->ddev;
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	adev->dm.dc = dc;
-	adev->dm.dc->caps.color.dpp.hw_3d_lut = dpp_hw_3d_lut;
-	adev->dm.dc->caps.color.mpc.preblend = mpc_preblend;
+	dc_test_caps(adev->dm.dc)->color.dpp.hw_3d_lut = dpp_hw_3d_lut;
+	dc_test_caps(adev->dm.dc)->color.mpc.preblend = mpc_preblend;
 
 	plane = drm_kunit_helper_create_primary_plane(test, drm,
 						       NULL, NULL, NULL, 0, NULL);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
index c0bbb95c4af4..204dc86266a3 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
@@ -22,6 +22,7 @@
 #include <linux/i2c.h>
 
 #include "dc.h"
+#include "dc_test.h"
 #include "amdgpu.h"
 #include "amdgpu_mode.h"
 #include "amdgpu_display.h"
@@ -3052,9 +3053,9 @@ static struct dm_test_fbc_ctx *dm_test_fbc_ctx_alloc(struct kunit *test)
 
 	/* Default to the fully-enabled path so each test only flips one knob */
 	ctx->link->connector_signal = SIGNAL_TYPE_EDP;
-	ctx->dc->fbc_compressor =
-		(struct compressor *)kunit_kzalloc(test, sizeof(void *), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, ctx->dc->fbc_compressor);
+	dc_test_set_fbc_compressor(ctx->dc,
+		(struct compressor *)kunit_kzalloc(test, sizeof(void *), GFP_KERNEL));
+	KUNIT_ASSERT_TRUE(test, dc_is_fbc_compressor_available(ctx->dc));
 
 	return ctx;
 }
@@ -3067,7 +3068,7 @@ static void dm_test_fbc_init_no_compressor(struct kunit *test)
 {
 	struct dm_test_fbc_ctx *ctx = dm_test_fbc_ctx_alloc(test);
 
-	ctx->dc->fbc_compressor = NULL;
+	dc_test_set_fbc_compressor(ctx->dc, NULL);
 
 	amdgpu_dm_fbc_init(&ctx->aconnector->base);
 
@@ -5076,7 +5077,7 @@ static struct dm_test_poll_ctx *dm_test_poll_ctx_alloc(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, ctx->dc);
 	ctx->link_srv = kunit_kzalloc(test, sizeof(*ctx->link_srv), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->link_srv);
-	ctx->dc->link_srv = ctx->link_srv;
+	dc_test_install_link_service(ctx->dc, ctx->link_srv);
 
 	ctx->dc_ctx = kunit_kzalloc(test, sizeof(*ctx->dc_ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->dc_ctx);
@@ -5676,7 +5677,7 @@ static void dm_test_atomic_check_mst_scaffold(struct kunit *test,
 
 	/* Fake DC link so dm_mst_get_pbn_divider() yields a non-zero divider. */
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	link = kunit_kzalloc(test, sizeof(*link), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, link_srv);
 	KUNIT_ASSERT_NOT_NULL(test, dc);
@@ -5685,7 +5686,7 @@ static void dm_test_atomic_check_mst_scaffold(struct kunit *test,
 		dm_test_atomic_check_dp_get_verified_link_cap;
 	link_srv->dp_link_bandwidth_kbps =
 		dm_test_atomic_check_dp_link_bandwidth_kbps;
-	dc->link_srv = link_srv;
+	dc_test_install_link_service(dc, link_srv);
 	link->dc = dc;
 	s->mst_root->dc_link = link;
 
@@ -6016,7 +6017,7 @@ static enum dc_status dm_test_vs_validate_mode_timing_ok(
 static void dm_test_validate_stream_dc_ok_no_pipe(struct kunit *test)
 {
 	struct drm_device *drm = dm_test_alloc_drm(test);
-	struct dc *dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	struct dc *dc = dm_kunit_alloc_dc(test);
 	struct dc_context *ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	struct dal_logger *logger = kunit_kzalloc(test, sizeof(*logger), GFP_KERNEL);
 	struct resource_pool *pool = kunit_kzalloc(test, sizeof(*pool), GFP_KERNEL);
@@ -6057,9 +6058,9 @@ static void dm_test_validate_stream_dc_ok_no_pipe(struct kunit *test)
 
 	link_srv->validate_mode_timing = dm_test_vs_validate_mode_timing_ok;
 
-	dc->ctx = ctx;
-	dc->res_pool = pool;
-	dc->link_srv = link_srv;
+	dc_test_set_ctx(dc, ctx);
+	dc_test_set_res_pool(dc, pool);
+	dc_test_install_link_service(dc, link_srv);
 
 	link->ep_type = DISPLAY_ENDPOINT_UNKNOWN;
 	stream->link = link;
@@ -6472,7 +6473,7 @@ static struct dm_test_i2c_ctx *dm_test_i2c_setup(struct kunit *test)
 	ctx->dc_ctx->dc = ctx->dc;
 	ctx->link->link_index = 0;
 	ctx->link->ddc = link_ddc;
-	ctx->dc->links[0] = ctx->link;
+	dc_test_set_link(ctx->dc, 0, ctx->link);
 	ctx->i2c->ddc_service = ctx->ddc;
 	i2c_set_adapdata(&ctx->i2c->base, ctx->i2c);
 
@@ -6517,7 +6518,7 @@ static void dm_test_i2c_xfer_oem_no_device(struct kunit *test)
 
 	pool = kunit_kzalloc(test, sizeof(*pool), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, pool);
-	ctx->dc->res_pool = pool;
+	dc_test_set_res_pool(ctx->dc, pool);
 	ctx->i2c->oem = true;
 
 	KUNIT_EXPECT_EQ(test, amdgpu_dm_i2c_xfer(&ctx->i2c->base, msgs, 1), -EIO);
@@ -7383,9 +7384,9 @@ static struct dm_test_cvs_dc *dm_test_cvs_dc_alloc(struct kunit *test)
 
 	c->dc = kunit_kzalloc(test, sizeof(*c->dc), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, c->dc);
-	c->dc->ctx = dcc;
-	c->dc->res_pool = pool;
-	c->dc->link_srv = c->link_srv;
+	dc_test_set_ctx(c->dc, dcc);
+	dc_test_set_res_pool(c->dc, pool);
+	dc_test_install_link_service(c->dc, c->link_srv);
 	c->adev->dm.dc = c->dc;
 
 	c->dm_state = kunit_kzalloc(test, sizeof(*c->dm_state), GFP_KERNEL);
@@ -8310,12 +8311,11 @@ static void dm_test_ces_setup(struct kunit *test, struct dm_test_edid_ctx *ctx,
 	i2c->base.lock_ops = &dm_test_force_edid_lock_ops;
 	ctx->aconnector->i2c = i2c;
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, link_srv);
 	link_srv->add_remote_sink = dm_test_ces_add_remote_sink;
-	dc->link_srv = link_srv;
+	dc_test_install_link_service(dc, link_srv);
 
 	ctx->link->dc = dc;
 	ctx->link->aux_mode = false;
@@ -8484,7 +8484,7 @@ dm_test_gm_ctx_alloc(struct kunit *test, int connector_type)
 	KUNIT_ASSERT_NOT_NULL(test, ctx->link);
 
 	ctx->link_srv->dp_get_encoding_format = dm_test_gm_enc_8b10b;
-	ctx->dc->link_srv = ctx->link_srv;
+	dc_test_install_link_service(ctx->dc, ctx->link_srv);
 	ctx->adev->dm.dc = ctx->dc;
 	ctx->link->dc = ctx->dc;
 	ctx->aconnector->dc_link = ctx->link;
@@ -9079,7 +9079,7 @@ static struct dm_test_frl_ctx *dm_test_frl_ctx_alloc(struct kunit *test)
 
 	ctx->link_srv->hdmi_frl_poll_status_flag = dm_test_frl_poll_true;
 	ctx->link_srv->detect_link = dm_test_frl_detect;
-	ctx->dc->link_srv = ctx->link_srv;
+	dc_test_install_link_service(ctx->dc, ctx->link_srv);
 	ctx->dm->dc = ctx->dc;
 	mutex_init(&ctx->dm->dc_lock);
 	INIT_DELAYED_WORK(&ctx->dm->hdmi_frl_status_polling_work, hdmi_frl_status_polling_work);
@@ -9099,7 +9099,7 @@ static struct dc_link *dm_test_frl_add_link(struct kunit *test, struct dm_test_f
 
 	KUNIT_ASSERT_NOT_NULL(test, link);
 	link->dc = ctx->dc;
-	ctx->dc->links[0] = link;
+	dc_test_set_link(ctx->dc, 0, link);
 
 	return link;
 }
@@ -9760,10 +9760,9 @@ dm_test_fs_caps_ctx_alloc(struct kunit *test, enum signal_type sink_signal)
 	ctx->pool = kunit_kzalloc(test, sizeof(*ctx->pool), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->pool);
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
-	dc->ctx = dc_ctx;
-	dc->res_pool = ctx->pool;
+	dc = dm_kunit_alloc_dc(test);
+	dc_test_set_ctx(dc, dc_ctx);
+	dc_test_set_res_pool(dc, ctx->pool);
 	ctx->adev->dm.dc = dc;
 
 	ctx->adev->dm.freesync_module =
@@ -10036,10 +10035,9 @@ dm_test_conn_init_ctx_alloc(struct kunit *test, enum signal_type signal)
 	KUNIT_ASSERT_NOT_NULL(test, link_srv);
 	link_srv->dp_get_encoding_format = dm_test_gm_enc_8b10b;
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
-	dc->ctx = dc_ctx;
-	dc->link_srv = link_srv;
+	dc = dm_kunit_alloc_dc(test);
+	dc_test_set_ctx(dc, dc_ctx);
+	dc_test_install_link_service(dc, link_srv);
 
 	ctx->link = kunit_kzalloc(test, sizeof(*ctx->link), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->link);
@@ -10054,8 +10052,8 @@ dm_test_conn_init_ctx_alloc(struct kunit *test, enum signal_type signal)
 	ddc->link = ctx->link;
 	ctx->link->ddc = ddc;
 
-	dc->links[0] = ctx->link;
-	dc->link_count = 1;
+	dc_test_set_link(dc, 0, ctx->link);
+	dc_test_set_link_count(dc, 1);
 	ctx->dm->dc = dc;
 
 	/* amdgpu_dm_connector_destroy() and amdgpu_dm_encoder_destroy() kfree() these. */
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_crc_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_crc_test.c
index 7f6340702502..8d3123904548 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_crc_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_crc_test.c
@@ -16,6 +16,7 @@
 #include <drm/drm_vblank.h>
 
 #include "dc.h"
+#include "dc_test.h"
 #include "core_types.h"
 #include "logger_types.h"
 #include "opp.h"
@@ -137,8 +138,8 @@ static struct dm_test_crc_dc_fixture *dm_test_alloc_crc_dc_fixture(struct kunit
 
 	mutex_init(&adev->dm.dc_lock);
 	adev->dm.dc = fixture->dc;
-	fixture->dc->ctx = fixture->dc_ctx;
-	fixture->dc->current_state = fixture->dc_state;
+	dc_test_set_ctx(fixture->dc, fixture->dc_ctx);
+	dc_test_set_current_state(fixture->dc, fixture->dc_state);
 	fixture->dc_ctx->dc = fixture->dc;
 	fixture->dc_ctx->logger = fixture->logger;
 	fixture->link->dc = fixture->dc;
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_crtc_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_crtc_test.c
index c130d809098c..96cf015a12d9 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_crtc_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_crtc_test.c
@@ -13,6 +13,7 @@
 #include <linux/debugfs.h>
 
 #include "dc.h"
+#include "dc_test.h"
 #include "inc/core_types.h"
 #include "irq/irq_service.h"
 #include "inc/hw/timing_generator.h"
@@ -532,7 +533,7 @@ static void dm_test_crtc_set_vupdate_irq_enable(struct kunit *test)
 
 	irqs->info = info;
 	res_pool->irqs = irqs;
-	dc->res_pool = res_pool;
+	dc_test_set_res_pool(dc, res_pool);
 	adev->dm.dc = dc;
 
 	acrtc->base.dev = &adev->ddev;
@@ -619,7 +620,7 @@ static void dm_test_idle_worker_enabled_breaks_when_idle_disallowed(struct kunit
 	adev->dm.dc = dm_kunit_alloc_dc_with_ctx(test);
 	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, adev->dm.dc);
 	/* First loop iteration breaks before any dc_allow_idle_optimizations(). */
-	adev->dm.dc->idle_optimizations_allowed = false;
+	dc_test_set_idle_optimizations_allowed(adev->dm.dc, false);
 
 	idle_work = kunit_kzalloc(test, sizeof(*idle_work), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, idle_work);
@@ -658,12 +659,12 @@ static void dm_test_idle_worker_enabled_breaks_when_not_headless(struct kunit *t
 	adev->dm.dc = dm_kunit_alloc_dc_with_ctx(test);
 	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, adev->dm.dc);
 	/* Allow idle so the first branch is skipped and dc_allow() is exercised. */
-	adev->dm.dc->idle_optimizations_allowed = true;
+	dc_test_set_idle_optimizations_allowed(adev->dm.dc, true);
 	/* is_apu path avoids DC_LOG_DC()'s NULL-logger dereference. */
-	adev->dm.dc->caps.is_apu = true;
+	dc_test_caps(adev->dm.dc)->is_apu = true;
 	/* Empty stream list -> amdgpu_dm_psr_is_active_allowed() returns false. */
-	adev->dm.dc->current_state = dm_kunit_alloc_dc_state(test);
-	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, adev->dm.dc->current_state);
+	dc_test_set_current_state(adev->dm.dc, dm_kunit_alloc_dc_state(test));
+	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, dc_get_current_state(adev->dm.dc));
 
 	/* A connected display makes amdgpu_dm_is_headless() false. */
 	display = kunit_kzalloc(test, sizeof(*display), GFP_KERNEL);
@@ -684,7 +685,7 @@ static void dm_test_idle_worker_enabled_breaks_when_not_headless(struct kunit *t
 
 /*
  * Report success only when disabling idle. dc_allow_idle_optimizations() then
- * clears dc->idle_optimizations_allowed on the disable call but leaves it clear
+ * clears dc_is_idle_optimizations_allowed(dc) on the disable call but leaves it clear
  * on the re-enable call inside the worker's enable-body, so the next loop
  * iteration breaks at the first branch instead of looping forever.
  */
@@ -721,18 +722,18 @@ static void dm_test_idle_worker_enabled_runs_body(struct kunit *test)
 	adev->dm.dc = dm_kunit_alloc_dc_with_ctx(test);
 	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, adev->dm.dc);
 	/* Allow idle so the first branch is skipped and dc_allow() is exercised. */
-	adev->dm.dc->idle_optimizations_allowed = true;
+	dc_test_set_idle_optimizations_allowed(adev->dm.dc, true);
 	/* is_apu path avoids DC_LOG_DC()'s NULL-logger dereference. */
-	adev->dm.dc->caps.is_apu = true;
+	dc_test_caps(adev->dm.dc)->is_apu = true;
 	/* dc_allow() logs via DC_LOG_DEBUG() when it flips the flag. */
 	logger = kunit_kzalloc(test, sizeof(*logger), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, logger);
 	logger->dev = &adev->ddev;
-	adev->dm.dc->ctx->logger = logger;
+	dc_get_ctx(adev->dm.dc)->logger = logger;
 	/* dc_allow() only flips the flag when clk_mgr and apply() are present. */
-	adev->dm.dc->clk_mgr = dm_kunit_alloc_clk_mgr(test);
-	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, adev->dm.dc->clk_mgr);
-	adev->dm.dc->hwss.apply_idle_power_optimizations = dm_test_idle_apply_flip;
+	dc_test_set_clk_mgr(adev->dm.dc, dm_kunit_alloc_clk_mgr(test));
+	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, dc_get_clk_mgr(adev->dm.dc));
+	dc_test_hwss(adev->dm.dc)->apply_idle_power_optimizations = dm_test_idle_apply_flip;
 
 	idle_work = kunit_kzalloc(test, sizeof(*idle_work), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, idle_work);
@@ -743,7 +744,7 @@ static void dm_test_idle_worker_enabled_runs_body(struct kunit *test)
 	amdgpu_dm_idle_worker(&idle_work->work);
 
 	/* Enable-body ran, then the next iteration disabled idle and stopped. */
-	KUNIT_EXPECT_FALSE(test, adev->dm.dc->idle_optimizations_allowed);
+	KUNIT_EXPECT_FALSE(test, dc_is_idle_optimizations_allowed(adev->dm.dc));
 	KUNIT_EXPECT_FALSE(test, idle_work->running);
 }
 
@@ -963,7 +964,7 @@ dm_test_crtc_setup_enable(struct kunit *test, struct amdgpu_device **adev_out,
 
 	adev->dm.dc = dm_kunit_alloc_dc_with_ctx(test);
 	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, adev->dm.dc);
-	adev->dm.dc->ctx->dce_version = dce_version;
+	dc_get_ctx(adev->dm.dc)->dce_version = dce_version;
 
 	/* crtc_id 0 maps to a valid IRQ type only when a CRTC is registered. */
 	adev->mode_info.num_crtc = 1;
@@ -1066,7 +1067,7 @@ static void dm_test_crtc_enable_vblank_vupdate_busy(struct kunit *test)
 
 	irqs->info = info;
 	res_pool->irqs = irqs;
-	adev->dm.dc->res_pool = res_pool;
+	dc_test_set_res_pool(adev->dm.dc, res_pool);
 
 	KUNIT_EXPECT_EQ(test,
 			amdgpu_dm_crtc_enable_vblank(&acrtc->base), -EBUSY);
@@ -1193,8 +1194,8 @@ static void dm_test_crtc_enable_vblank_ips_restore(struct kunit *test)
 	acrtc->base.funcs = &dm_test_crtc_funcs;
 
 	/* IPS enabled and not fully disabled -> first restore condition holds. */
-	adev->dm.dc->caps.ips_support = true;
-	adev->dm.dc->config.disable_ips = DMUB_IPS_ENABLE;
+	dc_test_caps(adev->dm.dc)->ips_support = true;
+	dc_test_config(adev->dm.dc)->disable_ips = DMUB_IPS_ENABLE;
 
 	/* Supported PSR version makes self-refresh supported. */
 	link = acrtc_state->stream->link;
@@ -1240,8 +1241,8 @@ static void dm_test_crtc_enable_vblank_ips_restore_replay(struct kunit *test)
 	acrtc->base.funcs = &dm_test_crtc_funcs;
 
 	/* IPS enabled and not fully disabled -> first restore condition holds. */
-	adev->dm.dc->caps.ips_support = true;
-	adev->dm.dc->config.disable_ips = DMUB_IPS_ENABLE;
+	dc_test_caps(adev->dm.dc)->ips_support = true;
+	dc_test_config(adev->dm.dc)->disable_ips = DMUB_IPS_ENABLE;
 
 	/*
 	 * PSR unsupported but replay supported -> sr_supported is driven by the
@@ -2002,7 +2003,7 @@ static void dm_test_crtc_disable_vblank_no_irq_installed(struct kunit *test)
 	adev->dm.dc = dm_kunit_alloc_dc_with_ctx(test);
 	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, adev->dm.dc);
 	/* DCE_VERSION_6_0 has no VRR, so the vupdate-irq branch is skipped. */
-	adev->dm.dc->ctx->dce_version = DCE_VERSION_6_0;
+	dc_get_ctx(adev->dm.dc)->dce_version = DCE_VERSION_6_0;
 	adev->dm.active_vblank_irq_count = 0;
 
 	/* No CRTCs registered and IRQs not installed -> irq_put returns early. */
@@ -2039,7 +2040,7 @@ static void dm_test_crtc_disable_vblank_vrr(struct kunit *test)
 	adev->dm.dc = dm_kunit_alloc_dc_with_ctx(test);
 	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, adev->dm.dc);
 	/* DCE_VERSION_8_0 supports VRR -> the vupdate-irq branch is walked. */
-	adev->dm.dc->ctx->dce_version = DCE_VERSION_8_0;
+	dc_get_ctx(adev->dm.dc)->dce_version = DCE_VERSION_8_0;
 
 	adev->mode_info.num_crtc = 1;
 	adev->irq.installed = true;
@@ -2089,7 +2090,7 @@ static void dm_test_crtc_disable_vblank_queues_work(struct kunit *test)
 	adev->dm.dc = dm_kunit_alloc_dc_with_ctx(test);
 	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, adev->dm.dc);
 	/* DCE_VERSION_6_0 has no VRR, so the vupdate-irq branch is skipped. */
-	adev->dm.dc->ctx->dce_version = DCE_VERSION_6_0;
+	dc_get_ctx(adev->dm.dc)->dce_version = DCE_VERSION_6_0;
 	adev->dm.active_vblank_irq_count = 2;
 
 	adev->mode_info.num_crtc = 1;
@@ -2187,7 +2188,7 @@ static void dm_test_crtc_init_registers_crtc(struct kunit *test)
 
 	dc = dm_kunit_alloc_dc_with_ctx(test);
 	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, dc);
-	dc->caps.max_cursor_size = 256;
+	dc_test_caps(dc)->max_cursor_size = 256;
 
 	adev->dm.adev = adev;
 	adev->dm.ddev = &adev->ddev;
@@ -2249,8 +2250,8 @@ static void dm_test_crtc_init_enables_degamma(struct kunit *test)
 	dc = dm_kunit_alloc_dc_with_ctx(test);
 	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, dc);
 	/* DCN DPP with a non-4.01 ASIC selects the degamma-enabled path. */
-	dc->caps.color.dpp.dcn_arch = 1;
-	dc->ctx->dce_version = DCN_VERSION_3_0;
+	dc_test_caps(dc)->color.dpp.dcn_arch = 1;
+	dc_get_ctx(dc)->dce_version = DCN_VERSION_3_0;
 
 	adev->dm.adev = adev;
 	adev->dm.ddev = &adev->ddev;
@@ -2520,12 +2521,12 @@ static void dm_test_crtc_atomic_check_valid_stream_passes(struct kunit *test)
 	tg_funcs->validate_timing = dm_test_atomic_check_validate_timing_ok;
 	tg->funcs = tg_funcs;
 	res_pool->timing_generators[0] = tg;
-	dc->res_pool = res_pool;
+	dc_test_set_res_pool(dc, res_pool);
 
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, link_srv);
 	link_srv->validate_mode_timing = dm_test_atomic_check_validate_mode_timing_ok;
-	dc->link_srv = link_srv;
+	dc_test_install_link_service(dc, link_srv);
 	adev->dm.dc = dc;
 
 	link = dm_kunit_alloc_link(test);
@@ -2588,7 +2589,7 @@ static void dm_test_crtc_atomic_check_invalid_stream_fails(struct kunit *test)
 	tg_funcs->validate_timing = dm_test_atomic_check_validate_timing_fail;
 	tg->funcs = tg_funcs;
 	res_pool->timing_generators[0] = tg;
-	dc->res_pool = res_pool;
+	dc_test_set_res_pool(dc, res_pool);
 	adev->dm.dc = dc;
 
 	link = dm_kunit_alloc_link(test);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_dmub_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_dmub_test.c
index 2e273dea17ef..449fb6d94f75 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_dmub_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_dmub_test.c
@@ -9,6 +9,8 @@
 #include <linux/firmware.h>
 
 #include "dc.h"
+#include "dc_test.h"
+#include "amdgpu_dm_kunit_test_helpers.h"
 #include "dc/inc/core_types.h"
 #include "dc/inc/hw/dmcu.h"
 #include "dc/inc/hw/abm.h"
@@ -524,8 +526,7 @@ static struct amdgpu_device *dm_test_alloc_adev_with_dc(struct kunit *test)
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, adev);
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 
 	res_pool = kunit_kzalloc(test, sizeof(*res_pool), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, res_pool);
@@ -533,8 +534,8 @@ static struct amdgpu_device *dm_test_alloc_adev_with_dc(struct kunit *test)
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx);
 
-	dc->res_pool = res_pool;
-	dc->ctx = ctx;
+	dc_test_set_res_pool(dc, res_pool);
+	dc_test_set_ctx(dc, ctx);
 	ctx->dc = dc;
 	ctx->driver_context = adev;
 	adev->dm.dc = dc;
@@ -647,7 +648,7 @@ static void dm_test_dmub_hw_init_success_fake_dmub(struct kunit *test)
 
 	KUNIT_EXPECT_EQ(test, dm_dmub_hw_init(adev), 0);
 	KUNIT_EXPECT_TRUE(test, adev->dm.dmub_srv->hw_init);
-	KUNIT_EXPECT_NOT_NULL(test, adev->dm.dc->ctx->dmub_srv);
+	KUNIT_EXPECT_NOT_NULL(test, dc_get_ctx(adev->dm.dc)->dmub_srv);
 }
 
 /**
@@ -664,7 +665,7 @@ static void dm_test_dmub_hw_init_no_hw_support(struct kunit *test)
 	adev->dm.dmub_srv->hw_funcs.is_supported = dm_test_dmub_unsupported;
 
 	KUNIT_EXPECT_EQ(test, dm_dmub_hw_init(adev), 0);
-	KUNIT_EXPECT_NULL(test, adev->dm.dc->ctx->dmub_srv);
+	KUNIT_EXPECT_NULL(test, dc_get_ctx(adev->dm.dc)->dmub_srv);
 }
 
 /**
@@ -717,7 +718,7 @@ static void dm_test_dmub_hw_init_auto_load_timeout(struct kunit *test)
 	adev->dm.dmub_srv->hw_funcs.get_fw_status = dm_test_dmub_fw_not_ready;
 
 	KUNIT_EXPECT_EQ(test, dm_dmub_hw_init(adev), 0);
-	KUNIT_EXPECT_NOT_NULL(test, adev->dm.dc->ctx->dmub_srv);
+	KUNIT_EXPECT_NOT_NULL(test, dc_get_ctx(adev->dm.dc)->dmub_srv);
 }
 
 /**
@@ -733,8 +734,8 @@ static void dm_test_dmub_hw_init_apu_dpia_dcn35(struct kunit *test)
 	struct amdgpu_device *adev = dm_test_alloc_adev_with_dmub(test);
 
 	adev->ip_versions[DCE_HWIP][0] = IP_VERSION(3, 5, 0);
-	adev->dm.dc->caps.is_apu = true;
-	adev->dm.dc->res_pool->usb4_dpia_count = 1;
+	dc_test_caps(adev->dm.dc)->is_apu = true;
+	dc_get_res_pool(adev->dm.dc)->usb4_dpia_count = 1;
 
 	KUNIT_EXPECT_EQ(test, dm_dmub_hw_init(adev), 0);
 	KUNIT_EXPECT_TRUE(test, adev->dm.dmub_srv->hw_init);
@@ -755,7 +756,7 @@ static void dm_test_dmub_hw_init_sanity_checks_dcn31(struct kunit *test)
 	adev->dm.dmcub_fw_version = DMUB_FW_VERSION(4, 0, 10);
 
 	KUNIT_EXPECT_EQ(test, dm_dmub_hw_init(adev), 0);
-	KUNIT_EXPECT_TRUE(test, adev->dm.dc->debug.sanity_checks);
+	KUNIT_EXPECT_TRUE(test, dc_test_debug_options(adev->dm.dc)->sanity_checks);
 }
 
 /**
@@ -773,7 +774,7 @@ static void dm_test_dmub_hw_init_sanity_checks_dcn314(struct kunit *test)
 	adev->dm.dmcub_fw_version = DMUB_FW_VERSION(4, 0, 10);
 
 	KUNIT_EXPECT_EQ(test, dm_dmub_hw_init(adev), 0);
-	KUNIT_EXPECT_TRUE(test, adev->dm.dc->debug.sanity_checks);
+	KUNIT_EXPECT_TRUE(test, dc_test_debug_options(adev->dm.dc)->sanity_checks);
 }
 
 /**
@@ -798,8 +799,8 @@ static void dm_test_dmub_hw_init_dmcu_abm(struct kunit *test)
 
 	dmcu->funcs = &dm_test_dmcu_funcs;
 	dmcu->psp_version = 0x12345678;
-	adev->dm.dc->res_pool->dmcu = dmcu;
-	adev->dm.dc->res_pool->abm = abm;
+	dc_get_res_pool(adev->dm.dc)->dmcu = dmcu;
+	dc_get_res_pool(adev->dm.dc)->abm = abm;
 
 	KUNIT_EXPECT_EQ(test, dm_dmub_hw_init(adev), 0);
 	KUNIT_EXPECT_TRUE(test, abm->dmcu_is_running);
@@ -857,7 +858,7 @@ static void dm_test_dmub_hw_resume_full_init(struct kunit *test)
 
 	dm_dmub_hw_resume(adev);
 
-	KUNIT_EXPECT_NOT_NULL(test, adev->dm.dc->ctx->dmub_srv);
+	KUNIT_EXPECT_NOT_NULL(test, dc_get_ctx(adev->dm.dc)->dmub_srv);
 }
 
 /**
@@ -999,7 +1000,7 @@ static void dm_test_execute_dmub_cmd_null_dmub_srv(struct kunit *test)
  * dm_test_process_dmub_aux_transfer_sync_engine_acquire - Test AUX transfer engine-acquire failure
  * @test: The KUnit test context
  *
- * With dc->link_count == 0, dc_process_dmub_aux_transfer_async() rejects the
+ * With dc_get_link_count(dc) == 0, dc_process_dmub_aux_transfer_async() rejects the
  * link index and amdgpu_dm_process_dmub_aux_transfer_sync() reports an
  * engine-acquire error and returns -1.
  */
@@ -1019,8 +1020,7 @@ static void dm_test_process_dmub_aux_transfer_sync_engine_acquire(struct kunit *
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx);
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 
 	payload = kunit_kzalloc(test, sizeof(*payload), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, payload);
@@ -1028,7 +1028,7 @@ static void dm_test_process_dmub_aux_transfer_sync_engine_acquire(struct kunit *
 	notify = kunit_kzalloc(test, sizeof(*notify), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, notify);
 
-	dc->link_count = 0;
+	dc_test_set_link_count(dc, 0);
 	ctx->dc = dc;
 	ctx->driver_context = adev;
 	adev->dm.dmub_notify = notify;
@@ -1071,8 +1071,7 @@ static void dm_test_process_dmub_aux_transfer_sync_protocol_error(struct kunit *
 	dc_ctx = kunit_kzalloc(test, sizeof(*dc_ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, dc_ctx);
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 
 	link = kunit_kzalloc(test, sizeof(*link), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, link);
@@ -1087,9 +1086,9 @@ static void dm_test_process_dmub_aux_transfer_sync_protocol_error(struct kunit *
 	KUNIT_ASSERT_NOT_NULL(test, notify);
 
 	link->ddc = ddc;
-	dc->ctx = dc_ctx;
-	dc->link_count = 1;
-	dc->links[0] = link;
+	dc_test_set_ctx(dc, dc_ctx);
+	dc_test_set_link_count(dc, 1);
+	dc_test_set_link(dc, 0, link);
 	dc_ctx->dc = dc;
 	dc_ctx->driver_context = adev;
 	dc_ctx->dmub_srv = NULL;
@@ -1139,8 +1138,7 @@ static void dm_test_process_dmub_aux_transfer_sync_copies_data(struct kunit *tes
 	dc_ctx = kunit_kzalloc(test, sizeof(*dc_ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, dc_ctx);
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 
 	link = kunit_kzalloc(test, sizeof(*link), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, link);
@@ -1155,9 +1153,9 @@ static void dm_test_process_dmub_aux_transfer_sync_copies_data(struct kunit *tes
 	KUNIT_ASSERT_NOT_NULL(test, notify);
 
 	link->ddc = ddc;
-	dc->ctx = dc_ctx;
-	dc->link_count = 1;
-	dc->links[0] = link;
+	dc_test_set_ctx(dc, dc_ctx);
+	dc_test_set_link_count(dc, 1);
+	dc_test_set_link(dc, 0, link);
 	dc_ctx->dc = dc;
 	dc_ctx->driver_context = adev;
 	dc_ctx->dmub_srv = NULL;
@@ -1220,8 +1218,7 @@ static void dm_test_process_dmub_aux_transfer_sync_zero_length(struct kunit *tes
 	dc_ctx = kunit_kzalloc(test, sizeof(*dc_ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, dc_ctx);
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 
 	link = kunit_kzalloc(test, sizeof(*link), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, link);
@@ -1236,9 +1233,9 @@ static void dm_test_process_dmub_aux_transfer_sync_zero_length(struct kunit *tes
 	KUNIT_ASSERT_NOT_NULL(test, notify);
 
 	link->ddc = ddc;
-	dc->ctx = dc_ctx;
-	dc->link_count = 1;
-	dc->links[0] = link;
+	dc_test_set_ctx(dc, dc_ctx);
+	dc_test_set_link_count(dc, 1);
+	dc_test_set_link(dc, 0, link);
 	dc_ctx->dc = dc;
 	dc_ctx->driver_context = adev;
 	dc_ctx->dmub_srv = NULL;
@@ -1294,8 +1291,7 @@ static void dm_test_process_dmub_set_config_sync_unknown_error(struct kunit *tes
 	dc_ctx = kunit_kzalloc(test, sizeof(*dc_ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, dc_ctx);
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 
 	link = kunit_kzalloc(test, sizeof(*link), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, link);
@@ -1306,9 +1302,9 @@ static void dm_test_process_dmub_set_config_sync_unknown_error(struct kunit *tes
 	notify = kunit_kzalloc(test, sizeof(*notify), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, notify);
 
-	dc->ctx = dc_ctx;
+	dc_test_set_ctx(dc, dc_ctx);
 	dc_ctx->dmub_srv = NULL;
-	dc->links[0] = link;
+	dc_test_set_link(dc, 0, link);
 	ctx->dc = dc;
 	ctx->driver_context = adev;
 	adev->dm.dmub_notify = notify;
@@ -1534,8 +1530,8 @@ static void dm_test_dmub_reg_write_then_read(struct kunit *test)
 	perf_trace = kunit_kzalloc(test, sizeof(*perf_trace), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, perf_trace);
 
-	adev->dm.dc->ctx->cgs_device = &dm_test_cgs.dev;
-	adev->dm.dc->ctx->perf_trace = perf_trace;
+	dc_get_ctx(adev->dm.dc)->cgs_device = &dm_test_cgs.dev;
+	dc_get_ctx(adev->dm.dc)->perf_trace = perf_trace;
 
 	amdgpu_dm_dmub_reg_write(adev, 0x1234, 0x0BADF00D);
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_freesync_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_freesync_test.c
index 710cdc7f40bf..a3b9ee396e5c 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_freesync_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_freesync_test.c
@@ -13,6 +13,7 @@
 #include <drm/drm_vblank.h>
 
 #include "dc.h"
+#include "dc_test.h"
 #include "inc/core_types.h"
 #include "amd_shared.h"
 #include "amdgpu.h"
@@ -594,7 +595,7 @@ static void dm_test_update_freesync_state_pre_ai_active(struct kunit *test)
 	stream->timing.v_total = 1125;
 	adev->dm.adev = adev;
 	adev->dm.dc = dm_kunit_alloc_dc_with_ctx(test);
-	adev->dm.dc->current_state = dm_kunit_alloc_dc_state(test);
+	dc_test_set_current_state(adev->dm.dc, dm_kunit_alloc_dc_state(test));
 
 	amdgpu_dm_update_freesync_state_on_stream(&adev->dm, &crtc_state, stream, surface, 0);
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_hdcp_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_hdcp_test.c
index 5af6ae47bb21..b53aba4153f8 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_hdcp_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_hdcp_test.c
@@ -11,6 +11,7 @@
 #include <linux/slab.h>
 #include <linux/sysfs.h>
 #include <linux/i2c.h>
+#include "dc_test.h"
 
 #include <drm/display/drm_dp_helper.h>
 
@@ -1161,7 +1162,7 @@ static void dm_test_hdcp_update_display_disable_resets_status_and_cancels_valida
  * dm_test_hdcp_create_workqueue_zero_max_links_returns_null - zero-link creation fails early
  * @test: KUnit test context
  *
- * When dc->caps.max_links is zero, hdcp_create_workqueue() should fail
+ * When dc_test_caps(dc)->max_links is zero, hdcp_create_workqueue() should fail
  * the initial allocation path and return NULL.
  */
 static void dm_test_hdcp_create_workqueue_zero_max_links_returns_null(struct kunit *test)
@@ -1170,10 +1171,9 @@ static void dm_test_hdcp_create_workqueue_zero_max_links_returns_null(struct kun
 	struct dc *dc;
 	struct hdcp_workqueue *work;
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 
-	dc->caps.max_links = 0;
+	dc_test_caps(dc)->max_links = 0;
 
 	work = hdcp_create_workqueue(NULL, &cp_psp, dc);
 
@@ -1200,9 +1200,9 @@ static void dm_test_hdcp_create_workqueue_initializes_work(struct kunit *test)
 
 	/* sysfs_create_bin_file() needs a real device kobject. */
 	adev->dev = adev->ddev.dev;
-	dc->caps.max_links = 1;
+	dc_test_caps(dc)->max_links = 1;
 	/* DCE_VERSION_UNKNOWN (0) is not in the DTM v3 list. */
-	dc->ctx->dce_version = DCE_VERSION_UNKNOWN;
+	dc_get_ctx(dc)->dce_version = DCE_VERSION_UNKNOWN;
 
 	work = hdcp_create_workqueue(adev, &cp_psp, dc);
 
@@ -1236,8 +1236,8 @@ static void dm_test_hdcp_create_workqueue_sets_dtm_v3_for_dcn31(struct kunit *te
 	struct hdcp_workqueue *work;
 
 	adev->dev = adev->ddev.dev;
-	dc->caps.max_links = 1;
-	dc->ctx->dce_version = DCN_VERSION_3_1;
+	dc_test_caps(dc)->max_links = 1;
+	dc_get_ctx(dc)->dce_version = DCN_VERSION_3_1;
 
 	work = hdcp_create_workqueue(adev, &cp_psp, dc);
 
@@ -1264,8 +1264,8 @@ static void dm_test_hdcp_create_workqueue_initializes_all_links(struct kunit *te
 	int i;
 
 	adev->dev = adev->ddev.dev;
-	dc->caps.max_links = 3;
-	dc->ctx->dce_version = DCN_VERSION_3_1;
+	dc_test_caps(dc)->max_links = 3;
+	dc_get_ctx(dc)->dce_version = DCN_VERSION_3_1;
 
 	work = hdcp_create_workqueue(adev, &cp_psp, dc);
 
@@ -2089,8 +2089,7 @@ static struct amdgpu_dm_connector *alloc_test_connector(struct kunit *test,
 	KUNIT_ASSERT_NOT_NULL(test, aconnector);
 	dc_link = kunit_kzalloc(test, sizeof(*dc_link), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, dc_link);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 
 	kref_init(&aconnector->base.base.refcount);
 	aconnector->base.index = index;
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_helpers_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_helpers_test.c
index 6e564f60b0df..48e30f1936b5 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_helpers_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_helpers_test.c
@@ -13,6 +13,7 @@
 #include <drm/display/drm_dp_mst_helper.h>
 
 #include "dc.h"
+#include "dc_test.h"
 #include "core_types.h"
 #include "clk_mgr.h"
 #include "link_service.h"
@@ -193,15 +194,16 @@ static void dm_test_apply_edid_quirks_psr_phy_power_down(struct kunit *test)
 	struct edid *embedded = dm_test_edid_with_panel_id(test,
 			drm_edid_encode_panel_id('S', 'D', 'C', 0x4203));
 
-	link->ctx = dc->ctx;
+	link->ctx = dc_get_ctx(dc);
 
 	link->connector_signal = SIGNAL_TYPE_DISPLAY_PORT;
 	apply_edid_quirks(link, external, &edid_caps);
-	KUNIT_EXPECT_FALSE(test, dc->debug.psr_phy_force_phy_power_down_up_level_2);
+	KUNIT_EXPECT_FALSE(
+		test, dc_test_debug_options(dc)->psr_phy_force_phy_power_down_up_level_2);
 
 	link->connector_signal = SIGNAL_TYPE_EDP;
 	apply_edid_quirks(link, embedded, &edid_caps);
-	KUNIT_EXPECT_TRUE(test, dc->debug.psr_phy_force_phy_power_down_up_level_2);
+	KUNIT_EXPECT_TRUE(test, dc_test_debug_options(dc)->psr_phy_force_phy_power_down_up_level_2);
 }
 
 /**
@@ -430,11 +432,10 @@ static void dm_test_parse_edid_caps_hdmi_frl(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, dc_edid);
 	edid_caps = kunit_kzalloc(test, sizeof(*edid_caps), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, edid_caps);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 
 	link->dc = dc;
-	dc->config.enable_frl = true;
+	dc_test_config(dc)->enable_frl = true;
 
 	dm_test_fill_base_edid(dc_edid, true);
 
@@ -473,11 +474,10 @@ static void dm_test_parse_edid_caps_hdmi_frl_dsc(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, dc_edid);
 	edid_caps = kunit_kzalloc(test, sizeof(*edid_caps), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, edid_caps);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 
 	link->dc = dc;
-	dc->config.enable_frl = true;
+	dc_test_config(dc)->enable_frl = true;
 
 	dm_test_fill_base_edid(dc_edid, true);
 
@@ -512,7 +512,7 @@ static void dm_test_parse_edid_caps_hdmi_comp_auto(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, edid_caps);
 
 	link->dc = dc;
-	link->ctx = dc->ctx;
+	link->ctx = dc_get_ctx(dc);
 
 	dm_test_fill_base_edid(dc_edid, true);
 
@@ -521,8 +521,8 @@ static void dm_test_parse_edid_caps_hdmi_comp_auto(struct kunit *test)
 
 	KUNIT_EXPECT_EQ(test, dm_helpers_parse_edid_caps(link, dc_edid, edid_caps), EDID_OK);
 	KUNIT_EXPECT_TRUE(test, edid_caps->panel_patch.hdmi_comp_auto);
-	KUNIT_EXPECT_TRUE(test, dc->debug.force_frl_max);
-	KUNIT_EXPECT_TRUE(test, dc->debug.force_frl_dsc);
+	KUNIT_EXPECT_TRUE(test, dc_test_debug_options(dc)->force_frl_max);
+	KUNIT_EXPECT_TRUE(test, dc_test_debug_options(dc)->force_frl_dsc);
 }
 
 /*
@@ -2143,13 +2143,12 @@ static void dm_test_override_panel_settings_debug_mask_disables_dsc(struct kunit
 
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, link_srv);
 	link = dm_kunit_alloc_link(test);
 	ctx->dc = dc;
-	dc->link_srv = link_srv;
+	dc_test_install_link_service(dc, link_srv);
 	link->dc = dc;
 	link_srv->dp_should_enable_fec = dm_test_dp_should_enable_fec;
 	link->connector_signal = SIGNAL_TYPE_DISPLAY_PORT;
@@ -2176,21 +2175,20 @@ static void dm_test_override_panel_settings_second_edp_disables_psr(struct kunit
 
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, link_srv);
 	first_link = dm_kunit_alloc_link(test);
 	second_link = dm_kunit_alloc_link(test);
 
 	ctx->dc = dc;
-	dc->link_srv = link_srv;
+	dc_test_install_link_service(dc, link_srv);
 	link_srv->dp_should_enable_fec = dm_test_dp_should_enable_fec;
 	first_link->dc = dc;
 	second_link->dc = dc;
-	dc->link_count = 2;
-	dc->links[0] = first_link;
-	dc->links[1] = second_link;
+	dc_test_set_link_count(dc, 2);
+	dc_test_set_link(dc, 0, first_link);
+	dc_test_set_link(dc, 1, second_link);
 	first_link->connector_signal = SIGNAL_TYPE_EDP;
 	second_link->connector_signal = SIGNAL_TYPE_EDP;
 
@@ -2538,7 +2536,7 @@ static void dm_test_dmub_aux_transfer_sync_hpd_discon(struct kunit *test)
  * @test: The KUnit test context
  *
  * With HPD connected the helper forwards the payload to
- * amdgpu_dm_process_dmub_aux_transfer_sync(). dc->link_count is zero, so the
+ * amdgpu_dm_process_dmub_aux_transfer_sync(). dc_get_link_count(dc) is zero, so the
  * async transfer is rejected and the engine-acquire error is reported.
  */
 static void dm_test_dmub_aux_transfer_sync_hpd_connected(struct kunit *test)
@@ -4117,15 +4115,14 @@ static void dm_test_dp_handle_test_pattern_no_pipe(struct kunit *test)
 	adev = dm_kunit_alloc_adev(test);
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	state = kunit_kzalloc(test, sizeof(*state), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, state);
 	link = dm_kunit_alloc_link(test);
 	aconnector = dm_kunit_alloc_connector(test, adev, link);
 
 	ctx->dc = dc;
-	dc->current_state = state;
+	dc_test_set_current_state(dc, state);
 	link->dc = dc;
 	link->priv = aconnector;
 
@@ -4267,14 +4264,13 @@ static void dm_test_dmub_set_config_sync_unknown_error(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, ctx);
 	dc_ctx = kunit_kzalloc(test, sizeof(*dc_ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, dc_ctx);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	notify = kunit_kzalloc(test, sizeof(*notify), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, notify);
 	link = dm_kunit_alloc_link(test);
 
-	dc->ctx = dc_ctx;
-	dc->links[0] = link;
+	dc_test_set_ctx(dc, dc_ctx);
+	dc_test_set_link(dc, 0, link);
 	ctx->dc = dc;
 	ctx->driver_context = adev;
 	adev->dm.dmub_notify = notify;
@@ -4309,8 +4305,7 @@ static void dm_test_is_dp_sink_present_queries_link_service(struct kunit *test)
 
 	adev = dm_kunit_alloc_adev(test);
 	KUNIT_ASSERT_NOT_NULL(test, adev);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, link_srv);
 	link = dm_kunit_alloc_link(test);
@@ -4321,7 +4316,7 @@ static void dm_test_is_dp_sink_present_queries_link_service(struct kunit *test)
 	drm_dp_aux_init(&aconnector->dm_dp_aux.aux);
 
 	link_srv->dp_is_sink_present = dm_test_dp_sink_present_true;
-	dc->link_srv = link_srv;
+	dc_test_install_link_service(dc, link_srv);
 	link->dc = dc;
 	link->priv = aconnector;
 
@@ -4588,8 +4583,7 @@ static struct dm_test_pattern_fixture dm_test_setup_pattern(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, adev);
 	fixture.ctx = kunit_kzalloc(test, sizeof(*fixture.ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, fixture.ctx);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	state = kunit_kzalloc(test, sizeof(*state), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, state);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
@@ -4607,9 +4601,9 @@ static struct dm_test_pattern_fixture dm_test_setup_pattern(struct kunit *test)
 	clk_mgr->funcs = &dm_test_clk_mgr_funcs;
 	clk_mgr->bw_params = bw_params;
 
-	dc->link_srv = link_srv;
-	dc->clk_mgr = clk_mgr;
-	dc->current_state = state;
+	dc_test_install_link_service(dc, link_srv);
+	dc_test_set_clk_mgr(dc, clk_mgr);
+	dc_test_set_current_state(dc, state);
 	fixture.ctx->dc = dc;
 	fixture.link->dc = dc;
 	fixture.link->priv = fixture.aconnector;
@@ -4794,7 +4788,7 @@ static void dm_test_read_local_edid_i2c_no_response(struct kunit *test)
 	fixture.link->aux_mode = false;
 	fixture.link->ddc_hw_inst = 1;
 	fixture.aconnector->i2c = (struct amdgpu_i2c_adapter *)ddc;
-	fixture.dc->hwss.prepare_ddc = dm_test_prepare_ddc;
+	dc_test_hwss(fixture.dc)->prepare_ddc = dm_test_prepare_ddc;
 	dm_test_prepare_ddc_calls = 0;
 
 	KUNIT_EXPECT_EQ(test,
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_irq_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_irq_test.c
index 8c112bda46c8..b64d63fe15fd 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_irq_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_irq_test.c
@@ -15,6 +15,7 @@
 #include <drm/display/drm_dp_helper.h>
 
 #include "dc.h"
+#include "dc_test.h"
 #include "inc/core_types.h"
 #include "inc/hw/timing_generator.h"
 #include "irq/irq_service.h"
@@ -444,7 +445,7 @@ static struct dc *dm_test_alloc_dc_with_irq_service(struct kunit *test,
 	irqs->funcs = funcs;
 	irqs->info = info;
 	res_pool->irqs = irqs;
-	dc->res_pool = res_pool;
+	dc_test_set_res_pool(dc, res_pool);
 
 	return dc;
 }
@@ -1532,9 +1533,8 @@ static void dm_test_hpd_rx_irq_create_workqueue(struct kunit *test)
 
 	adev = dm_kunit_alloc_adev(test);
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
-	dc->caps.max_links = 4;
+	dc = dm_kunit_alloc_dc(test);
+	dc_test_caps(dc)->max_links = 4;
 	adev->dm.dc = dc;
 
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
@@ -1542,10 +1542,10 @@ static void dm_test_hpd_rx_irq_create_workqueue(struct kunit *test)
 
 	ctx->wq = amdgpu_dm_hpd_rx_irq_create_workqueue(adev);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->wq);
-	ctx->count = dc->caps.max_links;
+	ctx->count = dc_test_caps(dc)->max_links;
 	KUNIT_ASSERT_EQ(test, kunit_add_action_or_reset(test, dm_test_destroy_hpd_rx_wq, ctx), 0);
 
-	for (i = 0; i < dc->caps.max_links; i++)
+	for (i = 0; i < dc_test_caps(dc)->max_links; i++)
 		KUNIT_EXPECT_TRUE(test, ctx->wq[i].wq != NULL);
 }
 
@@ -1578,9 +1578,8 @@ static void dm_test_hpd_rx_irq_work_suspend_flushes(struct kunit *test)
 
 	adev = dm_kunit_alloc_adev(test);
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
-	dc->caps.max_links = 2;
+	dc = dm_kunit_alloc_dc(test);
+	dc_test_caps(dc)->max_links = 2;
 	adev->dm.dc = dc;
 
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
@@ -1588,7 +1587,7 @@ static void dm_test_hpd_rx_irq_work_suspend_flushes(struct kunit *test)
 
 	ctx->wq = amdgpu_dm_hpd_rx_irq_create_workqueue(adev);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->wq);
-	ctx->count = dc->caps.max_links;
+	ctx->count = dc_test_caps(dc)->max_links;
 	KUNIT_ASSERT_EQ(test, kunit_add_action_or_reset(test, dm_test_destroy_hpd_rx_wq, ctx), 0);
 
 	adev->dm.hpd_rx_offload_wq = ctx->wq;
@@ -1756,12 +1755,12 @@ static void dm_test_set_crtc_irq_state_allows_idle(struct kunit *test)
 	logger = kunit_kzalloc(test, sizeof(*logger), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, logger);
 	logger->dev = &adev->ddev;
-	dc->ctx->logger = logger;
+	dc_get_ctx(dc)->logger = logger;
 
-	dc->caps.ips_support = true;
-	dc->idle_optimizations_allowed = true;
+	dc_test_caps(dc)->ips_support = true;
+	dc_test_set_idle_optimizations_allowed(dc, true);
 	/* Keep dc_allow_idle_optimizations() a safe early return. */
-	dc->debug.disable_idle_power_optimizations = true;
+	dc_test_debug_options(dc)->disable_idle_power_optimizations = true;
 	adev->dm.dc = dc;
 
 	acrtc->otg_inst = 0;
@@ -2052,8 +2051,8 @@ static void dm_test_hpd_init_empty_connectors(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, link);
 	link->irq_source_hpd = DC_IRQ_SOURCE_HPD1;
 	link->irq_source_hpd_rx = DC_IRQ_SOURCE_HPD1RX;
-	dc->links[0] = link;
-	dc->link_count = 1;
+	dc_test_set_link(dc, 0, link);
+	dc_test_set_link_count(dc, 1);
 
 	amdgpu_dm_hpd_init(adev);
 }
@@ -2118,8 +2117,8 @@ static void dm_test_hpd_init_fini_with_connectors(struct kunit *test)
 	link->irq_source_hpd = DC_IRQ_SOURCE_HPD1;
 	link->irq_source_hpd_rx = DC_IRQ_SOURCE_HPD1RX;
 	aconn->dc_link = link;
-	dc->links[0] = link;
-	dc->link_count = 1;
+	dc_test_set_link(dc, 0, link);
+	dc_test_set_link_count(dc, 1);
 
 	/* The irq service stubs accept the HW writes without register access. */
 	amdgpu_dm_hpd_init(adev);
@@ -2159,8 +2158,8 @@ static void dm_test_hpd_init_fini_analog_connector(struct kunit *test)
 	/* An analog connector id makes the loop request polling. */
 	link->link_id.id = CONNECTOR_ID_VGA;
 	aconn->dc_link = link;
-	dc->links[0] = link;
-	dc->link_count = 1;
+	dc_test_set_link(dc, 0, link);
+	dc_test_set_link_count(dc, 1);
 
 	/* use_polling becomes true, so init must enable KMS polling. */
 	amdgpu_dm_hpd_init(adev);
@@ -2210,8 +2209,8 @@ static void dm_test_hpd_init_fini_irq_ref(struct kunit *test)
 	link->irq_source_hpd = DC_IRQ_SOURCE_HPD1;
 	link->irq_source_hpd_rx = DC_IRQ_SOURCE_INVALID;
 	aconn->dc_link = link;
-	dc->links[0] = link;
-	dc->link_count = 1;
+	dc_test_set_link(dc, 0, link);
+	dc_test_set_link_count(dc, 1);
 
 	amdgpu_dm_hpd_init(adev);
 	amdgpu_dm_hpd_fini(adev);
@@ -2310,8 +2309,7 @@ dm_test_setup_hpd_rx_offload_work(struct kunit *test,
 	mutex_init(&aconn->hpd_lock);
 	offload_wq->aconnector = aconn;
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
@@ -2320,8 +2318,8 @@ dm_test_setup_hpd_rx_offload_work(struct kunit *test,
 	KUNIT_ASSERT_NOT_NULL(test, link);
 
 	link_srv->detect_connection_type = dm_test_detect_connection_single;
-	dc->link_srv = link_srv;
-	dc->ctx = ctx;
+	dc_test_install_link_service(dc, link_srv);
+	dc_test_set_ctx(dc, ctx);
 	ctx->dc = dc;
 	link->dc = dc;
 	link->ctx = ctx;
@@ -2542,8 +2540,7 @@ static struct amdgpu_dm_connector *dm_test_setup_hdmi_debounce(struct kunit *tes
 	INIT_DELAYED_WORK(&aconn->hdmi_hpd_debounce_work,
 			  amdgpu_dm_hdmi_hpd_debounce_work);
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
@@ -2552,8 +2549,8 @@ static struct amdgpu_dm_connector *dm_test_setup_hdmi_debounce(struct kunit *tes
 	KUNIT_ASSERT_NOT_NULL(test, link);
 
 	link_srv->detect_link = dm_test_detect_link_false;
-	dc->ctx = ctx;
-	dc->link_srv = link_srv;
+	dc_test_set_ctx(dc, ctx);
+	dc_test_install_link_service(dc, link_srv);
 	ctx->dc = dc;
 	link->dc = dc;
 	link->ctx = ctx;
@@ -2607,13 +2604,13 @@ static void dm_test_hdmi_hpd_debounce_reallow_idle(struct kunit *test)
 
 	/* DC_LOG_* dereferences ctx->logger->dev, so wire a real drm device. */
 	logger->dev = aconn->base.dev;
-	dc->ctx->logger = logger;
+	dc_get_ctx(dc)->logger = logger;
 
 	/* Make reallow_idle true and keep dc_allow_idle*() a safe early return. */
 	dmub_srv->idle_allowed = true;
-	dc->ctx->dmub_srv = dmub_srv;
-	dc->caps.ips_support = true;
-	dc->debug.disable_idle_power_optimizations = true;
+	dc_get_ctx(dc)->dmub_srv = dmub_srv;
+	dc_test_caps(dc)->ips_support = true;
+	dc_test_debug_options(dc)->disable_idle_power_optimizations = true;
 
 	/* A cached previous sink must be released and cleared. */
 	aconn->hdmi_prev_sink = dm_test_sink_create(aconn->dc_link);
@@ -2707,14 +2704,13 @@ static void dm_test_handle_hpd_irq_disabled(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, state);
 	aconn->base.state = &state->base;
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx);
 	link = kunit_kzalloc(test, sizeof(*link), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, link);
 
-	dc->ctx = ctx;
+	dc_test_set_ctx(dc, ctx);
 	ctx->dc = dc;
 	link->ctx = ctx;
 	aconn->dc_link = link;
@@ -2756,8 +2752,7 @@ static struct amdgpu_dm_connector *dm_test_setup_hpd_irq_helper(struct kunit *te
 	KUNIT_ASSERT_NOT_NULL(test, state);
 	aconn->base.state = &state->base;
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
@@ -2766,8 +2761,8 @@ static struct amdgpu_dm_connector *dm_test_setup_hpd_irq_helper(struct kunit *te
 	KUNIT_ASSERT_NOT_NULL(test, link);
 
 	link_srv->detect_connection_type = dm_test_detect_connection_none;
-	dc->ctx = ctx;
-	dc->link_srv = link_srv;
+	dc_test_set_ctx(dc, ctx);
+	dc_test_install_link_service(dc, link_srv);
 	ctx->dc = dc;
 	link->dc = dc;
 	link->ctx = ctx;
@@ -3017,8 +3012,7 @@ static void dm_test_handle_hpd_rx_irq_disabled(struct kunit *test)
 
 	aconn = dm_kunit_alloc_connector(test, adev, NULL);
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
@@ -3027,8 +3021,8 @@ static void dm_test_handle_hpd_rx_irq_disabled(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, link);
 
 	link_srv->dp_handle_hpd_rx_irq = dm_test_handle_hpd_rx_no_work;
-	dc->ctx = ctx;
-	dc->link_srv = link_srv;
+	dc_test_set_ctx(dc, ctx);
+	dc_test_install_link_service(dc, link_srv);
 	ctx->dc = dc;
 	link->dc = dc;
 	link->ctx = ctx;
@@ -3101,8 +3095,7 @@ static struct amdgpu_dm_connector *dm_test_setup_hpd_rx_irq(struct kunit *test,
 	mutex_init(&aconn->hpd_lock);
 	aconn->mst_mgr.mst_state = true;
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
@@ -3110,8 +3103,8 @@ static struct amdgpu_dm_connector *dm_test_setup_hpd_rx_irq(struct kunit *test,
 	link = kunit_kzalloc(test, sizeof(*link), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, link);
 
-	dc->ctx = ctx;
-	dc->link_srv = link_srv;
+	dc_test_set_ctx(dc, ctx);
+	dc_test_install_link_service(dc, link_srv);
 	ctx->dc = dc;
 	link->dc = dc;
 	link->ctx = ctx;
@@ -3332,8 +3325,7 @@ static void dm_test_dmub_hpd_callback_invalid_index(struct kunit *test)
 	struct dc *dc;
 
 	adev = dm_kunit_alloc_adev(test);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	adev->dm.dc = dc;
 	notify.link_index = 1;
 
@@ -3351,11 +3343,10 @@ static void dm_test_dmub_hpd_callback_empty_connectors(struct kunit *test)
 	struct dc *dc;
 
 	adev = dm_kunit_alloc_adev(test);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	adev->dm.dc = dc;
 	adev->dm.ddev = &adev->ddev;
-	dc->link_count = 1;
+	dc_test_set_link_count(dc, 1);
 	notify.type = DMUB_NOTIFICATION_HPD_SENSE_NOTIFY;
 
 	dmub_hpd_callback(adev, &notify);
@@ -3376,11 +3367,10 @@ static void dm_test_dmub_hpd_callback_suspend_skip(struct kunit *test)
 	struct dc *dc;
 
 	adev = dm_kunit_alloc_adev(test);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	adev->dm.dc = dc;
 	adev->in_suspend = true;
-	dc->link_count = 1;
+	dc_test_set_link_count(dc, 1);
 	notify.type = DMUB_NOTIFICATION_HPD;
 
 	/* adev->dm.ddev is left NULL: reaching the connector walk would crash. */
@@ -3408,15 +3398,14 @@ static void dm_test_dmub_hpd_callback_unknown_type_match(struct kunit *test)
 	struct dc *dc;
 
 	adev = dm_kunit_alloc_adev(test);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	adev->dm.dc = dc;
 	adev->dm.ddev = &adev->ddev;
-	dc->link_count = 1;
+	dc_test_set_link_count(dc, 1);
 
 	link = kunit_kzalloc(test, sizeof(*link), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, link);
-	dc->links[0] = link;
+	dc_test_set_link(dc, 0, link);
 
 	/* A writeback connector must be skipped by the loop. */
 	wbconn = kunit_kzalloc(test, sizeof(*wbconn), GFP_KERNEL);
@@ -3463,8 +3452,7 @@ static void dm_test_dmub_hpd_callback_hpd_type(struct kunit *test)
 	adev = dm_kunit_alloc_adev(test);
 	mutex_init(&adev->dm.dc_lock);
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
@@ -3474,16 +3462,16 @@ static void dm_test_dmub_hpd_callback_hpd_type(struct kunit *test)
 
 	link_srv->detect_connection_type = dm_test_detect_connection_none;
 	link_srv->detect_link = dm_test_detect_link_false;
-	dc->ctx = ctx;
-	dc->link_srv = link_srv;
+	dc_test_set_ctx(dc, ctx);
+	dc_test_install_link_service(dc, link_srv);
 	ctx->dc = dc;
 	link->dc = dc;
 	link->ctx = ctx;
 
 	adev->dm.dc = dc;
 	adev->dm.ddev = &adev->ddev;
-	dc->link_count = 1;
-	dc->links[0] = link;
+	dc_test_set_link_count(dc, 1);
+	dc_test_set_link(dc, 0, link);
 
 	aconn = kunit_kzalloc(test, sizeof(*aconn), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, aconn);
@@ -3532,8 +3520,7 @@ static void dm_test_dmub_hpd_callback_hpd_irq_type(struct kunit *test)
 	spin_lock_init(&offload_wq->offload_lock);
 	adev->dm.hpd_rx_offload_wq = offload_wq;
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
@@ -3542,8 +3529,8 @@ static void dm_test_dmub_hpd_callback_hpd_irq_type(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, link);
 
 	link_srv->dp_handle_hpd_rx_irq = dm_test_handle_hpd_rx_no_work;
-	dc->ctx = ctx;
-	dc->link_srv = link_srv;
+	dc_test_set_ctx(dc, ctx);
+	dc_test_install_link_service(dc, link_srv);
 	ctx->dc = dc;
 	link->dc = dc;
 	link->ctx = ctx;
@@ -3552,8 +3539,8 @@ static void dm_test_dmub_hpd_callback_hpd_irq_type(struct kunit *test)
 
 	adev->dm.dc = dc;
 	adev->dm.ddev = &adev->ddev;
-	dc->link_count = 1;
-	dc->links[0] = link;
+	dc_test_set_link_count(dc, 1);
+	dc_test_set_link(dc, 0, link);
 
 	aconn = kunit_kzalloc(test, sizeof(*aconn), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, aconn);
@@ -3584,8 +3571,7 @@ static void dm_test_register_hpd_handlers_empty(struct kunit *test)
 	struct dc *dc;
 
 	adev = dm_kunit_alloc_adev(test);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	adev->dm.dc = dc;
 
 	KUNIT_EXPECT_EQ(test, amdgpu_dm_register_hpd_handlers(adev), 0);
@@ -3609,8 +3595,7 @@ static void dm_test_register_hpd_handlers_valid(struct kunit *test)
 
 	adev = dm_kunit_alloc_adev(test);
 	KUNIT_ASSERT_EQ(test, amdgpu_dm_irq_init(adev), 0);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	adev->dm.dc = dc;
 
 	wbconn = kunit_kzalloc(test, sizeof(*wbconn), GFP_KERNEL);
@@ -3656,8 +3641,7 @@ static void dm_test_register_hpd_handlers_invalid_hpd(struct kunit *test)
 
 	adev = dm_kunit_alloc_adev(test);
 	KUNIT_ASSERT_EQ(test, amdgpu_dm_irq_init(adev), 0);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	adev->dm.dc = dc;
 
 	aconn = kunit_kzalloc(test, sizeof(*aconn), GFP_KERNEL);
@@ -3691,8 +3675,7 @@ static void dm_test_register_hpd_handlers_invalid_hpd_rx(struct kunit *test)
 
 	adev = dm_kunit_alloc_adev(test);
 	KUNIT_ASSERT_EQ(test, amdgpu_dm_irq_init(adev), 0);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 	adev->dm.dc = dc;
 
 	aconn = kunit_kzalloc(test, sizeof(*aconn), GFP_KERNEL);
@@ -3732,8 +3715,8 @@ static void dm_test_register_hpd_handlers_dmub_outbox(struct kunit *test)
 	adev->dm.dc = dc;
 
 	/* Make dc_is_dmub_outbox_supported() return true. */
-	dc->caps.dmcub_support = true;
-	dc->ctx->asic_id.chip_family = AMDGPU_FAMILY_GC_11_0_1;
+	dc_test_caps(dc)->dmcub_support = true;
+	dc_get_ctx(dc)->asic_id.chip_family = AMDGPU_FAMILY_GC_11_0_1;
 
 	KUNIT_EXPECT_EQ(test, amdgpu_dm_register_hpd_handlers(adev), 0);
 	KUNIT_EXPECT_PTR_EQ(test, adev->dm.dmub_callback[DMUB_NOTIFICATION_HPD],
@@ -3843,18 +3826,18 @@ static struct amdgpu_crtc *dm_test_setup_vrr_pflip_crtc(struct kunit *test,
 	KUNIT_ASSERT_EQ(test, drm_vblank_init(&adev->ddev, 1), 0);
 
 	dc = dm_kunit_alloc_dc_with_ctx(test);
-	dc->current_state = kunit_kzalloc(test, sizeof(*dc->current_state),
-					  GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc->current_state);
+	dc_test_set_current_state(dc, kunit_kzalloc(test, sizeof(*dc_get_current_state(dc)),
+					  GFP_KERNEL));
+	KUNIT_ASSERT_NOT_NULL(test, dc_get_current_state(dc));
 	adev->dm.dc = dc;
 
 	link = dm_kunit_alloc_link(test);
 	stream = dm_kunit_alloc_stream(test, link);
-	stream->ctx = dc->ctx;
+	stream->ctx = dc_get_ctx(dc);
 
 	if (tg) {
-		dc->current_state->res_ctx.pipe_ctx[0].stream = stream;
-		dc->current_state->res_ctx.pipe_ctx[0].stream_res.tg = tg;
+		dc_get_current_state(dc)->res_ctx.pipe_ctx[0].stream = stream;
+		dc_get_current_state(dc)->res_ctx.pipe_ctx[0].stream_res.tg = tg;
 	}
 
 	acrtc = dm_test_add_crtc(test, adev);
@@ -4056,9 +4039,9 @@ static struct amdgpu_crtc *dm_test_setup_vmin_vmax_crtc(struct kunit *test,
 	KUNIT_ASSERT_EQ(test, amdgpu_dm_irq_init(adev), 0);
 
 	dc = dm_kunit_alloc_dc_with_ctx(test);
-	dc->current_state = kunit_kzalloc(test, sizeof(*dc->current_state),
-					  GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc->current_state);
+	dc_test_set_current_state(dc, kunit_kzalloc(test, sizeof(*dc_get_current_state(dc)),
+					  GFP_KERNEL));
+	KUNIT_ASSERT_NOT_NULL(test, dc_get_current_state(dc));
 	adev->dm.dc = dc;
 
 	link = dm_kunit_alloc_link(test);
@@ -4205,7 +4188,7 @@ static void dm_test_crtc_high_irq_writeback_disables(struct kunit *test)
 	adev = dm_kunit_alloc_adev(test);
 	KUNIT_ASSERT_EQ(test, drm_vblank_init(&adev->ddev, 1), 0);
 
-	/* dc_stream_fc_disable_writeback() dereferences dc->res_pool. */
+	/* dc_stream_fc_disable_writeback() dereferences dc_get_res_pool(dc). */
 	dc = dm_test_alloc_dc_with_irq_service(test,
 					       &dm_test_irq_service_funcs_dcn10);
 	adev->dm.dc = dc;
@@ -4384,7 +4367,7 @@ static void dm_test_dmub_outbox1_low_irq_empty(struct kunit *test)
 
 	dmub->hw_funcs.get_outbox0_wptr = dm_test_dmub_get_outbox0_wptr;
 	dc_dmub_srv->dmub = dmub;
-	dc->ctx->dmub_srv = dc_dmub_srv;
+	dc_get_ctx(dc)->dmub_srv = dc_dmub_srv;
 	adev->dm.dc = dc;
 	params.adev = adev;
 	params.irq_src = DC_IRQ_SOURCE_DMCUB_OUTBOX;
@@ -4422,7 +4405,7 @@ static void dm_test_dmub_outbox1_low_irq_drains_trace(struct kunit *test)
 	dmub->outbox0_rb.capacity = DM_TEST_OUTBOX0_RB_SIZE;
 	dmub->hw_funcs.get_outbox0_wptr = dm_test_dmub_get_outbox0_wptr_full;
 	dc_dmub_srv->dmub = dmub;
-	dc->ctx->dmub_srv = dc_dmub_srv;
+	dc_get_ctx(dc)->dmub_srv = dc_dmub_srv;
 	adev->dm.dc = dc;
 	params.adev = adev;
 	params.irq_src = DC_IRQ_SOURCE_DMCUB_OUTBOX;
@@ -4460,11 +4443,11 @@ static struct amdgpu_device *dm_test_alloc_adev_outbox_notify(struct kunit *test
 	dmub->hw_funcs.get_outbox0_wptr = dm_test_dmub_get_outbox0_wptr;
 	dmub->hw_funcs.get_outbox1_wptr = dm_test_dmub_get_outbox1_wptr;
 	dc_dmub_srv->dmub = dmub;
-	dc->ctx->dmub_srv = dc_dmub_srv;
+	dc_get_ctx(dc)->dmub_srv = dc_dmub_srv;
 
 	/* Make dc_enable_dmub_notifications() return true. */
-	dc->caps.dmcub_support = true;
-	dc->ctx->asic_id.chip_family = AMDGPU_FAMILY_GC_11_0_1;
+	dc_test_caps(dc)->dmcub_support = true;
+	dc_get_ctx(dc)->asic_id.chip_family = AMDGPU_FAMILY_GC_11_0_1;
 
 	adev->dm.dc = dc;
 
@@ -4578,8 +4561,8 @@ static struct amdgpu_device *dm_test_setup_irq_regs(struct kunit *test,
 	KUNIT_ASSERT_EQ(test, kunit_add_action_or_reset(test, dm_test_free_irq_sources,
 							 adev), 0);
 	dc = dm_test_alloc_dc_with_irq_service(test, funcs);
-	dc->ctx->dce_version = DCE_VERSION_11_0;
-	dc->caps.max_otg_num = 1;
+	dc_get_ctx(dc)->dce_version = DCE_VERSION_11_0;
+	dc_test_caps(dc)->max_otg_num = 1;
 	adev->dm.dc = dc;
 	adev->mode_info.num_crtc = 1;
 	adev->mode_info.num_hpd = 1;
@@ -4663,7 +4646,7 @@ static void dm_test_dce110_register_irq_handlers_crtc_add_id_fails(struct kunit
 
 	adev = dm_kunit_alloc_adev(test);
 	dc = dm_test_alloc_dc_with_irq_service(test, &dm_test_irq_service_funcs_dce110);
-	dc->ctx->dce_version = DCE_VERSION_11_0;
+	dc_get_ctx(dc)->dce_version = DCE_VERSION_11_0;
 	adev->dm.dc = dc;
 	adev->mode_info.num_crtc = 1;
 
@@ -4917,7 +4900,7 @@ static void dm_test_register_outbox_irq_handlers_add_id_fails(struct kunit *test
  * dm_test_register_outbox_irq_handlers_with_dmub - Test outbox registration with DMUB
  * @test: The KUnit test context
  *
- * Exercises the dc->ctx->dmub_srv branch which maps the outbox source and
+ * Exercises the dc_get_ctx(dc)->dmub_srv branch which maps the outbox source and
  * registers dm_dmub_outbox1_low_irq in the low IRQ context table.
  */
 static void dm_test_register_outbox_irq_handlers_with_dmub(struct kunit *test)
@@ -4933,7 +4916,7 @@ static void dm_test_register_outbox_irq_handlers_with_dmub(struct kunit *test)
 	dc = dm_test_alloc_dc_with_irq_service(test, &dm_test_irq_service_funcs_dcn10);
 	dc_dmub_srv = kunit_kzalloc(test, sizeof(*dc_dmub_srv), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, dc_dmub_srv);
-	dc->ctx->dmub_srv = dc_dmub_srv;
+	dc_get_ctx(dc)->dmub_srv = dc_dmub_srv;
 	adev->dm.dc = dc;
 	amdgpu_dm_set_irq_funcs(adev);
 	KUNIT_ASSERT_EQ(test, amdgpu_dm_irq_init(adev), 0);
@@ -5086,9 +5069,9 @@ static void dm_test_handle_vmin_vmax_update(struct kunit *test)
 	mutex_init(&adev->dm.dc_lock);
 
 	dc = dm_kunit_alloc_dc_with_ctx(test);
-	dc->current_state = kunit_kzalloc(test, sizeof(*dc->current_state),
-					  GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc->current_state);
+	dc_test_set_current_state(dc, kunit_kzalloc(test, sizeof(*dc_get_current_state(dc)),
+					  GFP_KERNEL));
+	KUNIT_ASSERT_NOT_NULL(test, dc_get_current_state(dc));
 	adev->dm.dc = dc;
 
 	stream = kunit_kzalloc(test, sizeof(*stream), GFP_KERNEL);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_ism_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_ism_test.c
index a9c6485e2a9e..5864147faf1c 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_ism_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_ism_test.c
@@ -8,6 +8,7 @@
 #include <kunit/test.h>
 
 #include "dc.h"
+#include "dc_test.h"
 #include "amdgpu.h"
 #include "amdgpu_mode.h"
 #include "amdgpu_dm.h"
@@ -1191,9 +1192,9 @@ static void dm_test_ism_dispatch_optimized_idle_defers_sso(struct kunit *test)
  * ===== Behavioural tests for dm_ism_commit_idle_optimization_state =====
  *
  * The commit path runs the real DC calls. dc_allow_idle_optimizations() only
- * reaches hardware through dc->hwss.apply_idle_power_optimizations(), so the
+ * reaches hardware through dc_test_hwss(dc)->apply_idle_power_optimizations(), so the
  * spy is installed there — DC's own seam — and the outcome is read back from
- * dc->idle_optimizations_allowed. The callback fires only on an actual
+ * dc_is_idle_optimizations_allowed(dc). The callback fires only on an actual
  * transition, so the call count is the number of idle state changes requested.
  */
 
@@ -1236,12 +1237,12 @@ static struct dc_stream_state *setup_commit_test(struct kunit *test,
 	logger = kunit_kzalloc(test, sizeof(*logger), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, logger);
 	logger->dev = &adev->ddev;
-	dc->ctx->logger = logger;
+	dc_get_ctx(dc)->logger = logger;
 	/* is_apu path avoids DC_LOG_DC()'s NULL-logger dereference. */
-	dc->caps.is_apu = true;
+	dc_test_caps(dc)->is_apu = true;
 	/* dc_allow() only calls apply() when clk_mgr is present. */
-	dc->clk_mgr = dm_kunit_alloc_clk_mgr(test);
-	dc->hwss.apply_idle_power_optimizations = dm_ism_test_apply_idle;
+	dc_test_set_clk_mgr(dc, dm_kunit_alloc_clk_mgr(test));
+	dc_test_hwss(dc)->apply_idle_power_optimizations = dm_ism_test_apply_idle;
 	dm_ism_test_idle = (typeof(dm_ism_test_idle)){ };
 
 	amdgpu_dm_ism_init(&acrtc->ism, config);
@@ -1281,7 +1282,7 @@ static void dm_test_ism_commit_allows_idle_on_optimized_idle(struct kunit *test)
 		/* vblank disabled + no SSO -> a single allow-idle transition. */
 		KUNIT_EXPECT_EQ(test, dm_ism_test_idle.calls, 1);
 		KUNIT_EXPECT_TRUE(test, dm_ism_test_idle.last_allow);
-		KUNIT_EXPECT_TRUE(test, adev->dm.dc->idle_optimizations_allowed);
+		KUNIT_EXPECT_TRUE(test, dc_is_idle_optimizations_allowed(adev->dm.dc));
 
 		cancel_delayed_work(&acrtc->ism.sso_delayed_work);
 	}
@@ -1308,7 +1309,7 @@ static void dm_test_ism_commit_enables_sso_on_optimized_idle_sso(struct kunit *t
 	};
 
 	setup_commit_test(test, acrtc, &config);
-	adev->dm.dc->idle_optimizations_allowed = true;
+	dc_test_set_idle_optimizations_allowed(adev->dm.dc, true);
 
 	scoped_guard(mutex, &adev->dm.dc_lock) {
 		amdgpu_dm_ism_commit_event(&acrtc->ism,
@@ -1320,7 +1321,7 @@ static void dm_test_ism_commit_enables_sso_on_optimized_idle_sso(struct kunit *t
 		/* SSO engagement disallows idle, then re-allows it. */
 		KUNIT_EXPECT_EQ(test, dm_ism_test_idle.calls, 2);
 		KUNIT_EXPECT_TRUE(test, dm_ism_test_idle.last_allow);
-		KUNIT_EXPECT_TRUE(test, adev->dm.dc->idle_optimizations_allowed);
+		KUNIT_EXPECT_TRUE(test, dc_is_idle_optimizations_allowed(adev->dm.dc));
 	}
 
 	amdgpu_dm_ism_flush(&acrtc->ism);
@@ -1351,7 +1352,7 @@ static void dm_test_ism_commit_disallows_idle_on_timer_aborted(struct kunit *tes
 
 	stream = setup_commit_test(test, acrtc, &config);
 	setup_idle_delay_history(&acrtc->ism, stream);
-	adev->dm.dc->idle_optimizations_allowed = true;
+	dc_test_set_idle_optimizations_allowed(adev->dm.dc, true);
 
 	scoped_guard(mutex, &adev->dm.dc_lock) {
 		/* Non-zero delay parks the FSM in HYSTERESIS_WAITING. */
@@ -1369,7 +1370,7 @@ static void dm_test_ism_commit_disallows_idle_on_timer_aborted(struct kunit *tes
 		/* TIMER_ABORTED commit runs with vblank_enabled=true. */
 		KUNIT_EXPECT_EQ(test, dm_ism_test_idle.calls, 1);
 		KUNIT_EXPECT_FALSE(test, dm_ism_test_idle.last_allow);
-		KUNIT_EXPECT_FALSE(test, adev->dm.dc->idle_optimizations_allowed);
+		KUNIT_EXPECT_FALSE(test, dc_is_idle_optimizations_allowed(adev->dm.dc));
 	}
 
 	amdgpu_dm_ism_flush(&acrtc->ism);
@@ -1409,7 +1410,7 @@ static void dm_test_ism_exit_from_optimized_idle_disallows_idle(struct kunit *te
 		/* Allow on entry, disallow on exit. */
 		KUNIT_EXPECT_EQ(test, dm_ism_test_idle.calls, 2);
 		KUNIT_EXPECT_FALSE(test, dm_ism_test_idle.last_allow);
-		KUNIT_EXPECT_FALSE(test, adev->dm.dc->idle_optimizations_allowed);
+		KUNIT_EXPECT_FALSE(test, dc_is_idle_optimizations_allowed(adev->dm.dc));
 		/* The idle period was recorded on the way out. */
 		KUNIT_EXPECT_EQ(test, acrtc->ism.next_record_idx, 1);
 	}
@@ -1449,7 +1450,7 @@ static void dm_test_ism_exit_from_sso_disallows_idle(struct kunit *test)
 
 		KUNIT_EXPECT_EQ(test, dm_ism_test_idle.calls, 2);
 		KUNIT_EXPECT_FALSE(test, dm_ism_test_idle.last_allow);
-		KUNIT_EXPECT_FALSE(test, adev->dm.dc->idle_optimizations_allowed);
+		KUNIT_EXPECT_FALSE(test, dc_is_idle_optimizations_allowed(adev->dm.dc));
 		KUNIT_EXPECT_EQ(test, acrtc->ism.next_record_idx, 1);
 	}
 
@@ -1495,7 +1496,7 @@ static void dm_test_ism_delayed_work_runs_timer_elapsed(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, (int)acrtc->ism.current_state,
 			(int)DM_ISM_STATE_OPTIMIZED_IDLE_SSO);
 	KUNIT_EXPECT_EQ(test, dm_ism_test_idle.calls, 1);
-	KUNIT_EXPECT_TRUE(test, adev->dm.dc->idle_optimizations_allowed);
+	KUNIT_EXPECT_TRUE(test, dc_is_idle_optimizations_allowed(adev->dm.dc));
 
 	amdgpu_dm_ism_flush(&acrtc->ism);
 }
@@ -1533,7 +1534,7 @@ static void dm_test_ism_sso_delayed_work_runs_sso_elapsed(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, (int)acrtc->ism.current_state,
 			(int)DM_ISM_STATE_OPTIMIZED_IDLE_SSO);
 	KUNIT_EXPECT_EQ(test, dm_ism_test_idle.calls, 3);
-	KUNIT_EXPECT_TRUE(test, adev->dm.dc->idle_optimizations_allowed);
+	KUNIT_EXPECT_TRUE(test, dc_is_idle_optimizations_allowed(adev->dm.dc));
 
 	amdgpu_dm_ism_flush(&acrtc->ism);
 }
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_kunit_helpers.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_kunit_helpers.c
index f844b644bb77..9954cbab6541 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_kunit_helpers.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_kunit_helpers.c
@@ -11,6 +11,7 @@
 #include <drm/drm_managed.h>
 
 #include "dc.h"
+#include "dc_test.h"
 #include "core_types.h"
 #include "clk_mgr.h"
 #include "amdgpu.h"
@@ -47,18 +48,29 @@ struct dc_link *dm_kunit_alloc_link(struct kunit *test)
 }
 EXPORT_SYMBOL(dm_kunit_alloc_link);
 
+struct dc *dm_kunit_alloc_dc(struct kunit *test)
+{
+	struct dc *dc;
+
+	dc = dc_test_create();
+	KUNIT_ASSERT_NOT_NULL(test, dc);
+	kunit_add_action(test, (kunit_action_t *)dc_test_destroy, dc);
+
+	return dc;
+}
+EXPORT_SYMBOL(dm_kunit_alloc_dc);
+
 struct dc *dm_kunit_alloc_dc_with_ctx(struct kunit *test)
 {
 	struct dc_context *ctx;
 	struct dc *dc;
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx);
 
-	dc->ctx = ctx;
+	dc_test_set_ctx(dc, ctx);
 	ctx->dc = dc;
 
 	return dc;
@@ -72,7 +84,7 @@ struct dc_link *dm_kunit_alloc_link_with_ctx(struct kunit *test)
 
 	link = dm_kunit_alloc_link(test);
 	dc = dm_kunit_alloc_dc_with_ctx(test);
-	link->ctx = dc->ctx;
+	link->ctx = dc_get_ctx(dc);
 
 	return link;
 }
@@ -87,14 +99,12 @@ struct amdgpu_display_manager *dm_kunit_alloc_dm(struct kunit *test)
 	dm = kunit_kzalloc(test, sizeof(*dm), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, dm);
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
-
+	dc = dm_kunit_alloc_dc(test);
 	state = kunit_kzalloc(test, sizeof(*state), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, state);
 
 	dm->dc = dc;
-	dc->current_state = state;
+	dc_test_set_current_state(dc, state);
 
 	return dm;
 }
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_kunit_test_helpers.h b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_kunit_test_helpers.h
index 7d7bcd321775..b4bbf4a3750d 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_kunit_test_helpers.h
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_kunit_test_helpers.h
@@ -21,6 +21,7 @@ struct dc_stream_state;
 struct drm_device;
 
 struct amdgpu_device *dm_kunit_alloc_adev(struct kunit *test);
+struct dc *dm_kunit_alloc_dc(struct kunit *test);
 struct dc *dm_kunit_alloc_dc_with_ctx(struct kunit *test);
 struct dc_link *dm_kunit_alloc_link(struct kunit *test);
 struct dc_link *dm_kunit_alloc_link_with_ctx(struct kunit *test);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_mst_types_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_mst_types_test.c
index e624eb55cae1..b8ea85846872 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_mst_types_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_mst_types_test.c
@@ -23,6 +23,7 @@
 #include <drm/display/drm_dp_mst_helper.h>
 
 #include "dc.h"
+#include "dc_test.h"
 #include "dpcd_defs.h"
 #include "dmub_cmd.h"
 #include "amdgpu.h"
@@ -83,7 +84,7 @@ static void dm_mst_test_setup_dm_aux(struct amdgpu_dm_dp_aux *dm_aux,
 	dm_mst_test_aux_transfer_raw_reply = 0;
 	dm_mst_test_aux_transfer_raw_operation_result = AUX_RET_SUCCESS;
 	link_srv->aux_transfer_raw = dm_mst_test_aux_transfer_raw;
-	dc->link_srv = link_srv;
+	dc_test_install_link_service(dc, link_srv);
 	link->dc = dc;
 	ctx->driver_context = adev;
 	ddc->link = link;
@@ -137,7 +138,7 @@ static struct amdgpu_dm_connector *dm_mst_test_alloc_sideband_connector(struct k
 	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
 	link = kunit_kzalloc(test, sizeof(*link), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	KUNIT_ASSERT_NOT_NULL(test, aconnector);
 	KUNIT_ASSERT_NOT_NULL(test, link_srv);
 	KUNIT_ASSERT_NOT_NULL(test, link);
@@ -145,7 +146,7 @@ static struct amdgpu_dm_connector *dm_mst_test_alloc_sideband_connector(struct k
 
 	mutex_init(&aconnector->handle_mst_msg_ready);
 	link_srv->get_status = dm_mst_test_get_status;
-	dc->link_srv = link_srv;
+	dc_test_install_link_service(dc, link_srv);
 	link->dc = dc;
 	link->dpcd_caps.dpcd_rev.raw = DPCD_REV_14;
 	link->link_status.dpcd_caps = &link->dpcd_caps;
@@ -341,14 +342,14 @@ static void dm_mst_test_pbn_divider_uses_link_bandwidth(struct kunit *test)
 
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
 	link = kunit_kzalloc(test, sizeof(*link), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	KUNIT_ASSERT_NOT_NULL(test, link_srv);
 	KUNIT_ASSERT_NOT_NULL(test, link);
 	KUNIT_ASSERT_NOT_NULL(test, dc);
 
 	link_srv->dp_get_verified_link_cap = dm_mst_test_dp_get_verified_link_cap;
 	link_srv->dp_link_bandwidth_kbps = dm_mst_test_dp_link_bandwidth_kbps;
-	dc->link_srv = link_srv;
+	dc_test_install_link_service(dc, link_srv);
 	link->dc = dc;
 
 	KUNIT_EXPECT_EQ(test, dm_mst_get_pbn_divider(link),
@@ -624,7 +625,7 @@ static void dm_mst_test_aux_transfer_native_read(struct kunit *test)
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
 	ddc = kunit_kzalloc(test, sizeof(*ddc), GFP_KERNEL);
 	link = kunit_kzalloc(test, sizeof(*link), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, dm_aux);
@@ -675,7 +676,7 @@ static void dm_mst_test_aux_transfer_native_write(struct kunit *test)
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
 	ddc = kunit_kzalloc(test, sizeof(*ddc), GFP_KERNEL);
 	link = kunit_kzalloc(test, sizeof(*link), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, dm_aux);
@@ -727,7 +728,7 @@ static void dm_mst_test_aux_transfer_partial_write(struct kunit *test)
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
 	ddc = kunit_kzalloc(test, sizeof(*ddc), GFP_KERNEL);
 	link = kunit_kzalloc(test, sizeof(*link), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, dm_aux);
@@ -771,7 +772,7 @@ static void dm_mst_test_aux_transfer_error_result(struct kunit *test)
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
 	ddc = kunit_kzalloc(test, sizeof(*ddc), GFP_KERNEL);
 	link = kunit_kzalloc(test, sizeof(*link), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, dm_aux);
@@ -816,7 +817,7 @@ static void dm_mst_test_aux_transfer_hpd_discon_quirk(struct kunit *test)
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
 	ddc = kunit_kzalloc(test, sizeof(*ddc), GFP_KERNEL);
 	link = kunit_kzalloc(test, sizeof(*link), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, dm_aux);
@@ -870,7 +871,7 @@ static void dm_mst_test_aux_transfer_non_ack_reply(struct kunit *test)
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
 	ddc = kunit_kzalloc(test, sizeof(*ddc), GFP_KERNEL);
 	link = kunit_kzalloc(test, sizeof(*link), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
 	ctx = kunit_kzalloc(test, sizeof(*ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, dm_aux);
@@ -1196,14 +1197,14 @@ static void dm_mst_test_initialize_dp_connector_mst(struct kunit *test)
 
 	ddc = kunit_kzalloc(test, sizeof(*ddc), GFP_KERNEL);
 	link = dm_kunit_alloc_link(test);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ddc);
 	KUNIT_ASSERT_NOT_NULL(test, dc);
 	KUNIT_ASSERT_NOT_NULL(test, link_srv);
 
 	link_srv->dp_get_max_link_enc_cap = dm_mst_test_dp_get_max_link_enc_cap;
-	dc->link_srv = link_srv;
+	dc_test_install_link_service(dc, link_srv);
 	link->dc = dc;
 	link->ddc = ddc;
 
@@ -1656,7 +1657,7 @@ static void dm_mst_test_init_child(struct kunit *test, struct dm_mst_test_child
 	ret = drmm_mode_config_init(&adev->ddev);
 	KUNIT_ASSERT_EQ(test, ret, 0);
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	link_srv = kunit_kzalloc(test, sizeof(*link_srv), GFP_KERNEL);
 	child->port = kunit_kzalloc(test, sizeof(*child->port), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, dc);
@@ -1665,7 +1666,7 @@ static void dm_mst_test_init_child(struct kunit *test, struct dm_mst_test_child
 
 	link_srv->add_remote_sink = dm_mst_test_add_remote_sink;
 	link_srv->remove_remote_sink = dm_mst_test_remove_remote_sink;
-	dc->link_srv = link_srv;
+	dc_test_install_link_service(dc, link_srv);
 
 	child->adev = adev;
 	child->link = dm_kunit_alloc_link(test);
@@ -2519,7 +2520,7 @@ static void dm_mst_test_init_dsc_ctx(struct kunit *test, struct dm_mst_test_dsc_
 
 	dc = dm_kunit_alloc_dc_with_ctx(test);
 	ctx->link = dm_kunit_alloc_link(test);
-	ctx->link->ctx = dc->ctx;
+	ctx->link->ctx = dc_get_ctx(dc);
 
 	ctx->port = dm_mst_test_alloc_mgr_port(test);
 	ctx->port->parent = branch;
@@ -2680,14 +2681,14 @@ static void dm_mst_test_init_port_mode_ctx(struct kunit *test,
 	link_srv->dp_link_bandwidth_kbps = dm_mst_test_root_bandwidth_kbps;
 
 	ctx->dc = dm_kunit_alloc_dc_with_ctx(test);
-	ctx->dc->link_srv = link_srv;
-	ctx->dc->res_pool = res_pool;
+	dc_test_install_link_service(ctx->dc, link_srv);
+	dc_test_set_res_pool(ctx->dc, res_pool);
 
 	ctx->link = dm_kunit_alloc_link(test);
 	ctx->link->dc = ctx->dc;
-	ctx->link->ctx = ctx->dc->ctx;
+	ctx->link->ctx = dc_get_ctx(ctx->dc);
 
-	ctx->sink->ctx = ctx->dc->ctx;
+	ctx->sink->ctx = dc_get_ctx(ctx->dc);
 	ctx->port = dm_mst_test_alloc_mgr_port(test);
 	ctx->port->full_pbn = full_pbn;
 
@@ -2789,8 +2790,8 @@ static void dm_mst_test_setup_dsc_caps(struct kunit *test, struct dc *dc, struct
 	KUNIT_ASSERT_NOT_NULL(test, dsc);
 
 	dsc->funcs = &dm_mst_test_dsc_funcs;
-	dsc->ctx = dc->ctx;
-	dc->res_pool->dscs[0] = dsc;
+	dsc->ctx = dc_get_ctx(dc);
+	dc_get_res_pool(dc)->dscs[0] = dsc;
 
 	dec->is_dsc_supported = true;
 	dec->dsc_version = 0x21;
@@ -3026,8 +3027,8 @@ static struct amdgpu_dm_connector *dm_mst_test_alloc_frl_connector(struct kunit
 	link_srv->bw_kbps_from_raw_frl_link_rate_data = dm_mst_test_bw_kbps_from_raw_frl;
 
 	dc = dm_kunit_alloc_dc_with_ctx(test);
-	dc->link_srv = link_srv;
-	dc->caps.dp_hdmi21_pcon_support = pcon_support;
+	dc_test_install_link_service(dc, link_srv);
+	dc_test_caps(dc)->dp_hdmi21_pcon_support = pcon_support;
 
 	link = dm_kunit_alloc_link(test);
 	link->dc = dc;
@@ -3314,7 +3315,7 @@ static void dm_mst_test_init_recompute_ctx(struct kunit *test,
 	ctx->adev->ddev.mode_config.num_crtc = 1;
 
 	ctx->dc = dm_kunit_alloc_dc_with_ctx(test);
-	ctx->dc->current_state = dm_kunit_alloc_dc_state(test);
+	dc_test_set_current_state(ctx->dc, dm_kunit_alloc_dc_state(test));
 	ctx->dc_state = dm_kunit_alloc_dc_state(test);
 
 	ctx->link = dm_kunit_alloc_link(test);
@@ -3444,7 +3445,7 @@ static void dm_mst_test_recompute_unchanged_stream(struct kunit *test)
 
 	dm_mst_test_init_recompute_ctx(test, &ctx);
 	dm_mst_test_add_link_stream(test, ctx.dc_state, ctx.link, ctx.aconnector);
-	dm_mst_test_add_link_stream(test, ctx.dc->current_state, ctx.link, ctx.aconnector);
+	dm_mst_test_add_link_stream(test, dc_get_current_state(ctx.dc), ctx.link, ctx.aconnector);
 	ctx.crtc_state->enable = true;
 	ctx.crtc_state->active = true;
 
@@ -3466,7 +3467,7 @@ static void dm_mst_test_recompute_stream_removed(struct kunit *test)
 	dm_mst_test_init_recompute_ctx(test, &ctx);
 	gone = dm_kunit_alloc_connector(test, ctx.adev, ctx.link);
 	dm_mst_test_add_link_stream(test, ctx.dc_state, ctx.link, ctx.aconnector);
-	dm_mst_test_add_link_stream(test, ctx.dc->current_state, ctx.link, gone);
+	dm_mst_test_add_link_stream(test, dc_get_current_state(ctx.dc), ctx.link, gone);
 	ctx.crtc_state->enable = true;
 	ctx.crtc_state->active = true;
 
@@ -3500,7 +3501,7 @@ static void dm_mst_test_recompute_connector_without_crtc(struct kunit *test)
 
 	dm_mst_test_init_recompute_ctx(test, &ctx);
 	dm_mst_test_add_link_stream(test, ctx.dc_state, ctx.link, ctx.aconnector);
-	dm_mst_test_add_link_stream(test, ctx.dc->current_state, ctx.link, ctx.aconnector);
+	dm_mst_test_add_link_stream(test, dc_get_current_state(ctx.dc), ctx.link, ctx.aconnector);
 	ctx.conn_state->crtc = NULL;
 
 	KUNIT_EXPECT_FALSE(test, is_dsc_need_re_compute(ctx.state, ctx.dc_state, ctx.link));
@@ -3544,13 +3545,13 @@ dm_mst_test_add_mst_dsc_stream(struct kunit *test, struct dm_mst_test_recompute_
 
 	funcs->remove_stream_from_ctx = remove_stream;
 	res_pool->funcs = funcs;
-	ctx->dc->res_pool = res_pool;
+	dc_test_set_res_pool(ctx->dc, res_pool);
 	sink->dsc_caps.dsc_dec_caps.is_dsc_supported = true;
 	ctx->aconnector->dc_sink = sink;
 	ctx->aconnector->mst_output_port = port;
 
 	stream = dm_mst_test_add_link_stream(test, ctx->dc_state, ctx->link, ctx->aconnector);
-	stream->ctx = ctx->dc->ctx;
+	stream->ctx = dc_get_ctx(ctx->dc);
 	stream->signal = SIGNAL_TYPE_DISPLAY_PORT_MST;
 
 	return stream;
@@ -3568,7 +3569,7 @@ static void dm_mst_test_compute_configs_skips_sst(struct kunit *test)
 
 	dm_mst_test_init_recompute_ctx(test, &ctx);
 	stream = dm_mst_test_add_link_stream(test, ctx.dc_state, ctx.link, ctx.aconnector);
-	stream->ctx = ctx.dc->ctx;
+	stream->ctx = dc_get_ctx(ctx.dc);
 	stream->signal = SIGNAL_TYPE_DISPLAY_PORT;
 
 	KUNIT_EXPECT_EQ(test, compute_mst_dsc_configs_for_state(ctx.state, ctx.dc_state, vars), 0);
@@ -3589,7 +3590,7 @@ static void dm_mst_test_compute_configs_skips_incomplete(struct kunit *test)
 
 	dm_mst_test_init_recompute_ctx(test, &ctx);
 	stream = dm_mst_test_add_link_stream(test, ctx.dc_state, ctx.link, ctx.aconnector);
-	stream->ctx = ctx.dc->ctx;
+	stream->ctx = dc_get_ctx(ctx.dc);
 	stream->signal = SIGNAL_TYPE_DISPLAY_PORT_MST;
 
 	KUNIT_EXPECT_EQ(test, compute_mst_dsc_configs_for_state(ctx.state, ctx.dc_state, vars), 0);
@@ -3663,7 +3664,7 @@ static void dm_mst_test_pre_compute_configs_skips_sst(struct kunit *test)
 
 	dm_mst_test_init_recompute_ctx(test, &ctx);
 	stream = dm_mst_test_add_link_stream(test, ctx.dc_state, ctx.link, ctx.aconnector);
-	stream->ctx = ctx.dc->ctx;
+	stream->ctx = dc_get_ctx(ctx.dc);
 	stream->signal = SIGNAL_TYPE_DISPLAY_PORT;
 
 	KUNIT_EXPECT_EQ(test, pre_compute_mst_dsc_configs_for_state(ctx.state, ctx.dc_state, vars), 0);
@@ -3681,7 +3682,7 @@ static void dm_mst_test_pre_compute_configs_skips_incomplete(struct kunit *test)
 
 	dm_mst_test_init_recompute_ctx(test, &ctx);
 	stream = dm_mst_test_add_link_stream(test, ctx.dc_state, ctx.link, ctx.aconnector);
-	stream->ctx = ctx.dc->ctx;
+	stream->ctx = dc_get_ctx(ctx.dc);
 	stream->signal = SIGNAL_TYPE_DISPLAY_PORT_MST;
 
 	KUNIT_EXPECT_EQ(test, pre_compute_mst_dsc_configs_for_state(ctx.state, ctx.dc_state, vars), 0);
@@ -3846,16 +3847,16 @@ dm_mst_test_alloc_dsc_link_ctx(struct kunit *test, int total_avail_slots)
 	link_srv->mst_decide_link_encoding_format = dm_mst_test_mst_encoding_format;
 
 	dc = dm_kunit_alloc_dc_with_ctx(test);
-	dc->link_srv = link_srv;
-	dc->res_pool = res_pool;
-	dc->current_state = dm_kunit_alloc_dc_state(test);
+	dc_test_install_link_service(dc, link_srv);
+	dc_test_set_res_pool(dc, res_pool);
+	dc_test_set_current_state(dc, dm_kunit_alloc_dc_state(test));
 
 	link = dm_kunit_alloc_link(test);
 	link->dc = dc;
-	link->ctx = dc->ctx;
+	link->ctx = dc_get_ctx(dc);
 	link->type = dc_connection_mst_branch;
 
-	sink->ctx = dc->ctx;
+	sink->ctx = dc_get_ctx(dc);
 	dm_mst_test_setup_dsc_caps(test, dc, sink);
 
 	/* The payload allocation takes a reference, so start above zero. */
@@ -3870,7 +3871,7 @@ dm_mst_test_alloc_dsc_link_ctx(struct kunit *test, int total_avail_slots)
 
 	ctx->dc_state = dm_kunit_alloc_dc_state(test);
 	ctx->stream = dm_kunit_alloc_stream(test, link);
-	ctx->stream->ctx = dc->ctx;
+	ctx->stream->ctx = dc_get_ctx(dc);
 	ctx->stream->sink = sink;
 	ctx->stream->dm_stream_context = ctx->aconnector;
 	ctx->stream->signal = SIGNAL_TYPE_DISPLAY_PORT_MST;
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_plane_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_plane_test.c
index 7422e8ba9564..0d8fd26bb0ac 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_plane_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_plane_test.c
@@ -18,6 +18,7 @@
 #include <drm/drm_mode_config.h>
 #include <drm/drm_plane.h>
 #include <drm/drm_property.h>
+#include "dc_test.h"
 
 struct dm_test_dcc_cap_ctx {
 	bool callback_ret;
@@ -364,19 +365,19 @@ static void dm_test_get_min_max_dc_plane_scaling(struct kunit *test)
 	int max_upscale = 0;
 
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	fb = kunit_kzalloc(test, sizeof(*fb), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, adev);
 	KUNIT_ASSERT_NOT_NULL(test, dc);
 	KUNIT_ASSERT_NOT_NULL(test, fb);
 
 	adev->dm.dc = dc;
-	dc->caps.planes[0].max_upscale_factor.nv12 = 1;
-	dc->caps.planes[0].max_downscale_factor.nv12 = 1;
-	dc->caps.planes[0].max_upscale_factor.argb8888 = 1600;
-	dc->caps.planes[0].max_downscale_factor.argb8888 = 250;
-	dc->caps.planes[0].max_upscale_factor.fp16 = 2000;
-	dc->caps.planes[0].max_downscale_factor.fp16 = 500;
+	dc_test_caps(dc)->planes[0].max_upscale_factor.nv12 = 1;
+	dc_test_caps(dc)->planes[0].max_downscale_factor.nv12 = 1;
+	dc_test_caps(dc)->planes[0].max_upscale_factor.argb8888 = 1600;
+	dc_test_caps(dc)->planes[0].max_downscale_factor.argb8888 = 250;
+	dc_test_caps(dc)->planes[0].max_upscale_factor.fp16 = 2000;
+	dc_test_caps(dc)->planes[0].max_downscale_factor.fp16 = 500;
 
 	fb->format = drm_format_info(DRM_FORMAT_NV12);
 	KUNIT_ASSERT_NOT_NULL(test, fb->format);
@@ -688,7 +689,7 @@ static void dm_test_validate_dcc_rejects_from_cap(struct kunit *test)
 		dm_test_init_validate_dcc_inputs(&adev, &dc, &tiling_info, &dcc, &address,
 						 &plane_size, test);
 		dcc.independent_64b_blks = cases[i].independent_64b_blks;
-		dc->cap_funcs.get_dcc_compression_cap = dm_test_get_dcc_compression_cap;
+		dc_test_cap_funcs(dc)->get_dcc_compression_cap = dm_test_get_dcc_compression_cap;
 		dm_test_dcc_ctx = &ctx;
 
 		ret = amdgpu_dm_plane_validate_dcc(adev, SURFACE_PIXEL_FORMAT_GRPH_ARGB8888,
@@ -723,7 +724,7 @@ static void dm_test_validate_dcc_success_and_scan_mapping(struct kunit *test)
 
 	dm_test_init_validate_dcc_inputs(&adev, &dc, &tiling_info, &dcc, &address,
 					 &plane_size, test);
-	dc->cap_funcs.get_dcc_compression_cap = dm_test_get_dcc_compression_cap;
+	dc_test_cap_funcs(dc)->get_dcc_compression_cap = dm_test_get_dcc_compression_cap;
 	dm_test_dcc_ctx = &ctx;
 
 	KUNIT_EXPECT_EQ(test,
@@ -1103,7 +1104,7 @@ static void dm_test_setup_gfx9_dcc_device(struct amdgpu_device *adev,
 	adev->gfx.config.gb_addr_config_fields.num_pipes = 2;
 	adev->gfx.config.gb_addr_config_fields.num_pkrs = 2;
 	adev->ip_versions[GC_HWIP][0] = IP_VERSION(10, 3, 0);
-	dc->cap_funcs.get_dcc_compression_cap = dm_test_get_dcc_compression_cap;
+	dc_test_cap_funcs(dc)->get_dcc_compression_cap = dm_test_get_dcc_compression_cap;
 	ctx->callback_ret = true;
 	ctx->capable = true;
 	ctx->output_independent_64b_blks = output_independent_64b_blks;
@@ -1406,7 +1407,7 @@ static void dm_test_fill_gfx9_plane_attributes_dcc(struct kunit *test)
 	int ret;
 
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	afb = kunit_kzalloc(test, sizeof(*afb), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, adev);
 	KUNIT_ASSERT_NOT_NULL(test, dc);
@@ -1417,7 +1418,7 @@ static void dm_test_fill_gfx9_plane_attributes_dcc(struct kunit *test)
 	adev->gfx.config.gb_addr_config_fields.num_pipes = 2;
 	adev->gfx.config.gb_addr_config_fields.num_pkrs = 2;
 	adev->ip_versions[GC_HWIP][0] = IP_VERSION(10, 3, 0);
-	dc->cap_funcs.get_dcc_compression_cap = dm_test_get_dcc_compression_cap;
+	dc_test_cap_funcs(dc)->get_dcc_compression_cap = dm_test_get_dcc_compression_cap;
 	dm_test_dcc_ctx = &ctx;
 
 	afb->base.pitches[1] = 256;
@@ -1460,7 +1461,7 @@ static void dm_test_fill_gfx9_plane_attributes_validate_fails(struct kunit *test
 	int ret;
 
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	afb = kunit_kzalloc(test, sizeof(*afb), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, adev);
 	KUNIT_ASSERT_NOT_NULL(test, dc);
@@ -1511,7 +1512,7 @@ static void dm_test_fill_gfx9_plane_attributes_dcc_ind_blk(struct kunit *test)
 	unsigned int i;
 
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	afb = kunit_kzalloc(test, sizeof(*afb), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, adev);
 	KUNIT_ASSERT_NOT_NULL(test, dc);
@@ -1575,7 +1576,7 @@ static void dm_test_fill_gfx12_plane_attributes_dcc_blocks(struct kunit *test)
 	unsigned int i;
 
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	afb = kunit_kzalloc(test, sizeof(*afb), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, adev);
 	KUNIT_ASSERT_NOT_NULL(test, dc);
@@ -1583,7 +1584,7 @@ static void dm_test_fill_gfx12_plane_attributes_dcc_blocks(struct kunit *test)
 
 	adev->family = AMDGPU_FAMILY_GC_12_0_0;
 	adev->dm.dc = dc;
-	dc->cap_funcs.get_dcc_compression_cap = dm_test_get_dcc_compression_cap;
+	dc_test_cap_funcs(dc)->get_dcc_compression_cap = dm_test_get_dcc_compression_cap;
 	plane_size.surface_size.width = 1920;
 	plane_size.surface_size.height = 1080;
 
@@ -1635,7 +1636,7 @@ static void dm_test_fill_gfx12_plane_attributes_validate_fails(struct kunit *tes
 	int ret;
 
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	afb = kunit_kzalloc(test, sizeof(*afb), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, adev);
 	KUNIT_ASSERT_NOT_NULL(test, dc);
@@ -1726,7 +1727,7 @@ static void dm_test_fill_plane_buffer_attributes_gfx12(struct kunit *test)
 	int ret;
 
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	afb = kunit_kzalloc(test, sizeof(*afb), GFP_KERNEL);
 	tiling_info = (struct dc_tiling_info){0};
 	plane_size = (struct plane_size){0};
@@ -1772,7 +1773,7 @@ static void dm_test_helper_check_state_scaling_caps(struct kunit *test)
 	struct drm_framebuffer *fb;
 
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	plane = kunit_kzalloc(test, sizeof(*plane), GFP_KERNEL);
 	state = kunit_kzalloc(test, sizeof(*state), GFP_KERNEL);
 	crtc = kunit_kzalloc(test, sizeof(*crtc), GFP_KERNEL);
@@ -1787,8 +1788,8 @@ static void dm_test_helper_check_state_scaling_caps(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, fb);
 
 	adev->dm.dc = dc;
-	dc->caps.planes[0].max_upscale_factor.argb8888 = 1;
-	dc->caps.planes[0].max_downscale_factor.argb8888 = 1;
+	dc_test_caps(dc)->planes[0].max_upscale_factor.argb8888 = 1;
+	dc_test_caps(dc)->planes[0].max_downscale_factor.argb8888 = 1;
 
 	plane->type = DRM_PLANE_TYPE_OVERLAY;
 	plane->dev = &adev->ddev;
@@ -1873,7 +1874,7 @@ static void dm_test_fill_dc_scaling_info_plane_caps(struct kunit *test)
 	struct dc_scaling_info info = {0};
 
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	plane = kunit_kzalloc(test, sizeof(*plane), GFP_KERNEL);
 	state = kunit_kzalloc(test, sizeof(*state), GFP_KERNEL);
 	fb = kunit_kzalloc(test, sizeof(*fb), GFP_KERNEL);
@@ -1884,8 +1885,8 @@ static void dm_test_fill_dc_scaling_info_plane_caps(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, fb);
 
 	adev->dm.dc = dc;
-	dc->caps.planes[0].max_upscale_factor.argb8888 = 16000;
-	dc->caps.planes[0].max_downscale_factor.argb8888 = 250;
+	dc_test_caps(dc)->planes[0].max_upscale_factor.argb8888 = 16000;
+	dc_test_caps(dc)->planes[0].max_downscale_factor.argb8888 = 250;
 
 	plane->dev = &adev->ddev;
 	fb->format = drm_format_info(DRM_FORMAT_XRGB8888);
@@ -2025,7 +2026,7 @@ static struct amdgpu_device *dm_test_init_atomic_check_state(struct kunit *test,
 	struct drm_crtc *crtc;
 
 	adev = kunit_kzalloc(test, sizeof(*adev), GFP_KERNEL);
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
+	dc = dm_kunit_alloc_dc(test);
 	*state = kunit_kzalloc(test, sizeof(**state), GFP_KERNEL);
 	planes = kunit_kzalloc(test, sizeof(*planes), GFP_KERNEL);
 	crtcs = kunit_kzalloc(test, sizeof(*crtcs), GFP_KERNEL);
@@ -2048,10 +2049,10 @@ static struct amdgpu_device *dm_test_init_atomic_check_state(struct kunit *test,
 	KUNIT_ASSERT_NOT_NULL(test, *fb);
 
 	adev->dm.dc = dc;
-	dc->caps.planes[0].max_upscale_factor.argb8888 = 1000;
-	dc->caps.planes[0].max_downscale_factor.argb8888 = 1000;
-	dc->caps.planes[0].max_upscale_factor.nv12 = 1000;
-	dc->caps.planes[0].max_downscale_factor.nv12 = 1000;
+	dc_test_caps(dc)->planes[0].max_upscale_factor.argb8888 = 1000;
+	dc_test_caps(dc)->planes[0].max_downscale_factor.argb8888 = 1000;
+	dc_test_caps(dc)->planes[0].max_upscale_factor.nv12 = 1000;
+	dc_test_caps(dc)->planes[0].max_downscale_factor.nv12 = 1000;
 
 	(*plane)->dev = &adev->ddev;
 	(*plane)->index = 0;
@@ -3009,7 +3010,7 @@ static void dm_test_atomic_check_success(struct kunit *test)
 	res_pool->funcs = kunit_kzalloc(test, sizeof(*res_pool->funcs), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, res_pool->funcs);
 
-	adev->dm.dc->res_pool = res_pool;
+	dc_test_set_res_pool(adev->dm.dc, res_pool);
 
 	dm_plane_state->dc_state->src_rect.width = 100;
 	dm_plane_state->dc_state->src_rect.height = 100;
@@ -3107,7 +3108,7 @@ static void dm_test_handle_cursor_update_no_stream(struct kunit *test)
 	struct dm_test_cursor_ctx *ctx = dm_test_alloc_cursor_ctx(test);
 
 	ctx->crtc_state->cm_is_degamma_srgb = true;
-	ctx->adev->dm.dc->caps.color.dpp.gamma_corr = true;
+	dc_test_caps(ctx->adev->dm.dc)->color.dpp.gamma_corr = true;
 
 	amdgpu_dm_plane_handle_cursor_update(ctx->plane, &ctx->old_state);
 
@@ -3153,11 +3154,11 @@ static void dm_test_panic_flush_disables_dcc(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, res_pool);
 
 	dc = dm_kunit_alloc_dc_with_ctx(test);
-	dc->current_state = dm_kunit_alloc_dc_state(test);
-	dc->hwss.clear_surface_dcc_and_tiling = dm_test_clear_surface_dcc_and_tiling;
+	dc_test_set_current_state(dc, dm_kunit_alloc_dc_state(test));
+	dc_test_hwss(dc)->clear_surface_dcc_and_tiling = dm_test_clear_surface_dcc_and_tiling;
 	res_pool->pipe_count = 1;
-	dc->res_pool = res_pool;
-	dc_plane_state->ctx = dc->ctx;
+	dc_test_set_res_pool(dc, res_pool);
+	dc_plane_state->ctx = dc_get_ctx(dc);
 
 	fb->modifier = AMD_FMT_MOD;
 	dm_plane_state->base.fb = fb;
@@ -3231,7 +3232,7 @@ static void dm_test_plane_init_creates_color_pipeline(struct kunit *test)
 	struct drm_plane *plane;
 
 	plane = dm_test_alloc_init_plane(test, &adev);
-	adev->dm.dc->ctx->dce_version = DCN_VERSION_3_0;
+	dc_get_ctx(adev->dm.dc)->dce_version = DCN_VERSION_3_0;
 
 	KUNIT_ASSERT_EQ(test, amdgpu_dm_plane_init(&adev->dm, plane, 1, NULL), 0);
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_psr_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_psr_test.c
index 0a484ea7c0e8..8b9e34b3c4be 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_psr_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_psr_test.c
@@ -8,6 +8,7 @@
 #include <kunit/test.h>
 
 #include "dc.h"
+#include "dc_test.h"
 #include "core_types.h"
 #include "amdgpu_mode.h"
 #include "amdgpu_dm.h"
@@ -50,7 +51,7 @@ static struct dc_link *alloc_test_psrsu_link(struct kunit *test)
 	struct dc_context *ctx = link->ctx;
 	struct dc *dc = ctx->dc;
 
-	dc->caps.dmcub_support = true;
+	dc_test_caps(dc)->dmcub_support = true;
 	ctx->dce_version = DCN_VERSION_3_1;
 	link->dpcd_caps.edp_rev = DP_EDP_14;
 	link->dpcd_caps.psr_info.psr_version = DP_PSR2_WITH_Y_COORD_ET_SUPPORTED;
@@ -64,7 +65,7 @@ static struct dc_link *alloc_test_psr_caps_link(struct kunit *test)
 {
 	struct dc_link *link = alloc_test_psrsu_link(test);
 
-	link->ctx->dc->caps.dmub_caps.psr = true;
+	dc_test_caps(link->ctx->dc)->dmub_caps.psr = true;
 	link->connector_signal = SIGNAL_TYPE_EDP;
 	link->type = dc_connection_single;
 
@@ -91,7 +92,7 @@ static void dm_test_link_supports_psrsu_no_dmcub(struct kunit *test)
 {
 	struct dc_link *link = alloc_test_psrsu_link(test);
 
-	link->ctx->dc->caps.dmcub_support = false;
+	dc_test_caps(link->ctx->dc)->dmcub_support = false;
 
 	KUNIT_EXPECT_FALSE(test, link_supports_psrsu(link));
 }
@@ -232,7 +233,7 @@ static void dm_test_set_psr_caps_no_dmub_psr(struct kunit *test)
 	struct amdgpu_dm_connector *aconnector = alloc_test_aconnector(test);
 
 	link->psr_settings.psr_version = DC_PSR_VERSION_1;
-	link->ctx->dc->caps.dmub_caps.psr = false;
+	dc_test_caps(link->ctx->dc)->dmub_caps.psr = false;
 
 	KUNIT_EXPECT_FALSE(test, amdgpu_dm_set_psr_caps(link, aconnector));
 	KUNIT_EXPECT_EQ(test, link->psr_settings.psr_version,
@@ -293,9 +294,9 @@ static void dm_test_set_psr_caps_edp1_disabled(struct kunit *test)
 	struct dc *dc = link->ctx->dc;
 
 	edp0->connector_signal = SIGNAL_TYPE_EDP;
-	dc->links[0] = edp0;
-	dc->links[1] = link;
-	dc->link_count = 2;
+	dc_test_set_link(dc, 0, edp0);
+	dc_test_set_link(dc, 1, link);
+	dc_test_set_link_count(dc, 2);
 
 	KUNIT_EXPECT_FALSE(test, amdgpu_dm_set_psr_caps(link, aconnector));
 }
@@ -647,7 +648,7 @@ static void dm_test_psr_is_active_allowed_no_streams(struct kunit *test)
 static void dm_test_psr_is_active_allowed_null_link(struct kunit *test)
 {
 	struct amdgpu_display_manager *dm = dm_kunit_alloc_dm(test);
-	struct dc_state *state = dm->dc->current_state;
+	struct dc_state *state = dc_get_current_state(dm->dc);
 
 	dm_kunit_add_stream_to_state(test, state, 0, NULL);
 
@@ -662,7 +663,7 @@ static void dm_test_psr_is_active_allowed_null_link(struct kunit *test)
 static void dm_test_psr_is_active_allowed_requires_enabled_and_allowed(struct kunit *test)
 {
 	struct amdgpu_display_manager *dm = dm_kunit_alloc_dm(test);
-	struct dc_state *state = dm->dc->current_state;
+	struct dc_state *state = dc_get_current_state(dm->dc);
 	struct dc_link *link = dm_kunit_alloc_link(test);
 
 	dm_kunit_add_stream_to_state(test, state, 0, link);
@@ -682,7 +683,7 @@ static void dm_test_psr_is_active_allowed_requires_enabled_and_allowed(struct ku
 static void dm_test_psr_is_active_allowed_any_stream(struct kunit *test)
 {
 	struct amdgpu_display_manager *dm = dm_kunit_alloc_dm(test);
-	struct dc_state *state = dm->dc->current_state;
+	struct dc_state *state = dc_get_current_state(dm->dc);
 	struct dc_link *disabled_link = dm_kunit_alloc_link(test);
 	struct dc_link *allowed_link = dm_kunit_alloc_link(test);
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
index c375ee68778b..c0dbab0b7c46 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
@@ -22,6 +22,7 @@
 #include <drm/drm_writeback.h>
 
 #include "dc.h"
+#include "dc_test.h"
 #include "dc/dc_dmub_srv.h"
 #include "dal_asic_id.h"
 #include "dm_services_types.h"
@@ -1279,13 +1280,13 @@ static void dm_test_crtc_with_stream(struct kunit *test,
 	logger = kunit_kzalloc(test, sizeof(*logger), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, logger);
 	logger->dev = &adev->ddev;
-	dc->ctx->logger = logger;
+	dc_get_ctx(dc)->logger = logger;
 
-	dc->current_state = dm_kunit_alloc_dc_state(test);
-	KUNIT_ASSERT_NOT_NULL(test, dc->current_state);
+	dc_test_set_current_state(dc, dm_kunit_alloc_dc_state(test));
+	KUNIT_ASSERT_NOT_NULL(test, dc_get_current_state(dc));
 
 	stream = dm_kunit_alloc_stream(test, NULL);
-	stream->ctx = dc->ctx;
+	stream->ctx = dc_get_ctx(dc);
 
 	adev->dm.dc = dc;
 	adev->mode_info.num_crtc = 1;
@@ -1337,8 +1338,8 @@ static void dm_test_crtc_get_scanoutpos_exits_idle(struct kunit *test)
 	u32 position = 0;
 
 	dm_test_crtc_with_stream(test, adev, dc);
-	dc->caps.ips_support = true;
-	dc->idle_optimizations_allowed = true;
+	dc_test_caps(dc)->ips_support = true;
+	dc_test_set_idle_optimizations_allowed(dc, true);
 
 	KUNIT_EXPECT_EQ(test, dm_crtc_get_scanoutpos(adev, 0, &vbl, &position), 0);
 }
@@ -2940,8 +2941,8 @@ static struct dc_link *dm_test_dc_with_link(struct kunit *test,
 	struct dc *dc = dm_kunit_alloc_dc_with_ctx(test);
 	struct dc_link *link = dm_kunit_alloc_link(test);
 
-	dc->links[0] = link;
-	dc->link_count = 1;
+	dc_test_set_link(dc, 0, link);
+	dc_test_set_link_count(dc, 1);
 	adev->dm.dc = dc;
 
 	return link;
@@ -2967,7 +2968,7 @@ static void dm_test_dump_links_with_sinks(struct kunit *test)
 	link->local_sink = local_sink;
 	link->sink_count = 1;
 	link->remote_sinks[0] = remote_sink;
-	adev->dm.dc->link_count = 2;
+	dc_test_set_link_count(adev->dm.dc, 2);
 
 	amdgpu_dm_dump_links_and_sinks(adev);
 }
@@ -3328,7 +3329,7 @@ static void dm_test_trigger_timing_sync_streams(struct kunit *test)
 
 	context->streams[0] = stream;
 	context->stream_count = 1;
-	dc->current_state = context;
+	dc_test_set_current_state(dc, context);
 	adev->dm.dc = dc;
 	adev->dm.force_timing_sync = true;
 	mutex_init(&adev->dm.dc_lock);
@@ -3387,8 +3388,8 @@ static void dm_test_oem_i2c_hw_init_no_device(struct kunit *test)
 	struct amdgpu_device *adev = dm_kunit_alloc_adev(test);
 	struct dc *dc = dm_kunit_alloc_dc_with_ctx(test);
 
-	dc->res_pool = kunit_kzalloc(test, sizeof(*dc->res_pool), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc->res_pool);
+	dc_test_set_res_pool(dc, kunit_kzalloc(test, sizeof(*dc_get_res_pool(dc)), GFP_KERNEL));
+	KUNIT_ASSERT_NOT_NULL(test, dc_get_res_pool(dc));
 	adev->dm.dc = dc;
 
 	KUNIT_EXPECT_EQ(test, dm_oem_i2c_hw_init(adev), 0);
@@ -4471,8 +4472,8 @@ static void dm_test_commit_zero_streams_empty(struct kunit *test)
 {
 	struct dc *dc = dm_kunit_alloc_dc_with_ctx(test);
 
-	dc->current_state = dm_kunit_alloc_dc_state(test);
-	KUNIT_ASSERT_NOT_NULL(test, dc->current_state);
+	dc_test_set_current_state(dc, dm_kunit_alloc_dc_state(test));
+	KUNIT_ASSERT_NOT_NULL(test, dc_get_current_state(dc));
 
 	KUNIT_EXPECT_EQ(test, (int)amdgpu_dm_commit_zero_streams(dc), (int)DC_OK);
 }
@@ -4550,7 +4551,7 @@ static void dm_test_clear_writeback_removes_stream(struct kunit *test)
 	acrtc = kunit_kzalloc(test, sizeof(*acrtc), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, acrtc);
 	stream = dm_kunit_alloc_stream(test, NULL);
-	dm->dc->hwss.update_bandwidth = dm_test_update_bandwidth;
+	dc_test_hwss(dm->dc)->update_bandwidth = dm_test_update_bandwidth;
 	crtc_state->stream = stream;
 	stream->num_wb_info = 1;
 	stream->writeback_info[0].dwb_pipe_inst = 0;
@@ -4588,7 +4589,7 @@ static void dm_test_set_writeback_no_pipe(struct kunit *test)
 	acrtc = kunit_kzalloc(test, sizeof(*acrtc), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, acrtc);
 	dc = dm_kunit_alloc_dc_with_ctx(test);
-	dc->current_state = dm_kunit_alloc_dc_state(test);
+	dc_test_set_current_state(dc, dm_kunit_alloc_dc_state(test));
 
 	adev->dm.adev = adev;
 	adev->dm.dc = dc;
@@ -4735,8 +4736,8 @@ dm_test_plane_attr_ctx_alloc(struct kunit *test, u32 drm_format)
 
 	ctx->adev = dm_kunit_alloc_adev(test);
 	ctx->adev->dm.dc = dm_kunit_alloc_dc_with_ctx(test);
-	ctx->adev->dm.dc->caps.planes[0].max_upscale_factor.argb8888 = 1;
-	ctx->adev->dm.dc->caps.planes[0].max_downscale_factor.argb8888 = 1;
+	dc_test_caps(ctx->adev->dm.dc)->planes[0].max_upscale_factor.argb8888 = 1;
+	dc_test_caps(ctx->adev->dm.dc)->planes[0].max_downscale_factor.argb8888 = 1;
 
 	ctx->crtc_state->stream = dm_kunit_alloc_stream(test, NULL);
 	/* Colour management resolves the device through the commit backpointer. */
@@ -4821,7 +4822,7 @@ static void dm_test_plane_attributes_bad_color_mgmt(struct kunit *test)
 	/* A 3D LUT that is not a perfect cube fails validation. */
 	blob->data = lut;
 	blob->length = 16 * sizeof(*lut);
-	ctx->adev->dm.dc->caps.color.dpp.hw_3d_lut = true;
+	dc_test_caps(ctx->adev->dm.dc)->color.dpp.hw_3d_lut = true;
 	ctx->plane->dm_plane_state->lut3d = blob;
 
 	KUNIT_EXPECT_EQ(test, dm_test_fill_plane_attr(ctx), -EINVAL);
@@ -4980,8 +4981,8 @@ static struct amdgpu_device *dm_test_late_init_adev(struct kunit *test)
 	struct amdgpu_device *adev = dm_kunit_alloc_adev(test);
 	struct dc *dc = dm_kunit_alloc_dc_with_ctx(test);
 
-	dc->res_pool = kunit_kzalloc(test, sizeof(*dc->res_pool), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc->res_pool);
+	dc_test_set_res_pool(dc, kunit_kzalloc(test, sizeof(*dc_get_res_pool(dc)), GFP_KERNEL));
+	KUNIT_ASSERT_NOT_NULL(test, dc_get_res_pool(dc));
 	adev->dm.dc = dc;
 
 	return adev;
@@ -5044,7 +5045,7 @@ static void dm_test_late_init_boot_crc_disabled(struct kunit *test)
 	dm_test_fw_boot_options.bits.bootcrc_en_at_S0i3 = 0;
 	dmub->hw_funcs.get_fw_boot_option = dm_test_get_fw_boot_option;
 	dmub_srv->dmub = dmub;
-	adev->dm.dc->ctx->dmub_srv = dmub_srv;
+	dc_get_ctx(adev->dm.dc)->dmub_srv = dmub_srv;
 	adev->ip_versions[DCE_HWIP][0] = IP_VERSION(3, 6, 0);
 
 	KUNIT_EXPECT_EQ(test, dm_test_run_late_init(adev), 0);
@@ -5074,8 +5075,8 @@ static struct amdgpu_device *dm_test_mode_config_adev(struct kunit *test)
 	long saved_audio = amdgpu_dm_audio_get_param();
 
 	adev->dm.dc = dm_kunit_alloc_dc_with_ctx(test);
-	adev->dm.dc->current_state = dm_kunit_alloc_dc_state(test);
-	KUNIT_ASSERT_NOT_NULL(test, adev->dm.dc->current_state);
+	dc_test_set_current_state(adev->dm.dc, dm_kunit_alloc_dc_state(test));
+	KUNIT_ASSERT_NOT_NULL(test, dc_get_current_state(adev->dm.dc));
 
 	amdgpu_dm_audio_set_param(0);
 	KUNIT_ASSERT_EQ(test, kunit_add_action_or_reset(test, dm_test_restore_audio_param,
@@ -5141,7 +5142,7 @@ static void dm_test_initialize_plane_primary(struct kunit *test)
 	adev->family = AMDGPU_FAMILY_NV;
 	adev->dm.adev = adev;
 	adev->dm.dc = dm_kunit_alloc_dc_with_ctx(test);
-	adev->dm.dc->caps.max_streams = 1;
+	dc_test_caps(adev->dm.dc)->max_streams = 1;
 
 	KUNIT_ASSERT_EQ(test, initialize_plane(&adev->dm, mode_info, 0,
 					       DRM_PLANE_TYPE_PRIMARY, NULL), 0);
@@ -5167,7 +5168,7 @@ static void dm_test_initialize_plane_overlay(struct kunit *test)
 	adev->family = AMDGPU_FAMILY_NV;
 	adev->dm.adev = adev;
 	adev->dm.dc = dm_kunit_alloc_dc_with_ctx(test);
-	adev->dm.dc->caps.max_streams = 1;
+	dc_test_caps(adev->dm.dc)->max_streams = 1;
 	plane_cap->per_pixel_alpha = true;
 	plane_cap->pixel_format_support.nv12 = true;
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_wb_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_wb_test.c
index 047ac88cb2a9..d43f150704d1 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_wb_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_wb_test.c
@@ -18,6 +18,7 @@
 #include <drm/drm_writeback.h>
 
 #include "dc.h"
+#include "dc_test.h"
 #include "amdgpu.h"
 #include "amdgpu_dm.h"
 #include "amdgpu_dm_wb.h"
@@ -495,13 +496,12 @@ static void dm_test_wb_connector_init_success(struct kunit *test)
 	dm = &adev->dm;
 	dm->adev = adev;
 
-	dc = kunit_kzalloc(test, sizeof(*dc), GFP_KERNEL);
-	KUNIT_ASSERT_NOT_NULL(test, dc);
+	dc = dm_kunit_alloc_dc(test);
 
 	link = kunit_kzalloc(test, sizeof(*link), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, link);
 
-	dc->links[0] = link;
+	dc_test_set_link(dc, 0, link);
 	dm->dc = dc;
 
 	ret = amdgpu_dm_wb_connector_init(dm, wbcon, 0);
diff --git a/drivers/gpu/drm/amd/display/dc/Makefile b/drivers/gpu/drm/amd/display/dc/Makefile
index 0f39a15dfc60..440f5d358188 100644
--- a/drivers/gpu/drm/amd/display/dc/Makefile
+++ b/drivers/gpu/drm/amd/display/dc/Makefile
@@ -92,5 +92,9 @@ FILES += bls_executor/bls_executor.o
 FILES += workaround_manager/workaround_manager.o
 FILES += dmub_messenger/dmub_messenger.o
 
+ifneq ($(CONFIG_DRM_AMD_DC_KUNIT_TEST),)
+FILES += core/dc_test.o
+endif
+
 AMD_DISPLAY_FILES += $(addprefix $(AMDDALPATH)/dc/, $(FILES))
 
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c b/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c
index 2803471d7333..4c583d452446 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c
@@ -31,6 +31,7 @@
  * mapping stays obvious and auditable.
  */
 #include "dc.h"
+#include "dm_helpers.h"	/* EXPORT_IF_KUNIT */
 
 uint8_t dc_get_link_count(const struct dc *dc)
 {
@@ -41,6 +42,7 @@ struct dc_context *dc_get_ctx(const struct dc *dc)
 {
 	return dc->ctx;
 }
+EXPORT_IF_KUNIT(dc_get_ctx);
 
 enum dce_version dc_get_dce_version(const struct dc *dc)
 {
@@ -77,21 +79,25 @@ struct dc_state *dc_get_current_state(const struct dc *dc)
 {
 	return dc->current_state;
 }
+EXPORT_IF_KUNIT(dc_get_current_state);
 
 bool dc_is_idle_optimizations_allowed(const struct dc *dc)
 {
 	return dc->idle_optimizations_allowed;
 }
+EXPORT_IF_KUNIT(dc_is_idle_optimizations_allowed);
 
 struct resource_pool *dc_get_res_pool(const struct dc *dc)
 {
 	return dc->res_pool;
 }
+EXPORT_IF_KUNIT(dc_get_res_pool);
 
 struct clk_mgr *dc_get_clk_mgr(struct dc *dc)
 {
 	return dc->clk_mgr;
 }
+EXPORT_IF_KUNIT(dc_get_clk_mgr);
 
 bool dc_get_dcc_compression_cap(const struct dc *dc,
 		const struct dc_dcc_surface_param *input,
@@ -139,6 +145,7 @@ bool dc_is_fbc_compressor_available(const struct dc *dc)
 {
 	return dc->fbc_compressor != NULL;
 }
+EXPORT_IF_KUNIT(dc_is_fbc_compressor_available);
 
 void dc_set_fbc_gpu_addr(struct dc *dc, uint64_t gpu_addr)
 {
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_test.c b/drivers/gpu/drm/amd/display/dc/core/dc_test.c
new file mode 100644
index 000000000000..60fb45f9cfaa
--- /dev/null
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_test.c
@@ -0,0 +1,135 @@
+// SPDX-License-Identifier: MIT
+/*
+ * Copyright 2026 Advanced Micro Devices, Inc.
+ *
+ * Permission is hereby granted, free of charge, to any person obtaining a
+ * copy of this software and associated documentation files (the "Software"),
+ * to deal in the Software without restriction, including without limitation
+ * the rights to use, copy, modify, merge, publish, distribute, sublicense,
+ * and/or sell copies of the Software, and to permit persons to whom the
+ * Software is furnished to do so, subject to the following conditions:
+ *
+ * The above copyright notice and this permission notice shall be included in
+ * all copies or substantial portions of the Software.
+ *
+ * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
+ * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
+ * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
+ * THE COPYRIGHT HOLDER(S) OR AUTHOR(S) BE LIABLE FOR ANY CLAIM, DAMAGES OR
+ * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
+ * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
+ * OTHER DEALINGS IN THE SOFTWARE.
+ *
+ */
+
+/* FILE POLICY AND INTENDED USAGE:
+ * Implementation of the KUnit test double API declared in dc_test.h.
+ * struct dc is private to DC; this file is the only place outside of the
+ * accessors that maps test operations onto struct dc members. It carries
+ * no functional behavior.
+ */
+#include <linux/slab.h>
+#include <linux/export.h>
+
+#include "dc.h"
+#include "dc_test.h"
+
+struct dc *dc_test_create(void)
+{
+	return kvzalloc(sizeof(struct dc), GFP_KERNEL);
+}
+EXPORT_SYMBOL(dc_test_create);
+
+void dc_test_destroy(struct dc *dc)
+{
+	kvfree(dc);
+}
+EXPORT_SYMBOL(dc_test_destroy);
+
+void dc_test_set_ctx(struct dc *dc, struct dc_context *ctx)
+{
+	dc->ctx = ctx;
+}
+EXPORT_SYMBOL(dc_test_set_ctx);
+
+void dc_test_set_current_state(struct dc *dc, struct dc_state *state)
+{
+	dc->current_state = state;
+}
+EXPORT_SYMBOL(dc_test_set_current_state);
+
+void dc_test_install_link_service(struct dc *dc,
+		struct link_service *link_srv)
+{
+	dc->link_srv = link_srv;
+}
+EXPORT_SYMBOL(dc_test_install_link_service);
+
+void dc_test_set_res_pool(struct dc *dc, struct resource_pool *res_pool)
+{
+	dc->res_pool = res_pool;
+}
+EXPORT_SYMBOL(dc_test_set_res_pool);
+
+void dc_test_set_clk_mgr(struct dc *dc, struct clk_mgr *clk_mgr)
+{
+	dc->clk_mgr = clk_mgr;
+}
+EXPORT_SYMBOL(dc_test_set_clk_mgr);
+
+void dc_test_set_fbc_compressor(struct dc *dc, struct compressor *compressor)
+{
+	dc->fbc_compressor = compressor;
+}
+EXPORT_SYMBOL(dc_test_set_fbc_compressor);
+
+void dc_test_set_link(struct dc *dc, unsigned int index, struct dc_link *link)
+{
+	if (index >= MAX_LINKS)
+		return;
+
+	dc->links[index] = link;
+}
+EXPORT_SYMBOL(dc_test_set_link);
+
+void dc_test_set_link_count(struct dc *dc, unsigned int count)
+{
+	dc->link_count = count;
+}
+EXPORT_SYMBOL(dc_test_set_link_count);
+
+void dc_test_set_idle_optimizations_allowed(struct dc *dc, bool allowed)
+{
+	dc->idle_optimizations_allowed = allowed;
+}
+EXPORT_SYMBOL(dc_test_set_idle_optimizations_allowed);
+
+struct dc_caps *dc_test_caps(struct dc *dc)
+{
+	return &dc->caps;
+}
+EXPORT_SYMBOL(dc_test_caps);
+
+struct dc_config *dc_test_config(struct dc *dc)
+{
+	return &dc->config;
+}
+EXPORT_SYMBOL(dc_test_config);
+
+struct dc_debug_options *dc_test_debug_options(struct dc *dc)
+{
+	return &dc->debug;
+}
+EXPORT_SYMBOL(dc_test_debug_options);
+
+struct dc_cap_funcs *dc_test_cap_funcs(struct dc *dc)
+{
+	return &dc->cap_funcs;
+}
+EXPORT_SYMBOL(dc_test_cap_funcs);
+
+struct hw_sequencer_funcs *dc_test_hwss(struct dc *dc)
+{
+	return &dc->hwss;
+}
+EXPORT_SYMBOL(dc_test_hwss);
diff --git a/drivers/gpu/drm/amd/display/dc/inc/dc_test.h b/drivers/gpu/drm/amd/display/dc/inc/dc_test.h
new file mode 100644
index 000000000000..61911de9da05
--- /dev/null
+++ b/drivers/gpu/drm/amd/display/dc/inc/dc_test.h
@@ -0,0 +1,81 @@
+/* SPDX-License-Identifier: MIT */
+/*
+ * Copyright 2026 Advanced Micro Devices, Inc.
+ *
+ * Permission is hereby granted, free of charge, to any person obtaining a
+ * copy of this software and associated documentation files (the "Software"),
+ * to deal in the Software without restriction, including without limitation
+ * the rights to use, copy, modify, merge, publish, distribute, sublicense,
+ * and/or sell copies of the Software, and to permit persons to whom the
+ * Software is furnished to do so, subject to the following conditions:
+ *
+ * The above copyright notice and this permission notice shall be included in
+ * all copies or substantial portions of the Software.
+ *
+ * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
+ * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
+ * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
+ * THE COPYRIGHT HOLDER(S) OR AUTHOR(S) BE LIABLE FOR ANY CLAIM, DAMAGES OR
+ * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
+ * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
+ * OTHER DEALINGS IN THE SOFTWARE.
+ *
+ */
+
+#ifndef __DC_TEST_H__
+#define __DC_TEST_H__
+
+/*
+ * KUnit support for building DC test doubles.
+ *
+ * struct dc is private to DC, so test code outside the dc directory cannot
+ * allocate one or poke its members directly. These helpers construct an
+ * empty fake DC instance and let tests install the pieces they need. They
+ * exist only when the amdgpu_dm KUnit tests are enabled and must never be
+ * used outside tests.
+ */
+
+struct dc;
+struct dc_context;
+struct dc_state;
+struct dc_link;
+struct dc_caps;
+struct dc_config;
+struct dc_debug_options;
+struct dc_cap_funcs;
+struct link_service;
+struct resource_pool;
+struct clk_mgr;
+struct compressor;
+struct hw_sequencer_funcs;
+
+#if IS_ENABLED(CONFIG_DRM_AMD_DC_KUNIT_TEST)
+
+/*
+ * Allocate a zeroed fake DC instance. Free it with dc_test_destroy() (or
+ * register that as a KUnit action).
+ */
+struct dc *dc_test_create(void);
+void dc_test_destroy(struct dc *dc);
+
+void dc_test_set_ctx(struct dc *dc, struct dc_context *ctx);
+void dc_test_set_current_state(struct dc *dc, struct dc_state *state);
+void dc_test_install_link_service(struct dc *dc,
+		struct link_service *link_srv);
+void dc_test_set_res_pool(struct dc *dc, struct resource_pool *res_pool);
+void dc_test_set_clk_mgr(struct dc *dc, struct clk_mgr *clk_mgr);
+void dc_test_set_fbc_compressor(struct dc *dc, struct compressor *compressor);
+void dc_test_set_link(struct dc *dc, unsigned int index, struct dc_link *link);
+void dc_test_set_link_count(struct dc *dc, unsigned int count);
+void dc_test_set_idle_optimizations_allowed(struct dc *dc, bool allowed);
+
+/* Mutable views of embedded sub-structures, for test faking only. */
+struct dc_caps *dc_test_caps(struct dc *dc);
+struct dc_config *dc_test_config(struct dc *dc);
+struct dc_debug_options *dc_test_debug_options(struct dc *dc);
+struct dc_cap_funcs *dc_test_cap_funcs(struct dc *dc);
+struct hw_sequencer_funcs *dc_test_hwss(struct dc *dc);
+
+#endif /* IS_ENABLED(CONFIG_DRM_AMD_DC_KUNIT_TEST) */
+
+#endif /* __DC_TEST_H__ */

-- 
2.56.0

