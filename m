From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:07:50 +0100
Subject: [PATCH 12/86] drm/vc4: Direct include headers from drm_print
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-12-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331666; l=666;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=94GJRmVWzEzsZZMITso9w0Uzc/x2L+xwXvzK7NPyL1w=;
 b=exCtbi9KUCPlTeQoCl+on4kdUPWiU4Xt27B8mvSaTIoa66FXlgWpDHKOqB9xtS2zZMD4/gGjwZmV
 TS+0voshBH+auuvRDrZkADxngaKMu5bDf4x1HhU2gjH/M6DI5z9z
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_print.h, because drm_print.h will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/vc4/vc4_drv.h | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/vc4/vc4_drv.h b/drivers/gpu/drm/vc4/vc4_drv.h
index 95069bb16821..be2b3309c599 100644
--- a/drivers/gpu/drm/vc4/vc4_drv.h
+++ b/drivers/gpu/drm/vc4/vc4_drv.h
@@ -5,6 +5,7 @@
 #ifndef _VC4_DRV_H_
 #define _VC4_DRV_H_
 
+#include <linux/debugfs.h>
 #include <linux/delay.h>
 #include <linux/of.h>
 #include <linux/refcount.h>

-- 
2.34.1

