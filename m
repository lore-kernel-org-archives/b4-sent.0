From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:09:01 +0100
Subject: [PATCH 83/86] drm/xen: Direct include headers from
 drm_atomic_helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-83-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331667; l=841;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=SxDO6n2x0DH9C8qV7B220M04D/fc/HUQDkSZfSqJrBQ=;
 b=spPHf7HoOrT/29Kx8qX4cW2e2QL5oW1Qny+FeA0wJaYa5IJC23Uod+rPFrtGdGgC1lKBCRABXZAV
 lfw0QTMlDKXpa5gFXvAACHGyfa7zTe4XeQs9O6vTNttPazhvH+RB
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_atomic_helper, because drm_atomic_helper will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/xen/xen_drm_front_conn.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpu/drm/xen/xen_drm_front_conn.c b/drivers/gpu/drm/xen/xen_drm_front_conn.c
index a1ba6d3d0568..04fa1cdf7205 100644
--- a/drivers/gpu/drm/xen/xen_drm_front_conn.c
+++ b/drivers/gpu/drm/xen/xen_drm_front_conn.c
@@ -9,8 +9,10 @@
  */
 
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_drv.h>
 #include <drm/drm_fourcc.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_probe_helper.h>
 
 #include <video/videomode.h>

-- 
2.34.1

