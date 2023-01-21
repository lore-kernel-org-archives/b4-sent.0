From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:08:31 +0100
Subject: [PATCH 53/86] drm/ingenic: Direct include headers from
 drm_atomic_helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-53-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331667; l=1897;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=97HfJu+K3xhFOMhZ+cqgRrd6AKIdACMJR2PehLw1cEo=;
 b=UJZ1pMiERIe0vJ+hGswJxMpCEw+jyYzWJCQAXISx5KuIPv5hXDIFtZBwhtOrvKFdS/EfXhH2OyZs
 gJS731XLDF2xzXtLDgk2drmEmVVhmZKN1IL+h+N6uW2olSX/pOxY
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_atomic_helper, because drm_atomic_helper will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/ingenic/ingenic-drm-drv.c | 3 +++
 drivers/gpu/drm/ingenic/ingenic-ipu.c     | 2 ++
 2 files changed, 5 insertions(+)

diff --git a/drivers/gpu/drm/ingenic/ingenic-drm-drv.c b/drivers/gpu/drm/ingenic/ingenic-drm-drv.c
index 5ec75e9ba499..7eebb8bff515 100644
--- a/drivers/gpu/drm/ingenic/ingenic-drm-drv.c
+++ b/drivers/gpu/drm/ingenic/ingenic-drm-drv.c
@@ -22,6 +22,7 @@
 
 #include <drm/drm_atomic.h>
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_bridge.h>
 #include <drm/drm_bridge_connector.h>
 #include <drm/drm_color_mgmt.h>
@@ -37,6 +38,8 @@
 #include <drm/drm_gem_atomic_helper.h>
 #include <drm/drm_gem_framebuffer_helper.h>
 #include <drm/drm_managed.h>
+#include <drm/drm_modeset_helper.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_of.h>
 #include <drm/drm_panel.h>
 #include <drm/drm_plane.h>
diff --git a/drivers/gpu/drm/ingenic/ingenic-ipu.c b/drivers/gpu/drm/ingenic/ingenic-ipu.c
index 7a43505011a5..a8875cbae32a 100644
--- a/drivers/gpu/drm/ingenic/ingenic-ipu.c
+++ b/drivers/gpu/drm/ingenic/ingenic-ipu.c
@@ -20,6 +20,7 @@
 
 #include <drm/drm_atomic.h>
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_damage_helper.h>
 #include <drm/drm_drv.h>
 #include <drm/drm_fb_dma_helper.h>
@@ -28,6 +29,7 @@
 #include <drm/drm_gem_atomic_helper.h>
 #include <drm/drm_gem_dma_helper.h>
 #include <drm/drm_gem_framebuffer_helper.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_plane.h>
 #include <drm/drm_property.h>
 #include <drm/drm_vblank.h>

-- 
2.34.1

