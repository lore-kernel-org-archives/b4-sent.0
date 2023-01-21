From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:08:15 +0100
Subject: [PATCH 37/86] drm/bridge: panel: Direct include headers from
 drm_atomic_helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-37-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331667; l=732;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=YwNw0L75DwZlB9qXJ3fFWDB9pVTmtS3UB0gjGTSftOQ=;
 b=vkyTyeSN2nuQagMfUv4DbHfC96aBiiiq0AxccX3uj7Vmc/UQFvbviN6S/Vip1IiNeTI/AOtUHRHR
 N4qvxjlzDOyKumG0a6BwhpgrLgmX5pHp7U4T7GkJwF+6oQ+Qyatv
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_atomic_helper, because drm_atomic_helper will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/bridge/panel.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/bridge/panel.c b/drivers/gpu/drm/bridge/panel.c
index 97c305978f9b..91e6d4bc03b1 100644
--- a/drivers/gpu/drm/bridge/panel.c
+++ b/drivers/gpu/drm/bridge/panel.c
@@ -7,6 +7,7 @@
 #include <linux/debugfs.h>
 
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_bridge.h>
 #include <drm/drm_connector.h>
 #include <drm/drm_encoder.h>

-- 
2.34.1

