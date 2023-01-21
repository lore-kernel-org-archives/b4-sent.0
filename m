From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:09:04 +0100
Subject: [PATCH 86/86] drm: Move drm_get_panel_orientation_quirk prototype
 to drm_panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-86-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Daniel Vetter <daniel@ffwll.ch>, Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331667; l=3297;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=ZsBaKl2SrwvcyrN3qfNa9m8+QTAVcEdj8gRaVh06Jtc=;
 b=OrxWFm2Gz2ZkdkYFuiY7dbEe7/RE+lXrwGbtf/i5gvPa4KtY4sAkozvqvoT4fuRfyFVumgYyKA9j
 sD2YuIp6C8Jbo32bsJ2I8bux5UvhjLEgyhFqTEMIJ3v8GMEtAjyg
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

drm_panel already contain some panel orientation stuff,
So this is a good home for the prototype.

Update all users of drm_get_panel_orientation_quirk.
Remove drm_utils.h header as it is no longer used.

Suggested-by: Daniel Vetter <daniel@ffwll.ch>
[https://lore.kernel.org/dri-devel/20190527185311.GS21222@phenom.ffwll.local/]
Cc: Daniel Vetter <daniel@ffwll.ch>
Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/drm_connector.c                |  1 -
 drivers/gpu/drm/drm_panel_orientation_quirks.c |  2 +-
 drivers/video/fbdev/efifb.c                    |  2 +-
 include/drm/drm_panel.h                        |  1 +
 include/drm/drm_utils.h                        | 17 -----------------
 5 files changed, 3 insertions(+), 20 deletions(-)

diff --git a/drivers/gpu/drm/drm_connector.c b/drivers/gpu/drm/drm_connector.c
index 9d0250c28e9b..b39f4e807685 100644
--- a/drivers/gpu/drm/drm_connector.c
+++ b/drivers/gpu/drm/drm_connector.c
@@ -31,7 +31,6 @@
 #include <drm/drm_print.h>
 #include <drm/drm_privacy_screen_consumer.h>
 #include <drm/drm_sysfs.h>
-#include <drm/drm_utils.h>
 
 #include <linux/fb.h>
 #include <linux/uaccess.h>
diff --git a/drivers/gpu/drm/drm_panel_orientation_quirks.c b/drivers/gpu/drm/drm_panel_orientation_quirks.c
index ca531dbb749d..589adb3e26c6 100644
--- a/drivers/gpu/drm/drm_panel_orientation_quirks.c
+++ b/drivers/gpu/drm/drm_panel_orientation_quirks.c
@@ -11,7 +11,7 @@
 #include <linux/dmi.h>
 #include <linux/module.h>
 #include <drm/drm_connector.h>
-#include <drm/drm_utils.h>
+#include <drm/drm_panel.h>
 
 #ifdef CONFIG_DMI
 
diff --git a/drivers/video/fbdev/efifb.c b/drivers/video/fbdev/efifb.c
index a5779fb453a2..37487b945007 100644
--- a/drivers/video/fbdev/efifb.c
+++ b/drivers/video/fbdev/efifb.c
@@ -20,8 +20,8 @@
 #include <linux/pm_runtime.h>
 #include <video/vga.h>
 #include <asm/efi.h>
-#include <drm/drm_utils.h> /* For drm_get_panel_orientation_quirk */
 #include <drm/drm_connector.h>  /* For DRM_MODE_PANEL_ORIENTATION_* */
+#include <drm/drm_panel.h> /* For drm_get_panel_orientation_quirk */
 
 struct bmp_file_header {
 	u16 id;
diff --git a/include/drm/drm_panel.h b/include/drm/drm_panel.h
index 432fab2347eb..95e509feba75 100644
--- a/include/drm/drm_panel.h
+++ b/include/drm/drm_panel.h
@@ -200,6 +200,7 @@ struct drm_panel {
 	bool prepare_prev_first;
 };
 
+int drm_get_panel_orientation_quirk(int width, int height);
 void drm_panel_init(struct drm_panel *panel, struct device *dev,
 		    const struct drm_panel_funcs *funcs,
 		    int connector_type);
diff --git a/include/drm/drm_utils.h b/include/drm/drm_utils.h
deleted file mode 100644
index bae225f0a24b..000000000000
--- a/include/drm/drm_utils.h
+++ /dev/null
@@ -1,17 +0,0 @@
-/* SPDX-License-Identifier: MIT */
-/*
- * Function prototypes for misc. drm utility functions.
- * Specifically this file is for function prototypes for functions which
- * may also be used outside of drm code (e.g. in fbdev drivers).
- *
- * Copyright (C) 2017 Hans de Goede <hdegoede@redhat.com>
- */
-
-#ifndef __DRM_UTILS_H__
-#define __DRM_UTILS_H__
-
-#include <linux/types.h>
-
-int drm_get_panel_orientation_quirk(int width, int height);
-
-#endif

-- 
2.34.1

