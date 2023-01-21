From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:08:38 +0100
Subject: [PATCH 60/86] drm/msm: Direct include headers from
 drm_atomic_helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-60-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331667; l=11372;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=09cf+/OAUQvnK9vAo6ce5l67SWLl3GkBBpj2ThCsTJU=;
 b=i6TKCCZTqkvfwpujR1Ahvz0pf/P/G4/+S2D+2Jnr5/Ew2BoPRn4nCQhpoAuRsq/K02JPBM43Yv51
 Mpyih0m0Bb8aTolO3eba9zLKi6mriGR3hFTKlCqaaccWCRhZb1Wq
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_atomic_helper, because drm_atomic_helper will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/msm/disp/dpu1/dpu_crtc.c            | 2 ++
 drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c         | 1 +
 drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c             | 1 +
 drivers/gpu/drm/msm/disp/dpu1/dpu_plane.c           | 2 ++
 drivers/gpu/drm/msm/disp/dpu1/dpu_writeback.c       | 2 ++
 drivers/gpu/drm/msm/disp/mdp4/mdp4_crtc.c           | 2 ++
 drivers/gpu/drm/msm/disp/mdp4/mdp4_dsi_encoder.c    | 1 +
 drivers/gpu/drm/msm/disp/mdp4/mdp4_dtv_encoder.c    | 2 ++
 drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.c            | 1 +
 drivers/gpu/drm/msm/disp/mdp4/mdp4_lcdc_encoder.c   | 2 ++
 drivers/gpu/drm/msm/disp/mdp4/mdp4_lvds_connector.c | 3 +++
 drivers/gpu/drm/msm/disp/mdp4/mdp4_plane.c          | 2 ++
 drivers/gpu/drm/msm/disp/mdp5/mdp5_crtc.c           | 2 ++
 drivers/gpu/drm/msm/disp/mdp5/mdp5_encoder.c        | 1 +
 drivers/gpu/drm/msm/disp/mdp5/mdp5_kms.c            | 1 +
 drivers/gpu/drm/msm/disp/mdp5/mdp5_kms.h            | 2 ++
 drivers/gpu/drm/msm/disp/mdp5/mdp5_plane.c          | 2 ++
 drivers/gpu/drm/msm/dp/dp_drm.c                     | 1 +
 drivers/gpu/drm/msm/msm_drv.c                       | 2 ++
 drivers/gpu/drm/msm/msm_fb.c                        | 1 +
 20 files changed, 33 insertions(+)

diff --git a/drivers/gpu/drm/msm/disp/dpu1/dpu_crtc.c b/drivers/gpu/drm/msm/disp/dpu1/dpu_crtc.c
index 13ce321283ff..3f56cdd5a50c 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/dpu_crtc.c
+++ b/drivers/gpu/drm/msm/disp/dpu1/dpu_crtc.c
@@ -13,11 +13,13 @@
 #include <linux/bits.h>
 
 #include <drm/drm_atomic.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_blend.h>
 #include <drm/drm_crtc.h>
 #include <drm/drm_flip_work.h>
 #include <drm/drm_framebuffer.h>
 #include <drm/drm_mode.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_probe_helper.h>
 #include <drm/drm_rect.h>
 #include <drm/drm_vblank.h>
diff --git a/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c b/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
index 9c6817b5a194..cf6108687144 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
+++ b/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
@@ -14,6 +14,7 @@
 
 #include <drm/drm_crtc.h>
 #include <drm/drm_file.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_probe_helper.h>
 
 #include "msm_drv.h"
diff --git a/drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c b/drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c
index b71199511a52..8e910127511c 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c
+++ b/drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c
@@ -14,6 +14,7 @@
 #include <linux/of_irq.h>
 #include <linux/pm_opp.h>
 
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_crtc.h>
 #include <drm/drm_file.h>
 #include <drm/drm_framebuffer.h>
diff --git a/drivers/gpu/drm/msm/disp/dpu1/dpu_plane.c b/drivers/gpu/drm/msm/disp/dpu1/dpu_plane.c
index 86719020afe2..3827538dd93b 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/dpu_plane.c
+++ b/drivers/gpu/drm/msm/disp/dpu1/dpu_plane.c
@@ -11,11 +11,13 @@
 #include <linux/dma-buf.h>
 
 #include <drm/drm_atomic.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_atomic_uapi.h>
 #include <drm/drm_blend.h>
 #include <drm/drm_damage_helper.h>
 #include <drm/drm_framebuffer.h>
 #include <drm/drm_gem_atomic_helper.h>
+#include <drm/drm_modeset_helper_vtables.h>
 
 #include "msm_drv.h"
 #include "dpu_kms.h"
diff --git a/drivers/gpu/drm/msm/disp/dpu1/dpu_writeback.c b/drivers/gpu/drm/msm/disp/dpu1/dpu_writeback.c
index 088ec990a2f2..9eae9687a006 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/dpu_writeback.c
+++ b/drivers/gpu/drm/msm/disp/dpu1/dpu_writeback.c
@@ -3,7 +3,9 @@
  * Copyright (c) 2022 Qualcomm Innovation Center, Inc. All rights reserved.
  */
 
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_edid.h>
+#include <drm/drm_modeset_helper_vtables.h>
 
 #include "dpu_writeback.h"
 
