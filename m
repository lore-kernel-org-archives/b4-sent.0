From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:07:43 +0100
Subject: [PATCH 05/86] drm/nouveau: Direct include headers from drm_print
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-5-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331666; l=745;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=31Zd4WVX9Z0b32QhSleAn0woF7FYd6Wz4CKp3dvWOks=;
 b=spaFCWHPQgep4YZxQ4PMz8WVYafBq5ViM+m9larnG5Irl2TPk1cFo3ezTBZGHQswKHXFY6PqgS44
 SRUfIU00DMxs3JrCb7ILaaA6UDaoxi/l6KMU0BOFYi9eUAO3DkcA
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_print.h, because drm_print.h will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/nouveau/dispnv50/crc.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpu/drm/nouveau/dispnv50/crc.c b/drivers/gpu/drm/nouveau/dispnv50/crc.c
index 9c942fbd836d..5936b6b3b15d 100644
--- a/drivers/gpu/drm/nouveau/dispnv50/crc.c
+++ b/drivers/gpu/drm/nouveau/dispnv50/crc.c
@@ -1,5 +1,7 @@
 // SPDX-License-Identifier: MIT
+#include <linux/debugfs.h>
 #include <linux/string.h>
+
 #include <drm/drm_crtc.h>
 #include <drm/drm_atomic_helper.h>
 #include <drm/drm_vblank.h>

-- 
2.34.1

