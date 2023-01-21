From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:07:45 +0100
Subject: [PATCH 07/86] drm/radeon: Direct include headers from drm_print
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20230113-drm-include-v1-v1-7-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331666; l=5197;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=TZJXT/0VGcrMwsKEJDS2MRW74hDMDkfJnatYDx6v9JI=;
 b=T8DFGaI2a/zgTamtjdu001ppYRhhGiv1lPkpj5qIROle+az7EeZZRc8SFIFgfaGa2A6tlAqv7m7p
 DfqiWBkLB1ITN/F0TFeE/z7fEb2EOO9k1FWyEEgwB9SmS4TC/zxv
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_print.h, because drm_print.h will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/radeon/r100.c         | 1 +
 drivers/gpu/drm/radeon/r300.c         | 1 +
 drivers/gpu/drm/radeon/r420.c         | 1 +
 drivers/gpu/drm/radeon/r600.c         | 1 +
 drivers/gpu/drm/radeon/radeon_fence.c | 1 +
 drivers/gpu/drm/radeon/radeon_gem.c   | 1 +
 drivers/gpu/drm/radeon/radeon_ib.c    | 2 ++
 drivers/gpu/drm/radeon/radeon_pm.c    | 1 +
 drivers/gpu/drm/radeon/radeon_ring.c  | 2 ++
 drivers/gpu/drm/radeon/radeon_ttm.c   | 1 +
 drivers/gpu/drm/radeon/rs400.c        | 1 +
 drivers/gpu/drm/radeon/rv515.c        | 1 +
 12 files changed, 14 insertions(+)

diff --git a/drivers/gpu/drm/radeon/r100.c b/drivers/gpu/drm/radeon/r100.c
index d4f09ecc3d22..32e0709f4e90 100644
--- a/drivers/gpu/drm/radeon/r100.c
+++ b/drivers/gpu/drm/radeon/r100.c
@@ -26,6 +26,7 @@
  *          Jerome Glisse
  */
 
+#include <linux/debugfs.h>
 #include <linux/firmware.h>
 #include <linux/module.h>
 #include <linux/pci.h>
diff --git a/drivers/gpu/drm/radeon/r300.c b/drivers/gpu/drm/radeon/r300.c
index 7b0cfeaddcec..79127b7053c1 100644
--- a/drivers/gpu/drm/radeon/r300.c
+++ b/drivers/gpu/drm/radeon/r300.c
@@ -26,6 +26,7 @@
  *          Jerome Glisse
  */
 
+#include <linux/debugfs.h>
 #include <linux/pci.h>
 #include <linux/seq_file.h>
 #include <linux/slab.h>
diff --git a/drivers/gpu/drm/radeon/r420.c b/drivers/gpu/drm/radeon/r420.c
index 7e6320e8c6a0..1305e4b372af 100644
--- a/drivers/gpu/drm/radeon/r420.c
+++ b/drivers/gpu/drm/radeon/r420.c
@@ -26,6 +26,7 @@
  *          Jerome Glisse
  */
 
+#include <linux/debugfs.h>
 #include <linux/pci.h>
 #include <linux/seq_file.h>
 #include <linux/slab.h>
diff --git a/drivers/gpu/drm/radeon/r600.c b/drivers/gpu/drm/radeon/r600.c
index dd78fc499402..2dd2d4751168 100644
--- a/drivers/gpu/drm/radeon/r600.c
+++ b/drivers/gpu/drm/radeon/r600.c
@@ -26,6 +26,7 @@
  *          Jerome Glisse
  */
 
+#include <linux/debugfs.h>
 #include <linux/firmware.h>
 #include <linux/module.h>
 #include <linux/pci.h>
diff --git a/drivers/gpu/drm/radeon/radeon_fence.c b/drivers/gpu/drm/radeon/radeon_fence.c
index 73e3117420bf..6faf040197fa 100644
--- a/drivers/gpu/drm/radeon/radeon_fence.c
+++ b/drivers/gpu/drm/radeon/radeon_fence.c
@@ -30,6 +30,7 @@
  */
 
 #include <linux/atomic.h>
