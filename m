From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:07:52 +0100
Subject: [PATCH 14/86] drm/vmwgfx: Direct include headers from drm_print
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-14-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331666; l=647;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=pGCJGMKCcfPSru5HtDt+nJLZrXi94OWp4HZserY8tVQ=;
 b=p+N36zNWdzWMVB8n6oWFi0wXZBbfhQN/hlY1WEzd3S4Mzq7cQPN2y/C6GTdvZXLmKUozG2Ai4rLu
 LcFS9bc0AP2/P+l4dYOIlwC98qPWWVx0B0Vjb/ac1faXIjts7ySL
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_print.h, because drm_print.h will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/vmwgfx/vmwgfx_gem.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpu/drm/vmwgfx/vmwgfx_gem.c b/drivers/gpu/drm/vmwgfx/vmwgfx_gem.c
index ce609e7d758f..04b2dec75813 100644
--- a/drivers/gpu/drm/vmwgfx/vmwgfx_gem.c
+++ b/drivers/gpu/drm/vmwgfx/vmwgfx_gem.c
@@ -24,6 +24,8 @@
  *
  */
 
+#include <linux/debugfs.h>
+
 #include "vmwgfx_drv.h"
 
 #include "drm/drm_prime.h"

-- 
2.34.1

