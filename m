From: Dave Airlie <airlied@redhat.com>
Date: Thu, 12 Nov 2026 11:43:51 +1000
Subject: [PATCH 16/19] drm/amd/display: Add DC primitives for ABM hardware
 programming
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-amdgpu-dc-cleanup-v1-16-0fae41718ad2@redhat.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=21101; i=airlied@redhat.com;
 h=from:subject:message-id; bh=PmLI0FS8dx2UdiuqiYqRIyrFoshlA6b0Io44a0h3Qws=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq9RnQ/H/GQvF1xjnAE1Ants0tqgFdZJRcI0uGZ
 QL4VaBUEqSJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavUZ0AAKCRAMdPNZecSG
 vt4RD/wN0QBp0FAD5op2NRxgmOJ+iZQMH0Wrhz6+16UX0By4Dx/7znxUix5b8khm+GbO5dFBpI/
 PKaPU1qXM0kSu+v2zkh6jagRDecIqexc4Ge1IBEGdLr5ic9f/StjXv0CK+DEXJsntp0FH6PtCGs
 hZkTekRcXuHaGDdZbN1DZt/6l61L/ggk4Q31qsG3+YsMHMfYnVKYyyNxVBTFVKz7c93UZ9JmreE
 U7yimA6PwrrbjjvXglpuQsZQjL/lenIUn1OGF1R8DmT4SgNc+4TvGSqvLNjprVvCJOOJgDp8uJu
 tGWiy+d2sU1plsNqOWj3wdP0Z0PqCSSnl7nLXJGkwrQ+iiVyAnzeL/p5aT4FMJEMwaFhjXPWo4a
 oTEbd6crlEHEr7TRWETgVOfdYE1mDCvIJmmdJ1SFXQxDY7yLhmDMHY5f4gUIQanUgND0YtRwSR9
 JK+HNucbtKQi42sCd2Rfi93A+zk6w2Nsa5oYAF1jUjc06cdZeQK8thJWVppjr0LKiYbZPUScvCP
 RssnmUU9914odKvzphuHXvNtB7t/z371FxoZLHVmGJxdUQmc4m+160y9IA1NX/7vqmsbmgNXYi0
 wwcnqmTj4lRFuddhfFTIfSjR7lk1V6MyX7unXHGPavSshN4VyEVIZ+yMkpca/Q2ud3I7yfGriS2
 29Skly+RHOqHaqw==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ABM code in modules/power programmed the DMCU iRAM and the DMCUB
ABM configuration through struct resource_pool, forcing the power
module and DM to reach into DC internals.

Keep the ABM curve and iRAM table baking in modules/power where it
belongs, and add thin DC-side hardware primitives that the module
drives with baked blobs:

- dc_has_dmcu(), dc_get_dmcu_abm_version(), dc_dmcu_is_initialized()
  for the dispatch decisions
- dc_dmcu_load_iram() to load a baked iRAM blob at a given offset
- dc_abm_program_config() to program a baked ABM configuration table
- dc_abm_is_supported(), dc_abm_set_event() and dc_abm_set_strength()
  for the ABM event/strength dispatch

dmcu_load_iram() and dmub_init_abm_config() stay in modules/power and
now take struct dc; struct dmcu_iram_parameters and enum abm_defines
stay in power_helpers.h with them. The module no longer references
struct resource_pool.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c  |   9 +-
 drivers/gpu/drm/amd/display/dc/Makefile            |   1 +
 drivers/gpu/drm/amd/display/dc/core/dc_abm.c       | 121 ++++++++++++++++
 drivers/gpu/drm/amd/display/dc/inc/dc.h            |  42 ++++++
 drivers/gpu/drm/amd/display/modules/power/power.c  |   3 +-
 .../gpu/drm/amd/display/modules/power/power_abm.c  | 153 +++++++--------------
 .../drm/amd/display/modules/power/power_helpers.h  |  17 +--
 7 files changed, 218 insertions(+), 128 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index cb122cb32905..b601ec00ba05 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -1207,9 +1207,6 @@ STATIC_IFN_KUNIT int dm_late_init(struct amdgpu_ip_block *ip_block)
 	struct dmcu_iram_parameters params;
 	unsigned int linear_lut[16];
 	int i;
