From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:08:29 +0100
Subject: [PATCH 51/86] drm/i915: Direct include headers from
 drm_atomic_helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-51-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331667; l=9120;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=XAR6zpwi+obJucxSkllEqls3407BxXObg6cQQKE1byM=;
 b=liPBUorNr+0AU984zx5XA+ZLpH6wByLGtdJxtsJNR+vzlBB2hC3zY3b3Tar7CgDNd4gYp84uTdsR
 AtAT2r2iACFYHgeCiVNfS8eTm4mQmCqwC/pYxWgqQC63yYaAefDl
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_atomic_helper, because drm_atomic_helper will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/i915/display/icl_dsi.c            | 2 ++
 drivers/gpu/drm/i915/display/intel_atomic.c       | 1 +
 drivers/gpu/drm/i915/display/intel_atomic_plane.c | 2 ++
 drivers/gpu/drm/i915/display/intel_connector.c    | 1 +
 drivers/gpu/drm/i915/display/intel_crt.c          | 2 ++
 drivers/gpu/drm/i915/display/intel_crtc.c         | 1 +
 drivers/gpu/drm/i915/display/intel_display.c      | 3 +++
 drivers/gpu/drm/i915/display/intel_dp.c           | 2 ++
 drivers/gpu/drm/i915/display/intel_dp_mst.c       | 2 ++
 drivers/gpu/drm/i915/display/intel_dvo.c          | 2 ++
 drivers/gpu/drm/i915/display/intel_hdmi.c         | 2 ++
 drivers/gpu/drm/i915/display/intel_lvds.c         | 2 ++
 drivers/gpu/drm/i915/display/intel_sdvo.c         | 2 ++
 drivers/gpu/drm/i915/display/intel_tv.c           | 2 ++
 drivers/gpu/drm/i915/display/vlv_dsi.c            | 2 ++
 15 files changed, 28 insertions(+)

diff --git a/drivers/gpu/drm/i915/display/icl_dsi.c b/drivers/gpu/drm/i915/display/icl_dsi.c
index ae14c794c4bc..e5465ec1fe11 100644
--- a/drivers/gpu/drm/i915/display/icl_dsi.c
+++ b/drivers/gpu/drm/i915/display/icl_dsi.c
@@ -27,7 +27,9 @@
 
 #include <drm/display/drm_dsc_helper.h>
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_mipi_dsi.h>
+#include <drm/drm_modeset_helper_vtables.h>
 
 #include "i915_reg.h"
 #include "icl_dsi.h"
diff --git a/drivers/gpu/drm/i915/display/intel_atomic.c b/drivers/gpu/drm/i915/display/intel_atomic.c
index a9a3f3715279..7a2a77c2abea 100644
--- a/drivers/gpu/drm/i915/display/intel_atomic.c
+++ b/drivers/gpu/drm/i915/display/intel_atomic.c
@@ -31,6 +31,7 @@
 
 #include <drm/drm_atomic.h>
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_fourcc.h>
 
 #include "i915_drv.h"
diff --git a/drivers/gpu/drm/i915/display/intel_atomic_plane.c b/drivers/gpu/drm/i915/display/intel_atomic_plane.c
index 10e1fc9d0698..acccfd6eb0d9 100644
--- a/drivers/gpu/drm/i915/display/intel_atomic_plane.c
+++ b/drivers/gpu/drm/i915/display/intel_atomic_plane.c
@@ -32,7 +32,9 @@
  */
 
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_fourcc.h>
+#include <drm/drm_modeset_helper_vtables.h>
 
 #include "gt/intel_rps.h"
 
diff --git a/drivers/gpu/drm/i915/display/intel_connector.c b/drivers/gpu/drm/i915/display/intel_connector.c
index 562da3b741e2..754f0999cdee 100644
--- a/drivers/gpu/drm/i915/display/intel_connector.c
+++ b/drivers/gpu/drm/i915/display/intel_connector.c
@@ -27,6 +27,7 @@
 #include <linux/slab.h>
 
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_edid.h>
 
 #include "i915_drv.h"
diff --git a/drivers/gpu/drm/i915/display/intel_crt.c b/drivers/gpu/drm/i915/display/intel_crt.c
index 7267ffc7f539..1afc57325b9d 100644
--- a/drivers/gpu/drm/i915/display/intel_crt.c
+++ b/drivers/gpu/drm/i915/display/intel_crt.c
@@ -29,8 +29,10 @@
 #include <linux/slab.h>
 
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_crtc.h>
 #include <drm/drm_edid.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_probe_helper.h>
 
 #include "i915_drv.h"
diff --git a/drivers/gpu/drm/i915/display/intel_crtc.c b/drivers/gpu/drm/i915/display/intel_crtc.c
index 037fc140b585..e652ad01bc44 100644
--- a/drivers/gpu/drm/i915/display/intel_crtc.c
+++ b/drivers/gpu/drm/i915/display/intel_crtc.c
@@ -7,6 +7,7 @@
 #include <linux/slab.h>
 
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_fourcc.h>
 #include <drm/drm_plane.h>
 #include <drm/drm_vblank_work.h>
diff --git a/drivers/gpu/drm/i915/display/intel_display.c b/drivers/gpu/drm/i915/display/intel_display.c
index e75b9b2a0e01..7778c46566d9 100644
--- a/drivers/gpu/drm/i915/display/intel_display.c
+++ b/drivers/gpu/drm/i915/display/intel_display.c
@@ -37,10 +37,13 @@
 #include <drm/display/drm_dp_helper.h>
 #include <drm/drm_atomic.h>
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_atomic_uapi.h>
 #include <drm/drm_damage_helper.h>
 #include <drm/drm_edid.h>
 #include <drm/drm_fourcc.h>
