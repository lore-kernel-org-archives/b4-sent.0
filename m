From: Dave Airlie <airlied@redhat.com>
Date: Thu, 12 Nov 2026 11:43:49 +1000
Subject: [PATCH 14/19] drm/amd/display: Restrict the dc directory root to
 DC-internal builds
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-amdgpu-dc-cleanup-v1-14-0fae41718ad2@redhat.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=50949; i=airlied@redhat.com;
 h=from:subject:message-id; bh=DT8S5Vcif1kIGfY+S8+x60p2pbSFMMkuzsha7IMJ1hc=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq9RnQU7zUwB8LfkrOndBNgmPTm+fW8h4Jh1Uxl
 kkY+2S9MyGJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavUZ0AAKCRAMdPNZecSG
 vut1D/4vsZfgyunzT+OBOXQLuOWNGd/aGwABWDjgZSsknVaF0O/Xux5NcIw4RtIZ+Ccvf9ruu2I
 FCTxr8X58a4gDBdEIO5VJqO2ey5iL/UE77yVlqv+WspUAz3qJFYwqz1yS1ilnYqZ7/V8d7LiqXi
 XKuodFRodt9RpMhb2kx0ONvuvLxJbGoBBaxbeDPVs7k6xLsPTr+PoZY0GfFZ+mYhKsLvKUFncGX
 vsASqph2sYfG2SI95jCxzpZeXCvzY/8MHrEZfQiOlTwCS8GP+mkLSEnIh+Foz6Bg+HEqnlIOSrq
 KWXmVr5g4osLT81ZcwpYeMHTq3LUeCm/+sCAJ6kV1/K4bl0+MOQrc3AtMIPsAevylg5qUgkuhsk
 jqdxEzNVnYpnlKvQP0A83AF68Kbx6LZj/4TW0e1XfuKvEfBxw9DjOhupdRmLuAg/SeZzU3Rr9Qx
 OmjwXrXDGWCzKDFHVniXeHWRFohQmjGKPUoXr7Y87/x7UHghGqgv7iWGVEApQqk5IUXZPCzkVMT
 tbxWxt1HbCrHAZLnJLdOnngQsvgH4831SLtINGhuelI4njLwlhjstcKYalJk6v3/+W7aJhG/xgV
 DKiFy/qYenHfvXGE3KsktK9zKpALAHuo4C0hlZOstTFZLewroSSqWIuxpVsNdrQ+Nb+kFSheiA/
 Bi17W8mXAGpMwgQ==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dc directory root holds private headers (dc_priv.h and the other
*_priv.h / internal headers). Remove the global
-I(full-amd-display-path)/dc include flags from amdgpu/Makefile,
amdgpu_dm/Makefile and the amdgpu_dm tests so the root cannot be
reached from outside DC anymore; with this, including dc_priv.h from
DM or the DAL modules fails at compile time.

To keep the many "subdir/header.h" includes inside DC working, give
DC-internal objects the root on their include path through per-object
CFLAGS in dc/Makefile (same mechanism the DML Makefiles already use
for FPU flags) instead of a global ccflags-y entry.

Relocate the public dc-root headers to dc/inc, which was already the
exported interface directory:

  dc.h, dc_types.h, dc_state.h, dc_plane.h, dc_probe.h,
  dc_memory_pool.h, dc_ddc_types.h, dc_dp_types.h, dc_hdmi_types.h,
  dc_hw_types.h, os_types.h, irq_types.h, dm_helpers.h,
  dm_services.h, dm_services_types.h, dm_pp_smu.h, dc_dmub_srv.h,
  dc_bios_types.h, dc_trace.h, dm_cp_psp.h, dc_fused_io.h,
  dc_stat.h, dc_stream.h, dc_dsc.h

