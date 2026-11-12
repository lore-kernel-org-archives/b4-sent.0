From: Dave Airlie <airlied@redhat.com>
Date: Thu, 12 Nov 2026 11:43:40 +1000
Subject: [PATCH 05/19] drm/amd/display/amdgpu_dm: Use DC accessors in
 psr/replay/dmub/hdcp/irq paths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-amdgpu-dc-cleanup-v1-5-0fae41718ad2@redhat.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=19612; i=airlied@redhat.com;
 h=from:subject:message-id; bh=6a/YqPSTy1vgUxCsZOjr+QwHswyf6cWD4E2N8Gw6QFU=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq9RnPJ1JwI7/zpazaYYOznIaBAOneSwZ7B18MW
 pWk9GgpShKJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavUZzwAKCRAMdPNZecSG
 vqmdEACraGyJ3yI+Z592ki7FPHPkpEOJNXv/go8bkaobgFVr7Qj6YMj+FbBU/l5/epqs/Phne+p
 B1Zdad3fjj2BrTVWiE4C7p966mNahIepFXpMYJuP8u8DfzUAedxvtOJfb/jOzz7qjHr4VRg/MJb
 8oxWTyNCdqp9z42eppev8Yz/wwry0fHVFXFoNSMzPTV2tYpLjw1urgwuc93KY7FIKw7bCgNFlT0
 rSERjVF8y7Y8Nqz6RvParKrMZsrPwiqlWtfRBqIxfcW6PkUad8PjtFIwnLyNEeLkGLGXucy/cQs
 LVSgLnFmLaTovza+pv7oT6uQpUaHtXGEfaSaRa7XdWo+TuVvaF4XaPBcAt/fITAfkZMUK3g7K8Y
 b788esGaOl7Lc3HiqKSEXpwr8zQoTQJfAq+eO0AzFH3ogIIiFukhUCzWGr23Ig5Dx9qYFanzxwe
 m4C2F/xcEgDC2xpBcbiV51BafEkbq6y1M1Xg3IsN48tLLZgOHGOWyZ5UiZwkfbeAy1ETDlMGcOI
 KrXy4/53fax6rBFE4wSqmDywcNKtd4bwDv3z0iyF/cih8OKSkGB2ptTXI8f/8ibnC7G9rdpyh25
 cN7Rqb4XBFXGrMZ7WHfm29AWDKUfiBcYym8vCvteVSk2n1uvQ1ymbDJvbNx/PBYjlCIUW4r6EFQ
 rh/JaV0/FRfgvqw==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace direct struct dc member dereferences with the DC accessor
layer in amdgpu_dm_psr.c, amdgpu_dm_replay.c, amdgpu_dm_dmub.c,
amdgpu_dm_hdcp.c and amdgpu_dm_irq.c.

Add dc_get_dce_version() for the frequent ctx->dce_version reads and
split the debug options accessor into a const read view
(dc_get_debug_options) and an interim writable view
(dc_get_debug_options_mutable) for the remaining module parameter and
debugfs write sites.

Also constify the dc_color_caps consumers in the color module so
dc_get_caps() read views can flow through them.

Part of making struct dc private to DC.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c | 41 ++++++++++++----------
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_hdcp.c | 39 ++++++++++----------
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c  | 22 ++++++------
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_psr.c  | 10 +++---
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_replay.c   | 10 +++---
 drivers/gpu/drm/amd/display/dc/core/dc_accessors.c | 12 ++++++-
 drivers/gpu/drm/amd/display/dc/dc.h                | 10 ++++--
 7 files changed, 85 insertions(+), 59 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c
index 0ea8f9a582cc..af2cda9080d9 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c
@@ -179,6 +179,7 @@ dm_get_alt_channel_pstate_switch_aperture(struct amdgpu_device *adev,
 		G7_PSTATE_APERTURE2_ID,
 	};
 	struct mem_reserved_info apertures[ARRAY_SIZE(region_ids)];