diff --git a/drivers/gpu/drm/msm/disp/mdp4/mdp4_crtc.c b/drivers/gpu/drm/msm/disp/mdp4/mdp4_crtc.c
index 169f9de4a12a..814da839b027 100644
--- a/drivers/gpu/drm/msm/disp/mdp4/mdp4_crtc.c
+++ b/drivers/gpu/drm/msm/disp/mdp4/mdp4_crtc.c
@@ -4,9 +4,11 @@
  * Author: Rob Clark <robdclark@gmail.com>
  */
 
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_crtc.h>
 #include <drm/drm_flip_work.h>
 #include <drm/drm_mode.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_probe_helper.h>
 #include <drm/drm_vblank.h>
 
diff --git a/drivers/gpu/drm/msm/disp/mdp4/mdp4_dsi_encoder.c b/drivers/gpu/drm/msm/disp/mdp4/mdp4_dsi_encoder.c
index 39b8fe53c29d..4aca7a143bb1 100644
--- a/drivers/gpu/drm/msm/disp/mdp4/mdp4_dsi_encoder.c
+++ b/drivers/gpu/drm/msm/disp/mdp4/mdp4_dsi_encoder.c
@@ -7,6 +7,7 @@
  */
 
 #include <drm/drm_crtc.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_probe_helper.h>
 
 #include "mdp4_kms.h"
diff --git a/drivers/gpu/drm/msm/disp/mdp4/mdp4_dtv_encoder.c b/drivers/gpu/drm/msm/disp/mdp4/mdp4_dtv_encoder.c
index 88645dbc3785..0acea1f03378 100644
--- a/drivers/gpu/drm/msm/disp/mdp4/mdp4_dtv_encoder.c
+++ b/drivers/gpu/drm/msm/disp/mdp4/mdp4_dtv_encoder.c
@@ -5,6 +5,8 @@
  */
 
 #include <drm/drm_crtc.h>
+#include <drm/drm_encoder.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_probe_helper.h>
 
 #include "mdp4_kms.h"
diff --git a/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.c b/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.c
index 9a1a0769575d..e28a1eb83b7d 100644
--- a/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.c
+++ b/drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.c
@@ -6,6 +6,7 @@
 
 #include <linux/delay.h>
 
+#include <drm/drm_encoder.h>
 #include <drm/drm_vblank.h>
 
 #include "msm_drv.h"
diff --git a/drivers/gpu/drm/msm/disp/mdp4/mdp4_lcdc_encoder.c b/drivers/gpu/drm/msm/disp/mdp4/mdp4_lcdc_encoder.c
index 10eb3e5b218e..fc232263c870 100644
--- a/drivers/gpu/drm/msm/disp/mdp4/mdp4_lcdc_encoder.c
+++ b/drivers/gpu/drm/msm/disp/mdp4/mdp4_lcdc_encoder.c
@@ -8,6 +8,8 @@
 #include <linux/delay.h>
 
 #include <drm/drm_crtc.h>
+#include <drm/drm_encoder.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_probe_helper.h>
 
 #include "mdp4_kms.h"
diff --git a/drivers/gpu/drm/msm/disp/mdp4/mdp4_lvds_connector.c b/drivers/gpu/drm/msm/disp/mdp4/mdp4_lvds_connector.c
index 7444b75c4215..a61d3f251a77 100644
--- a/drivers/gpu/drm/msm/disp/mdp4/mdp4_lvds_connector.c
+++ b/drivers/gpu/drm/msm/disp/mdp4/mdp4_lvds_connector.c
@@ -5,6 +5,9 @@
  * Author: Vinay Simha <vinaysimha@inforcecomputing.com>
  */
 
