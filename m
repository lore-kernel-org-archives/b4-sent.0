From: Dave Airlie <airlied@redhat.com>
Date: Thu, 12 Nov 2026 11:43:52 +1000
Subject: [PATCH 17/19] drm/amd/display: Replace the dc_get_res_pool
 accessor with purpose APIs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-amdgpu-dc-cleanup-v1-17-0fae41718ad2@redhat.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=19395; i=airlied@redhat.com;
 h=from:subject:message-id; bh=aLrjfmRuVNABR0G+4/pR/qWC5Ff9G9CEUgqRMbt0D4Q=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq9RnQJE0nmBARJKeuxT2u28SbN1za/x9cqBpk3
 Xs641E9fgaJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavUZ0AAKCRAMdPNZecSG
 vpbiD/443Ea3wzTXr3STlsRm7KCIZpBPzHixgBc8aNR5jxVxDu+LVX7N5wIqijxMlmiwv82bUPL
 fO7RiOkkqjegFvS0YvOZKHzB2+q0cfOzBEq5xUyJ+iPAbxyuxmx6drL6cnMWybtxeuFATuvGScd
 mR6akTmO3dgJFmjpChnXDWbkxk68Y6FinwjxrUZqQsOoG7vX1X6Il4DABe4gjIjRQSKdoEi8XLz
 Q34LVDU8NaH6H8rPdjBzX/tS/j9G6Xac15T+5QPjx/eVjwlK3bx4kva11UjyYrzfr0EiiflcciH
 H6UL2Yoa12rIc053j3hcxO320C2JXOxYtksRBHzbrjsTN3dlXoOqz/QrJ5/CQ/DahzY3XSK2eIe
 1/TrnBPh9Mrnn33Q53j+DlxV7XMKlxT2dEtUjjorm93pT1ALJhvvdcY3YLi79/QoE44LqqB3RqZ
 h1+QNKoR1MXw80wr+Tbbxs1zmDigk3ckcQH+r31DYiRAEmzq3UOUOmkOAbF5aldjQLBiM7ZbKJu
 QyIZ5QUzaA04RlBexpGpB32/jisR8W8IT9qIeLiPs/46uN02YeCv2zxrsDDTelQHxnUF/7s2e5v
 z+JAV3WV6j0AKWZK8RGrB2s/BSqAQ5eBkVqHR/gMMDjKhvD0ehnwJ85FDoTExblUl0n7OR0FcTF
 SBG9V53fOuXvmuQ==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the last purpose-built interfaces for the data DM was reading
through dc_get_res_pool() and drop the accessor entirely:

- dc_get_audio_instances() fills the audio instance id array for
  amdgpu_dm_audio_init()
- dc_get_pipe_count() for the debugfs DCC bits dump
- dc_get_usb4_dpia_count() for the DMUB DPIA enablement
- dc_get_dmcu_psp_version() and dc_dmcu_init_abm() for the DMUB
  hardware init path
- dc_get_mall_en() for the debugfs capabilities dump
- dc_remove_stream_from_ctx() for the MST DSC recomputation

No code outside the dc directory references struct resource_pool in
production anymore; only the KUnit tests keep installing fake pools
through dc_test_set_res_pool() / dm_kunit_alloc_res_pool().

Part of making the struct dc sub-structures opaque outside DC.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_audio.c    |  8 +---
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_debugfs.c  |  7 +---
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c | 14 ++-----
 .../amd/display/amdgpu_dm/amdgpu_dm_mst_types.c    |  6 +--
 .../display/amdgpu_dm/tests/amdgpu_dm_dmub_test.c  | 12 ++++--
 .../display/amdgpu_dm/tests/amdgpu_dm_irq_test.c   |  2 +-
 .../amdgpu_dm/tests/amdgpu_dm_kunit_helpers.c      | 13 +++++++
 .../amdgpu_dm/tests/amdgpu_dm_kunit_test_helpers.h |  2 +
 .../amdgpu_dm/tests/amdgpu_dm_mst_types_test.c     |  5 ++-
 .../amd/display/amdgpu_dm/tests/amdgpu_dm_test.c   |  6 +--
 drivers/gpu/drm/amd/display/dc/core/dc_abm.c       | 11 ++++++
 drivers/gpu/drm/amd/display/dc/core/dc_accessors.c | 44 ++++++++++++++++++++--
 drivers/gpu/drm/amd/display/dc/core/dc_resource.c  | 10 +++++
 drivers/gpu/drm/amd/display/dc/inc/dc.h            | 38 ++++++++++++++++---
 14 files changed, 135 insertions(+), 43 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_audio.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_audio.c
