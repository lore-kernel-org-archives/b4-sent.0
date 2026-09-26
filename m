From: Jim Cromie <jim.cromie@gmail.com>
Date: Sat, 26 Sep 2026 16:33:32 -0600
Subject: [PATCH 1/2] drm/print: Mark __drm_debug as __read_mostly
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260926-rd-mostly-v1-1-28b7d714ed2c@gmail.com>
References: <20260926-rd-mostly-v1-0-28b7d714ed2c@gmail.com>
In-Reply-To: <20260926-rd-mostly-v1-0-28b7d714ed2c@gmail.com>
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790462033; l=1186;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=NHYPZMcwo+bZTlMUWxR3C+eUOnJQOrGzS6sFjK6QR7o=;
 b=SCaWekTeF5fI3x8YyVSdoR1Ax7xSj1vUuUes5O/Lc6T011ZE8poxxwKWNHG6UFxmCcbVFIVLu
 XmfS+0EWTuNCmaFvvUO6vSgKQVVUBQmiYxmh1hytdPG4sKn4VpuvFIR
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Under a multi-client workload of 12 concurrent vkcubes on AMD iGPU,
__drm_debug is read at ~83.3 kHz across multiple cores during atomic
and vblank checks.

__drm_debug is written only when userspace does:
  echo 0xff > /sys/module/drm/parameters/debug

Currently the linker packs __drm_debug into .bss adjacent to hot
structures: drm_lease_idr_object, drm_class, and drm_global_mutex,
causing unnecessary cacheline invalidations.

Mark __drm_debug as __read_mostly to relocate it to .data..read_mostly.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 drivers/gpu/drm/drm_print.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/drm_print.c b/drivers/gpu/drm/drm_print.c
index 86cef1a37678..50cdeb1b15e2 100644
--- a/drivers/gpu/drm/drm_print.c
+++ b/drivers/gpu/drm/drm_print.c
@@ -40,7 +40,7 @@
  * __drm_debug: Enable debug output.
  * Bitmask of DRM_UT_x. See include/drm/drm_print.h for details.
  */
-unsigned long __drm_debug;
+unsigned long __drm_debug __read_mostly;
 EXPORT_SYMBOL(__drm_debug);
 
 MODULE_PARM_DESC(debug, "Enable debug output, where each bit enables a debug category.\n"

-- 
2.55.0

