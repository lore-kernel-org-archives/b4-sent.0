From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:09:03 +0100
Subject: [PATCH 85/86] drm: move drm_timeout_abs_to_jiffies to drm_util
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-85-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Daniel Vetter <daniel@ffwll.ch>, Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331667; l=6458;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=Ft05c74akxNTHJxFQ9ehVrx+kpAGDuMtbGIH0qCBRik=;
 b=5lIsnO59eVs9anYN76R3tzqRirk8Y/R6fYgCJO6p6Wer7B4FLa3QVU92saGgIw1IeWb4EgWHjGvG
 6U0UQ2ZCCL4g9Fdrb3B6a/p2N3K5TgksUtzUwfLgXWlsNHkkzozs
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

drm_timeout_abs_to_jiffies() was implmented in drm_syncobj where
it really did not belong. Create a drm_util file and move the
implementation. Likewise move the prototype and update all users.

Suggested-by: Daniel Vetter <daniel@ffwll.ch>
[https://lore.kernel.org/dri-devel/20190527185311.GS21222@phenom.ffwll.local/]
Cc: Daniel Vetter <daniel@ffwll.ch>
Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/accel/ivpu/ivpu_gem.c           |  2 +-
 drivers/gpu/drm/Makefile                |  1 +
 drivers/gpu/drm/drm_syncobj.c           | 34 ----------------------------
 drivers/gpu/drm/drm_util.c              | 40 +++++++++++++++++++++++++++++++++
 drivers/gpu/drm/lima/lima_gem.c         |  2 +-
 drivers/gpu/drm/panfrost/panfrost_drv.c |  2 +-
 drivers/gpu/drm/tegra/uapi.c            |  2 +-
 include/drm/drm_util.h                  |  1 +
 include/drm/drm_utils.h                 |  2 --
 9 files changed, 46 insertions(+), 40 deletions(-)

diff --git a/drivers/accel/ivpu/ivpu_gem.c b/drivers/accel/ivpu/ivpu_gem.c
index d1f923971b4c..55aa94ba6c10 100644
--- a/drivers/accel/ivpu/ivpu_gem.c
+++ b/drivers/accel/ivpu/ivpu_gem.c
@@ -12,7 +12,7 @@
 #include <drm/drm_cache.h>
 #include <drm/drm_debugfs.h>
 #include <drm/drm_file.h>
-#include <drm/drm_utils.h>
+#include <drm/drm_util.h>
 
 #include "ivpu_drv.h"
 #include "ivpu_gem.h"
diff --git a/drivers/gpu/drm/Makefile b/drivers/gpu/drm/Makefile
index ab4460fcd63f..561b93d19685 100644
--- a/drivers/gpu/drm/Makefile
+++ b/drivers/gpu/drm/Makefile
@@ -42,6 +42,7 @@ drm-y := \
 	drm_syncobj.o \
 	drm_sysfs.o \
 	drm_trace_points.o \
+	drm_util.o \
 	drm_vblank.o \
 	drm_vblank_work.o \
 	drm_vma_manager.o \
diff --git a/drivers/gpu/drm/drm_syncobj.c b/drivers/gpu/drm/drm_syncobj.c
index 0c2be8360525..35f5416c5cfe 100644
--- a/drivers/gpu/drm/drm_syncobj.c
+++ b/drivers/gpu/drm/drm_syncobj.c
@@ -197,7 +197,6 @@
 #include <drm/drm_gem.h>
 #include <drm/drm_print.h>
 #include <drm/drm_syncobj.h>
-#include <drm/drm_utils.h>
 
 #include "drm_internal.h"
 
@@ -1114,39 +1113,6 @@ static signed long drm_syncobj_array_wait_timeout(struct drm_syncobj **syncobjs,
 	return timeout;
 }
 
-/**
- * drm_timeout_abs_to_jiffies - calculate jiffies timeout from absolute value
- *
- * @timeout_nsec: timeout nsec component in ns, 0 for poll
- *
- * Calculate the timeout in jiffies from an absolute time in sec/nsec.
- */
-signed long drm_timeout_abs_to_jiffies(int64_t timeout_nsec)
-{
-	ktime_t abs_timeout, now;
-	u64 timeout_ns, timeout_jiffies64;
-
-	/* make 0 timeout means poll - absolute 0 doesn't seem valid */
-	if (timeout_nsec == 0)
-		return 0;
-
-	abs_timeout = ns_to_ktime(timeout_nsec);
-	now = ktime_get();
-
-	if (!ktime_after(abs_timeout, now))
-		return 0;
-
-	timeout_ns = ktime_to_ns(ktime_sub(abs_timeout, now));
-
-	timeout_jiffies64 = nsecs_to_jiffies64(timeout_ns);
-	/*  clamp timeout to avoid infinite timeout */
-	if (timeout_jiffies64 >= MAX_SCHEDULE_TIMEOUT - 1)
-		return MAX_SCHEDULE_TIMEOUT - 1;
-
-	return timeout_jiffies64 + 1;
-}
-EXPORT_SYMBOL(drm_timeout_abs_to_jiffies);
-
 static int drm_syncobj_array_wait(struct drm_device *dev,
 				  struct drm_file *file_private,
 				  struct drm_syncobj_wait *wait,
diff --git a/drivers/gpu/drm/drm_util.c b/drivers/gpu/drm/drm_util.c
new file mode 100644
index 000000000000..5494fa6b8193
--- /dev/null
+++ b/drivers/gpu/drm/drm_util.c
@@ -0,0 +1,40 @@
+// SPDX-License-Identifier: MIT
+
+#include <linux/export.h>
+#include <linux/ktime.h>
+#include <linux/timekeeping.h>
+
+#include <drm/drm_util.h>
+
+/**
+ * drm_timeout_abs_to_jiffies - calculate jiffies timeout from absolute value
+ *
+ * @timeout_nsec: timeout nsec component in ns, 0 for poll
+ *
+ * Calculate the timeout in jiffies from an absolute time in sec/nsec.
+ */
+signed long drm_timeout_abs_to_jiffies(int64_t timeout_nsec)
+{
+	ktime_t abs_timeout, now;
+	u64 timeout_ns, timeout_jiffies64;
+
+	/* make 0 timeout means poll - absolute 0 doesn't seem valid */
+	if (timeout_nsec == 0)
+		return 0;
+
+	abs_timeout = ns_to_ktime(timeout_nsec);
+	now = ktime_get();
+
+	if (!ktime_after(abs_timeout, now))
+		return 0;
+
+	timeout_ns = ktime_to_ns(ktime_sub(abs_timeout, now));
+
+	timeout_jiffies64 = nsecs_to_jiffies64(timeout_ns);
+	/*  clamp timeout to avoid infinite timeout */
+	if (timeout_jiffies64 >= MAX_SCHEDULE_TIMEOUT - 1)
+		return MAX_SCHEDULE_TIMEOUT - 1;
+
+	return timeout_jiffies64 + 1;
+}
+EXPORT_SYMBOL(drm_timeout_abs_to_jiffies);
diff --git a/drivers/gpu/drm/lima/lima_gem.c b/drivers/gpu/drm/lima/lima_gem.c
index 0f1ca0b0db49..5cdd06682afe 100644
--- a/drivers/gpu/drm/lima/lima_gem.c
+++ b/drivers/gpu/drm/lima/lima_gem.c
@@ -10,7 +10,7 @@
 
 #include <drm/drm_file.h>
 #include <drm/drm_syncobj.h>
-#include <drm/drm_utils.h>
+#include <drm/drm_util.h>
 
 #include <drm/lima_drm.h>
 
diff --git a/drivers/gpu/drm/panfrost/panfrost_drv.c b/drivers/gpu/drm/panfrost/panfrost_drv.c
index fa619fe72086..581df5b724e2 100644
--- a/drivers/gpu/drm/panfrost/panfrost_drv.c
+++ b/drivers/gpu/drm/panfrost/panfrost_drv.c
@@ -11,7 +11,7 @@
 #include <drm/drm_drv.h>
 #include <drm/drm_ioctl.h>
 #include <drm/drm_syncobj.h>
-#include <drm/drm_utils.h>
+#include <drm/drm_util.h>
 
 #include "panfrost_device.h"
 #include "panfrost_gem.h"
diff --git a/drivers/gpu/drm/tegra/uapi.c b/drivers/gpu/drm/tegra/uapi.c
index 5adab6b22916..6d5601517a34 100644
--- a/drivers/gpu/drm/tegra/uapi.c
+++ b/drivers/gpu/drm/tegra/uapi.c
@@ -7,7 +7,7 @@
 
 #include <drm/drm_drv.h>
 #include <drm/drm_file.h>
-#include <drm/drm_utils.h>
+#include <drm/drm_util.h>
 
 #include "drm.h"
 #include "uapi.h"
diff --git a/include/drm/drm_util.h b/include/drm/drm_util.h
index 79952d8c4bba..3d719190cfd9 100644
--- a/include/drm/drm_util.h
+++ b/include/drm/drm_util.h
@@ -80,4 +80,5 @@ static inline bool drm_can_sleep(void)
 	return true;
 }
 
+signed long drm_timeout_abs_to_jiffies(int64_t timeout_nsec);
 #endif
diff --git a/include/drm/drm_utils.h b/include/drm/drm_utils.h
index 70775748d243..bae225f0a24b 100644
--- a/include/drm/drm_utils.h
+++ b/include/drm/drm_utils.h
@@ -14,6 +14,4 @@
 
 int drm_get_panel_orientation_quirk(int width, int height);
 
-signed long drm_timeout_abs_to_jiffies(int64_t timeout_nsec);
-
 #endif

-- 
2.34.1

