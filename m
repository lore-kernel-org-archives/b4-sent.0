From: Dave Airlie <airlied@redhat.com>
Date: Thu, 12 Nov 2026 11:43:46 +1000
Subject: [PATCH 11/19] drm/amd/display/amdgpu_dm: Finish DC accessor
 migration for non-test code
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-amdgpu-dc-cleanup-v1-11-0fae41718ad2@redhat.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=8023; i=airlied@redhat.com;
 h=from:subject:message-id; bh=smrKQQGz/eKSrZXLRXg6MqA1XX7cNLNtVfy3skfXGQ8=;
 b=owEBbAKT/ZANAwAKAQx081l5xIa+AcsmYgBq9RnPcKUpk+PoAmMDWusFdS4l+lK2lUTQ+/wgv
 uHbFxchyF2JAjIEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavUZzwAKCRAMdPNZecSG
 vrYiD/j5fw8dIyP8slMWEUxB/W+/FYOvmjLsWCPj4KuHbA+dLxM5SS0MuTGxikaj00OEZWILTjX
 ztS/JHIwPBSi3kzl+G1MLY8OsiDzRsHcrjpmb54D8tYeFMkMQxfg7abxzgzIE+OwBYz9WRqbfib
 i1K/h3RXWS2ibjbcGWkCv9Tfyu8rgjXNTB8ukjCwlnqz1pvOdU/Z6YlCBiLWhIE8jkULnnhquR3
 jVVJX4TZz1hxxQriG9al4VqKrp9Lgp3bAUYHKPyoAcRW8UtZglslUbQOhELZhXkIbPGUjN9+3kc
 tNLSNNTg2ak1sfhsU0DRH6Zr+o2wd+ZaF28fspVN1edVCEXosJtss0LewRay6sKA4jcGa0TKcW+
 Bpc2SMZ99fxbDVC+W6hGMmui0jVfo7KIhZnrgR5UJ/2sCNU+btQcdgxhMS5keu/Y6zKE/4/hqzm
 mDgcs7lEfVX40RE+v3v4Hj/8UAwmBGvht2kxg9O6HXZOFFU8OtdgmI0fTO/vadpT5OgdU0VuYHi
 iNS0lMNa1Vp/wPjgBAXN4DBzhjRYIy6FrtMhSQj6ZHd3yERfi9jw3n1FVbxPFPnOjTcPN21HRbx
 PdzWWvCS5jkdhzrP7SUe7NbeWuNrmSprS9F/KF4qPYJi9ulTxOKgaKeaIlRxDD/pv662vTKdfg4
 m0mGA7WIIvdEw
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert the last struct dc member dereferences outside DC (crtc,
irq, mst_types, amdgpu_dm ctx NULL check) to the accessor layer, and
move the PERFORMANCE_TRACE_{START,END} macros, which dereference a
dc-local variable, from the public logger_interface.h into
dc/dm_services.h where their users live.

No production code outside the dc directory dereferences struct dc
members anymore. Only the amdgpu_dm KUnit tests remain to migrate.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c  |  2 +-
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c |  2 +-
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c  |  2 +-
 .../amd/display/amdgpu_dm/amdgpu_dm_mst_types.c    | 26 +++++++++++++---------
 drivers/gpu/drm/amd/display/dc/dm_services.h       | 16 +++++++++++++
 .../gpu/drm/amd/display/include/logger_interface.h | 12 ----------
 6 files changed, 34 insertions(+), 26 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index cab39aa4d41f..3458b26846a1 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -1160,7 +1160,7 @@ static void amdgpu_dm_boot_time_crc_init(struct amdgpu_device *adev)
 	int ret = 0;
 	const uint32_t fb_size = 3 * 1024 * 1024;	/* 3MB for DCC pattern */
 
