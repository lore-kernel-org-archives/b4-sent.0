From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:08:33 +0100
Subject: [PATCH 55/86] drm/logicvc: Direct include headers from
 drm_atomic_helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-55-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331667; l=2507;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=w9RLVltZWMyPuI0kcn93WYnbA6TZ5d8CgVI+/VyIlrw=;
 b=8vJ/jlL4HEklB9CpojIx+Kf+qEI4mqIRf4+WHcwL3/FCakhl4S1jpku8qoMSbEGYsJywjQGulas2
 5dTDFNN0BJtHxq/2Z6pauWCB2ACR90tJhWWzwlPPd4cnCm7G38vh
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_atomic_helper, because drm_atomic_helper will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/logicvc/logicvc_crtc.c      | 2 ++
 drivers/gpu/drm/logicvc/logicvc_crtc.h      | 2 ++
 drivers/gpu/drm/logicvc/logicvc_interface.c | 1 +
 drivers/gpu/drm/logicvc/logicvc_layer.c     | 2 ++
 4 files changed, 7 insertions(+)

diff --git a/drivers/gpu/drm/logicvc/logicvc_crtc.c b/drivers/gpu/drm/logicvc/logicvc_crtc.c
index 43a675d03808..83b882b28be4 100644
--- a/drivers/gpu/drm/logicvc/logicvc_crtc.c
+++ b/drivers/gpu/drm/logicvc/logicvc_crtc.c
@@ -10,9 +10,11 @@
 #include <linux/workqueue.h>
 
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_crtc.h>
 #include <drm/drm_drv.h>
 #include <drm/drm_gem_dma_helper.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_print.h>
 #include <drm/drm_vblank.h>
 
diff --git a/drivers/gpu/drm/logicvc/logicvc_crtc.h b/drivers/gpu/drm/logicvc/logicvc_crtc.h
index b122901f2936..1134dd2519ab 100644
--- a/drivers/gpu/drm/logicvc/logicvc_crtc.h
+++ b/drivers/gpu/drm/logicvc/logicvc_crtc.h
@@ -7,6 +7,8 @@
 #ifndef _LOGICVC_CRTC_H_
 #define _LOGICVC_CRTC_H_
 
+#include <drm/drm_crtc.h>
+
 struct drm_pending_vblank_event;
 struct logicvc_drm;
 
diff --git a/drivers/gpu/drm/logicvc/logicvc_interface.c b/drivers/gpu/drm/logicvc/logicvc_interface.c
index 689049d395c0..a4f01bd3aec3 100644
--- a/drivers/gpu/drm/logicvc/logicvc_interface.c
+++ b/drivers/gpu/drm/logicvc/logicvc_interface.c
@@ -7,6 +7,7 @@
 #include <linux/types.h>
 
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_bridge.h>
 #include <drm/drm_connector.h>
 #include <drm/drm_drv.h>
diff --git a/drivers/gpu/drm/logicvc/logicvc_layer.c b/drivers/gpu/drm/logicvc/logicvc_layer.c
index 464000aea765..8f6b292b8bf7 100644
--- a/drivers/gpu/drm/logicvc/logicvc_layer.c
+++ b/drivers/gpu/drm/logicvc/logicvc_layer.c
@@ -9,10 +9,12 @@
 
 #include <drm/drm_atomic.h>
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_blend.h>
 #include <drm/drm_fb_dma_helper.h>
 #include <drm/drm_fourcc.h>
 #include <drm/drm_framebuffer.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_plane.h>
 #include <drm/drm_print.h>
 

-- 
2.34.1

