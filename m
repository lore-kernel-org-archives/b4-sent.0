From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:07:47 +0100
Subject: [PATCH 09/86] drm/scheduler: Direct include headers from drm_print
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-9-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331666; l=739;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=/TOkmcXyKyN23yBF4J/kNp3VyZ+tzaXviJl5TstN33U=;
 b=lr5z0+aAmiRsT/04gZHT1+PUPvCByL7ZO2QUoGfUSSGyN0KmE6jFnMzs82ctGBtiPaVMku/eNh2W
 sfzqFO4VBSIJZd1MtiCOWmQBrGX5VPeSAsLsKnqy9h18KP2kD54X
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_print.h, because drm_print.h will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/scheduler/sched_main.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/scheduler/sched_main.c b/drivers/gpu/drm/scheduler/sched_main.c
index 0e4378420271..964ea10bf68e 100644
--- a/drivers/gpu/drm/scheduler/sched_main.c
+++ b/drivers/gpu/drm/scheduler/sched_main.c
@@ -51,6 +51,7 @@
 #include <linux/dma-resv.h>
 #include <uapi/linux/sched/types.h>
 
+#include <drm/drm.h>
 #include <drm/drm_print.h>
 #include <drm/drm_gem.h>
 #include <drm/gpu_scheduler.h>

-- 
2.34.1

