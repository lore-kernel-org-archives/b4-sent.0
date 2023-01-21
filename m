From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:07:46 +0100
Subject: [PATCH 08/86] drm/ttm: Direct include headers from drm_print
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20230113-drm-include-v1-v1-8-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331666; l=1504;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=1jktr7iYIyNcVL7l5ZPEDaMaLjdQFrRNwL0NHAdecII=;
 b=dsymNVucUgHo1idChGpUZeabhKWPK14WfN1Cjy28GojyLN/nh2cgvgGjW0sp2LqHvm0zTv5anIDd
 S+c2T6CSAccaH5Dkwh/LME4jmSWs8CtS54HD8tg3kpmqMPHl6BFT
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_print.h, because drm_print.h will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/ttm/ttm_device.c   | 1 +
 drivers/gpu/drm/ttm/ttm_resource.c | 1 +
 drivers/gpu/drm/ttm/ttm_tt.c       | 1 +
 3 files changed, 3 insertions(+)

diff --git a/drivers/gpu/drm/ttm/ttm_device.c b/drivers/gpu/drm/ttm/ttm_device.c
index c7a1862f322a..d2d838bb3d12 100644
--- a/drivers/gpu/drm/ttm/ttm_device.c
+++ b/drivers/gpu/drm/ttm/ttm_device.c
@@ -27,6 +27,7 @@
 
 #define pr_fmt(fmt) "[TTM DEVICE] " fmt
 
+#include <linux/debugfs.h>
 #include <linux/mm.h>
 
 #include <drm/ttm/ttm_bo.h>
diff --git a/drivers/gpu/drm/ttm/ttm_resource.c b/drivers/gpu/drm/ttm/ttm_resource.c
index b8a826a24fb2..40b452021649 100644
--- a/drivers/gpu/drm/ttm/ttm_resource.c
+++ b/drivers/gpu/drm/ttm/ttm_resource.c
@@ -22,6 +22,7 @@
  * Authors: Christian König
  */
 
+#include <linux/debugfs.h>
 #include <linux/iosys-map.h>
 #include <linux/io-mapping.h>
 #include <linux/scatterlist.h>
diff --git a/drivers/gpu/drm/ttm/ttm_tt.c b/drivers/gpu/drm/ttm/ttm_tt.c
index ab725d9d14a6..df905445afd6 100644
--- a/drivers/gpu/drm/ttm/ttm_tt.c
+++ b/drivers/gpu/drm/ttm/ttm_tt.c
@@ -31,6 +31,7 @@
 
 #define pr_fmt(fmt) "[TTM] " fmt
 
+#include <linux/debugfs.h>
 #include <linux/sched.h>
 #include <linux/shmem_fs.h>
 #include <linux/file.h>

-- 
2.34.1

