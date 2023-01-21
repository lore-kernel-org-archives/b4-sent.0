From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:09:02 +0100
Subject: [PATCH 84/86] drm/drm_atomic_helper: Minimize include footprint
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-84-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331667; l=1468;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=zJMm7dzYnLnxIUkQaPpznHgQB5PDGjDdaSZxy+nXRsY=;
 b=pJuWc0PUjXTzJAkxcoDrQYfkxTc1R/gaoZEWroVm8LPkVPp5qgtduXd9xBwNZIFnmyx3L2tUWcnj
 eCRR3yFPB+/Y1TTJARVT4B3dGjE14p3wmM4TomCG5hCWXQ/o/PlU
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Reduce drm_atomic_helper.h to include or forward the minimal set of
files/symbols - to minimize the impact of the files that includes this
header file.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 include/drm/drm_atomic_helper.h | 21 ++++++++++++++-------
 1 file changed, 14 insertions(+), 7 deletions(-)

diff --git a/include/drm/drm_atomic_helper.h b/include/drm/drm_atomic_helper.h
index 33f982cd1a27..c7f2bc46bd24 100644
--- a/include/drm/drm_atomic_helper.h
+++ b/include/drm/drm_atomic_helper.h
@@ -28,11 +28,9 @@
 #ifndef DRM_ATOMIC_HELPER_H_
 #define DRM_ATOMIC_HELPER_H_
 
-#include <drm/drm_crtc.h>
-#include <drm/drm_modeset_helper_vtables.h>
-#include <drm/drm_modeset_helper.h>
-#include <drm/drm_atomic_state_helper.h>
-#include <drm/drm_util.h>
+#include <linux/types.h>
+
+#include <drm/drm_plane.h>
 
 /*
  * Drivers that don't allow primary plane scaling may pass this macro in place
@@ -44,8 +42,17 @@
 #define DRM_PLANE_NO_SCALING (1<<16)
 
 struct drm_atomic_state;
-struct drm_private_obj;
-struct drm_private_state;
+struct drm_bridge;
+struct drm_bridge_state;
+struct drm_connector_state;
+struct drm_crtc_state;
+struct drm_device;
+struct drm_encoder;
+struct drm_framebuffer;
+struct drm_mode_set;
+struct drm_modeset_acquire_ctx;
+struct drm_pending_vblank_event;
+
 
 int drm_atomic_helper_check_modeset(struct drm_device *dev,
 				struct drm_atomic_state *state);

-- 
2.34.1