+	struct dml2_soc_alt_ch_info alt_ch_cfg = {0};
 	u64 aperture_mc_bases[ARRAY_SIZE(region_ids)];
 	u32 i;
 	int r;
@@ -214,11 +215,13 @@ dm_get_alt_channel_pstate_switch_aperture(struct amdgpu_device *adev,
 		hw_params->soc_fb_info.alt_channel_region_size[i] =
 			apertures[i].reserved_region_size;
 		/* DML consumes the MC base address bits [47:16]. */
-		adev->dm.dc->dml2_options.alt_ch_cfg.region_base_addr_47_16[i] =
+		alt_ch_cfg.region_base_addr_47_16[i] =
 				(u32)(aperture_mc_bases[i] >> 16);
-		adev->dm.dc->dml2_options.alt_ch_cfg.region_size_bytes[i] =
+		alt_ch_cfg.region_size_bytes[i] =
 				(u32)apertures[i].reserved_region_size;
 	}
+
+	dc_set_dml2_alt_ch_cfg(adev->dm.dc, &alt_ch_cfg);
 }
 
 
@@ -229,9 +232,10 @@ int dm_dmub_hw_init(struct amdgpu_device *adev)
 	struct dmub_srv_fb_info *fb_info = adev->dm.dmub_fb_info;
 	const struct firmware *dmub_fw = adev->dm.dmub_fw;
 	struct dc *dc = adev->dm.dc;
-	struct dmcu *dmcu = adev->dm.dc->res_pool->dmcu;
-	struct abm *abm = adev->dm.dc->res_pool->abm;
-	struct dc_context *ctx = adev->dm.dc->ctx;
+	struct resource_pool *res_pool = dc_get_res_pool(dc);
+	struct dmcu *dmcu = res_pool->dmcu;
+	struct abm *abm = res_pool->abm;
+	struct dc_context *ctx = dc_get_ctx(adev->dm.dc);
 	struct dmub_srv_hw_params hw_params;
 	enum dmub_status status;
 	const unsigned char *fw_inst_const, *fw_bss_data;
@@ -335,14 +339,15 @@ int dm_dmub_hw_init(struct amdgpu_device *adev)
 	hw_params.fb_info = fb_info;
 
 	/* Enable usb4 dpia in the FW APU */
