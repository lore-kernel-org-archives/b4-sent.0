From: Noralf =?utf-8?q?Tr=C3=B8nnes?= <noralf@tronnes.org>
Date: Wed, 07 Dec 2022 20:51:25 +0100
Subject: [PATCH] drm/gud: Fix missing include
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 8bit
Message-Id: <20221207-gud-missing-include-v1-0-c5b32c9c59da@tronnes.org>
To: dri-devel@lists.freedesktop.org, tzimmermann@suse.de, kernel test robot <lkp@intel.com>, Noralf =?utf-8?q?Tr=C3=B8nnes?= <noralf@tronnes.org>
X-Mailer: b4 0.11.0-dev-b77ec
X-Developer-Signature: v=1; a=ed25519-sha256; t=1670442742; l=810;
 i=noralf@tronnes.org; s=20221122; h=from:subject:message-id;
 bh=Sy9oNM1AjyUtgivdSQfr1nLU6XGfgTofHWkK4Acvx/c=;
 b=xfIAU439zxo+rCQgXY2YaOisRrx2EEGtsCwZBhVm3sfsrE0JdIgJiYyFs2eebOVZcbAXyFRkcrdE
 /B8xFfsXAK7FN13RMs1HbLpFzyLD6ill3Gm8/8zDYuLAqDsztmhI
X-Developer-Key: i=noralf@tronnes.org; a=ed25519;
 pk=0o9is4iddvvlrY3yON5SVtAbgPnVs0LfQsjfqR2Hvz8=
X-Endpoint-Received: by B4 Submission Endpoint for noralf@tronnes.org/20221122 with auth_id=8
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Add missing vmalloc.h include.

Fixes: c17d048609bf ("drm/gud: Use the shadow plane helper")
Reported-by: kernel test robot <lkp@intel.com>
Signed-off-by: Noralf Trønnes <noralf@tronnes.org>
---
 drivers/gpu/drm/gud/gud_pipe.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/gud/gud_pipe.c b/drivers/gpu/drm/gud/gud_pipe.c
index 62c43d3632d4..dc16a92625d4 100644
--- a/drivers/gpu/drm/gud/gud_pipe.c
+++ b/drivers/gpu/drm/gud/gud_pipe.c
@@ -5,6 +5,7 @@
 
 #include <linux/lz4.h>
 #include <linux/usb.h>
+#include <linux/vmalloc.h>
 #include <linux/workqueue.h>
 
 #include <drm/drm_atomic.h>

---
base-commit: 5ad8e63ebba3d5a0730b43180b200e41eeb9409c
change-id: 20221207-gud-missing-include-9ccf56382f8a

Best regards,
-- 
Noralf Trønnes <noralf@tronnes.org>