-	if (!adev || !adev->dm.dc || !adev->dm.dc->ctx ||
+	if (!adev || !adev->dm.dc || !dc_get_ctx(adev->dm.dc) ||
 		!dc_get_ctx(adev->dm.dc)->dmub_srv) {
 		return;
 	}
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c
index 334e33b1c4f4..9c607ecc4bd6 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c
@@ -831,7 +831,7 @@ int amdgpu_dm_crtc_init(struct amdgpu_display_manager *dm,
 	 * both is rejected.
 	 */
 	has_degamma = dc_get_caps(dm->adev->dm.dc)->color.dpp.dcn_arch &&
-		      dm->adev->dm.dc->ctx->dce_version != DCN_VERSION_4_01;
+		      dc_get_dce_version(dm->adev->dm.dc) != DCN_VERSION_4_01;
 
 	drm_crtc_enable_color_mgmt(&acrtc->base, has_degamma ? MAX_COLOR_LUT_ENTRIES : 0,
 				   true, MAX_COLOR_LUT_ENTRIES);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c
index a7ee30c66a48..5c3b83f05d2b 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c
@@ -1656,7 +1656,7 @@ STATIC_IFN_KUNIT void dmub_hpd_callback(struct amdgpu_device *adev,
 		return;
 	}
 
-	if (notify->link_index > adev->dm.dc->link_count) {
+	if (notify->link_index > dc_get_link_count(adev->dm.dc)) {
 		drm_err(adev_to_drm(adev), "DMUB HPD index (%u)is abnormal", notify->link_index);
 		return;
 	}
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
index a3877ef767ec..2cbe08298706 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
@@ -1239,7 +1239,7 @@ STATIC_IFN_KUNIT bool get_conv_frl_bw(struct amdgpu_dm_connector *aconnector,
 	unsigned int dsc_max_sink_bw_in_kbps = 0;
 
 	if (aconnector->dc_sink &&
-	    aconnector->dc_link->dc->caps.dp_hdmi21_pcon_support &&
+	    dc_get_caps(aconnector->dc_link->dc)->dp_hdmi21_pcon_support &&
 	    aconnector->mst_downstream_port_caps.bytes.byte0.bits.DWN_STRM_PORTX_TYPE == DOWN_STREAM_DETAILED_HDMI) {
 		max_conv_bw_in_kbps = dc_link_bw_kbps_from_raw_frl_link_rate_data(
 				aconnector->dc_link->dc,
@@ -1399,7 +1399,8 @@ static int compute_mst_dsc_configs_for_link(struct drm_atomic_commit *state,
 			build_frl_mst_dsc_params(aconnector, stream, &dsc_policy, &params[count], frl_conv_dsc_bw_in_kbps);
 		if (!dc_dsc_compute_bandwidth_range(
 				stream->sink->ctx->dc,
-				stream->sink->ctx->dc->debug.dsc_min_slice_height_override,
+				dc_get_debug_options(
+					stream->sink->ctx->dc)->dsc_min_slice_height_override,
 				min_target_bpp_x16,
 				max_target_bpp_x16,
 				&stream->sink->dsc_caps.dsc_dec_caps,
@@ -1593,13 +1594,13 @@ STATIC_IFN_KUNIT bool is_dsc_need_re_compute(
 	}
 
 	DRM_DEBUG_DRIVER("%s: MST_DSC check on %d streams in current dc_state\n",
-			 __func__, dc->current_state->stream_count);
+			 __func__, dc_get_current_state(dc)->stream_count);
 
 	/* check current_state if there stream on link but it is not in
 	 * new request state
 	 */
-	for (i = 0; i < dc->current_state->stream_count; i++) {
-		stream = dc->current_state->streams[i];
+	for (i = 0; i < dc_get_current_state(dc)->stream_count; i++) {
+		stream = dc_get_current_state(dc)->streams[i];
 		/* only check stream on the mst hub */
 		if (stream->link != dc_link)
 			continue;
@@ -1943,12 +1944,15 @@ static bool is_dsc_common_config_possible(struct dc_stream_state *stream,
 	bool is_dsc_possible;
 
 	dc_dsc_get_policy_for_timing(&stream->timing, 0, &dsc_policy, dc_link_get_highest_encoding_format(stream->link));
-	is_dsc_possible = dc_dsc_compute_bandwidth_range(stream->sink->ctx->dc,
-							 stream->sink->ctx->dc->debug.dsc_min_slice_height_override,
-							 dsc_policy.min_target_bpp * 16,
-							 dsc_policy.max_target_bpp * 16,
-							 &stream->sink->dsc_caps.dsc_dec_caps,
-							 &stream->timing, dc_link_get_highest_encoding_format(stream->link), bw_range);
+	is_dsc_possible = dc_dsc_compute_bandwidth_range(
+			stream->sink->ctx->dc,
+			dc_get_debug_options(
+				stream->sink->ctx->dc)->dsc_min_slice_height_override,
+			dsc_policy.min_target_bpp * 16,
+			dsc_policy.max_target_bpp * 16,
+			&stream->sink->dsc_caps.dsc_dec_caps,
+			&stream->timing,
+			dc_link_get_highest_encoding_format(stream->link), bw_range);
 
 	return is_dsc_possible;
 }
diff --git a/drivers/gpu/drm/amd/display/dc/dm_services.h b/drivers/gpu/drm/amd/display/dc/dm_services.h
index 2cf4bcb03cb0..6f54f55d260c 100644
--- a/drivers/gpu/drm/amd/display/dc/dm_services.h
+++ b/drivers/gpu/drm/amd/display/dc/dm_services.h
@@ -262,6 +262,22 @@ void dm_perf_trace_timestamp(const char *func_name, unsigned int line, struct dc
 #define PERF_TRACE()	dm_perf_trace_timestamp(__func__, __LINE__, CTX)
 #define PERF_TRACE_CTX(__CTX)	dm_perf_trace_timestamp(__func__, __LINE__, __CTX)
 
+/*
+ * These macros dereference a dc-local variable and are therefore only
+ * usable from DC-internal code.
+ */
+#define PERFORMANCE_TRACE_START() \
+	unsigned long long perf_trc_start_stmp = dm_get_timestamp(dc->ctx)
+
+#define PERFORMANCE_TRACE_END() \
+	do { \
+		unsigned long long perf_trc_end_stmp = dm_get_timestamp(dc->ctx); \
+		if (dc->debug.performance_trace) { \
+			DC_LOG_PERF_TRACE("%s duration: %lld ticks\n", __func__, \
+				perf_trc_end_stmp - perf_trc_start_stmp); \
+		} \
+	} while (0)
+
 /*
  * SMU message tracing
  */
diff --git a/drivers/gpu/drm/amd/display/include/logger_interface.h b/drivers/gpu/drm/amd/display/include/logger_interface.h
index 7dc738b60162..89869c1b0e6a 100644
--- a/drivers/gpu/drm/amd/display/include/logger_interface.h
+++ b/drivers/gpu/drm/amd/display/include/logger_interface.h
@@ -125,18 +125,6 @@ void context_clock_trace(
 #define DTN_INFO_END() \
 	dm_dtn_log_end(dc_ctx, log_ctx)
 
-#define PERFORMANCE_TRACE_START() \
-	unsigned long long perf_trc_start_stmp = dm_get_timestamp(dc->ctx)
-
-#define PERFORMANCE_TRACE_END() \
-	do { \
-		unsigned long long perf_trc_end_stmp = dm_get_timestamp(dc->ctx); \
-		if (dc->debug.performance_trace) { \
-			DC_LOG_PERF_TRACE("%s duration: %lld ticks\n", __func__, \
-				perf_trc_end_stmp - perf_trc_start_stmp); \
-		} \
-	} while (0)
-
 #define DISPLAY_STATS_BEGIN(entry) (void)(entry)
 
 #define DISPLAY_STATS(msg, ...) DC_LOG_PERF_TRACE(msg, __VA_ARGS__)

-- 
2.56.0