No includer outside DC needs to change: bare-name includes resolve
through the existing -Idc/inc. Fix the few headers that referenced
siblings through the old root-relative forms (angle-bracket
inc/hw/*.h includes, inc/, dml/, dml2_wrapper/, sspl/ prefixes), the
handful of DM and dmub path includes, and the dm_pp_smu.h include in
pm/swsmu.

Also drop an unused dcn20_resource.h include from
amdgpu_dm_mst_types.c that only worked by accident.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 drivers/gpu/drm/amd/amdgpu/Makefile                  |  1 -
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c    | 18 +++++++++---------
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_audio.c  |  2 +-
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c  |  6 +++---
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c  | 16 ++++++++--------
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_debugfs.c    |  6 +++---
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c   |  8 ++++----
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c    |  2 +-
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c    |  6 +++---
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c  |  2 +-
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_replay.c |  2 +-
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_trace.h  |  4 ++--
 drivers/gpu/drm/amd/display/amdgpu_dm/tests/Makefile |  1 -
 .../display/amdgpu_dm/tests/amdgpu_dm_audio_test.c   |  4 ++--
 .../amdgpu_dm/tests/amdgpu_dm_backlight_test.c       |  2 +-
 .../amdgpu_dm/tests/amdgpu_dm_connector_test.c       |  6 +++---
 .../display/amdgpu_dm/tests/amdgpu_dm_crtc_test.c    |  8 ++++----
 .../display/amdgpu_dm/tests/amdgpu_dm_dmub_test.c    |  6 +++---
 .../amdgpu_dm/tests/amdgpu_dm_freesync_test.c        |  2 +-
 .../amd/display/amdgpu_dm/tests/amdgpu_dm_irq_test.c |  6 +++---
 .../amdgpu_dm/tests/amdgpu_dm_mst_types_test.c       |  6 +++---
 .../drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c |  4 ++--
 drivers/gpu/drm/amd/display/dc/Makefile              | 10 ++++++++++
 .../display/dc/bls_builder/bls_builder_legacy_init.h |  2 +-
 drivers/gpu/drm/amd/display/dc/core/dc_stat.c        |  2 +-
 drivers/gpu/drm/amd/display/dc/core2/dc_core2.h      |  2 +-
 .../drm/amd/display/dc/dc_api_dispatch/api_shim.c    |  2 +-
 .../drm/amd/display/dc/dc_api_dispatch/api_shim.h    |  2 +-
 drivers/gpu/drm/amd/display/dc/dce/dce_aux.h         |  2 +-
 drivers/gpu/drm/amd/display/dc/dce/dce_i2c.h         |  2 +-
 .../drm/amd/display/dc/dce110/dce110_mem_input_v.c   |  2 +-
 drivers/gpu/drm/amd/display/dc/dcn31/dcn31_afmt.c    |  2 +-
 drivers/gpu/drm/amd/display/dc/dcn31/dcn31_vpg.c     |  2 +-
 .../gpu/drm/amd/display/dc/hwss/dcn10/dcn10_init.c   |  2 +-
 .../gpu/drm/amd/display/dc/hwss/dcn20/dcn20_hwseq.c  |  2 +-
 .../gpu/drm/amd/display/dc/hwss/dcn31/dcn31_hwseq.c  |  2 +-
 .../drm/amd/display/dc/hwss/dcn314/dcn314_hwseq.c    |  2 +-
 .../gpu/drm/amd/display/dc/hwss/dcn35/dcn35_hwseq.c  |  2 +-
 .../gpu/drm/amd/display/dc/hwss/dcn35/dcn35_hwseq.h  |  2 +-
 .../drm/amd/display/dc/hwss/dcn401/dcn401_hwseq.h    |  2 +-
 .../gpu/drm/amd/display/dc/hwss/dcn50/dcn50_hwseq.h  |  2 +-
 .../gpu/drm/amd/display/dc/hwss/dcn60/dcn60_hwseq.h  |  2 +-
 drivers/gpu/drm/amd/display/dc/hwss/hw_sequencer.h   | 16 ++++++++--------
 drivers/gpu/drm/amd/display/dc/inc/core_types.h      |  8 ++++----
 drivers/gpu/drm/amd/display/dc/{ => inc}/dc.h        | 20 ++++++++++----------
 .../gpu/drm/amd/display/dc/{ => inc}/dc_bios_types.h |  0
 .../gpu/drm/amd/display/dc/{ => inc}/dc_ddc_types.h  |  0
 .../gpu/drm/amd/display/dc/{ => inc}/dc_dmub_srv.h   |  0
 .../gpu/drm/amd/display/dc/{ => inc}/dc_dp_types.h   |  0
 drivers/gpu/drm/amd/display/dc/{ => inc}/dc_dsc.h    |  0
 .../gpu/drm/amd/display/dc/{ => inc}/dc_fused_io.h   |  0
 .../gpu/drm/amd/display/dc/{ => inc}/dc_hdmi_types.h |  0
 .../gpu/drm/amd/display/dc/{ => inc}/dc_hw_types.h   |  0
 .../drm/amd/display/dc/{ => inc}/dc_memory_pool.h    |  0
 drivers/gpu/drm/amd/display/dc/{ => inc}/dc_plane.h  |  0
 drivers/gpu/drm/amd/display/dc/{ => inc}/dc_probe.h  |  0
 drivers/gpu/drm/amd/display/dc/{ => inc}/dc_stat.h   |  0
 drivers/gpu/drm/amd/display/dc/{ => inc}/dc_state.h  |  2 +-
 drivers/gpu/drm/amd/display/dc/{ => inc}/dc_stream.h |  0
 drivers/gpu/drm/amd/display/dc/{ => inc}/dc_trace.h  |  0
 drivers/gpu/drm/amd/display/dc/{ => inc}/dc_types.h  |  0
 drivers/gpu/drm/amd/display/dc/inc/dcn_calcs.h       |  2 +-
 drivers/gpu/drm/amd/display/dc/{ => inc}/dm_cp_psp.h |  0
 .../gpu/drm/amd/display/dc/{ => inc}/dm_helpers.h    |  0
 drivers/gpu/drm/amd/display/dc/{ => inc}/dm_pp_smu.h |  0
 .../gpu/drm/amd/display/dc/{ => inc}/dm_services.h   |  0
 .../drm/amd/display/dc/{ => inc}/dm_services_types.h |  0
 drivers/gpu/drm/amd/display/dc/inc/hw/dchubbub.h     |  2 +-
 drivers/gpu/drm/amd/display/dc/inc/hw/hubp.h         |  4 ++--
 drivers/gpu/drm/amd/display/dc/inc/hw/mcif_wb.h      |  2 +-
 drivers/gpu/drm/amd/display/dc/inc/hw/mem_input.h    |  4 ++--
 drivers/gpu/drm/amd/display/dc/inc/hw/transform.h    |  2 +-
 drivers/gpu/drm/amd/display/dc/{ => inc}/irq_types.h |  0
 drivers/gpu/drm/amd/display/dc/{ => inc}/os_types.h  |  0
 .../drm/amd/display/dc/link/protocols/link_dp_dpia.c |  2 +-
 .../display/dc/link/protocols/link_dp_panel_replay.c |  2 +-
 .../dc/link/protocols/link_dp_training_dpia.c        |  2 +-
 .../dc/link/protocols/link_edp_panel_control.c       |  2 +-
 drivers/gpu/drm/amd/display/dmub/dmub_srv.h          |  2 +-
 drivers/gpu/drm/amd/display/dmub/src/dmub_dcn32.c    |  2 +-
 drivers/gpu/drm/amd/display/dmub/src/dmub_dcn35.c    |  2 +-
 drivers/gpu/drm/amd/display/modules/power/power.c    |  2 +-
 .../gpu/drm/amd/display/modules/power/power_abm.c    |  2 +-
 .../gpu/drm/amd/display/modules/power/power_psr.c    |  2 +-
 .../gpu/drm/amd/display/modules/power/power_replay.c |  2 +-
 drivers/gpu/drm/amd/pm/swsmu/inc/amdgpu_smu.h        |  2 +-
 86 files changed, 130 insertions(+), 122 deletions(-)

diff --git a/drivers/gpu/drm/amd/amdgpu/Makefile b/drivers/gpu/drm/amd/amdgpu/Makefile
index 8687afc00c24..55c89f8d764e 100644
--- a/drivers/gpu/drm/amd/amdgpu/Makefile
+++ b/drivers/gpu/drm/amd/amdgpu/Makefile
@@ -39,7 +39,6 @@ ccflags-y := -I$(FULL_AMD_PATH)/include/asic_reg \
 	-I$(FULL_AMD_DISPLAY_PATH) \
 	-I$(FULL_AMD_DISPLAY_PATH)/include \
 	-I$(FULL_AMD_DISPLAY_PATH)/modules/inc \
-	-I$(FULL_AMD_DISPLAY_PATH)/dc \
 	-I$(FULL_AMD_DISPLAY_PATH)/amdgpu_dm \
 	-I$(FULL_AMD_PATH)/amdkfd \
 	-I$(FULL_AMD_PATH)/ras/ras_mgr
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index 3458b26846a1..cb122cb32905 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -30,19 +30,19 @@
 #include "dm_services_types.h"
 #include "dc.h"
 #include "link_enc_cfg.h"
-#include "dc/inc/core_types.h"
+#include "core_types.h"
 #include "dal_asic_id.h"
 #include "dmub/dmub_srv.h"
-#include "dc/inc/hw/dmcu.h"
-#include "dc/inc/hw/abm.h"
-#include "dc/dc_dmub_srv.h"
-#include "dc/dc_stat.h"
-#include "dc/dc_state.h"
+#include "hw/dmcu.h"
+#include "hw/abm.h"
+#include "dc_dmub_srv.h"
+#include "dc_stat.h"
+#include "dc_state.h"
 #include "amdgpu_dm_trace.h"
-#include "link/protocols/link_dpcd.h"
+#include "dc/link/protocols/link_dpcd.h"
 #include "link_service_types.h"
-#include "link/protocols/link_dp_capability.h"
-#include "link/protocols/link_ddc.h"
+#include "dc/link/protocols/link_dp_capability.h"
+#include "dc/link/protocols/link_ddc.h"
 
 #include "amdgpu.h"
 #include "amdgpu_display.h"
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_audio.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_audio.c
index 97cc52f45a2e..23392b229679 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_audio.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_audio.c
@@ -36,7 +36,7 @@
 #include <drm/drm_edid.h>
 #include <drm/drm_eld.h>
 
-#include "dc/inc/core_types.h"
+#include "core_types.h"
 
 static int amdgpu_dm_audio_component_get_eld(struct device *kdev, int port,
 					  int pipe, bool *enabled,
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c
index 3d268703c551..194e52fdd9f5 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c
@@ -24,9 +24,9 @@
  */
 
 #include "dc.h"
-#include "dc/dc_dmub_srv.h"
-#include "dc/dc_state.h"
-#include "dc/dc_stat.h"
+#include "dc_dmub_srv.h"
+#include "dc_state.h"
+#include "dc_stat.h"
 
 #include "amdgpu.h"
 #include "amdgpu_display.h"
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
index 134d08207a14..d1a672c721c4 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
@@ -26,16 +26,16 @@
 
 #include "dm_services_types.h"
 #include "dc.h"
-#include "dc/dc_dmub_srv.h"
-#include "dc/dc_stat.h"
-#include "dc/dc_state.h"
-#include "dc/dc_stream.h"
-#include "dc/inc/core_types.h"
+#include "dc_dmub_srv.h"
+#include "dc_stat.h"
+#include "dc_state.h"
+#include "dc_stream.h"
+#include "core_types.h"
 #include "link_enc_cfg.h"
-#include "link/protocols/link_dpcd.h"
+#include "dc/link/protocols/link_dpcd.h"
 #include "link_service_types.h"
-#include "link/protocols/link_dp_capability.h"
-#include "link/protocols/link_ddc.h"
+#include "dc/link/protocols/link_dp_capability.h"
+#include "dc/link/protocols/link_ddc.h"
 
 #include "amdgpu.h"
 #include "amdgpu_display.h"
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_debugfs.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_debugfs.c
index fddb47a32fb9..8d7ebb636554 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_debugfs.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_debugfs.c
@@ -39,9 +39,9 @@
 #include "resource.h"
 #include "dsc.h"
 #include "link_hwss.h"
-#include "dc/dc_dmub_srv.h"
-#include "link/protocols/link_dp_capability.h"
-#include "inc/hw/dchubbub.h"
+#include "dc_dmub_srv.h"
+#include "dc/link/protocols/link_dp_capability.h"
+#include "dc/inc/hw/dchubbub.h"
 
 #ifdef CONFIG_DRM_AMD_SECURE_DISPLAY
 #include "amdgpu_dm_psr.h"
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c
index af2cda9080d9..ffe561da24d6 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c
@@ -26,11 +26,11 @@
 
 #include "dm_services_types.h"
 #include "dc.h"
-#include "dc/inc/core_types.h"
-#include "dc/dc_dmub_srv.h"
+#include "core_types.h"
+#include "dc_dmub_srv.h"
 #include "dmub/dmub_srv.h"
-#include "dc/inc/hw/dmcu.h"
-#include "dc/inc/hw/abm.h"
+#include "hw/dmcu.h"
+#include "hw/abm.h"
 #include "dal_asic_id.h"
 
 #include "amdgpu.h"
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c
index 02a8cfde9f1a..b5b3269f3d97 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c
@@ -43,7 +43,7 @@
 #include "amdgpu_dm_irq.h"
 #include "amdgpu_dm_mst_types.h"
 #include "dpcd_defs.h"
-#include "dc/inc/core_types.h"
+#include "core_types.h"
 
 #include "dm_helpers.h"
 #include "ddc_service_types.h"
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c
index 5c3b83f05d2b..57e1dcf6bb45 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c
@@ -26,8 +26,8 @@
 
 #include "dm_services_types.h"
 #include "dc.h"
-#include "dc/dc_dmub_srv.h"
-#include "dc/dc_stat.h"
+#include "dc_dmub_srv.h"
+#include "dc_stat.h"
 
 #include "amdgpu.h"
 #include "amdgpu_display.h"
@@ -39,7 +39,7 @@
 #include "amdgpu_dm_mst_types.h"
 #include "amdgpu_dm_dmub.h"
 #include "amdgpu_dm_trace.h"
-#include "link/protocols/link_dpcd.h"
+#include "dc/link/protocols/link_dpcd.h"
 #include "link_service_types.h"
 #include "ivsrcid/ivsrcid_vislands30.h"
 #include "ivsrcid/dcn/irqsrcs_dcn_1_0.h"
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
index 2cbe08298706..4f9070579916 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
@@ -39,6 +39,7 @@
 #include "amdgpu_dm_hdcp.h"
 
 #include "dc.h"
+#include "core_types.h"
 #include "dm_helpers.h"
 
 #include "ddc_service_types.h"
@@ -48,7 +49,6 @@
 #include "amdgpu_dm_debugfs.h"
 #endif
 
-#include "dc/resource/dcn20/dcn20_resource.h"
 
 #define PEAK_FACTOR_X1000 1006
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_replay.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_replay.c
index 6441212f93a1..40b8d60642b6 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_replay.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_replay.c
@@ -30,7 +30,7 @@
 #include "amdgpu_dm.h"
 #include "modules/power/power_helpers.h"
 #include "dmub/inc/dmub_cmd.h"
-#include "dc/inc/link_service.h"
+#include "link_service.h"
 #include "dm_helpers.h"
 
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_trace.h b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_trace.h
index 9027933cec3f..a1452e58ad73 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_trace.h
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_trace.h
@@ -38,9 +38,9 @@
 #include <drm/drm_framebuffer.h>
 #include <drm/drm_encoder.h>
 #include <drm/drm_atomic.h>
-#include "dc/inc/hw/optc.h"
+#include "hw/optc.h"
 
-#include "dc/inc/core_types.h"
+#include "core_types.h"
 
 DECLARE_EVENT_CLASS(amdgpu_dc_reg_template,
 		    TP_PROTO(unsigned long *count, uint32_t reg, uint32_t value),
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/Makefile b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/Makefile
index e0549c04c62e..6b953d8fe826 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/Makefile
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/Makefile
@@ -8,7 +8,6 @@ ccflags-y += -I$(src)/..
 ccflags-y += -I$(src)/../..
 ccflags-y += -I$(src)/../../include
 ccflags-y += -I$(src)/../../modules/inc
-ccflags-y += -I$(src)/../../dc
 ccflags-y += -I$(src)/../../../amdgpu
 ccflags-y += -I$(src)/../../../amdkfd
 ccflags-y += -I$(src)/../../../include
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_audio_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_audio_test.c
index c2ed369f3ca2..56a2afc114b8 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_audio_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_audio_test.c
@@ -19,8 +19,8 @@
 
 #include "dc.h"
 #include "dc_test.h"
-#include "dc/inc/core_types.h"
-#include "dc/inc/hw/audio.h"
+#include "core_types.h"
+#include "hw/audio.h"
 #include "amdgpu.h"
 #include "amdgpu_mode.h"
 #include "amdgpu_dm.h"
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_backlight_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_backlight_test.c
index 377b92d84b98..5b8660c938c9 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_backlight_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_backlight_test.c
@@ -24,7 +24,7 @@
 #include "amdgpu_dm_kunit_test_helpers.h"
 #include "amd_shared.h"
 #include "link_service.h"
-#include "dc/inc/hw/panel_cntl.h"
+#include "hw/panel_cntl.h"
 
 struct dm_backlight_connector_fixture {
 	struct amdgpu_device *adev;
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
index 94bb2181d141..44c7324642b5 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
@@ -34,9 +34,9 @@
 #include "amdgpu_dm_psr.h"
 #include "include/grph_object_id.h"
 #include "amdgpu_dm_kunit_test_helpers.h"
-#include "inc/link_service.h"
-#include "inc/resource.h"
-#include "inc/hw/timing_generator.h"
+#include "link_service.h"
+#include "resource.h"
+#include "dc/inc/hw/timing_generator.h"
 
 /* Tests for get_subconnector_type() */
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_crtc_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_crtc_test.c
index 96cf015a12d9..c4f703980d1e 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_crtc_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_crtc_test.c
@@ -14,10 +14,10 @@
 
 #include "dc.h"
 #include "dc_test.h"
-#include "inc/core_types.h"
-#include "irq/irq_service.h"
-#include "inc/hw/timing_generator.h"
-#include "inc/link_service.h"
+#include "core_types.h"
+#include "dc/irq/irq_service.h"
+#include "dc/inc/hw/timing_generator.h"
+#include "link_service.h"
 #include "amdgpu.h"
 #include "amdgpu_mode.h"
 #include "amdgpu_dm.h"
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_dmub_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_dmub_test.c
index 449fb6d94f75..b71e1e11e85a 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_dmub_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_dmub_test.c
@@ -11,9 +11,9 @@
 #include "dc.h"
 #include "dc_test.h"
 #include "amdgpu_dm_kunit_test_helpers.h"
-#include "dc/inc/core_types.h"
-#include "dc/inc/hw/dmcu.h"
-#include "dc/inc/hw/abm.h"
+#include "core_types.h"
+#include "hw/dmcu.h"
+#include "hw/abm.h"
 #include "amdgpu_mode.h"
 #include "amdgpu_dm.h"
 #include "dal_asic_id.h"
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_freesync_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_freesync_test.c
index b751c64d88aa..467267d4bcc4 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_freesync_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_freesync_test.c
@@ -14,7 +14,7 @@
 
 #include "dc.h"
 #include "dc_test.h"
-#include "inc/core_types.h"
+#include "core_types.h"
 #include "amd_shared.h"
 #include "amdgpu.h"
 #include "amdgpu_mode.h"
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_irq_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_irq_test.c
index b64d63fe15fd..ea467ca45af8 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_irq_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_irq_test.c
@@ -16,9 +16,9 @@
 
 #include "dc.h"
 #include "dc_test.h"
-#include "inc/core_types.h"
-#include "inc/hw/timing_generator.h"
-#include "irq/irq_service.h"
+#include "core_types.h"
+#include "dc/inc/hw/timing_generator.h"
+#include "dc/irq/irq_service.h"
 #include "amdgpu.h"
 #include "amdgpu_mode.h"
 #include "amdgpu_dm.h"
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_mst_types_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_mst_types_test.c
index b8ea85846872..144cb03f504a 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_mst_types_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_mst_types_test.c
@@ -32,9 +32,9 @@
 #include "amdgpu_dm_hdcp.h"
 #include "amdgpu_dm_mst_types.h"
 #include "amdgpu_dm_kunit_test_helpers.h"
-#include "dsc/dsc.h"
-#include "inc/core_types.h"
-#include "inc/link_service.h"
+#include "dc/dsc/dsc.h"
+#include "core_types.h"
+#include "link_service.h"
 
 /*
  * Minimal mock DPCD backing store and AUX transfer callback used to exercise
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
index c0dbab0b7c46..8cf460a4cb9f 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_test.c
@@ -23,11 +23,11 @@
 
 #include "dc.h"
 #include "dc_test.h"
-#include "dc/dc_dmub_srv.h"
+#include "dc_dmub_srv.h"
 #include "dal_asic_id.h"
 #include "dm_services_types.h"
 #include "dmub/dmub_srv.h"
-#include "inc/core_types.h"
+#include "core_types.h"
 #include "logger_types.h"
 #include "amd_shared.h"
 #include "amdgpu.h"
diff --git a/drivers/gpu/drm/amd/display/dc/Makefile b/drivers/gpu/drm/amd/display/dc/Makefile
index 440f5d358188..c0fc7f7d241d 100644
--- a/drivers/gpu/drm/amd/display/dc/Makefile
+++ b/drivers/gpu/drm/amd/display/dc/Makefile
@@ -98,3 +98,13 @@ endif
 
 AMD_DISPLAY_FILES += $(addprefix $(AMDDALPATH)/dc/, $(FILES))
 
+# The dc directory root holds private headers (dc_priv.h and friends) that
+# must not be reachable outside DC, so the global include path deliberately
+# stops at dc/inc. DC-internal objects still need the root on their include
+# path for the many "subdir/header.h" includes inside DC, so add it per
+# object instead of through a global ccflags-y entry.
+DC_INTERNAL_OBJS := $(filter $(AMDDALPATH)/dc/%,$(AMD_DISPLAY_FILES))
+$(foreach obj,$(DC_INTERNAL_OBJS),\
+	$(eval CFLAGS_$(obj) += -I$(FULL_AMD_DISPLAY_PATH)/dc))
+
+
diff --git a/drivers/gpu/drm/amd/display/dc/bls_builder/bls_builder_legacy_init.h b/drivers/gpu/drm/amd/display/dc/bls_builder/bls_builder_legacy_init.h
index e9259699a9c0..bb8fe97fa8f2 100644
--- a/drivers/gpu/drm/amd/display/dc/bls_builder/bls_builder_legacy_init.h
+++ b/drivers/gpu/drm/amd/display/dc/bls_builder/bls_builder_legacy_init.h
@@ -8,7 +8,7 @@
 #include "dmub_cmd.h"
 #include "grph_object_ctrl_defs.h"
 #include "bios_parser_types.h"
-#include "inc/hw/hw_shared.h"
+#include "hw/hw_shared.h"
 
 /*
  * DC2_DC1_Wrapped hardware init: dcn401_init_hw as twelve BLS stages.
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_stat.c b/drivers/gpu/drm/amd/display/dc/core/dc_stat.c
index 1758c0b9390b..92466b7664aa 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_stat.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_stat.c
@@ -22,7 +22,7 @@
  * Authors: AMD
  */
 
-#include "dc/dc_stat.h"
+#include "dc_stat.h"
 #include "dmub/dmub_srv_stat.h"
 #include "dc_dmub_srv.h"
 #include "dc_priv.h"
diff --git a/drivers/gpu/drm/amd/display/dc/core2/dc_core2.h b/drivers/gpu/drm/amd/display/dc/core2/dc_core2.h
index a761e85a9973..a7fd4dcf66d8 100644
--- a/drivers/gpu/drm/amd/display/dc/core2/dc_core2.h
+++ b/drivers/gpu/drm/amd/display/dc/core2/dc_core2.h
@@ -5,7 +5,7 @@
 
 #pragma once
 
-#include "inc/dc_core_interface.h"
+#include "dc_core_interface.h"
 
 struct dc;
 
diff --git a/drivers/gpu/drm/amd/display/dc/dc_api_dispatch/api_shim.c b/drivers/gpu/drm/amd/display/dc/dc_api_dispatch/api_shim.c
index 3dcfde8308c5..8a90898f5d06 100644
--- a/drivers/gpu/drm/amd/display/dc/dc_api_dispatch/api_shim.c
+++ b/drivers/gpu/drm/amd/display/dc/dc_api_dispatch/api_shim.c
@@ -7,7 +7,7 @@
 #include "dc.h"
 #include "dc_api_dispatch/api_shim.h"
 #include "core2/dc_core2.h"
-#include "inc/dc_core_interface.h"
+#include "dc_core_interface.h"
 
 void api_shim_construct(struct dc *dc, const struct dc_init_data *init_params)
 {
diff --git a/drivers/gpu/drm/amd/display/dc/dc_api_dispatch/api_shim.h b/drivers/gpu/drm/amd/display/dc/dc_api_dispatch/api_shim.h
index 7802a18b8caa..88d4e2bfa1be 100644
--- a/drivers/gpu/drm/amd/display/dc/dc_api_dispatch/api_shim.h
+++ b/drivers/gpu/drm/amd/display/dc/dc_api_dispatch/api_shim.h
@@ -7,7 +7,7 @@
 
 #include "dc.h"
 #include "dc_priv.h"
-#include "inc/dc_core_interface.h"
+#include "dc_core_interface.h"
 #include "bls_builder/dmub_abi.h"
 
 struct dc2 {
diff --git a/drivers/gpu/drm/amd/display/dc/dce/dce_aux.h b/drivers/gpu/drm/amd/display/dc/dce/dce_aux.h
index b2153cb03b51..2e3f9bcc8a51 100644
--- a/drivers/gpu/drm/amd/display/dc/dce/dce_aux.h
+++ b/drivers/gpu/drm/amd/display/dc/dce/dce_aux.h
@@ -27,7 +27,7 @@
 #define __DAL_AUX_ENGINE_DCE110_H__
 
 #include "gpio_service_interface.h"
-#include "inc/hw/aux_engine.h"
+#include "hw/aux_engine.h"
 
 enum aux_return_code_type;
 
diff --git a/drivers/gpu/drm/amd/display/dc/dce/dce_i2c.h b/drivers/gpu/drm/amd/display/dc/dce/dce_i2c.h
index 535fd58de450..0949dd0b5bcb 100644
--- a/drivers/gpu/drm/amd/display/dc/dce/dce_i2c.h
+++ b/drivers/gpu/drm/amd/display/dc/dce/dce_i2c.h
@@ -26,7 +26,7 @@
 #ifndef __DCE_I2C_H__
 #define __DCE_I2C_H__
 
-#include "inc/core_types.h"
+#include "core_types.h"
 #include "dce_i2c_hw.h"
 #include "dce_i2c_sw.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/dce110/dce110_mem_input_v.c b/drivers/gpu/drm/amd/display/dc/dce110/dce110_mem_input_v.c
index 277c9e169a1f..3dd0e2ef9b80 100644
--- a/drivers/gpu/drm/amd/display/dc/dce110/dce110_mem_input_v.c
+++ b/drivers/gpu/drm/amd/display/dc/dce110/dce110_mem_input_v.c
@@ -29,7 +29,7 @@
 /* TODO: this needs to be looked at, used by Stella's workaround*/
 
 #include "include/logger_interface.h"
-#include "inc/dce_calcs.h"
+#include "dce_calcs.h"
 
 #include "dce/dce_mem_input.h"
 #include "dce110_mem_input_v.h"
diff --git a/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_afmt.c b/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_afmt.c
index 37b608ee7ca9..f788c6e7ee52 100644
--- a/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_afmt.c
+++ b/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_afmt.c
@@ -28,7 +28,7 @@
 #include "dcn30/dcn30_afmt.h"
 #include "dcn31_afmt.h"
 #include "reg_helper.h"
-#include "dc/dc.h"
+#include "dc.h"
 #include "dc_priv.h"
 
 #define DC_LOGGER \
diff --git a/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_vpg.c b/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_vpg.c
index a453cc24d82a..ecf30239e0e7 100644
--- a/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_vpg.c
+++ b/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_vpg.c
@@ -27,7 +27,7 @@
 #include "dcn30/dcn30_vpg.h"
 #include "dcn31_vpg.h"
 #include "reg_helper.h"
-#include "dc/dc.h"
+#include "dc.h"
 #include "dc_priv.h"
 
 #define DC_LOGGER \
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn10/dcn10_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn10/dcn10_init.c
index 442830726b38..85fc7c729d46 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn10/dcn10_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn10/dcn10_init.c
@@ -27,7 +27,7 @@
 #include "dce110/dce110_hwseq.h"
 #include "dcn10/dcn10_hwseq.h"
 #include "dcn20/dcn20_hwseq.h"
-#include "dc/hwss/dce/dce_hwseq.h"
+#include "hwss/dce/dce_hwseq.h"
 #include "dc_priv.h"
 
 static const struct hw_sequencer_funcs dcn10_funcs = {
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn20/dcn20_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn20/dcn20_hwseq.c
index 90a05af35782..da18577621df 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn20/dcn20_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn20/dcn20_hwseq.c
@@ -53,7 +53,7 @@
 #include "dce/dmub_hw_lock_mgr.h"
 #include "hw_sequencer.h"
 #include "dpcd_defs.h"
-#include "inc/link_enc_cfg.h"
+#include "link_enc_cfg.h"
 #include "link_hwss.h"
 #include "link_service.h"
 #include "dc_state_priv.h"
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn31/dcn31_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn31/dcn31_hwseq.c
index f5b96c86ca59..347e23a0cf8f 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn31/dcn31_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn31/dcn31_hwseq.c
@@ -49,7 +49,7 @@
 #include "link_service.h"
 #include "dcn10/dcn10_hwseq.h"
 #include "dcn21/dcn21_hwseq.h"
-#include "inc/link_enc_cfg.h"
+#include "link_enc_cfg.h"
 #include "dcn30/dcn30_vpg.h"
 #include "dce/dce_i2c_hw.h"
 #include "dce/dmub_abm_lcd.h"
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn314/dcn314_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn314/dcn314_hwseq.c
index d57f5be5c57f..c0b4e2f62ff1 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn314/dcn314_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn314/dcn314_hwseq.c
@@ -48,7 +48,7 @@
 #include "dce/dmub_outbox.h"
 #include "link_service.h"
 #include "dcn10/dcn10_hwseq.h"
-#include "inc/link_enc_cfg.h"
+#include "link_enc_cfg.h"
 #include "dcn30/dcn30_vpg.h"
 #include "dce/dce_i2c_hw.h"
 #include "dsc.h"
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn35/dcn35_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn35/dcn35_hwseq.c
index cd904a28fa12..9f0279d251d9 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn35/dcn35_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn35/dcn35_hwseq.c
@@ -50,7 +50,7 @@
 #include "link_service.h"
 #include "dce/dmub_hw_lock_mgr.h"
 #include "dcn10/dcn10_hwseq.h"
-#include "inc/link_enc_cfg.h"
+#include "link_enc_cfg.h"
 #include "dcn30/dcn30_vpg.h"
 #include "dce/dce_i2c_hw.h"
 #include "dsc.h"
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn35/dcn35_hwseq.h b/drivers/gpu/drm/amd/display/dc/hwss/dcn35/dcn35_hwseq.h
index 0ae2f44cfb9f..75d09525f014 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn35/dcn35_hwseq.h
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn35/dcn35_hwseq.h
@@ -27,7 +27,7 @@
 #ifndef __DC_HWSS_DCN35_H__
 #define __DC_HWSS_DCN35_H__
 
-#include "inc/core_types.h"
+#include "core_types.h"
 #include "dc.h"
 #include "hw_sequencer_private.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn401/dcn401_hwseq.h b/drivers/gpu/drm/amd/display/dc/hwss/dcn401/dcn401_hwseq.h
index fef0dd59a81f..f80113ebbd0c 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn401/dcn401_hwseq.h
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn401/dcn401_hwseq.h
@@ -5,7 +5,7 @@
 #ifndef __DC_HWSS_DCN401_H__
 #define __DC_HWSS_DCN401_H__
 
-#include "inc/core_types.h"
+#include "core_types.h"
 #include "dc.h"
 #include "dc_stream.h"
 #include "hw_sequencer_private.h"
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn50/dcn50_hwseq.h b/drivers/gpu/drm/amd/display/dc/hwss/dcn50/dcn50_hwseq.h
index 79b5a4794ac1..2ea189421fb4 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn50/dcn50_hwseq.h
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn50/dcn50_hwseq.h
@@ -5,7 +5,7 @@
 #ifndef __DC_HWSS_DCN50_H__
 #define __DC_HWSS_DCN50_H__
 
-#include "inc/core_types.h"
+#include "core_types.h"
 #include "dc.h"
 #include "dc_stream.h"
 #include "hw_sequencer_private.h"
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn60/dcn60_hwseq.h b/drivers/gpu/drm/amd/display/dc/hwss/dcn60/dcn60_hwseq.h
index b880988ff1fc..8f66f9b1854e 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn60/dcn60_hwseq.h
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn60/dcn60_hwseq.h
@@ -5,7 +5,7 @@
 #ifndef __DC_HWSS_DCN60_H__
 #define __DC_HWSS_DCN60_H__
 
-#include "inc/core_types.h"
+#include "core_types.h"
 #include "dc.h"
 #include "dc_stream.h"
 #include "hw_sequencer_private.h"
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/hw_sequencer.h b/drivers/gpu/drm/amd/display/dc/hwss/hw_sequencer.h
index 6580d13d9041..401b3982a14a 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/hw_sequencer.h
+++ b/drivers/gpu/drm/amd/display/dc/hwss/hw_sequencer.h
@@ -26,14 +26,14 @@
 #ifndef __DC_HW_SEQUENCER_H__
 #define __DC_HW_SEQUENCER_H__
 #include "dc_types.h"
-#include "inc/clock_source.h"
-#include "inc/hw/timing_generator.h"
-#include "inc/hw/opp.h"
-#include "inc/hw/link_encoder.h"
-#include "inc/core_status.h"
-#include "inc/hw/hw_shared.h"
-#include "inc/hw/dchubbub.h"
-#include "dsc/dsc.h"
+#include "clock_source.h"
+#include "hw/timing_generator.h"
+#include "hw/opp.h"
+#include "hw/link_encoder.h"
+#include "core_status.h"
+#include "hw/hw_shared.h"
+#include "hw/dchubbub.h"
+#include "../dsc/dsc.h"
 #include "link_service_types.h"
 #include "dmub/inc/dmub_cmd.h"
 #include "dc_dmub_srv.h"
diff --git a/drivers/gpu/drm/amd/display/dc/inc/core_types.h b/drivers/gpu/drm/amd/display/dc/inc/core_types.h
index 695eaa5cbf65..16145c863cd9 100644
--- a/drivers/gpu/drm/amd/display/dc/inc/core_types.h
+++ b/drivers/gpu/drm/amd/display/dc/inc/core_types.h
@@ -40,9 +40,9 @@
 #include "mcif_wb.h"
 #include "panel_cntl.h"
 #include "dmub/inc/dmub_cmd.h"
-#include "bls_builder/bls_builder_legacy_init.h"
+#include "../bls_builder/bls_builder_legacy_init.h"
 #include "pg_cntl.h"
-#include "sspl/dc_spl.h"
+#include "../sspl/dc_spl.h"
 
 #define MAX_CLOCK_SOURCES 7
 #define MAX_SVP_PHANTOM_STREAMS 2
@@ -61,8 +61,8 @@
 #include "transform.h"
 #include "dpp.h"
 
-#include "dml2_0/dml21/inc/dml_top_dchub_registers.h"
-#include "dml2_0/dml21/inc/dml_top_types.h"
+#include "../dml2_0/dml21/inc/dml_top_dchub_registers.h"
+#include "../dml2_0/dml21/inc/dml_top_types.h"
 
 struct resource_pool;
 struct dc_state;
diff --git a/drivers/gpu/drm/amd/display/dc/dc.h b/drivers/gpu/drm/amd/display/dc/inc/dc.h
similarity index 99%
rename from drivers/gpu/drm/amd/display/dc/dc.h
rename to drivers/gpu/drm/amd/display/dc/inc/dc.h
index d976425c190b..d20180a449d5 100644
--- a/drivers/gpu/drm/amd/display/dc/dc.h
+++ b/drivers/gpu/drm/amd/display/dc/inc/dc.h
@@ -37,22 +37,22 @@
 #include "gpio_types.h"
 #include "link_service_types.h"
 #include "grph_object_ctrl_defs.h"
-#include <inc/hw/opp.h>
-#include <inc/hw/rmcm.h>
+#include "hw/opp.h"
+#include "hw/rmcm.h"
 
-#include "hwss/hw_sequencer.h"
-#include "inc/compressor.h"
-#include "inc/hw/dmcu.h"
-#include "dml/display_mode_lib.h"
+#include "../hwss/hw_sequencer.h"
+#include "compressor.h"
+#include "hw/dmcu.h"
+#include "../dml/display_mode_lib.h"
 
-#include "dml2_wrapper/dml2_wrapper.h"
+#include "../dml2_wrapper/dml2_wrapper.h"
 
 #include "dmub/inc/dmub_cmd.h"
 
-#include "dml/dml1_frl_cap_chk.h"
+#include "../dml/dml1_frl_cap_chk.h"
 
-#include "sspl/dc_spl_types.h"
-#include "inc/dc_core_interface.h"
+#include "../sspl/dc_spl_types.h"
+#include "dc_core_interface.h"
 
 struct abm_save_restore;
 
diff --git a/drivers/gpu/drm/amd/display/dc/dc_bios_types.h b/drivers/gpu/drm/amd/display/dc/inc/dc_bios_types.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dc_bios_types.h
rename to drivers/gpu/drm/amd/display/dc/inc/dc_bios_types.h
diff --git a/drivers/gpu/drm/amd/display/dc/dc_ddc_types.h b/drivers/gpu/drm/amd/display/dc/inc/dc_ddc_types.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dc_ddc_types.h
rename to drivers/gpu/drm/amd/display/dc/inc/dc_ddc_types.h
diff --git a/drivers/gpu/drm/amd/display/dc/dc_dmub_srv.h b/drivers/gpu/drm/amd/display/dc/inc/dc_dmub_srv.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dc_dmub_srv.h
rename to drivers/gpu/drm/amd/display/dc/inc/dc_dmub_srv.h
diff --git a/drivers/gpu/drm/amd/display/dc/dc_dp_types.h b/drivers/gpu/drm/amd/display/dc/inc/dc_dp_types.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dc_dp_types.h
rename to drivers/gpu/drm/amd/display/dc/inc/dc_dp_types.h
diff --git a/drivers/gpu/drm/amd/display/dc/dc_dsc.h b/drivers/gpu/drm/amd/display/dc/inc/dc_dsc.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dc_dsc.h
rename to drivers/gpu/drm/amd/display/dc/inc/dc_dsc.h
diff --git a/drivers/gpu/drm/amd/display/dc/dc_fused_io.h b/drivers/gpu/drm/amd/display/dc/inc/dc_fused_io.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dc_fused_io.h
rename to drivers/gpu/drm/amd/display/dc/inc/dc_fused_io.h
diff --git a/drivers/gpu/drm/amd/display/dc/dc_hdmi_types.h b/drivers/gpu/drm/amd/display/dc/inc/dc_hdmi_types.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dc_hdmi_types.h
rename to drivers/gpu/drm/amd/display/dc/inc/dc_hdmi_types.h
diff --git a/drivers/gpu/drm/amd/display/dc/dc_hw_types.h b/drivers/gpu/drm/amd/display/dc/inc/dc_hw_types.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dc_hw_types.h
rename to drivers/gpu/drm/amd/display/dc/inc/dc_hw_types.h
diff --git a/drivers/gpu/drm/amd/display/dc/dc_memory_pool.h b/drivers/gpu/drm/amd/display/dc/inc/dc_memory_pool.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dc_memory_pool.h
rename to drivers/gpu/drm/amd/display/dc/inc/dc_memory_pool.h
diff --git a/drivers/gpu/drm/amd/display/dc/dc_plane.h b/drivers/gpu/drm/amd/display/dc/inc/dc_plane.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dc_plane.h
rename to drivers/gpu/drm/amd/display/dc/inc/dc_plane.h
diff --git a/drivers/gpu/drm/amd/display/dc/dc_probe.h b/drivers/gpu/drm/amd/display/dc/inc/dc_probe.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dc_probe.h
rename to drivers/gpu/drm/amd/display/dc/inc/dc_probe.h
diff --git a/drivers/gpu/drm/amd/display/dc/dc_stat.h b/drivers/gpu/drm/amd/display/dc/inc/dc_stat.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dc_stat.h
rename to drivers/gpu/drm/amd/display/dc/inc/dc_stat.h
diff --git a/drivers/gpu/drm/amd/display/dc/dc_state.h b/drivers/gpu/drm/amd/display/dc/inc/dc_state.h
similarity index 99%
rename from drivers/gpu/drm/amd/display/dc/dc_state.h
rename to drivers/gpu/drm/amd/display/dc/inc/dc_state.h
index acf461225e9d..a8c7296b17e3 100644
--- a/drivers/gpu/drm/amd/display/dc/dc_state.h
+++ b/drivers/gpu/drm/amd/display/dc/inc/dc_state.h
@@ -26,7 +26,7 @@
 #ifndef _DC_STATE_H_
 #define _DC_STATE_H_
 
-#include "inc/core_status.h"
+#include "core_status.h"
 
 struct dc_state *dc_state_create(struct dc *dc, struct dc_state_create_params *params);
 void dc_state_copy(struct dc_state *dst_state, struct dc_state *src_state);
diff --git a/drivers/gpu/drm/amd/display/dc/dc_stream.h b/drivers/gpu/drm/amd/display/dc/inc/dc_stream.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dc_stream.h
rename to drivers/gpu/drm/amd/display/dc/inc/dc_stream.h
diff --git a/drivers/gpu/drm/amd/display/dc/dc_trace.h b/drivers/gpu/drm/amd/display/dc/inc/dc_trace.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dc_trace.h
rename to drivers/gpu/drm/amd/display/dc/inc/dc_trace.h
diff --git a/drivers/gpu/drm/amd/display/dc/dc_types.h b/drivers/gpu/drm/amd/display/dc/inc/dc_types.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dc_types.h
rename to drivers/gpu/drm/amd/display/dc/inc/dc_types.h
diff --git a/drivers/gpu/drm/amd/display/dc/inc/dcn_calcs.h b/drivers/gpu/drm/amd/display/dc/inc/dcn_calcs.h
index 134091d5842d..845dc8ccd636 100644
--- a/drivers/gpu/drm/amd/display/dc/inc/dcn_calcs.h
+++ b/drivers/gpu/drm/amd/display/dc/inc/dcn_calcs.h
@@ -31,7 +31,7 @@
 #define __DCN_CALCS_H__
 
 #include "bw_fixed.h"
-#include "dml/display_mode_lib.h"
+#include "../dml/display_mode_lib.h"
 
 
 struct dc;
diff --git a/drivers/gpu/drm/amd/display/dc/dm_cp_psp.h b/drivers/gpu/drm/amd/display/dc/inc/dm_cp_psp.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dm_cp_psp.h
rename to drivers/gpu/drm/amd/display/dc/inc/dm_cp_psp.h
diff --git a/drivers/gpu/drm/amd/display/dc/dm_helpers.h b/drivers/gpu/drm/amd/display/dc/inc/dm_helpers.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dm_helpers.h
rename to drivers/gpu/drm/amd/display/dc/inc/dm_helpers.h
diff --git a/drivers/gpu/drm/amd/display/dc/dm_pp_smu.h b/drivers/gpu/drm/amd/display/dc/inc/dm_pp_smu.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dm_pp_smu.h
rename to drivers/gpu/drm/amd/display/dc/inc/dm_pp_smu.h
diff --git a/drivers/gpu/drm/amd/display/dc/dm_services.h b/drivers/gpu/drm/amd/display/dc/inc/dm_services.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dm_services.h
rename to drivers/gpu/drm/amd/display/dc/inc/dm_services.h
diff --git a/drivers/gpu/drm/amd/display/dc/dm_services_types.h b/drivers/gpu/drm/amd/display/dc/inc/dm_services_types.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/dm_services_types.h
rename to drivers/gpu/drm/amd/display/dc/inc/dm_services_types.h
diff --git a/drivers/gpu/drm/amd/display/dc/inc/hw/dchubbub.h b/drivers/gpu/drm/amd/display/dc/inc/hw/dchubbub.h
index b33273b61abd..030b1ccd90d9 100644
--- a/drivers/gpu/drm/amd/display/dc/inc/hw/dchubbub.h
+++ b/drivers/gpu/drm/amd/display/dc/inc/hw/dchubbub.h
@@ -33,7 +33,7 @@
  * blocks for the Data Fabric Interface that are not clock/power gated.
  */
 
-#include "dc/dc_hw_types.h"
+#include "dc_hw_types.h"
 
 enum dcc_control {
 	dcc_control__256_256_xxx,
diff --git a/drivers/gpu/drm/amd/display/dc/inc/hw/hubp.h b/drivers/gpu/drm/amd/display/dc/inc/hw/hubp.h
index d1cbcb87d271..6eade7556ffa 100644
--- a/drivers/gpu/drm/amd/display/dc/inc/hw/hubp.h
+++ b/drivers/gpu/drm/amd/display/dc/inc/hw/hubp.h
@@ -41,8 +41,8 @@
 #include "mem_input.h"
 #include "cursor_reg_cache.h"
 
-#include "dml2_0/dml21/inc/dml_top_dchub_registers.h"
-#include "dml2_0/dml21/inc/dml_top_types.h"
+#include "../../dml2_0/dml21/inc/dml_top_dchub_registers.h"
+#include "../../dml2_0/dml21/inc/dml_top_types.h"
 
 #define OPP_ID_INVALID 0xf
 #define MAX_TTU 0xffffff
diff --git a/drivers/gpu/drm/amd/display/dc/inc/hw/mcif_wb.h b/drivers/gpu/drm/amd/display/dc/inc/hw/mcif_wb.h
index aae0ad7ae835..ad267dc9e505 100644
--- a/drivers/gpu/drm/amd/display/dc/inc/hw/mcif_wb.h
+++ b/drivers/gpu/drm/amd/display/dc/inc/hw/mcif_wb.h
@@ -27,7 +27,7 @@
 
 #include "dc_hw_types.h"
 
-#include "dml2_0/dml21/inc/dml_top_dchub_registers.h"
+#include "../../dml2_0/dml21/inc/dml_top_dchub_registers.h"
 
 enum mmhubbub_wbif_mode {
 	PACKED_444 = 0,
diff --git a/drivers/gpu/drm/amd/display/dc/inc/hw/mem_input.h b/drivers/gpu/drm/amd/display/dc/inc/hw/mem_input.h
index d468bc85566a..bb7eed3ddb90 100644
--- a/drivers/gpu/drm/amd/display/dc/inc/hw/mem_input.h
+++ b/drivers/gpu/drm/amd/display/dc/inc/hw/mem_input.h
@@ -28,8 +28,8 @@
 #include "dc.h"
 #include "include/grph_object_id.h"
 
-#include "dml/display_mode_structs.h"
-#include "dml2_0/dml21/inc/dml_top_dchub_registers.h"
+#include "../../dml/display_mode_structs.h"
+#include "../../dml2_0/dml21/inc/dml_top_dchub_registers.h"
 
 struct dchub_init_data;
 struct cstate_pstate_watermarks_st {
diff --git a/drivers/gpu/drm/amd/display/dc/inc/hw/transform.h b/drivers/gpu/drm/amd/display/dc/inc/hw/transform.h
index d67373ec8e36..38f6bdd57dc7 100644
--- a/drivers/gpu/drm/amd/display/dc/inc/hw/transform.h
+++ b/drivers/gpu/drm/amd/display/dc/inc/hw/transform.h
@@ -29,7 +29,7 @@
 #include "hw_shared.h"
 #include "dc_hw_types.h"
 #include "fixed31_32.h"
-#include "sspl/dc_spl_types.h"
+#include "../sspl/dc_spl_types.h"
 
 #define CSC_TEMPERATURE_MATRIX_SIZE 12
 
diff --git a/drivers/gpu/drm/amd/display/dc/irq_types.h b/drivers/gpu/drm/amd/display/dc/inc/irq_types.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/irq_types.h
rename to drivers/gpu/drm/amd/display/dc/inc/irq_types.h
diff --git a/drivers/gpu/drm/amd/display/dc/os_types.h b/drivers/gpu/drm/amd/display/dc/inc/os_types.h
similarity index 100%
rename from drivers/gpu/drm/amd/display/dc/os_types.h
rename to drivers/gpu/drm/amd/display/dc/inc/os_types.h
diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_dpia.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_dpia.c
index da227889e007..b41e6ad65710 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_dpia.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_dpia.c
@@ -25,7 +25,7 @@
  */
 
 #include "dc.h"
-#include "inc/core_status.h"
+#include "core_status.h"
 #include "dpcd_defs.h"
 
 #include "link_dp_dpia.h"
diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_panel_replay.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_panel_replay.c
index 4b7b104bd3a8..e7b9b735de18 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_panel_replay.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_panel_replay.c
@@ -28,7 +28,7 @@
 #include "link_ddc.h"
 #include "link_dpcd.h"
 #include "dm_helpers.h"
-#include "dc/dc_dmub_srv.h"
+#include "dc_dmub_srv.h"
 #include "dce/dmub_replay.h"
 #include "dc_priv.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_dpia.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_dpia.c
index f1817c7f0948..fb972358ecc1 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_dpia.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_dpia.c
@@ -29,7 +29,7 @@
 #include "link_dp_training_dpia.h"
 #include "dc.h"
 #include "dc_priv.h"
-#include "inc/core_status.h"
+#include "core_status.h"
 #include "dpcd_defs.h"
 
 #include "link_dp_dpia.h"
diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_edp_panel_control.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_edp_panel_control.c
index f88fccf007c0..7d6b8759cb1a 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_edp_panel_control.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_edp_panel_control.c
@@ -36,7 +36,7 @@
 #include "dal_asic_id.h"
 #include "link_dp_phy.h"
 #include "dce/dmub_psr.h"
-#include "dc/dc_dmub_srv.h"
+#include "dc_dmub_srv.h"
 #include "dce/dmub_replay.h"
 #include "abm.h"
 #include "resource.h"
diff --git a/drivers/gpu/drm/amd/display/dmub/dmub_srv.h b/drivers/gpu/drm/amd/display/dmub/dmub_srv.h
index 84f825c924bc..75aaf507d0b7 100644
--- a/drivers/gpu/drm/amd/display/dmub/dmub_srv.h
+++ b/drivers/gpu/drm/amd/display/dmub/dmub_srv.h
@@ -66,7 +66,7 @@
  */
 
 #include "inc/dmub_cmd.h"
-#include "dc/dc_types.h"
+#include "dc_types.h"
 
 #define DMUB_PC_SNAPSHOT_COUNT 10
 #define DMUB_TRACE_SNAPSHOT_COUNT 8
diff --git a/drivers/gpu/drm/amd/display/dmub/src/dmub_dcn32.c b/drivers/gpu/drm/amd/display/dmub/src/dmub_dcn32.c
index 0d585dc63364..0911e1e139c1 100644
--- a/drivers/gpu/drm/amd/display/dmub/src/dmub_dcn32.c
+++ b/drivers/gpu/drm/amd/display/dmub/src/dmub_dcn32.c
@@ -26,7 +26,7 @@
 #include "../dmub_srv.h"
 #include "dmub_reg.h"
 #include "dmub_dcn32.h"
-#include "dc/dc_types.h"
+#include "dc_types.h"
 #include "dc_hw_types.h"
 
 #include "dcn/dcn_3_2_0_offset.h"
diff --git a/drivers/gpu/drm/amd/display/dmub/src/dmub_dcn35.c b/drivers/gpu/drm/amd/display/dmub/src/dmub_dcn35.c
index bd7637276aa6..19573e2f48d1 100644
--- a/drivers/gpu/drm/amd/display/dmub/src/dmub_dcn35.c
+++ b/drivers/gpu/drm/amd/display/dmub/src/dmub_dcn35.c
@@ -27,7 +27,7 @@
 #include "dc_types.h"
 #include "dmub_reg.h"
 #include "dmub_dcn35.h"
-#include "dc/dc_types.h"
+#include "dc_types.h"
 
 #include "dcn/dcn_3_5_0_offset.h"
 #include "dcn/dcn_3_5_0_sh_mask.h"
diff --git a/drivers/gpu/drm/amd/display/modules/power/power.c b/drivers/gpu/drm/amd/display/modules/power/power.c
index 884279696a2d..32c00a515d4f 100644
--- a/drivers/gpu/drm/amd/display/modules/power/power.c
+++ b/drivers/gpu/drm/amd/display/modules/power/power.c
@@ -30,7 +30,7 @@
 #include "dmcu.h"
 #include "abm.h"
 #include "power_helpers.h"
-#include "dce/dmub_psr.h"
+#include "dc/dce/dmub_psr.h"
 #include "dal_asic_id.h"
 #include "link_service.h"
 #include <linux/math.h>
diff --git a/drivers/gpu/drm/amd/display/modules/power/power_abm.c b/drivers/gpu/drm/amd/display/modules/power/power_abm.c
index 2b420eac5c56..6dabd30b4956 100644
--- a/drivers/gpu/drm/amd/display/modules/power/power_abm.c
+++ b/drivers/gpu/drm/amd/display/modules/power/power_abm.c
@@ -9,7 +9,7 @@
 #include "dmcu.h"
 #include "abm.h"
 #include "power_helpers.h"
-#include "dce/dmub_psr.h"
+#include "dc/dce/dmub_psr.h"
 #include "dal_asic_id.h"
 #include "link_service.h"
 #include <linux/math.h>
diff --git a/drivers/gpu/drm/amd/display/modules/power/power_psr.c b/drivers/gpu/drm/amd/display/modules/power/power_psr.c
index af59cf502297..219b199350cd 100644
--- a/drivers/gpu/drm/amd/display/modules/power/power_psr.c
+++ b/drivers/gpu/drm/amd/display/modules/power/power_psr.c
@@ -9,7 +9,7 @@
 #include "dmcu.h"
 #include "abm.h"
 #include "power_helpers.h"
-#include "dce/dmub_psr.h"
+#include "dc/dce/dmub_psr.h"
 #include "dal_asic_id.h"
 #include "link_service.h"
 #include <linux/math.h>
diff --git a/drivers/gpu/drm/amd/display/modules/power/power_replay.c b/drivers/gpu/drm/amd/display/modules/power/power_replay.c
index d68f14b18179..ccadbe07f302 100644
--- a/drivers/gpu/drm/amd/display/modules/power/power_replay.c
+++ b/drivers/gpu/drm/amd/display/modules/power/power_replay.c
@@ -9,7 +9,7 @@
 #include "dmcu.h"
 #include "abm.h"
 #include "power_helpers.h"
-#include "dce/dmub_psr.h"
+#include "dc/dce/dmub_psr.h"
 #include "dal_asic_id.h"
 #include "link_service.h"
 #include <linux/math.h>
diff --git a/drivers/gpu/drm/amd/pm/swsmu/inc/amdgpu_smu.h b/drivers/gpu/drm/amd/pm/swsmu/inc/amdgpu_smu.h
index 4e6dc9d41256..d0c0534a7e73 100644
--- a/drivers/gpu/drm/amd/pm/swsmu/inc/amdgpu_smu.h
+++ b/drivers/gpu/drm/amd/pm/swsmu/inc/amdgpu_smu.h
@@ -28,7 +28,7 @@
 #include "amdgpu.h"
 #include "kgd_pp_interface.h"
 #include "dm_pp_interface.h"
-#include "dm_pp_smu.h"
+#include "dc/inc/dm_pp_smu.h"
 #include "smu_types.h"
 #include "linux/firmware.h"
 #include <linux/ktime.h>

-- 
2.56.0