+#include <drm/drm_modeset_helper.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_privacy_screen_consumer.h>
 #include <drm/drm_probe_helper.h>
 #include <drm/drm_rect.h>
diff --git a/drivers/gpu/drm/i915/display/intel_dp.c b/drivers/gpu/drm/i915/display/intel_dp.c
index 80d95cec8f9d..aa19c6be03a4 100644
--- a/drivers/gpu/drm/i915/display/intel_dp.c
+++ b/drivers/gpu/drm/i915/display/intel_dp.c
@@ -35,12 +35,14 @@
 
 #include <asm/byteorder.h>
 
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/display/drm_dp_helper.h>
 #include <drm/display/drm_dsc_helper.h>
 #include <drm/display/drm_hdmi_helper.h>
 #include <drm/drm_atomic_helper.h>
 #include <drm/drm_crtc.h>
 #include <drm/drm_edid.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_probe_helper.h>
 
 #include "g4x_dp.h"
diff --git a/drivers/gpu/drm/i915/display/intel_dp_mst.c b/drivers/gpu/drm/i915/display/intel_dp_mst.c
index 8b0e4defa3f1..b030f11578a5 100644
--- a/drivers/gpu/drm/i915/display/intel_dp_mst.c
+++ b/drivers/gpu/drm/i915/display/intel_dp_mst.c
@@ -25,7 +25,9 @@
 
 #include <drm/drm_atomic.h>
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_edid.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_probe_helper.h>
 
 #include "i915_drv.h"
diff --git a/drivers/gpu/drm/i915/display/intel_dvo.c b/drivers/gpu/drm/i915/display/intel_dvo.c
index 4aeae0f3ac91..cdf0c2dd72f3 100644
--- a/drivers/gpu/drm/i915/display/intel_dvo.c
+++ b/drivers/gpu/drm/i915/display/intel_dvo.c
@@ -29,7 +29,9 @@
 #include <linux/slab.h>
 
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_crtc.h>
+#include <drm/drm_modeset_helper_vtables.h>
 
 #include "i915_drv.h"
 #include "i915_reg.h"
diff --git a/drivers/gpu/drm/i915/display/intel_hdmi.c b/drivers/gpu/drm/i915/display/intel_hdmi.c
index 6a2ee342eab5..5a3ad2fb38ae 100644
--- a/drivers/gpu/drm/i915/display/intel_hdmi.c
+++ b/drivers/gpu/drm/i915/display/intel_hdmi.c
@@ -36,8 +36,10 @@
 #include <drm/display/drm_hdmi_helper.h>
 #include <drm/display/drm_scdc_helper.h>
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_crtc.h>
 #include <drm/drm_edid.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/intel_lpe_audio.h>
 
 #include "i915_debugfs.h"
diff --git a/drivers/gpu/drm/i915/display/intel_lvds.c b/drivers/gpu/drm/i915/display/intel_lvds.c
index aecec992cd0d..f049583f05c5 100644
--- a/drivers/gpu/drm/i915/display/intel_lvds.c
+++ b/drivers/gpu/drm/i915/display/intel_lvds.c
@@ -35,8 +35,10 @@
 #include <linux/vga_switcheroo.h>
 
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_crtc.h>
 #include <drm/drm_edid.h>
+#include <drm/drm_modeset_helper_vtables.h>
 
 #include "i915_drv.h"
 #include "i915_reg.h"
diff --git a/drivers/gpu/drm/i915/display/intel_sdvo.c b/drivers/gpu/drm/i915/display/intel_sdvo.c
index 21805c15d5eb..3c6248eee3a4 100644
--- a/drivers/gpu/drm/i915/display/intel_sdvo.c
+++ b/drivers/gpu/drm/i915/display/intel_sdvo.c
@@ -33,8 +33,10 @@
 
 #include <drm/display/drm_hdmi_helper.h>
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_crtc.h>
 #include <drm/drm_edid.h>
+#include <drm/drm_modeset_helper_vtables.h>
 
 #include "i915_drv.h"
 #include "i915_reg.h"
diff --git a/drivers/gpu/drm/i915/display/intel_tv.c b/drivers/gpu/drm/i915/display/intel_tv.c
index b986bf075889..a3559ad07734 100644
--- a/drivers/gpu/drm/i915/display/intel_tv.c
+++ b/drivers/gpu/drm/i915/display/intel_tv.c
@@ -31,8 +31,10 @@
  */
 
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_crtc.h>
 #include <drm/drm_edid.h>
+#include <drm/drm_modeset_helper_vtables.h>
 
 #include "i915_drv.h"
 #include "i915_reg.h"
diff --git a/drivers/gpu/drm/i915/display/vlv_dsi.c b/drivers/gpu/drm/i915/display/vlv_dsi.c
index 662bdb656aa3..9dfe98bf1dfa 100644
--- a/drivers/gpu/drm/i915/display/vlv_dsi.c
+++ b/drivers/gpu/drm/i915/display/vlv_dsi.c
@@ -26,9 +26,11 @@
 #include <linux/slab.h>
 
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_crtc.h>
 #include <drm/drm_edid.h>
 #include <drm/drm_mipi_dsi.h>
+#include <drm/drm_modeset_helper_vtables.h>
 
 #include "i915_drv.h"
 #include "i915_reg.h"

-- 
2.34.1

