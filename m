From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:07:48 +0100
Subject: [PATCH 10/86] drm/armada: Direct include headers from drm_print
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-10-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331666; l=711;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=tMfNODGxSmxfn66asPob14EUR0XbvSYv1NeJXsiG3F0=;
 b=qzbc0bBWc1xQWuEhPSX1cU1IJWi1EM9GF17J+rBEdPGJyTJZIR0fmTw0hOP9arzYTyyZX48rFeIG
 ZyfsK+ZXBrLZZBxeDBMGWJYFfiVLSOX9aAHsXfLGx2gAUroBZC7O
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_print.h, because drm_print.h will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/armada/armada_debugfs.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/armada/armada_debugfs.c b/drivers/gpu/drm/armada/armada_debugfs.c
index 29f4b52e3c8d..a763349dd89f 100644
--- a/drivers/gpu/drm/armada/armada_debugfs.c
+++ b/drivers/gpu/drm/armada/armada_debugfs.c
@@ -5,6 +5,7 @@
  */
 
 #include <linux/ctype.h>
+#include <linux/debugfs.h>
 #include <linux/module.h>
 #include <linux/seq_file.h>
 #include <linux/uaccess.h>

-- 
2.34.1