-	if (dc->caps.is_apu &&
-		dc->res_pool->usb4_dpia_count != 0 &&
-		!dc->debug.dpia_debug.bits.disable_dpia) {
+	if (dc_get_caps(dc)->is_apu &&
+		dc_get_res_pool(dc)->usb4_dpia_count != 0 &&
+		!dc_get_debug_options(dc)->dpia_debug.bits.disable_dpia) {
 		hw_params.dpia_supported = true;
-		hw_params.disable_dpia = dc->debug.dpia_debug.bits.disable_dpia;
+		hw_params.disable_dpia = dc_get_debug_options(dc)->dpia_debug.bits.disable_dpia;
 		hw_params.dpia_hpd_int_enable_supported = false;
-		hw_params.enable_non_transparent_setconfig = dc->config.consolidated_dpia_dp_lt;
-		hw_params.disable_dpia_bw_allocation = !dc->config.usb4_bw_alloc_support;
+		hw_params.enable_non_transparent_setconfig =
+			dc_get_config(dc)->consolidated_dpia_dp_lt;
+		hw_params.disable_dpia_bw_allocation = !dc_get_config(dc)->usb4_bw_alloc_support;
 	}
 
 	switch (amdgpu_ip_version(adev, DCE_HWIP, 0)) {
@@ -375,9 +380,9 @@ int dm_dmub_hw_init(struct amdgpu_device *adev)
 		abm->dmcu_is_running = dmcu->funcs->is_dmcu_initialized(dmcu);
 	}
 
-	if (!adev->dm.dc->ctx->dmub_srv)
-		adev->dm.dc->ctx->dmub_srv = dc_dmub_srv_create(adev->dm.dc, dmub_srv);
-	if (!adev->dm.dc->ctx->dmub_srv) {
+	if (!dc_get_ctx(adev->dm.dc)->dmub_srv)
+		dc_get_ctx(adev->dm.dc)->dmub_srv = dc_dmub_srv_create(adev->dm.dc, dmub_srv);
+	if (!dc_get_ctx(adev->dm.dc)->dmub_srv) {
 		drm_err(adev_to_drm(adev), "Couldn't allocate DC DMUB server!\n");
 		return -ENOMEM;
 	}
@@ -401,13 +406,13 @@ int dm_dmub_hw_init(struct amdgpu_device *adev)
 		if (adev->dm.dmcub_fw_version &&
 		    adev->dm.dmcub_fw_version >= DMUB_FW_VERSION(4, 0, 0) &&
 		    adev->dm.dmcub_fw_version < DMUB_FW_VERSION(4, 0, 59))
-			adev->dm.dc->debug.sanity_checks = true;
+			dc_get_debug_options_mutable(adev->dm.dc)->sanity_checks = true;
 		break;
 	case IP_VERSION(3, 1, 4):
 		if (adev->dm.dmcub_fw_version &&
 		    adev->dm.dmcub_fw_version >= DMUB_FW_VERSION(4, 0, 0) &&
 		    adev->dm.dmcub_fw_version < DMUB_FW_VERSION(8, 0, 16))
-			adev->dm.dc->debug.sanity_checks = true;
+			dc_get_debug_options_mutable(adev->dm.dc)->sanity_checks = true;
 		break;
 	default:
 		break;
@@ -565,7 +570,7 @@ STATIC_IFN_KUNIT uint32_t amdgpu_dm_dmub_reg_read(void *ctx, uint32_t address)
 {
 	struct amdgpu_device *adev = ctx;
 
-	return dm_read_reg(adev->dm.dc->ctx, address);
+	return dm_read_reg(dc_get_ctx(adev->dm.dc), address);
 }
 EXPORT_IF_KUNIT(amdgpu_dm_dmub_reg_read);
 
@@ -574,7 +579,7 @@ STATIC_IFN_KUNIT void amdgpu_dm_dmub_reg_write(void *ctx, uint32_t address,
 {
 	struct amdgpu_device *adev = ctx;
 
-	return dm_write_reg(adev->dm.dc->ctx, address, value);
+	return dm_write_reg(dc_get_ctx(adev->dm.dc), address, value);
 }
 EXPORT_IF_KUNIT(amdgpu_dm_dmub_reg_write);
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_hdcp.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_hdcp.c
index 47cbc826ed45..73b56e078cbe 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_hdcp.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_hdcp.c
@@ -43,7 +43,7 @@ STATIC_IFN_KUNIT bool lp_write_i2c(void *handle, uint32_t address, const uint8_t
 	struct dc_link *link = handle;
 	struct i2c_payload i2c_payloads[] = {{true, address, size, (void *)data} };
 	struct i2c_command cmd = {i2c_payloads, 1, I2C_COMMAND_ENGINE_HW,
-				  link->dc->caps.i2c_speed_in_khz};
+				  dc_get_caps(link->dc)->i2c_speed_in_khz};
 
 	return dm_helpers_submit_i2c(link->ctx, link, &cmd);
 }
@@ -56,7 +56,7 @@ STATIC_IFN_KUNIT bool lp_read_i2c(void *handle, uint32_t address, uint8_t offset
 	struct i2c_payload i2c_payloads[] = {{true, address, 1, &offset},
 					     {false, address, size, data} };
 	struct i2c_command cmd = {i2c_payloads, 2, I2C_COMMAND_ENGINE_HW,
-				  link->dc->caps.i2c_speed_in_khz};
+				  dc_get_caps(link->dc)->i2c_speed_in_khz};
 
 	return dm_helpers_submit_i2c(link->ctx, link, &cmd);
 }
@@ -308,9 +308,9 @@ void hdcp_update_display(struct hdcp_workqueue *hdcp_work,
 	hdcp_w->aconnector[conn_index] = aconnector;
 
 	hdcp_get_link_display_adjustments(enable_encryption, content_type,
-			dc->caps.fused_io_supported,
-			dc->debug.hdcp_lc_force_fw_enable,
-			dc->debug.hdcp_lc_enable_sw_fallback,
+			dc_get_caps(dc)->fused_io_supported,
+			dc_get_debug_options(dc)->hdcp_lc_force_fw_enable,
+			dc_get_debug_options(dc)->hdcp_lc_enable_sw_fallback,
 			&link_adjust, &display_adjust);
 	hdcp_update_display_encryption_control(hdcp_work, hdcp_w, conn_index,
 					      enable_encryption);
@@ -676,8 +676,11 @@ void update_config(void *handle, struct cp_psp_stream_config *config)
 	link->adjust.auth_delay = 2;
 	link->adjust.retry_limit = MAX_NUM_OF_ATTEMPTS;
 	link->adjust.hdcp1.disable = 0;
-	link->adjust.hdcp2.use_fw_locality_check = (dc->caps.fused_io_supported || dc->debug.hdcp_lc_force_fw_enable);
-	link->adjust.hdcp2.use_sw_locality_fallback = dc->debug.hdcp_lc_enable_sw_fallback;
+	link->adjust.hdcp2.use_fw_locality_check =
+		(dc_get_caps(dc)->fused_io_supported ||
+		 dc_get_debug_options(dc)->hdcp_lc_force_fw_enable);
+	link->adjust.hdcp2.use_sw_locality_fallback =
+		dc_get_debug_options(dc)->hdcp_lc_enable_sw_fallback;
 	hdcp_w->encryption_status[display->index] = MOD_HDCP_ENCRYPTION_STATUS_HDCP_OFF;
 
 	DRM_DEBUG_DRIVER("[HDCP_DM] display %d, CP %d, type %d\n", aconnector->base.index,
@@ -839,7 +842,7 @@ static const struct bin_attribute data_attr = {
 struct hdcp_workqueue *hdcp_create_workqueue(struct amdgpu_device *adev,
 					     struct cp_psp *cp_psp, struct dc *dc)
 {
-	int max_caps = dc->caps.max_links;
+	int max_caps = dc_get_caps(dc)->max_links;
 	struct hdcp_workqueue *hdcp_work;
 	int i = 0;
 
@@ -874,16 +877,16 @@ struct hdcp_workqueue *hdcp_create_workqueue(struct amdgpu_device *adev,
 		struct mod_hdcp_ddc_funcs *ddc_funcs = &config->ddc.funcs;
 
 		config->psp.handle = &adev->psp;
-		if (dc->ctx->dce_version == DCN_VERSION_3_1  ||
-		    dc->ctx->dce_version == DCN_VERSION_3_14 ||
-		    dc->ctx->dce_version == DCN_VERSION_3_15 ||
-		    dc->ctx->dce_version == DCN_VERSION_3_16 ||
-		    dc->ctx->dce_version == DCN_VERSION_3_2  ||
-		    dc->ctx->dce_version == DCN_VERSION_3_21 ||
-		    dc->ctx->dce_version == DCN_VERSION_3_5  ||
-		    dc->ctx->dce_version == DCN_VERSION_3_51 ||
-		    dc->ctx->dce_version == DCN_VERSION_3_6  ||
-		    dc->ctx->dce_version == DCN_VERSION_4_01)
+		if (dc_get_dce_version(dc) == DCN_VERSION_3_1  ||
+		    dc_get_dce_version(dc) == DCN_VERSION_3_14 ||
+		    dc_get_dce_version(dc) == DCN_VERSION_3_15 ||
+		    dc_get_dce_version(dc) == DCN_VERSION_3_16 ||
+		    dc_get_dce_version(dc) == DCN_VERSION_3_2  ||
+		    dc_get_dce_version(dc) == DCN_VERSION_3_21 ||
+		    dc_get_dce_version(dc) == DCN_VERSION_3_5  ||
+		    dc_get_dce_version(dc) == DCN_VERSION_3_51 ||
+		    dc_get_dce_version(dc) == DCN_VERSION_3_6  ||
+		    dc_get_dce_version(dc) == DCN_VERSION_4_01)
 			config->psp.caps.dtm_v3_supported = 1;
 
 		config->ddc.handle = dc_get_link_at_index(dc, i);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c
index 5b4ff079cd55..a7ee30c66a48 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c
@@ -808,7 +808,7 @@ static inline int dm_irq_state(struct amdgpu_device *adev,
 
 	st = (state == AMDGPU_IRQ_STATE_ENABLE);
 
-	if (dc && dc->caps.ips_support && dc->idle_optimizations_allowed)
+	if (dc && dc_get_caps(dc)->ips_support && dc_is_idle_optimizations_allowed(dc))
 		dc_allow_idle_optimizations(dc, false);
 
 	amdgpu_dm_irq_set(adev, irq_source, st);
@@ -989,8 +989,8 @@ void amdgpu_dm_hpd_init(struct amdgpu_device *adev)
 	 * has rather than over the whole enum: the unused slots of the DC
 	 * interrupt table hold dummy handlers that assert when touched.
 	 */
-	for (i = 0; i < adev->dm.dc->link_count; i++) {
-		const struct dc_link *link = adev->dm.dc->links[i];
+	for (i = 0; i < dc_get_link_count(adev->dm.dc); i++) {
+		const struct dc_link *link = dc_get_link_at_index(adev->dm.dc, i);
 
 		if (link->irq_source_hpd != DC_IRQ_SOURCE_INVALID &&
 		    !amdgpu_dm_irq_set(adev, link->irq_source_hpd, false))
@@ -1226,7 +1226,7 @@ EXPORT_IF_KUNIT(dm_handle_hpd_rx_offload_work);
 struct hpd_rx_irq_offload_work_queue *amdgpu_dm_hpd_rx_irq_create_workqueue(struct amdgpu_device *adev)
 {
 	struct dc *dc = adev->dm.dc;
-	int max_caps = dc->caps.max_links;
+	int max_caps = dc_get_caps(dc)->max_links;
 	int i = 0;
 	struct hpd_rx_irq_offload_work_queue *hpd_rx_offload_wq = NULL;
 
@@ -1265,7 +1265,7 @@ void amdgpu_dm_hpd_rx_irq_work_suspend(struct amdgpu_display_manager *dm)
 	int i;
 
 	if (dm->hpd_rx_offload_wq) {
-		for (i = 0; i < dm->dc->caps.max_links; i++)
+		for (i = 0; i < dc_get_caps(dm->dc)->max_links; i++)
 			flush_workqueue(dm->hpd_rx_offload_wq[i].wq);
 	}
 }
@@ -1321,7 +1321,7 @@ void amdgpu_dm_hdmi_hpd_debounce_work(struct work_struct *work)
 
 	/* Re-detect the display */
 	scoped_guard(mutex, &adev->dm.dc_lock) {
-		if (dc->caps.ips_support && dc->ctx->dmub_srv->idle_allowed) {
+		if (dc_get_caps(dc)->ips_support && dc_get_ctx(dc)->dmub_srv->idle_allowed) {
 			dc_allow_idle_optimizations(dc, false);
 			reallow_idle = true;
 		}
@@ -1359,7 +1359,7 @@ void amdgpu_dm_hdmi_hpd_debounce_work(struct work_struct *work)
 	}
 
 	scoped_guard(mutex, &adev->dm.dc_lock) {
-		if (reallow_idle && dc->caps.ips_support)
+		if (reallow_idle && dc_get_caps(dc)->ips_support)
 			dc_allow_idle_optimizations(dc, true);
 	}
 }
@@ -1668,7 +1668,7 @@ STATIC_IFN_KUNIT void dmub_hpd_callback(struct amdgpu_device *adev,
 	}
 
 	link_index = notify->link_index;
-	link = adev->dm.dc->links[link_index];
+	link = dc_get_link_at_index(adev->dm.dc, link_index);
 	dev = adev->dm.ddev;
 
 	drm_connector_list_iter_begin(dev, &iter);
@@ -2362,7 +2362,7 @@ int amdgpu_dm_dce110_register_irq_handlers(struct amdgpu_device *adev)
 	unsigned int client_id = AMDGPU_IRQ_CLIENTID_LEGACY;
 	/* Use different interrupts for VBLANK on DCE 6 vs. newer. */
 	const unsigned int vblank_d1 =
-		adev->dm.dc->ctx->dce_version >= DCE_VERSION_8_0
+		dc_get_dce_version(adev->dm.dc) >= DCE_VERSION_8_0
 		? VISLANDS30_IV_SRCID_D1_VERTICAL_INTERRUPT0 : 1;
 
 	if (adev->family >= AMDGPU_FAMILY_AI)
@@ -2413,7 +2413,7 @@ int amdgpu_dm_dce110_register_irq_handlers(struct amdgpu_device *adev)
 			return -ENOMEM;
 	}
 
-	if (dc_supports_vrr(adev->dm.dc->ctx->dce_version)) {
+	if (dc_supports_vrr(dc_get_dce_version(adev->dm.dc))) {
 		/* Use VUPDATE interrupt */
 		for (i = 0; i < adev->mode_info.num_crtc; i++) {
 			src_id = VISLANDS30_IV_SRCID_D1_V_UPDATE_INT + i * 2;
@@ -2626,7 +2626,7 @@ int amdgpu_dm_register_outbox_irq_handlers(struct amdgpu_device *adev)
 		return r;
 	}
 
-	if (dc->ctx->dmub_srv) {
+	if (dc_get_ctx(dc)->dmub_srv) {
 		i = DCN_1_0__SRCID__DMCUB_OUTBOX_LOW_PRIORITY_READY_INT;
 		int_params.int_context = INTERRUPT_LOW_IRQ_CONTEXT;
 		int_params.irq_source =
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_psr.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_psr.c
index dbad0a6d3a2b..f71f66b04d5e 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_psr.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_psr.c
@@ -37,10 +37,10 @@ bool link_supports_psrsu(struct dc_link *link)
 {
 	struct dc *dc = link->ctx->dc;
 
-	if (!dc->caps.dmcub_support)
+	if (!dc_get_caps(dc)->dmcub_support)
 		return false;
 
-	if (dc->ctx->dce_version < DCN_VERSION_3_1)
+	if (dc_get_dce_version(dc) < DCN_VERSION_3_1)
 		return false;
 
 	if (!is_psr_su_specific_panel(link))
@@ -111,7 +111,7 @@ bool amdgpu_dm_set_psr_caps(struct dc_link *link, struct amdgpu_dm_connector *ac
 	/* Reset psr version first */
 	link->psr_settings.psr_version = DC_PSR_VERSION_UNSUPPORTED;
 
-	if (!dc->caps.dmub_caps.psr)
+	if (!dc_get_caps(dc)->dmub_caps.psr)
 		return false;
 
 	if (!(link->connector_signal & SIGNAL_TYPE_EDP))
@@ -148,8 +148,8 @@ bool amdgpu_dm_psr_is_active_allowed(struct amdgpu_display_manager *dm)
 {
 	unsigned int i;
 
-	for (i = 0; i < dm->dc->current_state->stream_count; i++) {
-		const struct dc_link *link = dm->dc->current_state->streams[i]->link;
+	for (i = 0; i < dc_get_current_state(dm->dc)->stream_count; i++) {
+		const struct dc_link *link = dc_get_current_state(dm->dc)->streams[i]->link;
 
 		if (!link)
 			continue;
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_replay.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_replay.c
index ee2e4754b089..6441212f93a1 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_replay.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_replay.c
@@ -97,8 +97,8 @@ bool amdgpu_dm_set_replay_caps(struct dc_link *link, struct amdgpu_dm_connector
 	if (!amdgpu_dm_link_supports_replay(link, aconnector))
 		return false;
 
-	if (!dc->ctx->dmub_srv || !dc->ctx->dmub_srv->dmub ||
-		!dc->ctx->dmub_srv->dmub->feature_caps.replay_supported)
+	if (!dc_get_ctx(dc)->dmub_srv || !dc_get_ctx(dc)->dmub_srv->dmub ||
+		!dc_get_ctx(dc)->dmub_srv->dmub->feature_caps.replay_supported)
 		return false;
 
 	/* Mark Replay is supported in link and update related attributes
@@ -121,8 +121,10 @@ bool amdgpu_dm_set_replay_caps(struct dc_link *link, struct amdgpu_dm_connector
 
 	debug_flags = (union replay_debug_flags *)&pr_config.debug_flags;
 	debug_flags->u32All = 0;
-	debug_flags->bitfields.visual_confirm =	dc->debug.visual_confirm == VISUAL_CONFIRM_REPLAY;
-	debug_flags->bitfields.skip_crtc_disabled = dc->debug.replay_skip_crtc_disabled;
+	debug_flags->bitfields.visual_confirm =
+		dc_get_debug_options(dc)->visual_confirm == VISUAL_CONFIRM_REPLAY;
+	debug_flags->bitfields.skip_crtc_disabled =
+		dc_get_debug_options(dc)->replay_skip_crtc_disabled;
 
 	init_replay_config(link, &pr_config);
 
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c b/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c
index 8aa2364b714e..15a203fbae81 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c
@@ -42,6 +42,11 @@ struct dc_context *dc_get_ctx(const struct dc *dc)
 	return dc->ctx;
 }
 
+enum dce_version dc_get_dce_version(const struct dc *dc)
+{
+	return dc->ctx->dce_version;
+}
+
 const struct dc_caps *dc_get_caps(const struct dc *dc)
 {
 	return &dc->caps;
@@ -52,7 +57,12 @@ const struct dc_config *dc_get_config(const struct dc *dc)
 	return &dc->config;
 }
 
-struct dc_debug_options *dc_get_debug_options(struct dc *dc)
+const struct dc_debug_options *dc_get_debug_options(const struct dc *dc)
+{
+	return &dc->debug;
+}
+
+struct dc_debug_options *dc_get_debug_options_mutable(struct dc *dc)
 {
 	return &dc->debug;
 }
diff --git a/drivers/gpu/drm/amd/display/dc/dc.h b/drivers/gpu/drm/amd/display/dc/dc.h
index f0c84abab0fb..9592a95544ea 100644
--- a/drivers/gpu/drm/amd/display/dc/dc.h
+++ b/drivers/gpu/drm/amd/display/dc/dc.h
@@ -2479,14 +2479,20 @@ uint8_t dc_get_link_count(const struct dc *dc);
 /* The DC context (logging, register access, dmub service). */
 struct dc_context *dc_get_ctx(const struct dc *dc);
 
+/* The ASIC display engine version. */
+enum dce_version dc_get_dce_version(const struct dc *dc);
+
 /* Capabilities detected at dc_create() time. Read-only. */
 const struct dc_caps *dc_get_caps(const struct dc *dc);
 
 /* Configuration captured at dc_create() time. Read-only. */
 const struct dc_config *dc_get_config(const struct dc *dc);
 
-/* Debug overrides (module parameters, debugfs). Writable. */
-struct dc_debug_options *dc_get_debug_options(struct dc *dc);
+/* Debug overrides (module parameters, debugfs). Read-only view. */
+const struct dc_debug_options *dc_get_debug_options(const struct dc *dc);
+
+/* Debug overrides; writable view for module parameter and debugfs writes. */
+struct dc_debug_options *dc_get_debug_options_mutable(struct dc *dc);
 
 /* The currently committed state. Owned by DC; read-only for DM. */
 struct dc_state *dc_get_current_state(const struct dc *dc);

-- 
2.56.0

