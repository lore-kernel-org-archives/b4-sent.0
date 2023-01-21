From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:07:44 +0100
Subject: [PATCH 06/86] drm/omapdrm: Direct include headers from drm_print
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-6-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331666; l=671;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=Ms4ktIBBzv59Kacn7jiYvIEUkBfNMtzbqvKZMC/lgLY=;
 b=pJYm01pAIVFSxKwEGKme1EU6068GLZnzfwKkUIM4nOUXX4bWPzrU/n2oNbQ5ozi+EkL1YGTUaQJF
 t/PxkdOsD4wQaprdL10z1f4l60Zi+pM4ClJJI01n7VjRkCZdmg6X
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_print.h, because drm_print.h will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/omapdrm/omap_fb.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/omapdrm/omap_fb.c b/drivers/gpu/drm/omapdrm/omap_fb.c
index 1d414b33fee3..449d521c78fe 100644
--- a/drivers/gpu/drm/omapdrm/omap_fb.c
+++ b/drivers/gpu/drm/omapdrm/omap_fb.c
@@ -5,6 +5,7 @@
  */
 
 #include <linux/dma-mapping.h>
+#include <linux/seq_file.h>
 
 #include <drm/drm_blend.h>
 #include <drm/drm_modeset_helper.h>

-- 
2.34.1