+#include <drm/drm_atomic_state_helper.h>
+#include <drm/drm_modeset_helper_vtables.h>
+
 #include "mdp4_kms.h"
 
 struct mdp4_lvds_connector {
diff --git a/drivers/gpu/drm/msm/disp/mdp4/mdp4_plane.c b/drivers/gpu/drm/msm/disp/mdp4/mdp4_plane.c
index b689b618da78..169d3c56e049 100644
--- a/drivers/gpu/drm/msm/disp/mdp4/mdp4_plane.c
+++ b/drivers/gpu/drm/msm/disp/mdp4/mdp4_plane.c
@@ -5,10 +5,12 @@
  */
 
 #include <drm/drm_atomic.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_damage_helper.h>
 #include <drm/drm_fourcc.h>
 #include <drm/drm_framebuffer.h>
 #include <drm/drm_gem_atomic_helper.h>
+#include <drm/drm_modeset_helper_vtables.h>
 
 #include "mdp4_kms.h"
 
diff --git a/drivers/gpu/drm/msm/disp/mdp5/mdp5_crtc.c b/drivers/gpu/drm/msm/disp/mdp5/mdp5_crtc.c
index e86421c69bd1..ebe4f87c7595 100644
--- a/drivers/gpu/drm/msm/disp/mdp5/mdp5_crtc.c
+++ b/drivers/gpu/drm/msm/disp/mdp5/mdp5_crtc.c
@@ -8,11 +8,13 @@
 #include <linux/sort.h>
 
 #include <drm/drm_atomic.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_blend.h>
 #include <drm/drm_mode.h>
 #include <drm/drm_crtc.h>
 #include <drm/drm_flip_work.h>
 #include <drm/drm_fourcc.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_probe_helper.h>
 #include <drm/drm_vblank.h>
 
diff --git a/drivers/gpu/drm/msm/disp/mdp5/mdp5_encoder.c b/drivers/gpu/drm/msm/disp/mdp5/mdp5_encoder.c
index 79d67c495780..c371c770fb4f 100644
--- a/drivers/gpu/drm/msm/disp/mdp5/mdp5_encoder.c
+++ b/drivers/gpu/drm/msm/disp/mdp5/mdp5_encoder.c
@@ -6,6 +6,7 @@
  */
 
 #include <drm/drm_crtc.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_probe_helper.h>
 
 #include "mdp5_kms.h"
diff --git a/drivers/gpu/drm/msm/disp/mdp5/mdp5_kms.c b/drivers/gpu/drm/msm/disp/mdp5/mdp5_kms.c
index 29ae5c9613f3..2e59aad43ebe 100644
--- a/drivers/gpu/drm/msm/disp/mdp5/mdp5_kms.c
+++ b/drivers/gpu/drm/msm/disp/mdp5/mdp5_kms.c
@@ -9,6 +9,7 @@
 #include <linux/interconnect.h>
 #include <linux/of_irq.h>
 
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_debugfs.h>
 #include <drm/drm_drv.h>
 #include <drm/drm_file.h>
diff --git a/drivers/gpu/drm/msm/disp/mdp5/mdp5_kms.h b/drivers/gpu/drm/msm/disp/mdp5/mdp5_kms.h
index 29bf11f08601..ef9a112cb7bc 100644
--- a/drivers/gpu/drm/msm/disp/mdp5/mdp5_kms.h
+++ b/drivers/gpu/drm/msm/disp/mdp5/mdp5_kms.h
@@ -7,6 +7,8 @@
 #ifndef __MDP5_KMS_H__
 #define __MDP5_KMS_H__
 
+#include <drm/drm_encoder.h>
+
 #include "msm_drv.h"
 #include "msm_kms.h"
 #include "disp/mdp_kms.h"
diff --git a/drivers/gpu/drm/msm/disp/mdp5/mdp5_plane.c b/drivers/gpu/drm/msm/disp/mdp5/mdp5_plane.c
index bd2c4ac45601..3f05154c3c0c 100644
--- a/drivers/gpu/drm/msm/disp/mdp5/mdp5_plane.c
+++ b/drivers/gpu/drm/msm/disp/mdp5/mdp5_plane.c
@@ -6,11 +6,13 @@
  */
 
 #include <drm/drm_atomic.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_blend.h>
 #include <drm/drm_damage_helper.h>
 #include <drm/drm_fourcc.h>
 #include <drm/drm_framebuffer.h>
 #include <drm/drm_gem_atomic_helper.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_print.h>
 
 #include "mdp5_kms.h"
diff --git a/drivers/gpu/drm/msm/dp/dp_drm.c b/drivers/gpu/drm/msm/dp/dp_drm.c
index 6db82f9b03af..c3105c02436b 100644
--- a/drivers/gpu/drm/msm/dp/dp_drm.c
+++ b/drivers/gpu/drm/msm/dp/dp_drm.c
@@ -5,6 +5,7 @@
 
 #include <drm/drm_atomic_helper.h>
 #include <drm/drm_atomic.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_bridge.h>
 #include <drm/drm_bridge_connector.h>
 #include <drm/drm_crtc.h>
diff --git a/drivers/gpu/drm/msm/msm_drv.c b/drivers/gpu/drm/msm/msm_drv.c
index 8b0b0ac74a6f..ec132e99e0fc 100644
--- a/drivers/gpu/drm/msm/msm_drv.c
+++ b/drivers/gpu/drm/msm/msm_drv.c
@@ -16,6 +16,8 @@
 #include <drm/drm_drv.h>
 #include <drm/drm_file.h>
 #include <drm/drm_ioctl.h>
+#include <drm/drm_modeset_helper.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_prime.h>
 #include <drm/drm_of.h>
 #include <drm/drm_vblank.h>
diff --git a/drivers/gpu/drm/msm/msm_fb.c b/drivers/gpu/drm/msm/msm_fb.c
index e3f61c39df69..b42085c6e7b4 100644
--- a/drivers/gpu/drm/msm/msm_fb.c
+++ b/drivers/gpu/drm/msm/msm_fb.c
@@ -10,6 +10,7 @@
 #include <drm/drm_fourcc.h>
 #include <drm/drm_framebuffer.h>
 #include <drm/drm_gem_framebuffer_helper.h>
+#include <drm/drm_modeset_helper.h>
 #include <drm/drm_probe_helper.h>
 
 #include "msm_drv.h"

-- 
2.34.1

