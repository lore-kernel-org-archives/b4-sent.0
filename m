From: Dave Airlie <airlied@redhat.com>
Date: Thu, 12 Nov 2026 11:43:37 +1000
Subject: [PATCH 02/19] drm/amd/display: Add DC accessors as the first step
 to opaque struct dc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-amdgpu-dc-cleanup-v1-2-0fae41718ad2@redhat.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=15743; i=airlied@redhat.com;
 h=from:subject:message-id; bh=1LtED0nwoQ8ppce0T0uuihoA1JhOh04sCVHjlh+aSNk=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq9RnOJAvPFh+I4llhXBABZTtTi59S/OSHkZmkS
 eE1pdZJp3qJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavUZzgAKCRAMdPNZecSG
 vg91EACdC6ohVepgbNzs2or/fhyh2rtWU87Y78wXOJ5yZ8daAy0YDWSOKEXFgqRoqL2GlFJ7Wit
 GFS73vJ7nw/EwlRjmJMEmnWbpDNL/BtSFd67IXySWZ7YP9JEj2yMXL47dh7Hs8M55V5+o2/78Vn
 WIHzwyZPc8SLXiPUdHbUqKQMdHaBnHOykgnxqiBFsGCvskma6Y8UYOSwindv//JMsqtTD2JW3PD
 nPZwnoNT+/nzA9jCh+xd0B/klDaFjflC9q1rO/qo3Yu4oEVPhIoSKl4L+NOIeoJqViNWYz5LRuN
 +8nzB33UbSP7TY4wJ7Ea2XwPDKQlpI5xMYjpflsrImNpq2qpefg8R/3Bdh04oQpTizY5wKBasNv
 MW15mGBawcJU9UN90BwC1hDi9yJnQubkUNhzr1UP3IGTrAZEvDVxA2BDjJtZ41e1tjP+UQoLrmy
 xZmSyyhVCxil9E7NBQ2dgUHDnlbvb7NdfDCH41WeSEDrRqpHjkhULMqc+aZZc3am/x/20tUo8Ez
 xK4rJ5mRpPdR9U4ENNmVui7ZvXpDTonNap9NU8ZnvAduZw1d5wpFjR/hdiwej678Bz+Mif/5Vb3
 oEybsmLAmCzaPVFNiyZ3atssdEgltcf5SEWhVBqXjsPIcCwV4ZBGtk4BvJ1aSHhe0XQ8KhkATT6
 HO8xueJ/9NzI1Nw==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

struct dc is defined in dc.h which is included by DM and DAL modules,
so any of them can dereference dc members directly. As a first step
towards making struct dc private to DC, add an accessor layer:

- Introspection accessors (link count, ctx, caps, config, debug
  options, current state, idle optimizations, resource pool, clock
  manager) implemented in a new dc/core/dc_accessors.c which is the
  single place mapping accessor names onto struct dc fields.
- hwss/cap_funcs wrappers for log_hw_state, get_dcc_en_bits,
  prepare_ddc, get_dcc_compression_cap and get_subvp_en.
- FBC and DML2 alternate channel configuration helpers.
- link_service wrappers in dc/core/dc_link_exports.c for the entry
  points that DM and DAL modules reach through dc->link_srv today,
  violating the link_service.h usage policy.

The accessors are additive; no consumer is migrated yet.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 drivers/gpu/drm/amd/display/dc/Makefile            |   1 +
 drivers/gpu/drm/amd/display/dc/core/dc_accessors.c | 136 ++++++++++++++++
 .../gpu/drm/amd/display/dc/core/dc_link_exports.c  |  85 ++++++++++
 drivers/gpu/drm/amd/display/dc/dc.h                | 174 +++++++++++++++++++++
 4 files changed, 396 insertions(+)

