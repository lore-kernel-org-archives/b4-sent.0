From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:07:42 +0100
Subject: [PATCH 04/86] drm/msm: Direct include headers from drm_print
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-4-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331666; l=774;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=i9y9pDCm2mA3/O720jg1Kgq6M5EgH/ydU59nA2VdrCc=;
 b=RX5TrvOVQZh62FgTpTrQP6B1J+/5naEnEvmJSJ1cXht34nwGG3+d4CbgLMRDdW4T2g0SQAzCuBVF
 WwrS8h/pB0pSmhIrLC7OpjtFTXws8R77+QRj0wHC9y0GUIYAVyrR
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_print.h, because drm_print.h will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/msm/disp/dpu1/dpu_hw_sspp.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpu/drm/msm/disp/dpu1/dpu_hw_sspp.c b/drivers/gpu/drm/msm/disp/dpu1/dpu_hw_sspp.c
index 691c471b08c2..53e0933ccfcb 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/dpu_hw_sspp.c
+++ b/drivers/gpu/drm/msm/disp/dpu1/dpu_hw_sspp.c
@@ -2,6 +2,8 @@
 /* Copyright (c) 2015-2018, The Linux Foundation. All rights reserved.
  */
 
+#include <linux/debugfs.h>
+
 #include "dpu_hwio.h"
 #include "dpu_hw_catalog.h"
 #include "dpu_hw_lm.h"

-- 
2.34.1