index 23392b229679..0301081e040e 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_audio.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_audio.c
@@ -140,19 +140,15 @@ EXPORT_IF_KUNIT(amdgpu_dm_audio_init_pins);
 int amdgpu_dm_audio_init(struct amdgpu_device *adev)
 {
 	unsigned int inst_array[MAX_AUDIOS];
-	struct resource_pool *res_pool;
 	int audio_count;
-	int i, ret;
+	int ret;
 
 	if (!amdgpu_audio)
 		return 0;
 
 	adev->mode_info.audio.enabled = true;
 
-	res_pool = dc_get_res_pool(adev->dm.dc);
-	audio_count = res_pool->audio_count;
-	for (i = 0; i < audio_count; i++)
-		inst_array[i] = res_pool->audios[i]->inst;
+	audio_count = dc_get_audio_instances(adev->dm.dc, inst_array);
 	amdgpu_dm_audio_init_pins(adev, audio_count, inst_array);
 
 	ret = component_add(adev->dev, &amdgpu_dm_audio_component_bind_ops);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_debugfs.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_debugfs.c
index 8d7ebb636554..8bc737117db9 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_debugfs.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_debugfs.c
@@ -4464,10 +4464,7 @@ static int capabilities_show(struct seq_file *m, void *unused)
 	unsigned int mall_in_use = false;
 	unsigned int subvp_in_use = false;
 
-	struct hubbub *hubbub = dc_get_res_pool(dc)->hubbub;
-
-	if (hubbub && hubbub->funcs->get_mall_en)
-		hubbub->funcs->get_mall_en(hubbub, &mall_in_use);
+	dc_get_mall_en(dc, &mall_in_use);
 
 	subvp_in_use = dc_get_subvp_en(dc, dc_get_current_state(dc));
 
@@ -4609,7 +4606,7 @@ static ssize_t dcc_en_bits_read(
 	const uint32_t rd_buf_size = 32;
 	uint32_t result = 0;
 	int offset = 0;
-	int num_pipes = dc_get_res_pool(dc)->pipe_count;
+	int num_pipes = dc_get_pipe_count(dc);
 	int *dcc_en_bits;
 	int i, r;
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c
index ffe561da24d6..3ed6a9318931 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c
@@ -232,9 +232,6 @@ int dm_dmub_hw_init(struct amdgpu_device *adev)
 	struct dmub_srv_fb_info *fb_info = adev->dm.dmub_fb_info;
 	const struct firmware *dmub_fw = adev->dm.dmub_fw;
 	struct dc *dc = adev->dm.dc;
-	struct resource_pool *res_pool = dc_get_res_pool(dc);
-	struct dmcu *dmcu = res_pool->dmcu;
-	struct abm *abm = res_pool->abm;
 	struct dc_context *ctx = dc_get_ctx(adev->dm.dc);
 	struct dmub_srv_hw_params hw_params;
 	enum dmub_status status;
@@ -333,14 +330,14 @@ int dm_dmub_hw_init(struct amdgpu_device *adev)
 	if (adev->firmware.load_type != AMDGPU_FW_LOAD_PSP)
 		hw_params.load_inst_const = true;
 
-	if (dmcu)
-		hw_params.psp_version = dmcu->psp_version;
+	if (dc_has_dmcu(dc))
+		hw_params.psp_version = dc_get_dmcu_psp_version(dc);
 
 	hw_params.fb_info = fb_info;
 
 	/* Enable usb4 dpia in the FW APU */
 	if (dc_get_caps(dc)->is_apu &&
-		dc_get_res_pool(dc)->usb4_dpia_count != 0 &&
+		dc_get_usb4_dpia_count(dc) != 0 &&
 		!dc_get_debug_options(dc)->dpia_debug.bits.disable_dpia) {
 		hw_params.dpia_supported = true;
 		hw_params.disable_dpia = dc_get_debug_options(dc)->dpia_debug.bits.disable_dpia;
@@ -375,10 +372,7 @@ int dm_dmub_hw_init(struct amdgpu_device *adev)
 		drm_warn(adev_to_drm(adev), "Wait for DMUB auto-load failed: %d\n", status);
 
 	/* Init DMCU and ABM if available. */
-	if (dmcu && abm) {
-		dmcu->funcs->dmcu_init(dmcu);
-		abm->dmcu_is_running = dmcu->funcs->is_dmcu_initialized(dmcu);
-	}
+	dc_dmcu_init_abm(dc);
 
 	if (!dc_get_ctx(adev->dm.dc)->dmub_srv)
 		dc_get_ctx(adev->dm.dc)->dmub_srv = dc_dmub_srv_create(adev->dm.dc, dmub_srv);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
index 4f9070579916..d533b72f1861 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
@@ -1643,7 +1643,6 @@ int compute_mst_dsc_configs_for_state(struct drm_atomic_commit *state,
 	bool computed_streams[MAX_PIPES];
 	struct amdgpu_dm_connector *aconnector;
 	struct drm_dp_mst_topology_mgr *mst_mgr;
-	struct resource_pool *res_pool;
 	int link_vars_start_index = 0;
 	int ret = 0;
 
@@ -1652,7 +1651,7 @@ int compute_mst_dsc_configs_for_state(struct drm_atomic_commit *state,
 
 	for (i = 0; i < dc_state->stream_count; i++) {
 		stream = dc_state->streams[i];
-		res_pool = dc_get_res_pool(stream->ctx->dc);
+
 
 		if (stream->signal != SIGNAL_TYPE_DISPLAY_PORT_MST)
 			continue;
@@ -1671,8 +1670,7 @@ int compute_mst_dsc_configs_for_state(struct drm_atomic_commit *state,
 		if (computed_streams[i])
 			continue;
 
-		if (res_pool->funcs->remove_stream_from_ctx &&
-		    res_pool->funcs->remove_stream_from_ctx(stream->ctx->dc, dc_state, stream) != DC_OK)
+		if (dc_remove_stream_from_ctx(stream->ctx->dc, dc_state, stream) != DC_OK)
 			return -EINVAL;
 
 		if (!is_dsc_need_re_compute(state, dc_state, stream->link))
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_dmub_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_dmub_test.c
index b71e1e11e85a..e1360a97ec26 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_dmub_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_dmub_test.c
@@ -731,11 +731,14 @@ static void dm_test_dmub_hw_init_auto_load_timeout(struct kunit *test)
  */
 static void dm_test_dmub_hw_init_apu_dpia_dcn35(struct kunit *test)
 {
+	struct resource_pool *res_pool;
+
 	struct amdgpu_device *adev = dm_test_alloc_adev_with_dmub(test);
 
 	adev->ip_versions[DCE_HWIP][0] = IP_VERSION(3, 5, 0);
 	dc_test_caps(adev->dm.dc)->is_apu = true;
-	dc_get_res_pool(adev->dm.dc)->usb4_dpia_count = 1;
+	res_pool = dm_kunit_alloc_res_pool(test, adev->dm.dc);
+	res_pool->usb4_dpia_count = 1;
 
 	KUNIT_EXPECT_EQ(test, dm_dmub_hw_init(adev), 0);
 	KUNIT_EXPECT_TRUE(test, adev->dm.dmub_srv->hw_init);
@@ -787,6 +790,8 @@ static void dm_test_dmub_hw_init_sanity_checks_dcn314(struct kunit *test)
  */
 static void dm_test_dmub_hw_init_dmcu_abm(struct kunit *test)
 {
+	struct resource_pool *res_pool;
+
 	struct amdgpu_device *adev = dm_test_alloc_adev_with_dmub(test);
 	struct dmcu *dmcu;
 	struct abm *abm;
@@ -799,8 +804,9 @@ static void dm_test_dmub_hw_init_dmcu_abm(struct kunit *test)
 
 	dmcu->funcs = &dm_test_dmcu_funcs;
 	dmcu->psp_version = 0x12345678;
-	dc_get_res_pool(adev->dm.dc)->dmcu = dmcu;
-	dc_get_res_pool(adev->dm.dc)->abm = abm;
+	res_pool = dm_kunit_alloc_res_pool(test, adev->dm.dc);
+	res_pool->dmcu = dmcu;
+	res_pool->abm = abm;
 
 	KUNIT_EXPECT_EQ(test, dm_dmub_hw_init(adev), 0);
 	KUNIT_EXPECT_TRUE(test, abm->dmcu_is_running);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_irq_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_irq_test.c
index ea467ca45af8..2ae534c4c252 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_irq_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_irq_test.c
@@ -4188,7 +4188,7 @@ static void dm_test_crtc_high_irq_writeback_disables(struct kunit *test)
 	adev = dm_kunit_alloc_adev(test);
 	KUNIT_ASSERT_EQ(test, drm_vblank_init(&adev->ddev, 1), 0);
 
-	/* dc_stream_fc_disable_writeback() dereferences dc_get_res_pool(dc). */
+	/* dc_stream_fc_disable_writeback() dereferences the DC resource pool. */
 	dc = dm_test_alloc_dc_with_irq_service(test,
 					       &dm_test_irq_service_funcs_dcn10);
 	adev->dm.dc = dc;
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_kunit_helpers.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_kunit_helpers.c
index 9954cbab6541..e4bea9fbad52 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_kunit_helpers.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_kunit_helpers.c
@@ -136,6 +136,19 @@ struct dc_state *dm_kunit_alloc_dc_state(struct kunit *test)
 }
 EXPORT_SYMBOL(dm_kunit_alloc_dc_state);
 
+struct resource_pool *dm_kunit_alloc_res_pool(struct kunit *test, struct dc *dc)
+{
+	struct resource_pool *res_pool;
+
+	res_pool = kunit_kzalloc(test, sizeof(*res_pool), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, res_pool);
+
+	dc_test_set_res_pool(dc, res_pool);
+
+	return res_pool;
+}
+EXPORT_SYMBOL(dm_kunit_alloc_res_pool);
+
 struct clk_mgr *dm_kunit_alloc_clk_mgr(struct kunit *test)
 {
 	struct clk_mgr *clk_mgr;
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_kunit_test_helpers.h b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_kunit_test_helpers.h
index b4bbf4a3750d..279d6eb79ad5 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_kunit_test_helpers.h
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_kunit_test_helpers.h
@@ -28,6 +28,8 @@ struct dc_link *dm_kunit_alloc_link_with_ctx(struct kunit *test);
 struct amdgpu_display_manager *dm_kunit_alloc_dm(struct kunit *test);
 struct drm_device *dm_kunit_alloc_drm_with_connector_list(struct kunit *test);
 struct dc_state *dm_kunit_alloc_dc_state(struct kunit *test);
+struct resource_pool;
+struct resource_pool *dm_kunit_alloc_res_pool(struct kunit *test, struct dc *dc);
 struct clk_mgr *dm_kunit_alloc_clk_mgr(struct kunit *test);
 struct dc_stream_state *dm_kunit_alloc_stream(struct kunit *test,
 					      struct dc_link *link);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_mst_types_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_mst_types_test.c
index 144cb03f504a..da5c2f958bf1 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_mst_types_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_mst_types_test.c
@@ -2783,6 +2783,8 @@ static const struct dsc_funcs dm_mst_test_dsc_funcs = {
 /* Install the DSC encoder fake and matching sink decoder capabilities. */
 static void dm_mst_test_setup_dsc_caps(struct kunit *test, struct dc *dc, struct dc_sink *sink)
 {
+	struct resource_pool *res_pool;
+
 	struct dsc_dec_dpcd_caps *dec = &sink->dsc_caps.dsc_dec_caps;
 	struct display_stream_compressor *dsc;
 
@@ -2791,7 +2793,8 @@ static void dm_mst_test_setup_dsc_caps(struct kunit *test, struct dc *dc, struct
 
 	dsc->funcs = &dm_mst_test_dsc_funcs;
 	dsc->ctx = dc_get_ctx(dc);
-	dc_get_res_pool(dc)->dscs[0] = dsc;
+	res_pool = dm_kunit_alloc_res_pool(test, dc);
+	res_pool->dscs[0] = dsc;
 
 	dec->is_dsc_supported = true;
 	dec->dsc_version = 0x21;
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
index 8cf460a4cb9f..0c27422cb8cf 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
@@ -3388,8 +3388,7 @@ static void dm_test_oem_i2c_hw_init_no_device(struct kunit *test)
 	struct amdgpu_device *adev = dm_kunit_alloc_adev(test);
 	struct dc *dc = dm_kunit_alloc_dc_with_ctx(test);
 
-	dc_test_set_res_pool(dc, kunit_kzalloc(test, sizeof(*dc_get_res_pool(dc)), GFP_KERNEL));
-	KUNIT_ASSERT_NOT_NULL(test, dc_get_res_pool(dc));
+	dm_kunit_alloc_res_pool(test, dc);
 	adev->dm.dc = dc;
 
 	KUNIT_EXPECT_EQ(test, dm_oem_i2c_hw_init(adev), 0);
@@ -4981,8 +4980,7 @@ static struct amdgpu_device *dm_test_late_init_adev(struct kunit *test)
 	struct amdgpu_device *adev = dm_kunit_alloc_adev(test);
 	struct dc *dc = dm_kunit_alloc_dc_with_ctx(test);
 
-	dc_test_set_res_pool(dc, kunit_kzalloc(test, sizeof(*dc_get_res_pool(dc)), GFP_KERNEL));
-	KUNIT_ASSERT_NOT_NULL(test, dc_get_res_pool(dc));
+	dm_kunit_alloc_res_pool(test, dc);
 	adev->dm.dc = dc;
 
 	return adev;
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_abm.c b/drivers/gpu/drm/amd/display/dc/core/dc_abm.c
index 1ed4b5fb6f93..28427e03289b 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_abm.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_abm.c
@@ -119,3 +119,14 @@ unsigned int dc_get_dmcu_abm_version(const struct dc *dc)
 
 	return dc->res_pool->dmcu->dmcu_version.abm_version;
 }
+
+void dc_dmcu_init_abm(struct dc *dc)
+{
+	struct dmcu *dmcu = dc->res_pool ? dc->res_pool->dmcu : NULL;
+	struct abm *abm = dc->res_pool ? dc->res_pool->abm : NULL;
+
+	if (dmcu && abm) {
+		dmcu->funcs->dmcu_init(dmcu);
+		abm->dmcu_is_running = dmcu->funcs->is_dmcu_initialized(dmcu);
+	}
+}
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c b/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c
index 9e8dffadfaec..163884db0294 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c
@@ -32,6 +32,8 @@
  */
 #include "dc.h"
 #include "dc_priv.h"
+#include "core_types.h"
+#include "hw/dchubbub.h"
 #include "dm_helpers.h"	/* EXPORT_IF_KUNIT */
 
 uint8_t dc_get_link_count(const struct dc *dc)
@@ -88,11 +90,47 @@ bool dc_is_idle_optimizations_allowed(const struct dc *dc)
 }
 EXPORT_IF_KUNIT(dc_is_idle_optimizations_allowed);
 
-struct resource_pool *dc_get_res_pool(const struct dc *dc)
+unsigned int dc_get_audio_instances(const struct dc *dc,
+		unsigned int *inst_array)
 {
-	return dc->res_pool;
+	unsigned int i;
+
+	for (i = 0; i < dc->res_pool->audio_count; i++)
+		inst_array[i] = dc->res_pool->audios[i]->inst;
+
+	return dc->res_pool->audio_count;
+}
+EXPORT_IF_KUNIT(dc_get_audio_instances);
+
+unsigned int dc_get_pipe_count(const struct dc *dc)
+{
+	return dc->res_pool->pipe_count;
+}
+EXPORT_IF_KUNIT(dc_get_pipe_count);
+
+unsigned int dc_get_usb4_dpia_count(const struct dc *dc)
+{
+	return dc->res_pool->usb4_dpia_count;
+}
+EXPORT_IF_KUNIT(dc_get_usb4_dpia_count);
+
+unsigned int dc_get_dmcu_psp_version(const struct dc *dc)
+{
+	if (!dc->res_pool || !dc->res_pool->dmcu)
+		return 0;
+
+	return dc->res_pool->dmcu->psp_version;
+}
+
+void dc_get_mall_en(struct dc *dc, unsigned int *mall_in_use)
+{
+	struct hubbub *hubbub = dc->res_pool ? dc->res_pool->hubbub : NULL;
+
+	*mall_in_use = false;
+
+	if (hubbub && hubbub->funcs->get_mall_en)
+		hubbub->funcs->get_mall_en(hubbub, mall_in_use);
 }
-EXPORT_IF_KUNIT(dc_get_res_pool);
 
 
 bool dc_get_dcc_compression_cap(const struct dc *dc,
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_resource.c b/drivers/gpu/drm/amd/display/dc/core/dc_resource.c
index d5d53491e91c..11b5647ca032 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_resource.c
@@ -6349,3 +6349,13 @@ bool resource_is_hpo_acquired(struct dc_state *context)
 
 	return false;
 }
+
+enum dc_status dc_remove_stream_from_ctx(struct dc *dc,
+		struct dc_state *context, struct dc_stream_state *stream)
+{
+	if (dc->res_pool->funcs->remove_stream_from_ctx)
+		return dc->res_pool->funcs->remove_stream_from_ctx(
+				dc, context, stream);
+
+	return DC_OK;
+}
diff --git a/drivers/gpu/drm/amd/display/dc/inc/dc.h b/drivers/gpu/drm/amd/display/dc/inc/dc.h
index 28cd052e0727..65705f4941c1 100644
--- a/drivers/gpu/drm/amd/display/dc/inc/dc.h
+++ b/drivers/gpu/drm/amd/display/dc/inc/dc.h
@@ -2376,12 +2376,6 @@ struct dc_state *dc_get_current_state(const struct dc *dc);
 /* Whether DC may enter idle power optimizations right now. */
 bool dc_is_idle_optimizations_allowed(const struct dc *dc);
 
-/*
- * The hardware resource pool (DSC engines, audio instances, DMCU/ABM...).
- * Interim accessor; prefer purpose-built DC interfaces where available.
- */
-struct resource_pool *dc_get_res_pool(const struct dc *dc);
-
 /*
  * Temporary workaround for DP compliance test failures: disallow p-state
  * switching for the given state, raise the memory clock to the maximum
@@ -2431,6 +2425,38 @@ bool dc_abm_set_event(struct dc *dc, unsigned int full_screen,
 bool dc_abm_set_strength(struct dc *dc, unsigned int strength,
 		unsigned int panel_inst);
 
+/*
+ * Fill inst_array with the instance ids of the DIO audio blocks and
+ * return their count. inst_array must have room for MAX_AUDIOS entries.
+ */
+unsigned int dc_get_audio_instances(const struct dc *dc,
+		unsigned int *inst_array);
+
+/* Number of pipes available for rendering. */
+unsigned int dc_get_pipe_count(const struct dc *dc);
+
+/* Number of USB4 DPIA endpoints. */
+unsigned int dc_get_usb4_dpia_count(const struct dc *dc);
+
+/* Read the DMCU PSP version; 0 when there is no DMCU. */
+unsigned int dc_get_dmcu_psp_version(const struct dc *dc);
+
+/*
+ * Initialize the DMCU and update the ABM "DMCU running" state.
+ * No-op when the ASIC has no DMCU or ABM.
+ */
+void dc_dmcu_init_abm(struct dc *dc);
+
+/* Whether MALL is currently enabled. */
+void dc_get_mall_en(struct dc *dc, unsigned int *mall_in_use);
+
+/*
+ * Remove the resources assigned to a stream in the given state.
+ * Returns DC_OK when the ASIC does not implement the removal.
+ */
+enum dc_status dc_remove_stream_from_ctx(struct dc *dc,
+		struct dc_state *context, struct dc_stream_state *stream);
+
 /*
  * Query DCC compression support for a surface.
  * return false - when the asic does not implement the query.

-- 
2.56.0

