From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:07:54 +0100
Subject: [PATCH 16/86] drm/drm_print: Minimize include footprint
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-16-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331666; l=965;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=p6u7BCu6iGEw/mZH2TZOMAba4klZ9DSvcjzEhAAduqg=;
 b=pxuw98SOeU7wiWuVVpt/bUcMQSvtyP/Z36Kx4YOnshnNRjAgWmUczNJZ0Wz5hMw+43OVkmMCa8Pf
 mtvGaUQ2DeY1ep7GALZuE7LPxGYGvl89Sgj9AMkXVBC8U8blBj1r
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Reduce drm_print.h to include or forward the minimal set of
files/symbols - to minimize the impact of the files that includes this
header file.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 include/drm/drm_print.h | 11 +++++------
 1 file changed, 5 insertions(+), 6 deletions(-)

diff --git a/include/drm/drm_print.h b/include/drm/drm_print.h
index c3753da97c4e..30673ee10190 100644
--- a/include/drm/drm_print.h
+++ b/include/drm/drm_print.h
@@ -26,14 +26,13 @@
 #ifndef DRM_PRINT_H_
 #define DRM_PRINT_H_
 
-#include <linux/compiler.h>
-#include <linux/printk.h>
-#include <linux/seq_file.h>
+#include <linux/dev_printk.h>
 #include <linux/device.h>
-#include <linux/debugfs.h>
-#include <linux/dynamic_debug.h>
+#include <linux/printk.h>
 
-#include <drm/drm.h>
+struct debugfs_regset32;
+struct seq_file;
+struct device;
 
 /* Do *not* use outside of drm_print.[ch]! */
 extern unsigned long __drm_debug;

-- 
2.34.1