+#include <linux/debugfs.h>
 #include <linux/firmware.h>
 #include <linux/kref.h>
 #include <linux/sched/signal.h>
diff --git a/drivers/gpu/drm/radeon/radeon_gem.c b/drivers/gpu/drm/radeon/radeon_gem.c
index 261fcbae88d7..f6753c4bd655 100644
--- a/drivers/gpu/drm/radeon/radeon_gem.c
+++ b/drivers/gpu/drm/radeon/radeon_gem.c
@@ -26,6 +26,7 @@
  *          Jerome Glisse
  */
 
+#include <linux/debugfs.h>
 #include <linux/iosys-map.h>
 #include <linux/pci.h>
 
diff --git a/drivers/gpu/drm/radeon/radeon_ib.c b/drivers/gpu/drm/radeon/radeon_ib.c
index 62b116727b4f..8f080b375fdc 100644
--- a/drivers/gpu/drm/radeon/radeon_ib.c
+++ b/drivers/gpu/drm/radeon/radeon_ib.c
@@ -27,6 +27,8 @@
  *          Christian König
  */
 
+#include <linux/debugfs.h>
+
 #include <drm/drm_file.h>
 
 #include "radeon.h"
diff --git a/drivers/gpu/drm/radeon/radeon_pm.c b/drivers/gpu/drm/radeon/radeon_pm.c
index cbc554928bcc..d966c554d92c 100644
--- a/drivers/gpu/drm/radeon/radeon_pm.c
+++ b/drivers/gpu/drm/radeon/radeon_pm.c
@@ -21,6 +21,7 @@
  *          Alex Deucher <alexdeucher@gmail.com>
  */
 
+#include <linux/debugfs.h>
 #include <linux/hwmon-sysfs.h>
 #include <linux/hwmon.h>
 #include <linux/pci.h>
diff --git a/drivers/gpu/drm/radeon/radeon_ring.c b/drivers/gpu/drm/radeon/radeon_ring.c
index 7e207276df37..ca0a7b97ff66 100644
--- a/drivers/gpu/drm/radeon/radeon_ring.c
+++ b/drivers/gpu/drm/radeon/radeon_ring.c
@@ -27,6 +27,8 @@
  *          Christian König
  */
 
+#include <linux/debugfs.h>
+
 #include <drm/drm_device.h>
 #include <drm/drm_file.h>
 
diff --git a/drivers/gpu/drm/radeon/radeon_ttm.c b/drivers/gpu/drm/radeon/radeon_ttm.c
index 1e8e287e113c..7e26675c690b 100644
--- a/drivers/gpu/drm/radeon/radeon_ttm.c
+++ b/drivers/gpu/drm/radeon/radeon_ttm.c
@@ -30,6 +30,7 @@
  *    Dave Airlie
  */
 
+#include <linux/debugfs.h>
 #include <linux/dma-mapping.h>
 #include <linux/pagemap.h>
 #include <linux/pci.h>
diff --git a/drivers/gpu/drm/radeon/rs400.c b/drivers/gpu/drm/radeon/rs400.c
index 6383f7a34bd8..85d995f7cbef 100644
--- a/drivers/gpu/drm/radeon/rs400.c
+++ b/drivers/gpu/drm/radeon/rs400.c
@@ -26,6 +26,7 @@
  *          Jerome Glisse
  */
 
+#include <linux/debugfs.h>
 #include <linux/seq_file.h>
 #include <linux/slab.h>
 
diff --git a/drivers/gpu/drm/radeon/rv515.c b/drivers/gpu/drm/radeon/rv515.c
index 63fb06e8e2d7..565f1c2b5b68 100644
--- a/drivers/gpu/drm/radeon/rv515.c
+++ b/drivers/gpu/drm/radeon/rv515.c
@@ -26,6 +26,7 @@
  *          Jerome Glisse
  */
 
+#include <linux/debugfs.h>
 #include <linux/seq_file.h>
 #include <linux/slab.h>
 

-- 
2.34.1

