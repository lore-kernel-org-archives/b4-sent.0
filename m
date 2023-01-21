From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:08:51 +0100
Subject: [PATCH 73/86] drm/tests: Direct include headers from
 drm_atomic_helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-73-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331667; l=787;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=/EPWbRXhHWpJFzHaQ9iJw9SB3A3ydh89ywhjZ+0vneY=;
 b=oOMIdIeLeLVcupkDri7fjd6ZtmjIy4rsNbYU/qDDiUP5+2NiAGHGVDuf2XZNRUgz0QBU/LjT8SwZ
 IrwGYTGlALLv9NezZzRCUSQ7CT7LDjoVFO/jIyRD4B3szf8qC8jS
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_atomic_helper, because drm_atomic_helper will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/tests/drm_plane_helper_test.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/tests/drm_plane_helper_test.c b/drivers/gpu/drm/tests/drm_plane_helper_test.c
index 0f392146b233..745e35db65db 100644
--- a/drivers/gpu/drm/tests/drm_plane_helper_test.c
+++ b/drivers/gpu/drm/tests/drm_plane_helper_test.c
@@ -8,6 +8,7 @@
 #include <kunit/test.h>
 
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_crtc.h>
 #include <drm/drm_framebuffer.h>
 #include <drm/drm_modes.h>
 #include <drm/drm_rect.h>

-- 
2.34.1

