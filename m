From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:08:01 +0100
Subject: [PATCH 23/86] drm/aspeed: Direct include headers from
 drm_atomic_helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-23-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331667; l=865;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=a+3WhUtgMc7BAn6KdK5DaKOVgPGJTfDgyO3TSdOCTD8=;
 b=nhf0eD80OCGqF1VZBJz2ap9lIXNeFSuI0vJZ+p9DFS4h4you3PeF2AzAzH7bkQnKDE8TyHqazUPU
 rydTHcsPD+mskgrI1QDSjtDLFd5amLIE8vEYhdWBbBv2taBfN717
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_atomic_helper, because drm_atomic_helper will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/aspeed/aspeed_gfx_out.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpu/drm/aspeed/aspeed_gfx_out.c b/drivers/gpu/drm/aspeed/aspeed_gfx_out.c
index 78775e0c853f..70163348377a 100644
--- a/drivers/gpu/drm/aspeed/aspeed_gfx_out.c
+++ b/drivers/gpu/drm/aspeed/aspeed_gfx_out.c
@@ -2,8 +2,10 @@
 // Copyright 2018 IBM Corporation
 
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_connector.h>
 #include <drm/drm_edid.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_probe_helper.h>
 
 #include "aspeed_gfx.h"

-- 
2.34.1