-	struct dmcu *dmcu = NULL;
-
-	dmcu = dc_get_res_pool(adev->dm.dc)->dmcu;
 
 	/* Init the boot time CRC (skip in resume) */
 	if ((adev->in_suspend == 0) &&
@@ -1234,8 +1231,8 @@ STATIC_IFN_KUNIT int dm_late_init(struct amdgpu_ip_block *ip_block)
 	 * dmcu object will be null.
 	 * ABM 2.4 and up are implemented on dmcub.
 	 */
-	if (dmcu) {
-		if (!dmcu_load_iram(dmcu, params))
+	if (dc_has_dmcu(adev->dm.dc)) {
+		if (!dmcu_load_iram(adev->dm.dc, params))
 			return -EINVAL;
 	} else if (dc_get_ctx(adev->dm.dc)->dmub_srv) {
 		struct dc_link *edp_links[MAX_NUM_EDP];
@@ -1243,7 +1240,7 @@ STATIC_IFN_KUNIT int dm_late_init(struct amdgpu_ip_block *ip_block)
 
 		dc_get_edp_links(adev->dm.dc, edp_links, &edp_num);
 		for (i = 0; i < edp_num; i++) {
-			if (!dmub_init_abm_config(dc_get_res_pool(adev->dm.dc), params, i))
+			if (!dmub_init_abm_config(adev->dm.dc, params, i))
 				return -EINVAL;
 		}
 	}
diff --git a/drivers/gpu/drm/amd/display/dc/Makefile b/drivers/gpu/drm/amd/display/dc/Makefile
index c0fc7f7d241d..2ff025af0f92 100644
--- a/drivers/gpu/drm/amd/display/dc/Makefile
+++ b/drivers/gpu/drm/amd/display/dc/Makefile
@@ -69,6 +69,7 @@ FILES += dc_helper.o
 FILES += dc_memory_pool.o
 FILES += core/dc.o
 FILES += core/dc_accessors.o
+FILES += core/dc_abm.o
 FILES += dc_api_dispatch/api_shim.o
 FILES += core/dc_debug.o
 FILES += core/dc_hw_sequencer.o
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_abm.c b/drivers/gpu/drm/amd/display/dc/core/dc_abm.c
new file mode 100644
index 000000000000..1ed4b5fb6f93
--- /dev/null
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_abm.c
@@ -0,0 +1,121 @@
+// SPDX-License-Identifier: MIT
+//
+// Copyright 2026 Advanced Micro Devices, Inc.
+//
+/* FILE POLICY AND INTENDED USAGE:
+ * DC-side ABM (Adaptive Backlight Management) hardware primitives. DC
+ * owns the ABM and DMCU objects in the resource pool, so the dispatch to
+ * their function tables lives here; the ABM curve and iRAM table baking
+ * is policy and stays in modules/power, which hands over opaque blobs
+ * through these entry points.
+ */
+#include "dm_services.h"
+#include "dc.h"
+#include "dc_priv.h"
+#include "core_types.h"
+#include "hw/dmcu.h"
+#include "hw/abm.h"
+
+bool dc_has_dmcu(const struct dc *dc)
+{
+	return dc->res_pool && dc->res_pool->dmcu != NULL;
+}
+
+bool dc_dmcu_is_initialized(struct dc *dc)
+{
+	if (!dc->res_pool || !dc->res_pool->dmcu)
+		return false;
+
+	return dc->res_pool->dmcu->funcs->is_dmcu_initialized(
+			dc->res_pool->dmcu);
+}
+
+bool dc_dmcu_load_iram(struct dc *dc, unsigned int start_offset,
+		const char *src, unsigned int bytes)
+{
+	if (!dc->res_pool || !dc->res_pool->dmcu)
+		return false;
+
+	return dc->res_pool->dmcu->funcs->load_iram(
+			dc->res_pool->dmcu, start_offset, src, bytes);
+}
+
+bool dc_abm_is_supported(struct dc *dc, unsigned int inst)
+{
+	if (dc->res_pool->abm == NULL && dc->res_pool->multiple_abms[inst] == NULL)
+		return false;
+
+	return true;
+}
+
+bool dc_abm_program_config(struct dc *dc, const char *config,
+		unsigned int size, unsigned int inst)
+{
+	if (dc->res_pool->abm == NULL && dc->res_pool->multiple_abms[inst] == NULL)
+		return false;
+
+	if (dc->res_pool->multiple_abms[inst])
+		return dc->res_pool->multiple_abms[inst]->funcs->init_abm_config(
+				dc->res_pool->multiple_abms[inst], config, size, inst);
+
+	return dc->res_pool->abm->funcs->init_abm_config(
+			dc->res_pool->abm, config, size, 0);
+}
+
+bool dc_abm_set_event(struct dc *dc,
+		unsigned int full_screen, unsigned int trans_info,
+		unsigned int hdr_mode, unsigned int scaling_enable,
+		unsigned int scaling_strength_map,
+		unsigned int inst)
+{
+	struct resource_pool *res_pool = dc->res_pool;
+	bool result = false;
+
+	if (res_pool->abm == NULL && res_pool->multiple_abms[inst] == NULL)
+		return false;
+
+	if (res_pool->multiple_abms[inst]) {
+		if (res_pool->multiple_abms[inst]->funcs->set_abm_event)
+			result = res_pool->multiple_abms[inst]->funcs->set_abm_event(
+				res_pool->multiple_abms[inst], full_screen, trans_info,
+					hdr_mode, scaling_enable, scaling_strength_map, inst);
+	} else {
+		if (res_pool->abm->funcs->set_abm_event)
+			result = res_pool->abm->funcs->set_abm_event(
+				res_pool->abm, full_screen, trans_info,
+					hdr_mode, scaling_enable, scaling_strength_map, inst);
+	}
+
+	return result;
+}
+
+bool dc_abm_set_strength(struct dc *dc,
+		unsigned int strength,
+		unsigned int inst)
+{
+	struct resource_pool *res_pool = dc->res_pool;
+	bool result = false;
+
+	if (res_pool->abm == NULL && res_pool->multiple_abms[inst] == NULL)
+		return false;
+
+	if (res_pool->multiple_abms[inst]) {
+		if (res_pool->multiple_abms[inst]->funcs->set_abm_level)
+			result = res_pool->multiple_abms[inst]->funcs->set_abm_level(
+				res_pool->multiple_abms[inst], strength);
+	} else {
+		if (res_pool->abm->funcs->set_abm_level)
+			result = res_pool->abm->funcs->set_abm_level(
+					res_pool->abm, strength);
+	}
+
+	return result;
+}
+
+unsigned int dc_get_dmcu_abm_version(const struct dc *dc)
+{
+	if (!dc->res_pool || !dc->res_pool->dmcu)
+		return 0;
+
+	return dc->res_pool->dmcu->dmcu_version.abm_version;
+}
diff --git a/drivers/gpu/drm/amd/display/dc/inc/dc.h b/drivers/gpu/drm/amd/display/dc/inc/dc.h
index 1cb97c7b6c16..28cd052e0727 100644
--- a/drivers/gpu/drm/amd/display/dc/inc/dc.h
+++ b/drivers/gpu/drm/amd/display/dc/inc/dc.h
@@ -2389,6 +2389,48 @@ struct resource_pool *dc_get_res_pool(const struct dc *dc);
  */
 void dc_force_max_dramclk(struct dc *dc, struct dc_state *context);
 
+/*
+ * ABM (Adaptive Backlight Management) hardware primitives.
+ *
+ * The ABM curve and iRAM table baking is module policy and lives in
+ * modules/power; these entry points program the baked blobs through the
+ * ABM/DMCU objects that DC owns. Callers pick the DMCU path with
+ * dc_has_dmcu().
+ */
+
+/* Whether ABM is implemented in the DMCU block on this ASIC. */
+bool dc_has_dmcu(const struct dc *dc);
+
+/* The DMCU firmware ABM version, 0 when there is no DMCU. */
+unsigned int dc_get_dmcu_abm_version(const struct dc *dc);
+
+/* Whether the DMCU firmware finished initializing. */
+bool dc_dmcu_is_initialized(struct dc *dc);
+
+/* Load a baked iRAM blob into the DMCU at the given offset. */
+bool dc_dmcu_load_iram(struct dc *dc, unsigned int start_offset,
+		const char *src, unsigned int bytes);
+
+/* Whether ABM is supported for the given eDP panel instance. */
+bool dc_abm_is_supported(struct dc *dc, unsigned int panel_inst);
+
+/*
+ * Program a baked ABM configuration table for the given eDP panel
+ * instance.
+ */
+bool dc_abm_program_config(struct dc *dc, const char *config,
+		unsigned int size, unsigned int panel_inst);
+
+/* Queue an ABM event (fullscreen transition info) for a panel instance. */
+bool dc_abm_set_event(struct dc *dc, unsigned int full_screen,
+		unsigned int trans_info, unsigned int hdr_mode,
+		unsigned int scaling_enable, unsigned int scaling_strength_map,
+		unsigned int panel_inst);
+
+/* Set the ABM strength for a panel instance. */
+bool dc_abm_set_strength(struct dc *dc, unsigned int strength,
+		unsigned int panel_inst);
+
 /*
  * Query DCC compression support for a surface.
  * return false - when the asic does not implement the query.
diff --git a/drivers/gpu/drm/amd/display/modules/power/power.c b/drivers/gpu/drm/amd/display/modules/power/power.c
index 32c00a515d4f..ebedcd9eb892 100644
--- a/drivers/gpu/drm/amd/display/modules/power/power.c
+++ b/drivers/gpu/drm/amd/display/modules/power/power.c
@@ -192,8 +192,7 @@ struct mod_power *mod_power_create(struct dc *dc,
 	}
 
 	// ABM used to contain 4 different configs. There is only 3 since ABM 2.3.
-	if (dc_get_res_pool(dc)->dmcu != NULL &&
-	    dc_get_res_pool(dc)->dmcu->dmcu_version.abm_version < 0x23)
+	if (dc_has_dmcu(dc) && dc_get_dmcu_abm_version(dc) < 0x23)
 		abm_max_config = 4;
 	else
 		abm_max_config = 3;
diff --git a/drivers/gpu/drm/amd/display/modules/power/power_abm.c b/drivers/gpu/drm/amd/display/modules/power/power_abm.c
index 6dabd30b4956..ae2fa3b12e1a 100644
--- a/drivers/gpu/drm/amd/display/modules/power/power_abm.c
+++ b/drivers/gpu/drm/amd/display/modules/power/power_abm.c
@@ -14,13 +14,27 @@
 #include "link_service.h"
 #include <linux/math.h>
 
-#define DC_TRACE_LEVEL_MESSAGE(...) /* do nothing */
-#define DC_TRACE_LEVEL_MESSAGEP(...) /* do nothing */
-
 #define DIV_ROUNDUP(a, b) (((a)+((b)/2))/(b))
 #define bswap16_based_on_endian(big_endian, value) \
 	((big_endian) ? cpu_to_be16(value) : cpu_to_le16(value))
 
+#define DC_TRACE_LEVEL_MESSAGE(...) /* do nothing */
+#define DC_TRACE_LEVEL_MESSAGEP(...) /* do nothing */
+
+
+#define MOD_POWER_MAX_CONCURRENT_STREAMS 32
+#define SMOOTH_BRIGHTNESS_ADJUSTMENT_TIME_IN_MS 500
+
+/* If system or panel does not report some sort of brightness percent to nits
+ * mapping, we will use following default values so backlight control using
+ * nits based interfaces will still work, but might not describe panel
+ * correctly. In this case percentage based backlight control should ideally
+ * be used.
+ * Min = 5 nits
+ * Max = 300 nits
+ */
+
+
 /* Possible Min Reduction config from least aggressive to most aggressive
  *  0    1     2     3     4     5     6     7     8     9     10    11   12
  * 100  98.0 94.1  94.1  85.1  80.3  75.3  69.4  60.0  57.6  50.2  49.8  40.0 %
@@ -230,17 +244,6 @@ struct iram_table_v_2_2 {
 };
 #pragma pack(pop)
 
-#define MOD_POWER_MAX_CONCURRENT_STREAMS 32
-#define SMOOTH_BRIGHTNESS_ADJUSTMENT_TIME_IN_MS 500
-
-/* If system or panel does not report some sort of brightness percent to nits
- * mapping, we will use following default values so backlight control using
- * nits based interfaces will still work, but might not describe panel
- * correctly. In this case percentage based backlight control should ideally
- * be used.
- * Min = 5 nits
- * Max = 300 nits
- */
 
 #define MOD_POWER_TO_CORE(mod_power)\
 		container_of(mod_power, struct core_power, mod_public)
@@ -849,7 +852,6 @@ bool mod_power_hw_init_backlight(struct mod_power *mod_power)
 {
 	struct core_power *core_power = NULL;
 	struct dc *dc = NULL;
-	struct dmcu *dmcu = NULL;
 	struct dmcu_iram_parameters params;
 	unsigned int i;
 
@@ -868,16 +870,14 @@ bool mod_power_hw_init_backlight(struct mod_power *mod_power)
 		params.backlight_lut_array_size = core_power->bl_prop[i].num_backlight_levels;
 		params.min_abm_backlight = core_power->bl_prop[i].min_abm_backlight;
 
-		dmcu = dc_get_res_pool(dc)->dmcu;
-
 		// In the case where abm is implemented on dmcub,
 		// dmcu object will be null.
 		// ABM 2.4 and up are implemented on dmcub.
-		if (dmcu) {
+		if (dc_has_dmcu(dc)) {
 			//DMCU does not support multiple eDP
-			return dmcu_load_iram(dmcu, params);
+			return dmcu_load_iram(dc, params);
 		} else if (dc_get_ctx(dc)->dmub_srv) {
-			if (!dmub_init_abm_config(dc_get_res_pool(dc), params, i))
+			if (!dmub_init_abm_config(dc, params, i))
 				return false;
 		} else
 			return false;
@@ -1659,7 +1659,7 @@ bool mod_power_is_abm_supported(struct mod_power *mod_power,
 
 	// It's only implemented on dmcub.
 	if (dc_get_ctx(dc)->dmub_srv) {
-		if (!dmub_is_abm_supported(dc_get_res_pool(dc), inst))
+		if (!dc_abm_is_supported(dc, inst))
 			return false;
 	} else
 		return false;
@@ -1683,9 +1683,8 @@ bool mod_power_abm_set_event(struct mod_power *mod_power,
 
 	// It's only implemented on dmcub.
 	if (dc_get_ctx(dc)->dmub_srv) {
-		if (!dmub_set_abm_event(dc_get_res_pool(dc), full_screen,
-				trans_info, hdr_mode, scaling_enable,
-				scaling_strength_map, inst))
+		if (!dc_abm_set_event(dc, full_screen, trans_info,
+				hdr_mode, scaling_enable, scaling_strength_map, inst))
 			return false;
 	} else
 		return false;
@@ -1708,7 +1707,7 @@ bool mod_power_abm_set_strength(struct mod_power *mod_power,
 
 	// It's only implemented on dmcub.
 	if (dc_get_ctx(dc)->dmub_srv) {
-		if (!dmub_set_abm_strength(dc_get_res_pool(dc), strength, inst))
+		if (!dc_abm_set_strength(dc, strength, inst))
 			return false;
 	} else
 		return false;
@@ -2176,17 +2175,17 @@ static void fill_iram_v_2_3(struct iram_table_v_2_2 *ram_table, struct dmcu_iram
 			params, ram_table, big_endian);
 }
 
-bool dmub_init_abm_config(struct resource_pool *res_pool,
+
+bool dmub_init_abm_config(struct dc *dc,
 	struct dmcu_iram_parameters params,
 	unsigned int inst)
 {
 	struct iram_table_v_2_2 ram_table;
 	struct abm_config_table config;
 	unsigned int set = params.set;
-	bool result = false;
 	uint32_t i, j = 0;
 
-	if (res_pool->abm == NULL && res_pool->multiple_abms[inst] == NULL)
+	if (!dc_abm_is_supported(dc, inst))
 		return false;
 
 	memset(&ram_table, 0, sizeof(ram_table));
@@ -2243,109 +2242,49 @@ bool dmub_init_abm_config(struct resource_pool *res_pool,
 
 	config.min_abm_backlight = ram_table.min_abm_backlight;
 
-	if (res_pool->multiple_abms[inst]) {
-		result = res_pool->multiple_abms[inst]->funcs->init_abm_config(
-			res_pool->multiple_abms[inst], (char *)(&config), sizeof(struct abm_config_table), inst);
-	} else
-		result = res_pool->abm->funcs->init_abm_config(
-			res_pool->abm, (char *)(&config), sizeof(struct abm_config_table), 0);
-
-	return result;
-}
-
-bool dmub_is_abm_supported(struct resource_pool *res_pool, unsigned int inst)
-{
-
-	if (res_pool->abm == NULL && res_pool->multiple_abms[inst] == NULL)
-		return false;
-
-	return true;
-}
-
-bool dmub_set_abm_event(struct resource_pool *res_pool,
-		unsigned int full_screen, unsigned int trans_info,
-		unsigned int hdr_mode, unsigned int scaling_enable, unsigned int scaling_strength_map,
-		unsigned int inst)
-{
-	bool result = false;
-
-	if (res_pool->abm == NULL && res_pool->multiple_abms[inst] == NULL)
-		return false;
-
-	if (res_pool->multiple_abms[inst]) {
-		if (res_pool->multiple_abms[inst]->funcs->set_abm_event)
-			result = res_pool->multiple_abms[inst]->funcs->set_abm_event(
-				res_pool->multiple_abms[inst], full_screen, trans_info,
-					hdr_mode, scaling_enable, scaling_strength_map, inst);
-	} else {
-		if (res_pool->abm->funcs->set_abm_event)
-			result = res_pool->abm->funcs->set_abm_event(
-					res_pool->abm, full_screen, trans_info,
-					hdr_mode, scaling_enable, scaling_strength_map, inst);
-	}
-
-	return result;
-}
-
-bool dmub_set_abm_strength(struct resource_pool *res_pool,
-	unsigned int strength,
-	unsigned int inst)
-{
-	bool result = false;
-
-	if (res_pool->abm == NULL && res_pool->multiple_abms[inst] == NULL)
-		return false;
-
-	if (res_pool->multiple_abms[inst]) {
-		if (res_pool->multiple_abms[inst]->funcs->set_abm_level)
-			result = res_pool->multiple_abms[inst]->funcs->set_abm_level(
-				res_pool->multiple_abms[inst], strength);
-	} else {
-		if (res_pool->abm->funcs->set_abm_level)
-			result = res_pool->abm->funcs->set_abm_level(
-					res_pool->abm, strength);
-	}
-
-	return result;
+	return dc_abm_program_config(dc, (const char *)&config,
+			sizeof(struct abm_config_table), inst);
 }
 
-bool dmcu_load_iram(struct dmcu *dmcu,
+bool dmcu_load_iram(struct dc *dc,
 	struct dmcu_iram_parameters params)
 {
 	unsigned char ram_table[IRAM_SIZE];
+	unsigned int abm_version;
 	bool result = false;
 
-	if (dmcu == NULL)
+	if (!dc_has_dmcu(dc))
 		return false;
 
-	if (dmcu && !dmcu->funcs->is_dmcu_initialized(dmcu))
+	if (!dc_dmcu_is_initialized(dc))
 		return true;
 
 	memset(&ram_table, 0, sizeof(ram_table));
 
-	if (dmcu->dmcu_version.abm_version == 0x24) {
+	abm_version = dc_get_dmcu_abm_version(dc);
+	if (abm_version == 0x24) {
 		fill_iram_v_2_3((struct iram_table_v_2_2 *)ram_table, params, true);
-		result = dmcu->funcs->load_iram(dmcu, 0, (char *)(&ram_table),
+		result = dc_dmcu_load_iram(dc, 0, (char *)(&ram_table),
 						IRAM_RESERVE_AREA_START_V2_2);
-	} else if (dmcu->dmcu_version.abm_version == 0x23) {
+	} else if (abm_version == 0x23) {
 		fill_iram_v_2_3((struct iram_table_v_2_2 *)ram_table, params, true);
 
-		result = dmcu->funcs->load_iram(
-				dmcu, 0, (char *)(&ram_table), IRAM_RESERVE_AREA_START_V2_2);
-	} else if (dmcu->dmcu_version.abm_version == 0x22) {
+		result = dc_dmcu_load_iram(
+				dc, 0, (char *)(&ram_table), IRAM_RESERVE_AREA_START_V2_2);
+	} else if (abm_version == 0x22) {
 		fill_iram_v_2_2((struct iram_table_v_2_2 *)ram_table, params);
 
-		result = dmcu->funcs->load_iram(
-				dmcu, 0, (char *)(&ram_table), IRAM_RESERVE_AREA_START_V2_2);
+		result = dc_dmcu_load_iram(
+				dc, 0, (char *)(&ram_table), IRAM_RESERVE_AREA_START_V2_2);
 	} else {
 		fill_iram_v_2((struct iram_table_v_2 *)ram_table, params);
 
-		result = dmcu->funcs->load_iram(
-				dmcu, 0, (char *)(&ram_table), IRAM_RESERVE_AREA_START_V2);
+		result = dc_dmcu_load_iram(
+				dc, 0, (char *)(&ram_table), IRAM_RESERVE_AREA_START_V2);
 
 		if (result)
-			result = dmcu->funcs->load_iram(
-					dmcu, IRAM_RESERVE_AREA_END_V2 + 1,
+			result = dc_dmcu_load_iram(
+					dc, IRAM_RESERVE_AREA_END_V2 + 1,
 					(char *)(&ram_table) + IRAM_RESERVE_AREA_END_V2 + 1,
 					sizeof(ram_table) - IRAM_RESERVE_AREA_END_V2 - 1);
 	}
diff --git a/drivers/gpu/drm/amd/display/modules/power/power_helpers.h b/drivers/gpu/drm/amd/display/modules/power/power_helpers.h
index 68679fa10946..c16a265e2a46 100644
--- a/drivers/gpu/drm/amd/display/modules/power/power_helpers.h
+++ b/drivers/gpu/drm/amd/display/modules/power/power_helpers.h
@@ -30,7 +30,7 @@
 #include "dc/inc/core_types.h"
 #include "mod_power.h"
 
-struct resource_pool;
+struct dc;
 
 
 enum abm_defines {
@@ -47,6 +47,7 @@ struct dmcu_iram_parameters {
 	unsigned int min_abm_backlight;
 	unsigned int set;
 };
+
 struct backlight_state {
 	/* HW uses u16.16 format for backlight PWM */
 	unsigned int backlight_pwm;
@@ -147,22 +148,12 @@ union dmcu_abm_set_bl_params {
 	} bits;
 	unsigned int u32All;
 };
-bool dmcu_load_iram(struct dmcu *dmcu,
+bool dmcu_load_iram(struct dc *dc,
 		struct dmcu_iram_parameters params);
-bool dmub_init_abm_config(struct resource_pool *res_pool,
+bool dmub_init_abm_config(struct dc *dc,
 		struct dmcu_iram_parameters params,
 		unsigned int inst);
 
-bool dmub_is_abm_supported(struct resource_pool *res_pool,
-		unsigned int inst);
-bool dmub_set_abm_event(struct resource_pool *res_pool,
-		unsigned int full_screen, unsigned int trans_info,
-		unsigned int hdr_mode, unsigned int scaling_enable,
-		unsigned int scaling_strength_map, unsigned int inst);
-bool dmub_set_abm_strength(struct resource_pool *res_pool,
-		unsigned int strength,
-		unsigned int inst);
-
 void init_replay_config(struct dc_link *link, struct replay_config *pr_config);
 void set_replay_coasting_vtotal(struct dc_link *link,
 	enum replay_coasting_vtotal_type type,

-- 
2.56.0

