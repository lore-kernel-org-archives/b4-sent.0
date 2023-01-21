From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:07:40 +0100
Subject: [PATCH 02/86] drm/bridge: ite-it6505: Direct include headers from
 drm_print
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-2-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331666; l=955;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=PXjFrIkPGFbhb6CLPdMJXmdce9NEOxxLArs7WJsY1U8=;
 b=pWDFvd4ku/jt9cUHFDNzIXfpBhAjRBHlKBzcLGf2ta31BsMn3JqQglFuThVsaM9sjGQxa3gtnQmL
 K8xz4zaxAw09hRcjFx+sDL2Rpi9mbaxFvghrzSeCXA5gSXvH5nZg
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_print.h, because drm_print.h will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/bridge/ite-it6505.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpu/drm/bridge/ite-it6505.c b/drivers/gpu/drm/bridge/ite-it6505.c
index bc451b2a77c2..ef42cd840958 100644
--- a/drivers/gpu/drm/bridge/ite-it6505.c
+++ b/drivers/gpu/drm/bridge/ite-it6505.c
@@ -3,6 +3,7 @@
  * Copyright (c) 2020, The Linux Foundation. All rights reserved.
  */
 #include <linux/bits.h>
+#include <linux/debugfs.h>
 #include <linux/delay.h>
 #include <linux/device.h>
 #include <linux/err.h>
@@ -16,6 +17,7 @@
 #include <linux/pm_runtime.h>
 #include <linux/regmap.h>
 #include <linux/regulator/consumer.h>
+#include <linux/seq_file.h>
 #include <linux/types.h>
 #include <linux/wait.h>
 

-- 
2.34.1