diff --git a/drivers/gpu/drm/amd/display/dc/Makefile b/drivers/gpu/drm/amd/display/dc/Makefile
index 84c68b87210f..0f39a15dfc60 100644
--- a/drivers/gpu/drm/amd/display/dc/Makefile
+++ b/drivers/gpu/drm/amd/display/dc/Makefile
@@ -68,6 +68,7 @@ FILES += dc_fused_io.o
 FILES += dc_helper.o
 FILES += dc_memory_pool.o
 FILES += core/dc.o
+FILES += core/dc_accessors.o
 FILES += dc_api_dispatch/api_shim.o
 FILES += core/dc_debug.o
 FILES += core/dc_hw_sequencer.o
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c b/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c
new file mode 100644
index 000000000000..8aa2364b714e
--- /dev/null
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c
@@ -0,0 +1,136 @@
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
+ * Authors: AMD
+ *
+ */
+
+/* FILE POLICY AND INTENDED USAGE:
+ * This file implements the struct dc accessors declared in dc.h. struct dc
+ * is private to DC; this file is the single place that maps public accessor
+ * names onto struct dc fields. Keep it free of functional behavior so the
+ * mapping stays obvious and auditable.
+ */
+#include "dc.h"
+
+uint8_t dc_get_link_count(const struct dc *dc)
+{
+	return dc->link_count;
+}
+
+struct dc_context *dc_get_ctx(const struct dc *dc)
+{
+	return dc->ctx;
+}
+
+const struct dc_caps *dc_get_caps(const struct dc *dc)
+{
+	return &dc->caps;
+}
+
+const struct dc_config *dc_get_config(const struct dc *dc)
+{
+	return &dc->config;
+}
+
+struct dc_debug_options *dc_get_debug_options(struct dc *dc)
+{
+	return &dc->debug;
+}
+
+struct dc_state *dc_get_current_state(const struct dc *dc)
+{
+	return dc->current_state;
+}
+
+bool dc_is_idle_optimizations_allowed(const struct dc *dc)
+{
+	return dc->idle_optimizations_allowed;
+}
+
+struct resource_pool *dc_get_res_pool(const struct dc *dc)
+{
+	return dc->res_pool;
+}
+
+struct clk_mgr *dc_get_clk_mgr(struct dc *dc)
+{
+	return dc->clk_mgr;
+}
+
+bool dc_get_dcc_compression_cap(const struct dc *dc,
+		const struct dc_dcc_surface_param *input,
+		struct dc_surface_dcc_cap *output)
+{
+	if (!dc->cap_funcs.get_dcc_compression_cap)
+		return false;
+
+	return dc->cap_funcs.get_dcc_compression_cap(dc, input, output);
+}
+
+bool dc_get_subvp_en(struct dc *dc, struct dc_state *context)
+{
+	if (!dc->cap_funcs.get_subvp_en)
+		return false;
+
+	return dc->cap_funcs.get_subvp_en(dc, context);
+}
+
+bool dc_log_hw_state(struct dc *dc, struct dc_log_buffer_ctx *log_ctx)
+{
+	if (!dc->hwss.log_hw_state)
+		return false;
+
+	dc->hwss.log_hw_state(dc, log_ctx);
+	return true;
+}
+
+bool dc_get_dcc_en_bits(struct dc *dc, int *dcc_en_bits)
+{
+	if (!dc->hwss.get_dcc_en_bits)
+		return false;
+
+	dc->hwss.get_dcc_en_bits(dc, dcc_en_bits);
+	return true;
+}
+
+void dc_prepare_ddc(struct dc_link *link)
+{
+	if (link->dc->hwss.prepare_ddc)
+		link->dc->hwss.prepare_ddc(link);
+}
+
+bool dc_is_fbc_compressor_available(const struct dc *dc)
+{
+	return dc->fbc_compressor != NULL;
+}
+
+void dc_set_fbc_gpu_addr(struct dc *dc, uint64_t gpu_addr)
+{
+	dc->ctx->fbc_gpu_addr = gpu_addr;
+}
+
+void dc_set_dml2_alt_ch_cfg(struct dc *dc,
+		const struct dml2_soc_alt_ch_info *alt_ch_cfg)
+{
+	dc->dml2_options.alt_ch_cfg = *alt_ch_cfg;
+}
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_link_exports.c b/drivers/gpu/drm/amd/display/dc/core/dc_link_exports.c
index 5926e8a4f95a..d2f52e4839fe 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_link_exports.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_link_exports.c
@@ -545,6 +545,91 @@ void dc_link_edp_replay_residency(const struct dc_link *link,
 		link->dc->link_srv->edp_replay_residency(link, residency, is_start, mode);
 }
 
