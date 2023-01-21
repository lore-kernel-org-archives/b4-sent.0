From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:07:49 +0100
Subject: [PATCH 11/86] drm/sti: Direct include headers from drm_print
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-11-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331666; l=667;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=rbapGLXVM96Fah80Nc/fR5r5VwfXre8lyA6BSv6keis=;
 b=vSaINf0WU7vdIqQj8l0tByyCb8yStAQ873BhKGmze9+NzTa/9l7TnBukeeUnqwxhnIQGO5ebQ20I
 E8wlHNDgDcukXqZ58btSmGdWhshHWqBo17j28QispKDredCWZ+N/
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_print.h, because drm_print.h will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/sti/sti_drv.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/sti/sti_drv.c b/drivers/gpu/drm/sti/sti_drv.c
index ef6a4e63198f..b81fc05aee8d 100644
--- a/drivers/gpu/drm/sti/sti_drv.c
+++ b/drivers/gpu/drm/sti/sti_drv.c
@@ -5,6 +5,7 @@
  */
 
 #include <linux/component.h>
+#include <linux/debugfs.h>
 #include <linux/dma-mapping.h>
 #include <linux/kernel.h>
 #include <linux/module.h>

-- 
2.34.1

