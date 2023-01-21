From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:07:53 +0100
Subject: [PATCH 15/86] drm/i915: Direct include headers from drm_print
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20230113-drm-include-v1-v1-15-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331666; l=1961;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=8UI+rVb3Xa7p9It0Y4FaZV3HuJwLBciCKf8V4++b8CQ=;
 b=zCouiaQ9PgNGLypv+3QCkeyr5sc+f9LRXYHFMZm3KpMC46ZezmNeqI3KVtQiTCRbHPuzbRkwQs3t
 2Sab81l5D+MaZbDnynLlyqjVyZkfPwVnyi3Kj95kD9KOe6QKmLXM
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_print.h, because drm_print.h will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/i915/display/intel_dmc.c   | 1 +
 drivers/gpu/drm/i915/i915_debugfs.c        | 1 +
 drivers/gpu/drm/i915/i915_debugfs_params.c | 1 +
 drivers/gpu/drm/i915/i915_params.c         | 1 +
 4 files changed, 4 insertions(+)

diff --git a/drivers/gpu/drm/i915/display/intel_dmc.c b/drivers/gpu/drm/i915/display/intel_dmc.c
index 4124b3d37110..8e127c22c755 100644
--- a/drivers/gpu/drm/i915/display/intel_dmc.c
+++ b/drivers/gpu/drm/i915/display/intel_dmc.c
@@ -22,6 +22,7 @@
  *
  */
 
+#include <linux/debugfs.h>
 #include <linux/firmware.h>
 
 #include "i915_drv.h"
diff --git a/drivers/gpu/drm/i915/i915_debugfs.c b/drivers/gpu/drm/i915/i915_debugfs.c
index 6c7ac73b69a5..415086050aa6 100644
--- a/drivers/gpu/drm/i915/i915_debugfs.c
+++ b/drivers/gpu/drm/i915/i915_debugfs.c
@@ -26,6 +26,7 @@
  *
  */
 
+#include <linux/debugfs.h>
 #include <linux/sched/mm.h>
 #include <linux/sort.h>
 #include <linux/string_helpers.h>
diff --git a/drivers/gpu/drm/i915/i915_debugfs_params.c b/drivers/gpu/drm/i915/i915_debugfs_params.c
index 783c8676eee2..72eee814f631 100644
--- a/drivers/gpu/drm/i915/i915_debugfs_params.c
+++ b/drivers/gpu/drm/i915/i915_debugfs_params.c
@@ -3,6 +3,7 @@
  * Copyright © 2019 Intel Corporation
  */
 
+#include <linux/debugfs.h>
 #include <linux/kernel.h>
 
 #include "i915_debugfs_params.h"
diff --git a/drivers/gpu/drm/i915/i915_params.c b/drivers/gpu/drm/i915/i915_params.c
index 5b24dd50fb6a..e0aed6fabe2a 100644
--- a/drivers/gpu/drm/i915/i915_params.c
+++ b/drivers/gpu/drm/i915/i915_params.c
@@ -22,6 +22,7 @@
  * IN THE SOFTWARE.
  */
 
+#include <linux/dynamic_debug.h>
 #include <linux/string_helpers.h>
 
 #include <drm/drm_print.h>

-- 
2.34.1