+void dc_link_edp_get_psr_residency(const struct dc_link *link,
+		uint32_t *residency, enum psr_residency_mode mode)
+{
+	if (link && link->dc && link->dc->link_srv)
+		link->dc->link_srv->edp_get_psr_residency(link, residency, mode);
+}
+
+bool dc_link_edp_set_sink_vtotal_in_psr_active(const struct dc_link *link,
+		uint16_t psr_vtotal_idle, uint16_t psr_vtotal_su)
+{
+	if (!link || !link->dc || !link->dc->link_srv)
+		return false;
+
+	return link->dc->link_srv->edp_set_sink_vtotal_in_psr_active(
+			link, psr_vtotal_idle, psr_vtotal_su);
+}
+
+bool dc_link_edp_send_replay_cmd(struct dc_link *link,
+		enum replay_FW_Message_type msg,
+		union dmub_replay_cmd_set *cmd_data)
+{
+	if (!link || !link->dc || !link->dc->link_srv)
+		return false;
+
+	return link->dc->link_srv->edp_send_replay_cmd(link, msg, cmd_data);
+}
+
+bool dc_link_edp_set_coasting_vtotal(struct dc_link *link,
+		uint32_t coasting_vtotal, uint16_t frame_skip_number)
+{
+	if (!link || !link->dc || !link->dc->link_srv)
+		return false;
+
+	return link->dc->link_srv->edp_set_coasting_vtotal(
+			link, coasting_vtotal, frame_skip_number);
+}
+
+bool dc_link_edp_replay_get_cumulative_residency(const struct dc_link *link,
+		uint32_t *residency_milli_pct)
+{
+	if (!link || !link->dc || !link->dc->link_srv)
+		return false;
+
+	return link->dc->link_srv->edp_replay_get_cumulative_residency(
+			link, residency_milli_pct);
+}
+
+bool dc_link_edp_set_replay_power_opt_and_coasting_vtotal(
+		struct dc_link *link, const unsigned int *power_opts,
+		uint32_t coasting_vtotal, uint16_t frame_skip_number)
+{
+	if (!link || !link->dc || !link->dc->link_srv)
+		return false;
+
+	return link->dc->link_srv->edp_set_replay_power_opt_and_coasting_vtotal(
+			link, power_opts, coasting_vtotal, frame_skip_number);
+}
+
+bool dc_link_dp_setup_replay(struct dc_link *link,
+		const struct dc_stream_state *stream)
+{
+	if (!link || !link->dc || !link->dc->link_srv)
+		return false;
+
+	return link->dc->link_srv->dp_setup_replay(link, stream);
+}
+
+uint8_t dc_link_get_ddc_aux_inst(const struct dc_link *link)
+{
+	if (!link || !link->dc || !link->dc->link_srv)
+		return 0;
+
+	return link->dc->link_srv->get_ddc_aux_inst(link);
+}
+
+enum dp_link_encoding dc_link_dp_get_encoding_format(
+		const struct dc_link *link)
+{
+	if (!link || !link->dc || !link->dc->link_srv)
+		return DP_8b_10b_ENCODING;
+
+	return link->dc->link_srv->dp_get_encoding_format(
+			&link->verified_link_cap);
+}
+
 bool dc_link_get_pr_state(const struct dc_link *link, uint64_t *state)
 {
 	return link->dc->link_srv->dp_pr_get_state(link, state);
diff --git a/drivers/gpu/drm/amd/display/dc/dc.h b/drivers/gpu/drm/amd/display/dc/dc.h
index 916fa87d0dbc..f0c84abab0fb 100644
--- a/drivers/gpu/drm/amd/display/dc/dc.h
+++ b/drivers/gpu/drm/amd/display/dc/dc.h
@@ -2464,6 +2464,92 @@ uint32_t dc_bandwidth_in_kbps_from_timing(
 		const struct dc_crtc_timing *timing,
 		const enum dc_link_encoding_format link_encoding);
 
+/*
+ * DC accessors.
+ *
+ * struct dc is private to DC. These accessors are the supported way for
+ * DM and DAL modules to query DC-wide state. Some of them return pointers
+ * to still-public sub-structures; treat those as read-only unless the
+ * documentation says otherwise.
+ */
+
+/* Number of links; valid indices for dc_get_link_at_index(). */
+uint8_t dc_get_link_count(const struct dc *dc);
+
+/* The DC context (logging, register access, dmub service). */
+struct dc_context *dc_get_ctx(const struct dc *dc);
+
+/* Capabilities detected at dc_create() time. Read-only. */
+const struct dc_caps *dc_get_caps(const struct dc *dc);
+
+/* Configuration captured at dc_create() time. Read-only. */
+const struct dc_config *dc_get_config(const struct dc *dc);
+
+/* Debug overrides (module parameters, debugfs). Writable. */
+struct dc_debug_options *dc_get_debug_options(struct dc *dc);
+
+/* The currently committed state. Owned by DC; read-only for DM. */
+struct dc_state *dc_get_current_state(const struct dc *dc);
+
+/* Whether DC may enter idle power optimizations right now. */
+bool dc_is_idle_optimizations_allowed(const struct dc *dc);
+
+/*
+ * The hardware resource pool (DSC engines, audio instances, DMCU/ABM...).
+ * Interim accessor; prefer purpose-built DC interfaces where available.
+ */
+struct resource_pool *dc_get_res_pool(const struct dc *dc);
+
+/* The clock manager. Interim accessor. */
+struct clk_mgr *dc_get_clk_mgr(struct dc *dc);
+
+/*
+ * Query DCC compression support for a surface.
+ * return false - when the asic does not implement the query.
+ */
+bool dc_get_dcc_compression_cap(const struct dc *dc,
+		const struct dc_dcc_surface_param *input,
+		struct dc_surface_dcc_cap *output);
+
+/*
+ * Whether SubVP is enabled in the given state.
+ * return false - when the asic does not support SubVP.
+ */
+bool dc_get_subvp_en(struct dc *dc, struct dc_state *context);
+
+/*
+ * Dump hardware state into the log buffer, or into the kernel log when
+ * log_ctx is NULL.
+ * return false - when the asic does not implement the dump.
+ */
+bool dc_log_hw_state(struct dc *dc, struct dc_log_buffer_ctx *log_ctx);
+
+/*
+ * Read the per-pipe DCC enable bits.
+ * return false - when the asic does not implement the query.
+ */
+bool dc_get_dcc_en_bits(struct dc *dc, int *dcc_en_bits);
+
+/*
+ * Run the DDC prepare sequence on the link ahead of aux transactions that
+ * require a prepared DDC line. Optional; silently skipped when the asic
+ * does not implement it.
+ */
+void dc_prepare_ddc(struct dc_link *link);
+
+/* Whether an FBC compressor is instantiated for this DC. */
+bool dc_is_fbc_compressor_available(const struct dc *dc);
+
+/*
+ * Provide the GPU address of the FBC compression buffer that DM allocated.
+ * Only meaningful while an FBC compressor is instantiated.
+ */
+void dc_set_fbc_gpu_addr(struct dc *dc, uint64_t gpu_addr);
+
+/* Configure the alternate channel aperture consumed by DML2. */
+void dc_set_dml2_alt_ch_cfg(struct dc *dc,
+		const struct dml2_soc_alt_ch_info *alt_ch_cfg);
+
 /* Link Interfaces */
 /* Return an enumerated dc_link.
  * dc_link order is constant and determined at
@@ -3019,6 +3105,94 @@ bool dc_link_set_pr_general_cmd(struct dc_link *link,
 void dc_link_edp_replay_residency(const struct dc_link *link,
 		unsigned int *residency, bool is_start, enum pr_residency_mode mode);
 
+/*
+ * Measure PSR residency for the given link.
+ * mode: PSR_RESIDENCY_MODE_PHY, PSR_RESIDENCY_MODE_ALPM, or
+ *       PSR_RESIDENCY_MODE_ENABLEMENT_PERIOD
+ */
+void dc_link_edp_get_psr_residency(const struct dc_link *link,
+		uint32_t *residency, enum psr_residency_mode mode);
+
+/*
+ * Set the sink vtotal in psr active to restore sink timing after
+ * exit psr with firmware initiated mode switching.
+ * return false - if the setting is not applied by firmware.
+ */
+bool dc_link_edp_set_sink_vtotal_in_psr_active(const struct dc_link *link,
+		uint16_t psr_vtotal_idle, uint16_t psr_vtotal_su);
+
+/*
+ * Send general command to Panel Replay firmware:
+ *
+ * @link: link to send the replay command on
+ * @msg: message type which indicates the variable passed to DMUB
+ * @cmd_data: payload for message types that carry one
+ *
+ * return: true if successful, false otherwise
+ */
+bool dc_link_edp_send_replay_cmd(struct dc_link *link,
+		enum replay_FW_Message_type msg,
+		union dmub_replay_cmd_set *cmd_data);
+
+/*
+ * Set panel replay coasting vtotal.
+ *
+ * @link: link to set the coasting vtotal on
+ * @coasting_vtotal: coasting vtotal to program
+ * @frame_skip_number: number of frames to skip
+ *
+ * return: true if successful, false otherwise
+ */
+bool dc_link_edp_set_coasting_vtotal(struct dc_link *link,
+		uint32_t coasting_vtotal, uint16_t frame_skip_number);
+
+/*
+ * Measure cumulative Panel Replay residency for the given link.
+ *
+ * @link: pointer to the dc_link struct instance
+ * @residency_milli_pct: residency in milli-percentage
+ *
+ * return: true if successful, false otherwise
+ */
+bool dc_link_edp_replay_get_cumulative_residency(const struct dc_link *link,
+		uint32_t *residency_milli_pct);
+
+/*
+ * Set panel replay power optimization and coasting vtotal together.
+ *
+ * @link: link to configure
+ * @power_opts: power optimization bits to enable
+ * @coasting_vtotal: coasting vtotal to program
+ * @frame_skip_number: number of frames to skip
+ *
+ * return: true if successful, false otherwise
+ */
+bool dc_link_edp_set_replay_power_opt_and_coasting_vtotal(
+		struct dc_link *link, const unsigned int *power_opts,
+		uint32_t coasting_vtotal, uint16_t frame_skip_number);
+
+/*
+ * Set up the link for panel replay.
+ *
+ * @link: link to configure
+ * @stream: stream to enable panel replay for
+ *
+ * return: true if successful, false otherwise
+ */
+bool dc_link_dp_setup_replay(struct dc_link *link,
+		const struct dc_stream_state *stream);
+
+/*
+ * Get the instance id of the DDC aux service backing the link.
+ */
+uint8_t dc_link_get_ddc_aux_inst(const struct dc_link *link);
+
+/*
+ * Get the DP link encoding format of the link's verified link settings.
+ */
+enum dp_link_encoding dc_link_dp_get_encoding_format(
+		const struct dc_link *link);
+
 /*
  * Get Panel Replay state:
  *

-- 
2.56.0

