From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:07:39 +0100
Subject: [PATCH 01/86] drm/komeda: Direct include headers from drm_print
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-1-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331666; l=1273;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=/YryTtZUbqmnAxzUz3X6U0yYG0gnWZZ+IgEvDOZWomQ=;
 b=0wM9i60X0sTlOjpJSxM7vpyjlYEbnO5xWmx4eG25Q/qOZPPFLbiYbeftJQwdho1CC3rrwEm5Qn/w
 tv+rxIWMCr8kV82mi8DNYUa/UiI5Tmd2c2wuuj86vRyDjUxBP9H2
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_print.h, because drm_print.h will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/arm/display/komeda/d71/d71_component.c | 2 ++
 drivers/gpu/drm/arm/display/komeda/komeda_pipeline.c   | 1 +
 2 files changed, 3 insertions(+)

diff --git a/drivers/gpu/drm/arm/display/komeda/d71/d71_component.c b/drivers/gpu/drm/arm/display/komeda/d71/d71_component.c
index 42510fdea27e..875731a8ae90 100644
--- a/drivers/gpu/drm/arm/display/komeda/d71/d71_component.c
+++ b/drivers/gpu/drm/arm/display/komeda/d71/d71_component.c
@@ -4,6 +4,8 @@
  * Author: James.Qian.Wang <james.qian.wang@arm.com>
  *
  */
+#include <linux/seq_file.h>
+
 #include "d71_dev.h"
 #include "komeda_kms.h"
 #include "malidp_io.h"
diff --git a/drivers/gpu/drm/arm/display/komeda/komeda_pipeline.c b/drivers/gpu/drm/arm/display/komeda/komeda_pipeline.c
index 4b7d94961527..00f5864a0495 100644
--- a/drivers/gpu/drm/arm/display/komeda/komeda_pipeline.c
+++ b/drivers/gpu/drm/arm/display/komeda/komeda_pipeline.c
@@ -5,6 +5,7 @@
  *
  */
 #include <linux/of.h>
+#include <linux/seq_file.h>
 
 #include <drm/drm_print.h>
 

-- 
2.34.1

