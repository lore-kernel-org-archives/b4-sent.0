From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:08:32 +0100
Subject: [PATCH 54/86] drm/kmb: Direct include headers from
 drm_atomic_helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-54-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331667; l=1798;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=eSsyOKZ6+p7JiXIU8GHkQMxYDhY+FTh/eVSeR8TwAEY=;
 b=SXdQTupU3WJjBqoEq9OJXAtWDIJDTrrqBxYZfDTdEgFLGUJJ8+2Jw/dvact7MIp+5w7BsQOQPzk5
 41tP7EVvCoObj3ZgBF6CFZkLcfSoUjkOykrCLkw5COAUBZJ0i6av
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_atomic_helper, because drm_atomic_helper will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/kmb/kmb_crtc.c  | 1 +
 drivers/gpu/drm/kmb/kmb_drv.h   | 1 +
 drivers/gpu/drm/kmb/kmb_plane.c | 2 ++
 3 files changed, 4 insertions(+)

diff --git a/drivers/gpu/drm/kmb/kmb_crtc.c b/drivers/gpu/drm/kmb/kmb_crtc.c
index 647872f65bff..b1b51b923928 100644
--- a/drivers/gpu/drm/kmb/kmb_crtc.c
+++ b/drivers/gpu/drm/kmb/kmb_crtc.c
@@ -7,6 +7,7 @@
 
 #include <drm/drm_atomic.h>
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_crtc.h>
 #include <drm/drm_print.h>
 #include <drm/drm_vblank.h>
diff --git a/drivers/gpu/drm/kmb/kmb_drv.h b/drivers/gpu/drm/kmb/kmb_drv.h
index bf085e95b28f..846164236f9c 100644
--- a/drivers/gpu/drm/kmb/kmb_drv.h
+++ b/drivers/gpu/drm/kmb/kmb_drv.h
@@ -7,6 +7,7 @@
 #define __KMB_DRV_H__
 
 #include <drm/drm_device.h>
+#include <drm/drm_crtc.h>
 
 #include "kmb_plane.h"
 #include "kmb_regs.h"
diff --git a/drivers/gpu/drm/kmb/kmb_plane.c b/drivers/gpu/drm/kmb/kmb_plane.c
index 9e0562aa2bcb..362b8b1ea54a 100644
--- a/drivers/gpu/drm/kmb/kmb_plane.c
+++ b/drivers/gpu/drm/kmb/kmb_plane.c
@@ -5,6 +5,7 @@
 
 #include <drm/drm_atomic.h>
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_blend.h>
 #include <drm/drm_crtc.h>
 #include <drm/drm_fb_dma_helper.h>
@@ -12,6 +13,7 @@
 #include <drm/drm_framebuffer.h>
 #include <drm/drm_gem_dma_helper.h>
 #include <drm/drm_managed.h>
+#include <drm/drm_modeset_helper_vtables.h>
 
 #include "kmb_drv.h"
 #include "kmb_plane.h"

-- 
2.34.1

